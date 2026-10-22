extends StadiumModule
## A row of a sculpted prop (lantern cluster, ornate column or planter urn)
## every "every" degrees across "span", "height" m tall, standing on the
## top of the stands and facades ("place" top) or on the outfield terrace
## in front of them ("place" terrace). One MultiMesh per row, tinted toward
## the park's facade color ("tint" 0 keeps the model's own colors).
## Lanterns also get a warm glow at the lamp.

const BAY_TINT := preload("res://presentation/stadium/bay_tint.gdshader")
const ROLES := {&"lantern": &"lantern_cluster", &"column": &"column", &"urn": &"planter_urn"}


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var model := StringName(piece.param("model"))
	var kit := ModelKit.mesh_of(ROLES.get(model, &"column"))
	if kit.is_empty():
		return
	var box: AABB = kit["aabb"]
	var tall := float(piece.param("height")) * piece.size
	var k := tall / maxf(box.size.y, 0.01)
	var span := float(piece.param("span"))
	var every := float(piece.param("every"))
	var on_top := StringName(piece.param("place")) == &"top"
	var spots: Array[Vector3] = []
	var steps := maxi(1, int(absf(span) / every))
	for i in steps + 1:
		var a := piece.angle + span * i / steps
		if absf(wrapf(a, -180.0, 180.0)) < 12.0:
			continue  # leave the centerpiece clear
		var top := stadium.skyline_top(a) if on_top else stadium.stand_top(a)
		var r := top.x - (0.8 if on_top else 2.0)
		spots.append(stadium.point(a, r, top.y + (0.0 if on_top else 0.4)))
	if spots.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = kit["mesh"]
	mm.instance_count = spots.size()
	var strength := float(piece.param("tint"))
	var tint := def.facade_tint()
	var origin := Transform3D(Basis(), -Vector3(box.get_center().x, box.position.y, box.get_center().z))
	for i in spots.size():
		var at := spots[i]
		var facing := Vector3(-at.x, 0.0, -at.z).normalized()
		var basis := Basis.looking_at(facing, Vector3.UP).scaled(Vector3.ONE * k)
		mm.set_instance_transform(i, Transform3D(basis, at) * origin * (kit["transform"] as Transform3D))
		mm.set_instance_color(i, Color(tint.r, tint.g, tint.b, strength))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = stadium.unique_name("Props")
	mmi.multimesh = mm
	mmi.material_override = _material(kit["mesh"])
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stadium.add_child(mmi)
	if model == &"lantern":
		# The lamps' glow, so the clusters light up at dusk and night.
		var bulb := SphereMesh.new()
		bulb.radius = tall * 0.12
		bulb.height = tall * 0.24
		var glow := MultiMesh.new()
		glow.transform_format = MultiMesh.TRANSFORM_3D
		glow.mesh = bulb
		glow.instance_count = spots.size()
		for i in spots.size():
			glow.set_instance_transform(i, Transform3D(Basis(), spots[i] + Vector3.UP * tall * 0.62))
		var gi := MultiMeshInstance3D.new()
		gi.multimesh = glow
		gi.material_override = Stadium.glow(def.window_color.lerp(Color(1.0, 0.75, 0.4), 0.5), 3.0 if def.night or def.sky_kind() in [&"dusk", &"sunset"] else 1.4)
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.add_child(gi)


static func _material(mesh: Mesh) -> ShaderMaterial:
	var source := mesh.surface_get_material(0) as StandardMaterial3D
	var mat := ShaderMaterial.new()
	mat.shader = BAY_TINT
	if source != null:
		mat.set_shader_parameter("albedo_tex", source.albedo_texture)
		if source.normal_texture != null:
			mat.set_shader_parameter("normal_tex", source.normal_texture)
			mat.set_shader_parameter("has_normal", true)
		var orm: Texture2D = source.roughness_texture if source.roughness_texture != null else source.metallic_texture
		if orm != null:
			mat.set_shader_parameter("orm_tex", orm)
			mat.set_shader_parameter("has_orm", true)
	return mat
