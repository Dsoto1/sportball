class_name MatchDirector
extends Node
## Runs one interactive match. Turns semantic input into the same intents
## the AI produces, hands them to the pure resolvers, applies results to
## MatchState and tells the view/HUD what to show. Real-time windows (pitch
## meter, swing, throw choice) live here; baseball outcomes never do.

enum Phase { PREGAME, PRE_PITCH, METER, PITCH_FLIGHT, CALL, BALL_IN_PLAY, GAME_OVER }

# Presentation pacing (seconds). Kept short: no dead air between pitches.
const AI_PRE_PITCH_DELAY := 1.8
# The last part of the pre-pitch is the pitcher's visible windup.
const WINDUP_TIME := 0.7
## Hit pause by contact tier (seconds the play clock holds after contact).
const HIT_STOP := {ContactFeedback.Tier.SOLID: 0.05, ContactFeedback.Tier.SWEET: 0.11}
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
var roster: MatchRoster

var _view: MatchView
var _hud: MatchHud
var _debug: DebugOverlay
var _phase := Phase.PRE_PITCH
var _phase_time := 0.0
## Hit pause: the play clock holds for this long after solid contact.
var _hit_stop := 0.0
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
## Substitution menu: open while not empty. Each option {label, out, in}.
var _sub_options: Array[Dictionary] = []
var _sub_selected := 0
## Who's on first: announced once each time he gets there.
var _who_on_first := false
## Human steal orders before the pitch: start base -> phase time pressed.
var _steal_orders := {}
## Runners going on this pitch: start base -> jump delay (s).
var _steals := {}


func setup(p_content: ContentLibrary, view: MatchView, hud: MatchHud, debug: DebugOverlay) -> void:
	content = p_content
	tuning = content.tuning
	_view = view
	_hud = hud
	_debug = debug


## A 6-inning exhibition: the first two clubs in the library, away at home.
func start_match(seed_value: int) -> void:
	rng = MatchRng.new(seed_value)
	roster = MatchRoster.new(content.teams[0], content.teams[1])
	state = MatchState.from_teams(roster.teams[0], roster.teams[1], content.rules)
	_event_cursor = 0
	_input_log.clear()
	_sub_options.clear()
	_who_on_first = false
	print("[match] seed=%d  %s at %s" % [seed_value, roster.teams[0].full_name(), roster.teams[1].full_name()])
	_debug.set_section("match", {"seed": seed_value})
	_view.clear_debug_play()
	_view.set_roster(roster)
	_hud.set_roster(roster)
	_view.reset_for_pitch(state)
	_view.set_camera_mode(MatchView.CameraMode.FIELD)
	_set_phase(Phase.PREGAME)
	var away := roster.teams[0]
	var home := roster.teams[1]
	_hud.show_card([
		[away.full_name().to_upper(), MatchHud.text_color(away), 54],
		[away.identity.get_slice(".", 0), Color(0.9, 0.9, 0.9), 18],
		["at", Color.WHITE, 26],
		[home.full_name().to_upper(), MatchHud.text_color(home), 54],
		[home.identity.get_slice(".", 0), Color(0.9, 0.9, 0.9), 18],
		["", Color.WHITE, 12],
		["%s · Exhibition · %d innings · %s rules" % [home.stadium, content.rules.innings, content.rules.display_name], Color.WHITE, 22],
		["Mercy rule at %d runs after %d · runner on second in extras · %ds pitch clock" % [content.rules.mercy_runs, content.rules.mercy_after_inning, roundi(content.rules.pitch_clock)], Color(0.85, 0.85, 0.85), 16],
	])
	_hud.show_prompt("Play as the %s (bat first): J / click / A      Play as the %s (field first): K / right-click / X" % [away.team_name.to_upper(), home.team_name.to_upper()])


func _process_pregame() -> void:
	var pick := -1
	if Input.is_action_just_pressed(&"swing_contact"):
		pick = MatchState.AWAY
	elif Input.is_action_just_pressed(&"swing_power"):
		pick = MatchState.HOME
	if pick < 0:
		return
	user_team = pick
	_hud.show_card([])
	var hint := "You bat first: swing as the white ring closes on the plate" if pick == MatchState.AWAY else "You pitch first: aim, then stop the meter in the white band"
	_hud.show_callout("PLAY BALL", "You are the %s. %s" % [roster.teams[pick].full_name(), hint], 3.0)
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


func sub_menu_open() -> bool:
	return not _sub_options.is_empty()


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
	elif event.is_action_pressed(&"swing_bunt"):
		type = SwingIntent.Type.BUNT
	if type == SwingIntent.Type.NONE:
		return
	_pending_swing = type
	_pending_swing_usec = _now_usec()
	_pending_stick = Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up")


func _process(delta: float) -> void:
	if state == null:
		return
	_tick_clock(delta)
	if _phase == Phase.BALL_IN_PLAY and _hit_stop > 0.0:
		_hit_stop -= delta  # the ball hangs off the bat for a beat
	else:
		_phase_time += delta
	_handle_global_input()
	match _phase:
		Phase.PREGAME:
			_process_pregame()
		Phase.PRE_PITCH:
			if not _sub_options.is_empty():
				_process_sub_menu()
			else:
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
		_hud.show_callout("ROOKIE ASSIST %s" % ("ON" if tuning.rookie_assist else "OFF"), "batting: slower pitches, wider window · fielding: quicker, longer reach, auto-runs to the ball")
		_hud.show_prompt(_hud_prompt_suffix())
	if Input.is_action_just_pressed(&"switch_side") and _phase != Phase.PREGAME:
		user_team = MatchState.HOME if user_team == MatchState.AWAY else MatchState.AWAY
		_hud.show_callout("YOU CONTROL THE %s" % roster.teams[user_team].team_name.to_upper())
		if _phase == Phase.PRE_PITCH:
			_enter_pre_pitch()


# --- Pitch setup ---------------------------------------------------------

func _enter_pre_pitch() -> void:
	_hud.set_clock(-1.0)
	_steal_orders.clear()
	if state.game_over:
		_enter_game_over()
		return
	_set_phase(Phase.PRE_PITCH)
	_ai_pitching_change()
	_announce_whos_on_first()
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
		_selected_pitch = mini(_selected_pitch, _repertoire().size() - 1)
		_hud.show_pitching(true, _repertoire(), _selected_pitch)
		_hud.set_meter(0.0, tuning.pitch_meter_sweet_spot)
	_hud.show_prompt(_hud_prompt_suffix())


func _process_pre_pitch(delta: float) -> void:
	if user_is_batting():
		_show_stick_marker()
		if Input.is_action_just_pressed(&"runner_advance"):
			_order_steal(_held_base())
		if Input.is_action_just_pressed(&"runner_retreat") and not _steal_orders.is_empty():
			_steal_orders.clear()
			_hud.show_callout("STEAL OFF", "", 0.8)
		var windup_start := AI_PRE_PITCH_DELAY - WINDUP_TIME
		if _phase_time >= windup_start:
			_view.show_windup((_phase_time - windup_start) / WINDUP_TIME)
		if Input.is_action_just_pressed(&"open_subs") and _phase_time < AI_PRE_PITCH_DELAY - WINDUP_TIME:
			_open_sub_menu()
			return
		if _phase_time >= AI_PRE_PITCH_DELAY:
			var intent := AiPitcher.choose(state, content.pitches, tuning, rng, _club(state.fielding_team()), _player(state.pitcher(state.fielding_team())))
			if tuning.rookie_assist:
				intent.speed_scale = tuning.assist_pitch_speed_scale
			_throw_pitch(intent)
		return
	if Input.is_action_just_pressed(&"open_subs"):
		_open_sub_menu()
		return
	# Pitch clock: a human pitcher who never starts the pitch is charged a ball.
	var clock := content.rules.pitch_clock
	if clock > 0.0:
		_hud.set_clock(clock - _phase_time)
		if _phase_time >= clock:
			_hud.set_clock(-1.0)
			_hud.show_callout("PITCH CLOCK", "automatic ball", 1.2)
			_log({"pitch_clock": "ball"})
			state.apply_pitch_call(MatchState.PitchCall.BALL)
			_set_phase(Phase.CALL)
			return
	_move_cursor(delta)
	_view.set_cursor(_cursor, 0.07, 0.0, Color(0.3, 0.95, 1.0))
	var repertoire := _repertoire()
	var count := repertoire.size()
	if Input.is_action_just_pressed(&"pitch_next"):
		_selected_pitch = (_selected_pitch + 1) % count
	if Input.is_action_just_pressed(&"pitch_prev"):
		_selected_pitch = (_selected_pitch + count - 1) % count
	_hud.show_pitching(true, repertoire, _selected_pitch)
	if Input.is_action_just_pressed(&"pitch_primary"):
		_hud.set_clock(-1.0)
		_set_phase(Phase.METER)
		_hud.show_prompt("Release in the white band: Space / A")


func _process_meter(delta: float) -> void:
	_move_cursor(delta)
	_view.set_cursor(_cursor, 0.07, 0.0, Color(0.3, 0.95, 1.0))
	_meter = minf(_meter + delta / tuning.pitch_meter_sweep_time, 1.0)
	_hud.set_meter(_meter, tuning.pitch_meter_sweet_spot)
	if Input.is_action_just_pressed(&"pitch_primary") or _meter >= 1.0:
		var family := _repertoire()[_selected_pitch]
		var error := PitchResolver.meter_error(_meter, tuning)
		_throw_pitch(PitchIntent.new(family.id, _cursor, error))


func _throw_pitch(intent: PitchIntent) -> void:
	var family := content.pitch(intent.family_id)
	var pitcher := state.pitcher(state.fielding_team())
	_pitch = PitchResolver.resolve(intent, family, tuning, rng, Ratings.pitcher_mods(_player(pitcher), state.pitches_thrown(pitcher), tuning))
	state.record_pitch(_pitch.to_dict())
	_log({"pitch": state.pitch_count, "family": intent.family_id, "aim": intent.aim, "meter_error": snappedf(intent.meter_error, 0.001)})
	_ai_swing = null
	_contact = null
	_decide_steals()
	if not user_is_batting():
		_ai_swing = AiBatter.decide(_pitch, family, state, tuning, rng, _club(state.batting_team()), _player(state.current_batter()))
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
	var family := content.pitch(_pitch.family_id)
	_view.show_pitch(_pitch, minf(flight, travel), family.tell_color, family.tell_trail)
	for base: int in _steals:
		_view.set_runner_off_base(state.runner_on(base), base, _steal_head(base, minf(flight, travel)))
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
				Ratings.apply_batter(swing, _player(state.current_batter()), tuning)
				if tuning.rookie_assist:
					swing.window_scale *= tuning.assist_timing_window_scale
				_resolve_swing(swing)
		elif _ai_swing.type != SwingIntent.Type.NONE and timing >= _ai_swing.timing_offset:
			_resolve_swing(_ai_swing)
		if _contact == null and timing >= tuning.swing_late_cutoff:
			_resolve_swing(SwingIntent.take())
	# The ball always reaches the plate before the result plays out.
	if _contact != null and flight >= travel:
		_view.show_pitch_marker(_pitch)
		_view.set_aim_preview(false)
		var call_text := ""
		var bases_before := state.bases.duplicate()
		if _contact.outcome == ContactResult.Outcome.IN_PLAY:
			_start_ball_in_play()
			if _outcome != null:
				call_text = String(_outcome.kind).replace("_", " ").to_upper()
		else:
			call_text = _apply_call()
		if _contact.swing_type != SwingIntent.Type.NONE:
			_show_contact_feedback(call_text)
		if _contact.outcome != ContactResult.Outcome.IN_PLAY and _contact.outcome != ContactResult.Outcome.FOUL:
			_start_steal_play(bases_before)
		_steals.clear()


## The moment the ball meets the bat (or doesn't): what kind of contact it
## was and why, the burst, and the crack.
func _show_contact_feedback(call_text: String) -> void:
	var f := ContactFeedback.describe(_contact, tuning)
	var head: String = f["headline"]
	if head == "":
		head = call_text
	elif call_text != "":
		head = "%s %s" % [head, call_text]
	_hud.show_callout(head, f["detail"], 2.2)
	_view.contact_feedback(_pitch.location, f["tier"])
	if _phase == Phase.BALL_IN_PLAY:
		_hit_stop = HIT_STOP.get(f["tier"], 0.0)


func _resolve_swing(swing: SwingIntent) -> void:
	_contact = ContactResolver.resolve(_pitch, swing, tuning, rng)
	_log({"swing": SwingIntent.Type.keys()[swing.type], "timing_ms": roundi(swing.timing_offset * 1000.0), "stick": swing.stick})
	if swing.type == SwingIntent.Type.BUNT:
		_view.bunt_bat()
	elif swing.type != SwingIntent.Type.NONE:
		_view.swing_bat()


func _apply_call() -> String:
	var call := ContactResolver.call_for(_pitch, _contact) as MatchState.PitchCall
	var text: String = {
		MatchState.PitchCall.BALL: "BALL",
		MatchState.PitchCall.CALLED_STRIKE: "STRIKE",
		MatchState.PitchCall.SWINGING_STRIKE: "SWING & MISS",
		MatchState.PitchCall.FOUL: "FOUL",
		MatchState.PitchCall.FOUL_BUNT: "FOUL BUNT",
	}[call]
	_hud.show_callout(text, _timing_detail(), 1.0)
	state.apply_pitch_call(call)
	_set_phase(Phase.CALL)
	return text


# --- Ball in play ---------------------------------------------------------

func _start_ball_in_play() -> void:
	_bip = BallInPlay.create(_contact, state, tuning, roster)
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
			_live.assist = tuning.rookie_assist
		_play = _bip.start_live(not human_fields, rng)
		_play.human_defense = not user_is_batting()
		for base: int in _steals:
			_play.set_running_start(base, _steal_head(base, _pitch.travel_time))
		if _play.human_defense and tuning.rookie_assist:
			_play.error_scale = tuning.assist_error_scale
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
	var aim := 0
	if not user_is_batting() and _play != null and _outcome == null and _play.ball == LivePlay.Ball.HELD:
		aim = ThrowAim.base_for(Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up"))
	_view.set_throw_target(aim)
	_view.set_field_focus(_field_focus(t))
	if _outcome == null:
		return
	var skip := Input.is_action_just_pressed(&"swing_contact") or Input.is_action_just_pressed(&"pitch_primary")
	if t >= _play_done_at + PLAY_SETTLE_PAUSE or (skip and t > _play_done_at):
		if _bip.is_steal():
			state.apply_steal(_outcome)
		else:
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
		# Or point at the base and press throw (centered = best play).
		if Input.is_action_just_pressed(&"throw_ball"):
			defense["throw"] = ThrowAim.base_for(move)
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
			"error":
				var labels := {"bobble": ["BOBBLED!", "can't find the handle"], "wild_throw": ["WILD THROW!", "it gets away at %s" % FieldLayout.base_name(e["base"])], "dive_miss": ["IT GETS BY HIM!", "the dive comes up empty"]}
				var text: Array = labels.get(e["kind"], ["ERROR", ""])
				_hud.show_callout(text[0], text[1], 1.2)
				_log({"error": e["kind"], "base": e["base"], "time": snappedf(_play.time, 0.01)})
			"throw":
				_log({"throw": e["base"], "time": snappedf(_play.time, 0.01)})


func _field_focus(t: float) -> Vector3:
	var ball := _play.ball_position() if _play != null else _bip.trajectory.position_at(t)
	var focus := Vector3(ball.x, 0.0, ball.z)
	if _live != null and not _live.is_secured() and _live.controlled >= 0:
		focus = focus.lerp(_live.positions[_live.controlled], 0.5)
	focus = focus.lerp(Vector3(0.0, 0.0, -30.0), 0.35)
	focus.y = ball.y  # the camera tilts up to keep a fly ball in frame
	return focus


func _finish_play(outcome: PlayOutcome) -> void:
	_outcome = outcome
	_log({"outcome": _outcome.kind, "throws": _outcome.throws.map(func(leg: Dictionary) -> int: return leg["base"]), "runs": _outcome.runs.size(), "outs": _outcome.outs.size()})
	var detail := "%.1f m/s  %d°  %.0f m" % [_contact.exit_velocity, roundi(_contact.launch_angle), _bip.trajectory.distance()]
	var text := String(_outcome.kind).replace("_", " ").to_upper()
	if _bip.is_steal():
		var names := PackedStringArray()
		for base: int in _bip.steal_heads:
			names.append(_name(_bip.bases_before[base - 1]))
		text = "CAUGHT STEALING" if not _outcome.outs.is_empty() else "STOLEN BASE!"
		detail = ", ".join(names)
	elif _outcome.kind == PlayOutcome.KIND_DOUBLE_PLAY or _outcome.kind == PlayOutcome.KIND_TRIPLE_PLAY:
		text += "!"
	elif _play != null and _play.fielding != null and _play.fielding.is_dive and _play.fielding.caught_in_air:
		text = "DIVING CATCH!"
	_hud.show_callout(text, detail, 2.0)
	_hud.show_prompt(_hud_prompt_suffix())


# --- Game over / events / debug --------------------------------------------

func _enter_game_over() -> void:
	_set_phase(Phase.GAME_OVER)
	_view.set_camera_mode(MatchView.CameraMode.FIELD)
	_hud.show_pitching(false)
	var reason: StringName = state.events[state.events.size() - 1].data.get("reason", &"")
	var lines := [["FINAL%s" % (" · MERCY RULE" if reason == &"mercy" else ""), Color.WHITE, 60]]
	if state.winner() >= 0:
		var club := roster.teams[state.winner()]
		lines.append(["%s WIN" % club.full_name().to_upper(), MatchHud.text_color(club), 40])
	lines.append(["", Color.WHITE, 10])
	lines.append(["        R    H    E", Color(0.85, 0.85, 0.85), 26])
	for team in [MatchState.AWAY, MatchState.HOME]:
		lines.append(["%s   %2d   %2d   %2d" % [roster.teams[team].abbreviation, state.score[team], state.hits[team], state.errors[team]], MatchHud.text_color(roster.teams[team]), 30])
	_hud.show_card(lines)
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
			DomainEvent.SUBSTITUTION:
				var who := _name(event.data["in"])
				if event.data["position"] == &"p":
					_hud.show_callout("PITCHING CHANGE", "%s replaces %s" % [who, _name(event.data["out"])], 2.0)
				else:
					_hud.show_callout("SUBSTITUTION", "%s for %s" % [who, _name(event.data["out"])], 2.0)
				_log({"sub": event.data["in"], "for": event.data["out"]})
			DomainEvent.RUNNER_PLACED:
				_hud.show_callout("EXTRA INNINGS", "%s starts on second" % _name(event.data["runner"]), 2.0)


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
				base = "Watch the pitcher. SWING as the ring closes: J or click (contact) / K or right-click (power) / B (bunt, ←→ places it)\nHold WASD / L-stick while swinging: ←→ aim field  ↑ lift  ↓ chop    Steal: E / RB before the pitch (hold 1-3 for one runner), Q / LB cancel    Pinch hit: P / Y"
			else:
				base = "Aim: WASD / L-stick    Pitch: Q E / LB RB    Start meter: Space / A    Pitching change: P / Y"
		Phase.BALL_IN_PLAY:
			if _outcome != null:
				base = "Skip: J / A"
			elif user_is_batting():
				base = "Runners: advance E / RB   retreat Q / LB   (hold 1-4 / B Y X A for one runner)"
			else:
				base = "Run: WASD / L-stick   Dive: Shift / RT   Switch: F / LT\nThrow: hold a direction (→ 1st  ↑ 2nd  ← 3rd  ↓ home) + Space / J / click / RB  (no direction = best play)   or 1-4 / B Y X A"
	var assist := "   Rookie assist: %s (T)" % ("ON" if tuning.rookie_assist else "OFF")
	return "%s\n[%s]   Tab/Back: switch side   ` or F1: debug   R or F5: restart%s" % [base, role, assist]


## Reads the batting stick and shows it as a small marker on the zone:
## where in the zone it points is the direction/loft it will add.
func _show_stick_marker() -> Vector2:
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up")
	var half := Vector2(tuning.zone_half_width, (tuning.zone_top - tuning.zone_bottom) * 0.5)
	_view.set_cursor(PitchResolver.zone_center(tuning) + stick * half, 0.05, 0.0, Color(1.0, 0.85, 0.2))
	_view.set_aim_preview(true, stick.x * tuning.stick_spray, stick.y)
	return stick


func _move_cursor(delta: float) -> void:
	var dir := Input.get_vector(&"aim_left", &"aim_right", &"aim_down", &"aim_up")
	_cursor += dir * CURSOR_SPEED * delta
	_cursor = _cursor.clamp(tuning.cursor_min, tuning.cursor_max)


# --- Steals ----------------------------------------------------------------

## The human orders a steal before the pitch: the runner on `base`, or with
## no base held every runner who has an open base ahead (lead runner first).
func _order_steal(base: int) -> void:
	var picked := PackedStringArray()
	for b in [2, 1]:
		if (base > 0 and b != base) or state.runner_on(b) == &"":
			continue
		if state.runner_on(b + 1) != &"" and not _steal_orders.has(b + 1):
			continue
		if not _steal_orders.has(b):
			_steal_orders[b] = _phase_time
		picked.append(_name(state.runner_on(b)))
	if picked.is_empty():
		_hud.show_callout("NO BASE TO STEAL", "", 0.8)
	else:
		_hud.show_callout("RUNNER GOING", "%s on the pitch · Q / LB to call it off" % " & ".join(picked), 1.4)


## At the release: the human's orders (a late order costs jump) or the AI's.
func _decide_steals() -> void:
	_steals.clear()
	if user_is_batting():
		var windup_start := AI_PRE_PITCH_DELAY - WINDUP_TIME
		for base: int in _steal_orders:
			var late := maxf(_steal_orders[base] - windup_start, 0.0)
			_steals[base] = tuning.steal_jump_delay + late + rng.randfn(0.0, tuning.steal_jump_sigma * 0.6)
	else:
		_steals = AiManager.steal_attempts(state, roster, tuning, rng)
		if not _steals.is_empty():
			_hud.show_callout("RUNNER GOING!", "throw to the base he is stealing", 1.0)
	_steal_orders.clear()
	if not _steals.is_empty():
		_log({"steal": _steals.keys()})


func _steal_head(base: int, flight: float) -> float:
	var speed := Ratings.runner_speed(_player(state.runner_on(base)), tuning)
	return LivePlay.steal_head_start(speed, flight, _steals[base], tuning)


## Runners who were going still go after a pitch not put in play.
func _start_steal_play(bases_before: Array[StringName]) -> void:
	var still := {}
	for base: int in _steals:
		if bases_before[base - 1] != &"" and state.bases[base - 1] == bases_before[base - 1]:
			still[base] = _steals[base]
	if still.is_empty():
		return
	var bip := BallInPlay.create_steal(state, tuning, roster, still, _pitch.travel_time)
	if bip == null:
		return
	_bip = bip
	_play = bip.start_live(false, rng)
	_play.human_defense = not user_is_batting()
	_live = null
	_outcome = null
	_play_event_cursor = 0
	_play_done_at = -1.0
	_view.set_camera_mode(MatchView.CameraMode.FIELD)
	_view.set_cursor(Vector2.ZERO, 0.0, 0.0, Color.WHITE)
	_set_phase(Phase.BALL_IN_PLAY)
	_hud.show_prompt(_hud_prompt_suffix())


# --- Roster helpers ------------------------------------------------------

func _player(id: StringName) -> PlayerDef:
	return roster.player(id) if roster != null else null


func _club(team: int) -> TeamDef:
	return roster.teams[team] if roster != null else null


func _name(id: StringName) -> String:
	var p := _player(id)
	return p.display_name if p != null else String(id)


## Pitches the current pitcher throws.
func _repertoire() -> Array[PitchFamilyDef]:
	var p := _player(state.pitcher(state.fielding_team()))
	var list: Array[PitchFamilyDef] = []
	for f in content.pitches:
		if p == null or p.pitches.has(f.id):
			list.append(f)
	return list if not list.is_empty() else content.pitches


## The AI manages whichever side the human is not.
func _ai_pitching_change() -> void:
	if state.fielding_team() == user_team:
		return
	var reliever := AiManager.pitching_change(state, roster, tuning)
	if reliever != &"":
		state.substitute(state.fielding_team(), state.pitcher(state.fielding_team()), reliever)


func _announce_whos_on_first() -> void:
	var first := state.runner_on(1)
	var p := _player(first)
	var there := p != null and p.display_name == "Who"
	if there and not _who_on_first:
		var up := _name(state.current_batter())
		_hud.show_callout("WHO'S ON FIRST", "and %s is at the plate" % up if up in ["What", "I Don't Know"] else "naturally", 2.5)
	_who_on_first = there


# --- Substitutions ----------------------------------------------------------

## Pitching change when fielding, pinch hitter when batting.
func _open_sub_menu() -> void:
	_sub_options.clear()
	var team := user_team
	var club := _club(team)
	if club == null:
		return
	if state.fielding_team() == team:
		var current := state.pitcher(team)
		for id in club.bullpen:
			if state.can_substitute(team, current, id):
				var p := _player(id)
				_sub_options.append({"label": "P  #%d %s  (%s)  vel %d  ctl %d" % [p.number, p.display_name, p.throws, p.velocity, p.control], "out": current, "in": id})
		var tired := Ratings.fatigue(_player(current), state.pitches_thrown(current), tuning)
		_hud.show_menu("PITCHING CHANGE — %s: %d pitches, %d%% tired" % [_name(current), state.pitches_thrown(current), roundi(tired * 100.0)], _sub_options.map(func(o: Dictionary) -> String: return o["label"]), 0)
	else:
		var batter := state.current_batter()
		for p in club.bench():
			if state.can_substitute(team, batter, p.id):
				_sub_options.append({"label": "PH  #%d %s  (%s)  con %d  pow %d  spd %d" % [p.number, p.display_name, p.bats, p.contact, p.power, p.speed], "out": batter, "in": p.id})
		_hud.show_menu("PINCH HITTER for %s" % _name(batter), _sub_options.map(func(o: Dictionary) -> String: return o["label"]), 0)
	if _sub_options.is_empty():
		_hud.show_menu("", [], 0)
		_hud.show_callout("NO SUBSTITUTES LEFT", "", 1.2)
	_sub_selected = 0


func _process_sub_menu() -> void:
	var count := _sub_options.size()
	if Input.is_action_just_pressed(&"aim_down"):
		_sub_selected = (_sub_selected + 1) % count
	if Input.is_action_just_pressed(&"aim_up"):
		_sub_selected = (_sub_selected + count - 1) % count
	var labels: Array = _sub_options.map(func(o: Dictionary) -> String: return o["label"])
	_hud.update_menu(labels, _sub_selected)
	if Input.is_action_just_pressed(&"open_subs"):
		_close_sub_menu()
	elif Input.is_action_just_pressed(&"pitch_primary") or Input.is_action_just_pressed(&"swing_contact"):
		var pick := _sub_options[_sub_selected]
		state.substitute(user_team, pick["out"], pick["in"])
		_close_sub_menu()


func _close_sub_menu() -> void:
	_sub_options.clear()
	_hud.show_menu("", [], 0)
	_drain_events()
	_enter_pre_pitch()


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
