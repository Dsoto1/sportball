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
## Each club's identity: the six-color set (primary, secondary, accent,
## support, dark, highlight), slogan and emblem [shape, glyph]. Clubs with an
## owner reference sheet (docs/stadium_refs) use its colors exactly; the
## rest are drafts until theirs arrive. Sheets so far: Glitterati,
## Gearheads, Bankers, Gulls, Comets, Yetis, Neutrons, Lamplighters,
## Conductors, Swans, Safecrackers, and the seven 2026-10-22 clubs.
const IDENTITY := {
	&"glitterati": {"colors": ["4b2a7b", "d9a93a", "9b5cff", "a7a9b4", "141019", "f4f1fa"],
		"slogan": "Bigger Brighter Together", "emblem": [&"halo", "*"]},
	&"gearheads": {"colors": ["c6531a", "3e4347", "d4a017", "5b7ca8", "1b1b1b", "f1eee7"],
		"slogan": "Built Harder Together", "emblem": [&"gear", "G"]},
	&"bankers": {"colors": ["0b4d2e", "d4a017", "8b2e2e", "f4f1e6", "2b2b2b", "e9d58a"],
		"slogan": "Interest Compounds", "emblem": [&"laurel", "B"]},
	&"gulls": {"colors": ["0b4f8a", "30c6c1", "d64545", "f4f6f9", "1b2b44", "c1a878"],
		"slogan": "Ride the Tide", "emblem": [&"disc", "TG"]},
	&"comets": {"colors": ["d35400", "a8322b", "1ca3a3", "e6d0a8", "3b3b3b", "ffd166"],
		"slogan": "Blaze a Trail", "emblem": [&"star", ""]},
	&"yetis": {"colors": ["0b6fbf", "e3f4ff", "00b3c7", "a7b3c2", "0e2a4a", "b6fde0"],
		"slogan": "Cold Blooded", "emblem": [&"shield", "Y"]},
	&"neutrons": {"colors": ["39d353", "ffd733", "1b1b1b", "6b7c85", "3b3e43", "e6f7ff"],
		"slogan": "Critical Mass", "emblem": [&"atom", ""]},
	&"lamplighters": {"colors": ["0b2a4a", "f0c04b", "b61e2e", "f6e7c3", "3a3f47", "ffe7a3"],
		"slogan": "Light Up the Night", "emblem": [&"shield", "ML"]},
	&"conductors": {"colors": ["b2222b", "3b6ea5", "d4a017", "7a7d85", "1b1b1b", "e5e5e3"],
		"slogan": "All Aboard", "emblem": [&"gear", "IC"]},
	&"swans": {"colors": ["145a3b", "f4f1e8", "f3a7c4", "a7a7af", "0b2e1f", "d4af37"],
		"slogan": "Grace Under Pressure", "emblem": [&"laurel", "S"]},
	&"safecrackers": {"colors": ["2b2f3a", "0f2a44", "ff2d2d", "8b1e2d", "15171c", "c0c6cf"],
		"slogan": "Crack the Code", "emblem": [&"gear", "V"]},
	&"kitsune": {"colors": ["e8b6c9", "9b1c2f", "d4a017", "6b7177", "1a1a1a", "f8f6f1"],
		"slogan": "Nine Tails, One Spirit", "emblem": [&"blossom", ""]},
	&"krakens": {"colors": ["0b3d54", "2ebbbb", "e85d4a", "d4af37", "06202c", "f2faff"],
		"slogan": "Rule the Deep", "emblem": [&"trident", ""]},
	&"aviators": {"colors": ["3b7dd8", "d4a017", "b8442a", "6b7787", "0f2a4d", "f4efe6"],
		"slogan": "Above It All", "emblem": [&"wings", ""]},
	&"legion": {"colors": ["8b1e1e", "daa520", "dcc9a1", "8a7a66", "3a2f28", "f5f3e9"],
		"slogan": "Glory Stands", "emblem": [&"laurel", "SL"]},
	&"vulcans": {"colors": ["ff6a00", "1b1b1b", "c62828", "d7c3a1", "2a1d18", "ffd34d"],
		"slogan": "Forged in Fire", "emblem": [&"flame", ""]},
	&"sentinels": {"colors": ["2e2e38", "1f488f", "a61e2d", "d4af37", "11131a", "e6e2d9"],
		"slogan": "Hold the Line", "emblem": [&"shield", "IS"]},
	&"scorpions": {"colors": ["8b1e2d", "d4a017", "d9c49a", "7a4e2e", "1b1b1b", "fdf4e6"],
		"slogan": "Strike from the Sands", "emblem": [&"diamond", "CD"]},
}

const LEAGUE := [
	{"id": &"bankers", "city": "Brickhaven", "name": "Bankers", "abbr": "BHB", "park": &"ledger_street", "stadium": "Ledger Street Park",
	"mascot": "Ledger, a monocled piggy bank", "rival": &"conductors",
	"identity": "Old-money patience in the oldest park in the league. They work counts, take walks and line doubles off the Leviathan in left. Fans keep score in pencil and boo the wave.",
	"mods": {"eye": 12, "contact": 4, "power": 4, "speed": -8}, "staff": {"control": 6}, "lefty": 0.2, "pitches": "balanced",
	"nicknames": ["Interest", "Ledger", "Penny", "Vault", "Dividend", "Escrow", "Teller", "Mortgage", "Collateral", "Audit", "Coupon", "Pinstripe", "Gold Standard", "Compound", "Tax Man", "Fine Print", "Bottom Line"],
	"ai": {"swing_aggression": 0.85, "chase_scale": 0.7, "power_swing_rate": 0.38, "runner_aggression": -0.1, "edge_bias_scale": 1.1, "bullpen_hook": 0.6, "steal_rate": 0.6, "bunt_rate": 0.4}},
	{"id": &"gulls", "city": "Tidewater", "name": "Gulls", "abbr": "TWG", "park": &"pier_nine", "stadium": "Pier 9 Ballyard",
	"mascot": "Squawk, a gull in a sailor cap", "rival": &"swans",
	"identity": "Harbor sluggers built for the short porch. Left-handed pull power aimed at the bay, where kayakers fight over every splash home run. Loud, salty and streaky.",
	"mods": {"power": 10, "contact": -4, "eye": -2}, "staff": {"velocity": 2}, "lefty": 0.7, "pitches": "balanced",
	"nicknames": ["Splash", "Barnacle", "Riptide", "Anchor", "Squall", "Undertow", "Bilge", "Scuttlebutt", "Low Tide", "Harpoon", "Driftwood", "Foghorn", "Breakwater", "Galley", "Starboard", "Mainsail", "Lighthouse"],
	"ai": {"swing_aggression": 1.05, "chase_scale": 1.1, "power_swing_rate": 0.44, "runner_aggression": 0.0, "edge_bias_scale": 1.0, "bullpen_hook": 0.6, "steal_rate": 0.6, "bunt_rate": 0.3}},
	{"id": &"comets", "city": "Copper Mesa", "name": "Comets", "abbr": "CMC", "park": &"the_kiln", "stadium": "The Kiln",
	"mascot": "Blaze, a comet in mirrored sunglasses", "rival": &"yetis",
	"identity": "Desert speedsters in a canyon of an outfield. They turn gappers into triples, run on everything and track down fly balls nobody else could reach. The thin air does the rest.",
	"mods": {"speed": 14, "power": -6, "glove": 6, "contact": 2}, "staff": {"stuff": 2}, "lefty": 0.4, "pitches": "balanced",
	"nicknames": ["Tumbleweed", "Mirage", "Sidewinder", "Cactus", "Heatwave", "Dust Storm", "Meteor", "Roadrunner", "Sundial", "Canyon", "Scorcher", "Coyote", "Stardust", "Prospector", "Buckshot", "Tailwind", "Afterburn"],
	"ai": {"swing_aggression": 1.0, "chase_scale": 0.95, "power_swing_rate": 0.32, "runner_aggression": 0.35, "edge_bias_scale": 1.0, "bullpen_hook": 0.6, "steal_rate": 2.2, "bunt_rate": 0.6}},
	{"id": &"yetis", "city": "Frostgate", "name": "Yetis", "abbr": "FGY", "park": &"the_icebox", "stadium": "The Icebox",
	"mascot": "Mitts, a shaggy yeti in earmuffs", "rival": &"comets",
	"identity": "Cold-weather grinders. Contact hitters who foul off everything, sinkerballers who live on ground balls, and gloves that never drop a thing. In the heavy air of the Icebox, nothing comes easy.",
	"mods": {"contact": 10, "power": -5, "glove": 8, "eye": 4}, "staff": {"control": 10, "velocity": -2, "stuff": 2}, "lefty": 0.35, "pitches": "sinkers",
	"nicknames": ["Snowplow", "Frostbite", "Icicle", "Avalanche", "Tundra", "Blizzard", "Mitten", "Sleet", "Permafrost", "Hailstorm", "Igloo", "Whiteout", "Polar", "Snowdrift", "Glacier", "Cold Snap", "Deep Freeze"],
	"ai": {"swing_aggression": 0.9, "chase_scale": 0.8, "power_swing_rate": 0.28, "runner_aggression": 0.0, "edge_bias_scale": 1.15, "bullpen_hook": 0.55, "steal_rate": 1.0, "bunt_rate": 1.0}},
	{"id": &"neutrons", "city": "Atomic Falls", "name": "Neutrons", "abbr": "AFN", "park": &"reactor_park", "stadium": "Reactor Park",
	"mascot": "Glowy, a friendly glowing atom", "rival": &"lamplighters",
	"identity": "All-or-nothing power plant. Every swing is a meltdown, every pitcher throws gas, and nobody bothers to bunt. They strike out a ton and hit the scoreboard more than anyone.",
	"mods": {"power": 14, "contact": -10, "eye": -6, "speed": -4}, "staff": {"velocity": 12, "control": -8}, "lefty": 0.4, "pitches": "heat",
	"nicknames": ["Meltdown", "Fission", "Gamma", "Half-Life", "Isotope", "Reactor", "Fallout", "Uranium", "Critical Mass", "Particle", "Chain Reaction", "Megaton", "Geiger", "Plutonium", "Supernova", "Cyclotron", "Mushroom Cloud"],
	"ai": {"swing_aggression": 1.15, "chase_scale": 1.3, "power_swing_rate": 0.52, "runner_aggression": -0.2, "edge_bias_scale": 0.85, "bullpen_hook": 0.7, "steal_rate": 0.4, "bunt_rate": 0.15}},
	{"id": &"lamplighters", "city": "Midtown", "name": "Lamplighters", "abbr": "MTL", "park": &"the_horseshoe", "stadium": "The Horseshoe",
	"mascot": "Wick, a gas lamp in a top hat", "rival": &"neutrons",
	"identity": "Night owls of the Horseshoe. They pull everything down the 279-foot lines, run down the endless center field and win late. Old-time ball under the lights, with a brass band.",
	"mods": {"power": 2, "contact": 0, "speed": 2}, "staff": {"stuff": 3, "velocity": -5}, "lefty": 0.5, "pitches": "crafty",
	"nicknames": ["Gaslight", "Wick", "Nightcap", "Lantern", "Moonbeam", "Streetlight", "Midnight", "Sparkler", "Neon", "Owl", "Curtain Call", "Matinee", "Flicker", "Torch", "Ember", "Last Call", "Encore Bell"],
	"ai": {"swing_aggression": 1.0, "chase_scale": 1.0, "power_swing_rate": 0.4, "runner_aggression": 0.1, "edge_bias_scale": 1.0, "bullpen_hook": 0.65, "steal_rate": 1.0, "bunt_rate": 0.5}},
	{"id": &"conductors", "city": "Ironbridge", "name": "Conductors", "abbr": "IBC", "park": &"warehouse_row", "stadium": "Warehouse Row",
	"mascot": "Chug, a little steam engine", "rival": &"bankers",
	"identity": "Railyard line-drive machine, always on schedule. Left-handed hitters spray liners off the brick wall in right; nobody chases and nobody panics. Train whistles after every double.",
	"mods": {"contact": 8, "eye": 2, "power": 0}, "staff": {"control": 6, "velocity": 4, "stuff": 2}, "lefty": 0.65, "pitches": "balanced",
	"nicknames": ["Caboose", "Whistle", "Boxcar", "Switchman", "Express", "Freight", "Signal", "Coal Car", "Turntable", "Brakeman", "Timetable", "Locomotive", "Sleeper", "Junction", "Semaphore", "Steam", "Full Throttle"],
	"ai": {"swing_aggression": 0.95, "chase_scale": 0.8, "power_swing_rate": 0.34, "runner_aggression": 0.05, "edge_bias_scale": 1.05, "bullpen_hook": 0.6, "steal_rate": 1.0, "bunt_rate": 0.6}},
	{"id": &"swans", "city": "Cascade City", "name": "Swans", "abbr": "CCS", "park": &"fountain_gardens", "stadium": "Fountain Gardens",
	"mascot": "Duchess, an elegant swan in a tiara", "rival": &"gulls",
	"identity": "Graceful pitching and defense in the most beautiful park in the league. Deep staff, slick gloves, strong arms, and just enough offense. Every win feels like a ballet.",
	"mods": {"glove": 10, "arm": 6, "contact": 0, "power": -2}, "staff": {"velocity": 6, "control": 8, "stuff": 8}, "lefty": 0.45, "pitches": "balanced",
	"nicknames": ["Ballet", "Cascade", "Feather", "Grace", "Lily Pad", "Pirouette", "Silk", "Swan Song", "Duchess", "Reflection", "Waltz", "Ripple", "Plume", "Serenade", "Fountain", "Elegance", "Curtsy"],
	"ai": {"swing_aggression": 0.95, "chase_scale": 0.9, "power_swing_rate": 0.33, "runner_aggression": 0.05, "edge_bias_scale": 1.1, "bullpen_hook": 0.5, "steal_rate": 1.1, "bunt_rate": 0.8}},
	{"id": &"safecrackers", "city": "Vaultborough", "name": "Safecrackers", "abbr": "VBS", "park": &"the_vault", "stadium": "The Vault",
	"mascot": "Tumbler, a masked safecracker with a stethoscope", "rival": &"bankers",
	"identity": "Turf burglars. Slap the ball into the carpet, run before anyone blinks, steal every base that isn't bolted down. In the Vault, grounders scoot through and so do they.",
	"mods": {"speed": 14, "contact": 4, "power": -14}, "staff": {"stuff": 2}, "lefty": 0.55, "pitches": "crafty",
	"nicknames": ["Lockpick", "Getaway", "Tumbler", "Combination", "Heist", "Alibi", "Ski Mask", "Stethoscope", "Crowbar", "Loot", "Fast Hands", "Jackpot", "Inside Job", "Smoke Bomb", "Safehouse", "Midnight Run", "Clean Getaway"],
	"ai": {"swing_aggression": 1.0, "chase_scale": 0.9, "power_swing_rate": 0.25, "runner_aggression": 0.4, "edge_bias_scale": 1.0, "bullpen_hook": 0.6, "steal_rate": 3.0, "bunt_rate": 1.0}},
	{"id": &"kitsune", "city": "Silver Blossom", "name": "Kitsune", "abbr": "SBK", "park": &"sakura_gate", "stadium": "Sakura Gate Park",
	"mascot": "Kiko, a nine-tailed fox spirit with a paper lantern", "rival": &"swans",
	"identity": "Tricksters of the mountain shrine. Slap hitters who never strike out, foxes on the bases, and a staff of illusionists whose changeups vanish. They win by a thousand small cuts.",
	"mods": {"contact": 10, "speed": 8, "power": -10, "eye": 4}, "staff": {"stuff": 8, "velocity": -4, "control": 4}, "lefty": 0.55, "pitches": "crafty",
	"nicknames": ["Foxfire", "Lantern", "Petal", "Torii", "Moonlit", "Nine Tails", "Shrine", "Spirit", "Wisp", "Origami", "Sakura", "Trickster", "Mist", "Paper Crane", "Koi", "Bamboo", "Illusion"],
	"ai": {"swing_aggression": 0.95, "chase_scale": 0.75, "power_swing_rate": 0.22, "runner_aggression": 0.3, "edge_bias_scale": 1.15, "bullpen_hook": 0.55, "steal_rate": 2.0, "bunt_rate": 1.4}},
	{"id": &"krakens", "city": "Tidal Reign", "name": "Krakens", "abbr": "TRK", "park": &"deepwater", "stadium": "Deepwater Park",
	"mascot": "Inky, a grinning kraken in a captain's hat", "rival": &"gulls",
	"identity": "Pressure from the deep. Cannon arms in every corner, a bullpen of flamethrowers and hitters who drag the ball to the gaps. Nothing gets out of Deepwater alive.",
	"mods": {"arm": 12, "power": 4, "glove": 4, "contact": -2, "speed": -4}, "staff": {"velocity": 8, "stuff": 2, "control": -2}, "lefty": 0.4, "pitches": "heat",
	"nicknames": ["Tentacle", "Riptide", "Abyss", "Ink", "Leviathan", "Trench", "Undertow", "Coral", "Barnacle", "Sonar", "Depth Charge", "Maelstrom", "Siren", "Anchor", "Whirlpool", "Pressure", "Kraken"],
	"ai": {"swing_aggression": 1.05, "chase_scale": 1.05, "power_swing_rate": 0.42, "runner_aggression": -0.05, "edge_bias_scale": 0.95, "bullpen_hook": 0.65, "steal_rate": 0.7, "bunt_rate": 0.4}},
	{"id": &"aviators", "city": "Skyward", "name": "Aviators", "abbr": "SKA", "park": &"cloudreach", "stadium": "Cloudreach Stadium",
	"mascot": "Captain Gale, a goggled pilot with a propeller cap", "rival": &"neutrons",
	"identity": "High-flying fly-ball club above the clouds. They launch everything into the jet stream and run down every gap in the outfield. Strikeouts happen; so do moonshots.",
	"mods": {"power": 8, "speed": 6, "eye": -6, "contact": -2}, "staff": {"velocity": 4, "stuff": 2}, "lefty": 0.45, "pitches": "balanced",
	"nicknames": ["Tailwind", "Barnstormer", "Propwash", "Cirrus", "Loop", "Updraft", "Jet Stream", "Goggles", "Zeppelin", "Ace", "Contrail", "Altitude", "Wingtip", "Skybridge", "Nosedive", "Thunderhead", "Moonshot"],
	"ai": {"swing_aggression": 1.1, "chase_scale": 1.15, "power_swing_rate": 0.48, "runner_aggression": 0.2, "edge_bias_scale": 1.0, "bullpen_hook": 0.6, "steal_rate": 1.3, "bunt_rate": 0.3}},
	{"id": &"legion", "city": "Sandstone", "name": "Legion", "abbr": "SDL", "park": &"forum_field", "stadium": "Forum Field",
	"mascot": "Maximus, a bronze-helmeted centurion", "rival": &"sentinels",
	"identity": "Disciplined ranks of the colosseum. They take pitches, march runners station to station and defend like a shield wall. Sinkers, ground balls and glory.",
	"mods": {"eye": 10, "glove": 6, "contact": 4, "speed": -6}, "staff": {"control": 8, "stuff": 2}, "lefty": 0.35, "pitches": "sinkers",
	"nicknames": ["Centurion", "Gladius", "Phalanx", "Laurel", "Chariot", "Aqueduct", "Spartan", "Tribune", "Colossus", "Arena", "Ironclad", "Senator", "Forum", "Shield Wall", "Javelin", "Triumph", "Imperator"],
	"ai": {"swing_aggression": 0.85, "chase_scale": 0.7, "power_swing_rate": 0.34, "runner_aggression": -0.1, "edge_bias_scale": 1.1, "bullpen_hook": 0.55, "steal_rate": 0.7, "bunt_rate": 0.9}},
	{"id": &"vulcans", "city": "Emberpeak", "name": "Vulcans", "abbr": "EPV", "park": &"firelight", "stadium": "Firelight Park",
	"mascot": "Cinder, a little lava golem with a hot temper", "rival": &"yetis",
	"identity": "Volcanic island sluggers. Molten bats, short tempers and a staff that throws pure fire. They erupt in big innings and cool off just as fast.",
	"mods": {"power": 12, "contact": -4, "eye": -4, "speed": 0}, "staff": {"velocity": 10, "control": -6, "stuff": 4}, "lefty": 0.4, "pitches": "heat",
	"nicknames": ["Magma", "Eruption", "Cinder", "Obsidian", "Lava Flow", "Ash Cloud", "Pyro", "Brimstone", "Scorch", "Ember", "Caldera", "Firestorm", "Basalt", "Molten", "Hotfoot", "Kindling", "Inferno"],
	"ai": {"swing_aggression": 1.12, "chase_scale": 1.2, "power_swing_rate": 0.5, "runner_aggression": 0.05, "edge_bias_scale": 0.9, "bullpen_hook": 0.65, "steal_rate": 0.7, "bunt_rate": 0.2}},
	{"id": &"sentinels", "city": "Ironspire", "name": "Sentinels", "abbr": "ISS", "park": &"citadel_park", "stadium": "Citadel Park",
	"mascot": "Sir Bastion, a knight in oversized armor", "rival": &"legion",
	"identity": "The fortress. Gold-glove gloves, cannon arms and a staff that paints corners like a cathedral fresco. They don't score much; they don't need to.",
	"mods": {"glove": 12, "arm": 8, "contact": 2, "power": -6}, "staff": {"control": 8, "stuff": 6, "velocity": 2}, "lefty": 0.4, "pitches": "balanced",
	"nicknames": ["Bastion", "Rampart", "Portcullis", "Keep", "Squire", "Halberd", "Gauntlet", "Watchtower", "Moat", "Banner", "Paladin", "Battlement", "Drawbridge", "Crusader", "Gargoyle", "Siege", "Ironclad"],
	"ai": {"swing_aggression": 0.95, "chase_scale": 0.85, "power_swing_rate": 0.3, "runner_aggression": -0.05, "edge_bias_scale": 1.15, "bullpen_hook": 0.5, "steal_rate": 0.8, "bunt_rate": 0.9}},
	{"id": &"scorpions", "city": "Crimson Dunes", "name": "Scorpions", "abbr": "CDS", "park": &"amber_gate", "stadium": "Amber Gate Park",
	"mascot": "Sting, a scorpion in a fez", "rival": &"comets",
	"identity": "Desert ambush artists. Patient at the plate, venomous with two strikes, and quick to sting on the bases. Their crafty staff lives on breaking balls that bite late.",
	"mods": {"contact": 6, "speed": 8, "power": -2, "eye": 2}, "staff": {"stuff": 8, "control": 2, "velocity": -2}, "lefty": 0.5, "pitches": "crafty",
	"nicknames": ["Stinger", "Mirage", "Oasis", "Sandstorm", "Venom", "Dune", "Caravan", "Pincer", "Sirocco", "Scimitar", "Nomad", "Bazaar", "Sunburn", "Viper", "Quicksand", "Desert Rose", "Last Sting"],
	"ai": {"swing_aggression": 0.95, "chase_scale": 0.85, "power_swing_rate": 0.32, "runner_aggression": 0.25, "edge_bias_scale": 1.05, "bullpen_hook": 0.6, "steal_rate": 1.8, "bunt_rate": 1.0}},
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
		var look: Dictionary = IDENTITY[t["id"]]
		var palette: Array = look["colors"]
		team.primary_color = Color(palette[0])
		team.secondary_color = Color(palette[1])
		team.accent_color = Color(palette[2])
		team.support_color = Color(palette[3])
		team.dark_color = Color(palette[4])
		team.highlight_color = Color(palette[5])
		team.slogan = look["slogan"]
		team.emblem_shape = look["emblem"][0]
		team.emblem_glyph = look["emblem"][1]
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
