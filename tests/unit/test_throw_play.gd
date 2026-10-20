extends TestCase
## Multi-throw plays: double/triple plays, relays, force removal.


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


func _play(bases: Array[StringName], fielding: FieldingResult, outs: int) -> ThrowPlay:
	var plans := RunnerResolver.plan(bases, &"bat", fielding, outs, tuning())
	return ThrowPlay.new(plans, &"bat", fielding, outs, 5.0, tuning())


func _shortstop_grounder() -> FieldingResult:
	return _fielded(Vector3(-9, 0, -34), 1.0)


func test_six_four_three_double_play() -> void:
	var play := _play(_bases(&"r1"), _shortstop_grounder(), 0)
	var to_second := play.throw_to(2)
	check_eq(to_second["out_runner"], &"r1", "force at second")
	check_eq(to_second["out_kind"], PlayOutcome.OUT_FORCE, "force")
	var to_first := play.throw_to(1)
	check_eq(to_first["out_runner"], &"bat", "relay beats the batter")
	check(to_first["release"] >= to_second["arrival"] + tuning().relay_release_time - 0.0001, "pivot takes time")
	var outcome := play.outcome()
	check_eq(outcome.kind, PlayOutcome.KIND_DOUBLE_PLAY)
	check_eq(outcome.outs.size(), 2, "two outs")
	check_eq(outcome.final_bases, _bases(), "bases empty")
	check_eq(outcome.throws.size(), 2, "two legs recorded")


func test_double_play_ends_inning_and_cancels_run() -> void:
	var play := _play(_bases(&"r1", &"", &"r3"), _shortstop_grounder(), 1)
	play.throw_to(2)
	play.throw_to(1)
	var outcome := play.outcome()
	check(play.inning_over(), "third out")
	check(not play.can_throw(), "no throws after the third out")
	check(outcome.runs.is_empty(), "inning-ending force double play: run does not count")


func test_batter_out_first_removes_force_at_second() -> void:
	# 3-6: first baseman fields it near the bag, then throws to second.
	var play := _play(_bases(&"r1"), _fielded(Vector3(19, 0, -22), 1.0), 0)
	var at_first := play.throw_to(1)
	check(at_first["unassisted"], "1B steps on the bag himself")
	check_eq(at_first["out_runner"], &"bat", "batter out")
	var plan_r1: RunnerPlan = play.plans.filter(func(p: RunnerPlan) -> bool: return p.runner_id == &"r1")[0]
	check(not play.is_forced_at(plan_r1, at_first["out_time"] + 0.01), "force removed once the batter is out")
	var at_second := play.throw_to(2)
	if at_second["out_runner"] == &"r1":
		check_eq(at_second["out_kind"], PlayOutcome.OUT_TAG, "needs a tag now")


func test_runner_already_safe_is_not_doubled_up() -> void:
	# Slow grounder deep in the hole: nobody can be caught at second.
	var play := _play(_bases(&"r1"), _fielded(Vector3(-14, 0, -40), 2.6), 0)
	var leg := play.throw_to(2)
	check_eq(leg["out_runner"], &"", "runner beats the throw")


func test_max_legs_and_holder() -> void:
	var play := _play(_bases(&"r1"), _fielded(Vector3(-40, 0, -70), 3.5), 0)
	check_eq(play.holder_base(), -1, "fielder holds the ball")
	play.throw_to(2)
	check_eq(play.holder_base(), 2, "ball at second")
	play.throw_to(3)
	play.throw_to(4)
	check(not play.can_throw(), "leg limit")


func test_ai_turns_two_with_runner_on_first() -> void:
	var f := _shortstop_grounder()
	var plans := RunnerResolver.plan(_bases(&"r1"), &"bat", f, 0, tuning())
	var outcome := RunnerResolver.resolve_throws(plans, &"bat", f, [] as Array[int], 0, 5.0, tuning())
	check_eq(outcome.outs.size(), 0, "no throws, no outs")
	var play := ThrowPlay.new(plans, &"bat", f, 0, 5.0, tuning())
	var bases: Array[int] = []
	while true:
		var b := AiDefense.next_throw(play)
		if b == AiDefense.NO_THROW:
			break
		bases.append(b)
		play.throw_to(b)
	check_eq(bases, [2, 1] as Array[int], "AI goes second-to-first")
	check_eq(play.outcome().kind, PlayOutcome.KIND_DOUBLE_PLAY)


func test_ai_stops_when_nothing_to_gain() -> void:
	var play := _play(_bases(), _shortstop_grounder(), 0)
	check_eq(AiDefense.next_throw(play), 1, "throws the batter out")
	play.throw_to(1)
	check_eq(AiDefense.next_throw(play), AiDefense.NO_THROW, "then holds")


func test_line_drive_double_play_off_tagging_runner() -> void:
	# Caught fly: runner tags from third; a strong throw home doubles him up.
	var f := _fielded(Vector3(0, 0, -60), 2.5, true)
	var plans := RunnerResolver.plan(_bases(&"", &"", &"r3"), &"bat", f, 0, tuning())
	var r3: RunnerPlan = plans[0]
	r3.target_base = 4
	r3.arrival_time = 20.0  # force the send for the test
	var play := ThrowPlay.new(plans, &"bat", f, 0, 30.0, tuning())
	var leg := play.throw_to(4)
	check_eq(leg["out_kind"], PlayOutcome.OUT_TAG, "tag at home")
	check_eq(play.outcome().kind, PlayOutcome.KIND_DOUBLE_PLAY, "catch plus tag")
