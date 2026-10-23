extends StadiumModule
## A signature landmark: one sculpted model (a ModelKit role, "model")
## standing behind the outfield stands at the piece's angle, "distance" m
## beyond them, "height" m tall, turned to face home plate ("turn" adds
## degrees of yaw so a building can show a three-quarter view). It stands
## on the back of the stands ("base" m above their top row), in front of
## any landmark rows, so it rises over the bowl as the sheets' hero does.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var role := StringName(piece.param("model"))
	if not ModelKit.has(role):
		return
	var height := float(piece.param("height")) * piece.size
	var node := ModelKit.spawn(role, height, RandomNumberGenerator.new())
	node.name = stadium.unique_name("Hero")
	# Sculpted models are centered on their origin: stand them on their base.
	var box := ModelKit._aabb(node)
	var holder := Node3D.new()
	holder.name = stadium.unique_name("HeroSpot")
	stadium.add_child(holder)
	var top := stadium.stand_top(piece.angle)
	# Never reaching over the stands toward the field: however big the
	# model, its front edge (its footprint turned by "turn") stays at
	# least 2 m behind the stands' back.
	var size := box.size * node.scale
	var turn := deg_to_rad(float(piece.param("turn")))
	var reach := absf(cos(turn)) * size.z * 0.5 + absf(sin(turn)) * size.x * 0.5
	var radius := maxf(top.x + float(piece.param("distance")), top.x + 2.0 + reach)
	holder.position = stadium.point(piece.angle, radius, top.y + float(piece.param("base")))
	stadium.face_home(holder)
	holder.rotation.y += deg_to_rad(float(piece.param("turn")))
	node.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * node.scale
	holder.add_child(node)
	_ground(stadium, piece, holder, box.size * node.scale)


## Settles the landmark into the park: rocks and planting around its foot (the "foot" tree kind,
## "" for none), so it rises out of the scene rather than floating on it.
func _ground(stadium: Stadium, piece: StadiumPiece, holder: Node3D, size: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(stadium.def.id) + str(piece.angle))
	var stone := stadium.def.facade_tint().darkened(0.2)
	var kind := StringName(piece.param("foot"))
	if kind == &"":
		return
	var leaf: Color = {&"blossom": Color(0.97, 0.68, 0.82)}.get(kind, Color(0, 0, 0, 0))
	var rock := StadiumSurfaces.material(&"rock", stone.lerp(Color(0.45, 0.43, 0.4), 0.5), false, 0.4)
	# Around the front and sides of the footprint, thinning toward the back.
	var count := int(piece.param("foot_count"))
	for i in count:
		var t := float(i) / maxf(count - 1, 1)
		var ang := lerpf(-PI * 0.85, PI * 0.85, t) + rng.randf_range(-0.1, 0.1)
		var spot := Vector3(sin(ang) * size.x * 0.58, 0.4, cos(ang) * size.z * 0.58)
		if i % 3 == 0:
			var r := Scenery.sphere(holder, rng.randf_range(1.6, 3.2), Color.WHITE, 0.6)
			r.material_override = rock
			r.position = spot
			r.rotation.y = rng.randf() * TAU
		else:
			var tree := ModelKit.spawn(kind, rng.randf_range(0.14, 0.24) * size.y, rng, leaf)
			tree.position = spot
			tree.rotation.y = rng.randf() * TAU
			holder.add_child(tree)
		if i % 2 == 0:
			var bush := ModelKit.spawn(&"bush", rng.randf_range(2.0, 3.5), rng)
			bush.position = spot + Vector3(rng.randf_range(-2.0, 2.0), 0, rng.randf_range(1.0, 3.0))
			holder.add_child(bush)
