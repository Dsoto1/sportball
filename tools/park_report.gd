extends SceneTree
## How each park plays: runs, homers and extra-base hits per game over N
## AI-vs-AI matches in every park in the catalog.
##   godot --headless --path . -s res://tools/park_report.gd -- [matches] [first_seed]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var matches := int(args[0]) if args.size() > 0 else 60
	var first_seed := int(args[1]) if args.size() > 1 else 1
	var content := ContentLibrary.load_default()
	print("%-20s %6s %6s %6s %6s   %s" % ["park", "R/G", "HR/G", "2B/G", "3B/G", "LF-CF-RF ft (wall)"])
	for park in content.parks:
		var runs := 0
		var counts := {}
		for i in matches:
			var sim := AutoMatch.play(first_seed + i, content, &"gearheads", &"glitterati", park.id)
			runs += sim.state.score[0] + sim.state.score[1]
			for k in sim.outcome_counts:
				counts[k] = counts.get(k, 0) + sim.outcome_counts[k]
		var g := float(matches)
		var s := park.field_shape
		var dims := "%d-%d-%d (%.0f/%.0f/%.0f m)" % [roundi(s.distance_at(-45) * 3.2808), roundi(s.distance_at(0) * 3.2808), roundi(s.distance_at(45) * 3.2808), s.height_at(-30), s.height_at(0), s.height_at(30)]
		print("%-20s %6.2f %6.2f %6.2f %6.2f   %s" % [park.display_name, runs / g, counts.get(PlayOutcome.KIND_HOME_RUN, 0) / g,
			counts.get(PlayOutcome.KIND_DOUBLE, 0) / g, counts.get(PlayOutcome.KIND_TRIPLE, 0) / g, dims])
	quit()
