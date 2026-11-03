class_name BatMesh
extends RefCounted
## A bat turned on a lathe from a profile: knob, thin handle, taper, barrel
## and a cupped end. Arcade proportions (a little thick, so it reads from the
## batting camera). The mesh runs along -Z from the knob (z = 0) so a node
## that looks at the barrel direction holds it by the handle. UV.y is 0 at
## the knob and 1 at the end; UV.x wraps around.

const SHADER := preload("res://presentation/props/bat.gdshader")
const LENGTH := 0.95
## (fraction of length, radius m), knob to end.
const PROFILE := [[0.0, 0.0], [0.004, 0.032], [0.018, 0.038], [0.035, 0.03], [0.05, 0.021],
	[0.3, 0.023], [0.45, 0.03], [0.6, 0.045], [0.72, 0.055], [0.93, 0.057], [0.97, 0.054], [0.99, 0.045], [1.0, 0.0]]
const SIDES := 24
## The owner's Meshy bat (tools/bat_from_meshy.py: laid along -Z, knob at
## the origin, LENGTH long), used when present instead of the lathe bat.
const MODEL := "res://assets/generated/meshy/bat/bat.glb"
static var _model: Mesh


static func has_model() -> bool:
	return ResourceLoader.exists(MODEL)


static func build() -> Mesh:
	if has_model():
		if _model == null:
			var scene: Node = (load(MODEL) as PackedScene).instantiate()
			var mi: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
			_model = mi.mesh
			scene.free()
		return _model
	return _lathe()


static func _lathe() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in PROFILE.size() - 1:
		var p0: Array = PROFILE[i]
		var p1: Array = PROFILE[i + 1]
		for s in SIDES:
			var a0 := TAU * s / SIDES
			var a1 := TAU * (s + 1) / SIDES
			var v00 := _vertex(p0, a0)
			var v01 := _vertex(p0, a1)
			var v10 := _vertex(p1, a0)
			var v11 := _vertex(p1, a1)
			_add(st, v00, p0, float(s) / SIDES)
			_add(st, v10, p1, float(s) / SIDES)
			_add(st, v11, p1, float(s + 1) / SIDES)
			_add(st, v00, p0, float(s) / SIDES)
			_add(st, v11, p1, float(s + 1) / SIDES)
			_add(st, v01, p0, float(s + 1) / SIDES)
	st.generate_normals()
	return st.commit()


## The lathe bat's material (null with the model: it carries its own).
static func material() -> ShaderMaterial:
	if has_model():
		return null
	var m := ShaderMaterial.new()
	m.shader = SHADER
	return m


static func _vertex(p: Array, angle: float) -> Vector3:
	return Vector3(cos(angle) * float(p[1]), sin(angle) * float(p[1]), -float(p[0]) * LENGTH)


static func _add(st: SurfaceTool, v: Vector3, p: Array, u: float) -> void:
	st.set_uv(Vector2(u, float(p[0])))
	st.add_vertex(v)
