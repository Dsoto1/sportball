extends SceneTree
## Renders every club's emblem in a grid (with its six-color set below) to
## one image. Needs a display:
##   godot --path . --resolution 1200x800 -s res://tools/emblem_sheet.gd -- /tmp/emblems.png
var _frames := 0
var _out := ""


func _init() -> void:
	_out = OS.get_cmdline_user_args()[0] if not OS.get_cmdline_user_args().is_empty() else "/tmp/emblems.png"
	var lib := ContentLibrary.load_default()
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.93, 0.93, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.8
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 20, 0)
	world.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 8.0
	cam.position = Vector3(0, 0, 10)
	world.add_child(cam)
	var cols := 6
	for i in lib.teams.size():
		var team: TeamDef = lib.teams[i]
		var x := -5.0 + (i % cols) * 2.0
		var y := 2.2 - (i / cols) * 4.0
		var e := Emblem.build(team, 1.6)
		e.position = Vector3(x, y, 0)
		world.add_child(e)
		var colors: Array = team.palette().values()
		for k in colors.size():
			var sw := MeshInstance3D.new()
			var q := QuadMesh.new()
			q.size = Vector2(0.28, 0.28)
			sw.mesh = q
			var m := StandardMaterial3D.new()
			m.albedo_color = colors[k]
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			sw.material_override = m
			sw.position = Vector3(x - 0.75 + k * 0.3, y - 1.15, 0)
			world.add_child(sw)
		var name := Label3D.new()
		name.text = team.team_name.to_upper()
		name.font_size = 40
		name.pixel_size = 0.006
		name.modulate = Color(0.1, 0.1, 0.1)
		name.position = Vector3(x, y - 1.5, 0)
		world.add_child(name)
	process_frame.connect(_frame)


func _frame() -> void:
	_frames += 1
	if _frames == 6:
		root.get_texture().get_image().save_png(_out)
		quit()
