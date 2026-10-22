extends StadiumModule
## A cathedral on the skyline: a long nave with a pitched roof, twin front
## spires and a glowing rose window, set "distance" m behind the stands.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var k := piece.size
	var root := Node3D.new()
	root.name = stadium.unique_name("Cathedral")
	stadium.add_child(root)
	root.position = Scenery.behind(stadium, piece.angle, float(piece.param("distance")))
	stadium.face_home(root)
	var stone := def.facade_tint().lightened(0.1)
	var nave := stadium.box(Vector3(26, 34, 70) * k, stone, root, &"stone")
	nave.position = Vector3(0, 17, -45) * k
	var roof := Scenery.cylinder(root, 15.0 * k, 0.0, 14.0 * k, home.secondary_color.darkened(0.3), 4)
	roof.scale = Vector3(1.0, 1.0, 3.4)
	roof.rotation.y = PI * 0.25
	roof.position = Vector3(0, 41, -45) * k
	for side: float in [-1.0, 1.0]:
		var tower := stadium.box(Vector3(12, 62, 12) * k, stone, root, &"stone")
		tower.position = Vector3(side * 14, 31, -8) * k
		var spire := Scenery.cylinder(root, 7.5 * k, 0.0, 34.0 * k, home.secondary_color.darkened(0.3), 8)
		spire.position = Vector3(side * 14, 79, -8) * k
		for w in 3:
			var slit := stadium.box(Vector3(2.0, 7.0, 0.2) * k, def.window_color, root)
			slit.position = Vector3(side * 14, 18 + w * 13, -1.9) * k
			slit.material_override = Stadium.glow(def.window_color, 1.4 if def.night else 0.3)
	var front := stadium.box(Vector3(18, 40, 4) * k, stone, root, &"stone")
	front.position = Vector3(0, 20, -4) * k
	var rose := Scenery.cylinder(root, 6.0 * k, 6.0 * k, 0.6, home.accent_color, 24)
	rose.rotation.x = PI * 0.5
	rose.position = Vector3(0, 28, -1.6) * k
	rose.material_override = Stadium.glow(home.accent_color.lerp(def.window_color, 0.4), 1.6 if def.night else 0.6)
	var door := stadium.box(Vector3(8, 14, 0.4) * k, Color(0.15, 0.1, 0.08), root)
	door.position = Vector3(0, 7, -1.8) * k
