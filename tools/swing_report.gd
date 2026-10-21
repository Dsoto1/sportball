extends SceneTree
## Every hitter's swing signature in Statcast terms (style, bat speed,
## attack angle, attack direction, swing path tilt):
##   godot --headless --path . -s res://tools/swing_report.gd
func _init() -> void:
	var content := ContentLibrary.load_default()
	print("%-22s %-3s %-9s %5s %5s %9s %5s" % ["hitter", "B", "style", "mph", "AA", "dir", "tilt"])
	for team: TeamDef in content.teams:
		for p: PlayerDef in team.roster:
			if p.is_pitcher():
				continue
			var style := BattingStyles.for_player(p)
			var s := PlayerSwing.for_player(p, style)
			var yaw := float(s["attack_yaw"])
			print("%-22s %-3s %-9s %5.1f %4.0f° %4.0f° %-4s %4.0f°" % [p.display_name, p.bats, style, s["bat_speed"], s["attack_lift"], absf(yaw), "oppo" if yaw > 0.5 else "pull", s["tilt"]])
	quit()
