class_name ActorView
extends Node3D
## Placeholder player body: capsule + head + floating tag. Purely visual.

var _body: MeshInstance3D
var _tag: Label3D


func setup(color: Color, tag: String) -> void:
	_body = MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.38
	capsule.height = 1.7
	_body.mesh = capsule
	_body.position.y = 0.85
	add_child(_body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.26
	sphere.height = 0.52
	head.mesh = sphere
	head.position.y = 1.95
	head.material_override = GrayboxField._mat(Color(0.93, 0.78, 0.62))
	add_child(head)
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


func set_look(color: Color, tag: String) -> void:
	_body.material_override = GrayboxField._mat(color)
	_tag.text = tag


## Lowers the body for crouching roles (catcher) without changing position.
func set_crouch(crouched: bool) -> void:
	scale = Vector3(1.0, 0.45, 1.0) if crouched else Vector3.ONE


func face(target: Vector3) -> void:
	var flat := Vector3(target.x, global_position.y, target.z)
	if flat.distance_to(global_position) > 0.05:
		look_at(flat, Vector3.UP)
