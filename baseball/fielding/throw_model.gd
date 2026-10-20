class_name ThrowModel
extends RefCounted
## Throw timing. Phase 0 assumes the target base is covered in time.


static func flight_time(from: Vector3, to: Vector3, tuning: BaseballTuning) -> float:
	var flat := Vector2(to.x - from.x, to.z - from.z).length()
	return flat / tuning.throw_speed + flat * flat * tuning.throw_long_penalty


## Contact-relative time a throw from the fielding play reaches a base.
static func arrival_at_base(fielding: FieldingResult, base: int, tuning: BaseballTuning) -> float:
	var target := FieldLayout.base_position(base)
	return fielding.ready_time + tuning.throw_release_time + flight_time(fielding.secure_point, target, tuning)


## Visible throw position: straight line with a shallow arc.
static func position_at(from: Vector3, to: Vector3, u: float, tuning: BaseballTuning) -> Vector3:
	var start := from + Vector3.UP * 1.6
	var finish := to + Vector3.UP * 1.2
	var arc := 4.0 * u * (1.0 - u) * tuning.throw_arc_height
	return start.lerp(finish, u) + Vector3.UP * arc
