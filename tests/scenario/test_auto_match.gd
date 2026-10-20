extends TestCase
## Full AI-vs-AI matches with no scene loaded.

const SEEDS := 30


func test_matches_complete_without_intervention() -> void:
	for seed_value in SEEDS:
		var sim := AutoMatch.play(seed_value, content())
		check(sim.state.game_over, "seed %d finished" % seed_value)
		check(sim.state.inning >= tuning().innings, "seed %d played regulation" % seed_value)
		check(sim.state.winner() != -1, "seed %d has a winner" % seed_value)


func test_match_is_reproducible_from_seed() -> void:
	var a := AutoMatch.play(1234, content())
	var b := AutoMatch.play(1234, content())
	check_eq(a.state.score, b.state.score, "score")
	check_eq(a.state.events.size(), b.state.events.size(), "event count")
	check_eq(a.stats["pitches"], b.stats["pitches"], "pitch count")


func test_runs_and_line_score_agree() -> void:
	for seed_value in 10:
		var s := AutoMatch.play(seed_value, content()).state
		for team in 2:
			var total := 0
			for runs in s.line_score[team]:
				total += runs
			check_eq(total, s.score[team], "seed %d team %d line score" % [seed_value, team])


func test_outcome_rates_are_baseball_shaped() -> void:
	var totals := {}
	var runs := 0
	for seed_value in SEEDS:
		var sim := AutoMatch.play(1000 + seed_value, content())
		runs += sim.state.score[0] + sim.state.score[1]
		for key in sim.stats:
			totals[key] = totals.get(key, 0) + sim.stats[key]
	var pa := float(totals["plate_appearances"])
	var hits_per_pa: float = totals["hits"] / pa
	var k_rate: float = totals["strikeouts"] / pa
	var runs_per_team := runs / (2.0 * SEEDS)
	check(hits_per_pa > 0.15 and hits_per_pa < 0.40, "hits/PA %.3f" % hits_per_pa)
	check(k_rate > 0.08 and k_rate < 0.35, "K rate %.3f" % k_rate)
	check(runs_per_team > 1.0 and runs_per_team < 9.0, "runs per team per game %.2f" % runs_per_team)
	check(totals["home_runs"] > 0, "home runs happen")
	check(totals["ground_outs"] > 0 and totals["air_outs"] > 0, "both ground and air outs")
