extends StadiumModule
## Vermilion torii gates behind the stands across "span" degrees: two
## pillars, a tie beam and a curved top lintel with black caps.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var root := Node3D.new()
	root.name = stadium.unique_name("Torii")
	stadium.add_child(root)
	var red := Color(0.78, 0.16, 0.12)
	var black := Color(0.08, 0.07, 0.07)
	var tall := float(piece.param("height")) * piece.size
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var gate := Node3D.new()
		root.add_child(gate)
		var top := stadium.skyline_top(angle)
		gate.position = stadium.point(angle, top.x + float(piece.param("distance")), 0.0 if float(piece.param("distance")) > 8.0 else top.y)
		stadium.face_home(gate)
		var w := tall * 0.85
		for side: float in [-1.0, 1.0]:
			var pillar := Scenery.cylinder(gate, tall * 0.045, tall * 0.04, tall, red, 10)
			pillar.position = Vector3(side * w * 0.42, tall * 0.5, 0)
			var foot := Scenery.cylinder(gate, tall * 0.06, tall * 0.06, tall * 0.06, black, 10)
			foot.position = Vector3(side * w * 0.42, tall * 0.03, 0)
		var tie := stadium.box(Vector3(w * 1.0, tall * 0.06, tall * 0.06), red, gate)
		tie.position.y = tall * 0.78
		# The kasagi: a lintel that sweeps up at both ends.
		for k in 9:
			var t := (k - 4) / 4.0
			var seg := stadium.box(Vector3(w * 1.3 / 9.0 + 0.05, tall * 0.07, tall * 0.1), black if k % 8 == 0 else red, gate)
			seg.position = Vector3(t * w * 0.65, tall + pow(absf(t), 2.0) * tall * 0.08, 0)
			seg.rotation.z = -t * 0.18
		var cap := stadium.box(Vector3(w * 1.36, tall * 0.035, tall * 0.12), black, gate)
		cap.position.y = tall + tall * 0.06
