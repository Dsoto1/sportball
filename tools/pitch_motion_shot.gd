extends SceneTree
## The pitcher's delivery on the mound, from the side (first-base line),
## at six points from set to follow-through: checks his feet stay on the
## mound's surface through the stride. Saves a 3x2 sheet. Needs a display:
##   godot --path . --resolution 600x600 -s res://tools/pitch_motion_shot.gd -- /tmp/pitch.png [lefty]
const AT := [0.0, 0.5, 0.8, 1.0, 1.2, 1.5]
var _frames := 0
var _out := ""
var _actor: ActorView
var _cam: Camera3D
var _shots: Array[Image] = []


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.32, 0.36, 0.42)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.72)
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root.add_child(sun)
	var field := GrayboxField.new()
	root.add_child(field)
	field.build(load("res://data/tuning/default_tuning.tres") if ResourceLoader.exists("res://data/tuning/default_tuning.tres") else ContentLibrary.load_default().tuning_for(ContentLibrary.load_default().parks[0]))
	_actor = ActorView.new()
	root.add_child(_actor)
	_actor.setup(Color(0.5, 0.2, 0.7), "")
	_actor.set_lefty(OS.get_cmdline_user_args().has("lefty"))
	_cam = Camera3D.new()
	_cam.fov = 40.0
	root.add_child(_cam)



func _process(delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		# Placed once the scene is in the tree.
		_actor.position = Vector3(0, 0, -8.0 if OS.get_cmdline_user_args().has("flat") else FieldLayout.RUBBER_FRONT_Z + 0.25)
		_actor.face(Vector3.ZERO)
		_cam.position = Vector3(5.5, 1.2, FieldLayout.RUBBER_FRONT_Z + 1.2)
		_cam.look_at(Vector3(0, 0.9, FieldLayout.RUBBER_FRONT_Z + 1.2), Vector3.UP)
		_cam.make_current()
	var i := maxi(0, (_frames - 10) / 6)
	if i >= AT.size():
		var sheet := Image.create(1800, 1200, false, Image.FORMAT_RGB8)
		for k in _shots.size():
			var im := _shots[k]
			im.convert(Image.FORMAT_RGB8)
			im.resize(600, 600)
			sheet.blit_rect(im, Rect2i(0, 0, 600, 600), Vector2i((k % 3) * 600, (k / 3) * 600))
		sheet.save_png(_out)
		return true
	_actor.animate(ActorView.Pose.PITCH, delta, 0.0, false, AT[i])
	if _frames > 10 and (_frames - 10) % 6 == 5:
		_shots.append(root.get_texture().get_image())
		# Each foot's sole over the surface under it (should be ~ the same
		# small gap both feet, wherever they stand).
		var sk: Skeleton3D = _actor._skeleton
		var line := "t=%.2f" % AT[i]
		for side in ["l", "r"]:
			var heel := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("foot_" + side)).origin
			var toe := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("ball_" + side)).origin
			line += "  %s heel %+.3f toe %+.3f (ground %.3f at z %.2f)" % [side, heel.y - FieldLayout.ground_height(heel), toe.y - FieldLayout.ground_height(toe), FieldLayout.ground_height(toe), toe.z]
		var plant: FootPlant = sk.get_node("FootPlant")
		print(line, "   planted ankle gaps ", plant.last_gap, "  hand ", _actor.grip_position())
	return false
