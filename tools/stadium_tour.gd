extends SceneTree
## Flies the camera to stadium landmarks (left-field corner, scoreboard,
## aerial, center field, behind home, the third-base stands), dressing the
## park for its own club when a park_id is given, and saves a screenshot of
## each. Needs a display:
##   godot --path . --resolution 1280x720 -s res://tools/stadium_tour.gd -- /tmp/shots [park_id] [orbit]
## "orbit" flies a drone circle instead: eight shots from high over the
## stands all the way round, looking down across the bowl, to check the
## layout from every side. "mound" stands on the pitcher's mound and turns
## round at eye height (home plate first), then looks straight down.
var _frames := 0
var _out := ""
var _view: MatchView
var _i := 0
var _park_id: StringName = &""
const SHOTS := [
	[Vector3(-20, 4, -60), Vector3(-60, 2, -78)],
	[Vector3(10, 10, -40), Vector3(50, 20, -125)],
	[Vector3(0, 85, 150), Vector3(0, 0, -50)],
	[Vector3(0, 1.6, -40), Vector3(0, 3, -112)],
	[Vector3(0, 9, 8), Vector3(0, 5, -60)],
	[Vector3(30, 6, -30), Vector3(-80, 10, 40)],
]
var _shots: Array = SHOTS
var _cheer := -1.0
## Mound mode: hide the players and ball (the camera stands where the
## pitcher does) so only the park is seen.
var _bare := false
## "nocrowd": the stands empty, to see the seats and structure.
var _nocrowd := false


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	if OS.get_cmdline_user_args().size() > 1:
		_park_id = StringName(OS.get_cmdline_user_args()[1])
	if OS.get_cmdline_user_args().size() > 2 and OS.get_cmdline_user_args()[2].begins_with("cam:"):
		# One shot from a given camera: cam:x,y,z,tx,ty,tz
		var v := OS.get_cmdline_user_args()[2].substr(4).split_floats(",")
		_shots = [[Vector3(v[0], v[1], v[2]), Vector3(v[3], v[4], v[5])]]
	elif OS.get_cmdline_user_args().size() > 2 and OS.get_cmdline_user_args()[2] == "mound":
		# Standing on the mound at eye height, turning round in eight steps
		# (home plate first, then clockwise seen from above), then straight
		# down from high over the infield.
		_bare = true
		var eye := Vector3(0, 2.0, -18.44)
		_shots = []
		for k in 8:
			var a := TAU * k / 8.0
			_shots.append([eye, eye + Vector3(sin(a) * 50.0, 1.0, cos(a) * 50.0)])
		_shots.append([Vector3(0, 230, -40), Vector3(0, 0, -40.5)])
	elif OS.get_cmdline_user_args().size() > 2 and OS.get_cmdline_user_args()[2] == "orbit":
		# The drone: radius 175 m round the middle of the park, 75 m up,
		# starting behind home and going clockwise seen from above.
		var center := Vector3(0, 0, -55)
		_shots = []
		for k in 8:
			var a := PI * 0.5 + TAU * k / 8.0
			_shots.append([center + Vector3(cos(a) * 175.0, 75.0, sin(a) * 175.0), center + Vector3(0, -10, 0)])
	for a: String in OS.get_cmdline_user_args():
		if a == "nocrowd":
			_nocrowd = true
		if a.begins_with("cheer:"):
			# Hold the crowd at this excitement (0 calm .. 1 a home run).
			_cheer = a.substr(6).to_float()
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
	if _cheer >= 0.0 and _view._stadium != null:
		_view._stadium._excitement = _cheer
	if _nocrowd and _view._stadium != null:
		for c in _view._stadium.get_children():
			if c is MultiMeshInstance3D and (c.name.begins_with("Crowd") or c.name.begins_with("Fans")):
				c.visible = false
	if _bare:
		for c in _view.get_children():
			if c is Node3D and not (c is Stadium or c is GrayboxField or c is Camera3D or c is DirectionalLight3D):
				(c as Node3D).visible = false
	if _frames < 30:
		return false
	if _i >= _shots.size():
		return true
	var cam := _view.get_node("Camera3D") if _view.has_node("Camera3D") else null
	for c in _view.get_children():
		if c is Camera3D:
			cam = c
	cam.set_process(false)
	_view.set_process(false)
	cam.position = _shots[_i][0]
	cam.look_at(_shots[_i][1])
	cam.fov = 55.0 if _shots == SHOTS else (70.0 if _i < 8 or _shots.size() != 9 else 62.0)
	if _frames % 8 == 0:
		root.get_texture().get_image().save_png(_out.path_join("%s_%d.png" % [_park_id if _park_id != &"" else &"tour", _i]))
		_i += 1
	return false
