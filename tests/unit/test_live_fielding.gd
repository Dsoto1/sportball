extends TestCase


func _setup(ev: float, la: float, spray: float) -> Dictionary:
	var traj := BallTrajectory.simulate(ev, la, spray, tuning())
	var fielders := FielderState.default_defense(tuning())
	var projection := FieldingResolver.resolve(traj, fielders, tuning())
	return {"traj": traj, "fielders": fielders, "projection": projection}


func _index(id: StringName) -> int:
	return tuning().fielder_ids.find(id)


## Steers the controlled fielder straight at a point, the way a player would.
func _steer_to(live: LiveFielding, goal: Vector3, max_time: float = 15.0) -> void:
	while not live.is_secured() and live.time < max_time:
		var p := live.positions[live.controlled]
		var d := Vector2(goal.x - p.x, -(goal.z - p.z))
		live.step(tuning().sim_step, d.normalized() if d.length() > 0.05 else Vector2.ZERO)


func test_all_ai_matches_projection() -> void:
	for spec in [[36.0, 32.0, 0.0], [30.0, -6.0, -15.0], [26.0, 70.0, 5.0], [41.0, 14.0, -24.0]]:
		var s := _setup(spec[0], spec[1], spec[2])
		var projection: FieldingResult = s["projection"]
		var live := LiveFielding.new(s["traj"], s["fielders"], projection, tuning(), -1)
		while not live.is_secured():
			live.step(tuning().sim_step)
		check_eq(live.result.fielder_id, projection.fielder_id, "same fielder for %s" % [spec])
		check_eq(live.result.caught_in_air, projection.caught_in_air, "same catch type for %s" % [spec])
		check_near(live.result.secure_time, projection.secure_time, 0.3, "similar time for %s" % [spec])


func test_steering_to_landing_spot_makes_the_catch() -> void:
	var s := _setup(36.0, 32.0, 0.0)
	var traj: BallTrajectory = s["traj"]
	var live := LiveFielding.new(traj, s["fielders"], s["projection"], tuning(), _index(&"cf"))
	_steer_to(live, traj.landing_point)
	check(live.is_secured(), "secured")
	check_eq(live.result.fielder_id, &"cf", "player-controlled CF")
	check(live.result.caught_in_air, "on the fly")


func test_standing_still_lets_the_ball_drop() -> void:
	var s := _setup(36.0, 32.0, -22.0)
	var live := LiveFielding.new(s["traj"], s["fielders"], s["projection"], tuning(), _index(&"lf"))
	while not live.is_secured() and live.time < 30.0:
		live.step(tuning().sim_step)
	check(live.is_secured(), "a teammate or the CF eventually fields it")
	check(not live.result.caught_in_air, "nobody caught it on the fly")
	var all_ai := LiveFielding.new(s["traj"], s["fielders"], s["projection"], tuning(), -1)
	while not all_ai.is_secured():
		all_ai.step(tuning().sim_step)
	check(all_ai.result.caught_in_air, "with no human, the AI makes the routine catch")


func test_misplayed_fly_lets_runners_advance() -> void:
	var s := _setup(36.0, 32.0, 0.0)
	var state := new_match()
	state.bases = [&"r1", &"", &""]
	var contact := ContactResult.new()
	contact.exit_velocity = 36.0
	contact.launch_angle = 32.0
	var bip := BallInPlay.create(contact, state, tuning())
	check(bip.fielding.caught_in_air, "projection says routine fly")
	var live := LiveFielding.new(bip.trajectory, bip.fielders, bip.fielding, tuning(), _index(&"cf"))
	while not live.is_secured() and live.time < 30.0:
		live.step(tuning().sim_step, Vector2(0.0, -1.0))  # run the wrong way
	bip.set_fielding(live.result)
	var outcome := bip.resolve(bip.ai_throw_target())
	check(outcome.batter_base >= 1, "batter reaches (%s)" % outcome.kind)


func test_dive_extends_reach_and_miss_costs_time() -> void:
	var s := _setup(36.0, 32.0, 0.0)
	var traj: BallTrajectory = s["traj"]
	var cf := _index(&"cf")
	# Arrive short of the ball by more than reach but within dive range.
	var live := LiveFielding.new(traj, s["fielders"], s["projection"], tuning(), cf)
	var short := traj.landing_point + Vector3(tuning().catch_reach + tuning().dive_reach * 0.5, 0.0, 0.0)
	_steer_to(live, short, traj.first_bounce_time - 0.03)
	check(not live.is_secured(), "not caught without diving")
	live.step(tuning().sim_step, Vector2.ZERO, true)
	check(live.is_secured() and live.result.is_dive, "dive makes the catch")
	# Diving far too early whiffs and pins the fielder down.
	var early := LiveFielding.new(traj, s["fielders"], s["projection"], tuning(), cf)
	early.step(tuning().sim_step, Vector2.ZERO, true)
	check(not early.is_secured(), "early dive misses")
	check_eq(early.dives_missed, 1, "miss recorded")
	var p := early.positions[cf]
	early.step(tuning().sim_step, Vector2(1.0, 0.0))
	check_eq(early.positions[cf], p, "cannot move while down")


func test_switch_picks_nearest_other_fielder() -> void:
	var s := _setup(30.0, -6.0, -15.0)
	var live := LiveFielding.new(s["traj"], s["fielders"], s["projection"], tuning(), _index(&"rf"))
	for i in 60:
		live.step(tuning().sim_step)
	live.switch_to_nearest()
	check(live.controlled in [_index(&"ss"), _index(&"3b"), _index(&"p")], "switched to an infielder near the grounder (%d)" % live.controlled)


func test_live_fielding_is_deterministic() -> void:
	var a_setup := _setup(41.0, 14.0, -24.0)
	var b_setup := _setup(41.0, 14.0, -24.0)
	var a := LiveFielding.new(a_setup["traj"], a_setup["fielders"], a_setup["projection"], tuning(), _index(&"lf"))
	var b := LiveFielding.new(b_setup["traj"], b_setup["fielders"], b_setup["projection"], tuning(), _index(&"lf"))
	for i in 2000:
		var move := Vector2(sin(i * 0.01), cos(i * 0.013))
		a.step(tuning().sim_step, move)
		b.step(tuning().sim_step, move)
	check(a.is_secured() and b.is_secured(), "both finished")
	check_eq(a.result.secure_time, b.result.secure_time, "same time")
	check_eq(a.result.fielder_id, b.result.fielder_id, "same fielder")
