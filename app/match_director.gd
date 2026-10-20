class_name MatchDirector
extends Node
## Runs one interactive match. Turns semantic input into the same intents
## the AI produces, hands them to the pure resolvers, applies results to
## MatchState and tells the view/HUD what to show. Real-time windows (pitch
## meter, swing, throw choice) live here; baseball outcomes never do.

enum Phase { PRE_PITCH, METER, PITCH_FLIGHT, CALL, BALL_IN_PLAY, GAME_OVER }

# Presentation pacing (seconds). Kept short: no dead air between pitches.
const AI_PRE_PITCH_DELAY := 1.8
# The last part of the pre-pitch is the pitcher's visible windup.
const WINDUP_TIME := 0.7
const CALL_PAUSE := 0.8
const PLAY_SETTLE_PAUSE := 0.9
# How long a human fielder can hold the ball before the AI throw is used.
const THROW_DECISION_WINDOW := 0.6
# Cursor speed in the plate plane, meters per second.
const CURSOR_SPEED := 1.5

var content: ContentLibrary
var tuning: BaseballTuning
var state: MatchState
var rng: MatchRng
var user_team := MatchState.AWAY

var _view: MatchView
var _hud: MatchHud
var _debug: DebugOverlay
var _phase := Phase.PRE_PITCH
var _phase_time := 0.0
var _cursor := Vector2.ZERO
var _selected_pitch := 0
var _meter := 0.0
var _pitch: PitchResult
var _ai_swing: SwingIntent
var _contact: ContactResult
var _bip: BallInPlay
var _live: LiveFielding
var _dive_requested := false
var _play: LivePlay
var _play_event_cursor := 0
var _play_done_at := -1.0
var _outcome: PlayOutcome
var _event_cursor := 0
## Swing timing clock. Wall-clock microseconds in play; tools that run
## faster than real time (--fixed-fps) switch to accumulated frame time.
var use_wall_clock := true
var _virtual_usec := 0
var _last_frame_usec := -1
var _frame_interval := 1.0 / 60.0
var _pitch_release_usec := 0
var _pending_swing := SwingIntent.Type.NONE
var _pending_swing_usec := 0
var _pending_stick := Vector2.ZERO
var _input_log: Array[Dictionary] = []


func setup(p_content: ContentLibrary, view: MatchView, hud: MatchHud, debug: DebugOverlay) -> void:
	content = p_content
	tuning = content.tuning
	_view = view
	_hud = hud
	_debug = debug


func start_match(seed_value: int) -> void:
	rng = MatchRng.new(seed_value)
	state = MatchState.new(MatchState.placeholder_lineup("away"), MatchState.placeholder_lineup("home"), tuning.innings)
	_event_cursor = 0
	_input_log.clear()
	print("[match] seed=%d" % seed_value)
	_debug.set_section("match", {"seed": seed_value})
	_view.clear_debug_play()
	_hud.show_callout("PLAY BALL", "Batting: press J (or click) as the white ring closes on the plate", 4.0)
	_enter_pre_pitch()


func user_is_batting() -> bool:
	return state.batting_team() == user_team


# Read-only accessors for tools (playtest bot, future replay tooling).
func current_phase() -> Phase:
	return _phase


func phase_time() -> float:
	return _phase_time


func current_pitch() -> PitchResult:
	return _pitch


func meter_value() -> float:
	return _meter


func ball_in_play() -> BallInPlay:
	return _bip


func live_fielding() -> LiveFielding:
	return _live


## Tool hook: place the aim/bat cursor directly (bots, tests).
func debug_set_cursor(at: Vector2) -> void:
	_cursor = at.clamp(tuning.cursor_min, tuning.cursor_max)


## Swings are stamped here, as the event arrives, not when _process polls.
func _input(event: InputEvent) -> void:
	if state == null or _phase != Phase.PITCH_FLIGHT or not user_is_batting():
		return
	if _contact != null or _pending_swing != SwingIntent.Type.NONE:
		return
	var type := SwingIntent.Type.NONE
	if event.is_action_pressed(&"swing_contact"):
		type = SwingIntent.Type.CONTACT
	elif event.is_action_pressed(&"swing_power"):
		type = SwingIntent.Type.POWER
	if type == SwingIntent.Type.NONE:
		return
	_pending_swing = type
	_pending_swing_usec = _now_usec()
	_pending_stick = Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up")


func _process(delta: float) -> void:
	if state == null:
		return
	_tick_clock(delta)
	_phase_time += delta
	_handle_global_input()
	match _phase:
		Phase.PRE_PITCH:
			_process_pre_pitch(delta)
		Phase.METER:
			_process_meter(delta)
		Phase.PITCH_FLIGHT:
			_process_pitch_flight(delta)
		Phase.CALL:
			if _phase_time >= CALL_PAUSE:
				_enter_pre_pitch()
		Phase.BALL_IN_PLAY:
			_process_ball_in_play()
		Phase.GAME_OVER:
			pass
	_drain_events()
	_hud.show_state(state, user_team)
	_update_debug()


func _handle_global_input() -> void:
	if Input.is_action_just_pressed(&"toggle_debug"):
		_debug.visible = not _debug.visible
		_view.set_debug_visible(_debug.visible)
	if Input.is_action_just_pressed(&"restart_match"):
		start_match(int(Time.get_ticks_usec() % 1000000))
	if Input.is_action_just_pressed(&"toggle_assist"):
		tuning.rookie_assist = not tuning.rookie_assist
		_hud.show_callout("ROOKIE ASSIST %s" % ("ON" if tuning.rookie_assist else "OFF"), "slower pitches, wider timing window")
		_hud.show_prompt(_hud_prompt_suffix())
	if Input.is_action_just_pressed(&"switch_side"):
		user_team = MatchState.HOME if user_team == MatchState.AWAY else MatchState.AWAY
		_hud.show_callout("YOU CONTROL %s" % ("AWAY" if user_team == MatchState.AWAY else "HOME"))
		if _phase == Phase.PRE_PITCH:
			_enter_pre_pitch()


# --- Pitch setup ---------------------------------------------------------

func _enter_pre_pitch() -> void:
	if state.game_over:
		_enter_game_over()
		return
	_set_phase(Phase.PRE_PITCH)
	_view.reset_for_pitch(state)
	_bip = null
	_outcome = null
	_meter = 0.0
	_cursor = PitchResolver.zone_center(tuning)
	if user_is_batting():
		_view.set_camera_mode(MatchView.CameraMode.BAT)
		_hud.show_pitching(false)
	else:
		_view.set_camera_mode(MatchView.CameraMode.PITCH)
		_hud.show_pitching(true, content.pitches, _selected_pitch)
		_hud.set_meter(0.0, tuning.pitch_meter_sweet_spot)
	_hud.show_prompt(_hud_prompt_suffix())


func _process_pre_pitch(delta: float) -> void:
	if user_is_batting():
		_show_stick_marker()
		var windup_start := AI_PRE_PITCH_DELAY - WINDUP_TIME
		if _phase_time >= windup_start:
			_view.show_windup((_phase_time - windup_start) / WINDUP_TIME)
		if _phase_time >= AI_PRE_PITCH_DELAY:
			var intent := AiPitcher.choose(state, content.pitches, tuning, rng)
			if tuning.rookie_assist:
				intent.speed_scale = tuning.assist_pitch_speed_scale
			_throw_pitch(intent)
		return
	_move_cursor(delta)
	_view.set_cursor(_cursor, 0.07, 0.0, Color(0.3, 0.95, 1.0))
	var count := content.pitches.size()
	if Input.is_action_just_pressed(&"pitch_next"):
		_selected_pitch = (_selected_pitch + 1) % count
	if Input.is_action_just_pressed(&"pitch_prev"):
		_selected_pitch = (_selected_pitch + count - 1) % count
	_hud.show_pitching(true, content.pitches, _selected_pitch)
	if Input.is_action_just_pressed(&"pitch_primary"):
		_set_phase(Phase.METER)
		_hud.show_prompt("Release in the white band: Space / A")


func _process_meter(delta: float) -> void:
	_move_cursor(delta)
	_view.set_cursor(_cursor, 0.07, 0.0, Color(0.3, 0.95, 1.0))
	_meter = minf(_meter + delta / tuning.pitch_meter_sweep_time, 1.0)
	_hud.set_meter(_meter, tuning.pitch_meter_sweet_spot)
	if Input.is_action_just_pressed(&"pitch_primary") or _meter >= 1.0:
		var family := content.pitches[_selected_pitch]
		var error := PitchResolver.meter_error(_meter, tuning)
		_throw_pitch(PitchIntent.new(family.id, _cursor, error))


func _throw_pitch(intent: PitchIntent) -> void:
	var family := content.pitch(intent.family_id)
	_pitch = PitchResolver.resolve(intent, family, tuning, rng)
	state.record_pitch(_pitch.to_dict())
	_log({"pitch": state.pitch_count, "family": intent.family_id, "aim": intent.aim, "meter_error": snappedf(intent.meter_error, 0.001)})
	_ai_swing = null
	_contact = null
	if not user_is_batting():
		_ai_swing = AiBatter.decide(_pitch, family, state, tuning, rng)
		_hud.show_pitching(false)
		_view.set_cursor(_cursor, 0.0, 0.0, Color.WHITE)
	_debug.clear_section("contact")
	_pending_swing = SwingIntent.Type.NONE
	_pitch_release_usec = _now_usec()
	_view.show_windup(-1.0)
	_set_phase(Phase.PITCH_FLIGHT)


# --- Pitch flight and swing ------------------------------------------------

func _process_pitch_flight(_delta: float) -> void:
	var travel := _pitch.travel_time
	# Flight runs on the same clock the swing is judged on.
	var flight := float(_now_usec() - _pitch_release_usec) / 1000000.0
	_view.show_pitch(_pitch, minf(flight, travel))
	var timing := flight - travel
	if user_is_batting():
		_view.show_timing_ring(flight / travel if _contact == null or flight < travel else -1.0)
	if _contact == null:
		if user_is_batting():
			_show_stick_marker()
			if _pending_swing != SwingIntent.Type.NONE:
				var offset := SwingTiming.offset(_pending_swing_usec, _pitch_release_usec, travel,
					_frame_interval, tuning.swing_latency_calibration)
				var swing := SwingIntent.swing(_pending_swing, offset, _pending_stick)
				if tuning.rookie_assist:
					swing.window_scale = tuning.assist_timing_window_scale
				_resolve_swing(swing)
		elif _ai_swing.type != SwingIntent.Type.NONE and timing >= _ai_swing.timing_offset:
			_resolve_swing(_ai_swing)
		if _contact == null and timing >= tuning.swing_late_cutoff:
			_resolve_swing(SwingIntent.take())
	# The ball always reaches the plate before the result plays out.
	if _contact != null and flight >= travel:
		_view.show_pitch_marker(_pitch)
		if _contact.outcome == ContactResult.Outcome.IN_PLAY:
			_start_ball_in_play()
		else:
			_apply_call()


func _resolve_swing(swing: SwingIntent) -> void:
	_contact = ContactResolver.resolve(_pitch, swing, tuning, rng)
	_log({"swing": SwingIntent.Type.keys()[swing.type], "timing_ms": roundi(swing.timing_offset * 1000.0), "stick": swing.stick})
	if swing.type != SwingIntent.Type.NONE:
		_view.swing_bat()
		var ms := roundi(swing.timing_offset * 1000.0)
		var when := "PERFECT" if absi(ms) <= 15 else ("EARLY %d ms" % -ms if ms < 0 else "LATE %d ms" % ms)
		_hud.show_callout("", when, 1.0)


func _apply_call() -> void:
	var call := ContactResolver.call_for(_pitch, _contact) as MatchState.PitchCall
	var text: String = {
		MatchState.PitchCall.BALL: "BALL",
		MatchState.PitchCall.CALLED_STRIKE: "STRIKE",
		MatchState.PitchCall.SWINGING_STRIKE: "SWING & MISS",
		MatchState.PitchCall.FOUL: "FOUL",
	}[call]
	_hud.show_callout(text, _timing_detail(), 1.0)
	state.apply_pitch_call(call)
	_set_phase(Phase.CALL)


# --- Ball in play ---------------------------------------------------------

func _start_ball_in_play() -> void:
	_bip = BallInPlay.create(_contact, state, tuning)
	_play = null
	_outcome = null
	_play_event_cursor = 0
	_play_done_at = -1.0
	_view.show_debug_play(_bip)
	_view.set_camera_mode(MatchView.CameraMode.FIELD)
	_view.set_cursor(Vector2.ZERO, 0.0, 0.0, Color.WHITE)
	_live = null
	_dive_requested = false
	if _bip.is_home_run():
		_play_done_at = _bip.home_run_settle_time()
		_finish_play(RunnerResolver.home_run(_bip.bases_before, _bip.batter_id))
	else:
		var human_fields := not user_is_batting() and _bip.fielding.has_fielder()
		if human_fields:
			# The human steers whoever the projection says gets there first.
			_live = LiveFielding.new(_bip.trajectory, _bip.fielders, _bip.fielding, tuning, _bip.fielding.fielder_index)
		_play = _bip.start_live(not human_fields)
		_play.human_defense = not user_is_batting()
	_set_phase(Phase.BALL_IN_PLAY)
	_hud.show_prompt(_hud_prompt_suffix())


func _process_ball_in_play() -> void:
	var t := _phase_time
	if _play != null and _outcome == null:
		_step_play(t)
	var selected: StringName = &""
	if user_is_batting() and _play != null and _outcome == null and _held_base() > 0:
		var r := _play.runner_for_base(_held_base())
		selected = r.id if r != null else &""
	_view.show_play(_bip, t, _play, _outcome, _live, selected)
	_view.set_field_focus(_field_focus(t))
	if _outcome == null:
		return
	var skip := Input.is_action_just_pressed(&"swing_contact") or Input.is_action_just_pressed(&"pitch_primary")
	if t >= _play_done_at + PLAY_SETTLE_PAUSE or (skip and t > _play_done_at):
		state.apply_play(_outcome)
		_enter_pre_pitch()


## Steps fielding and the live play together at the fixed sim step, feeding
## the human's intents to whichever side they control.
func _step_play(t: float) -> void:
	var defense := {}
	var offense := {}
	var move := Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up")
	if user_is_batting():
		# Hold a base button to order just that runner; otherwise all of them.
		offense = {"advance": Input.is_action_just_pressed(&"runner_advance"), "retreat": Input.is_action_just_pressed(&"runner_retreat"), "base": _held_base()}
	else:
		for base in [1, 2, 3, 4]:
			if Input.is_action_just_pressed(StringName("throw_base_%d" % base)):
				defense["throw"] = base
		defense["move"] = move if _live == null or _live.is_secured() else Vector2.ZERO
		if _live != null and not _live.is_secured():
			if Input.is_action_just_pressed(&"switch_fielder"):
				_live.switch_to_nearest()
			if Input.is_action_just_pressed(&"dive"):
				_dive_requested = true
	var dt := tuning.sim_step
	while _play.time + dt <= t and not _play.is_done():
		if _live != null and not _live.is_secured():
			_live.step(dt, move, _dive_requested)
			_dive_requested = false
			if _live.is_secured():
				_play.secure(_live.result)
				_bip.fielding = _live.result
				_log({"fielded": _live.result.fielder_id, "time": snappedf(_live.result.secure_time, 0.01), "in_air": _live.result.caught_in_air, "dive": _live.result.is_dive, "missed_dives": _live.dives_missed})
		_play.step(dt, defense, offense)
		defense.erase("throw")  # one-shot inputs apply to one step only
		offense = {}
	_drain_play_events()
	if _play.is_done():
		_play_done_at = _play.time
		_finish_play(_play.outcome())


## Base button held down (1..4), or 0.
func _held_base() -> int:
	for base in [1, 2, 3, 4]:
		if Input.is_action_pressed(StringName("throw_base_%d" % base)):
			return base
	return 0


func _drain_play_events() -> void:
	while _play_event_cursor < _play.events.size():
		var e: Dictionary = _play.events[_play_event_cursor]
		_play_event_cursor += 1
		match e["type"]:
			"out":
				var labels := {PlayOutcome.OUT_FORCE: "FORCE OUT", PlayOutcome.OUT_TAG: "TAGGED OUT", PlayOutcome.OUT_DOUBLED_OFF: "DOUBLED OFF", PlayOutcome.OUT_CATCH: "CAUGHT"}
				_hud.show_callout(labels.get(e["kind"], "OUT"), "at %s" % FieldLayout.base_name(e["base"]), 1.2)
				_log({"out": e["runner"], "kind": e["kind"], "base": e["base"], "time": snappedf(_play.time, 0.01)})
			"rundown":
				_hud.show_callout("RUNDOWN!", "", 1.0)
			"throw":
				_log({"throw": e["base"], "time": snappedf(_play.time, 0.01)})


func _field_focus(t: float) -> Vector3:
	var ball := _play.ball_position() if _play != null else _bip.trajectory.position_at(t)
	var focus := Vector3(ball.x, 0.0, ball.z)
	if _live != null and not _live.is_secured() and _live.controlled >= 0:
		focus = focus.lerp(_live.positions[_live.controlled], 0.5)
	return focus.lerp(Vector3(0.0, 0.0, -30.0), 0.35)


func _finish_play(outcome: PlayOutcome) -> void:
	_outcome = outcome
	_log({"outcome": _outcome.kind, "throws": _outcome.throws.map(func(leg: Dictionary) -> int: return leg["base"]), "runs": _outcome.runs.size(), "outs": _outcome.outs.size()})
	var detail := "%.1f m/s  %d°  %.0f m" % [_contact.exit_velocity, roundi(_contact.launch_angle), _bip.trajectory.distance()]
	var text := String(_outcome.kind).replace("_", " ").to_upper()
	if _outcome.kind == PlayOutcome.KIND_DOUBLE_PLAY or _outcome.kind == PlayOutcome.KIND_TRIPLE_PLAY:
		text += "!"
	elif _bip.fielding.is_dive and _bip.fielding.caught_in_air:
		text = "DIVING CATCH!"
	_hud.show_callout(text, detail, 2.0)
	_hud.show_prompt(_hud_prompt_suffix())


# --- Game over / events / debug --------------------------------------------

func _enter_game_over() -> void:
	_set_phase(Phase.GAME_OVER)
	_view.set_camera_mode(MatchView.CameraMode.FIELD)
	_hud.show_pitching(false)
	var winner := "AWAY" if state.winner() == MatchState.AWAY else "HOME"
	_hud.show_callout("FINAL", "%s WINS %d-%d" % [winner, state.score[MatchState.AWAY], state.score[MatchState.HOME]], 3600.0)
	_hud.show_prompt("New match: F5 / Start")
	print("[match] final %s  line %s" % [state.score, state.line_score])


func _drain_events() -> void:
	while _event_cursor < state.events.size():
		var event := state.events[_event_cursor]
		_event_cursor += 1
		_debug.push_event(event)
		match event.type:
			DomainEvent.PLATE_APPEARANCE_ENDED:
				if event.data["result"] == &"strikeout":
					_hud.show_callout("STRUCK OUT", _timing_detail())
				elif event.data["result"] == &"walk":
					_hud.show_callout("WALK")
			DomainEvent.HALF_INNING_ENDED:
				_hud.show_callout("SIDE RETIRED", "%d run%s" % [event.data["runs"], "" if event.data["runs"] == 1 else "s"])


func _update_debug() -> void:
	var snap := state.snapshot()
	snap["phase"] = Phase.keys()[_phase]
	snap["user_team"] = "AWAY" if user_team == MatchState.AWAY else "HOME"
	snap["seed"] = rng.seed_value
	_debug.set_section("match", snap)
	if _pitch != null:
		var p := _pitch.to_dict()
		p["travel_time"] = snappedf(_pitch.travel_time, 0.001)
		_debug.set_section("pitch", p)
	if _contact != null:
		_debug.set_section("contact", _contact.to_dict())
	if _bip != null:
		_debug.set_section("flight", _bip.trajectory.to_dict())
		var f := _bip.fielding.to_dict()
		var candidates := _bip.fielding.candidates.duplicate()
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["time"] < b["time"])
		f["next_best"] = candidates.slice(1, 3).map(func(c: Dictionary) -> String: return "%s %.2fs" % [c["id"], c["time"]])
		_debug.set_section("fielding", f)
		if _play != null:
			_debug.set_section("runners", _play.runners.map(func(r: LivePlay.Runner) -> String: return "%s %s->%d s=%.1f%s%s" % [r.id, LivePlay.State.keys()[r.state], r.target, r.s, " forced" if r.forced else "", " retouch" if r.must_retouch else ""]))
		if _outcome != null:
			_debug.set_section("outcome", {"kind": _outcome.kind, "throws": _outcome.throws.map(func(leg: Dictionary) -> String: return "%s@%.2f" % [FieldLayout.base_name(leg["base"]), leg["arrival"]]), "runs": _outcome.runs, "outs": _outcome.outs.map(func(o: Dictionary) -> String: return "%s %s@%s" % [o["runner_id"], o["kind"], FieldLayout.base_name(o["base"])])})


func _timing_detail() -> String:
	if _contact == null or _contact.swing_type == SwingIntent.Type.NONE:
		return ""
	return "timing %+d ms" % roundi(_contact.timing_offset * 1000.0)


func _hud_prompt_suffix() -> String:
	var role := "BATTING" if user_is_batting() else "PITCHING / FIELDING"
	var base := ""
	match _phase:
		Phase.PRE_PITCH, Phase.PITCH_FLIGHT:
			if user_is_batting():
				base = "Watch the pitcher. SWING as the ring closes: J or click (contact) / K or right-click (power)\nHold WASD / L-stick while swinging: ←→ aim field  ↑ lift  ↓ chop"
			else:
				base = "Aim: WASD / L-stick    Pitch: Q E / LB RB    Start meter: Space / A"
		Phase.BALL_IN_PLAY:
			if _outcome != null:
				base = "Skip: J / A"
			elif user_is_batting():
				base = "Runners: advance E / RB   retreat Q / LB   (hold 1-4 / B Y X A for one runner)"
			else:
				base = "Run: WASD / L-stick   Dive: Shift / RT   Switch: F / LT   Throw (again to relay) 1st-2nd-3rd-home: 1-4 / B Y X A"
	var assist := "   Rookie assist: %s (T)" % ("ON" if tuning.rookie_assist else "OFF") if user_is_batting() else ""
	return "%s\n[%s]   Tab/Back: switch side   ` or F1: debug   R or F5: restart%s" % [base, role, assist]


## Reads the batting stick and shows it as a small marker on the zone:
## where in the zone it points is the direction/loft it will add.
func _show_stick_marker() -> Vector2:
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up")
	var half := Vector2(tuning.zone_half_width, (tuning.zone_top - tuning.zone_bottom) * 0.5)
	_view.set_cursor(PitchResolver.zone_center(tuning) + stick * half, 0.05, 0.0, Color(1.0, 0.85, 0.2))
	return stick


func _move_cursor(delta: float) -> void:
	var dir := Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up")
	_cursor += dir * CURSOR_SPEED * delta
	_cursor = _cursor.clamp(tuning.cursor_min, tuning.cursor_max)


func _now_usec() -> int:
	return Time.get_ticks_usec() if use_wall_clock else _virtual_usec


func _tick_clock(delta: float) -> void:
	_virtual_usec += roundi(delta * 1000000.0)
	var now := _now_usec()
	if _last_frame_usec >= 0:
		_frame_interval = float(now - _last_frame_usec) / 1000000.0
	_last_frame_usec = now


func _set_phase(phase: Phase) -> void:
	_phase = phase
	_phase_time = 0.0


func _log(entry: Dictionary) -> void:
	_input_log.append(entry)
	print("[play] ", entry)
