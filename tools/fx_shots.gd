extends SceneTree
## Stills of the match's particle effects (MatchFx) at a park: the bat's
## contact burst at each tier, home-run fireworks over the outfield, and a
## slide's dust. Needs a display:
##   godot --path . --resolution 1280x720 --fixed-fps 30 -s res://tools/fx_shots.gd -- /tmp/shots [park_id]

var _out := ""
var _frames := 0
var _view: MatchView
var _cam: Camera3D
var _shot := 0
## [frame to trigger, frames to wait, name, camera from, camera to, action]
var _plan: Array = []


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	root.add_child(load("res://app/main.tscn").instantiate())


func _process(_d: float) -> bool:
	_frames += 1
	if _view == null:
		_view = root.get_node_or_null("Main/MatchView")
		if _view != null:
			var hud: Control = root.get_node_or_null("Main/UI/MatchHud")
			hud.visible = false
			_plan = [
				[40, 3, "contact_weak", Vector3(0.75, 1.7, 4.4), Vector3(0, 0.9, 0.1), func() -> void: _view.fx.contact(Vector3(0, 0.9, 0.1), ContactFeedback.Tier.WEAK, Color.RED)],
				[60, 4, "contact_solid", Vector3(0.75, 1.7, 4.4), Vector3(0, 0.9, 0.1), func() -> void: _view.fx.contact(Vector3(0, 0.9, 0.1), ContactFeedback.Tier.SOLID, Color.RED)],
				[80, 4, "contact_sweet", Vector3(0.75, 1.7, 4.4), Vector3(0, 0.9, 0.1), func() -> void: _view.fx.contact(Vector3(0, 0.9, 0.1), ContactFeedback.Tier.SWEET, Color(0.9, 0.3, 0.1))],
				[100, 22, "fireworks", Vector3(0, 6, 10), Vector3(0, 45, -120), func() -> void:
					var colors: Array[Color] = [Color(0.9, 0.3, 0.1), Color(1.0, 0.82, 0.3), Color.WHITE]
					_view.fx.fireworks(Vector3.ZERO, FieldLayout.fence_distance(0.0, _view.tuning) + 15.0, 75.0, colors, 7, 1.0)],
				[170, 8, "dust", Vector3(17.5, 1.2, -16.5), Vector3(19.4, 0.3, -19.4), func() -> void: _view.fx.dust(Vector3(19.4, 0.05, -19.4), 1.0)],
			]
		return false
	if _cam == null:
		_cam = Camera3D.new()
		_cam.fov = 50.0
		_cam.near = 0.05
		_view.add_child(_cam)
		_cam.make_current()
	for step: Array in _plan:
		if _frames == step[0]:
			_cam.position = step[3]
			_cam.look_at(step[4])
			(step[5] as Callable).call()
		if _frames == step[0] + step[1]:
			root.get_texture().get_image().save_png(_out.path_join("%02d_%s.png" % [_shot, step[2]]))
			_shot += 1
	return _frames > 190
