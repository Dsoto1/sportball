extends StadiumModule
## A waterfall beyond the outfield: a rock cliff over the stands with
## streams of water spilling down stepped ledges into a pool, lit at night.
## Mirror it for a pair flanking the centerpiece. "style" picks the fall:
## water (streaming), ice (frozen still, pale blue-white) or molten (a
## glowing pour of metal or lava, for forge and volcano parks).

const SHADER := preload("res://presentation/stadium/waterfall.gdshader")


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var k := piece.size
	var style := StringName(piece.param("style"))
	if bool(piece.param("frozen")):
		style = &"ice"
	# Stands on the back rows of the outfield stands, in front of any facade,
	# and rises above it, so the falls frame the centerpiece as on the sheets.
	# Flank the centerpiece rather than cover it (it spans about +-12 deg).
	var angle := piece.angle
	if stadium.def.has_piece(&"centerpiece") and absf(angle) < 15.0:
		angle = 15.0 * (signf(angle) if angle != 0.0 else 1.0)
	var top := stadium.stand_top(angle)
	var base := top.y - 1.0
	var height := float(piece.param("height")) * k + stadium.facade_height(angle)
	var width := float(piece.param("width")) * k
	var spot := stadium.point(angle, top.x - 2.5, base)
	var fall := Node3D.new()
	fall.name = stadium.unique_name("Waterfall")
	stadium.add_child(fall)
	fall.look_at_from_position(spot, spot + (spot - Vector3(0, spot.y, 0)), Vector3.UP)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fall.name)
	# The cliff: a dark rock face with shoulders, boulders breaking up the
	# silhouette along the top and sides, plants and vines on the ledges.
	var rock := def.structure_color.darkened(0.3).lerp(Color(0.36, 0.34, 0.32), 0.6)
	if style == &"molten":
		rock = Color(0.16, 0.13, 0.12)
	elif style == &"ice":
		rock = Color(0.4, 0.46, 0.56)
	var face := stadium.box(Vector3(width + 4.0, height, 5.0), rock, fall, &"rock")
	face.position = Vector3(0, height * 0.5, -2.5)
	for side: float in [-1.0, 1.0]:
		var shoulder := stadium.box(Vector3(3.5, height * 0.8, 6.0), rock.darkened(0.15), fall, &"rock")
		shoulder.position = Vector3(side * (width * 0.5 + 2.6), height * 0.4, -1.5)
		shoulder.rotation.y = side * 0.25
	var rock_mat := stadium.surface_mat(&"rock", rock)
	var boulders: Array[Vector3] = []
	for i in 5:
		var x := lerpf(-width * 0.5 - 2.5, width * 0.5 + 2.5, i / 4.0)
		boulders.append(Vector3(x, height - 1.0, -2.0 + rng.randf_range(-0.5, 0.5)))
	for side: float in [-1.0, 1.0]:
		for i in 3:
			boulders.append(Vector3(side * (width * 0.5 + 3.2), height * (0.2 + 0.28 * i), 0.0))
	for p in boulders:
		var b := ModelKit.spawn(&"rock", rng.randf_range(4.0, 8.0) * k, rng)
		b.position = p
		b.rotation.y = rng.randf() * TAU
		for mi: MeshInstance3D in b.find_children("*", "MeshInstance3D", true, false):
			mi.material_override = rock_mat
		fall.add_child(b)
	var water := ShaderMaterial.new()
	water.shader = SHADER
	match style:
		&"ice":
			water.set_shader_parameter("color", Color(0.5, 0.76, 0.98))
			water.set_shader_parameter("foam", Color(0.94, 0.98, 1.0))
			water.set_shader_parameter("flow", 0.0)
			water.set_shader_parameter("glow", 0.25)
		&"molten":
			water.set_shader_parameter("color", Color(0.95, 0.24, 0.03))
			water.set_shader_parameter("foam", Color(1.0, 0.62, 0.15))
			water.set_shader_parameter("flow", 0.35)
			water.set_shader_parameter("glow", 1.1)
		_:
			water.set_shader_parameter("color", Color(0.36, 0.68, 0.94))
			water.set_shader_parameter("glow", 0.8 if def.night else 0.35)
	var foam_color := Color(1.0, 0.75, 0.3) if style == &"molten" else Color(0.92, 0.97, 1.0)
	# Three tiers, each stepping forward to a ledge; wide falls split into
	# two streams around a rock spur, as on the sheets.
	var tiers := 3
	var streams := 2 if width >= 8.0 else 1
	for t in tiers:
		var y0 := height * float(tiers - 1 - t) / tiers
		var y1 := height * float(tiers - t) / tiers
		var forward := t * 1.4
		var w := width * (1.0 - 0.12 * t)
		var gap := 1.6 * k if streams > 1 else 0.0
		var sw := (w - gap * (streams - 1)) / streams
		for s in streams:
			var x := -w * 0.5 + sw * 0.5 + s * (sw + gap)
			var sheet := MeshInstance3D.new()
			var quad := QuadMesh.new()
			quad.size = Vector2(sw, y1 - y0 + 0.6)
			sheet.mesh = quad
			sheet.material_override = water
			sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			sheet.position = Vector3(x, (y0 + y1) * 0.5, 0.3 + forward)
			fall.add_child(sheet)
			var foam := stadium.box(Vector3(sw + 0.4, 0.5, 1.2), foam_color, fall)
			foam.position = Vector3(x, y0 + 0.4, 1.4 + forward)
			foam.material_override = Stadium.glow(foam_color, 1.5 if style == &"molten" else 0.4)
		if streams > 1:
			var spur := stadium.box(Vector3(gap + 0.4, y1 - y0, 2.0), rock.darkened(0.1), fall, &"rock")
			spur.position = Vector3(0, (y0 + y1) * 0.5, forward)
		var ledge := stadium.box(Vector3(w + 1.6, 0.9, 2.2), rock.lightened(0.05), fall, &"rock")
		ledge.position = Vector3(0, y0, 1.0 + forward)
		if style == &"water":
			for b in 4:
				var bush := Scenery.sphere(fall, 1.0 + 0.3 * (b % 3), Color(0.22, 0.5, 0.25).darkened(0.08 * b), 0.8)
				var side := 1.0 if b % 2 == 0 else -1.0
				bush.position = Vector3((w * 0.5 + 0.6 + 0.9 * (b / 2)) * side, y0 + 0.9, 1.0 + forward)
	# Vines hanging off the lip either side of the water.
	if style == &"water":
		var vine := Color(0.2, 0.45, 0.22)
		for i in 6:
			var side := -1.0 if i % 2 == 0 else 1.0
			var length := rng.randf_range(0.25, 0.55) * height
			var v := stadium.box(Vector3(0.5, length, 0.3), vine.darkened(rng.randf() * 0.2), fall)
			v.position = Vector3(side * (width * 0.5 + 0.4 + 0.8 * (i / 2)), height - length * 0.5, 0.2)
	if style != &"ice":
		var mist := CPUParticles3D.new()
		mist.amount = 20
		mist.lifetime = 3.0
		mist.preprocess = 3.0
		mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		mist.emission_box_extents = Vector3(width * 0.5, 0.3, 0.6)
		mist.direction = Vector3(0, 1, 0.4)
		mist.spread = 30.0
		mist.initial_velocity_min = 1.0
		mist.initial_velocity_max = 2.5
		mist.gravity = Vector3.ZERO
		mist.scale_amount_min = 1.5
		mist.scale_amount_max = 3.0
		var puff := SphereMesh.new()
		puff.radial_segments = 8
		puff.rings = 4
		mist.mesh = puff
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.3, 0.25, 0.22, 0.35) if style == &"molten" else Color(0.95, 0.98, 1.0, 0.3)
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mist.material_override = mm
		mist.position = Vector3(0, 0.8, 3.0 + tiers * 1.4)
		fall.add_child(mist)
	if style == &"molten":
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.5, 0.15)
		light.light_energy = 3.0
		light.omni_range = width * 2.5
		light.position = Vector3(0, height * 0.4, 6.0)
		fall.add_child(light)
	var pool := stadium.box(Vector3(width + 6.0, 0.8, 7.0), rock if style == &"molten" else def.structure_color, fall, &"stone")
	pool.position = Vector3(0, 0.4, 3.0 + tiers * 1.4)
	var surface := stadium.box(Vector3(width + 5.0, 0.1, 6.0), Stadium.WATER, fall)
	surface.position = Vector3(0, 0.82, 3.0 + tiers * 1.4)
	surface.material_override = water
