extends StadiumModule
## A ski gondola line strung across the backdrop: towers, a cable and
## cabins in the club's colors, from the piece's angle across "span".


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var root := Node3D.new()
	root.name = stadium.unique_name("Gondola")
	stadium.add_child(root)
	var towers := 4
	var tops: Array[Vector3] = []
	for i in towers:
		var angle := piece.angle + float(piece.param("span")) * i / (towers - 1)
		var base := Scenery.behind(stadium, angle, 30.0 + 25.0 * i)
		var h := 30.0 + 10.0 * i
		var tower := stadium.box(Vector3(1.4, h, 1.4), Color(0.25, 0.27, 0.3), root)
		tower.position = base + Vector3.UP * h * 0.5
		tops.append(base + Vector3.UP * h)
	for i in towers - 1:
		var a := tops[i]
		var b := tops[i + 1]
		var cable := stadium.box(Vector3(0.15, 0.15, a.distance_to(b)), Color(0.1, 0.1, 0.1), root)
		cable.look_at_from_position((a + b) * 0.5, b, Vector3.UP)
		for c in 2:
			var t := 0.3 + c * 0.4
			var cabin := stadium.box(Vector3(2.4, 2.2, 2.4), home.primary_color if c == 0 else home.accent_color, root)
			cabin.position = a.lerp(b, t) + Vector3.DOWN * 2.4
