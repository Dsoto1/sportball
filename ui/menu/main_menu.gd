class_name MainMenu
extends Control
## The main menu, laid out as the owner's UI/UX reference: the big
## slanted buttons down the left (PLAY NOW, CAREER, CREATOR STUDIO,
## SETTINGS), the profile / sound / power icons top right, the game's
## crest over a live stadium (MenuBackdrop flies the camera behind this),
## gold flashes in the corners. CAREER and CREATOR STUDIO open their tile
## screens; their modes aren't built yet, so the tiles say "coming soon".
## Gamepad, keyboard and mouse all work (focus navigation).

signal play_pressed
signal quit_pressed

enum Screen { HOME, CAREER, CREATOR, SETTINGS }

var _screen := Screen.HOME
var _home: Control
var _career: Control
var _creator: Control
var _settings: SettingsPanel
var _crest: MenuCrest
var _sound: MenuTile
var _toast := ""
var _toast_until := 0.0
var _first_home: MenuTile
var _clock := 0.0
## The sound effects, if the match view's are available.
var sfx: Sfx


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# Under a CanvasLayer the anchors have no parent rect: size to the view.
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func() -> void: size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_home = _screen_root()
	_crest = MenuCrest.new()
	_crest.position = Vector2(900, 150)
	_crest.size = Vector2(520, 520)
	_home.add_child(_crest)
	var column := [
		["PLAY NOW", &"play", "", false, _play],
		["CAREER", &"cap", "My Player   |   My Franchise", false, _show.bind(Screen.CAREER)],
		["CREATOR STUDIO", &"tools", "", false, _show.bind(Screen.CREATOR)],
		["SETTINGS", &"gear", "", false, _show.bind(Screen.SETTINGS)],
	]
	for i in column.size():
		var b := MenuTile.new(MenuTile.Kind.WIDE, column[i][0], column[i][1], column[i][2])
		b.custom_minimum_size = Vector2(500 - i * 14, 104 if i == 0 else 92)
		b.position = Vector2(60 - i * 10, 210 + i * 116)
		b.size = b.custom_minimum_size
		b.pressed.connect(column[i][4])
		b.focus_entered.connect(_tick)
		_home.add_child(b)
		if i == 0:
			_first_home = b
	# Profile, sound and power, top right.
	var bar := HBoxContainer.new()
	bar.position = Vector2(1300, 34)
	bar.add_theme_constant_override("separation", 10)
	_home.add_child(bar)
	var profile := MenuTile.new(MenuTile.Kind.ICON, "", &"person")
	profile.pressed.connect(_say.bind("PROFILES · COMING SOON"))
	_sound = MenuTile.new(MenuTile.Kind.ICON, "", &"mute" if GameSettings.get_value("muted") else &"sound")
	_sound.pressed.connect(_toggle_mute)
	var power := MenuTile.new(MenuTile.Kind.ICON, "", &"power")
	power.pressed.connect(func() -> void: quit_pressed.emit())
	for b in [profile, _sound, power]:
		b.focus_entered.connect(_tick)
		bar.add_child(b)
	_career = _tiles_screen("CAREER", &"cap", [["MY PLAYER", &"batter"], ["MY\nFRANCHISE", &"trophy"]])
	_creator = _tiles_screen("CREATOR STUDIO", &"tools", [["BALLPARK\nCREATOR", &"diamond"], ["TEAM\nCREATOR", &"jersey"], ["LEAGUE\nCREATOR", &"bats"]])
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_show.bind(Screen.HOME))
	add_child(_settings)
	_show(Screen.HOME)


func open() -> void:
	visible = true
	_show(Screen.HOME)


func _screen_root() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c


## A sub-menu: the gold header band, a row of tiles (all coming soon),
## and BACK.
func _tiles_screen(heading: String, icon: StringName, tiles: Array) -> Control:
	var root := _screen_root()
	var head := MenuHeader.new(heading, icon)
	head.position = Vector2(200, 230)
	head.size = Vector2(1200, 380)
	root.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	root.add_child(row)
	var first: MenuTile = null
	for t: Array in tiles:
		var tile := MenuTile.new(MenuTile.Kind.TILE, t[0], t[1])
		tile.soon = true
		tile.custom_minimum_size = Vector2(300, 240)
		tile.pressed.connect(_say.bind("%s · COMING SOON" % String(t[0]).replace("\n", " ")))
		tile.focus_entered.connect(_tick)
		row.add_child(tile)
		if first == null:
			first = tile
	var width := tiles.size() * 300.0 + (tiles.size() - 1) * 26.0
	row.position = Vector2(800 - width * 0.5, 330)
	var back := MenuTile.new(MenuTile.Kind.BAR, "BACK", &"back")
	back.custom_minimum_size = Vector2(240, 58)
	back.position = Vector2(1130, 640)
	back.pressed.connect(_show.bind(Screen.HOME))
	back.focus_entered.connect(_tick)
	root.add_child(back)
	root.set_meta("first", first)
	return root


func _show(screen: Screen) -> void:
	var from := _screen
	_screen = screen
	_home.visible = screen == Screen.HOME
	_career.visible = screen == Screen.CAREER
	_creator.visible = screen == Screen.CREATOR
	_settings.visible = false
	match screen:
		Screen.HOME:
			# Back on the button that opened the sub-menu.
			var index := {Screen.CAREER: 1, Screen.CREATOR: 2, Screen.SETTINGS: 3}.get(from, 0) as int
			var buttons := _home.get_children().filter(func(n: Node) -> bool: return n is MenuTile)
			(buttons[index] as MenuTile).grab_focus()
		Screen.CAREER:
			(_career.get_meta("first") as MenuTile).grab_focus()
		Screen.CREATOR:
			(_creator.get_meta("first") as MenuTile).grab_focus()
		Screen.SETTINGS:
			_settings.open()
	if from != screen and sfx != null:
		sfx.play(&"ui_select")
	queue_redraw()


func _play() -> void:
	if sfx != null:
		sfx.play(&"ui_confirm")
	play_pressed.emit()


func _toggle_mute() -> void:
	GameSettings.set_value("muted", not bool(GameSettings.get_value("muted")))
	_sound.icon = &"mute" if GameSettings.get_value("muted") else &"sound"
	_sound.queue_redraw()


func _say(text: String) -> void:
	_toast = text
	_toast_until = _clock + 2.0
	if sfx != null:
		sfx.play(&"ui_error")
	queue_redraw()


func _tick() -> void:
	if sfx != null and visible:
		sfx.play(&"ui_tick")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"ui_cancel") and _screen in [Screen.CAREER, Screen.CREATOR]:
		get_viewport().set_input_as_handled()
		_show(Screen.HOME)


func _process(delta: float) -> void:
	_clock += delta
	if _toast != "" and _clock > _toast_until:
		_toast = ""
	queue_redraw()


func _draw() -> void:
	var s := size
	# Navy wash, heaviest on the left behind the buttons, a vignette.
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(s.x * 0.62, 0), Vector2(s.x * 0.42, s.y), Vector2(0, s.y)]),
		PackedColorArray([Color(MenuStyle.DEEP, 0.82), Color(MenuStyle.DEEP, 0.0), Color(MenuStyle.DEEP, 0.0), Color(MenuStyle.DEEP, 0.85)]))
	draw_rect(Rect2(0, s.y - 120, s.x, 120), Color(MenuStyle.DEEP, 0.35))
	if _screen != Screen.HOME:
		draw_rect(Rect2(Vector2.ZERO, s), Color(MenuStyle.DEEP, 0.45))
	# Gold flashes: top-left and bottom-right corners.
	MenuStyle.draw_stripe(self, Vector2(-40, 0), 210, 16, MenuStyle.GOLD)
	MenuStyle.draw_stripe(self, Vector2(-80, 30), 150, 6, Color(MenuStyle.GOLD, 0.6))
	MenuStyle.draw_stripe(self, Vector2(s.x - 380, s.y - 22), 420, 22, MenuStyle.GOLD)
	MenuStyle.draw_stripe(self, Vector2(s.x - 300, s.y - 40), 340, 6, Color(MenuStyle.GOLD, 0.6))
	if _screen == Screen.HOME:
		MenuStyle.draw_text(self, Vector2(64, 92), "SPORTBALL", MenuStyle.HEAD_FONT, 88, MenuStyle.NEUTRAL)
		MenuStyle.draw_stripe(self, Vector2(66, 176), 300, 5, MenuStyle.GOLD)
	# Prompt line, bottom left.
	var hint := "ENTER / A  select      ESC / B  back      F11  full screen" if _screen != Screen.HOME else "ENTER / A  select      F11  full screen"
	MenuStyle.draw_text(self, Vector2(64, s.y - 52), hint, MenuStyle.body(600), 17, Color(MenuStyle.NEUTRAL, 0.75))
	if _toast != "":
		var a := clampf((_toast_until - _clock) / 0.3, 0.0, 1.0)
		var tw := MenuStyle.text_width(_toast, MenuStyle.HEAD_FONT, 40) + 80.0
		var r := Rect2(Vector2((s.x - tw) * 0.5, s.y - 190), Vector2(tw, 62))
		MenuStyle.draw_panel(self, r, Color(MenuStyle.NAVY, a), Color(MenuStyle.GOLD, a), 2.5, 0.2)
		MenuStyle.draw_text(self, r.position + Vector2(40, 12), _toast, MenuStyle.HEAD_FONT, 40, Color(MenuStyle.GOLD, a))


## The game's crest (our own mark): a gold-rimmed navy shield, two crossed
## bats behind a ball, a gold swoosh under it, bobbing gently.
class MenuCrest:
	extends Control
	var _t := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5 + Vector2(0, sin(_t * 1.2) * 6.0)
		var r := size.x * 0.36
		# A soft glow behind it.
		for i in 6:
			draw_circle(c, r * (1.25 - i * 0.05), Color(MenuStyle.GOLD, 0.025))
		# Bats, crossed behind the shield.
		for side: float in [-1.0, 1.0]:
			var a := c + Vector2(side * r * 1.05, -r * 1.0)
			var b := c + Vector2(-side * r * 0.75, r * 0.85)
			var d := (b - a).normalized()
			var n := Vector2(-d.y, d.x)
			var wood := Color(0.78, 0.55, 0.3)
			draw_colored_polygon(PackedVector2Array([a + n * r * 0.13, a - n * r * 0.13, b - n * r * 0.04, b + n * r * 0.04]), wood)
			draw_circle(a, r * 0.13, wood)
			draw_line(a + n * r * 0.13, b + n * r * 0.04, wood.lightened(0.3), 3.0, true)
			draw_circle(b, r * 0.07, wood.darkened(0.3))
		# The shield: gold rim, navy face, an inner gold line.
		var shield := _shield(c, r)
		draw_colored_polygon(shield, MenuStyle.GOLD)
		draw_colored_polygon(_shield(c, r * 0.9), MenuStyle.NAVY)
		var inner := _shield(c, r * 0.8)
		inner.append(inner[0])
		draw_polyline(inner, Color(MenuStyle.GOLD, 0.7), 2.5, true)
		# The ball with its red seams.
		var bc := c + Vector2(0, -r * 0.08)
		var br := r * 0.42
		draw_circle(bc, br + 4.0, MenuStyle.GOLD.darkened(0.2))
		draw_circle(bc, br, Color(0.97, 0.96, 0.93))
		draw_circle(bc + Vector2(br * 0.25, br * 0.3), br * 0.75, Color(0.88, 0.86, 0.82, 0.5))
		for side: float in [-1.0, 1.0]:
			var seam := bc + Vector2(side * br * 1.35, 0)
			draw_arc(seam, br * 0.95, PI * 0.5 + side * PI * 0.5 - 0.62, PI * 0.5 + side * PI * 0.5 + 0.62, 18, MenuStyle.DANGER, 2.5, true)
			for k in 7:
				var ang := PI * 0.5 + side * PI * 0.5 - 0.5 + k * 1.0 / 6.0
				var p := seam + Vector2(cos(ang), sin(ang)) * br * 0.95
				var t := Vector2(-sin(ang), cos(ang)) * 5.0
				draw_line(p - t + Vector2(side * 4, 0), p + t + Vector2(side * 4, 0), MenuStyle.DANGER, 2.0)
		# The swoosh under the ball.
		var sw := PackedVector2Array()
		for i in 25:
			var u := i / 24.0
			sw.append(c + Vector2(lerpf(-r * 0.95, r * 1.05, u), r * 0.42 - sin(u * PI) * r * 0.22 - u * r * 0.12))
		for i in 24:
			var u := 1.0 - i / 23.0
			sw.append(c + Vector2(lerpf(-r * 0.95, r * 1.05, u), r * 0.42 - sin(u * PI) * r * 0.22 - u * r * 0.12 + r * 0.1 * sin(u * PI)))
		draw_colored_polygon(sw, MenuStyle.GOLD)

	static func _shield(c: Vector2, r: float) -> PackedVector2Array:
		return PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.85, -r * 0.62), c + Vector2(r * 0.9, r * 0.05),
			c + Vector2(r * 0.55, r * 0.62), c + Vector2(0, r * 1.02), c + Vector2(-r * 0.55, r * 0.62),
			c + Vector2(-r * 0.9, r * 0.05), c + Vector2(-r * 0.85, -r * 0.62)])


## A sub-menu's frame: a navy panel with a gold header band (icon, title).
class MenuHeader:
	extends Control
	var heading := ""
	var icon: StringName

	func _init(p_heading: String, p_icon: StringName) -> void:
		heading = p_heading
		icon = p_icon
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		MenuStyle.draw_panel(self, Rect2(Vector2.ZERO, size), MenuStyle.NAVY, MenuStyle.GOLD, 2.5, 0.05)
		var band := Rect2(Vector2(0, 0), Vector2(size.x * 0.55, 66))
		draw_polygon(MenuStyle.slanted(band, 0.0), PackedColorArray([MenuStyle.GOLD, MenuStyle.GOLD.darkened(0.1), Color(MenuStyle.GOLD, 0.0), MenuStyle.GOLD]))
		MenuStyle.draw_icon(self, icon, Vector2(48, 33), 40.0, MenuStyle.NAVY)
		MenuStyle.draw_text(self, Vector2(86, 10), heading, MenuStyle.HEAD_FONT, 48, MenuStyle.NAVY, false)
