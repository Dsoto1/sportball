extends SceneTree
## Renders the long-ball camera for a home run in a park: frames through the
## flight (rise, chase, wall, landing, trot) into one contact sheet. Needs a
## display:
##   godot --path . --resolution 960x540 -s res://tools/flight_shots.gd -- /tmp/out.png [park_id] [ev_mps] [launch] [spray]
var _frames := 0
var _view: MatchView
var _out := ""
var _park_id: StringName = &"ledger_street"
var _traj: BallTrajectory
var _times: Array[float] = []
var _shot := 0
var _images: Array[Image] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	if args.size() > 1:
		_park_id = StringName(args[1])
	root.add_child(load("res://app/main.tscn").instantiate())
	var ev := float(args[2]) if args.size() > 2 else 48.0
	var la := float(args[3]) if args.size() > 3 else 28.0
	var spray := float(args[4]) if args.size() > 4 else -12.0
	set_meta("hit", [ev, la, spray])


func _process(_d: float) -> bool:
	_frames += 1
	if _view == null:
		_view = root.get_node_or_null("Main/MatchView")
		if _view == null:
			return false
		var hud: Node = root.get_node_or_null("Main/UI/MatchHud")
		if hud != null:
			hud.visible = false
		var content := ContentLibrary.load_default()
		var park := content.park(_park_id)
		var playing: MatchRoster = _view._roster
		for team in content.teams:
			if team.stadium_def == park:
				_view.set_roster(MatchRoster.new(playing.teams[MatchState.AWAY], team))
		_view.set_park(content.tuning_for(park), park)
		return false
	if _frames == 20:
		var director: Node = root.get_node_or_null("Main/MatchDirector")
		if director != null:
			director.set_process(false)
		var hit: Array = get_meta("hit")
		_traj = BallTrajectory.simulate(hit[0], hit[1], hit[2], _view.tuning)
		print("result ", BallTrajectory.Result.keys()[_traj.result], " wall ", roundi(_traj.distance() * 3.28), " ft projected ", roundi(_traj.projected_distance() * 3.28), " ft")
		var club: TeamDef = _view._roster.teams[MatchState.HOME]
		var hitter: PlayerDef = club.roster[0] if not club.roster.is_empty() else null
		_view.start_flight(_traj, _traj.result == BallTrajectory.Result.HOME_RUN, INF, {"team": club, "name": hitter.display_name if hitter != null else "", "number": hitter.number if hitter != null else 0, "exit_velocity": roundi(hit[0] * 2.237), "launch": roundi(hit[1]), "runs": 1})
		var land := _view._flight_land_t
		_times = [0.2, 1.2, 2.4, maxf(_traj.end_time() - 0.5, 2.6), land - 0.3, land + 0.5, land + 2.0, land + 3.5]
		_view.step_flight(0.0)
		return false
	if _frames < 20:
		return false
	if _shot >= _times.size():
		if true:
			var w := 480
			var sheet := Image.create(w * 4, 270 * 2, false, Image.FORMAT_RGB8)
			for i in _images.size():
				var im := _images[i]
				im.convert(Image.FORMAT_RGB8)
				im.resize(w, 270)
				sheet.blit_rect(im, Rect2i(0, 0, w, 270), Vector2i((i % 4) * w, (i / 4) * 270))
			sheet.save_png(_out)
			return true
		return false
	# Settle the camera on each moment for a few frames, then grab it.
	var t: float = _times[_shot]
	var k := (_frames - 20) % 24
	_view.step_flight(t - 0.4 + 0.4 * k / 23.0)
	if k == 23:
		_images.append(root.get_texture().get_image())
		_shot += 1
	return false
