extends StadiumModule
## Patriotic half-fan bunting hung along the deck fronts, from the piece's
## angle across "span" degrees, every few meters: red, white and blue
## bands (or the club's colors with "club_colors").


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var root := Node3D.new()
	root.name = stadium.unique_name("Bunting")
	stadium.add_child(root)
	var colors := [home.primary_color, home.highlight_color, home.secondary_color] if bool(piece.param("club_colors")) \
		else [Color(0.12, 0.2, 0.5), Color(0.96, 0.96, 0.94), Color(0.75, 0.12, 0.15)]
	var span := float(piece.param("span"))
	var steps := maxi(1, int(absf(span) / float(piece.param("every"))))
	for i in steps:
		var angle := piece.angle + span * (i + 0.5) / steps
		# Only where the decks have split (past the foul poles).
		if absf(wrapf(angle, -180.0, 180.0)) < 60.0:
			continue
		var p := stadium.profile(angle)
		for k in int(p.z):
			if k == 0 or not stadium.is_deck_front(k):
				continue
			var top := stadium.row_height(angle, p, k)
			var fan := Node3D.new()
			root.add_child(fan)
			fan.position = stadium.point(angle, p.x + k * Stadium.ROW_DEPTH - 0.25, top - 0.15)
			stadium.face_home(fan)
			# Three bands of a half disc hanging from its flat top edge.
			for band in 3:
				var half := MeshInstance3D.new()
				half.mesh = _half_disc(1.1 - band * 0.33)
				half.material_override = GrayboxField._mat(colors[band])
				half.position = Vector3(0, 0, 0.02 * band)
				fan.add_child(half)


static func _half_disc(r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 12
	for i in n:
		var a0 := PI + PI * i / n
		var a1 := PI + PI * (i + 1) / n
		for v in [Vector3.ZERO, Vector3(cos(a1) * r, sin(a1) * r, 0.0), Vector3(cos(a0) * r, sin(a0) * r, 0.0)]:
			st.set_normal(Vector3.BACK)
			st.add_vertex(v)
	return st.commit()
