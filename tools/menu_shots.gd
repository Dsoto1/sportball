extends SceneTree
## Screenshots of the menus as the game opens them (main menu over the
## park flyover, Career, Creator Studio, each Settings tab, the pause menu
## and its settings). Needs a display:
##   godot --path . --resolution 1600x900 -s res://tools/menu_shots.gd -- /tmp/shots

var _out := ""
var _frames := 0
var _shot := 0
var _main: Node
## [frame, name, action]
var _plan: Array = []


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	# Windowed at the given resolution, whatever the saved settings say.
	GameSettings.load_saved()
	GameSettings.values["fullscreen"] = false
	GameSettings.save()
	change_scene_to_file("res://app/main.tscn")
	_plan = [
		[60, "menu_home", func() -> void: pass],
		[70, "menu_home_career", func() -> void: _menu()._home.get_children().filter(func(n: Node) -> bool: return n is MenuTile)[1].grab_focus()],
		[80, "menu_career", func() -> void: _menu()._show(MainMenu.Screen.CAREER)],
		[90, "menu_creator", func() -> void: _menu()._show(MainMenu.Screen.CREATOR)],
		[100, "menu_settings_display", func() -> void: _menu()._show(MainMenu.Screen.SETTINGS)],
		[110, "menu_settings_audio", func() -> void: _menu()._settings._show_tab(1)],
		[120, "menu_settings_gameplay", func() -> void: _menu()._settings._show_tab(2)],
		[130, "menu_settings_controls", func() -> void: _menu()._settings._show_tab(3)],
		[140, "menu_toast", func() -> void:
			_menu()._show(MainMenu.Screen.CAREER)
			_menu()._say("MY PLAYER · COMING SOON")],
		[175, "match_card", func() -> void:
			_menu()._show(MainMenu.Screen.HOME)
			_main._play()],
		[215, "pause", func() -> void: _main._pause_game()],
		[225, "pause_settings", func() -> void: _main._pause._open_settings()],
	]


func _menu() -> MainMenu:
	return _main._menu


func _process(_d: float) -> bool:
	_frames += 1
	if _main == null:
		_main = current_scene
		return false
	for step: Array in _plan:
		if _frames == step[0] - 8:
			(step[2] as Callable).call()
		if _frames == step[0]:
			root.get_texture().get_image().save_png(_out.path_join("%02d_%s.png" % [_shot, step[1]]))
			_shot += 1
	return _frames > (_plan[_plan.size() - 1][0] as int)
