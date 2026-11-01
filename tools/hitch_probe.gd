extends SceneTree
## Plays a match with the AI batting (the user fields; the fielders run
## themselves with rookie assist) and logs every slow frame: the process
## time and the frame's wall time, with the match phase and what just
## happened. Finds stutters and freezes. Needs a display:
##   godot --path . --resolution 640x360 -s res://tools/hitch_probe.gd -- [frames]
var _frames := 0
var _director: MatchDirector
var _picked := false
var _last := 0
var _limit := 2400
var _phase := -1
var _since := 0
var _log: Array = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_limit = int(args[0])
	root.add_child(load("res://app/main.tscn").instantiate())
	_last = Time.get_ticks_usec()


func _process(_d: float) -> bool:
	_frames += 1
	var now := Time.get_ticks_usec()
	var wall := (now - _last) / 1000.0
	_last = now
	if _director == null:
		_director = root.get_node_or_null("Main/MatchDirector")
		return false
	# Bisecting: switch parts off (args "nostadium", "nohud", "noboards").
	var args := OS.get_cmdline_user_args()
	if _frames == 10:
		var view: MatchView = root.get_node("Main/MatchView")
		if args.has("nostadium") and view._stadium != null:
			view._stadium.process_mode = Node.PROCESS_MODE_DISABLED
		if args.has("noboards") and view._stadium != null:
			for vp: SubViewport in view._stadium.find_children("*", "SubViewport", true, false):
				vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
				vp.process_mode = Node.PROCESS_MODE_DISABLED
		if args.has("nohud"):
			var hud: Node = root.get_node("Main/UI/MatchHud")
			hud.process_mode = Node.PROCESS_MODE_DISABLED
			hud.visible = false
	if not _picked and _frames > 20:
		var press := InputEventAction.new()
		press.action = &"swing_power"  # field first: the AI bats
		press.pressed = true
		Input.parse_input_event(press)
		_picked = true
		return false
	if _frames == 22:
		var up := InputEventAction.new()
		up.action = &"swing_power"
		up.pressed = false
		Input.parse_input_event(up)
	var phase: int = _director._phase
	if phase != _phase:
		_phase = phase
		_since = _frames
	# Pitch for the user: start and stop the meter every pitch.
	if phase == MatchDirector.Phase.PRE_PITCH and (_frames - _since) == 30:
		Input.action_press(&"pitch_primary")
	if phase == MatchDirector.Phase.METER and (_frames - _since) == 8:
		Input.action_release(&"pitch_primary")
		Input.action_press(&"pitch_primary")
	if phase != MatchDirector.Phase.METER and phase != MatchDirector.Phase.PRE_PITCH:
		Input.action_release(&"pitch_primary")
	var proc := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_log.append([_frames, wall, proc, MatchDirector.Phase.keys()[phase], _frames - _since])
	if _frames >= _limit:
		_report()
		return true
	return false


func _report() -> void:
	var walls: Array = _log.map(func(e: Array) -> float: return e[1])
	walls.sort()
	var median: float = walls[walls.size() / 2]
	print("HITCH median frame %.1f ms over %d frames" % [median, _log.size()])
	var spikes := _log.filter(func(e: Array) -> bool: return e[1] > median * 2.5 or e[2] > 30.0)
	spikes.sort_custom(func(a: Array, b: Array) -> bool: return a[1] > b[1])
	for e: Array in spikes.slice(0, 25):
		print("HITCH frame %d wall %.0f ms process %.1f ms  %s +%d" % e)
