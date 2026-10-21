class_name AiBatter
extends RefCounted
## Reads a pitch with noise and produces a SwingIntent like a human would.


## profile: the batting team's AI personality; batter: who is up. Either
## may be null (league-average defaults).
static func decide(pitch: PitchResult, family: PitchFamilyDef, state: MatchState, tuning: BaseballTuning, rng: MatchRng,
		profile: TeamDef = null, batter: PlayerDef = null) -> SwingIntent:
	var fooled := 1.0 + pitch.deception
	var eye := Ratings.eye_scale(batter, tuning)
	var read := pitch.location + Vector2(
		rng.randfn(0.0, tuning.ai_batter_read_sigma * fooled * eye),
		rng.randfn(0.0, tuning.ai_batter_read_sigma * fooled * eye))
	var looks_strike := PitchResolver.in_zone(read, tuning)
	var bunt := _bunt(state, tuning, rng, profile, batter, looks_strike)
	if bunt != null:
		return bunt
	var chase := tuning.ai_swing_chase * eye * (profile.chase_scale if profile != null else 1.0)
	var swing_chance := tuning.ai_swing_in_zone if looks_strike else chase
	if profile != null:
		swing_chance *= profile.swing_aggression
	if state.strikes == 2:
		swing_chance += tuning.ai_two_strike_protect
	elif state.balls == 0 and state.strikes == 0:
		swing_chance *= tuning.ai_first_pitch_patience
	if state.balls == 3 and state.strikes < 2 and not looks_strike:
		swing_chance *= 0.5
	if not rng.chance(swing_chance):
		return SwingIntent.take()
	var power_rate := profile.power_swing_rate if profile != null else tuning.ai_power_swing_rate
	if batter != null:
		power_rate *= 1.0 + Ratings.norm(batter.power) * 0.5  # sluggers sell out more
	var power := state.strikes < 2 and rng.chance(power_rate)
	var type := SwingIntent.Type.POWER if power else SwingIntent.Type.CONTACT
	var timing := rng.randfn(0.0, tuning.ai_batter_timing_sigma * fooled)
	var stick := Vector2(rng.randfn(0.0, tuning.ai_batter_stick_sigma), rng.randfn(0.0, tuning.ai_batter_stick_sigma))
	# Runner on third, fewer than two outs: try to lift it for a sacrifice fly.
	if state.runner_on(3) != &"" and state.outs < 2:
		stick.y += 0.5
	var swing := SwingIntent.swing(type, timing, stick)
	Ratings.apply_batter(swing, batter, tuning)
	return swing


## Sacrifice with a runner on first or second and fewer than two outs (weak
## hitters more), or bunt for a hit with a fast batter. Only on pitches that
## look like strikes; the stick places it.
static func _bunt(state: MatchState, tuning: BaseballTuning, rng: MatchRng, profile: TeamDef, batter: PlayerDef, looks_strike: bool) -> SwingIntent:
	if not looks_strike or state.strikes >= 2:
		return null
	var rate := profile.bunt_rate if profile != null else 1.0
	var power := Ratings.norm(batter.power) if batter != null else 0.0
	var on_first := state.runner_on(1) != &""
	var on_second := state.runner_on(2) != &""
	var aim := 0.0
	var chance := 0.0
	if state.outs < 2 and (on_first or on_second) and state.runner_on(3) == &"":
		chance = tuning.ai_sac_bunt_rate * rate * clampf(1.0 - power, 0.2, 1.5)
		aim = 0.6 if on_first and not on_second else -0.6  # make the corner man field it
	elif batter != null and batter.speed >= 75 and state.outs < 2:
		chance = tuning.ai_bunt_hit_rate * rate
		aim = -0.9  # down the third-base line
	if chance <= 0.0 or not rng.chance(chance):
		return null
	var timing := rng.randfn(0.0, tuning.ai_batter_timing_sigma * 0.6)
	var swing := SwingIntent.swing(SwingIntent.Type.BUNT, timing, Vector2(aim + rng.randfn(0.0, 0.2), 0.0))
	Ratings.apply_batter(swing, batter, tuning)
	return swing
