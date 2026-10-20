class_name AiBatter
extends RefCounted
## Reads a pitch with noise and produces a SwingIntent like a human would.


static func decide(pitch: PitchResult, family: PitchFamilyDef, state: MatchState, tuning: BaseballTuning, rng: MatchRng) -> SwingIntent:
	var fooled := 1.0 + family.deception
	var read := pitch.location + Vector2(
		rng.randfn(0.0, tuning.ai_batter_read_sigma * fooled),
		rng.randfn(0.0, tuning.ai_batter_read_sigma * fooled))
	var looks_strike := PitchResolver.in_zone(read, tuning)
	var swing_chance := tuning.ai_swing_in_zone if looks_strike else tuning.ai_swing_chase
	if state.strikes == 2:
		swing_chance += tuning.ai_two_strike_protect
	elif state.balls == 0 and state.strikes == 0:
		swing_chance *= tuning.ai_first_pitch_patience
	if state.balls == 3 and state.strikes < 2 and not looks_strike:
		swing_chance *= 0.5
	if not rng.chance(swing_chance):
		return SwingIntent.take()
	var power := state.strikes < 2 and rng.chance(tuning.ai_power_swing_rate)
	var type := SwingIntent.Type.POWER if power else SwingIntent.Type.CONTACT
	var timing := rng.randfn(0.0, tuning.ai_batter_timing_sigma * fooled)
	var stick := Vector2(rng.randfn(0.0, tuning.ai_batter_stick_sigma), rng.randfn(0.0, tuning.ai_batter_stick_sigma))
	# Runner on third, fewer than two outs: try to lift it for a sacrifice fly.
	if state.runner_on(3) != &"" and state.outs < 2:
		stick.y += 0.5
	return SwingIntent.swing(type, timing, stick)
