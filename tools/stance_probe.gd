extends SceneTree
## Measures the batter's arms in the stance, at the top of the load and at
## the stride (m, in his frame: +x toward the plate, +y up, +z toward the
## pitcher, from the midpoint of his shoulders), to set beside the book's
## figures (VanSuch, Baseball Swing Mechanics). Righty, classic unless a
## style is given:
##   godot --headless --path . -s res://tools/stance_probe.gd -- [style]
var _frames := 0
var _view: MatchView
var _style: StringName = &"classic"


func _initialize() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		_style = StringName(OS.get_cmdline_user_args()[0])
	root.add_child(load("res://app/main.tscn").instantiate())


func _process(_d: float) -> bool:
	_frames += 1
	if _view == null:
		_view = root.get_node_or_null("Main/MatchView")
		return false
	var b: ActorView = _view._runners.get(_view._batter_id)
	if b == null or _frames < 30:
		return false
	b.style = _style
	if _view._bats_left:
		_view._bats_left = false
		b.set_lefty(false)
		b.position = _view._batter_spot()
		b.face(b.position + Vector3.RIGHT)
	# 60 stance, then load to the top of the load (approach 0.5), then stride.
	if _frames >= 90 and _frames < 150:
		_view._windup = float(_frames - 90) / 60.0
	if _frames == 150:
		_view._windup = -1.0
		_view._pitch_u = 0.6
	if _frames == 176:
		_view.swing_bat()
	var marks := [80, 148, 175, 177, 178, 179, 180, 181, 215]
	if marks.has(_frames):
		_report(b, ["STANCE", "LOAD", "STRIDE", "LAUNCH+1", "LAUNCH+2", "LAUNCH+3", "LAUNCH+4", "CONTACT", "FINISH"][marks.find(_frames)])
	return _frames > 216


func _report(b: ActorView, label: String) -> void:
	var sk: Skeleton3D = b._skeleton
	var g := func(bone: String) -> Vector3:
		return sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bone)).origin
	var sl: Vector3 = g.call("upperarm_l")
	var sr: Vector3 = g.call("upperarm_r")
	var o := (sl + sr) * 0.5
	var f := func(p: Vector3) -> String:
		var d := p - o
		return "(plate %+.2f up %+.2f pitcher %+.2f)" % [d.x, d.y, -d.z]
	var hands: Vector3 = (g.call("hand_l") + g.call("hand_r")) * 0.5
	var bat := -b._grip_ik.bat.global_transform.basis.z
	print("PROBE %s %s" % [_style, label])
	print("  rear shoulder %s  front shoulder %s" % [f.call(sr), f.call(sl)])
	print("  hands %s   rear elbow %s   front elbow %s" % [f.call(hands), f.call(g.call("lowerarm_r")), f.call(g.call("lowerarm_l"))])
	var bend := func(side: String) -> float:
		var sh: Vector3 = g.call("upperarm_" + side)
		var el: Vector3 = g.call("lowerarm_" + side)
		var wr: Vector3 = g.call("hand_" + side)
		return 180.0 - rad_to_deg((el - sh).angle_to(wr - el))
	print("  elbow angle (180 straight): front %.0f  rear %.0f" % [bend.call("l"), bend.call("r")])
	print("  head %s   bat lift %.0f deg, toward plate %+.2f up %+.2f pitcher %+.2f" % [f.call(g.call("Head")), rad_to_deg(asin(clampf(bat.y, -1, 1))), bat.x, bat.y, -bat.z])
