extends SceneTree
## Renders every GLB in a folder side by side (each scaled to the same
## height, three-quarter view) to one image, to review generated models.
##   godot --path . --resolution 1600x900 -s res://tools/model_sheet.gd -- res://assets/generated/artlist/stadium /tmp/sheet.png
var _frames := 0
var _out := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var dir: String = args[0]
	_out = args[1]
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.82, 0.84, 0.88)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	world.add_child(sun)
	var files := Array(DirAccess.get_files_at(dir)).filter(func(f: String) -> bool: return f.ends_with(".glb"))
	files.sort()
	var cols := 6
	for i in files.size():
		var node: Node3D = (load(dir.path_join(files[i])) as PackedScene).instantiate()
		var box := AABB()
		var first := true
		for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			box = mi.get_aabb() if first else box.merge(mi.get_aabb())
			first = false
		var k := 3.0 / maxf(box.size.y, maxf(box.size.x, box.size.z))
		node.scale = Vector3.ONE * k
		node.position = Vector3((i % cols) * 4.0 - (cols - 1) * 2.0, -(i / cols) * 4.6 + 2.0, 0) - box.get_center() * k
		node.rotation.y = deg_to_rad(-30)
		world.add_child(node)
		var label := Label3D.new()
		label.text = files[i].get_basename()
		label.pixel_size = 0.01
		label.font_size = 36
		label.modulate = Color.BLACK
		label.position = Vector3((i % cols) * 4.0 - (cols - 1) * 2.0, -(i / cols) * 4.6 + 0.0, 1.0)
		world.add_child(label)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.5
	cam.position = Vector3(0, 0, 20)
	world.add_child(cam)
	process_frame.connect(func() -> void:
		_frames += 1
		if _frames == 8:
			root.get_texture().get_image().save_png(_out)
			quit())
