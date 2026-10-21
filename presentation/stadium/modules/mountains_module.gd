extends StadiumModule
## A natural backdrop ringing the far side of the park, across "span"
## degrees from the piece's angle: snowcapped peaks, or red-rock mesas and
## buttes (with a natural arch when "arch" is on). Far enough out to frame
## the skyline, close enough to loom over the outfield.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("mountains" + stadium.def.id + str(piece.angle))
	var root := Node3D.new()
	root.name = stadium.unique_name("Mountains")
	stadium.add_child(root)
	var mesa := StringName(piece.param("style")) == &"mesa"
	var count := int(piece.param("count"))
	var tall := float(piece.param("height")) * piece.size
	var rock := Color(0.66, 0.3, 0.18) if mesa else Color(0.42, 0.46, 0.55)
	for i in count:
		var angle := piece.angle + float(piece.param("span")) * (i + rng.randf_range(0.2, 0.8)) / count
		var spot := stadium.point(angle, float(piece.param("distance")) * rng.randf_range(0.85, 1.2), 0.0)
		var h := tall * rng.randf_range(0.6, 1.15)
		if mesa:
			var w := h * rng.randf_range(1.0, 2.2)
			var butte := Scenery.cylinder(root, w * 0.55, w * 0.42, h, rock.darkened(rng.randf_range(0.0, 0.2)), 7)
			butte.position = spot + Vector3.UP * h * 0.5
			butte.rotation.y = rng.randf() * TAU
			# Strata: a paler band and a dark cap.
			var band := Scenery.cylinder(butte, w * 0.5, w * 0.48, h * 0.12, rock.lightened(0.25), 7)
			band.position.y = h * 0.1
			var cap := Scenery.cylinder(butte, w * 0.43, w * 0.43, h * 0.06, rock.darkened(0.35), 7)
			cap.position.y = h * 0.5
		else:
			var peak := Scenery.cylinder(root, h * 0.75, 0.0, h, rock.darkened(rng.randf_range(0.0, 0.2)), 7)
			peak.position = spot + Vector3.UP * h * 0.5
			peak.rotation.y = rng.randf() * TAU
			var snow := Scenery.cylinder(peak, h * 0.75 * 0.36, 0.0, h * 0.36, Color(0.95, 0.97, 1.0), 7)
			snow.position.y = h * 0.32
	if mesa and bool(piece.param("arch")):
		# A natural stone arch standing over the outfield horizon.
		var arch_angle := piece.angle + float(piece.param("span")) * 0.5
		var spot := stadium.point(arch_angle, float(piece.param("distance")) * 0.8, 0.0)
		var arch := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = tall * 0.55
		torus.outer_radius = tall * 0.8
		torus.rings = 24
		torus.ring_segments = 8
		arch.mesh = torus
		arch.material_override = GrayboxField._mat(rock)
		root.add_child(arch)
		arch.look_at_from_position(spot, Vector3(0, 0, 0), Vector3.UP)
		arch.rotate_object_local(Vector3.RIGHT, PI * 0.5)
