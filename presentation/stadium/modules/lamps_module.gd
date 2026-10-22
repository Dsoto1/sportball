extends StadiumModule
## Gas-lamp posts (or flaming braziers, "style" brazier) along the top of
## the stands, from the piece's angle across "span" degrees.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Lamps")
	stadium.add_child(root)
	var warm := Color(1.0, 0.82, 0.48)
	var light := Stadium.glow(warm, 3.0 if def.night else 1.2)
	var brazier := StringName(piece.param("style")) == &"brazier"
	var fire := Stadium.glow(Color(1.0, 0.55, 0.15), 3.5)
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		if brazier:
			var t := stadium.skyline_top(angle)
			var at := stadium.point(angle, t.x - 0.3, t.y + 0.6)
			var stand := Scenery.cylinder(root, 0.25, 0.35, 2.2, Color(0.2, 0.17, 0.15), 8)
			stand.position = at + Vector3.UP * 1.1
			var bowl := Scenery.cylinder(root, 0.9, 0.4, 0.7, Color(0.3, 0.22, 0.15), 10)
			bowl.position = at + Vector3.UP * 2.5
			var flame := Scenery.cylinder(root, 0.6, 0.0, 1.8, Color.ORANGE, 8)
			flame.position = at + Vector3.UP * 3.6
			flame.material_override = fire
			continue
		var top := stadium.skyline_top(angle)
		var base := stadium.point(angle, top.x - 0.3, top.y + 0.6)
		var post := Scenery.cylinder(root, 0.16, 0.12, 4.4, Color(0.12, 0.12, 0.13), 8)
		post.position = base + Vector3.UP * 2.2
		var lantern := stadium.box(Vector3(0.8, 1.0, 0.8), warm, root)
		lantern.position = base + Vector3.UP * 4.8
		lantern.material_override = light
		var cap := Scenery.cylinder(root, 0.6, 0.05, 0.5, Color(0.12, 0.12, 0.13), 8)
		cap.position = base + Vector3.UP * 5.5
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
