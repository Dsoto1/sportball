extends TestCase


func _flight(ev: float, la: float, spray: float) -> BallTrajectory:
	return BallTrajectory.simulate(ev, la, spray, tuning())


func _field(traj: BallTrajectory) -> FieldingResult:
	return FieldingResolver.resolve(traj, FielderState.default_defense(tuning()), tuning())


func test_vacuum_flight_matches_projectile_formula() -> void:
	var t := tuning().duplicate() as BaseballTuning
	t.drag = 0.0
	t.fence_center = 10000.0
	t.fence_line = 10000.0
	t.contact_height = 0.0
	var traj := BallTrajectory.simulate(30.0, 45.0, 0.0, t)
	var expected := 30.0 * 30.0 / t.gravity
	check_near(traj.distance(), expected, 0.6, "range")
	check_near(traj.first_bounce_time, 2.0 * 30.0 * sin(deg_to_rad(45.0)) / t.gravity, 0.02, "hang time")


func test_drag_shortens_flight() -> void:
	var t := tuning().duplicate() as BaseballTuning
	t.fence_center = 10000.0
	t.fence_line = 10000.0
	var with_drag := BallTrajectory.simulate(40.0, 30.0, 0.0, t)
	t.drag = 0.0
	var vacuum := BallTrajectory.simulate(40.0, 30.0, 0.0, t)
	check(with_drag.distance() < vacuum.distance() * 0.85, "drag matters")


func test_crushed_ball_is_home_run() -> void:
	var traj := _flight(50.0, 28.0, -10.0)
	check_eq(traj.result, BallTrajectory.Result.HOME_RUN, "home run")
	check(not _field(traj).has_fielder(), "nobody fields a home run")


func test_wall_ball_rebounds_into_play() -> void:
	var traj := _flight(44.0, 16.0, 0.0)
	check_eq(traj.result, BallTrajectory.Result.IN_PLAY, "stays in park")
	var rest := traj.rest_point()
	check(Vector2(rest.x, rest.z).length() < tuning().fence_center, "rests inside the fence")


func test_foul_angle_is_foul() -> void:
	check_eq(_flight(35.0, 20.0, 50.0).result, BallTrajectory.Result.FOUL)


func test_ground_ball_comes_to_rest() -> void:
	var traj := _flight(30.0, -8.0, 5.0)
	check(traj.first_bounce_time < 0.3, "bounces quickly")
	check(traj.end_time() < tuning().max_flight_time, "stops rolling")


func test_trajectory_is_deterministic() -> void:
	var a := _flight(41.3, 22.2, 13.7)
	var b := _flight(41.3, 22.2, 13.7)
	check_eq(a.points.size(), b.points.size(), "sample count")
	check_eq(a.rest_point(), b.rest_point(), "same rest point")


func test_position_at_interpolates_samples() -> void:
	var traj := _flight(35.0, 30.0, 0.0)
	var t := traj.times[10] + traj.step * 0.5
	var expected := traj.points[10].lerp(traj.points[11], 0.5)
	check_near(traj.position_at(t).distance_to(expected), 0.0, 0.0001, "midpoint")


func test_pop_up_caught_in_air_by_infielder() -> void:
	var f := _field(_flight(26.0, 70.0, 5.0))
	check(f.has_fielder(), "someone catches it")
	check(f.caught_in_air, "on the fly")
	check(f.fielder_id in [&"p", &"c", &"1b", &"2b", &"ss", &"3b"], "an infielder (%s)" % f.fielder_id)


func test_routine_fly_to_center_fielder() -> void:
	var f := _field(_flight(36.0, 32.0, 0.0))
	check_eq(f.fielder_id, &"cf", "center fielder")
	check(f.caught_in_air, "caught")
	check(not f.is_dive, "routine, no dive")


func test_grounder_to_short_fielded_on_ground() -> void:
	var f := _field(_flight(30.0, -6.0, -15.0))
	check_eq(f.fielder_id, &"ss", "shortstop fields it")
	check(not f.caught_in_air, "on the ground")
	check(f.secure_time < 2.0, "quickly (%.2f)" % f.secure_time)


func test_gap_liner_falls_in() -> void:
	var f := _field(_flight(41.0, 14.0, -24.0))
	check(not f.caught_in_air, "liner into the gap drops")
	check(f.fielder_id in [&"lf", &"cf"], "outfielder runs it down (%s)" % f.fielder_id)


func test_throw_arrival_grows_with_distance() -> void:
	var f := FieldingResult.new()
	f.ready_time = 1.0
	f.secure_point = FieldLayout.base_position(2) + Vector3(0, 0, -5)
	var near := ThrowModel.arrival_at_base(f, 2, tuning())
	var far := ThrowModel.arrival_at_base(f, 4, tuning())
	check(far > near, "home is farther from short center than second")
	check_near(near, 1.0 + tuning().throw_release_time + 5.0 / tuning().throw_speed + 25.0 * tuning().throw_long_penalty, 0.001, "near throw time")


func test_ball_off_the_wall_costs_pickup_time() -> void:
	var found := false
	for la in range(10, 30):
		var traj := BallTrajectory.simulate(47.0, float(la), -30.0, tuning())
		if traj.result != BallTrajectory.Result.IN_PLAY or not traj.hit_fence:
			continue
		found = true
		check(traj.fence_time < INF, "fence time recorded")
		var f := FieldingResolver.resolve(traj, FielderState.default_defense(tuning()), tuning())
		if f.secure_time >= traj.fence_time:
			check_near(f.ready_time - f.secure_time, tuning().wall_carom_delay, 0.001, "carom delay at la %d" % la)
		break
	check(found, "some ball comes off the wall")


# --- Park shapes -------------------------------------------------------------

func _park(points: PackedVector3Array, drag_scale: float = 1.0) -> BaseballTuning:
	var t: BaseballTuning = tuning().duplicate()
	var shape := FieldShape.new()
	shape.points = points
	shape.air_drag_scale = drag_scale
	t.field_shape = shape
	return t


func test_field_shape_sets_wall_distance_and_height() -> void:
	var t := _park(PackedVector3Array([Vector3(-45, 94, 11.3), Vector3(-20, 105, 11.3), Vector3(-18, 110, 2.5), Vector3(45, 92, 2.5)]))
	check_near(FieldLayout.fence_distance(-45.0, t), 94.0, 0.01, "left corner")
	check_near(FieldLayout.fence_height(-30.0, t), 11.3, 0.01, "tall wall in left")
	check_near(FieldLayout.fence_height(10.0, t), 2.5, 0.01, "normal wall in right")
	check(FieldLayout.fence_distance(-19.0, t) > 105.0 and FieldLayout.fence_distance(-19.0, t) < 110.0, "between points")


func test_tall_wall_turns_homers_into_wall_balls() -> void:
	var normal := _park(PackedVector3Array([Vector3(-45, 94, 3.2), Vector3(45, 94, 3.2)]))
	var monster := _park(PackedVector3Array([Vector3(-45, 94, 11.3), Vector3(45, 94, 11.3)]))
	var homers := [0, 0]
	for la in range(14, 30, 2):
		if BallTrajectory.simulate(42.0, float(la), -30.0, normal).result == BallTrajectory.Result.HOME_RUN:
			homers[0] += 1
		var tall := BallTrajectory.simulate(42.0, float(la), -30.0, monster)
		if tall.result == BallTrajectory.Result.HOME_RUN:
			homers[1] += 1
	check(homers[0] > homers[1], "the tall wall stops some (%d vs %d)" % homers)


func test_thin_air_carries() -> void:
	var sea := _park(PackedVector3Array([Vector3(-45, 400, 3), Vector3(45, 400, 3)]))
	var thin := _park(PackedVector3Array([Vector3(-45, 400, 3), Vector3(45, 400, 3)]), 0.8)
	var d0 := BallTrajectory.simulate(42.0, 28.0, 0.0, sea).distance()
	var d1 := BallTrajectory.simulate(42.0, 28.0, 0.0, thin).distance()
	check(d1 > d0 + 4.0, "carries farther in thin air (%.1f vs %.1f)" % [d1, d0])
