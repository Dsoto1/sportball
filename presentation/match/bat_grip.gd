class_name BatGrip
extends SkeletonModifier3D
## Puts the batter's hands on the bat. The swing animation brings his hands
## roughly where they belong; this reaches both arms (two-bone IK) onto the
## handle, bottom hand near the knob and top hand just above it, and holds
## the bat there pointing where the swing says. Visual only.

## The bat node (handle at its origin, barrel along -Z), placed every frame.
var bat: Node3D
## World direction from the knob to the barrel.
var direction := Vector3.FORWARD
## Distance between the hands along the handle (m, world): choked together
## for a swing, spread for a bunt.
var gap := 0.1
## Lefties: the left hand is on top.
var lefty := false


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
	_reach(sk, bottom_side, bottom_target)
	_reach(sk, top_side, top_target)
	var up := Vector3.UP if absf(direction.normalized().dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
	bat.global_transform = Transform3D(Basis.looking_at(direction, up), xf * bottom_target)


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
	var to := target - s
	var dist := clampf(to.length(), absf(a - b) + 0.001, a + b - 0.001)
	var n := to.normalized()
	# Skeleton space: +X is the body's left, so "out" flips per arm.
	var pole := Vector3(0.6 if side == "l" else -0.6, -1.0, -0.2)
	var m := pole - n * pole.dot(n)
	if m.length() < 0.001:
		m = Vector3.DOWN
	m = m.normalized()
	var cos_a := clampf((a * a + dist * dist - b * b) / (2.0 * a * dist), -1.0, 1.0)
	var elbow := s + a * (cos_a * n + sqrt(1.0 - cos_a * cos_a) * m)
	var parent_g := sk.get_bone_global_pose(sk.get_bone_parent(upper))
	var new_upper := Basis(Quaternion((gl.origin - s).normalized(), (elbow - s).normalized())) * gu.basis
	sk.set_bone_pose_rotation(upper, (parent_g.basis.inverse() * new_upper).get_rotation_quaternion())
	var lower_local := sk.get_bone_pose(lower)
	var new_lower_t := Transform3D(new_upper, s) * lower_local
	var along := new_lower_t.basis * sk.get_bone_pose(hand).origin
	var new_lower := Basis(Quaternion(along.normalized(), (target - new_lower_t.origin).normalized())) * new_lower_t.basis
	sk.set_bone_pose_rotation(lower, (new_upper.inverse() * new_lower).get_rotation_quaternion())
