class_name LiveFielding
extends RefCounted
## Steps every fielder through a ball in play, one fixed step at a time.
## One fielder may be steered by a movement intent (human); the rest run
## AI routes. Everyone uses the same rules: move at fielder speed, glove
## the ball when it is within reach and low enough. A dive extends reach
## for one attempt; a missed dive leaves the fielder on the ground.
## While a fielder is human-controlled, AI teammates only back up: they
## cannot catch the ball on the fly, so the player's route decides it.
## Deterministic for a given sequence of step() calls.

var trajectory: BallTrajectory
var fielders: Array[FielderState]
var tuning: BaseballTuning
var projection: FieldingResult
var controlled: int = -1
var time: float = 0.0
var positions: PackedVector3Array = PackedVector3Array()
var result: FieldingResult = null
## Controlled fielder cannot move or catch until this time (missed dive).
var down_until: float = -1.0
var dives_missed: int = 0
## Rookie assist for the human fielder: a little quicker, a little more
## reach, and with the stick at rest he runs to the ball on his own.
var assist := false
## Times control passed automatically to a better-placed fielder.
var auto_switches: int = 0

var _targets: PackedVector3Array = PackedVector3Array()
var _target_times: PackedFloat32Array = PackedFloat32Array()


func _init(p_trajectory: BallTrajectory, p_fielders: Array[FielderState], p_projection: FieldingResult, p_tuning: BaseballTuning, p_controlled: int) -> void:
	trajectory = p_trajectory
	fielders = p_fielders
	projection = p_projection
	tuning = p_tuning
	controlled = p_controlled
	for i in fielders.size():
		positions.append(fielders[i].start)
		var candidate: Dictionary = projection.candidates[i] if i < projection.candidates.size() else {}
		var point: Vector3 = candidate.get("point", trajectory.rest_point())
		_targets.append(Vector3(point.x, 0.0, point.z))
		_target_times.append(candidate.get("time", trajectory.end_time()))


func is_secured() -> bool:
	return result != null


## move: stick direction, +Y = toward center field, +X = toward right field.
func step(dt: float, move: Vector2 = Vector2.ZERO, dive: bool = false) -> void:
	if result != null:
		return
	time += dt
	var ball := trajectory.position_at(time)
	var airborne := trajectory.is_airborne_at(time)
	for i in fielders.size():
		var f := fielders[i]
		if i == controlled:
			if time < down_until:
				continue
			if dive:
				_dive(i, ball, airborne, move)
				if result != null:
					return
				continue
			var speed := f.speed * (tuning.assist_fielder_speed_scale if assist else 1.0)
			if assist and move.length() < 0.2:
				# Auto-route: the landing spot for a fly, just ahead of a grounder.
				var goal := trajectory.landing_point if airborne else trajectory.position_at(time + 0.6)
				positions[i] = positions[i].move_toward(Vector3(goal.x, 0.0, goal.z), speed * dt)
				continue
			var dir := Vector3(move.x, 0.0, -move.y)
			if dir.length() > 1.0:
				dir = dir.normalized()
			positions[i] += dir * speed * dt
		elif time > f.reaction:
			# Run the projected route; once that moment has passed, chase the ball.
			var goal := _targets[i] if time < _target_times[i] else Vector3(ball.x, 0.0, ball.z)
			positions[i] = positions[i].move_toward(goal, f.speed * dt)
	if not airborne:
		_auto_switch(ball)
	if ball.y > tuning.catch_max_height:
		return
	var best := -1
	var best_gap := INF
	for i in fielders.size():
		if i == controlled and time < down_until:
			continue
		if airborne and controlled >= 0 and i != controlled:
			continue
		var gap := _gap(positions[i], ball)
		var reach := fielders[i].reach + (tuning.assist_reach_bonus if assist and i == controlled else 0.0)
		if gap <= reach and gap < best_gap:
			best = i
			best_gap = gap
	if best >= 0:
		_secure(best, ball, airborne, false)
	elif time > trajectory.end_time() + tuning.max_flight_time:
		_secure(_nearest(ball), ball, false, false)  # safety net: never stall a play


## Hands control to the fielder (other than the current one) nearest the ball.
func switch_to_nearest() -> void:
	var ball := trajectory.position_at(time)
	var best := -1
	var best_gap := INF
	for i in fielders.size():
		if i == controlled:
			continue
		var gap := _gap(positions[i], ball)
		if gap < best_gap:
			best = i
			best_gap = gap
	controlled = best


## A ball on the ground that has got past the human's fielder hands control
## to a teammate who is much closer to it (a grounder through the infield).
func _auto_switch(ball: Vector3) -> void:
	if controlled < 0 or time < down_until:
		return
	var mine := _gap(positions[controlled], ball)
	if mine < tuning.auto_switch_min_gap:
		return
	var best := controlled
	var best_gap := mine * tuning.auto_switch_ratio
	for i in fielders.size():
		var gap := _gap(positions[i], ball)
		if i != controlled and gap < best_gap:
			best = i
			best_gap = gap
	if best != controlled:
		controlled = best
		auto_switches += 1


func _dive(i: int, ball: Vector3, airborne: bool, move: Vector2) -> void:
	var f := fielders[i]
	if _gap(positions[i], ball) <= f.reach + f.dive_reach and ball.y <= tuning.catch_max_height:
		_secure(i, ball, airborne, true)
		return
	# Missed: lunge toward the stick (or the ball) and lie there.
	var dir := Vector3(move.x, 0.0, -move.y)
	if dir.length() < 0.2:
		dir = Vector3(ball.x - positions[i].x, 0.0, ball.z - positions[i].z)
	positions[i] += dir.normalized() * f.dive_reach if dir.length() > 0.0 else Vector3.ZERO
	down_until = time + tuning.dive_recovery
	dives_missed += 1


func _secure(i: int, ball: Vector3, airborne: bool, dive: bool) -> void:
	result = FieldingResult.new()
	result.fielder_index = i
	result.fielder_id = fielders[i].id
	result.secure_time = time
	result.secure_point = Vector3(ball.x, 0.0, ball.z)
	result.caught_in_air = airborne
	result.is_dive = dive
	result.ready_time = time + (tuning.dive_recovery if dive else 0.0) + trajectory.pickup_delay(time, tuning)
	result.candidates = projection.candidates.duplicate()
	positions[i] = Vector3(positions[i].x, 0.0, positions[i].z)


func _nearest(ball: Vector3) -> int:
	var best := 0
	for i in fielders.size():
		if _gap(positions[i], ball) < _gap(positions[best], ball):
			best = i
	return best


static func _gap(p: Vector3, ball: Vector3) -> float:
	return Vector2(ball.x - p.x, ball.z - p.z).length()
