extends TestCase
## The baked baseball moves: IK puts hands and feet where a pose says,
## mirroring swaps sides, and every move (and its lefty copy) is baked.

const BODY := preload("res://assets/third_party/quaternius/universal-animation-library/UAL1_Standard.glb")


func _rig() -> Node3D:
	return BODY.instantiate()


## Forward kinematics of a solved pose: skeleton-space bone positions.
func _posed(model: Node3D, pose: Dictionary) -> Dictionary:
	var sk := model.find_child("Skeleton3D") as Skeleton3D
	var solved := PoseBaker.new(sk).solve(pose)
	var global := {}
	for bone: String in PoseBaker.BODY_BONES:
		var i := sk.find_bone(bone)
		var origin: Vector3 = solved["@pelvis_position"] if bone == "pelvis" else sk.get_bone_rest(i).origin
		var local := Transform3D(Basis(solved[bone] as Quaternion), origin)
		var parent := sk.get_bone_name(sk.get_bone_parent(i))
		global[bone] = (global[parent] as Transform3D) * local if global.has(parent) else sk.get_bone_global_rest(sk.get_bone_parent(i)) * local
	return global


func test_ik_reaches_hand_and_foot_targets() -> void:
	var model := _rig()
	for pose: Dictionary in [BaseballMoves.STANCE, BaseballMoves.READY, BaseballMoves.CATCHER]:
		var bones := _posed(model, pose)
		for end in ["hand_l", "hand_r", "foot_l", "foot_r"]:
			var at := (bones[end] as Transform3D).origin
			check(at.distance_to(pose[end]) < 0.03, "%s lands on its target (%.3f m off)" % [end, at.distance_to(pose[end])])
	model.free()


func test_mirror_swaps_sides() -> void:
	var m := PoseBaker.mirror({"hand_r": PoseBaker.P(0.2, 1.4, 0.1), "hips": Vector3(5, 30, 10), "toe_l": 20.0})
	check(m.has("hand_l") and not m.has("hand_r"), "right hand becomes left")
	check_eq(m["hand_l"], PoseBaker.P(-0.2, 1.4, 0.1), "position flips across the body")
	check_eq(m["hips"], Vector3(5, -30, -10), "turns flip, lean stays")
	check_eq(m["toe_r"], -20.0, "foot turn flips")


func test_every_move_is_baked_for_both_hands() -> void:
	var model := _rig()
	var player := model.find_child("AnimationPlayer") as AnimationPlayer
	var lib := BaseballMoves.library(model.find_child("Skeleton3D") as Skeleton3D, player)
	for move: String in BaseballMoves.MOVES:
		check(lib.has_animation(StringName(move)), "%s baked" % move)
		check(lib.has_animation(StringName(move + "_L")), "%s lefty copy baked" % move)
	check_eq(lib.get_animation(&"Pitch").length, BaseballMoves.PITCH_LENGTH, "pitch runs through its follow-through")
	check(lib.get_animation(&"Stance").loop_mode == Animation.LOOP_LINEAR, "the stance loops")
	model.free()
