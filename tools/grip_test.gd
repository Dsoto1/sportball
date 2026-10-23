extends SceneTree
## The batter's grip alone: one player in a batting stance holding the bat,
## plain light, cameras round his hands (front, top-hand side, behind,
## above), or with `body` the whole stance from four sides. Saves a 2x2
## sheet. Needs a display:
##   godot --path . --resolution 600x600 -s res://tools/grip_test.gd -- /tmp/grip.png [style] [lefty] [lift] [yaw]
var _frames := 0
var _out := ""
var _actor: ActorView
var _bat: Node3D
var _cam: Camera3D
var _style: StringName = &"classic"
var _lefty := false
var _body := false
var _shots: Array[Image] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	if args.size() > 1:
		_style = StringName(args[1])
	_lefty = args.has("lefty")
	_body = args.has("body")
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
	_actor = ActorView.new()
	root.add_child(_actor)
	_actor.setup(Color(0.9, 0.4, 0.1), "")
	_actor.set_glove_visible(false)
	_actor.set_lefty(_lefty)
	_actor.style = _style
	_actor.face(Vector3(-1 if _lefty else 1, 0, 0))
	_bat = Node3D.new()
	root.add_child(_bat)
	var mesh := MeshInstance3D.new()
	mesh.mesh = BatMesh.build()
	mesh.position = Vector3(0, 0, 0.06)
	mesh.material_override = BatMesh.material()
	_bat.add_child(mesh)
	_cam = Camera3D.new()
	_cam.fov = 35.0
	root.add_child(_cam)
	_cam.make_current()


func _process(delta: float) -> bool:
	_frames += 1
	_actor.animate(ActorView.Pose.BAT_STANCE, delta)
	var bat := BattingStyles.approach_bat(_style, 0.0, 0.0)
	var side := -1.0 if _lefty else 1.0
	var y := deg_to_rad(bat.x)
	var e := deg_to_rad(bat.y)
	_actor.grip_bat(_bat, Vector3(cos(e) * cos(y) * side, sin(e), cos(e) * sin(y)), 0.1, false, float(BattingStyles.BAT[_style]["choke"]))
	if _frames < 30:
		return false
	var g := _actor.grip_position()
	var views := [Vector3(1.0 * side, 0.1, -0.15), Vector3(-0.2 * side, 0.15, -1.0), Vector3(-1.0 * side, 0.1, 0.2), Vector3(0.3, 1.0, 0.2)]
	var dist := 0.55
	if _body:
		# The whole batter: from the pitcher, from behind the catcher (the
		# broadcast side), from the first-base side, and the game's camera.
		g = _actor.global_position + Vector3(0, 1.0, 0)
		views = [Vector3(0, 0.1, -1.0), Vector3(0.35 * side, 0.15, 1.0), Vector3(1.0 * side, 0.1, 0.0), Vector3(-0.55 * side, 0.08, 1.0)]
		dist = 3.6
	var i := (_frames - 30) / 4
	if i >= views.size():
		var sheet := Image.create(1200, 1200, false, Image.FORMAT_RGB8)
		for k in _shots.size():
			var im := _shots[k]
			im.convert(Image.FORMAT_RGB8)
			im.resize(600, 600)
			sheet.blit_rect(im, Rect2i(0, 0, 600, 600), Vector2i((k % 2) * 600, (k / 2) * 600))
		sheet.save_png(_out)
		return true
	_cam.position = g + (views[i] as Vector3).normalized() * dist
	_cam.look_at(g, Vector3.UP if i < 3 or _body else Vector3.FORWARD)
	if (_frames - 30) % 4 == 3:
		_shots.append(root.get_texture().get_image())
	return false
