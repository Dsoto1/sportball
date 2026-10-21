extends StadiumModule
## A long arched bridge across the river beyond the stands, running
## sideways to the view from home, its arches lit at night.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Bridge")
	stadium.add_child(root)
	var center := Scenery.behind(stadium, piece.angle, float(piece.param("distance")))
	root.look_at_from_position(center, Vector3(0, 0, -45.0), Vector3.UP)
	root.rotate_y(PI * 0.5)
	root.scale = Vector3.ONE * piece.size
	var length := float(piece.param("length"))
	var spans := 4
	var arch_radius := length / spans * 0.46
	var deck_height := arch_radius * 0.92
	# The river under it, running out from the park.
	var river := stadium.box(Vector3(70.0, 0.1, length * 0.8), Stadium.WATER, root)
	river.position = Vector3(0, 0.05, 0)
	river.rotation.y = PI * 0.5
	var deck := stadium.box(Vector3(8.0, 1.5, length), def.structure_color.darkened(0.3), root)
	deck.position.y = deck_height
	for i in spans + 1:
		var z := -length * 0.5 + length * i / spans
		var tower := stadium.box(Vector3(9.0, deck_height + 14.0, 3.0), def.structure_color.darkened(0.15), root)
		tower.position = Vector3(0, (deck_height + 14.0) * 0.5, z)
	# Arches spring from the ground between the towers (half rings).
	for i in spans:
		var z := -length * 0.5 + length * (i + 0.5) / spans
		var arch := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = arch_radius - 1.6
		torus.outer_radius = arch_radius
		torus.rings = 32
		arch.mesh = torus
		arch.rotation = Vector3(0, 0, PI * 0.5)
		arch.position = Vector3(0, 0, z)
		arch.material_override = Stadium.glow(def.accent_color, 1.2 if def.night else 0.3)
		root.add_child(arch)
