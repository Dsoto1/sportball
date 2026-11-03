class_name MixamoRetarget
extends RefCounted
## Bakes a Mixamo clip (motion capture on the standard mixamorig skeleton,
## T-pose rest, from the owner's Drive: assets/third_party/mixamo) onto the
## players' skeleton (Quaternius UAL, also a T-pose rest) as an Animation
## of rotation tracks plus the pelvis position. Every frame each player
## bone takes its Mixamo twin's turn from rest, in the skeleton's frame;
## arm, leg and finger bones are first lined up rest-to-rest along their
## segment, so the T-poses' small differences don't bend the limbs. The
## pelvis follows the hips, scaled to the players' hip height.

const DIR := "res://assets/third_party/mixamo/"
const FPS := 30.0
## How much of the hand's roll about the forearm the forearm takes.
const FOREARM_ROLL := 0.85

## Player (UAL) bone -> Mixamo bone (without the "mixamorig_" prefix).
const MAP := {
	"pelvis": "Hips", "spine_01": "Spine", "spine_02": "Spine1", "spine_03": "Spine2",
	"neck_01": "Neck", "Head": "Head",
	"clavicle_l": "LeftShoulder", "upperarm_l": "LeftArm", "lowerarm_l": "LeftForeArm", "hand_l": "LeftHand",
	"clavicle_r": "RightShoulder", "upperarm_r": "RightArm", "lowerarm_r": "RightForeArm", "hand_r": "RightHand",
	"thigh_l": "LeftUpLeg", "calf_l": "LeftLeg", "foot_l": "LeftFoot", "ball_l": "LeftToeBase",
	"thigh_r": "RightUpLeg", "calf_r": "RightLeg", "foot_r": "RightFoot", "ball_r": "RightToeBase",
	"thumb_01_l": "LeftHandThumb1", "thumb_02_l": "LeftHandThumb2", "thumb_03_l": "LeftHandThumb3",
	"index_01_l": "LeftHandIndex1", "index_02_l": "LeftHandIndex2", "index_03_l": "LeftHandIndex3",
	"middle_01_l": "LeftHandMiddle1", "middle_02_l": "LeftHandMiddle2", "middle_03_l": "LeftHandMiddle3",
	"ring_01_l": "LeftHandRing1", "ring_02_l": "LeftHandRing2", "ring_03_l": "LeftHandRing3",
	"pinky_01_l": "LeftHandPinky1", "pinky_02_l": "LeftHandPinky2", "pinky_03_l": "LeftHandPinky3",
	"thumb_01_r": "RightHandThumb1", "thumb_02_r": "RightHandThumb2", "thumb_03_r": "RightHandThumb3",
	"index_01_r": "RightHandIndex1", "index_02_r": "RightHandIndex2", "index_03_r": "RightHandIndex3",
	"middle_01_r": "RightHandMiddle1", "middle_02_r": "RightHandMiddle2", "middle_03_r": "RightHandMiddle3",
	"ring_01_r": "RightHandRing1", "ring_02_r": "RightHandRing2", "ring_03_r": "RightHandRing3",
	"pinky_01_r": "RightHandPinky1", "pinky_02_r": "RightHandPinky2", "pinky_03_r": "RightHandPinky3",
}


## The clip `name` (file name without .fbx) baked for `target`, from `from`
## to `to` seconds of the source (to < 0: its end). Null if missing.
## `mirror`: the left-handed version, the mocap reflected left for right
## (each side's bones take the other side's turn, reflected across the
## body's mid plane), so lefties are an exact mirror.
## `yaw` (degrees) turns the whole capture about the vertical first: the
## batting captures face about 87 degrees off the way the players' clips
## are built (chest to the plate), the pitching and catching ones don't.
static func bake(name: String, target: Skeleton3D, from: float = 0.0, to: float = -1.0, loop: bool = false, mirror: bool = false, yaw: float = 0.0) -> Animation:
	var spin := Quaternion(Vector3.UP, deg_to_rad(yaw))
	var path := DIR + name + ".fbx"
	if not ResourceLoader.exists(path):
		return null
	var scene: Node = (load(path) as PackedScene).instantiate()
	var src: Skeleton3D = scene.find_children("*", "Skeleton3D", true, false)[0]
	var player: AnimationPlayer = scene.find_children("*", "AnimationPlayer", true, false)[0]
	var clip := player.get_animation(player.get_animation_list()[0])
	if to < 0.0:
		to = clip.length
	var bones := _pairs(src, target, mirror)
	var anim := Animation.new()
	anim.length = to - from
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var tracks := {}
	for t: int in bones:
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, NodePath("%s:%s" % [PoseBaker.SKELETON_PATH, target.get_bone_name(t)]))
		tracks[t] = tr
	var pelvis := target.find_bone("pelvis")
	var pos := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos, NodePath("%s:pelvis" % PoseBaker.SKELETON_PATH))
	var hips := src.find_bone("mixamorig_Hips")
	var scale := target.get_bone_global_rest(pelvis).origin.y / maxf(src.get_bone_global_rest(hips).origin.y, 0.001)
	var frames := int(ceil(anim.length * FPS))
	var arms := _arm_chains(src, target, mirror)
	for f in frames + 1:
		var t := minf(from + f / FPS, to)
		_sample(clip, src, t)
		var src_g := _globals(src)
		var globals := {}
		for i in target.get_bone_count():
			var parent := target.get_bone_parent(i)
			var parent_g: Quaternion = globals[parent] if parent >= 0 else Quaternion()
			var g: Quaternion
			if bones.has(i):
				var pair: Array = bones[i]
				var s: int = pair[0]
				var turn := (src_g[s] as Transform3D).basis.get_rotation_quaternion() * src.get_bone_global_rest(s).basis.get_rotation_quaternion().inverse()
				turn = spin * turn
				if mirror:
					# Reflected across the X = 0 plane.
					turn = Quaternion(turn.x, -turn.y, -turn.z, turn.w)
				g = (turn * (pair[1] as Quaternion)).normalized()
			else:
				g = parent_g * target.get_bone_rest(i).basis.get_rotation_quaternion()
			globals[i] = g
		var moved := spin * (((src_g[hips] as Transform3D).origin - src.get_bone_global_rest(hips).origin) * scale)
		if mirror:
			moved.x = -moved.x
		var root_g := target.get_bone_global_rest(target.get_bone_parent(pelvis))
		var pelvis_local := root_g.affine_inverse() * (target.get_bone_global_rest(pelvis).origin + moved)
		# Hands where the performer's are (from his shoulders, scaled to
		# our arms): copied joint turns alone put them apart, the players'
		# shoulders being wider and higher than his.
		_place_hands(target, src, src_g, globals, pelvis, pelvis_local, arms, spin, mirror)
		for i: int in tracks:
			var parent := target.get_bone_parent(i)
			var parent_g: Quaternion = globals[parent] if parent >= 0 else Quaternion()
			anim.rotation_track_insert_key(tracks[i], f / FPS, (parent_g.inverse() * (globals[i] as Quaternion)).normalized())
		anim.position_track_insert_key(pos, f / FPS, pelvis_local)
	scene.free()
	return anim


## Each side's arm: [target upperarm, lowerarm, hand, source shoulder,
## source wrist, our arm length / the performer's, the bones below the
## hand] (mirrored: the source's other side).
static func _arm_chains(src: Skeleton3D, target: Skeleton3D, mirror: bool) -> Array:
	var out := []
	for side: String in ["l", "r"]:
		var src_side := ("Right" if side == "l" else "Left") if mirror else ("Left" if side == "l" else "Right")
		var up := target.find_bone("upperarm_" + side)
		var lo := target.find_bone("lowerarm_" + side)
		var hand := target.find_bone("hand_" + side)
		var s_up := src.find_bone("mixamorig_%sArm" % src_side)
		var s_lo := src.find_bone("mixamorig_%sForeArm" % src_side)
		var s_hand := src.find_bone("mixamorig_%sHand" % src_side)
		if up < 0 or lo < 0 or hand < 0 or s_up < 0 or s_hand < 0:
			continue
		var ours := target.get_bone_global_rest(up).origin.distance_to(target.get_bone_global_rest(lo).origin) + target.get_bone_global_rest(lo).origin.distance_to(target.get_bone_global_rest(hand).origin)
		var his := src.get_bone_global_rest(s_up).origin.distance_to(src.get_bone_global_rest(s_lo).origin) + src.get_bone_global_rest(s_lo).origin.distance_to(src.get_bone_global_rest(s_hand).origin)
		var below := []
		for i in target.get_bone_count():
			var p := target.get_bone_parent(i)
			while p >= 0 and p != hand:
				p = target.get_bone_parent(p)
			if p == hand:
				below.append(i)
		out.append([up, lo, hand, s_up, s_hand, ours / maxf(his, 0.0001), below])
	return out


## Global positions of every bone from global turns (rests' offsets), the
## pelvis at its keyed spot.
static func _positions(target: Skeleton3D, globals: Dictionary, pelvis: int, pelvis_local: Vector3) -> Dictionary:
	var out := {}
	for i in target.get_bone_count():
		var parent := target.get_bone_parent(i)
		var offset := pelvis_local if i == pelvis else target.get_bone_rest(i).origin
		if parent < 0:
			out[i] = offset
		else:
			out[i] = (out[parent] as Vector3) + (globals[parent] as Quaternion) * offset
	return out


## Reaches each arm (two-bone, elbow on the side the copied turns put it)
## so its wrist sits where the performer's does relative to his shoulders'
## midpoint, scaled to our arms; the hand keeps its captured turn.
static func _place_hands(target: Skeleton3D, src: Skeleton3D, src_g: Dictionary, globals: Dictionary, pelvis: int, pelvis_local: Vector3, arms: Array, spin: Quaternion, mirror: bool) -> void:
	if arms.size() < 2:
		return
	var p := _positions(target, globals, pelvis, pelvis_local)
	var ours_mid := ((p[arms[0][0]] as Vector3) + (p[arms[1][0]] as Vector3)) * 0.5
	var his_mid := ((src_g[arms[0][3]] as Transform3D).origin + (src_g[arms[1][3]] as Transform3D).origin) * 0.5
	for arm: Array in arms:
		var v := spin * ((src_g[arm[4]] as Transform3D).origin - his_mid)
		if mirror:
			v.x = -v.x
		_reach(target, globals, p, arm, ours_mid + v * float(arm[5]))


## One arm reaching its wrist to `goal` (two-bone; see _place_hands); the
## hand keeps its turn, the forearm takes most of its roll.
static func _reach(target: Skeleton3D, globals: Dictionary, p: Dictionary, arm: Array, goal: Vector3) -> void:
	var up: int = arm[0]
	var lo: int = arm[1]
	var hand: int = arm[2]
	var s: Vector3 = p[up]
	var e: Vector3 = p[lo]
	var w: Vector3 = p[hand]
	var a := s.distance_to(e)
	var b := e.distance_to(w)
	var to_goal := goal - s
	var d := clampf(to_goal.length(), absf(a - b) + 0.001, a + b - 0.001)
	var dir := to_goal.normalized()
	var wrist := s + dir * d
	var hand_g: Quaternion = globals[hand]
	# Where the performer's forearm ran into this hand (its captured bend
	# undone): put the elbow as near the end of such a forearm as the
	# arm allows, so the hand (which keeps its captured turn: both hands
	# stay on one bat) sits at the end of a forearm aimed at it.
	var bone_axis := target.get_bone_rest(hand).origin.normalized()
	var wrist_local := (globals[lo] as Quaternion).inverse() * hand_g
	var fore_wanted := (hand_g * wrist_local.inverse()) * bone_axis
	var want_elbow := wrist - fore_wanted.normalized() * b
	var pole := (want_elbow - s) - dir * (want_elbow - s).dot(dir)
	if pole.length() < 0.001:
		pole = (e - s) - dir * (e - s).dot(dir)
	if pole.length() < 0.001:
		pole = Vector3.DOWN - dir * Vector3.DOWN.dot(dir)
	pole = pole.normalized()
	var along := (a * a - b * b + d * d) / (2.0 * d)
	var elbow := s + dir * along + pole * sqrt(maxf(a * a - along * along, 0.0))
	var r1 := Quaternion((e - s).normalized(), (elbow - s).normalized())
	globals[up] = (r1 * (globals[up] as Quaternion)).normalized()
	var lower_g := (r1 * (globals[lo] as Quaternion)).normalized()
	var fore_now := (r1 * (w - e)).normalized()
	var r2 := Quaternion(fore_now, (wrist - elbow).normalized())
	lower_g = (r2 * lower_g).normalized()
	# The forearm turns the palm (pronation), not the wrist: the capture
	# rig puts that turn on the hand bone, which on the players' mesh
	# wrings the wrist. Most of the hand's roll about the forearm goes
	# to the forearm (turning about its own length, so the wrist stays
	# put); the hand's world turn is unchanged by it.
	var roll := MixamoRetarget._twist_about(lower_g.inverse() * hand_g, bone_axis)
	lower_g = (lower_g * Quaternion.IDENTITY.slerp(roll, FOREARM_ROLL)).normalized()
	globals[lo] = lower_g
	globals[hand] = hand_g


## The part of rotation q that turns about `axis` (swing-twist split).
static func _twist_about(q: Quaternion, axis: Vector3) -> Quaternion:
	var v := Vector3(q.x, q.y, q.z)
	var p := axis * v.dot(axis)
	var t := Quaternion(p.x, p.y, p.z, q.w)
	if t.length_squared() < 1e-9:
		return Quaternion()
	return t.normalized()


## Target bone -> [source bone, rest alignment * target global rest].
static func _pairs(src: Skeleton3D, target: Skeleton3D, mirror: bool = false) -> Dictionary:
	var out := {}
	for t_name: String in MAP:
		var t := target.find_bone(t_name)
		var s_name := String(MAP[t_name])
		if mirror:
			s_name = s_name.replace("Left", "@").replace("Right", "Left").replace("@", "Right")
		var s := src.find_bone("mixamorig_" + s_name)
		if t < 0 or s < 0:
			continue
		var align := Quaternion()
		var t_child := _child(target, t)
		var s_child := _child(src, s)
		if t_child >= 0 and s_child >= 0 and not t_name in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head"]:
			var dt := target.get_bone_global_rest(t_child).origin - target.get_bone_global_rest(t).origin
			var ds := src.get_bone_global_rest(s_child).origin - src.get_bone_global_rest(s).origin
			if mirror:
				ds.x = -ds.x
			if dt.length() > 0.0001 and ds.length() > 0.0001:
				align = Quaternion(dt.normalized(), ds.normalized())
		out[t] = [s, (align * target.get_bone_global_rest(t).basis.get_rotation_quaternion()).normalized()]
	return out


## A bone's main child (the one the limb runs to), or -1.
static func _child(sk: Skeleton3D, bone: int) -> int:
	var kids := sk.get_bone_children(bone)
	if kids.is_empty():
		return -1
	var name := sk.get_bone_name(bone).to_lower()
	for k in kids:
		var kn := sk.get_bone_name(k).to_lower()
		# Hands run to the middle finger; skip thumbs and side digits.
		if name.contains("hand") and (kn.contains("middle")):
			return k
	return kids[0]


## Every bone's global pose from the local poses (the source skeleton is
## not in the scene tree, so it doesn't keep its own up to date).
static func _globals(sk: Skeleton3D) -> Dictionary:
	var out := {}
	for i in sk.get_bone_count():
		var local := sk.get_bone_pose(i)
		var parent := sk.get_bone_parent(i)
		out[i] = (out[parent] as Transform3D) * local if parent >= 0 else local
	return out


## Poses the source skeleton at time t of the clip.
static func _sample(clip: Animation, src: Skeleton3D, t: float) -> void:
	for tr in clip.get_track_count():
		var bone := src.find_bone(String(clip.track_get_path(tr).get_concatenated_subnames()))
		if bone < 0:
			continue
		match clip.track_get_type(tr):
			Animation.TYPE_ROTATION_3D:
				src.set_bone_pose_rotation(bone, clip.rotation_track_interpolate(tr, t))
			Animation.TYPE_POSITION_3D:
				src.set_bone_pose_position(bone, clip.position_track_interpolate(tr, t))
			Animation.TYPE_SCALE_3D:
				src.set_bone_pose_scale(bone, clip.scale_track_interpolate(tr, t))
