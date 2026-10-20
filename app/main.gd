extends Node
## Bootstrap: loads content, builds the graybox match view, HUD and debug
## overlay, and starts an interactive match.
## Optional: pass `-- --seed=1234` to reproduce a logged match.


func _ready() -> void:
	var content := ContentLibrary.load_default()
	for problem in content.validate():
		push_error("Content: %s" % problem)
	var view := MatchView.new()
	view.name = "MatchView"
	add_child(view)
	view.setup(content.tuning)
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	var hud := MatchHud.new()
	hud.name = "MatchHud"
	ui.add_child(hud)
	var debug := DebugOverlay.new()
	debug.name = "DebugOverlay"
	ui.add_child(debug)
	var director := MatchDirector.new()
	director.name = "MatchDirector"
	add_child(director)
	director.setup(content, view, hud, debug)
	debug.visible = false  # ` or F1 shows it
	view.set_debug_visible(false)
	director.start_match(_seed_from_args())


func _seed_from_args() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			return int(arg.trim_prefix("--seed="))
	return int(Time.get_unix_time_from_system()) % 1000000
