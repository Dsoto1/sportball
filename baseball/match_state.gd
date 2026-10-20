class_name MatchState
extends RefCounted
## Authoritative record of a match: inning/half, outs, count, score, bases
## and batting order. Scenes present this state; they never own it.
## Counts per out/walk/strikeout are rules of baseball and live here as
## constants. Format choices (innings) are passed in.

enum PitchCall { BALL, CALLED_STRIKE, SWINGING_STRIKE, FOUL }

const AWAY := 0
const HOME := 1
const BALLS_FOR_WALK := 4
const STRIKES_FOR_OUT := 3
const OUTS_PER_HALF := 3

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

var _next_sequence: int = 0
var _half_runs: int = 0


func _init(away_lineup: Array[StringName], home_lineup: Array[StringName], p_innings: int) -> void:
	assert(not away_lineup.is_empty() and not home_lineup.is_empty())
	lineups = [away_lineup.duplicate(), home_lineup.duplicate()]
	innings_scheduled = p_innings


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
	emit(DomainEvent.PITCH_THROWN, data)


## Applies a pitch that did not put the ball in play.
func apply_pitch_call(call: PitchCall) -> void:
	if game_over:
		return
	emit(DomainEvent.PITCH_CALLED, {"call": call, "batter": current_batter()})
	match call:
		PitchCall.BALL:
			balls += 1
			if balls >= BALLS_FOR_WALK:
				_walk()
		PitchCall.CALLED_STRIKE, PitchCall.SWINGING_STRIKE:
			strikes += 1
			if strikes >= STRIKES_FOR_OUT:
				var batter := current_batter()
				_end_plate_appearance(&"strikeout")
				_record_out(batter, FieldLayout.HOME, &"strikeout")
		PitchCall.FOUL:
			if strikes < STRIKES_FOR_OUT - 1:
				strikes += 1


## Applies a resolved ball in play.
func apply_play(outcome: PlayOutcome) -> void:
	if game_over:
		return
	emit(DomainEvent.BALL_CONTACTED, {"batter": outcome.batter_id, "kind": outcome.kind})
	for advance in outcome.advances:
		if advance["safe"] and advance["to"] != advance["from"]:
			emit(DomainEvent.RUNNER_ADVANCED, advance)
	for runner in outcome.runs:
		_score_run(runner)
		if game_over and outcome.kind != PlayOutcome.KIND_HOME_RUN:
			# Walk-off: only the winning run counts unless it left the park.
			_end_plate_appearance(outcome.kind)
			return
	_end_plate_appearance(outcome.kind)
	bases = outcome.final_bases.duplicate()
	for out in outcome.outs:
		_record_out(out["runner_id"], out["base"], out["kind"])
		if outs == 0:
			break  # the half inning ended


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
	if is_top:
		if last_scheduled and score[HOME] > score[AWAY]:
			_finish_game(&"home_leads")
			return
		is_top = false
	else:
		if last_scheduled and score[HOME] != score[AWAY]:
			_finish_game(&"regulation")
			return
		inning += 1
		is_top = true


func _finish_game(reason: StringName) -> void:
	if reason == &"walk_off":
		line_score[batting_team()].append(_half_runs)
	game_over = true
	emit(DomainEvent.GAME_ENDED, {"reason": reason, "score": score.duplicate(), "inning": inning})
