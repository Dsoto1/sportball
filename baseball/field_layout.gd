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
	if tuning.field_shape != null:
		return tuning.field_shape.distance_at(spray_deg)
	var t := clampf(absf(spray_deg) / tuning.foul_line_angle, 0.0, 1.0)
	return lerpf(tuning.fence_center, tuning.fence_line, t * t)


## Where fielder `index` stands before the pitch. Outfielders play at the
## same share of the wall distance as they do in the default park, so a
## deep park pushes them back and a short porch pulls them in.
static func fielder_spot(index: int, tuning: BaseballTuning) -> Vector3:
	var spot := tuning.fielder_spots[index]
	if tuning.field_shape == null or not tuning.fielder_ids[index] in [&"lf", &"cf", &"rf"]:
		return spot
	var angle := spray_angle_of(spot)
	var t := clampf(absf(angle) / tuning.foul_line_angle, 0.0, 1.0)
	var default_fence := lerpf(tuning.fence_center, tuning.fence_line, t * t)
	var depth := Vector2(spot.x, spot.z).length() / default_fence
	return direction_for_spray(angle) * fence_distance(angle, tuning) * depth


## Wall height at a spray angle (a park's tall wall stops would-be homers).
static func fence_height(spray_deg: float, tuning: BaseballTuning) -> float:
	return tuning.field_shape.height_at(spray_deg) if tuning.field_shape != null else tuning.fence_height


## Air drag in this park (thin air carries the ball).
## Ground-ball roll slowdown (m/s²) on this park's surface.
static func roll_deceleration(tuning: BaseballTuning) -> float:
	return tuning.roll_deceleration / _surface(tuning)


## Share of ground speed a bounce keeps on this park's surface.
static func bounce_friction(tuning: BaseballTuning) -> float:
	return minf(tuning.bounce_friction * (1.0 + (_surface(tuning) - 1.0) * 0.5), 0.98)


static func _surface(tuning: BaseballTuning) -> float:
	return tuning.field_shape.surface_speed if tuning.field_shape != null else 1.0


static func drag(tuning: BaseballTuning) -> float:
	return tuning.drag * (tuning.field_shape.air_drag_scale if tuning.field_shape != null else 1.0)


static func is_fair_angle(spray_deg: float, tuning: BaseballTuning) -> bool:
	return absf(spray_deg) <= tuning.foul_line_angle


static func base_name(base: int) -> String:
	return ["home", "1st", "2nd", "3rd", "home"][clampi(base, 0, 4)]
