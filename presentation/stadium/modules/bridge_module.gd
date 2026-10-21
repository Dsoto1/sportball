extends StadiumModule
## A long arched bridge beyond the stands, running out from the park at
## its angle so it spans a river there (place a water piece under it), its
## arches lit at night.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Bridge")
	stadium.add_child(root)
	# Centered on a river at its angle when there is one ("distance" 0 or
	# any river crossing there); otherwise "distance" m behind the stands.
	var center := Scenery.behind(stadium, piece.angle, float(piece.param("distance")))
	for water in stadium.def.pieces_of(&"water"):
		var band := Scenery.water_band(stadium, water, piece.angle)
		if band.y > band.x and StringName(water.param("style")) == &"river":
			center = stadium.point(piece.angle, (band.x + band.y) * 0.5, 0.0)
			break
	root.look_at_from_position(center, Vector3(0, 0, 0), Vector3.UP)
	root.scale = Vector3.ONE * piece.size
	var length := float(piece.param("length"))
	var spans := 4
	var arch_radius := length / spans * 0.46
	var deck_height := arch_radius * 0.92
	var deck := stadium.box(Vector3(8.0, 1.5, length), def.structure_color.darkened(0.3), root, &"steel")
	deck.position.y = deck_height
	for i in spans + 1:
		var z := -length * 0.5 + length * i / spans
		var tall := deck_height + arch_radius * 0.5
		var tower := stadium.box(Vector3(9.0, tall, minf(3.0, arch_radius * 0.25)), def.structure_color.darkened(0.15), root, &"stone")
		tower.position = Vector3(0, tall * 0.5, z)
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
