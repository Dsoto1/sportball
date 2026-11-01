extends TestCase
## The captured batting clips (MixamoRetarget): baked onto the players'
## skeleton, the lefty clip an exact mirror of the righty one, both hands
## at a grip's distance, and no elbow or forearm inside the body.

func _rig() -> Skeleton3D:
	var model: Node3D = ActorView.BODY.instantiate()
	return model.find_child("Skeleton3D") as Skeleton3D


func _pose_at(sk: Skeleton3D, anim: Animation, t: float) -> Dictionary:
	for tr in anim.get_track_count():
		var bone := sk.find_bone(String(anim.track_get_path(tr).get_concatenated_subnames()))
		if anim.track_get_type(tr) == Animation.TYPE_ROTATION_3D:
			sk.set_bone_pose_rotation(bone, anim.rotation_track_interpolate(tr, t))
		elif anim.track_get_type(tr) == Animation.TYPE_POSITION_3D:
			sk.set_bone_pose_position(bone, anim.position_track_interpolate(tr, t))
	return MixamoRetarget._globals(sk)


func test_lefty_is_the_righty_mirrored() -> void:
	if not BaseballMoves.has_mocap():
		return
	var sk := _rig()
	var right := MixamoRetarget.bake("Baseball_Hit", sk, 1.12, 1.75)
	var left := MixamoRetarget.bake("Baseball_Hit", sk, 1.12, 1.75, false, true)
	check(right != null and left != null, "the swing bakes both ways")
	for t: float in [0.0, 0.1, 0.18, 0.3, 0.5]:
		var r := _pose_at(sk, right, t)
		var hr: Vector3 = (r[sk.find_bone("hand_r")] as Transform3D).origin
		var l := _pose_at(sk, left, t)
		var hl: Vector3 = (l[sk.find_bone("hand_l")] as Transform3D).origin
		check(hl.distance_to(Vector3(-hr.x, hr.y, hr.z)) < 0.02, "t=%.2f: the lefty's left hand mirrors the righty's right (%s vs %s)" % [t, hl, hr])
	sk.get_parent().get_parent().free()


func test_captured_swing_keeps_the_arms_off_the_body() -> void:
	if not BaseballMoves.has_mocap():
		return
	var sk := _rig()
	var swing := MixamoRetarget.bake("Baseball_Hit", sk, 0.0, 1.75)
	var t := 0.0
	while t <= swing.length:
		var g := _pose_at(sk, swing, t)
		var o := func(b: String) -> Vector3: return (g[sk.find_bone(b)] as Transform3D).origin
		var across: Vector3 = (o.call("upperarm_l") - o.call("upperarm_r")).normalized()
		var up: Vector3 = (o.call("neck_01") - o.call("spine_01")).normalized()
		var torso := [o.call("spine_01"), o.call("neck_01"), across, across.cross(up).normalized()]
		for side in ["l", "r"]:
			var e: Vector3 = o.call("lowerarm_" + side)
			var w: Vector3 = o.call("hand_" + side)
			var c := minf(PoseBaker.torso_clearance(e, torso), PoseBaker.torso_clearance((e + w) * 0.5, torso))
			check(c > 0.6, "t=%.2f: %s elbow/forearm off the body (%.2f)" % [t, side, c])
		t += 1.0 / 15.0
	sk.get_parent().get_parent().free()
