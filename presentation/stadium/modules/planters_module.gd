extends StadiumModule
## Greenery along a terrace: rows of shrubs (round clumps in a few greens)
## dotted with flowers, set along the top of the outfield stands (or in
## front of the facades) from the piece's angle across "span" degrees.
## Shrubs and flowers are two MultiMeshes.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("planters" + str(piece.angle) + stadium.def.id)
	var span := float(piece.param("span"))
	var density := float(piece.param("density"))
	var flower: Color = piece.param("flower")
	var green: Color = piece.param("green")
	var shrubs: Array[Transform3D] = []
	var shrub_colors: Array[Color] = []
	var blooms: Array[Transform3D] = []
	var steps := maxi(2, int(absf(span) * density))
	for i in steps:
		var a := piece.angle + span * (i + rng.randf()) / steps
		var top := stadium.stand_top(a)
		var at := stadium.point(a, top.x - rng.randf_range(0.2, 1.6), top.y + 0.4)
		var s := rng.randf_range(0.9, 1.8) * piece.size
		shrubs.append(Transform3D(Basis().scaled(Vector3(s, s * 0.8, s)), at + Vector3.UP * s * 0.5))
		shrub_colors.append(green.darkened(rng.randf_range(0.0, 0.3)).lerp(Color(0.3, 0.5, 0.15), rng.randf() * 0.3))
		if rng.randf() < 0.7:
			for b in rng.randi_range(2, 5):
				var off := Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(0.5, 1.0), rng.randf_range(-0.7, 0.7)) * s
				blooms.append(Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.18, 0.32)), at + Vector3.UP * s * 0.5 + off))
	var root := Node3D.new()
	root.name = stadium.unique_name("Planters")
	stadium.add_child(root)
	_batch(root, shrubs, shrub_colors, 1.0, 8, Color.WHITE, false)
	var bloom_colors: Array[Color] = []
	for b in blooms.size():
		bloom_colors.append(flower.lightened(rng.randf_range(-0.1, 0.2)))
	_batch(root, blooms, bloom_colors, 1.0, 6, Color.WHITE, true)


static func _batch(root: Node3D, xfs: Array[Transform3D], colors: Array[Color], radius: float, segments: int, _c: Color, glow: bool) -> void:
	if xfs.is_empty():
		return
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = sphere
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, colors[i])
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	if glow:
		mat.emission_enabled = true
		mat.emission = Color(0.3, 0.3, 0.3)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)
