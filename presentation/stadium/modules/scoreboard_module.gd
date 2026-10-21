extends StadiumModule
## The big video board above the outfield stands: park name, line score,
## count lamps and the batter's name.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, away: TeamDef) -> void:
	var def := stadium.def
	var top := stadium.stand_top(piece.angle)
	var center := stadium.point(piece.angle, top.x + 3.0, top.y + Stadium.ROW_RISE + float(piece.param("height")) * piece.size)
	var board := Node3D.new()
	board.name = stadium.unique_name("Scoreboard")
	stadium.add_child(board)
	# Local +Z faces home plate, so labels read from the field.
	board.look_at_from_position(center, center + (center - Vector3(0, center.y, 0)), Vector3.UP)
	board.scale = Vector3.ONE * piece.size
	var frame := stadium.box(Vector3(34.0, 17.0, 1.2), def.structure_color.darkened(0.55), board)
	frame.position = Vector3(0, 0, -0.6)
	var trim := stadium.box(Vector3(34.6, 0.5, 1.4), def.accent_color, board)
	trim.position = Vector3(0, 8.6, -0.5)
	trim.material_override = Stadium.glow(def.accent_color, 1.4)
	var screen := stadium.box(Vector3(32.0, 13.0, 0.2), Color(0.03, 0.04, 0.08), board)
	screen.position = Vector3(0, -0.8, 0.05)
	var legs := stadium.box(Vector3(30.0, 6.0, 0.8), def.structure_color.darkened(0.3), board)
	legs.position = Vector3(0, -11.0, -0.6)
	var title := stadium.label(def.display_name.to_upper(), 120, def.accent_color, board)
	title.position = Vector3(0, 6.6, 0.3)
	stadium.add_board(stadium.board_face(board, home, away, Color(1.0, 0.92, 0.6), Color(0.75, 0.8, 0.95), true))
