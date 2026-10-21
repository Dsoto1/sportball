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
	check(content().team(&"glitterati").stadium_def.halo, "the Halo Dome has its halo")


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
		check(st._profile(angle).x > FieldLayout.fence_distance(angle, tuning()), "seats behind the wall at %d°" % angle)
	check(st._profile(180.0).x > 15.0, "room for the batting camera behind home")
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
			check(st._profile(angle).x > FieldLayout.fence_distance(angle, t), "%s: seats behind the wall at %d°" % [park.id, angle])
		seen[str(park.field_shape.points)] = true
		check_eq(st.has_node("WallScoreboard"), park.wall_scoreboard, "%s wall scoreboard" % park.id)
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
