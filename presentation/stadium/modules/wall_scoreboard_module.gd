extends StadiumModule
## A hand-operated scoreboard set into a tall outfield wall: white numbers
## on painted panels, slotted in by hand (no batter line). Skipped where the
## wall is under 6 m.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, away: TeamDef) -> void:
	var angle := piece.angle
	var h := FieldLayout.fence_height(angle, stadium.tuning)
	if h < 6.0:
		return
	var inward := stadium.wall_inward(angle)
	var spot := stadium.point(angle, FieldLayout.fence_distance(angle, stadium.tuning), h * 0.55) + inward * 0.3
	var board := Node3D.new()
	board.name = stadium.unique_name("WallScoreboard")
	stadium.add_child(board)
	board.look_at_from_position(spot, spot - inward, Vector3.UP)
	board.scale = Vector3.ONE * 0.42 * piece.size
	var panel := stadium.box(Vector3(30.0, 11.0, 0.3), stadium.def.outfield_wall_color.darkened(0.35), board)
	panel.position = Vector3(0, 0, -0.2)
	stadium.add_board(stadium.board_face(board, home, away, Color.WHITE, Color(0.85, 0.9, 0.85), false))
