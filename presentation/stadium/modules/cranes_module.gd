extends StadiumModule
## Lattice gantry cranes beyond the stands: a tower, a boom reaching over
## toward the park, a counterweight and a hook. Foundries and harbors.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Cranes")
	stadium.add_child(root)
	var steel := def.accent_color.lerp(def.structure_color, 0.4)
	var i := 0
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var tall := float(piece.param("height")) * piece.size * (1.0 - 0.12 * (i % 2))
		var base := Scenery.behind(stadium, angle, 16.0 + 8.0 * (i % 2))
		var crane := Node3D.new()
		root.add_child(crane)
		crane.look_at_from_position(base, Vector3(0.0, 0.0, -45.0), Vector3.UP)
		crane.rotate_y(deg_to_rad(25.0 * (1 if i % 2 == 0 else -1)))
		for leg in 4:
			var post := stadium.box(Vector3(0.5, tall, 0.5), steel, crane, &"steel")
			post.position = Vector3(-1.2 + 2.4 * (leg % 2), tall * 0.5, -1.2 + 2.4 * (leg / 2))
		for rung in int(tall / 4.0):
			var brace := stadium.box(Vector3(2.9, 0.25, 2.9), steel.darkened(0.2), crane)
			brace.position.y = 2.0 + rung * 4.0
		var boom := stadium.box(Vector3(1.6, 1.6, tall * 0.8), steel, crane, &"steel")
		boom.position = Vector3(0, tall + 0.8, -tall * 0.3)
		var weight := stadium.box(Vector3(3.0, 2.4, 3.0), def.structure_color.darkened(0.4), crane)
		weight.position = Vector3(0, tall + 0.4, tall * 0.12)
		var cab := stadium.box(Vector3(2.4, 2.0, 2.4), def.accent_color, crane)
		cab.position = Vector3(0, tall - 1.4, -1.6)
		var cable := stadium.box(Vector3(0.12, tall * 0.35, 0.12), Color(0.1, 0.1, 0.1), crane)
		cable.position = Vector3(0, tall - tall * 0.175, -tall * 0.62)
		var hook := stadium.box(Vector3(1.2, 1.2, 1.2), def.accent_color, crane)
		hook.position = Vector3(0, tall - tall * 0.35, -tall * 0.62)
		i += 1
