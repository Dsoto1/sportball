class_name GrayboxField
extends Node3D
## Primitive-mesh field built from FieldLayout + tuning. Changing it never
## changes baseball rules. Grass and dirt use the field surface shader:
## project palette colors with CC0 ambientCG texture as subtle detail.

const GRASS := Color(0.17, 0.45, 0.19)
const DIRT := Color(0.72, 0.43, 0.24)
const CHALK := Color(0.95, 0.95, 0.9)
const WALL := Color(0.16, 0.22, 0.38)
const WALL_CAP := Color(0.98, 0.72, 0.15)

const SURFACE := preload("res://presentation/stadium/field_surface.gdshader")
const GRASS_TEX := preload("res://assets/third_party/ambientcg/Grass004/Grass004_512_Color.jpg")
const GRASS_NORMAL := preload("res://assets/third_party/ambientcg/Grass004/Grass004_512_NormalGL.jpg")
const DIRT_TEX := preload("res://assets/third_party/ambientcg/Ground037/Ground037_512_Color.jpg")
const DIRT_NORMAL := preload("res://assets/third_party/ambientcg/Ground037/Ground037_512_NormalGL.jpg")

var _tuning: BaseballTuning
var _grass_mat: ShaderMaterial
var _infield_grass_mat: ShaderMaterial
var _dirt_mat: ShaderMaterial
var _park: StadiumDef


## park (optional) dresses the outfield wall: color and style.
func build(tuning: BaseballTuning, park: StadiumDef = null) -> void:
	_tuning = tuning
	_park = park
	for child in get_children():
		child.queue_free()
	_grass_mat = _surface(GRASS, GRASS_TEX, GRASS_NORMAL, 0.385, 2.5, 0.028)
	_grass_mat.set_shader_parameter("stripe_width", 9.0)
	_infield_grass_mat = _surface(GRASS.lightened(0.04), GRASS_TEX, GRASS_NORMAL, 0.385, 2.5, 0.02)
	_dirt_mat = _surface(DIRT, DIRT_TEX, DIRT_NORMAL, 0.556, 3.0, 0.0)
	_dirt_mat.set_shader_parameter("detail_strength", 0.45)
	_add_box("Grass", Vector3(320, 0.1, 320), Vector3(0, -0.06, -110), GRASS).material_override = _grass_mat
	_build_infield()
	_build_foul_lines()
	_build_fence()
	_build_lighting()


func _build_infield() -> void:
	var half := FieldLayout.BASE_DISTANCE / sqrt(2.0)
	var dirt := _add_box("InfieldDirt", Vector3(FieldLayout.BASE_DISTANCE + 6, 0.04, FieldLayout.BASE_DISTANCE + 6), Vector3(0, -0.01, -half), DIRT)
	dirt.rotation_degrees.y = 45.0
	dirt.material_override = _dirt_mat
	# The infield arc: dirt out past the bases, the way a real infield looks.
	_add_disc("InfieldArc", 29.0, Vector3(0, -0.015, -18.4), _dirt_mat, 0.03)
	var grass := _add_box("InfieldGrass", Vector3(FieldLayout.BASE_DISTANCE - 4, 0.05, FieldLayout.BASE_DISTANCE - 4), Vector3(0, 0.0, -half), GRASS.lightened(0.05))
	grass.rotation_degrees.y = 45.0
	grass.material_override = _infield_grass_mat
	# Cutouts around home plate and each bag.
	_add_disc("HomeCircle", 4.0, Vector3(0, 0.035, 0), _dirt_mat)
	for base in [FieldLayout.FIRST, FieldLayout.SECOND, FieldLayout.THIRD]:
		_add_disc("BaseCircle%d" % base, 2.6, FieldLayout.base_position(base) + Vector3(0, 0.035, 0), _dirt_mat)
	var mound := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 2.8
	cyl.height = 0.25
	mound.mesh = cyl
	mound.material_override = _dirt_mat
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
		var length := FieldLayout.fence_distance(side * _tuning.foul_line_angle, _tuning)
		var line := _add_box("FoulLine", Vector3(0.12, 0.03, length), dir * length * 0.5 + Vector3(0, 0.03, 0), CHALK)
		line.look_at_from_position(line.position, line.position + dir, Vector3.UP)
		var pole := _add_box("FoulPole", Vector3(0.3, 14.0, 0.3), dir * length + Vector3(0, 7.0, 0), WALL_CAP)
		pole.name = "FoulPole"


func _build_fence() -> void:
	var segments := 72
	var angle := _tuning.foul_line_angle
	var wall_color := _park.outfield_wall_color if _park != null else WALL
	var cap_color := _park.accent_color if _park != null else WALL_CAP
	var style: StringName = _park.wall_style if _park != null else &"padded"
	var wall_mat: Material = _mat(wall_color)
	match style:
		&"ivy":
			wall_mat = _surface(wall_color, GRASS_TEX, GRASS_NORMAL, 0.385, 1.2, 0.0)
			wall_mat.set_shader_parameter("detail_strength", 1.3)
			wall_mat.set_shader_parameter("vertical_uv", true)
		&"brick":
			wall_mat = _surface(wall_color, DIRT_TEX, DIRT_NORMAL, 0.556, 1.6, 0.0)
			wall_mat.set_shader_parameter("detail_strength", 0.9)
			wall_mat.set_shader_parameter("vertical_uv", true)
		&"iron":
			var iron := _mat(wall_color)
			iron.metallic = 0.55
			iron.roughness = 0.45
			wall_mat = iron
	for i in segments:
		var a0 := lerpf(-angle, angle, float(i) / segments)
		var a1 := lerpf(-angle, angle, float(i + 1) / segments)
		var p0 := FieldLayout.direction_for_spray(a0) * FieldLayout.fence_distance(a0, _tuning)
		var p1 := FieldLayout.direction_for_spray(a1) * FieldLayout.fence_distance(a1, _tuning)
		var mid := (p0 + p1) * 0.5
		var length := p0.distance_to(p1) + 0.2
		var h := FieldLayout.fence_height((a0 + a1) * 0.5, _tuning)
		var wall := _add_box("Wall", Vector3(length, h, 0.5), mid + Vector3(0, h * 0.5, 0), WALL)
		wall.look_at_from_position(wall.position, wall.position + (p1 - p0).cross(Vector3.UP), Vector3.UP)
		wall.material_override = wall_mat
		var cap := _add_box("WallCap", Vector3(length, 0.25, 0.6), mid + Vector3(0, h, 0), cap_color)
		cap.rotation = wall.rotation
		if style == &"iron":
			# Riveted plate seams.
			for band in [0.35, 0.7]:
				var seam := _add_box("Seam", Vector3(length, 0.12, 0.56), mid + Vector3(0, h * band, 0), wall_color.lightened(0.25))
				seam.rotation = wall.rotation
		# Warning track: a band of dirt in front of the wall.
		var inward := -(mid.normalized()) * 2.2
		var track := _add_box("WarningTrack", Vector3(length, 0.02, 4.4), mid + inward + Vector3(0, -0.005, 0), DIRT)
		track.rotation = wall.rotation
		track.material_override = _dirt_mat


func _build_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	# A painted-looking day sky; ambient light comes from it.
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.16, 0.38, 0.74)
	sky_mat.sky_horizon_color = Color(0.62, 0.78, 0.93)
	sky_mat.ground_bottom_color = Color(0.2, 0.3, 0.25)
	sky_mat.ground_horizon_color = Color(0.62, 0.78, 0.93)
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.45
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	add_child(env)


## Flat dirt or grass disc (thin cylinder) at a world position.
func _add_disc(node_name: String, radius: float, pos: Vector3, material: Material, height: float = 0.02) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = 48
	mi.mesh = cyl
	mi.material_override = material
	mi.position = pos
	mi.name = node_name
	add_child(mi)
	return mi


static func _surface(color: Color, tex: Texture2D, normal: Texture2D, mid: float, tile: float, stripes: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SURFACE
	m.set_shader_parameter("base_color", color)
	m.set_shader_parameter("detail", tex)
	m.set_shader_parameter("detail_normal", normal)
	m.set_shader_parameter("detail_mid", mid)
	m.set_shader_parameter("tile", tile)
	m.set_shader_parameter("stripe_strength", stripes)
	return m


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
