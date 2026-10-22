extends SceneTree
## Screenshot of the user pitching (camera over the pitcher's shoulder, the
## pitching HUD): starts a match as the home club (who pitch first), waits
## for the first pitch, aims a little, and saves the frame. Needs a display:
##   godot --path . --resolution 1600x900 -s res://tools/pitch_view_shot.gd -- /tmp/out.png [aim_x aim_y] [batting]
var _frames := 0
var _out := ""
var _director: Node
var _picked := false
var _batting := false


func _initialize() -> void:
	_out = OS.get_cmdline_user_args()[0]
	_batting = OS.get_cmdline_user_args().has("batting")
	root.add_child(load("res://app/main.tscn").instantiate())


func _process(_d: float) -> bool:
	_frames += 1
	if _director == null:
		_director = root.get_node_or_null("Main/MatchDirector")
		return false
	if not _picked and _frames > 20:
		# The matchup card: home pitches first, away bats first.
		var press := InputEventAction.new()
		press.action = &"swing_contact" if _batting else &"swing_power"
		press.pressed = true
		Input.parse_input_event(press)
		_picked = true
		return false
	if _frames == 24:
		var release := InputEventAction.new()
		release.action = &"swing_contact" if _batting else &"swing_power"
		release.pressed = false
		Input.parse_input_event(release)
	if _frames > 24 and _frames < 70 and not _batting:
		# Nudge the aim up and to the side.
		Input.action_press(&"aim_right", 0.6)
		Input.action_press(&"aim_up", 0.4)
	if _frames == 70:
		Input.action_release(&"aim_right")
		Input.action_release(&"aim_up")
	if _frames == 110:
		root.get_texture().get_image().save_png(_out)
		return true
	return false
