extends TestCase
## LivePlay: live runners, throws, forces, tags, doubled off, rundowns.

const GROUNDER := [30.0, -6.0, -15.0]
const LINER := [40.0, 6.0, -15.0]


func _fielded(point: Vector3, time: float, in_air: bool = false) -> FieldingResult:
	var f := FieldingResult.new()
	f.fielder_index = 0
	f.fielder_id = &"test"
	f.secure_point = point
	f.secure_time = time
	f.ready_time = time
	f.caught_in_air = in_air
	return f


func _bases(first: StringName = &"", second: StringName = &"", third: StringName = &"") -> Array[StringName]:
	var b: Array[StringName] = [first, second, third]
	return b


func _play(bases: Array[StringName], outs: int, f: FieldingResult, flight: Array = GROUNDER) -> LivePlay:
	var traj := BallTrajectory.simulate(flight[0], flight[1], flight[2], tuning())
	return LivePlay.new(bases, &"bat", outs, flight[1], traj, f, tuning(), true)


func _run(play: LivePlay) -> PlayOutcome:
	return play.run_ai(tuning().sim_play_step)


func _step_until(play: LivePlay, t: float, offense: Dictionary = {}) -> void:
	var first := true
	while play.time < t and not play.is_done():
		play.step(tuning().sim_play_step, {}, offense if first else {})
		first = false


func _has_event(play: LivePlay, type: String) -> bool:
	return play.events.any(func(e: Dictionary) -> bool: return e["type"] == type)


func test_routine_grounder_is_force_at_first() -> void:
	var outcome := _run(_play(_bases(), 0, _fielded(Vector3(-9, 0, -34), 1.0)))
	check_eq(outcome.kind, PlayOutcome.KIND_GROUND_OUT)
	check_eq(outcome.outs[0]["kind"], PlayOutcome.OUT_FORCE, "force")
	check_eq(outcome.outs[0]["base"], 1, "at first")


func test_slow_roller_is_infield_single() -> void:
	var outcome := _run(_play(_bases(), 0, _fielded(Vector3(-2, 0, -12), 3.4)))
	check_eq(outcome.kind, PlayOutcome.KIND_SINGLE)
	check_eq(outcome.final_bases[0], &"bat", "batter on first")


func test_six_four_three_double_play() -> void:
	var outcome := _run(_play(_bases(&"r1"), 0, _fielded(Vector3(-9, 0, -34), 1.0)))
	check_eq(outcome.kind, PlayOutcome.KIND_DOUBLE_PLAY)
	check_eq(outcome.throws.map(func(l: Dictionary) -> int: return l["base"]), [2, 1], "short to second to first")
	check_eq(outcome.final_bases, _bases(), "bases empty")


func test_inning_ending_double_play_cancels_run() -> void:
	var outcome := _run(_play(_bases(&"r1", &"", &"r3"), 1, _fielded(Vector3(-9, 0, -34), 1.0)))
	check_eq(outcome.outs.size(), 2, "two outs end the inning")
	check(outcome.runs.is_empty(), "run does not count on an inning-ending force")


func test_force_becomes_tag_after_batter_is_out() -> void:
	# First baseman fields it by the bag: batter first, then the runner needs a tag.
	var outcome := _run(_play(_bases(&"r1"), 0, _fielded(Vector3(18.5, 0, -21), 0.9)))
	check_eq(outcome.outs[0]["runner_id"], &"bat", "batter out first")
	if outcome.outs.size() > 1:
		check_eq(outcome.outs[1]["kind"], PlayOutcome.OUT_TAG, "runner had to be tagged")


func test_runner_doubled_off_after_catch() -> void:
	# Runner breaks on contact; the second baseman catches it and fires to first.
	var play := _play(_bases(&"r1"), 0, _fielded(Vector3(9, 0, -37), 1.6, true), [26.0, 70.0, 5.0])
	_step_until(play, 0.02, {"advance": true})
	var outcome := _run(play)
	check_eq(outcome.kind, PlayOutcome.KIND_DOUBLE_PLAY, "caught, runner doubled off")
	if outcome.outs.size() > 1:
		check_eq(outcome.outs[1]["kind"], PlayOutcome.OUT_DOUBLED_OFF)


func test_runner_who_stays_retouches_safely() -> void:
	var outcome := _run(_play(_bases(&"r1"), 0, _fielded(Vector3(-9, 0, -34), 0.55, true), LINER))
	check_eq(outcome.outs.size(), 1, "only the catch")
	check_eq(outcome.final_bases[0], &"r1", "runner back on first")


func test_sac_fly_and_trail_runner_moves_up_on_the_throw() -> void:
	var play := _play(_bases(&"r1", &"", &"r3"), 0, _fielded(Vector3(0, 0, -95), 4.0, true), [40.0, 35.0, 0.0])
	play.human_defense = true
	while play.runner(&"r1").state != LivePlay.State.ON_BASE and play.time < 8.0:
		play.step(tuning().sim_play_step)
	play.step(tuning().sim_play_step, {"throw": 4})  # throw home on the tag-up
	var outcome := _run(play)
	check(outcome.runs.has(&"r3") or play.runner(&"r3").state == LivePlay.State.OUT, "runner tagged from third")
	check(play.events.any(func(e: Dictionary) -> bool: return e["type"] == "advance" and e["runner"] == &"r1"), "trail runner reacts to the throw")
	check_eq(outcome.final_bases[1], &"r1", "takes second on the throw home")


func test_rundown_happens_and_ends() -> void:
	var play := _play(_bases(&"", &"r2"), 0, _fielded(Vector3(-9, 0, -34), 1.0))
	_step_until(play, 0.3)
	# The runner wrongly breaks for third on a grounder to short; then the AI
	# runner has to get himself out of it.
	play._set_target(play.runner(&"r2"), 3, 0.0)
	var outcome := _run(play)
	check(_has_event(play, "rundown"), "runner gets hung up")
	check(play.time < tuning().max_play_time - 1.0, "rundown resolves on its own (%.1fs)" % play.time)
	var r2 := play.runner(&"r2")
	check(r2.state == LivePlay.State.OUT or outcome.final_bases.has(&"r2"), "runner tagged or safe on a bag")


func test_human_retreat_sends_runner_back() -> void:
	var play := _play(_bases(&"r1"), 0, _fielded(Vector3(0, 0, -86), 3.4, true), [36.0, 32.0, 0.0])
	_step_until(play, 1.0, {"advance": true})
	check_eq(play.runner(&"r1").target, 2, "running")
	play.step(tuning().sim_play_step, {}, {"retreat": true})
	check_eq(play.runner(&"r1").target, 1, "heading back")


func test_ai_plays_always_finish_cleanly() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 150:
		var bases := _bases(&"r1" if rng.randf() < 0.5 else &"", &"r2" if rng.randf() < 0.4 else &"", &"r3" if rng.randf() < 0.3 else &"")
		var outs := rng.randi_range(0, 2)
		var ev := rng.randf_range(25.0, 48.0)
		var la := rng.randf_range(-15.0, 45.0)
		var spray := rng.randf_range(-40.0, 40.0)
		var traj := BallTrajectory.simulate(ev, la, spray, tuning())
		if traj.result != BallTrajectory.Result.IN_PLAY:
			continue
		var f := FieldingResolver.resolve(traj, FielderState.default_defense(tuning()), tuning())
		var play := LivePlay.new(bases, &"bat", outs, la, traj, f, tuning(), true)
		var outcome := play.run_ai(tuning().sim_play_step)
		check(play.is_done(), "case %d finished" % i)
		check(play.time < tuning().max_play_time, "case %d did not time out (%.1fs)" % [i, play.time])
		var seen := {}
		for id in outcome.final_bases:
			if id != &"":
				check(not seen.has(id), "case %d runner on two bases" % i)
				seen[id] = true
		var occupied := outcome.final_bases.filter(func(id: StringName) -> bool: return id != &"").size()
		var accounted := occupied + outcome.runs.size() + outcome.outs.size()
		var people := bases.filter(func(id: StringName) -> bool: return id != &"").size() + 1
		if not play.inning_over():
			check_eq(accounted, people, "case %d every runner accounted for" % i)


func test_live_play_is_deterministic() -> void:
	var a := _run(_play(_bases(&"r1", &"r2"), 1, _fielded(Vector3(-30, 0, -55), 2.2)))
	var b := _run(_play(_bases(&"r1", &"r2"), 1, _fielded(Vector3(-30, 0, -55), 2.2)))
	check_eq(a.kind, b.kind, "kind")
	check_eq(a.runs, b.runs, "runs")
	check_eq(a.final_bases, b.final_bases, "bases")
