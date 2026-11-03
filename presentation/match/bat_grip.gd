class_name BatGrip
extends SkeletonModifier3D
## Puts the batter's hands on the bat. The swing animation brings his hands
## roughly where they belong; this wraps both hands round the handle as a
## real grip: the handle sits in the fingers, not deep in the palm, the
## wrists cocked back (extension, not locked in flexion),
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
## Where the middle of the grip must be (world), and how much that wins
## over where the animation brought the hands (0..1): the swing path's
## hands on the way into contact.
var anchor := Vector3.ZERO
var anchor_weight := 0.0
## The elbows' shape by phase (VanSuch, Baseball Swing Mechanics): `set_up`
## 1 while he waits, loads and strides, 0 once the swing is under way;
## `cocked` 0 in the stance, 1 at the top of the load.
##   stance: back elbow down, pointing down and back; front elbow down;
##   load: back elbow lifted out to the side near shoulder height
##     (abducted, Fig. 2-11), front arm across the chest, its elbow down;
##   swing: back elbow drops and tucks to his side, the "L" (Fig. 4-38).
var set_up := 0.0
var cocked := 0.0
## The arms are motion capture: each elbow bends the way the animation
## already bends it (the wrist only moves onto the handle), so it can't
## flip or fold into the body.
var follow_elbows := false
## The hands are motion capture and already together on a (captured) bat:
## nothing moves the arms or turns the hands; the bat is fitted to them,
## along the line through both grips, and only the fingers close round it.
var from_hands := false
## How much the hitter's stance (hands at the back shoulder, the bat over
## it) replaces the captured hands: 1 waiting and loading, easing to 0 as
## the swing gets going.
var stance := 0.0
var _rest_mid := Vector3.ZERO
var _rest_d := Vector3.UP
var _have_rest := false

## The stance spot from the back shoulder (m): x in toward the chest, y up,
## z in front; and the bat's tilt (per unit up): x back over the shoulder,
## y behind the head.
const STANCE_HANDS := Vector3(0.06, -0.04, 0.3)
## The front elbow's direction in the stance: x in front, y down, z out
## toward the pitcher.
const STANCE_FRONT_ELBOW := Vector3(0.75, 0.6, 0.15)
const STANCE_BAT := Vector2(0.75, 0.3)
## The stance grip stays within this share of each arm's length.
const STANCE_REACH := 0.82
## Locked grip: the handle's angle across the fingers off square (deg),
## the wrists' cock back (deg), the hands' spots apart on the handle (m).
const GRIP_DIAGONAL := 35.0
const LOCKED_EXTENSION := 8.0
const HANDS_STACKED := 0.095
## Hands farther apart than this (m) are spread along the bat (a bunt):
## the bat runs through both, not along the fists.
const SPREAD_HANDS := 0.18
## Where the handle crosses the palm, in the hand bone's frame (fingers
## along +Y, the index side +Z for the right hand): the base of the
## fingers, a little out from the palm.
const PALM := Vector3(0.0, 0.115, 0.0)
## How far the handle's axis sits off the palm (half a handle and a glove).
const PALM_DEPTH := 0.03
## Extra handle below the bottom hand (the bat mesh already sits its knob
## 6 cm below the grip point).
const KNOB_ROOM := 0.0
## Finger curl round the handle, per joint (degrees).
## A knuckle's distance from the handle's axis when wrapped round it:
## handle radius plus a gloved finger's half thickness.
const WRAP := 0.03
## How far each finger joint may bend (degrees).
const MAX_BEND := [95.0, 110.0, 90.0]
## Wrist extension: the hand bent back from the forearm line (degrees).
const EXTENSION := 28.0
const FINGERS := ["index", "middle", "ring", "pinky"]
## How much of the hand's roll about the forearm the forearm takes.
const FOREARM_ROLL := 0.8


func _process_modification_with_delta(_delta: float) -> void:
	var sk := get_skeleton()
	if sk == null or bat == null or direction.length() < 0.001:
		return
	if from_hands:
		_lock_to_bat(sk)
		return
	var top_side := "l" if lefty else "r"
	var bottom_side := "r" if lefty else "l"
	var xf := sk.global_transform
	var top_at := sk.get_bone_global_pose(sk.find_bone("hand_" + top_side)).origin
	var bottom_at := sk.get_bone_global_pose(sk.find_bone("hand_" + bottom_side)).origin
	var mid := (top_at + bottom_at) * 0.5
	if anchor_weight > 0.0:
		mid = mid.lerp(xf.affine_inverse() * anchor, clampf(anchor_weight, 0.0, 1.0))
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


## Grip spots on the bat, the hands locked to them: the bat takes the
## captured hands' path (along the fists, through the middle of the two
## grips, rolled the way the top hand wraps it); each hand is set in a real
## grip at its spot (bottom hand at the knob, top hand stacked above it,
## the handle on the diagonal across the fingers) and its arm reaches there,
## the elbow on the captured side. So the bat leads; arms, elbows and
## wrists bend to hold it.
func _lock_to_bat(sk: Skeleton3D) -> void:
	var top_side := "l" if lefty else "r"
	var bottom_side := "r" if lefty else "l"
	var bottom := _grip_point(sk, bottom_side)
	var top := _grip_point(sk, top_side)
	var spread := not one_hand and bottom.distance_to(top) > SPREAD_HANDS
	var d := _fist_axis(sk, top_side if not one_hand else bottom_side)
	if spread:
		d = (top - bottom).normalized()
		if d.dot(_fist_axis(sk, bottom_side)) < 0.0:
			d = -d
	elif not one_hand:
		d = (d + _fist_axis(sk, bottom_side)).normalized()
	var mid := (bottom + top) * 0.5 if not one_hand else bottom
	if stance > 0.0 and not spread and not one_hand:
		var moved := _stance_shift(sk, mid, d)
		mid = mid.lerp(moved[0], stance)
		d = d.slerp(moved[1], stance).normalized()
	# The way the fingers wrap the handle: the top hand's (it holds right).
	var wrap_side := top_side if not one_hand else bottom_side
	var fingers := sk.get_bone_global_pose(sk.find_bone("hand_" + wrap_side)).basis.y.normalized()
	var apart := bottom.distance_to(top) if spread else HANDS_STACKED
	var spots := {bottom_side: mid - d * apart * 0.5, top_side: mid + d * apart * 0.5}
	if one_hand:
		spots = {bottom_side: mid}
	for side: String in spots:
		_grip(sk, side, spots[side], d, fingers, LOCKED_EXTENSION)
	var xf := sk.global_transform
	var world_d := (xf.basis * d).normalized()
	var up := Vector3.UP if absf(world_d.dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
	bat.global_transform = Transform3D(Basis.looking_at(world_d, up), xf * (spots[bottom_side] as Vector3) - world_d * (choke + KNOB_ROOM))


## The hitter's stance (VanSuch): hands up by the back shoulder, a hand's
## width in front of it, the bat tilted back over that shoulder. The
## capture holds them low in front of the chest with the bat upright, which
## no pair of hands can grip with straight wrists. Returns [grip middle,
## bat direction]: the stance spot plus the capture's own movement since
## its stance (so the load still shows), the bat turned likewise.
func _stance_shift(sk: Skeleton3D, mid: Vector3, d: Vector3) -> Array:
	var rear_side := "l" if lefty else "r"
	var spine := sk.get_bone_global_pose(sk.find_bone("spine_01")).origin
	var neck := sk.get_bone_global_pose(sk.find_bone("neck_01")).origin
	var shoulder := sk.get_bone_global_pose(sk.find_bone("upperarm_" + rear_side)).origin
	var other := sk.get_bone_global_pose(sk.find_bone("upperarm_" + ("r" if lefty else "l"))).origin
	var up := (neck - spine).normalized()
	var rear := (shoulder - other).normalized()
	var front := rear.cross(up).normalized()
	if front.z < 0.0:
		front = -front
	var spot := shoulder + front * STANCE_HANDS.z + up * STANCE_HANDS.y - rear * STANCE_HANDS.x
	var tilt := (up + rear * STANCE_BAT.x - front * STANCE_BAT.y).normalized()
	# The capture's stance frame, learned while he stands in it.
	if not _have_rest or (stance >= 0.999 and cocked < 0.02):
		_rest_mid = mid
		_rest_d = d
		_have_rest = true
	var turn := Quaternion(_rest_d, d) if _rest_d.dot(d) > -0.99 else Quaternion()
	var goal := spot + (mid - _rest_mid)
	# Within both arms' reach (the front arm crosses the chest to it).
	for side: String in ["l", "r"]:
		var sh := sk.get_bone_global_pose(sk.find_bone("upperarm_" + side)).origin
		var lo := sk.get_bone_global_pose(sk.find_bone("lowerarm_" + side)).origin
		var hd := sk.get_bone_global_pose(sk.find_bone("hand_" + side)).origin
		var reach := (sh.distance_to(lo) + lo.distance_to(hd)) * STANCE_REACH
		if goal.distance_to(sh) > reach:
			goal = sh + (goal - sh).normalized() * reach
	return [goal, (turn * tilt).normalized()]


## The bat along the captured hands: through the middle of both grips,
## the knob below the bottom hand; then the fingers close round it.
func _fit_to_hands(sk: Skeleton3D) -> void:
	var top_side := "l" if lefty else "r"
	var bottom_side := "r" if lefty else "l"
	var bottom := _grip_point(sk, bottom_side)
	var top := _grip_point(sk, top_side)
	# A fist holds the handle across its knuckles (pinky side to index
	# side): the bat runs along both fists' own axis, toward the barrel.
	var d := _fist_axis(sk, bottom_side)
	if not one_hand and bottom.distance_to(top) > SPREAD_HANDS:
		# Hands spread (a bunt, the top hand up the barrel): along them.
		d = (top - bottom).normalized()
		if d.dot(_fist_axis(sk, bottom_side)) < 0.0:
			d = -d
	elif not one_hand:
		d = (d + _fist_axis(sk, top_side)).normalized()
		# Through the middle of both grips.
		var mid := (bottom + top) * 0.5
		bottom = mid - d * d.dot(mid - bottom)
	d = d.normalized()
	var xf := sk.global_transform
	for side: String in ([bottom_side] if one_hand else [bottom_side, top_side]):
		var at := _grip_point(sk, side)
		var on_axis := bottom + d * d.dot(at - bottom)
		for finger: String in FINGERS:
			for j in 3:
				_wrap(sk, "%s_%02d_%s" % [finger, j + 1, side], "%s_%02d%s_%s" % [finger, j + 2, "_leaf" if j == 2 else "", side], on_axis, d, Vector3(1, 0, 0), 0.0, MAX_BEND[j])
		for j in 3:
			_wrap(sk, "thumb_%02d_%s" % [j + 1, side], "thumb_%02d%s_%s" % [j + 2, "_leaf" if j == 2 else "", side], on_axis, d, Vector3.ZERO, -80.0, 80.0, 1.2)
	var world_d := (xf.basis * d).normalized()
	var up := Vector3.UP if absf(world_d.dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
	bat.global_transform = Transform3D(Basis.looking_at(world_d, up), xf * bottom - world_d * (choke + KNOB_ROOM))


## A hand's fist axis, pinky side to index side (skeleton space).
func _fist_axis(sk: Skeleton3D, side: String) -> Vector3:
	var basis := sk.get_bone_global_pose(sk.find_bone("hand_" + side)).basis
	var index_side := signf(sk.get_bone_rest(sk.find_bone("index_01_" + side)).origin.z)
	return (basis.z * index_side).normalized()


## Where a hand holds the handle (skeleton space): the base of its
## fingers, out from the palm, as the hand is posed.
func _grip_point(sk: Skeleton3D, side: String) -> Vector3:
	var hand := sk.get_bone_global_pose(sk.find_bone("hand_" + side))
	var palm_side := signf(sk.get_bone_rest(sk.find_bone("thumb_01_" + side)).origin.x)
	return hand * (PALM + Vector3(PALM_DEPTH * palm_side, 0.0, 0.0))


## One hand round the handle at `on_axis` (skeleton space), the handle
## along d: works out the hand's turn (thumb side up the bat, fingers
## across it, carrying on from the forearm), reaches the arm so the palm
## lands there, then sets the hand and curls the fingers.
func _grip(sk: Skeleton3D, side: String, on_axis: Vector3, d: Vector3, fingers: Vector3 = Vector3.ZERO, extension: float = EXTENSION) -> void:
	var hand := sk.find_bone("hand_" + side)
	var lower := sk.find_bone("lowerarm_" + side)
	# This hand's own sides (the skeleton mirrors left and right).
	var index_side := signf(sk.get_bone_rest(sk.find_bone("index_01_" + side)).origin.z)
	var palm_side := signf(sk.get_bone_rest(sk.find_bone("thumb_01_" + side)).origin.x)
	var forearm := (sk.get_bone_global_pose(hand).origin - sk.get_bone_global_pose(lower).origin).normalized()
	var y := (forearm - d * forearm.dot(d))
	if fingers != Vector3.ZERO:
		# Locked to the bat: the fingers wrap the given way round it, the
		# handle crossing them on the diagonal (index base up the bat, the
		# heel of the hand toward the knob), as a real grip holds it.
		y = fingers - d * fingers.dot(d)
	if y.length() < 0.01:
		y = d.cross(Vector3.UP)
	y = y.normalized()
	if fingers != Vector3.ZERO:
		var g := deg_to_rad(GRIP_DIAGONAL)
		y = (y * cos(g) + d * sin(g)).normalized()
	var z := d * index_side
	z = (z - y * z.dot(y)).normalized()
	var x := y.cross(z).normalized()
	# Cock the wrist back: the fingers tip away from the palm side, about
	# the handle's own line (so the hand stays square to the bat).
	var palm_normal := x * palm_side
	var e := deg_to_rad(extension)
	y = (y * cos(e) - palm_normal * sin(e)).normalized()
	x = y.cross(z).normalized()
	var basis := Basis(x, y, z).orthonormalized()
	var palm := basis * (PALM + Vector3(PALM_DEPTH * palm_side, 0.0, 0.0))
	_reach(sk, side, on_axis - palm)
	var parent_g := sk.get_bone_global_pose(lower)
	# The hand's roll about the forearm goes mostly to the forearm itself
	# (turning about its own length, so the wrist stays put): this rig has
	# no twist bones, so a whole roll at the wrist wrings its skin.
	var local := (parent_g.basis.inverse() * basis).get_rotation_quaternion()
	var axis := sk.get_bone_rest(hand).origin.normalized()
	var twist := _twist(local, axis)
	var roll := twist.get_angle() * signf(Vector3(twist.x, twist.y, twist.z).dot(axis))
	var lower_rot := sk.get_bone_pose_rotation(lower) * Quaternion(axis, wrapf(roll, -PI, PI) * FOREARM_ROLL)
	sk.set_bone_pose_rotation(lower, lower_rot.normalized())
	parent_g = sk.get_bone_global_pose(lower)
	sk.set_bone_pose_rotation(hand, (parent_g.basis.inverse() * basis).get_rotation_quaternion())
	# Fingers and thumb wrap the handle: each joint bends until the next
	# knuckle sits on the handle's surface (handle plus finger thickness
	# from its axis), so the hand closes round it at any bat angle.
	for finger: String in FINGERS:
		for j in 3:
			_wrap(sk, "%s_%02d_%s" % [finger, j + 1, side], "%s_%02d%s_%s" % [finger, j + 2, "_leaf" if j == 2 else "", side], on_axis, d, Vector3(1, 0, 0), 0.0, MAX_BEND[j])
	# The thumb's joints turn on their own axes: each tries all three and
	# keeps the bend that wraps it best (over the fingers, round the handle).
	for j in 3:
		_wrap(sk, "thumb_%02d_%s" % [j + 1, side], "thumb_%02d%s_%s" % [j + 2, "_leaf" if j == 2 else "", side], on_axis, d, Vector3.ZERO, -80.0, 80.0, 1.2)


## The part of rotation q that turns about `axis` (swing-twist split).
static func _twist(q: Quaternion, axis: Vector3) -> Quaternion:
	var v := Vector3(q.x, q.y, q.z)
	var p := axis * v.dot(axis)
	var t := Quaternion(p.x, p.y, p.z, q.w)
	if t.length_squared() < 1e-9:
		return Quaternion()
	return t.normalized()


## Bends one joint (about its local `axis`, between lo and hi degrees off
## its rest; a zero axis tries the joint's X and Z) so its child knuckle
## lands nearest WRAP from the handle's axis (and, with `across`, near the
## hand's own spot along it: wrapped round, not laid along).
func _wrap(sk: Skeleton3D, bone_name: String, child_name: String, on_axis: Vector3, d: Vector3, axis: Vector3, lo: float, hi: float, across: float = 0.0) -> void:
	var b := sk.find_bone(bone_name)
	var c := sk.find_bone(child_name)
	if b < 0 or c < 0:
		return
	var rest := sk.get_bone_rest(b).basis
	var axes: Array[Vector3] = [Vector3(1, 0, 0), Vector3(0, 0, 1)]
	if axis != Vector3.ZERO:
		axes = [axis]
	var best := Basis()
	var best_err := INF
	for ax in axes:
		var a := lo
		while a <= hi:
			var turn := Basis(ax, deg_to_rad(a))
			sk.set_bone_pose_rotation(b, (rest * turn).get_rotation_quaternion())
			var p := sk.get_bone_global_pose(c).origin - on_axis
			# `across` keeps it wrapping round, not lying along the handle.
			var err := absf((p - d * p.dot(d)).length() - WRAP) + absf(p.dot(d)) * across
			if err < best_err - 0.0005:
				best_err = err
				best = turn
			a += 6.0
	sk.set_bone_pose_rotation(b, (rest * best).get_rotation_quaternion())


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
	# Front is toward the plate (the rig faces +Z), lefties too.
	if front.z < 0.0:
		front = -front
	var out := across * (1.0 if side == "l" else -1.0)
	var rear := side == ("l" if lefty else "r")
	# In the swing: the back elbow tucks down at his side (the "L"), the
	# front one hangs down and a little out toward the pitcher.
	var pole := (out * 0.25 - up - front * 0.15) if rear else (out * 0.6 - up - front * 0.2)
	if set_up > 0.0:
		var waiting: Vector3
		if rear:
			waiting = (out * 0.55 - up - front * 0.45).normalized().slerp((out + up * 0.45 - front * 0.3).normalized(), clampf(cocked, 0.0, 1.0))
		else:
			waiting = -up + front * 0.6 + out * 0.1
		pole = pole.normalized().slerp(waiting.normalized(), clampf(set_up, 0.0, 1.0))
	if follow_elbows:
		# The captured elbow's side of the shoulder-to-wrist line.
		var line := (target - s).normalized()
		var off := gl.origin - s
		off -= line * off.dot(line)
		if off.length() > 0.01:
			pole = off.normalized()
		if stance > 0.0 and not rear:
			# In the stance the front arm reaches across the chest to the back
			# shoulder: its elbow points down and out in front of him (the
			# captured elbow, set for hands at the chest, folds it into the
			# body).
			var front_pole := (front * STANCE_FRONT_ELBOW.x - up * STANCE_FRONT_ELBOW.y + out * STANCE_FRONT_ELBOW.z).normalized()
			pole = pole.slerp(front_pole, clampf(stance, 0.0, 1.0)).normalized()
	var elbow := PoseBaker.bend(s, target, a, b, pole, [spine, neck, across, front])
	var parent_g := sk.get_bone_global_pose(sk.get_bone_parent(upper))
	var new_upper := Basis(Quaternion((gl.origin - s).normalized(), (elbow - s).normalized())) * gu.basis
	sk.set_bone_pose_rotation(upper, (parent_g.basis.inverse() * new_upper).get_rotation_quaternion())
	var lower_local := sk.get_bone_pose(lower)
	var new_lower_t := Transform3D(new_upper, s) * lower_local
	var along := new_lower_t.basis * sk.get_bone_pose(hand).origin
	var new_lower := Basis(Quaternion(along.normalized(), (target - new_lower_t.origin).normalized())) * new_lower_t.basis
	sk.set_bone_pose_rotation(lower, (new_upper.inverse() * new_lower).get_rotation_quaternion())
