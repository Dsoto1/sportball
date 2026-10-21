extends SceneTree
## Drives the real interactive scene with simulated semantic input so the
## whole director loop (pitch -> swing -> ball in play -> throw -> reset)
## is exercised end to end. Optionally saves screenshots.
##   godot --path . -s res://tools/playtest_bot.gd -- [seconds] [screenshot_dir] [home]
## Pass `home` to control the home team (field first).
## Headless works for logic; screenshots need a rendering display.

const FRAME := 1.0 / 60.0

var _director: MatchDirector
var _rng := RandomNumberGenerator.new()
var _pressed: Array[StringName] = []
var _sim_seconds := 120.0
var _shot_dir := ""
var _shots_taken := 0
var _elapsed := 0.0
var _swing_offset := 0.0
var _planned_pitch: PitchResult
var _last_phase := -1
var _plays := 0
var _control_home := false
var _events_down: Array[StringName] = []
## One of each: a pitching change, a pinch hitter, a pitch-clock violation.
var _did_pitching_change := false
var _did_pinch_hit := false
var _did_clock := false
var _waiting_clock := false
var _bunt_shot := 0
var _swing_shots := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_sim_seconds = float(args[0])
	if args.size() > 1:
		_shot_dir = args[1]
		DirAccess.make_dir_recursive_absolute(_shot_dir)
	_control_home = args.size() > 2 and args[2] == "home"
	_rng.seed = 42
	var main: Node = load("res://app/main.tscn").instantiate()
	root.add_child(main)


func _process(delta: float) -> bool:
	if _director == null:
		_director = root.get_node_or_null("Main/MatchDirector")
		if _director != null:
			# --fixed-fps runs faster than real time: judge swings on frame time.
			_director.use_wall_clock = false
			if _control_home:
				_director.user_team = MatchState.HOME
		return false
	for action in _pressed:
		Input.action_release(action)
	_pressed.clear()
	for action in _events_down:
		_send(action, false)
	_events_down.clear()
	_elapsed += delta
	_drive()
	if _director.state.game_over or _elapsed >= _sim_seconds:
		print("[bot] stopped after %.1fs sim, plays=%d, score=%s, inning=%d, game_over=%s" % [
			_elapsed, _plays, _director.state.score, _director.state.inning, _director.state.game_over])
		return true
	return false


func _drive() -> void:
	if _bunt_shot > 0:
		_bunt_shot -= 1
		if _bunt_shot == 0:
			_screenshot("bunt")
	var phase := _director.current_phase()
	var entered := phase != _last_phase
	_last_phase = phase
	var batting := _director.user_is_batting()
	if _waiting_clock and phase != MatchDirector.Phase.PRE_PITCH:
		_waiting_clock = false
		_did_clock = true
	match phase:
		MatchDirector.Phase.PREGAME:
			if _director.phase_time() > 0.3 and _shots_taken == 0:
				_screenshot("pregame")
			if _director.phase_time() > 0.5:
				_press(&"swing_power" if _control_home else &"swing_contact")
		MatchDirector.Phase.PRE_PITCH:
			var inning := _director.state.inning
			if _director.sub_menu_open():
				_press(&"swing_contact" if batting else &"pitch_primary")
				return
			if not batting and not _did_clock and inning >= 2:
				_waiting_clock = true
				return  # let the pitch clock run out once
			if _director.phase_time() > 0.15 and _director.phase_time() < 0.25 and inning >= 3:
				if not batting and not _did_pitching_change:
					_did_pitching_change = true
					_press(&"open_subs")
					return
				if batting and not _did_pinch_hit:
					_did_pinch_hit = true
					_press(&"open_subs")
					return
			if batting and entered and (_director.state.runner_on(1) != &"" or _director.state.runner_on(2) != &"") and _rng.randf() < 0.3:
				_press(&"runner_advance")  # steal on this pitch
			if not batting and entered and _director.state.runner_on(1) != &"" and _rng.randf() < 0.3:
				_press(&"slide_step")  # toggle the quick delivery
			if not batting and entered and _director.state.can_pickoff() and _rng.randf() < 0.15:
				_press(&"pickoff")  # throw over first
				return
			if not batting and _director.phase_time() > 0.3:
				_director.debug_set_cursor(Vector2(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.5, 1.1)))
				_press(&"pitch_primary")
		MatchDirector.Phase.METER:
			if absf(_director.meter_value() - _director.tuning.pitch_meter_sweet_spot) < 0.03 + _rng.randf() * 0.05:
				_press(&"pitch_primary")
		MatchDirector.Phase.PITCH_FLIGHT:
			var pitch := _director.current_pitch()
			if entered:
				_planned_pitch = pitch
				_swing_offset = _rng.randfn(0.0, 0.05)
				if _shots_taken < 3:
					_screenshot("pitch")
			if batting and pitch != null:
				if _rng.randf() < 0.5:
					_press(&"aim_up" if _rng.randf() < 0.5 else &"aim_down", _rng.randf())
				# The event is seen next frame, so press one frame ahead.
				if _director.phase_time() + FRAME >= pitch.travel_time + _swing_offset and PitchResolver.in_zone(pitch.location, _director.tuning):
					var roll := _rng.randf()
					var bunt_chance := 0.4 if _director.state.runner_on(1) != &"" else 0.08
					var swing := &"swing_bunt" if roll < bunt_chance else (&"swing_power" if roll < bunt_chance + 0.25 else &"swing_contact")
					_send(swing, true)
					if swing == &"swing_bunt":
						_bunt_shot = 3
					elif _swing_shots < 2:
						_swing_shots += 1
						_bunt_shot = 7  # mid-swing
					_events_down.append(swing)
		MatchDirector.Phase.BALL_IN_PLAY:
			if entered:
				_plays += 1
			var bip := _director.ball_in_play()
			if bip != null and bip.is_steal() and _director.phase_time() > 0.9 and _director.phase_time() < 0.95:
				_screenshot("steal")
			var live := _director.live_fielding()
			if live != null and not live.is_secured():
				_steer(live)
			if batting and _director.phase_time() > 0.3 and _rng.randf() < 0.01:
				if _rng.randf() < 0.5:
					_press(StringName("throw_base_%d" % _rng.randi_range(1, 4)))  # single runner
				_press(&"runner_advance" if _rng.randf() < 0.6 else &"runner_retreat")
			if not batting and _director.phase_time() > 0.5 and _rng.randf() < 0.02:
				if _rng.randf() < 0.5:
					_press(StringName("throw_base_%d" % _rng.randi_range(1, 4)))
				else:
					# Directional throw: hold toward a base (or nothing) and press throw.
					var dirs: Array[StringName] = [&"aim_right", &"aim_up", &"aim_left", &"aim_down"]
					if _rng.randf() < 0.8:
						_press(dirs[_rng.randi_range(0, 3)])
					_press(&"throw_ball")
			var shot_chance := 0.08 if (live != null and not live.is_secured()) else 0.01
			if _director.phase_time() > 0.8 and _shots_taken < 12 and _rng.randf() < shot_chance:
				_screenshot("field" if live != null else "play")


## Runs the controlled fielder at the landing spot (or the ball once down),
## with some sloppiness, and dives when the ball is just out of reach.
func _steer(live: LiveFielding) -> void:
	var traj := live.trajectory
	var goal := traj.landing_point if traj.is_airborne_at(live.time) else traj.position_at(live.time + 0.8)
	var me := live.positions[live.controlled]
	var d := Vector2(goal.x - me.x, -(goal.z - me.z))
	if d.length() < 0.3:
		return
	d = (d.normalized() + Vector2(_rng.randfn(0, 0.25), _rng.randfn(0, 0.25))).normalized()
	_press(&"aim_right" if d.x > 0 else &"aim_left", absf(d.x))
	_press(&"aim_up" if d.y > 0 else &"aim_down", absf(d.y))
	var ball := traj.position_at(live.time)
	var gap := Vector2(ball.x - me.x, ball.z - me.z).length()
	if traj.is_airborne_at(live.time) and ball.y < 2.0 and gap > live.fielders[live.controlled].reach and gap < 2.0 and _rng.randf() < 0.3:
		_press(&"dive")


## Swings go through the event path (_input), like a real key press.
func _send(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _press(action: StringName, strength: float = 1.0) -> void:
	Input.action_press(action, strength)
	_pressed.append(action)


func _screenshot(tag: String) -> void:
	if _shot_dir == "" or _shots_taken >= 12 or DisplayServer.get_name() == "headless":
		return
	var image := root.get_texture().get_image()
	var path := _shot_dir.path_join("%02d_%s.png" % [_shots_taken, tag])
	image.save_png(path)
	_shots_taken += 1
	print("[bot] screenshot ", path)
