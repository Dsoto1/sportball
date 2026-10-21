extends SceneTree
## Writes the ballpark resources in res://data/stadiums (look + field shape).
##   godot --headless --path . -s res://tools/generate_parks.gd
## Run before generate_teams.gd, which links each club to its home park.
## Shapes are (spray deg, wall distance m, wall height m) from the left-field
## line (-45) to the right-field line (+45). All names are original.
## Pieces are [kind, angle, params, mirrored] (StadiumModules.CATALOG), added
## after the standard set (centerpiece in the park's "frame", line-score
## board, slogan board, light towers, skyline at the park's skyline_height)
## unless a park lists its own "standard". "decks" tiers the foul stands.

const PARKS := [
	{
		"id": &"halo_dome", "decks": 3, "frame": &"board", "display_name": "The Halo Dome",
		"blurb": "Glitterati home · symmetrical, padded glass-and-gold wall",
		"shape": [[-45, 96, 3.4], [-30, 104, 3.4], [-15, 112, 3.4], [0, 116, 4.2], [15, 112, 3.4], [30, 104, 3.4], [45, 96, 3.4]], "air": 1.0,
		"seat_color": Color("3d2466"), "seat_color_alt": Color("2c1a4d"), "structure_color": Color("8f8aa3"), "accent_color": Color("ffc94a"),
		"outfield_wall_color": Color("2a1c4f"), "wall_style": &"padded", "home_fan_share": 0.62, "away_fan_share": 0.12, "attendance": 0.9,
		"pieces": [[&"halo"], [&"waterfalls", 11.0, {}, true], [&"trees", 15.0, {"span": 35.0, "count": 7, "kind": &"palm"}, true], [&"flying_craft"], [&"flags", -50.0, {"span": 100.0, "count": 12}], [&"water", 0.0, {"style": &"moat", "gap": 24.0, "width": 12.0, "glow": 1.2}]],
		"sponsors": ["SPOTLIGHT COLA", "NEON HEIGHTS TRANSIT", "MARQUEE MOTORS", "VELVET ROPE LOUNGE", "GLAM SLAM GUM", "CRT VISION", "HEADLINER HOTELS", "ENCORE AIRWAYS"],
		"skyline_color": Color("2b2a52"), "window_color": Color("ffd27a"), "skyline_height": 1.0,
	},
	{
		"id": &"foundry_field", "decks": 2, "frame": &"gate", "display_name": "Foundry Field",
		"blurb": "Gearheads home · The Boilerplate: a 34-foot iron wall in short right",
		"shape": [[-45, 101, 2.6], [-25, 116, 2.6], [0, 121, 2.6], [13, 113, 2.6], [14.5, 111, 10.5], [30, 99, 10.5], [45, 90, 10.5]], "air": 1.0,
		"seat_color": Color("6b3a22"), "seat_color_alt": Color("4f2b19"), "structure_color": Color("8a7d70"), "accent_color": Color("ff8a2a"),
		"outfield_wall_color": Color("2e2a2a"), "wall_style": &"iron", "home_fan_share": 0.6, "away_fan_share": 0.15, "attendance": 0.75,
		"foul_rows": 20, "outfield_rows": 12,
		"pieces": [[&"wall_scoreboard", 26.0], [&"smokestacks", -32.0, {"span": -40.0, "count": 5}], [&"cranes", 22.0, {"span": 30.0, "count": 3}], [&"bridge", 38.0, {"distance": 140.0}], [&"waterfalls", -12.0, {"height": 20.0}], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"water", 10.0, {"distance": 190.0, "width": 70.0}]],
		"sponsors": ["RIVET & SONS HARDWARE", "RUSTWATER FERRY", "SPROCKET DINER", "LUGNUT BREWS", "FORGE & ANVIL", "BOILERMAKERS UNION"],
		"skyline_color": Color("4a4040"), "window_color": Color("ffb35c"), "skyline_height": 0.6,
	},
	{
		"id": &"ledger_street", "decks": 2, "frame": &"arch", "display_name": "Ledger Street Park",
		"blurb": "Bankers home · The Leviathan: a 37-foot green wall in short left, a deep triangle in right-center",
		"shape": [[-45, 94.5, 11.3], [-30, 101, 11.3], [-14, 111, 11.3], [-12.5, 114, 4.0], [0, 119, 4.0], [12, 128, 4.0], [24, 116, 1.8], [33, 104, 1.8], [45, 92, 1.0]], "air": 1.0,
		"seat_color": Color("1f4a33"), "seat_color_alt": Color("173828"), "structure_color": Color("8a4b3c"), "accent_color": Color("f2e6c8"),
		"outfield_wall_color": Color("1d5235"), "wall_style": &"padded", "home_fan_share": 0.5, "away_fan_share": 0.3, "attendance": 0.95,
		"foul_rows": 22, "outfield_rows": 10,
		"pieces": [[&"wall_scoreboard", -28.0], [&"statue", 22.0, {}, true], [&"trees", 30.0, {"span": 25.0, "count": 5, "kind": &"round"}, true], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"water", 65.0, {"distance": 115.0, "width": 24.0}], [&"bridge", 75.0, {"distance": 65.0, "length": 80.0}], [&"bunting", 50.0, {"span": 260.0}]],
		"sponsors": ["PEMBERTON PEANUTS", "COBBLESTONE COFFEE", "LANTERN LAUNDRY", "IRONCLAD INSURANCE", "LEDGER STREET LAGER"],
		"skyline_color": Color("5a4a48"), "window_color": Color("ffe1a8"), "skyline_height": 0.8,
	},
	{
		"id": &"pier_nine", "decks": 2, "frame": &"board", "display_name": "Pier 9 Ballyard",
		"blurb": "Gulls home · short porch in right, the bay beyond it, deep left-center",
		"shape": [[-45, 101, 2.4], [-20, 115, 2.4], [0, 123, 2.4], [20, 110, 2.4], [32, 101, 2.4], [45, 94, 2.4]], "air": 1.03,
		"seat_color": Color("1d3b5c"), "seat_color_alt": Color("152c45"), "structure_color": Color("c9c4b6"), "accent_color": Color("ff6b4a"),
		"outfield_wall_color": Color("133047"), "wall_style": &"padded", "home_fan_share": 0.45, "away_fan_share": 0.35, "attendance": 0.88,
		"foul_rows": 24, "outfield_rows": 8,
		"pieces": [[&"bay", 40.0], [&"lighthouse", 16.0], [&"sailboats", 26.0, {"span": 34.0, "count": 6}], [&"cranes", -30.0, {"count": 1}], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"water", 62.0, {"style": &"moat", "gap": 6.0, "width": 400.0, "span": 198.0}]],
		"sponsors": ["SALTWIND SAILS", "PIER 9 OYSTERS", "TIDECALLER TAXI", "BUOY BEVERAGES", "FOGHORN FRIES"],
		"skyline_color": Color("37465e"), "window_color": Color("ffe9b0"), "skyline_height": 0.9,
	},
	{
		"id": &"the_kiln", "ground_color": Color("8f4a2c"), "decks": 2, "frame": &"gate", "display_name": "The Kiln",
		"blurb": "Comets home · thin desert air carries the ball, so the outfield is a canyon; red mesas and a rocket beyond",
		"shape": [[-45, 105, 4.3], [-25, 119, 4.3], [0, 127, 4.3], [25, 119, 4.3], [45, 106, 4.3]], "air": 0.82,
		"seat_color": Color("a65a32"), "seat_color_alt": Color("8a4826"), "structure_color": Color("d9b98a"), "accent_color": Color("2ec4b6"),
		"outfield_wall_color": Color("2f3936"), "wall_style": &"padded", "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.8,
		"foul_rows": 24, "outfield_rows": 18,
		"pieces": [[&"mountains", -95.0, {"style": &"mesa", "span": 190.0, "count": 12, "height": 70.0, "distance": 380.0, "arch": true}], [&"rocket", 16.0], [&"smokestacks", 34.0, {"span": 16.0, "count": 2, "height": 40.0}], [&"trees", 20.0, {"span": 30.0, "count": 4, "kind": &"cactus"}, true], [&"flags", -50.0, {"span": 100.0, "count": 10}]],
		"sponsors": ["SUNBAKED SODA", "MESA MOTOR LODGE", "CACTUS CANDY CO.", "COPPER CANYON CHILI"],
		"skyline_color": Color("b08a62"), "window_color": Color("fff0c0"), "skyline_height": 0.35,
	},
	{
		"id": &"the_icebox", "ground_color": Color("e4ebf2"), "decks": 2, "frame": &"arch", "display_name": "The Icebox",
		"blurb": "Yetis home · cold heavy air knocks fly balls down; ice falls and peaks beyond the wall",
		"shape": [[-45, 99, 4.6], [-22, 112, 4.6], [0, 118, 4.6], [22, 112, 4.6], [45, 99, 4.6]], "air": 1.1,
		"seat_color": Color("2d4a63"), "seat_color_alt": Color("223a4f"), "structure_color": Color("b8c4cc"), "accent_color": Color("9fe8ff"),
		"outfield_wall_color": Color("143a63"), "wall_style": &"padded", "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.85,
		"pieces": [[&"mountains", -125.0, {"span": 250.0, "count": 13, "height": 150.0, "distance": 540.0}], [&"waterfalls", 10.0, {"frozen": true, "height": 28.0}, true], [&"trees", 22.0, {"span": 45.0, "count": 10, "kind": &"pine"}, true], [&"gondola", -32.0, {"span": -40.0}], [&"icicles", -180.0], [&"flags", -50.0, {"span": 100.0, "count": 10}]],
		"sponsors": ["FROSTGATE FURNACES", "SNOWLINE SKIS", "YETI COCOA", "GLACIER GLASS", "NORTHWIND WOOLENS"],
		"skyline_color": Color("4a5866"), "window_color": Color("dff4ff"), "skyline_height": 0.4,
	},
	{
		"id": &"reactor_park", "decks": 3, "frame": &"gate", "display_name": "Reactor Park",
		"blurb": "Neutrons home · odd angles and a deep center-field notch behind a tall reactor wall",
		"shape": [[-45, 98, 3.0], [-28, 108, 3.0], [-12, 121, 3.0], [-9, 130, 6.5], [-3, 130, 6.5], [0, 120, 3.0], [9, 121, 3.0], [18, 111, 3.0], [31, 102, 3.0], [45, 97, 3.0]], "air": 1.0,
		"seat_color": Color("2a2e30"), "seat_color_alt": Color("202426"), "structure_color": Color("4b5154"), "accent_color": Color("39d353"),
		"outfield_wall_color": Color("1e2622"), "wall_style": &"iron", "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.82, "night": true,
		"pieces": [[&"smokestacks", -24.0, {"span": -30.0, "count": 2, "style": &"cooling", "height": 75.0, "tint": 0.6}], [&"smokestacks", 24.0, {"span": 30.0, "count": 2, "style": &"cooling", "height": 70.0, "tint": 0.6}], [&"smokestacks", 46.0, {"span": 14.0, "count": 2, "height": 45.0}], [&"pipes", -48.0, {"span": 96.0}], [&"water", 25.0, {"distance": 200.0, "width": 55.0}]],
		"sponsors": ["ATOMIC FALLS POWER & LIGHT", "MUSHROOM CLOUD MALTS", "FISSION FIZZ", "RAY-GUN RADIO"],
		"skyline_color": Color("3d3f2e"), "window_color": Color("c8ffd8"), "skyline_height": 0.9,
	},
	{
		"id": &"the_horseshoe", "decks": 2, "frame": &"arch", "display_name": "The Horseshoe",
		"blurb": "Lamplighters home · night ball in a horseshoe: 279-foot lines, a 482-foot center field",
		"shape": [[-45, 85, 4.9], [-36, 97, 4.9], [-26, 120, 3.0], [-12, 139, 3.0], [0, 147, 3.0], [12, 139, 3.0], [26, 119, 3.0], [36, 94, 3.4], [45, 81, 3.4]], "air": 1.0,
		"seat_color": Color("16294a"), "seat_color_alt": Color("10203a"), "structure_color": Color("7a5a44"), "accent_color": Color("f0c04b"),
		"outfield_wall_color": Color("0f2440"), "wall_style": &"padded", "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.9,
		"foul_rows": 28, "outfield_rows": 20, "night": true,
		"pieces": [[&"viaduct", 14.0, {"span": 40.0, "height": 18.0}], [&"lamps", -150.0, {"span": 300.0, "count": 44}], [&"bunting", 50.0, {"span": 260.0}]],
		"sponsors": ["OLD TOWNE TROLLEY", "HORSESHOE HAMS", "MIDNIGHT MATINEE", "NICKEL ARCADE", "LAMPLIGHTER LAGER"],
		"skyline_color": Color("1a1f33"), "window_color": Color("ffe0a0"), "skyline_height": 1.2,
	},
	{
		"id": &"warehouse_row", "decks": 2, "frame": &"gate", "clock": true, "display_name": "Warehouse Row",
		"blurb": "Conductors home · a 25-foot brick wall in right and the old Roundhouse warehouse looming over it",
		"shape": [[-45, 101, 2.4], [-25, 111, 2.4], [-8, 123, 2.4], [0, 122, 2.4], [14, 115, 2.4], [20, 112, 2.4], [21.5, 110, 7.6], [45, 97, 7.6]], "air": 1.0,
		"seat_color": Color("8a2a2a"), "seat_color_alt": Color("6e2121"), "structure_color": Color("6e3a2c"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("1f3a3c"), "wall_style": &"brick", "home_fan_share": 0.5, "away_fan_share": 0.3, "attendance": 0.92,
		"foul_rows": 24, "outfield_rows": 12,
		"pieces": [[&"warehouse", 45.0], [&"warehouse", -45.0, {"text": "CARGO BUILDS CITIES", "length": 180.0}], [&"viaduct", 16.0, {"span": 34.0, "height": 20.0}], [&"cranes", 30.0, {"span": 20.0, "count": 2}], [&"smokestacks", 40.0, {"span": 8.0, "count": 1, "height": 35.0}], [&"bunting", 50.0, {"span": 260.0}], [&"water", 20.0, {"distance": 230.0, "width": 60.0}], [&"bridge", -15.0, {"distance": 180.0, "length": 200.0}]],
		"sponsors": ["ROUNDHOUSE STORAGE CO.", "HARBORLIGHT CRAB SHACK", "BRASS RAIL BITTERS", "OLD LINE LOCKSMITHS", "CANAL STREET CANDY"],
		"skyline_color": Color("514848"), "window_color": Color("ffe1a8"), "skyline_height": 0.9,
	},
	{
		"id": &"fountain_gardens", "decks": 2, "frame": &"board", "display_name": "Fountain Gardens",
		"blurb": "Swans home · big, symmetric and fair: garden terraces, fountains and blossoms beyond the wall",
		"shape": [[-45, 101, 3.7], [-22, 118, 3.7], [0, 125, 3.7], [22, 118, 3.7], [45, 101, 3.7]], "air": 1.0,
		"seat_color": Color("1d4a35"), "seat_color_alt": Color("163c2b"), "structure_color": Color("e8e2d0"), "accent_color": Color("d4af37"),
		"outfield_wall_color": Color("145a3b"), "wall_style": &"padded", "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.8,
		"foul_rows": 24, "outfield_rows": 5,
		"pieces": [[&"fountains", 14.0, {}, true], [&"waterfalls", 9.0, {"height": 22.0}, true], [&"trees", 22.0, {"span": 30.0, "count": 8, "kind": &"blossom"}, true], [&"trees", 4.0, {"span": 8.0, "count": 4, "kind": &"cypress"}, true], [&"statue", 16.0, {"figure": &"figure"}, true], [&"conservatory", 42.0], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"water", 0.0, {"style": &"moat", "gap": 20.0, "width": 16.0, "glow": 0.5}]],
		"sponsors": ["CASCADE COLA", "SPRINKLE & SONS PLUMBING", "BLUE PLAINS BBQ", "MISTY MEADOW DAIRY", "JUBILEE JEWELERS"],
		"skyline_color": Color("26304a"), "window_color": Color("d8ecff"), "skyline_height": 0.6,
	},
	{
		"id": &"the_vault", "decks": 3, "frame": &"board", "display_name": "The Vault",
		"blurb": "Safecrackers home · a sealed dome on fast turf: grounders scoot through the gaps",
		"shape": [[-45, 100, 3.0], [-22, 114, 3.0], [0, 122, 3.0], [22, 114, 3.0], [45, 100, 3.0]], "air": 0.97, "surface": 1.3,
		"seat_color": Color("2a2f3a"), "seat_color_alt": Color("20242d"), "structure_color": Color("9aa3b5"), "accent_color": Color("ff5ad0"),
		"outfield_wall_color": Color("1c2236"), "wall_style": &"padded", "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.7,
		"foul_rows": 26, "outfield_rows": 14, "turf": true,
		"pieces": [[&"dome"], [&"flags", -50.0, {"span": 100.0, "count": 10}]], "standard": [&"centerpiece", &"scoreboard", &"slogan_board"],
		"sponsors": ["STRONGBOX SECURITY", "TITAN TURF", "DOMELIGHT DINER", "PRESSURE SEAL WINDOWS", "BIG TOP BURGERS"],
		"skyline_color": Color("26304a"), "window_color": Color("d8ecff"),
	},
]


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/stadiums")
	for spec in PARKS:
		var park := StadiumDef.new()
		var shape := FieldShape.new()
		shape.id = spec["id"]
		shape.display_name = spec["display_name"]
		var points := PackedVector3Array()
		for p in spec["shape"]:
			points.append(Vector3(p[0], p[1], p[2]))
		shape.points = points
		shape.air_drag_scale = spec["air"]
		shape.surface_speed = spec.get("surface", 1.0)
		park.field_shape = shape
		for kind: StringName in spec.get("standard", StadiumModules.STANDARD):
			var tall: float = spec.get("skyline_height", 1.0)
			var params := {}
			if kind == &"skyline" and tall != 1.0:
				params["height"] = tall
			if kind == &"centerpiece" and spec["frame"] != &"board":
				params["frame"] = spec["frame"]
			if kind == &"centerpiece" and spec.get("clock", false):
				params["clock"] = true
			park.add_piece(kind, NAN, params)
		for p in spec.get("pieces", []):
			park.add_piece(p[0], p[1] if p.size() > 1 else NAN, p[2] if p.size() > 2 else {}, p[3] if p.size() > 3 else false)
		var problems := park.validate()
		if not problems.is_empty():
			push_error("%s: %s" % [park.id, ", ".join(problems)])
		for key in spec:
			if key in ["shape", "air", "surface", "pieces", "standard", "skyline_height", "frame", "clock"]:
				continue
			var value: Variant = spec[key]
			park.set(key, PackedStringArray(value) if key == "sponsors" else value)
		var path := "res://data/stadiums/%s.tres" % park.id
		print("%s -> %s (%s)" % [park.display_name, path, error_string(ResourceSaver.save(park, path))])
	quit()
