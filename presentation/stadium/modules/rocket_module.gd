extends StadiumModule
## A rocket sculpture standing behind the outfield stands: a tall body in
## the club's colors on a launch gantry, fins, a nose cone and a lit
## exhaust ring.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var tall := float(piece.param("height")) * piece.size
	var root := Node3D.new()
	root.name = stadium.unique_name("Rocket")
	stadium.add_child(root)
	root.position = Scenery.behind(stadium, piece.angle, 6.0)
	var body := Scenery.cylinder(root, tall * 0.07, tall * 0.07, tall * 0.7, Color(0.94, 0.92, 0.88), 16)
	body.position.y = tall * 0.45
	for band in 2:
		var stripe := Scenery.cylinder(body, tall * 0.072, tall * 0.072, tall * 0.05, home.primary_color, 16)
		stripe.position.y = -tall * 0.1 + band * tall * 0.2
	var nose := Scenery.cylinder(root, tall * 0.07, 0.0, tall * 0.2, home.primary_color, 16)
	nose.position.y = tall * 0.9
	for f in 4:
		var fin := stadium.box(Vector3(0.4, tall * 0.16, tall * 0.1), home.secondary_color, root)
		var a := TAU * f / 4.0
		fin.position = Vector3(cos(a), 0.0, sin(a)) * tall * 0.09 + Vector3.UP * tall * 0.17
		fin.rotation.y = -a
	var ring := Scenery.cylinder(root, tall * 0.075, tall * 0.075, tall * 0.02, home.accent_color, 16)
	ring.position.y = tall * 0.1
	ring.material_override = Stadium.glow(home.accent_color, 2.0)
	var gantry := stadium.box(Vector3(2.0, tall * 0.85, 2.0), stadium.def.structure_color.darkened(0.3), root, &"steel")
	gantry.position = Vector3(tall * 0.14, tall * 0.425, 0.0)
