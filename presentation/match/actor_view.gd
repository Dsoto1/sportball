class_name ActorView
extends Node3D
## Placeholder player body: capsule + head + one arm with a glove, on a
## small procedural rig (lean, bob, sway, arm angle) so runs, turns, chases,
## tags, throws, slides and falls read without a skeleton. Purely visual.

enum Pose { IDLE, RUN, TURN, CHASE, TAG, THROW, DOWN, SLIDE }

const SMOOTHING := 14.0

var _rig: Node3D
var _body: MeshInstance3D
var _shoulder: Node3D
var _hand: Node3D
var _tag: Label3D
var _clock := 0.0
var _lean := 0.0
var _arm := 0.0
var _drop := 0.0
var _sway := 0.0


func setup(color: Color, tag: String) -> void:
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	_body = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	_body.mesh = capsule
	_body.position.y = 0.85
	_rig.add_child(_body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.26
	sphere.height = 0.52
	head.mesh = sphere
	head.position.y = 1.95
	head.material_override = GrayboxField._mat(Color(0.93, 0.78, 0.62))
	_rig.add_child(head)
	_shoulder = Node3D.new()
	_shoulder.position = Vector3(0.42, 1.45, 0.0)
	_rig.add_child(_shoulder)
	var arm := MeshInstance3D.new()
	var limb := CapsuleMesh.new()
	limb.radius = 0.09
	limb.height = 0.75
	arm.mesh = limb
	arm.position = Vector3(0.0, -0.36, 0.0)
	_shoulder.add_child(arm)
	_hand = Node3D.new()
	_hand.position = Vector3(0.0, -0.76, 0.0)
	_shoulder.add_child(_hand)
	var glove := MeshInstance3D.new()
	var mitt := SphereMesh.new()
	mitt.radius = 0.15
	mitt.height = 0.3
	glove.mesh = mitt
	glove.material_override = GrayboxField._mat(Color(0.45, 0.28, 0.14))
	_hand.add_child(glove)
	_tag = Label3D.new()
	_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_tag.position.y = 2.6
	_tag.fixed_size = true
	_tag.pixel_size = 0.0012
	_tag.font_size = 22
	_tag.outline_size = 8
	_tag.no_depth_test = true
	add_child(_tag)
	set_look(color, tag)
	arm.material_override = _body.material_override


func set_look(color: Color, tag: String) -> void:
	_body.material_override = GrayboxField._mat(color)
	_tag.text = tag


## Lowers the body for crouching roles (catcher) without changing position.
func set_crouch(crouched: bool) -> void:
	scale = Vector3(1.0, 0.38, 1.0) if crouched else Vector3.ONE


func face(target: Vector3) -> void:
	var flat := Vector3(target.x, global_position.y, target.z)
	if flat.distance_to(global_position) > 0.05:
		look_at(flat, Vector3.UP)


## Snap back to standing (between plays).
func reset_pose() -> void:
	_lean = 0.0
	_arm = 0.0
	_drop = 0.0
	_sway = 0.0
	_rig.rotation_degrees = Vector3.ZERO
	_rig.position = Vector3.ZERO
	_shoulder.rotation_degrees = Vector3.ZERO


## World position of the glove (where a held ball is drawn).
func hand_position() -> Vector3:
	return _hand.global_position


## Drives the rig toward a pose. speed (m/s) scales the run cycle; juke adds
## a side-to-side feint; progress (0..1) sequences one-shot poses (throw).
func animate(pose: Pose, delta: float, speed: float = 0.0, juke: bool = false, progress: float = 0.0) -> void:
	_clock += delta
	var lean := 0.0
	var arm := 0.0
	var drop := 0.0
	var bob := 0.0
	var cycle := _clock * (6.0 + speed * 0.9)
	match pose:
		Pose.RUN:
			lean = 16.0 * clampf(speed / 8.0, 0.0, 1.0)
			arm = sin(cycle) * 40.0
			bob = absf(sin(cycle)) * 0.08
		Pose.TURN:
			# Plant and stop: lean back, sink, arm out for balance.
			lean = -20.0
			drop = -0.15
			arm = 60.0
		Pose.CHASE:
			# Ball held high, ready to flip or tag.
			lean = 12.0
			arm = 130.0
			bob = absf(sin(cycle)) * 0.06
		Pose.TAG:
			lean = 38.0
			arm = 95.0
			drop = -0.2
		Pose.THROW:
			# Cocked behind the head, released out front.
			lean = lerpf(-12.0, 22.0, progress)
			arm = lerpf(200.0, 50.0, progress)
		Pose.DOWN:
			lean = 82.0  # face down, reaching for the bag
			arm = 170.0
		Pose.SLIDE:
			lean = -70.0  # feet first
			arm = 150.0
	var k := 1.0 - exp(-delta * SMOOTHING)
	_lean = lerpf(_lean, lean, k)
	_arm = lerpf(_arm, arm, k)
	_drop = lerpf(_drop, drop, k)
	_sway = lerpf(_sway, sin(_clock * 9.0) * 0.22 if juke else 0.0, k)
	# The actor faces -Z, so a forward lean is a negative rotation about X.
	_rig.rotation_degrees = Vector3(-_lean, 0.0, 0.0)
	_rig.position = Vector3(_sway, _drop + bob, 0.0)
	_shoulder.rotation_degrees = Vector3(_arm, 0.0, 0.0)
