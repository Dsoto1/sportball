extends StadiumModule
## A giant round bank-vault door set in a tall wall behind the stands: a
## riveted steel ring, a spoked wheel, locking bolts and red warning lights.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var r := float(piece.param("radius")) * piece.size
	var top := stadium.stand_top(piece.angle)
	var spot := stadium.point(piece.angle, top.x + 3.0, 0.0)
	var root := Node3D.new()
	root.name = stadium.unique_name("VaultDoor")
	stadium.add_child(root)
	root.look_at_from_position(spot, spot + (spot - Vector3(0, spot.y, 0)), Vector3.UP)
	var steel := def.structure_color.darkened(0.2)
	var wall := stadium.box(Vector3(r * 2.8, r * 2.8, 3.0), def.structure_color.darkened(0.45), root)
	wall.position = Vector3(0, r * 1.4, -1.5)
	var center := Vector3(0, top.y + r + 1.0, 0.3)
	var ring := Scenery.cylinder(root, r, r, 1.6, steel, 40)
	ring.rotation.x = PI * 0.5
	ring.position = center
	var face := Scenery.cylinder(root, r * 0.82, r * 0.82, 1.9, steel.lightened(0.15), 40)
	face.rotation.x = PI * 0.5
	face.position = center
	for b in 12:
		var a := TAU * b / 12.0
		var bolt := Scenery.cylinder(root, r * 0.05, r * 0.05, 2.4, home.highlight_color, 10)
		bolt.rotation.x = PI * 0.5
		bolt.position = center + Vector3(cos(a), sin(a), 0.0) * r * 0.91
	var hub := Scenery.cylinder(root, r * 0.16, r * 0.16, 3.0, steel.darkened(0.3), 20)
	hub.rotation.x = PI * 0.5
	hub.position = center
	for s in 6:
		var spoke := stadium.box(Vector3(r * 1.1, r * 0.06, 0.4), home.highlight_color, root)
		spoke.position = center + Vector3(0, 0, 1.4)
		spoke.rotation.z = PI * s / 6.0
	for side: float in [-1.0, 1.0]:
		var lamp := stadium.box(Vector3(0.8, r * 1.6, 0.6), home.accent_color, root)
		lamp.position = center + Vector3(side * r * 1.2, 0, 0.5)
		lamp.material_override = Stadium.glow(home.accent_color, 2.5 if def.night else 1.0)
