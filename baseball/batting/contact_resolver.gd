class_name ContactResolver
extends RefCounted
## Turns a swing against a pitch into contact values (exit velocity, launch
## angle, spray). Timing drives spray, vertical bat error drives launch,
## overall error drives quality. Power trades a smaller window for speed.


static func resolve(pitch: PitchResult, swing: SwingIntent, tuning: BaseballTuning, rng: MatchRng) -> ContactResult:
	var result := ContactResult.new()
	result.swing_type = swing.type
	if swing.type == SwingIntent.Type.NONE:
		result.outcome = ContactResult.Outcome.TAKE
		return result

	var power := swing.type == SwingIntent.Type.POWER
	var window := tuning.power_timing_window if power else tuning.contact_timing_window
	var radius := tuning.power_radius if power else tuning.contact_radius
	result.timing_offset = swing.timing_offset
	result.timing_norm = swing.timing_offset / window
	result.location_error = pitch.location - swing.cursor
	result.location_norm = result.location_error.length() / radius

	var t_abs := absf(result.timing_norm)
	if t_abs > 1.0 or result.location_norm > 1.0:
		var foul := t_abs <= tuning.foul_timing_band and result.location_norm <= tuning.foul_location_band
		result.outcome = ContactResult.Outcome.FOUL if foul else ContactResult.Outcome.WHIFF
		return result

	var error := sqrt(0.5 * t_abs * t_abs + 0.5 * result.location_norm * result.location_norm)
	result.quality = clampf(1.0 - error, 0.0, 1.0)
	var ev_max := tuning.power_exit_velocity_max if power else tuning.contact_exit_velocity_max
	result.exit_velocity = lerpf(tuning.exit_velocity_min, ev_max, pow(result.quality, tuning.exit_velocity_curve))

	# Ball above the bat's sweet spot means the bat got under it: lift.
	var vertical := result.location_error.y / radius
	var base_launch := tuning.power_base_launch if power else tuning.contact_base_launch
	result.launch_angle = clampf(base_launch + vertical * tuning.launch_spread + rng.randfn(0.0, tuning.launch_noise), -25.0, 80.0)

	# Early swings pull the ball. A right-handed batter pulls to left field (-).
	var hand := -1.0 if swing.bats_left else 1.0
	var spray := result.timing_norm * tuning.spray_per_timing * hand
	spray += pitch.location.x / tuning.zone_half_width * tuning.spray_per_location
	spray += rng.randfn(0.0, tuning.spray_noise)
	result.spray_angle = spray

	if result.quality < tuning.min_fair_quality or not FieldLayout.is_fair_angle(spray, tuning):
		result.outcome = ContactResult.Outcome.FOUL
	else:
		result.outcome = ContactResult.Outcome.IN_PLAY
	return result


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
