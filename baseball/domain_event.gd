class_name DomainEvent
extends RefCounted
## An explicit baseball fact. Presentation, stats and logs consume these;
## the rules layer never needs to know who is listening.

const PITCH_THROWN := &"pitch_thrown"
const PITCH_CALLED := &"pitch_called"
const BALL_CONTACTED := &"ball_contacted"
const CATCH_COMPLETED := &"catch_completed"
const THROW_RELEASED := &"throw_released"
const RUNNER_ADVANCED := &"runner_advanced"
const RUN_SCORED := &"run_scored"
const OUT_RECORDED := &"out_recorded"
const PLATE_APPEARANCE_ENDED := &"plate_appearance_ended"
const HALF_INNING_ENDED := &"half_inning_ended"
const GAME_ENDED := &"game_ended"
const SUBSTITUTION := &"substitution"
## A runner put on base by rule (the extra-innings runner).
const RUNNER_PLACED := &"runner_placed"

var sequence: int
var type: StringName
var data: Dictionary


func _init(p_sequence: int, p_type: StringName, p_data: Dictionary) -> void:
	sequence = p_sequence
	type = p_type
	data = p_data


func _to_string() -> String:
	return "#%d %s %s" % [sequence, type, data]
