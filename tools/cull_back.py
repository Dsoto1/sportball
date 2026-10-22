"""Drop the triangles of a GLB that face away from the viewer. Stadium
pieces only ever face the bowl (their +Z toward home plate), so faces
whose normal points back (normal.z below -THRESHOLD) are never seen.
Unused vertices are removed. Single-mesh, single-primitive files (as
Meshy exports them); images and materials are kept as they are.
  python3 tools/cull_back.py in.glb out.glb [threshold=0.25]"""
import json
import struct
import sys

import numpy as np

TYPES = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}
DTYPES = {5126: np.float32, 5125: np.uint32, 5123: np.uint16, 5121: np.uint8}


def read(path: str) -> tuple[dict, bytes]:
	data = open(path, "rb").read()
	json_len = struct.unpack("<I", data[12:16])[0]
	gltf = json.loads(data[20:20 + json_len])
	bin_start = 20 + json_len + 8
	bin_len = struct.unpack("<I", data[20 + json_len:24 + json_len])[0]
	return gltf, data[bin_start:bin_start + bin_len]


def accessor(gltf: dict, blob: bytes, index: int) -> np.ndarray:
	acc = gltf["accessors"][index]
	view = gltf["bufferViews"][acc["bufferView"]]
	comps = TYPES[acc["type"]]
	dtype = np.dtype(DTYPES[acc["componentType"]])
	start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
	stride = view.get("byteStride", comps * dtype.itemsize)
	count = acc["count"]
	raw = np.frombuffer(blob, dtype=np.uint8, count=stride * (count - 1) + comps * dtype.itemsize, offset=start)
	rows = np.lib.stride_tricks.as_strided(raw, shape=(count, comps * dtype.itemsize), strides=(stride, 1))
	return np.ascontiguousarray(rows).view(dtype).reshape(count, comps)


def cull(src: str, dst: str, threshold: float = 0.25) -> None:
	gltf, blob = read(src)
	prim = gltf["meshes"][0]["primitives"][0]
	idx = accessor(gltf, blob, prim["indices"]).reshape(-1, 3).astype(np.int64)
	pos = accessor(gltf, blob, prim["attributes"]["POSITION"])
	a, b, c = pos[idx[:, 0]], pos[idx[:, 1]], pos[idx[:, 2]]
	n = np.cross(b - a, c - a)
	length = np.linalg.norm(n, axis=1)
	nz = np.where(length > 0, n[:, 2] / np.maximum(length, 1e-12), 0.0)
	keep = idx[nz >= -threshold]
	used = np.unique(keep)
	remap = np.full(len(pos), -1, dtype=np.int64)
	remap[used] = np.arange(len(used))
	new_idx = remap[keep].astype(np.uint32).reshape(-1)
	attrs = {name: accessor(gltf, blob, i)[used] for name, i in prim["attributes"].items()}
	# Rebuild the binary chunk: images first (unchanged), then geometry.
	out = bytearray()
	views: list = []
	accessors: list = []

	def add_view(data: bytes, target: int | None = None) -> int:
		while len(out) % 4:
			out.append(0)
		view = {"buffer": 0, "byteOffset": len(out), "byteLength": len(data)}
		if target is not None:
			view["target"] = target
		out.extend(data)
		views.append(view)
		return len(views) - 1

	for image in gltf.get("images", []):
		if "bufferView" in image:
			old = gltf["bufferViews"][image["bufferView"]]
			start = old.get("byteOffset", 0)
			image["bufferView"] = add_view(blob[start:start + old["byteLength"]])
	accessors.append({"bufferView": add_view(new_idx.tobytes(), 34963), "componentType": 5125, "count": int(new_idx.size), "type": "SCALAR"})
	prim["indices"] = 0
	for name, values in attrs.items():
		values = np.ascontiguousarray(values.astype(np.float32))
		acc = {"bufferView": add_view(values.tobytes(), 34962), "componentType": 5126, "count": int(len(values)), "type": {1: "SCALAR", 2: "VEC2", 3: "VEC3", 4: "VEC4"}[values.shape[1]]}
		if name == "POSITION":
			acc["min"] = values.min(axis=0).tolist()
			acc["max"] = values.max(axis=0).tolist()
		accessors.append(acc)
		prim["attributes"][name] = len(accessors) - 1
	while len(out) % 4:
		out.append(0)
	gltf["accessors"] = accessors
	gltf["bufferViews"] = views
	gltf["buffers"] = [{"byteLength": len(out)}]
	js = json.dumps(gltf, separators=(",", ":")).encode()
	while len(js) % 4:
		js += b" "
	with open(dst, "wb") as f:
		f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(out)))
		f.write(struct.pack("<I", len(js)) + b"JSON" + js)
		f.write(struct.pack("<I", len(out)) + b"BIN\x00" + bytes(out))
	print(f"{src}: kept {len(keep)} of {len(idx)} triangles ({100 * len(keep) / len(idx):.0f}%)")


if __name__ == "__main__":
	cull(sys.argv[1], sys.argv[2], float(sys.argv[3]) if len(sys.argv) > 3 else 0.25)
