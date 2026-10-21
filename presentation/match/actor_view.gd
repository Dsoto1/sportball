class_name ActorView
extends Node3D
## A player's body: the Quaternius mannequin (CC0, Universal Animation
## Library) in team colors. Baseball moves (stance, swing, bunt, pitch,
## throw, ready, scoop, high catch, dive, tag, lead, slide) are the game's
## own, baked by BaseballMoves; runs and celebrations come from the library.
## Gameplay decides where everyone is; this only picks a clip per pose,
## matches run cycles to speed and keeps the glove on the hand. Visual only.

enum Pose { IDLE, RUN, TURN, CHASE, TAG, THROW, DOWN, SLIDE, BAT_STANCE, SWING, CELEBRATE, BUNT, PITCH, SCOOP, CATCH_HIGH, DIVE, LEAD }

const BODY := preload("res://assets/third_party/quaternius/universal-animation-library/UAL1_Standard.glb")
const BLEND := 0.12
## Arcade proportions: broader and a little bigger than the mannequin, so
## players read from the high field camera.
const BUILD := Vector3(1.35, 1.12, 1.35)
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
var _glove: MeshInstance3D
## Throwing hand (right for a righty): holds the bat's handle and the ball.
var _grip: BoneAttachment3D
var _lefty := false
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
	_mesh = _model.find_child("Mannequin") as MeshInstance3D
	var skeleton := _model.find_child("Skeleton3D") as Skeleton3D
	_player.add_animation_library(BaseballMoves.LIBRARY, BaseballMoves.library(skeleton, _player))
	var attach := BoneAttachment3D.new()
	attach.bone_name = "hand_l"
	skeleton.add_child(attach)
	_glove = MeshInstance3D.new()
	var mitt := SphereMesh.new()
	mitt.radius = 0.13
	mitt.height = 0.22
	_glove.mesh = mitt
	_glove.material_override = GrayboxField._mat(Color(0.45, 0.28, 0.14))
	attach.add_child(_glove)
	_hand = attach
	var grip := BoneAttachment3D.new()
	grip.bone_name = "hand_r"
	skeleton.add_child(grip)
	_grip = grip
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


## Fielders wear a glove; batters and runners do not.
func set_glove_visible(value: bool) -> void:
	_glove.visible = value
	if _pose <= Pose.IDLE:
		_play(_idle_clip(), 1.0, 0.0)


## Lefties play the mirrored moves and wear the glove on the right hand.
func set_lefty(value: bool) -> void:
	if value == _lefty:
		return
	_lefty = value
	_hand.bone_name = "hand_r" if value else "hand_l"
	_grip.bone_name = "hand_l" if value else "hand_r"
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


## Uniform in the team's main color, joints and trim in its second color.
func set_look(color: Color, tag: String, trim: Color = Color(0, 0, 0, 0)) -> void:
	var main := GrayboxField._mat(color)
	main.roughness = 0.7
	_mesh.set_surface_override_material(0, main)
	_mesh.set_surface_override_material(1, GrayboxField._mat(trim if trim.a > 0.0 else color.darkened(0.35)))
	_tag.text = tag


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
## a side-to-side feint; progress scrubs the timed moves: THROW and SWING
## 0..1, PITCH 0..BaseballMoves.PITCH_LENGTH (release at 1).
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
			_scrub("Swing", progress, 1.0)
		Pose.PITCH:
			_scrub("Pitch", progress, BaseballMoves.PITCH_LENGTH)
		Pose.BAT_STANCE:
			_play(BaseballMoves.clip("Stance", _lefty), 1.0)
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


## Holds a timed move at a point on its 0..length progress clock.
func _scrub(move: String, progress: float, length: float) -> void:
	_play(BaseballMoves.clip(move, _lefty), 0.0)
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
