extends TestCase
## The arcade effects' rules: who is on a hit streak, which trail a pitch
## draws, when the bat catches fire.


func _pa(state: MatchState, batter: StringName, result: StringName) -> void:
	state.emit(DomainEvent.PLATE_APPEARANCE_ENDED, {"batter": batter, "result": result, "pitcher": &"p"})


func test_hit_streak_counts_hits_in_a_row() -> void:
	var state := new_match()
	check_eq(GameLines.hit_streak(state, &"a"), 0, "no plate appearances yet")
	_pa(state, &"a", PlayOutcome.KIND_SINGLE)
	_pa(state, &"b", &"strikeout")  # someone else's out doesn't count
	_pa(state, &"a", PlayOutcome.KIND_DOUBLE)
	check_eq(GameLines.hit_streak(state, &"a"), 2, "two straight hits")
	_pa(state, &"a", &"walk")  # a walk neither adds nor ends it
	check_eq(GameLines.hit_streak(state, &"a"), 2, "walk keeps the streak")
	_pa(state, &"a", PlayOutcome.KIND_HOME_RUN)
	check_eq(GameLines.hit_streak(state, &"a"), 3, "a homer adds to it")
	_pa(state, &"a", &"strikeout")
	check_eq(GameLines.hit_streak(state, &"a"), 0, "an out ends it")
	check_eq(GameLines.hit_streak(state, &"b"), 0, "b never hit")


func test_bat_catches_fire_from_two_straight_hits() -> void:
	var flames := StreakFlames.new()
	flames.set_level(1)
	check(not flames.lit(), "one hit: no fire")
	flames.set_level(StreakFlames.HOT_FROM)
	check_eq(flames.level, 1, "hot")
	flames.set_level(StreakFlames.BLAZING_FROM + 2)
	check_eq(flames.level, 2, "blazing")
	flames.set_level(0)
	check(not flames.lit(), "out: fire out")
	flames.free()


func test_every_pitch_draws_its_kind_of_trail() -> void:
	var styles := {}
	for f: PitchFamilyDef in content().pitches:
		var style := PitchTrail.style_for(f)
		check(style in [PitchTrail.STYLE_FASTBALL, PitchTrail.STYLE_BREAKING, PitchTrail.STYLE_OFFSPEED, PitchTrail.STYLE_SIGNATURE], "%s has a style" % f.id)
		styles[style] = true
		check(PitchTrail.trail_seconds(f.tell_trail) > 0.0, "%s trail has length" % f.id)
	check_eq(styles.size(), 4, "all four trail kinds are used")
	check(PitchTrail.trail_seconds(8) > PitchTrail.trail_seconds(2), "longer tell, longer trail")
