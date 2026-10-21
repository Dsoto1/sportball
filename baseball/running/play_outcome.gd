class_name PlayOutcome
extends RefCounted
## The authoritative result of one ball in play, ready for MatchState.

const KIND_HOME_RUN := &"home_run"
const KIND_SINGLE := &"single"
const KIND_DOUBLE := &"double"
const KIND_TRIPLE := &"triple"
const KIND_INSIDE_PARK_HR := &"inside_the_park_home_run"
const KIND_FLY_OUT := &"fly_out"
const KIND_LINE_OUT := &"line_out"
const KIND_POP_OUT := &"pop_out"
const KIND_GROUND_OUT := &"ground_out"
const KIND_FIELDERS_CHOICE := &"fielders_choice"
const KIND_DOUBLE_PLAY := &"double_play"
const KIND_TRIPLE_PLAY := &"triple_play"
## Batter bunted out on purpose and a runner moved up (not an at-bat).
const KIND_SACRIFICE := &"sacrifice"
## A stolen-base play between pitches (no batter involved).
const KIND_STEAL := &"steal"
## A pickoff throw between pitches.
const KIND_PICKOFF := &"pickoff"
## Batter safe only because of a bobble or a wild throw to first: not a hit.
const KIND_REACHED_ON_ERROR := &"reached_on_error"

const OUT_CATCH := &"catch"
const OUT_FORCE := &"force"
const OUT_TAG := &"tag"
## Runner who had not retouched after a catch, beaten back by the ball.
const OUT_DOUBLED_OFF := &"doubled_off"

var kind: StringName
var batter_id: StringName
## Runner ids whose runs count, in the order they crossed the plate.
var runs: Array[StringName] = []
## Each entry: {runner_id: StringName, base: int, kind: StringName, time: float}
var outs: Array[Dictionary] = []
## Occupants of 1st, 2nd, 3rd after the play (&"" = empty).
var final_bases: Array[StringName] = [&"", &"", &""]
## Base the batter finished on: 0 if out, 1..3, or 4 if they scored.
var batter_base: int = 0
## First throw of the play (kept for quick checks); every leg is in throws.
var throw_base: int = -1
var throw_arrival: float = INF
## Throws made in the play: {from, to, base, release, arrival}
var throws: Array[Dictionary] = []
## Runner movements for presentation/logging: {runner_id, from, to, safe}
var advances: Array[Dictionary] = []
## Misplays: {type: "bobble"|"wild_throw"|"dive_miss", base, on_batter}
var errors: Array[Dictionary] = []


func is_hit() -> bool:
	return kind in [KIND_SINGLE, KIND_DOUBLE, KIND_TRIPLE, KIND_HOME_RUN, KIND_INSIDE_PARK_HR]


func describe() -> String:
	var text := String(kind).replace("_", " ")
	if not runs.is_empty():
		text += " (%d run%s)" % [runs.size(), "" if runs.size() == 1 else "s"]
	return text
