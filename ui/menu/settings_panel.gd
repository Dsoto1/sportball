class_name SettingsPanel
extends Control
## Settings, in the reference's tabs: DISPLAY, AUDIO, GAMEPLAY and
## CONTROLS. Each row is a label with a slider or an ON/OFF toggle; left
## and right (stick, d-pad, arrows) change the focused row, the mouse can
## click and drag. Values live in GameSettings (saved as they change).
## Shared by the main menu and the pause menu; emits `closed` on Back.

signal closed

const TABS := ["DISPLAY", "AUDIO", "GAMEPLAY", "CONTROLS"]
## [label, settings key, kind (toggle / slider)] per tab.
const ROWS := {
	"DISPLAY": [["Full screen  (F11 / Alt+Enter)", "fullscreen", "toggle"], ["Vertical sync", "vsync", "toggle"]],
	"AUDIO": [["Master volume", "master", "slider"], ["Effects", "effects", "slider"], ["Crowd", "crowd", "slider"], ["Mute all", "muted", "toggle"]],
	"GAMEPLAY": [["Rookie assist  (slower pitches, wider window)", "rookie_assist", "toggle"], ["Reduce camera shake", "reduce_shake", "toggle"], ["Reduce flashes", "reduce_flashes", "toggle"]],
}
## Controls, as the input map has them: [what, keyboard / mouse, gamepad].
const CONTROLS := [
	["Move / aim", "WASD or arrows", "Left stick, d-pad"],
	["Contact swing / pitch", "J or left click", "A"],
	["Power swing", "K or right click", "X"],
	["Bunt", "B", "B"],
	["Pick a pitch", "1-5, Q / E", "LB / RB"],
	["Throw to base 1-4", "1-4", "B, Y, X, A"],
	["Dive / slide step", "Shift", "RT"],
	["Pickoff / switch fielder", "F", "LT"],
	["Runners advance / retreat", "E / Q", "RB / LB"],
	["Substitutions", "P", "Y"],
	["Switch sides", "Tab", "View"],
	["Pause", "Esc", "Start"],
	["Full screen", "F11 or Alt+Enter", "-"],
]

var _tab := 0
var _tabs: Array[MenuTab] = []
var _body: VBoxContainer
var _back: MenuTile
## Called when a gameplay setting changes (the match applies it at once).
var on_change: Callable


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Under a CanvasLayer the anchors have no parent rect: size to the view.
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func() -> void: size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := Control.new()
	frame.position = Vector2(220, 120)
	frame.size = Vector2(1160, 660)
	frame.draw.connect(func() -> void: _draw_frame(frame))
	add_child(frame)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(260, 210)
	tabs.add_theme_constant_override("separation", 6)
	add_child(tabs)
	for i in TABS.size():
		var t := MenuTab.new(TABS[i])
		t.pressed.connect(_show_tab.bind(i))
		t.focus_entered.connect(_show_tab.bind(i))
		tabs.add_child(t)
		_tabs.append(t)
	_body = VBoxContainer.new()
	_body.position = Vector2(270, 290)
	_body.custom_minimum_size = Vector2(1060, 0)
	_body.add_theme_constant_override("separation", 14)
	add_child(_body)
	_back = MenuTile.new(MenuTile.Kind.BAR, "BACK", &"back")
	_back.custom_minimum_size = Vector2(260, 60)
	_back.position = Vector2(1080, 690)
	_back.pressed.connect(func() -> void: closed.emit())
	add_child(_back)
	_show_tab(0)


func open() -> void:
	visible = true
	_show_tab(_tab)
	_tabs[_tab].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func _draw_frame(frame: Control) -> void:
	var r := Rect2(Vector2.ZERO, frame.size)
	frame.draw_rect(Rect2(Vector2(-400, -400), Vector2(3000, 2000)), Color(MenuStyle.DEEP, 0.55))
	MenuStyle.draw_panel(frame, r, MenuStyle.NAVY, MenuStyle.GOLD, 2.5, 0.05)
	# The gold header band with the gear and the title.
	var band := Rect2(Vector2(0, 0), Vector2(520, 66))
	frame.draw_polygon(MenuStyle.slanted(band, 0.0), PackedColorArray([MenuStyle.GOLD, MenuStyle.GOLD.darkened(0.1), Color(MenuStyle.GOLD, 0.0), MenuStyle.GOLD]))
	MenuStyle.draw_icon(frame, &"gear", Vector2(48, 33), 40.0, MenuStyle.NAVY)
	MenuStyle.draw_text(frame, Vector2(86, 10), "SETTINGS", MenuStyle.HEAD_FONT, 48, MenuStyle.NAVY, false)


func _show_tab(i: int) -> void:
	if _body == null:
		return
	var changed := i != _tab or _body.get_child_count() == 0
	_tab = i
	for k in _tabs.size():
		_tabs[k].active = k == i
		_tabs[k].queue_redraw()
	if not changed:
		return
	for c in _body.get_children():
		c.queue_free()
	var name: String = TABS[i]
	if name == "CONTROLS":
		_body.add_child(_controls_table())
		return
	for row: Array in ROWS[name]:
		var line := SettingRow.new(row[0], row[1], row[2])
		line.changed.connect(func() -> void:
			if on_change.is_valid():
				on_change.call())
		_body.add_child(line)


func _controls_table() -> Control:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	for header: String in ["ACTION", "KEYBOARD / MOUSE", "GAMEPAD"]:
		grid.add_child(_cell(header, MenuStyle.HEAD_FONT, 28, MenuStyle.GOLD))
	for row: Array in CONTROLS:
		grid.add_child(_cell(row[0], MenuStyle.body(600), 19, MenuStyle.NEUTRAL))
		grid.add_child(_cell(row[1], MenuStyle.body(500), 19, MenuStyle.HIGHLIGHT.lightened(0.3)))
		grid.add_child(_cell(row[2], MenuStyle.body(500), 19, MenuStyle.HIGHLIGHT.lightened(0.3)))
	return grid


static func _cell(text: String, font: Font, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## A sub-menu tab: gold when it is the open one, blue otherwise.
class MenuTab:
	extends BaseButton
	var text := ""
	var active := false

	func _init(p_text: String) -> void:
		text = p_text
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(maxf(160.0, MenuStyle.text_width(p_text, MenuStyle.HEAD_FONT, 30) + 70.0), 50)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)

	func _draw() -> void:
		var on := active or has_focus()
		var fill := MenuStyle.GOLD if active else MenuStyle.BLUE.darkened(0.15)
		var rim := MenuStyle.NEUTRAL if has_focus() else (MenuStyle.GOLD.lightened(0.3) if active else MenuStyle.HIGHLIGHT.darkened(0.4))
		MenuStyle.draw_panel(self, Rect2(Vector2.ZERO, size), fill, rim, 3.0 if has_focus() else 1.5, 0.25, not active)
		var ink := MenuStyle.NAVY if active else (MenuStyle.NEUTRAL if on else MenuStyle.NEUTRAL.darkened(0.25))
		var tw := MenuStyle.text_width(text, MenuStyle.HEAD_FONT, 30)
		MenuStyle.draw_text(self, Vector2((size.x - tw) * 0.5, 10), text, MenuStyle.HEAD_FONT, 30, ink, false)


## One setting: its label, then a slider (0..1) or an ON/OFF toggle.
class SettingRow:
	extends Control
	signal changed
	var label := ""
	var key := ""
	var kind := ""
	var _drag := false

	func _init(p_label: String, p_key: String, p_kind: String) -> void:
		label = p_label
		key = p_key
		kind = p_kind
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(1060, 58)
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)

	func _control_rect() -> Rect2:
		return Rect2(Vector2(size.x - 380, 10), Vector2(320, 38))

	func _gui_input(event: InputEvent) -> void:
		var step := 0
		if event.is_action_pressed(&"ui_left"):
			step = -1
		elif event.is_action_pressed(&"ui_right"):
			step = 1
		elif event.is_action_pressed(&"ui_accept") and kind == "toggle":
			step = 1
		if step != 0:
			accept_event()
			if kind == "toggle":
				_apply_value(not bool(GameSettings.get_value(key)))
			else:
				_apply_value(clampf(snappedf(float(GameSettings.get_value(key)) + step * 0.05, 0.05), 0.0, 1.0))
			return
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_drag = event.pressed and kind == "slider"
			if event.pressed:
				accept_event()
				if kind == "toggle":
					_apply_value(not bool(GameSettings.get_value(key)))
				else:
					_slide(event.position.x)
		elif event is InputEventMouseMotion and _drag:
			_slide(event.position.x)

	func _slide(x: float) -> void:
		var r := _control_rect()
		_apply_value(clampf((x - r.position.x) / r.size.x, 0.0, 1.0))

	func _apply_value(value: Variant) -> void:
		GameSettings.set_value(key, value)
		queue_redraw()
		changed.emit()

	func _draw() -> void:
		var on := has_focus()
		var r := Rect2(Vector2.ZERO, size)
		if on:
			MenuStyle.draw_panel(self, r, MenuStyle.BLUE, MenuStyle.GOLD, 2.0, 0.08, false)
		else:
			draw_line(Vector2(0, size.y - 1), Vector2(size.x, size.y - 1), Color(MenuStyle.HIGHLIGHT, 0.18), 1.0)
		MenuStyle.draw_text(self, Vector2(26, 14), label, MenuStyle.body(600), 22, MenuStyle.NEUTRAL if on else MenuStyle.NEUTRAL.darkened(0.15), false)
		var c := _control_rect()
		if kind == "toggle":
			var value := bool(GameSettings.get_value(key))
			var pill := Rect2(Vector2(c.end.x - 170, c.position.y), Vector2(170, 38))
			MenuStyle.draw_panel(self, pill, MenuStyle.DEEP, MenuStyle.HIGHLIGHT.darkened(0.4), 1.5, 0.2, false)
			var half := Rect2(pill.position + (Vector2.ZERO if value else Vector2(85, 0)), Vector2(85, 38))
			MenuStyle.draw_panel(self, half, MenuStyle.GOLD, MenuStyle.GOLD.lightened(0.4), 1.5, 0.2, false)
			MenuStyle.draw_text(self, pill.position + Vector2(22, 8), "ON", MenuStyle.body(700), 18, MenuStyle.NAVY if value else MenuStyle.NEUTRAL.darkened(0.3), false)
			MenuStyle.draw_text(self, pill.position + Vector2(105, 8), "OFF", MenuStyle.body(700), 18, MenuStyle.NEUTRAL.darkened(0.3) if value else MenuStyle.NAVY, false)
		else:
			var value := float(GameSettings.get_value(key))
			var y := c.get_center().y
			draw_line(Vector2(c.position.x, y), Vector2(c.end.x, y), MenuStyle.DEEP, 8.0, true)
			draw_line(Vector2(c.position.x, y), Vector2(c.position.x + c.size.x * value, y), MenuStyle.GOLD, 8.0, true)
			var knob := Vector2(c.position.x + c.size.x * value, y)
			draw_circle(knob, 13.0, MenuStyle.GOLD.lightened(0.2))
			draw_circle(knob, 7.0, MenuStyle.GOLD.darkened(0.25))
			MenuStyle.draw_text(self, Vector2(c.end.x + 18, 12), "%d" % roundi(value * 100.0), MenuStyle.body(700), 20, MenuStyle.NEUTRAL, false)
