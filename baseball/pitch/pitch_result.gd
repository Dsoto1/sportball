class_name PitchResult
extends RefCounted
## Authoritative pitch: where it crosses the plate and when.

var family_id: StringName
var aim: Vector2
var meter_error: float
## Where the pitch crosses the plate plane (x, height).
var location: Vector2
var speed: float
var travel_time: float
var in_zone: bool
var release_point: Vector3
var break_amount: Vector2
## 0..1+: how hard this pitch is to read (family plus the pitcher's stuff).
var deception: float = 0.0
var slide_step: bool = false


## Position along the pitch path, t seconds after release. The pitch starts
## on a line toward (location - break) and the break arrives late.
func position_at(t: float) -> Vector3:
	var u := clampf(t / travel_time, 0.0, 1.0)
	var plate := Vector3(location.x, location.y, 0.0)
	var straight := release_point.lerp(plate, u)
	var late := (1.0 - u * u)
	return straight - Vector3(break_amount.x, break_amount.y, 0.0) * late * u


func to_dict() -> Dictionary:
	return {
		"family": family_id,
		"aim": aim,
		"location": location,
		"speed": snappedf(speed, 0.01),
		"in_zone": in_zone,
		"meter_error": snappedf(meter_error, 0.001),
	}
