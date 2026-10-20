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
	for i in matches:
		var sim := AutoMatch.play(first_seed + i, content)
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
	print("errors: %d (%.2f/team/game)   missed dives: %d" % [totals["errors"], totals["errors"] / (2.0 * matches), totals["dive_misses"]])
	var keys := outcomes.keys()
	keys.sort()
	for key in keys:
		print("  %-26s %5d  (%.1f%% of BIP)" % [key, outcomes[key], 100.0 * outcomes[key] / bip])
	quit()
