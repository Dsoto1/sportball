class_name FootPlant
extends SkeletonModifier3D
## Keeps each foot on the field's surface where it stands. The actor is
## lifted by the ground height under its own root (FieldLayout); on a
## slope (the mound) one foot is then too high or too low: this reaches
## that leg (two-bone IK, knee bending the way the animation bent it) so
## the foot lands on the surface right under it, its angle unchanged.
## A pitcher's back foot stays on the rubber and his stride foot comes
## down on the slope toward home. Visual only.

const SIDES := ["l", "r"]
## Below this (m) a foot is left as the animation put it.
const TOLERANCE := 0.004
## Each foot's height over the surface under it after planting (tools read it).
var last_gap := {}
## Pin feet near the ground down onto it (the pitcher: his stride foot stays
## planted from landing through the follow-through, his back toe drags on
## the dirt). Off for everyone else, whose strides lift feet on purpose.
var pin := false
## A foot whose ball is lower than this over the surface is pinned (m).
const PIN_BELOW := 0.25
## The ball of a planted foot sits this far up its bone (rest height).
const BALL_REST := 0.015


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	var xf := sk.global_transform
	var root_world := xf.origin
	var base := FieldLayout.ground_height(root_world)
	var inv := xf.basis.inverse()
	var targets := {}
	var shortfall := 0.0
	for side: String in SIDES:
		var foot := sk.find_bone("foot_" + side)
		if foot < 0:
			continue
		var at := sk.get_bone_global_pose(foot).origin
		var lift := FieldLayout.ground_height(xf * at) - base
		if pin:
			# How far the ball of the foot hangs over the ground where it is.
			var ball := xf * sk.get_bone_global_pose(sk.find_bone("ball_" + side)).origin
			var hang := ball.y - FieldLayout.ground_height(ball) - BALL_REST
			if hang > 0.0 and hang < PIN_BELOW:
				lift = -hang
			elif hang <= 0.0:
				lift = -hang
			else:
				lift = 0.0
		targets[side] = at + inv * Vector3(0.0, lift, 0.0)
		# A leg already near straight can't reach down the slope: the hips
		# come down by what it lacks (a lunge onto the downhill foot).
		var thigh := sk.get_bone_global_pose(sk.find_bone("thigh_" + side)).origin
		var calf := sk.get_bone_global_pose(sk.find_bone("calf_" + side)).origin
		var reach := (thigh.distance_to(calf) + calf.distance_to(at)) * 0.985
		shortfall = maxf(shortfall, thigh.distance_to(targets[side]) - reach)
	if shortfall > 0.0:
		var pelvis := sk.find_bone("pelvis")
		var p := sk.get_bone_pose_position(pelvis)
		var parent := sk.get_bone_global_pose(sk.get_bone_parent(pelvis)).basis
		sk.set_bone_pose_position(pelvis, p + parent.inverse() * (inv * Vector3(0.0, -shortfall * 1.05, 0.0)))
	for side: String in targets:
		var foot := sk.find_bone("foot_" + side)
		var now := sk.get_bone_global_pose(foot).origin
		if now.distance_to(targets[side]) > TOLERANCE:
			_reach(sk, side, targets[side])
		var placed := xf * sk.get_bone_global_pose(foot).origin
		var ball := xf * sk.get_bone_global_pose(sk.find_bone("ball_" + side)).origin
		last_gap[side] = [snappedf(placed.y - FieldLayout.ground_height(placed), 0.001), snappedf(ball.y - FieldLayout.ground_height(ball), 0.001)]


func _reach(sk: Skeleton3D, side: String, target: Vector3) -> void:
	var thigh := sk.find_bone("thigh_" + side)
	var calf := sk.find_bone("calf_" + side)
	var foot := sk.find_bone("foot_" + side)
	var gt := sk.get_bone_global_pose(thigh)
	var gc := sk.get_bone_global_pose(calf)
	var gf := sk.get_bone_global_pose(foot)
	var s := gt.origin
	var a := s.distance_to(gc.origin)
	var b := gc.origin.distance_to(gf.origin)
	var to := target - s
	var d := clampf(to.length(), absf(a - b) + 0.001, a + b - 0.001)
	var u := to.normalized()
	# The knee bends where the animation had it bend.
	var bend := (gc.origin - s) - u * (gc.origin - s).dot(u)
	if bend.length() < 0.001:
		bend = Vector3(0, 0, 1) - u * u.z
	bend = bend.normalized()
	var cos_a := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var knee := s + u * a * cos_a + bend * a * sqrt(1.0 - cos_a * cos_a)
	var foot_basis := gf.basis
	var parent_g := sk.get_bone_global_pose(sk.get_bone_parent(thigh))
	var new_thigh := Basis(Quaternion((gc.origin - s).normalized(), (knee - s).normalized())) * gt.basis
	sk.set_bone_pose_rotation(thigh, (parent_g.basis.inverse() * new_thigh).get_rotation_quaternion())
	var calf_t := Transform3D(new_thigh, s) * sk.get_bone_pose(calf)
	var foot_at := calf_t * sk.get_bone_pose(foot).origin
	var new_calf := Basis(Quaternion((foot_at - calf_t.origin).normalized(), (s + u * d - calf_t.origin).normalized())) * calf_t.basis
	sk.set_bone_pose_rotation(calf, (new_thigh.inverse() * new_calf).get_rotation_quaternion())
	sk.set_bone_pose_rotation(foot, (new_calf.inverse() * foot_basis).get_rotation_quaternion())
