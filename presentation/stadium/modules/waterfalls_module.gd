extends StadiumModule
## A waterfall beyond the outfield: a rock or masonry face over the stands
## with a shimmering sheet of water spilling into a pool, lit at night.
## Mirror it for a pair flanking the centerpiece. "frozen" makes it an ice
## fall: still, pale blue-white.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var k := piece.size
	# Stands on the back rows of the outfield stands, in front of any facade,
	# and rises above it, so the falls frame the centerpiece as on the sheets.
	var top := stadium.stand_top(piece.angle)
	var base := top.y - 1.0
	var height := float(piece.param("height")) * k + stadium.facade_height(piece.angle)
	var width := float(piece.param("width")) * k
	var spot := stadium.point(piece.angle, top.x - 2.5, base)
	var fall := Node3D.new()
	fall.name = stadium.unique_name("Waterfall")
	stadium.add_child(fall)
	fall.look_at_from_position(spot, spot + (spot - Vector3(0, spot.y, 0)), Vector3.UP)
	# A rock cliff face: stepped ledges the water spills over, darker rock
	# shoulders either side, plants on the ledges.
	var rock := def.structure_color.darkened(0.3).lerp(Color(0.42, 0.4, 0.38), 0.5)
	var face := stadium.box(Vector3(width + 4.0, height, 5.0), rock, fall, &"rock")
	face.position = Vector3(0, height * 0.5, -2.5)
	for side: float in [-1.0, 1.0]:
		var shoulder := stadium.box(Vector3(3.5, height * 0.8, 6.0), rock.darkened(0.15), fall, &"rock")
		shoulder.position = Vector3(side * (width * 0.5 + 2.6), height * 0.4, -1.5)
		shoulder.rotation.y = side * 0.25
	var water: Material
	var frozen := bool(piece.param("frozen"))
	if frozen:
		water = StadiumSurfaces.material(&"marble", Color(0.62, 0.82, 0.97), false, 2.0)
	else:
		water = ShaderMaterial.new()
		water.shader = Stadium.FOUNTAIN_SHADER
		water.set_shader_parameter("color", Color(0.48, 0.78, 0.98))
		water.set_shader_parameter("glow", 0.9 if def.night else 0.4)
	# Three tiers: each a sheet falling to a ledge that steps forward.
	var tiers := 3
	for t in tiers:
		var y0 := height * float(tiers - 1 - t) / tiers
		var y1 := height * float(tiers - t) / tiers
		var forward := t * 1.4
		var w := width * (1.0 - 0.12 * t)
		var sheet := stadium.box(Vector3(w, y1 - y0, 0.35), Color.WHITE, fall)
		sheet.position = Vector3(0, (y0 + y1) * 0.5, 0.2 + forward)
		sheet.material_override = water
		var ledge := stadium.box(Vector3(w + 1.6, 0.9, 2.2), rock.lightened(0.05), fall, &"rock")
		ledge.position = Vector3(0, y0, 1.0 + forward)
		var foam := stadium.box(Vector3(w + 0.4, 0.5, 1.2), Color(0.95, 0.98, 1.0), fall)
		foam.position = Vector3(0, y0 + 0.4, 1.4 + forward)
		foam.material_override = Stadium.glow(Color(0.92, 0.97, 1.0), 0.4)
		for b in 3:
			var bush := Scenery.sphere(fall, 1.0 + 0.3 * b, Color(0.22, 0.5, 0.25).darkened(0.1 * b), 0.8)
			bush.position = Vector3((w * 0.5 + 0.6) * (1.0 if b % 2 == 0 else -1.0), y0 + 0.9, 1.0 + forward)
	if not frozen:
		var mist := CPUParticles3D.new()
		mist.amount = 20
		mist.lifetime = 3.0
		mist.preprocess = 3.0
		mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		mist.emission_box_extents = Vector3(width * 0.5, 0.3, 0.6)
		mist.direction = Vector3(0, 1, 0.4)
		mist.spread = 30.0
		mist.initial_velocity_min = 1.0
		mist.initial_velocity_max = 2.5
		mist.gravity = Vector3.ZERO
		mist.scale_amount_min = 1.5
		mist.scale_amount_max = 3.0
		var puff := SphereMesh.new()
		puff.radial_segments = 8
		puff.rings = 4
		mist.mesh = puff
		var mm := StandardMaterial3D.new()
		mm.albedo_color = Color(0.95, 0.98, 1.0, 0.3)
		mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mist.material_override = mm
		mist.position = Vector3(0, 0.8, 3.0 + tiers * 1.4)
		fall.add_child(mist)
	var pool := stadium.box(Vector3(width + 6.0, 0.8, 7.0), def.structure_color, fall, &"stone")
	pool.position = Vector3(0, 0.4, 3.0 + tiers * 1.4)
	var surface := stadium.box(Vector3(width + 5.0, 0.1, 6.0), Stadium.WATER, fall)
	surface.position = Vector3(0, 0.82, 3.0 + tiers * 1.4)
	surface.material_override = water
