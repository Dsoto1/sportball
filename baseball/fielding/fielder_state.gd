class_name FielderState
extends RefCounted
## A defender's position and physical abilities for intercept math.

var id: StringName
var start: Vector3
var speed: float
var reaction: float
var reach: float
var dive_reach: float
var player_id: StringName = &""
## Throw speed multiplier (arm rating).
var arm: float = 1.0
## Multipliers on this fielder's bobble and wild-throw chances.
var error_scale: float = 1.0
var throw_error_scale: float = 1.0


## players: field position id -> PlayerDef (missing = league average).
static func default_defense(tuning: BaseballTuning, players: Dictionary = {}) -> Array[FielderState]:
	var fielders: Array[FielderState] = []
	for i in tuning.fielder_ids.size():
		var f := FielderState.new()
		f.id = tuning.fielder_ids[i]
		f.start = FieldLayout.fielder_spot(i, tuning)
		f.speed = tuning.fielder_speed
		f.reaction = tuning.fielder_reaction
		f.reach = tuning.catch_reach
		f.dive_reach = tuning.dive_reach
		Ratings.apply_fielder(f, players.get(f.id), tuning)
		fielders.append(f)
	return fielders


## Horizontal distance this fielder can cover t seconds after contact.
func coverage_at(t: float) -> float:
	return maxf(t - reaction, 0.0) * speed
