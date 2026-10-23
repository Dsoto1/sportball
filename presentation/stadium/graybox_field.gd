class_name GrayboxField
extends Node3D
## Primitive-mesh field built from FieldLayout + tuning. Changing it never
## changes baseball rules. Grass and dirt use the field surface shader:
## project palette colors with CC0 ambientCG texture as subtle detail.

const GRASS := Color(0.13, 0.38, 0.13)
const TURF := Color(0.07, 0.4, 0.2)
const DIRT := Color(0.64, 0.37, 0.22)
const FOUL_POLE := Color(1.0, 0.8, 0.1)
const CHALK := Color(0.95, 0.95, 0.9)
const WALL := Color(0.16, 0.22, 0.38)
const WALL_CAP := Color(0.98, 0.72, 0.15)
## StadiumDef.mowing names, in the field shader's pattern order (from 1).
const MOWING := ["checker", "diamond", "stripes", "diagonal", "rings", "sunburst", "plain"]
## The field's layers, each well clear of the one under it (the camera's
## depth buffer keeps 3+ cm apart clean from the stands): tops in m.
const GRASS_TOP := 0.0
const TRACK_TOP := 0.03
const ARC_TOP := 0.04
const DIRT_TOP := 0.06
const INFIELD_GRASS_TOP := 0.09
const CUTOUT_TOP := 0.12
const CHALK_TOP := 0.15

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
	var turf := park != null and park.turf
	# Turf: a brighter, flatter green in crisp 5-yard seams instead of mowing.
	var grass := TURF if turf else GRASS
	if park != null and park.grass_color.a > 0.0 and not turf:
		grass = park.grass_color
	var dirt := park.dirt_color if park != null and park.dirt_color.a > 0.0 else DIRT
	var pattern := MOWING.find(park.mowing if park != null else "checker") + 1
	_grass_mat = _surface(grass, GRASS_TEX, GRASS_NORMAL, 0.385, 2.5, 0.05 if turf else 0.07)
	_grass_mat.set_shader_parameter("stripe_width", 4.57 if turf else (park.mowing_width if park != null else 9.0))
	_grass_mat.set_shader_parameter("pattern", 3 if turf else pattern)
	_infield_grass_mat = _surface(grass.lightened(0.04), GRASS_TEX, GRASS_NORMAL, 0.385, 2.5, 0.05 if turf else 0.06)
	# The infield: its own finer cut (a checker on most, the turf's seams on turf).
	_infield_grass_mat.set_shader_parameter("stripe_width", 4.57 if turf else 3.0)
	_infield_grass_mat.set_shader_parameter("pattern", 3 if turf else (0 if pattern == 7 else 1))
	if turf:
		for m in [_grass_mat, _infield_grass_mat]:
			m.set_shader_parameter("detail_strength", 0.25)
	_dirt_mat = _surface(dirt, DIRT_TEX, DIRT_NORMAL, 0.556, 3.0, 0.0)
	_dirt_mat.set_shader_parameter("pattern", 0)
	_dirt_mat.set_shader_parameter("detail_strength", 0.45)
	_add_box("Grass", Vector3(320, 0.1, 320), Vector3(0, GRASS_TOP - 0.05, -110), GRASS).material_override = _grass_mat
	_build_infield()
	_build_foul_lines()
	_build_fence()
	_build_lighting()


func _build_infield() -> void:
	var half := FieldLayout.BASE_DISTANCE / sqrt(2.0)
	var dirt := _add_box("InfieldDirt", Vector3(FieldLayout.BASE_DISTANCE + 6, 0.04, FieldLayout.BASE_DISTANCE + 6), Vector3(0, DIRT_TOP - 0.02, -half), DIRT)
	dirt.rotation_degrees.y = 45.0
	dirt.material_override = _dirt_mat
	# The infield arc: dirt out past the bases, the way a real infield looks.
	_add_disc("InfieldArc", 29.0, Vector3(0, ARC_TOP - 0.015, -18.4), _dirt_mat, 0.03)
	var grass := _add_box("InfieldGrass", Vector3(FieldLayout.BASE_DISTANCE - 4, 0.05, FieldLayout.BASE_DISTANCE - 4), Vector3(0, INFIELD_GRASS_TOP - 0.025, -half), GRASS.lightened(0.05))
	grass.rotation_degrees.y = 45.0
	grass.material_override = _infield_grass_mat
	# Cutouts around home plate and each bag.
	_add_disc("HomeCircle", 4.0, Vector3(0, CUTOUT_TOP - 0.01, 0), _dirt_mat)
	for base in [FieldLayout.FIRST, FieldLayout.SECOND, FieldLayout.THIRD]:
		_add_disc("BaseCircle%d" % base, 2.6, FieldLayout.base_position(base) + Vector3(0, CUTOUT_TOP - 0.01, 0), _dirt_mat)
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
	_build_home_plate()
	_build_batters_boxes()
	for base in [FieldLayout.FIRST, FieldLayout.SECOND, FieldLayout.THIRD]:
		var bag := _add_box("Base%d" % base, Vector3(0.6, 0.12, 0.6), FieldLayout.base_position(base) + Vector3(0, CHALK_TOP + 0.0, 0), CHALK)
		bag.rotation_degrees.y = 45.0


## Home plate to the rulebook: a five-sided slab of whitened rubber, 17 in
## across the front (facing the pitcher), 8.5 in down each side, and two
## 12 in edges meeting at the point toward the catcher, with a beveled
## black rubber rim, set flush in its dirt cutout.
func _build_home_plate() -> void:
	var w := 0.2159  # half of 17 in
	var outline := [Vector2(-w, -w), Vector2(w, -w), Vector2(w, 0.0), Vector2(0.0, w), Vector2(-w, 0.0)]
	for layer: Array in [[1.08, CHALK_TOP - 0.005, Color(0.08, 0.08, 0.09)], [1.0, CHALK_TOP + 0.012, CHALK]]:
		var scale: float = layer[0]
		var top: float = layer[1]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var center := Vector3(0, top, 0.0)
		for i in outline.size():
			var a: Vector2 = outline[i] * scale
			var b: Vector2 = outline[(i + 1) % outline.size()] * scale
			# Top, then the sloped edge down to the dirt.
			st.set_normal(Vector3.UP)
			st.add_vertex(center)
			st.add_vertex(Vector3(b.x, top, b.y))
			st.add_vertex(Vector3(a.x, top, a.y))
			var out_a := Vector3(a.x, 0.0, a.y) * 1.04
			var out_b := Vector3(b.x, 0.0, b.y) * 1.04
			for v: Vector3 in [Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), out_b, Vector3(a.x, top, a.y), out_b, out_a]:
				st.add_vertex(v)
		st.generate_normals()
		var mi := MeshInstance3D.new()
		mi.name = "HomePlate" if scale == 1.0 else "HomePlateRim"
		mi.mesh = st.commit()
		var m := _mat(layer[2])
		m.roughness = 0.6
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		add_child(mi)


## The batter's boxes and catcher's box in chalk, as on a real field: each
## batter's box 4 ft wide and 6 ft long, its inside line 6 in off the
## plate, centered on the plate's middle; the catcher's box behind. Every
## batting stance's feet, stride included, land inside them.
func _build_batters_boxes() -> void:
	var line := 0.076  # 3 in chalk
	var inside := 0.2159 + 0.1524
	var width := 1.2192
	var length := 1.8288
	# Centered on the plate's middle: the same box BattingStyles keeps every
	# stance's feet in (BOX_TOWARD_PITCHER / BOX_TOWARD_CATCHER from the
	# batter's spot).
	var mid_z := 0.0
	for side: float in [-1.0, 1.0]:
		var x0 := side * inside
		var x1 := side * (inside + width)
		var xm := (x0 + x1) * 0.5
		for z: float in [mid_z - length * 0.5, mid_z + length * 0.5]:
			_add_box("BoxLine", Vector3(width + line, 0.012, line), Vector3(xm, CHALK_TOP - 0.004, z), CHALK)
		for x: float in [x0, x1]:
			_add_box("BoxLine", Vector3(line, 0.012, length), Vector3(x, CHALK_TOP - 0.004, mid_z), CHALK)
	# The catcher's box: 43 in wide, running 8 ft back from the boxes.
	var back := mid_z + length * 0.5
	for x: float in [-0.546, 0.546]:
		_add_box("CatcherBox", Vector3(line, 0.012, 2.44), Vector3(x, CHALK_TOP - 0.004, back + 1.22), CHALK)


func _build_foul_lines() -> void:
	for side in [-1.0, 1.0]:
		var dir := FieldLayout.direction_for_spray(side * _tuning.foul_line_angle)
		var length := FieldLayout.fence_distance(side * _tuning.foul_line_angle, _tuning)
		var line := _add_box("FoulLine", Vector3(0.12, 0.03, length), dir * length * 0.5 + Vector3(0, CHALK_TOP - 0.015, 0), CHALK)
		line.look_at_from_position(line.position, line.position + dir, Vector3.UP)
		# Yellow, standing well above the wall, with a screen fin on the fair side.
		var tall := FieldLayout.fence_height(side * _tuning.foul_line_angle, _tuning) + 13.0
		var pole := _add_box("FoulPole", Vector3(0.35, tall, 0.35), dir * length + Vector3(0, tall * 0.5, 0), FOUL_POLE)
		pole.name = "FoulPole"
		var fair := (FieldLayout.direction_for_spray(side * (_tuning.foul_line_angle - 5.0)) - dir).normalized()
		var fin := _add_box("FoulPoleScreen", Vector3(0.06, tall * 0.6, 1.1), pole.position + fair * 0.6 + Vector3(0, tall * 0.15, 0), FOUL_POLE)
		fin.look_at_from_position(fin.position, fin.position + fair, Vector3.UP)


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
		&"brick", &"stone", &"wood", &"rock", &"marble":
			wall_mat = StadiumSurfaces.material(style, wall_color, false, 0.6)
		&"iron":
			wall_mat = StadiumSurfaces.material(&"steel", wall_color, false, 0.7)
		&"ice":
			wall_mat = StadiumSurfaces.material(&"marble", wall_color.lerp(Color(0.8, 0.92, 1.0), 0.5), false, 0.8)
		&"glass":
			var glass := StandardMaterial3D.new()
			glass.albedo_color = Color(wall_color.lerp(Color(0.2, 0.7, 0.8), 0.5), 0.6)
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			glass.emission_enabled = true
			glass.emission = wall_color.lerp(Color(0.2, 0.7, 0.8), 0.6)
			glass.emission_energy_multiplier = 0.7
			glass.roughness = 0.05
			wall_mat = glass
	var cap_mat: Material = _mat(cap_color)
	if style == &"neon":
		cap_mat = Stadium.glow(cap_color, 2.2)
	var stripe := _park.wall_stripe if _park != null else Color(0, 0, 0, 0)
	var stripe_mat: Material = null
	if stripe.a > 0.0:
		stripe_mat = Stadium.glow(stripe, _park.wall_stripe_glow) if _park.wall_stripe_glow > 0.0 else _mat(stripe)
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
		cap.material_override = cap_mat
		if stripe_mat != null:
			var band := _add_box("WallStripe", Vector3(length, minf(0.3, h * 0.1), 0.54), mid + Vector3(0, h * 0.68, 0), stripe)
			band.rotation = wall.rotation
			band.material_override = stripe_mat
		if style in [&"padded", &"neon"] and i % 2 == 0:
			# Pad seams.
			var seam := _add_box("PadSeam", Vector3(0.08, h * 0.96, 0.54), p0 + Vector3(0, h * 0.5, 0), wall_color.darkened(0.35))
			seam.rotation = wall.rotation
		if style == &"ice":
			for k in 3:
				var icicle := MeshInstance3D.new()
				var cone := CylinderMesh.new()
				cone.top_radius = 0.12
				cone.bottom_radius = 0.0
				cone.height = 0.5 + 0.4 * ((i + k) % 3)
				icicle.mesh = cone
				icicle.material_override = Stadium.glow(Color(0.85, 0.95, 1.0), 0.3)
				icicle.position = p0.lerp(p1, (k + 0.5) / 3.0) + Vector3(0, h - cone.height * 0.5, 0) - mid.normalized() * 0.3
				add_child(icicle)
		if style == &"iron":
			# Riveted plate seams.
			for band in [0.35, 0.7]:
				var seam := _add_box("Seam", Vector3(length, 0.12, 0.56), mid + Vector3(0, h * band, 0), wall_color.lightened(0.25))
				seam.rotation = wall.rotation
		# Warning track: a band of dirt in front of the wall.
		var inward := -(mid.normalized()) * 2.2
		var track := _add_box("WarningTrack", Vector3(length, 0.02, 4.4), mid + inward + Vector3(0, TRACK_TOP - 0.01, 0), DIRT)
		track.rotation = wall.rotation
		track.material_override = _dirt_mat


## Day: sun and a painted sky. Night: floodlights from high over the
## infield under a dark sky, with glow so the lamps bloom. Dome: the same
## floods, brighter fill, no sky at all.
## Sky looks, from the parks' sheets: [sky top, horizon, sun color, sun
## elevation (deg), sun yaw (deg), sun energy, ambient energy]. The sun
## stays behind home plate, as on the sheets, so the field is lit warm
## from the batter's side.
const SKIES := {
	&"day": [Color(0.2, 0.45, 0.82), Color(0.72, 0.84, 0.95), Color(1.0, 0.98, 0.94), -55.0, 35.0, 1.15, 0.45],
	&"golden": [Color(0.3, 0.46, 0.78), Color(1.0, 0.76, 0.5), Color(1.0, 0.86, 0.66), -34.0, 25.0, 1.2, 0.45],
	&"sunset": [Color(0.32, 0.24, 0.55), Color(1.0, 0.58, 0.4), Color(1.0, 0.78, 0.6), -26.0, 15.0, 1.1, 0.5],
	&"dusk": [Color(0.1, 0.1, 0.3), Color(0.95, 0.5, 0.45), Color(1.0, 0.7, 0.55), -12.0, 10.0, 0.35, 0.45],
	&"underwater": [Color(0.02, 0.18, 0.3), Color(0.1, 0.55, 0.62), Color(0.7, 0.95, 1.0), -70.0, 20.0, 0.9, 0.6],
	&"night": [Color(0.01, 0.015, 0.05), Color(0.09, 0.1, 0.2), Color(1.0, 0.96, 0.88), -72.0, 15.0, 0.0, 0.4],
}


## The park's sky (see SKIES) and its light: the sun low and warm at golden
## hour and sunset; floodlights (and a softer fill) whenever the lights are
## on, at dusk and night, with glow so lamps bloom. Dome: floods, no sky.
func _build_lighting() -> void:
	var lights_on := _park != null and _park.night
	var roof := _park != null and _park.is_roofed()
	var kind: StringName = _park.sky_kind() if _park != null else &"day"
	var look: Array = SKIES.get(kind, SKIES[&"day"])
	if float(look[5]) > 0.0 and not roof:
		var sun := DirectionalLight3D.new()
		sun.name = "Sun"
		sun.rotation_degrees = Vector3(look[3], look[4], 0)
		sun.light_energy = look[5]
		sun.light_color = look[2]
		sun.shadow_enabled = not lights_on
		add_child(sun)
	if lights_on or roof:
		var flood := DirectionalLight3D.new()
		flood.name = "Floodlights"
		flood.rotation_degrees = Vector3(-72, 15, 0)
		flood.light_energy = 1.0 if kind == &"night" or roof else 0.75
		flood.light_color = Color(1.0, 0.96, 0.88)
		flood.shadow_enabled = true
		flood.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
		add_child(flood)
		var fill := DirectionalLight3D.new()
		fill.name = "FloodFill"
		fill.rotation_degrees = Vector3(-60, 200, 0)
		fill.light_energy = 0.45
		fill.light_color = Color(0.92, 0.95, 1.0)
		fill.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
		add_child(fill)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = look[0]
	sky_mat.sky_horizon_color = look[1]
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = (look[1] as Color).darkened(0.7)
	sky_mat.ground_horizon_color = look[1]
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	# Ambient from a soft neutral of the horizon, not the blue sky dome, so
	# the grass stays green rather than mint.
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = (look[1] as Color).lerp(Color(0.85, 0.85, 0.8), 0.6)
	environment.ambient_light_energy = look[6]
	if lights_on or roof:
		environment.glow_enabled = true
		environment.glow_intensity = 0.6
		environment.glow_hdr_threshold = 1.2
	if kind == &"night" or roof:
		environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.ambient_light_color = Color(0.55, 0.6, 0.75) if not roof else Color(0.7, 0.7, 0.75)
		environment.ambient_light_energy = 0.4 if not roof else 0.5
	if roof:
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color(0.05, 0.05, 0.07)
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.06
	environment.adjustment_contrast = 1.06
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
