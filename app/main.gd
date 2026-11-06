extends Node
## Bootstrap: loads content, builds the graybox match view, HUD and debug
## overlay. Run as the game (the main scene) it opens on the main menu,
## full screen per the player's settings, with the pause menu in matches;
## loaded by a tool or a test it starts an interactive match straight away.
## Optional: pass `-- --seed=1234` to reproduce a logged match.

var _content: ContentLibrary
var _view: MatchView
var _hud: MatchHud
var _director: MatchDirector
var _menu: MainMenu
var _pause: PauseMenu
var _backdrop: MenuBackdrop
var _paused_at := 0


const EMBEDDED_NOTICE := "Running inside the editor's Game tab, so full screen can't work here.\nRestart the Godot editor (it reads the project's window settings at start-up), or in the Game tab's  ⋮  menu\nturn off \"Embed Game on Next Play\", then press Play again. Or run:  godot --path ."


func _ready() -> void:
	GameSettings.load_saved()
	GameSettings.ensure_buses()
	_content = ContentLibrary.load_default()
	for problem in _content.validate():
		push_error("Content: %s" % problem)
	_view = MatchView.new()
	_view.name = "MatchView"
	add_child(_view)
	_view.setup(_content.tuning)
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	_hud = MatchHud.new()
	_hud.name = "MatchHud"
	ui.add_child(_hud)
	var debug := DebugOverlay.new()
	debug.name = "DebugOverlay"
	ui.add_child(debug)
	_director = MatchDirector.new()
	_director.name = "MatchDirector"
	add_child(_director)
	_director.setup(_content, _view, _hud, debug)
	debug.visible = false  # ` or F1 shows it
	_view.set_debug_visible(false)
	_apply_gameplay_settings()
	if get_tree().current_scene == self:
		GameSettings.apply()
		_build_menus(ui)
		_open_menu()
		if Engine.is_embedded_in_editor():
			# project.godot keeps the editor from embedding the game
			# (window/size/mode.editor_hint); if it still did (an editor
			# opened before that setting, or embedding forced on in the
			# editor settings), say how to get a real window up front: the
			# editor may take F11 before the game sees it.
			_notice(EMBEDDED_NOTICE, 12.0)
	else:
		_director.start_match(_seed_from_args())


func _build_menus(ui: CanvasLayer) -> void:
	_menu = MainMenu.new()
	_menu.name = "MainMenu"
	_menu.sfx = _view.sfx
	_menu.play_pressed.connect(_play)
	_menu.quit_pressed.connect(func() -> void: get_tree().quit())
	ui.add_child(_menu)
	_menu._settings.on_change = _apply_gameplay_settings
	_pause = PauseMenu.new()
	_pause.name = "PauseMenu"
	_pause.sfx = _view.sfx
	_pause.on_change = _apply_gameplay_settings
	_pause.resumed.connect(_resume)
	_pause.restart_requested.connect(func() -> void:
		_resume()
		_director.start_match(int(Time.get_ticks_usec() % 1000000)))
	_pause.quit_requested.connect(func() -> void:
		_resume()
		_director.stop_match()
		_open_menu())
	ui.add_child(_pause)
	_backdrop = MenuBackdrop.new()
	_backdrop.name = "MenuBackdrop"
	add_child(_backdrop)


func _open_menu() -> void:
	_hud.visible = false
	_backdrop.start(_view, _content)
	_menu.open()


func _play() -> void:
	_menu.visible = false
	_backdrop.stop()
	_hud.visible = true
	_director.start_match(_seed_from_args())


func _pause_game() -> void:
	_paused_at = Time.get_ticks_usec()
	get_tree().paused = true
	_pause.open()


func _resume() -> void:
	_pause.visible = false
	get_tree().paused = false
	_director.add_pause(float(Time.get_ticks_usec() - _paused_at) / 1000000.0)


## Gameplay settings onto the running game (they also apply mid-match).
func _apply_gameplay_settings() -> void:
	_view.reduce_shake = bool(GameSettings.get_value("reduce_shake"))
	_view.reduce_flashes = bool(GameSettings.get_value("reduce_flashes"))
	_hud.reduce_flashes = bool(GameSettings.get_value("reduce_flashes"))
	if _director.tuning != null:
		_director.tuning.rookie_assist = bool(GameSettings.get_value("rookie_assist"))


func _unhandled_input(event: InputEvent) -> void:
	var alt_enter: bool = event is InputEventKey and event.pressed and not event.echo and event.alt_pressed and event.keycode in [KEY_ENTER, KEY_KP_ENTER]
	if event.is_action_pressed(&"toggle_fullscreen") or alt_enter:
		get_viewport().set_input_as_handled()
		if Engine.is_embedded_in_editor():
			_notice(EMBEDDED_NOTICE, 12.0)
			return
		GameSettings.toggle_fullscreen()
		return
	if _pause == null:
		return
	if event.is_action_pressed(&"pause_menu") and not _pause.visible and not _menu.visible and _director.is_running():
		get_viewport().set_input_as_handled()
		_pause_game()


## A short note across the top of the screen for a few seconds.
func _notice(text: String, seconds: float = 6.0) -> void:
	var ui := get_node("UI")
	var old := ui.get_node_or_null("Notice")
	if old != null:
		old.free()
	var label := Label.new()
	label.name = "Notice"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", MenuStyle.body(600))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", MenuStyle.GOLD)
	label.add_theme_color_override("font_outline_color", MenuStyle.DEEP)
	label.add_theme_constant_override("outline_size", 8)
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	label.offset_top = 24.0
	ui.add_child(label)
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free())


func _seed_from_args() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			return int(arg.trim_prefix("--seed="))
	return int(Time.get_unix_time_from_system()) % 1000000
