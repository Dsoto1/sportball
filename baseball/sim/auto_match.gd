class_name AutoMatch
extends RefCounted
## Plays a full AI-vs-AI match through the same resolvers the interactive
## game uses, with no scene loaded. Used by tests and the feel report.

var state: MatchState
var rng: MatchRng
var content: ContentLibrary
var stats := {
	"pitches": 0, "in_zone": 0, "swings": 0, "whiffs": 0, "fouls": 0, "balls_in_play": 0,
	"hits": 0, "home_runs": 0, "strikeouts": 0, "walks": 0, "dives": 0, "air_outs": 0,
	"ground_outs": 0, "double_plays": 0, "errors": 0, "dive_misses": 0, "plate_appearances": 0, "exit_velocity_sum": 0.0,
}
var outcome_counts := {}


func _init(p_seed: int, p_content: ContentLibrary) -> void:
	content = p_content
	rng = MatchRng.new(p_seed)
	state = MatchState.new(
		MatchState.placeholder_lineup("away"),
		MatchState.placeholder_lineup("home"),
		content.tuning.innings)


static func play(p_seed: int, p_content: ContentLibrary) -> AutoMatch:
	var sim := AutoMatch.new(p_seed, p_content)
	sim.run()
	return sim


func run() -> void:
	var tuning := content.tuning
	while not state.game_over and stats["pitches"] < tuning.max_pitches_per_match:
		play_pitch()
	_tally_plate_appearances()


func play_pitch() -> void:
	var tuning := content.tuning
	var intent := AiPitcher.choose(state, content.pitches, tuning, rng)
	var family := content.pitch(intent.family_id)
	var pitch := PitchResolver.resolve(intent, family, tuning, rng)
	state.record_pitch(pitch.to_dict())
	stats["pitches"] += 1
	if pitch.in_zone:
		stats["in_zone"] += 1
	var swing := AiBatter.decide(pitch, family, state, tuning, rng)
	var contact := ContactResolver.resolve(pitch, swing, tuning, rng)
	if swing.type != SwingIntent.Type.NONE:
		stats["swings"] += 1
	match contact.outcome:
		ContactResult.Outcome.WHIFF:
			stats["whiffs"] += 1
		ContactResult.Outcome.FOUL:
			stats["fouls"] += 1
	if contact.outcome != ContactResult.Outcome.IN_PLAY:
		state.apply_pitch_call(ContactResolver.call_for(pitch, contact))
		return
	var bip := BallInPlay.create(contact, state, tuning)
	var outcome := bip.resolve_ai(rng)
	_count_outcome(bip, outcome)
	state.apply_play(outcome)


func _tally_plate_appearances() -> void:
	for event in state.events:
		if event.type != DomainEvent.PLATE_APPEARANCE_ENDED:
			continue
		stats["plate_appearances"] += 1
		match event.data["result"]:
			&"strikeout":
				stats["strikeouts"] += 1
			&"walk":
				stats["walks"] += 1


func _count_outcome(bip: BallInPlay, outcome: PlayOutcome) -> void:
	stats["balls_in_play"] += 1
	stats["exit_velocity_sum"] += bip.contact.exit_velocity
	outcome_counts[outcome.kind] = outcome_counts.get(outcome.kind, 0) + 1
	if outcome.is_hit():
		stats["hits"] += 1
	if outcome.kind == PlayOutcome.KIND_HOME_RUN:
		stats["home_runs"] += 1
	if bip.fielding.is_dive:
		stats["dives"] += 1
	if bip.fielding.caught_in_air and not outcome.errors.any(func(e: Dictionary) -> bool: return e["type"] == "dive_miss"):
		stats["air_outs"] += 1
	if outcome.kind == PlayOutcome.KIND_GROUND_OUT:
		stats["ground_outs"] += 1
	if outcome.outs.size() >= 2:
		stats["double_plays"] += 1
	for e in outcome.errors:
		stats["dive_misses" if e["type"] == "dive_miss" else "errors"] += 1
