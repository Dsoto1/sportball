extends TestCase
## Pickoffs: the pitcher throws over; a normal lead gets back, a lean does not.


func _bases(first: StringName = &"", second: StringName = &"", third: StringName = &"") -> Array[StringName]:
	var b: Array[StringName] = [first, second, third]
	return b


func _pickoff(state: MatchState, base: int, leaning: bool) -> PlayOutcome:
	return BallInPlay.create_pickoff(state, tuning(), null, base, leaning).resolve_ai()


func _state_with(bases: Array[StringName]) -> MatchState:
	var s := new_match()
	s.bases = bases
	return s


func test_normal_lead_gets_back() -> void:
	var o := _pickoff(_state_with(_bases(&"r1")), 1, false)
	check_eq(o.kind, PlayOutcome.KIND_PICKOFF)
	check(o.outs.is_empty(), "safe back at first")
	check_eq(o.final_bases, _bases(&"r1"), "still on first")
	check_eq(o.throws.size(), 1, "one throw over")
	check_eq(o.throws[0]["base"], 1, "to first")


func test_leaning_runner_is_picked_off() -> void:
	var o := _pickoff(_state_with(_bases(&"r1")), 1, true)
	check_eq(o.outs.size(), 1, "picked off")
	check_eq(o.outs[0]["runner_id"], &"r1")


func test_pickoff_at_second() -> void:
	var safe := _pickoff(_state_with(_bases(&"", &"r2")), 2, false)
	check(safe.outs.is_empty(), "normal lead at second is safe")
	check_eq(safe.throws[0]["base"], 2, "throw to second")


func test_limit_and_lead_shrink() -> void:
	var s := _state_with(_bases(&"r1"))
	check(s.can_pickoff(), "can throw over")
	var before := BallInPlay.lead_for(s, &"r1", tuning())
	s.record_pickoff_attempt(&"r1", tuning().pickoff_lead_shrink)
	check(BallInPlay.lead_for(s, &"r1", tuning()) < before, "lead shrinks after a throw over")
	s.record_pickoff_attempt(&"r1", tuning().pickoff_lead_shrink)
	check(not s.can_pickoff(), "two per batter")
	s.apply_pitch_call(MatchState.PitchCall.BALL)
	s.apply_pitch_call(MatchState.PitchCall.BALL)
	s.apply_pitch_call(MatchState.PitchCall.BALL)
	s.apply_pitch_call(MatchState.PitchCall.BALL)
	check(s.can_pickoff(), "limit resets with the next batter")
	check_eq(s.lead_cut.size(), 0, "leads reset too")


func test_lead_never_below_minimum() -> void:
	var s := _state_with(_bases(&"r1"))
	for i in 10:
		s.record_pickoff_attempt(&"r1", 1.0)
	check_near(BallInPlay.lead_for(s, &"r1", tuning()), tuning().min_lead, 0.001, "floored")


func test_picked_off_applies_an_out() -> void:
	var s := _state_with(_bases(&"r1"))
	s.apply_pickoff(_pickoff(s, 1, true))
	check_eq(s.outs, 1, "one out")
	check_eq(s.bases, _bases(), "bases empty")
	check(s.events.any(func(e: DomainEvent) -> bool: return e.type == DomainEvent.PICKED_OFF), "picked-off event")


func test_shorter_lead_hurts_the_steal() -> void:
	var s := _state_with(_bases(&"r1"))
	var full: float = BallInPlay.create_steal(s, tuning(), null, {1: 0.15}, 0.48).steal_heads[1]
	s.record_pickoff_attempt(&"r1", tuning().pickoff_lead_shrink)
	var held: float = BallInPlay.create_steal(s, tuning(), null, {1: 0.15}, 0.48).steal_heads[1]
	check(held < full, "held runner gets a smaller head start (%.1f vs %.1f)" % [held, full])


func test_wild_pickoff_throw_lets_the_runner_advance() -> void:
	var s := _state_with(_bases(&"r1"))
	var t: BaseballTuning = tuning().duplicate()
	t.throw_error_chance = 1.0
	t.wild_throw_past_min = 25.0
	t.wild_throw_past_max = 25.0
	var o := BallInPlay.create_pickoff(s, t, null, 1, false).resolve_ai(MatchRng.new(3))
	check(not o.errors.is_empty(), "the throw sailed")
	check(o.final_bases[1] == &"r1" or o.final_bases[2] == &"r1", "runner took off on it")
