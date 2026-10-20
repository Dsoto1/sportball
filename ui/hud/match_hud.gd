class_name MatchHud
extends Control
## Broadcast-style match HUD in priority order: score/inning/outs, bases,
## count, matchup, then context prompt and timing feedback. It only reads
## state handed to it.

var _score: Label
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
	_score = _label(left, 30)
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
	show_pitching(false)


func show_state(state: MatchState, user_team: int) -> void:
	var half := "▲" if state.is_top else "▼"
	var away := "AWAY%s" % (" (YOU)" if user_team == MatchState.AWAY else "")
	var home := "HOME%s" % (" (YOU)" if user_team == MatchState.HOME else "")
	_score.text = "%s %d   %s %d" % [away, state.score[MatchState.AWAY], home, state.score[MatchState.HOME]]
	var outs := "●".repeat(state.outs) + "○".repeat(MatchState.OUTS_PER_HALF - state.outs)
	_count.text = "%s%d   %d-%d   OUTS %s (%d)" % [half, state.inning, state.balls, state.strikes, outs, state.outs]
	_matchup.text = "AT BAT: %s" % String(state.current_batter()).to_upper()
	_diamond.set_bases(state.bases)


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
