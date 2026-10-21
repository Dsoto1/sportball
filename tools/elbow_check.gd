extends SceneTree
## Drives a batter through every style's stance, approach and swing (with
## the bat grip IK on, as in a game) and reports how close each elbow and
## forearm comes to the torso. Clearance < 1.0 means inside the keep-out
## (PoseBaker.TORSO_HALF_WIDTH / _DEPTH). Headless:
##   godot --headless --path . -s res://tools/elbow_check.gd [-- [lefty] [verbose <style>]]
const SAMPLES := [["stance", 0.0], ["load", 0.5], ["stride", 0.85], ["swing", 0.0], ["swing", 0.06], ["swing", 0.11], ["swing", 0.16], ["swing", 0.2], ["swing", 0.35], ["swing", 0.5], ["swing", 0.7], ["swing", 1.0]]
var _actor: ActorView
var _bat: Node3D
var _style := 0
var _sample := 0
var _wait := 0
var _worst := {}
var _lefty := false


func _initialize() -> void:
	_lefty = OS.get_cmdline_user_args().has("lefty")
	_actor = ActorView.new()
	root.add_child(_actor)
	_actor.setup(Color.RED, "")
	_actor.set_glove_visible(false)
	_actor.set_lefty(_lefty)
	_bat = Node3D.new()
	root.add_child(_bat)


func _process(delta: float) -> bool:
	if _style >= BattingStyles.ORDER.size():
		for style: StringName in BattingStyles.ORDER:
			print("%-9s %s" % [style, _worst[style]])
		return true
	var style: StringName = BattingStyles.ORDER[_style]
	_actor.style = style
	var s: Array = SAMPLES[_sample]
	var side := -1.0 if _lefty else 1.0
	var bat: Vector2
	if s[0] == "swing":
		_actor.animate(ActorView.Pose.SWING, delta, 0.0, false, s[1])
		bat = BattingStyles.swing_bat(style, s[1], BattingStyles.approach_bat(style, 1.0, 0.0))
	else:
		_actor.animate(ActorView.Pose.APPROACH, delta, 0.0, false, s[1])
		bat = BattingStyles.approach_bat(style, s[1], 0.0)
	var y := deg_to_rad(bat.x)
	var e := deg_to_rad(bat.y)
	var dir := Vector3(cos(e) * cos(y) * side, sin(e), cos(e) * sin(y))
	_actor.grip_bat(_bat, dir, 0.09, bool(BattingStyles.BAT[style]["one_hand"]) and s[0] == "swing" and s[1] > BattingStyles.ONE_HAND_RELEASE)
	_wait += 1
	if _wait < 3:
		return false
	_wait = 0
	var sk := _actor._skeleton
	var g := func(bone: String) -> Vector3: return sk.get_bone_global_pose(sk.find_bone(bone)).origin
	var across: Vector3 = (g.call("upperarm_l") - g.call("upperarm_r")).normalized()
	var spine: Vector3 = g.call("spine_01")
	var neck: Vector3 = g.call("neck_01")
	var up := (neck - spine).normalized()
	var torso := [spine, neck, across, across.cross(up).normalized()]
	var worst := INF
	var where := ""
	if OS.get_cmdline_user_args().has("verbose") and String(style) == OS.get_cmdline_user_args()[-1]:
		var line := "%s %.2f:" % s
		for side_name in ["l", "r"]:
			var el: Vector3 = g.call("lowerarm_" + side_name)
			var wr: Vector3 = g.call("hand_" + side_name)
			line += "  %s elbow %.2f forearm %.2f wrist %.2f" % [side_name, PoseBaker.torso_clearance(el, torso), PoseBaker.torso_clearance((el + wr) * 0.5, torso), PoseBaker.torso_clearance(wr, torso)]
		print(line)
	for side_name in ["l", "r"]:
		var elbow: Vector3 = g.call("lowerarm_" + side_name)
		var wrist: Vector3 = g.call("hand_" + side_name)
		for p: Array in [["elbow", elbow], ["forearm", (elbow + wrist) * 0.5]]:
			var c := PoseBaker.torso_clearance(p[1], torso)
			if c < worst:
				worst = c
				where = "%s_%s at %s %.2f" % [p[0], side_name, s[0], s[1]]
	var prev: Dictionary = _worst.get(style, {"clear": INF})
	if worst < float(prev["clear"]):
		_worst[style] = {"clear": snappedf(worst, 0.01), "where": where}
	_sample += 1
	if _sample >= SAMPLES.size():
		_sample = 0
		_style += 1
	return false
