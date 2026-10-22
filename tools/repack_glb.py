"""Shrink a GLB's embedded textures (resize to a max size, re-encode JPEG)
and repack the binary chunk. Geometry is untouched.
  python3 tools/repack_glb.py in.glb out.glb [max_px=1024] [quality=85]"""
import io
import json
import struct
import sys

from PIL import Image


def repack(src: str, dst: str, max_px: int = 1024, quality: int = 85) -> None:
	data = open(src, "rb").read()
	json_len = struct.unpack("<I", data[12:16])[0]
	gltf = json.loads(data[20:20 + json_len])
	bin_start = 20 + json_len + 8
	images = {im["bufferView"]: im for im in gltf.get("images", []) if "bufferView" in im}
	out = bytearray()
	for index, view in enumerate(gltf["bufferViews"]):
		start = bin_start + view.get("byteOffset", 0)
		chunk = data[start:start + view["byteLength"]]
		if index in images:
			img = Image.open(io.BytesIO(chunk)).convert("RGB")
			if max(img.size) > max_px:
				img = img.resize((max_px, max_px * img.size[1] // img.size[0]), Image.LANCZOS)
			buf = io.BytesIO()
			img.save(buf, "JPEG", quality=quality)
			chunk = buf.getvalue()
			images[index]["mimeType"] = "image/jpeg"
		while len(out) % 4:
			out.append(0)
		view["byteOffset"] = len(out)
		view["byteLength"] = len(chunk)
		out.extend(chunk)
	while len(out) % 4:
		out.append(0)
	gltf["buffers"][0]["byteLength"] = len(out)
	js = json.dumps(gltf, separators=(",", ":")).encode()
	while len(js) % 4:
		js += b" "
	total = 12 + 8 + len(js) + 8 + len(out)
	with open(dst, "wb") as f:
		f.write(struct.pack("<III", 0x46546C67, 2, total))
		f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
		f.write(struct.pack("<II", len(out), 0x004E4942) + bytes(out))


if __name__ == "__main__":
	repack(sys.argv[1], sys.argv[2], int(sys.argv[3]) if len(sys.argv) > 3 else 1024, int(sys.argv[4]) if len(sys.argv) > 4 else 85)
