extends StadiumModule
## A natural backdrop ringing the far side of the park, across "span"
## degrees from the piece's angle: snowcapped peaks, or red-rock mesas and
## buttes (with a natural arch when "arch" is on). Far enough out to frame
## the skyline, close enough to loom over the outfield. "hills" are low
## rounded forested hills instead. Peaks take a "spread" (base radius per
## height: 0.75 a sharp alp, 1.6 a broad volcano like Fuji) and a "snow"
## line (fraction of the height).


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("mountains" + stadium.def.id + str(piece.angle))
	var root := Node3D.new()
	root.name = stadium.unique_name("Mountains")
	stadium.add_child(root)
	var mesa := StringName(piece.param("style")) == &"mesa"
	var hills := StringName(piece.param("style")) == &"hills"
	var spread := float(piece.param("spread"))
	var snow_line := float(piece.param("snow"))
	if StringName(piece.param("style")) == &"volcano":
		_volcano(stadium, root, piece)
		return
	var count := int(piece.param("count"))
	var tall := float(piece.param("height")) * piece.size
	var rock := Color(0.66, 0.3, 0.18) if mesa else Color(0.42, 0.46, 0.55)
	for i in count:
		var angle := piece.angle + float(piece.param("span")) * (i + rng.randf_range(0.2, 0.8)) / count
		var spot := stadium.point(angle, float(piece.param("distance")) * rng.randf_range(0.85, 1.2), 0.0)
		var h := tall * rng.randf_range(0.6, 1.15)
		if hills:
			# A forested hill: a low rounded dome, dark green, its crown a
			# shade lighter where the sun reaches.
			var w := h * rng.randf_range(1.8, 2.6)
			var green := Color(0.3, 0.46, 0.22).darkened(rng.randf_range(0.0, 0.2))
			var prof := []
			for k in 8:
				var t := k / 7.0
				prof.append(Vector3(w * cos(t * PI * 0.5), h * pow(sin(t * PI * 0.5), 0.8), 0.0))
			var hill := Scenery.lathe(root, prof, 20, 0.12, rng, StadiumSurfaces.material(&"rock", green, true, 1.0 + h / 40.0))
			hill.position = spot
			hill.rotation.y = rng.randf() * TAU
		elif mesa:
			# A butte: a talus apron, sheer eroded walls banded with strata
			# (light and dark rings), a dark caprock overhanging the top.
			var w := h * rng.randf_range(0.5, 1.1)
			var mat := StadiumSurfaces.material(&"rock", rock.darkened(rng.randf_range(0.0, 0.15)), true, 1.0 + h / 60.0)
			var prof := [Vector3(w * 1.25, 0.0, 0.25), Vector3(w * 1.02, h * 0.12, 0.1), Vector3(w * 0.9, h * 0.2, 0.0)]
			var y := 0.2
			var band := 0
			while y < 0.9:
				var step := rng.randf_range(0.06, 0.13)
				prof.append(Vector3(w * (0.86 - y * 0.08) * rng.randf_range(0.97, 1.03), h * (y + step), [0.0, 0.18, -0.15, 0.08][band % 4]))
				y += step
				band += 1
			prof.append(Vector3(w * 0.84, h * 0.94, 0.45))
			prof.append(Vector3(w * 0.8, h, 0.4))
			prof.append(Vector3(0.0, h, 0.4))
			var butte := Scenery.lathe(root, prof, 22, 0.12, rng, mat)
			butte.position = spot
			butte.rotation.y = rng.randf() * TAU
		else:
			# A peak: concave flanks, ridged by the per-side jitter, snow above
			# the tree line (white vertex color on a snow-dusted rock texture).
			# A broad volcano is smooth-sided and blue in the distance; an alp
			# is craggy.
			var broad := spread > 1.2
			var jitter := 0.08 if broad else 0.22
			var tone := Color(0.5, 0.58, 0.72) if broad else rock
			var mat := StadiumSurfaces.material(&"rock", tone.darkened(rng.randf_range(0.0, 0.2)), true, 1.0 + h / 60.0)
			var prof := []
			for k in 9:
				var t := k / 8.0
				prof.append(Vector3(h * spread * pow(1.0 - t, 1.35), h * t, 0.0))
			var peak := Scenery.lathe(root, prof, 18, jitter, rng, mat)
			peak.position = spot
			peak.rotation.y = rng.randf() * TAU
			var snow_prof := []
			for k in 4:
				var t := snow_line + (1.0 - snow_line) * k / 3.0
				snow_prof.append(Vector3(h * spread * pow(1.0 - t, 1.35) * (1.12 if broad else 1.06), h * t, 0.0))
			var snow := Scenery.lathe(root, snow_prof, 18, jitter * 0.5, rng, StadiumSurfaces.material(&"snow", Color(0.97, 0.98, 1.0), false, 3.0))
			snow.position = spot + Vector3.UP * 0.2
			snow.rotation.y = peak.rotation.y
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
		arch.material_override = StadiumSurfaces.material(&"rock", rock, false, 2.0)
		root.add_child(arch)
		arch.look_at_from_position(spot, Vector3(0, 0, 0), Vector3.UP)
		arch.rotate_object_local(Vector3.RIGHT, PI * 0.5)


## One great volcano: a dark cone with a crater, glowing lava streaks down
## its flanks, a lava glow in the crater and smoke rising from it.
func _volcano(stadium: Stadium, root: Node3D, piece: StadiumPiece) -> void:
	var tall := float(piece.param("height")) * piece.size
	var spot := stadium.point(piece.angle, float(piece.param("distance")), 0.0)
	# A concave cone, ridged and gullied, darker toward the summit where
	# the ash lies, with a crater rim.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("volcano" + stadium.def.id)
	var prof := []
	for k in 11:
		var t := k / 10.0
		prof.append(Vector3(tall * (0.12 + 0.78 * pow(1.0 - t, 1.6)), tall * t, 0.1 + 0.45 * t))
	prof.append(Vector3(tall * 0.14, tall * 1.02, 0.6))
	prof.append(Vector3(tall * 0.1, tall * 0.97, 0.75))
	prof.append(Vector3(0.0, tall * 0.97, 0.8))
	var cone := Scenery.lathe(root, prof, 28, 0.08, rng, StadiumSurfaces.material(&"rock", Color(0.36, 0.3, 0.28), true, 3.0))
	cone.position = spot
	var lava := Stadium.glow(Color(0.95, 0.22, 0.03), 1.2)
	var crater := Scenery.cylinder(root, tall * 0.1, tall * 0.1, 1.0, Color.ORANGE, 14)
	crater.position = spot + Vector3.UP * (tall + 0.2)
	crater.material_override = lava
	# Lava streaks running down the field-facing flank, crater to foot.
	var toward := (Vector3(0, 0, 0) - spot)
	toward.y = 0.0
	toward = toward.normalized()
	for k in 5:
		var side := toward.rotated(Vector3.UP, deg_to_rad(-40.0 + k * 20.0 + rng.randf_range(-5.0, 5.0)))
		# Down the concave flank in segments, narrowing as it cools.
		var reach := 0.55 + 0.1 * (k % 3)
		for seg in 6:
			var t0 := 1.0 - reach * seg / 6.0
			var t1 := 1.0 - reach * (seg + 1) / 6.0
			var a := spot + side * tall * (0.12 + 0.78 * pow(1.0 - t0, 1.6) + 0.015) + Vector3.UP * tall * t0
			var b := spot + side * tall * (0.12 + 0.78 * pow(1.0 - t1, 1.6) + 0.015) + Vector3.UP * tall * t1
			var stream := stadium.box(Vector3(tall * 0.014 * (1.0 - seg * 0.12), tall * 0.008, a.distance_to(b)), Color.ORANGE, root)
			stream.position = (a + b) * 0.5
			stream.look_at_from_position(stream.position, b, Vector3.UP)
			stream.material_override = lava
	var smoke := CPUParticles3D.new()
	smoke.amount = 30
	smoke.lifetime = 10.0
	smoke.preprocess = 10.0
	smoke.direction = Vector3(0.2, 1.0, 0.0)
	smoke.spread = 15.0
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 10.0
	smoke.gravity = Vector3(1.5, 0.5, 0.0)
	smoke.scale_amount_min = tall * 0.08
	smoke.scale_amount_max = tall * 0.16
	var puff := SphereMesh.new()
	puff.radial_segments = 8
	puff.rings = 4
	smoke.mesh = puff
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.22, 0.22, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke.material_override = mat
	smoke.position = spot + Vector3.UP * tall
	root.add_child(smoke)
