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


func test_uniform_regions_follow_the_body() -> void:
	check_eq(UniformLook.region_for("Head", Vector3(0, 1.7, 0)), UniformLook.Region.SKIN, "head is skin")
	check_eq(UniformLook.region_for("spine_02", Vector3(0, 1.2, 0)), UniformLook.Region.JERSEY, "chest is jersey")
	check_eq(UniformLook.region_for("pelvis", Vector3(0, 0.96, 0)), UniformLook.Region.BELT, "belt at the waist")
	check_eq(UniformLook.region_for("thigh_l", Vector3(0.1, 0.7, 0)), UniformLook.Region.PANTS, "thighs in pants")
	check_eq(UniformLook.region_for("calf_r", Vector3(-0.1, 0.2, 0)), UniformLook.Region.SOCKS, "socks below the knee")
	check_eq(UniformLook.region_for("foot_l", Vector3(0.1, 0.05, 0)), UniformLook.Region.CLEATS, "cleats")
	check_eq(UniformLook.region_for("upperarm_r", Vector3(-0.25, 1.44, 0)), UniformLook.Region.JERSEY, "sleeve")
	check_eq(UniformLook.region_for("lowerarm_r", Vector3(-0.6, 1.44, 0)), UniformLook.Region.SKIN, "bare forearm")
	check_eq(UniformLook.region_for("index_02_l", Vector3(0.8, 1.44, 0)), UniformLook.Region.HANDS, "hands")


func test_every_pitch_has_a_spin() -> void:
	for family: PitchFamilyDef in content().pitches:
		var spin := PitchSpin.for_family(family)
		check_near((spin[0] as Vector3).length(), 1.0, 0.001, "%s spin axis is a direction" % family.id)
		check(float(spin[1]) > 0.0 and float(spin[1]) < 70.0, "%s spins at a readable rate" % family.id)
	check(float(PitchSpin.BY_FAMILY[&"junkball"][1]) < 5.0, "the knuckler barely turns over")


func test_every_batting_style_is_baked() -> void:
	var model := _rig()
	var lib := BaseballMoves.library(model.find_child("Skeleton3D") as Skeleton3D, model.find_child("AnimationPlayer") as AnimationPlayer)
	for style: StringName in BattingStyles.ORDER:
		for move in ["Stance_%s", "Approach_%s", "Swing_%s"]:
			check(lib.has_animation(StringName(move % style)), "%s baked" % (move % style))
			check(lib.has_animation(StringName((move % style) + "_L")), "%s lefty baked" % (move % style))
		check(BattingStyles.BAT.has(style), "%s has a bat setup" % style)
	model.free()


func test_the_barrel_is_square_at_contact() -> void:
	for style: StringName in BattingStyles.ORDER:
		var start := BattingStyles.approach_bat(style, 1.0, 0.0)
		var at := BattingStyles.swing_bat(style, BattingStyles.CONTACT_AT, start)
		var b: Dictionary = BattingStyles.BAT[style]
		check_near(at.x, float(b["attack_yaw"]), 0.5, "%s: barrel meets the ball on its attack direction" % style)
		check_near(at.y, float(b["attack_lift"]), 0.5, "%s: and at its attack angle" % style)
		check(absf(at.x) <= 15.0, "%s: still through the hitting zone, not around it" % style)
		var finish := BattingStyles.swing_bat(style, 1.0, start)
		check_eq(finish.x, float(BattingStyles.BAT[style]["finish_yaw"]), "%s: sweeps through to its finish" % style)
	check(MatchView.SWING_TIME * BattingStyles.CONTACT_AT < 0.08, "contact lands within 80 ms of the press")
	check(float(BattingStyles.BAT[&"slap"]["attack_yaw"]) > 5.0, "the slap goes the other way")
	check(float(BattingStyles.BAT[&"leg_kick"]["attack_lift"]) > float(BattingStyles.BAT[&"slap"]["attack_lift"]), "the slugger swings up, the slapper flat")


func test_styles_suit_the_hitter() -> void:
	var slugger := PlayerDef.new()
	slugger.id = &"x_slugger"
	slugger.power = 90
	check([&"leg_kick", &"wrap"].has(BattingStyles.for_player(slugger)), "sluggers load big")
	var slapper := PlayerDef.new()
	slapper.id = &"x_slapper"
	slapper.power = 35
	slapper.contact = 80
	slapper.speed = 85
	check([&"slap", &"open"].has(BattingStyles.for_player(slapper)), "quick contact hitters slap")
	slapper.batting_style = &"crouch"
	check_eq(BattingStyles.for_player(slapper), &"crouch", "a set style wins")


## BATTING_STYLE_SPEC.md's QA checklist, checked on every style's poses.
func test_styles_obey_the_batters_box() -> void:
	for style: StringName in BattingStyles.ORDER:
		var p := BattingStyles.poses(style)
		for key: String in p:
			var pose: Dictionary = p[key]
			for foot in ["foot_l", "foot_r"]:
				var at: Vector3 = pose.get(foot, BaseballMoves.STANCE[foot])
				# Body space: +Z toward the plate.
				check(at.z < BattingStyles.PLATE_CLEAR, "%s %s: %s stays off the plate" % [style, key, foot])
				check(absf(at.x) < 0.7, "%s %s: %s stays in the box" % [style, key, foot])
		# The rear foot is anchored through the load.
		check_eq(p["load"].get("foot_r", BaseballMoves.STANCE["foot_r"]), p["stance"].get("foot_r", BaseballMoves.STANCE["foot_r"]), "%s: rear foot anchored through the load" % style)
		# The lead foot strides toward the pitcher, not across the plate.
		var from: Vector3 = p["load"]["foot_l"]
		var to: Vector3 = p["stride"]["foot_l"]
		check(absf(to.z - from.z) <= 0.5 * absf(to.x - from.x) + 0.05, "%s: stride goes at the pitcher" % style)
		check(to.x > from.x - 0.001, "%s: stride lands toward the pitcher's side" % style)
	var stride := func(style: StringName) -> float:
		var p := BattingStyles.poses(style)
		return float(p["stride"]["foot_l"].x - p["stance"]["foot_l"].x)
	for style: StringName in BattingStyles.ORDER:
		if style != &"leg_kick":
			check(stride.call(&"leg_kick") > stride.call(style), "leg kick strides farther than %s" % style)
		if style != &"slap":
			check(stride.call(&"slap") < stride.call(style), "slap strides shorter than %s" % style)
	var crouch := BattingStyles.poses(&"crouch")
	var classic := BattingStyles.poses(&"classic")
	check(float(crouch["stance"]["drop"]) > float(classic["stance"]["drop"]), "the crouch sits lowest")
	check(float(crouch["finish"]["drop"]) > float(classic["finish"]["drop"]), "and finishes lower")
	check(BattingStyles.ONE_HAND_RELEASE > BattingStyles.CONTACT_AT, "a one-hand release only comes after contact")
	# The front side braces: the planted lead foot does not spin with the hips.
	for style: StringName in BattingStyles.ORDER:
		var p := BattingStyles.poses(style)
		for key in ["stride", "contact", "finish"]:
			var toe := float(p[key].get("toe_l", 999.0))
			check(toe >= 0.0 and toe <= 60.0, "%s %s: lead foot planted and braced (%.0f°)" % [style, key, toe])


## Every foot a style places is one the leg can reach (no hovering feet).
func test_style_feet_are_reachable() -> void:
	var model := _rig()
	for style: StringName in BattingStyles.ORDER:
		var p := BattingStyles.poses(style)
		for key: String in p:
			var pose: Dictionary = p[key]
			var bones := _posed(model, pose)
			for foot in ["foot_l", "foot_r"]:
				if not pose.has(foot):
					continue
				var at := (bones[foot] as Transform3D).origin
				check(at.distance_to(pose[foot]) < 0.03, "%s %s: %s reaches its spot (%.3f m off)" % [style, key, foot, at.distance_to(pose[foot])])
	model.free()
