extends StadiumModule
## Bronze statues on pedestals atop the outfield stands: a charging bull
## (or a figure), facing the field.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var bronze := Color(0.55, 0.38, 0.2)
	var root := Node3D.new()
	root.name = stadium.unique_name("Statue")
	stadium.add_child(root)
	var top := stadium.skyline_top(piece.angle)
	var spot := stadium.point(piece.angle, top.x - 1.0, top.y + 0.6)
	root.look_at_from_position(spot, Vector3(0, spot.y, -45.0), Vector3.UP)
	root.scale = Vector3.ONE * piece.size
	var pedestal := stadium.box(Vector3(5.0, 2.4, 3.0), stadium.def.structure_color.lightened(0.15), root, &"marble")
	pedestal.position.y = 1.2
	if StringName(piece.param("figure")) == &"bull":
		var body := Scenery.sphere(root, 1.6, bronze, 0.8)
		body.scale = Vector3(1.0, 1.0, 1.9)
		body.position = Vector3(0, 4.4, 0)
		var head := Scenery.sphere(root, 0.9, bronze)
		head.position = Vector3(0, 4.4, -3.0)
		for side: float in [-1.0, 1.0]:
			var horn := Scenery.cylinder(root, 0.18, 0.04, 1.4, Color(0.85, 0.8, 0.6), 6)
			horn.position = Vector3(side * 0.9, 5.2, -3.2)
			horn.rotation.z = -side * 0.9
			for end: float in [-1.0, 1.0]:
				var leg := Scenery.cylinder(root, 0.3, 0.25, 1.8, bronze, 6)
				leg.position = Vector3(side * 0.8, 3.0, end * 1.6)
	else:
		var figure := Scenery.cylinder(root, 0.8, 0.6, 4.0, bronze, 10)
		figure.position.y = 4.4
		var head := Scenery.sphere(root, 0.55, bronze)
		head.position.y = 6.9
