class_name ActorView
extends Node3D
## A player's body: the Quaternius mannequin (CC0, Universal Animation
## Library) in team colors, animated from its clip library. Gameplay
## decides where everyone is; this only picks a clip per pose, matches run
## cycles to speed and keeps the glove on the hand. Purely visual.

enum Pose { IDLE, RUN, TURN, CHASE, TAG, THROW, DOWN, SLIDE, BAT_STANCE, SWING, CELEBRATE }

const BODY := preload("res://assets/third_party/quaternius/universal-animation-library/UAL1_Standard.glb")
const BLEND := 0.12
## Arcade proportions: broader and a little bigger than the mannequin, so
## players read from the high field camera.
const BUILD := Vector3(1.35, 1.12, 1.35)
## Ground speed (m/s) the jog and sprint cycles are animated at.
const JOG_SPEED := 3.6
const SPRINT_SPEED := 7.2
## Clip time where a punch/throw/swing reaches full extension.
const THROW_RELEASE := 0.45
## Poses that play once and hold their last frame.

var _model: Node3D
var _player: AnimationPlayer
var _mesh: MeshInstance3D
var _hand: Node3D
var _glove: MeshInstance3D
## Right hand: where a batter's bat is gripped.
var _grip: Node3D
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


## Where the batter's hands hold the bat.
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
		_play(&"Crouch_Idle" if crouched else &"Idle", 1.0, 0.0)


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
	_play(&"Crouch_Idle" if _crouched else &"Idle", 1.0, 0.0)


## World position of the glove (where a held ball is drawn).
func hand_position() -> Vector3:
	return _hand.global_position


## Drives the body toward a pose. speed (m/s) matches run cycles; juke adds
## a side-to-side feint; progress (0..1) scrubs one-shot poses (throw).
func animate(pose: Pose, delta: float, speed: float = 0.0, juke: bool = false, progress: float = 0.0) -> void:
	_clock += delta
	var fresh := pose != _pose
	_pose = pose
	match pose:
		Pose.IDLE, Pose.TURN:
			_play(&"Crouch_Idle" if _crouched else &"Idle", 1.0)
		Pose.RUN, Pose.CHASE:
			if speed > (JOG_SPEED + SPRINT_SPEED) * 0.5:
				_play(&"Sprint", speed / SPRINT_SPEED)
			else:
				_play(&"Jog_Fwd", maxf(speed / JOG_SPEED, 0.6))
		Pose.THROW:
			# Scrubbed by the throw's progress: cocked, then released.
			_play(&"Punch_Cross", 0.0)
			_player.seek(lerpf(0.1, THROW_RELEASE + 0.2, clampf(progress, 0.0, 1.0)), true)
		Pose.TAG:
			if fresh:
				_play(&"Punch_Jab", 1.4, BLEND, true)
		Pose.DOWN:
			if fresh:
				_play(&"Death01", 1.2, BLEND, true)
		Pose.SLIDE:
			if fresh:
				_play(&"Roll", 1.3, BLEND, true)
		Pose.BAT_STANCE, Pose.SWING:
			# Both hands together out front: the grip. The swing itself is
			# the bat's sweep plus a torso twist (set_twist), timed by play.
			_play(&"Pistol_Idle", 1.0)
		Pose.CELEBRATE:
			_play(&"Dance", 1.0)
	var target := sin(_clock * 9.0) * 0.22 if juke else 0.0
	_sway = lerpf(_sway, target, 1.0 - exp(-delta * 14.0))
	_model.position.x = _sway


func _play(clip: StringName, speed: float, blend: float = BLEND, restart: bool = false) -> void:
	_player.speed_scale = speed
	if clip == _clip and not restart:
		return
	_clip = clip
	_player.play(clip, blend)
