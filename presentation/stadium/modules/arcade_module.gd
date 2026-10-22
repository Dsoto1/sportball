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
##            cliff (canyons, volcanoes).
## Arches stack in "tiers" rows (2-3 for a colosseum or an aqueduct).
## Every "towers" bays a tower rises "tower_height" m above the facade,
## capped with a spire, dome, tiered pagoda roof or crenellations ("cap").
## The openings glow warm at night. Every "banners" bays a column carries
## a hanging banner in the club's color with its emblem (0 for none).


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
	for e in tower_spots:
		_tower(stadium, root, piece, e, height, bay, home)
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


## A tower standing through the facade at a bay edge, with its cap and a
## lit window.
func _tower(stadium: Stadium, root: Node3D, piece: StadiumPiece, e: Vector3, height: float, bay: float, home: TeamDef) -> void:
	var def := stadium.def
	var tw := clampf(bay * 0.55, 2.5, 6.0)
	var tall := height + float(piece.param("tower_height")) * piece.size
	var tower := Node3D.new()
	root.add_child(tower)
	tower.position = stadium.point(e.x, e.y + tw * 0.2, e.z)
	stadium.face_home(tower)
	var body := stadium.box(Vector3(tw, tall, tw), def.facade_tint().darkened(0.08), tower, &"facade")
	body.position.y = tall * 0.5
	var window := stadium.box(Vector3(tw * 0.3, tw * 0.6, 0.1), def.window_color, tower)
	window.position = Vector3(0, tall - tw * 0.9, tw * 0.5 + 0.05)
	window.material_override = Stadium.glow(def.window_color, 1.6 if def.night else 0.3)
	var roof := home.primary_color.darkened(0.2) if StringName(piece.param("cap")) != &"pagoda" else Color(0.14, 0.13, 0.15)
	match StringName(piece.param("cap")):
		&"spire":
			var spire := Scenery.cylinder(tower, tw * 0.75, 0.0, tw * 1.8, roof, 8)
			spire.position.y = tall + tw * 0.9
		&"dome":
			var dome := Scenery.sphere(tower, tw * 0.62, def.accent_color.darkened(0.15), 0.9)
			dome.position.y = tall
			var finial := Scenery.cylinder(tower, 0.15, 0.0, tw * 0.6, def.accent_color, 6)
			finial.position.y = tall + tw * 0.75
		&"pagoda":
			for k in 3:
				var w := tw * (1.25 - k * 0.28)
				var eave := Scenery.cylinder(tower, w * 0.95, w * 0.35, tw * 0.32, roof, 4)
				eave.rotation.y = PI * 0.25
				eave.position.y = tall + k * tw * 0.5 + tw * 0.16
				if k < 2:
					var drum := stadium.box(Vector3(w * 0.5, tw * 0.22, w * 0.5), def.facade_tint(), tower, &"facade")
					drum.position.y = tall + k * tw * 0.5 + tw * 0.42
		_:
			for m in 4:
				var merlon := stadium.box(Vector3(tw * 0.26, tw * 0.3, tw * 0.26), def.facade_tint().darkened(0.08), tower, &"facade")
				merlon.position = Vector3((-0.37 + 0.74 * (m % 2)) * tw, tall + tw * 0.15, (-0.37 + 0.74 * (m / 2)) * tw)


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
