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
## Surfaces (facade, structure, ground) name StadiumSurfaces kinds.

const PARKS := [
	{
		"id": &"halo_dome", "pillar_cap": &"emblem", "crown": true, "sky": &"sunset", "facade_color": Color("6a5a8c"), "facade_surface": &"marble", "structure_surface": &"steel", "decks": 3, "frame": &"board", "display_name": "The Halo Dome",
		"blurb": "Glitterati home · symmetrical, padded glass-and-gold wall",
		"shape": [[-45, 96, 3.4], [-30, 104, 3.4], [-15, 112, 3.4], [0, 116, 4.2], [15, 112, 3.4], [30, 104, 3.4], [45, 96, 3.4]], "air": 1.0,
		"seat_color": Color("3d2466"), "seat_color_alt": Color("2c1a4d"), "structure_color": Color("8f8aa3"), "accent_color": Color("ffc94a"),
		"outfield_wall_color": Color("2a1c4f"), "wall_style": &"neon", "home_fan_share": 0.62, "away_fan_share": 0.12, "attendance": 0.9,
		"pieces": [[&"halo"], [&"waterfalls", 11.0, {}, true], [&"trees", 15.0, {"span": 35.0, "count": 7, "kind": &"palm"}, true], [&"flying_craft"], [&"flags", -50.0, {"span": 100.0, "count": 12}], [&"water", 0.0, {"style": &"moat", "gap": 24.0, "width": 12.0, "glow": 1.2}], [&"arcade", 50.0, {"style": &"arches", "height": 11.0, "banners": 4}, true], [&"arcade", 11.0, {"style": &"glass", "towers": 3, "tower_height": 14.0, "cap": &"dome", "height": 16.0, "span": 36.0, "banners": 3}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"motif": &"star", "glow": 0.8}], [&"lamps", -150.0, {"span": 300.0, "count": 40}], [&"string_lights", -150.0, {"color": Color("ffd56b")}], [&"planters", -46.0, {"span": 92.0, "flower": Color("c58cff"), "density": 2.0}], [&"props", -150.0, {"model": &"lantern", "every": 7, "height": 7.5}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 6, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["SPOTLIGHT COLA", "NEON HEIGHTS TRANSIT", "MARQUEE MOTORS", "VELVET ROPE LOUNGE", "GLAM SLAM GUM", "CRT VISION", "HEADLINER HOTELS", "ENCORE AIRWAYS"],
		"skyline_color": Color("2b2a52"), "window_color": Color("ffd27a"), "skyline_height": 1.0,
	},
	{
		"id": &"foundry_field", "pillar_cap": &"brazier", "sky": &"sunset", "facade_color": Color("8a4a32"), "facade_surface": &"brick", "structure_surface": &"steel", "decks": 2, "frame": &"gate", "display_name": "Foundry Field",
		"blurb": "Gearheads home · The Boilerplate: a 34-foot iron wall in short right",
		"shape": [[-45, 101, 2.6], [-25, 116, 2.6], [0, 121, 2.6], [13, 113, 2.6], [14.5, 111, 10.5], [30, 99, 10.5], [45, 90, 10.5]], "air": 1.0,
		"seat_color": Color("6b3a22"), "seat_color_alt": Color("4f2b19"), "structure_color": Color("8a7d70"), "accent_color": Color("ff8a2a"),
		"outfield_wall_color": Color("2e2a2a"), "wall_style": &"iron", "wall_stripe": Color("c6531a"), "home_fan_share": 0.6, "away_fan_share": 0.15, "attendance": 0.75,
		"foul_rows": 20, "outfield_rows": 12,
		"pieces": [[&"wall_scoreboard", 26.0], [&"smokestacks", -32.0, {"span": -40.0, "count": 5}], [&"cranes", 22.0, {"span": 30.0, "count": 3}], [&"bridge", 38.0, {"distance": 140.0}], [&"waterfalls", -12.0, {"height": 20.0}], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"water", 10.0, {"distance": 190.0, "width": 70.0}], [&"arcade", 50.0, {"style": &"truss", "height": 10.0, "banners": 0}, true], [&"arcade", 11.0, {"style": &"truss", "height": 15.0, "span": 36.0, "banners": 3}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"motif": &"gear"}], [&"lamps", -150.0, {"span": 300.0, "count": 34}], [&"string_lights", -150.0, {"color": Color("ffb35c")}], [&"lamps", -46.0, {"span": 92.0, "count": 16, "style": &"brazier"}], [&"props", -150.0, {"model": &"lantern", "every": 9, "height": 7.5}]],
		"sponsors": ["RIVET & SONS HARDWARE", "RUSTWATER FERRY", "SPROCKET DINER", "LUGNUT BREWS", "FORGE & ANVIL", "BOILERMAKERS UNION"],
		"skyline_color": Color("4a4040"), "window_color": Color("ffb35c"), "skyline_height": 0.6,
	},
	{
		"id": &"ledger_street", "facade_color": Color("a0503c"), "facade_surface": &"brick", "structure_surface": &"stone", "decks": 2, "frame": &"arch", "display_name": "Ledger Street Park",
		"blurb": "Bankers home · The Leviathan: a 37-foot green wall in short left, a deep triangle in right-center",
		"shape": [[-45, 94.5, 11.3], [-30, 101, 11.3], [-14, 111, 11.3], [-12.5, 114, 4.0], [0, 119, 4.0], [12, 128, 4.0], [24, 116, 1.8], [33, 104, 1.8], [45, 92, 1.0]], "air": 1.0,
		"seat_color": Color("1f4a33"), "seat_color_alt": Color("173828"), "structure_color": Color("8a4b3c"), "accent_color": Color("f2e6c8"),
		"outfield_wall_color": Color("1d5235"), "wall_style": &"padded", "wall_stripe": Color("d4a017"), "home_fan_share": 0.5, "away_fan_share": 0.3, "attendance": 0.95,
		"foul_rows": 22, "outfield_rows": 10,
		"pieces": [[&"wall_scoreboard", -28.0], [&"statue", 22.0, {}, true], [&"trees", 30.0, {"span": 25.0, "count": 5, "kind": &"round"}, true], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"water", 65.0, {"distance": 115.0, "width": 24.0}], [&"bridge", 75.0, {"distance": 65.0, "length": 80.0}], [&"bunting", 50.0, {"span": 260.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"victorian", "bay": 9.0, "towers": 5, "tower_height": 10.0, "cap": &"spire", "height": 9.0, "banners": 5}, true], [&"arcade", 11.0, {"style": &"arches", "towers": 3, "tower_height": 12.0, "cap": &"dome", "height": 14.0, "span": 36.0, "banners": 3}, true], [&"wall_art", 0.0, {"motif": &"emblem", "every": 10.0}], [&"lamps", -150.0, {"span": 300.0, "count": 40}], [&"string_lights", -150.0, {"color": Color("ffe1a8")}], [&"planters", -46.0, {"span": 92.0, "flower": Color("ffffff"), "density": 1.6}], [&"props", -150.0, {"model": &"lantern", "every": 7, "height": 7.5}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 8, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["PEMBERTON PEANUTS", "COBBLESTONE COFFEE", "LANTERN LAUNDRY", "IRONCLAD INSURANCE", "LEDGER STREET LAGER"],
		"skyline_color": Color("5a4a48"), "window_color": Color("ffe1a8"), "skyline_height": 0.8,
	},
	{
		"id": &"pier_nine", "facade_color": Color("8a6a4a"), "facade_surface": &"wood", "structure_surface": &"stone", "decks": 2, "frame": &"board", "display_name": "Pier 9 Ballyard",
		"blurb": "Gulls home · short porch in right, the bay beyond it, deep left-center",
		"shape": [[-45, 101, 2.4], [-20, 115, 2.4], [0, 123, 2.4], [20, 110, 2.4], [32, 101, 2.4], [45, 94, 2.4]], "air": 1.03,
		"seat_color": Color("1d3b5c"), "seat_color_alt": Color("152c45"), "structure_color": Color("c9c4b6"), "accent_color": Color("ff6b4a"),
		"outfield_wall_color": Color("133047"), "wall_style": &"wood", "home_fan_share": 0.45, "away_fan_share": 0.35, "attendance": 0.88,
		"foul_rows": 24, "outfield_rows": 8,
		"pieces": [[&"bay", 40.0], [&"lighthouse", 16.0], [&"sailboats", 8.0, {"span": 34.0, "count": 7}], [&"cranes", -30.0, {"count": 1}], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"water", 62.0, {"style": &"moat", "gap": 6.0, "width": 400.0, "span": 198.0}], [&"arcade", 50.0, {"style": &"timber", "height": 8.0, "banners": 0}, true], [&"arcade", 11.0, {"style": &"timber", "height": 13.0, "span": 36.0, "banners": 3}, true], [&"canopy", 52.0, {"style": &"timber"}, true], [&"wall_art", 0.0, {"motif": &"waves", "every": 7.0}], [&"lamps", -150.0, {"span": 300.0, "count": 36}], [&"string_lights", -150.0, {"color": Color("fff0c0"), "sag": 2.0}], [&"props", -150.0, {"model": &"lantern", "every": 8, "height": 7.5}]],
		"sponsors": ["SALTWIND SAILS", "PIER 9 OYSTERS", "TIDECALLER TAXI", "BUOY BEVERAGES", "FOGHORN FRIES"],
		"skyline_color": Color("37465e"), "window_color": Color("ffe9b0"), "skyline_height": 0.9,
	},
	{
		"id": &"the_kiln", "sky": &"golden", "facade_color": Color("b25a3c"), "facade_surface": &"rock", "structure_surface": &"stone", "ground_surface": &"sand", "ground_color": Color("8f4a2c"), "decks": 2, "frame": &"gate", "display_name": "The Kiln",
		"blurb": "Comets home · thin desert air carries the ball, so the outfield is a canyon; red mesas and a rocket beyond",
		"shape": [[-45, 105, 4.3], [-25, 119, 4.3], [0, 127, 4.3], [25, 119, 4.3], [45, 106, 4.3]], "air": 0.82,
		"seat_color": Color("a65a32"), "seat_color_alt": Color("8a4826"), "structure_color": Color("d9b98a"), "accent_color": Color("2ec4b6"),
		"outfield_wall_color": Color("2f3936"), "wall_style": &"rock", "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.8,
		"foul_rows": 24, "outfield_rows": 18,
		"pieces": [[&"mountains", -95.0, {"style": &"mesa", "span": 190.0, "count": 12, "distance": 320.0, "height": 85.0, "arch": true}], [&"rocket", 16.0, {"height": 70.0}], [&"smokestacks", 34.0, {"span": 16.0, "count": 2, "height": 40.0}], [&"trees", 20.0, {"span": 30.0, "count": 4, "kind": &"cactus"}, true], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"arcade", 50.0, {"style": &"kit", "kit": &"colosseum", "bay": 9.0, "height": 9.0, "banners": 6}, true], [&"arcade", 11.0, {"style": &"arches", "towers": 3, "tower_height": 8.0, "cap": &"flat", "height": 6.0, "span": 36.0, "banners": 3}, true], [&"wall_art", 0.0, {"motif": &"star"}], [&"lamps", -150.0, {"span": 300.0, "count": 30}], [&"string_lights", -150.0, {"color": Color("ffc070")}], [&"props", -150.0, {"model": &"lantern", "every": 9, "height": 7.5}]],
		"sponsors": ["SUNBAKED SODA", "MESA MOTOR LODGE", "CACTUS CANDY CO.", "COPPER CANYON CHILI"],
		"skyline_color": Color("b08a62"), "window_color": Color("fff0c0"), "skyline_height": 0.35,
	},
	{
		"id": &"the_icebox", "facade_color": Color("8494a6"), "facade_surface": &"stone", "structure_surface": &"wood", "ground_surface": &"snow", "ground_color": Color("e4ebf2"), "decks": 2, "frame": &"arch", "display_name": "The Icebox",
		"blurb": "Yetis home · cold heavy air knocks fly balls down; ice falls and peaks beyond the wall",
		"shape": [[-45, 99, 4.6], [-22, 112, 4.6], [0, 118, 4.6], [22, 112, 4.6], [45, 99, 4.6]], "air": 1.1,
		"seat_color": Color("2d4a63"), "seat_color_alt": Color("223a4f"), "structure_color": Color("b8c4cc"), "accent_color": Color("9fe8ff"),
		"outfield_wall_color": Color("143a63"), "wall_style": &"ice", "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.85,
		"pieces": [[&"mountains", -125.0, {"span": 250.0, "count": 13, "height": 150.0, "distance": 540.0}], [&"waterfalls", 10.0, {"frozen": true, "height": 34.0, "width": 16.0}, true], [&"trees", 22.0, {"span": 45.0, "count": 10, "kind": &"pine"}, true], [&"gondola", -32.0, {"span": -40.0}], [&"icicles", -180.0], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"arcade", 50.0, {"style": &"timber", "height": 9.0, "banners": 5}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"gothic", "bay": 9.0, "towers": 3, "tower_height": 9.0, "cap": &"spire", "height": 14.0, "span": 36.0, "banners": 3}, true], [&"canopy", 52.0, {"style": &"timber"}, true], [&"wall_art", 0.0, {"motif": &"snowflake", "every": 7.0}], [&"icicles", -60.0, {"span": 120.0}], [&"string_lights", -150.0, {"color": Color("dff4ff")}], [&"props", -150.0, {"model": &"lantern", "every": 8, "height": 7.5}]],
		"sponsors": ["FROSTGATE FURNACES", "SNOWLINE SKIS", "YETI COCOA", "GLACIER GLASS", "NORTHWIND WOOLENS"],
		"skyline_color": Color("4a5866"), "window_color": Color("dff4ff"), "skyline_height": 0.4,
	},
	{
		"id": &"reactor_park", "pillar_cap": &"emblem", "sky": &"dusk", "facade_color": Color("6a6e70"), "facade_surface": &"concrete", "structure_surface": &"steel", "decks": 3, "frame": &"gate", "display_name": "Reactor Park",
		"blurb": "Neutrons home · odd angles and a deep center-field notch behind a tall reactor wall",
		"shape": [[-45, 98, 3.0], [-28, 108, 3.0], [-12, 121, 3.0], [-9, 130, 6.5], [-3, 130, 6.5], [0, 120, 3.0], [9, 121, 3.0], [18, 111, 3.0], [31, 102, 3.0], [45, 97, 3.0]], "air": 1.0,
		"seat_color": Color("2a2e30"), "seat_color_alt": Color("202426"), "structure_color": Color("4b5154"), "accent_color": Color("39d353"),
		"outfield_wall_color": Color("1e2622"), "wall_style": &"neon", "wall_stripe": Color("39d353"), "wall_stripe_glow": 1.5, "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.82, "night": true,
		"pieces": [[&"smokestacks", -24.0, {"span": -30.0, "count": 2, "style": &"cooling", "height": 75.0, "tint": 0.6}], [&"smokestacks", 24.0, {"span": 30.0, "count": 2, "style": &"cooling", "height": 70.0, "tint": 0.6}], [&"smokestacks", 46.0, {"span": 14.0, "count": 2, "height": 45.0}], [&"pipes", -48.0, {"span": 96.0}], [&"water", 25.0, {"distance": 200.0, "width": 55.0}], [&"arcade", 50.0, {"style": &"truss", "height": 11.0, "banners": 0}, true], [&"arcade", 11.0, {"style": &"truss", "height": 16.0, "span": 36.0, "banners": 3}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"motif": &"zigzag", "glow": 2.0}], [&"pipes", 12.0, {"span": 34.0, "runs": 3}, true], [&"string_lights", -150.0, {"color": Color("7dffb0")}]],
		"sponsors": ["ATOMIC FALLS POWER & LIGHT", "MUSHROOM CLOUD MALTS", "FISSION FIZZ", "RAY-GUN RADIO"],
		"skyline_color": Color("3d3f2e"), "window_color": Color("c8ffd8"), "skyline_height": 0.9,
	},
	{
		"id": &"the_horseshoe", "sky": &"dusk", "facade_color": Color("9a7a5e"), "facade_surface": &"stone", "structure_surface": &"brick", "decks": 2, "frame": &"arch", "display_name": "The Horseshoe",
		"blurb": "Lamplighters home · night ball in a horseshoe: 279-foot lines, a 482-foot center field",
		"shape": [[-45, 85, 4.9], [-36, 97, 4.9], [-26, 120, 3.0], [-12, 139, 3.0], [0, 147, 3.0], [12, 139, 3.0], [26, 119, 3.0], [36, 94, 3.4], [45, 81, 3.4]], "air": 1.0,
		"seat_color": Color("16294a"), "seat_color_alt": Color("10203a"), "structure_color": Color("7a5a44"), "accent_color": Color("f0c04b"),
		"outfield_wall_color": Color("0f2440"), "wall_style": &"padded", "wall_stripe": Color("f0c04b"), "wall_stripe_glow": 0.8, "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.9,
		"foul_rows": 28, "outfield_rows": 20, "night": true,
		"pieces": [[&"viaduct", 14.0, {"span": 40.0, "height": 18.0}], [&"lamps", -150.0, {"span": 300.0, "count": 44}], [&"bunting", 50.0, {"span": 260.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"victorian", "bay": 9.0, "towers": 6, "tower_height": 7.0, "cap": &"dome", "height": 12.0, "banners": 6}, true], [&"arcade", 11.0, {"style": &"arches", "height": 17.0, "span": 36.0, "banners": 3}, true], [&"wall_art", 0.0, {"motif": &"star", "glow": 0.6, "every": 10.0}], [&"string_lights", -150.0, {"color": Color("ffd59a"), "every": 4.0}], [&"props", -150.0, {"model": &"lantern", "every": 5, "height": 7.5}]],
		"sponsors": ["OLD TOWNE TROLLEY", "HORSESHOE HAMS", "MIDNIGHT MATINEE", "NICKEL ARCADE", "LAMPLIGHTER LAGER"],
		"skyline_color": Color("1a1f33"), "window_color": Color("ffe0a0"), "skyline_height": 1.2,
	},
	{
		"id": &"warehouse_row", "facade_color": Color("8a3e2e"), "facade_surface": &"brick", "structure_surface": &"steel", "decks": 2, "frame": &"gate", "clock": true, "display_name": "Warehouse Row",
		"blurb": "Conductors home · a 25-foot brick wall in right and the old Roundhouse warehouse looming over it",
		"shape": [[-45, 101, 2.4], [-25, 111, 2.4], [-8, 123, 2.4], [0, 122, 2.4], [14, 115, 2.4], [20, 112, 2.4], [21.5, 110, 7.6], [45, 97, 7.6]], "air": 1.0,
		"seat_color": Color("8a2a2a"), "seat_color_alt": Color("6e2121"), "structure_color": Color("6e3a2c"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("1f3a3c"), "wall_style": &"padded", "wall_stripe": Color("b2222b"), "home_fan_share": 0.5, "away_fan_share": 0.3, "attendance": 0.92,
		"foul_rows": 24, "outfield_rows": 12,
		"pieces": [[&"warehouse", 45.0], [&"warehouse", -45.0, {"text": "CARGO BUILDS CITIES", "length": 180.0}], [&"viaduct", 16.0, {"span": 34.0, "height": 20.0}], [&"cranes", 30.0, {"span": 20.0, "count": 2}], [&"smokestacks", 40.0, {"span": 8.0, "count": 1, "height": 35.0}], [&"bunting", 50.0, {"span": 260.0}], [&"water", 20.0, {"distance": 230.0, "width": 60.0}], [&"bridge", -15.0, {"distance": 180.0, "length": 200.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"victorian", "bay": 9.0, "height": 10.0, "banners": 6}, true], [&"arcade", 11.0, {"style": &"windows", "height": 15.0, "span": 36.0, "banners": 3}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"motif": &"crossed", "every": 10.0}], [&"lamps", -150.0, {"span": 300.0, "count": 34}], [&"string_lights", -150.0, {"color": Color("ffd59a")}], [&"props", -150.0, {"model": &"lantern", "every": 7, "height": 7.5}]],
		"sponsors": ["ROUNDHOUSE STORAGE CO.", "HARBORLIGHT CRAB SHACK", "BRASS RAIL BITTERS", "OLD LINE LOCKSMITHS", "CANAL STREET CANDY"],
		"skyline_color": Color("514848"), "window_color": Color("ffe1a8"), "skyline_height": 0.9,
	},
	{
		"id": &"fountain_gardens", "facade_color": Color("d6cfbb"), "facade_surface": &"marble", "structure_surface": &"stone", "decks": 2, "frame": &"board", "display_name": "Fountain Gardens",
		"blurb": "Swans home · big, symmetric and fair: garden terraces, fountains and blossoms beyond the wall",
		"shape": [[-45, 101, 3.7], [-22, 118, 3.7], [0, 125, 3.7], [22, 118, 3.7], [45, 101, 3.7]], "air": 1.0,
		"seat_color": Color("1d4a35"), "seat_color_alt": Color("163c2b"), "structure_color": Color("e8e2d0"), "accent_color": Color("d4af37"),
		"outfield_wall_color": Color("145a3b"), "wall_style": &"marble", "wall_stripe": Color("d4af37"), "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.8,
		"foul_rows": 24, "outfield_rows": 5,
		"pieces": [[&"fountains", 14.0, {}, true], [&"waterfalls", 9.0, {"height": 22.0}, true], [&"trees", 22.0, {"span": 30.0, "count": 8, "kind": &"blossom"}, true], [&"trees", 4.0, {"span": 8.0, "count": 4, "kind": &"cypress"}, true], [&"statue", 16.0, {"figure": &"figure"}, true], [&"conservatory", 42.0], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"water", 0.0, {"style": &"moat", "gap": 20.0, "width": 16.0, "glow": 0.5}], [&"arcade", 50.0, {"style": &"kit", "kit": &"colosseum", "bay": 9.0, "height": 10.0, "banners": 5}, true], [&"arcade", 11.0, {"style": &"colonnade", "height": 15.0, "span": 36.0, "banners": 3}, true], [&"wall_art", 0.0, {"motif": &"blossom", "every": 7.0}], [&"lamps", -150.0, {"span": 300.0, "count": 36}], [&"planters", -46.0, {"span": 92.0, "flower": Color("f3a7c4"), "density": 2.5}], [&"string_lights", -150.0, {"color": Color("fff3dc")}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 4, "height": 5.5, "place": &"terrace"}], [&"props", -46.0, {"model": &"column", "span": 92.0, "every": 6, "height": 9, "place": &"terrace", "tint": 0.6}]],
		"sponsors": ["CASCADE COLA", "SPRINKLE & SONS PLUMBING", "BLUE PLAINS BBQ", "MISTY MEADOW DAIRY", "JUBILEE JEWELERS"],
		"skyline_color": Color("26304a"), "window_color": Color("d8ecff"), "skyline_height": 0.6,
	},
	{
		"id": &"the_vault", "sky": &"night", "facade_color": Color("5a5e66"), "facade_surface": &"concrete", "structure_surface": &"steel", "decks": 3, "frame": &"gate", "display_name": "The Vault",
		"blurb": "Safecrackers home · fast turf under searchlights: grounders scoot through the gaps, a giant vault door looms in left",
		"shape": [[-45, 100, 3.0], [-22, 114, 3.0], [0, 122, 3.0], [22, 114, 3.0], [45, 100, 3.0]], "air": 0.97, "surface": 1.3,
		"seat_color": Color("7a1a26"), "seat_color_alt": Color("5e141d"), "structure_color": Color("4a4f5a"), "accent_color": Color("ff2d2d"),
		"outfield_wall_color": Color("1a2230"), "wall_style": &"iron", "wall_stripe": Color("ff2d2d"), "wall_stripe_glow": 2.0, "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.7,
		"foul_rows": 26, "outfield_rows": 14, "turf": true, "night": true, "standard": [&"centerpiece", &"slogan_board", &"light_towers", &"skyline"],
		"pieces": [[&"vault_door", -37.0], [&"slogan_board", -21.0, {"text": "Vaultborough Safecrackers", "height": 10.0}], [&"searchlights", -70.0, {"span": 140.0, "count": 7}], [&"viaduct", 18.0, {"span": 32.0, "height": 20.0}], [&"bridge", 40.0, {"distance": 120.0, "length": 160.0}], [&"bunting", 50.0, {"span": 260.0}], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"arcade", 50.0, {"style": &"truss", "towers": 5, "tower_height": 9.0, "cap": &"flat", "height": 11.0, "banners": 4}, true], [&"arcade", 11.0, {"style": &"truss", "height": 16.0, "span": 36.0, "banners": 3}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"motif": &"crossed", "glow": 1.5, "every": 10.0}], [&"lamps", -150.0, {"span": 300.0, "count": 34}], [&"string_lights", -150.0, {"color": Color("ff6a5a")}], [&"props", -150.0, {"model": &"lantern", "every": 8, "height": 7.5}]],
		"sponsors": ["STRONGBOX SECURITY", "TITAN TURF", "DOMELIGHT DINER", "PRESSURE SEAL WINDOWS", "BIG TOP BURGERS"],
		"skyline_color": Color("1e2433"), "window_color": Color("ffd59a"), "skyline_height": 1.3,
	},
	{
		"id": &"sakura_gate", "pillar_cap": &"lamp", "sky": &"sunset", "facade_color": Color("7a2420"), "facade_surface": &"wood", "structure_surface": &"wood", "decks": 3, "frame": &"gate", "display_name": "Sakura Gate Park",
		"blurb": "Kitsune home · a mountain shrine under cherry blossoms: torii gates, pagodas and a great fox spirit",
		"shape": [[-45, 97, 3.0], [-22, 112, 3.0], [0, 122, 3.0], [22, 118, 3.0], [45, 109, 3.0]], "air": 1.02,
		"seat_color": Color("8a1c2a"), "seat_color_alt": Color("6e1622"), "structure_color": Color("4a2c22"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("221516"), "wall_style": &"wood", "wall_stripe": Color("d4a017"), "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.9,
		"foul_rows": 24, "outfield_rows": 12, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"mountains", -8.0, {"span": 16.0, "count": 1, "height": 210.0, "distance": 620.0}], [&"mountains", -70.0, {"span": 140.0, "count": 8, "height": 110.0, "distance": 560.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"temple", "bay": 9.0, "height": 10.0, "banners": 5, "towers": 5, "tower_height": 9.0, "cap": &"pagoda"}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"temple", "bay": 9.0, "height": 12.0, "span": 36.0, "banners": 3, "towers": 2, "tower_height": 14.0, "cap": &"pagoda"}, true], [&"torii", 24.0, {"height": 22.0, "distance": 30.0}], [&"torii", -26.0, {"height": 14.0, "distance": 4.0}], [&"statue", 31.0, {"figure": &"fox", "scale": 1.3}], [&"waterfalls", 7.0, {"height": 26.0}, true], [&"trees", 14.0, {"span": 40.0, "count": 12, "kind": &"blossom"}, true], [&"lamps", -150.0, {"span": 300.0, "count": 40}], [&"wall_art", 0.0, {"motif": &"blossom", "every": 7.0}], [&"planters", -46.0, {"span": 92.0, "flower": Color("f7b6cf"), "green": Color("e8a3bf"), "density": 2.0}], [&"string_lights", -150.0, {"color": Color("ff9a5a"), "every": 5.0}], [&"props", -150.0, {"model": &"lantern", "every": 6, "height": 7.5}]],
		"sponsors": ["LANTERN TEA HOUSE", "PETAL RAMEN", "FOXFIRE FIREWORKS", "MOUNTAIN SPRING SODA"],
		"skyline_color": Color("3a2a3a"), "window_color": Color("ffc48a"),
	},
	{
		"id": &"deepwater", "pillar_cap": &"emblem", "sky": &"underwater", "ground_color": Color("0e3b4a"), "facade_color": Color("6f8f8a"), "facade_surface": &"stone", "structure_surface": &"stone", "decks": 3, "frame": &"arch", "display_name": "Deepwater Park",
		"blurb": "Krakens home · a sunken ruin under the sea: glass tanks, aqueducts and the sea king",
		"shape": [[-45, 98, 3.0], [-20, 114, 3.0], [0, 123, 3.0], [22, 110, 3.0], [45, 102, 3.0]], "air": 1.06,
		"seat_color": Color("123f55"), "seat_color_alt": Color("0d3245"), "structure_color": Color("5f7f7f"), "accent_color": Color("2ebbbb"),
		"outfield_wall_color": Color("0b3d54"), "wall_style": &"glass", "wall_stripe": Color("d4af37"), "home_fan_share": 0.55, "away_fan_share": 0.25, "attendance": 0.85,
		"foul_rows": 26, "outfield_rows": 10, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"water", 0.0, {"style": &"moat", "gap": 4.0, "width": 500.0, "glow": 0.3}], [&"arcade", 50.0, {"style": &"arches", "tiers": 2, "height": 14.0, "banners": 4, "towers": 5, "tower_height": 8.0, "cap": &"dome"}, true], [&"arcade", 11.0, {"style": &"arches", "tiers": 2, "height": 16.0, "span": 36.0, "banners": 3, "towers": 3, "tower_height": 10.0, "cap": &"dome"}, true], [&"aquarium", 14.0, {"span": 30.0, "height": 22.0, "fish": 40}, true], [&"statue", 24.0, {"figure": &"titan", "scale": 1.5}], [&"waterfalls", -12.0, {"height": 22.0}], [&"viaduct", -40.0, {"span": 26.0, "height": 22.0, "train": false}], [&"trees", 16.0, {"span": 30.0, "count": 10, "kind": &"coral"}, true], [&"wall_art", 0.0, {"motif": &"trident", "every": 8.0, "glow": 0.6}], [&"planters", -46.0, {"span": 92.0, "flower": Color("ff8a6a"), "green": Color("2a8a7a"), "density": 1.6}], [&"string_lights", -150.0, {"color": Color("9ff3ff")}], [&"props", -150.0, {"model": &"lantern", "every": 7, "height": 7.5}], [&"props", -46.0, {"model": &"column", "span": 92.0, "every": 7, "height": 10, "place": &"terrace", "tint": 0.6}]],
		"sponsors": ["ABYSS AQUARIUM", "KELP COLA", "DEEP DIVE GEAR", "PEARL DIVER BANK"],
		"skyline_color": Color("123a48"), "window_color": Color("9ff3ff"),
	},
	{
		"id": &"cloudreach", "pillar_cap": &"emblem", "ground_color": Color("eef2f8"), "ground_surface": &"snow", "facade_color": Color("b08a4e"), "facade_surface": &"steel", "structure_surface": &"steel", "decks": 3, "frame": &"gate", "display_name": "Cloudreach Stadium",
		"blurb": "Aviators home · a floating island high above the clouds: airships, skybridges and propeller towers",
		"shape": [[-45, 102, 3.0], [-22, 116, 3.0], [0, 125, 3.0], [22, 118, 3.0], [45, 108, 3.0]], "air": 0.9,
		"seat_color": Color("1f4f8f"), "seat_color_alt": Color("183f74"), "structure_color": Color("a8833e"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("0f2a4d"), "wall_style": &"padded", "wall_stripe": Color("d4a017"), "home_fan_share": 0.55, "away_fan_share": 0.25, "attendance": 0.85,
		"foul_rows": 24, "outfield_rows": 10, "skyline_height": 0.8,
		"pieces": [[&"islands", -180.0, {"span": 360.0, "count": 16}], [&"flying_craft", 0.0, {"style": &"blimp", "count": 6}], [&"arcade", 50.0, {"style": &"truss", "height": 11.0, "banners": 4, "towers": 5, "tower_height": 9.0, "cap": &"dome"}, true], [&"arcade", 11.0, {"style": &"glass", "height": 14.0, "span": 36.0, "banners": 3, "towers": 3, "tower_height": 14.0, "cap": &"dome"}, true], [&"propellers", 36.0, {"height": 16.0}, true], [&"lighthouse", -42.0], [&"waterfalls", -16.0, {"height": 24.0}], [&"bridge", -28.0, {"distance": 40.0, "length": 120.0}], [&"wall_art", 0.0, {"motif": &"wings"}], [&"string_lights", -150.0, {"color": Color("fff0c0")}], [&"planters", -46.0, {"span": 92.0, "flower": Color("ffd54a"), "density": 1.2}], [&"props", -150.0, {"model": &"lantern", "every": 8, "height": 7.5}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 8, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["ZEPHYR AIRLINES", "PROPWASH PRETZELS", "CUMULUS COFFEE", "HIGH ALTITUDE HATS"],
		"skyline_color": Color("6c8fb8"), "window_color": Color("fff0c0"),
	},
	{
		"id": &"forum_field", "pillar_cap": &"brazier", "facade_color": Color("d6bf92"), "facade_surface": &"stone", "structure_surface": &"marble", "decks": 3, "frame": &"arch", "display_name": "Forum Field",
		"blurb": "Legion home · a sandstone colosseum: tiered arches, braziers, statues and red banners",
		"shape": [[-45, 101, 3.2], [-20, 115, 3.2], [0, 122, 3.2], [20, 112, 3.2], [45, 97, 3.2]], "air": 1.0,
		"seat_color": Color("8b1e1e"), "seat_color_alt": Color("701818"), "structure_color": Color("c9b48a"), "accent_color": Color("daa520"),
		"outfield_wall_color": Color("7a1d1d"), "wall_style": &"stone", "wall_stripe": Color("daa520"), "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.95,
		"foul_rows": 27, "outfield_rows": 12, "skyline_height": 0.6,
		"pieces": [[&"arcade", 50.0, {"style": &"kit", "kit": &"colosseum", "bay": 9.0, "tiers": 3, "height": 18.0, "banners": 3}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"colosseum", "bay": 9.0, "tiers": 2, "height": 16.0, "span": 36.0, "banners": 2, "towers": 3, "tower_height": 8.0, "cap": &"flat"}, true], [&"statue", 17.0, {"figure": &"knight"}, true], [&"waterfalls", 7.0, {"height": 18.0}, true], [&"trees", 30.0, {"span": 15.0, "count": 5, "kind": &"cypress"}, true], [&"lamps", -150.0, {"span": 300.0, "count": 34, "style": &"brazier"}], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"wall_art", 0.0, {"motif": &"emblem", "every": 9.0}], [&"planters", -46.0, {"span": 92.0, "flower": Color("c0392b"), "density": 1.4}], [&"string_lights", -150.0, {"color": Color("ffc070")}], [&"props", -46.0, {"model": &"column", "span": 92.0, "every": 5, "height": 10, "place": &"terrace", "tint": 0.6}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 7, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["GLADIATOR GYROS", "AQUEDUCT WATER CO.", "LAUREL & SONS", "CHARIOT CAR WASH"],
		"skyline_color": Color("8a6a4a"), "window_color": Color("ffe1a8"),
	},
	{
		"id": &"firelight", "pillar_cap": &"brazier", "sky": &"sunset", "ground_color": Color("3a2a24"), "ground_surface": &"rock", "facade_color": Color("5a4038"), "facade_surface": &"rock", "structure_surface": &"stone", "decks": 3, "frame": &"gate", "display_name": "Firelight Park",
		"blurb": "Vulcans home · an island fortress under a live volcano: lava-lit cliffs, aqueducts and the sea",
		"shape": [[-45, 101, 3.0], [-22, 117, 3.0], [0, 126, 3.0], [24, 119, 3.0], [45, 110, 3.0]], "air": 0.98,
		"seat_color": Color("7a2a1a"), "seat_color_alt": Color("5e2014"), "structure_color": Color("6a5a50"), "accent_color": Color("ff6a00"),
		"outfield_wall_color": Color("221b18"), "wall_style": &"rock", "wall_stripe": Color("ff6a00"), "wall_stripe_glow": 2.0, "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.9,
		"foul_rows": 25, "outfield_rows": 12, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"mountains", -12.0, {"style": &"volcano", "height": 150.0, "distance": 430.0}], [&"water", 20.0, {"style": &"moat", "gap": 18.0, "width": 450.0, "span": 150.0}], [&"sailboats", 32.0, {"span": 40.0, "count": 6}], [&"lighthouse", 42.0], [&"arcade", 50.0, {"style": &"carved", "height": 11.0, "banners": 4, "towers": 5, "tower_height": 8.0, "cap": &"flat"}, true], [&"arcade", 11.0, {"style": &"carved", "height": 14.0, "span": 36.0, "banners": 3, "towers": 3, "tower_height": 12.0, "cap": &"flat"}, true], [&"waterfalls", -30.0, {"height": 26.0}], [&"viaduct", 18.0, {"span": 20.0, "height": 22.0, "train": false}], [&"trees", -22.0, {"span": -20.0, "count": 6, "kind": &"palm"}], [&"lamps", -150.0, {"span": 300.0, "count": 34, "style": &"brazier"}], [&"wall_art", 0.0, {"motif": &"flame", "glow": 1.5}], [&"string_lights", -150.0, {"color": Color("ff8a3a")}], [&"props", -150.0, {"model": &"lantern", "every": 7, "height": 7.5}]],
		"sponsors": ["MAGMA HOT SAUCE", "OBSIDIAN OPTICS", "CALDERA COFFEE", "ASHFALL INSURANCE"],
		"skyline_color": Color("3a2a2a"), "window_color": Color("ffb35c"),
	},
	{
		"id": &"citadel_park", "pillar_cap": &"emblem", "facade_color": Color("8c8a8e"), "facade_surface": &"stone", "structure_surface": &"stone", "decks": 3, "frame": &"arch", "display_name": "Citadel Park",
		"blurb": "Sentinels home · a fortified citadel: battlements, knight guardians and a cathedral skyline",
		"shape": [[-45, 100, 3.4], [-22, 115, 3.4], [0, 125, 3.4], [22, 118, 3.4], [45, 108, 3.4]], "air": 1.02,
		"seat_color": Color("1f3a6f"), "seat_color_alt": Color("192f5a"), "structure_color": Color("6e6c72"), "accent_color": Color("d4af37"),
		"outfield_wall_color": Color("1b2a4f"), "wall_style": &"stone", "wall_stripe": Color("a61e2d"), "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.9,
		"foul_rows": 26, "outfield_rows": 12, "skyline_height": 0.7,
		"pieces": [[&"arcade", 50.0, {"style": &"kit", "kit": &"gothic", "bay": 9.0, "height": 12.0, "banners": 3, "towers": 4, "tower_height": 10.0, "cap": &"spire"}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"gothic", "bay": 9.0, "height": 16.0, "span": 36.0, "banners": 2, "towers": 2, "tower_height": 16.0, "cap": &"spire"}, true], [&"statue", 15.0, {"figure": &"knight"}, true], [&"cathedral", -6.0, {"distance": 150.0}], [&"flags", -55.0, {"span": 110.0, "count": 16}], [&"wall_art", 0.0, {"motif": &"emblem", "every": 8.0}], [&"string_lights", -150.0, {"color": Color("ffd59a")}], [&"props", -150.0, {"model": &"lantern", "every": 7, "height": 7.5}]],
		"sponsors": ["RAMPART ROOFING", "SQUIRE SANDWICHES", "PORTCULLIS PARKING", "BASTION BANK"],
		"skyline_color": Color("4a4a58"), "window_color": Color("ffd59a"),
	},
	{
		"id": &"amber_gate", "pillar_cap": &"brazier", "sky": &"golden", "ground_color": Color("c99a62"), "ground_surface": &"sand", "facade_color": Color("c4925a"), "facade_surface": &"stone", "structure_surface": &"stone", "decks": 3, "frame": &"gate", "display_name": "Amber Gate Park",
		"blurb": "Scorpions home · a desert canyon city: scorpion statues, an oasis of palms and market terraces",
		"shape": [[-45, 94, 3.0], [-22, 113, 3.0], [0, 130, 3.0], [24, 120, 3.0], [45, 107, 3.0]], "air": 0.9,
		"seat_color": Color("8b1e2d"), "seat_color_alt": Color("701824"), "structure_color": Color("b88a58"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("5e1a24"), "wall_style": &"stone", "wall_stripe": Color("d4a017"), "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.88,
		"foul_rows": 25, "outfield_rows": 12, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"mountains", -100.0, {"style": &"mesa", "span": 200.0, "count": 12, "height": 75.0, "distance": 340.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"colosseum", "bay": 9.0, "tiers": 2, "height": 12.0, "banners": 4}, true], [&"canopy", 52.0, {"style": &"cloth"}, true], [&"arcade", 11.0, {"style": &"carved", "height": 13.0, "span": 36.0, "banners": 3, "towers": 3, "tower_height": 10.0, "cap": &"dome"}, true], [&"statue", 9.0, {"figure": &"scorpion", "scale": 1.6}, true], [&"waterfalls", 5.0, {"height": 20.0}, true], [&"trees", 22.0, {"span": 30.0, "count": 9, "kind": &"palm"}, true], [&"lamps", -150.0, {"span": 300.0, "count": 32, "style": &"brazier"}], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"wall_art", 0.0, {"motif": &"star"}], [&"planters", -46.0, {"span": 92.0, "flower": Color("e85d4a"), "density": 1.6}], [&"string_lights", -150.0, {"color": Color("ffc070")}], [&"props", -150.0, {"model": &"lantern", "every": 6, "height": 7.5}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 7, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["OASIS SPRINGS", "CARAVAN KEBAB", "SANDSTORM SUNSCREEN", "DUNE BUGGY RENTALS"],
		"skyline_color": Color("a07850"), "window_color": Color("ffe0a0"),
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
			if kind == &"centerpiece" and spec.get("crown", false):
				params["crown"] = true
			if kind == &"centerpiece" and spec.has("pillar_cap"):
				params["pillar_cap"] = spec["pillar_cap"]
			park.add_piece(kind, NAN, params)
		for p in spec.get("pieces", []):
			park.add_piece(p[0], p[1] if p.size() > 1 else NAN, p[2] if p.size() > 2 else {}, p[3] if p.size() > 3 else false)
		var problems := park.validate()
		if not problems.is_empty():
			push_error("%s: %s" % [park.id, ", ".join(problems)])
		for key in spec:
			if key in ["shape", "air", "surface", "pieces", "standard", "skyline_height", "frame", "clock", "crown", "pillar_cap"]:
				continue
			var value: Variant = spec[key]
			park.set(key, PackedStringArray(value) if key == "sponsors" else value)
		var path := "res://data/stadiums/%s.tres" % park.id
		print("%s -> %s (%s)" % [park.display_name, path, error_string(ResourceSaver.save(park, path))])
	quit()
