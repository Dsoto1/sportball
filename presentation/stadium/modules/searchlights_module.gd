extends StadiumModule
## Searchlight beams sweeping up from behind the stands into the night sky,
## from the piece's angle across "span" degrees.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var root := Node3D.new()
	root.name = stadium.unique_name("Searchlights")
	stadium.add_child(root)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.92, 1.0, 0.16)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var length := float(piece.param("length"))
	var i := 0
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var base := Scenery.behind(stadium, angle, 10.0) + Vector3.UP * stadium.stand_top(angle).y
		var beam := Scenery.cylinder(root, 1.2, 9.0, length, Color.WHITE, 12)
		beam.material_override = mat
		beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var tilt := Basis(Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(angle * 1.7 + i * 40.0)), deg_to_rad(20.0 + 8.0 * (i % 3)))
		beam.basis = tilt
		beam.position = base + tilt * Vector3.UP * length * 0.5
		var lamp := Scenery.cylinder(root, 1.6, 1.6, 1.4, Color(0.2, 0.2, 0.22), 12)
		lamp.position = base
		i += 1
