extends SceneTree
## Close-up shots of the batter (kit, helmet, grip) and a fielder from
## around the plate, with the match running behind. Needs a display:
##   godot --path . --resolution 800x800 --fixed-fps 60 -s res://tools/batter_closeup.gd -- /tmp/shots [swing]
## Pass `swing` for a swing sequence (six frames from the pitcher's side)
## instead of stills around his stance.
const AROUND := [Vector3(1.6, 1.3, -1.2), Vector3(-2.6, 1.4, 1.2), Vector3(0.0, 1.5, 3.2)]
const SWING_FROM := Vector3(1.2, 1.3, -3.2)
const SWING_FRAMES := 6
var _out := ""
var _frames := 0
var _cam: Camera3D
var _view: MatchView
var _shot := 0
var _swing := false


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	_swing = OS.get_cmdline_user_args().size() > 1
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
	if _shot >= AROUND.size():
		return true
	_cam.position = at + AROUND[_shot]
	_cam.look_at(at + Vector3(0, 1.1, 0))
	if _frames % 6 == 0:
		root.get_texture().get_image().save_png(_out.path_join("batter_%d.png" % _shot))
		_shot += 1
	return false


## Starts a swing, then saves a frame every few ticks through it.
func _swing_sequence(at: Vector3) -> bool:
	_cam.position = at + SWING_FROM
	_cam.look_at(at + Vector3(0, 1.1, 0))
	if _shot == 0 and _frames == 60:
		_view.swing_bat()
	var step := int(MatchView.SWING_TIME * 60.0 / (SWING_FRAMES - 1))
	if (_frames - 60) % maxi(step, 1) == 1:
		root.get_texture().get_image().save_png(_out.path_join("swing_%d.png" % _shot))
		_shot += 1
	return _shot >= SWING_FRAMES
