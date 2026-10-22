extends StadiumModule
## Smokestacks (or a power plant's cooling towers) beyond the stands, with
## smoke or steam drifting off the top. Industry across "span" degrees.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Smokestacks")
	stadium.add_child(root)
	var cooling := StringName(piece.param("style")) == &"cooling"
	var i := 0
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var tall := float(piece.param("height")) * piece.size * (1.0 - 0.15 * (i % 3))
		var base := Scenery.behind(stadium, angle, (75.0 if cooling else 22.0) + 10.0 * (i % 2))
		var stack: MeshInstance3D
		if cooling:
			# A hyperboloid shell: flared base on a ring of legs, pinched
			# waist two-thirds up, flaring again at the lip; weather stains
			# darken it toward the top.
			var rng := RandomNumberGenerator.new()
			rng.seed = i
			var prof := []
			for k in 13:
				var t := k / 12.0
				var r := tall * 0.25 * sqrt(1.0 + pow((t - 0.72) / 0.3, 2.0) * 0.9)
				prof.append(Vector3(r, tall * t, 0.05 + 0.3 * t * t))
			prof.append(Vector3(tall * 0.27, tall, 0.5))
			prof.append(Vector3(tall * 0.255, tall * 0.96, 0.7))
			prof.append(Vector3(0.0, tall * 0.96, 0.8))
			var concrete := StadiumSurfaces.material(&"concrete", Color(0.86, 0.85, 0.82), true, 2.0)
			stack = Scenery.lathe(root, prof, 40, 0.0, rng, concrete)
			var plinth := Scenery.cylinder(stack, tall * 0.43, tall * 0.43, tall * 0.03, Color(0.4, 0.4, 0.42), 40)
			plinth.position.y = tall * 0.015
		else:
			stack = Scenery.cylinder(root, tall * 0.07, tall * 0.055, tall, def.outfield_wall_color.lerp(Color(0.45, 0.25, 0.18), 0.5), 12)
			for band in 2:
				var ring := Scenery.cylinder(stack, tall * 0.075, tall * 0.075, 1.2, def.accent_color, 12)
				ring.position.y = tall * (0.3 + band * 0.12)
				ring.material_override = Stadium.glow(def.accent_color, 0.6)
		if cooling:
			stack.position = base
		else:
			stack.position = base + Vector3.UP * tall * 0.5
			stack.material_override = StadiumSurfaces.material(&"brick", stack.material_override.albedo_color, false, 1.0)
		var smoke := CPUParticles3D.new()
		smoke.amount = 24
		smoke.lifetime = 7.0
		smoke.preprocess = 7.0
		smoke.direction = Vector3(0.3, 1.0, 0.1)
		smoke.spread = 12.0
		smoke.initial_velocity_min = 3.0
		smoke.initial_velocity_max = 5.0
		smoke.gravity = Vector3(1.2, 0.4, 0.0)
		smoke.scale_amount_min = 3.0 if not cooling else 8.0
		smoke.scale_amount_max = 6.0 if not cooling else 14.0
		var puff := SphereMesh.new()
		puff.radius = 1.0
		puff.height = 2.0
		puff.radial_segments = 8
		puff.rings = 4
		smoke.mesh = puff
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.92, 0.92, 0.95, 0.35) if cooling else Color(0.25, 0.24, 0.24, 0.45)
		# "tint" glows the plume in the park's accent (the reactor's green steam).
		var tint := float(piece.param("tint"))
		if tint > 0.0:
			var c := Color(mat.albedo_color.lerp(def.accent_color, tint), mat.albedo_color.a)
			mat.albedo_color = c
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke.material_override = mat
		smoke.position = base + Vector3.UP * tall
		root.add_child(smoke)
		i += 1
