extends SceneTree
## Writes the semantic input actions into project.godot.
##   godot --headless --path . -s res://tools/generate_input_map.gd
## Gameplay code only ever reads these action names, never physical keys.
## Gamepad buttons use the Xbox-style layout (A bottom, B right, X left, Y top).

const DEADZONE := 0.25

# action -> list of bindings: [type, code, (axis direction)]
const BINDINGS := {
	&"aim_left": [["key", KEY_A], ["key", KEY_LEFT], ["axis", JOY_AXIS_LEFT_X, -1.0], ["button", JOY_BUTTON_DPAD_LEFT]],
	&"aim_right": [["key", KEY_D], ["key", KEY_RIGHT], ["axis", JOY_AXIS_LEFT_X, 1.0], ["button", JOY_BUTTON_DPAD_RIGHT]],
	&"aim_up": [["key", KEY_W], ["key", KEY_UP], ["axis", JOY_AXIS_LEFT_Y, -1.0], ["button", JOY_BUTTON_DPAD_UP]],
	&"aim_down": [["key", KEY_S], ["key", KEY_DOWN], ["axis", JOY_AXIS_LEFT_Y, 1.0], ["button", JOY_BUTTON_DPAD_DOWN]],
	&"swing_contact": [["key", KEY_J], ["mouse", MOUSE_BUTTON_LEFT], ["button", JOY_BUTTON_A]],
	&"swing_power": [["key", KEY_K], ["mouse", MOUSE_BUTTON_RIGHT], ["button", JOY_BUTTON_X]],
	&"swing_bunt": [["key", KEY_B], ["button", JOY_BUTTON_B]],
	&"pitch_primary": [["key", KEY_SPACE], ["key", KEY_J], ["mouse", MOUSE_BUTTON_LEFT], ["button", JOY_BUTTON_A]],
	&"pitch_next": [["key", KEY_E], ["button", JOY_BUTTON_RIGHT_SHOULDER]],
	&"pitch_prev": [["key", KEY_Q], ["button", JOY_BUTTON_LEFT_SHOULDER]],
	# Pick a pitch straight off the list (keyboard; a pad cycles with LB/RB).
	&"pitch_slot_1": [["key", KEY_1]],
	&"pitch_slot_2": [["key", KEY_2]],
	&"pitch_slot_3": [["key", KEY_3]],
	&"pitch_slot_4": [["key", KEY_4]],
	&"pitch_slot_5": [["key", KEY_5]],
	&"throw_base_1": [["key", KEY_1], ["button", JOY_BUTTON_B]],
	&"throw_base_2": [["key", KEY_2], ["button", JOY_BUTTON_Y]],
	&"throw_base_3": [["key", KEY_3], ["button", JOY_BUTTON_X]],
	&"throw_base_4": [["key", KEY_4], ["button", JOY_BUTTON_A]],
	&"throw_ball": [["key", KEY_SPACE], ["key", KEY_J], ["mouse", MOUSE_BUTTON_LEFT], ["button", JOY_BUTTON_RIGHT_SHOULDER]],
	&"slide_step": [["key", KEY_SHIFT], ["axis", JOY_AXIS_TRIGGER_RIGHT, 1.0]],
	&"pickoff": [["key", KEY_F], ["axis", JOY_AXIS_TRIGGER_LEFT, 1.0]],
	&"dive": [["key", KEY_SHIFT], ["key", KEY_L], ["axis", JOY_AXIS_TRIGGER_RIGHT, 1.0]],
	&"switch_fielder": [["key", KEY_F], ["axis", JOY_AXIS_TRIGGER_LEFT, 1.0]],
	&"runner_advance": [["key", KEY_E], ["button", JOY_BUTTON_RIGHT_SHOULDER]],
	&"runner_retreat": [["key", KEY_Q], ["button", JOY_BUTTON_LEFT_SHOULDER]],
	&"open_subs": [["key", KEY_P], ["button", JOY_BUTTON_Y]],
	&"switch_side": [["key", KEY_TAB], ["button", JOY_BUTTON_BACK]],
	# MacBooks need fn for F-keys, so each also has a plain key.
	&"toggle_debug": [["key", KEY_F1], ["key", KEY_QUOTELEFT], ["button", JOY_BUTTON_RIGHT_STICK]],
	&"restart_match": [["key", KEY_F5], ["key", KEY_R], ["button", JOY_BUTTON_START]],
	&"toggle_assist": [["key", KEY_T], ["button", JOY_BUTTON_LEFT_STICK]],
}


func _initialize() -> void:
	for action: StringName in BINDINGS:
		var events: Array[InputEvent] = []
		for binding: Array in BINDINGS[action]:
			var event := _event(binding)
			event.device = -1  # any keyboard / any gamepad
			events.append(event)
		ProjectSettings.set_setting("input/%s" % action, {"deadzone": DEADZONE, "events": events})
	var err := ProjectSettings.save()
	print("Wrote %d input actions (%s)" % [BINDINGS.size(), error_string(err)])
	quit(0 if err == OK else 1)


func _event(binding: Array) -> InputEvent:
	match binding[0]:
		"key":
			var key := InputEventKey.new()
			key.physical_keycode = binding[1]
			return key
		"mouse":
			var mouse := InputEventMouseButton.new()
			mouse.button_index = binding[1]
			return mouse
		"axis":
			var axis := InputEventJoypadMotion.new()
			axis.axis = binding[1]
			axis.axis_value = binding[2]
			return axis
		_:
			var button := InputEventJoypadButton.new()
			button.button_index = binding[1]
			return button
