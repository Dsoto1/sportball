extends StadiumModule
## Floating islands beyond the stands across "span" degrees: inverted rock
## cones with grassy tops, trees, a little tower and a waterfall spilling
## off the edge into the clouds.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("islands" + stadium.def.id + str(piece.angle))
	var root := Node3D.new()
	root.name = stadium.unique_name("Islands")
	stadium.add_child(root)
	var count := int(piece.param("count"))
	for i in count:
		var angle := piece.angle + float(piece.param("span")) * (i + rng.randf_range(0.2, 0.8)) / count
		var size := rng.randf_range(10.0, 26.0) * piece.size
		var isle := Node3D.new()
		root.add_child(isle)
		isle.position = stadium.point(angle, rng.randf_range(150.0, 330.0), rng.randf_range(30.0, 85.0))
		var rock := Scenery.cylinder(isle, 0.5, size, size * 1.4, Color(0.5, 0.44, 0.38), 9)
		rock.position.y = -size * 0.7
		rock.material_override = StadiumSurfaces.material(&"rock", Color(0.62, 0.55, 0.47), false, 1.5)
		var turf := Scenery.cylinder(isle, size * 1.02, size * 1.0, size * 0.12, Color(0.25, 0.55, 0.25), 9)
		turf.position.y = size * 0.06
		for t in rng.randi_range(1, 3):
			var tree := ModelKit.spawn(&"round", size * 0.5, rng)
			isle.add_child(tree)
			tree.position = Vector3(rng.randf_range(-0.6, 0.6) * size, size * 0.1, rng.randf_range(-0.6, 0.6) * size)
		if i % 2 == 0:
			var tower := stadium.box(Vector3(size * 0.25, size * 0.8, size * 0.25), home.highlight_color.darkened(0.15), isle, &"stone")
			tower.position = Vector3(size * 0.3, size * 0.5, -size * 0.2)
			var cap := Scenery.cylinder(isle, size * 0.22, 0.0, size * 0.35, home.primary_color, 8)
			cap.position = Vector3(size * 0.3, size * 1.07, -size * 0.2)
		if i % 3 == 0:
			var fall := stadium.box(Vector3(size * 0.25, size * 1.6, 0.4), Color(0.85, 0.95, 1.0), isle)
			fall.position = Vector3(0, -size * 0.75, size * 0.85)
			fall.material_override = Stadium.glow(Color(0.8, 0.93, 1.0), 0.4)
