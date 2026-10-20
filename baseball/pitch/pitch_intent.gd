class_name PitchIntent
extends RefCounted
## What the pitcher (human or AI) asked for.

var family_id: StringName
## Intended finishing point in the plate plane (x, height).
var aim: Vector2
## 0 = perfect meter, 1 = fully missed.
var meter_error: float


func _init(p_family_id: StringName, p_aim: Vector2, p_meter_error: float) -> void:
	family_id = p_family_id
	aim = p_aim
	meter_error = clampf(p_meter_error, 0.0, 1.0)
