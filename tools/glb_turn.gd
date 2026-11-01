extends SceneTree
## Renders one GLB from four sides (front, right, back, left) in a row,
## to check a generated or rigged model.
##   godot --path . --resolution 1600x500 -s res://tools/glb_turn.gd -- res://path/model.glb /tmp/out.png
var _frames := 0
var _out := ""


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[1]
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.32, 0.36, 0.42)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.6, 0.62, 0.66)
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 30, 0)
	world.add_child(sun)
	var scene: PackedScene = load(args[0])
	for i in 4:
		var node: Node3D = scene.instantiate()
		world.add_child(node)
		node.position = Vector3(-4.5 + i * 3.0, 0, 0)
		node.rotation_degrees.y = i * 90.0
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 3.4
	cam.position = Vector3(0, 0, 8)
	world.add_child(cam)
	cam.make_current()


func _process(_d: float) -> bool:
	_frames += 1
	if _frames == 8:
		root.get_texture().get_image().save_png(_out)
		return true
	return false
