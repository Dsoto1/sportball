class_name StadiumModules
## The catalog of ballpark modules: what each one is called, where it can
## go, which settings it takes (with ranges a designer's sliders can use),
## what it clashes with, and the script that builds it. Adding a module
## means adding one script under modules/ and one entry here.

const CATALOG := {
	&"scoreboard": {
		"name": "Scoreboard", "category": &"boards", "unique": false, "placed": true,
		"about": "The big video board over the outfield stands: line score, count, batter.",
		"angle": 27.0, "angle_range": [-60.0, 60.0],
		"params": {"height": [9.5, 4.0, 20.0]},
		"script": preload("res://presentation/stadium/modules/scoreboard_module.gd"),
	},
	&"wall_scoreboard": {
		"name": "Wall Scoreboard", "category": &"boards", "unique": false, "placed": true,
		"about": "A hand-operated scoreboard set into a tall outfield wall (needs a wall 6 m or taller there).",
		"angle": -28.0, "angle_range": [-45.0, 45.0],
		"params": {},
		"script": preload("res://presentation/stadium/modules/wall_scoreboard_module.gd"),
	},
	&"light_towers": {
		"name": "Light Towers", "category": &"structure", "unique": true, "placed": false,
		"about": "Six floodlight towers around the bowl; brighter under the lights.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"height": [46.0, 25.0, 70.0]},
		"excludes": [&"dome"],
		"script": preload("res://presentation/stadium/modules/light_towers_module.gd"),
	},
	&"skyline": {
		"name": "City Skyline", "category": &"backdrop", "unique": true, "placed": false,
		"about": "Towers ringing the park, taller beyond center, windows lit at night.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"height": [1.0, 0.2, 2.0], "count": [40, 10, 80]},
		"excludes": [&"dome"],
		"script": preload("res://presentation/stadium/modules/skyline_module.gd"),
	},
	&"halo": {
		"name": "Halo Ring", "category": &"landmark", "unique": true, "placed": false,
		"about": "A glowing ring floating over the park on four pylons, hung with sponsor boards.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"height": [58.0, 35.0, 90.0], "radius": [150.0, 110.0, 190.0]},
		"excludes": [&"dome"],
		"script": preload("res://presentation/stadium/modules/halo_module.gd"),
	},
	&"bay": {
		"name": "The Bay", "category": &"backdrop", "unique": true, "placed": true,
		"about": "Open water beyond one side of the outfield, with low stands along it and boats bobbing.",
		"angle": 40.0, "angle_range": [-45.0, 45.0],
		"params": {"boats": [5, 0, 10]},
		"script": preload("res://presentation/stadium/modules/bay_module.gd"),
	},
	&"warehouse": {
		"name": "Warehouse", "category": &"landmark", "unique": false, "placed": true,
		"about": "A long brick warehouse beyond the stands, parallel to the foul line, its name along the top.",
		"angle": 45.0, "angle_range": [-45.0, 45.0],
		"params": {"length": [250.0, 120.0, 320.0], "height": [30.0, 15.0, 45.0], "text": [""]},
		"script": preload("res://presentation/stadium/modules/warehouse_module.gd"),
	},
	&"fountains": {
		"name": "Fountains", "category": &"landmark", "unique": false, "placed": true,
		"about": "Pools beyond the wall with a cascade and dancing jets, from angle out to angle + span.",
		"angle": 14.0, "angle_range": [-45.0, 45.0],
		"params": {"span": [26.0, 8.0, 40.0], "basins": [10, 2, 16]},
		"script": preload("res://presentation/stadium/modules/fountains_module.gd"),
	},
	&"dome": {
		"name": "Dome", "category": &"structure", "unique": true, "placed": false,
		"about": "A sealed roof over the whole park: catwalk rings, light banks, a glowing crown. Indoor light.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"rise": [70.0, 45.0, 100.0]},
		"excludes": [&"light_towers", &"skyline", &"halo"],
		"script": preload("res://presentation/stadium/modules/dome_module.gd"),
	},
}

## Every park gets these unless its designer takes them out.
const STANDARD := [&"scoreboard", &"light_towers", &"skyline"]


static func kinds() -> Array:
	return CATALOG.keys()


static func info(kind: StringName) -> Dictionary:
	return CATALOG.get(kind, {})


static func default_param(kind: StringName, key: String) -> Variant:
	var spec: Array = info(kind).get("params", {}).get(key, [])
	return null if spec.is_empty() else spec[0]


static func default_angle(kind: StringName) -> float:
	return float(info(kind).get("angle", 0.0))


## A new piece with the module's defaults, ready to place.
static func new_piece(kind: StringName) -> StadiumPiece:
	return StadiumPiece.make(kind, default_angle(kind))


## Builds one piece (and its mirror image) into the stadium.
static func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, away: TeamDef) -> void:
	var spec := info(piece.kind)
	if spec.is_empty():
		push_warning("unknown stadium module %s" % piece.kind)
		return
	var module: StadiumModule = (spec["script"] as GDScript).new()
	module.build(stadium, piece, home, away)
	if piece.mirrored and spec["placed"]:
		var twin: StadiumPiece = piece.duplicate()
		twin.angle = -piece.angle
		twin.mirrored = false
		module.build(stadium, twin, home, away)


## Problems with a park's pieces; empty when it is buildable as designed.
static func validate(def: StadiumDef) -> PackedStringArray:
	var problems := PackedStringArray()
	var count := {}
	for piece in def.pieces:
		if piece == null:
			problems.append("an empty piece slot")
			continue
		var spec := info(piece.kind)
		if spec.is_empty():
			problems.append("unknown module '%s'" % piece.kind)
			continue
		count[piece.kind] = count.get(piece.kind, 0) + 1
		var span: Array = spec["angle_range"]
		if spec["placed"] and (piece.angle < span[0] or piece.angle > span[1]):
			problems.append("%s at %.0f° is outside %.0f..%.0f°" % [spec["name"], piece.angle, span[0], span[1]])
		if piece.size <= 0.0:
			problems.append("%s has no size" % spec["name"])
		for key in piece.params:
			var range_spec: Array = spec["params"].get(key, [])
			if range_spec.is_empty():
				problems.append("%s has no setting '%s'" % [spec["name"], key])
			elif range_spec.size() == 3 and (float(piece.params[key]) < float(range_spec[1]) or float(piece.params[key]) > float(range_spec[2])):
				problems.append("%s %s %s is outside %s..%s" % [spec["name"], key, piece.params[key], range_spec[1], range_spec[2]])
		if piece.kind == &"wall_scoreboard" and def.field_shape != null and def.field_shape.height_at(piece.angle) < 6.0:
			problems.append("Wall Scoreboard at %.0f° needs a wall 6 m or taller (%.1f m)" % [piece.angle, def.field_shape.height_at(piece.angle)])
	for kind in count:
		if info(kind)["unique"] and count[kind] > 1:
			problems.append("only one %s per park" % info(kind)["name"])
		for other: StringName in info(kind).get("excludes", []):
			if count.has(other):
				problems.append("%s and %s can't share a park" % [info(kind)["name"], info(other)["name"]])
	if not count.has(&"scoreboard") and not count.has(&"wall_scoreboard"):
		problems.append("no scoreboard")
	return problems
