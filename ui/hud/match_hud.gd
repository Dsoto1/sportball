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
##   pregame: the matchup card (away vs home, the venue, the rules);
##   game over: the final card (winner, R H E).
## It only reads state handed to it. The look is the owner's UI/UX
## reference (MenuStyle): slanted navy panels with a blue rim, gold for
## whatever is selected or featured, gold header bands with navy titles,
## Bebas Neue for names, numbers and callouts, Montserrat for text (both
## SIL OFL). Prompts show the player's own key or button icons (Kenney
## Input Prompts, CC0).

const DISPLAY_FONT := MenuStyle.HEAD_FONT
const PANEL := Color(0.043, 0.122, 0.239, 0.9)
const PANEL_SOFT := Color(0.043, 0.122, 0.239, 0.78)
const RIM := Color(0.31, 0.5, 0.85, 0.7)
const GOLD := MenuStyle.GOLD
const NAVY := MenuStyle.NAVY
const DIM := Color(0.9, 0.93, 0.95, 0.68)
## Every panel leans this many px across its height.
const SLANT_PX := 12.0
const LEFT := 24.0
const CARD_W := 440.0
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
var _card_box: PanelContainer
var _matchup: MatchupCard
var _final: FinalCard
var _menu_box: PanelContainer
var _callout: Label
var _detail: Label
## The callout's panel, off to the right under the little field, out of
## the view of the pitch and the play.
var _callout_box: PanelContainer
var _prompt: RichTextLabel
var _prompt_text := ""
var _callout_timer := 0.0
var _meter: PitchMeter

# Scorebug and cards.
var _bug: ScoreBug
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
var _options_box: PanelContainer
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
var _bat_box: PanelContainer
var _steal_hint: RichTextLabel


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var look := Theme.new()
	look.default_font = MenuStyle.body(600)
	theme = look
	_bug = ScoreBug.new()
	_bug.position = Vector2(LEFT, 18)
	_bug.size = Vector2(CARD_W, 84)
	_bug.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bug)
	_pitcher_card = _build_card(Vector2(LEFT, 110), "P")
	_batter_card = _build_card(Vector2(LEFT, 182), "AT BAT")
	_field = MiniField.new()
	_field.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_field.position = Vector2(-240, 18)
	_field.size = Vector2(216, 176)
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_field)
	_build_pitch_list()
	_build_pitch_info()
	_build_controls()
	_build_batting()

	_callout_box = PanelContainer.new()
	_callout_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin(_callout_box, GOLD)
	add_child(_callout_box)
	_callout_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_callout_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_callout_box.offset_right = -24.0
	_callout_box.offset_top = 250.0
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", -2)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_callout_box.add_child(stack)
	_callout = _label(stack, 46)
	_callout.add_theme_constant_override("outline_size", 0)
	_callout.add_theme_color_override("font_color", GOLD)
	_detail = _label(stack, 15)
	_detail.add_theme_constant_override("outline_size", 0)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size.x = 360.0
	_callout_box.modulate.a = 0.0
	_prompt = RichTextLabel.new()
	_prompt.bbcode_enabled = true
	_prompt.fit_content = true
	_prompt.scroll_active = false
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_theme_font_size_override("normal_font_size", 20)
	_prompt.add_theme_color_override("font_outline_color", MenuStyle.DEEP)
	_prompt.add_theme_constant_override("outline_size", 7)
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
	_menu_box = _centered_box(GOLD)
	_menu = _label(_menu_box, 21)
	_menu.add_theme_constant_override("outline_size", 0)
	_menu_box.visible = false
	_clock = _label(self, 46)
	_clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_clock.position += Vector2(-330, 24)
	_clock.visible = false
	_card_box = _centered_box(GOLD)
	_card = VBoxContainer.new()
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_box.add_child(_card)
	_card_box.visible = false
	_matchup = MatchupCard.new()
	_matchup.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_matchup.size = MatchupCard.SIZE
	_matchup.position = Vector2(-MatchupCard.SIZE.x * 0.5, 120)
	_matchup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_matchup.visible = false
	add_child(_matchup)
	_final = FinalCard.new()
	_final.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_final.size = FinalCard.SIZE
	_final.position = Vector2(-FinalCard.SIZE.x * 0.5, 170)
	_final.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_final.visible = false
	add_child(_final)
	for big in [_callout, _clock]:
		big.add_theme_font_override("font", DISPLAY_FONT)
	show_pitching(false)


# --- Building -----------------------------------------------------------------

## Gives a Panel or PanelContainer the HUD's panel look: a slanted navy
## panel with a rim (gold when featured or selected) and, with `band` > 0,
## a gold header band that tall across its top for a navy title. The look
## is drawn under the children; `restyle` changes it later.
static func skin(box: Control, rim: Color = RIM, fill: Color = PANEL, band: float = 0.0) -> void:
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 12.0 + SLANT_PX
	empty.content_margin_right = 12.0 + SLANT_PX
	empty.content_margin_top = 8.0 + band
	empty.content_margin_bottom = 8.0
	box.add_theme_stylebox_override("panel", empty)
	box.set_meta(&"hud_rim", rim)
	box.set_meta(&"hud_fill", fill)
	box.set_meta(&"hud_band", band)
	box.draw.connect(_draw_skin.bind(box))


static func restyle(box: Control, rim: Color, fill: Color) -> void:
	box.set_meta(&"hud_rim", rim)
	box.set_meta(&"hud_fill", fill)
	box.queue_redraw()


static func _draw_skin(box: Control) -> void:
	var r := Rect2(Vector2.ZERO, box.size)
	if r.size.y < 4.0:
		return
	var rim: Color = box.get_meta(&"hud_rim")
	var band: float = box.get_meta(&"hud_band")
	draw_hud_panel(box, r, box.get_meta(&"hud_fill"), rim, band)


## The panel itself (also used by the drawn cards): slanted SLANT_PX across
## `r`, a fill, an optional gold header band and the rim.
static func draw_hud_panel(ci: CanvasItem, r: Rect2, fill: Color, rim: Color, band: float = 0.0, weave: bool = false, slant_px: float = SLANT_PX) -> void:
	var slant := slant_px / r.size.y
	MenuStyle.draw_panel(ci, r, fill, rim, 2.0, slant, weave)
	if band > 0.0:
		var pts := MenuStyle.slanted(r, slant)
		var t := band / r.size.y
		var strip := PackedVector2Array([pts[0], pts[1], pts[1].lerp(pts[2], t), pts[0].lerp(pts[3], t)])
		var hi := GOLD.lightened(0.12)
		var lo := GOLD.darkened(0.12)
		ci.draw_polygon(strip, PackedColorArray([hi, hi, lo, lo]))
		var loop := pts.duplicate()
		loop.append(pts[0])
		ci.draw_polyline(loop, rim, 2.0, true)


func _panel(at: Vector2, size_px: Vector2, rim: Color = RIM, band: float = 0.0) -> Panel:
	var p := Panel.new()
	p.position = at
	p.size = size_px
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin(p, rim, PANEL, band)
	add_child(p)
	return p


## A skinned box that grows from the screen's center (menus, title cards).
func _centered_box(rim: Color) -> PanelContainer:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin(box, rim)
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	return box


## A skinned box holding a RichTextLabel (controls, options).
func _text_box(font_size: int) -> Array:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin(box, RIM, PANEL_SOFT)
	add_child(box)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("normal_font_size", font_size)
	box.add_child(text)
	return [box, text]


## A gold title for a box's RichTextLabel, in Bebas Neue.
static func heading(text: String) -> String:
	return "[font=%s][font_size=27][color=#%s]%s[/color][/font_size][/font]" % [DISPLAY_FONT.resource_path, GOLD.to_html(false), text]


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


## A player card: a round badge, a name line, a stat line and (the
## pitcher's) a thin stamina bar along the bottom.
func _build_card(at: Vector2, tag: String) -> Dictionary:
	var card := _panel(at, Vector2(CARD_W, 64))
	var badge := Badge.new()
	badge.position = Vector2(12, 10)
	badge.size = Vector2(44, 44)
	card.add_child(badge)
	var head := _text(card, Vector2(66, 2), 27, Color.WHITE, true)
	head.size = Vector2(CARD_W - 150, 32)
	head.clip_text = true
	head.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var hand := _text(card, Vector2(CARD_W - 84, 4), 24, GOLD, true)
	hand.size = Vector2(60, 28)
	hand.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var line := _text(card, Vector2(66, 33), 14, DIM)
	var bar := Bar.new()
	bar.position = Vector2(64, 55)
	bar.size = Vector2(CARD_W - 100, 4)
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
		skin(row, RIM, PANEL_SOFT)
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
		var name_label := _label(words, 28)
		name_label.add_theme_font_override("font", DISPLAY_FONT)
		name_label.add_theme_constant_override("outline_size", 0)
		var speed := _label(words, 14)
		speed.add_theme_constant_override("outline_size", 0)
		speed.add_theme_color_override("font_color", DIM)
		_pitch_rows.append({"row": row, "key": key, "name": name_label, "speed": speed, "ball": ball})
	var pair := _text_box(18)
	_options_box = pair[0]
	_options = pair[1]
	_options_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_options_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_options_box.offset_left = LEFT
	_options_box.offset_bottom = -20.0


## The picked pitch's card: velocity, a 3x3 break chart, movement in
## inches and how well he commands it.
func _build_pitch_info() -> void:
	var box := Panel.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skin(box, RIM, PANEL, 36.0)
	box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	box.position = Vector2(-290, 404)
	box.size = Vector2(266, 250)
	add_child(box)
	var title := _text(box, Vector2(24, 2), 30, NAVY, true)
	var ball := BallIcon.new()
	ball.position = Vector2(34, 52)
	ball.size = Vector2(46, 46)
	box.add_child(ball)
	_text(box, Vector2(150, 46), 12, DIM).text = "VELOCITY"
	var velo := _text(box, Vector2(150, 60), 30, Color.WHITE, true)
	var grid := BreakGrid.new()
	grid.position = Vector2(20, 114)
	grid.size = Vector2(106, 112)
	box.add_child(grid)
	_text(box, Vector2(150, 106), 12, DIM).text = "MOVEMENT"
	var h_line := _text(box, Vector2(150, 120), 26, Color.WHITE, true)
	var v_line := _text(box, Vector2(150, 148), 26, Color.WHITE, true)
	_text(box, Vector2(150, 186), 12, DIM).text = "CONTROL"
	var bar := Bar.new()
	bar.position = Vector2(150, 206)
	bar.size = Vector2(92, 10)
	bar.fill = MenuStyle.HIGHLIGHT
	box.add_child(bar)
	_pitch_info = {"box": box, "title": title, "velo": velo, "grid": grid, "h": h_line, "v": v_line, "bar": bar, "ball": ball}


func _build_controls() -> void:
	var pair := _text_box(16)
	_controls = pair[0]
	_controls_text = pair[1]
	_controls.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_controls.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_controls.offset_right = -24.0
	_controls.offset_top = 670.0


## The batting set: the hitter's banner top center (season line, tonight's
## hits, bases), his card on the left (ratings bars, his nickname as his
## calling card), the pitcher's repertoire on the right as scouting (the
## pitch list), the swing controls bottom right and options bottom left.
func _build_batting() -> void:
	var banner := Panel.new()
	skin(banner, GOLD)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(-230, 118)
	banner.size = Vector2(460, 118)
	add_child(banner)
	var badge := Badge.new()
	badge.position = Vector2(16, 14)
	badge.size = Vector2(90, 90)
	banner.add_child(badge)
	var title := _text(banner, Vector2(116, 4), 32, Color.WHITE, true)
	title.size = Vector2(246, 36)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var pos := _text(banner, Vector2(116, 40), 14, GOLD)
	var stats := []
	for i in 3:
		_text(banner, Vector2(116 + i * 64, 62), 11, DIM).text = ["AVG", "HR", "RBI"][i]
		stats.append(_text(banner, Vector2(116 + i * 64, 74), 30, Color.WHITE, true))
	var rule := ColorRect.new()
	rule.color = Color(GOLD, 0.45)
	rule.position = Vector2(366, 10)
	rule.size = Vector2(1, 98)
	banner.add_child(rule)
	_text(banner, Vector2(378, 8), 11, GOLD).text = "TONIGHT"
	var tonight := _text(banner, Vector2(380, 22), 32, Color.WHITE, true)
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
	cbadge.position = Vector2(16, 10)
	var cname := _text(card, Vector2(96, 4), 30, Color.WHITE, true)
	cname.size = Vector2(160, 34)
	cname.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cname.clip_text = true
	var chand := _text(card, Vector2(264, 6), 28, GOLD, true)
	var cpos := _text(card, Vector2(96, 38), 13, GOLD)
	var cline := _text(card, Vector2(96, 56), 15)
	var calling := _text(card, Vector2(22, 90), 16, GOLD)
	var bars := []
	for i in 3:
		_text(card, Vector2(20, 122 + i * 32), 14).text = ["CONTACT", "POWER", "VISION"][i]
		var bar := Bar.new()
		bar.position = Vector2(118, 129 + i * 32)
		bar.size = Vector2(136, 10)
		bar.fill = [MenuStyle.SUCCESS, MenuStyle.WARNING, MenuStyle.HIGHLIGHT][i]
		card.add_child(bar)
		var num := _text(card, Vector2(266, 116 + i * 32), 26, Color.WHITE, true)
		bars.append([bar, num])
	_hitter = {"box": card, "badge": cbadge, "name": cname, "hand": chand, "pos": cpos, "line": cline, "calling": calling, "bars": bars}

	var pair := _text_box(16)
	_swing_box = pair[0]
	_swing_text = pair[1]
	pair = _text_box(17)
	_bat_box = pair[0]
	_bat_options = pair[1]
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
	for node: CanvasItem in [_banner["box"], _hitter["box"], _swing_box, _bat_box, _steal_hint]:
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
	_swing_box.reset_size()
	_bat_box.reset_size()
	_swing_box.position = Vector2(LEFT, size.y - 20 - _swing_box.size.y) if _lefty else Vector2(size.x - 24 - _swing_box.size.x, size.y - 20 - _swing_box.size.y)
	_bat_box.position = Vector2(LEFT, 262) if _lefty else Vector2(LEFT, size.y - 20 - _bat_box.size.y)
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
	_swing_text.text = heading("SWING") + "\n%s  CONTACT\n%s  POWER\n%s  BUNT\n%s  AIM · LIFT · CHOP" % [
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
	_bug.teams = [roster.teams[0], roster.teams[1]]
	_bug.queue_redraw()


## The brighter of a team's two main colors, so it reads on a dark panel.
static func text_color(team: TeamDef) -> Color:
	var a := team.primary_color
	var b := team.secondary_color
	return a if a.get_luminance() >= b.get_luminance() else b


func show_state(state: MatchState, user_team: int) -> void:
	_state = state
	_bug.show_state(state, user_team)
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
		_pitcher_card["head"].text = "#%d  %s" % [pitcher.number, pitcher.display_name.to_upper()]
		_pitcher_card["hand"].text = "%sHP" % pitcher.throws
		_pitcher_card["line"].text = "PITCHING  ·  %s IP   %d H   %d R   %d BB   %d K" % [line["ip"], line["h"], line["r"], line["bb"], line["k"]]
		var bar: Bar = _pitcher_card["bar"]
		bar.visible = tuning != null
		if tuning != null:
			bar.value = 1.0 - Ratings.fatigue(pitcher, state.pitches_thrown(pitcher.id), tuning)
			bar.fill = MenuStyle.SUCCESS if bar.value > 0.5 else (MenuStyle.WARNING if bar.value > 0.25 else MenuStyle.DANGER)
			bar.queue_redraw()
	if batter != null:
		var season := SeasonLine.for_player(batter)
		var today := GameLines.batter(state, batter.id)
		_batter_card["badge"].set_letter(str(batter.number), batting)
		var nick := (" \"%s\"" % batter.nickname) if batter.nickname != "" else ""
		_batter_card["head"].text = "#%d  %s%s" % [batter.number, batter.display_name.to_upper(), nick.to_upper()]
		_batter_card["hand"].text = String(batter.bats)
		_batter_card["line"].text = "AT BAT  ·  %s AVG   %d HR   %d RBI   %d-%d TODAY" % [SeasonLine.avg_text(season["avg"]), season["hr"], season["rbi"], today["h"], today["ab"]]


# --- Pitching -------------------------------------------------------------------

func show_pitching(visible_now: bool, families: Array[PitchFamilyDef] = [], selected: int = 0, slide_step: bool = false) -> void:
	_pitching = visible_now
	_families = families
	_selected = selected
	_slide_step = slide_step
	for node: CanvasItem in [_pitch_info["box"], _controls, _options_box, _meter]:
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
		# Gold is the selected one (the reference's primary button).
		restyle(panel, GOLD.lightened(0.3) if on else RIM, GOLD if on else PANEL_SOFT)
		panel.custom_minimum_size.x = 320.0 if on else 300.0
		(row["name"] as Label).add_theme_color_override("font_color", NAVY if on else Color.WHITE)
		(row["speed"] as Label).add_theme_color_override("font_color", Color(NAVY, 0.8) if on else DIM)
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
	_controls_text.text = heading("PITCH") + "\n%s  AIM\n%s  THROW\n%s  PITCH" % [
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
## An empty list hides every title card (this one, the matchup and the
## final).
func show_card(lines: Array) -> void:
	for child in _card.get_children():
		child.queue_free()
	_card_box.visible = not lines.is_empty()
	if lines.is_empty():
		_matchup.visible = false
		_final.visible = false
	_title_up(not lines.is_empty())
	for line in lines:
		var label := _label(_card, line[2])
		label.text = line[0]
		label.add_theme_constant_override("outline_size", 0)
		if line[2] >= 26:
			label.add_theme_font_override("font", DISPLAY_FONT)
			label.add_theme_font_size_override("font_size", int(line[2] * 1.25))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", line[1])
	if _card_box.visible:
		_card_box.reset_size()
		_hide_callout()


## The pregame matchup card: `info` holds away, home (TeamDef), venue,
## venue_color, blurb, dims, rules, fine_print and row (the selected line:
## 0 away, 1 home, 2 venue). An empty dictionary hides it.
func show_matchup(info: Dictionary) -> void:
	_matchup.visible = not info.is_empty()
	if _matchup.visible:
		_card_box.visible = false
		_final.visible = false
		_matchup.info = info
		_matchup.queue_redraw()
		_hide_callout()
	_title_up(_matchup.visible)


## The final card: `title` (FINAL, FINAL · MERCY RULE), the two clubs
## (away, home), each one's [R, H, E], and the winner's index (-1 for none).
func show_final(title: String, teams: Array, rhe: Array, winner: int) -> void:
	_final.visible = true
	_card_box.visible = false
	_matchup.visible = false
	_final.title = title
	_final.teams = teams
	_final.rhe = rhe
	_final.winner = winner
	_final.queue_redraw()
	_hide_callout()
	_title_up(true)


## The player cards step aside while a title card is up.
func _title_up(up: bool) -> void:
	_pitcher_card["panel"].visible = not up
	_batter_card["panel"].visible = not up and not _batting


func _hide_callout() -> void:
	_callout_timer = 0.0
	_callout_box.modulate.a = 0.0


## Seconds left on the pitch clock; shown in the last few seconds (<0 hides).
func set_clock(seconds: float) -> void:
	_clock.visible = seconds >= 0.0 and seconds <= 5.0
	_clock.text = "CLOCK  %d" % ceili(seconds)
	_clock.add_theme_color_override("font_color", MenuStyle.DANGER if seconds <= 3.0 else Color.WHITE)


## A simple list menu (substitutions). An empty title hides it.
func show_menu(title: String, lines: Array, selected: int) -> void:
	_menu_title = title
	_menu.visible = title != ""
	_menu_box.visible = _menu.visible
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
	_menu_box.reset_size()


func show_callout(text: String, detail: String = "", seconds: float = 1.4) -> void:
	_callout.text = text
	_detail.text = detail
	_detail.visible = detail != ""
	_callout_box.reset_size()
	_callout_timer = seconds
	_callout_box.modulate.a = 1.0


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
		_callout_box.modulate.a = clampf(_callout_timer / 0.4, 0.0, 1.0)


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
	label.add_theme_color_override("font_outline_color", MenuStyle.DEEP)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


# --- Small drawn pieces -----------------------------------------------------------

## A club's badge: its colors and initial (or a letter / number), round,
## or a shield (`shield`) on the title cards.
class Badge extends Control:
	var fill := Color(0.3, 0.3, 0.35)
	var ring := Color.WHITE
	var letter := ""
	var shield := false

	func set_team(team: TeamDef) -> void:
		set_letter(team.abbreviation.substr(0, 1), team)

	func set_letter(text: String, team: TeamDef) -> void:
		letter = text
		fill = team.primary_color
		ring = team.secondary_color.lerp(Color.WHITE, 0.3)
		queue_redraw()

	func _draw() -> void:
		MatchHud.draw_badge(self, Rect2(Vector2.ZERO, size), letter, fill, ring, shield)


## Draws a badge in `r` (see Badge).
static func draw_badge(ci: CanvasItem, r: Rect2, letter: String, fill: Color, ring: Color, shield: bool = false) -> void:
	var c := r.get_center()
	var rad := minf(r.size.x, r.size.y) * 0.5 - 1.0
	if shield:
		var w := rad * 0.86
		var pts := PackedVector2Array([c + Vector2(-w, -rad * 0.82), c + Vector2(0, -rad), c + Vector2(w, -rad * 0.82),
			c + Vector2(w, rad * 0.1), c + Vector2(0, rad), c + Vector2(-w, rad * 0.1)])
		ci.draw_colored_polygon(pts, ring)
		var inner := PackedVector2Array()
		for p in pts:
			inner.append(c + (p - c) * 0.86)
		ci.draw_colored_polygon(inner, fill)
	else:
		ci.draw_circle(c, rad, ring)
		ci.draw_circle(c, rad - maxf(2.5, rad * 0.1), fill)
	var font := MatchHud.DISPLAY_FONT
	var fs := int(rad * (1.3 if letter.length() <= 1 else (1.05 if letter.length() == 2 else 0.85)))
	var tw := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var base := c + Vector2(-tw * 0.5, fs * 0.36 - (rad * 0.06 if shield else 0.0))
	ci.draw_string_outline(font, base, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 4, Color(0, 0, 0, 0.55))
	ci.draw_string(font, base, letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


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
		draw_rect(Rect2(Vector2.ZERO, size), Color(MenuStyle.DEEP, 0.85))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.0, 1.0), size.y)), fill)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.0, 1.0), size.y * 0.4)), Color(1, 1, 1, 0.18))


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
				draw_rect(Rect2(Vector2(x * w + 1, y * h + 1), Vector2(w - 2, h - 2)), MatchHud.GOLD if on else Color(1, 1, 1, 0.1))
		var c := Vector2((cell.x + 0.5) * w, (cell.y + 0.5) * h)
		draw_circle(c, 2.5, Color.WHITE)


## The little field top right, seen from above with home at the bottom:
## the outfield fan, the infield dirt and grass, the foul lines, and the
## bases (gold with a runner on), the lead runner's speed in the corner.
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

	## A wedge from `home` out to `r` across fair territory.
	static func _fan(home: Vector2, r: float, steps: int = 24) -> PackedVector2Array:
		var pts := PackedVector2Array([home])
		for i in steps + 1:
			var ang := deg_to_rad(-135.0 + 90.0 * i / steps)
			pts.append(home + Vector2(cos(ang), sin(ang)) * r)
		return pts

	func _draw() -> void:
		MatchHud.draw_hud_panel(self, Rect2(Vector2.ZERO, size), MatchHud.PANEL, MatchHud.RIM)
		var home := Vector2(size.x * 0.5, size.y - 22.0)
		var a := 38.0
		var reach := size.y - 52.0
		var first := home + Vector2(a, -a)
		var second := home + Vector2(0, -2.0 * a)
		var third := home + Vector2(-a, -a)
		var mid := home + Vector2(0, -a)
		draw_colored_polygon(_fan(home, reach), Color(0.12, 0.36, 0.18))
		draw_arc(home, reach - 3.0, deg_to_rad(-135.0), deg_to_rad(-45.0), 24, Color(0.55, 0.4, 0.27), 5.0, true)
		draw_colored_polygon(_fan(home, a * 2.0 * 1.12), Color(0.66, 0.45, 0.29))
		var inset := 0.72
		draw_colored_polygon(PackedVector2Array([mid + (home - mid) * inset, mid + (first - mid) * inset, mid + (second - mid) * inset, mid + (third - mid) * inset]), Color(0.17, 0.46, 0.23))
		draw_circle(mid + Vector2(0, 2), 5.0, Color(0.66, 0.45, 0.29))
		for side: float in [-1.0, 1.0]:
			draw_line(home, home + Vector2(side, -1.0).normalized() * reach, Color(1, 1, 1, 0.85), 1.5, true)
		draw_polyline(PackedVector2Array([home, first, second, third, home]), Color(1, 1, 1, 0.45), 1.0, true)
		var spots := [first, second, third]
		for i in 3:
			var p: Vector2 = spots[i]
			var on := bases[i] != &""
			var k := 9.0 if on else 6.5
			var d := PackedVector2Array([p + Vector2(0, -k), p + Vector2(k, 0), p + Vector2(0, k), p + Vector2(-k, 0)])
			draw_colored_polygon(d, MatchHud.GOLD if on else Color.WHITE)
			if on:
				var loop := d.duplicate()
				loop.append(d[0])
				draw_polyline(loop, MatchHud.NAVY, 1.5, true)
		draw_colored_polygon(PackedVector2Array([home + Vector2(-5, -3), home + Vector2(5, -3), home + Vector2(5, 2), home + Vector2(0, 5), home + Vector2(-5, 2)]), Color.WHITE)
		if lead_speed >= 0:
			var font := MatchHud.DISPLAY_FONT
			var at := Vector2(size.x - 34.0, size.y - 30.0)
			draw_circle(at, 17.0, Color(MenuStyle.DEEP, 0.95))
			draw_arc(at, 17.0, 0.0, TAU, 28, MatchHud.GOLD, 2.0, true)
			var t := str(lead_speed)
			var w := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			draw_string(font, at + Vector2(-w * 0.5, 7), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
			draw_string(MenuStyle.body(700), at + Vector2(-11, -21), "SPD", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, MatchHud.GOLD)


## The scorebug (the reference's HUD snippet): both clubs with their color
## chip, badge, letters and runs; the bases as three gold diamonds; the
## inning with its half as an arrow, the count, and the outs.
class ScoreBug extends Control:
	var teams: Array = []
	var runs := [0, 0]
	var user_team := -1
	var batting := 0
	var inning := 1
	var top := true
	var balls := 0
	var strikes := 0
	var outs := 0
	var bases: Array[bool] = [false, false, false]

	func show_state(state: MatchState, user: int) -> void:
		runs = [state.score[0], state.score[1]]
		user_team = user
		batting = state.batting_team()
		inning = state.inning
		top = state.is_top
		balls = state.balls
		strikes = state.strikes
		outs = state.outs
		for i in 3:
			bases[i] = state.bases[i] != &""
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		MatchHud.draw_hud_panel(self, r, MatchHud.PANEL, MatchHud.RIM, 0.0, true)
		var head := MatchHud.DISPLAY_FONT
		var split_a := size.x * 0.5
		var split_b := split_a + 92.0
		# The clubs, one row each.
		for i in 2:
			var y := 6.0 + i * 37.0
			var row := Rect2(Vector2(16.0, y), Vector2(split_a - 26.0, 34.0))
			if i == batting:
				draw_colored_polygon(MenuStyle.slanted(row, 0.2), Color(1, 1, 1, 0.07))
			var team: TeamDef = teams[i] if i < teams.size() else null
			var color := team.primary_color if team != null else Color.GRAY
			draw_colored_polygon(MenuStyle.slanted(Rect2(Vector2(18.0, y + 4.0), Vector2(9.0, 26.0)), 0.25), color)
			if team != null:
				MatchHud.draw_badge(self, Rect2(Vector2(32.0, y + 3.0), Vector2(28.0, 28.0)), team.abbreviation.substr(0, 1), team.primary_color, team.secondary_color.lerp(Color.WHITE, 0.3))
			var abbr: String = team.abbreviation if team != null else ["AWAY", "HOME"][i]
			MenuStyle.draw_text(self, Vector2(68.0, y + 1.0), abbr, head, 32, Color.WHITE)
			if i == user_team:
				MenuStyle.draw_icon(self, &"person", Vector2(76.0 + MenuStyle.text_width(abbr, head, 32) + 6.0, y + 17.0), 18.0, MatchHud.GOLD)
			var score := str(runs[i])
			MenuStyle.draw_text(self, Vector2(split_a - 16.0 - MenuStyle.text_width(score, head, 34), y), score, head, 34, Color.WHITE)
		for x in [split_a, split_b]:
			draw_line(Vector2(x, 12.0), Vector2(x - 3.0, size.y - 12.0), Color(MatchHud.GOLD, 0.45), 1.5)
		# The bases.
		var c := Vector2((split_a + split_b) * 0.5, size.y * 0.5 + 3.0)
		var spots := [c + Vector2(19, 0), c + Vector2(0, -19), c + Vector2(-19, 0)]
		for i in 3:
			var p: Vector2 = spots[i]
			var d := PackedVector2Array([p + Vector2(0, -12), p + Vector2(12, 0), p + Vector2(0, 12), p + Vector2(-12, 0)])
			draw_colored_polygon(d, MatchHud.GOLD if bases[i] else Color(MenuStyle.DEEP, 0.9))
			var loop := d.duplicate()
			loop.append(d[0])
			draw_polyline(loop, MatchHud.GOLD.lightened(0.3) if bases[i] else Color(MenuStyle.NEUTRAL, 0.7), 2.0, true)
		# Inning, count, outs.
		var x0 := split_b + 14.0
		var tip := Vector2(x0 + 8.0, 20.0)
		var tri := PackedVector2Array([tip + Vector2(-7, 5), tip + Vector2(7, 5), tip + Vector2(0, -6)]) if top \
			else PackedVector2Array([tip + Vector2(-7, -4), tip + Vector2(7, -4), tip + Vector2(0, 7)])
		draw_colored_polygon(tri, MatchHud.GOLD)
		MenuStyle.draw_text(self, Vector2(x0 + 20.0, 3.0), str(inning), head, 32, Color.WHITE)
		var count := "%d-%d" % [balls, strikes]
		var right := size.x - 22.0
		MenuStyle.draw_text(self, Vector2(right - MenuStyle.text_width(count, head, 32), 3.0), count, head, 32, Color.WHITE)
		MenuStyle.draw_text(self, Vector2(x0, 52.0), "OUTS", MenuStyle.body(600), 12, MatchHud.DIM, false)
		for i in 2:
			var p := Vector2(right - 7.0 - (1 - i) * 20.0, 60.0)
			if i < outs:
				draw_circle(p, 6.5, MatchHud.GOLD)
			else:
				draw_arc(p, 6.0, 0.0, TAU, 20, Color(MenuStyle.NEUTRAL, 0.6), 1.6, true)


## The pregame matchup card: AWAY and HOME side by side with their badges,
## names and identity lines, VS between, the venue under them, the rules at
## the foot. The selected line (club or venue) is rimmed in gold with
## arrows: left and right change it.
class MatchupCard extends Control:
	const SIZE := Vector2(1040, 470)
	var info := {}

	func _draw() -> void:
		if info.is_empty():
			return
		var head := MatchHud.DISPLAY_FONT
		var body := MenuStyle.body(600)
		var light := MenuStyle.body(500)
		var r := Rect2(Vector2.ZERO, size)
		MatchHud.draw_hud_panel(self, r, MatchHud.PANEL, MatchHud.GOLD, 46.0, true, 22.0)
		MenuStyle.draw_text(self, Vector2(42, 4), "EXHIBITION", head, 36, MatchHud.NAVY, false)
		var rules: String = info.get("rules", "")
		MenuStyle.draw_text(self, Vector2(size.x - 52 - MenuStyle.text_width(rules, head, 28), 9), rules, head, 28, MatchHud.NAVY, false)
		var row: int = info.get("row", -1)
		for i in 2:
			var team: TeamDef = info["away" if i == 0 else "home"]
			var block := Rect2(Vector2(46 + i * 560, 66), Vector2(440, 236))
			var on := row == i
			MatchHud.draw_hud_panel(self, block, Color(MenuStyle.DEEP, 0.92), MatchHud.GOLD if on else MatchHud.RIM, 0.0, false, 16.0)
			MenuStyle.draw_text(self, block.position + Vector2(28, 12), ["AWAY  ·  BATS FIRST", "HOME  ·  FIELDS FIRST"][i], body, 13, MatchHud.GOLD, false)
			MatchHud.draw_badge(self, Rect2(block.position + Vector2(20, 46), Vector2(120, 132)), team.abbreviation.substr(0, 1), team.primary_color, team.secondary_color.lerp(Color.WHITE, 0.3), true)
			var tx := block.position.x + 156
			var tw := block.size.x - 156 - 22
			MenuStyle.draw_text(self, Vector2(tx, block.position.y + 52), team.city.to_upper(), body, 16, MatchHud.DIM, false)
			var name := team.team_name.to_upper()
			var fs := 64
			while fs > 34 and MenuStyle.text_width(name, head, fs) > tw:
				fs -= 2
			MenuStyle.draw_text(self, Vector2(tx, block.position.y + 72), name, head, fs, MatchHud.text_color(team))
			var identity := team.identity.get_slice(".", 0)
			draw_multiline_string(light, Vector2(tx, block.position.y + 160 + light.get_ascent(14)), identity, HORIZONTAL_ALIGNMENT_LEFT, tw, 14, 3, MatchHud.DIM)
			if on:
				_arrows(block)
		# VS between the clubs.
		var vs := Vector2(size.x * 0.5, 184)
		draw_circle(vs, 44, Color(MenuStyle.DEEP, 0.95))
		draw_arc(vs, 44, 0, TAU, 40, MatchHud.GOLD, 3.0, true)
		MenuStyle.draw_text(self, vs - Vector2(MenuStyle.text_width("VS", head, 46) * 0.5, 26), "VS", head, 46, MatchHud.GOLD, false)
		# The venue.
		var venue := Rect2(Vector2(46, 318), Vector2(size.x - 92, 92))
		MatchHud.draw_hud_panel(self, venue, Color(MenuStyle.DEEP, 0.92), MatchHud.GOLD if row == 2 else MatchHud.RIM, 0.0, false, 14.0)
		MenuStyle.draw_text(self, venue.position + Vector2(30, 10), "VENUE", body, 13, MatchHud.GOLD, false)
		MenuStyle.draw_text(self, venue.position + Vector2(30, 26), String(info.get("venue", "")).to_upper(), head, 44, info.get("venue_color", Color.WHITE))
		var vx := venue.position.x + 46 + MenuStyle.text_width(String(info.get("venue", "")).to_upper(), head, 44) + 24
		var about := "%s%s" % [info.get("blurb", ""), ("\n" + String(info["dims"])) if String(info.get("dims", "")) != "" else ""]
		draw_multiline_string(light, Vector2(vx, venue.position.y + 30 + light.get_ascent(15)), about, HORIZONTAL_ALIGNMENT_LEFT, venue.end.x - vx - 40, 15, 3, MatchHud.DIM)
		if row == 2:
			_arrows(venue)
		var fine: String = info.get("fine_print", "")
		draw_string(light, Vector2(0, size.y - 22), fine, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, MatchHud.DIM)

	## Gold arrows either side of the selected line (left/right change it).
	func _arrows(box: Rect2) -> void:
		var y := box.get_center().y
		for side: float in [-1.0, 1.0]:
			var x := box.position.x - 2.0 if side < 0.0 else box.end.x + 2.0
			draw_colored_polygon(PackedVector2Array([Vector2(x + side * 16.0, y), Vector2(x, y - 13.0), Vector2(x, y + 13.0)]), MatchHud.GOLD)


## The final card: FINAL (and why) on a gold band, who won, and the line
## score's runs, hits and errors for both clubs, the winner's row in gold.
class FinalCard extends Control:
	const SIZE := Vector2(720, 330)
	var title := "FINAL"
	var teams: Array = []
	var rhe: Array = []
	var winner := -1

	func _draw() -> void:
		if teams.size() < 2:
			return
		var head := MatchHud.DISPLAY_FONT
		var body := MenuStyle.body(600)
		MatchHud.draw_hud_panel(self, Rect2(Vector2.ZERO, size), MatchHud.PANEL, MatchHud.GOLD, 46.0, true, 20.0)
		MenuStyle.draw_text(self, Vector2(40, 4), title, head, 38, MatchHud.NAVY, false)
		var won := "%s WIN" % (teams[winner] as TeamDef).full_name().to_upper() if winner >= 0 else "TIED"
		var fs := 52
		while fs > 30 and MenuStyle.text_width(won, head, fs) > size.x - 80:
			fs -= 2
		var won_color := MatchHud.text_color(teams[winner]) if winner >= 0 else Color.WHITE
		MenuStyle.draw_text(self, Vector2((size.x - MenuStyle.text_width(won, head, fs)) * 0.5, 60), won, head, fs, won_color)
		var cols := [size.x - 250.0, size.x - 170.0, size.x - 90.0]
		for c in 3:
			var label: String = ["R", "H", "E"][c]
			MenuStyle.draw_text(self, Vector2(cols[c] - MenuStyle.text_width(label, body, 14) * 0.5, 138), label, body, 14, MatchHud.DIM, false)
		for i in 2:
			var team: TeamDef = teams[i]
			var y := 160.0 + i * 74.0
			var row := Rect2(Vector2(40, y), Vector2(size.x - 80, 64))
			MatchHud.draw_hud_panel(self, row, Color(MenuStyle.DEEP, 0.92), MatchHud.GOLD if i == winner else MatchHud.RIM, 0.0, false, 12.0)
			draw_colored_polygon(MenuStyle.slanted(Rect2(Vector2(58, y + 10), Vector2(10, 44)), 0.25), team.primary_color)
			MatchHud.draw_badge(self, Rect2(Vector2(76, y + 8), Vector2(48, 48)), team.abbreviation.substr(0, 1), team.primary_color, team.secondary_color.lerp(Color.WHITE, 0.3))
			var name := team.full_name().to_upper()
			var nfs := 40
			while nfs > 24 and MenuStyle.text_width(name, head, nfs) > cols[0] - 30.0 - 138.0:
				nfs -= 2
			MenuStyle.draw_text(self, Vector2(138, y + 32 - nfs * 0.6), name, head, nfs, Color.WHITE)
			var line: Array = rhe[i] if i < rhe.size() else [0, 0, 0]
			for c in 3:
				var n := str(line[c])
				MenuStyle.draw_text(self, Vector2(cols[c] - MenuStyle.text_width(n, head, 42) * 0.5, y + 7), n, head, 42, MatchHud.GOLD if c == 0 and i == winner else Color.WHITE)
