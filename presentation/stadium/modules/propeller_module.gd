extends StadiumModule
## Propeller towers behind the stands across "span" degrees: a brass
## lattice tower carrying a big spinning propeller facing the field.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var root := Node3D.new()
	root.name = stadium.unique_name("Propellers")
	stadium.add_child(root)
	var brass := home.secondary_color.lerp(Color(0.8, 0.6, 0.3), 0.4)
	var tall := float(piece.param("height")) * piece.size
	var i := 0
	var lib := AnimationLibrary.new()
	var spin := Animation.new()
	spin.length = 2.0
	spin.loop_mode = Animation.LOOP_LINEAR
	var paths: Array[NodePath] = []
	for angle in Scenery.spread(piece.angle, float(piece.param("span")), int(piece.param("count"))):
		var top := stadium.skyline_top(angle)
		var tower := Node3D.new()
		tower.name = "Tower%d" % i
		root.add_child(tower)
		tower.position = stadium.point(angle, top.x + 6.0, 0.0)
		stadium.face_home(tower)
		var mast := stadium.box(Vector3(2.4, top.y + tall, 2.4), brass.darkened(0.3), tower, &"steel")
		mast.position.y = (top.y + tall) * 0.5
		var hub := Node3D.new()
		hub.name = "Hub"
		tower.add_child(hub)
		hub.position = Vector3(0, top.y + tall, 2.0)
		var nose := Scenery.sphere(hub, 1.4, brass)
		nose.scale = Vector3(1, 1, 1.4)
		for b in 4:
			var blade := Node3D.new()
			hub.add_child(blade)
			blade.rotation.z = TAU * b / 4.0
			var wood := stadium.box(Vector3(1.4, tall * 0.42, 0.25), Color(0.55, 0.36, 0.2), blade, &"wood")
			wood.position.y = tall * 0.22
			wood.rotation.y = 0.35
		var track := spin.add_track(Animation.TYPE_VALUE)
		spin.track_set_path(track, NodePath("Tower%d/Hub:rotation:z" % i))
		spin.track_insert_key(track, 0.0, 0.0)
		spin.track_insert_key(track, 2.0, TAU * (1 if i % 2 == 0 else -1))
		i += 1
	lib.add_animation(&"spin", spin)
	var player := AnimationPlayer.new()
	root.add_child(player)
	player.add_animation_library(&"", lib)
	player.autoplay = &"spin"
