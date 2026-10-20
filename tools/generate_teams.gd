extends SceneTree
## Writes the team resources in res://data/teams from the tables below.
##   godot --headless --path . -s res://tools/generate_teams.gd
## Edit the tables, rerun, and commit both this file and the .tres output.

# Hitters: id, name, nickname, number, bats, throws, positions,
#          contact, power, eye, speed, arm, glove
# Pitchers: id, name, nickname, number, throws, velocity, control, stuff, stamina
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
			[&"rwg_hollerith", "Otis Hollerith", "The Foreman", 41, &"R", 54, 80, 62, 80],
			[&"rwg_bracket", "Nell Bracket", "Shim", 50, &"L", 50, 66, 64, 40],
			[&"rwg_wexley", "Cobb Wexley", "Grease Fire", 36, &"R", 58, 58, 52, 38],
			[&"rwg_sprock", "Juno Sprock", "Torque", 47, &"R", 52, 70, 58, 42],
			[&"rwg_fenwick", "Mack Fenwick", "Overtime", 99, &"R", 62, 68, 66, 30],
		],
		"order": [&"rwg_calloway", &"rwg_brightwater", &"rwg_paskett", &"rwg_mahoney", &"rwg_inkwell", &"rwg_corrigan", &"rwg_varga", &"rwg_mott", &"rwg_ferrow"],
		"lineup_positions": [&"cf", &"ss", &"2b", &"1b", &"3b", &"dh", &"lf", &"rf", &"c"],
		"ai": {"swing_aggression": 0.95, "chase_scale": 0.75, "power_swing_rate": 0.36, "runner_aggression": 0.2, "edge_bias_scale": 1.1, "bullpen_hook": 0.55},
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
			[&"nhg_tomorrow", "Tomorrow", "Headliner", 19, &"R", 72, 50, 66, 70],
			[&"nhg_crisp", "Monty Crisp", "Cue Card", 38, &"L", 64, 54, 66, 40],
			[&"nhg_kahn", "Desiree Kahn", "Standing Ovation", 45, &"R", 70, 48, 60, 38],
			[&"nhg_platinum", "Ziggy Platinum", "Glam Slam", 64, &"L", 68, 50, 72, 36],
			[&"nhg_gloss", "Maximilian Gloss", "The Finale", 0, &"R", 82, 56, 64, 28],
		],
		"order": [&"nhg_i_dont_care", &"nhg_because", &"nhg_who", &"nhg_vandermeer", &"nhg_lux", &"nhg_i_dont_know", &"nhg_why", &"nhg_what", &"nhg_today"],
		"lineup_positions": [&"ss", &"cf", &"1b", &"rf", &"dh", &"3b", &"lf", &"2b", &"c"],
		"ai": {"swing_aggression": 1.1, "chase_scale": 1.5, "power_swing_rate": 0.45, "runner_aggression": -0.1, "edge_bias_scale": 0.9, "bullpen_hook": 0.8},
	},
]


func _init() -> void:
	for t in TEAMS:
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
			p.contact = 20; p.power = 15; p.eye = 20; p.speed = 40; p.arm = 70; p.glove = 50
			team.roster.append(p)
		team.batting_order.assign(t["order"])
		team.lineup_positions.assign(t["lineup_positions"])
		team.starting_pitcher = t["pitchers"][0][0]
		for i in range(1, t["pitchers"].size()):
			team.bullpen.append(t["pitchers"][i][0])
		for key in t["ai"]:
			team.set(key, t["ai"][key])
		var path := "res://data/teams/%s.tres" % team.id
		var err := ResourceSaver.save(team, path)
		print("%s -> %s (%s)" % [team.full_name(), path, error_string(err)])
	var rules := MatchRules.new()
	print("rules -> ", error_string(ResourceSaver.save(rules, "res://data/rules/arcade.tres")))
	quit()
