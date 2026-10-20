class_name DebugOverlay
extends Control
## Developer overlay: RNG seed, match state, last pitch/contact/flight/
## fielding/runner values, recent domain events and frame time.

const MAX_EVENTS := 10

var _text: Label
var _sections := {}
var _events: PackedStringArray = PackedStringArray()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-436, 16)
	panel.custom_minimum_size = Vector2(420, 0)
	panel.self_modulate = Color(1, 1, 1, 0.85)
	add_child(panel)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 12)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_text)


func set_section(section: String, values: Variant) -> void:
	_sections[section] = values


func clear_section(section: String) -> void:
	_sections.erase(section)


func push_event(event: DomainEvent) -> void:
	_events.append(str(event))
	if _events.size() > MAX_EVENTS:
		_events.remove_at(0)


func _process(_delta: float) -> void:
	if not visible:
		return
	var lines := PackedStringArray()
	lines.append("DEBUG [F1]   fps %d   frame %.1f ms" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0])
	for key in _sections:
		lines.append("— %s —" % key)
		var value: Variant = _sections[key]
		if value is Dictionary:
			for k in value:
				lines.append("  %s: %s" % [k, value[k]])
		else:
			lines.append("  %s" % str(value))
	lines.append("— events —")
	for e in _events:
		lines.append("  " + e)
	_text.text = "\n".join(lines)
