extends StadiumModule
## Icicles and snow along the deck fronts and the top of the stands, from
## the piece's angle across "span" degrees: a white snow lip and rows of
## hanging ice.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var root := Node3D.new()
	root.name = stadium.unique_name("Icicles")
	stadium.add_child(root)
	var ice := Color(0.85, 0.95, 1.0)
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.0
	mesh.height = 1.0
	mesh.radial_segments = 5
	var mat := Stadium.glow(ice, 0.25)
	var span := float(piece.param("span"))
	var steps := int(absf(span) / 2.5)
	for i in steps:
		var angle := piece.angle + span * (i + 0.5) / steps
		var p := stadium.profile(angle)
		var fronts: Array[int] = []
		for k in int(p.z):
			if k > 0 and stadium.is_deck_front(k):
				fronts.append(k)
		var top := stadium.stand_top(angle)
		var spots: Array[Vector2] = [Vector2(top.x, top.y + 1.2)]
		for k in fronts:
			var front := stadium.deck_front(angle, p, k)
			spots.append(Vector2(front.x - 0.1, front.y + Stadium.PARAPET))
		for spot in spots:
			var lip := stadium.box(Vector3(1.6, 0.35, 0.8), Color.WHITE, root)
			lip.position = stadium.point(angle, spot.x, spot.y + 0.1)
			stadium.face_home(lip)
			var icicle := MeshInstance3D.new()
			icicle.mesh = mesh
			icicle.material_override = mat
			icicle.scale = Vector3(1.0, 0.8 + fmod(i * 0.37, 1.0) * 1.4, 1.0)
			icicle.position = stadium.point(angle, spot.x - 0.2, spot.y - icicle.scale.y * 0.5)
			root.add_child(icicle)
