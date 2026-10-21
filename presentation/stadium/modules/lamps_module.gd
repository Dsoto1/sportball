extends StadiumModule
## Gas-lamp posts along the top of the stands, from the piece's angle across
## "span" degrees: iron posts with warm glowing lanterns.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Lamps")
	stadium.add_child(root)
	var warm := Color(1.0, 0.82, 0.48)
	var light := Stadium.glow(warm, 3.0 if def.night else 1.2)
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var top := stadium.stand_top(angle)
		var base := stadium.point(angle, top.x - 0.3, top.y + 0.6)
		var post := Scenery.cylinder(root, 0.16, 0.12, 4.4, Color(0.12, 0.12, 0.13), 8)
		post.position = base + Vector3.UP * 2.2
		var lantern := stadium.box(Vector3(0.8, 1.0, 0.8), warm, root)
		lantern.position = base + Vector3.UP * 4.8
		lantern.material_override = light
		var cap := Scenery.cylinder(root, 0.6, 0.05, 0.5, Color(0.12, 0.12, 0.13), 8)
		cap.position = base + Vector3.UP * 5.5
