extends TestCase
## The Halo Dome builds from data, seats a crowd and keeps a live scoreboard.


func _build() -> Stadium:
	var st := Stadium.new()
	st.build(tuning(), content().team(&"glitterati").stadium_def, content().team(&"glitterati"), content().team(&"gearheads"))
	return st


func test_both_parks_have_data() -> void:
	for id in [&"glitterati", &"gearheads"]:
		var park := content().team(id).stadium_def
		check(park != null, "%s has a home park" % id)
		check(park.sponsors.size() > 0, "%s park has sponsor boards" % id)
	check(content().team(&"glitterati").stadium_def.has_piece(&"halo"), "the Halo Dome has its halo")


func test_stadium_builds_bowl_crowd_and_landmarks() -> void:
	var st := _build()
	var crowd := st.get_node("Crowd") as MultiMeshInstance3D
	check(crowd.multimesh.instance_count > 5000, "a big crowd (%d)" % crowd.multimesh.instance_count)
	for node in ["SeatingBowl", "Scoreboard", "Halo", "BattersEye", "Backstop"]:
		check(st.has_node(node), "has %s" % node)
	st.free()


func test_no_fans_in_the_batters_eye() -> void:
	var st := _build()
	var crowd := st.get_node("Crowd") as MultiMeshInstance3D
	for i in range(0, crowd.multimesh.instance_count, 7):
		var p := crowd.multimesh.get_instance_transform(i).origin
		var spray := rad_to_deg(atan2(p.x, -p.z))
		check(absf(spray) >= Stadium.BATTERS_EYE, "fan %d sits outside the batter's eye" % i)
		if absf(spray) < Stadium.BATTERS_EYE:
			break
	st.free()


func test_stands_stay_out_of_play() -> void:
	var st := _build()
	for angle in range(-45, 46, 5):
		check(st.profile(angle).x > FieldLayout.fence_distance(angle, tuning()), "seats behind the wall at %d°" % angle)
	check(st.profile(180.0).x > 15.0, "room for the batting camera behind home")
	st.free()


func test_scoreboard_follows_the_game() -> void:
	var st := _build()
	var s := MatchState.from_teams(content().team(&"gearheads"), content().team(&"glitterati"), content().rules)
	var roster := MatchRoster.new(content().team(&"gearheads"), content().team(&"glitterati"))
	s.apply_pitch_call(MatchState.PitchCall.BALL)
	st.update_scoreboard(s, roster)
	var card: Dictionary = st._boards[0]["card"]
	check(card["name"].text.contains("CALLOWAY"), "the centerpiece shows the batter")
	check(card["avg"].text.begins_with("."), "and his average (%s)" % card["avg"].text)
	var board: Dictionary = st._boards.filter(func(b: Dictionary) -> bool: return b.has("cells"))[0]
	check(board["batter"].text.contains("CALLOWAY"), "the line-score board shows the batter")
	check_eq(board["cells"][Vector2i(9, 0)].text, "0", "away runs")
	var lamps: Array = board["lamps"]["B"][0]
	check((lamps[0] as MeshInstance3D).material_override.emission_enabled, "first ball lamp lit")
	st.free()



func test_every_park_builds_with_its_own_shape() -> void:
	var seen := {}
	for park in content().parks:
		check(park.field_shape != null, "%s has dimensions" % park.id)
		var t := content().tuning_for(park)
		var st := Stadium.new()
		st.build(t, park, content().team(&"glitterati"), content().team(&"gearheads"))
		for angle in range(-45, 46, 5):
			check(st.profile(angle).x > FieldLayout.fence_distance(angle, t), "%s: seats behind the wall at %d°" % [park.id, angle])
		seen[str(park.field_shape.points)] = true
		check_eq(st.has_node("WallScoreboard"), park.has_piece(&"wall_scoreboard"), "%s wall scoreboard" % park.id)
		check(park.validate().is_empty(), "%s is a valid design: %s" % [park.id, park.validate()])
		st.free()
	check(content().parks.size() >= 7, "a catalog of parks (%d)" % content().parks.size())
	check_eq(seen.size(), content().parks.size(), "every park has its own layout")


func test_signature_walls() -> void:
	var ledger := content().park(&"ledger_street").field_shape
	check(ledger.height_at(-30) > 10.0 and ledger.distance_at(-45) < 96.0, "the Leviathan is short and tall in left")
	check(ledger.height_at(40) < 2.0, "and the right-field wall is knee-high")
	var foundry := content().park(&"foundry_field").field_shape
	check(foundry.height_at(30) > 10.0 and foundry.distance_at(45) < 92.0, "the Boilerplate in right")
	check(content().park(&"the_kiln").field_shape.air_drag_scale < 0.9, "thin air at the Kiln")


func _build_park(id: StringName) -> Stadium:
	var park := content().park(id)
	var st := Stadium.new()
	st.build(content().tuning_for(park), park, content().team(&"glitterati"), content().team(&"gearheads"))
	return st


func test_landmark_parks_build_their_landmarks() -> void:
	var st := _build_park(&"warehouse_row")
	check(st.has_node("Warehouse"), "Warehouse Row has its warehouse")
	st.free()
	st = _build_park(&"the_vault")
	check(st.has_node("VaultDoor") and st.has_node("Searchlights"), "the Vault has its vault door and searchlights")
	st.free()
	# A dome still builds and keeps a park indoors.
	var domed: StadiumDef = content().park(&"the_vault").duplicate()
	domed.pieces = []
	domed.add_piece(&"centerpiece")
	domed.add_piece(&"dome")
	st = Stadium.new()
	st.build(content().tuning_for(domed), domed, content().team(&"glitterati"), content().team(&"gearheads"))
	check(st.has_node("Roof") and domed.is_roofed(), "a dome roofs the park")
	check(domed.validate().is_empty(), "a domed design is valid: %s" % domed.validate())
	st.free()
	check(content().park(&"the_vault").turf, "the Vault plays on turf")
	check(content().park(&"the_horseshoe").night, "the Horseshoe is a night game")


func test_turf_runs_grounders_faster() -> void:
	var grass := tuning()
	var turf := content().tuning_for(content().park(&"the_vault"))
	check(FieldLayout.roll_deceleration(turf) < FieldLayout.roll_deceleration(grass), "less roll friction on turf")
	check(FieldLayout.bounce_friction(turf) > FieldLayout.bounce_friction(grass), "grounders skip off turf")


func test_bat_is_turned_from_knob_to_barrel() -> void:
	var mesh := BatMesh.build()
	var aabb := mesh.get_aabb()
	check_near(aabb.size.z, BatMesh.LENGTH, 0.01, "bat is full length")
	check(aabb.position.z + aabb.size.z <= 0.001, "knob at the grip end (z = 0), barrel toward -Z")
	check(aabb.size.x > 0.1 and aabb.size.x < 0.13, "barrel about 11 cm across (%.3f)" % aabb.size.x)


# --- Modules -----------------------------------------------------------------

func _blank_park() -> StadiumDef:
	var park: StadiumDef = content().park(&"the_kiln").duplicate()
	park.pieces = []
	return park


func _build_def(park: StadiumDef) -> Stadium:
	var st := Stadium.new()
	st.build(content().tuning_for(park), park, content().team(&"glitterati"), content().team(&"gearheads"))
	return st


func test_every_module_builds_on_its_own() -> void:
	for kind: StringName in StadiumModules.kinds():
		var park := _blank_park()
		park.add_piece(&"scoreboard")
		park.add_piece(kind)
		var st := _build_def(park)
		var spec := StadiumModules.info(kind)
		check(st.get_child_count() > 7, "%s adds to the park" % spec["name"])
		check(not String(spec["about"]).is_empty(), "%s describes itself for the designer" % kind)
		for key in spec["params"]:
			check(StadiumModules.default_param(kind, key) != null, "%s.%s has a default" % [kind, key])
		st.free()


func test_a_park_is_just_its_pieces() -> void:
	var park := _blank_park()
	var st := _build_def(park)
	for node in ["SeatingBowl", "Crowd", "BattersEye", "Backstop"]:
		check(st.has_node(node), "the core has %s" % node)
	check(not st.has_node("Scoreboard") and not st.has_node("LightTowers"), "nothing else without pieces")
	st.free()
	# Move the scoreboard and add a second warehouse down the left-field line.
	park.add_piece(&"scoreboard", -35.0)
	park.add_piece(&"warehouse", 45.0)
	park.add_piece(&"warehouse", -45.0, {"text": "LEFT FIELD LOFTS"})
	st = _build_def(park)
	check((st.get_node("Scoreboard") as Node3D).position.x < 0.0, "the scoreboard moved to left field")
	check(st.has_node("Warehouse") and st.has_node("Warehouse2"), "two warehouses, one each side")
	check(park.validate().is_empty(), "a valid design: %s" % park.validate())
	st.free()


func test_mirrored_pieces_build_both_sides() -> void:
	var park := _blank_park()
	park.add_piece(&"scoreboard")
	park.add_piece(&"fountains", 14.0, {"basins": 4}, true)
	var st := _build_def(park)
	var sides := []
	for name in ["Fountains", "Fountains2"]:
		check(st.has_node(name), "has %s" % name)
		sides.append(signf((st.get_node(name).get_child(0) as Node3D).position.x))
	check(sides.size() == 2 and sides[0] != sides[1], "one pool set in each power alley")
	st.free()


func test_bay_follows_its_piece() -> void:
	var park := _blank_park()
	park.add_piece(&"scoreboard")
	park.add_piece(&"bay", -40.0)
	var st := _build_def(park)
	check(st.is_water(-40.0) and not st.is_water(40.0), "the bay moved to left field")
	check(st.profile(-40.0).z <= 5.0, "with low stands along it")
	st.free()


func test_validation_catches_bad_designs() -> void:
	var park := _blank_park()
	check(park.validate().size() == 1, "a park needs a scoreboard")
	park.add_piece(&"scoreboard")
	check(park.validate().is_empty(), "a scoreboard is enough")
	park.add_piece(&"dome")
	park.add_piece(&"light_towers")
	check(Array(park.validate()).any(func(p: String) -> bool: return p.contains("can't share")), "no light towers under a dome")
	park = _blank_park()
	park.add_piece(&"scoreboard")
	park.add_piece(&"halo")
	park.add_piece(&"halo")
	park.add_piece(&"wall_scoreboard", 0.0)
	park.add_piece(&"warehouse", 90.0, {"height": 500.0, "colour": 1})
	park.add_piece(&"moat")
	var problems := " | ".join(park.validate())
	for expect in ["only one Halo Ring", "needs a wall 6 m", "outside -45..45", "height 500", "no setting 'colour'", "unknown module 'moat'"]:
		check(problems.contains(expect), "flags: %s (%s)" % [expect, problems])


func test_recolor_for_a_club() -> void:
	var team := content().team(&"gearheads")
	var park := content().park(&"halo_dome").recolored(team.primary_color, team.secondary_color)
	check(park != content().park(&"halo_dome"), "a copy, the original untouched")
	check(park.seat_color.is_equal_approx(team.primary_color.darkened(0.35)), "seats in the club's color")
	check_eq(park.pieces.size(), content().park(&"halo_dome").pieces.size(), "same pieces")


# --- Club identity and the shared pieces ---------------------------------------

func test_every_club_has_an_identity() -> void:
	for team in content().teams:
		var colors: Array = team.palette().values()
		check_eq(colors.size(), 6, "%s has six colors" % team.id)
		var distinct := {}
		for c: Color in colors:
			distinct[c.to_html()] = true
		check(distinct.size() >= 5, "%s's colors are distinct" % team.id)
		check(not team.slogan.is_empty(), "%s has a slogan" % team.id)
		check(team.emblem_shape in Emblem.SHAPES, "%s has a known emblem shape" % team.id)
		var mark := Emblem.build(team, 2.0)
		check(mark.get_child_count() >= 2, "%s's emblem builds" % team.id)
		mark.free()
	var gearheads := content().team(&"gearheads")
	check(gearheads.primary_color.is_equal_approx(Color("c6531a")), "Gearheads use the reference sheet's Rust Orange")


func test_decks_step_up_with_fascia() -> void:
	var st := _build_park(&"halo_dome")
	check_eq(st.def.decks, 3, "the Halo Dome has three decks")
	var p := st.profile(120.0)
	var k := st.rows_per_deck()
	var jump := st.row_height(120.0, p, k) - st.row_height(120.0, p, k - 1)
	check(jump > Stadium.ROW_RISE + 2.0, "the upper deck starts above the one below (%.1f m)" % jump)
	var out := st.profile(0.0)
	check_near(st.row_height(0.0, out, k) - st.row_height(0.0, out, k - 1), Stadium.ROW_RISE, 0.01, "the bleachers are one deck")
	check(st.get_node("Fascia").get_child_count() > 40, "wordmarks along the deck fronts")
	st.free()


func test_shared_pieces_dress_every_park() -> void:
	for park in content().parks:
		var home: TeamDef = null
		for team in content().teams:
			if team.stadium_def == park:
				home = team
		var st := Stadium.new()
		st.build(content().tuning_for(park), park, home, content().team(&"glitterati") if home.id != &"glitterati" else content().team(&"gearheads"))
		check(st.has_node("Centerpiece"), "%s has its centerpiece" % park.id)
		check(st.has_node("SloganBoard"), "%s has its slogan board" % park.id)
		check(st.has_node("Dugout_%s" % home.abbreviation), "%s has the home dugout" % park.id)
		check((st.get_node("Dugout_%s" % home.abbreviation) as Node3D).position.x > 0.0, "%s: home dugout on the first-base side" % park.id)
		var dugout_signs := st.find_children("*", "Label3D", true, false).filter(func(l: Label3D) -> bool: return l.text == "VISITORS")
		check_eq(dugout_signs.size(), 1, "%s: the visitors' dugout says VISITORS" % park.id)
		st.free()


func test_centerpiece_shows_the_batters_card() -> void:
	var st := _build()
	var s := MatchState.from_teams(content().team(&"gearheads"), content().team(&"glitterati"), content().rules)
	var roster := MatchRoster.new(content().team(&"gearheads"), content().team(&"glitterati"))
	st.update_scoreboard(s, roster)
	var card: Dictionary = st._boards[0]["card"]
	var p := roster.player(s.current_batter())
	var line := SeasonLine.for_player(p)
	check_eq(card["number"].text, "#%d" % p.number, "his number")
	check_eq(card["hr"].text, str(line["hr"]), "his home runs")
	check(card["position"].text.length() in [1, 2], "his position (%s)" % card["position"].text)
	check(line["avg"] > 0.15 and line["avg"] < 0.37, "a believable average")
	st.free()


func test_foul_poles_are_yellow_and_tall() -> void:
	var field := GrayboxField.new()
	field.build(tuning())
	var poles := field.find_children("FoulPole*", "MeshInstance3D", true, false).filter(func(m: MeshInstance3D) -> bool: return m.name.begins_with("FoulPole") and not m.name.contains("Screen"))
	check_eq(poles.size(), 2, "two foul poles")
	for pole: MeshInstance3D in poles:
		var c: Color = (pole.material_override as StandardMaterial3D).albedo_color
		check(c.r > 0.9 and c.g > 0.7 and c.b < 0.3, "yellow")
		check((pole.mesh as BoxMesh).size.y > FieldLayout.fence_height(45.0, tuning()) + 10.0, "well above the wall")
	field.free()


func test_water_sits_beyond_the_stands() -> void:
	for park in content().parks:
		for water in park.pieces_of(&"water"):
			var st := Stadium.new()
			st.build(content().tuning_for(park), park, content().team(&"glitterati"), content().team(&"gearheads"))
			var wet := 0
			for angle in range(-180, 180, 5):
				var band := Scenery.water_band(st, water, angle)
				if band.y > band.x:
					wet += 1
					check(band.x >= st.stand_top(angle).x, "%s: water behind the stands at %d°" % [park.id, angle])
			check(wet > 0, "%s: its water shows somewhere" % park.id)
			st.free()
	check(content().park(&"pier_nine").pieces_of(&"water").size() > 0, "Pier 9 sits in the harbor")
	check(content().park(&"the_kiln").pieces_of(&"water").is_empty(), "the desert park stays dry")


func test_angles_wrap_around_home() -> void:
	var st := _build_park(&"fountain_gardens")
	for angle in [190.0, 270.0, 350.0, -200.0]:
		check_near(st.profile(angle).x, st.profile(wrapf(angle, -180.0, 180.0)).x, 0.001, "%d° is the same stand as %d°" % [angle, wrapf(angle, -180.0, 180.0)])
	for angle in range(0, 360, 10):
		check(st.stand_top(angle).x > 40.0, "the stands never collapse onto the field at %d°" % angle)
	st.free()


func test_surfaces_and_models_load() -> void:
	for kind: StringName in StadiumSurfaces.kinds():
		var m := StadiumSurfaces.material(kind, Color(0.5, 0.4, 0.3))
		check(m.albedo_texture != null and m.normal_texture != null, "%s has its detail and normal maps" % kind)
		check(m.uv1_world_triplanar, "%s maps in world space (no UVs needed)" % kind)
	check(StadiumSurfaces.material(&"nope", Color.RED).albedo_texture == null, "an unknown surface is a flat color")
	var rng := RandomNumberGenerator.new()
	for role: StringName in ModelKit.SETS:
		var node := ModelKit.spawn(role, 10.0, rng)
		check(node.find_children("*", "MeshInstance3D", true, false).size() > 0, "%s model loads" % role)
		node.free()
	for park in content().parks:
		for kind in [park.facade_surface, park.structure_surface, park.stand_surface]:
			check(kind == &"" or StadiumSurfaces.KINDS.has(kind), "%s uses known surfaces (%s)" % [park.id, kind])
