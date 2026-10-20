class_name FieldingResult
extends RefCounted
## Who gets to the ball first, where, and when.

var fielder_index: int = -1
var fielder_id: StringName = &""
## Contact-relative time the ball is in the fielder's glove.
var secure_time: float = INF
## Time the fielder is ready to throw (secure + any dive recovery).
var ready_time: float = INF
var secure_point: Vector3 = Vector3.ZERO
var caught_in_air: bool = false
var is_dive: bool = false
## Debug: each fielder's earliest feasible time {id, time, point}.
var candidates: Array[Dictionary] = []


func has_fielder() -> bool:
	return fielder_index >= 0


func to_dict() -> Dictionary:
	return {
		"fielder": fielder_id,
		"secure_time": snappedf(secure_time, 0.01),
		"point": secure_point.snapped(Vector3.ONE * 0.1),
		"in_air": caught_in_air,
		"dive": is_dive,
	}
