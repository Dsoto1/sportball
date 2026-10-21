extends StadiumModule
## A striped lighthouse beyond the stands with a glowing lamp room.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var tall := float(piece.param("height")) * piece.size
	var root := Node3D.new()
	root.name = stadium.unique_name("Lighthouse")
	stadium.add_child(root)
	root.position = Scenery.behind(stadium, piece.angle, 30.0)
	var rock := Scenery.sphere(root, 9.0, Color(0.42, 0.4, 0.38), 0.4)
	rock.material_override = StadiumSurfaces.material(&"rock", Color(0.5, 0.48, 0.45))
	var bands := 6
	for b in bands:
		var t0 := float(b) / bands
		var t1 := float(b + 1) / bands
		var seg := Scenery.cylinder(root, lerpf(3.2, 2.2, t0), lerpf(3.2, 2.2, t1), tall / bands, home.accent_color if b % 2 == 0 else Color(0.96, 0.96, 0.94), 16)
		seg.position.y = 2.0 + tall * (t0 + t1) * 0.5
	var gallery := Scenery.cylinder(root, 3.2, 3.2, 0.6, Color(0.15, 0.15, 0.17), 16)
	gallery.position.y = 2.0 + tall + 0.3
	var lamp := Scenery.cylinder(root, 1.8, 1.8, 3.0, Color(1.0, 0.95, 0.7), 16)
	lamp.position.y = 2.0 + tall + 2.1
	lamp.material_override = Stadium.glow(Color(1.0, 0.95, 0.7), 3.0 if stadium.def.night else 1.5)
	var cap := Scenery.cylinder(root, 2.4, 0.3, 2.4, home.accent_color.darkened(0.3), 16)
	cap.position.y = 2.0 + tall + 4.8
