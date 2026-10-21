extends StadiumModule
## The Halo Dome's landmark: a glowing ring over the park on four pylons,
## its underside hung with the park's sponsor boards.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var height := float(piece.param("height"))
	var radius := float(piece.param("radius")) * piece.size
	var center := Stadium.FIELD_CENTER
	var ring := MeshInstance3D.new()
	ring.name = stadium.unique_name("Halo")
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 3.0
	torus.outer_radius = radius + 3.0
	torus.rings = 96
	torus.ring_segments = 12
	ring.mesh = torus
	ring.position = center + Vector3.UP * height
	ring.material_override = Stadium.glow(def.accent_color, 1.8)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stadium.add_child(ring)
	for i in 4:
		var a := TAU * (i + 0.5) / 4.0
		var foot := center + Vector3(cos(a), 0.0, sin(a)) * radius
		var pylon := stadium.box(Vector3(4.0, height, 4.0), def.structure_color)
		pylon.position = foot + Vector3.UP * height * 0.5
		var stripe := stadium.box(Vector3(4.2, height, 0.6), def.accent_color)
		stripe.position = foot + Vector3.UP * height * 0.5
		stripe.material_override = Stadium.glow(def.seat_color.lightened(0.3), 1.2)
		stripe.look_at_from_position(stripe.position, Vector3(center.x, stripe.position.y, center.z), Vector3.UP)
	var count := def.sponsors.size()
	for i in count:
		var a := TAU * i / count
		var spot := center + Vector3(cos(a), 0.0, sin(a)) * (radius - 1.0) + Vector3.UP * (height - 6.5)
		var board := Node3D.new()
		stadium.add_child(board)
		# Local +Z toward the middle of the park, so the text reads from inside.
		board.look_at_from_position(spot, spot + (spot - Vector3(center.x, spot.y, center.z)), Vector3.UP)
		var panel := stadium.box(Vector3(34.0, 7.0, 0.8), def.seat_color.darkened(0.3), board)
		panel.position = Vector3(0, 0, -0.4)
		var edge := stadium.box(Vector3(34.4, 0.4, 1.0), def.accent_color, board)
		edge.position = Vector3(0, -3.6, -0.3)
		edge.material_override = Stadium.glow(def.accent_color, 1.5)
		var text := stadium.label(def.sponsors[i], 230, Color.WHITE, board)
		text.position = Vector3(0, 0, 0.1)
		text.modulate = Color(1.0, 0.97, 0.9)
