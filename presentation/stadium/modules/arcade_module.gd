extends StadiumModule
## The upper facade standing on the back edge of the stands, from the
## piece's angle across "span" degrees, in bays "bay" m wide:
##   arches:  a wall pierced by arched openings between columns (stone,
##            marble, brick parks);
##   windows: a wall with two rows of tall windows (warehouses, mills);
##   truss:   an open steel frame with X-bracing (industrial parks);
##   timber:  the same open frame in timber (lodges, piers).
## The openings glow warm at night. Every "banners" bays a column carries
## a hanging banner in the club's color with its emblem (0 for none).


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var style := StringName(piece.param("style"))
	var height := float(piece.param("height")) * piece.size
	var bay := float(piece.param("bay"))
	var span := float(piece.param("span"))
	var open_frame := style in [&"truss", &"timber"]
	var frame_surface: StringName = &"wood" if style == &"timber" else (&"steel" if style == &"truss" else &"structure")
	var frame_color := def.structure_color.darkened(0.15) if not open_frame else (Color(0.42, 0.3, 0.2) if style == &"timber" else def.structure_color.darkened(0.35))
	var wall := SurfaceTool.new()
	wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	var holes := SurfaceTool.new()
	holes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var banner_spots: Array[Transform3D] = []
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
		if not open_frame:
			_quad(wall, p.call(0.0, 0.0), p.call(1.0, 0.0), p.call(1.0, height), p.call(0.0, height))
			# Openings: arched (rectangle + half disc) or two rows of windows.
			if style == &"arches":
				var w := 0.5 - col
				var spring := height * 0.55
				_quad(holes, p.call(0.5 - w * 0.6, 0.0, 0.35), p.call(0.5 + w * 0.6, 0.0, 0.35), p.call(0.5 + w * 0.6, spring, 0.35), p.call(0.5 - w * 0.6, spring, 0.35))
				var chord := w * 0.6
				var rise := chord * bay
				for k in 10:
					var t0 := PI * k / 10.0
					var t1 := PI * (k + 1) / 10.0
					_tri(holes, p.call(0.5, spring, 0.35), p.call(0.5 + cos(t0) * chord, spring + sin(t0) * rise, 0.35), p.call(0.5 + cos(t1) * chord, spring + sin(t1) * rise, 0.35))
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
	_commit(root, wall, _double_sided(stadium.surface_mat(&"facade", def.facade_tint())))
	_commit(root, frame, _double_sided(stadium.surface_mat(frame_surface, frame_color)))
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.08, 0.07, 0.07)
	lit.emission_enabled = true
	lit.emission = def.window_color
	lit.emission_energy_multiplier = 0.7 if def.night else 0.1
	lit.cull_mode = BaseMaterial3D.CULL_DISABLED
	_commit(root, holes, lit)
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
