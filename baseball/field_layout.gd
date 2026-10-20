class_name FieldLayout
extends RefCounted
## Field geometry. Base distance is a rule of the game; fence shape is
## stadium balance and comes from tuning.
## Base indices: 0 = home (batter), 1 = first, 2 = second, 3 = third,
## 4 = home again (scored).

const BASE_DISTANCE := 27.43
const HOME := 0
const FIRST := 1
const SECOND := 2
const THIRD := 3
const SCORED := 4


static func base_position(base: int) -> Vector3:
	var half := BASE_DISTANCE / sqrt(2.0)
	match base % 4:
		FIRST:
			return Vector3(half, 0.0, -half)
		SECOND:
			return Vector3(0.0, 0.0, -2.0 * half)
		THIRD:
			return Vector3(-half, 0.0, -half)
		_:
			return Vector3.ZERO


## Horizontal spray angle of a field point: 0 = straight to center field,
## positive toward the first-base (right field) line.
static func spray_angle_of(point: Vector3) -> float:
	return rad_to_deg(atan2(point.x, -point.z))


static func direction_for_spray(spray_deg: float) -> Vector3:
	var s := deg_to_rad(spray_deg)
	return Vector3(sin(s), 0.0, -cos(s))


static func fence_distance(spray_deg: float, tuning: BaseballTuning) -> float:
	var t := clampf(absf(spray_deg) / tuning.foul_line_angle, 0.0, 1.0)
	return lerpf(tuning.fence_center, tuning.fence_line, t * t)


static func is_fair_angle(spray_deg: float, tuning: BaseballTuning) -> bool:
	return absf(spray_deg) <= tuning.foul_line_angle


static func base_name(base: int) -> String:
	return ["home", "1st", "2nd", "3rd", "home"][clampi(base, 0, 4)]
