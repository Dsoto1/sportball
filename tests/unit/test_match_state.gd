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
