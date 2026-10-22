extends SceneTree
## Renders the video board flat: the scoreboard, then the home-run takeover
## at a few moments, to one image. Needs a display:
##   godot --path . --resolution 1280x720 -s res://tools/board_shots.gd -- /tmp/board.png [home_team] [away_team]
var _jumbo: Jumbotron
var _frames := 0
var _shots: Array[Image] = []
var _out := ""


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	var content := ContentLibrary.load_default()
	var home := content.team(StringName(args[1]) if args.size() > 1 else &"conductors")
	var away := content.team(StringName(args[2]) if args.size() > 2 else &"gearheads")
	_jumbo = Jumbotron.new()
	root.add_child(_jumbo)
	_jumbo.setup(home, away)
	var state := MatchState.from_teams(away, home, content.rules)
	state.score = [2, 3]
	state.inning = 7
	state.is_top = false
	state.balls = 2
	state.strikes = 1
	state.outs = 1
	_jumbo.show_state(state, MatchRoster.new(away, home))
	set_meta("home", home)


func _process(delta: float) -> bool:
	_frames += 1
	if _frames == 6:
		_shots.append(_jumbo.get_texture().get_image())
		var home: TeamDef = get_meta("home")
		_jumbo.play_moment(&"home_run", {"team": home, "name": home.roster[2].display_name, "number": home.roster[2].number, "distance": 441, "exit_velocity": 112, "launch": 27, "runs": 2})
	for at in [10, 40, 90]:
		if _frames == 6 + at:
			_shots.append(_jumbo.get_texture().get_image())
	if _frames > 100:
		var sheet := Image.create(1280, 720 * 2, false, Image.FORMAT_RGB8)
		for i in _shots.size():
			var im := _shots[i]
			im.convert(Image.FORMAT_RGB8)
			im.resize(640, 360)
			sheet.blit_rect(im, Rect2i(0, 0, 640, 360), Vector2i((i % 2) * 640, (i / 2) * 360))
		sheet.crop(1280, 720)
		sheet.save_png(_out)
		return true
	return false
