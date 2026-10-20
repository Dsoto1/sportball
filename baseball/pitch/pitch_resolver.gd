class_name PitchResolver
extends RefCounted
## Turns a pitch intent into an authoritative pitch. Command (meter error)
## widens scatter; it does not roll dice on whether the pitch "works".


## mods: the pitcher's ratings and fatigue (Ratings.pitcher_mods); {} = average.
static func resolve(intent: PitchIntent, family: PitchFamilyDef, tuning: BaseballTuning, rng: MatchRng, mods: Dictionary = {}) -> PitchResult:
	var result := PitchResult.new()
	result.family_id = family.id
	result.aim = intent.aim
	result.meter_error = intent.meter_error
	var sigma: float = lerpf(tuning.pitch_scatter_min, tuning.pitch_scatter_max, intent.meter_error) * family.scatter_scale * mods.get("scatter", 1.0)
	var offset := Vector2(rng.randfn(0.0, sigma), rng.randfn(0.0, sigma))
	var center := zone_center(tuning)
	var location := intent.aim + offset
	location.x = clampf(location.x, -tuning.wild_limit.x, tuning.wild_limit.x)
	location.y = clampf(location.y, center.y - tuning.wild_limit.y, center.y + tuning.wild_limit.y)
	location.y = maxf(location.y, 0.05)
	result.location = location
	result.speed = family.speed * intent.speed_scale * mods.get("speed", 1.0) * lerpf(1.0, tuning.pitch_speed_at_max_error, intent.meter_error)
	result.release_point = Vector3(tuning.release_side, tuning.release_height, -tuning.release_distance)
	result.travel_time = result.release_point.distance_to(Vector3(location.x, location.y, 0.0)) / result.speed
	result.in_zone = in_zone(location, tuning)
	result.break_amount = family.break_amount * mods.get("break", 1.0)
	result.deception = maxf(family.deception + mods.get("deception", 0.0), 0.0)
	return result


static func in_zone(location: Vector2, tuning: BaseballTuning) -> bool:
	return absf(location.x) <= tuning.zone_half_width \
		and location.y >= tuning.zone_bottom \
		and location.y <= tuning.zone_top


static func zone_center(tuning: BaseballTuning) -> Vector2:
	return Vector2(0.0, (tuning.zone_bottom + tuning.zone_top) * 0.5)


## Converts a meter position (0..1) into a meter error (0 = perfect).
static func meter_error(meter_value: float, tuning: BaseballTuning) -> float:
	var sweet := tuning.pitch_meter_sweet_spot
	if meter_value <= sweet:
		return clampf((sweet - meter_value) / sweet, 0.0, 1.0)
	# The overshoot side is a narrow band: steeper per unit, capped at half error.
	return clampf((meter_value - sweet) / (1.0 - sweet) * 0.5, 0.0, 1.0)
