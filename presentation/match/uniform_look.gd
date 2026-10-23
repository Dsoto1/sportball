class_name UniformLook
extends RefCounted
## Paints the mannequin as a ballplayer: a copy of its mesh where every
## vertex carries its body region (in UV2.x, an exact float) from its strongest bone
## and its rest-pose height, read by the uniform shader. Built once and
## shared; each player's colors live in his own material.

const SHADER := preload("res://presentation/match/uniform.gdshader")
const CLOTH_SHADER := preload("res://presentation/match/cloth.gdshader")
enum Region { JERSEY, TRIM, BELT, PANTS, SOCKS, CLEATS, SKIN, HANDS }
## Rest-pose heights (m): jersey tucks in above the belt, pants end below
## the knee, sleeves end partway down the upper arm.
const BELT_TOP := 0.99
const BELT_BOTTOM := 0.94
const SOCK_TOP := 0.37
const SLEEVE_END := 0.33
const CUFF := 0.03
## Kept a little deep: the ballpark sun and sky light wash pale tones out.
const SKIN_TONES := [Color(0.86, 0.66, 0.52), Color(0.78, 0.56, 0.4), Color(0.66, 0.45, 0.3),
	Color(0.52, 0.34, 0.22), Color(0.4, 0.26, 0.17), Color(0.3, 0.19, 0.12)]

static var _mesh: ArrayMesh
static var _shell: ArrayMesh


## The region-painted copy of the mannequin mesh (same skinning).
static func mesh_for(source: MeshInstance3D) -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var src := source.mesh
	var names := PackedStringArray()
	for b in source.skin.get_bind_count():
		names.append(String(source.skin.get_bind_name(b)))
	_mesh = ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / verts.size()
		var regions := PackedVector2Array()
		regions.resize(verts.size())
		for i in verts.size():
			var best := 0
			for k in per:
				if weights[i * per + k] > weights[i * per + best]:
					best = k
			var region := region_for(names[bones[i * per + best]], verts[i])
			regions[i] = Vector2(float(region), 0.0)
		arrays[Mesh.ARRAY_TEX_UV2] = regions
		_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return _mesh


## The uniform as cloth: the jersey, sleeve trim, belt and pants of the
## mannequin copied out and stood off the skin (looser at the waist, the
## sleeve cuffs and above the socks, where real kits blouse), with the
## body's own skinning so it moves with every clip. UV carries the rest
## position across the body (x, z) and UV2 the region and rest height,
## for the cloth shader's placket, stripes and folds.
static func shell_for(source: MeshInstance3D) -> ArrayMesh:
	if _shell != null:
		return _shell
	var src := source.mesh
	var names := PackedStringArray()
	for b in source.skin.get_bind_count():
		names.append(String(source.skin.get_bind_name(b)))
	_shell = ArrayMesh.new()
	for s in src.get_surface_count():
		var arrays := src.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var per := bones.size() / verts.size()
		# Normals averaged over vertices sharing a spot (split along UV
		# seams), so the cloth stands off as one piece without cracks.
		var smooth := {}
		for i in verts.size():
			var key := Vector3i((verts[i] * 2000.0).round())
			smooth[key] = smooth.get(key, Vector3.ZERO) + normals[i]
		var region := PackedInt32Array()
		var bone_of := PackedStringArray()
		region.resize(verts.size())
		bone_of.resize(verts.size())
		for i in verts.size():
			var best := 0
			for k in per:
				if weights[i * per + k] > weights[i * per + best]:
					best = k
			bone_of[i] = names[bones[i * per + best]]
			region[i] = region_for(bone_of[i], verts[i])
		var remap := {}
		var out_v := PackedVector3Array()
		var out_n := PackedVector3Array()
		var out_b := PackedInt32Array()
		var out_w := PackedFloat32Array()
		var out_uv := PackedVector2Array()
		var out_uv2 := PackedVector2Array()
		var out_i := PackedInt32Array()
		for t in range(0, indices.size(), 3):
			var cloth := true
			for c in 3:
				if region[indices[t + c]] > Region.PANTS:
					cloth = false
			if not cloth:
				continue
			for c in 3:
				var i := indices[t + c]
				if not remap.has(i):
					remap[i] = out_v.size()
					var n: Vector3 = (smooth[Vector3i((verts[i] * 2000.0).round())] as Vector3).normalized()
					out_v.append(verts[i] + n * _stand_off(region[i], bone_of[i], verts[i]))
					out_n.append(n)
					for k in per:
						out_b.append(bones[i * per + k])
						out_w.append(weights[i * per + k])
					out_uv.append(Vector2(verts[i].x, verts[i].z))
					out_uv2.append(Vector2(float(region[i]), verts[i].y))
				out_i.append(remap[i])
		var shell := []
		shell.resize(Mesh.ARRAY_MAX)
		shell[Mesh.ARRAY_VERTEX] = out_v
		shell[Mesh.ARRAY_NORMAL] = out_n
		shell[Mesh.ARRAY_BONES] = out_b
		shell[Mesh.ARRAY_WEIGHTS] = out_w
		shell[Mesh.ARRAY_TEX_UV] = out_uv
		shell[Mesh.ARRAY_TEX_UV2] = out_uv2
		shell[Mesh.ARRAY_INDEX] = out_i
		if out_i.size() > 0:
			var flags := Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per == 8 else 0
			_shell.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, shell, [], {}, flags)
	return _shell


## How far the cloth stands off the skin (m) at a rest-pose spot.
static func _stand_off(region: int, bone: String, rest: Vector3) -> float:
	match region:
		Region.BELT:
			return 0.012
		Region.TRIM:
			return 0.03
		Region.PANTS:
			# Roomy through the seat and thigh, bloused over the sock top.
			return 0.022 + 0.01 * smoothstep(0.75, 0.9, rest.y) + 0.022 * smoothstep(0.52, 0.4, rest.y)
	if bone.begins_with("upperarm"):
		# Sleeves widen toward the cuff.
		return 0.02 + 0.012 * smoothstep(0.2, SLEEVE_END, absf(rest.x))
	# The jersey hangs looser lower down, bloused over the belt.
	return 0.016 + 0.016 * smoothstep(1.3, 1.02, rest.y)


static func cloth_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CLOTH_SHADER
	return m


## Body region for a vertex from its strongest bone and rest position.
static func region_for(bone: String, rest: Vector3) -> Region:
	if bone == "Head" or bone == "neck_01":
		return Region.SKIN
	if bone.begins_with("hand") or bone.begins_with("index") or bone.begins_with("middle") \
			or bone.begins_with("ring") or bone.begins_with("pinky") or bone.begins_with("thumb"):
		return Region.HANDS
	if bone.begins_with("lowerarm"):
		return Region.SKIN
	if bone.begins_with("upperarm"):
		var out := absf(rest.x)
		if out > SLEEVE_END + CUFF:
			return Region.SKIN
		return Region.TRIM if out > SLEEVE_END else Region.JERSEY
	if bone.begins_with("foot") or bone.begins_with("ball"):
		return Region.CLEATS
	if bone.begins_with("calf"):
		return Region.PANTS if rest.y > SOCK_TOP else Region.SOCKS
	if bone.begins_with("thigh"):
		return Region.PANTS
	# Torso and hips: jersey, belt, pants by height.
	if rest.y >= BELT_TOP:
		return Region.JERSEY
	return Region.BELT if rest.y >= BELT_BOTTOM else Region.PANTS


const HAIR_COLORS := [Color(0.08, 0.06, 0.05), Color(0.2, 0.12, 0.07), Color(0.38, 0.24, 0.12), Color(0.6, 0.44, 0.24), Color(0.5, 0.18, 0.08)]


## A hair color picked steadily from a player's id.
static func hair_for(id: String) -> Color:
	return HAIR_COLORS[absi(hash(id + "hair")) % HAIR_COLORS.size()]


## A skin tone picked steadily from a player's id.
static func skin_for(id: String) -> Color:
	return SKIN_TONES[absi(hash(id)) % SKIN_TONES.size()]


static func material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	return m
