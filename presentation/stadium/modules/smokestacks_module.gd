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
			stack = Scenery.cylinder(root, tall * 0.42, tall * 0.28, tall, def.structure_color.lightened(0.2), 24)
		else:
			stack = Scenery.cylinder(root, tall * 0.07, tall * 0.055, tall, def.outfield_wall_color.lerp(Color(0.45, 0.25, 0.18), 0.5), 12)
			for band in 2:
				var ring := Scenery.cylinder(stack, tall * 0.075, tall * 0.075, 1.2, def.accent_color, 12)
				ring.position.y = tall * (0.3 + band * 0.12)
				ring.material_override = Stadium.glow(def.accent_color, 0.6)
		stack.position = base + Vector3.UP * tall * 0.5
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
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke.material_override = mat
		smoke.position = base + Vector3.UP * tall
		root.add_child(smoke)
		i += 1
