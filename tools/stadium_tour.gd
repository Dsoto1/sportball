extends SceneTree
## Flies the camera to stadium landmarks (left-field corner, scoreboard,
## aerial, center field, behind home, the third-base stands), dressing the
## park for its own club when a park_id is given, and saves a screenshot of
## each. Needs a display:
##   godot --path . --resolution 1280x720 -s res://tools/stadium_tour.gd -- /tmp/shots [park_id]
var _frames := 0
var _out := ""
var _view: MatchView
var _i := 0
var _park_id: StringName = &""
const SHOTS := [
	[Vector3(-20, 4, -60), Vector3(-60, 2, -78)],
	[Vector3(10, 10, -40), Vector3(50, 20, -125)],
	[Vector3(0, 40, 120), Vector3(0, 30, -60)],
	[Vector3(0, 1.6, -40), Vector3(0, 3, -112)],
	[Vector3(0, 9, 8), Vector3(0, 5, -60)],
	[Vector3(30, 6, -30), Vector3(-80, 10, 40)],
]
func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	if OS.get_cmdline_user_args().size() > 1:
		_park_id = StringName(OS.get_cmdline_user_args()[1])
	root.add_child(load("res://app/main.tscn").instantiate())
func _process(_d: float) -> bool:
	_frames += 1
	if _view == null:
		_view = root.get_node_or_null("Main/MatchView")
		var hud: MatchHud = root.get_node_or_null("Main/UI/MatchHud")
		if hud != null:
			hud.visible = false
		if _view != null and _park_id != &"":
			var content := ContentLibrary.load_default()
			var park := content.park(_park_id)
			# Dress the park for its own club (emblem, wordmarks, slogan), then
			# hand the match's roster back so the boards keep following it.
			var playing: MatchRoster = _view._roster
			for team in content.teams:
				if team.stadium_def == park:
					_view.set_roster(MatchRoster.new(playing.teams[MatchState.AWAY] if playing != null else team, team))
			_view.set_park(content.tuning_for(park), park)
			_view.set_roster(playing)
		return false
	if _frames < 30:
		return false
	if _i >= SHOTS.size():
		return true
	var cam := _view.get_node("Camera3D") if _view.has_node("Camera3D") else null
	for c in _view.get_children():
		if c is Camera3D:
			cam = c
	cam.set_process(false)
	_view.set_process(false)
	cam.position = SHOTS[_i][0]
	cam.look_at(SHOTS[_i][1])
	cam.fov = 55.0
	if _frames % 8 == 0:
		root.get_texture().get_image().save_png(_out.path_join("%s_%d.png" % [_park_id if _park_id != &"" else &"tour", _i]))
		_i += 1
	return false
