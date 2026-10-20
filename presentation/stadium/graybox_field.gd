class_name GrayboxField
extends Node3D
## Primitive-mesh field built from FieldLayout + tuning. Disposable Phase 0
## placeholder: changing it never changes baseball rules.

const GRASS := Color(0.22, 0.46, 0.25)
const DIRT := Color(0.62, 0.45, 0.30)
const CHALK := Color(0.95, 0.95, 0.9)
const WALL := Color(0.16, 0.22, 0.38)
const WALL_CAP := Color(0.98, 0.72, 0.15)

var _tuning: BaseballTuning


func build(tuning: BaseballTuning) -> void:
	_tuning = tuning
	for child in get_children():
		child.queue_free()
	_add_box("Grass", Vector3(320, 0.1, 320), Vector3(0, -0.06, -110), GRASS)
	_build_infield()
	_build_foul_lines()
	_build_fence()
	_build_lighting()


func _build_infield() -> void:
	var half := FieldLayout.BASE_DISTANCE / sqrt(2.0)
	var dirt := _add_box("InfieldDirt", Vector3(FieldLayout.BASE_DISTANCE + 6, 0.04, FieldLayout.BASE_DISTANCE + 6), Vector3(0, -0.01, -half), DIRT)
	dirt.rotation_degrees.y = 45.0
	var grass := _add_box("InfieldGrass", Vector3(FieldLayout.BASE_DISTANCE - 4, 0.05, FieldLayout.BASE_DISTANCE - 4), Vector3(0, 0.0, -half), GRASS.lightened(0.05))
	grass.rotation_degrees.y = 45.0
	var mound := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 2.8
	cyl.height = 0.25
	mound.mesh = cyl
	mound.material_override = _mat(DIRT)
	mound.position = Vector3(0, 0.05, -18.4)
	mound.name = "Mound"
	add_child(mound)
	_add_box("HomePlate", Vector3(0.43, 0.06, 0.43), Vector3(0, 0.02, 0), CHALK)
	for base in [FieldLayout.FIRST, FieldLayout.SECOND, FieldLayout.THIRD]:
		var bag := _add_box("Base%d" % base, Vector3(0.6, 0.12, 0.6), FieldLayout.base_position(base) + Vector3(0, 0.05, 0), CHALK)
		bag.rotation_degrees.y = 45.0


func _build_foul_lines() -> void:
	for side in [-1.0, 1.0]:
		var dir := FieldLayout.direction_for_spray(side * _tuning.foul_line_angle)
		var length := _tuning.fence_line
		var line := _add_box("FoulLine", Vector3(0.12, 0.03, length), dir * length * 0.5 + Vector3(0, 0.03, 0), CHALK)
		line.look_at_from_position(line.position, line.position + dir, Vector3.UP)
		var pole := _add_box("FoulPole", Vector3(0.3, 14.0, 0.3), dir * length + Vector3(0, 7.0, 0), WALL_CAP)
		pole.name = "FoulPole"


func _build_fence() -> void:
	var segments := 36
	var angle := _tuning.foul_line_angle
	for i in segments:
		var a0 := lerpf(-angle, angle, float(i) / segments)
		var a1 := lerpf(-angle, angle, float(i + 1) / segments)
		var p0 := FieldLayout.direction_for_spray(a0) * FieldLayout.fence_distance(a0, _tuning)
		var p1 := FieldLayout.direction_for_spray(a1) * FieldLayout.fence_distance(a1, _tuning)
		var mid := (p0 + p1) * 0.5
		var length := p0.distance_to(p1) + 0.2
		var h := _tuning.fence_height
		var wall := _add_box("Wall", Vector3(length, h, 0.5), mid + Vector3(0, h * 0.5, 0), WALL)
		wall.look_at_from_position(wall.position, wall.position + (p1 - p0).cross(Vector3.UP), Vector3.UP)
		var cap := _add_box("WallCap", Vector3(length, 0.25, 0.6), mid + Vector3(0, h, 0), WALL_CAP)
		cap.rotation = wall.rotation


func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.36, 0.55, 0.78)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.78, 0.85)
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)


func _add_box(node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = _mat(color)
	mi.position = pos
	mi.name = node_name
	add_child(mi)
	return mi


static func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.9
	return m
