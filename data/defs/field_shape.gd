class_name FieldShape
extends Resource
## A ballpark's playing dimensions: how far the outfield wall is and how tall
## it stands at every spray angle, plus the air. These are rules of the
## park, so ball flight reads them (through BaseballTuning.field_shape).

@export var id: StringName
@export var display_name: String
## (spray degrees, wall distance m, wall height m) from the left-field line
## (-45) to the right-field line (+45), sorted by angle. Put two points close
## together for a sudden change (the end of a tall wall).
@export var points: PackedVector3Array = PackedVector3Array([Vector3(-45, 92, 3.2), Vector3(0, 112, 3.2), Vector3(45, 92, 3.2)])
## Multiplier on air drag: < 1 is thin air (the ball carries), > 1 heavy.
@export var air_drag_scale: float = 1.0
## How fast grounders run on this surface: 1 = grass, > 1 = artificial turf
## (less roll friction, skips off the bounce).
@export var surface_speed: float = 1.0


func distance_at(spray_deg: float) -> float:
	return _sample(spray_deg).x


func height_at(spray_deg: float) -> float:
	return _sample(spray_deg).y


## (distance, height) at an angle, linearly between the control points.
func _sample(spray_deg: float) -> Vector2:
	var a := clampf(spray_deg, points[0].x, points[points.size() - 1].x)
	for i in range(1, points.size()):
		var p0 := points[i - 1]
		var p1 := points[i]
		if a <= p1.x:
			var t := 0.0 if p1.x == p0.x else (a - p0.x) / (p1.x - p0.x)
			# Distances curve smoothly between points; heights step linearly.
			var s := t * t * (3.0 - 2.0 * t)
			return Vector2(lerpf(p0.y, p1.y, lerpf(t, s, 0.5)), lerpf(p0.z, p1.z, t))
	var last := points[points.size() - 1]
	return Vector2(last.y, last.z)


## Shortest and deepest wall distances (for sanity checks and reports).
func extremes() -> Vector2:
	var lo := INF
	var hi := 0.0
	for p in points:
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
	return Vector2(lo, hi)
