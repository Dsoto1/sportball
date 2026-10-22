extends StadiumModule
## An elevated railway on an arched viaduct beyond the stands, from the
## piece's angle across "span" degrees, with a train on it (lit windows,
## a puff of steam) when "train" is on.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var root := Node3D.new()
	root.name = stadium.unique_name("Viaduct")
	stadium.add_child(root)
	var span := float(piece.param("span"))
	# Deck height above the tallest thing in front (stands, facade), so the
	# train runs in view over the outfield.
	var height := float(piece.param("height")) * piece.size + stadium.skyline_top(piece.angle + float(piece.param("span")) * 0.5).y * 0.85
	var setback := float(piece.param("distance"))
	var steps := maxi(2, int(absf(span) / 4.0))
	var brick := def.structure_color.lerp(Color(0.55, 0.3, 0.22), 0.6)
	var spots: Array[Vector3] = []
	for i in steps + 1:
		spots.append(Scenery.behind(stadium, piece.angle + span * i / steps, setback))
	for i in steps:
		var a := spots[i]
		var b := spots[i + 1]
		var mid := (a + b) * 0.5
		var length := a.distance_to(b)
		var deck := stadium.box(Vector3(6.0, 1.6, length + 0.4), brick.darkened(0.15), root, &"brick")
		deck.position = mid + Vector3.UP * height
		deck.look_at_from_position(deck.position, b + Vector3.UP * height, Vector3.UP)
		var pier := stadium.box(Vector3(5.0, height, 2.4), brick, root, &"brick")
		pier.position = a + Vector3.UP * height * 0.5
		pier.look_at_from_position(pier.position, b + Vector3.UP * height * 0.5, Vector3.UP)
		# The arch between piers: a half ring under the deck.
		var arch := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = length * 0.38
		torus.outer_radius = length * 0.5
		torus.rings = 16
		torus.ring_segments = 6
		arch.mesh = torus
		arch.material_override = StadiumSurfaces.material(&"brick", brick)
		root.add_child(arch)
		arch.position = mid + Vector3.UP * (height - length * 0.5)
		arch.look_at_from_position(arch.position, arch.position + (b - a).cross(Vector3.UP), Vector3.UP)
		arch.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	if bool(piece.param("train")):
		var cars := 5
		for c in cars:
			var i := steps / 3 + c
			if i >= steps:
				break
			var a := spots[i]
			var b := spots[i + 1]
			if c == cars - 1:
				# The engine leads (a sculpted locomotive), facing along the track.
				var engine := Node3D.new()
				root.add_child(engine)
				engine.look_at_from_position((a + b) * 0.5 + Vector3.UP * (height + 0.8), b + Vector3.UP * (height + 0.8), Vector3.UP)
				var loco := ModelKit.spawn(&"locomotive", 5.5, RandomNumberGenerator.new())
				loco.rotation.y = PI * 0.5
				engine.add_child(loco)
				continue
			var car := stadium.box(Vector3(3.6, 3.4, a.distance_to(b) * 0.92), home.primary_color if c > 0 else home.dark_color, root)
			car.position = (a + b) * 0.5 + Vector3.UP * (height + 2.6)
			car.look_at_from_position(car.position, b + Vector3.UP * (height + 2.6), Vector3.UP)
			var windows := stadium.box(Vector3(3.7, 0.9, a.distance_to(b) * 0.8), Color.WHITE, car)
			windows.position.y = 0.5
			windows.material_override = Stadium.glow(def.window_color, 1.5 if def.night else 0.4)
