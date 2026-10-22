class_name PromptIcons
extends RefCounted
## Turns {action} tokens in prompt text into key or gamepad button icons
## (Kenney Input Prompts icon fonts, CC0) for whichever device the player
## used last. Unknown tokens are left as written.

const KB_FONT := "res://assets/third_party/kenney/input-prompts/kenney_input_keyboard_mouse.ttf"
const PAD_FONT := "res://assets/third_party/kenney/input-prompts/kenney_input_xbox_series.ttf"

## Glyph code points, from the pack's *_map.txt files.
const GLYPHS := {
	&"keyboard_1": 0xE003, &"keyboard_2": 0xE005, &"keyboard_3": 0xE007, &"keyboard_4": 0xE009, &"keyboard_5": 0xE00B,
	&"keyboard_arrows_all": 0xE026, &"keyboard_arrows_horizontal": 0xE029,
	&"keyboard_b": 0xE036, &"keyboard_e": 0xE05A, &"keyboard_f": 0xE066, &"keyboard_j": 0xE08C,
	&"keyboard_k": 0xE08E, &"keyboard_p": 0xE0A3, &"keyboard_q": 0xE0B3, &"keyboard_r": 0xE0B9,
	&"keyboard_shift": 0xE0C3, &"keyboard_space": 0xE0CB, &"keyboard_t": 0xE0CF, &"keyboard_tab": 0xE0D1,
	&"keyboard_tilde": 0xE0D7, &"mouse_left": 0xE0EB, &"mouse_right": 0xE0EF,
	&"xbox_button_a": 0xE004, &"xbox_button_b": 0xE006, &"xbox_button_menu": 0xE014, &"xbox_button_view": 0xE01C,
	&"xbox_button_x": 0xE01E, &"xbox_button_y": 0xE020, &"xbox_dpad": 0xE022, &"xbox_lb": 0xE043,
	&"xbox_lt": 0xE047, &"xbox_rb": 0xE049, &"xbox_rt": 0xE04D, &"xbox_stick_l": 0xE04F, &"xbox_stick_r": 0xE057,
}

## Semantic action -> [keyboard glyphs, gamepad glyphs] (matches generate_input_map.gd).
const ACTIONS := {
	&"swing_contact": [[&"keyboard_j", &"mouse_left"], [&"xbox_button_a"]],
	&"swing_power": [[&"keyboard_k", &"mouse_right"], [&"xbox_button_x"]],
	&"swing_bunt": [[&"keyboard_b"], [&"xbox_button_b"]],
	&"move": [[&"keyboard_arrows_all"], [&"xbox_stick_l"]],
	&"sideways": [[&"keyboard_arrows_horizontal"], [&"xbox_stick_l"]],
	&"pitch_prev": [[&"keyboard_q"], [&"xbox_lb"]],
	&"pitch_next": [[&"keyboard_e"], [&"xbox_rb"]],
	&"pitch_primary": [[&"keyboard_space"], [&"xbox_button_a"]],
	&"pitch_slot_1": [[&"keyboard_1"], [&"xbox_lb"]],
	&"pitch_slot_2": [[&"keyboard_2"], [&"xbox_lb"]],
	&"pitch_slot_3": [[&"keyboard_3"], [&"xbox_lb"]],
	&"pitch_slot_4": [[&"keyboard_4"], [&"xbox_lb"]],
	&"pitch_slot_5": [[&"keyboard_5"], [&"xbox_lb"]],
	&"pickoff": [[&"keyboard_f"], [&"xbox_lt"]],
	&"slide_step": [[&"keyboard_shift"], [&"xbox_rt"]],
	&"open_subs": [[&"keyboard_p"], [&"xbox_button_y"]],
	&"runner_advance": [[&"keyboard_e"], [&"xbox_rb"]],
	&"runner_retreat": [[&"keyboard_q"], [&"xbox_lb"]],
	&"dive": [[&"keyboard_shift"], [&"xbox_rt"]],
	&"switch_fielder": [[&"keyboard_f"], [&"xbox_lt"]],
	&"throw_ball": [[&"keyboard_space", &"mouse_left"], [&"xbox_rb"]],
	&"throw_base_1": [[&"keyboard_1"], [&"xbox_button_b"]],
	&"throw_base_2": [[&"keyboard_2"], [&"xbox_button_y"]],
	&"throw_base_3": [[&"keyboard_3"], [&"xbox_button_x"]],
	&"throw_base_4": [[&"keyboard_4"], [&"xbox_button_a"]],
	&"skip": [[&"keyboard_j"], [&"xbox_button_a"]],
	&"switch_side": [[&"keyboard_tab"], [&"xbox_button_view"]],
	&"toggle_debug": [[&"keyboard_tilde"], [&"xbox_stick_r"]],
	&"restart_match": [[&"keyboard_r"], [&"xbox_button_menu"]],
	&"toggle_assist": [[&"keyboard_t"], [&"xbox_stick_l"]],
}


## BBCode with every {action} replaced by its icons for the device.
static func render(text: String, gamepad: bool, size: int = 44) -> String:
	var out := text
	for action: StringName in ACTIONS:
		var token := "{%s}" % action
		if out.contains(token):
			out = out.replace(token, icons(action, gamepad, size))
	return out


static func icons(action: StringName, gamepad: bool, size: int = 30) -> String:
	var glyphs: Array = ACTIONS[action][1 if gamepad else 0]
	var font := PAD_FONT if gamepad else KB_FONT
	var chars := ""
	for g: StringName in glyphs:
		chars += String.chr(GLYPHS[g])
	return "[font=%s][font_size=%d]%s[/font_size][/font]" % [font, size, chars]
