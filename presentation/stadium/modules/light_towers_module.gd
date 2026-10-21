extends StadiumModule
## Six floodlight towers behind the stands, their lamp banks aimed at the
## middle of the field; they blaze at night.

const ANGLES := [-128.0, -72.0, -32.0, 32.0, 72.0, 128.0]


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var height := float(piece.param("height")) * piece.size
	var root := Node3D.new()
	root.name = stadium.unique_name("LightTowers")
	stadium.add_child(root)
	for angle: float in ANGLES:
		var p := stadium.profile(angle)
		var base := stadium.point(angle, p.x + p.z * Stadium.ROW_DEPTH + 4.0, 0.0)
		var pole := stadium.box(Vector3(1.4, height, 1.4), def.structure_color.darkened(0.2), root)
		pole.position = base + Vector3.UP * height * 0.5
		var bank := Node3D.new()
		root.add_child(bank)
		bank.look_at_from_position(base + Vector3.UP * height, Stadium.FIELD_CENTER, Vector3.UP)
		stadium.box(Vector3(9.0, 5.0, 0.8), def.structure_color.darkened(0.4), bank)
		for row in 3:
			for col in 6:
				var lamp := stadium.box(Vector3(1.2, 1.2, 0.3), Color.WHITE, bank)
				lamp.position = Vector3(-3.75 + col * 1.5, -1.5 + row * 1.5, -0.5)
				lamp.material_override = Stadium.glow(Color(1.0, 0.97, 0.85), 6.0 if def.night else 2.5)
