extends SceneTree
## A row of players in one pose each (idle, run, batting stance, throw,
## pitch, celebrate), worn as `body` (default the robot) in front and the
## person in the kit behind, to check a worn body (BodyDouble) against the
## skeleton it rides. Needs a display:
##   godot --path . --resolution 1600x700 --fixed-fps 30 -s res://tools/body_check.gd -- /tmp/out.png [robot] [side|back]
const POSES := [ActorView.Pose.IDLE, ActorView.Pose.RUN, ActorView.Pose.BAT_STANCE, ActorView.Pose.THROW, ActorView.Pose.PITCH, ActorView.Pose.CELEBRATE]
var _actors: Array = []
var _frames := 0
var _out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var body := StringName(args[1]) if args.size() > 1 and not args[1] in ["side", "back"] else &"robot"
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.3, 0.34, 0.4)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.57, 0.6)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 25, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 12)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.25, 0.4, 0.22)
	ground.material_override = gm
	world.add_child(ground)
	for row in 2:
		for i in POSES.size():
			var a := ActorView.new()
			world.add_child(a)
			a.setup(Color(0.18, 0.18, 0.22), "")
			a.set_player("check_%d" % i, 19, body if row == 0 else &"")
			a.set_glove_visible(POSES[i] != ActorView.Pose.BAT_STANCE)
			a.position = Vector3(-6.25 + i * 2.5, 0, 2.2 * row)
			_actors.append(a)
	var cam := Camera3D.new()
	var side := args.has("side")
	cam.fov = 45
	world.add_child(cam)
	# Actors face -Z: the camera looks back at their fronts.
	if args.has("back"):
		# Close behind the person in the kit doing the pitch pose (from behind).
		cam.look_at_from_position(Vector3(3.75, 1.3, 2.2 + 3.2), Vector3(3.75, 0.9, 2.2), Vector3.UP)
	else:
		cam.look_at_from_position(Vector3(16, 1.6, 1.0) if side else Vector3(0, 1.6, -8.5), Vector3(0, 0.95, 1.0))
	cam.make_current()


func _process(delta: float) -> bool:
	_frames += 1
	for k in _actors.size():
		var a: ActorView = _actors[k]
		var pose: ActorView.Pose = POSES[k % POSES.size()]
		a.animate(pose, delta, 4.0 if pose == ActorView.Pose.RUN else 0.0, false, clampf(_frames / 30.0, 0.0, 0.55))
	if _frames == 30:
		root.get_texture().get_image().save_png(_out)
		return true
	return false
