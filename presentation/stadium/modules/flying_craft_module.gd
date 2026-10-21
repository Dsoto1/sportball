extends StadiumModule
## Flying craft over the park: saucer cars or blimps, in the club's colors
## with glowing rims, hovering above the skyline.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("craft" + stadium.def.id)
	var root := Node3D.new()
	root.name = stadium.unique_name("FlyingCraft")
	stadium.add_child(root)
	var blimp := StringName(piece.param("style")) == &"blimp"
	for i in int(piece.param("count")):
		var angle := rng.randf_range(-70.0, 70.0)
		var craft := Node3D.new()
		root.add_child(craft)
		craft.position = stadium.point(angle, rng.randf_range(170.0, 320.0), rng.randf_range(60.0, 110.0))
		craft.rotation.y = rng.randf() * TAU
		craft.scale = Vector3.ONE * piece.size
		if blimp:
			var body := Scenery.sphere(craft, 6.0, home.primary_color, 0.45)
			body.scale = Vector3(1.0, 1.0, 2.6)
			var gondola := Scenery.cylinder(craft, 1.2, 1.2, 3.0, home.dark_color, 8)
			gondola.position.y = -3.4
		else:
			var hull := Scenery.sphere(craft, 4.0, home.primary_color, 0.3)
			var dome := Scenery.sphere(craft, 1.6, Color(0.7, 0.9, 1.0), 0.8)
			dome.position.y = 1.0
			var rim := Scenery.cylinder(craft, 4.1, 4.1, 0.3, home.accent_color, 24)
			rim.material_override = Stadium.glow(home.accent_color, 2.0)
