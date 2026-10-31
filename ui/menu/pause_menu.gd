class_name PauseMenu
extends Control
## The in-match pause menu (Esc / Start), in the menus' style: RESUME,
## SETTINGS, RESTART MATCH, QUIT TO MENU over the frozen game. The tree is
## paused while it shows; this keeps running (PROCESS_MODE_ALWAYS).

signal resumed
signal restart_requested
signal quit_requested

var _list: VBoxContainer
var _settings: SettingsPanel
var sfx: Sfx
## Passed on to the settings panel: a gameplay setting changed.
var on_change: Callable


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Under a CanvasLayer the anchors have no parent rect: size to the view.
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func() -> void: size = get_viewport_rect().size)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_list = VBoxContainer.new()
	_list.position = Vector2(610, 300)
	_list.add_theme_constant_override("separation", 14)
	add_child(_list)
	for item: Array in [["RESUME", &"resume", func() -> void: resumed.emit()],
			["SETTINGS", &"gear", _open_settings],
			["RESTART MATCH", &"restart", func() -> void: restart_requested.emit()],
			["QUIT TO MENU", &"power", func() -> void: quit_requested.emit()]]:
		var b := MenuTile.new(MenuTile.Kind.BAR, item[0], item[1])
		b.pressed.connect(item[2])
		b.focus_entered.connect(func() -> void:
			if sfx != null and visible:
				sfx.play(&"ui_tick"))
		_list.add_child(b)
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_close_settings)
	add_child(_settings)


func open() -> void:
	visible = true
	_settings.on_change = on_change
	_close_settings()


func _open_settings() -> void:
	_list.visible = false
	_settings.open()
	queue_redraw()


func _close_settings() -> void:
	_settings.visible = false
	_list.visible = true
	(_list.get_child(0) as MenuTile).grab_focus()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _settings.visible:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause_menu"):
		get_viewport().set_input_as_handled()
		resumed.emit()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(MenuStyle.DEEP, 0.62))
	if _settings.visible:
		return
	var r := Rect2(Vector2(540, 190), Vector2(540, 420))
	MenuStyle.draw_panel(self, r, MenuStyle.NAVY, MenuStyle.GOLD, 2.5, 0.05)
	var band := Rect2(r.position, Vector2(360, 66))
	draw_polygon(MenuStyle.slanted(band, 0.0), PackedColorArray([MenuStyle.GOLD, MenuStyle.GOLD.darkened(0.1), Color(MenuStyle.GOLD, 0.0), MenuStyle.GOLD]))
	MenuStyle.draw_text(self, r.position + Vector2(32, 10), "PAUSED", MenuStyle.HEAD_FONT, 48, MenuStyle.NAVY, false)
