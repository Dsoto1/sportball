class_name FielderState
extends RefCounted
## A defender's position and physical abilities for intercept math.

var id: StringName
var start: Vector3
var speed: float
var reaction: float
var reach: float
var dive_reach: float


static func default_defense(tuning: BaseballTuning) -> Array[FielderState]:
	var fielders: Array[FielderState] = []
	for i in tuning.fielder_ids.size():
		var f := FielderState.new()
		f.id = tuning.fielder_ids[i]
		f.start = tuning.fielder_spots[i]
		f.speed = tuning.fielder_speed
		f.reaction = tuning.fielder_reaction
		f.reach = tuning.catch_reach
		f.dive_reach = tuning.dive_reach
		fielders.append(f)
	return fielders


## Horizontal distance this fielder can cover t seconds after contact.
func coverage_at(t: float) -> float:
	return maxf(t - reaction, 0.0) * speed
