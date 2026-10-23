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
		# A straight band: it runs on into the haze at the land's rim.
		var c := cos(deg_to_rad(angle - piece.angle))
		var near := float(piece.param("distance")) / maxf(c, 0.001)
		if c <= 0.0 or near >= Stadium.GROUND_RIM:
			return Vector2.ZERO
		var back := stadium.stand_top(angle).x + 4.0
		return Vector2(maxf(near, back), minf((float(piece.param("distance")) + width) / c, Stadium.GROUND_RIM))
	var span := float(piece.param("span"))
	var rel := fposmod((angle - piece.angle) * signf(span if span != 0.0 else 1.0), 360.0)
	if absf(span) < 360.0 and rel > absf(span):
		return Vector2.ZERO
	var start := stadium.stand_top(angle).x + float(piece.param("gap"))
	return Vector2(start, minf(start + width, Stadium.GROUND_RIM))


## A surface of revolution: `profile` is a list of Vector3(radius, height,
## shade) from the base up, swept around `sides` times. `jitter` roughens
## each ring's radius per side (eroded rock), with a smooth per-side bias so
## buttresses and gullies run the full height. Shade (0..1) darkens that
## ring's vertex color (strata, caps, stains), which the material multiplies
## with its texture. Base at the node origin.
static func lathe(parent: Node, profile: Array, sides: int, jitter: float, rng: RandomNumberGenerator, material: Material) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bias: Array[float] = []
	for s in sides:
		bias.append(rng.randf_range(-1.0, 1.0))
	var rings: Array = []
	for r in profile.size():
		var p: Vector3 = profile[r]
		var ring: Array[Vector3] = []
		for s in sides:
			var a := TAU * s / sides
			var wobble := 1.0 + jitter * (0.65 * bias[s] + 0.35 * rng.randf_range(-1.0, 1.0))
			if r == profile.size() - 1 and p.x < 0.01:
				wobble = 1.0
			ring.append(Vector3(cos(a) * p.x * wobble, p.y, sin(a) * p.x * wobble))
		rings.append(ring)
	for r in profile.size() - 1:
		var c0 := Color.WHITE.darkened((profile[r] as Vector3).z)
		var c1 := Color.WHITE.darkened((profile[r + 1] as Vector3).z)
		var lo: Array[Vector3] = rings[r]
		var hi: Array[Vector3] = rings[r + 1]
		# Clockwise seen from outside (Godot's front faces), so the faces
		# and their normals point out.
		for s in sides:
			var n := (s + 1) % sides
			st.set_color(c0)
			st.add_vertex(lo[s])
			st.set_color(c1)
			st.add_vertex(hi[n])
			st.set_color(c1)
			st.add_vertex(hi[s])
			st.set_color(c0)
			st.add_vertex(lo[s])
			st.set_color(c0)
			st.add_vertex(lo[n])
			st.set_color(c1)
			st.add_vertex(hi[n])
	# Close the top.
	var top: Array[Vector3] = rings[rings.size() - 1]
	var center := Vector3(0, (profile[profile.size() - 1] as Vector3).y, 0)
	var ct := Color.WHITE.darkened((profile[profile.size() - 1] as Vector3).z)
	for s in sides:
		st.set_color(ct)
		st.add_vertex(center)
		st.add_vertex(top[s])
		st.add_vertex(top[(s + 1) % sides])
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material
	parent.add_child(mi)
	return mi
