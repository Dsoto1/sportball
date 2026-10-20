class_name BallTrajectory
extends RefCounted
## Authoritative batted-ball flight computed from exit velocity, launch
## angle and spray with a fixed-step integrator (gravity, quadratic drag,
## bounces, roll, fence). Deterministic for identical inputs. The visible
## ball samples this; physics bodies never decide the outcome.

enum Result { IN_PLAY, HOME_RUN, FOUL }

var result: Result = Result.IN_PLAY
var step: float
var times: PackedFloat32Array = PackedFloat32Array()
var points: PackedVector3Array = PackedVector3Array()
## Time of first ground contact; INF if the ball never landed in play.
var first_bounce_time: float = INF
## Where the ball first touched ground (or left the park for a home run).
var landing_point: Vector3 = Vector3.ZERO
var apex_height: float = 0.0
var hit_fence: bool = false

var _fence_point: Vector3
var _fence_velocity: Vector3


static func simulate(exit_velocity: float, launch_angle: float, spray_angle: float, tuning: BaseballTuning) -> BallTrajectory:
	var traj := BallTrajectory.new()
	traj.step = tuning.sim_step
	var fair := FieldLayout.is_fair_angle(spray_angle, tuning)
	traj.result = Result.IN_PLAY if fair else Result.FOUL
	var la := deg_to_rad(launch_angle)
	var dir := FieldLayout.direction_for_spray(spray_angle)
	var v := dir * exit_velocity * cos(la) + Vector3.UP * exit_velocity * sin(la)
	var p := Vector3(0.0, tuning.contact_height, 0.0)
	var airborne := true
	var t := 0.0
	var max_time := tuning.max_flight_time if fair else 3.0
	traj._append(t, p)
	while t < max_time:
		t += traj.step
		if airborne:
			var accel := Vector3(0.0, -tuning.gravity, 0.0) - v * (tuning.drag * v.length())
			v += accel * traj.step
			p += v * traj.step
			if p.y <= 0.0:
				p.y = 0.0
				if traj.first_bounce_time == INF:
					traj.first_bounce_time = t
					traj.landing_point = p
				if -v.y > tuning.bounce_min_speed:
					v.y = -v.y * tuning.bounce_restitution
					v.x *= tuning.bounce_friction
					v.z *= tuning.bounce_friction
				else:
					v.y = 0.0
					airborne = false
		else:
			var flat := Vector2(v.x, v.z)
			var speed := flat.length()
			if speed <= tuning.stop_speed:
				traj._append(t, p)
				break
			flat = flat * (maxf(speed - tuning.roll_deceleration * traj.step, 0.0) / speed)
			v = Vector3(flat.x, 0.0, flat.y)
			p += v * traj.step
		traj.apex_height = maxf(traj.apex_height, p.y)
		if fair and traj._check_fence(p, v, tuning):
			if traj.result == Result.HOME_RUN:
				traj._append(t, p)
				break
			p = traj._fence_point
			v = traj._fence_velocity
		traj._append(t, p)
	if traj.first_bounce_time == INF and traj.result != Result.HOME_RUN:
		traj.landing_point = traj.points[traj.points.size() - 1]
	return traj


func end_time() -> float:
	return times[times.size() - 1]


func rest_point() -> Vector3:
	return points[points.size() - 1]


func position_at(t: float) -> Vector3:
	if t <= 0.0:
		return points[0]
	var index := int(t / step)
	if index >= points.size() - 1:
		return points[points.size() - 1]
	var u := (t - times[index]) / step
	return points[index].lerp(points[index + 1], clampf(u, 0.0, 1.0))


func is_airborne_at(t: float) -> bool:
	return t < first_bounce_time


func distance() -> float:
	return Vector2(landing_point.x, landing_point.z).length()


func to_dict() -> Dictionary:
	return {
		"result": Result.keys()[result],
		"hang_time": snappedf(first_bounce_time if first_bounce_time != INF else end_time(), 0.01),
		"distance": snappedf(distance(), 0.1),
		"apex": snappedf(apex_height, 0.1),
		"landing": landing_point.snapped(Vector3.ONE * 0.1),
	}



func _append(t: float, p: Vector3) -> void:
	times.append(t)
	points.append(p)


## Returns true if the ball reached the fence this step. Sets result to
## HOME_RUN when it cleared it on the fly, otherwise prepares a rebound.
func _check_fence(p: Vector3, v: Vector3, tuning: BaseballTuning) -> bool:
	var flat := Vector2(p.x, p.z)
	var r := flat.length()
	var fence := FieldLayout.fence_distance(FieldLayout.spray_angle_of(p), tuning)
	if r < fence:
		return false
	if p.y > tuning.fence_height and first_bounce_time == INF:
		result = Result.HOME_RUN
		landing_point = p
		return true
	hit_fence = true
	var n := Vector3(flat.x / r, 0.0, flat.y / r)
	var vn := v.x * n.x + v.z * n.z
	_fence_velocity = v
	if vn > 0.0:
		_fence_velocity -= n * vn * (1.0 + tuning.fence_restitution)
	_fence_point = Vector3(n.x * (fence - 0.05), p.y, n.z * (fence - 0.05))
	return true
