class_name Scenery
## Shared helpers for scenery modules: where the ground beyond the stands
## is at an angle, and simple shapes (cylinders, cones) in the park's kit.


## A spot on the ground `setback` meters behind the back of the stands.
static func behind(stadium: Stadium, angle: float, setback: float) -> Vector3:
	return stadium.point(angle, stadium.stand_top(angle).x + setback, 0.0)


## Spray angles spread over [angle, angle + span] (span may be negative).
static func spread(angle: float, span: float, count: int) -> Array[float]:
	var out: Array[float] = []
	for i in count:
		out.append(angle + span * ((i + 0.5) / count if count > 1 else 0.5))
	return out


static func cylinder(parent: Node, radius_bottom: float, radius_top: float, height: float, color: Color, sides: int = 12) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.bottom_radius = radius_bottom
	cyl.top_radius = radius_top
	cyl.height = height
	cyl.radial_segments = sides
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = GrayboxField._mat(color)
	parent.add_child(mi)
	return mi


static func sphere(parent: Node, radius: float, color: Color, squash: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0 * squash
	s.radial_segments = 12
	s.rings = 6
	mi.mesh = s
	mi.material_override = GrayboxField._mat(color)
	parent.add_child(mi)
	return mi
