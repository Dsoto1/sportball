extends StadiumModule
## A waterfall beyond the outfield: a rock or masonry face over the stands
## with a shimmering sheet of water spilling into a pool, lit at night.
## Mirror it for a pair flanking the centerpiece. "frozen" makes it an ice
## fall: still, pale blue-white.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var k := piece.size
	var height := float(piece.param("height")) * k
	var width := float(piece.param("width")) * k
	var top := stadium.stand_top(piece.angle)
	var spot := stadium.point(piece.angle, top.x + 6.0, 0.0)
	var fall := Node3D.new()
	fall.name = stadium.unique_name("Waterfall")
	stadium.add_child(fall)
	fall.look_at_from_position(spot, spot + (spot - Vector3(0, spot.y, 0)), Vector3.UP)
	var face := stadium.box(Vector3(width + 4.0, height, 5.0), def.structure_color.darkened(0.25), fall)
	face.position = Vector3(0, height * 0.5, -2.5)
	var lip := stadium.box(Vector3(width + 4.4, 0.8, 5.4), def.accent_color, fall)
	lip.position = Vector3(0, height, -2.5)
	lip.material_override = Stadium.glow(def.accent_color, 0.8)
	var water: Material
	if bool(piece.param("frozen")):
		water = Stadium.glow(Color(0.82, 0.93, 1.0), 0.35)
	else:
		water = ShaderMaterial.new()
		water.shader = Stadium.FOUNTAIN_SHADER
		water.set_shader_parameter("color", Color(0.75, 0.92, 1.0))
		water.set_shader_parameter("glow", 0.8 if def.night else 0.25)
	var sheet := stadium.box(Vector3(width, height, 0.3), Color.WHITE, fall)
	sheet.position = Vector3(0, height * 0.5, 0.2)
	sheet.material_override = water
	var pool := stadium.box(Vector3(width + 6.0, 0.8, 7.0), def.structure_color, fall)
	pool.position = Vector3(0, 0.4, 3.0)
	var surface := stadium.box(Vector3(width + 5.0, 0.1, 6.0), Stadium.WATER, fall)
	surface.position = Vector3(0, 0.82, 3.0)
	surface.material_override = water
