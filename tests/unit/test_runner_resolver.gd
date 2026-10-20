extends TestCase


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


func _plan_for(plans: Array[RunnerPlan], id: StringName) -> RunnerPlan:
	for p in plans:
		if p.runner_id == id:
			return p
	return null


func _play(bases: Array[StringName], fielding: FieldingResult, outs: int, throw_base: int) -> PlayOutcome:
	var plans := RunnerResolver.plan(bases, &"bat", fielding, outs, tuning())
	return RunnerResolver.resolve(plans, &"bat", fielding, throw_base, outs, 30.0, tuning())


func test_routine_grounder_is_force_out_at_first() -> void:
	var f := _fielded(Vector3(-10, 0, -34), 1.2)
	var outcome := _play(_bases(), f, 0, 1)
	check_eq(outcome.kind, PlayOutcome.KIND_GROUND_OUT, "ground out")
	check_eq(outcome.outs.size(), 1, "one out")
	check_eq(outcome.outs[0]["kind"], PlayOutcome.OUT_FORCE, "force")


func test_slow_roller_beats_throw() -> void:
	var f := _fielded(Vector3(-2, 0, -12), 3.4)
	var outcome := _play(_bases(), f, 0, 1)
	check_eq(outcome.kind, PlayOutcome.KIND_SINGLE, "infield single")
	check_eq(outcome.final_bases[0], &"bat", "batter on first")


func test_ball_in_gap_gives_extra_bases() -> void:
	var f := _fielded(Vector3(-55, 0, -85), 5.5)
	var plans := RunnerResolver.plan(_bases(), &"bat", f, 0, tuning())
	check(plans[0].target_base >= 2, "batter goes for two or more (%d)" % plans[0].target_base)


func test_forced_runners_must_advance() -> void:
	var f := _fielded(Vector3(0, 0, -20), 0.9)
	var plans := RunnerResolver.plan(_bases(&"r1", &"r2"), &"bat", f, 0, tuning())
	check(_plan_for(plans, &"r1").forced, "runner on first forced")
	check(_plan_for(plans, &"r2").forced, "runner on second forced")
	check_eq(_plan_for(plans, &"r2").target_base, 3, "advances to third")


func test_unforced_runner_holds_on_infield_grounder() -> void:
	var f := _fielded(Vector3(-20, 0, -24), 1.0)
	var plans := RunnerResolver.plan(_bases(&"", &"", &"r3"), &"bat", f, 0, tuning())
	var r3 := _plan_for(plans, &"r3")
	check(not r3.forced, "not forced")
	check_eq(r3.target_base, 3, "holds third on a grounder to third")


func test_runner_cannot_pass_lead_runner() -> void:
	var f := _fielded(Vector3(-60, 0, -80), 3.0)
	var plans := RunnerResolver.plan(_bases(&"r1", &"r2"), &"bat", f, 0, tuning())
	var limits := {}
	for p in plans:
		limits[p.runner_id] = p.target_base
	check(limits[&"r1"] < limits[&"r2"] or limits[&"r2"] == 4, "trail runner behind lead")
	check(limits[&"bat"] < limits[&"r1"] or limits[&"r1"] == 4, "batter behind runner")


func test_third_out_force_cancels_run() -> void:
	var f := _fielded(Vector3(-10, 0, -34), 1.6)
	var outcome := _play(_bases(&"", &"", &"r3"), f, 2, 1)
	check_eq(outcome.outs.size(), 1, "out at first")
	check(outcome.runs.is_empty(), "run does not count on inning-ending force")


func test_tag_out_after_run_crosses_still_counts_run() -> void:
	# Deep fly caught with one out: runner tags from third and scores while
	# the trail runner is thrown out at second for the third out later.
	var f := _fielded(Vector3(0, 0, -95), 4.0, true)
	var bases := _bases(&"r1", &"", &"r3")
	var plans := RunnerResolver.plan(bases, &"bat", f, 0, tuning())
	var r3 := _plan_for(plans, &"r3")
	check_eq(r3.target_base, 4, "tags and goes home")
	# Force a late trail runner to test run timing on a tag out.
	var r1 := _plan_for(plans, &"r1")
	r1.target_base = 2
	r1.arrival_time = 20.0
	# Quick throw: the tag at second beats r3 home, so the run is wiped out.
	var quick := RunnerResolver.resolve(plans, &"bat", f, 2, 1, 35.0, tuning())
	check_eq(quick.outs.size(), 2, "catch plus tag out")
	check_eq(quick.outs[1]["kind"], PlayOutcome.OUT_TAG, "tag")
	check(quick.outs[1]["time"] < r3.arrival_time, "tag lands before r3 scores")
	check(quick.runs.is_empty(), "run does not count when the tag comes first")
	# Bobbled before the throw: r3 crosses first, so the run counts.
	f.ready_time = 8.0
	var late := RunnerResolver.resolve(plans, &"bat", f, 2, 1, 35.0, tuning())
	check_eq(late.outs.size(), 2, "still a tag out")
	check_eq(late.runs, [&"r3"] as Array[StringName], "run crossed before the tag")


func test_caught_fly_with_two_outs_ends_play() -> void:
	var f := _fielded(Vector3(0, 0, -80), 4.0, true)
	var outcome := _play(_bases(&"", &"", &"r3"), f, 2, -1)
	check_eq(outcome.kind, PlayOutcome.KIND_FLY_OUT)
	check(outcome.runs.is_empty(), "no run on third-out catch")


func test_ai_takes_force_for_third_out() -> void:
	var f := _fielded(Vector3(0, 0, -30), 1.0)
	var plans := RunnerResolver.plan(_bases(&"r1", &"r2", &"r3"), &"bat", f, 2, tuning())
	var base := AiDefense.choose_throw(plans, f, 2, tuning())
	var outcome := RunnerResolver.resolve(plans, &"bat", f, base, 2, 5.0, tuning())
	check_eq(outcome.outs.size(), 1, "gets an out")
	check(outcome.runs.is_empty(), "inning-ending force cancels the run")


func test_ai_no_throw_after_third_out_catch() -> void:
	var f := _fielded(Vector3(0, 0, -80), 4.0, true)
	var plans := RunnerResolver.plan(_bases(), &"bat", f, 2, tuning())
	check_eq(AiDefense.choose_throw(plans, f, 2, tuning()), AiDefense.NO_THROW)


func test_home_run_scores_everyone() -> void:
	var outcome := RunnerResolver.home_run(_bases(&"r1", &"", &"r3"), &"bat")
	check_eq(outcome.runs, [&"r3", &"r1", &"bat"] as Array[StringName], "three runs in order")
	check_eq(outcome.final_bases, _bases(), "bases empty")


func test_runner_position_follows_base_path() -> void:
	var p := RunnerPlan.new()
	p.start_base = 1
	p.target_base = 3
	p.start_time = 0.0
	p.arrival_time = 2.0
	check_near(p.position_at(1.0).distance_to(FieldLayout.base_position(2)), 0.0, 0.001, "at second halfway")
	check_near(p.position_at(5.0).distance_to(FieldLayout.base_position(3)), 0.0, 0.001, "at third when done")
