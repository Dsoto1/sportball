extends StadiumModule
## Fans up in the outfield architecture, not just in the seats: standing
## balconies across the face of the facade and a roof terrace along its top,
## from the piece's angle across "span" degrees. Each level is a ledge with
## a railing, "rows" deep, at a share of the facade's height ("levels",
## e.g. [0.5, 1.0] for a mid balcony and the roof), filled at "density".
## The center gap (scoreboard) is left clear. Where no facade stands, a
## level rises "lift" m over the top row of seats instead. Ledges stand
## "out" m in front of the facade line, clear of deep sculpted bays.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(String(def.id) + "terraces" + str(piece.angle))
	var span := float(piece.param("span"))
	var rows := int(piece.param("rows"))
	var density := float(piece.param("density"))
	var gap := float(piece.param("center_gap"))
	var levels: Array = piece.param("levels")
	var depth := 1.1
	var ledge_color := def.structure_color.darkened(0.2)
	var rail_color := def.accent_color.darkened(0.25)
	var ledges := SurfaceTool.new()
	ledges.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rails := SurfaceTool.new()
	rails.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seats: Array[Vector3] = []
	var step := 1.5
	var count := maxi(1, int(absf(span) / step))
	for level: float in levels:
		for i in count:
			var a0 := piece.angle + span * i / count
			var a1 := piece.angle + span * (i + 1) / count
			var mid := (a0 + a1) * 0.5
			if absf(wrapf(mid, -180.0, 180.0)) < gap:
				continue
			var top := stadium.stand_top(mid)
			var facade := stadium.facade_height(mid)
			var y := top.y + (facade * level if facade > 0.0 else float(piece.param("lift")) * level) + 0.6
			# The ledge sits proud of the facade face ("out" m toward the
			# field: sculpted bays stand deeper than the wall line).
			var r_back := top.x - 0.2 - float(piece.param("out"))
			var r_front := r_back - depth * rows - 0.4
			_box_arc(ledges, stadium, a0, a1, r_front, r_back, y - 0.35, y)
			_box_arc(rails, stadium, a0, a1, r_front - 0.08, r_front, y + 0.45, y + 0.6)
			# Fans along the ledge, rows stepping back.
			var radius := (r_front + r_back) * 0.5
			var arc := deg_to_rad(absf(a1 - a0)) * radius
			for k in rows:
				var r := r_front + 0.6 + k * depth
				var n := int(arc / 0.7)
				for f in n:
					if rng.randf() > density:
						continue
					var a := lerpf(a0, a1, (f + rng.randf_range(0.2, 0.8)) / n)
					seats.append(stadium.point(a, r, y + k * 0.12))
	var root := Node3D.new()
	root.name = stadium.unique_name("Terraces")
	stadium.add_child(root)
	_commit(root, ledges, stadium.surface_mat(def.structure_surface, ledge_color))
	_commit(root, rails, stadium.surface_mat(&"steel", rail_color))
	stadium.add_fans(seats, "TerraceFans")


## A curved slab between two angles and radii, from y0 to y1.
static func _box_arc(st: SurfaceTool, stadium: Stadium, a0: float, a1: float, r0: float, r1: float, y0: float, y1: float) -> void:
	var p := func(a: float, r: float, y: float) -> Vector3: return stadium.point(a, r, y)
	var faces := [
		[p.call(a0, r0, y1), p.call(a1, r0, y1), p.call(a1, r1, y1), p.call(a0, r1, y1)],  # top
		[p.call(a0, r0, y0), p.call(a1, r0, y0), p.call(a1, r0, y1), p.call(a0, r0, y1)],  # front
		[p.call(a0, r1, y0), p.call(a0, r1, y1), p.call(a1, r1, y1), p.call(a1, r1, y0)],  # back
		[p.call(a0, r0, y0), p.call(a0, r1, y0), p.call(a1, r1, y0), p.call(a1, r0, y0)],  # under
	]
	for f: Array in faces:
		st.add_vertex(f[0])
		st.add_vertex(f[1])
		st.add_vertex(f[2])
		st.add_vertex(f[0])
		st.add_vertex(f[2])
		st.add_vertex(f[3])


static func _commit(root: Node3D, st: SurfaceTool, mat: StandardMaterial3D) -> void:
	st.generate_normals()
	var mesh := st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m: StandardMaterial3D = mat.duplicate()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	root.add_child(mi)
