class_name StadiumModules
## The catalog of ballpark modules: what each one is called, where it can
## go, which settings it takes (with ranges a designer's sliders can use),
## what it clashes with, and the script that builds it. Adding a module
## means adding one script under modules/ and one entry here.

const CATALOG := {
	&"scoreboard": {
		"name": "Scoreboard", "category": &"boards", "unique": false, "placed": true,
		"about": "The line-score board over the outfield stands: innings, R H E, the count, the batter.",
		"angle": -34.0, "angle_range": [-60.0, 60.0],
		"params": {"height": [9.5, 4.0, 20.0]},
		"script": preload("res://presentation/stadium/modules/scoreboard_module.gd"),
	},
	&"centerpiece": {
		"name": "Centerpiece", "category": &"boards", "unique": true, "placed": false,
		"about": "The board in straightaway center: club name under its emblem and the batter's card. Framed as a board, gate or arch.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"height": [17.0, 12.0, 28.0], "frame": [&"board"], "clock": [false], "crown": [false]},
		"choices": {"frame": [&"board", &"gate", &"arch"]},
		"script": preload("res://presentation/stadium/modules/centerpiece_module.gd"),
	},
	&"slogan_board": {
		"name": "Slogan Board", "category": &"boards", "unique": false, "placed": true,
		"about": "A big lit sign over the stands: the park's name (or text) and the home club's slogan under its emblem.",
		"angle": 34.0, "angle_range": [-60.0, 60.0],
		"params": {"height": [8.0, 3.0, 20.0], "text": [""]},
		"script": preload("res://presentation/stadium/modules/slogan_board_module.gd"),
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
		"about": "Floodlight towers around the bowl and a pair flanking the centerpiece; brighter under the lights.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"height": [46.0, 25.0, 70.0], "flank": [16.0, 0.0, 40.0]},
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
	&"water": {
		"name": "Water", "category": &"backdrop", "unique": false, "placed": true,
		"about": "A river (a straight band across the angle, distance m out) or a moat (gap m behind the stands, across span degrees; wide for harbor water). Glow lights it like a neon canal.",
		"angle": 0.0, "angle_range": [-180.0, 180.0],
		"params": {"style": [&"river"], "distance": [200.0, 60.0, 600.0], "width": [60.0, 6.0, 500.0], "gap": [12.0, 0.0, 120.0], "span": [360.0, -360.0, 360.0], "glow": [0.0, 0.0, 3.0]},
		"choices": {"style": [&"river", &"moat"]},
		"script": preload("res://presentation/stadium/modules/water_module.gd"),
	},
	&"waterfalls": {
		"name": "Waterfall", "category": &"scenery", "unique": false, "placed": true,
		"about": "A waterfall behind the outfield stands spilling into a pool. Mirror it to flank the centerpiece.",
		"angle": 12.0, "angle_range": [-60.0, 60.0],
		"params": {"height": [26.0, 10.0, 45.0], "width": [10.0, 4.0, 24.0], "frozen": [false]},
		"script": preload("res://presentation/stadium/modules/waterfalls_module.gd"),
	},
	&"trees": {
		"name": "Trees", "category": &"scenery", "unique": false, "placed": true,
		"about": "A grove behind the stands across span degrees: palms, pines, cacti, round shade trees, cypresses or blossoming trees.",
		"angle": -45.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [30.0, -120.0, 120.0], "count": [8, 1, 30], "kind": [&"palm"]},
		"choices": {"kind": [&"palm", &"pine", &"cactus", &"round", &"cypress", &"blossom", &"rock"]},
		"script": preload("res://presentation/stadium/modules/trees_module.gd"),
	},
	&"smokestacks": {
		"name": "Smokestacks", "category": &"scenery", "unique": false, "placed": true,
		"about": "Smokestacks trailing smoke, or a power plant's cooling towers trailing steam, across span degrees.",
		"angle": -30.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [30.0, -90.0, 90.0], "count": [4, 1, 10], "height": [55.0, 25.0, 90.0], "style": [&"stack"], "tint": [0.0, 0.0, 1.0]},
		"choices": {"style": [&"stack", &"cooling"]},
		"script": preload("res://presentation/stadium/modules/smokestacks_module.gd"),
	},
	&"cranes": {
		"name": "Cranes", "category": &"scenery", "unique": false, "placed": true,
		"about": "Lattice gantry cranes behind the stands, booms reaching over toward the park.",
		"angle": 30.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [20.0, -90.0, 90.0], "count": [2, 1, 6], "height": [40.0, 20.0, 70.0]},
		"script": preload("res://presentation/stadium/modules/cranes_module.gd"),
	},
	&"lighthouse": {
		"name": "Lighthouse", "category": &"scenery", "unique": false, "placed": true,
		"about": "A striped lighthouse on a rock behind the stands, its lamp lit.",
		"angle": 20.0, "angle_range": [-180.0, 180.0],
		"params": {"height": [30.0, 15.0, 50.0]},
		"script": preload("res://presentation/stadium/modules/lighthouse_module.gd"),
	},
	&"sailboats": {
		"name": "Sailboats", "category": &"scenery", "unique": false, "placed": true,
		"about": "Sailboats and a tall ship on the water behind the stands (over the bay).",
		"angle": 25.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [30.0, -90.0, 90.0], "count": [5, 1, 12]},
		"script": preload("res://presentation/stadium/modules/sailboats_module.gd"),
	},
	&"flying_craft": {
		"name": "Flying Craft", "category": &"sky", "unique": true, "placed": false,
		"about": "Saucer cars or blimps in the club's colors hovering over the skyline.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"count": [6, 1, 16], "style": [&"saucer"]},
		"choices": {"style": [&"saucer", &"blimp"]},
		"excludes": [&"dome"],
		"script": preload("res://presentation/stadium/modules/flying_craft_module.gd"),
	},
	&"flags": {
		"name": "Flags", "category": &"structure", "unique": false, "placed": true,
		"about": "Flagpoles along the top of the stands across span degrees, in the club's colors.",
		"angle": -60.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [120.0, -240.0, 240.0], "count": [10, 1, 40]},
		"script": preload("res://presentation/stadium/modules/flags_module.gd"),
	},
	&"statue": {
		"name": "Statue", "category": &"landmark", "unique": false, "placed": true,
		"about": "A bronze statue on a pedestal atop the outfield stands: a charging bull or a figure.",
		"angle": -25.0, "angle_range": [-60.0, 60.0],
		"params": {"figure": [&"bull"]},
		"choices": {"figure": [&"bull", &"figure"]},
		"script": preload("res://presentation/stadium/modules/statues_module.gd"),
	},
	&"bridge": {
		"name": "Bridge", "category": &"scenery", "unique": false, "placed": true,
		"about": "A long arched bridge across the river behind the stands.",
		"angle": 35.0, "angle_range": [-180.0, 180.0],
		"params": {"distance": [110.0, 30.0, 300.0], "length": [220.0, 60.0, 400.0]},
		"script": preload("res://presentation/stadium/modules/bridge_module.gd"),
	},
	&"mountains": {
		"name": "Mountains", "category": &"backdrop", "unique": false, "placed": true,
		"about": "A natural backdrop across span degrees: snowcapped peaks or red-rock mesas (with a natural arch).",
		"angle": -70.0, "angle_range": [-180.0, 180.0],
		"params": {"style": [&"peaks"], "span": [140.0, -360.0, 360.0], "count": [9, 1, 30], "height": [90.0, 30.0, 220.0], "distance": [420.0, 200.0, 800.0], "arch": [false]},
		"choices": {"style": [&"peaks", &"mesa"]},
		"script": preload("res://presentation/stadium/modules/mountains_module.gd"),
	},
	&"rocket": {
		"name": "Rocket", "category": &"landmark", "unique": false, "placed": true,
		"about": "A rocket sculpture on a launch gantry behind the outfield stands.",
		"angle": 18.0, "angle_range": [-60.0, 60.0],
		"params": {"height": [45.0, 20.0, 80.0]},
		"script": preload("res://presentation/stadium/modules/rocket_module.gd"),
	},
	&"gondola": {
		"name": "Gondola", "category": &"scenery", "unique": false, "placed": true,
		"about": "A ski gondola line across the backdrop: towers, cable and cabins.",
		"angle": -40.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [-30.0, -90.0, 90.0]},
		"script": preload("res://presentation/stadium/modules/gondola_module.gd"),
	},
	&"icicles": {
		"name": "Icicles", "category": &"structure", "unique": false, "placed": true,
		"about": "Snow lips and hanging icicles along the deck fronts and the top of the stands, across span degrees.",
		"angle": -180.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [360.0, -360.0, 360.0]},
		"script": preload("res://presentation/stadium/modules/icicles_module.gd"),
	},
	&"pipes": {
		"name": "Pipes", "category": &"structure", "unique": false, "placed": true,
		"about": "Industrial pipe runs along the top of the stands across span degrees, the top run lit in the park's accent.",
		"angle": -60.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [120.0, -360.0, 360.0], "runs": [2, 1, 4]},
		"script": preload("res://presentation/stadium/modules/pipes_module.gd"),
	},
	&"viaduct": {
		"name": "Viaduct", "category": &"scenery", "unique": false, "placed": true,
		"about": "An elevated railway on brick arches behind the stands across span degrees, with a lit train.",
		"angle": 15.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [45.0, -120.0, 120.0], "height": [16.0, 8.0, 30.0], "distance": [18.0, 6.0, 120.0], "train": [true]},
		"script": preload("res://presentation/stadium/modules/viaduct_module.gd"),
	},
	&"lamps": {
		"name": "Gas Lamps", "category": &"structure", "unique": false, "placed": true,
		"about": "Iron lamp posts with warm lanterns along the top of the stands across span degrees.",
		"angle": -150.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [300.0, -360.0, 360.0], "count": [30, 2, 80]},
		"script": preload("res://presentation/stadium/modules/lamps_module.gd"),
	},
	&"bunting": {
		"name": "Bunting", "category": &"structure", "unique": false, "placed": true,
		"about": "Half-fan bunting along the deck fronts across span degrees: red, white and blue, or the club's colors.",
		"angle": 55.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [250.0, -360.0, 360.0], "every": [9.0, 3.0, 30.0], "club_colors": [false]},
		"script": preload("res://presentation/stadium/modules/bunting_module.gd"),
	},
	&"conservatory": {
		"name": "Conservatory", "category": &"landmark", "unique": false, "placed": true,
		"about": "A glass greenhouse dome on a stone base behind the stands, glowing softly inside.",
		"angle": 40.0, "angle_range": [-180.0, 180.0],
		"params": {"radius": [12.0, 6.0, 24.0]},
		"script": preload("res://presentation/stadium/modules/conservatory_module.gd"),
	},
	&"vault_door": {
		"name": "Vault Door", "category": &"landmark", "unique": false, "placed": true,
		"about": "A giant round bank-vault door in a tall wall behind the stands, with bolts, a spoked wheel and red lights.",
		"angle": -35.0, "angle_range": [-60.0, 60.0],
		"params": {"radius": [14.0, 6.0, 24.0]},
		"script": preload("res://presentation/stadium/modules/vault_door_module.gd"),
	},
	&"searchlights": {
		"name": "Searchlights", "category": &"sky", "unique": false, "placed": true,
		"about": "Searchlight beams sweeping up into the night sky from behind the stands, across span degrees.",
		"angle": -60.0, "angle_range": [-180.0, 180.0],
		"params": {"span": [120.0, -360.0, 360.0], "count": [6, 1, 16], "length": [160.0, 60.0, 300.0]},
		"excludes": [&"dome"],
		"script": preload("res://presentation/stadium/modules/searchlights_module.gd"),
	},
	&"arcade": {
		"name": "Arcade Facade", "category": &"structure", "unique": false, "placed": true,
		"about": "The upper facade on the back of the stands across span degrees: arches, windows, open steel or timber frames, a colonnade, a glass curtain wall or battlements, with columns, a cornice, club banners and optional towers (spire, dome, pagoda or crenellated caps). Openings glow at night.",
		"angle": 50.0, "angle_range": [-180.0, 180.0],
		"params": {"style": [&"arches"], "span": [130.0, -360.0, 360.0], "height": [9.0, 4.0, 20.0], "bay": [7.0, 3.0, 16.0], "banners": [4, 0, 20], "towers": [0, 0, 20], "tower_height": [8.0, 2.0, 40.0], "cap": [&"spire"]},
		"choices": {"style": [&"arches", &"windows", &"truss", &"timber", &"colonnade", &"glass", &"battlements"], "cap": [&"spire", &"dome", &"pagoda", &"flat"]},
		"script": preload("res://presentation/stadium/modules/arcade_module.gd"),
	},
	&"canopy": {
		"name": "Canopy", "category": &"structure", "unique": false, "placed": true,
		"about": "A roof over the top rows of the stands across span degrees, in steel or timber, with a lit front edge and struts. It sits height m above any facade there.",
		"angle": 55.0, "angle_range": [-180.0, 180.0],
		"params": {"style": [&"steel"], "span": [120.0, -360.0, 360.0], "depth": [9.0, 3.0, 20.0], "height": [0.5, 0.0, 24.0]},
		"choices": {"style": [&"steel", &"timber"]},
		"script": preload("res://presentation/stadium/modules/canopy_module.gd"),
	},
	&"wall_art": {
		"name": "Wall Art", "category": &"boards", "unique": false, "placed": false,
		"about": "Motifs painted along the outfield wall between the numbers and emblems: waves, snowflakes, zigzag bolts, blossoms, gears, stars, crossed bars or the club emblem.",
		"angle": 0.0, "angle_range": [0.0, 0.0],
		"params": {"motif": [&"emblem"], "every": [8.0, 4.0, 20.0], "glow": [0.0, 0.0, 3.0]},
		"choices": {"motif": [&"emblem", &"waves", &"snowflake", &"zigzag", &"blossom", &"gear", &"star", &"crossed"]},
		"script": preload("res://presentation/stadium/modules/wall_art_module.gd"),
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
const STANDARD := [&"centerpiece", &"scoreboard", &"slogan_board", &"light_towers", &"skyline"]


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
		# A span sweeps the other way on the mirror side.
		if piece.params.has("span") or spec["params"].has("span"):
			twin.params = piece.params.duplicate()
			twin.params["span"] = -float(piece.param("span"))
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
			var choices: Array = spec.get("choices", {}).get(key, [])
			if range_spec.is_empty():
				problems.append("%s has no setting '%s'" % [spec["name"], key])
			elif not choices.is_empty() and not StringName(str(piece.params[key])) in choices:
				problems.append("%s %s must be one of %s" % [spec["name"], key, choices])
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
	if not count.has(&"scoreboard") and not count.has(&"wall_scoreboard") and not count.has(&"centerpiece"):
		problems.append("no scoreboard")
	return problems
