class_name RunnerPlan
extends RefCounted
## One runner's committed decision on a ball in play.

var runner_id: StringName
## 0 = batter at home, 1..3 = base occupied before the play.
var start_base: int
## Base the runner is going to (start_base when holding, 4 = home).
var target_base: int
var forced: bool
var is_batter: bool
## Contact-relative seconds the runner leaves and reaches the target.
var start_time: float
var arrival_time: float
## Meters already off the bag toward the next base when the ball is hit.
var lead: float = 0.0
## Runner's speed (m/s) and the fielder's arm, for the read.
var speed: float = 8.0
var arm: float = 1.0


func is_moving() -> bool:
	return target_base != start_base


## Where the runner is along the base paths at time t (for presentation).
func position_at(t: float) -> Vector3:
	if not is_moving():
		return FieldLayout.base_position(start_base)
	if t <= start_time:
		var first := FieldLayout.base_position(start_base)
		return first.move_toward(FieldLayout.base_position(start_base + 1), lead)
	var u := clampf((t - start_time) / (arrival_time - start_time), 0.0, 1.0)
	var legs := float(target_base - start_base)
	var lead_legs := lead / FieldLayout.BASE_DISTANCE
	var travelled := lead_legs + u * (legs - lead_legs)
	var leg := mini(int(travelled), target_base - start_base - 1)
	var from := FieldLayout.base_position(start_base + leg)
	var to := FieldLayout.base_position(start_base + leg + 1)
	return from.lerp(to, travelled - float(leg))


func to_dict() -> Dictionary:
	return {
		"runner": runner_id,
		"from": start_base,
		"to": target_base,
		"forced": forced,
		"arrive": snappedf(arrival_time, 0.01),
	}
