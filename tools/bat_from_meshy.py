#!/usr/bin/env python3
"""Turns a Meshy bat (image-to-3D GLB: hundreds of thousands of triangles,
4K textures, lying along its Y) into the game's bat: simplified with its
its shape kept closed, the texture baked onto a fresh atlas (pymeshlab), laid along -Z with the knob at the origin and
BatMesh.LENGTH long (BatMesh's own convention, so it drops in for the
lathe bat), the base-color texture as one 1024 px JPEG. Usage:

    python3 tools/bat_from_meshy.py in.glb out.glb [faces=12000] [length=0.95]
"""
import io
import json
import os
import struct
import sys
import tempfile

import numpy as np
import pymeshlab
from PIL import Image

# The baked texture (px).
TEX = 2048


def read_glb(path):
    data = open(path, "rb").read()
    n = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + n])
    start = 20 + n + 8

    def acc(i):
        a = gltf["accessors"][i]
        v = gltf["bufferViews"][a["bufferView"]]
        k = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16}[a["componentType"]]
        o = start + v.get("byteOffset", 0) + a.get("byteOffset", 0)
        arr = np.frombuffer(data, dtype=dt, count=a["count"] * k, offset=o)
        return arr.reshape(-1, k) if k > 1 else arr

    prim = gltf["meshes"][0]["primitives"][0]
    pos = acc(prim["attributes"]["POSITION"]).astype(np.float64)
    uv = acc(prim["attributes"]["TEXCOORD_0"]).astype(np.float64)
    tri = acc(prim["indices"]).astype(np.int64).reshape(-1, 3)
    mat = gltf["materials"][prim.get("material", 0)]
    img_i = gltf["textures"][mat["pbrMetallicRoughness"]["baseColorTexture"]["index"]]["source"]
    v = gltf["bufferViews"][gltf["images"][img_i]["bufferView"]]
    o = start + v.get("byteOffset", 0)
    image = Image.open(io.BytesIO(data[o:o + v["byteLength"]])).convert("RGB")
    return pos, uv, tri, image


def write_glb(path, pos, nrm, uv, tri, jpeg):
    blobs = [pos.astype(np.float32).tobytes(), nrm.astype(np.float32).tobytes(), uv.astype(np.float32).tobytes(), tri.astype(np.uint32).tobytes(), jpeg]
    views, binary = [], bytearray()
    for b in blobs:
        while len(binary) % 4:
            binary.append(0)
        views.append({"buffer": 0, "byteOffset": len(binary), "byteLength": len(b)})
        binary += b
    while len(binary) % 4:
        binary.append(0)
    for i in range(3):
        views[i]["target"] = 34962
    views[3]["target"] = 34963
    gltf = {
        "asset": {"version": "2.0", "generator": "sportball bat_from_meshy.py"},
        "scene": 0, "scenes": [{"nodes": [0]}],
        "nodes": [{"name": "Bat", "mesh": 0}],
        "meshes": [{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "indices": 3, "material": 0}]}],
        "materials": [{"name": "Bat", "pbrMetallicRoughness": {"baseColorTexture": {"index": 0}, "metallicFactor": 0.0, "roughnessFactor": 0.55}}],
        "textures": [{"source": 0, "sampler": 0}],
        "samplers": [{"magFilter": 9729, "minFilter": 9987}],
        "images": [{"bufferView": 4, "mimeType": "image/jpeg"}],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": len(pos), "type": "VEC3", "min": pos.min(0).tolist(), "max": pos.max(0).tolist()},
            {"bufferView": 1, "componentType": 5126, "count": len(nrm), "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": len(uv), "type": "VEC2"},
            {"bufferView": 3, "componentType": 5125, "count": tri.size, "type": "SCALAR"},
        ],
        "bufferViews": views,
        "buffers": [{"byteLength": len(binary)}],
    }
    text = json.dumps(gltf, separators=(",", ":")).encode()
    while len(text) % 4:
        text += b" "
    with open(path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(text) + 8 + len(binary)))
        f.write(struct.pack("<I4s", len(text), b"JSON") + text)
        f.write(struct.pack("<I4s", len(binary), b"BIN\x00") + bytes(binary))


def main():
    src, dst = sys.argv[1], sys.argv[2]
    faces = int(sys.argv[3]) if len(sys.argv) > 3 else 12000
    length = float(sys.argv[4]) if len(sys.argv) > 4 else 0.95
    pos, uv, tri, image = read_glb(src)
    # Welded first (the source splits its vertices at UV seams; simplified
    # split, each seam's two sides move apart and the bat shows holes), the
    # UVs kept per triangle corner, then simplified keeping its own texture.
    _, first, inverse = np.unique(np.round(pos, 6), axis=0, return_index=True, return_inverse=True)
    welded = pos[first]
    wtri = inverse.reshape(-1)[tri]
    wedge_uv = uv[tri.reshape(-1)]
    # (Through an OBJ with its texture, so every face carries one.)
    tex_dir = tempfile.mkdtemp()
    image.save(os.path.join(tex_dir, "src.png"))
    with open(os.path.join(tex_dir, "src.mtl"), "w") as m:
        m.write("newmtl bat\nKd 1 1 1\nmap_Kd src.png\n")
    with open(os.path.join(tex_dir, "src.obj"), "w") as o:
        o.write("mtllib src.mtl\nusemtl bat\n")
        o.write("".join("v %.6f %.6f %.6f\n" % tuple(p) for p in welded))
        o.write("".join("vt %.6f %.6f\n" % (t[0], 1.0 - t[1]) for t in wedge_uv))
        o.write("".join("f %d/%d %d/%d %d/%d\n" % (a + 1, 3 * k + 1, b + 1, 3 * k + 2, c + 1, 3 * k + 3) for k, (a, b, c) in enumerate(wtri)))
    ms = pymeshlab.MeshSet()
    ms.load_new_mesh(os.path.join(tex_dir, "src.obj"))
    ms.apply_filter("meshing_decimation_quadric_edge_collapse_with_texture", targetfacenum=faces, preservenormal=True, preserveboundary=True)
    baked = image if max(image.size) <= TEX else image.resize((TEX, TEX), Image.LANCZOS)
    out = ms.current_mesh()
    v = out.vertex_matrix()
    f = out.face_matrix()
    wuv = out.wedge_tex_coord_matrix().reshape(-1, 2).copy()
    wuv[:, 1] = 1.0 - wuv[:, 1]  # (back from the OBJ's flipped V)
    # One UV per GPU vertex: split by (position index, UV); positions stay
    # shared, so nothing opens.
    corner_v = f.reshape(-1)
    key = np.hstack([corner_v[:, None].astype(np.float64), np.round(wuv, 6)])
    uniq, inv = np.unique(key, axis=0, return_inverse=True)
    vid = uniq[:, 0].astype(int)
    pos2 = v[vid]
    uv2 = uniq[:, 1:]
    tri2 = inv.reshape(-1, 3)
    # Lay it along -Z, the knob (the thin end) at the origin, at length.
    axis = int(np.argmax(v.max(0) - v.min(0)))
    lo, hi = v[:, axis].min(), v[:, axis].max()
    span = hi - lo
    others = [i for i in range(3) if i != axis]
    center = (v[:, others].max(0) + v[:, others].min(0)) * 0.5
    radius = np.linalg.norm(v[:, others] - center, axis=1)
    near_lo = radius[v[:, axis] < lo + span * 0.15].mean()
    near_hi = radius[v[:, axis] > hi - span * 0.15].mean()
    knob_at_lo = near_lo < near_hi
    scale = length / span

    def lay(p):
        t = (p[:, axis] - lo) / span if knob_at_lo else (hi - p[:, axis]) / span
        o = np.zeros_like(p)
        o[:, 0] = (p[:, others[0]] - center[0]) * scale * (1.0 if knob_at_lo else -1.0)
        o[:, 1] = (p[:, others[1]] - center[1]) * scale
        o[:, 2] = -t * length
        return o

    out_v = lay(v)
    out_pos = out_v[vid]
    # Smooth normals over the shared positions (no shading seams).
    fn = np.cross(out_v[f[:, 1]] - out_v[f[:, 0]], out_v[f[:, 2]] - out_v[f[:, 0]])
    vn = np.zeros_like(out_v)
    for k in range(3):
        np.add.at(vn, f[:, k], fn)
    radial = out_v.copy()
    radial[:, 2] = 0.0
    if (vn * radial).sum() < 0.0:
        tri2 = tri2[:, [0, 2, 1]]
        vn = -vn
    vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-9)
    buf = io.BytesIO()
    baked.save(buf, "JPEG", quality=90)
    write_glb(dst, out_pos, vn[vid], uv2, tri2, buf.getvalue())
    # Closed? (edges shared by exactly two faces, over the positions)
    e = np.sort(np.vstack([f[:, [0, 1]], f[:, [1, 2]], f[:, [2, 0]]]), 1)
    _, cnt = np.unique(e, axis=0, return_counts=True)
    print("faces %d -> %d, open edges %d, knob at %s end, radius knob/barrel %.3f/%.3f m" % (len(tri), len(f), int((cnt == 1).sum()), "low" if knob_at_lo else "high", min(near_lo, near_hi) * scale, max(near_lo, near_hi) * scale))


if __name__ == "__main__":
    main()
