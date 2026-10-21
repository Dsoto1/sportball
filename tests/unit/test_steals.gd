extends TestCase
## Stolen bases: a live race between the runner's jump and the catcher's throw.


func _bases(first: StringName = &"", second: StringName = &"", third: StringName = &"") -> Array[StringName]:
	var b: Array[StringName] = [first, second, third]
	return b


func _steal(bases: Array[StringName], stealers: Dictionary, speed: float, arm: float = 1.0, outs: int = 0) -> PlayOutcome:
	var fielders := FielderState.default_defense(tuning())
	fielders[tuning().fielder_ids.find(&"c")].arm = arm
	var speeds := {}
	for id in bases:
		speeds[id] = speed
	return LivePlay.steal_play(bases, stealers, outs, tuning(), fielders, speeds).run_ai(tuning().sim_play_step)


func _head(speed: float, jump: float = 0.15) -> float:
	return LivePlay.steal_head_start(speed, 0.48, jump, tuning())


func test_great_jump_steals_second() -> void:
	var o := _steal(_bases(&"r1"), {1: _head(8.6, -0.1)}, 8.6)
	check_eq(o.kind, PlayOutcome.KIND_STEAL)
	check_eq(o.final_bases, _bases(&"", &"r1"), "safe at second")
	check(o.outs.is_empty(), "no out")


func test_slow_runner_is_thrown_out() -> void:
	var o := _steal(_bases(&"r1"), {1: _head(7.0, 0.35)}, 7.0, 1.1)
	check_eq(o.outs.size(), 1, "caught stealing")
	check_eq(o.outs[0]["base"], 2, "at second")
	check_eq(o.final_bases, _bases(), "bases empty")


func test_stealer_does_not_turn_back() -> void:
	var o := _steal(_bases(&"r1"), {1: _head(7.0, 0.35)}, 7.0, 1.1)
	check(o.final_bases[0] == &"", "never retreated to first")


func test_runner_who_stays_put_is_not_part_of_it() -> void:
	var o := _steal(_bases(&"r1", &"", &"r3"), {1: _head(8.0)}, 8.0)
	check(o.final_bases[2] == &"r3" or o.runs.has(&"r3"), "runner on third holds or scores on the throw")


func test_double_steal() -> void:
	var o := _steal(_bases(&"r1", &"r2"), {1: _head(8.6, 0.0), 2: _head(8.6, 0.0)}, 8.6)
	check_eq(o.final_bases[1], &"r1", "trail runner takes second")
	check(o.outs.size() <= 1, "the catcher gets one at most")
	check(o.final_bases[2] == &"r2" or o.outs.any(func(x: Dictionary) -> bool: return x["runner_id"] == &"r2"), "lead runner safe at third or thrown out there")


func test_apply_steal_keeps_the_count_and_batter() -> void:
	var s := new_match()
	s.apply_pitch_call(MatchState.PitchCall.BALL)
	var batter := s.current_batter()
	s.bases = _bases(&"r1")
	var o := _steal(_bases(&"r1"), {1: _head(8.6, -0.1)}, 8.6)
	s.apply_steal(o)
	check_eq(s.bases, _bases(&"", &"r1"), "runner on second")
	check_eq(s.balls, 1, "count stays")
	check_eq(s.current_batter(), batter, "same batter")
	check(s.events.any(func(e: DomainEvent) -> bool: return e.type == DomainEvent.STOLEN_BASE), "stolen base event")


func test_caught_stealing_records_the_out() -> void:
	var s := new_match()
	s.bases = _bases(&"r1")
	s.apply_steal(_steal(_bases(&"r1"), {1: _head(7.0, 0.35)}, 7.0, 1.1))
	check_eq(s.outs, 1, "one out")
	check(s.events.any(func(e: DomainEvent) -> bool: return e.type == DomainEvent.CAUGHT_STEALING), "caught stealing event")


func test_speed_and_arm_decide_steals() -> void:
	var rng := MatchRng.new(9)
	var fast := 0
	var slow := 0
	for i in 60:
		var jump := tuning().steal_jump_delay + rng.randfn(0.0, tuning().steal_jump_sigma)
		if _steal(_bases(&"r1"), {1: _head(8.8, jump)}, 8.8).final_bases[1] != &"":
			fast += 1
		if _steal(_bases(&"r1"), {1: _head(7.2, jump)}, 7.2).final_bases[1] != &"":
			slow += 1
	check(fast > 50, "fast runners usually make it (%d/60)" % fast)
	check(slow < 25, "slow runners usually don't (%d/60)" % slow)


func test_running_start_beats_the_force_on_a_grounder() -> void:
	# Hit-and-run: a routine grounder to short that would be a force at second.
	var f := FieldingResult.new()
	f.fielder_index = 4
	f.fielder_id = &"ss"
	f.secure_point = Vector3(-9, 0, -34)
	f.secure_time = 1.0
	f.ready_time = 1.0
	var traj := BallTrajectory.simulate(30.0, -6.0, -15.0, tuning())
	var plain := LivePlay.new(_bases(&"r1"), &"bat", 0, -6.0, traj, f, tuning(), true).run_ai(tuning().sim_play_step)
	var running := LivePlay.new(_bases(&"r1"), &"bat", 0, -6.0, traj, f, tuning(), true)
	running.set_running_start(1, _head(8.0))
	var hit_and_run := running.run_ai(tuning().sim_play_step)
	check(plain.outs.any(func(o: Dictionary) -> bool: return o["runner_id"] == &"r1"), "without the jump he is forced")
	check(not hit_and_run.outs.any(func(o: Dictionary) -> bool: return o["runner_id"] == &"r1"), "with it he is safe")
