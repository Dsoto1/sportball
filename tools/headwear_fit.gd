extends SceneTree
## Helmet and cap fit: a batter and a fielder, front and side, close on
## the head. Needs a display:
##   godot --path . --resolution 400x400 -s res://tools/headwear_fit.gd -- out.png
var _f := 0
var _a: Array = []
var _cam: Camera3D
var _shots: Array[Image] = []
func _initialize() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.35, 0.42)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.72)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	root.add_child(sun)
	for i in 2:
		var a := ActorView.new()
		root.add_child(a)
		a.setup(Color(0.75, 0.25, 0.15), "")
		a.set_glove_visible(i == 1)
		_a.append(a)
	_cam = Camera3D.new()
	_cam.fov = 22
	root.add_child(_cam)
	_cam.make_current()
func _process(_d: float) -> bool:
	_f += 1
	if _f == 1:
		for i in 2:
			_a[i].position = Vector3(i * 2.0, 0, 0)
			_a[i].face(Vector3(i * 2.0, 0, 5))
	var views := [[0, Vector3(0, 0.05, 1.3)], [0, Vector3(1.3, 0.05, 0)], [1, Vector3(0, 0.05, 1.3)], [1, Vector3(1.3, 0.05, 0)]]
	var k := (_f - 4) / 4
	if _f >= 4 and k < views.size():
		var a: ActorView = _a[views[k][0]]
		var sk: Skeleton3D = a._skeleton
		var head := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("Head")).origin + Vector3(0, 0.08, 0)
		_cam.look_at_from_position(head + views[k][1], head)
		if (_f - 4) % 4 == 3:
			_shots.append(root.get_texture().get_image())
	if k >= views.size():
		var o := Image.create(400 * _shots.size(), 400, false, Image.FORMAT_RGB8)
		for i in _shots.size():
			_shots[i].convert(Image.FORMAT_RGB8)
			o.blit_rect(_shots[i], Rect2i(0, 0, 400, 400), Vector2i(400 * i, 0))
		o.save_png(OS.get_cmdline_user_args()[0])
		return true
	return false
