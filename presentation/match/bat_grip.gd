class_name BatGrip
extends SkeletonModifier3D
## Puts the batter's hands on the bat. The swing animation brings his hands
## roughly where they belong; this wraps both hands round the handle as a
## real grip: the handle runs across each palm at the base of the fingers,
## thumbs and index fingers toward the barrel, the hands stacked (bottom
## hand at the knob, top hand touching it), fingers and thumbs curled round
## it. Each arm reaches (two-bone IK) to wherever its wrist must be for
## that, and the bat is held there pointing where the swing says. Visual
## only.

## The bat node (handle at its origin, barrel along -Z), placed every frame.
var bat: Node3D
## World direction from the knob to the barrel.
var direction := Vector3.FORWARD
## Distance between the hands along the handle (m, world): choked together
## for a swing, spread for a bunt.
var gap := 0.1
## Lefties: the left hand is on top.
var lefty := false
## The top hand has let go (a one-hand finish).
var one_hand := false
## Hands choked up the handle (m): the knob sits this far below the
## bottom hand.
var choke := 0.0

## Where the handle crosses the palm, in the hand bone's frame (fingers
## along +Y, the index side +Z for the right hand): the base of the
## fingers, a little out from the palm.
const PALM := Vector3(0.0, 0.085, 0.0)
## How far the handle's axis sits off the palm (half a handle and a glove).
const PALM_DEPTH := 0.03
## Handle below the bottom hand's middle to the knob (half a hand).
const KNOB_ROOM := 0.05
## Finger curl round the handle, per joint (degrees).
const CURL := [72.0, 88.0, 60.0]
const FINGERS := ["index", "middle", "ring", "pinky"]


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or bat == null or direction.length() < 0.001:
		return
	var top_side := "l" if lefty else "r"
	var bottom_side := "r" if lefty else "l"
	var xf := sk.global_transform
	var top_at := sk.get_bone_global_pose(sk.find_bone("hand_" + top_side)).origin
	var bottom_at := sk.get_bone_global_pose(sk.find_bone("hand_" + bottom_side)).origin
	var mid := (top_at + bottom_at) * 0.5
	var d := (xf.basis.inverse() * direction).normalized()
	var spread := gap / maxf((xf.basis * d).length(), 0.001)
	var bottom_target := mid - d * spread * 0.5
	var top_target := mid + d * spread * 0.5
	_grip(sk, bottom_side, bottom_target, d)
	if not one_hand:
		_grip(sk, top_side, top_target, d)
	var up := Vector3.UP if absf(direction.normalized().dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
	# The knob just below the bottom hand (its palm is centered on the axis).
	bat.global_transform = Transform3D(Basis.looking_at(direction, up), xf * bottom_target - direction.normalized() * (choke + KNOB_ROOM))


## One hand round the handle at `on_axis` (skeleton space), the handle
## along d: works out the hand's turn (thumb side up the bat, fingers
## across it, carrying on from the forearm), reaches the arm so the palm
## lands there, then sets the hand and curls the fingers.
func _grip(sk: Skeleton3D, side: String, on_axis: Vector3, d: Vector3) -> void:
	var hand := sk.find_bone("hand_" + side)
	var lower := sk.find_bone("lowerarm_" + side)
	# This hand's own sides (the skeleton mirrors left and right).
	var index_side := signf(sk.get_bone_rest(sk.find_bone("index_01_" + side)).origin.z)
	var palm_side := signf(sk.get_bone_rest(sk.find_bone("thumb_01_" + side)).origin.x)
	var forearm := (sk.get_bone_global_pose(hand).origin - sk.get_bone_global_pose(lower).origin).normalized()
	var y := (forearm - d * forearm.dot(d))
	if y.length() < 0.01:
		y = d.cross(Vector3.UP)
	y = y.normalized()
	var z := d * index_side
	var x := y.cross(z).normalized()
	var basis := Basis(x, y, z).orthonormalized()
	var palm := basis * (PALM + Vector3(PALM_DEPTH * palm_side, 0.0, 0.0))
	_reach(sk, side, on_axis - palm)
	var parent_g := sk.get_bone_global_pose(lower)
	sk.set_bone_pose_rotation(hand, (parent_g.basis.inverse() * basis).get_rotation_quaternion())
	# Fingers curl toward the palm, round the handle; the thumb wraps over.
	for finger: String in FINGERS:
		for j in 3:
			var b := sk.find_bone("%s_%02d_%s" % [finger, j + 1, side])
			if b < 0:
				continue
			var r := sk.get_bone_rest(b).basis
			sk.set_bone_pose_rotation(b, (r * Basis(Vector3(1, 0, 0), deg_to_rad(CURL[j]))).get_rotation_quaternion())
	for j in 3:
		var b := sk.find_bone("thumb_%02d_%s" % [j + 1, side])
		if b >= 0:
			var r := sk.get_bone_rest(b).basis
			sk.set_bone_pose_rotation(b, (r * Basis(Vector3(1, 0, 0), deg_to_rad(25.0 + j * 15.0) * -palm_side)).get_rotation_quaternion())


## Two-bone IK for one arm: the wrist lands on target, elbow bent down and out.
func _reach(sk: Skeleton3D, side: String, target: Vector3) -> void:
	var upper := sk.find_bone("upperarm_" + side)
	var lower := sk.find_bone("lowerarm_" + side)
	var hand := sk.find_bone("hand_" + side)
	var gu := sk.get_bone_global_pose(upper)
	var gl := sk.get_bone_global_pose(lower)
	var gh := sk.get_bone_global_pose(hand)
	var s := gu.origin
	var a := s.distance_to(gl.origin)
	var b := gl.origin.distance_to(gh.origin)
	# The chest's own frame (it turns through the swing): side, up, front.
	var spine := sk.get_bone_global_pose(sk.find_bone("spine_01")).origin
	var neck := sk.get_bone_global_pose(sk.find_bone("neck_01")).origin
	var across := (sk.get_bone_global_pose(sk.find_bone("upperarm_l")).origin - sk.get_bone_global_pose(sk.find_bone("upperarm_r")).origin).normalized()
	var up := (neck - spine).normalized()
	var front := across.cross(up).normalized()
	# Elbows hang down and out to their own side, a little behind the body,
	# and swing clear of the chest if that would bury them.
	var pole := across * (0.6 if side == "l" else -0.6) - up - front * 0.2
	var elbow := PoseBaker.bend(s, target, a, b, pole, [spine, neck, across, front])
	var parent_g := sk.get_bone_global_pose(sk.get_bone_parent(upper))
	var new_upper := Basis(Quaternion((gl.origin - s).normalized(), (elbow - s).normalized())) * gu.basis
	sk.set_bone_pose_rotation(upper, (parent_g.basis.inverse() * new_upper).get_rotation_quaternion())
	var lower_local := sk.get_bone_pose(lower)
	var new_lower_t := Transform3D(new_upper, s) * lower_local
	var along := new_lower_t.basis * sk.get_bone_pose(hand).origin
	var new_lower := Basis(Quaternion(along.normalized(), (target - new_lower_t.origin).normalized())) * new_lower_t.basis
	sk.set_bone_pose_rotation(lower, (new_upper.inverse() * new_lower).get_rotation_quaternion())
