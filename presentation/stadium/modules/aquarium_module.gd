extends StadiumModule
## A giant aquarium tank behind the stands across "span" degrees: a lit
## glass wall full of sea water, coral on the floor, fish and a shark or two
## swimming slow laps (an AnimationPlayer drifts the school).


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("tank" + str(piece.angle))
	var root := Node3D.new()
	root.name = stadium.unique_name("Aquarium")
	stadium.add_child(root)
	var tall := float(piece.param("height")) * piece.size
	var span := float(piece.param("span"))
	var steps := maxi(2, int(absf(span) / 3.0))
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.1, 0.55, 0.7, 0.55)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.emission_enabled = true
	water.emission = Color(0.1, 0.6, 0.75)
	water.emission_energy_multiplier = 0.8
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	water.roughness = 0.05
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fish_root := Node3D.new()
	fish_root.name = "School"
	root.add_child(fish_root)
	for i in steps:
		var a0 := piece.angle + span * i / steps
		var a1 := piece.angle + span * (i + 1) / steps
		var t0 := stadium.skyline_top(a0)
		var t1 := stadium.skyline_top(a1)
		var base0 := t0.y
		var base1 := t1.y
		var p := [stadium.point(a0, t0.x + 2.0, base0), stadium.point(a1, t1.x + 2.0, base1), stadium.point(a1, t1.x + 2.0, base1 + tall), stadium.point(a0, t0.x + 2.0, base0 + tall)]
		for v in [p[0], p[1], p[2], p[0], p[2], p[3]]:
			st.add_vertex(v)
		var frame := stadium.box(Vector3(0.6, tall, 0.6), home.support_color.darkened(0.2), root, &"steel")
		frame.position = stadium.point(a0, t0.x + 1.9, base0 + tall * 0.5)
		# Coral on the tank floor, just behind the glass.
		for c in 2:
			var coral := Scenery.sphere(root, rng.randf_range(1.0, 2.2), [Color(0.95, 0.4, 0.45), Color(0.98, 0.65, 0.3), Color(0.7, 0.4, 0.9)][rng.randi_range(0, 2)], 0.8)
			coral.position = stadium.point(lerpf(a0, a1, rng.randf()), t0.x + rng.randf_range(4.0, 10.0), base0 + 0.8)
	st.generate_normals()
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	glass.mesh = st.commit()
	glass.material_override = water
	root.add_child(glass)
	for f in int(piece.param("fish")):
		var a := piece.angle + span * rng.randf()
		var top := stadium.skyline_top(a)
		var shark := f % 7 == 0
		var fish := Scenery.sphere(fish_root, 3.2 if shark else 1.3, Color(0.45, 0.52, 0.6) if shark else [Color(1.0, 0.75, 0.2), Color(0.3, 0.8, 1.0), Color(1.0, 0.45, 0.35)][f % 3], 0.5)
		fish.scale = Vector3(1.0, 1.0, 2.6)
		fish.position = stadium.point(a, top.x + rng.randf_range(4.0, 12.0), top.y + rng.randf_range(2.0, tall - 2.0))
		fish.rotation.y = rng.randf() * TAU
	# The school drifts back and forth along the tank.
	var anim := Animation.new()
	anim.length = 24.0
	anim.loop_mode = Animation.LOOP_PINGPONG
	var track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track, NodePath("School:rotation:y"))
	anim.track_insert_key(track, 0.0, 0.0)
	anim.track_insert_key(track, 24.0, deg_to_rad(span * 0.15))
	var lib := AnimationLibrary.new()
	lib.add_animation(&"drift", anim)
	var player := AnimationPlayer.new()
	root.add_child(player)
	player.add_animation_library(&"", lib)
	player.autoplay = &"drift"
