class_name BodyDouble
extends SkeletonModifier3D
## A character rigged on its own skeleton (the owner's Meshy models: a
## different bone set, rest pose and proportions) worn by a player. It
## sits on the player's skeleton after the animation and the IK, and every
## frame turns each of the body's bones the way its twin on the player's
## skeleton has turned from rest. Limbs are first lined up with the
## player's rest pose (the robot's T-pose arms hang a little lower and its
## legs stand wider), the hips follow the pelvis, scaled to the body's own
## leg length, and every bone keeps its own length, so the body keeps its
## proportions and its feet land on the ground. Presentation only.

## The robot player (Meshy image-to-3D, rigged by Meshy).
const ROBOT := "res://assets/generated/meshy/robot_player/robot_player.glb"

## Body bone -> player (Quaternius UAL) bone.
const MAP := {
	"Hips": "pelvis", "Spine02": "spine_01", "Spine01": "spine_02", "Spine": "spine_03",
	"neck": "neck_01", "Head": "Head",
	"LeftShoulder": "clavicle_l", "LeftArm": "upperarm_l", "LeftForeArm": "lowerarm_l", "LeftHand": "hand_l",
	"RightShoulder": "clavicle_r", "RightArm": "upperarm_r", "RightForeArm": "lowerarm_r", "RightHand": "hand_r",
	"LeftUpLeg": "thigh_l", "LeftLeg": "calf_l", "LeftFoot": "foot_l", "LeftToeBase": "ball_l",
	"RightUpLeg": "thigh_r", "RightLeg": "calf_r", "RightFoot": "foot_r", "RightToeBase": "ball_r",
}
## Limb bones lined up with the player's rest: the segment each is
## measured along, [body from, body to, player from, player to]. Hands and
## toes line up as their forearm and foot do; the torso keeps its rest.
const ALIGN := {
	"LeftArm": ["LeftArm", "LeftForeArm", "upperarm_l", "lowerarm_l"],
	"LeftForeArm": ["LeftForeArm", "LeftHand", "lowerarm_l", "hand_l"],
	"LeftHand": ["LeftForeArm", "LeftHand", "lowerarm_l", "hand_l"],
	"RightArm": ["RightArm", "RightForeArm", "upperarm_r", "lowerarm_r"],
	"RightForeArm": ["RightForeArm", "RightHand", "lowerarm_r", "hand_r"],
	"RightHand": ["RightForeArm", "RightHand", "lowerarm_r", "hand_r"],
	"LeftUpLeg": ["LeftUpLeg", "LeftLeg", "thigh_l", "calf_l"],
	"LeftLeg": ["LeftLeg", "LeftFoot", "calf_l", "foot_l"],
	"LeftFoot": ["LeftFoot", "LeftToeBase", "foot_l", "ball_l"],
	"LeftToeBase": ["LeftFoot", "LeftToeBase", "foot_l", "ball_l"],
	"RightUpLeg": ["RightUpLeg", "RightLeg", "thigh_r", "calf_r"],
	"RightLeg": ["RightLeg", "RightFoot", "calf_r", "foot_r"],
	"RightFoot": ["RightFoot", "RightToeBase", "foot_r", "ball_r"],
	"RightToeBase": ["RightFoot", "RightToeBase", "foot_r", "ball_r"],
}

## The body's own scene root and skeleton.
var body: Node3D
var target: Skeleton3D
# Per mapped bone, parents before children: body index, player index,
# body parent index (-1 at the root), and the rest rotation to apply
# after the player's turn (alignment * body rest).
var _bones: Array = []
var _hips := -1
var _pelvis := -1
var _hips_rest := Vector3.ZERO
var _pelvis_rest := Vector3.ZERO
## Player skeleton meters -> body skeleton units, and the hips' lift so
## the body's straightened legs reach the ground.
var _scale := 1.0
var _lift := 0.0
# Scratch: each body bone's turn in skeleton space this frame.
var _global: Array[Quaternion] = []


## A body of `kind` (&"robot") to wear on `source`, or null if unknown.
static func make(kind: StringName, source: Skeleton3D) -> BodyDouble:
	if kind != &"robot" or not ResourceLoader.exists(ROBOT):
		return null
	var double := BodyDouble.new()
	double.name = "BodyDouble"
	double.body = (load(ROBOT) as PackedScene).instantiate()
	double.target = double.body.find_children("*", "Skeleton3D", true, false)[0]
	# The model's own clips stay off; the player's skeleton drives it.
	for player: AnimationPlayer in double.body.find_children("*", "AnimationPlayer", true, false):
		player.stop()
		player.autoplay = ""
	double._bind(source)
	return double


func _bind(source: Skeleton3D) -> void:
	var order: Array = []
	for i in target.get_bone_count():
		order.append(i)
	# Parents before children (bone indices already are in a glTF import,
	# but sort by depth to be safe).
	order.sort_custom(func(a: int, b: int) -> bool: return _depth(a) < _depth(b))
	_global.resize(target.get_bone_count())
	for i: int in order:
		var name := target.get_bone_name(i)
		if not MAP.has(name):
			continue
		var j := source.find_bone(MAP[name])
		if j < 0:
			continue
		var align := Quaternion()
		if ALIGN.has(name):
			var seg: Array = ALIGN[name]
			var d_body := _pos(target, seg[1]) - _pos(target, seg[0])
			var d_player := _pos(source, seg[3]) - _pos(source, seg[2])
			if d_body.length() > 0.0 and d_player.length() > 0.0:
				align = Quaternion(d_body.normalized(), d_player.normalized())
		var body_rest := target.get_bone_global_rest(i).basis.get_rotation_quaternion()
		var player_rest := source.get_bone_global_rest(j).basis.get_rotation_quaternion()
		_bones.append([i, j, target.get_bone_parent(i), player_rest.inverse(), align * body_rest])
	_hips = target.find_bone("Hips")
	_pelvis = source.find_bone("pelvis")
	_hips_rest = target.get_bone_global_rest(_hips).origin
	_pelvis_rest = source.get_bone_global_rest(_pelvis).origin
	# Hip height with the legs straightened under it, in both skeletons.
	var body_leg := (_pos(target, "LeftLeg") - _pos(target, "LeftUpLeg")).length() + (_pos(target, "LeftFoot") - _pos(target, "LeftLeg")).length() + _pos(target, "LeftFoot").y
	var body_hip := body_leg + (_hips_rest.y - _pos(target, "LeftUpLeg").y)
	var player_hip := _pelvis_rest.y
	_scale = body_hip / player_hip
	_lift = body_hip - _hips_rest.y


func _depth(i: int) -> int:
	var d := 0
	var p := target.get_bone_parent(i)
	while p >= 0:
		d += 1
		p = target.get_bone_parent(p)
	return d


static func _pos(skeleton: Skeleton3D, bone: String) -> Vector3:
	return skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin


func _process_modification() -> void:
	var source := get_skeleton()
	if source == null or target == null or not body.visible:
		return
	for entry: Array in _bones:
		var i: int = entry[0]
		var turn := source.get_bone_global_pose(entry[1]).basis.get_rotation_quaternion() * (entry[3] as Quaternion)
		var global: Quaternion = turn * (entry[4] as Quaternion)
		_global[i] = global
		var parent: int = entry[2]
		var parent_global := _global[parent] if parent >= 0 else Quaternion()
		target.set_bone_pose_rotation(i, (parent_global.inverse() * global).normalized())
	# The hips ride with the pelvis (its rest offset scaled to the body).
	var moved := source.get_bone_global_pose(_pelvis).origin - _pelvis_rest
	target.set_bone_pose_position(_hips, _hips_rest + Vector3(0, _lift, 0) + moved * _scale)
