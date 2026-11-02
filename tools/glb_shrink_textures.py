#!/usr/bin/env python3
"""Rewrites a GLB with its textures as JPEGs at a smaller size, so a Meshy
character (4096 px PNGs, tens of MB) fits the repo. The mesh, skin and
animations are copied as they are. Usage:

    python3 tools/glb_shrink_textures.py in.glb out.glb [size=2048] [--drop-mr]

--drop-mr drops the metallic-roughness map (the players' look ignores it).
"""
import io
import json
import struct
import sys

from PIL import Image


def main() -> None:
    src, dst = sys.argv[1], sys.argv[2]
    size = int(sys.argv[3]) if len(sys.argv) > 3 and sys.argv[3].isdigit() else 2048
    drop_mr = "--drop-mr" in sys.argv
    data = open(src, "rb").read()
    json_len = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + json_len])
    bin_start = 20 + json_len + 8
    views = gltf["bufferViews"]

    def view_bytes(i: int) -> bytes:
        v = views[i]
        o = bin_start + v.get("byteOffset", 0)
        return data[o:o + v["byteLength"]]

    blobs = [view_bytes(i) for i in range(len(views))]
    if drop_mr:
        for m in gltf.get("materials", []):
            m.get("pbrMetallicRoughness", {}).pop("metallicRoughnessTexture", None)
    used = set()
    for m in gltf.get("materials", []):
        for key in ("baseColorTexture", "metallicRoughnessTexture"):
            t = m.get("pbrMetallicRoughness", {}).get(key)
            if t is not None:
                used.add(gltf["textures"][t["index"]]["source"])
        for key in ("normalTexture", "emissiveTexture", "occlusionTexture"):
            if key in m:
                used.add(gltf["textures"][m[key]["index"]]["source"])
    for i, image in enumerate(gltf.get("images", [])):
        if i not in used:
            # Unused: shrink it to nothing rather than renumber everything.
            out = io.BytesIO()
            Image.new("RGB", (4, 4)).save(out, "JPEG")
        else:
            img = Image.open(io.BytesIO(blobs[image["bufferView"]])).convert("RGB")
            if max(img.size) > size:
                img = img.resize((size, size * img.size[1] // img.size[0]), Image.LANCZOS)
            out = io.BytesIO()
            img.save(out, "JPEG", quality=88)
        blobs[image["bufferView"]] = out.getvalue()
        image["mimeType"] = "image/jpeg"
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
    total = 12 + 8 + len(text) + 8 + len(binary)
    with open(dst, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total))
        f.write(struct.pack("<I4s", len(text), b"JSON") + text)
        f.write(struct.pack("<I4s", len(binary), b"BIN\x00") + bytes(binary))
    print("wrote %s (%.1f MB)" % (dst, total / 1e6))


if __name__ == "__main__":
    main()
