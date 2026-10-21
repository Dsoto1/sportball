extends StadiumModule
## A roof canopy over the top rows of the stands, from the piece's angle
## across "span" degrees: a sloped deck "depth" m deep cantilevered from
## the top of the facade (or the back of the stands), a lit trim along its
## front edge and struts back to the stands, in steel or timber.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var depth := float(piece.param("depth")) * piece.size
	var rise := float(piece.param("height"))
	var span := float(piece.param("span"))
	var timber := StringName(piece.param("style")) == &"timber"
	var steps := maxi(2, int(absf(span) / 2.0))
	var roof := SurfaceTool.new()
	roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var trim := SurfaceTool.new()
	trim.begin(Mesh.PRIMITIVE_TRIANGLES)
	var edges: Array[Array] = []
	for i in steps + 1:
		var a := piece.angle + span * i / steps
		var top := stadium.stand_top(a)
		var back := stadium.point(a, top.x + 0.2, top.y + rise)
		var front := stadium.point(a, top.x - depth, top.y + rise + depth * 0.18)
		edges.append([back, front])
	for i in steps:
		var b0: Vector3 = edges[i][0]
		var f0: Vector3 = edges[i][1]
		var b1: Vector3 = edges[i + 1][0]
		var f1: Vector3 = edges[i + 1][1]
		_quad(roof, b0, b1, f1, f0)
		_quad(trim, f0, f1, f1 + Vector3.DOWN * 0.9, f0 + Vector3.DOWN * 0.9)
	var root := Node3D.new()
	root.name = stadium.unique_name("Canopy")
	stadium.add_child(root)
	var mat: StandardMaterial3D = stadium.surface_mat(&"wood" if timber else &"steel", def.structure_color.darkened(0.3) if not timber else Color(0.45, 0.32, 0.22)).duplicate()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_commit(root, roof, mat)
	_commit(root, trim, Stadium.glow(def.accent_color, 1.2 if def.night else 0.4))
	# Struts from the front edge down to the stands, every few meters.
	for i in range(0, steps + 1, 3):
		var a := piece.angle + span * i / steps
		var top := stadium.stand_top(a)
		var foot := stadium.point(a, top.x - depth * 0.55, stadium.row_height(a, stadium.profile(a), maxi(0, int(stadium.profile(a).z) - int(depth * 0.55 / Stadium.ROW_DEPTH))))
		var head: Vector3 = edges[i][1]
		var strut := stadium.box(Vector3(0.35, 0.35, foot.distance_to(head)), def.structure_color.darkened(0.4), root, &"wood" if timber else &"steel")
		strut.position = (foot + head) * 0.5
		strut.look_at_from_position(strut.position, head, Vector3.UP)


static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for v in [a, b, c, a, c, d]:
		st.add_vertex(v)


static func _commit(root: Node3D, st: SurfaceTool, mat: Material) -> void:
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
