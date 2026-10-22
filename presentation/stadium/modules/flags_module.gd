extends StadiumModule
## Flagpoles along the top of the stands, from the piece's angle across
## "span" degrees, flying the club's colors (and its emblem on every third).


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var root := Node3D.new()
	root.name = stadium.unique_name("Flags")
	stadium.add_child(root)
	var colors := [home.primary_color, home.secondary_color, home.accent_color]
	var i := 0
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var top := stadium.skyline_top(angle)
		var base := stadium.point(angle, top.x, top.y + 1.2)
		var pole := stadium.box(Vector3(0.18, 7.0 * piece.size, 0.18), Color(0.85, 0.85, 0.82), root)
		pole.position = base + Vector3.UP * 3.5 * piece.size
		var flag := Node3D.new()
		root.add_child(flag)
		flag.look_at_from_position(base + Vector3.UP * 6.0 * piece.size, Vector3(0, base.y + 6.0, 0), Vector3.UP)
		flag.rotate_y(PI * 0.5)
		var cloth := stadium.box(Vector3(0.05, 1.6, 2.6) * piece.size, colors[i % 3], flag)
		cloth.position.z = -1.3 * piece.size
		if i % 3 == 0:
			var mark := Emblem.build(home, 1.2 * piece.size, 0.3)
			mark.rotation.y = PI * 0.5
			mark.position = Vector3(0.05, 0, -1.3 * piece.size)
			flag.add_child(mark)
		i += 1
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
