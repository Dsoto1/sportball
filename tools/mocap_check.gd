extends SceneTree
## A Mixamo clip baked onto a player (MixamoRetarget), seen from his chest
## side (top row) and from the pitcher (bottom row) at evenly spaced
## times; prints where his hands are. Needs a display:
##   godot --path . --resolution 1800x700 -s res://tools/mocap_check.gd -- out.png Baseball_Hit [frames=8] [yaw:<deg>] [hands]
var _frames := 0
var _out := ""
var _actors: Array = []
var _anim: Animation
var _n := 8
var _from := 0.0
var _to := -1.0
var _shot := 0
var _cams: Array = []
var _images: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var clip := args[1] if args.size() > 1 else "Baseball_Hit"
	if args.size() > 2:
		_n = int(args[2])
	if args.size() > 4 and not args[3].begins_with("yaw:"):
		_from = float(args[3])
		_to = float(args[4])
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.34, 0.4)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.62, 0.66)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	world.add_child(sun)
	var a := ActorView.new()
	world.add_child(a)
	a.setup(Color(0.75, 0.2, 0.12), "")
	a.set_glove_visible(false)
	var yaw := 0.0
	for arg: String in args:
		if arg.begins_with("yaw:"):
			yaw = float(arg.substr(4))
	_anim = MixamoRetarget.bake(clip, a._skeleton, 0.0, -1.0, false, false, yaw)
	var lib := AnimationLibrary.new()
	lib.add_animation(&"clip", _anim)
	a._player.add_animation_library(&"mocap", lib)
	a._player.play(&"mocap/clip")
	a._player.pause()
	_actors.append(a)
	print("MOCAP %s length %.2f" % [clip, _anim.length])


func _process(_d: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	if _shot >= _n * 2:
		return true
	var a: ActorView = _actors[0]
	var cam: Camera3D = root.get_viewport().get_camera_3d()
	if cam == null:
		cam = Camera3D.new()
		cam.fov = 40
		root.get_child(root.get_child_count() - 1).add_child(cam)
		cam.make_current()
	var step := _shot / 2
	var view := _shot % 2
	var end := _anim.length if _to < 0.0 else _to
	var t := lerpf(_from, end, step / maxf(_n - 1, 1))
	a._player.seek(t, true)
	# Actors face -Z: their chest side is -Z after the turn.
	if view == 0:
		cam.look_at_from_position(Vector3(0, 1.1, -4.2), Vector3(0, 0.95, 0))
	else:
		cam.look_at_from_position(Vector3(-4.2, 1.1, 0), Vector3(0, 0.95, 0))
	if OS.get_cmdline_user_args().has("hands"):
		# Tight on the raw captured hands (no bat, no grip).
		var skh: Skeleton3D = a._skeleton
		var mid := skh.global_transform * ((skh.get_bone_global_pose(skh.find_bone("hand_l")).origin + skh.get_bone_global_pose(skh.find_bone("hand_r")).origin) * 0.5)
		cam.look_at_from_position(mid + (Vector3(0, 0.1, -0.9) if view == 0 else Vector3(-0.9, 0.1, 0)), mid)
	if _frames % 3 != 0:
		return false
	var sk: Skeleton3D = a._skeleton
	var hl := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
	var hr := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_r")).origin
	if view == 0:
		print("MOCAP t=%.2f hand_l %s hand_r %s apart %.2f" % [t, hl.snapped(Vector3.ONE * 0.01), hr.snapped(Vector3.ONE * 0.01), hl.distance_to(hr)])
	_images.append(root.get_texture().get_image())
	_shot += 1
	if _shot >= _n * 2:
		var w: int = _images[0].get_width()
		var h: int = _images[0].get_height()
		var sheet := Image.create(w * _n, h * 2, false, _images[0].get_format())
		for i in _images.size():
			sheet.blit_rect(_images[i], Rect2i(0, 0, w, h), Vector2i((i / 2) * w, (i % 2) * h))
		# (the first image is taken before the camera exists)
		sheet.save_png(_out)
		return true
	return false
