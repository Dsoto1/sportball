extends StadiumModule
## Strings of warm bulbs draped along the top of the stands and facades,
## from the piece's angle across "span" degrees: each run sags between
## posts every "every" degrees. All bulbs are one MultiMesh.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var span := float(piece.param("span"))
	var every := float(piece.param("every"))
	var drop := float(piece.param("sag"))
	var lift := float(piece.param("lift"))
	var points: Array[Vector3] = []
	var runs := maxi(1, int(absf(span) / every))
	for r in runs:
		var a0 := piece.angle + span * r / runs
		var a1 := piece.angle + span * (r + 1) / runs
		# Leave the centerpiece's gap in center field unstrung.
		if absf(wrapf(a0, -180.0, 180.0)) < 12.0 or absf(wrapf(a1, -180.0, 180.0)) < 12.0:
			continue
		var t0 := stadium.skyline_top(a0)
		var t1 := stadium.skyline_top(a1)
		var p0 := stadium.point(a0, t0.x - 0.6, t0.y + lift)
		var p1 := stadium.point(a1, t1.x - 0.6, t1.y + lift)
		var n := maxi(4, int(p0.distance_to(p1) / 1.6))
		for i in n:
			var t := float(i) / n
			points.append(p0.lerp(p1, t) + Vector3.DOWN * drop * 4.0 * t * (1.0 - t))
	var bulb := SphereMesh.new()
	bulb.radius = 0.42 * piece.size
	bulb.height = 0.84 * piece.size
	bulb.radial_segments = 6
	bulb.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bulb
	mm.instance_count = points.size()
	for i in points.size():
		mm.set_instance_transform(i, Transform3D(Basis(), points[i]))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = stadium.unique_name("StringLights")
	mmi.multimesh = mm
	var color: Color = piece.param("color")
	mmi.material_override = Stadium.glow(color, 4.0 if def.night or def.sky_kind() in [&"dusk", &"sunset"] else 2.0)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stadium.add_child(mmi)
