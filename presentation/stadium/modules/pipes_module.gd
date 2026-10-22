extends StadiumModule
## Industrial pipes running along the top of the stands, from the piece's
## angle across "span" degrees: stacked runs on brackets, the top one lit in
## the park's accent (neon coolant).


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Pipes")
	stadium.add_child(root)
	var span := float(piece.param("span"))
	var steps := maxi(2, int(absf(span) / 3.0))
	var lit := Stadium.glow(def.accent_color, 1.6 if def.night else 0.8)
	var steel := GrayboxField._mat(def.structure_color.darkened(0.35))
	for run in int(piece.param("runs")):
		var lift := 2.0 + run * 1.6
		var prev := Vector3.ZERO
		for i in steps + 1:
			var angle := piece.angle + span * i / steps
			var top := stadium.skyline_top(angle)
			var p := stadium.point(angle, top.x + 1.0 + run * 0.4, top.y + lift)
			if i > 0:
				var pipe := Scenery.cylinder(root, 0.45, 0.45, prev.distance_to(p), Color.WHITE, 10)
				pipe.material_override = lit if run == 0 else steel
				pipe.position = (prev + p) * 0.5
				pipe.look_at_from_position(pipe.position, p, Vector3.UP)
				pipe.rotate_object_local(Vector3.RIGHT, PI * 0.5)
			if i % 3 == 0:
				var bracket := stadium.box(Vector3(0.4, lift, 0.4), def.structure_color.darkened(0.4), root)
				bracket.position = stadium.point(angle, top.x + 1.0 + run * 0.4, top.y + lift * 0.5)
			prev = p
