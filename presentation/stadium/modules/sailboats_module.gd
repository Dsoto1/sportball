extends StadiumModule
## Sailboats and a tall ship on the water beyond the stands (place it over
## the bay): hulls in the club's colors under white sails.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("sails" + str(piece.angle))
	var root := Node3D.new()
	root.name = stadium.unique_name("Sailboats")
	stadium.add_child(root)
	var count := int(piece.param("count"))
	for i in count:
		var angle := piece.angle + float(piece.param("span")) * (i + 0.5) / count
		var boat := Node3D.new()
		root.add_child(boat)
		var tall_ship := i == count / 2
		var k := piece.size * (2.0 if tall_ship else rng.randf_range(0.8, 1.2))
		boat.position = Scenery.behind(stadium, angle, rng.randf_range(25.0, 120.0))
		boat.rotation.y = rng.randf() * TAU
		boat.scale = Vector3.ONE * k
		if tall_ship:
			boat.add_child(ModelKit.spawn(&"tall_ship", 12.0, rng))
			continue
		var hull := stadium.box(Vector3(2.6, 1.4, 9.0), home.primary_color if i % 2 == 0 else home.dark_color, boat)
		hull.position.y = 0.4
		var masts := 3 if tall_ship else 1
		for m in masts:
			var z := -2.5 + m * 2.5 if masts > 1 else 0.0
			var mast := stadium.box(Vector3(0.25, 11.0, 0.25), Color(0.4, 0.3, 0.2), boat)
			mast.position = Vector3(0, 6.5, z)
			var sail := stadium.box(Vector3(0.1, 8.0, 3.6 if masts == 1 else 2.2), Color(0.97, 0.96, 0.92), boat)
			sail.position = Vector3(0.2, 6.5, z + (1.6 if masts == 1 else 0.0))
