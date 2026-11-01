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
static func bake(name: String, target: Skeleton3D, from: float = 0.0, to: float = -1.0, loop: bool = false, mirror: bool = false) -> Animation:
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
				if mirror:
					# Reflected across the X = 0 plane.
					turn = Quaternion(turn.x, -turn.y, -turn.z, turn.w)
				g = (turn * (pair[1] as Quaternion)).normalized()
				anim.rotation_track_insert_key(tracks[i], f / FPS, (parent_g.inverse() * g).normalized())
			else:
				g = parent_g * target.get_bone_rest(i).basis.get_rotation_quaternion()
			globals[i] = g
		var moved := ((src_g[hips] as Transform3D).origin - src.get_bone_global_rest(hips).origin) * scale
		if mirror:
			moved.x = -moved.x
		var root_g := target.get_bone_global_rest(target.get_bone_parent(pelvis))
		anim.position_track_insert_key(pos, f / FPS, root_g.affine_inverse() * (target.get_bone_global_rest(pelvis).origin + moved))
	scene.free()
	return anim


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
