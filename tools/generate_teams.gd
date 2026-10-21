extends SceneTree
## Writes the team resources in res://data/teams from the tables below.
##   godot --headless --path . -s res://tools/generate_teams.gd
## Edit the tables, rerun, and commit both this file and the .tres output.
## Run tools/generate_parks.gd first (home parks are linked by id).

# Hitters: id, name, nickname, number, bats, throws, positions,
#          contact, power, eye, speed, arm, glove
# Pitchers: id, name, nickname, number, throws, velocity, control, stuff, stamina, pitches
const TEAMS := [
	{
		"id": &"gearheads", "city": "Rustwater", "name": "Gearheads", "abbr": "RWG",
		"colors": [Color("c4561f"), Color("1d2a4a"), Color("efe3c8")],
		"mascot": "Sprocket, a patched-up wind-up robot",
		"stadium": "Foundry Field",
		"identity": "Scrappy river-port underdogs. Small ball: steals, bunts, hustle doubles, strong gloves and not much power. Blue-collar grit: fans bang wrenches on the metal bleachers.",
		"rival": &"glitterati",
		"hitters": [
			[&"rwg_calloway", "Wren Calloway", "Spark", 2, &"L", &"R", [&"cf", &"lf"], 74, 35, 68, 88, 60, 80],
			[&"rwg_brightwater", "Tomas Brightwater", "Socket", 6, &"R", &"R", [&"ss", &"2b"], 70, 40, 60, 78, 72, 84],
			[&"rwg_paskett", "Junie Paskett", "Lugnut", 4, &"L", &"R", [&"2b", &"ss"], 76, 38, 70, 72, 58, 76],
			[&"rwg_mahoney", "Oz Mahoney", "Anvil", 33, &"R", &"R", [&"1b"], 64, 72, 55, 38, 55, 62],
			[&"rwg_inkwell", "Rosa Inkwell", "Rivet", 15, &"R", &"R", [&"3b", &"1b"], 68, 55, 58, 55, 74, 70],
			[&"rwg_corrigan", "Hank Corrigan", "Smokestack", 21, &"L", &"L", [&"1b", &"lf"], 62, 62, 52, 40, 50, 48],
			[&"rwg_varga", "Pip Varga", "Pistons", 9, &"R", &"R", [&"lf", &"rf"], 67, 45, 55, 80, 62, 70],
			[&"rwg_mott", "Della Mott", "Ratchet", 12, &"L", &"L", [&"rf", &"cf"], 66, 48, 60, 74, 78, 72],
			[&"rwg_ferrow", "Gus Ferrow", "Boiler", 8, &"R", &"R", [&"c"], 59, 44, 50, 35, 70, 66],
			[&"rwg_strand", "Milo Strand", "Shift Whistle", 18, &"L", &"R", [&"lf", &"cf", &"rf"], 64, 35, 58, 84, 55, 66],
			[&"rwg_kettle", "Ivy Kettle", "Teakettle", 3, &"R", &"R", [&"2b", &"3b", &"ss"], 69, 32, 64, 70, 60, 74],
			[&"rwg_holloway", "Bram Holloway", "Bellows", 27, &"R", &"R", [&"c", &"1b"], 54, 52, 46, 30, 64, 58],
		],
		"pitchers": [
			[&"rwg_hollerith", "Otis Hollerith", "The Foreman", 41, &"R", 54, 80, 62, 80, [&"sinker", &"changeup", &"curveball", &"junkball"]],
			[&"rwg_bracket", "Nell Bracket", "Shim", 50, &"L", 50, 66, 64, 40, [&"fastball", &"slider", &"changeup"]],
			[&"rwg_wexley", "Cobb Wexley", "Grease Fire", 36, &"R", 58, 58, 52, 38, [&"sinker", &"slider", &"splitter"]],
			[&"rwg_sprock", "Juno Sprock", "Torque", 47, &"R", 52, 70, 58, 42, [&"cutter", &"curveball", &"changeup"]],
			[&"rwg_fenwick", "Mack Fenwick", "Overtime", 99, &"R", 62, 68, 66, 30, [&"fastball", &"cutter", &"splitter"]],
		],
		"order": [&"rwg_calloway", &"rwg_brightwater", &"rwg_paskett", &"rwg_mahoney", &"rwg_inkwell", &"rwg_corrigan", &"rwg_varga", &"rwg_mott", &"rwg_ferrow"],
		"lineup_positions": [&"cf", &"ss", &"2b", &"1b", &"3b", &"dh", &"lf", &"rf", &"c"],
		"park": &"foundry_field",
		"ai": {"swing_aggression": 0.95, "chase_scale": 0.75, "power_swing_rate": 0.36, "runner_aggression": 0.2, "edge_bias_scale": 1.1, "bullpen_hook": 0.55, "steal_rate": 2.5, "bunt_rate": 0.7},
	},
	{
		"id": &"glitterati", "city": "Neon Heights", "name": "Glitterati", "abbr": "NHG",
		"colors": [Color("4b2a7b"), Color("d9a93a"), Color("f4f1fa")],
		"mascot": "Monsieur Marquee, a top-hatted spotlight",
		"stadium": "The Halo Dome",
		"identity": "Glamorous sky-city darlings everyone loves to hate. Power, home runs and bat flips, bought with big contracts. Celebrity showboating: fireworks on every homer and a red-carpet entrance. Their lineup is a running vaudeville act: Who plays first, What is on second, I Don't Know is on third, Why in left, Because in center, Tomorrow pitches and Today catches. Nobody has ever named the right fielder.",
		"rival": &"gearheads",
		"hitters": [
			[&"nhg_i_dont_care", "I Don't Care", "Velvet", 1, &"R", &"R", [&"ss", &"2b"], 64, 55, 58, 76, 70, 66],
			[&"nhg_because", "Because", "Flashbulb", 7, &"L", &"L", [&"cf", &"rf"], 60, 58, 50, 85, 64, 62],
			[&"nhg_who", "Who", "The Marquee", 44, &"L", &"L", [&"1b"], 56, 84, 60, 36, 50, 52],
			[&"nhg_vandermeer", "Roxy Vandermeer", "Encore", 24, &"R", &"R", [&"rf", &"lf"], 58, 80, 52, 55, 76, 58],
			[&"nhg_lux", "Bruno Lux", "Penthouse", 55, &"R", &"R", [&"1b"], 50, 90, 45, 30, 45, 40],
			[&"nhg_i_dont_know", "I Don't Know", "Paparazzi", 13, &"R", &"R", [&"3b"], 54, 70, 48, 48, 72, 60],
			[&"nhg_why", "Why", "Silver Screen", 17, &"L", &"L", [&"lf", &"cf"], 58, 66, 55, 60, 58, 56],
			[&"nhg_what", "What", "Sequins", 11, &"R", &"R", [&"2b", &"ss"], 62, 52, 56, 68, 60, 64],
			[&"nhg_today", "Today", "Red Carpet", 5, &"R", &"R", [&"c"], 48, 64, 44, 32, 68, 58],
			[&"nhg_sato", "Remy Sato", "Spotlight", 30, &"L", &"R", [&"lf", &"rf", &"cf"], 56, 62, 52, 66, 60, 56],
			[&"nhg_belmonte", "Coco Belmonte", "Champagne", 22, &"R", &"R", [&"3b", &"2b", &"ss"], 55, 58, 50, 58, 64, 60],
			[&"nhg_halloran", "Fritz Halloran", "Velvet Rope", 29, &"R", &"R", [&"c", &"1b"], 46, 66, 42, 28, 62, 52],
		],
		"pitchers": [
			[&"nhg_tomorrow", "Tomorrow", "Headliner", 19, &"R", 72, 50, 66, 70, [&"fastball", &"slider", &"splitter", &"showstopper"]],
			[&"nhg_crisp", "Monty Crisp", "Cue Card", 38, &"L", 64, 54, 66, 40, [&"fastball", &"curveball", &"changeup"]],
			[&"nhg_kahn", "Desiree Kahn", "Standing Ovation", 45, &"R", 70, 48, 60, 38, [&"fastball", &"slider", &"changeup"]],
			[&"nhg_platinum", "Ziggy Platinum", "Glam Slam", 64, &"L", 68, 50, 72, 36, [&"sinker", &"slider", &"curveball"]],
			[&"nhg_gloss", "Maximilian Gloss", "The Finale", 0, &"R", 82, 56, 64, 28, [&"fastball", &"splitter"]],
		],
		"order": [&"nhg_i_dont_care", &"nhg_because", &"nhg_who", &"nhg_vandermeer", &"nhg_lux", &"nhg_i_dont_know", &"nhg_why", &"nhg_what", &"nhg_today"],
		"lineup_positions": [&"ss", &"cf", &"1b", &"rf", &"dh", &"3b", &"lf", &"2b", &"c"],
		"park": &"halo_dome",
		"ai": {"swing_aggression": 1.1, "chase_scale": 1.3, "power_swing_rate": 0.43, "runner_aggression": -0.1, "edge_bias_scale": 0.9, "bullpen_hook": 0.8, "steal_rate": 0.5, "bunt_rate": 0.25},
	},
]


# The rest of the league: one club per park. Rosters are built from a
# lineup template, shifted by the club's style ("mods"), with a steady
# per-player variation, original names and themed nicknames (_build).
# Hitter slots: position(s), contact, power, eye, speed, arm, glove.
const LINEUP_TEMPLATE := [
	[[&"cf", &"lf"], 68, 42, 62, 80, 62, 72],
	[[&"ss", &"2b"], 66, 45, 60, 72, 70, 76],
	[[&"rf", &"lf"], 64, 66, 58, 56, 72, 62],
	[[&"1b"], 60, 78, 56, 36, 52, 54],
	[[&"3b", &"1b"], 60, 64, 54, 48, 70, 64],
	[[&"1b", &"lf"], 58, 68, 52, 40, 50, 45],
	[[&"lf", &"rf"], 62, 52, 54, 62, 60, 60],
	[[&"2b", &"ss"], 64, 42, 58, 66, 60, 70],
	[[&"c"], 54, 46, 50, 34, 68, 62],
	[[&"2b", &"3b", &"ss"], 62, 38, 56, 62, 60, 66],
	[[&"lf", &"cf", &"rf"], 60, 42, 54, 72, 60, 64],
	[[&"c", &"1b"], 50, 48, 46, 30, 64, 58],
]
const LINEUP_SLOTS := [&"cf", &"ss", &"rf", &"1b", &"3b", &"dh", &"lf", &"2b", &"c"]
# Pitcher slots: velocity, control, stuff, stamina (starter, then bullpen,
# the closer last).
const STAFF_TEMPLATE := [[60, 64, 62, 75], [58, 60, 60, 40], [56, 62, 58, 38], [60, 58, 64, 36], [68, 60, 64, 28]]
const NUMBERS := [1, 3, 8, 25, 10, 31, 16, 4, 26, 14, 20, 23, 34, 42, 48, 52, 61]
const FIRST_NAMES := ["Abe", "Ada", "Alder", "Ansel", "Bea", "Benny", "Birdie", "Boone", "Cal", "Cass", "Cleo", "Clem", "Dash", "Dot", "Ellis", "Elsie", "Emmett", "Etta", "Felix", "Flo", "Gil", "Greta", "Harlan", "Hattie", "Iggy", "Inez", "Jasper", "Jo", "Kip", "Kit", "Lenny", "Lottie", "Lyle", "Mabel", "Marlo", "Merritt", "Mina", "Nate", "Nell", "Odie", "Opal", "Orrin", "Pearl", "Percy", "Quill", "Rafe", "Remi", "Rhea", "Rollo", "Ruby", "Sal", "Sully", "Tad", "Tess", "Theo", "Tilly", "Vern", "Vida", "Walt", "Wanda", "Wes", "Winnie", "Yates", "Zeke", "Zora", "Ozzie", "Fern", "Rudy", "Juno", "Mack"]
const LAST_NAMES := ["Abernathy", "Ashgrove", "Ballantine", "Barlow", "Beckwith", "Blackwood", "Bramble", "Carraway", "Chandler", "Cobblestone", "Crumley", "Delacroix", "Dunmore", "Eastwick", "Ellery", "Fairbanks", "Farrow", "Fennimore", "Fitzwater", "Gallagher", "Goodnight", "Granger", "Hadley", "Halfpenny", "Hargrove", "Huckabee", "Ingram", "Jessup", "Kettering", "Kinsley", "Langtry", "Larkspur", "Lockwood", "Loveless", "Mallory", "Marchetti", "McAllister", "Merriweather", "Moonlight", "Mulberry", "Nightingale", "Northcott", "Oakes", "Ormsby", "Pemberton", "Pettibone", "Quimby", "Radcliffe", "Ravenswood", "Redfern", "Ridley", "Rockwell", "Rosewood", "Saltonstall", "Sayers", "Shackleford", "Sinclair", "Springfield", "Stillwater", "Strickland", "Sutter", "Tamberlane", "Thistlewood", "Tolliver", "Treadwell", "Underhill", "Valentine", "Vanderpool", "Wainwright", "Waverly", "Westbrook", "Whitlock", "Wickersham", "Wildfire", "Winterbottom", "Woodruff", "Yardley", "Zimmerly", "Achterberg", "Bonaventure", "Castellanos", "Duquesne", "Esposito", "Fontaine", "Guzmán", "Hashimoto", "Iwamoto", "Jaramillo", "Kowalczyk", "Lindqvist", "Moreau", "Nakagawa", "Okonkwo", "Petrakis", "Quintero", "Rasmussen", "Szabo", "Takahashi", "Uchenna", "Villanueva", "Wójcik", "Yilmaz", "Zapata", "Oyelaran", "Brannigan", "Delgado", "Haverford", "Montclair"]
const REPERTOIRES := {
	"balanced": [[&"fastball", &"slider", &"changeup", &"curveball"], [&"fastball", &"slider", &"changeup"], [&"sinker", &"curveball", &"changeup"], [&"cutter", &"slider", &"splitter"], [&"fastball", &"splitter"]],
	"sinkers": [[&"sinker", &"changeup", &"slider", &"curveball"], [&"sinker", &"slider", &"changeup"], [&"sinker", &"cutter", &"curveball"], [&"sinker", &"splitter", &"slider"], [&"sinker", &"cutter"]],
	"heat": [[&"fastball", &"slider", &"splitter", &"curveball"], [&"fastball", &"slider"], [&"fastball", &"cutter", &"splitter"], [&"fastball", &"curveball", &"slider"], [&"fastball", &"splitter"]],
	"crafty": [[&"changeup", &"curveball", &"sinker", &"junkball"], [&"cutter", &"changeup", &"curveball"], [&"sinker", &"curveball", &"changeup"], [&"slider", &"changeup", &"junkball"], [&"cutter", &"curveball", &"splitter"]],
}
const LEAGUE := [
	{"id": &"bankers", "city": "Brickhaven", "name": "Bankers", "abbr": "BHB", "park": &"ledger_street", "stadium": "Ledger Street Park",
	"colors": [Color("1f6b45"), Color("f2e6c8"), Color("8a4b3c")], "mascot": "Ledger, a monocled piggy bank", "rival": &"conductors",
	"identity": "Old-money patience in the oldest park in the league. They work counts, take walks and line doubles off the Leviathan in left. Fans keep score in pencil and boo the wave.",
	"mods": {"eye": 12, "contact": 4, "power": 4, "speed": -8}, "staff": {"control": 6}, "lefty": 0.2, "pitches": "balanced",
	"nicknames": ["Interest", "Ledger", "Penny", "Vault", "Dividend", "Escrow", "Teller", "Mortgage", "Collateral", "Audit", "Coupon", "Pinstripe", "Gold Standard", "Compound", "Tax Man", "Fine Print", "Bottom Line"],
	"ai": {"swing_aggression": 0.85, "chase_scale": 0.7, "power_swing_rate": 0.38, "runner_aggression": -0.1, "edge_bias_scale": 1.1, "bullpen_hook": 0.6, "steal_rate": 0.6, "bunt_rate": 0.4}},
	{"id": &"gulls", "city": "Tidewater", "name": "Gulls", "abbr": "TWG", "park": &"pier_nine", "stadium": "Pier 9 Ballyard",
	"colors": [Color("1d3b6c"), Color("ff6b4a"), Color("f4f4f0")], "mascot": "Squawk, a gull in a sailor cap", "rival": &"swans",
	"identity": "Harbor sluggers built for the short porch. Left-handed pull power aimed at the bay, where kayakers fight over every splash home run. Loud, salty and streaky.",
	"mods": {"power": 10, "contact": -4, "eye": -2}, "staff": {"velocity": 2}, "lefty": 0.7, "pitches": "balanced",
	"nicknames": ["Splash", "Barnacle", "Riptide", "Anchor", "Squall", "Undertow", "Bilge", "Scuttlebutt", "Low Tide", "Harpoon", "Driftwood", "Foghorn", "Breakwater", "Galley", "Starboard", "Mainsail", "Lighthouse"],
	"ai": {"swing_aggression": 1.05, "chase_scale": 1.1, "power_swing_rate": 0.44, "runner_aggression": 0.0, "edge_bias_scale": 1.0, "bullpen_hook": 0.6, "steal_rate": 0.6, "bunt_rate": 0.3}},
	{"id": &"comets", "city": "Copper Mesa", "name": "Comets", "abbr": "CMC", "park": &"the_kiln", "stadium": "The Kiln",
	"colors": [Color("1fa596"), Color("b8662f"), Color("f1e2c4")], "mascot": "Blaze, a comet in mirrored sunglasses", "rival": &"yetis",
	"identity": "Desert speedsters in a canyon of an outfield. They turn gappers into triples, run on everything and track down fly balls nobody else could reach. The thin air does the rest.",
	"mods": {"speed": 14, "power": -6, "glove": 6, "contact": 2}, "staff": {"stuff": 2}, "lefty": 0.4, "pitches": "balanced",
	"nicknames": ["Tumbleweed", "Mirage", "Sidewinder", "Cactus", "Heatwave", "Dust Storm", "Meteor", "Roadrunner", "Sundial", "Canyon", "Scorcher", "Coyote", "Stardust", "Prospector", "Buckshot", "Tailwind", "Afterburn"],
	"ai": {"swing_aggression": 1.0, "chase_scale": 0.95, "power_swing_rate": 0.32, "runner_aggression": 0.35, "edge_bias_scale": 1.0, "bullpen_hook": 0.6, "steal_rate": 2.2, "bunt_rate": 0.6}},
	{"id": &"yetis", "city": "Frostgate", "name": "Yetis", "abbr": "FGY", "park": &"the_icebox", "stadium": "The Icebox",
	"colors": [Color("3a6e9e"), Color("f4f8fb"), Color("9fe8ff")], "mascot": "Mitts, a shaggy yeti in earmuffs", "rival": &"comets",
	"identity": "Cold-weather grinders. Contact hitters who foul off everything, sinkerballers who live on ground balls, and gloves that never drop a thing. In the heavy air of the Icebox, nothing comes easy.",
	"mods": {"contact": 10, "power": -5, "glove": 8, "eye": 4}, "staff": {"control": 10, "velocity": -2, "stuff": 2}, "lefty": 0.35, "pitches": "sinkers",
	"nicknames": ["Snowplow", "Frostbite", "Icicle", "Avalanche", "Tundra", "Blizzard", "Mitten", "Sleet", "Permafrost", "Hailstorm", "Igloo", "Whiteout", "Polar", "Snowdrift", "Glacier", "Cold Snap", "Deep Freeze"],
	"ai": {"swing_aggression": 0.9, "chase_scale": 0.8, "power_swing_rate": 0.28, "runner_aggression": 0.0, "edge_bias_scale": 1.15, "bullpen_hook": 0.55, "steal_rate": 1.0, "bunt_rate": 1.0}},
	{"id": &"neutrons", "city": "Atomic Falls", "name": "Neutrons", "abbr": "AFN", "park": &"reactor_park", "stadium": "Reactor Park",
	"colors": [Color("262626"), Color("7dffb0"), Color("e3c94f")], "mascot": "Glowy, a friendly glowing atom", "rival": &"lamplighters",
	"identity": "All-or-nothing power plant. Every swing is a meltdown, every pitcher throws gas, and nobody bothers to bunt. They strike out a ton and hit the scoreboard more than anyone.",
	"mods": {"power": 14, "contact": -10, "eye": -6, "speed": -4}, "staff": {"velocity": 12, "control": -8}, "lefty": 0.4, "pitches": "heat",
	"nicknames": ["Meltdown", "Fission", "Gamma", "Half-Life", "Isotope", "Reactor", "Fallout", "Uranium", "Critical Mass", "Particle", "Chain Reaction", "Megaton", "Geiger", "Plutonium", "Supernova", "Cyclotron", "Mushroom Cloud"],
	"ai": {"swing_aggression": 1.15, "chase_scale": 1.3, "power_swing_rate": 0.52, "runner_aggression": -0.2, "edge_bias_scale": 0.85, "bullpen_hook": 0.7, "steal_rate": 0.4, "bunt_rate": 0.15}},
	{"id": &"lamplighters", "city": "Midtown", "name": "Lamplighters", "abbr": "MTL", "park": &"the_horseshoe", "stadium": "The Horseshoe",
	"colors": [Color("7a1f3d"), Color("ff4f7b"), Color("f2ead8")], "mascot": "Wick, a gas lamp in a top hat", "rival": &"neutrons",
	"identity": "Night owls of the Horseshoe. They pull everything down the 279-foot lines, run down the endless center field and win late. Old-time ball under the lights, with a brass band.",
	"mods": {"power": 2, "contact": 0, "speed": 2}, "staff": {"stuff": 3, "velocity": -5}, "lefty": 0.5, "pitches": "crafty",
	"nicknames": ["Gaslight", "Wick", "Nightcap", "Lantern", "Moonbeam", "Streetlight", "Midnight", "Sparkler", "Neon", "Owl", "Curtain Call", "Matinee", "Flicker", "Torch", "Ember", "Last Call", "Encore Bell"],
	"ai": {"swing_aggression": 1.0, "chase_scale": 1.0, "power_swing_rate": 0.4, "runner_aggression": 0.1, "edge_bias_scale": 1.0, "bullpen_hook": 0.65, "steal_rate": 1.0, "bunt_rate": 0.5}},
	{"id": &"conductors", "city": "Ironbridge", "name": "Conductors", "abbr": "IBC", "park": &"warehouse_row", "stadium": "Warehouse Row",
	"colors": [Color("d79a1e"), Color("1f4f34"), Color("1c1c1c")], "mascot": "Chug, a little steam engine", "rival": &"bankers",
	"identity": "Railyard line-drive machine, always on schedule. Left-handed hitters spray liners off the brick wall in right; nobody chases and nobody panics. Train whistles after every double.",
	"mods": {"contact": 8, "eye": 2, "power": 0}, "staff": {"control": 6, "velocity": 4, "stuff": 2}, "lefty": 0.65, "pitches": "balanced",
	"nicknames": ["Caboose", "Whistle", "Boxcar", "Switchman", "Express", "Freight", "Signal", "Coal Car", "Turntable", "Brakeman", "Timetable", "Locomotive", "Sleeper", "Junction", "Semaphore", "Steam", "Full Throttle"],
	"ai": {"swing_aggression": 0.95, "chase_scale": 0.8, "power_swing_rate": 0.34, "runner_aggression": 0.05, "edge_bias_scale": 1.05, "bullpen_hook": 0.6, "steal_rate": 1.0, "bunt_rate": 0.6}},
	{"id": &"swans", "city": "Cascade City", "name": "Swans", "abbr": "CCS", "park": &"fountain_gardens", "stadium": "Fountain Gardens",
	"colors": [Color("1e4fb0"), Color("f7f7fa"), Color("6fd6ff")], "mascot": "Duchess, an elegant swan in a tiara", "rival": &"gulls",
	"identity": "Graceful pitching and defense in the most beautiful park in the league. Deep staff, slick gloves, strong arms, and just enough offense. Every win feels like a ballet.",
	"mods": {"glove": 10, "arm": 6, "contact": 0, "power": -2}, "staff": {"velocity": 6, "control": 8, "stuff": 8}, "lefty": 0.45, "pitches": "balanced",
	"nicknames": ["Ballet", "Cascade", "Feather", "Grace", "Lily Pad", "Pirouette", "Silk", "Swan Song", "Duchess", "Reflection", "Waltz", "Ripple", "Plume", "Serenade", "Fountain", "Elegance", "Curtsy"],
	"ai": {"swing_aggression": 0.95, "chase_scale": 0.9, "power_swing_rate": 0.33, "runner_aggression": 0.05, "edge_bias_scale": 1.1, "bullpen_hook": 0.5, "steal_rate": 1.1, "bunt_rate": 0.8}},
	{"id": &"safecrackers", "city": "Vaultborough", "name": "Safecrackers", "abbr": "VBS", "park": &"the_vault", "stadium": "The Vault",
	"colors": [Color("5a6272"), Color("ff5ad0"), Color("151518")], "mascot": "Tumbler, a masked safecracker with a stethoscope", "rival": &"bankers",
	"identity": "Turf burglars. Slap the ball into the carpet, run before anyone blinks, steal every base that isn't bolted down. In the Vault, grounders scoot through and so do they.",
	"mods": {"speed": 14, "contact": 4, "power": -14}, "staff": {"stuff": 2}, "lefty": 0.55, "pitches": "crafty",
	"nicknames": ["Lockpick", "Getaway", "Tumbler", "Combination", "Heist", "Alibi", "Ski Mask", "Stethoscope", "Crowbar", "Loot", "Fast Hands", "Jackpot", "Inside Job", "Smoke Bomb", "Safehouse", "Midnight Run", "Clean Getaway"],
	"ai": {"swing_aggression": 1.0, "chase_scale": 0.9, "power_swing_rate": 0.25, "runner_aggression": 0.4, "edge_bias_scale": 1.0, "bullpen_hook": 0.6, "steal_rate": 3.0, "bunt_rate": 1.0}},
]


## A league club's full spec (hitters, pitchers, order) from its LEAGUE row.
static func _build(spec: Dictionary, team_index: int) -> Dictionary:
	var t := spec.duplicate()
	var mods: Dictionary = spec["mods"]
	var staff_mods: Dictionary = spec["staff"]
	var nicks: Array = spec["nicknames"]
	var abbr := String(spec["abbr"]).to_lower()
	var hitters := []
	var keys := ["contact", "power", "eye", "speed", "arm", "glove"]
	for i in LINEUP_TEMPLATE.size():
		var slot: Array = LINEUP_TEMPLATE[i]
		var name := _name(team_index, i)
		var id := StringName("%s_%s" % [abbr, name.get_slice(" ", 1).to_lower().replace("ó", "o").replace("á", "a")])
		var r := []
		for k in keys.size():
			var v := int(slot[k + 1]) + int(mods.get(keys[k], 0)) + _wobble(id, keys[k])
			r.append(clampi(v, 20, 95))
		var positions: Array = slot[0]
		var infield_only := positions.has(&"ss") or positions.has(&"2b") or positions.has(&"3b") or positions.has(&"c")
		var bats := &"L" if _roll(id, "bats") < float(spec["lefty"]) else &"R"
		var throws := &"L" if bats == &"L" and not infield_only and _roll(id, "throws") < 0.6 else &"R"
		hitters.append([id, name, nicks[i], NUMBERS[i], bats, throws, positions, r[0], r[1], r[2], r[3], r[4], r[5]])
	var pitchers := []
	var rep: Array = REPERTOIRES[spec["pitches"]]
	for j in STAFF_TEMPLATE.size():
		var slot: Array = STAFF_TEMPLATE[j]
		var name := _name(team_index, LINEUP_TEMPLATE.size() + j)
		var id := StringName("%s_%s" % [abbr, name.get_slice(" ", 1).to_lower().replace("ó", "o").replace("á", "a")])
		var vel := clampi(int(slot[0]) + int(staff_mods.get("velocity", 0)) + _wobble(id, "vel"), 25, 95)
		var ctl := clampi(int(slot[1]) + int(staff_mods.get("control", 0)) + _wobble(id, "ctl"), 25, 95)
		var stf := clampi(int(slot[2]) + int(staff_mods.get("stuff", 0)) + _wobble(id, "stf"), 25, 95)
		var throws := &"L" if _roll(id, "throws") < 0.3 else &"R"
		pitchers.append([id, name, nicks[LINEUP_TEMPLATE.size() + j], NUMBERS[LINEUP_TEMPLATE.size() + j], throws, vel, ctl, stf, slot[3], rep[j]])
	t["hitters"] = hitters
	t["pitchers"] = pitchers
	var order := []
	for i in LINEUP_SLOTS.size():
		order.append(hitters[i][0])
	t["order"] = order
	t["lineup_positions"] = LINEUP_SLOTS
	return t


## An original name, steady per club and slot; never repeated on a club.
static func _name(team_index: int, slot: int) -> String:
	var n := team_index * 17 + slot
	var first: String = FIRST_NAMES[(n * 37 + 11) % FIRST_NAMES.size()]
	var last: String = LAST_NAMES[(n * 53 + 7) % LAST_NAMES.size()]
	return "%s %s" % [first, last]


## A steady -5..5 rating nudge for a player and a trait.
static func _wobble(id: StringName, what: String) -> int:
	return absi(hash(String(id) + what)) % 11 - 5


static func _roll(id: StringName, what: String) -> float:
	return float(absi(hash(String(id) + "/" + what)) % 1000) / 1000.0


func _init() -> void:
	var all := TEAMS.duplicate()
	for i in LEAGUE.size():
		all.append(_build(LEAGUE[i], i))
	for t in all:
		var team := TeamDef.new()
		team.id = t["id"]
		team.city = t["city"]
		team.team_name = t["name"]
		team.abbreviation = t["abbr"]
		team.primary_color = t["colors"][0]
		team.secondary_color = t["colors"][1]
		team.accent_color = t["colors"][2]
		team.mascot = t["mascot"]
		team.stadium = t["stadium"]
		team.identity = t["identity"]
		team.rival = t["rival"]
		for h in t["hitters"]:
			var p := PlayerDef.new()
			p.id = h[0]; p.display_name = h[1]; p.nickname = h[2]; p.number = h[3]
			p.bats = h[4]; p.throws = h[5]
			p.positions.assign(h[6])
			p.contact = h[7]; p.power = h[8]; p.eye = h[9]; p.speed = h[10]; p.arm = h[11]; p.glove = h[12]
			team.roster.append(p)
		for q in t["pitchers"]:
			var p := PlayerDef.new()
			p.id = q[0]; p.display_name = q[1]; p.nickname = q[2]; p.number = q[3]
			p.throws = q[4]; p.bats = q[4]
			p.positions.assign([&"p"])
			p.velocity = q[5]; p.control = q[6]; p.stuff = q[7]; p.stamina = q[8]
			p.pitches.assign(q[9])
			p.contact = 20; p.power = 15; p.eye = 20; p.speed = 40; p.arm = 70; p.glove = 50
			team.roster.append(p)
		team.batting_order.assign(t["order"])
		team.lineup_positions.assign(t["lineup_positions"])
		team.starting_pitcher = t["pitchers"][0][0]
		for i in range(1, t["pitchers"].size()):
			team.bullpen.append(t["pitchers"][i][0])
		for key in t["ai"]:
			team.set(key, t["ai"][key])
		if t.has("park"):
			# Parks come from tools/generate_parks.gd.
			team.stadium_def = load("res://data/stadiums/%s.tres" % t["park"])
		var path := "res://data/teams/%s.tres" % team.id
		var err := ResourceSaver.save(team, path)
		print("%s -> %s (%s)" % [team.full_name(), path, error_string(err)])
	var rules := MatchRules.new()
	print("rules -> ", error_string(ResourceSaver.save(rules, "res://data/rules/arcade.tres")))
	quit()
