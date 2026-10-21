extends StadiumModule
## A grove beyond the stands, from the piece's angle across "span" degrees:
## palms, pines, cacti or round shade trees.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(piece.angle) + str(piece.param("kind")))
	var root := Node3D.new()
	root.name = stadium.unique_name("Trees")
	stadium.add_child(root)
	var kind := StringName(piece.param("kind"))
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var tree := Node3D.new()
		root.add_child(tree)
		tree.position = Scenery.behind(stadium, angle + rng.randf_range(-1.0, 1.0), rng.randf_range(2.0, 14.0))
		tree.rotation.y = rng.randf() * TAU
		tree.scale = Vector3.ONE * piece.size * rng.randf_range(0.8, 1.2)
		match kind:
			&"palm":
				var trunk := Scenery.cylinder(tree, 0.5, 0.35, 16.0, Color(0.45, 0.33, 0.22), 8)
				trunk.position.y = 8.0
				# Long fronds arching out and drooping from the crown.
				for f in 9:
					var frond := Node3D.new()
					tree.add_child(frond)
					frond.position.y = 16.0
					frond.rotation = Vector3(deg_to_rad(-35.0 - 10.0 * (f % 2)), TAU * f / 9.0, 0.0)
					var blade := stadium.box(Vector3(1.2, 0.15, 6.0), Color(0.16, 0.5, 0.22).darkened(0.1 * (f % 3)), frond)
					blade.position.z = -3.0
			&"pine":
				var trunk := Scenery.cylinder(tree, 0.5, 0.4, 4.0, Color(0.36, 0.25, 0.17), 8)
				trunk.position.y = 2.0
				for t in 3:
					var cone := Scenery.cylinder(tree, 4.5 - t * 1.2, 0.2, 7.0, Color(0.1, 0.33, 0.22).darkened(t * 0.08), 10)
					cone.position.y = 6.0 + t * 4.0
			&"cactus":
				tree.scale *= 1.7
				var stem := Scenery.cylinder(tree, 0.9, 0.8, 10.0, Color(0.3, 0.55, 0.32), 10)
				stem.position.y = 5.0
				for arm_side: float in [-1.0, 1.0]:
					var arm := Scenery.cylinder(tree, 0.6, 0.55, 4.0, Color(0.3, 0.55, 0.32), 8)
					arm.position = Vector3(arm_side * 1.8, 6.0 + arm_side, 0.0)
					var elbow := Scenery.cylinder(tree, 0.6, 0.6, 1.8, Color(0.3, 0.55, 0.32), 8)
					elbow.rotation.z = PI * 0.5
					elbow.position = Vector3(arm_side * 1.0, 4.2 + arm_side, 0.0)
			_:
				var trunk := Scenery.cylinder(tree, 0.6, 0.45, 6.0, Color(0.38, 0.27, 0.18), 8)
				trunk.position.y = 3.0
				var crown := Scenery.sphere(tree, 4.5, Color(0.2, 0.45, 0.2))
				crown.position.y = 8.5
