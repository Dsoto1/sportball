extends SceneTree
## Drives the real interactive scene with simulated semantic input so the
## whole director loop (pitch -> swing -> ball in play -> throw -> reset)
## is exercised end to end. Optionally saves screenshots.
##   godot --path . -s res://tools/playtest_bot.gd -- [seconds] [screenshot_dir]
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


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_sim_seconds = float(args[0])
	if args.size() > 1:
		_shot_dir = args[1]
		DirAccess.make_dir_recursive_absolute(_shot_dir)
	_rng.seed = 42
	var main: Node = load("res://app/main.tscn").instantiate()
	root.add_child(main)


func _process(delta: float) -> bool:
	if _director == null:
		_director = root.get_node_or_null("Main/MatchDirector")
		return false
	for action in _pressed:
		Input.action_release(action)
	_pressed.clear()
	_elapsed += delta
	_drive()
	if _director.state.game_over or _elapsed >= _sim_seconds:
		print("[bot] stopped after %.1fs sim, plays=%d, score=%s, inning=%d, game_over=%s" % [
			_elapsed, _plays, _director.state.score, _director.state.inning, _director.state.game_over])
		return true
	return false


func _drive() -> void:
	var phase := _director.current_phase()
	var entered := phase != _last_phase
	_last_phase = phase
	var batting := _director.user_is_batting()
	match phase:
		MatchDirector.Phase.PRE_PITCH:
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
				_screenshot("pitch")
			if batting and pitch != null:
				_director.debug_set_cursor(pitch.location + Vector2(_rng.randfn(0, 0.05), _rng.randfn(0, 0.05)))
				if _director.phase_time() >= pitch.travel_time + _swing_offset and PitchResolver.in_zone(pitch.location, _director.tuning):
					_press(&"swing_power" if _rng.randf() < 0.3 else &"swing_contact")
		MatchDirector.Phase.BALL_IN_PLAY:
			if entered:
				_plays += 1
			if not batting and _director.phase_time() > 0.5 and _rng.randf() < 0.02:
				_press(StringName("throw_base_%d" % _rng.randi_range(1, 4)))
			if _director.phase_time() > 1.2 and _shots_taken < 12 and _rng.randf() < 0.03:
				_screenshot("play")


func _press(action: StringName) -> void:
	Input.action_press(action)
	_pressed.append(action)


func _screenshot(tag: String) -> void:
	if _shot_dir == "" or _shots_taken >= 12 or DisplayServer.get_name() == "headless":
		return
	var image := root.get_texture().get_image()
	var path := _shot_dir.path_join("%02d_%s.png" % [_shots_taken, tag])
	image.save_png(path)
	_shots_taken += 1
	print("[bot] screenshot ", path)
