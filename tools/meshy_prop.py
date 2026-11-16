#!/usr/bin/env python3
"""Turns a Meshy prop (text/image-to-3D GLB: hundreds of thousands of
triangles, 2-4K textures) into a game asset: welded (so the surface stays
closed), simplified keeping its own texture (pymeshlab), its size kept as
it came (the game scales it), centred over its base (min Y = 0), the
base colour as one JPEG. Usage:

    python3 tools/meshy_prop.py in.glb out.glb [faces=6000] [tex=1024]
"""
import io
import os
import sys
import tempfile

import numpy as np
import pymeshlab
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from bat_from_meshy import read_glb, write_glb  # noqa: E402


def main():
    src, dst = sys.argv[1], sys.argv[2]
    faces = int(sys.argv[3]) if len(sys.argv) > 3 else 6000
    tex = int(sys.argv[4]) if len(sys.argv) > 4 else 1024
    pos, uv, tri, image = read_glb(src)
    _, first, inverse = np.unique(np.round(pos, 6), axis=0, return_index=True, return_inverse=True)
    welded = pos[first]
    wtri = inverse.reshape(-1)[tri]
    wedge_uv = uv[tri.reshape(-1)]
    tex_dir = tempfile.mkdtemp()
    image.save(os.path.join(tex_dir, "src.png"))
    with open(os.path.join(tex_dir, "src.mtl"), "w") as m:
        m.write("newmtl prop\nKd 1 1 1\nmap_Kd src.png\n")
    with open(os.path.join(tex_dir, "src.obj"), "w") as o:
        o.write("mtllib src.mtl\nusemtl prop\n")
        o.write("".join("v %.6f %.6f %.6f\n" % tuple(p) for p in welded))
        o.write("".join("vt %.6f %.6f\n" % (t[0], 1.0 - t[1]) for t in wedge_uv))
        o.write("".join("f %d/%d %d/%d %d/%d\n" % (a + 1, 3 * k + 1, b + 1, 3 * k + 2, c + 1, 3 * k + 3) for k, (a, b, c) in enumerate(wtri)))
    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(os.path.join(tex_dir, "src.obj"))
    ms.apply_filter("meshing_decimation_quadric_edge_collapse_with_texture", targetfacenum=faces, preservenormal=True, preserveboundary=True)
    out = ms.current_mesh()
    v = out.vertex_matrix()
    f = out.face_matrix()
    wuv = out.wedge_tex_coord_matrix().reshape(-1, 2).copy()
    wuv[:, 1] = 1.0 - wuv[:, 1]
    key = np.hstack([f.reshape(-1)[:, None].astype(np.float64), np.round(wuv, 6)])
    uniq, inv = np.unique(key, axis=0, return_inverse=True)
    vid = uniq[:, 0].astype(int)
    # Centred over its base.
    c = (v.max(0) + v.min(0)) * 0.5
    v = v - np.array([c[0], v[:, 1].min(), c[2]])
    fn = np.cross(v[f[:, 1]] - v[f[:, 0]], v[f[:, 2]] - v[f[:, 0]])
    vn = np.zeros_like(v)
    for k in range(3):
        np.add.at(vn, f[:, k], fn)
    vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-9)
    img = image if max(image.size) <= tex else image.resize((tex, tex), Image.LANCZOS)
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=88)
    write_glb(dst, v[vid], vn[vid], uniq[:, 1:], inv.reshape(-1, 3), buf.getvalue())
    e = np.sort(np.vstack([f[:, [0, 1]], f[:, [1, 2]], f[:, [2, 0]]]), 1)
    _, cnt = np.unique(e, axis=0, return_counts=True)
    print("faces %d -> %d, open edges %d, size %s" % (len(tri), len(f), int((cnt == 1).sum()), np.round(v.max(0) - v.min(0), 3)))


if __name__ == "__main__":
    main()
