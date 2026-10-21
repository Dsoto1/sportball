extends SceneTree
## The baked baseball moves at their key moments: one shot per move and
## moment from the front-right and one from the side (pose_NN_a/b.png), for
## a contact sheet (e.g. ImageMagick montage). Needs a display:
##   godot --path . --resolution 480x540 -s res://tools/pose_gallery.gd -- /tmp/shots [lefty]
const ENTRIES := [
	["Stance", 0.0], ["Swing", 0.22], ["Swing", 0.42], ["Swing", 0.68], ["Swing", 1.0], ["Bunt", 0.25],
	["Pitch", 0.0], ["Pitch", 0.4], ["Pitch", 0.72], ["Pitch", 1.0], ["Pitch", 1.5], ["Throw", 0.0],
	["Throw", 0.3], ["Throw", 1.0], ["Ready", 0.0], ["Scoop", 0.3], ["Catch_High", 0.3], ["Dive", 0.3],
	["Tag", 0.2], ["Catcher", 0.0], ["Lead", 0.0], ["Slide", 0.5],
]
## Camera spots around the actor (who faces +Z here).
const SHOTS := [Vector3(-2.2, 1.9, 3.6), Vector3(-4.2, 1.3, 0.0)]
var _out := ""
var _frames := 0
var _cam: Camera3D
var _shot := 0
var _entry := 0
var _actors: Array[ActorView] = []


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	var lefty := OS.get_cmdline_user_args().size() > 1
	var world := Node3D.new()
	root.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.shadow_enabled = true
	world.add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.62, 0.7)
	env.environment.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.environment.ambient_light_energy = 0.6
	world.add_child(env)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor_mesh.mesh = plane
	floor_mesh.material_override = GrayboxField._mat(Color(0.25, 0.42, 0.25))
	world.add_child(floor_mesh)
	for i in ENTRIES.size():
		var actor := ActorView.new()
		world.add_child(actor)
		actor.setup(Color(0.85, 0.25, 0.2), "%s %.2f" % ENTRIES[i])
		actor.set_lefty(lefty)
		actor.set_tag_visible(false)
		# Actors face -Z; turn them toward the front camera.
		actor.rotation.y = PI
		actor.visible = false
		_actors.append(actor)
	_cam = Camera3D.new()
	_cam.fov = 50.0
	world.add_child(_cam)


func _process(_d: float) -> bool:
	_frames += 1
	for i in _actors.size():
		var player: AnimationPlayer = _actors[i]._player
		var clip := BaseballMoves.clip(ENTRIES[i][0], _actors[i]._lefty)
		if player.current_animation != String(clip):
			player.play(clip, 0.0)
		player.speed_scale = 0.0
		player.seek(ENTRIES[i][1], true)
	if _frames < 10:
		return false
	if _entry >= _actors.size():
		return true
	for i in _actors.size():
		_actors[i].visible = i == _entry
	_cam.position = SHOTS[_shot]
	_cam.look_at(Vector3(0.0, 0.85, 0.0))
	if _frames % 4 == 0:
		root.get_texture().get_image().save_png(_out.path_join("pose_%02d_%s.png" % [_entry, "ab"[_shot]]))
		_shot += 1
		if _shot >= SHOTS.size():
			_shot = 0
			_entry += 1
	return false
