extends StadiumModule
## The centerpiece in straightaway center, over the batter's eye: the home
## club's name under its emblem (or a station clock, with "clock") and
## the batter's card (number, name,
## position, AVG / HR / RBI), framed as a plain board, an iron gate or an
## arch in the park's materials.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var top := stadium.skyline_top(0.0)
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
				var post := stadium.box(Vector3(4.0, 34.0, 3.0), frame_color, board, &"steel")
				post.position = Vector3(side * 19.0, -3.0, -1.5)
				for band in 4:
					var rivets := stadium.box(Vector3(4.3, 0.5, 3.2), def.accent_color.darkened(0.2), post)
					rivets.position.y = -12.0 + band * 7.0
			var lintel := stadium.box(Vector3(42.0, 4.0, 3.0), frame_color, board, &"steel")
			lintel.position = Vector3(0, 13.5, -1.5)
		&"arch":
			# Masonry piers and a round-topped crown.
			for side: float in [-1.0, 1.0]:
				var pier := stadium.box(Vector3(5.0, 32.0, 3.0), def.structure_color, board, &"facade")
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
			crown.material_override = stadium.surface_mat(&"facade", def.structure_color)
			board.add_child(crown)
		&"model":
			# The park's architecture-set gatehouse framing the board.
			var role := StringName(piece.param("frame_model"))
			if ModelKit.has(role):
				var gate := ModelKit.spawn(role, 1.0, RandomNumberGenerator.new())
				var box := ModelKit._aabb(gate)
				var w := float(piece.param("frame_width"))
				gate.scale = Vector3.ONE * (w / maxf(box.size.x, 0.01))
				gate.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * gate.scale + Vector3(0, float(piece.param("frame_drop")), -3.0)
				board.add_child(gate)
		_:
			var legs := stadium.box(Vector3(30.0, 14.0, 1.0), frame_color, board, &"structure")
			legs.position = Vector3(0, -15.0, -0.8)
	var back := stadium.box(Vector3(36.0, 22.0, 1.4), frame_color, board, &"structure")
	back.position = Vector3(0, 0, -0.8)
	var trim := stadium.box(Vector3(36.6, 0.6, 1.6), def.accent_color, board)
	trim.position = Vector3(0, 11.2, -0.6)
	trim.material_override = Stadium.glow(def.accent_color, 1.6)
	var screen := stadium.box(Vector3(34.0, 20.0, 0.2), home.dark_color, board)
	screen.position = Vector3(0, 0, 0.0)
	if bool(piece.param("crown")):
		# A glowing ring floating over the board (the Halo Dome's crown).
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 12.0
		torus.outer_radius = 14.2
		torus.rings = 64
		torus.ring_segments = 10
		ring.mesh = torus
		ring.material_override = Stadium.glow(def.accent_color, 0.9)
		ring.position = Vector3(0, 18.0, 0.0)
		ring.rotation_degrees.x = 70.0
		board.add_child(ring)
	if bool(piece.param("clock")):
		# A station clock crowns it; the emblem moves beside the name.
		var face := Scenery.cylinder(board, 4.2, 4.2, 0.6, Color(0.96, 0.94, 0.86), 32)
		face.rotation.x = PI * 0.5
		face.position = Vector3(0, 16.0, 0.0)
		face.material_override = Stadium.glow(Color(0.98, 0.95, 0.82), 0.8)
		var rim := Scenery.cylinder(board, 4.7, 4.7, 0.4, def.accent_color, 32)
		rim.rotation.x = PI * 0.5
		rim.position = Vector3(0, 16.0, -0.3)
		for hand in [[2.6, 0.0], [3.6, 70.0]]:
			var h := stadium.box(Vector3(0.35, hand[0], 0.1), Color(0.1, 0.1, 0.1), board)
			h.rotation.z = deg_to_rad(hand[1])
			h.position = Vector3(0, 16.0, 0.4) + Vector3(-sin(h.rotation.z), cos(h.rotation.z), 0) * hand[0] * 0.5
		for side: float in [-1.0, 1.0]:
			var mark := Emblem.build(home, 4.0, 0.6)
			mark.position = Vector3(side * 13.5, 7.0, 0.2)
			board.add_child(mark)
	else:
		var emblem := Emblem.build(home, 9.0, 0.6)
		emblem.position = Vector3(0, 15.5, 0.2)
		board.add_child(emblem)
	var name := stadium.label(home.team_name.to_upper(), 300, home.sign_color(), board)
	name.position = Vector3(0, 7.0, 0.2)
	var city := stadium.label(home.city.to_upper(), 120, home.highlight_color, board)
	city.position = Vector3(0, 3.6, 0.2)
	_pillars(stadium, board, piece, home)
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


## Flanking pillars, as on every sheet: a tall pier either side of the
## board hung with a long club banner (emblem on it), capped with a lamp,
## a flaming brazier or the emblem ("pillar_cap"; "none" for no pillars).
func _pillars(stadium: Stadium, board: Node3D, piece: StadiumPiece, home: TeamDef) -> void:
	var cap := StringName(piece.param("pillar_cap"))
	if cap == &"none":
		return
	var def := stadium.def
	var lit := Stadium.glow(def.window_color, 2.5 if def.night else 1.2)
	for side: float in [-1.0, 1.0]:
		var x := side * 24.0
		var pier := stadium.box(Vector3(4.0, 40.0, 3.4), def.facade_tint(), board, &"facade")
		pier.position = Vector3(x, -6.0, -1.0)
		var cornice := stadium.box(Vector3(4.8, 1.0, 4.0), def.facade_tint().lightened(0.2), board, &"facade")
		cornice.position = Vector3(x, 14.5, -1.0)
		var banner := stadium.box(Vector3(3.2, 18.0, 0.15), home.primary_color, board)
		banner.position = Vector3(x, 1.0, 0.8)
		var hem := stadium.box(Vector3(3.3, 0.6, 0.2), home.secondary_color, board)
		hem.position = Vector3(x, -8.0, 0.85)
		var top_hem := stadium.box(Vector3(3.6, 0.5, 0.2), def.accent_color, board)
		top_hem.position = Vector3(x, 10.1, 0.85)
		var mark := Emblem.build(home, 2.8, 0.4)
		mark.position = Vector3(x, 4.5, 0.95)
		board.add_child(mark)
		match cap:
			&"brazier":
				var bowl := Scenery.cylinder(board, 2.2, 1.0, 1.6, Color(0.3, 0.22, 0.15), 10)
				bowl.position = Vector3(x, 15.8, -1.0)
				var flame := Scenery.cylinder(board, 1.6, 0.0, 4.5, Color.ORANGE, 8)
				flame.position = Vector3(x, 18.6, -1.0)
				flame.material_override = Stadium.glow(Color(1.0, 0.55, 0.15), 4.0)
			&"emblem":
				var crest := Emblem.build(home, 4.5, 0.6)
				crest.position = Vector3(x, 17.5, -0.6)
				board.add_child(crest)
			_:
				var post := Scenery.cylinder(board, 0.25, 0.25, 2.0, Color(0.12, 0.12, 0.13), 8)
				post.position = Vector3(x, 16.0, -1.0)
				var lamp := stadium.box(Vector3(1.6, 2.0, 1.6), def.window_color, board)
				lamp.position = Vector3(x, 18.0, -1.0)
				lamp.material_override = lit
				var hood := Scenery.cylinder(board, 1.3, 0.1, 1.0, Color(0.12, 0.12, 0.13), 8)
				hood.position = Vector3(x, 19.5, -1.0)
