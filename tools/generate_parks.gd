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
		"outfield_open": 30.0, "lights": {"mast": &"deco", "head": &"halo", "heads": 1, "lamp": Color("f3e2ff"), "tilt": 8.0}, "id": &"halo_dome", "grandstand": {"roof": &"barrel", "suites": &"glass", "surface": &"marble", "roof_color": Color("e8dcc4"), "set": &"deco"}, "mowing": "sunburst", "mowing_width": 9.0, "pillar_cap": &"emblem", "sky": &"sunset", "facade_color": Color("6a5a8c"), "facade_surface": &"marble", "structure_surface": &"steel", "decks": 3, "frame": &"model", "frame_model": &"set_deco_gate", "frame_width": 112.0, "display_name": "The Halo Dome",
		"blurb": "Glitterati home · symmetrical, padded glass-and-gold wall",
		"shape": [[-45, 102.4, 4.27], [-22.5, 114.9, 4.27], [0, 121.9, 4.27], [22.5, 113.4, 4.27], [45, 98.1, 4.27]], "air": 1.0,
		"seat_color": Color("3d2466"), "seat_color_alt": Color("2c1a4d"), "structure_color": Color("8f8aa3"), "accent_color": Color("ffc94a"),
		"outfield_wall_color": Color("4a1f7a"), "wall_style": &"padded", "home_fan_share": 0.62, "away_fan_share": 0.12, "attendance": 0.9,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "model": &"set_deco_block", "rows": 2, "height": 40.0, "center_gap": 16.0}], [&"halo"], [&"trees", 11.0, {"span": 6.0, "count": 3, "kind": &"palm"}, true], [&"trees", 15.0, {"span": 35.0, "count": 7, "kind": &"palm"}, true], [&"flying_craft"], [&"water", 0.0, {"style": &"moat", "gap": 24.0, "width": 12.0, "glow": 1.2}], [&"arcade", 50.0, {"style": &"kit", "height": 12.0, "banners": 0, "kit": &"deco_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_deco_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "towers": 3, "tower_height": 14.0, "height": 16.0, "span": 36.0, "banners": 0, "kit": &"deco_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_deco_tower"}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8c547"), "layout": [[-42.0, &"club", 1.0], [42.0, &"club", 1.0]]}], [&"planters", -46.0, {"span": 92.0, "flower": Color("c58cff"), "density": 2.0}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 6, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["SPOTLIGHT COLA", "NEON HEIGHTS TRANSIT", "MARQUEE MOTORS", "VELVET ROPE LOUNGE", "GLAM SLAM GUM", "CRT VISION", "HEADLINER HOTELS", "ENCORE AIRWAYS"],
		"skyline_color": Color("2b2a52"), "window_color": Color("ffd27a"), "skyline_height": 1.0,
	},
	{
		"lights": {"mast": &"lattice", "head": &"bank", "heads": 2, "lamp": Color("ffd29a"), "paint": Color(Color("b4532a"), 0.6)}, "id": &"foundry_field", "grandstand": {"roof": &"sawtooth", "suites": &"glass", "surface": &"steel", "roof_color": Color("5a3a2c"), "set": &"foundry"}, "mowing": "stripes", "mowing_width": 8.0, "dirt_color": Color(0.55, 0.33, 0.22), "pillar_cap": &"brazier", "sky": &"sunset", "facade_color": Color("8a4a32"), "facade_surface": &"brick", "structure_surface": &"steel", "decks": 2, "frame": &"model", "frame_model": &"set_foundry_gate", "display_name": "Foundry Field",
		"blurb": "Gearheads home · The Boilerplate: a 34-foot iron wall in short right",
		"shape": [[-45, 102.4, 4.27], [-22.5, 117.2, 4.27], [0, 121.9, 4.27], [22.5, 116.2, 4.27], [45, 98.1, 4.27]], "air": 1.0,
		"seat_color": Color("6b3a22"), "seat_color_alt": Color("4f2b19"), "structure_color": Color("8a7d70"), "accent_color": Color("ff8a2a"),
		"outfield_wall_color": Color("2a2624"), "wall_style": &"iron", "home_fan_share": 0.6, "away_fan_share": 0.15, "attendance": 0.75,
		"foul_rows": 20, "outfield_open": 28.0, "outfield_rows": 12,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 3, "height": 40.0, "gap": 30.0, "model": &"set_foundry_block"}], [&"smokestacks", -32.0, {"span": -40.0, "count": 5}], [&"cranes", 22.0, {"span": 30.0, "count": 3}], [&"bridge", 38.0, {"distance": 140.0}], [&"smokestacks", 13.0, {"span": 6.0, "count": 2, "height": 38.0}, true], [&"water", 10.0, {"distance": 190.0, "width": 70.0}], [&"arcade", 50.0, {"style": &"kit", "height": 12.0, "banners": 0, "kit": &"foundry_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_foundry_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "height": 15.0, "span": 36.0, "banners": 0, "kit": &"foundry_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_foundry_tower", "towers": 3, "tower_height": 16.0}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("f0a830"), "layout": [[-42.0, &"gear", 1.0], [42.0, &"gear", 1.0]]}]],
		"sponsors": ["RIVET & SONS HARDWARE", "RUSTWATER FERRY", "SPROCKET DINER", "LUGNUT BREWS", "FORGE & ANVIL", "BOILERMAKERS UNION"],
		"skyline_color": Color("4a4040"), "window_color": Color("ffb35c"), "skyline_height": 0.6,
	},
	{
		"lights": {"mast": &"deco", "head": &"bank", "heads": 1, "lamp": Color("fff0cc"), "paint": Color(Color("2c5a3e"), 0.6)}, "id": &"ledger_street", "grandstand": {"roof": &"gable", "suites": &"arches", "surface": &"stone", "roof_color": Color("6f8c7c"), "set": &"bank"}, "mowing": "checker", "mowing_width": 9.0, "facade_color": Color("a0503c"), "facade_surface": &"brick", "structure_surface": &"stone", "decks": 2, "frame": &"model", "frame_model": &"set_bank_gate", "display_name": "Ledger Street Park",
		"blurb": "Bankers home · The Leviathan: a 37-foot green wall in short left, a deep triangle in right-center",
		"shape": [[-45, 102.4, 4.27], [-22.5, 112.6, 4.27], [0, 121.9, 4.27], [22.5, 110.5, 4.27], [45, 98.1, 4.27]], "air": 1.0,
		"seat_color": Color("1f4a33"), "seat_color_alt": Color("173828"), "structure_color": Color("8a4b3c"), "accent_color": Color("f2e6c8"),
		"outfield_wall_color": Color("1d4a33"), "wall_style": &"padded", "home_fan_share": 0.5, "away_fan_share": 0.3, "attendance": 0.95,
		"foul_rows": 22, "outfield_open": 30.0, "outfield_rows": 10,
		"pieces": [[&"terraces", 13.0, {"span": 30.0, "levels": [1.0], "rows": 4, "density": 0.95, "out": 0.5}, true], [&"hero", 30.0, {"model": &"domed_bank", "height": 58.0, "distance": 24.0, "turn": -38.0, "clear": 13.0}], [&"landmarks", -50.0, {"style": &"model", "rows": 3, "height": 40.0, "model": &"set_bank_block"}], [&"statue", 22.0, {}, true], [&"trees", 30.0, {"span": 25.0, "count": 5, "kind": &"round"}, true], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"water", 65.0, {"distance": 115.0, "width": 24.0}], [&"bunting", 50.0, {"span": 260.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"bank_set", "bay": 0.0, "towers": 5, "tower_height": 10.0, "height": 12.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_bank_tower"}, true], [&"arcade", 11.0, {"style": &"kit", "towers": 3, "tower_height": 12.0, "height": 14.0, "span": 36.0, "banners": 0, "kit": &"bank_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_bank_tower"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e2b23c"), "layout": [[-21.0, &"club", 1.1], [21.0, &"club", 1.1]]}], [&"lamps", -150.0, {"span": 300.0, "count": 40}], [&"planters", -46.0, {"span": 92.0, "flower": Color("ffffff"), "density": 1.6}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 8, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["PEMBERTON PEANUTS", "COBBLESTONE COFFEE", "LANTERN LAUNDRY", "IRONCLAD INSURANCE", "LEDGER STREET LAGER"],
		"skyline_color": Color("5a4a48"), "window_color": Color("ffe1a8"), "skyline_height": 0.8,
	},
	{
		"lights": {"mast": &"lattice", "head": &"bank", "heads": 2, "lamp": Color("fff6dc"), "paint": Color(Color("1f4a73"), 0.6)}, "id": &"pier_nine", "grandstand": {"roof": &"gable", "suites": &"glass", "surface": &"wood", "roof_color": Color("8a6a4a"), "set": &"pier"}, "mowing": "diagonal", "mowing_width": 7.0, "facade_color": Color("8a6a4a"), "facade_surface": &"wood", "structure_surface": &"stone", "decks": 2, "frame": &"model", "frame_model": &"set_pier_gate", "display_name": "Pier 9 Ballyard",
		"blurb": "Gulls home · short porch in right, the bay beyond it, deep left-center",
		"shape": [[-45, 102.4, 4.27], [-22.5, 114.9, 4.27], [0, 121.9, 4.27], [22.5, 112.9, 4.27], [45, 96.9, 4.27]], "air": 1.03,
		"seat_color": Color("1d3b5c"), "seat_color_alt": Color("152c45"), "structure_color": Color("c9c4b6"), "accent_color": Color("ff6b4a"),
		"outfield_wall_color": Color("17375e"), "wall_style": &"padded", "home_fan_share": 0.45, "away_fan_share": 0.35, "attendance": 0.88,
		"foul_rows": 24, "outfield_open": 28.0, "outfield_rows": 8,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 2, "height": 30.0, "gap": 30.0, "model": &"set_pier_block"}], [&"bay", 40.0], [&"lighthouse", 16.0], [&"bunting", 50.0, {"span": 260.0}], [&"sailboats", 8.0, {"span": 34.0, "count": 7}], [&"cranes", -30.0, {"count": 1}], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"water", 62.0, {"style": &"moat", "gap": 6.0, "width": 400.0, "span": 198.0}], [&"arcade", 50.0, {"style": &"kit", "height": 12.0, "banners": 0, "kit": &"pier_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_pier_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "height": 13.0, "span": 36.0, "banners": 0, "kit": &"pier_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_pier_tower", "towers": 3, "tower_height": 16.0}, true], [&"canopy", 52.0, {"style": &"timber"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("f2d27a"), "layout": [[-42.0, &"club", 1.0], [-21.0, &"waves", 1.1], [21.0, &"waves", 1.1], [42.0, &"club", 1.0]]}]],
		"sponsors": ["SALTWIND SAILS", "PIER 9 OYSTERS", "TIDECALLER TAXI", "BUOY BEVERAGES", "FOGHORN FRIES"],
		"skyline_color": Color("37465e"), "window_color": Color("ffe9b0"), "skyline_height": 0.9,
	},
	{
		"lights": {"mast": &"lattice", "head": &"bank", "heads": 2, "lamp": Color("ffd9a0"), "paint": Color(Color("b5622e"), 0.6)}, "standard": [&"centerpiece", &"slogan_board", &"light_towers"], "id": &"the_kiln", "grandstand": {"roof": &"barrel", "suites": &"arches", "surface": &"rock", "roof_color": Color("a0583a"), "set": &"kiln"}, "mowing": "rings", "mowing_width": 10.0, "grass_color": Color(0.22, 0.4, 0.14), "dirt_color": Color(0.66, 0.3, 0.17), "sky": &"golden", "facade_color": Color("b25a3c"), "facade_surface": &"rock", "structure_surface": &"stone", "ground_surface": &"sand", "ground_color": Color("8f4a2c"), "decks": 2, "frame": &"model", "frame_model": &"set_kiln_gate", "display_name": "The Kiln",
		"blurb": "Comets home · thin desert air carries the ball, so the outfield is a canyon; red mesas and a rocket beyond",
		"shape": [[-45, 102.1, 4.27], [-22.5, 114.8, 4.27], [0, 121.9, 4.27], [22.5, 113.1, 4.27], [45, 97.5, 4.27]], "air": 0.82,
		"seat_color": Color("a65a32"), "seat_color_alt": Color("8a4826"), "structure_color": Color("d9b98a"), "accent_color": Color("2ec4b6"),
		"outfield_wall_color": Color("2a2220"), "wall_style": &"padded", "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.8,
		"foul_rows": 24, "outfield_open": 30.0, "outfield_rows": 18,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 2, "height": 34.0, "gap": 40.0, "model": &"set_kiln_block"}], [&"mountains", -95.0, {"style": &"mesa", "span": 190.0, "count": 12, "distance": 320.0, "height": 85.0, "arch": true}], [&"rocket", 16.0, {"height": 70.0}], [&"smokestacks", 34.0, {"span": 16.0, "count": 2, "height": 40.0}], [&"trees", 20.0, {"span": 30.0, "count": 4, "kind": &"cactus"}, true], [&"arcade", 50.0, {"style": &"kit", "kit": &"kiln_set", "bay": 0.0, "height": 12.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_kiln_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "towers": 3, "tower_height": 8.0, "height": 6.0, "span": 36.0, "banners": 0, "kit": &"kiln_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_kiln_tower"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("f08a30"), "layout": [[-42.0, &"club", 1.0], [-21.0, &"mesa", 1.0, Color("c8551f")], [21.0, &"mesa", 1.0, Color("c8551f")], [42.0, &"club", 1.0]]}]],
		"sponsors": ["SUNBAKED SODA", "MESA MOTOR LODGE", "CACTUS CANDY CO.", "COPPER CANYON CHILI"],
		"skyline_color": Color("b08a62"), "window_color": Color("fff0c0"), "skyline_height": 0.35,
	},
	{
		"outfield_open": 30.0, "lights": {"mast": &"stone", "head": &"crown", "heads": 1, "lamp": Color("e0f4ff"), "head_size": 8.0, "tilt": 0.0}, "standard": [&"centerpiece", &"slogan_board", &"light_towers"], "id": &"the_icebox", "grandstand": {"roof": &"gable", "suites": &"screens", "surface": &"wood", "roof_color": Color("5c4434"), "set": &"alpine"}, "mowing": "stripes", "mowing_width": 6.0, "grass_color": Color(0.11, 0.33, 0.17), "dirt_color": Color(0.6, 0.45, 0.33), "facade_color": Color("8494a6"), "facade_surface": &"stone", "structure_surface": &"wood", "ground_surface": &"snow", "ground_color": Color("e4ebf2"), "decks": 2, "frame": &"model", "frame_model": &"set_alpine_gate", "display_name": "The Icebox",
		"blurb": "Yetis home · cold heavy air knocks fly balls down; ice falls and peaks beyond the wall",
		"shape": [[-45, 102.1, 4.27], [-22.5, 114.8, 4.27], [0, 121.9, 4.27], [22.5, 112.6, 4.27], [45, 96.0, 4.27]], "air": 1.1,
		"seat_color": Color("2d4a63"), "seat_color_alt": Color("223a4f"), "structure_color": Color("b8c4cc"), "accent_color": Color("9fe8ff"),
		"outfield_wall_color": Color("1f4f8f"), "wall_style": &"ice", "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.85,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 3, "height": 42.0, "model": &"set_alpine_block"}], [&"mountains", -125.0, {"span": 250.0, "count": 13, "height": 150.0, "distance": 540.0}], [&"trees", 10.0, {"span": 10.0, "count": 6, "kind": &"pine"}, true], [&"trees", 22.0, {"span": 45.0, "count": 10, "kind": &"pine"}, true], [&"gondola", -32.0, {"span": -40.0}], [&"icicles", -180.0], [&"arcade", 50.0, {"style": &"kit", "height": 12.0, "banners": 0, "kit": &"alpine_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_alpine_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"alpine_set", "bay": 0.0, "towers": 3, "tower_height": 9.0, "height": 14.0, "span": 36.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_alpine_tower"}, true], [&"canopy", 52.0, {"style": &"timber"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("ffffff"), "layout": [[-42.0, &"snowflake", 1.0], [-21.0, &"peaks", 1.0], [21.0, &"peaks", 1.0], [42.0, &"snowflake", 1.0]]}], [&"icicles", -60.0, {"span": 120.0}]],
		"sponsors": ["FROSTGATE FURNACES", "SNOWLINE SKIS", "YETI COCOA", "GLACIER GLASS", "NORTHWIND WOOLENS"],
		"skyline_color": Color("4a5866"), "window_color": Color("dff4ff"), "skyline_height": 0.4,
	},
	{
		"outfield_open": 26.0, "lights": {"mast": &"lattice", "head": &"halo", "heads": 1, "lamp": Color("a8ffbe"), "paint": Color(Color("2a3a30"), 0.6), "tilt": 8.0}, "id": &"reactor_park", "grandstand": {"roof": &"flat", "suites": &"glass", "surface": &"concrete", "roof_color": Color("8a8a80"), "set": &"reactor"}, "mowing": "diamond", "mowing_width": 7.0, "pillar_cap": &"emblem", "sky": &"dusk", "facade_color": Color("6a6e70"), "facade_surface": &"concrete", "structure_surface": &"steel", "decks": 3, "frame": &"model", "frame_model": &"set_reactor_gate", "display_name": "Reactor Park",
		"blurb": "Neutrons home · odd angles and a deep center-field notch behind a tall reactor wall",
		"shape": [[-45, 102.4, 4.27], [-22.5, 114.9, 4.27], [0, 121.9, 4.27], [22.5, 114.0, 4.27], [45, 100.0, 4.27]], "air": 1.0,
		"seat_color": Color("2a2e30"), "seat_color_alt": Color("202426"), "structure_color": Color("4b5154"), "accent_color": Color("39d353"),
		"outfield_wall_color": Color("1f2622"), "wall_style": &"neon", "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.82, "night": true,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 2, "height": 40.0, "gap": 40.0, "model": &"set_reactor_block"}], [&"smokestacks", -24.0, {"span": -30.0, "count": 2, "style": &"cooling", "height": 75.0, "tint": 0.6}], [&"smokestacks", 24.0, {"span": 30.0, "count": 2, "style": &"cooling", "height": 70.0, "tint": 0.6}], [&"smokestacks", 46.0, {"span": 14.0, "count": 2, "height": 45.0}], [&"pipes", -48.0, {"span": 96.0}], [&"water", 25.0, {"distance": 200.0, "width": 55.0}], [&"arcade", 50.0, {"style": &"kit", "height": 12.0, "banners": 0, "kit": &"reactor_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_reactor_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "height": 16.0, "span": 36.0, "banners": 0, "kit": &"reactor_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_reactor_tower", "towers": 3, "tower_height": 16.0}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"glow": 1.2, "numbers": Color("f4d23c"), "layout": [[-42.0, &"club", 1.0], [-21.0, &"zigzag", 1.1], [21.0, &"zigzag", 1.1], [42.0, &"club", 1.0]]}], [&"pipes", 12.0, {"span": 34.0, "runs": 3}, true]],
		"sponsors": ["ATOMIC FALLS POWER & LIGHT", "MUSHROOM CLOUD MALTS", "FISSION FIZZ", "RAY-GUN RADIO"],
		"skyline_color": Color("3d3f2e"), "window_color": Color("c8ffd8"), "skyline_height": 0.9,
	},
	{
		"lights": {"mast": &"deco", "head": &"crown", "heads": 2, "lamp": Color("ffc870"), "head_size": 8.0, "tilt": 0.0}, "id": &"the_horseshoe", "grandstand": {"roof": &"barrel", "suites": &"arches", "surface": &"steel", "roof_color": Color("3e4a44"), "set": &"lamp"}, "mowing": "checker", "mowing_width": 7.0, "sky": &"dusk", "facade_color": Color("9a7a5e"), "facade_surface": &"stone", "structure_surface": &"brick", "decks": 2, "frame": &"model", "frame_model": &"set_lamp_gate", "display_name": "The Horseshoe",
		"blurb": "Lamplighters home · night ball in a horseshoe: 279-foot lines, a 482-foot center field",
		"shape": [[-45, 102.7, 4.27], [-22.5, 115.0, 4.27], [0, 121.9, 4.27], [22.5, 113.5, 4.27], [45, 98.5, 4.27]], "air": 1.0,
		"seat_color": Color("16294a"), "seat_color_alt": Color("10203a"), "structure_color": Color("7a5a44"), "accent_color": Color("f0c04b"),
		"outfield_wall_color": Color("14254a"), "wall_style": &"padded", "home_fan_share": 0.45, "away_fan_share": 0.3, "attendance": 0.9,
		"foul_rows": 28, "outfield_rows": 20, "night": true,
		"pieces": [[&"terraces", 13.0, {"span": 40.0, "levels": [0.45, 1.0], "rows": 4, "density": 0.95}, true], [&"landmarks", -50.0, {"style": &"model", "rows": 3, "height": 48.0, "model": &"set_lamp_block"}], [&"viaduct", 14.0, {"span": 40.0, "height": 18.0}], [&"lamps", -150.0, {"span": 300.0, "count": 44}], [&"bunting", 50.0, {"span": 260.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"lamp_set", "bay": 0.0, "towers": 6, "tower_height": 7.0, "height": 12.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_lamp_tower"}, true], [&"arcade", 11.0, {"style": &"kit", "height": 17.0, "span": 36.0, "banners": 0, "kit": &"lamp_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_lamp_tower", "towers": 3, "tower_height": 16.0}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8c25a"), "layout": [[-42.0, &"lamp", 1.0], [-32.0, &"lamp", 1.0], [-21.0, &"club", 1.0], [21.0, &"club", 1.0], [32.0, &"lamp", 1.0], [42.0, &"lamp", 1.0]]}], [&"string_lights", -150.0, {"color": Color("ffd59a"), "every": 4.0}], [&"props", -150.0, {"model": &"lantern", "every": 5, "height": 7.5}]],
		"sponsors": ["OLD TOWNE TROLLEY", "HORSESHOE HAMS", "MIDNIGHT MATINEE", "NICKEL ARCADE", "LAMPLIGHTER LAGER"],
		"skyline_color": Color("1a1f33"), "window_color": Color("ffe0a0"), "skyline_height": 1.2,
	},
	{
		"lights": {"mast": &"lattice", "head": &"bank", "heads": 2, "lamp": Color("ffe2a8"), "paint": Color(Color("2a2624"), 0.6)}, "id": &"warehouse_row", "grandstand": {"roof": &"sawtooth", "suites": &"glass", "surface": &"brick", "roof_color": Color("7a4030"), "set": &"rail"}, "mowing": "stripes", "mowing_width": 10.0, "facade_color": Color("8a3e2e"), "facade_surface": &"brick", "structure_surface": &"steel", "decks": 2, "frame": &"model", "frame_model": &"set_rail_gate", "clock": true, "display_name": "Warehouse Row",
		"blurb": "Conductors home · a 25-foot brick wall in right and the old Roundhouse warehouse looming over it",
		"shape": [[-45, 94.5, 4.27], [-22.5, 115.9, 4.27], [0, 128.0, 4.27], [22.5, 119.0, 4.27], [45, 103.0, 4.27]], "air": 1.0,
		"seat_color": Color("8a2a2a"), "seat_color_alt": Color("6e2121"), "structure_color": Color("6e3a2c"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("1f3d4a"), "wall_style": &"padded", "home_fan_share": 0.5, "away_fan_share": 0.3, "attendance": 0.92,
		"foul_rows": 24, "outfield_open": 30.0, "outfield_rows": 12,
		"pieces": [[&"terraces", 13.0, {"span": 34.0, "levels": [1.0], "rows": 4, "density": 0.95}, true], [&"landmarks", -50.0, {"style": &"model", "rows": 3, "height": 40.0, "model": &"set_rail_block"}], [&"warehouse", 45.0], [&"warehouse", -45.0, {"text": "CARGO BUILDS CITIES", "length": 180.0}], [&"viaduct", 16.0, {"span": 34.0, "height": 20.0}], [&"cranes", 30.0, {"span": 20.0, "count": 2}], [&"smokestacks", 40.0, {"span": 8.0, "count": 1, "height": 35.0}], [&"bunting", 50.0, {"span": 260.0}], [&"water", 20.0, {"distance": 230.0, "width": 60.0}], [&"bridge", -15.0, {"distance": 180.0, "length": 200.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"rail_set", "bay": 0.0, "height": 12.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_rail_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "height": 15.0, "span": 36.0, "banners": 0, "kit": &"rail_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_rail_tower", "towers": 3, "tower_height": 16.0}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8b84a"), "layout": [[-42.0, &"club", 1.2], [-26.0, &"sign", 1.25, "IRONBRIDGE FREIGHT CO"], [-14.0, &"sign", 1.1, "RIVERTON RAILWAY", Color("4a8a96")], [9.0, &"clock", 1.25], [20.0, &"freight", 1.35], [31.0, &"sign", 1.25, "ALL ABOARD!", Color("e8c25a")], [42.0, &"crossed", 1.2]]}], [&"lamps", -150.0, {"span": 300.0, "count": 34}]],
		"sponsors": ["ROUNDHOUSE STORAGE CO.", "HARBORLIGHT CRAB SHACK", "BRASS RAIL BITTERS", "OLD LINE LOCKSMITHS", "CANAL STREET CANDY"],
		"skyline_color": Color("514848"), "window_color": Color("ffe1a8"), "skyline_height": 0.9,
	},
	{
		"lights": {"mast": &"stone", "head": &"crown", "heads": 1, "lamp": Color("fff2d8"), "head_size": 8.0, "tilt": 0.0}, "id": &"fountain_gardens", "grandstand": {"roof": &"sail", "suites": &"arches", "surface": &"marble", "roof_color": Color("f2f0ea"), "set": &"garden"}, "mowing": "rings", "mowing_width": 8.0, "grass_color": Color(0.15, 0.42, 0.15), "facade_color": Color("d6cfbb"), "facade_surface": &"marble", "structure_surface": &"stone", "decks": 2, "frame": &"model", "frame_model": &"set_garden_gate", "display_name": "Fountain Gardens",
		"blurb": "Swans home · big, symmetric and fair: garden terraces, fountains and blossoms beyond the wall",
		"shape": [[-45, 100.0, 4.27], [-22.5, 114.0, 4.27], [0, 121.9, 4.27], [22.5, 112.9, 4.27], [45, 96.9, 4.27]], "air": 1.0,
		"seat_color": Color("1d4a35"), "seat_color_alt": Color("163c2b"), "structure_color": Color("e8e2d0"), "accent_color": Color("d4af37"),
		"outfield_wall_color": Color("18432f"), "wall_style": &"padded", "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.8,
		"foul_rows": 24, "outfield_open": 32.0, "outfield_rows": 5,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 2, "height": 36.0, "gap": 60.0, "model": &"set_garden_block"}], [&"fountains", 14.0, {}, true], [&"trees", 9.0, {"span": 6.0, "count": 3, "kind": &"cypress"}, true], [&"trees", 22.0, {"span": 30.0, "count": 8, "kind": &"blossom"}, true], [&"trees", 4.0, {"span": 8.0, "count": 4, "kind": &"cypress"}, true], [&"statue", 27.0, {"figure": &"swan"}, true], [&"conservatory", 42.0], [&"flags", -50.0, {"span": 100.0, "count": 10}], [&"water", 0.0, {"style": &"moat", "gap": 20.0, "width": 16.0, "glow": 0.5}], [&"arcade", 50.0, {"style": &"kit", "kit": &"garden_set", "bay": 0.0, "height": 12.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_garden_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "height": 15.0, "span": 36.0, "banners": 0, "kit": &"garden_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_garden_tower", "towers": 3, "tower_height": 16.0}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8c25a"), "layout": [[-42.0, &"blossom", 1.0], [-27.0, &"club", 1.0], [-13.0, &"fountain", 1.0], [-7.0, &"blossom", 0.7], [7.0, &"blossom", 0.7], [13.0, &"fountain", 1.0], [27.0, &"club", 1.0], [42.0, &"blossom", 1.0]]}], [&"planters", -46.0, {"span": 92.0, "flower": Color("f3a7c4"), "density": 2.5}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 4, "height": 5.5, "place": &"terrace"}], [&"props", -46.0, {"model": &"column", "span": 92.0, "every": 6, "height": 9, "place": &"terrace", "tint": 0.6}]],
		"sponsors": ["CASCADE COLA", "SPRINKLE & SONS PLUMBING", "BLUE PLAINS BBQ", "MISTY MEADOW DAIRY", "JUBILEE JEWELERS"],
		"skyline_color": Color("26304a"), "window_color": Color("d8ecff"), "skyline_height": 0.6,
	},
	{
		"lights": {"mast": &"deco", "head": &"bank", "heads": 1, "lamp": Color("ffe6c8"), "paint": Color(Color("3a3f48"), 0.6)}, "id": &"the_vault", "grandstand": {"banners": true, "roof": &"flat", "suites": &"portholes", "surface": &"steel", "roof_color": Color("2a2e36"), "set": &"vault"}, "mowing": "diamond", "mowing_width": 9.0, "sky": &"night", "facade_color": Color("5a5e66"), "facade_surface": &"concrete", "structure_surface": &"steel", "decks": 3, "frame": &"model", "frame_model": &"set_vault_gate", "display_name": "The Vault",
		"blurb": "Safecrackers home · fast turf under searchlights: grounders scoot through the gaps, a giant vault door looms in left",
		"shape": [[-45, 94.5, 4.27], [-22.5, 115.9, 4.27], [0, 128.0, 4.27], [22.5, 119.2, 4.27], [45, 103.6, 4.27]], "air": 0.97, "surface": 1.3,
		"seat_color": Color("7a1a26"), "seat_color_alt": Color("5e141d"), "structure_color": Color("4a4f5a"), "accent_color": Color("ff2d2d"),
		"outfield_wall_color": Color("1c222b"), "wall_style": &"iron", "home_fan_share": 0.5, "away_fan_share": 0.25, "attendance": 0.7,
		"foul_rows": 26, "outfield_open": 30.0, "outfield_rows": 14, "turf": true, "night": true, "standard": [&"centerpiece", &"slogan_board", &"light_towers", &"skyline"],
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 3, "height": 48.0, "model": &"set_vault_block"}], [&"vault_door", -37.0], [&"slogan_board", -21.0, {"text": "Vaultborough Safecrackers", "height": 10.0}], [&"searchlights", -70.0, {"span": 140.0, "count": 7}], [&"viaduct", 18.0, {"span": 32.0, "height": 20.0}], [&"bridge", 40.0, {"distance": 120.0, "length": 160.0}], [&"bunting", 50.0, {"span": 260.0}], [&"arcade", 50.0, {"style": &"kit", "towers": 5, "tower_height": 9.0, "height": 12.0, "banners": 0, "kit": &"vault_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_vault_tower"}, true], [&"arcade", 11.0, {"style": &"kit", "height": 16.0, "span": 36.0, "banners": 0, "kit": &"vault_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_vault_tower", "towers": 3, "tower_height": 16.0}, true], [&"canopy", 52.0, {"style": &"steel"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8c25a"), "layout": [[-42.0, &"vault", 1.0], [-27.0, &"crossed", 0.7], [-7.0, &"banner_x", 1.0], [7.0, &"banner_x", 1.0], [27.0, &"crossed", 0.7], [42.0, &"club", 1.0]]}], [&"lamps", -150.0, {"span": 300.0, "count": 34}]],
		"sponsors": ["STRONGBOX SECURITY", "TITAN TURF", "DOMELIGHT DINER", "PRESSURE SEAL WINDOWS", "BIG TOP BURGERS"],
		"skyline_color": Color("1e2433"), "window_color": Color("ffd59a"), "skyline_height": 1.3,
	},
	{
		"lights": {"mast": &"stone", "head": &"crown", "heads": 1, "lamp": Color("ffb070"), "paint": Color(Color("8a2a20"), 0.6), "head_size": 8.0, "tilt": 0.0}, "id": &"sakura_gate", "grandstand": {"banners": true, "roof": &"pagoda", "suites": &"screens", "surface": &"wood", "roof_color": Color("3a2a2a"), "set": &"temple"}, "mowing": "diagonal", "mowing_width": 6.0, "grass_color": Color(0.16, 0.42, 0.13), "dirt_color": Color(0.6, 0.36, 0.24), "ground_color": Color(0.22, 0.28, 0.13), "pillar_cap": &"lamp", "sky": &"sunset", "facade_color": Color("7a2420"), "facade_surface": &"wood", "structure_surface": &"wood", "decks": 3, "frame": &"model", "frame_model": &"set_temple_gate", "display_name": "Sakura Gate Park",
		"blurb": "Kitsune home · a mountain shrine under cherry blossoms: torii gates, pagodas and a great fox spirit",
		"shape": [[-45, 96.9, 4.27], [-22.5, 112.9, 4.27], [0, 121.9, 4.27], [22.5, 117.3, 4.27], [45, 109.1, 4.27]], "air": 1.02,
		"seat_color": Color("8a1c2a"), "seat_color_alt": Color("6e1622"), "structure_color": Color("4a2c22"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("1c1214"), "wall_style": &"padded", "wall_stripe": Color("c8102e"), "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.9,
		"foul_rows": 24, "outfield_open": 32.0, "outfield_rows": 12, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"hero", -27.0, {"model": &"sakura_cliff", "height": 72.0, "distance": 22.0, "turn": 25.0, "clear": 14.0}], [&"landmarks", -50.0, {"style": &"model", "rows": 3, "height": 46.0, "model": &"set_temple_block"}], [&"mountains", -8.0, {"span": 16.0, "count": 1, "height": 210.0, "distance": 620.0}], [&"mountains", -70.0, {"span": 140.0, "count": 8, "height": 110.0, "distance": 560.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"temple_set", "bay": 0.0, "height": 12.0, "banners": 0, "towers": 5, "tower_height": 9.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_temple_tower"}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"temple_set", "bay": 0.0, "height": 12.0, "span": 36.0, "banners": 0, "towers": 2, "tower_height": 14.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_temple_tower"}, true], [&"torii", 24.0, {"height": 22.0, "distance": 30.0}], [&"torii", -26.0, {"height": 14.0, "distance": 4.0}], [&"statue", 31.0, {"figure": &"fox", "scale": 1.3}], [&"trees", 7.0, {"span": 8.0, "count": 4, "kind": &"blossom"}, true], [&"trees", 14.0, {"span": 40.0, "count": 12, "kind": &"blossom"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8c25a"), "layout": [[-42.0, &"blossom", 1.0], [-30.0, &"blossom", 1.0], [-22.0, &"blossom", 0.8], [-11.0, &"torii", 1.0], [11.0, &"blossom", 1.0], [21.0, &"blossom", 0.8], [30.0, &"blossom", 1.0], [42.0, &"blossom", 1.0]]}], [&"planters", -46.0, {"span": 92.0, "flower": Color("f7b6cf"), "green": Color("e8a3bf"), "density": 2.0}], [&"string_lights", -150.0, {"color": Color("ff9a5a"), "every": 5.0}], [&"props", -150.0, {"model": &"lantern", "every": 6, "height": 7.5}]],
		"sponsors": ["LANTERN TEA HOUSE", "PETAL RAMEN", "FOXFIRE FIREWORKS", "MOUNTAIN SPRING SODA"],
		"skyline_color": Color("3a2a3a"), "window_color": Color("ffc48a"),
	},
	{
		"lights": {"mast": &"deco", "head": &"halo", "heads": 1, "lamp": Color("b8f4ff"), "tilt": 8.0}, "id": &"deepwater", "grandstand": {"banners": true, "roof": &"barrel", "suites": &"portholes", "surface": &"stone", "roof_color": Color("2f6a6a"), "set": &"atlantis"}, "mowing": "rings", "mowing_width": 12.0, "grass_color": Color(0.1, 0.38, 0.2), "pillar_cap": &"emblem", "sky": &"underwater", "ground_color": Color("0e3b4a"), "facade_color": Color("6f8f8a"), "facade_surface": &"stone", "structure_surface": &"stone", "decks": 3, "frame": &"model", "frame_model": &"set_atlantis_gate", "frame_width": 112.0, "display_name": "Deepwater Park",
		"blurb": "Krakens home · a sunken ruin under the sea: glass tanks, aqueducts and the sea king",
		"shape": [[-45, 97.5, 4.27], [-22.5, 114.1, 4.27], [0, 123.4, 4.27], [22.5, 115.8, 4.27], [45, 102.1, 4.27]], "air": 1.06,
		"seat_color": Color("123f55"), "seat_color_alt": Color("0d3245"), "structure_color": Color("5f7f7f"), "accent_color": Color("2ebbbb"),
		"outfield_wall_color": Color("123c5c"), "wall_style": &"padded", "home_fan_share": 0.55, "away_fan_share": 0.25, "attendance": 0.85,
		"foul_rows": 26, "outfield_open": 32.0, "outfield_rows": 10, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "model": &"set_atlantis_block", "rows": 2, "height": 40.0, "center_gap": 16.0}], [&"water", 0.0, {"style": &"moat", "gap": 4.0, "width": 500.0, "glow": 0.3}], [&"arcade", 50.0, {"style": &"kit", "height": 14.0, "banners": 0, "towers": 5, "tower_height": 8.0, "kit": &"atlantis_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_atlantis_tower"}, true], [&"arcade", 11.0, {"style": &"kit", "height": 16.0, "span": 36.0, "banners": 0, "towers": 3, "tower_height": 10.0, "kit": &"atlantis_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_atlantis_tower"}, true], [&"aquarium", 14.0, {"span": 30.0, "height": 22.0, "fish": 40}, true], [&"statue", 24.0, {"figure": &"titan", "scale": 1.5}], [&"viaduct", -40.0, {"span": 26.0, "height": 22.0, "train": false}], [&"trees", 16.0, {"span": 30.0, "count": 10, "kind": &"coral"}, true], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("ffffff"), "layout": [[-42.0, &"coral", 1.0], [-22.0, &"fish", 0.9], [-10.0, &"coral", 0.8], [10.0, &"coral", 0.8], [22.0, &"fish", 0.9], [42.0, &"coral", 1.0]]}], [&"planters", -46.0, {"span": 92.0, "flower": Color("ff8a6a"), "green": Color("2a8a7a"), "density": 1.6}], [&"props", -46.0, {"model": &"column", "span": 92.0, "every": 7, "height": 10, "place": &"terrace", "tint": 0.6}]],
		"sponsors": ["ABYSS AQUARIUM", "KELP COLA", "DEEP DIVE GEAR", "PEARL DIVER BANK"],
		"skyline_color": Color("123a48"), "window_color": Color("9ff3ff"),
	},
	{
		"lights": {"mast": &"deco", "head": &"halo", "heads": 1, "lamp": Color("fff0c8"), "tilt": 8.0}, "standard": [&"centerpiece", &"slogan_board", &"light_towers"], "id": &"cloudreach", "grandstand": {"banners": true, "roof": &"sail", "suites": &"glass", "surface": &"steel", "roof_color": Color("f4f6fa"), "set": &"sky"}, "mowing": "sunburst", "mowing_width": 9.0, "pillar_cap": &"emblem", "ground_color": Color("eef2f8"), "ground_surface": &"snow", "facade_color": Color("b08a4e"), "facade_surface": &"steel", "structure_surface": &"steel", "decks": 3, "frame": &"model", "frame_model": &"set_sky_gate", "frame_width": 112.0, "display_name": "Cloudreach Stadium",
		"blurb": "Aviators home · a floating island high above the clouds: airships, skybridges and propeller towers",
		"shape": [[-45, 102.1, 4.27], [-22.5, 116.7, 4.27], [0, 125.0, 4.27], [22.5, 118.9, 4.27], [45, 108.2, 4.27]], "air": 0.9,
		"seat_color": Color("1f4f8f"), "seat_color_alt": Color("183f74"), "structure_color": Color("a8833e"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("173a6e"), "wall_style": &"padded", "home_fan_share": 0.55, "away_fan_share": 0.25, "attendance": 0.85,
		"foul_rows": 24, "outfield_open": 32.0, "outfield_rows": 10, "skyline_height": 0.8,
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "model": &"set_sky_block", "rows": 2, "height": 40.0, "center_gap": 16.0}], [&"islands", -180.0, {"span": 360.0, "count": 16}], [&"flying_craft", 0.0, {"style": &"blimp", "count": 6}], [&"arcade", 50.0, {"style": &"kit", "height": 12.0, "banners": 0, "towers": 5, "tower_height": 9.0, "kit": &"sky_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_sky_tower"}, true], [&"arcade", 11.0, {"style": &"kit", "height": 14.0, "span": 36.0, "banners": 0, "towers": 3, "tower_height": 14.0, "kit": &"sky_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_sky_tower"}, true], [&"bunting", 50.0, {"span": 260.0}], [&"lighthouse", -42.0], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8c25a"), "layout": [[-42.0, &"rocks", 1.0], [-24.0, &"rocks", 1.1], [-10.0, &"club", 0.8], [10.0, &"club", 0.8], [24.0, &"rocks", 1.1], [42.0, &"rocks", 1.0]]}], [&"planters", -46.0, {"span": 92.0, "flower": Color("ffd54a"), "density": 1.2}]],
		"sponsors": ["ZEPHYR AIRLINES", "PROPWASH PRETZELS", "CUMULUS COFFEE", "HIGH ALTITUDE HATS"],
		"skyline_color": Color("6c8fb8"), "window_color": Color("fff0c0"),
	},
	{
		"lights": {"mast": &"stone", "head": &"crown", "heads": 1, "lamp": Color("ffbe60"), "head_size": 8.0, "tilt": 0.0}, "id": &"forum_field", "grandstand": {"banners": true, "roof": &"gable", "suites": &"arches", "surface": &"marble", "roof_color": Color("b8865a"), "set": &"forum"}, "mowing": "diamond", "mowing_width": 10.0, "dirt_color": Color(0.7, 0.45, 0.28), "pillar_cap": &"brazier", "facade_color": Color("d6bf92"), "facade_surface": &"stone", "structure_surface": &"marble", "decks": 3, "frame": &"model", "frame_model": &"set_forum_gate", "frame_width": 112.0, "display_name": "Forum Field",
		"blurb": "Legion home · a sandstone colosseum: tiered arches, braziers, statues and red banners",
		"shape": [[-45, 101.2, 4.27], [-22.5, 114.5, 4.27], [0, 121.9, 4.27], [22.5, 112.9, 4.27], [45, 96.9, 4.27]], "air": 1.0,
		"seat_color": Color("8b1e1e"), "seat_color_alt": Color("701818"), "structure_color": Color("c9b48a"), "accent_color": Color("daa520"),
		"outfield_wall_color": Color("6e1a14"), "wall_style": &"stone", "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.95,
		"foul_rows": 27, "outfield_open": 30.0, "outfield_rows": 12, "skyline_height": 0.6,
		"pieces": [[&"terraces", 13.0, {"span": 36.0, "levels": [0.5, 1.0], "rows": 4, "density": 0.95}, true], [&"landmarks", -50.0, {"style": &"model", "rows": 2, "height": 36.0, "model": &"set_forum_block"}], [&"arcade", 50.0, {"style": &"kit", "kit": &"forum_set", "bay": 0.0, "height": 18.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_forum_tower", "towers": 3, "tower_height": 16.0}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"forum_set", "bay": 0.0, "height": 16.0, "span": 36.0, "banners": 0, "towers": 3, "tower_height": 8.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_forum_tower"}, true], [&"statue", 17.0, {"figure": &"knight"}, true], [&"trees", 7.0, {"span": 6.0, "count": 3, "kind": &"cypress"}, true], [&"trees", 30.0, {"span": 15.0, "count": 5, "kind": &"cypress"}, true], [&"lamps", -150.0, {"span": 300.0, "count": 34, "style": &"brazier"}], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("e8c25a"), "layout": [[-42.0, &"club", 1.0], [42.0, &"club", 1.0]]}], [&"planters", -46.0, {"span": 92.0, "flower": Color("c0392b"), "density": 1.4}], [&"props", -46.0, {"model": &"column", "span": 92.0, "every": 5, "height": 10, "place": &"terrace", "tint": 0.6}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 7, "height": 5.5, "place": &"terrace"}]],
		"sponsors": ["GLADIATOR GYROS", "AQUEDUCT WATER CO.", "LAUREL & SONS", "CHARIOT CAR WASH"],
		"skyline_color": Color("8a6a4a"), "window_color": Color("ffe1a8"),
	},
	{
		"lights": {"mast": &"stone", "head": &"crown", "heads": 1, "lamp": Color("ff9a48"), "paint": Color(Color("3a2a24"), 0.6), "head_size": 8.0, "tilt": 0.0}, "id": &"firelight", "grandstand": {"banners": true, "roof": &"battlement", "suites": &"arches", "surface": &"rock", "roof_color": Color("3a2c28"), "set": &"volcano"}, "mowing": "stripes", "mowing_width": 9.0, "grass_color": Color(0.14, 0.34, 0.11), "dirt_color": Color(0.42, 0.24, 0.17), "pillar_cap": &"brazier", "sky": &"sunset", "ground_color": Color("3a2a24"), "ground_surface": &"rock", "facade_color": Color("5a4038"), "facade_surface": &"rock", "structure_surface": &"stone", "decks": 3, "frame": &"model", "frame_model": &"set_volcano_gate", "frame_width": 160.0, "display_name": "Firelight Park",
		"blurb": "Vulcans home · an island fortress under a live volcano: lava-lit cliffs, aqueducts and the sea",
		"shape": [[-45, 100.6, 4.27], [-22.5, 117.2, 4.27], [0, 126.5, 4.27], [22.5, 120.7, 4.27], [45, 110.3, 4.27]], "air": 0.98,
		"seat_color": Color("7a2a1a"), "seat_color_alt": Color("5e2014"), "structure_color": Color("6a5a50"), "accent_color": Color("ff6a00"),
		"outfield_wall_color": Color("241a16"), "wall_style": &"rock", "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.9,
		"foul_rows": 25, "outfield_open": 32.0, "outfield_rows": 12, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"landmarks", -50.0, {"style": &"model", "rows": 2, "height": 40.0, "model": &"set_volcano_block"}], [&"mountains", -26.0, {"style": &"volcano", "height": 220.0, "distance": 560.0}], [&"water", 20.0, {"style": &"moat", "gap": 18.0, "width": 450.0, "span": 150.0}], [&"sailboats", 32.0, {"span": 40.0, "count": 6}], [&"lighthouse", 42.0], [&"arcade", 50.0, {"style": &"kit", "height": 12.0, "banners": 0, "towers": 5, "tower_height": 8.0, "kit": &"volcano_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_volcano_tower"}, true], [&"arcade", 11.0, {"style": &"kit", "height": 14.0, "span": 36.0, "banners": 0, "towers": 3, "tower_height": 12.0, "kit": &"volcano_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_volcano_tower"}, true], [&"lamps", -150.0, {"span": 300.0, "count": 34, "style": &"brazier"}], [&"wall_art", 0.0, {"glow": 1.2, "numbers": Color("f08a30"), "layout": [[-42.0, &"rocks", 1.0, Color("4a3a34")], [-23.0, &"volcano", 1.0], [11.0, &"volcano", 1.1], [29.0, &"volcano", 0.8], [42.0, &"rocks", 1.0, Color("4a3a34")]]}]],
		"sponsors": ["MAGMA HOT SAUCE", "OBSIDIAN OPTICS", "CALDERA COFFEE", "ASHFALL INSURANCE"],
		"skyline_color": Color("3a2a2a"), "window_color": Color("ffb35c"),
	},
	{
		"lights": {"mast": &"stone", "head": &"crown", "heads": 1, "lamp": Color("ffe2a8"), "head_size": 8.0, "tilt": 0.0}, "id": &"citadel_park", "grandstand": {"banners": true, "roof": &"battlement", "suites": &"arches", "surface": &"stone", "roof_color": Color("6a7480"), "set": &"gothic"}, "mowing": "checker", "mowing_width": 11.0, "pillar_cap": &"emblem", "facade_color": Color("8c8a8e"), "facade_surface": &"stone", "structure_surface": &"stone", "decks": 3, "frame": &"model", "frame_model": &"set_gothic_gate", "display_name": "Citadel Park",
		"blurb": "Sentinels home · a fortified citadel: battlements, knight guardians and a cathedral skyline",
		"shape": [[-45, 100.0, 4.27], [-22.5, 116.0, 4.27], [0, 125.0, 4.27], [22.5, 118.9, 4.27], [45, 108.2, 4.27]], "air": 1.02,
		"seat_color": Color("1f3a6f"), "seat_color_alt": Color("192f5a"), "structure_color": Color("6e6c72"), "accent_color": Color("d4af37"),
		"outfield_wall_color": Color("1b2a4f"), "wall_style": &"stone", "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.9,
		"foul_rows": 26, "outfield_open": 30.0, "outfield_rows": 12, "skyline_height": 0.7,
		"pieces": [[&"terraces", 13.0, {"span": 36.0, "levels": [1.0], "rows": 4, "density": 0.95}, true], [&"hero", 0.0, {"model": &"cathedral_spires", "height": 190.0, "distance": 170.0, "clear": 0.0}], [&"landmarks", -50.0, {"style": &"model", "model": &"set_gothic_block", "rows": 3, "height": 40.0, "center_gap": 18.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"gothic_set", "bay": 14.0, "height": 12.0, "banners": 0, "towers": 3, "tower_height": 16.0, "tower_model": &"set_gothic_tower", "tint": 0.0, "pavilion": 0}, true], [&"arcade", 11.0, {"style": &"kit", "kit": &"gothic_set", "bay": 16.0, "height": 14.0, "span": 36.0, "banners": 0, "towers": 2, "tower_height": 20.0, "tower_model": &"set_gothic_tower", "tint": 0.0, "pavilion": 0}, true], [&"statue", 15.0, {"figure": &"knight"}, true], [&"flags", -55.0, {"span": 110.0, "count": 16}], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("ffffff"), "layout": [[-42.0, &"shield", 0.9, Color("a61e2d")], [-32.0, &"shield", 0.9, Color("1f488f")], [-24.0, &"shield", 0.9, Color("a61e2d")], [-15.0, &"shield", 0.9, Color("1f488f")], [-7.0, &"shield", 0.9, Color("a61e2d")], [7.0, &"shield", 0.9, Color("1f488f")], [15.0, &"shield", 0.9, Color("a61e2d")], [24.0, &"shield", 0.9, Color("1f488f")], [32.0, &"shield", 0.9, Color("a61e2d")], [42.0, &"shield", 0.9, Color("1f488f")]]}]],
		"sponsors": ["RAMPART ROOFING", "SQUIRE SANDWICHES", "PORTCULLIS PARKING", "BASTION BANK"],
		"skyline_color": Color("4a4a58"), "window_color": Color("ffd59a"),
	},
	{
		"lights": {"mast": &"stone", "head": &"crown", "heads": 1, "lamp": Color("ffc878"), "paint": Color(Color("c4925a"), 0.6), "head_size": 8.0, "tilt": 0.0}, "id": &"amber_gate", "grandstand": {"banners": true, "roof": &"sail", "suites": &"arches", "surface": &"stone", "roof_color": Color("e6cfa0"), "set": &"desert"}, "mowing": "diamond", "mowing_width": 8.0, "grass_color": Color(0.24, 0.42, 0.15), "dirt_color": Color(0.72, 0.38, 0.2), "pillar_cap": &"brazier", "sky": &"golden", "ground_color": Color("c99a62"), "ground_surface": &"sand", "facade_color": Color("c4925a"), "facade_surface": &"stone", "structure_surface": &"stone", "decks": 3, "frame": &"model", "frame_model": &"set_desert_gate", "display_name": "Amber Gate Park",
		"blurb": "Scorpions home · a desert canyon city: scorpion statues, an oasis of palms and market terraces",
		"shape": [[-45, 93.9, 4.27], [-22.5, 116.7, 4.27], [0, 129.5, 4.27], [22.5, 121.5, 4.27], [45, 107.3, 4.27]], "air": 0.9,
		"seat_color": Color("8b1e2d"), "seat_color_alt": Color("701824"), "structure_color": Color("b88a58"), "accent_color": Color("d4a017"),
		"outfield_wall_color": Color("2c2a3a"), "wall_style": &"stone", "home_fan_share": 0.6, "away_fan_share": 0.2, "attendance": 0.88,
		"foul_rows": 25, "outfield_open": 32.0, "outfield_rows": 12, "standard": [&"centerpiece", &"slogan_board", &"light_towers"],
		"pieces": [[&"terraces", 13.0, {"span": 36.0, "levels": [0.5, 1.0], "rows": 4, "density": 0.95}, true], [&"landmarks", -50.0, {"style": &"model", "rows": 2, "height": 36.0, "model": &"set_desert_block"}], [&"mountains", -100.0, {"style": &"mesa", "span": 200.0, "count": 12, "height": 75.0, "distance": 340.0}], [&"arcade", 50.0, {"style": &"kit", "kit": &"desert_set", "bay": 0.0, "height": 12.0, "banners": 0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_desert_tower", "towers": 3, "tower_height": 16.0}, true], [&"canopy", 52.0, {"style": &"cloth"}, true], [&"arcade", 11.0, {"style": &"kit", "height": 13.0, "span": 36.0, "banners": 0, "towers": 3, "tower_height": 10.0, "kit": &"desert_set", "bay": 0.0, "tint": 0.0, "pavilion": 0, "tower_model": &"set_desert_tower"}, true], [&"statue", 9.0, {"figure": &"scorpion", "scale": 1.6}, true], [&"bunting", 50.0, {"span": 260.0, "club_colors": true}], [&"trees", 6.0, {"span": 6.0, "count": 3, "kind": &"palm"}, true], [&"trees", 22.0, {"span": 30.0, "count": 9, "kind": &"palm"}, true], [&"lamps", -150.0, {"span": 300.0, "count": 32, "style": &"brazier"}], [&"flags", -55.0, {"span": 110.0, "count": 14}], [&"wall_art", 0.0, {"glow": 0.0, "numbers": Color("f0e0b0"), "layout": [[-42.0, &"rocks", 1.0, Color("c99a62")], [-24.0, &"club", 1.0], [25.0, &"club", 1.0], [42.0, &"club", 1.0]]}], [&"planters", -46.0, {"span": 92.0, "flower": Color("e85d4a"), "density": 1.6}], [&"props", -46.0, {"model": &"urn", "span": 92.0, "every": 7, "height": 5.5, "place": &"terrace"}]],
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
			if kind == &"light_towers" and spec.has("lights"):
				params = spec["lights"]
			if kind == &"centerpiece" and spec.has("frame_model"):
				params["frame_model"] = spec["frame_model"]
			if kind == &"centerpiece" and spec.has("frame_width"):
				params["frame_width"] = spec["frame_width"]
			park.add_piece(kind, NAN, params)
		for p in spec.get("pieces", []):
			park.add_piece(p[0], p[1] if p.size() > 1 else NAN, p[2] if p.size() > 2 else {}, p[3] if p.size() > 3 else false)
		var problems := park.validate()
		if not problems.is_empty():
			push_error("%s: %s" % [park.id, ", ".join(problems)])
		for key in spec:
			if key in ["shape", "air", "surface", "pieces", "standard", "skyline_height", "frame", "clock", "crown", "pillar_cap", "frame_model", "frame_width", "lights"]:
				continue
			var value: Variant = spec[key]
			park.set(key, PackedStringArray(value) if key == "sponsors" else value)
		var path := "res://data/stadiums/%s.tres" % park.id
		print("%s -> %s (%s)" % [park.display_name, path, error_string(ResourceSaver.save(park, path))])
	quit()
