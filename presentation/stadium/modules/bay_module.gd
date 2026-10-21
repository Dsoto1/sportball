extends StadiumModule
## Boats bobbing on the bay. The water itself, and the low stands along it,
## are part of the bowl (Stadium.is_water), which reads this piece's side
## (the sign of its angle) and reach (22 degrees either side of it).


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var side := signf(piece.angle) if piece.angle != 0.0 else 1.0
	var root := Node3D.new()
	root.name = stadium.unique_name("Bay")
	stadium.add_child(root)
	for i in int(piece.param("boats")):
		var boat := stadium.box(Vector3(6.0, 1.6, 2.4) * piece.size, Color.WHITE if i % 2 == 0 else stadium.def.accent_color, root)
		boat.position = FieldLayout.direction_for_spray(side * (absf(piece.angle) - 18.0 + i * 7.0)) * (150.0 + i * 14.0) + Vector3(0, 0.6, 0)
		boat.rotation.y = i * 0.7
