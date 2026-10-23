class_name MatchHud
extends Control
## Broadcast-style match HUD, laid out after the owner's reference frame:
##   top left: the scorebug (both clubs, runs, inning, count, outs, bases),
##     the pitcher's card (today's IP H R BB K and his stamina) and the
##     batter's card (season AVG HR RBI and today's hits in at-bats);
##   top right: a little field with the runners on it and the lead runner's
##     speed, the steal hint when batting;
##   pitching: the repertoire down the left (key, name, speed), the picked
##     pitch's card on the right (velocity, movement, break direction,
##     control), the controls under it and the options (pitching change,
##     pickoff, slide step) bottom left; the meter under the plate.
## It only reads state handed to it. Text and menus are M PLUS 1 Bold;
## scores, callouts and title cards are Bungee (both SIL OFL). Prompts
## show the player's own key or button icons (Kenney Input Prompts, CC0).

const BODY_FONT := preload("res://ui/fonts/menu_font.tres")
const DISPLAY_FONT := preload("res://assets/third_party/fonts/bungee/Bungee-Regular.ttf")
const PANEL := Color(0.04, 0.05, 0.08, 0.86)
const PANEL_EDGE := Color(1, 1, 1, 0.08)
const SELECT := Color(0.12, 0.32, 0.72, 0.95)
const SELECT_EDGE := Color(0.55, 0.75, 1.0)
const DIM := Color(1, 1, 1, 0.62)
const LEFT := 24.0
const CARD_W := 482.0
const MPH := 2.23694
const INCHES := 39.3701

## The match's tuning (pitch speeds and ratings); set by the director.
var tuning: BaseballTuning
var gamepad := false

var _roster: MatchRoster
var _state: MatchState
var _menu: Label
var _menu_title := ""
var _clock: Label
var _card: VBoxContainer
var _callout: Label
var _detail: Label
var _prompt: RichTextLabel
var _prompt_text := ""
var _callout_timer := 0.0
var _meter: PitchMeter

# Scorebug and cards.
var _bug := {}
var _pitcher_card := {}
var _batter_card := {}
var _field: MiniField
# Pitching.
var _pitch_list: VBoxContainer
var _pitch_rows: Array = []
var _pitch_info := {}
var _controls: PanelContainer
var _controls_text: RichTextLabel
var _options: RichTextLabel
var _families: Array[PitchFamilyDef] = []
var _selected := 0
var _slide_step := false
var _pitching := false
# Batting.
var _batting := false
## The hitter bats left: his card and the scouting list swap sides.
var _lefty := false
var _banner := {}
var _hitter := {}
var _swing_box: PanelContainer
var _swing_text: RichTextLabel
var _bat_options: RichTextLabel
var _steal_hint: RichTextLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := Theme.new()
	look.default_font = BODY_FONT
	theme = look
	_build_scorebug()
	_pitcher_card = _build_card(Vector2(LEFT, 112), "P")
	_batter_card = _build_card(Vector2(LEFT, 180), "AT BAT")
	_field = MiniField.new()
	_field.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_field.position = Vector2(-236, 6)
	_field.size = Vector2(216, 200)
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_field)
	_build_pitch_list()
	_build_pitch_info()
	_build_controls()
	_build_batting()

	_callout = _wide_label(64, Control.PRESET_TOP_WIDE, 250.0)
	_detail = _wide_label(24, Control.PRESET_TOP_WIDE, 335.0)
	_prompt = RichTextLabel.new()
	_prompt.bbcode_enabled = true
	_prompt.fit_content = true
	_prompt.scroll_active = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_font_size_override("normal_font_size", 21)
	_prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt.add_theme_constant_override("outline_size", 6)
	add_child(_prompt)
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.offset_top = -90.0
	_prompt.offset_bottom = -12.0

	_meter = PitchMeter.new()
	_meter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_meter.size = Vector2(360, 22)
	_meter.position = Vector2(-180, -64)
	add_child(_meter)
	_menu = _label(self, 22)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_menu.position += Vector2(-330, -60)
	_menu.visible = false
	_clock = _label(self, 34)
	_clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_clock.position += Vector2(-330, 30)
	_clock.visible = false
	_card = VBoxContainer.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_card.position.y = 230.0
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	for big in [_callout, _clock]:
		big.add_theme_font_override("font", DISPLAY_FONT)
	show_pitching(false)


# --- Building -----------------------------------------------------------------

static func panel_style(color: Color = PANEL, radius: int = 8, edge: Color = PANEL_EDGE) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(radius)
	box.border_color = edge
	box.set_border_width_all(1)
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box


func _panel(at: Vector2, size_px: Vector2, color: Color = PANEL) -> Panel:
	var p := Panel.new()
	p.position = at
	p.size = size_px
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", panel_style(color))
	add_child(p)
	return p


func _text(parent: Control, at: Vector2, font_size: int, color: Color = Color.WHITE, display: bool = false) -> Label:
	var l := Label.new()
	l.position = at
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if display:
		l.add_theme_font_override("font", DISPLAY_FONT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## Both clubs with their badge colors and runs, the inning, count and outs,
## and the bases in a diamond.
func _build_scorebug() -> void:
	var bug := _panel(Vector2(LEFT, 18), Vector2(CARD_W, 86))
	for i in 2:
		var x := 6.0 + i * 190.0
		var tile := ColorRect.new()
		tile.position = Vector2(x, 6)
		tile.size = Vector2(182, 46)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bug.add_child(tile)
		var badge := Badge.new()
		badge.position = Vector2(x + 4, 7)
		badge.size = Vector2(44, 44)
		bug.add_child(badge)
		_bug["tile%d" % i] = tile
		_bug["badge%d" % i] = badge
		_bug["abbr%d" % i] = _text(bug, Vector2(x + 54, 10), 26, Color.WHITE, true)
		_bug["runs%d" % i] = _text(bug, Vector2(x + 140, 6), 32, Color.WHITE, true)
	_bug["inning"] = _text(bug, Vector2(14, 54), 20, Color.WHITE, true)
	_bug["count"] = _text(bug, Vector2(86, 54), 20, Color.WHITE, true)
	_bug["balls"] = Dots.new(3, Color(0.4, 0.9, 0.5))
	_bug["balls"].position = Vector2(150, 62)
	bug.add_child(_bug["balls"])
	_bug["strikes"] = Dots.new(2, Color(1.0, 0.75, 0.25))
	_bug["strikes"].position = Vector2(206, 62)
	bug.add_child(_bug["strikes"])
	_text(bug, Vector2(250, 54), 20, Color.WHITE, true).text = "OUTS"
	_bug["outs"] = Dots.new(2, Color(1.0, 0.35, 0.3))
	_bug["outs"].position = Vector2(326, 62)
	bug.add_child(_bug["outs"])
	_bug["bases"] = BaseDiamond.new()
	_bug["bases"].position = Vector2(388, 2)
	_bug["bases"].size = Vector2(88, 82)
	bug.add_child(_bug["bases"])


## A player card: a round badge, a heading line and a stat line.
func _build_card(at: Vector2, tag: String) -> Dictionary:
	var card := _panel(at, Vector2(CARD_W, 62))
	var badge := Badge.new()
	badge.position = Vector2(8, 9)
	badge.size = Vector2(42, 42)
	card.add_child(badge)
	var head := _text(card, Vector2(60, 4), 19)
	var hand := _text(card, Vector2(CARD_W - 60, 4), 19)
	hand.size = Vector2(48, 26)
	hand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var line := _text(card, Vector2(60, 32), 18, DIM)
	var bar := Bar.new()
	bar.position = Vector2(CARD_W - 170, 38)
	bar.size = Vector2(150, 12)
	bar.visible = false
	card.add_child(bar)
	return {"panel": card, "badge": badge, "head": head, "hand": hand, "line": line, "bar": bar, "tag": tag}


## The repertoire, one row per pitch: its key, a ball, the name and speed.
func _build_pitch_list() -> void:
	_pitch_list = VBoxContainer.new()
	_pitch_list.position = Vector2(LEFT + 12, 370)
	_pitch_list.add_theme_constant_override("separation", 4)
	_pitch_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pitch_list)
	for i in 5:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(320, 62)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pitch_list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(h)
		var ball := BallIcon.new()
		ball.custom_minimum_size = Vector2(46, 46)
		ball.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(ball)
		var key := RichTextLabel.new()
		key.bbcode_enabled = true
		key.fit_content = true
		key.scroll_active = false
		key.custom_minimum_size = Vector2(36, 36)
		key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(key)
		var words := VBoxContainer.new()
		words.add_theme_constant_override("separation", -4)
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_child(words)
		var name_label := _label(words, 22)
		var speed := _label(words, 15)
		speed.add_theme_color_override("font_color", DIM)
		_pitch_rows.append({"row": row, "key": key, "name": name_label, "speed": speed, "ball": ball})
	_options = RichTextLabel.new()
	_options.bbcode_enabled = true
	_options.fit_content = true
	_options.scroll_active = false
	_options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options.add_theme_font_size_override("normal_font_size", 19)
	_options.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_options.position = Vector2(LEFT + 6, -150)
	_options.size = Vector2(420, 140)
	add_child(_options)


## The picked pitch's card: velocity, a 3x3 break chart, movement in
## inches and how well he commands it.
func _build_pitch_info() -> void:
	var box := Panel.new()
	box.add_theme_stylebox_override("panel", panel_style())
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	box.position = Vector2(-290, 404)
	box.size = Vector2(266, 250)
	add_child(box)
	var title := _text(box, Vector2(14, 8), 19)
	var rule := ColorRect.new()
	rule.color = Color(1, 1, 1, 0.25)
	rule.position = Vector2(14, 38)
	rule.size = Vector2(238, 1)
	box.add_child(rule)
	var ball := BallIcon.new()
	ball.position = Vector2(30, 56)
	ball.size = Vector2(44, 44)
	box.add_child(ball)
	_text(box, Vector2(150, 46), 14, DIM).text = "VELOCITY"
	var velo := _text(box, Vector2(150, 62), 22)
	var grid := BreakGrid.new()
	grid.position = Vector2(18, 116)
	grid.size = Vector2(108, 112)
	box.add_child(grid)
	_text(box, Vector2(150, 108), 14, DIM).text = "MOVEMENT"
	var h_line := _text(box, Vector2(150, 126), 19)
	var v_line := _text(box, Vector2(150, 152), 19)
	_text(box, Vector2(150, 186), 14, DIM).text = "CONTROL"
	var bar := Bar.new()
	bar.position = Vector2(150, 208)
	bar.size = Vector2(98, 12)
	bar.fill = Color(0.35, 0.6, 1.0)
	box.add_child(bar)
	_pitch_info = {"box": box, "title": title, "velo": velo, "grid": grid, "h": h_line, "v": v_line, "bar": bar, "ball": ball}


func _build_controls() -> void:
	_controls = PanelContainer.new()
	_controls.add_theme_stylebox_override("panel", panel_style())
	_controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_controls.position = Vector2(-206, 670)
	_controls.size = Vector2(182, 150)
	add_child(_controls)
	_controls_text = RichTextLabel.new()
	_controls_text.bbcode_enabled = true
	_controls_text.fit_content = true
	_controls_text.scroll_active = false
	_controls_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_controls_text.add_theme_font_size_override("normal_font_size", 17)
	_controls.add_child(_controls_text)


## The batting set: the hitter's banner top center (season line, tonight's
## hits, bases), his card on the left (ratings bars, his nickname as his
## calling card), the pitcher's repertoire on the right as scouting (the
## pitch list), the swing controls bottom right and options bottom left.
func _build_batting() -> void:
	var banner := Panel.new()
	banner.add_theme_stylebox_override("panel", panel_style(PANEL, 8, Color(1, 1, 1, 0.25)))
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-230, 118)
	banner.size = Vector2(460, 118)
	add_child(banner)
	var badge := Badge.new()
	badge.position = Vector2(10, 14)
	badge.size = Vector2(90, 90)
	banner.add_child(badge)
	var title := _text(banner, Vector2(112, 8), 20, Color.WHITE, true)
	title.size = Vector2(250, 30)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var pos := _text(banner, Vector2(112, 40), 15, DIM)
	var stats := []
	for i in 3:
		_text(banner, Vector2(112 + i * 62, 62), 12, DIM).text = ["AVG", "HR", "RBI"][i]
		stats.append(_text(banner, Vector2(112 + i * 62, 76), 22, Color.WHITE, true))
	var rule := ColorRect.new()
	rule.color = Color(1, 1, 1, 0.2)
	rule.position = Vector2(366, 10)
	rule.size = Vector2(1, 98)
	banner.add_child(rule)
	_text(banner, Vector2(378, 8), 12, DIM).text = "TONIGHT"
	var tonight := _text(banner, Vector2(380, 24), 24, Color.WHITE, true)
	var bases := BaseDiamond.new()
	bases.position = Vector2(378, 56)
	bases.size = Vector2(66, 58)
	banner.add_child(bases)
	_banner = {"box": banner, "badge": badge, "title": title, "pos": pos, "stats": stats, "tonight": tonight, "bases": bases}

	var card := _panel(Vector2(LEFT + 12, 470), Vector2(320, 228))
	var cbadge := Badge.new()
	cbadge.position = Vector2(10, 10)
	cbadge.size = Vector2(70, 70)
	card.add_child(cbadge)
	var cname := _text(card, Vector2(90, 8), 20, Color.WHITE, true)
	cname.size = Vector2(160, 28)
	cname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cname.clip_text = true
	var chand := _text(card, Vector2(270, 8), 20, Color.WHITE, true)
	var cpos := _text(card, Vector2(90, 34), 15, DIM)
	var cline := _text(card, Vector2(90, 54), 17)
	var calling := _text(card, Vector2(14, 92), 17, Color(1.0, 0.85, 0.35))
	var bars := []
	for i in 3:
		_text(card, Vector2(14, 122 + i * 32), 17).text = ["CONTACT", "POWER", "VISION"][i]
		var bar := Bar.new()
		bar.position = Vector2(118, 130 + i * 32)
		bar.size = Vector2(140, 12)
		bar.fill = [Color(0.35, 0.85, 0.35), Color(1.0, 0.8, 0.25), Color(0.35, 0.6, 1.0)][i]
		card.add_child(bar)
		var num := _text(card, Vector2(270, 122 + i * 32), 17)
		bars.append([bar, num])
	_hitter = {"box": card, "badge": cbadge, "name": cname, "hand": chand, "pos": cpos, "line": cline, "calling": calling, "bars": bars}

	_swing_box = PanelContainer.new()
	_swing_box.add_theme_stylebox_override("panel", panel_style())
	_swing_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swing_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_swing_box.position = Vector2(-372, -196)
	_swing_box.size = Vector2(348, 172)
	add_child(_swing_box)
	_swing_text = RichTextLabel.new()
	_swing_text.bbcode_enabled = true
	_swing_text.fit_content = true
	_swing_text.scroll_active = false
	_swing_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swing_text.add_theme_font_size_override("normal_font_size", 17)
	_swing_box.add_child(_swing_text)
	_bat_options = RichTextLabel.new()
	_bat_options.bbcode_enabled = true
	_bat_options.fit_content = true
	_bat_options.scroll_active = false
	_bat_options.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bat_options.add_theme_font_size_override("normal_font_size", 19)
	_bat_options.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_bat_options.position = Vector2(LEFT + 6, -130)
	_bat_options.size = Vector2(460, 120)
	add_child(_bat_options)
	_steal_hint = RichTextLabel.new()
	_steal_hint.bbcode_enabled = true
	_steal_hint.fit_content = true
	_steal_hint.scroll_active = false
	_steal_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_steal_hint.add_theme_font_size_override("normal_font_size", 18)
	_steal_hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_steal_hint.position = Vector2(-150, 200)
	_steal_hint.size = Vector2(140, 40)
	add_child(_steal_hint)


func show_batting(visible_now: bool, families: Array[PitchFamilyDef] = []) -> void:
	_batting = visible_now
	for node: CanvasItem in [_banner["box"], _hitter["box"], _swing_box, _bat_options, _steal_hint]:
		node.visible = visible_now
	_batter_card["panel"].visible = not visible_now
	if visible_now:
		_families = families
		_selected = -1
		_pitch_list.visible = true
		_prompt.visible = false
		_refresh_batting()
		_refresh_pitches()
	elif not _pitching:
		_pitch_list.visible = false
		_prompt.visible = true


func _refresh_batting() -> void:
	if _state == null or _roster == null:
		return
	var b := _roster.player(_state.current_batter())
	if b == null:
		return
	var team := _roster.teams[_state.batting_team()]
	var season := SeasonLine.for_player(b)
	var today := GameLines.batter(_state, b.id)
	var position: StringName = &"DH"
	var defense: Dictionary = _state.defense[_state.batting_team()]
	for pos: StringName in defense:
		if defense[pos] == b.id:
			position = StringName(String(pos).to_upper())
	_lefty = b.bats_left()
	var card: Panel = _hitter["box"]
	card.position = Vector2(size.x - 24 - 12 - card.size.x, 470) if _lefty else Vector2(LEFT + 12, 470)
	# The swing controls and options swap too (mirror of the righty layout).
	_swing_box.position = Vector2(LEFT, size.y - 196) if _lefty else Vector2(size.x - 372, size.y - 196)
	_bat_options.position = Vector2(LEFT + 6, size.y - 270) if _lefty else Vector2(LEFT + 6, size.y - 130)
	(_banner["badge"] as Badge).set_letter(str(b.number), team)
	_banner["title"].text = "#%d  %s" % [b.number, b.display_name.to_upper()]
	_banner["pos"].text = String(position)
	var vals := [SeasonLine.avg_text(season["avg"]), str(season["hr"]), str(season["rbi"])]
	for i in 3:
		(_banner["stats"][i] as Label).text = vals[i]
	_banner["tonight"].text = "%d-%d" % [today["h"], today["ab"]]
	(_banner["bases"] as BaseDiamond).set_bases(_state.bases)
	(_hitter["badge"] as Badge).set_letter(String(position), team)
	_hitter["name"].text = "#%d %s" % [b.number, b.display_name.get_slice(" ", b.display_name.get_slice_count(" ") - 1).to_upper()]
	_hitter["hand"].text = String(b.bats)
	_hitter["pos"].text = String(position)
	_hitter["line"].text = "%s  ·  %d HR  ·  %d RBI" % [vals[0], season["hr"], season["rbi"]]
	_hitter["calling"].text = ("★  \"%s\"" % b.nickname) if b.nickname != "" else ""
	var ratings := [b.contact, b.power, b.eye]
	for i in 3:
		var pair: Array = _hitter["bars"][i]
		(pair[0] as Bar).value = ratings[i] / 100.0
		(pair[0] as Bar).queue_redraw()
		(pair[1] as Label).text = str(ratings[i])
	var pad := gamepad
	_swing_text.text = "[b]SWING[/b]\n%s  CONTACT\n%s  POWER\n%s  BUNT\n%s  AIM · LIFT · CHOP" % [
		PromptIcons.icons(&"swing_contact", pad, 28), PromptIcons.icons(&"swing_power", pad, 28),
		PromptIcons.icons(&"swing_bunt", pad, 28), PromptIcons.icons(&"move", pad, 28)]
	_bat_options.text = "%s  PINCH HIT\n%s %s  STEAL / CALL IT OFF" % [
		PromptIcons.icons(&"open_subs", pad, 28), PromptIcons.icons(&"runner_advance", pad, 28), PromptIcons.icons(&"runner_retreat", pad, 28)]
	var on_base := _state.bases.any(func(r: StringName) -> bool: return r != &"")
	_steal_hint.visible = on_base
	_steal_hint.text = "STEAL %s" % PromptIcons.icons(&"runner_advance", pad, 26)


# --- State ----------------------------------------------------------------------

func set_roster(roster: MatchRoster) -> void:
	_roster = roster
	for i in 2:
		var team := roster.teams[i]
		(_bug["tile%d" % i] as ColorRect).color = team.primary_color.darkened(0.15)
		(_bug["badge%d" % i] as Badge).set_team(team)
		(_bug["abbr%d" % i] as Label).text = team.abbreviation


## The brighter of a team's two main colors, so it reads on a dark panel.
static func text_color(team: TeamDef) -> Color:
	var a := team.primary_color
	var b := team.secondary_color
	return a if a.get_luminance() >= b.get_luminance() else b


func show_state(state: MatchState, user_team: int) -> void:
	_state = state
	for i in 2:
		(_bug["runs%d" % i] as Label).text = str(state.score[i])
		(_bug["abbr%d" % i] as Label).text = (_roster.teams[i].abbreviation if _roster != null else ["AWAY", "HOME"][i]) + ("*" if user_team == i else "")
	(_bug["inning"] as Label).text = "%s%d" % ["▲" if state.is_top else "▼", state.inning]
	(_bug["count"] as Label).text = "%d-%d" % [state.balls, state.strikes]
	(_bug["balls"] as Dots).set_lit(state.balls)
	(_bug["strikes"] as Dots).set_lit(state.strikes)
	(_bug["outs"] as Dots).set_lit(state.outs)
	(_bug["bases"] as BaseDiamond).set_bases(state.bases)
	_field.set_state(state, _roster, tuning, user_team)
	_show_cards(state)
	if _pitching:
		_refresh_pitches()
	if _batting:
		_refresh_batting()


func _show_cards(state: MatchState) -> void:
	if _roster == null:
		return
	var pitcher := _roster.player(state.pitcher(state.fielding_team()))
	var batter := _roster.player(state.current_batter())
	var fielding := _roster.teams[state.fielding_team()]
	var batting := _roster.teams[state.batting_team()]
	if pitcher != null:
		var line := GameLines.pitcher(state, pitcher.id)
		_pitcher_card["badge"].set_letter("P", fielding)
		_pitcher_card["head"].text = "P  %d   %s" % [pitcher.number, pitcher.display_name]
		_pitcher_card["hand"].text = "%sHP" % pitcher.throws
		_pitcher_card["line"].text = "%s IP   %d H   %d R   %d BB   %d K" % [line["ip"], line["h"], line["r"], line["bb"], line["k"]]
		var bar: Bar = _pitcher_card["bar"]
		bar.visible = tuning != null
		if tuning != null:
			bar.value = 1.0 - Ratings.fatigue(pitcher, state.pitches_thrown(pitcher.id), tuning)
			bar.fill = Color(0.35, 0.85, 0.35) if bar.value > 0.5 else (Color(1.0, 0.8, 0.25) if bar.value > 0.25 else Color(1.0, 0.35, 0.3))
			bar.queue_redraw()
	if batter != null:
		var season := SeasonLine.for_player(batter)
		var today := GameLines.batter(state, batter.id)
		_batter_card["badge"].set_letter(str(batter.number), batting)
		var nick := (" \"%s\"" % batter.nickname) if batter.nickname != "" else ""
		_batter_card["head"].text = "AT BAT  %d   %s%s" % [batter.number, batter.display_name, nick]
		_batter_card["hand"].text = String(batter.bats)
		_batter_card["line"].text = "%s AVG    %d HR    %d RBI    %d-%d" % [SeasonLine.avg_text(season["avg"]), season["hr"], season["rbi"], today["h"], today["ab"]]


# --- Pitching -------------------------------------------------------------------

func show_pitching(visible_now: bool, families: Array[PitchFamilyDef] = [], selected: int = 0, slide_step: bool = false) -> void:
	_pitching = visible_now
	_families = families
	_selected = selected
	_slide_step = slide_step
	for node: CanvasItem in [_pitch_info["box"], _controls, _options, _meter]:
		node.visible = visible_now
	_pitch_list.visible = visible_now or _batting
	# The panels carry the pitching and batting controls; the prompt line
	# stays for the rest.
	_prompt.visible = not visible_now and not _batting
	if visible_now:
		_refresh_pitches()


func _refresh_pitches() -> void:
	var pitcher: PlayerDef = null
	var thrown := 0
	if _roster != null and _state != null:
		pitcher = _roster.player(_state.pitcher(_state.fielding_team()))
		thrown = _state.pitches_thrown(pitcher.id) if pitcher != null else 0
	var mods := Ratings.pitcher_mods(pitcher, thrown, tuning) if pitcher != null and tuning != null else {"speed": 1.0, "scatter": 1.0, "break": 1.0}
	# Pitching: the list is yours down the left. Batting: it is the pitcher's,
	# down the right, as scouting.
	if _batting:
		# Opposite the batter: a lefty stands on the right of the frame.
		_pitch_list.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_pitch_list.position = Vector2(LEFT + 12, 400) if _lefty else Vector2(size.x - 24 - 310, 400)
	else:
		_pitch_list.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_pitch_list.position = Vector2(LEFT + 12, 370)
	for i in _pitch_rows.size():
		var row: Dictionary = _pitch_rows[i]
		var panel: PanelContainer = row["row"]
		panel.visible = i < _families.size()
		if not panel.visible:
			continue
		var f := _families[i]
		var on := i == _selected
		panel.add_theme_stylebox_override("panel", panel_style(SELECT if on else Color(0.04, 0.05, 0.08, 0.72), 6, SELECT_EDGE if on else PANEL_EDGE))
		panel.custom_minimum_size.x = 320.0 if on else 300.0
		(row["key"] as RichTextLabel).text = PromptIcons.icons(StringName("pitch_slot_%d" % (i + 1)), false, 44) if not gamepad and not _batting else ""
		(row["name"] as Label).text = f.display_name
		(row["speed"] as Label).text = "%d MPH" % roundi(f.speed * float(mods["speed"]) * MPH)
		(row["ball"] as BallIcon).tint = f.tell_color
		(row["ball"] as BallIcon).queue_redraw()
	if _selected >= 0 and _selected < _families.size():
		var f := _families[_selected]
		_pitch_info["title"].text = f.display_name.to_upper()
		_pitch_info["velo"].text = "%d MPH" % roundi(f.speed * float(mods["speed"]) * MPH)
		var brk := f.break_amount * float(mods["break"])
		_pitch_info["h"].text = "H  %d\"" % roundi(absf(brk.x) * INCHES)
		_pitch_info["v"].text = "V  %d\"" % roundi(absf(brk.y) * INCHES)
		(_pitch_info["grid"] as BreakGrid).set_break(brk)
		var control := clampf(1.0 / maxf(f.scatter_scale * float(mods["scatter"]), 0.01) * 0.6, 0.05, 1.0)
		(_pitch_info["bar"] as Bar).value = control
		_pitch_info["bar"].queue_redraw()
		(_pitch_info["ball"] as BallIcon).tint = f.tell_color
		_pitch_info["ball"].queue_redraw()
	if _batting:
		return
	var pad := gamepad
	_controls_text.text = "[b]PITCH[/b]\n%s  AIM\n%s  THROW\n%s  PITCH" % [
		PromptIcons.icons(&"move", pad, 28), PromptIcons.icons(&"pitch_primary", pad, 28),
		PromptIcons.icons(&"pitch_prev", pad, 28) + PromptIcons.icons(&"pitch_next", pad, 28)]
	_options.text = "%s  PITCHING CHANGE\n%s  PICKOFF\n%s  SLIDE STEP: %s" % [
		PromptIcons.icons(&"open_subs", pad, 28), PromptIcons.icons(&"pickoff", pad, 28),
		PromptIcons.icons(&"slide_step", pad, 28), "ON" if _slide_step else "OFF"]


func set_meter(value: float, sweet_spot: float) -> void:
	_meter.value = value
	_meter.sweet_spot = sweet_spot
	_meter.queue_redraw()


# --- Cards, menus, callouts -----------------------------------------------------

## A title card (pregame matchup, final score): lines of [text, color,
## font size], centered. An empty list hides it.
func show_card(lines: Array) -> void:
	for child in _card.get_children():
		child.queue_free()
	_card.visible = not lines.is_empty()
	for line in lines:
		var label := _label(_card, line[2])
		label.text = line[0]
		if line[2] >= 26:
			label.add_theme_font_override("font", DISPLAY_FONT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", line[1])
	if _card.visible:
		_callout_timer = 0.0
		_callout.modulate.a = 0.0
		_detail.modulate.a = 0.0


## Seconds left on the pitch clock; shown in the last few seconds (<0 hides).
func set_clock(seconds: float) -> void:
	_clock.visible = seconds >= 0.0 and seconds <= 5.0
	_clock.text = "⏱ %d" % ceili(seconds)
	_clock.add_theme_color_override("font_color", Color(1.0, 0.35, 0.3) if seconds <= 3.0 else Color.WHITE)


## A simple list menu (substitutions). An empty title hides it.
func show_menu(title: String, lines: Array, selected: int) -> void:
	_menu_title = title
	_menu.visible = title != ""
	update_menu(lines, selected)


func update_menu(lines: Array, selected: int) -> void:
	if not _menu.visible:
		return
	var text := PackedStringArray([_menu_title, ""])
	for i in lines.size():
		text.append(("▶ %s" if i == selected else "   %s") % lines[i])
	text.append("")
	text.append("Up/Down: choose    %s: confirm    %s: cancel" % ["A" if gamepad else "J", "Y" if gamepad else "P"])
	_menu.text = "\n".join(text)


func show_callout(text: String, detail: String = "", seconds: float = 1.4) -> void:
	_callout.text = text
	_detail.text = detail
	_callout_timer = seconds
	_callout.modulate.a = 1.0
	_detail.modulate.a = 1.0


## text may hold {action} tokens; they become key or button icons.
func show_prompt(text: String) -> void:
	_prompt_text = text
	_prompt.text = "[center]%s[/center]" % PromptIcons.render(text, gamepad)


## The player switched between keyboard/mouse and a gamepad.
func set_gamepad(value: bool) -> void:
	if value == gamepad:
		return
	gamepad = value
	show_prompt(_prompt_text)
	if _pitching or _batting:
		_refresh_pitches()
	if _batting:
		_refresh_batting()


func _process(delta: float) -> void:
	if _callout_timer > 0.0:
		_callout_timer -= delta
		var a := clampf(_callout_timer / 0.4, 0.0, 1.0)
		_callout.modulate.a = a
		_detail.modulate.a = a


func _wide_label(font_size: int, preset: Control.LayoutPreset, y: float) -> Label:
	var label := _label(self, font_size)
	label.set_anchors_and_offsets_preset(preset)
	label.offset_top += y
	label.offset_bottom += y
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _label(parent: Node, font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


# --- Small drawn pieces -----------------------------------------------------------

## A club's round badge: its colors and initial (or a letter / number).
class Badge extends Control:
	var fill := Color(0.3, 0.3, 0.35)
	var ring := Color.WHITE
	var letter := ""

	func set_team(team: TeamDef) -> void:
		set_letter(team.abbreviation.substr(0, 1), team)

	func set_letter(text: String, team: TeamDef) -> void:
		letter = text
		fill = team.primary_color
		ring = team.secondary_color.lerp(Color.WHITE, 0.3)
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 1.0
		draw_circle(c, r, ring)
		draw_circle(c, r - 3.0, fill)
		var font := MatchHud.DISPLAY_FONT
		var fs := int(r * (1.0 if letter.length() <= 1 else 0.8))
		var w := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string_outline(font, c + Vector2(-w * 0.5, fs * 0.36), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.6))
		draw_string(font, c + Vector2(-w * 0.5, fs * 0.36), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


## A row of count lamps.
class Dots extends Control:
	var count := 3
	var lit := 0
	var color := Color.WHITE

	func _init(n: int = 3, c: Color = Color.WHITE) -> void:
		count = n
		color = c
		size = Vector2(n * 18, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_lit(n: int) -> void:
		lit = n
		queue_redraw()

	func _draw() -> void:
		for i in count:
			var p := Vector2(7 + i * 18, 7)
			if i < lit:
				draw_circle(p, 6.5, color)
			else:
				draw_arc(p, 6.0, 0.0, TAU, 20, Color(1, 1, 1, 0.55), 1.6)


## A thin bar (stamina, control).
class Bar extends Control:
	var value := 1.0
	var fill := Color(0.35, 0.85, 0.35)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.0, 1.0), size.y)), fill)


## A baseball: white with red seams, ringed in the pitch's tell color.
class BallIcon extends Control:
	var tint := Color.WHITE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 2.0
		draw_circle(c, r + 2.0, tint.lerp(Color.WHITE, 0.3))
		draw_circle(c, r, Color(0.97, 0.96, 0.92))
		# Two seams curving in from either side.
		for side: float in [-1.0, 1.0]:
			draw_arc(c + Vector2(side * r * 1.25, 0), r * 0.85, PI - 0.75 if side > 0.0 else -0.75, PI + 0.75 if side > 0.0 else 0.75, 12, Color(0.85, 0.15, 0.15), 1.8)


## Where a pitch breaks to, on a 3x3 chart (seen from the mound).
class BreakGrid extends Control:
	var cell := Vector2i(1, 1)

	func set_break(brk: Vector2) -> void:
		cell = Vector2i(1 + (int(signf(brk.x)) if absf(brk.x) > 0.04 else 0), 1 - (int(signf(brk.y)) if absf(brk.y) > 0.04 else 0))
		queue_redraw()

	func _draw() -> void:
		var w := size.x / 3.0
		var h := size.y / 3.0
		for x in 3:
			for y in 3:
				var on := Vector2i(x, y) == cell
				draw_rect(Rect2(Vector2(x * w + 1, y * h + 1), Vector2(w - 2, h - 2)), Color(0.2, 0.45, 0.95) if on else Color(1, 1, 1, 0.12))
		var c := Vector2((cell.x + 0.5) * w, (cell.y + 0.5) * h)
		draw_circle(c, 2.5, Color.WHITE)


## The little field top right: the diamond with the runners on it, the lead
## runner's speed, and the steal hint when the user is batting.
class MiniField extends Control:
	var bases: Array[StringName] = [&"", &"", &""]
	var lead_speed := -1
	var batting := false

	func set_state(state: MatchState, roster: MatchRoster, _tuning: BaseballTuning, user_team: int) -> void:
		bases = state.bases.duplicate()
		lead_speed = -1
		for b in [2, 1, 0]:
			if bases[b] != &"" and roster != null:
				var p := roster.player(bases[b])
				if p != null:
					lead_speed = p.speed
				break
		batting = state.batting_team() == user_team
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.52)
		var r := minf(size.x, size.y) * 0.42
		var home := c + Vector2(0, r)
		var first := c + Vector2(r, 0)
		var second := c + Vector2(0, -r)
		var third := c + Vector2(-r, 0)
		draw_colored_polygon(PackedVector2Array([home, first, second, third]), Color(0.16, 0.42, 0.2, 0.92))
		draw_colored_polygon(PackedVector2Array([home, home.lerp(first, 0.62) + Vector2(0, -r * 0.08), c, home.lerp(third, 0.62) + Vector2(0, -r * 0.08)]), Color(0.66, 0.42, 0.26, 0.9))
		draw_polyline(PackedVector2Array([home, first, second, third, home]), Color(1, 1, 1, 0.9), 2.0)
		var spots := [first, second, third]
		for i in 3:
			var p: Vector2 = spots[i]
			var sq := PackedVector2Array([p + Vector2(0, -9), p + Vector2(9, 0), p + Vector2(0, 9), p + Vector2(-9, 0)])
			draw_colored_polygon(sq, Color(1.0, 0.82, 0.2) if bases[i] != &"" else Color.WHITE)
			if bases[i] != &"":
				draw_circle(p + Vector2(0, -16), 6.0, Color(1.0, 0.82, 0.2))
		draw_colored_polygon(PackedVector2Array([home + Vector2(-7, -4), home + Vector2(7, -4), home + Vector2(7, 3), home, home + Vector2(-7, 3)]), Color.WHITE)
		var font := MatchHud.DISPLAY_FONT
		if lead_speed >= 0:
			var at := second + Vector2(0, -26)
			draw_circle(at, 15.0, Color(0.1, 0.1, 0.12))
			draw_arc(at, 15.0, 0.0, TAU, 24, Color(1.0, 0.82, 0.2), 2.0)
			var t := str(lead_speed)
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
			draw_string(font, at + Vector2(-w * 0.5, 5), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
			draw_string(font, at + Vector2(-13, -18), "SPD", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1.0, 0.82, 0.2))
