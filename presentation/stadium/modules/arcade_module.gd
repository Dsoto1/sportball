extends StadiumModule
## The upper facade standing on the back edge of the stands, from the
## piece's angle across "span" degrees, in bays "bay" m wide:
##   arches:  a wall pierced by arched openings between columns (stone,
##            marble, brick parks);
##   windows: a wall with two rows of tall windows (warehouses, mills);
##   truss:   an open steel frame with X-bracing (industrial parks);
##   timber:  the same open frame in timber (lodges, piers);
##   colonnade: free-standing columns over a balustrade, no wall (gardens,
##            classical parks);
##   glass:   a lit glass curtain wall with mullions (modern, sky cities);
##   battlements: a stone wall with arrow slits and crenellations on top
##            (citadels, castles);
##   eaves:   red posts and pale panels under sweeping tiled eaves with
##            hanging lanterns (shrines, pagodas);
##   carved:  a rock face with arched cave openings, as if cut from a
##            cliff (canyons, volcanoes);
##   kit:     a sculpted bay model ("kit": colosseum, gothic, temple or
##            victorian) repeated bay by bay, batched into one MultiMesh.
## Arches stack in "tiers" rows (2-3 for a colosseum or an aqueduct).
## Every "towers" bays a tower rises "tower_height" m above the facade,
## capped with a spire, dome, tiered pagoda roof or crenellations ("cap").
## The openings glow warm at night. Every "banners" bays a column carries
## a hanging banner in the club's color with its emblem (0 for none).


const BAY_TINT := preload("res://presentation/stadium/bay_tint.gdshader")


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var style := StringName(piece.param("style"))
	var height := float(piece.param("height")) * piece.size
	var bay := float(piece.param("bay"))
	var span := float(piece.param("span"))
	var open_frame := style in [&"truss", &"timber"]
	var wall_color := Color(0.95, 0.92, 0.85) if style == &"eaves" else def.facade_tint()
	var no_wall := open_frame or style == &"colonnade"
	var frame_surface: StringName = &"wood" if style == &"timber" else (&"steel" if style == &"truss" else &"structure")
	var frame_color := Color(0.72, 0.15, 0.12) if style == &"eaves" else def.structure_color.darkened(0.15) if not open_frame else (Color(0.42, 0.3, 0.2) if style == &"timber" else def.structure_color.darkened(0.35))
	var wall := SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	var holes := SurfaceTool.new()
	holes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var banner_spots: Array[Transform3D] = []
	var glass := SurfaceTool.new()
	glass.begin(Mesh.PRIMITIVE_TRIANGLES)
	var merlon_spots: Array = []
	var roofs := SurfaceTool.new()
	roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rock := SurfaceTool.new()
	rock.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lantern_spots: Array[Vector3] = []
	var tower_spots: Array[Vector3] = []
	var every_tower := int(piece.param("towers"))
	# Bay edges: each carries its own back-of-stands radius and base height,
	# so the facade follows the bowl without gaps.
	if style == &"kit":
		_build_kit(stadium, piece, home)
		return
	var radius_mid := stadium.stand_top(piece.angle + span * 0.5).x
	var steps := maxi(1, int(absf(deg_to_rad(span)) * radius_mid / bay))
	var edges: Array[Vector3] = []  # (angle, radius, base height)
	for i in steps + 1:
		var a := piece.angle + span * i / steps
		var top := stadium.stand_top(a)
		edges.append(Vector3(a, top.x + 0.2, top.y + 0.4))
	var col := 0.11  # column width as a share of the bay
	for i in steps:
		var e0 := edges[i]
		var e1 := edges[i + 1]
		var p := func(t: float, y_off: float, inset: float = 0.0) -> Vector3:
			var a := lerpf(e0.x, e1.x, t)
			return stadium.point(a, lerpf(e0.y, e1.y, t) - inset, lerpf(e0.z, e1.z, t) + y_off)
		if style == &"colonnade":
			# Balustrade along the bottom, a second column mid-bay.
			_quad(frame, p.call(0.0, 0.0, 0.1), p.call(1.0, 0.0, 0.1), p.call(1.0, 1.1, 0.1), p.call(0.0, 1.1, 0.1))
			var mid := lerpf(e0.x, e1.x, 0.5)
			_column(frame, stadium, mid, lerpf(e0.y, e1.y, 0.5), lerpf(e0.z, e1.z, 0.5), height + 0.6, maxf(bay * col, 0.6), 0.6)
		elif style == &"glass":
			_quad(glass, p.call(0.0, 0.0), p.call(1.0, 0.0), p.call(1.0, height), p.call(0.0, height))
			_quad(frame, p.call(0.0, height * 0.5 - 0.15, 0.3), p.call(1.0, height * 0.5 - 0.15, 0.3), p.call(1.0, height * 0.5 + 0.15, 0.3), p.call(0.0, height * 0.5 + 0.15, 0.3))
			_quad(frame, p.call(0.48, 0.0, 0.3), p.call(0.52, 0.0, 0.3), p.call(0.52, height, 0.3), p.call(0.48, height, 0.3))
		elif style == &"eaves":
			_quad(wall, p.call(0.0, 0.0), p.call(1.0, 0.0), p.call(1.0, height * 0.82), p.call(0.0, height * 0.82))
			for c in [0.3, 0.7]:
				_quad(holes, p.call(c - 0.12, height * 0.2, 0.35), p.call(c + 0.12, height * 0.2, 0.35), p.call(c + 0.12, height * 0.65, 0.35), p.call(c - 0.12, height * 0.65, 0.35))
			# Tiled eave: sloping out over the bay, its ends lifted.
			_quad(roofs, p.call(0.0, height * 0.82, -0.2), p.call(1.0, height * 0.82, -0.2), p.call(1.0, height * 0.82 - 1.0, 2.2), p.call(0.0, height * 0.82 - 1.0, 2.2))
			_quad(roofs, p.call(0.0, height + 0.6, 0.6), p.call(1.0, height + 0.6, 0.6), p.call(1.0, height * 0.82, -0.6), p.call(0.0, height * 0.82, -0.6))
			lantern_spots.append(stadium.point(lerpf(e0.x, e1.x, 0.5), lerpf(e0.y, e1.y, 0.5) - 1.8, lerpf(e0.z, e1.z, 0.5) + height * 0.62))
		elif style == &"carved":
			_quad(rock, p.call(0.0, 0.0), p.call(1.0, 0.0), p.call(1.0, height), p.call(0.0, height))
			var chord := 0.3
			var spring := height * 0.45
			_quad(holes, p.call(0.5 - chord, 0.0, 0.35), p.call(0.5 + chord, 0.0, 0.35), p.call(0.5 + chord, spring, 0.35), p.call(0.5 - chord, spring, 0.35))
			for k in 10:
				var t0 := PI * k / 10.0
				var t1 := PI * (k + 1) / 10.0
				_tri(holes, p.call(0.5, spring, 0.35), p.call(0.5 + cos(t0) * chord, spring + sin(t0) * chord * bay, 0.35), p.call(0.5 + cos(t1) * chord, spring + sin(t1) * chord * bay, 0.35))
		elif style == &"battlements":
			_quad(wall, p.call(0.0, 0.0), p.call(1.0, 0.0), p.call(1.0, height), p.call(0.0, height))
			for c in [0.33, 0.67]:
				_quad(holes, p.call(c - 0.03, height * 0.35, 0.35), p.call(c + 0.03, height * 0.35, 0.35), p.call(c + 0.03, height * 0.8, 0.35), p.call(c - 0.03, height * 0.8, 0.35))
			merlon_spots.append([e0, e1])
		elif not open_frame:
			_quad(wall, p.call(0.0, 0.0), p.call(1.0, 0.0), p.call(1.0, height), p.call(0.0, height))
			# Openings: arched (rectangle + half disc) or two rows of windows.
			if style == &"arches":
				var tiers := int(piece.param("tiers"))
				var tier_h := height / tiers
				for tier in tiers:
					var y0 := tier * tier_h
					var w := 0.5 - col
					var chord := w * 0.6
					var rise := minf(chord * bay, tier_h * 0.4)
					var spring := y0 + tier_h * 0.85 - rise
					_quad(holes, p.call(0.5 - chord, y0 + tier_h * 0.08, 0.35), p.call(0.5 + chord, y0 + tier_h * 0.08, 0.35), p.call(0.5 + chord, spring, 0.35), p.call(0.5 - chord, spring, 0.35))
					for k in 10:
						var t0 := PI * k / 10.0
						var t1 := PI * (k + 1) / 10.0
						_tri(holes, p.call(0.5, spring, 0.35), p.call(0.5 + cos(t0) * chord, spring + sin(t0) * rise, 0.35), p.call(0.5 + cos(t1) * chord, spring + sin(t1) * rise, 0.35))
					if tier > 0:
						_quad(frame, p.call(0.0, y0 - 0.25, 0.5), p.call(1.0, y0 - 0.25, 0.5), p.call(1.0, y0 + 0.25, 0.5), p.call(0.0, y0 + 0.25, 0.5))
			else:
				for row in 2:
					var y0 := height * (0.12 + row * 0.44)
					var y1 := y0 + height * 0.32
					for side: float in [-1.0, 1.0]:
						var c := 0.5 + side * 0.2
						_quad(holes, p.call(c - 0.12, y0, 0.35), p.call(c + 0.12, y0, 0.35), p.call(c + 0.12, y1, 0.35), p.call(c - 0.12, y1, 0.35))
		else:
			# Open frame: top and bottom chords and an X of braces.
			var t := 0.06
			_quad(frame, p.call(0.0, height - 0.8, 0.0), p.call(1.0, height - 0.8, 0.0), p.call(1.0, height, 0.0), p.call(0.0, height, 0.0))
			_quad(frame, p.call(0.0, 0.0, 0.0), p.call(1.0, 0.0, 0.0), p.call(1.0, 0.7, 0.0), p.call(0.0, 0.7, 0.0))
			_quad(frame, p.call(0.0, 0.7, 0.0), p.call(t, 0.7, 0.0), p.call(1.0, height - 0.8, 0.0), p.call(1.0 - t, height - 0.8, 0.0))
			_quad(frame, p.call(1.0 - t, 0.7, 0.0), p.call(1.0, 0.7, 0.0), p.call(t, height - 0.8, 0.0), p.call(0.0, height - 0.8, 0.0))
		# Rhythm: every "pavilion" bays one rises higher under a pediment
		# (a gable on open frames), so the run isn't one bay copied across.
		var rhythm := int(piece.param("pavilion"))
		if rhythm > 0 and i % rhythm == rhythm / 2 and style != &"eaves":
			var top_h := height * 1.28
			var target := frame if no_wall or style == &"glass" else wall
			_quad(target, p.call(0.0, height, 0.2), p.call(1.0, height, 0.2), p.call(1.0, top_h, 0.2), p.call(0.0, top_h, 0.2))
			_tri(frame, p.call(-0.04, top_h, 0.45), p.call(1.04, top_h, 0.45), p.call(0.5, top_h + bay * 0.32, 0.45))
			_quad(frame, p.call(-0.04, top_h - 0.3, 0.5), p.call(1.04, top_h - 0.3, 0.5), p.call(1.04, top_h + 0.1, 0.5), p.call(-0.04, top_h + 0.1, 0.5))
			if not no_wall:
				_quad(holes, p.call(0.4, height + 0.6, 0.38), p.call(0.6, height + 0.6, 0.38), p.call(0.6, top_h - 0.8, 0.38), p.call(0.4, top_h - 0.8, 0.38))
		# The column at this bay's start, standing proud of the wall.
		var cw := maxf(bay * col, 0.6)
		_column(frame, stadium, e0.x, e0.y, e0.z, height + 0.6, cw, 0.6)
		if every_tower > 0 and i > 0 and i % every_tower == 0:
			tower_spots.append(e0)
		if int(piece.param("banners")) > 0 and i % int(piece.param("banners")) == 0 and i > 0:
			var at := stadium.point(e0.x, e0.y - 0.7, e0.z + height * 0.55)
			banner_spots.append(Transform3D(Basis(), at))
		# Cornice: a band along the top, proud of the wall.
		_quad(frame, p.call(0.0, height, 0.5), p.call(1.0, height, 0.5), p.call(1.0, height + 0.7, 0.5), p.call(0.0, height + 0.7, 0.5))
	var last := edges[steps]
	_column(frame, stadium, last.x, last.y, last.z, height + 0.6, maxf(bay * col, 0.6), 0.6)
	var root := Node3D.new()
	root.name = stadium.unique_name("Arcade")
	stadium.add_child(root)
	_commit(root, wall, _double_sided(stadium.surface_mat(&"facade" if style != &"eaves" else &"wood", wall_color)))
	_commit(root, frame, _double_sided(stadium.surface_mat(frame_surface, frame_color)))
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.08, 0.07, 0.07)
	lit.emission_enabled = true
	lit.emission = def.window_color
	lit.emission_energy_multiplier = 0.7 if def.night else 0.1
	lit.cull_mode = BaseMaterial3D.CULL_DISABLED
	_commit(root, holes, lit)
	var pane := StandardMaterial3D.new()
	pane.albedo_color = Color(def.window_color.lerp(Color(0.5, 0.75, 1.0), 0.6), 0.55)
	pane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pane.metallic = 0.6
	pane.roughness = 0.08
	pane.emission_enabled = true
	pane.emission = def.window_color
	pane.emission_energy_multiplier = 0.9 if def.night else 0.12
	pane.cull_mode = BaseMaterial3D.CULL_DISABLED
	_commit(root, glass, pane)
	_commit(root, roofs, _double_sided(stadium.surface_mat(&"steel", Color(0.16, 0.15, 0.17))))
	_commit(root, rock, _double_sided(StadiumSurfaces.material(&"rock", def.facade_tint(), false, 1.5)))
	var paper := Stadium.glow(Color(1.0, 0.55, 0.3), 2.2 if def.night else 1.0)
	for at in lantern_spots:
		var lantern := Scenery.sphere(root, 0.55, Color.ORANGE, 1.3)
		lantern.position = at
		lantern.material_override = paper
	# Crenellations: two merlons per bay along the top.
	for pair: Array in merlon_spots:
		var a0: Vector3 = pair[0]
		var a1: Vector3 = pair[1]
		for t in [0.25, 0.75]:
			var merlon := stadium.box(Vector3(maxf(bay * 0.22, 0.8), 1.4, 0.9), def.facade_tint(), root, &"facade")
			merlon.position = stadium.point(lerpf(a0.x, a1.x, t), lerpf(a0.y, a1.y, t) - 0.2, lerpf(a0.z, a1.z, t) + height + 1.4)
			stadium.face_home(merlon)
	for t in tower_spots.size():
		_tower(stadium, root, piece, tower_spots[t], height, bay, home, t)
	for spot in banner_spots:
		var banner := Node3D.new()
		root.add_child(banner)
		banner.position = spot.origin
		stadium.face_home(banner)
		var cloth := stadium.box(Vector3(2.2, height * 0.55, 0.08), home.primary_color, banner)
		cloth.position.z = 0.1
		var trim := stadium.box(Vector3(2.3, 0.25, 0.1), home.secondary_color, banner)
		trim.position = Vector3(0, -height * 0.275, 0.12)
		var mark := Emblem.build(home, 1.7, 0.3)
		mark.position = Vector3(0, height * 0.08, 0.16)
		banner.add_child(mark)


## The kit style: one sculpted bay per bay width along the back of the
## stands, each stretched to the bay and the facade height, all drawn by a
## single MultiMesh. Towers and banners work as for the built styles.
func _build_kit(stadium: Stadium, piece: StadiumPiece, home: TeamDef) -> void:
	var kit := ModelKit.mesh_of(StringName("bay_%s" % piece.param("kit")))
	if kit.is_empty():
		return
	var mesh_box: AABB = kit["aabb"]
	var height := float(piece.param("height")) * piece.size
	var bay := float(piece.param("bay"))
	var span := float(piece.param("span"))
	var radius_mid := stadium.stand_top(piece.angle + span * 0.5).x
	var steps := maxi(1, int(absf(deg_to_rad(span)) * radius_mid / bay))
	var root := Node3D.new()
	root.name = stadium.unique_name("Arcade")
	stadium.add_child(root)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = kit["mesh"]
	mm.instance_count = steps
	var tint_to := stadium.def.facade_tint()
	var strength := float(piece.param("tint"))
	var rhythm := int(piece.param("pavilion"))
	var every_tower := int(piece.param("towers"))
	for i in steps:
		var a0 := piece.angle + span * i / steps
		var a1 := piece.angle + span * (i + 1) / steps
		var t0 := stadium.stand_top(a0)
		var t1 := stadium.stand_top(a1)
		var p0 := stadium.point(a0, t0.x + 0.2, t0.y + 0.4)
		var p1 := stadium.point(a1, t1.x + 0.2, t1.y + 0.4)
		var width := p0.distance_to(p1)
		var across := (p1 - p0).normalized()
		var facing := across.cross(Vector3.UP).normalized()
		if facing.dot(-((p0 + p1) * 0.5).normalized()) < 0.0:
			facing = -facing
		# Local axes: X along the bay, Y up, Z toward the field.
		var basis := Basis(across, Vector3.UP, facing)
		# Every "pavilion" bays one stands taller and steps forward, so the
		# facade has a rhythm instead of one bay copied straight across.
		var pavilion := rhythm > 0 and i % rhythm == rhythm / 2
		var bay_h := height * (1.28 if pavilion else 1.0)
		var scale := Vector3(width / maxf(mesh_box.size.x, 0.01), bay_h / maxf(mesh_box.size.y, 0.01), bay_h / maxf(mesh_box.size.y, 0.01))
		var fit := Transform3D(basis.scaled_local(scale), (p0 + p1) * 0.5 + facing * (0.8 if pavilion else 0.0))
		# A gentle per-bay tone shift (weathering), lighter on pavilions.
		var tone := 1.0 + 0.06 * sin(i * 2.3) + (0.1 if pavilion else 0.0)
		mm.set_instance_color(i, Color(tint_to.r * tone, tint_to.g * tone, tint_to.b * tone, strength))
		var origin := Transform3D(Basis(), -Vector3(mesh_box.get_center().x, mesh_box.position.y, mesh_box.get_center().z))
		mm.set_instance_transform(i, fit * origin * (kit["transform"] as Transform3D))
		if every_tower > 0 and i > 0 and i % every_tower == 0:
			_tower(stadium, root, piece, Vector3(a0, t0.x + 0.2, t0.y + 0.4), height, bay, home, i / every_tower)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = _bay_material(kit["mesh"])
	root.add_child(mmi)


## The bay's own textures in the tint shader.
static func _bay_material(mesh: Mesh) -> ShaderMaterial:
	var source := mesh.surface_get_material(0) as StandardMaterial3D
	var mat := ShaderMaterial.new()
	mat.shader = BAY_TINT
	if source != null:
		mat.set_shader_parameter("albedo_tex", source.albedo_texture)
		if source.normal_texture != null:
			mat.set_shader_parameter("normal_tex", source.normal_texture)
			mat.set_shader_parameter("has_normal", true)
		var orm: Texture2D = source.roughness_texture if source.roughness_texture != null else source.metallic_texture
		if orm != null:
			mat.set_shader_parameter("orm_tex", orm)
			mat.set_shader_parameter("has_orm", true)
	return mat


## A tower standing through the facade at a bay edge, with its cap and a
## lit window.
func _tower(stadium: Stadium, root: Node3D, piece: StadiumPiece, e: Vector3, height: float, bay: float, home: TeamDef, index: int = 0) -> void:
	var def := stadium.def
	# Alternate towers stand taller, so a run of them reads as a skyline.
	var lift := 1.0 + 0.35 * float(index % 2) + 0.15 * float(index % 3 == 2)
	var cap := StringName(piece.param("cap"))
	if cap == &"pagoda":
		# A sculpted five-tier pagoda standing through the facade.
		var pagoda := ModelKit.spawn(&"pagoda", (height + float(piece.param("tower_height")) * piece.size) * lift + 6.0, RandomNumberGenerator.new())
		root.add_child(pagoda)
		pagoda.position = stadium.point(e.x, e.y + 1.5, e.z)
		return
	var tw := clampf(bay * 0.55, 2.5, 6.0)
	var tall := height + float(piece.param("tower_height")) * piece.size * lift
	var stone := def.facade_tint().darkened(0.08)
	var trim := def.facade_tint().lightened(0.18)
	var tower := Node3D.new()
	root.add_child(tower)
	tower.position = stadium.point(e.x, e.y + tw * 0.2, e.z)
	stadium.face_home(tower)
	var body := stadium.box(Vector3(tw, tall, tw), stone, tower, &"facade")
	body.position.y = tall * 0.5
	# Plinth, string courses and stacked lit windows up the field face.
	var plinth := stadium.box(Vector3(tw * 1.12, tall * 0.08, tw * 1.12), stone.darkened(0.15), tower, &"facade")
	plinth.position.y = tall * 0.04
	var courses := maxi(2, int(tall / 7.0))
	for c in courses:
		var band := stadium.box(Vector3(tw * 1.06, 0.35, tw * 1.06), trim, tower, &"facade")
		band.position.y = tall * float(c + 1) / (courses + 1)
	var lit := Stadium.glow(def.window_color, 1.6 if def.night else 0.3)
	for w in mini(3, courses):
		var window := stadium.box(Vector3(tw * 0.26, tw * 0.5, 0.12), def.window_color, tower)
		window.position = Vector3(0, tall * (float(w) + 1.5) / (courses + 1), tw * 0.5 + 0.05)
		window.material_override = lit
	var roof := home.primary_color.darkened(0.2)
	match cap:
		&"spire":
			# A flared skirt, a collar, the spire, a ball finial and a pennant.
			var eave := stadium.box(Vector3(tw * 1.18, 0.5, tw * 1.18), trim, tower, &"facade")
			eave.position.y = tall + 0.25
			var skirt := Scenery.cylinder(tower, tw * 0.86, tw * 0.62, tw * 0.45, roof, 8)
			skirt.position.y = tall + 0.5 + tw * 0.22
			var spire := Scenery.cylinder(tower, tw * 0.62, 0.05, tw * 2.0, roof, 8)
			spire.position.y = tall + 0.5 + tw * 0.45 + tw * 1.0
			var collar := Scenery.cylinder(tower, tw * 0.3, tw * 0.3, 0.3, def.accent_color, 8)
			collar.position.y = tall + 0.5 + tw * 1.25
			collar.material_override = Stadium.glow(def.accent_color, 0.4)
			var top := tall + 0.5 + tw * 2.45
			var ball := Scenery.sphere(tower, tw * 0.1, def.accent_color)
			ball.position.y = top + 0.1
			var mast := Scenery.cylinder(tower, 0.06, 0.06, tw * 0.9, Color(0.2, 0.2, 0.2), 4)
			mast.position.y = top + tw * 0.45
			var pennant := stadium.box(Vector3(tw * 0.55, tw * 0.22, 0.05), home.primary_color if index % 2 == 0 else home.secondary_color, tower)
			pennant.position = Vector3(tw * 0.28, top + tw * 0.75, 0)
		&"dome":
			var drum := Scenery.cylinder(tower, tw * 0.55, tw * 0.55, tw * 0.4, trim, 16)
			drum.position.y = tall + tw * 0.2
			for k in 8:
				var rib := stadium.box(Vector3(0.18, tw * 0.42, 0.18), stone, tower)
				var ang := TAU * k / 8.0
				rib.position = Vector3(cos(ang) * tw * 0.56, tall + tw * 0.2, sin(ang) * tw * 0.56)
			var dome := Scenery.sphere(tower, tw * 0.56, def.accent_color.darkened(0.15), 0.9)
			dome.position.y = tall + tw * 0.4
			var lantern := Scenery.cylinder(tower, tw * 0.14, tw * 0.14, tw * 0.3, def.window_color, 8)
			lantern.position.y = tall + tw * 0.95
			lantern.material_override = lit
			var finial := Scenery.cylinder(tower, 0.12, 0.0, tw * 0.6, def.accent_color, 6)
			finial.position.y = tall + tw * 1.4
		_:
			# Corbelled parapet: a projecting band, then merlons on all sides.
			var corbel := stadium.box(Vector3(tw * 1.2, tw * 0.22, tw * 1.2), stone.darkened(0.1), tower, &"facade")
			corbel.position.y = tall + tw * 0.11
			for side in 4:
				for m in 3:
					var merlon := stadium.box(Vector3(tw * 0.24, tw * 0.32, tw * 0.2), stone, tower, &"facade")
					var along := (-0.38 + 0.38 * m) * tw
					var out := tw * 0.5
					var p: Vector3 = [Vector3(along, 0, out), Vector3(along, 0, -out), Vector3(out, 0, along), Vector3(-out, 0, along)][side]
					merlon.position = p + Vector3.UP * (tall + tw * 0.38)


## A box-like column at a spray angle: front and two sides.
func _column(st: SurfaceTool, stadium: Stadium, angle: float, radius: float, base: float, tall: float, width: float, depth: float) -> void:
	var half := rad_to_deg(width * 0.5 / radius)
	var r0 := radius + 0.1
	var r1 := radius - depth
	var a0 := angle - half
	var a1 := angle + half
	_quad(st, stadium.point(a0, r1, base), stadium.point(a1, r1, base), stadium.point(a1, r1, base + tall), stadium.point(a0, r1, base + tall))
	_quad(st, stadium.point(a0, r0, base), stadium.point(a0, r1, base), stadium.point(a0, r1, base + tall), stadium.point(a0, r0, base + tall))
	_quad(st, stadium.point(a1, r1, base), stadium.point(a1, r0, base), stadium.point(a1, r0, base + tall), stadium.point(a1, r1, base + tall))


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_tri(st, a, b, c)
	_tri(st, a, c, d)


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _double_sided(mat: StandardMaterial3D) -> StandardMaterial3D:
	var m: StandardMaterial3D = mat.duplicate()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _commit(root: Node3D, st: SurfaceTool, mat: Material) -> void:
	st.generate_normals()
	var mesh := st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	root.add_child(mi)
