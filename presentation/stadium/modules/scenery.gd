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


## (near, far) radius of a water piece at a spray angle; far <= near where
## it has none. Rivers are straight bands (near bank `distance` m out across
## the piece's angle); moats follow the back of the stands.
static func water_band(stadium: Stadium, piece: StadiumPiece, angle: float) -> Vector2:
	var width := float(piece.param("width")) * piece.size
	if StringName(piece.param("style")) == &"river":
		var c := cos(deg_to_rad(angle - piece.angle))
		if c < 0.35:
			return Vector2.ZERO
		var near := float(piece.param("distance")) / c
		var back := stadium.stand_top(angle).x + 4.0
		return Vector2(maxf(near, back), minf((float(piece.param("distance")) + width) / c, 900.0))
	var span := float(piece.param("span"))
	var rel := fposmod((angle - piece.angle) * signf(span if span != 0.0 else 1.0), 360.0)
	if absf(span) < 360.0 and rel > absf(span):
		return Vector2.ZERO
	var start := stadium.stand_top(angle).x + float(piece.param("gap"))
	return Vector2(start, minf(start + width, 900.0))
