class_name MatchHud
extends Control
## Broadcast-style match HUD in priority order: score/inning/outs, bases,
## count, matchup, then context prompt and timing feedback. It only reads
## state handed to it.

var _score: Label
var _away_score: Label
var _home_score: Label
var _menu: Label
var _clock: Label
var _menu_title := ""
var _card: VBoxContainer
var _roster: MatchRoster
var _diamond: BaseDiamond
var _count: Label
var _matchup: Label
var _callout: Label
var _detail: Label
var _prompt: Label
var _pitch_menu: Label
var _meter: PitchMeter
var _callout_timer := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var left := VBoxContainer.new()
	row.add_child(left)
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 22)
	left.add_child(scores)
	_away_score = _label(scores, 30)
	_home_score = _label(scores, 30)
	_score = _label(left, 14)
	_count = _label(left, 22)
	_matchup = _label(left, 16)
	_diamond = BaseDiamond.new()
	_diamond.custom_minimum_size = Vector2(110, 110)
	row.add_child(_diamond)

	_callout = _wide_label(64, Control.PRESET_TOP_WIDE, 150.0)
	_detail = _wide_label(24, Control.PRESET_TOP_WIDE, 235.0)
	_prompt = _wide_label(20, Control.PRESET_BOTTOM_WIDE, -24.0)
	_prompt.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	_pitch_menu = _label(self, 20)
	_pitch_menu.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_pitch_menu.position = Vector2(24, -170)
	_meter = PitchMeter.new()
	_meter.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_meter.position = Vector2(24, -60)
	_meter.size = Vector2(320, 24)
	add_child(_meter)
	_menu = _label(self, 22)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_menu.position += Vector2(-330, -60)
	_menu.visible = false
	_clock = _label(self, 34)
	_clock.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_clock.position += Vector2(-150, 24)
	_clock.visible = false
	_card = VBoxContainer.new()
	_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_card.position.y = 130.0
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	show_pitching(false)


func set_roster(roster: MatchRoster) -> void:
	_roster = roster
	for i in 2:
		var label := _away_score if i == 0 else _home_score
		label.add_theme_color_override("font_color", text_color(roster.teams[i]))


## The brighter of a team's two main colors, so it reads on a dark panel.
static func text_color(team: TeamDef) -> Color:
	var a := team.primary_color
	var b := team.secondary_color
	return a if a.get_luminance() >= b.get_luminance() else b


func show_state(state: MatchState, user_team: int) -> void:
	var half := "▲" if state.is_top else "▼"
	var names := ["AWAY", "HOME"]
	if _roster != null:
		names = [_roster.teams[0].abbreviation, _roster.teams[1].abbreviation]
	_away_score.text = "%s %d%s" % [names[0], state.score[MatchState.AWAY], " (YOU)" if user_team == MatchState.AWAY else ""]
	_home_score.text = "%s %d%s" % [names[1], state.score[MatchState.HOME], " (YOU)" if user_team == MatchState.HOME else ""]
	_score.text = "H %d-%d   E %d-%d" % [state.hits[0], state.hits[1], state.errors[0], state.errors[1]]
	var outs := "●".repeat(state.outs) + "○".repeat(MatchState.OUTS_PER_HALF - state.outs)
	_count.text = "%s%d   %d-%d   OUTS %s (%d)" % [half, state.inning, state.balls, state.strikes, outs, state.outs]
	_matchup.text = _matchup_text(state)
	_diamond.set_bases(state.bases)


func _matchup_text(state: MatchState) -> String:
	var batter := state.current_batter()
	if _roster == null:
		return "AT BAT: %s" % String(batter).to_upper()
	var b := _roster.player(batter)
	var p := _roster.player(state.pitcher(state.fielding_team()))
	var line := "AT BAT  #%d %s (%s)  \"%s\"" % [b.number, b.display_name, b.bats, b.nickname]
	if p != null:
		line += "\nPITCHING  #%d %s  %d pitches" % [p.number, p.display_name, state.pitches_thrown(p.id)]
	return line


## A title card (pregame matchup, final score): lines of [text, color,
## font size], centered. An empty list hides it.
func show_card(lines: Array) -> void:
	for child in _card.get_children():
		child.queue_free()
	_card.visible = not lines.is_empty()
	for line in lines:
		var label := _label(_card, line[2])
		label.text = line[0]
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
	text.append("Up/Down: choose    J / A: confirm    P / Y: cancel")
	_menu.text = "\n".join(text)


func show_callout(text: String, detail: String = "", seconds: float = 1.4) -> void:
	_callout.text = text
	_detail.text = detail
	_callout_timer = seconds
	_callout.modulate.a = 1.0
	_detail.modulate.a = 1.0


func show_prompt(text: String) -> void:
	_prompt.text = text


func show_pitching(visible_now: bool, families: Array[PitchFamilyDef] = [], selected: int = 0) -> void:
	_pitch_menu.visible = visible_now
	_meter.visible = visible_now
	if not visible_now:
		return
	var lines := PackedStringArray()
	for i in families.size():
		lines.append(("> %s <" if i == selected else "  %s") % families[i].display_name.to_upper())
	_pitch_menu.text = "\n".join(lines)


func set_meter(value: float, sweet_spot: float) -> void:
	_meter.value = value
	_meter.sweet_spot = sweet_spot
	_meter.queue_redraw()


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
