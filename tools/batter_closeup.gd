extends SceneTree
## Close-up shots of the batter (kit, helmet, grip) and a fielder from
## around the plate, with the match running behind. Needs a display:
##   godot --path . --resolution 800x800 --fixed-fps 60 -s res://tools/batter_closeup.gd -- /tmp/shots [swing [style]]
## Pass `swing` for a swing sequence from the pitcher's side instead of
## stills around his stance: stance, load (a fake windup), stride (a fake
## pitch), then the swing through contact to the finish. A style
## (BattingStyles.ORDER) overrides the batter's own. Pass `flip` as the
## style argument's neighbour (swing <style> flip) to barrel it and watch
## the bat flip after contact, `pitcher` to watch from the mound, or
## `slowmo` for the whip from the press to contact at quarter speed.
## `style:<name>` overrides the batter's style for the stills too;
## `hands` frames the grip tight instead of the whole batter.
const AROUND := [0, 1, 2, 3]
const SWING_FROM := Vector3(3.2, 1.3, -1.4)
## Frames (at 60 fps) of the sequence: windup from WINDUP_FROM, the pitch
## from PITCH_FROM, the press at PRESS; shots saved at SHOTS.
const WINDUP_FROM := 60
const PITCH_FROM := 120
const PRESS := 136
const SHOTS := [70, 104, 132, 137, 140, 146, 160]
var _out := ""
var _frames := 0
var _cam: Camera3D
var _view: MatchView
var _shot := 0
var _swing := false
var _style: StringName = &""
var _flip := false
const FLIP_SHOTS := [140, 150, 160, 172, 186, 205, 230]
## With `slowmo`: from the press to just past contact at quarter speed.
const SLOWMO_SHOTS := [132, 137, 139, 141, 143, 145, 147, 150, 156]


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	_swing = OS.get_cmdline_user_args().size() > 1 and OS.get_cmdline_user_args()[1] == "swing"
	if _swing and OS.get_cmdline_user_args().size() > 2:
		_style = StringName(OS.get_cmdline_user_args()[2])
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("style:"):
			_style = StringName(a.substr(6))
	_flip = OS.get_cmdline_user_args().has("flip")
	root.add_child(load("res://app/main.tscn").instantiate())


func _process(_d: float) -> bool:
	_frames += 1
	if _view == null:
		_view = root.get_node_or_null("Main/MatchView")
		var hud: Control = root.get_node_or_null("Main/UI/MatchHud")
		if hud != null:
			hud.visible = false
		return false
	if _cam == null:
		_cam = Camera3D.new()
		_cam.fov = 40.0
		_view.add_child(_cam)
		_cam.make_current()
	if _frames < 60:
		return false
	var batter: ActorView = _view._runners.get(_view._batter_id)
	var at := batter.global_position if batter != null else Vector3.ZERO
	if _swing:
		return _swing_sequence(at)
	if batter != null and _style != &"":
		batter.style = _style
	if batter != null and OS.get_cmdline_user_args().has("lefty") and not _view._bats_left:
		# A lefty in the other box, as the match places one.
		_view._bats_left = true
		batter.set_lefty(true)
		batter.position = _view._batter_spot()
		batter.face(batter.position + Vector3.LEFT)
		at = batter.global_position
	# Nothing between the camera and the batter.
	for f: Node3D in _view._fielders:
		if f.global_position.distance_to(at) < 4.0:
			f.visible = false
	for n: Node in _view.get_children():
		if n is Node3D and n.name.begins_with("Umpire"):
			(n as Node3D).visible = false
	if _shot >= AROUND.size():
		return true
	# From the pitcher, square to his chest (the plate side), from his back
	# side, and high from behind the plate: relative to how he stands.
	var fwd := -batter.global_transform.basis.z if batter != null else Vector3.FORWARD
	fwd = Vector3(fwd.x, 0.0, fwd.z).normalized()
	var side := -1.0 if _view._bats_left else 1.0
	var around := [Vector3(0.9 * side, 1.5, -3.0), fwd * 3.0 + Vector3(0, 1.3, 0), -fwd * 2.8 + Vector3(0, 1.5, -1.0), Vector3(-0.6 * side, 2.6, 3.4)]
	_cam.position = at + around[_shot]
	_cam.look_at(at + Vector3(0, 1.2, 0))
	_cam.near = 0.05
	if OS.get_cmdline_user_args().has("hands") and batter != null:
		# Tight on the grip from three sides.
		var g := batter.grip_position()
		var b := batter.global_transform.basis
		var views := [-b.z, b.x, -b.x - b.z]
		_cam.position = g + (views[_shot] as Vector3).normalized() * 0.5 + Vector3.UP * 0.08
		_cam.look_at(g, Vector3.UP)
	if _frames % 6 == 3:
		root.get_texture().get_image().save_png(_out.path_join("batter_%d.png" % _shot))
		_shot += 1
	return false


## Fakes a windup and a pitch so he loads and strides, presses swing, and
## saves frames from his stance to his finish.
func _swing_sequence(at: Vector3) -> bool:
	# Face him whichever side he bats from (or watch from the pitcher).
	var from := SWING_FROM * Vector3(-1.0 if _view._bats_left else 1.0, 1.0, 1.0)
	if OS.get_cmdline_user_args().has("pitcher"):
		from = Vector3(0.9 if _view._bats_left else -0.9, 1.4, -3.4)
	_cam.position = at + from
	_cam.look_at(at + Vector3(0, 1.1, 0))
	var batter: ActorView = _view._runners.get(_view._batter_id)
	if batter != null and _style != &"":
		batter.style = _style
	if _frames >= WINDUP_FROM and _frames < PITCH_FROM:
		_view._windup = float(_frames - WINDUP_FROM) / (PITCH_FROM - WINDUP_FROM)
	elif _frames >= PITCH_FROM:
		_view._windup = -1.0
		_view._pitch_u = minf(float(_frames - PITCH_FROM) / 30.0, 0.6)
	if _frames == PRESS:
		_view.swing_bat()
	var shots: Array = FLIP_SHOTS if _flip else SHOTS
	if OS.get_cmdline_user_args().has("slowmo"):
		# Quarter speed from just before the press: the whip, frame by frame.
		Engine.time_scale = 0.25 if _frames >= PRESS - 1 else 1.0
		shots = SLOWMO_SHOTS
	if _flip and _frames == PRESS + 4:
		_view.contact_feedback(Vector2(0.0, 0.8), ContactFeedback.Tier.SWEET)
	if _flip and _frames == PRESS + 18:
		_view._toss_bat()
	if shots.has(_frames):
		root.get_texture().get_image().save_png(_out.path_join("swing_%d.png" % _shot))
		_shot += 1
	return _shot >= shots.size()
