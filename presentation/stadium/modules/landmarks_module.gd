extends StadiumModule
## Tall landmarks rising behind the outfield stands in up to three rows of
## depth, each row taller, farther and hazier than the last, so the park
## sits in front of a layered city as on the sheets. Built from free Kenney
## kits (CC0), recolored to the park by the kit palette shader. "style":
## - castle: stacked stone towers (square and hexagon) with spires or
##   crenellated tops ("flat"), banners, curtain walls between them.
## - industrial: factory halls, tall chimneys, steel gantries with hoppers.
## - town: tall townhouse blocks and houses, some stacked, some chimneys.
## - harbor: stone lighthouse towers, dock pavilions and masts.
## - pagoda: tiered pagodas among blossom trees.
## Across "span" degrees from the piece's angle; "rows" deep (1-3).

const KITS := "res://assets/third_party/kenney/"
const PALETTE := preload("res://presentation/stadium/kit_palette.gdshader")
## Per row: extra distance, height factor, haze.
const ROWS := [[0.0, 1.0, 0.0], [70.0, 1.45, 0.16], [170.0, 1.95, 0.34]]

static var _scenes := {}
static var _boxes := {}

var _stadium: Stadium
var _rng: RandomNumberGenerator
var _mats := {}
var _colors := {}
var _haze := 0.0
var _flat := false
var _piece: StadiumPiece
var _style := &""
var _wall_surface := &"stone"


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	_stadium = stadium
	_piece = piece
	_rng = RandomNumberGenerator.new()
	_rng.seed = hash(String(stadium.def.id) + str(piece.angle) + str(piece.param("style")))
	var def := stadium.def
	var style := StringName(piece.param("style"))
	_style = style
	# The wall surface: the piece's "surface", else one that suits the style.
	_wall_surface = StringName(piece.param("surface"))
	if not StadiumSurfaces.KINDS.has(_wall_surface):
		_wall_surface = {&"town": &"brick", &"industrial": &"concrete", &"pagoda": &"wood"}.get(style, &"stone")
	_flat = bool(piece.param("flat"))
	var stone := def.facade_tint() if def.facade_color.a > 0.0 else def.structure_color
	_colors = {
		"stone": Color(piece.param("stone")) if Color(piece.param("stone")).a > 0.0 else stone,
		"metal": def.structure_color.darkened(0.25),
		"roof": Color(piece.param("roof")) if Color(piece.param("roof")).a > 0.0 else home.primary_color.darkened(0.15),
		"accent": home.secondary_color if home.secondary_color.get_luminance() < 0.85 else home.accent_color,
		"trim": home.accent_color,
		"window": def.window_color,
	}
	var look: Array = GrayboxField.SKIES.get(def.sky_kind(), GrayboxField.SKIES[&"day"])
	var horizon: Color = (look[1] as Color).lerp(look[0], 0.3)
	var root := Node3D.new()
	root.name = stadium.unique_name("Landmarks")
	stadium.add_child(root)
	var span := float(piece.param("span"))
	var height := float(piece.param("height")) * piece.size
	var rows := int(piece.param("rows"))
	for row in rows:
		var conf: Array = ROWS[row]
		_haze = float(conf[2])
		_mats = {}
		_colors["haze"] = horizon
		var a := piece.angle
		var end := piece.angle + span
		var dir := signf(span)
		while (end - a) * dir > 0.0:
			var top := stadium.skyline_top(a)
			var radius := top.x + float(piece.param("gap")) + float(conf[0]) + _rng.randf_range(0.0, 20.0)
			var h := maxf(height * float(conf[1]) * _rng.randf_range(0.7, 1.3), top.y + 12.0)
			var made: Array = _make(style, h)
			var node: Node3D = made[0]
			var width: float = made[1]
			var step := rad_to_deg(width * 1.05 / radius)
			a += step * 0.5 * dir
			# The front row leaves the center gap for the scoreboard, and the
			# front two rows leave room around any signature landmark.
			if (row == 0 and absf(wrapf(a, -180.0, 180.0)) < float(piece.param("center_gap"))) or (row < 2 and _near_hero(stadium, a)):
				node.free()
				a += step * 0.5 * dir
				continue
			node.position = stadium.point(a, radius, 0.0)
			stadium.face_home(node)
			node.rotation.y += _rng.randf_range(-0.12, 0.12)
			root.add_child(node)
			a += (step * 0.5 + _rng.randf_range(0.2, 1.6)) * dir


## Within a signature landmark's clear zone (its "clear" degrees).
static func _near_hero(stadium: Stadium, angle: float) -> bool:
	for hero in stadium.def.pieces_of(&"hero"):
		var angles := [hero.angle, -hero.angle] if hero.mirrored else [hero.angle]
		for h: float in angles:
			if absf(wrapf(angle - h, -180.0, 180.0)) < float(hero.param("clear")):
				return true
	return false


## One landmark of the style about h meters tall: [node, footprint width].
func _make(style: StringName, h: float) -> Array:
	match style:
		&"model":
			return _model(h)
		&"castle":
			return _castle(h)
		&"industrial":
			return _industrial(h)
		&"harbor":
			return _harbor(h)
		&"pagoda":
			return _pagoda(h)
		_:
			return _town(h)


## The park's architecture-set backdrop block ("model"), stood on its
## base, varied in height and turned a little; far rows fade toward the
## horizon color like the kit styles.
func _model(h: float) -> Array:
	var b := Node3D.new()
	var role := StringName(_piece.param("model"))
	if not ModelKit.has(role):
		return [b, 10.0]
	var m := ModelKit.spawn(role, h, _rng)
	var box := ModelKit._aabb(m)
	m.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * m.scale
	if _rng.randf() < 0.5:
		m.scale.x *= -1.0
		m.position.x *= -1.0
	b.add_child(m)
	if _haze > 0.0:
		for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
			var src := mi.mesh.surface_get_material(0) as StandardMaterial3D
			if src != null:
				if not _mats.has(src):
					var hazed: StandardMaterial3D = src.duplicate()
					hazed.albedo_color = Color.WHITE.lerp(_colors["haze"], _haze * 1.4)
					_mats[src] = hazed
				mi.material_override = _mats[src]
	return [b, maxf(box.size.x, box.size.z) * m.scale.y]


func _castle(h: float) -> Array:
	var b := Node3D.new()
	var w := _rng.randf_range(9.0, 15.0)
	var hex := _rng.randf() < 0.35
	var parts: Array[String] = []
	if hex:
		parts.append("tower-hexagon-base")
		var top := "tower-hexagon-top" if _flat else ("tower-hexagon-roof" if _rng.randf() < 0.7 else "tower-hexagon-top-wood")
		_stack(b, "castle-kit", parts, "tower-hexagon-mid", top, w, h)
	else:
		parts.append("tower-square-base-border" if _rng.randf() < 0.5 else "tower-square-base")
		var tops := ["tower-square-top"] if _flat else ["tower-square-top-roof-high", "tower-square-top-roof-high-windows", "tower-square-top-roof-rounded", "tower-square-top-roof-high"]
		_stack(b, "castle-kit", parts, "", tops[_rng.randi_range(0, tops.size() - 1)], w, h,
			["tower-square-mid", "tower-square-mid-windows", "tower-square-mid-windows", "tower-square-mid-color"])
	# A banner hung down the face.
	if _rng.randf() < 0.6:
		var banner := _part("castle-kit", "flag-banner-long")
		var k := (h * 0.35) / maxf(_box("castle-kit", "flag-banner-long").size.y, 0.01)
		banner.scale = Vector3.ONE * k
		banner.position = Vector3(0, h * 0.35, w * 0.52)
		b.add_child(banner)
	# A curtain wall reaching to the next tower.
	if _rng.randf() < 0.7:
		var wall := _part("castle-kit", "wall")
		var wb := _box("castle-kit", "wall")
		var k := (h * 0.32) / maxf(wb.size.y, 0.01)
		wall.scale = Vector3(w * 1.4 / maxf(wb.size.x, 0.01), k, k)
		wall.position = Vector3(w * 0.95 * (1.0 if _rng.randf() < 0.5 else -1.0), 0, -w * 0.1)
		b.add_child(wall)
	return [b, w * 1.6]


func _industrial(h: float) -> Array:
	var b := Node3D.new()
	var kind := _rng.randf()
	var w := _rng.randf_range(22.0, 34.0)
	if kind < 0.45:
		# A factory hall with chimneys standing out of it.
		var names := ["building-a", "building-b", "building-d", "building-e", "building-f", "building-g", "building-l", "building-m", "building-n"]
		var hall: String = names[_rng.randi_range(0, names.size() - 1)]
		_place(b, "city-kit-industrial", hall, w, Vector3.ZERO, true)
		for c in _rng.randi_range(1, 3):
			var chim: String = ["chimney-large", "chimney-medium", "chimney-basic"][_rng.randi_range(0, 2)]
			_place_h(b, "city-kit-industrial", chim, h * _rng.randf_range(0.7, 1.0), Vector3(_rng.randf_range(-0.35, 0.35) * w, 0, -w * 0.2))
	elif kind < 0.8:
		# A steel gantry: four legs of stacked frame sections, catwalks
		# bracing them every few levels, sometimes a hopper on top.
		w = _rng.randf_range(14.0, 20.0)
		var cols := ["structure-tall", "structure-yellow-tall", "structure-high"]
		var col: String = cols[_rng.randi_range(0, cols.size() - 1)]
		var cb := _box("factory-kit", col)
		var k := w * 0.18 / maxf(cb.size.x, 0.01)
		var top := 0.0
		for x: float in [-0.5, 0.5]:
			for z: float in [-0.35, 0.35]:
				var leg := Node3D.new()
				leg.position = Vector3(x * w, 0, z * w)
				b.add_child(leg)
				var y := 0.0
				while y < h * 0.85:
					y = _put(leg, "factory-kit", col, k, y)
				top = y
		var cwb := _box("factory-kit", "catwalk-straight")
		var level := top / 3.0
		for l in 3:
			var cw := _part("factory-kit", "catwalk-straight")
			cw.scale = Vector3(w * 1.15 / maxf(cwb.size.x, 0.01), k * 2.0, k * 2.0)
			cw.position = Vector3(0, level * (l + 1) - cwb.position.y * k * 2.0, 0)
			b.add_child(cw)
		if _rng.randf() < 0.5:
			_place(b, "factory-kit", ["hopper-high-round", "hopper-high-square"][_rng.randi_range(0, 1)], w * 0.8, Vector3(0, top, 0), true)
	else:
		# A water tower or a tank farm.
		if _rng.randf() < 0.5:
			_place_h(b, "city-kit-industrial", "water-tower", h * 0.75, Vector3.ZERO)
			w = 16.0
		else:
			_place(b, "city-kit-industrial", "detail-tank-large", w * 0.7, Vector3.ZERO, true)
			_place_h(b, "city-kit-industrial", "chimney-medium", h * 0.8, Vector3(w * 0.3, 0, -w * 0.2))
	return [b, w]


func _town(h: float) -> Array:
	var b := Node3D.new()
	var w := _rng.randf_range(16.0, 24.0)
	var towers := ["building-sample-tower-a", "building-sample-tower-b", "building-sample-tower-c", "building-sample-tower-d"]
	var name: String = towers[_rng.randi_range(0, 3)]
	var tb := _box("modular-buildings", name)
	var k := w / maxf(maxf(tb.size.x, tb.size.z), 0.01)
	var y := 0.0
	# Stack blocks to the height, each a little narrower (setbacks).
	while y < h * 0.85:
		var part := _part("modular-buildings", name)
		part.scale = Vector3.ONE * k
		part.position = Vector3(0, y - tb.position.y * k, 0)
		b.add_child(part)
		y += tb.size.y * k
		k *= _rng.randf_range(0.78, 0.92)
		name = towers[_rng.randi_range(0, 3)]
		tb = _box("modular-buildings", name)
		if _rng.randf() < 0.25:
			break
	if _rng.randf() < 0.35:
		var house: String = ["building-sample-house-a", "building-sample-house-b", "building-sample-house-c"][_rng.randi_range(0, 2)]
		_place(b, "modular-buildings", house, w * 0.9, Vector3(w * 0.85, 0, w * 0.1), true)
		w *= 1.6
	return [b, w]


func _harbor(h: float) -> Array:
	var b := Node3D.new()
	var w := _rng.randf_range(10.0, 16.0)
	var r := _rng.randf()
	if r < 0.55:
		_stack(b, "pirate-kit", ["tower-base-door" if _rng.randf() < 0.5 else "tower-base"], "", "tower-roof" if _rng.randf() < 0.6 else "tower-top", w, h, ["tower-middle", "tower-middle-windows"])
	elif r < 0.8:
		w = _rng.randf_range(18.0, 26.0)
		_place(b, "pirate-kit", "structure-roof" if _rng.randf() < 0.6 else "structure", w, Vector3.ZERO, true)
		_place_h(b, "pirate-kit", "mast-ropes", h * 0.7, Vector3(w * 0.3, 0, -2.0))
	else:
		_place_h(b, "pirate-kit", "tower-complete-large", h, Vector3.ZERO)
	return [b, w]


func _pagoda(h: float) -> Array:
	var b := Node3D.new()
	var p := ModelKit.spawn(&"pagoda", h, _rng)
	# The sculpted model is centered on its origin: stand it on its base.
	p.position.y = -ModelKit._aabb(p).position.y * p.scale.y
	b.add_child(p)
	for t in _rng.randi_range(2, 4):
		var tree := ModelKit.spawn(&"blossom", _rng.randf_range(8.0, 13.0), _rng, Color(0.97, 0.68, 0.82))
		tree.position = Vector3(_rng.randf_range(-12.0, 12.0), 0, _rng.randf_range(2.0, 9.0))
		b.add_child(tree)
	return [b, h * 0.55]


## Stacks a tower: base, mids up to the height, then the top, all scaled
## so the base is w wide.
func _stack(b: Node3D, kit: String, bases: Array[String], mid: String, top: String, w: float, h: float, mids: Array = []) -> void:
	var base_box := _box(kit, bases[0])
	var k := w / maxf(maxf(base_box.size.x, base_box.size.z), 0.01)
	var y := 0.0
	for name in bases:
		y = _put(b, kit, name, k, y)
	var top_h := _box(kit, top).size.y * k
	var guard := 0
	while y + top_h < h and guard < 30:
		var name: String = mid if mid != "" else mids[_rng.randi_range(0, mids.size() - 1)]
		y = _put(b, kit, name, k, y)
		guard += 1
	_put(b, kit, top, k, y)


func _put(b: Node3D, kit: String, name: String, k: float, y: float) -> float:
	var part := _part(kit, name)
	var box := _box(kit, name)
	part.scale = Vector3.ONE * k
	part.position = Vector3(0, y - box.position.y * k, 0)
	b.add_child(part)
	return y + box.size.y * k


## A part scaled to w wide, its base at p.
func _place(b: Node3D, kit: String, name: String, w: float, p: Vector3, _ground: bool) -> void:
	var box := _box(kit, name)
	var k := w / maxf(maxf(box.size.x, box.size.z), 0.01)
	var part := _part(kit, name)
	part.scale = Vector3.ONE * k
	part.position = p - Vector3(0, box.position.y * k, 0)
	b.add_child(part)


## A part scaled to h tall, its base at p.
func _place_h(b: Node3D, kit: String, name: String, h: float, p: Vector3) -> void:
	var box := _box(kit, name)
	var k := h / maxf(box.size.y, 0.01)
	var part := _part(kit, name)
	part.scale = Vector3.ONE * k
	part.position = p - Vector3(0, box.position.y * k, 0)
	b.add_child(part)


func _part(kit: String, name: String) -> Node3D:
	var path := KITS + kit + "/" + name + ".glb"
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var node: Node3D = (_scenes[path] as PackedScene).instantiate()
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if _haze > 0.0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s) as BaseMaterial3D
			if src != null and src.albedo_texture != null:
				mi.set_surface_override_material(s, _material(src.albedo_texture))
	return node


func _box(kit: String, name: String) -> AABB:
	var path := KITS + kit + "/" + name + ".glb"
	if not _boxes.has(path):
		if not _scenes.has(path):
			_scenes[path] = load(path)
		var node: Node = (_scenes[path] as PackedScene).instantiate()
		_boxes[path] = ModelKit._aabb(node)
		node.free()
	return _boxes[path]


func _material(tex: Texture2D) -> ShaderMaterial:
	if _mats.has(tex):
		return _mats[tex]
	var m := ShaderMaterial.new()
	m.shader = PALETTE
	m.set_shader_parameter("albedo_tex", tex)
	for key: String in ["stone", "metal", "roof", "accent", "trim", "window"]:
		m.set_shader_parameter(key, _colors[key])
	m.set_shader_parameter("window_glow", 1.4 if _stadium.def.night else 0.0)
	m.set_shader_parameter("blue_is_window", _style == &"town")
	# Surface detail fades out with the haze: crisp up front, soft far back.
	var wall: Array = StadiumSurfaces.KINDS[_wall_surface]
	var steel: Array = StadiumSurfaces.KINDS[&"steel"]
	m.set_shader_parameter("wall_detail", wall[0])
	m.set_shader_parameter("wall_normal", wall[1])
	m.set_shader_parameter("wall_tile", float(wall[2]))
	m.set_shader_parameter("metal_detail", steel[0])
	m.set_shader_parameter("metal_normal", steel[1])
	m.set_shader_parameter("metal_tile", float(steel[2]))
	m.set_shader_parameter("detail", 0.85 * (1.0 - _haze * 1.6))
	m.set_shader_parameter("haze_color", _colors["haze"])
	m.set_shader_parameter("haze", _haze)
	_mats[tex] = m
	return m
