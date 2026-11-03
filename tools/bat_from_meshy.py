#!/usr/bin/env python3
"""Turns a Meshy bat (image-to-3D GLB: hundreds of thousands of triangles,
4K textures, lying along its Y) into the game's bat: simplified with its
UVs kept (pymeshlab), laid along -Z with the knob at the origin and
BatMesh.LENGTH long (BatMesh's own convention, so it drops in for the
lathe bat), the base-color texture as one 1024 px JPEG. Usage:

    python3 tools/bat_from_meshy.py in.glb out.glb [faces=12000] [length=0.95]
"""
import io
import json
import struct
import sys

import numpy as np
import pymeshlab
from PIL import Image


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
    ms = pymeshlab.MeshSet()
    m = pymeshlab.Mesh(vertex_matrix=pos, face_matrix=tri, v_tex_coords_matrix=uv)
    ms.add_mesh(m)
    ms.apply_filter("compute_texcoord_transfer_vertex_to_wedge")
    ms.apply_filter("meshing_decimation_quadric_edge_collapse_with_texture", targetfacenum=faces, preservenormal=True)
    out = ms.current_mesh()
    # Back to one UV per vertex: split vertices by their wedge UVs.
    v = out.vertex_matrix()
    f = out.face_matrix()
    w = out.wedge_tex_coord_matrix().reshape(-1, 2)
    corner_pos = v[f.reshape(-1)]
    key = np.round(np.hstack([corner_pos, w]), 6)
    uniq, inverse = np.unique(key, axis=0, return_inverse=True)
    pos2 = uniq[:, :3]
    uv2 = uniq[:, 3:]
    tri2 = inverse.reshape(-1, 3)
    # Lay it along -Z, the knob (the thin end) at the origin, at length.
    axis = int(np.argmax(pos2.max(0) - pos2.min(0)))
    lo, hi = pos2[:, axis].min(), pos2[:, axis].max()
    span = hi - lo
    others = [i for i in range(3) if i != axis]
    center = (pos2[:, others].max(0) + pos2[:, others].min(0)) * 0.5
    radius = np.linalg.norm(pos2[:, others] - center, axis=1)
    near_lo = radius[pos2[:, axis] < lo + span * 0.15].mean()
    near_hi = radius[pos2[:, axis] > hi - span * 0.15].mean()
    knob_at_lo = near_lo < near_hi
    t = (pos2[:, axis] - lo) / span if knob_at_lo else (hi - pos2[:, axis]) / span
    scale = length / span
    out_pos = np.zeros_like(pos2)
    out_pos[:, 0] = (pos2[:, others[0]] - center[0]) * scale
    out_pos[:, 1] = (pos2[:, others[1]] - center[1]) * scale
    out_pos[:, 2] = -t * length
    if not knob_at_lo:
        # Mirrored by the flip of the long axis: undo with one side axis.
        out_pos[:, 0] = -out_pos[:, 0]
    # Normals from the faces, smoothed per vertex.
    fn = np.cross(out_pos[tri2[:, 1]] - out_pos[tri2[:, 0]], out_pos[tri2[:, 2]] - out_pos[tri2[:, 0]])
    vn = np.zeros_like(out_pos)
    for k in range(3):
        np.add.at(vn, tri2[:, k], fn)
    vn /= np.maximum(np.linalg.norm(vn, axis=1, keepdims=True), 1e-9)
    # Keep the winding facing out (normals away from the bat's axis).
    radial = out_pos.copy()
    radial[:, 2] = 0.0
    if (vn * radial).sum() < 0.0:
        tri2 = tri2[:, [0, 2, 1]]
        vn = -vn
    buf = io.BytesIO()
    image.resize((1024, 1024), Image.LANCZOS).save(buf, "JPEG", quality=88)
    write_glb(dst, out_pos, vn, uv2, tri2, buf.getvalue())
    print("faces %d -> %d, verts %d, knob at %s end, radius knob/barrel %.3f/%.3f m" % (len(tri), len(tri2), len(out_pos), "low" if knob_at_lo else "high", min(near_lo, near_hi) * scale, max(near_lo, near_hi) * scale))


if __name__ == "__main__":
    main()
