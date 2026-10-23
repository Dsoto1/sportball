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
## Time the ball first came off the wall; INF if it never reached it.
var fence_time: float = INF
## The bag the ball glanced off (FieldLayout.FIRST..THIRD), or -1.
var hit_base: int = -1
## The ball's radius (m) and how lively it comes off a bag.
const BALL_RADIUS := 0.037
const BAG_RESTITUTION := 0.45

var _fence_point: Vector3
var _fence_velocity: Vector3
## A home run's flight on past the wall to field level (presentation and
## the "projected distance" the board shows; nothing in the rules reads it).
var tail_times: PackedFloat32Array = PackedFloat32Array()
var tail_points: PackedVector3Array = PackedVector3Array()
var _hr_velocity: Vector3


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
	var drag := FieldLayout.drag(tuning)
	var t := 0.0
	var max_time := tuning.max_flight_time if fair else 3.0
	traj._append(t, p)
	while t < max_time:
		t += traj.step
		if airborne:
			var accel := Vector3(0.0, -tuning.gravity, 0.0) - v * (drag * v.length())
			v += accel * traj.step
			p += v * traj.step
			# The ground is the mound where it rises, flat everywhere else.
			var ground := FieldLayout.ground_height(p)
			if p.y <= ground:
				p.y = ground
				if traj.first_bounce_time == INF:
					traj.first_bounce_time = t
					traj.landing_point = p
				var n := FieldLayout.ground_normal(p)
				var vn := v.dot(n)
				if -vn > tuning.bounce_min_speed:
					# Off the slope: the normal part reverses (losing energy),
					# the rest keeps going, slowed by the turf.
					var along := (v - n * vn) * FieldLayout.bounce_friction(tuning)
					v = along - n * vn * tuning.bounce_restitution
				else:
					v = v - n * minf(vn, 0.0)
					v.y = 0.0
					airborne = false
		else:
			var flat := Vector2(v.x, v.z)
			# Down the mound's slope, or slowed climbing it.
			var n := FieldLayout.ground_normal(p)
			flat += Vector2(n.x, n.z) * tuning.gravity * traj.step
			var speed := flat.length()
			if speed <= tuning.stop_speed and n.y > 0.999:
				traj._append(t, p)
				break
			if speed > 0.0:
				flat = flat * (maxf(speed - FieldLayout.roll_deceleration(tuning) * traj.step, 0.0) / speed)
			v = Vector3(flat.x, 0.0, flat.y)
			p += v * traj.step
			var lift := FieldLayout.ground_height(p) - p.y
			p.y += lift
			# Rolling up the mound's edge fast enough, it hops off its lip.
			if lift > 0.0 and speed > 0.0 and lift / (speed * traj.step) > 0.3 and speed > 6.0:
				v.y = speed * 0.25
				airborne = true
		# Off a bag at first, second or third: back the way it came through
		# the face it hit, livelier off its side than its top.
		var bag := FieldLayout.base_contact(p, BALL_RADIUS)
		if not bag.is_empty():
			var bn: Vector3 = bag["normal"]
			p += bn * float(bag["depth"])
			var bvn := v.dot(bn)
			if bvn < 0.0:
				v -= bn * bvn * (1.0 + BAG_RESTITUTION)
				v -= (v - bn * v.dot(bn)) * 0.15
				if bn.y < 0.5 or v.y > tuning.bounce_min_speed:
					airborne = true
					if traj.first_bounce_time == INF:
						traj.first_bounce_time = t
						traj.landing_point = p
				traj.hit_base = int(bag["base"])
		traj.apex_height = maxf(traj.apex_height, p.y)
		if fair and traj._check_fence(p, v, tuning):
			if traj.result == Result.HOME_RUN:
				traj._append(t, p)
				break
			p = traj._fence_point
			v = traj._fence_velocity
			traj.fence_time = minf(traj.fence_time, t)
		traj._append(t, p)
	if traj.first_bounce_time == INF and traj.result != Result.HOME_RUN:
		traj.landing_point = traj.points[traj.points.size() - 1]
	if traj.result == Result.HOME_RUN:
		# Carry on over the stands, same air, down to field level.
		var hv := traj._hr_velocity
		var hp := traj.points[traj.points.size() - 1]
		var ht := traj.times[traj.times.size() - 1]
		while hp.y > 0.0 and ht < max_time + 6.0:
			ht += traj.step
			hv += (Vector3(0.0, -tuning.gravity, 0.0) - hv * (drag * hv.length())) * traj.step
			hp += hv * traj.step
			traj.tail_times.append(ht)
			traj.tail_points.append(hp)
	return traj


## Statcast-style projected distance of a home run (m): where it would have
## come down at field level. The wall distance for anything else.
func projected_distance() -> float:
	if tail_points.is_empty():
		return distance()
	var last := tail_points[tail_points.size() - 1]
	return Vector2(last.x, last.z).length()


## Where the ball is at `t`, following a home run on past the wall.
func flight_position(t: float) -> Vector3:
	if tail_points.is_empty() or t <= end_time():
		return position_at(t)
	var u := (t - end_time()) / step
	var i := int(u)
	if i >= tail_points.size() - 1:
		return tail_points[tail_points.size() - 1]
	var a := tail_points[i - 1] if i > 0 else rest_point()
	return a.lerp(tail_points[i], u - i)


## Extra time a fielder needs to pick the ball up at `t`: a ball off the
## wall has to be played off the carom.
func pickup_delay(t: float, tuning: BaseballTuning) -> float:
	return tuning.wall_carom_delay if t >= fence_time else 0.0


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
	var spray := FieldLayout.spray_angle_of(p)
	var fence := FieldLayout.fence_distance(spray, tuning)
	if r < fence:
		return false
	if p.y > FieldLayout.fence_height(spray, tuning) and first_bounce_time == INF:
		result = Result.HOME_RUN
		landing_point = p
		_hr_velocity = v
		return true
	hit_fence = true
	var n := Vector3(flat.x / r, 0.0, flat.y / r)
	var vn := v.x * n.x + v.z * n.z
	_fence_velocity = v
	if vn > 0.0:
		_fence_velocity -= n * vn * (1.0 + tuning.fence_restitution)
	_fence_point = Vector3(n.x * (fence - 0.05), p.y, n.z * (fence - 0.05))
	return true
