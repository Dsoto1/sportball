extends StadiumModule
## A waterfall beyond the outfield, standing on the back of the outfield
## stands and rising above the facade. Mirror it for a pair flanking the
## centerpiece. "style" picks the fall:
## - water: a natural gorge of piled boulders, streams wandering down
##   uneven ledges, foam and mist where they land, bushes and vines.
## - terrace: formal stepped marble basins with balustrades, each spilling
##   a sheet into the wider one below, urns and flowers, for garden parks.
## - ice: the gorge frozen still. molten: the gorge pouring glowing metal.
## "greenery" tints the plants; "tree" picks the trees on the rim.

const SHADER := preload("res://presentation/stadium/waterfall.gdshader")


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var k := piece.size
	var style := StringName(piece.param("style"))
	if bool(piece.param("frozen")):
		style = &"ice"
	# Flank the centerpiece rather than cover it (it spans about +-12 deg).
	var angle := piece.angle
	if def.has_piece(&"centerpiece") and absf(angle) < 15.0:
		angle = 15.0 * (signf(angle) if angle != 0.0 else 1.0)
	var top := stadium.stand_top(angle)
	var height := float(piece.param("height")) * k + stadium.facade_height(angle)
	var width := float(piece.param("width")) * k
	var spot := stadium.point(angle, top.x - 2.5, top.y - 1.0)
	var fall := Node3D.new()
	fall.name = stadium.unique_name("Waterfall")
	stadium.add_child(fall)
	fall.look_at_from_position(spot, spot + (spot - Vector3(0, spot.y, 0)), Vector3.UP)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(def.id) + fall.name)
	var water := _water(style, def.night)
	var green := Color(piece.param("greenery"))
	if style == &"terrace":
		_terrace(stadium, fall, width, height, water, green, rng)
	else:
		_gorge(stadium, fall, style, width, height, water, green, StringName(piece.param("tree")), rng)


static func _water(style: StringName, night: bool) -> ShaderMaterial:
	var water := ShaderMaterial.new()
	water.shader = SHADER
	match style:
		&"ice":
			water.set_shader_parameter("color", Color(0.5, 0.76, 0.98))
			water.set_shader_parameter("foam", Color(0.9, 0.96, 1.0))
			water.set_shader_parameter("flow", 0.0)
			water.set_shader_parameter("glow", 0.25)
		&"molten":
			water.set_shader_parameter("color", Color(0.95, 0.24, 0.03))
			water.set_shader_parameter("foam", Color(1.0, 0.62, 0.15))
			water.set_shader_parameter("flow", 0.35)
			water.set_shader_parameter("glow", 1.1)
		_:
			water.set_shader_parameter("color", Color(0.3, 0.62, 0.92))
			water.set_shader_parameter("glow", 0.8 if night else 0.3)
	return water


## A falling sheet from y_top down to y_bottom, leaning back a touch, with a
## short pour curving over the lip above it.
static func _sheet(parent: Node3D, water: Material, x: float, z: float, w: float, y_top: float, y_bottom: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(w, y_top - y_bottom + 0.4)
	var sheet := MeshInstance3D.new()
	sheet.mesh = quad
	sheet.material_override = water
	sheet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sheet.position = Vector3(x, (y_top + y_bottom) * 0.5, z)
	sheet.rotation.x = -0.06
	parent.add_child(sheet)
	var lq := QuadMesh.new()
	lq.size = Vector2(w * 0.96, 1.4)
	var lip := MeshInstance3D.new()
	lip.mesh = lq
	lip.material_override = water
	lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lip.position = Vector3(x, y_top + 0.35, z - 0.55)
	lip.rotation.x = -1.0
	parent.add_child(lip)


## White water churning where a stream lands, and spray rising off it.
static func _splash(parent: Node3D, x: float, y: float, z: float, w: float, color: Color, rng: RandomNumberGenerator, glow: float) -> void:
	var mat := Stadium.glow(color, glow)
	for i in maxi(3, int(w / 1.2)):
		var puff := Scenery.sphere(parent, rng.randf_range(0.6, 1.1), color, 0.5)
		puff.position = Vector3(x + rng.randf_range(-0.5, 0.5) * w, y + 0.2, z + rng.randf_range(0.2, 1.0))
		puff.material_override = mat
	var mist := CPUParticles3D.new()
	mist.amount = 12
	mist.lifetime = 2.5
	mist.preprocess = 2.5
	mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mist.emission_box_extents = Vector3(w * 0.5, 0.3, 0.5)
	mist.direction = Vector3(0, 1, 0.5)
	mist.spread = 35.0
	mist.initial_velocity_min = 0.8
	mist.initial_velocity_max = 2.0
	mist.gravity = Vector3.ZERO
	mist.scale_amount_min = 1.0
	mist.scale_amount_max = 2.2
	var ball := SphereMesh.new()
	ball.radial_segments = 8
	ball.rings = 4
	mist.mesh = ball
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(color, 0.28)
	mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mist.material_override = mm
	mist.position = Vector3(x, y + 0.6, z + 0.8)
	parent.add_child(mist)


## A faceted low-poly boulder: a coarse sphere squashed and turned at
## random, wider than tall, so piles of them read as a broken cliff.
static func _rock(parent: Node3D, mat: Material, p: Vector3, size: float, rng: RandomNumberGenerator) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = rng.randi_range(5, 7)
	mesh.rings = 3
	var r := MeshInstance3D.new()
	r.mesh = mesh
	r.material_override = mat
	r.scale = Vector3(rng.randf_range(1.2, 1.8), rng.randf_range(0.7, 1.0), rng.randf_range(1.0, 1.4)) * size
	r.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.3, 0.3))
	r.position = p + Vector3(0, size * 0.35, 0)
	parent.add_child(r)


static func _gorge(stadium: Stadium, fall: Node3D, style: StringName, width: float, height: float, water: Material, green: Color, tree_kind: StringName, rng: RandomNumberGenerator) -> void:
	var rock := stadium.def.structure_color.darkened(0.35).lerp(Color(0.4, 0.38, 0.36), 0.8)
	if style == &"molten":
		rock = Color(0.16, 0.13, 0.12)
	elif style == &"ice":
		rock = Color(0.4, 0.46, 0.56)
	var lush := style == &"water"
	var mat := stadium.surface_mat(&"rock", rock)
	var dark := stadium.surface_mat(&"rock", rock.darkened(0.25))
	# A dark backing so no sky shows through the gaps between boulders.
	var back := stadium.box(Vector3(width + 8.0, height * 0.92, 3.0), rock.darkened(0.4), fall, &"rock")
	back.position = Vector3(0, height * 0.46, -4.0)
	# Boulders piled into the gorge walls: behind the water in the channel,
	# in front of it either side, the walls rising a little toward the edges.
	var half := width * 0.5
	var edge := half + 5.5
	var x := -edge
	while x <= edge + 0.1:
		var outside := absf(x) > half
		var top := height * (1.0 + (0.12 * (absf(x) - half) / 5.5 if outside else 0.0)) + rng.randf_range(-1.5, 1.0)
		var y := 0.0
		while y < top:
			var size := rng.randf_range(3.2, 5.4)
			var z := rng.randf_range(-1.0, 1.8) if outside else -2.8
			_rock(fall, mat if rng.randf() < 0.7 else dark, Vector3(x + rng.randf_range(-1.4, 1.4), y, z), size, rng)
			y += size * rng.randf_range(0.35, 0.55)
		x += 2.6
	# The water wanders down uneven ledges: each tier's streams sit a little
	# off the last, one or two of them, never quite the same width.
	var tiers := 3 if height < 34.0 else 4
	var foam := Color(1.0, 0.75, 0.3) if style == &"molten" else Color(0.93, 0.97, 1.0)
	var drift := 0.0
	for t in tiers:
		var y_top := height * float(tiers - t) / tiers
		var y_bottom := height * float(tiers - 1 - t) / tiers
		var z := 0.4 + t * 1.5
		var streams := 1 if width < 7.0 or t == 0 or rng.randf() < 0.5 else 2
		drift = clampf(drift + rng.randf_range(-0.08, 0.08) * width, -half * 0.15, half * 0.15)
		var span := width * (0.85 - 0.08 * t)
		var cuts: Array[float] = [0.0, 1.0]
		if streams == 2:
			cuts = [0.0, rng.randf_range(0.4, 0.6), 1.0]
		for s in streams:
			var gap := 0.9 if streams == 2 else 0.0
			var x0 := -span * 0.5 + span * cuts[s] + (gap * 0.5 if s > 0 else 0.0)
			var x1 := -span * 0.5 + span * cuts[s + 1] - (gap * 0.5 if s < streams - 1 else 0.0)
			var w := (x1 - x0) * rng.randf_range(0.75, 1.0)
			var cx := drift + (x0 + x1) * 0.5
			_sheet(fall, water, cx, z, w, y_top, y_bottom)
			if style != &"ice":
				_splash(fall, cx, y_bottom, z, w, foam, rng, 1.5 if style == &"molten" else 0.35)
		# The ledge each tier lands on: a few boulders, bigger at its ends.
		if t < tiers - 1:
			for i in 3:
				_rock(fall, mat, Vector3(drift + (i - 1) * span * 0.3, y_bottom - 1.2, z + 0.6), rng.randf_range(1.8, 2.6), rng)
		for side: float in [-1.0, 1.0]:
			_rock(fall, mat, Vector3(drift + side * (span * 0.5 + 1.2), y_bottom, z + 1.0), rng.randf_range(2.5, 4.0), rng)
			if lush:
				var bush := ModelKit.spawn(&"bush", rng.randf_range(1.6, 2.6), rng, green)
				bush.position = Vector3(drift + side * (span * 0.5 + rng.randf_range(0.2, 1.6)), y_bottom + 0.6, z + 1.6)
				fall.add_child(bush)
	if lush:
		# Bushes along the rim, a tree at each shoulder, vines down the walls.
		for i in 7:
			var bush := ModelKit.spawn(&"bush", rng.randf_range(2.0, 3.4), rng, green.darkened(rng.randf() * 0.2))
			bush.position = Vector3(rng.randf_range(-edge, edge), height + rng.randf_range(-1.0, 1.5), rng.randf_range(-2.0, 1.0))
			fall.add_child(bush)
		for side: float in [-1.0, 1.0]:
			# Plain trees take the greenery tint, blossoms go pink.
			var leaf: Color = {&"round": green, &"blossom": Color(0.97, 0.68, 0.82)}.get(tree_kind, Color(0, 0, 0, 0))
			var tree := ModelKit.spawn(tree_kind, rng.randf_range(7.0, 10.0), rng, leaf)
			tree.position = Vector3(side * (edge - 1.0), height + 0.5, -1.0)
			fall.add_child(tree)
		# Moss on the boulders either side of the channel.
		for i in 16:
			var side := -1.0 if i % 2 == 0 else 1.0
			var moss := Scenery.sphere(fall, rng.randf_range(0.9, 1.6), green.darkened(rng.randf() * 0.3), 0.35)
			moss.position = Vector3(side * rng.randf_range(half + 0.5, edge), rng.randf_range(0.15, 0.95) * height, rng.randf_range(1.2, 2.6))
		for i in 10:
			var side := -1.0 if i % 2 == 0 else 1.0
			var length := rng.randf_range(0.15, 0.45) * height
			var v := stadium.box(Vector3(0.45, length, 0.3), green.darkened(0.2 + rng.randf() * 0.25), fall)
			v.position = Vector3(side * (half + rng.randf_range(0.4, 4.0)), height - length * 0.5 - rng.randf() * 3.0, 1.7)
	if style == &"molten":
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.5, 0.15)
		light.light_energy = 3.0
		light.omni_range = width * 2.5
		light.position = Vector3(0, height * 0.4, 6.0)
		fall.add_child(light)
	# The plunge pool, ringed with boulders.
	var pool_z := 0.4 + tiers * 1.5 + 1.5
	var pq := QuadMesh.new()
	pq.size = Vector2(width + 3.0, 4.0)
	var pool := MeshInstance3D.new()
	pool.mesh = pq
	pool.material_override = water
	pool.rotation.x = -PI * 0.5
	pool.position = Vector3(0, 0.5, pool_z)
	fall.add_child(pool)
	var x2 := -half - 2.0
	while x2 <= half + 2.0:
		_rock(fall, mat, Vector3(x2, -0.5, pool_z + 2.3), rng.randf_range(1.6, 2.6), rng)
		x2 += 2.2


static func _terrace(stadium: Stadium, fall: Node3D, width: float, height: float, water: Material, green: Color, rng: RandomNumberGenerator) -> void:
	var marble := stadium.def.structure_color.lerp(Color(0.93, 0.91, 0.86), 0.6)
	var trim := marble.lightened(0.25)
	# The back wall: pilasters and a cornice, urns along the top.
	var wall_w := width + 8.0
	var wall := stadium.box(Vector3(wall_w, height, 2.0), marble.darkened(0.08), fall, &"marble")
	wall.position = Vector3(0, height * 0.5, -3.5)
	var cornice := stadium.box(Vector3(wall_w + 1.0, 1.0, 2.8), trim, fall, &"marble")
	cornice.position = Vector3(0, height + 0.5, -3.3)
	var pilasters := int(wall_w / 3.5)
	for i in pilasters + 1:
		var px := -wall_w * 0.5 + wall_w * i / pilasters
		var pil := stadium.box(Vector3(0.9, height, 0.6), trim, fall, &"marble")
		pil.position = Vector3(px, height * 0.5, -2.3)
		# A ball finial on each pilaster, an arched niche between them.
		var finial := Scenery.sphere(fall, 0.55, trim)
		finial.position = Vector3(px, height + 1.5, -2.9)
		if i < pilasters:
			var nx := px + wall_w * 0.5 / pilasters
			var niche_w := wall_w / pilasters - 1.6
			var niche_h := height * 0.3
			var niche := stadium.box(Vector3(niche_w, niche_h, 0.3), green.darkened(0.55), fall)
			niche.position = Vector3(nx, height * 0.6, -2.45)
			var arch := Scenery.cylinder(fall, niche_w * 0.5, niche_w * 0.5, 0.3, green.darkened(0.55), 12)
			arch.rotation.x = PI * 0.5
			arch.position = Vector3(nx, height * 0.6 + niche_h * 0.5, -2.45)
	# Basins step down and widen toward the field; each spills a sheet off
	# its lip into the next, the lowest into the pool at the foot.
	var tiers := 4
	var flowers := [Color(0.97, 0.66, 0.8), Color(1.0, 1.0, 1.0), Color(0.86, 0.5, 0.75)]
	for t in tiers:
		var y := height * float(tiers - 1 - t) / tiers
		var y_next := height * float(tiers - 2 - t) / tiers if t < tiers - 1 else -1.4
		var w := width * (0.55 + 0.15 * t)
		var z := -1.6 + t * 2.4
		var basin := stadium.box(Vector3(w + 1.2, 1.4, 2.6), marble, fall, &"marble")
		basin.position = Vector3(0, y + 0.7, z)
		var coping := stadium.box(Vector3(w + 1.6, 0.3, 2.9), trim, fall, &"marble")
		coping.position = Vector3(0, y + 1.55, z)
		# Balustrade along the front edge, with a gap where the water spills.
		var posts := int(w / 0.9)
		for i in posts + 1:
			var px := -w * 0.5 + w * i / posts
			if absf(px) < w * 0.4:
				continue
			var post := Scenery.cylinder(fall, 0.16, 0.12, 0.9, trim, 6)
			post.position = Vector3(px, y + 2.15, z + 1.25)
		for side: float in [-1.0, 1.0]:
			var rail := stadium.box(Vector3(w * 0.1 + 0.2, 0.22, 0.35), trim, fall, &"marble")
			rail.position = Vector3(side * w * 0.45, y + 2.65, z + 1.25)
		var surface := MeshInstance3D.new()
		var sq := QuadMesh.new()
		sq.size = Vector2(w, 2.0)
		surface.mesh = sq
		surface.material_override = water
		surface.rotation.x = -PI * 0.5
		surface.position = Vector3(0, y + 1.72, z)
		fall.add_child(surface)
		if y > 0.5:
			_sheet(fall, water, 0.0, z + 1.55, w * 0.8, y + 1.5, y_next + 1.4)
			_splash(fall, 0.0, y_next + 1.5, z + 1.8, w * 0.8, Color(0.94, 0.98, 1.0), rng, 0.35)
		# Flower boxes on the basin ends.
		for side: float in [-1.0, 1.0]:
			for f in 4:
				var bloom := Scenery.sphere(fall, rng.randf_range(0.45, 0.75), flowers[rng.randi_range(0, 2)] if f % 2 == 0 else green, 0.8)
				bloom.position = Vector3(side * (w * 0.5 + rng.randf_range(0.0, 0.9)), y + 1.9 + rng.randf() * 0.4, z + rng.randf_range(-0.9, 0.9))
	# Climbing vines on the wall either side.
	for i in 8:
		var side := -1.0 if i % 2 == 0 else 1.0
		var length := rng.randf_range(0.3, 0.7) * height
		var v := stadium.box(Vector3(0.5, length, 0.25), green.darkened(rng.randf() * 0.25), fall)
		v.position = Vector3(side * (width * 0.5 + rng.randf_range(1.0, 3.8)), height - length * 0.5, -2.3)
