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

const OUT_CATCH := &"catch"
const OUT_FORCE := &"force"
const OUT_TAG := &"tag"

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
## ThrowPlay legs: {from, base, release, arrival, unassisted, out_runner, out_kind, out_time}
var throws: Array[Dictionary] = []
## Runner movements for presentation/logging: {runner_id, from, to, safe}
var advances: Array[Dictionary] = []


func is_hit() -> bool:
	return kind in [KIND_SINGLE, KIND_DOUBLE, KIND_TRIPLE, KIND_HOME_RUN, KIND_INSIDE_PARK_HR]


func describe() -> String:
	var text := String(kind).replace("_", " ")
	if not runs.is_empty():
		text += " (%d run%s)" % [runs.size(), "" if runs.size() == 1 else "s"]
	return text
