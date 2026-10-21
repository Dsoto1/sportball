extends SceneTree
## Prints every batting style's foot positions (body space, m) per key pose
## as JSON, for drawing the top-down foot diagram:
##   godot --headless --path . -s res://tools/foot_diagram_data.gd > feet.json
func _init() -> void:
	var out := {}
	for style: StringName in BattingStyles.ORDER:
		var poses := BattingStyles.poses(style)
		var rows := {}
		for key in ["stance", "load", "stride", "contact", "finish"]:
			var pose: Dictionary = poses[key]
			var row := {}
			for foot in ["foot_l", "foot_r"]:
				var at: Vector3 = pose.get(foot, BaseballMoves.STANCE[foot])
				# Back to (right, up, forward) for a right-handed batter.
				row[foot] = [-at.x, at.y, at.z]
			for toe in ["toe_l", "toe_r"]:
				# Feet point the way the hips face unless the pose turns them.
				row[toe] = float(pose.get(toe, (pose.get("hips", Vector3.ZERO) as Vector3).y))
			rows[key] = row
		out[style] = rows
	print(JSON.stringify(out))
	quit()
