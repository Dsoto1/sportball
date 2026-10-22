extends SceneTree
## Bakes the crowd atlas: the player mannequin in fan poses (seated, seated
## clapping, standing clapping, arms-up cheer, jumping, fist pump), four
## frames each, rendered front-on into 64x128 cells with the body region in
## red and the light in green (crowd_encode.gdshader). The crowd shader
## flip-books these per fan and recolors them. Needs a display:
##   godot --path . --resolution 256x512 -s res://tools/bake_crowd.gd
const OUT := "res://assets/generated/crowd/crowd_atlas.png"
const CELL := Vector2i(64, 128)
const COLS := 8
const ENCODE := preload("res://presentation/stadium/crowd_encode.gdshader")

static func P(r: float, u: float, f: float) -> Vector3:
	return PoseBaker.P(r, u, f)

var STAND := {
	"foot_l": P(-0.13, 0.1, 0.0), "foot_r": P(0.13, 0.1, 0.0), "knee_l": P(0, 0, 1), "knee_r": P(0, 0, 1),
	"hand_l": P(-0.28, 0.88, 0.06), "hand_r": P(0.28, 0.88, 0.06), "elbow_l": P(-1, -0.4, -0.3), "elbow_r": P(1, -0.4, -0.3),
}
var SIT := {
	# Seated: hips down at chair height, thighs level, shins down to feet
	# set forward under the knees.
	"drop": 0.58, "chest": Vector3(4, 0, 0),
	"foot_l": P(-0.17, 0.1, 0.5), "foot_r": P(0.17, 0.1, 0.5), "knee_l": P(0, 0.2, 1), "knee_r": P(0, 0.2, 1),
	"hand_l": P(-0.17, 0.62, 0.34), "hand_r": P(0.17, 0.62, 0.34), "elbow_l": P(-1, -0.5, 0), "elbow_r": P(1, -0.5, 0),
}

var _actor: ActorView
var _cam: Camera3D
## Degrees the bake looks down on the mannequin.
const VIEW_DOWN := 22.0
var _poses: Array = []
var _frame := 0
var _cell := 0
var _atlas: Image
var _wait := 0


func _with(base: Dictionary, changes: Dictionary) -> Dictionary:
	var d := base.duplicate()
	d.merge(changes, true)
	return d


func _initialize() -> void:
	root.transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	root.add_child(env)
	_actor = ActorView.new()
	root.add_child(_actor)
	_actor.setup(Color.RED, "")
	_actor.rotation.y = PI
	for n in [_actor._glove, _actor._back, _actor._cap, _actor._helmet, _actor._tag]:
		if n != null:
			n.visible = false
	var body_mat := ShaderMaterial.new()
	body_mat.shader = ENCODE
	_actor._mesh.material_override = body_mat
	var hair_mat := ShaderMaterial.new()
	hair_mat.shader = ENCODE
	hair_mat.set_shader_parameter("forced_region", 8.0)
	for h in [_actor._hair, _actor._beard]:
		if h != null:
			h.material_override = hair_mat
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = 2.4
	# A little above, as the stands are seen (broadcast angles look down on
	# them): seated fans' thighs then read as seated.
	var eye := Vector3(0, 1.05, 0) + Vector3(0, sin(deg_to_rad(VIEW_DOWN)), cos(deg_to_rad(VIEW_DOWN))) * 4.0
	_cam.transform = Transform3D(Basis.looking_at(Vector3(0, 1.05, 0) - eye), eye)
	root.add_child(_cam)
	_cam.current = true
	# Each pose: four frames (a loop the crowd shader plays).
	var clap_in := func(base: Dictionary, h: float, f: float) -> Dictionary: return _with(base, {"hand_l": P(-0.03, h, f), "hand_r": P(0.03, h + 0.02, f), "elbow_l": P(-1, -0.6, 0), "elbow_r": P(1, -0.6, 0)})
	var clap_out := func(base: Dictionary, h: float, f: float) -> Dictionary: return _with(base, {"hand_l": P(-0.2, h, f - 0.02), "hand_r": P(0.2, h + 0.02, f - 0.02), "elbow_l": P(-1, -0.6, 0), "elbow_r": P(1, -0.6, 0)})
	var up := func(base: Dictionary, sway: float, lift: float) -> Dictionary: return _with(base, {"head": Vector3(-12, 0, 0), "hand_l": P(-0.38 + sway, 1.98 + lift, 0.05), "hand_r": P(0.38 + sway, 1.98 - lift, 0.05), "elbow_l": P(-1, 0.2, 0), "elbow_r": P(1, 0.2, 0)})
	var sit_breathe := _with(SIT, {"chest": Vector3(3, 4, 0), "head": Vector3(0, 10, 0)})
	_poses = [
		[SIT, sit_breathe, SIT, _with(SIT, {"head": Vector3(0, -12, 0)})],
		[clap_in.call(SIT, 1.0, 0.36), clap_out.call(SIT, 1.0, 0.36), clap_in.call(SIT, 1.0, 0.36), clap_out.call(SIT, 1.02, 0.36)],
		[clap_in.call(STAND, 1.28, 0.32), clap_out.call(STAND, 1.28, 0.32), clap_in.call(STAND, 1.3, 0.32), clap_out.call(STAND, 1.28, 0.32)],
		[up.call(STAND, -0.06, 0.05), up.call(STAND, 0.0, -0.05), up.call(STAND, 0.06, 0.05), up.call(STAND, 0.0, -0.05)],
		[up.call(_with(STAND, {"drop": 0.12, "knee_l": P(0, 0.2, 1), "knee_r": P(0, 0.2, 1)}), 0.0, 0.0), up.call(_with(STAND, {"shift": P(0, 0.12, 0)}), 0.0, 0.03),
			up.call(_with(STAND, {"shift": P(0, 0.2, 0), "foot_l": P(-0.13, 0.25, 0.0), "foot_r": P(0.13, 0.25, 0.0)}), 0.0, 0.0), up.call(_with(STAND, {"shift": P(0, 0.08, 0)}), 0.0, -0.03)],
		[_with(STAND, {"hand_r": P(0.24, 1.82, 0.12), "elbow_r": P(1, 0.3, 0)}), _with(STAND, {"hand_r": P(0.26, 1.5, 0.22), "elbow_r": P(1, -0.3, 0)}),
			_with(STAND, {"hand_r": P(0.24, 1.84, 0.12), "elbow_r": P(1, 0.3, 0)}), _with(STAND, {"hand_r": P(0.26, 1.5, 0.22), "elbow_r": P(1, -0.3, 0)})],
	]
	_atlas = Image.create(CELL.x * COLS, CELL.y * ceili(_poses.size() * 4.0 / COLS), false, Image.FORMAT_RGBA8)


func _process(_d: float) -> bool:
	if _cell >= _poses.size() * 4:
		_atlas.save_png(ProjectSettings.globalize_path(OUT))
		print("baked %d cells -> %s" % [_cell, OUT])
		return true
	_wait += 1
	if _wait == 1:
		var pose: Dictionary = _poses[_cell / 4][_cell % 4]
		var baker := PoseBaker.new(_actor._skeleton, _actor._player.get_animation(&"Punch_Jab"))
		var anim := baker.bake([[0.0, pose], [0.1, pose]])
		var lib := AnimationLibrary.new()
		lib.add_animation(&"fan", anim)
		if _actor._player.has_animation_library(&"crowd"):
			_actor._player.remove_animation_library(&"crowd")
		_actor._player.add_animation_library(&"crowd", lib)
		_actor._player.play(&"crowd/fan")
		_actor._player.seek(0.05, true)
		return false
	if _wait < 4:
		return false
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
	_atlas.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i((_cell % COLS) * CELL.x, (_cell / COLS) * CELL.y))
	_cell += 1
	_wait = 0
	return false
