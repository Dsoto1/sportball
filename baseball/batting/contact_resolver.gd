class_name ContactResolver
extends RefCounted
## Timing-first contact. The bat finds the pitch's height automatically.
## Timing sets quality and pull/push; pitch location costs quality the
## farther it is from the heart of the zone (chasing is punished); the
## stick at the swing nudges spray and loft. Mishits scatter more.
## Power trades a smaller timing window and worse coverage for speed.


static func resolve(pitch: PitchResult, swing: SwingIntent, tuning: BaseballTuning, rng: MatchRng) -> ContactResult:
	var result := ContactResult.new()
	result.swing_type = swing.type
	if swing.type == SwingIntent.Type.NONE:
		result.outcome = ContactResult.Outcome.TAKE
		return result

	var power := swing.type == SwingIntent.Type.POWER
	var window := (tuning.power_timing_window if power else tuning.contact_timing_window) * swing.window_scale
	result.timing_offset = swing.timing_offset
	result.timing_norm = swing.timing_offset / window
	result.location_norm = location_norm(pitch.location, tuning)

	var t_abs := absf(result.timing_norm)
	if t_abs > 1.0 or result.location_norm > tuning.reach_limit:
		var foul := t_abs <= tuning.foul_timing_band and result.location_norm <= tuning.reach_limit
		result.outcome = ContactResult.Outcome.FOUL if foul else ContactResult.Outcome.WHIFF
		return result

	var coverage := maxf(result.location_norm - tuning.sweet_zone, 0.0) * tuning.location_penalty
	if power:
		coverage *= tuning.power_location_penalty_scale
	var error := sqrt(t_abs * t_abs * tuning.timing_weight + coverage * coverage)
	result.quality = clampf(1.0 - error, 0.0, 1.0)
	var ev_max := (tuning.power_exit_velocity_max if power else tuning.contact_exit_velocity_max) * swing.power_scale
	result.exit_velocity = lerpf(tuning.exit_velocity_min, ev_max, pow(result.quality, tuning.exit_velocity_curve))

	var miss := 1.0 - result.quality
	var center := PitchResolver.zone_center(tuning)
	var height := (pitch.location.y - center.y) / ((tuning.zone_top - tuning.zone_bottom) * 0.5)
	var base_launch := tuning.power_base_launch if power else tuning.contact_base_launch
	var launch := base_launch + swing.stick.y * tuning.stick_lift + height * tuning.launch_per_height
	launch += rng.randfn(0.0, tuning.launch_noise + miss * tuning.mishit_launch_spread)
	result.launch_angle = clampf(launch, -25.0, 80.0)

	# Early swings pull the ball. A right-handed batter pulls to left field (-).
	var hand := -1.0 if swing.bats_left else 1.0
	var spray := result.timing_norm * tuning.spray_per_timing * hand
	spray += pitch.location.x / tuning.zone_half_width * tuning.spray_per_location
	spray += swing.stick.x * tuning.stick_spray
	spray += rng.randfn(0.0, tuning.spray_noise + miss * tuning.mishit_spray_spread)
	result.spray_angle = spray

	if result.quality < tuning.min_fair_quality or not FieldLayout.is_fair_angle(spray, tuning):
		result.outcome = ContactResult.Outcome.FOUL
	else:
		result.outcome = ContactResult.Outcome.IN_PLAY
	return result


## Distance of a pitch from the zone center in zone half-sizes:
## 0 = middle-middle, 1 = on an edge, sqrt(2) = a corner.
static func location_norm(location: Vector2, tuning: BaseballTuning) -> float:
	var center := PitchResolver.zone_center(tuning)
	var half := Vector2(tuning.zone_half_width, (tuning.zone_top - tuning.zone_bottom) * 0.5)
	return Vector2((location.x - center.x) / half.x, (location.y - center.y) / half.y).length()


## Pitch call for anything that is not a ball in play; -1 for in play.
static func call_for(pitch: PitchResult, contact: ContactResult) -> int:
	match contact.outcome:
		ContactResult.Outcome.TAKE:
			return MatchState.PitchCall.CALLED_STRIKE if pitch.in_zone else MatchState.PitchCall.BALL
		ContactResult.Outcome.WHIFF:
			return MatchState.PitchCall.SWINGING_STRIKE
		ContactResult.Outcome.FOUL:
			return MatchState.PitchCall.FOUL
	return -1
