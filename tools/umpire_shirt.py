#!/usr/bin/env python3
"""Recolors the umpire's dark shirt in his base-color texture, keeping its
shading: the texels under triangles skinned mostly to the spine, shoulders
and upper arms (the shirt and its sleeves), and dark there (not skin, the
mask's straps or the belt), take the new color scaled by how light they
were. Run on the rigged GLB before tools/glb_shrink_textures.py:

    python3 tools/umpire_shirt.py in.glb out.glb [r g b]
"""
import io
import json
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw

# Powder blue, the umpires' light shirt.
COLOR = (0.72, 0.84, 0.97)
# Skin joints that the shirt covers (indices into the skin's joints, by
# name), and the darkest texels counted as shirt.
SHIRT_BONES = ("Spine", "Spine1", "Spine2", "LeftShoulder", "RightShoulder", "LeftArm", "RightArm")
DARK = 0.32


def main() -> None:
    src, dst = sys.argv[1], sys.argv[2]
    color = np.array([float(v) for v in sys.argv[3:6]]) if len(sys.argv) >= 6 else np.array(COLOR)
    data = bytearray(open(src, "rb").read())
    json_len = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + json_len])
    bin_start = 20 + json_len + 8

    def accessor(i: int) -> np.ndarray:
        a = gltf["accessors"][i]
        v = gltf["bufferViews"][a["bufferView"]]
        n = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        dt = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}[a["componentType"]]
        o = bin_start + v.get("byteOffset", 0) + a.get("byteOffset", 0)
        arr = np.frombuffer(bytes(data), dtype=dt, count=a["count"] * n, offset=o)
        return arr.reshape(-1, n) if n > 1 else arr

    prim = gltf["meshes"][0]["primitives"][0]
    uv = accessor(prim["attributes"]["TEXCOORD_0"])
    joints = accessor(prim["attributes"]["JOINTS_0"])
    weights = accessor(prim["attributes"]["WEIGHTS_0"])
    tris = accessor(prim["indices"]).reshape(-1, 3)
    names = [gltf["nodes"][n]["name"].split(":")[-1] for n in gltf["skins"][0]["joints"]]
    shirt = {i for i, n in enumerate(names) if n in SHIRT_BONES}
    top = joints[np.arange(len(joints)), np.argmax(weights, axis=1)]
    on_shirt = np.isin(top, list(shirt))

    material = gltf["materials"][prim["material"]]
    image_index = gltf["textures"][material["pbrMetallicRoughness"]["baseColorTexture"]["index"]]["source"]
    view = gltf["bufferViews"][gltf["images"][image_index]["bufferView"]]
    o = bin_start + view.get("byteOffset", 0)
    img = Image.open(io.BytesIO(bytes(data[o:o + view["byteLength"]]))).convert("RGB")
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    draw = ImageDraw.Draw(mask)
    for t in tris:
        if on_shirt[t].sum() >= 2:
            draw.polygon([(uv[k][0] * w, uv[k][1] * h) for k in t], fill=255)
    px = np.asarray(img).astype(np.float32) / 255.0
    luma = px @ np.array([0.299, 0.587, 0.114])
    sel = (np.asarray(mask) > 0) & (luma < DARK)
    ref = np.median(luma[sel]) if sel.any() else 0.1
    shade = np.clip(luma / max(ref, 0.01), 0.45, 1.35)[..., None]
    out = np.where(sel[..., None], np.clip(color * shade, 0.0, 1.0), px)
    print("shirt texels: %d (%.1f%% of the texture), median luma %.3f" % (sel.sum(), 100.0 * sel.mean(), ref))
    buf = io.BytesIO()
    Image.fromarray((out * 255.0).astype(np.uint8)).save(buf, "PNG")
    new = buf.getvalue()

    # Rebuild the binary chunk with the new image in its buffer view.
    views = gltf["bufferViews"]
    blobs = []
    for i, v in enumerate(views):
        if i == gltf["images"][image_index]["bufferView"]:
            blobs.append(new)
        else:
            s = bin_start + v.get("byteOffset", 0)
            blobs.append(bytes(data[s:s + v["byteLength"]]))
    binary = bytearray()
    for i, v in enumerate(views):
        while len(binary) % 4:
            binary.append(0)
        v["byteOffset"] = len(binary)
        v["byteLength"] = len(blobs[i])
        binary += blobs[i]
    while len(binary) % 4:
        binary.append(0)
    gltf["buffers"] = [{"byteLength": len(binary)}]
    text = json.dumps(gltf, separators=(",", ":")).encode()
    while len(text) % 4:
        text += b" "
    with open(dst, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(text) + 8 + len(binary)))
        f.write(struct.pack("<I4s", len(text), b"JSON") + text)
        f.write(struct.pack("<I4s", len(binary), b"BIN\x00") + bytes(binary))
    Image.fromarray((out * 255.0).astype(np.uint8)).resize((512, 512)).save(dst + ".preview.png")


if __name__ == "__main__":
    main()
