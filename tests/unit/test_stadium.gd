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
	var board: Dictionary = st._boards[0]
	check(board["batter"].text.contains("CALLOWAY"), "shows the batter")
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
	check(st.has_node("Roof"), "the Vault is roofed")
	check(not st.has_node("LightTowers") and not st.has_node("Skyline"), "and has no towers or sky")
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
