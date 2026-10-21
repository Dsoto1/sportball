extends TestCase
## Full AI-vs-AI matches with no scene loaded.

const SEEDS := 30


func test_matches_complete_without_intervention() -> void:
	for seed_value in SEEDS:
		var sim := AutoMatch.play(seed_value, content())
		check(sim.state.game_over, "seed %d finished" % seed_value)
		var mercy: bool = sim.state.events[sim.state.events.size() - 1].data.get("reason") == &"mercy"
		check(sim.state.inning >= tuning().innings or mercy, "seed %d played regulation" % seed_value)
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
	var dp_per_team: float = totals["double_plays"] / (2.0 * SEEDS)
	check(dp_per_team > 0.2 and dp_per_team < 2.0, "double plays per team per game %.2f" % dp_per_team)


func test_placeholder_match_still_plays() -> void:
	var sim := AutoMatch.play(5, content(), &"", &"")
	check(sim.state.game_over, "placeholder teams finish")
	check(sim.roster == null, "no roster")


func test_bullpen_gets_used() -> void:
	var changes := 0
	for seed_value in 10:
		var sim := AutoMatch.play(200 + seed_value, content())
		changes += sim.stats["pitching_changes"]
		for team in 2:
			check(sim.state.pitches_thrown(sim.roster.teams[team].starting_pitcher) > 0, "starters pitch")
	check(changes >= 10, "pitching changes happen (%d in 10 games)" % changes)


func test_team_styles_show_up_in_the_numbers() -> void:
	# Glitterati hit for power; the Gearheads put the ball in play.
	var hr := [0, 0]
	var events := [0, 0]
	for seed_value in 20:
		var sim := AutoMatch.play(300 + seed_value, content())
		for e in sim.state.events:
			if e.type == DomainEvent.BALL_CONTACTED:
				var team: int = 0 if sim.roster.teams[0].player(e.data["batter"]) != null else 1
				events[team] += 1
				if e.data["kind"] == PlayOutcome.KIND_HOME_RUN:
					hr[team] += 1
	check(hr[1] > hr[0], "Glitterati out-homer the Gearheads (%d vs %d)" % [hr[1], hr[0]])


func test_small_ball_shows_up() -> void:
	var steals := 0
	var caught := 0
	var bunts := 0
	for seed_value in 20:
		var sim := AutoMatch.play(400 + seed_value, content())
		steals += sim.stats["steals"]
		caught += sim.stats["caught_stealing"]
		bunts += sim.stats["bunts"]
		check(sim.state.game_over, "seed %d finished" % seed_value)
	check(steals >= 10, "bases get stolen (%d in 20 games)" % steals)
	check(caught >= 1, "and runners get caught (%d)" % caught)
	check(bunts >= 10, "and people bunt (%d)" % bunts)
