extends StadiumModule
## A city ringing the park: modeled buildings and towers (Kenney City Kit)
## in a nearer ring, and lit-window towers behind them, taller toward the
## far side so they peek over the outfield (more windows lit at night).


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var rng := stadium.rng
	var mat := ShaderMaterial.new()
	mat.shader = Stadium.SKYLINE_SHADER
	mat.set_shader_parameter("wall_color", def.skyline_color)
	mat.set_shader_parameter("window_color", def.window_color)
	mat.set_shader_parameter("lit_share", 0.5 if def.night else 0.22)
	mat.set_shader_parameter("glow", 1.6 if def.night else 0.35)
	var root := Node3D.new()
	root.name = stadium.unique_name("Skyline")
	stadium.add_child(root)
	var count := int(piece.param("count"))
	var tall := float(piece.param("height")) * piece.size
	for i in count:
		var a := TAU * (i + rng.randf_range(-0.3, 0.3)) / count
		var radius := rng.randf_range(520.0, 700.0)
		var behind_center := maxf(-sin(a), 0.0)
		var size := Vector3(rng.randf_range(26.0, 55.0), (rng.randf_range(30.0, 70.0) + 90.0 * behind_center * rng.randf()) * tall, rng.randf_range(26.0, 55.0))
		var tower := stadium.box(size, def.skyline_color, root)
		tower.material_override = mat
		tower.position = Stadium.FIELD_CENTER + Vector3(cos(a) * radius, size.y * 0.5, sin(a) * radius)
		tower.rotation.y = rng.randf_range(0.0, PI)
		tower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The nearer ring: modeled city blocks, offices and skyscrapers.
	var near := int(count * 0.9)
	for i in near:
		var a := TAU * (i + rng.randf_range(-0.35, 0.35)) / near
		var behind_center := maxf(-sin(a), 0.0)
		var role: StringName = &"tower" if rng.randf() < 0.3 + 0.4 * behind_center else (&"building" if rng.randf() < 0.6 else &"block")
		var height := (rng.randf_range(45.0, 85.0) if role == &"tower" else rng.randf_range(22.0, 40.0)) * tall
		var b := ModelKit.spawn(role, height, rng)
		root.add_child(b)
		var radius := rng.randf_range(330.0, 470.0)
		b.position = Stadium.FIELD_CENTER + Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		b.rotation.y = rng.randf() * TAU
