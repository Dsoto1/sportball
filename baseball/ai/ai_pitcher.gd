class_name AiPitcher
extends RefCounted
## Produces a PitchIntent the same shape a human produces. Picks from the
## pitcher's repertoire by situation: fastballs when behind in the count,
## the nastier stuff when ahead, rarely the same pitch twice in a row,
## breaking balls to same-handed hitters and changeups/splitters to
## opposite-handed ones. Each pitch is located where it works best.

const MATCHUP_EDGE := 1.4


static func choose(state: MatchState, pitches: Array[PitchFamilyDef], tuning: BaseballTuning, rng: MatchRng,
		profile: TeamDef = null, pitcher: PlayerDef = null, batter: PlayerDef = null) -> PitchIntent:
	var repertoire := pitches
	if pitcher != null:
		repertoire = pitches.filter(func(f: PitchFamilyDef) -> bool: return pitcher.pitches.has(f.id))
		if repertoire.is_empty():
			repertoire = pitches
	var family := _pick(state, repertoire, rng, pitcher, batter)
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
		(rng.randf_range(-1.0, 1.0) * edge + family.aim_height * 0.6) * half.y)
	var error := absf(rng.randfn(0.0, tuning.ai_pitcher_meter_sigma))
	return PitchIntent.new(family.id, aim, error)


static func weight(f: PitchFamilyDef, state: MatchState, last: StringName, pitcher: PlayerDef, batter: PlayerDef) -> float:
	var w := f.usage
	var behind := state.balls >= 3 or state.balls - state.strikes >= 2
	var ahead := state.strikes > state.balls
	if behind:
		w *= 2.0 if f.category == &"fastball" else 0.55
	elif ahead:
		w *= 1.0 + f.deception * 1.6
	if f.id == last:
		w *= 0.55
	if pitcher != null and batter != null:
		var same := pitcher.throws == batter.bats
		if f.category == &"breaking":
			w *= MATCHUP_EDGE if same else 0.8
		elif f.category == &"offspeed":
			w *= MATCHUP_EDGE if not same else 0.85
	return w


static func _pick(state: MatchState, repertoire: Array[PitchFamilyDef], rng: MatchRng, pitcher: PlayerDef, batter: PlayerDef) -> PitchFamilyDef:
	var last := last_pitch(state)
	var weights: Array[float] = []
	var total := 0.0
	for f in repertoire:
		var w := weight(f, state, last, pitcher, batter)
		weights.append(w)
		total += w
	var roll := rng.randf() * total
	for i in repertoire.size():
		roll -= weights[i]
		if roll <= 0.0:
			return repertoire[i]
	return repertoire[repertoire.size() - 1]


## Family of the last pitch thrown in the game (&"" before the first).
static func last_pitch(state: MatchState) -> StringName:
	for i in range(state.events.size() - 1, -1, -1):
		var e := state.events[i]
		if e.type == DomainEvent.PITCH_THROWN:
			return e.data.get("family", &"")
	return &""
