class_name AiPitcher
extends RefCounted
## Produces a PitchIntent the same shape a human produces.


## profile: the fielding team's AI personality; pitcher: who is throwing
## (limits the repertoire). Either may be null.
static func choose(state: MatchState, pitches: Array[PitchFamilyDef], tuning: BaseballTuning, rng: MatchRng,
		profile: TeamDef = null, pitcher: PlayerDef = null) -> PitchIntent:
	var repertoire := pitches
	if pitcher != null:
		repertoire = pitches.filter(func(f: PitchFamilyDef) -> bool: return pitcher.pitches.has(f.id))
		if repertoire.is_empty():
			repertoire = pitches
	var family := repertoire[rng.pick_index(repertoire.size())]
	var center := PitchResolver.zone_center(tuning)
	var half := Vector2(tuning.zone_half_width, (tuning.zone_top - tuning.zone_bottom) * 0.5)
	# Ahead in the count: work the edges. Behind: come into the zone.
	var edge := tuning.ai_pitcher_edge_bias * (profile.edge_bias_scale if profile != null else 1.0)
	if state.balls >= 3 or state.balls - state.strikes >= 2:
		edge *= 0.65
	elif state.strikes == 2 and state.balls < 2:
		edge *= 1.15
	var aim := center + Vector2(
		rng.randf_range(-1.0, 1.0) * half.x * edge,
		rng.randf_range(-1.0, 1.0) * half.y * edge)
	var error := absf(rng.randfn(0.0, tuning.ai_pitcher_meter_sigma))
	return PitchIntent.new(family.id, aim, error)
