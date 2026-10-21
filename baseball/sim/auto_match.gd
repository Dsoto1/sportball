class_name AutoMatch
extends RefCounted
## Plays a full AI-vs-AI match through the same resolvers the interactive
## game uses, with no scene loaded. Used by tests and the feel report.

var state: MatchState
var rng: MatchRng
var content: ContentLibrary
## Null for a placeholder match (league-average players, classic rules).
var roster: MatchRoster
## Tuning for this match, carrying the park's field shape.
var tuning: BaseballTuning
var park: StadiumDef
var stats := {
	"pitches": 0, "in_zone": 0, "swings": 0, "whiffs": 0, "fouls": 0, "balls_in_play": 0,
	"hits": 0, "home_runs": 0, "strikeouts": 0, "walks": 0, "dives": 0, "air_outs": 0,
	"ground_outs": 0, "double_plays": 0, "errors": 0, "dive_misses": 0, "pitching_changes": 0, "steals": 0, "caught_stealing": 0, "sacrifices": 0, "bunts": 0, "pickoffs": 0, "picked_off": 0, "slide_steps": 0, "plate_appearances": 0, "exit_velocity_sum": 0.0,
}
var outcome_counts := {}


## away/home: team ids from the content library, or &"" for a placeholder
## match with classic rules.
## park_id: where it is played (&"" = the home team's park).
func _init(p_seed: int, p_content: ContentLibrary, away: StringName = &"gearheads", home: StringName = &"glitterati", park_id: StringName = &"") -> void:
	content = p_content
	rng = MatchRng.new(p_seed)
	park = content.park(park_id)
	if park == null and home != &"":
		park = content.team(home).stadium_def
	tuning = content.tuning_for(park)
	if away == &"" or home == &"":
		state = MatchState.new(
			MatchState.placeholder_lineup("away"),
			MatchState.placeholder_lineup("home"),
			tuning.innings)
	else:
		roster = MatchRoster.new(content.team(away), content.team(home))
		state = MatchState.from_teams(roster.teams[0], roster.teams[1], content.rules)


static func play(p_seed: int, p_content: ContentLibrary, away: StringName = &"gearheads", home: StringName = &"glitterati", park_id: StringName = &"") -> AutoMatch:
	var sim := AutoMatch.new(p_seed, p_content, away, home, park_id)
	sim.run()
	return sim


func run() -> void:
	while not state.game_over and stats["pitches"] < tuning.max_pitches_per_match:
		play_pitch()
	_tally_plate_appearances()


func play_pitch() -> void:
	var reliever := AiManager.pitching_change(state, roster, tuning)
	if reliever != &"" and state.substitute(state.fielding_team(), state.pitcher(state.fielding_team()), reliever):
		stats["pitching_changes"] += 1
	var defense_club := roster.teams[state.fielding_team()] if roster != null else null
	var offense_club := roster.teams[state.batting_team()] if roster != null else null
	var pitcher := roster.player(state.pitcher(state.fielding_team())) if roster != null else null
	var batter := roster.player(state.current_batter()) if roster != null else null
	var intent := AiPitcher.choose(state, content.pitches, tuning, rng, defense_club, pitcher, batter)
	var family := content.pitch(intent.family_id)
	var mods := Ratings.pitcher_mods(pitcher, state.pitches_thrown(state.pitcher(state.fielding_team())), tuning)
	var steals := AiManager.steal_attempts(state, roster, tuning, rng)
	var pick := AiManager.pickoff_choice(state, roster, tuning, rng, steals)
	if pick > 0:
		_run_pickoff(pick, steals.has(pick))
		return  # no pitch this time
	intent.slide_step = AiManager.slide_step(state, roster, tuning, rng, steals)
	if intent.slide_step:
		stats["slide_steps"] += 1
	var pitch := PitchResolver.resolve(intent, family, tuning, rng, mods)
	state.record_pitch(pitch.to_dict())
	stats["pitches"] += 1
	if pitch.in_zone:
		stats["in_zone"] += 1
	var swing := AiBatter.decide(pitch, family, state, tuning, rng, offense_club, batter)
	var contact := ContactResolver.resolve(pitch, swing, tuning, rng)
	if swing.type != SwingIntent.Type.NONE:
		stats["swings"] += 1
	match contact.outcome:
		ContactResult.Outcome.WHIFF:
			stats["whiffs"] += 1
		ContactResult.Outcome.FOUL:
			stats["fouls"] += 1
	if swing.type == SwingIntent.Type.BUNT:
		stats["bunts"] += 1
	if contact.outcome != ContactResult.Outcome.IN_PLAY:
		var bases_before := state.bases.duplicate()
		state.apply_pitch_call(ContactResolver.call_for(pitch, contact))
		if contact.outcome != ContactResult.Outcome.FOUL:
			_run_steal(steals, bases_before, pitch.travel_time, pitch.slide_step)
		return
	var bip := BallInPlay.create(contact, state, tuning, roster)
	var outcome: PlayOutcome
	if bip.is_home_run():
		outcome = bip.resolve_ai(rng)
	else:
		var live := bip.start_live(true, rng)
		for base: int in steals:
			live.set_running_start(base, steal_head(state.bases[base - 1], pitch.travel_time, steals[base], pitch.slide_step))
		outcome = live.run_ai(tuning.sim_play_step)
	_count_outcome(bip, outcome)
	state.apply_play(outcome)


## Runners who were going keep going after a pitch not put in play, if the
## pitch left them where they were (no walk, no third out).
func _run_steal(steals: Dictionary, bases_before: Array[StringName], travel: float, slide_step: bool = false) -> void:
	var still := {}
	for base: int in steals:
		if bases_before[base - 1] != &"" and state.bases[base - 1] == bases_before[base - 1]:
			still[base] = steals[base]
	if still.is_empty():
		return
	var bip := BallInPlay.create_steal(state, tuning, roster, still, travel, slide_step)
	if bip == null:
		return
	var outcome := bip.resolve_ai(rng)
	stats["steals"] += outcome.advances.filter(func(a: Dictionary) -> bool: return bip.steal_heads.has(a["from"]) and a["safe"] and a["to"] > a["from"]).size()
	stats["caught_stealing"] += outcome.outs.size()
	state.apply_steal(outcome)


func _run_pickoff(base: int, leaning: bool) -> void:
	var bip := BallInPlay.create_pickoff(state, tuning, roster, base, leaning, rng)
	if bip == null:
		return
	state.record_pickoff_attempt(state.runner_on(base), tuning.pickoff_lead_shrink)
	var outcome := bip.resolve_ai(rng)
	stats["pickoffs"] += 1
	stats["picked_off"] += outcome.outs.size()
	state.apply_pickoff(outcome)


func steal_head(runner_id: StringName, travel: float, jump: float, slide_step: bool = false) -> float:
	var p := roster.player(runner_id) if roster != null else null
	return LivePlay.steal_head_start(Ratings.runner_speed(p, tuning), travel, jump, tuning,
		BallInPlay.lead_for(state, runner_id, tuning), slide_step)


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
	if outcome.kind == PlayOutcome.KIND_SACRIFICE:
		stats["sacrifices"] += 1
	for e in outcome.errors:
		stats["dive_misses" if e["type"] == "dive_miss" else "errors"] += 1
