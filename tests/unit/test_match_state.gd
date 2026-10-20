extends TestCase


func _calls(state: MatchState, call: MatchState.PitchCall, times: int) -> void:
	for i in times:
		state.apply_pitch_call(call)


func _strikeout(state: MatchState) -> void:
	_calls(state, MatchState.PitchCall.CALLED_STRIKE, 3)


func _half_inning(state: MatchState) -> void:
	for i in 3:
		_strikeout(state)


func test_count_resets_after_walk() -> void:
	var s := new_match()
	var batter := s.current_batter()
	_calls(s, MatchState.PitchCall.BALL, 4)
	check_eq(s.bases[0], batter, "walked batter on first")
	check_eq(s.balls, 0, "balls reset")
	check_eq(s.current_batter(), &"away_02", "next batter up")


func test_foul_cannot_be_third_strike() -> void:
	var s := new_match()
	_calls(s, MatchState.PitchCall.FOUL, 5)
	check_eq(s.strikes, 2, "strikes capped")
	check_eq(s.outs, 0, "no out on fouls")


func test_strikeout_records_out() -> void:
	var s := new_match()
	_strikeout(s)
	check_eq(s.outs, 1, "outs")
	check_eq(s.strikes, 0, "count reset")


func test_bases_loaded_walk_forces_run() -> void:
	var s := new_match()
	_calls(s, MatchState.PitchCall.BALL, 16)
	check_eq(s.score[MatchState.AWAY], 1, "run forced home")
	check(s.bases.all(func(b: StringName) -> bool: return b != &""), "bases still loaded")


func test_walk_with_runner_on_second_only_does_not_force() -> void:
	var s := new_match()
	s.bases = [&"", &"r2", &""]
	_calls(s, MatchState.PitchCall.BALL, 4)
	check_eq(s.bases, [&"away_01", &"r2", &""] as Array[StringName], "runner on second stays")


func test_three_outs_switch_half_and_clear_bases() -> void:
	var s := new_match()
	_calls(s, MatchState.PitchCall.BALL, 4)
	_half_inning(s)
	check(not s.is_top, "now bottom")
	check_eq(s.inning, 1, "still first inning")
	check_eq(s.bases, [&"", &"", &""] as Array[StringName], "bases cleared")
	check_eq(s.line_score[MatchState.AWAY], [0], "away line score")


func test_lineup_order_persists_across_halves() -> void:
	var s := new_match()
	_half_inning(s)
	_half_inning(s)
	check_eq(s.current_batter(), &"away_04", "away resumes at 4th hitter")


func test_game_ends_after_scheduled_innings() -> void:
	var s := new_match(2)
	_calls(s, MatchState.PitchCall.BALL, 16)  # away scores 1 in the top of the 1st
	for i in 3:
		_half_inning(s)
	check(not s.game_over, "game still on before final bottom")
	_half_inning(s)
	check(s.game_over, "game over after 2 innings")
	check_eq(s.winner(), MatchState.AWAY, "away wins")


func test_bottom_of_last_skipped_when_home_leads() -> void:
	var s := new_match(1)
	_half_inning(s)
	_calls(s, MatchState.PitchCall.BALL, 16)
	_half_inning(s)
	check(s.game_over, "game over")
	check_eq(s.inning, 1, "one inning played")
	s = new_match(1)
	s.score = [0, 2]
	_half_inning(s)
	check(s.game_over, "home leads after top of final inning: no bottom half")


func test_walk_off_ends_game_immediately() -> void:
	var s := new_match(1)
	_half_inning(s)
	_calls(s, MatchState.PitchCall.BALL, 16)
	check(s.game_over, "walk-off ends game")
	check_eq(s.score, [0, 1] as Array[int], "only the winning run")
	var pitches_before := s.events.size()
	s.apply_pitch_call(MatchState.PitchCall.BALL)
	check_eq(s.events.size(), pitches_before, "no play after game over")


func test_tie_goes_to_extra_innings() -> void:
	var s := new_match(1)
	_half_inning(s)
	_half_inning(s)
	check(not s.game_over, "tied game continues")
	check_eq(s.inning, 2, "extra inning")


func test_apply_play_scores_runs_then_records_outs() -> void:
	var s := new_match()
	s.outs = 1
	s.bases = [&"r1", &"", &"r3"]
	var outcome := PlayOutcome.new()
	outcome.kind = PlayOutcome.KIND_FIELDERS_CHOICE
	outcome.batter_id = s.current_batter()
	outcome.runs = [&"r3"]
	outcome.outs = [{"runner_id": &"r1", "base": 2, "kind": PlayOutcome.OUT_FORCE, "time": 2.0}]
	outcome.final_bases = [s.current_batter(), &"", &""]
	s.apply_play(outcome)
	check_eq(s.score[MatchState.AWAY], 1, "run scored")
	check_eq(s.outs, 2, "out recorded")
	check_eq(s.bases[0], &"away_01", "batter on first")


func test_events_are_sequenced() -> void:
	var s := new_match()
	_strikeout(s)
	for i in s.events.size():
		check_eq(s.events[i].sequence, i, "event sequence")
	check(s.events.any(func(e: DomainEvent) -> bool: return e.type == DomainEvent.OUT_RECORDED), "out event emitted")


# --- Arcade rules, rosters, substitutions -------------------------------------

func _arcade_match() -> MatchState:
	return MatchState.from_teams(content().team(&"gearheads"), content().team(&"glitterati"), content().rules)


## Walks in `runs` runs for the batting team (bases loaded first).
func _walk_in(state: MatchState, runs: int) -> void:
	_calls(state, MatchState.PitchCall.BALL, 4 * (3 + runs))


func test_from_teams_sets_lineups_and_defense() -> void:
	var s := _arcade_match()
	check_eq(s.current_batter(), &"rwg_calloway", "Gearheads lead off")
	check_eq(s.pitcher(MatchState.HOME), &"nhg_tomorrow", "Glitterati starter")
	check_eq(s.defense[MatchState.HOME][&"1b"], &"nhg_who", "first baseman")
	check(not s.defense[MatchState.HOME].values().has(&"nhg_lux"), "the DH does not field")
	check_eq(s.rules.innings, 6, "six innings")


func test_pitch_counts_follow_the_pitcher() -> void:
	var s := _arcade_match()
	s.record_pitch({})
	s.record_pitch({})
	check_eq(s.pitches_thrown(&"nhg_tomorrow"), 2, "starter's count")
	check(s.substitute(MatchState.HOME, &"nhg_tomorrow", &"nhg_crisp"), "pitching change")
	s.record_pitch({})
	check_eq(s.pitches_thrown(&"nhg_crisp"), 1, "reliever's count")
	check_eq(s.pitcher(MatchState.HOME), &"nhg_crisp", "new pitcher")


func test_pinch_hitter_takes_slot_and_position() -> void:
	var s := _arcade_match()
	check(s.substitute(MatchState.AWAY, &"rwg_calloway", &"rwg_strand"), "pinch hit")
	check_eq(s.current_batter(), &"rwg_strand", "pinch hitter is up")
	check_eq(s.defense[MatchState.AWAY][&"cf"], &"rwg_strand", "and stays in center")
	check(not s.can_substitute(MatchState.AWAY, &"rwg_strand", &"rwg_calloway"), "no re-entry")
	check(not s.can_substitute(MatchState.AWAY, &"rwg_paskett", &"rwg_mahoney"), "cannot bring in someone already playing")
	check(s.events.any(func(e: DomainEvent) -> bool: return e.type == DomainEvent.SUBSTITUTION), "substitution event")


func test_mercy_rule_ends_game_after_fourth() -> void:
	var s := _arcade_match()
	for i in 3:
		_half_inning(s)
		_half_inning(s)
	_walk_in(s, 10)  # top of the 4th: away leads 10-0
	check(not s.game_over, "mercy waits for the end of the inning")
	_half_inning(s)
	check(not s.game_over, "home still bats in the 4th")
	_half_inning(s)
	check(s.game_over, "mercy after four")
	check_eq(s.events[s.events.size() - 1].data["reason"], &"mercy", "reason")


func test_mercy_needs_four_innings() -> void:
	var s := _arcade_match()
	_walk_in(s, 10)
	_half_inning(s)
	_half_inning(s)
	check(not s.game_over, "no mercy in the first")


func test_home_mercy_ends_mid_inning() -> void:
	var s := _arcade_match()
	for i in 3:
		_half_inning(s)
		_half_inning(s)
	_half_inning(s)
	_walk_in(s, 10)
	check(s.game_over, "home goes up ten in the bottom of the 4th")
	check_eq(s.score[MatchState.HOME], 10, "stops at the deciding run")


func test_extra_innings_start_with_runner_on_second() -> void:
	var s := _arcade_match()
	for i in 12:
		_half_inning(s)
	check_eq(s.inning, 7, "extra innings")
	check(s.bases[1] != &"", "runner on second")
	check_eq(s.bases[1], s.lineups[MatchState.AWAY][(s.lineup_index[MatchState.AWAY] + 8) % 9], "the previous batter")
	check_eq(s.bases[0], &"", "first empty")


func test_classic_rules_have_no_extras_runner() -> void:
	var s := new_match()
	for i in 12:
		_half_inning(s)
	check_eq(s.bases[1], &"", "classic extras start empty")


func test_hits_and_errors_are_counted() -> void:
	var s := _arcade_match()
	var single := PlayOutcome.new()
	single.kind = PlayOutcome.KIND_SINGLE
	single.batter_id = s.current_batter()
	single.final_bases = [single.batter_id, &"", &""]
	s.apply_play(single)
	var roe := PlayOutcome.new()
	roe.kind = PlayOutcome.KIND_REACHED_ON_ERROR
	roe.batter_id = s.current_batter()
	roe.errors = [{"type": "bobble", "base": -1, "on_batter": true}]
	s.apply_play(roe)
	check_eq(s.hits[MatchState.AWAY], 1, "one hit")
	check_eq(s.errors[MatchState.HOME], 1, "error charged to the defense")
