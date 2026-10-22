extends StadiumModule
## A city round the park, built on the street grid the ground draws (city
## blocks Stadium.CITY_BLOCK m apart): one building per lot, squared to the
## streets. The nearer blocks get modeled buildings and towers (Kenney City
## Kit); the far ones lit-window towers, batched, fading into the haze and
## taller toward the outfield so they peek over it (more windows lit at
## night). Lots under water, or where the park's own pieces already stand,
## stay empty. Built after the other pieces, so it can see them.

## Out to here (m from the middle of the field) the city is built; the haze
## covers what lies beyond.
const CITY_RIM := 1500.0
## Modeled buildings this close in; plain towers beyond.
const MODELED_RIM := 600.0


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var rng := stadium.rng
	var root := Node3D.new()
	root.name = stadium.unique_name("Skyline")
	stadium.add_child(root)
	var tall := float(piece.param("height")) * piece.size
	var block := Stadium.CITY_BLOCK
	var lot := block - Stadium.CITY_STREET - 8.0
	var origin := Vector2(Stadium.FIELD_CENTER.x, Stadium.FIELD_CENTER.z)
	var center := origin
	var taken := _taken_blocks(stadium, block, origin)
	var towers: Array[Transform3D] = []
	# The modeled buildings, batched: mesh -> where each copy stands.
	var models := {}
	var n := int(ceil(CITY_RIM / block))
	for ix in range(-n, n):
		for iz in range(-n, n):
			var lot_center := origin + Vector2(ix + 0.5, iz + 0.5) * block
			var r := lot_center.distance_to(center)
			if r < stadium.city_from() + block * 0.5 or r > CITY_RIM:
				continue
			if taken.has(Vector2i(ix, iz)) or _wet(stadium, Vector3(lot_center.x, 0.0, lot_center.y)):
				continue
			var t := clampf((r - stadium.city_from()) / (CITY_RIM - stadium.city_from()), 0.0, 1.0)
			if rng.randf() > lerpf(0.92, 0.7, t):
				continue
			# Toward the outfield (and so seen over it from home) the city rises.
			var beyond := clampf((center.y - lot_center.y) / r, 0.0, 1.0)
			var at := Vector3(lot_center.x, 0.0, lot_center.y)
			if r < MODELED_RIM:
				# A tower alone on its lot, or four low buildings sharing it.
				var tower := rng.randf() < 0.25 + 0.45 * beyond
				var spots: Array[Vector3] = [at]
				if not tower:
					spots = [at + Vector3(-1, 0, -1) * lot * 0.25, at + Vector3(1, 0, -1) * lot * 0.25, at + Vector3(-1, 0, 1) * lot * 0.25, at + Vector3(1, 0, 1) * lot * 0.25]
				for spot in spots:
					var role: StringName = &"tower" if tower else (&"building" if rng.randf() < 0.6 else &"block")
					var height := (rng.randf_range(45.0, 85.0) if tower else rng.randf_range(16.0, 32.0)) * tall
					var b := ModelKit.spawn(role, height, rng)
					var size := ModelKit._aabb(b).size * b.scale.x
					var room := lot * (0.9 if tower else 0.46)
					# Fill the lot, but never stretch a tower past 1.25x its height.
					b.scale *= minf(room / maxf(maxf(size.x, size.z), 0.001), 1.25 if tower else 1.6)
					b.position = spot
					b.rotation.y = PI * 0.5 * rng.randi_range(0, 3)
					_collect(b, models)
					b.free()
				continue
			# One tower on the lot, or two sharing it.
			var pair := rng.randf() < 0.35
			for k in (2 if pair else 1):
				var w := rng.randf_range(lot * 0.55, lot) * (0.5 if pair else 1.0)
				var d := rng.randf_range(lot * 0.55, lot)
				var h := (rng.randf_range(28.0, 70.0) + 110.0 * beyond * rng.randf() * (1.0 - t * 0.5)) * tall
				var offset := Vector3(((k - 0.5) * lot * 0.5) if pair else 0.0, 0.0, 0.0)
				var basis := Basis.from_scale(Vector3(w, h, d))
				towers.append(Transform3D(basis, at + offset + Vector3(0.0, h * 0.5, 0.0)))
	for mesh: Mesh in models:
		var mmi := _batch(mesh, models[mesh])
		mmi.name = "Buildings"
		root.add_child(mmi)
	_plant_parkland(stadium, root, taken, block, origin)
	if towers.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = BoxMesh.new()
	mm.instance_count = towers.size()
	for i in towers.size():
		mm.set_instance_transform(i, towers[i])
	var mat := ShaderMaterial.new()
	mat.shader = Stadium.SKYLINE_SHADER
	mat.set_shader_parameter("wall_color", def.skyline_color)
	mat.set_shader_parameter("window_color", def.window_color)
	mat.set_shader_parameter("lit_share", 0.5 if def.night else 0.22)
	mat.set_shader_parameter("glow", 1.6 if def.night else 0.35)
	mat.set_shader_parameter("haze_color", stadium.horizon_color())
	mat.set_shader_parameter("center", center)
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Towers"
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


## The blocks the park's own pieces stand on (landmarks, mountains,
## stacks, bridges...), from the bounds of everything built so far beyond
## the stands.
func _taken_blocks(stadium: Stadium, block: float, origin: Vector2) -> Dictionary:
	var taken := {}
	for vi: VisualInstance3D in stadium.find_children("*", "VisualInstance3D", true, false):
		if vi is GPUParticles3D or vi is CPUParticles3D:
			continue
		# Relative to the stadium (which may be built off the scene tree).
		var xf := vi.transform
		var n := vi.get_parent()
		while n != stadium and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var box := xf * vi.get_aabb()
		var lo := Vector2(box.position.x, box.position.z)
		var hi := lo + Vector2(box.size.x, box.size.z)
		# The bowl, ground, plaza and water span everything; skip them.
		if hi.x - lo.x > 400.0 or hi.y - lo.y > 400.0:
			continue
		if (lo + hi).distance_to(origin * 2.0) * 0.5 < stadium.city_from() - block:
			continue
		for ix in range(floori((lo.x - origin.x) / block - 0.1), floori((hi.x - origin.x) / block + 0.1) + 1):
			for iz in range(floori((lo.y - origin.y) / block - 0.1), floori((hi.y - origin.y) / block + 0.1) + 1):
				taken[Vector2i(ix, iz)] = true
	return taken


## Whether a point is under a bay, river or moat.
func _wet(stadium: Stadium, at: Vector3) -> bool:
	var angle := FieldLayout.spray_angle_of(at)
	var radius := Vector2(at.x, at.z).length()
	if stadium.is_water(angle) and radius < Stadium.WATER_EDGE + Stadium.CITY_BLOCK:
		return true
	for water in stadium.def.pieces_of(&"water"):
		var band := Scenery.water_band(stadium, water, angle)
		if band.y > band.x and radius > band.x - Stadium.CITY_BLOCK * 0.7 and radius < band.y + Stadium.CITY_BLOCK * 0.7:
			return true
	return false


## Clumps of trees on the parkland lawn between the plaza and the streets,
## batched (one draw per kind), clear of the park's own pieces.
func _plant_parkland(stadium: Stadium, root: Node3D, taken: Dictionary, block: float, origin: Vector2) -> void:
	var rng := stadium.rng
	var trees: Array[Transform3D] = []
	var kit := ModelKit.mesh_of(&"round")
	if kit.is_empty():
		return
	var tree_h: float = maxf((kit["aabb"] as AABB).size.y, 0.001)
	for i in 70:
		var a := rng.randf() * 360.0
		var near := stadium.stand_top(a).x + Stadium.PLAZA_WIDTH + 14.0
		var r := rng.randf_range(near, stadium.city_from() - 24.0)
		if r <= near:
			continue
		var c := stadium.point(a, r, 0.0)
		var cell := Vector2i(floori((c.x - origin.x) / block), floori((c.z - origin.y) / block))
		if taken.has(cell) or _wet(stadium, c):
			continue
		for k in rng.randi_range(3, 7):
			var at := c + Vector3(rng.randf_range(-14.0, 14.0), 0.0, rng.randf_range(-14.0, 14.0))
			var h := rng.randf_range(9.0, 16.0)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * (h / tree_h))
			trees.append(Transform3D(basis, at) * (kit["transform"] as Transform3D))
	if trees.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ModelKit.tinted_leaves(kit["mesh"], Color(0.24, 0.42, 0.16).darkened(0.3 if stadium.def.night else 0.0))
	mm.instance_count = trees.size()
	for i in trees.size():
		mm.set_instance_transform(i, trees[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Parkland"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mmi)


## Every mesh in a spawned model, with where it stands (model and inner
## transforms), added to `into` (mesh -> transforms).
func _collect(model: Node3D, into: Dictionary) -> void:
	for mi: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var xf := mi.transform
		var n := mi.get_parent()
		while n != model and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		if not into.has(mi.mesh):
			into[mi.mesh] = []
		into[mi.mesh].append(model.transform * xf)


func _batch(mesh: Mesh, transforms: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi
