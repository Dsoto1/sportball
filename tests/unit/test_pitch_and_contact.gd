extends TestCase


func _pitch(aim: Vector2, error: float, seed_value: int = 1, family: StringName = &"fastball") -> PitchResult:
	var rng := MatchRng.new(seed_value)
	return PitchResolver.resolve(PitchIntent.new(family, aim, error), content().pitch(family), tuning(), rng)


func _swing(pitch: PitchResult, type: SwingIntent.Type, timing: float, stick: Vector2 = Vector2.ZERO, lefty: bool = false) -> ContactResult:
	var swing := SwingIntent.swing(type, timing, stick, lefty)
	return ContactResolver.resolve(pitch, swing, tuning(), MatchRng.new(7))


func test_content_validates() -> void:
	check_eq(content().validate().size(), 0, "content problems: %s" % [content().validate()])


func test_perfect_meter_lands_near_aim() -> void:
	var aim := Vector2(0.1, 0.8)
	var worst := 0.0
	for seed_value in 50:
		worst = maxf(worst, _pitch(aim, 0.0, seed_value).location.distance_to(aim))
	check(worst < 0.12, "perfect pitches stay tight (worst %.3f)" % worst)


func test_missed_meter_scatters_more() -> void:
	var aim := Vector2(0.0, 0.8)
	var tight := 0.0
	var wild := 0.0
	for seed_value in 100:
		tight += _pitch(aim, 0.0, seed_value).location.distance_to(aim)
		wild += _pitch(aim, 1.0, seed_value).location.distance_to(aim)
	check(wild > tight * 4.0, "wild meter scatters far more (%.2f vs %.2f)" % [wild, tight])


func test_pitch_is_deterministic_for_seed() -> void:
	var a := _pitch(Vector2(0.2, 0.7), 0.5, 99)
	var b := _pitch(Vector2(0.2, 0.7), 0.5, 99)
	check_eq(a.location, b.location, "same seed, same pitch")


func test_zone_membership() -> void:
	check(PitchResolver.in_zone(Vector2(0.0, 0.8), tuning()), "middle is a strike")
	check(not PitchResolver.in_zone(Vector2(0.5, 0.8), tuning()), "far outside is a ball")
	check(not PitchResolver.in_zone(Vector2(0.0, 0.2), tuning()), "at the knees-minus is a ball")


func test_pitch_path_ends_at_plate_location() -> void:
	var p := _pitch(Vector2(0.15, 0.7), 0.0, 3, &"breaking_ball")
	var end := p.position_at(p.travel_time)
	check_near(end.distance_to(Vector3(p.location.x, p.location.y, 0.0)), 0.0, 0.001, "path ends on location")
	check_near(p.position_at(0.0).distance_to(p.release_point), 0.0, 0.001, "path starts at release")
	check(p.travel_time > 0.35 and p.travel_time < 0.7, "travel time arcade-readable (%.2f)" % p.travel_time)


func test_meter_error_mapping() -> void:
	check_near(PitchResolver.meter_error(tuning().pitch_meter_sweet_spot, tuning()), 0.0, 0.0001, "sweet spot")
	check(PitchResolver.meter_error(0.2, tuning()) > 0.6, "early release is inaccurate")
	check(PitchResolver.meter_error(1.0, tuning()) >= 0.5, "overshoot is inaccurate")


func test_take_is_called_by_zone() -> void:
	var strike := _pitch(Vector2(0.0, 0.8), 0.0)
	var take := ContactResolver.resolve(strike, SwingIntent.take(), tuning(), MatchRng.new(1))
	check_eq(take.outcome, ContactResult.Outcome.TAKE)
	check_eq(ContactResolver.call_for(strike, take), MatchState.PitchCall.CALLED_STRIKE, "called strike")


func test_perfect_swing_is_hard_contact_up_the_middle() -> void:
	var p := _pitch(Vector2(0.0, 0.8), 0.0)
	var c := _swing(p, SwingIntent.Type.CONTACT, 0.0)
	check_eq(c.outcome, ContactResult.Outcome.IN_PLAY, "in play")
	check(c.quality > 0.95, "high quality")
	check(c.exit_velocity > tuning().contact_exit_velocity_max - 1.5, "high exit velocity")
	check(absf(c.spray_angle) < 15.0, "up the middle (%.1f)" % c.spray_angle)


func test_power_hits_harder_with_smaller_window() -> void:
	var p := _pitch(Vector2(0.0, 0.8), 0.0)
	check(_swing(p, SwingIntent.Type.POWER, 0.0).exit_velocity > _swing(p, SwingIntent.Type.CONTACT, 0.0).exit_velocity, "power is faster")
	var timing := tuning().power_timing_window * 1.2
	check_eq(_swing(p, SwingIntent.Type.CONTACT, timing).outcome, ContactResult.Outcome.IN_PLAY, "contact still connects")
	check(_swing(p, SwingIntent.Type.POWER, timing).outcome != ContactResult.Outcome.IN_PLAY, "power misses the same timing")


func test_early_pulls_late_goes_opposite() -> void:
	var p := _pitch(Vector2(0.0, 0.8), 0.0)
	var early := _swing(p, SwingIntent.Type.CONTACT, -0.06)
	var late := _swing(p, SwingIntent.Type.CONTACT, 0.06)
	check(early.spray_angle < -10.0, "right-handed early swing pulls to left (%.1f)" % early.spray_angle)
	check(late.spray_angle > 10.0, "late swing goes to right (%.1f)" % late.spray_angle)
	var lefty_early := _swing(p, SwingIntent.Type.CONTACT, -0.06, Vector2.ZERO, true)
	check(lefty_early.spray_angle > 10.0, "left-handed early swing pulls to right (%.1f)" % lefty_early.spray_angle)


func test_stick_lifts_or_chops() -> void:
	var p := _pitch(Vector2(0.0, 0.8), 0.0)
	var lift := _swing(p, SwingIntent.Type.CONTACT, 0.0, Vector2(0.0, 1.0))
	var chop := _swing(p, SwingIntent.Type.CONTACT, 0.0, Vector2(0.0, -1.0))
	check(lift.launch_angle > chop.launch_angle + 30.0, "stick up = fly, down = grounder (%.1f vs %.1f)" % [lift.launch_angle, chop.launch_angle])


func test_stick_steers_spray() -> void:
	var p := _pitch(Vector2(0.0, 0.8), 0.0)
	var left := _swing(p, SwingIntent.Type.CONTACT, 0.0, Vector2(-1.0, 0.0))
	var right := _swing(p, SwingIntent.Type.CONTACT, 0.0, Vector2(1.0, 0.0))
	check_near(right.spray_angle - left.spray_angle, 2.0 * tuning().stick_spray, 0.5, "stick shifts spray")


func test_location_costs_quality_and_chases_whiff() -> void:
	var middle := _swing(_pitch(Vector2(0.0, 0.8), 0.0), SwingIntent.Type.CONTACT, 0.0)
	var corner := ContactResolver.resolve(_fixed_pitch(Vector2(0.26, 1.1)), SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0), tuning(), MatchRng.new(7))
	var chase := ContactResolver.resolve(_fixed_pitch(Vector2(0.7, 0.8)), SwingIntent.swing(SwingIntent.Type.CONTACT, 0.0), tuning(), MatchRng.new(7))
	check(middle.quality > corner.quality + 0.1, "corner is harder (%.2f vs %.2f)" % [middle.quality, corner.quality])
	check_eq(chase.outcome, ContactResult.Outcome.WHIFF, "way outside is out of reach")
	var power_corner := ContactResolver.resolve(_fixed_pitch(Vector2(0.26, 1.1)), SwingIntent.swing(SwingIntent.Type.POWER, 0.0), tuning(), MatchRng.new(7))
	check(power_corner.quality < corner.quality, "power covers the corners worse")


func _fixed_pitch(location: Vector2) -> PitchResult:
	var p := _pitch(Vector2(0.0, 0.8), 0.0)
	p.location = location
	p.in_zone = PitchResolver.in_zone(location, tuning())
	return p


func test_wild_miss_is_whiff_near_miss_is_foul() -> void:
	var p := _pitch(Vector2(0.0, 0.8), 0.0)
	check_eq(_swing(p, SwingIntent.Type.CONTACT, 0.4).outcome, ContactResult.Outcome.WHIFF, "way late whiffs")
	var near := _swing(p, SwingIntent.Type.CONTACT, tuning().contact_timing_window * 1.3)
	check_eq(near.outcome, ContactResult.Outcome.FOUL, "just late fouls off")
	check_eq(ContactResolver.call_for(p, near), MatchState.PitchCall.FOUL)
