class_name ActorView
extends Node3D
## A player's body: the Quaternius mannequin (CC0, Universal Animation
## Library) in team colors. Baseball moves (stance, swing, bunt, pitch,
## throw, ready, scoop, high catch, dive, tag, lead, slide) are the game's
## own, baked by BaseballMoves; runs and celebrations come from the library.
## Gameplay decides where everyone is; this only picks a clip per pose,
## matches run cycles to speed and keeps the glove on the hand. Visual only.

enum Pose { IDLE, RUN, TURN, CHASE, TAG, THROW, DOWN, SLIDE, BAT_STANCE, SWING, CELEBRATE, BUNT, PITCH, SCOOP, CATCH_HIGH, DIVE, LEAD, APPROACH, FINISH }

const BODY := preload("res://assets/third_party/quaternius/universal-animation-library/UAL1_Standard.glb")
## The player's body: Quaternius Universal Base Characters (CC0), on the
## same skeleton as the animation library, with a buzz cut and, for some, a
## beard.
const BASE_DIR := "res://assets/third_party/quaternius/universal-base-characters/"
const BASE_BODY := preload(BASE_DIR + "Superhero_Male_FullBody.gltf")
const HAIR := preload(BASE_DIR + "Hair_Buzzed.gltf")
const BEARD := preload(BASE_DIR + "Hair_Beard.gltf")
const SKIN_TEX := preload(BASE_DIR + "T_Superhero_Male_Light.png")
const SKIN_NORMAL := preload(BASE_DIR + "T_Superhero_Male_Normal.png")
## Share of players with a beard.
const BEARD_SHARE := 0.35
## Fielder's glove (Artlist AI, see the asset manifest): fingers along +Y,
## wrist at y = -0.95, about 1.9 units tall.
const GLOVE := preload("res://assets/generated/artlist/glove/glove.glb")
const GLOVE_SCALE := 0.15
const BACK_FONT := preload("res://assets/third_party/fonts/bungee/Bungee-Regular.ttf")
## Rest-pose (skeleton space, m) spots: the number between the shoulder
## blades, the crown of the head. +X is the body's left, +Z its front.
const BACK_NUMBER_AT := Vector3(0.0, 1.3, -0.175)
const CROWN := Vector3(0.0, 1.68, 0.0)
const BLEND := 0.12
## Arcade proportions: a little broader and bigger than life, so players
## read from the high field camera (the base character is already athletic).
const BUILD := Vector3(1.15, 1.08, 1.15)
## Ground speed (m/s) the jog and sprint cycles are animated at.
## Moves that play once and hold their last frame, by pose.
const ONE_SHOTS := {Pose.TAG: "Tag", Pose.SLIDE: "Slide", Pose.SCOOP: "Scoop", Pose.CATCH_HIGH: "Catch_High", Pose.DIVE: "Dive"}
const JOG_SPEED := 3.6
const SPRINT_SPEED := 7.2

var _model: Node3D
var _player: AnimationPlayer
var _mesh: MeshInstance3D
## Glove hand (left for a righty).
var _hand: BoneAttachment3D
var _glove: Node3D
## Throwing hand (right for a righty): holds the bat's handle and the ball.
var _grip: BoneAttachment3D
var _lefty := false
var _kit: ShaderMaterial
var _hair: MeshInstance3D
var _beard: MeshInstance3D
var _skeleton: Skeleton3D
## Batting helmet (with ear flap) for batters and runners, cap for fielders.
var _helmet: Node3D
var _cap: Node3D
var _back: Label3D
var _grip_ik: BatGrip
## How this batter stands and swings (BattingStyles).
var style: StringName = &"classic"
var _twist := 0.0
var _tag: Label3D
var _clock := 0.0
var _sway := 0.0
var _crouched := false
var _pose := -1
var _clip := &""


func setup(color: Color, tag: String) -> void:
	_model = BODY.instantiate()
	_model.name = "Body"
	# The mannequin faces +Z; actors face -Z (look_at), so turn it around.
	_model.rotation.y = PI
	_model.scale = BUILD
	add_child(_model)
	_player = _model.find_child("AnimationPlayer") as AnimationPlayer
	var skeleton := _model.find_child("Skeleton3D") as Skeleton3D
	_skeleton = skeleton
	# The library's mannequin only lends its skeleton and clips; the base
	# character's body (same bones) is worn on it.
	(_model.find_child("Mannequin") as MeshInstance3D).visible = false
	_mesh = _wear(skeleton, BASE_BODY, "SuperHero_Male")
	_mesh.mesh = UniformLook.mesh_for(_mesh)
	_kit = UniformLook.material()
	_kit.set_shader_parameter("textured_skin", true)
	_kit.set_shader_parameter("skin_tex", SKIN_TEX)
	_kit.set_shader_parameter("skin_normal", SKIN_NORMAL)
	_mesh.material_override = _kit
	_hair = _wear(skeleton, HAIR, "")
	_beard = _wear(skeleton, BEARD, "")
	_player.add_animation_library(BaseballMoves.LIBRARY, BaseballMoves.library(skeleton, _player))
	var attach := BoneAttachment3D.new()
	attach.bone_name = "hand_l"
	skeleton.add_child(attach)
	_glove = GLOVE.instantiate()
	# Bone space: +Y runs from the wrist toward the fingers.
	_glove.scale = Vector3.ONE * GLOVE_SCALE
	_glove.position = Vector3(0.0, 0.95 * GLOVE_SCALE * 0.75, 0.0)
	attach.add_child(_glove)
	_hand = attach
	var grip := BoneAttachment3D.new()
	grip.bone_name = "hand_r"
	skeleton.add_child(grip)
	_grip = grip
	_build_headwear(skeleton)
	_back = Label3D.new()
	_back.font = BACK_FONT
	_back.font_size = 72
	_back.pixel_size = 0.0035
	_back.outline_size = 10
	_back.double_sided = false
	_attach(skeleton, "spine_03", _back, Transform3D(Basis(Vector3.UP, PI), BACK_NUMBER_AT))
	_tag = Label3D.new()
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.position.y = 2.55
	_tag.fixed_size = true
	_tag.pixel_size = 0.0012
	_tag.font_size = 22
	_tag.outline_size = 8
	_tag.no_depth_test = true
	add_child(_tag)
	set_look(color, tag)
	_play(&"Idle", 1.0)


func set_tag_visible(value: bool) -> void:
	_tag.visible = value


## Fielders wear a glove and a cap; batters and runners wear batting
## gloves and a helmet.
func set_glove_visible(value: bool) -> void:
	_glove.visible = value
	_cap.visible = value
	_helmet.visible = not value
	_kit.set_shader_parameter("gloved", not value)
	if _pose <= Pose.IDLE:
		_play(_idle_clip(), 1.0, 0.0)


## Lefties play the mirrored moves and wear the glove on the right hand.
func set_lefty(value: bool) -> void:
	if value == _lefty:
		return
	_lefty = value
	_hand.bone_name = "hand_r" if value else "hand_l"
	_grip.bone_name = "hand_l" if value else "hand_r"
	# The helmet's ear flap covers the ear toward the pitcher.
	_helmet.get_node("FlapLeft").visible = not value
	_helmet.get_node("FlapRight").visible = value
	_clip = &""
	_play(_idle_clip(), 1.0, 0.0)


## Where the batter's hands hold the bat (and a thrower holds the ball).
func grip_position() -> Vector3:
	return _grip.global_position


## Turns the body about its feet (degrees, + = counterclockwise from above):
## the batter's torso following his swing.
func set_twist(degrees: float) -> void:
	_twist = degrees
	_model.rotation.y = PI + deg_to_rad(degrees)


## The team's kit: jersey, helmet and cap in its main color, sleeve
## trim, belt, batting gloves and socks from its second color; home whites
## or road grays.
func set_look(color: Color, tag: String, trim: Color = Color(0, 0, 0, 0), home: bool = true) -> void:
	var second := trim if trim.a > 0.0 else color.darkened(0.35)
	_kit.set_shader_parameter("jersey", color)
	_kit.set_shader_parameter("trim", second)
	_kit.set_shader_parameter("socks", color.darkened(0.25))
	_kit.set_shader_parameter("pants", Color(0.94, 0.93, 0.89) if home else Color(0.66, 0.67, 0.7))
	for gear: Node3D in [_helmet, _cap]:
		for part in gear.find_children("*", "MeshInstance3D", true, false):
			if part.has_meta("team_part"):
				var shell := GrayboxField._mat(color if part.get_meta("team_part") == "main" else second)
				shell.roughness = 0.25 if gear == _helmet else 0.8
				shell.metallic_specular = 0.7
				part.material_override = shell
	_back.modulate = second.lightened(0.25)
	_back.outline_modulate = color.darkened(0.5)
	_tag.text = tag


## Who wears the kit: skin tone, hair color and beard from his id, number
## on his back.
func set_player(id: String, number: int) -> void:
	_kit.set_shader_parameter("skin", UniformLook.skin_for(id))
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = UniformLook.hair_for(id)
	hair_mat.roughness = 0.8
	for mi in [_hair, _beard]:
		if mi != null:
			mi.material_override = hair_mat
	if _beard != null:
		_beard.visible = float(absi(hash(id + "beard")) % 100) / 100.0 < BEARD_SHARE
	_back.text = str(number) if number >= 0 else ""


## Hands on the bat (batter at the plate): the IK holds both hands on the
## handle and places the bat, pointing along direction (world), hands gap
## meters apart. Pass bat = null to let go.
func grip_bat(bat: Node3D, direction: Vector3 = Vector3.FORWARD, gap: float = 0.1, one_hand: bool = false, choke: float = 0.0) -> void:
	if bat == null:
		if _grip_ik != null:
			_grip_ik.active = false
		return
	if _grip_ik == null:
		_grip_ik = BatGrip.new()
		_grip_ik.name = "BatGrip"
		_skeleton.add_child(_grip_ik)
	_grip_ik.active = true
	_grip_ik.bat = bat
	_grip_ik.direction = direction
	_grip_ik.gap = gap
	_grip_ik.lefty = _lefty
	_grip_ik.one_hand = one_hand
	_grip_ik.choke = choke


## Crouching roles (catcher) idle in a crouch.
func set_crouch(crouched: bool) -> void:
	_crouched = crouched
	if _pose == -1 or _pose == Pose.IDLE:
		_play(_idle_clip(), 1.0, 0.0)


func face(target: Vector3) -> void:
	var flat := Vector3(target.x, global_position.y, target.z)
	if flat.distance_to(global_position) > 0.05:
		look_at(flat, Vector3.UP)


## Snap back to standing (between plays).
func reset_pose() -> void:
	_sway = 0.0
	_model.position = Vector3.ZERO
	set_twist(0.0)
	_pose = -1
	_play(_idle_clip(), 1.0, 0.0)


## World position of the glove (where a held ball is drawn).
func hand_position() -> Vector3:
	return _hand.global_position


## Drives the body toward a pose. speed (m/s) matches run cycles; juke adds
## a side-to-side feint; progress scrubs the timed moves: THROW, SWING and
## APPROACH 0..1, PITCH 0..BaseballMoves.PITCH_LENGTH (release at 1).
func animate(pose: Pose, delta: float, speed: float = 0.0, juke: bool = false, progress: float = 0.0) -> void:
	_clock += delta
	var fresh := pose != _pose
	_pose = pose
	match pose:
		Pose.IDLE, Pose.TURN:
			_play(_idle_clip(), 1.0)
		Pose.RUN, Pose.CHASE:
			if speed > (JOG_SPEED + SPRINT_SPEED) * 0.5:
				_play(&"Sprint", speed / SPRINT_SPEED)
			else:
				_play(&"Jog_Fwd", maxf(speed / JOG_SPEED, 0.6))
		Pose.THROW:
			_scrub("Throw", progress, 1.0)
		Pose.SWING:
			_scrub("Swing_%s" % style, progress, 1.0)
		Pose.APPROACH:
			_scrub("Approach_%s" % style, progress, 1.0)
		Pose.FINISH:
			# Admiring it: holds the end of his swing.
			_scrub("Swing_%s" % style, 1.0, 1.0)
		Pose.PITCH:
			_scrub("Pitch", progress, BaseballMoves.PITCH_LENGTH)
		Pose.BAT_STANCE:
			_play(BaseballMoves.clip("Stance_%s" % style, _lefty), 1.0)
		Pose.BUNT:
			_play(BaseballMoves.clip("Bunt", _lefty), 1.6)
		Pose.LEAD:
			_play(BaseballMoves.clip("Lead", _lefty), 1.0)
		Pose.TAG, Pose.SLIDE, Pose.SCOOP, Pose.CATCH_HIGH, Pose.DIVE:
			if fresh:
				_play(BaseballMoves.clip(ONE_SHOTS[pose], _lefty), 1.0, BLEND, true)
		Pose.DOWN:
			if fresh:
				_play(&"Death01", 1.2, BLEND, true)
		Pose.CELEBRATE:
			_play(&"Dance", 1.0)
	var target := sin(_clock * 9.0) * 0.22 if juke else 0.0
	_sway = lerpf(_sway, target, 1.0 - exp(-delta * 14.0))
	_model.position.x = _sway
	# Feet on the field's surface: up on the mound, flat everywhere else.
	_model.position.y = FieldLayout.ground_height(global_position)


## Moves the meshes of a base-character scene onto this skeleton (same
## bone names, so its skin binds there). Returns the named one, or the
## first. The scene itself is discarded.
func _wear(skeleton: Skeleton3D, scene: PackedScene, wanted: String) -> MeshInstance3D:
	var source := scene.instantiate()
	var found: MeshInstance3D = null
	for mi: MeshInstance3D in source.find_children("*", "MeshInstance3D", true, false):
		mi.owner = null
		mi.get_parent().remove_child(mi)
		skeleton.add_child(mi)
		mi.transform = Transform3D.IDENTITY
		mi.skeleton = NodePath("..")
		if found == null or mi.name == wanted:
			found = mi
	source.free()
	return found


## Hangs a node on a bone at a rest-pose spot (skeleton space).
func _attach(skeleton: Skeleton3D, bone: String, node: Node3D, at: Transform3D) -> BoneAttachment3D:
	var attach := BoneAttachment3D.new()
	attach.bone_name = bone
	skeleton.add_child(attach)
	attach.add_child(node)
	node.transform = skeleton.get_bone_global_rest(skeleton.find_bone(bone)).affine_inverse() * at
	return attach


## A glossy batting helmet (shell, brim, ear flap on the left for a righty)
## and a soft cap (crown, button, long brim), both on the head.
func _build_headwear(skeleton: Skeleton3D) -> void:
	_helmet = Node3D.new()
	_helmet.name = "Helmet"
	# The head is a narrow egg: about 0.17 m wide, 0.23 deep, top at 1.83.
	_helmet_part(_helmet, _dome(0.105, 0.165), Vector3(0, 0, -0.005), Vector3(1, 1, 1.28), "main")
	_helmet_part(_helmet, _disc(0.07, 0.014), Vector3(0, 0.005, 0.135), Vector3(1.2, 1.0, 0.8), "main")
	for side: float in [1.0, -1.0]:
		# Skeleton +X is the body's left.
		var flap := Node3D.new()
		flap.name = "FlapLeft" if side > 0.0 else "FlapRight"
		_helmet.add_child(flap)
		var shell := _helmet_part(flap, _dome(0.06, 0.03), Vector3(0.085 * side, -0.06, 0.025), Vector3(1.0, 1.0, 1.15), "main")
		shell.rotation.z = -PI * 0.5 * side
		var hole := _helmet_part(flap, _disc(0.026, 0.01), Vector3(0.116 * side, -0.055, 0.02), Vector3.ONE, "trim")
		hole.rotation.z = PI * 0.5
	_helmet.get_node("FlapRight").visible = false
	_attach(skeleton, "Head", _helmet, Transform3D(Basis.IDENTITY, CROWN))
	_cap = Node3D.new()
	_cap.name = "Cap"
	_helmet_part(_cap, _dome(0.098, 0.14), Vector3(0, 0.01, 0.0), Vector3(1, 1, 1.24), "main")
	_helmet_part(_cap, _disc(0.014, 0.014), Vector3(0, 0.15, 0.0), Vector3.ONE, "trim")
	var brim := _helmet_part(_cap, _disc(0.075, 0.01), Vector3(0, 0.02, 0.15), Vector3(1.05, 1.0, 1.0), "trim")
	brim.rotation.x = 0.12
	_attach(skeleton, "Head", _cap, Transform3D(Basis.IDENTITY, CROWN))
	_cap.visible = false


func _helmet_part(parent: Node3D, mesh: Mesh, at: Vector3, size: Vector3, part: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = at
	mi.scale = size
	mi.set_meta("team_part", part)
	mi.material_override = GrayboxField._mat(Color.GRAY)
	parent.add_child(mi)
	return mi


static func _dome(radius: float, height: float) -> SphereMesh:
	var dome := SphereMesh.new()
	dome.radius = radius
	dome.height = height  # a hemisphere's height is the dome's own height
	dome.is_hemisphere = true
	dome.radial_segments = 24
	dome.rings = 8
	return dome


static func _disc(radius: float, thickness: float) -> CylinderMesh:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = thickness
	disc.radial_segments = 24
	return disc


## Holds a timed move at a point on its 0..length progress clock.
func _scrub(move: String, progress: float, length: float) -> void:
	# No cross-fade: a blend only advances while the clip plays, and a
	# scrubbed clip stands still, so it would never finish blending in.
	_play(BaseballMoves.clip(move, _lefty), 0.0, 0.0)
	_player.seek(clampf(progress, 0.0, length), true)


## Standing still: catchers squat, gloved fielders sit in their ready
## stance, everyone else stands.
func _idle_clip() -> StringName:
	if _crouched:
		return BaseballMoves.clip("Catcher", _lefty)
	if _glove != null and _glove.visible:
		return BaseballMoves.clip("Ready", _lefty)
	return &"Idle"


func _play(clip: StringName, speed: float, blend: float = BLEND, restart: bool = false) -> void:
	_player.speed_scale = speed
	if clip == _clip and not restart:
		return
	_clip = clip
	_player.play(clip, blend)
