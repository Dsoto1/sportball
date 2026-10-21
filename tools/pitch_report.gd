extends SceneTree
## Per-pitch report: usage, swing-and-miss, ground-ball share and damage
## for every pitch family over N AI-vs-AI matches.
##   godot --headless --path . -s res://tools/pitch_report.gd -- [matches] [first_seed]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var matches := int(args[0]) if args.size() > 0 else 100
	var first_seed := int(args[1]) if args.size() > 1 else 1
	var content := ContentLibrary.load_default()
	var rows := {}
	var wins := [0, 0]
	for i in matches:
		var sim := AutoMatch.play(first_seed + i, content)
		if sim.state.winner() >= 0:
			wins[sim.state.winner()] += 1
		var family: StringName = &""
		for e in sim.state.events:
			match e.type:
				DomainEvent.PITCH_THROWN:
					family = e.data["family"]
					var row: Dictionary = rows.get(family, {"pitches": 0, "whiffs": 0, "bip": 0, "hits": 0, "hr": 0})
					row["pitches"] += 1
					rows[family] = row
				DomainEvent.PITCH_CALLED:
					if e.data["call"] == MatchState.PitchCall.SWINGING_STRIKE:
						rows[family]["whiffs"] += 1
				DomainEvent.BALL_CONTACTED:
					rows[family]["bip"] += 1
					if e.data["kind"] in [PlayOutcome.KIND_SINGLE, PlayOutcome.KIND_DOUBLE, PlayOutcome.KIND_TRIPLE, PlayOutcome.KIND_HOME_RUN, PlayOutcome.KIND_INSIDE_PARK_HR]:
						rows[family]["hits"] += 1
					if e.data["kind"] == PlayOutcome.KIND_HOME_RUN:
						rows[family]["hr"] += 1
	var total := 0
	for f in rows:
		total += rows[f]["pitches"]
	print("matches %d   away-home wins %s" % [matches, wins])
	print("%-12s %7s %7s %8s %8s %7s" % ["pitch", "use%", "whiff%", "BIP%", "H/BIP", "HR/BIP"])
	for f in rows:
		var r: Dictionary = rows[f]
		var p := maxf(r["pitches"], 1.0)
		var b := maxf(r["bip"], 1.0)
		print("%-12s %6.1f%% %6.1f%% %7.1f%% %8.3f %7.3f" % [f, 100.0 * r["pitches"] / total, 100.0 * r["whiffs"] / p, 100.0 * r["bip"] / p, r["hits"] / b, r["hr"] / b])
	quit()
