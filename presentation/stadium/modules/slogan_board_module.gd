extends StadiumModule
## A big lit sign over the stands: the home club's emblem, the park's name
## (or the piece's text) and the club's slogan underneath, framed in the
## park's accent.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var top := stadium.stand_top(piece.angle)
	var center := stadium.point(piece.angle, top.x + 2.0, top.y + float(piece.param("height")) * piece.size)
	var sign := Node3D.new()
	sign.name = stadium.unique_name("SloganBoard")
	stadium.add_child(sign)
	sign.look_at_from_position(center, center + (center - Vector3(0, center.y, 0)), Vector3.UP)
	sign.scale = Vector3.ONE * piece.size
	var frame := stadium.box(Vector3(26.0, 14.0, 1.0), def.accent_color, sign)
	frame.position.z = -0.7
	frame.material_override = Stadium.glow(def.accent_color, 1.2)
	var panel := stadium.box(Vector3(25.0, 13.0, 0.4), home.dark_color, sign)
	panel.position.z = -0.1
	var legs := stadium.box(Vector3(1.2, 10.0, 1.2), def.structure_color.darkened(0.3), sign)
	legs.position = Vector3(0, -12.0, -0.8)
	var emblem := Emblem.build(home, 4.4, 0.6)
	emblem.position = Vector3(-8.5, 1.6, 0.2)
	sign.add_child(emblem)
	var text := str(piece.param("text"))
	if text.is_empty():
		text = def.display_name
	# Long names shrink so each word stays whole on its line.
	var longest := 0
	for word in text.split(" "):
		longest = maxi(longest, word.length())
	var title := stadium.label(text.to_upper(), mini(150, int(1500.0 / maxi(longest, 1))), home.sign_color(), sign)
	title.position = Vector3(2.5, 2.2, 0.2)
	title.width = 1200.0
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	if not home.slogan.is_empty():
		var line := stadium.label(home.slogan, 90, home.highlight_color, sign)
		line.position = Vector3(0, -4.2, 0.2)
