extends SceneTree
## Records the bat's sweet spot through one real swing, in slow motion, as
## Baseball Savant's bat tracking sees it: starts a match, lets the batter
## load and stride to a fake pitch, swings, and samples the sweet spot (and
## the knob) every frame from the stride to the finish. Writes JSON for
## tools/swing_path_plot.py, which measures swing path tilt, attack angle,
## attack direction and the contact point the way Savant does and draws the
## path from behind the catcher, from the side and from above. Needs a
## display:
##   godot --path . --resolution 400x400 --fixed-fps 60 -s res://tools/swing_path.gd -- out.json <style> [lefty|righty] [savant:tilt,attack,direction,mph]

## The sweet spot, m from the barrel's end (about 6 in in).
const SWEET_FROM_TIP := 0.15
const WINDUP_FROM := 60
const PITCH_FROM := 120
const PRESS := 136
## Slow motion from just before the press, so the 0.3 s swing gets many
## samples; stops a little after the finish.
const SLOW := 0.05
var _out := ""
var _style: StringName = &"classic"
var _frames := 0
var _view: MatchView
var _samples: Array = []
var _done := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_out = args[0]
	if args.size() > 1:
		_style = StringName(args[1])
	root.add_child(load("res://app/main.tscn").instantiate())


func _process(_d: float) -> bool:
	_frames += 1
	if _view == null:
		_view = root.get_node_or_null("Main/MatchView")
		var hud: Control = root.get_node_or_null("Main/UI/MatchHud")
		if hud != null:
			hud.visible = false
		return false
	var batter: ActorView = _view._runners.get(_view._batter_id)
	if batter == null:
		return false
	batter.style = _style
	var args := OS.get_cmdline_user_args()
	var want_left := args.has("lefty")
	if (want_left or args.has("righty")) and _view._bats_left != want_left:
		_view._bats_left = want_left
		batter.set_lefty(want_left)
		batter.position = _view._batter_spot()
		batter.face(batter.position + (Vector3.LEFT if want_left else Vector3.RIGHT))
	if _frames >= WINDUP_FROM and _frames < PITCH_FROM:
		_view._windup = float(_frames - WINDUP_FROM) / (PITCH_FROM - WINDUP_FROM)
	elif _frames >= PITCH_FROM:
		_view._windup = -1.0
		_view._pitch_u = minf(float(_frames - PITCH_FROM) / 30.0, 0.6)
	if _frames == PRESS - 2:
		Engine.time_scale = SLOW
	if _frames == PRESS:
		for a: String in args:
			if a.begins_with("savant:"):
				# A hitter's own Savant numbers: tilt, attack angle, attack
				# direction (- pull), bat speed.
				var n := a.substr(7).split_floats(",")
				_view._swing_profile = {"tilt": n[0], "attack_lift": n[1], "attack_yaw": n[2], "bat_speed": n[3]}
		_view.swing_bat()
	if _frames >= PRESS:
		var xf := _view._bat_pivot.global_transform
		_samples.append({
			"t": _view._view_clock - _view._bat_swing_start,
			"sweet": _v(xf * Vector3(0, 0, -BatMesh.LENGTH + SWEET_FROM_TIP)),
			"knob": _v(xf.origin),
			"hands": _v(_hands(batter)),
			"path_sweet": _v(_view._swing_path.at(_view._view_clock - _view._bat_swing_start)["sweet"]) if _view._swing_path != null else [0, 0, 0],
		})
		if _view._view_clock - _view._bat_swing_start > MatchView.SWING_TIME * 0.8:
			var data := {
				"style": String(_style),
				"bats_left": _view._bats_left,
				"swing_time": MatchView.SWING_TIME,
				"contact_t": MatchView.SWING_TIME * BattingStyles.CONTACT_AT,
				"batter": _v(batter.global_position),
				"plate_front_z": -0.2159,
				"profile": _view._swing_profile,
				"samples": _samples,
			}
			var f := FileAccess.open(_out, FileAccess.WRITE)
			f.store_string(JSON.stringify(data))
			f.close()
			return true
	return false


## The middle of his two hands (world).
static func _hands(batter: ActorView) -> Vector3:
	var sk: Skeleton3D = batter._skeleton
	var a := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_l")).origin
	var b := sk.global_transform * sk.get_bone_global_pose(sk.find_bone("hand_r")).origin
	return (a + b) * 0.5


static func _v(p: Vector3) -> Array:
	return [p.x, p.y, p.z]
