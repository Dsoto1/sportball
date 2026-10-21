extends StadiumModule
## A long brick warehouse beyond the stands, parallel to the line at its
## angle (on the outside of it), windows lit, its name painted along the
## top (the "text" setting, or the park's first sponsor).


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var side := signf(piece.angle) if piece.angle != 0.0 else 1.0
	var line := FieldLayout.direction_for_spray(piece.angle)
	var outward := Vector3(-line.z, 0.0, line.x) * side  # away from the field
	var p := stadium.profile(piece.angle + 20.0 * side)
	var setback := p.x * 0.45 + p.z * Stadium.ROW_DEPTH + 14.0
	var size := Vector3(22.0, float(piece.param("height")), float(piece.param("length"))) * piece.size
	var center := line * 175.0 + outward * setback + Vector3.UP * size.y * 0.5
	var mat := ShaderMaterial.new()
	mat.shader = Stadium.SKYLINE_SHADER
	mat.set_shader_parameter("wall_color", def.outfield_wall_color.darkened(0.1))
	mat.set_shader_parameter("window_color", def.window_color)
	mat.set_shader_parameter("lit_share", 0.45 if def.night else 0.12)
	mat.set_shader_parameter("glow", 1.4 if def.night else 0.25)
	var building := Node3D.new()
	building.name = stadium.unique_name("Warehouse")
	stadium.add_child(building)
	building.look_at_from_position(center, center + line, Vector3.UP)
	var body := stadium.box(size, def.outfield_wall_color, building)
	body.material_override = mat
	var cornice := stadium.box(Vector3(size.x + 1.2, 1.4, size.z + 1.2), def.structure_color, building)
	cornice.position.y = size.y * 0.5
	for i in 6:
		var stack := stadium.box(Vector3(2.4, 7.0, 2.4), def.structure_color.darkened(0.2), building)
		stack.position = Vector3(0.0, size.y * 0.5 + 3.5, -size.z * 0.4 + i * size.z * 0.16)
	var text := str(piece.param("text"))
	if text.is_empty():
		text = def.sponsors[0] if not def.sponsors.is_empty() else "WAREHOUSE"
	var sign := stadium.label(text, 900, def.accent_color, building)
	# Painted on the field-facing side.
	sign.rotation.y = -PI * 0.5 * side
	sign.position = Vector3(-size.x * 0.5 * side - 0.15 * side, size.y * 0.5 - 4.0, 0.0)
