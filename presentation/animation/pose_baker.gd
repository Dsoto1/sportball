class_name PoseBaker
extends RefCounted
## Turns poses written in body terms into keyframed Animations on the
## mannequin skeleton. A pose says where the hands and feet go and how the
## hips, chest and head turn; two-bone IK places elbows and knees, and the
## result is stored as ordinary bone rotation tracks. Purely visual.
##
## Body space is skeleton space seen from the player: P(right, up, forward)
## in meters, mannequin size (pelvis 0.92 m, shoulders 1.44 m). Angles are
## degrees as Vector3(pitch, yaw, roll): + pitch leans forward, + yaw turns
## left (counterclockwise from above), + roll tips toward the right.
##
## Pose keys (all optional):
##   hips, chest, head: Vector3 angles. hips is body space; chest turns
##     relative to the hips (spread over the three spine bones); head turns
##     relative to the chest.
##   drop: float, meters the pelvis sinks. shift: P offset of the pelvis.
##   hand_l, hand_r, foot_l, foot_r: P targets (wrist / ankle).
##   elbow_l, elbow_r, knee_l, knee_r: P pole directions for the bend.
##   toe_l, toe_r: float, foot yaw in degrees (default: follows the hips).

const SKELETON_PATH := "Armature/Skeleton3D"
const CHAINS := {
	"hand_l": ["upperarm_l", "lowerarm_l", "hand_l", "elbow_l"],
	"hand_r": ["upperarm_r", "lowerarm_r", "hand_r", "elbow_r"],
	"foot_l": ["thigh_l", "calf_l", "foot_l", "knee_l"],
	"foot_r": ["thigh_r", "calf_r", "foot_r", "knee_r"],
}
const SPINE := ["spine_01", "spine_02", "spine_03"]
## Bones every baked clip keys; the rest of the rig follows its parents.
const BODY_BONES := ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head",
	"clavicle_l", "upperarm_l", "lowerarm_l", "hand_l", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r",
	"thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r"]

var _skeleton: Skeleton3D
var _rest_local: Array[Transform3D] = []
var _rest_global: Array[Transform3D] = []
## Curled fingers (a fist), sampled from a library clip: {bone: Quaternion}.
var _fist := {}


func _init(skeleton: Skeleton3D, fist_source: Animation = null) -> void:
	_skeleton = skeleton
	for i in skeleton.get_bone_count():
		_rest_local.append(skeleton.get_bone_rest(i))
		_rest_global.append(skeleton.get_bone_global_rest(i))
	if fist_source != null:
		for t in fist_source.get_track_count():
			if fist_source.track_get_type(t) != Animation.TYPE_ROTATION_3D:
				continue
			var bone := String(fist_source.track_get_path(t).get_subname(0))
			if BODY_BONES.has(bone) or _skeleton.find_bone(bone) < 0:
				continue
			_fist[bone] = fist_source.rotation_track_interpolate(t, 0.0)


static func P(right: float, up: float, forward: float) -> Vector3:
	return Vector3(-right, up, forward)


## The same pose for the other hand: left and right swapped.
static func mirror(pose: Dictionary) -> Dictionary:
	var out := {}
	for key: String in pose:
		var value: Variant = pose[key]
		var name := key
		if key.ends_with("_l"):
			name = key.trim_suffix("_l") + "_r"
		elif key.ends_with("_r"):
			name = key.trim_suffix("_r") + "_l"
		if value is Vector3:
			var v: Vector3 = value
			# Positions flip across the body; angles keep pitch, flip yaw/roll.
			value = Vector3(v.x, -v.y, -v.z) if key in ["hips", "chest", "head"] else Vector3(-v.x, v.y, v.z)
		elif key.begins_with("toe"):
			value = -float(value)
		out[name] = value
	return out


## Bone-local rotations (and the pelvis position) for one pose.
func solve(pose: Dictionary) -> Dictionary:
	var hips := _euler(pose.get("hips", Vector3.ZERO))
	var chest := _euler(pose.get("chest", Vector3.ZERO))
	var head := _euler(pose.get("head", Vector3.ZERO))
	var targets := {}  # bone -> wanted direction (body space)
	var global := {}
	var out := {}
	# Torso first, so the shoulders are known before the arms are solved.
	for bone: String in BODY_BONES:
		var i := _skeleton.find_bone(bone)
		var parent := _skeleton.get_bone_parent(i)
		var parent_g: Transform3D = global.get(_skeleton.get_bone_name(parent), _rest_global[parent]) if parent >= 0 else Transform3D.IDENTITY
		var g := parent_g * _rest_local[i]
		match bone:
			"pelvis":
				g.basis = Basis(hips) * _rest_global[i].basis
				g.origin = _rest_global[i].origin + Vector3(0.0, -float(pose.get("drop", 0.0)), 0.0) + pose.get("shift", Vector3.ZERO)
			"spine_01", "spine_02", "spine_03":
				var share := float(SPINE.find(bone) + 1) / SPINE.size()
				g.basis = Basis(hips * Quaternion.IDENTITY.slerp(chest, share)) * _rest_global[i].basis
			"neck_01":
				g.basis = Basis(hips * chest * Quaternion.IDENTITY.slerp(head, 0.4)) * _rest_global[i].basis
			"Head":
				g.basis = Basis(hips * chest * head) * _rest_global[i].basis
			"upperarm_l", "upperarm_r", "thigh_l", "thigh_r":
				var end := "hand" + bone.right(2) if bone.begins_with("upper") else "foot" + bone.right(2)
				if pose.has(end):
					_solve_chain(end, g.origin, pose, targets)
		if targets.has(bone):
			g.basis = _aim(g.basis, i, targets[bone])
		elif bone.begins_with("foot"):
			# Feet stay flat and point the way the hips face (or toe_*).
			var yaw := deg_to_rad(float(pose.get("toe" + bone.right(2), rad_to_deg(hips.get_euler(EULER_ORDER_YXZ).y))))
			g.basis = Basis(Vector3.UP, yaw) * _rest_global[i].basis
		elif bone.begins_with("hand"):
			# Hands carry on from the forearm.
			pass
		global[bone] = g
		var local := parent_g.affine_inverse() * g
		out[bone] = local.basis.get_rotation_quaternion()
		if bone == "pelvis":
			out["@pelvis_position"] = local.origin
	return out


## Bakes keyframes [[time, pose], ...] into an Animation.
func bake(keys: Array, loop: bool = false, length: float = -1.0) -> Animation:
	var anim := Animation.new()
	var solved: Array[Dictionary] = []
	for k: Array in keys:
		solved.append(solve(k[1]))
	anim.length = length if length > 0.0 else float(keys[keys.size() - 1][0])
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	var pos := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pos, NodePath("%s:pelvis" % SKELETON_PATH))
	for j in keys.size():
		anim.position_track_insert_key(pos, float(keys[j][0]), solved[j]["@pelvis_position"])
	for bone: String in BODY_BONES:
		var t := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, NodePath("%s:%s" % [SKELETON_PATH, bone]))
		anim.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
		for j in keys.size():
			anim.rotation_track_insert_key(t, float(keys[j][0]), solved[j][bone])
	for bone: String in _fist:
		var t := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, NodePath("%s:%s" % [SKELETON_PATH, bone]))
		anim.rotation_track_insert_key(t, 0.0, _fist[bone])
	return anim


## Two-bone IK: picks directions for the upper and lower bone so the end
## (wrist or ankle) lands on the target, bending toward the pole.
func _solve_chain(end: String, root: Vector3, pose: Dictionary, targets: Dictionary) -> void:
	var chain: Array = CHAINS[end]
	var upper := _skeleton.find_bone(chain[0])
	var lower := _skeleton.find_bone(chain[1])
	var tip := _skeleton.find_bone(chain[2])
	var a := _rest_global[upper].origin.distance_to(_rest_global[lower].origin)
	var b := _rest_global[lower].origin.distance_to(_rest_global[tip].origin)
	var to: Vector3 = pose[end] - root
	var d := clampf(to.length(), absf(a - b) + 0.01, a + b - 0.001)
	var n := to.normalized()
	var default_pole := P(0, -1, 0.3) if end.begins_with("hand") else P(0, 0, 1)
	var pole: Vector3 = pose.get(chain[3], default_pole)
	var m := (pole - n * pole.dot(n))
	if m.length() < 0.001:
		m = n.cross(Vector3.RIGHT).cross(n)
	m = m.normalized()
	var cos_a := clampf((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var elbow := root + a * (cos_a * n + sqrt(1.0 - cos_a * cos_a) * m)
	targets[chain[0]] = (elbow - root).normalized()
	targets[chain[1]] = (root + n * d - elbow).normalized()


## Rotates a bone's global basis so it points along dir (shortest arc).
func _aim(basis: Basis, bone: int, dir: Vector3) -> Basis:
	var child := -1
	for c in _skeleton.get_bone_children(bone):
		child = c
		break
	if child < 0:
		return basis
	var along := (basis * _rest_local[child].origin).normalized()
	if along.dot(dir) > 0.99999:
		return basis
	return Basis(Quaternion(along, dir.normalized())) * basis


static func _euler(deg: Vector3) -> Quaternion:
	return Quaternion.from_euler(Vector3(deg_to_rad(deg.x), deg_to_rad(deg.y), deg_to_rad(deg.z)))
