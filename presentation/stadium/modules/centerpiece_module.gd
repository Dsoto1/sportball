extends StadiumModule
## The centerpiece in straightaway center, over the batter's eye: the home
## club's name under its emblem and the batter's card (number, name,
## position, AVG / HR / RBI), framed as a plain board, an iron gate or an
## arch in the park's materials.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var top := stadium.stand_top(0.0)
	var k := piece.size
	var center := stadium.point(0.0, top.x + 4.0, top.y + float(piece.param("height")) * k)
	var board := Node3D.new()
	board.name = stadium.unique_name("Centerpiece")
	stadium.add_child(board)
	board.look_at_from_position(center, center + (center - Vector3(0, center.y, 0)), Vector3.UP)
	board.scale = Vector3.ONE * k
	var frame_color := def.structure_color.darkened(0.45)
	match StringName(piece.param("frame")):
		&"gate":
			# Iron posts and a lintel, rivet bands, the board hung inside.
			for side: float in [-1.0, 1.0]:
				var post := stadium.box(Vector3(4.0, 34.0, 3.0), frame_color, board)
				post.position = Vector3(side * 19.0, -3.0, -1.5)
				for band in 4:
					var rivets := stadium.box(Vector3(4.3, 0.5, 3.2), def.accent_color.darkened(0.2), post)
					rivets.position.y = -12.0 + band * 7.0
			var lintel := stadium.box(Vector3(42.0, 4.0, 3.0), frame_color, board)
			lintel.position = Vector3(0, 13.5, -1.5)
		&"arch":
			# Masonry piers and a round-topped crown.
			for side: float in [-1.0, 1.0]:
				var pier := stadium.box(Vector3(5.0, 32.0, 3.0), def.structure_color, board)
				pier.position = Vector3(side * 19.5, -4.0, -1.5)
				var cap := stadium.box(Vector3(6.0, 1.2, 3.6), def.accent_color, pier)
				cap.position.y = 16.5
			var crown := MeshInstance3D.new()
			var disc := CylinderMesh.new()
			disc.top_radius = 12.0
			disc.bottom_radius = 12.0
			disc.height = 3.0
			crown.mesh = disc
			crown.rotation_degrees.x = 90.0
			crown.position = Vector3(0, 11.0, -1.6)
			crown.material_override = GrayboxField._mat(def.structure_color)
			board.add_child(crown)
		_:
			var legs := stadium.box(Vector3(30.0, 14.0, 1.0), frame_color, board)
			legs.position = Vector3(0, -15.0, -0.8)
	var back := stadium.box(Vector3(36.0, 22.0, 1.4), frame_color, board)
	back.position = Vector3(0, 0, -0.8)
	var trim := stadium.box(Vector3(36.6, 0.6, 1.6), def.accent_color, board)
	trim.position = Vector3(0, 11.2, -0.6)
	trim.material_override = Stadium.glow(def.accent_color, 1.6)
	var screen := stadium.box(Vector3(34.0, 20.0, 0.2), home.dark_color, board)
	screen.position = Vector3(0, 0, 0.0)
	var emblem := Emblem.build(home, 9.0, 0.6)
	emblem.position = Vector3(0, 15.5, 0.2)
	board.add_child(emblem)
	var name := stadium.label(home.team_name.to_upper(), 300, home.sign_color(), board)
	name.position = Vector3(0, 7.0, 0.2)
	var city := stadium.label(home.city.to_upper(), 120, home.highlight_color, board)
	city.position = Vector3(0, 3.6, 0.2)
	# The batter's card: a portrait panel in his club's colors, then his line.
	var portrait := stadium.box(Vector3(8.0, 9.0, 0.1), home.primary_color, board)
	portrait.position = Vector3(-11.5, -4.5, 0.15)
	var card := {}
	card["number"] = stadium.label("", 260, Color.WHITE, board)
	card["number"].position = Vector3(-11.5, -4.5, 0.3)
	card["name"] = stadium.label("", 140, Color.WHITE, board)
	card["name"].position = Vector3(3.0, -1.6, 0.2)
	card["position"] = stadium.label("", 110, home.highlight_color, board)
	card["position"].position = Vector3(3.0, -3.8, 0.2)
	for i in 3:
		var x := -2.5 + i * 6.0
		var head := stadium.label(["AVG", "HR", "RBI"][i], 80, home.support_color.lightened(0.3), board)
		head.position = Vector3(x, -6.2, 0.2)
		card[["avg", "hr", "rbi"][i]] = stadium.label("", 130, Color.WHITE, board)
		card[["avg", "hr", "rbi"][i]].position = Vector3(x, -8.4, 0.2)
	stadium.add_board({"card": card})
