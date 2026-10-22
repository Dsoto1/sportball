extends StadiumModule
## Water around the park, laid over the ground beyond the stands:
##   river: a straight band "width" m wide whose near bank is "distance" m
##     from home plate, running across the piece's angle (seen from home it
##     crosses that direction); it fades out where it would turn edge-on.
##   moat: a band "gap" m behind the back of the stands and "width" m wide,
##     from the piece's angle across "span" degrees (360 for a full ring,
##     very wide for open harbor water).
## "glow" lights it (neon canals; it brightens at night). A river runs on
## into the haze at the land's rim.

const STEP := 0.5


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var river := StringName(piece.param("style")) == &"river"
	var a0 := piece.angle - 89.0 if river else piece.angle
	var a1 := piece.angle + 89.0 if river else piece.angle + float(piece.param("span"))
	var a := minf(a0, a1)
	var quads := 0
	while a < maxf(a0, a1) - 0.01:
		var b := minf(a + STEP, maxf(a0, a1))
		var band_a := Scenery.water_band(stadium, piece, a)
		var band_b := Scenery.water_band(stadium, piece, b)
		if band_a.y > band_a.x and band_b.y > band_b.x:
			var p0 := stadium.point(a, band_a.x, 0.16)
			var p1 := stadium.point(b, band_b.x, 0.16)
			var p2 := stadium.point(b, band_b.y, 0.16)
			var p3 := stadium.point(a, band_a.y, 0.16)
			for p in [p0, p2, p1, p0, p3, p2]:
				st.set_normal(Vector3.UP)
				st.add_vertex(p)
			quads += 1
		a = b
	if quads == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = stadium.unique_name("Water")
	mi.mesh = st.commit()
	var glow := float(piece.param("glow"))
	var color := Stadium.WATER.lerp(def.accent_color, 0.2) if glow > 0.0 else Stadium.WATER
	# Neon canals: a faint glow by day, lit up at night.
	var mat := stadium.ground_material(true, color, glow * (1.4 if def.night else 0.12))
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stadium.add_child(mi)
