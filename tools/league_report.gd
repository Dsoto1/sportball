extends SceneTree
## Round robin: every club plays every other, home and away, in the home
## club's park. Prints standings (W-L, runs for and against per game).
##   godot --headless --path . -s res://tools/league_report.gd -- [games_per_pair] [slice] [slices]
## Run several slices in parallel and pass their outputs to merge_league
## (tools/league_report.gd -- merge a.txt b.txt ...) for one table.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and args[0] == "merge":
		_merge(args.slice(1))
		quit()
		return
	var games := int(args[0]) if args.size() > 0 else 6
	var slice := int(args[1]) if args.size() > 1 else 0
	var slices := int(args[2]) if args.size() > 2 else 1
	var content := ContentLibrary.load_default()
	var rows := {}
	for t in content.teams:
		rows[t.id] = {"w": 0, "l": 0, "rf": 0, "ra": 0, "g": 0}
	var pair := 0
	for away in content.teams:
		for home in content.teams:
			if away == home:
				continue
			pair += 1
			if pair % slices != slice:
				continue
			for i in games:
				var sim := AutoMatch.play(pair * 1000 + i, content, away.id, home.id, home.stadium_def.id)
				var s := sim.state
				for side in [MatchState.AWAY, MatchState.HOME]:
					var id: StringName = (away if side == MatchState.AWAY else home).id
					var r: Dictionary = rows[id]
					r["g"] += 1
					r["rf"] += s.score[side]
					r["ra"] += s.score[1 - side]
					r["w" if s.winner() == side else "l"] += 1
	print(JSON.stringify(rows))
	quit()


func _merge(files: PackedStringArray) -> void:
	var total := {}
	for f in files:
		var text := FileAccess.get_file_as_string(f)
		for line in text.split("\n"):
			if not line.begins_with("{"):
				continue
			var rows: Dictionary = JSON.parse_string(line)
			for id in rows:
				var acc: Dictionary = total.get_or_add(id, {})
				for k in rows[id]:
					acc[k] = acc.get(k, 0) + int(rows[id][k])
	var ids := total.keys()
	ids.sort_custom(func(a, b): return float(total[a]["w"]) / maxf(total[a]["g"], 1) > float(total[b]["w"]) / maxf(total[b]["g"], 1))
	print("%-14s %5s %5s %6s %6s %6s" % ["club", "W", "L", "pct", "RF/G", "RA/G"])
	for id in ids:
		var r: Dictionary = total[id]
		var g := maxf(r["g"], 1)
		print("%-14s %5d %5d %6.3f %6.2f %6.2f" % [id, r["w"], r["l"], r["w"] / g, r["rf"] / g, r["ra"] / g])
