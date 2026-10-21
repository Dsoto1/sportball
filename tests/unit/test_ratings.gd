extends TestCase
## Ratings: player numbers change play, gently, around league average.


func _player(fields: Dictionary) -> PlayerDef:
	var p := PlayerDef.new()
	for key in fields:
		p.set(key, fields[key])
	return p


func test_average_player_changes_nothing() -> void:
	var avg := _player({})
	var mods := Ratings.pitcher_mods(avg, 0, tuning())
	check_near(mods["speed"], 1.0, 0.0001, "speed")
	check_near(mods["scatter"], 1.0, 0.0001, "scatter")
	var swing := SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0)
	Ratings.apply_batter(swing, avg, tuning())
	# Only his own small swing variation (SwingProfile wobble: up to 3 deg
	# of attack angle) remains.
	check_near(swing.window_scale, 1.0, 3.0 * tuning().attack_angle_window + 0.0001, "window: within his own swing's variation")
	var wobble := 1.5 * tuning().bat_speed_ev_per_mph
	check_near(swing.power_scale, 1.0, wobble + 0.0001, "power: within his own swing's variation")
	check_near(swing.attack_angle, SwingProfile.LEAGUE_ATTACK_ANGLE, 3.01, "attack angle near the league's")
	check_near(Ratings.runner_speed(avg, tuning()), tuning().runner_speed, 0.0001, "runner speed")


func test_swing_numbers_shape_contact() -> void:
	var pitch := PitchResult.new()
	pitch.location = PitchResolver.zone_center(tuning())
	var launches := {}
	var sprays := {}
	for aa in [2.0, 18.0]:
		var swing := SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0)
		swing.attack_angle = aa
		var total := 0.0
		for i in 200:
			total += ContactResolver.resolve(pitch, swing, tuning(), MatchRng.new(i)).launch_angle
		launches[aa] = total / 200.0
	check(launches[18.0] > launches[2.0] + 6.0, "uppercut swings lift the ball (%.1f vs %.1f)" % [launches[18.0], launches[2.0]])
	for pull in [-11.0, 15.0]:
		var swing := SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0)
		swing.attack_pull = pull
		var total := 0.0
		for i in 200:
			total += ContactResolver.resolve(pitch, swing, tuning(), MatchRng.new(i)).spray_angle
		sprays[pull] = total / 200.0
	check(sprays[15.0] < sprays[-11.0] - 15.0, "a righty pull swing sprays to left field (%.1f vs %.1f)" % [sprays[15.0], sprays[-11.0]])
	var slow := _player({"power": 20})
	var fast := _player({"power": 95})
	var a := SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0)
	var b := SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0)
	Ratings.apply_batter(a, slow, tuning())
	Ratings.apply_batter(b, fast, tuning())
	check(b.power_scale > a.power_scale + 0.05, "bat speed drives exit velocity")
	# Loft costs contact: an uppercut swing has a smaller timing window.
	var flat := _player({"id": &"x_flat", "batting_style": &"slap"})
	var steep := _player({"id": &"x_steep", "batting_style": &"leg_kick"})
	var f := SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0)
	var u := SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0)
	Ratings.apply_batter(f, flat, tuning())
	Ratings.apply_batter(u, steep, tuning())
	check(u.window_scale < f.window_scale, "uppercuts whiff more than flat swings")


func test_pitcher_ratings_and_fatigue() -> void:
	var ace := _player({"velocity": 90, "control": 80, "stamina": 50})
	var fresh := Ratings.pitcher_mods(ace, 0, tuning())
	check(fresh["speed"] > 1.0, "hard thrower")
	check(fresh["scatter"] < 1.0, "good command")
	check_eq(fresh["fatigue"], 0.0, "fresh")
	var tired := Ratings.pitcher_mods(ace, 120, tuning())
	check_near(tired["fatigue"], 1.0, 0.0001, "gassed after 120")
	check(tired["speed"] < fresh["speed"], "loses velocity")
	check(tired["scatter"] > fresh["scatter"] * 1.5, "loses command")
	var horse := _player({"stamina": 100})
	check(Ratings.fatigue(horse, 80, tuning()) < Ratings.fatigue(_player({"stamina": 20}), 80, tuning()), "stamina delays fatigue")


func test_velocity_rating_speeds_up_the_pitch() -> void:
	var family := content().pitch(&"fastball")
	var intent := PitchIntent.new(&"fastball", Vector2(0.0, 0.8), 0.0)
	var slow := PitchResolver.resolve(intent, family, tuning(), MatchRng.new(3))
	var fast := PitchResolver.resolve(intent, family, tuning(), MatchRng.new(3), Ratings.pitcher_mods(_player({"velocity": 100}), 0, tuning()))
	check(fast.speed > slow.speed * 1.04, "faster pitch (%.1f vs %.1f)" % [fast.speed, slow.speed])


func test_contact_and_power_ratings() -> void:
	var slugger := _player({"power": 100, "contact": 20, "bats": &"L"})
	var swing := SwingIntent.swing(SwingIntent.Type.POWER, 0.0)
	Ratings.apply_batter(swing, slugger, tuning())
	check(swing.power_scale > 1.05, "more exit velocity")
	check(swing.window_scale < 0.95, "smaller window")
	check(swing.bats_left, "lefty")


func test_fielder_ratings() -> void:
	var star := _player({"speed": 90, "glove": 90, "arm": 90})
	var players := {&"ss": star}
	var defense := FielderState.default_defense(tuning(), players)
	var ss := defense[tuning().fielder_ids.find(&"ss")]
	var avg := defense[tuning().fielder_ids.find(&"2b")]
	check(ss.speed > avg.speed, "faster")
	check(ss.reach > avg.reach, "more range")
	check(ss.arm > 1.0, "stronger arm")
	check(ss.error_scale < 1.0, "fewer bobbles")
	check_eq(ss.player_id, star.id, "player recorded")


func test_fast_runner_beats_out_what_a_slow_one_cannot() -> void:
	# A slow roller to short: speed decides the infield single.
	var f := FieldingResult.new()
	f.fielder_index = 4
	f.fielder_id = &"ss"
	f.secure_point = Vector3(-6, 0, -26)
	f.secure_time = 2.25
	f.ready_time = 2.25
	var traj := BallTrajectory.simulate(30.0, -6.0, -15.0, tuning())
	var b: Array[StringName] = [&"", &"", &""]
	var fielders := FielderState.default_defense(tuning())
	var slow := LivePlay.new(b, &"bat", 0, -6.0, traj, f, tuning(), true, fielders, {&"bat": 7.0}).run_ai(tuning().sim_play_step)
	var fast := LivePlay.new(b, &"bat", 0, -6.0, traj, f, tuning(), true, fielders, {&"bat": 9.0}).run_ai(tuning().sim_play_step)
	check_eq(slow.kind, PlayOutcome.KIND_GROUND_OUT, "slow runner out")
	check_eq(fast.kind, PlayOutcome.KIND_SINGLE, "fast runner safe")


func test_ai_pitcher_sticks_to_repertoire() -> void:
	var s := new_match()
	var p := _player({"pitches": [&"fastball", &"changeup"] as Array[StringName]})
	var rng := MatchRng.new(11)
	for i in 60:
		var intent := AiPitcher.choose(s, content().pitches, tuning(), rng, null, p)
		check(intent.family_id in [&"fastball", &"changeup"], "only his pitches")
