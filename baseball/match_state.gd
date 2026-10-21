class_name MatchState
extends RefCounted
## Authoritative record of a match: inning/half, outs, count, score, bases
## and batting order, plus who is in the game: each team's defense,
## pitcher, substitutions and pitch counts. Scenes present this state; they
## never own it. The rules package (MatchRules) sets counts, innings, the
## mercy rule and the extra-innings runner.

## FOUL_BUNT is a strike even with two strikes (a strikeout).
enum PitchCall { BALL, CALLED_STRIKE, SWINGING_STRIKE, FOUL, FOUL_BUNT }

const AWAY := 0
const HOME := 1
const OUTS_PER_HALF := 3

var rules: MatchRules
var innings_scheduled: int
var inning: int = 1
var is_top: bool = true
var outs: int = 0
var balls: int = 0
var strikes: int = 0
var score: Array[int] = [0, 0]
## Occupants of 1st, 2nd, 3rd (&"" = empty).
var bases: Array[StringName] = [&"", &"", &""]
var lineups: Array = [[], []]
var lineup_index: Array[int] = [0, 0]
## Runs per half inning, per team.
var line_score: Array = [[], []]
var game_over: bool = false
var pitch_count: int = 0
var events: Array[DomainEvent] = []
## Per team: field position -> player id (&"p" is the pitcher). Empty for
## placeholder lineups (tests and old sims), which have no named defense.
var defense: Array = [{}, {}]
## Pitches thrown by each pitcher id.
var pitches_by: Dictionary = {}
## Player ids that have left the game (no re-entry under the rules).
var removed: Dictionary = {}
var hits: Array[int] = [0, 0]
## Errors charged to each team's defense.
var errors: Array[int] = [0, 0]

var _next_sequence: int = 0
var _half_runs: int = 0


## p_rules: a MatchRules, or an innings count for classic rules.
func _init(away_lineup: Array[StringName], home_lineup: Array[StringName], p_rules: Variant) -> void:
	assert(not away_lineup.is_empty() and not home_lineup.is_empty())
	lineups = [away_lineup.duplicate(), home_lineup.duplicate()]
	rules = p_rules if p_rules is MatchRules else MatchRules.classic(int(p_rules))
	innings_scheduled = rules.innings


## A match between two clubs with their default lineups and defenses.
static func from_teams(away: TeamDef, home: TeamDef, p_rules: MatchRules) -> MatchState:
	var state := MatchState.new(away.batting_order, home.batting_order, p_rules)
	for team in [AWAY, HOME]:
		var def: TeamDef = away if team == AWAY else home
		var spots := {}
		for i in def.batting_order.size():
			if def.lineup_positions[i] != &"dh":
				spots[def.lineup_positions[i]] = def.batting_order[i]
		spots[&"p"] = def.starting_pitcher
		state.defense[team] = spots
	return state


static func placeholder_lineup(prefix: String, size: int = 9) -> Array[StringName]:
	var ids: Array[StringName] = []
	for i in size:
		ids.append(StringName("%s_%02d" % [prefix, i + 1]))
	return ids


func batting_team() -> int:
	return AWAY if is_top else HOME


func fielding_team() -> int:
	return HOME if is_top else AWAY


func current_batter() -> StringName:
	var team := batting_team()
	return lineups[team][lineup_index[team]]


## Current pitcher of a team (&"" for placeholder lineups).
func pitcher(team: int) -> StringName:
	return defense[team].get(&"p", &"")


func pitches_thrown(pitcher_id: StringName) -> int:
	return pitches_by.get(pitcher_id, 0)


## Players of `team` currently in the game (lineup and pitcher).
func in_game(team: int) -> Array[StringName]:
	var list: Array[StringName] = []
	list.assign(lineups[team])
	for id: StringName in defense[team].values():
		if not list.has(id):
			list.append(id)
	return list


## Can `in_id` replace `out_id` for `team` right now?
func can_substitute(team: int, out_id: StringName, in_id: StringName) -> bool:
	if game_over or out_id == in_id or in_id == &"":
		return false
	if rules.no_reentry and removed.has(in_id):
		return false
	var current := in_game(team)
	return current.has(out_id) and not current.has(in_id)


## Replaces a player: the newcomer takes his lineup slot and his position.
## A pitching change is substitute(team, pitcher(team), reliever).
func substitute(team: int, out_id: StringName, in_id: StringName) -> bool:
	if not can_substitute(team, out_id, in_id):
		return false
	var slot: int = lineups[team].find(out_id)
	if slot >= 0:
		lineups[team][slot] = in_id
	var position: StringName = &""
	for pos: StringName in defense[team]:
		if defense[team][pos] == out_id:
			position = pos
	if position != &"":
		defense[team][position] = in_id
	for i in bases.size():
		if bases[i] == out_id:
			bases[i] = in_id  # pinch runner
	removed[out_id] = true
	emit(DomainEvent.SUBSTITUTION, {"team": team, "out": out_id, "in": in_id, "position": position, "slot": slot})
	return true


func runner_on(base: int) -> StringName:
	return bases[base - 1]


func winner() -> int:
	if not game_over or score[AWAY] == score[HOME]:
		return -1
	return HOME if score[HOME] > score[AWAY] else AWAY


func emit(type: StringName, data: Dictionary = {}) -> DomainEvent:
	var event := DomainEvent.new(_next_sequence, type, data)
	_next_sequence += 1
	events.append(event)
	return event


func record_pitch(data: Dictionary) -> void:
	pitch_count += 1
	var p := pitcher(fielding_team())
	if p != &"":
		pitches_by[p] = pitches_by.get(p, 0) + 1
	emit(DomainEvent.PITCH_THROWN, data)


## Applies a pitch that did not put the ball in play.
func apply_pitch_call(call: PitchCall) -> void:
	if game_over:
		return
	emit(DomainEvent.PITCH_CALLED, {"call": call, "batter": current_batter()})
	match call:
		PitchCall.BALL:
			balls += 1
			if balls >= rules.balls_for_walk:
				_walk()
		PitchCall.CALLED_STRIKE, PitchCall.SWINGING_STRIKE, PitchCall.FOUL_BUNT:
			strikes += 1
			if strikes >= rules.strikes_for_out:
				var batter := current_batter()
				_end_plate_appearance(&"strikeout")
				_record_out(batter, FieldLayout.HOME, &"strikeout")
		PitchCall.FOUL:
			if strikes < rules.strikes_for_out - 1:
				strikes += 1


## Applies a resolved ball in play.
func apply_play(outcome: PlayOutcome) -> void:
	if game_over:
		return
	emit(DomainEvent.BALL_CONTACTED, {"batter": outcome.batter_id, "kind": outcome.kind})
	if outcome.is_hit():
		hits[batting_team()] += 1
	for e in outcome.errors:
		if e["type"] != "dive_miss":
			errors[fielding_team()] += 1
	for advance in outcome.advances:
		if advance["safe"] and advance["to"] != advance["from"]:
			emit(DomainEvent.RUNNER_ADVANCED, advance)
	for runner in outcome.runs:
		_score_run(runner)
		if game_over and outcome.kind != PlayOutcome.KIND_HOME_RUN:
			# Walk-off (or mercy): only the deciding run counts unless it left the park.
			_end_plate_appearance(outcome.kind)
			return
	_end_plate_appearance(outcome.kind)
	bases = outcome.final_bases.duplicate()
	for out in outcome.outs:
		_record_out(out["runner_id"], out["base"], out["kind"])
		if outs == 0:
			break  # the half inning ended


## Applies a stolen-base play between pitches: the count and batter stay.
func apply_steal(outcome: PlayOutcome) -> void:
	if game_over:
		return
	for advance in outcome.advances:
		if advance["safe"] and advance["to"] > advance["from"]:
			emit(DomainEvent.STOLEN_BASE, advance)
	for runner in outcome.runs:
		_score_run(runner)
		if game_over:
			return
	bases = outcome.final_bases.duplicate()
	for out in outcome.outs:
		emit(DomainEvent.CAUGHT_STEALING, {"runner": out["runner_id"], "base": out["base"]})
		_record_out(out["runner_id"], out["base"], &"caught_stealing")
		if outs == 0:
			break


func snapshot() -> Dictionary:
	return {
		"inning": inning,
		"half": "top" if is_top else "bottom",
		"outs": outs,
		"balls": balls,
		"strikes": strikes,
		"score": score.duplicate(),
		"bases": bases.duplicate(),
		"batter": current_batter(),
		"game_over": game_over,
	}


func _walk() -> void:
	var batter := current_batter()
	if bases[0] != &"":
		if bases[1] != &"":
			if bases[2] != &"":
				_score_run(bases[2])
			bases[2] = bases[1]
		bases[1] = bases[0]
	bases[0] = batter
	_end_plate_appearance(&"walk")


func _score_run(runner: StringName) -> void:
	if game_over:
		return
	var team := batting_team()
	score[team] += 1
	_half_runs += 1
	emit(DomainEvent.RUN_SCORED, {"runner": runner, "team": team, "score": score.duplicate()})
	if not is_top and inning >= innings_scheduled and score[HOME] > score[AWAY]:
		_finish_game(&"walk_off")
	elif not is_top and _mercy_inning() and score[HOME] - score[AWAY] >= rules.mercy_runs:
		_finish_game(&"mercy")


func _record_out(runner: StringName, base: int, kind: StringName) -> void:
	if game_over:
		return
	outs += 1
	emit(DomainEvent.OUT_RECORDED, {"runner": runner, "base": base, "kind": kind, "outs": outs})
	if outs >= OUTS_PER_HALF:
		_end_half()


func _end_plate_appearance(result: StringName) -> void:
	var team := batting_team()
	emit(DomainEvent.PLATE_APPEARANCE_ENDED, {"batter": current_batter(), "result": result})
	balls = 0
	strikes = 0
	lineup_index[team] = (lineup_index[team] + 1) % lineups[team].size()


func _end_half() -> void:
	line_score[batting_team()].append(_half_runs)
	emit(DomainEvent.HALF_INNING_ENDED, {"inning": inning, "top": is_top, "runs": _half_runs})
	_half_runs = 0
	outs = 0
	balls = 0
	strikes = 0
	bases = [&"", &"", &""]
	var last_scheduled := inning >= innings_scheduled
	var lead := score[HOME] - score[AWAY]
	if is_top:
		if last_scheduled and lead > 0:
			_finish_game(&"home_leads")
			return
		if _mercy_inning() and lead >= rules.mercy_runs:
			_finish_game(&"mercy")
			return
		is_top = false
	else:
		if last_scheduled and lead != 0:
			_finish_game(&"regulation")
			return
		if _mercy_inning() and absi(lead) >= rules.mercy_runs:
			_finish_game(&"mercy")
			return
		inning += 1
		is_top = true
	if inning > innings_scheduled and rules.extras_runner_on_second:
		# Extra innings start with the previous batter on second.
		var team := batting_team()
		var size: int = lineups[team].size()
		var runner: StringName = lineups[team][(lineup_index[team] + size - 1) % size]
		bases[1] = runner
		emit(DomainEvent.RUNNER_PLACED, {"runner": runner, "base": 2})


func _mercy_inning() -> bool:
	return rules.mercy_runs > 0 and inning >= rules.mercy_after_inning


func _finish_game(reason: StringName) -> void:
	# Mid-half endings have not closed their line-score entry yet.
	if reason == &"walk_off" or (reason == &"mercy" and _half_runs > 0):
		line_score[batting_team()].append(_half_runs)
	game_over = true
	emit(DomainEvent.GAME_ENDED, {"reason": reason, "score": score.duplicate(), "inning": inning})
