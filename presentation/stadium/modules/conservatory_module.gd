extends StadiumModule
## A glass greenhouse dome on a stone drum behind the stands: green glass
## panes on white ribs, a finial on top, lit softly from inside.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var r := float(piece.param("radius")) * piece.size
	var root := Node3D.new()
	root.name = stadium.unique_name("Conservatory")
	stadium.add_child(root)
	root.position = Scenery.behind(stadium, piece.angle, r + 6.0)
	var drum := Scenery.cylinder(root, r, r, r * 0.6, stadium.def.structure_color.lightened(0.2), 24)
	drum.position.y = r * 0.3
	var glass := Scenery.sphere(root, r * 0.95, Color(0.55, 0.85, 0.75), 1.0)
	glass.position.y = r * 0.6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.85, 0.75, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.95, 0.8)
	mat.emission_energy_multiplier = 0.9 if stadium.def.night else 0.25
	mat.metallic = 0.2
	mat.roughness = 0.1
	glass.material_override = mat
	for rib in 8:
		var arc := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = r * 0.95
		torus.outer_radius = r * 0.98
		torus.rings = 32
		torus.ring_segments = 4
		arc.mesh = torus
		arc.material_override = GrayboxField._mat(Color(0.95, 0.95, 0.92))
		arc.rotation = Vector3(PI * 0.5, PI * rib / 8.0, 0.0)
		arc.position.y = r * 0.6
		root.add_child(arc)
	var finial := Scenery.cylinder(root, 0.5, 0.0, r * 0.4, stadium.def.accent_color, 8)
	finial.position.y = r * 1.75
