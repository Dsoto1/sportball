extends SceneTree
## Feel report: plays N AI-vs-AI matches headless and prints rates.
##   godot --headless --path . -s res://tools/sim_report.gd -- [matches] [first_seed]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var matches := int(args[0]) if args.size() > 0 else 50
	var first_seed := int(args[1]) if args.size() > 1 else 1
	var content := ContentLibrary.load_default()
	var totals := {}
	var outcomes := {}
	var runs := 0
	var innings := 0
	var start := Time.get_ticks_msec()
	var team := [{"runs": 0, "hits": 0, "errors": 0, "hr": 0, "wins": 0}, {"runs": 0, "hits": 0, "errors": 0, "hr": 0, "wins": 0}]
	var mercy := 0
	var names := ["away", "home"]
	for i in matches:
		var sim := AutoMatch.play(first_seed + i, content)
		if sim.roster != null:
			names = [sim.roster.teams[0].team_name, sim.roster.teams[1].team_name]
		for t in 2:
			team[t]["runs"] += sim.state.score[t]
			team[t]["hits"] += sim.state.hits[t]
			team[t]["errors"] += sim.state.errors[t]
			if sim.state.winner() == t:
				team[t]["wins"] += 1
		for e in sim.state.events:
			if e.type == DomainEvent.BALL_CONTACTED and e.data["kind"] == PlayOutcome.KIND_HOME_RUN:
				var t: int = 0 if sim.roster == null or sim.roster.teams[0].player(e.data["batter"]) != null else 1
				team[t]["hr"] += 1
			if e.type == DomainEvent.GAME_ENDED and e.data["reason"] == &"mercy":
				mercy += 1
		runs += sim.state.score[0] + sim.state.score[1]
		innings += sim.state.inning
		for key in sim.stats:
			totals[key] = totals.get(key, 0) + sim.stats[key]
		for key in sim.outcome_counts:
			outcomes[key] = outcomes.get(key, 0) + sim.outcome_counts[key]
	var pa := maxf(float(totals["plate_appearances"]), 1.0)
	var bip := maxf(float(totals["balls_in_play"]), 1.0)
	print("matches: %d (%.1f s)" % [matches, (Time.get_ticks_msec() - start) / 1000.0])
	print("runs/team/game: %.2f   innings/game: %.2f" % [runs / (2.0 * matches), float(innings) / matches])
	print("pitches/game: %.1f   zone%%: %.1f   swing%%: %.1f   whiff/swing: %.1f%%" % [
		totals["pitches"] / float(matches), 100.0 * totals["in_zone"] / totals["pitches"],
		100.0 * totals["swings"] / totals["pitches"], 100.0 * totals["whiffs"] / maxf(totals["swings"], 1.0)])
	print("PA: %d   H/PA: %.3f   K%%: %.1f   BB%%: %.1f   HR/PA: %.3f" % [
		totals["plate_appearances"], totals["hits"] / pa, 100.0 * totals["strikeouts"] / pa,
		100.0 * totals["walks"] / pa, totals["home_runs"] / pa])
	print("BIP: %d   avg EV: %.1f m/s   air outs: %d   ground outs: %d   dives: %d   multi-out plays: %d" % [
		totals["balls_in_play"], totals["exit_velocity_sum"] / bip, totals["air_outs"], totals["ground_outs"],
		totals["dives"], totals["double_plays"]])
	for t in 2:
		print("%-12s W %3d   R/G %.2f   H/G %.2f   HR/G %.2f   E/G %.2f" % [names[t], team[t]["wins"], team[t]["runs"] / float(matches),
			team[t]["hits"] / float(matches), team[t]["hr"] / float(matches), team[t]["errors"] / float(matches)])
	print("steals/game: %.2f  caught: %.2f (SB%% %.0f)   bunts/game: %.2f  sacrifices/game: %.2f" % [totals["steals"] / float(matches), totals["caught_stealing"] / float(matches),
		100.0 * totals["steals"] / maxf(totals["steals"] + totals["caught_stealing"], 1.0), totals["bunts"] / float(matches), totals["sacrifices"] / float(matches)])
	print("pickoff throws/game: %.2f  picked off/game: %.2f" % [totals["pickoffs"] / float(matches), totals["picked_off"] / float(matches)])
	print("mercy-rule games: %d   pitching changes/game: %.2f" % [mercy, totals["pitching_changes"] / float(matches)])
	print("errors: %d (%.2f/team/game)   missed dives: %d" % [totals["errors"], totals["errors"] / (2.0 * matches), totals["dive_misses"]])
	var keys := outcomes.keys()
	keys.sort()
	for key in keys:
		print("  %-26s %5d  (%.1f%% of BIP)" % [key, outcomes[key], 100.0 * outcomes[key] / bip])
	quit()
