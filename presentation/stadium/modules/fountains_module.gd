extends StadiumModule
## Pools beyond the outfield wall, from the piece's angle out toward the
## line by "span" degrees: a cascade spills over the back of each basin and
## a row of jets rises and falls, lit at night.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var jet_mat := ShaderMaterial.new()
	jet_mat.shader = Stadium.FOUNTAIN_SHADER
	jet_mat.set_shader_parameter("color", def.accent_color.lerp(Color(0.85, 0.95, 1.0), 0.3))
	jet_mat.set_shader_parameter("glow", 0.7 if def.night else 0.15)
	var water := Stadium.glow(Stadium.WATER.lightened(0.15), 0.6 if def.night else 0.0)
	var side := signf(piece.angle) if piece.angle != 0.0 else 1.0
	var a0 := piece.angle
	var a1 := piece.angle + float(piece.param("span")) * side
	var steps := int(piece.param("basins"))
	var root := Node3D.new()
	root.name = stadium.unique_name("Fountains")
	stadium.add_child(root)
	for i in steps:
		var a := lerpf(a0, a1, (i + 0.5) / steps)
		var p := stadium.profile(a)
		var spot := FieldLayout.direction_for_spray(a) * (p.x + p.z * Stadium.ROW_DEPTH + 7.0)
		var basin := stadium.box(Vector3(14.0, 0.6, 9.0), def.structure_color, root)
		basin.position = spot + Vector3.UP * 0.3
		basin.look_at_from_position(basin.position, basin.position + FieldLayout.direction_for_spray(a), Vector3.UP)
		basin.scale = Vector3.ONE * piece.size
		var surface := stadium.box(Vector3(13.4, 0.1, 8.4), Stadium.WATER, basin)
		surface.position.y = 0.32
		surface.material_override = water
		var cascade := stadium.box(Vector3(14.0, 8.0, 1.2), def.structure_color.darkened(0.15), basin)
		cascade.position = Vector3(0.0, 4.0, -4.5)
		var sheet := stadium.box(Vector3(13.0, 7.6, 0.2), Stadium.WATER, basin)
		sheet.position = Vector3(0.0, 4.0, -3.8)
		sheet.material_override = jet_mat
		for j in 3:
			var jet := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.25
			cyl.bottom_radius = 0.6
			cyl.height = 1.0
			jet.mesh = cyl
			jet.material_override = jet_mat
			jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			jet.position = Vector3(-4.0 + j * 4.0, 0.3, 0.0)
			jet.set_instance_shader_parameter("phase", float(i * 3 + j) * 0.7)
			jet.set_instance_shader_parameter("peak", 9.0 + 4.0 * float((i + j) % 3))
			basin.add_child(jet)
