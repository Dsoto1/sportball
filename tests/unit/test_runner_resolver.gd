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
