"""Regrade a GLB's embedded base-color textures in place: pixels in a hue
band (degrees) are darkened and desaturated, e.g. icy pale blue roofs to
slate. Geometry and other maps are untouched.
  python3 tools/regrade_glb.py model.glb HUE_LO HUE_HI DARKEN [DESAT]"""
import colorsys
import io
import json
import struct
import sys

from PIL import Image


def regrade(path: str, lo: float, hi: float, darken: float, desat: float = 0.0) -> None:
	data = open(path, "rb").read()
	json_len = struct.unpack("<I", data[12:16])[0]
	gltf = json.loads(data[20:20 + json_len])
	bin_start = 20 + json_len + 8
	base = set()
	for mat in gltf.get("materials", []):
		tex = mat.get("pbrMetallicRoughness", {}).get("baseColorTexture")
		if tex is not None:
			base.add(gltf["textures"][tex["index"]]["source"])
	views = {gltf["images"][i]["bufferView"]: i for i in base}
	out = bytearray()
	for index, view in enumerate(gltf["bufferViews"]):
		start = bin_start + view.get("byteOffset", 0)
		chunk = data[start:start + view["byteLength"]]
		if index in views:
			img = Image.open(io.BytesIO(chunk)).convert("RGB")
			px = img.load()
			for y in range(img.size[1]):
				for x in range(img.size[0]):
					r, g, b = px[x, y]
					h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
					if lo <= h * 360 <= hi and s > 0.12:
						l *= 1.0 - darken
						s *= 1.0 - desat
						r, g, b = colorsys.hls_to_rgb(h, l, s)
						px[x, y] = (int(r * 255), int(g * 255), int(b * 255))
			buf = io.BytesIO()
			img.save(buf, "JPEG", quality=85)
			chunk = buf.getvalue()
			gltf["images"][views[index]]["mimeType"] = "image/jpeg"
		while len(out) % 4:
			out.append(0)
		view["byteOffset"] = len(out)
		view["byteLength"] = len(chunk)
		out += chunk
	while len(out) % 4:
		out.append(0)
	gltf["buffers"][0]["byteLength"] = len(out)
	js = json.dumps(gltf, separators=(",", ":")).encode()
	while len(js) % 4:
		js += b" "
	total = 12 + 8 + len(js) + 8 + len(out)
	with open(path, "wb") as f:
		f.write(struct.pack("<III", 0x46546C67, 2, total))
		f.write(struct.pack("<I", len(js)) + b"JSON" + js)
		f.write(struct.pack("<I", len(out)) + b"BIN\x00" + bytes(out))


if __name__ == "__main__":
	regrade(sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4]), float(sys.argv[5]) if len(sys.argv) > 5 else 0.0)
