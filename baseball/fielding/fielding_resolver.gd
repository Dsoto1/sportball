class_name FieldingResolver
extends RefCounted
## Finds the earliest moment any fielder can reach the authoritative ball.
## A fielder reaches a sample if it is low enough to glove and within
## (run distance + reach) of where they started. Dives extend reach but
## add recovery time before a throw.


static func resolve(traj: BallTrajectory, fielders: Array[FielderState], tuning: BaseballTuning) -> FieldingResult:
	var result := FieldingResult.new()
	if traj.result == BallTrajectory.Result.HOME_RUN:
		return result
	for i in fielders.size():
		var candidate := _earliest_for(traj, fielders[i], tuning)
		result.candidates.append(candidate)
		if candidate["time"] < result.secure_time:
			result.fielder_index = i
			result.fielder_id = fielders[i].id
			result.secure_time = candidate["time"]
			result.secure_point = candidate["point"]
			result.is_dive = candidate["dive"]
	if result.has_fielder():
		result.caught_in_air = traj.is_airborne_at(result.secure_time)
		result.secure_point.y = 0.0
		result.ready_time = result.secure_time + (tuning.dive_recovery if result.is_dive else 0.0) + traj.pickup_delay(result.secure_time, tuning)
	return result


static func _earliest_for(traj: BallTrajectory, fielder: FielderState, tuning: BaseballTuning) -> Dictionary:
	var normal_index := -1
	var dive_index := -1
	for i in traj.points.size():
		var t := traj.times[i]
		if t <= fielder.reaction:
			continue
		var p := traj.points[i]
		if p.y > tuning.catch_max_height:
			continue
		var gap := Vector2(p.x - fielder.start.x, p.z - fielder.start.z).length()
		var run := fielder.coverage_at(t)
		if gap <= run + fielder.reach:
			normal_index = i
			break
		# Dives only rob a ball before it lands; keep the earliest one.
		if dive_index < 0 and traj.is_airborne_at(t) and gap <= run + fielder.reach + fielder.dive_reach:
			dive_index = i
	# Prefer a routine catch on the fly; dive only when that is impossible.
	if normal_index >= 0 and traj.is_airborne_at(traj.times[normal_index]):
		return _candidate(fielder, traj, normal_index, false)
	if dive_index >= 0:
		return _candidate(fielder, traj, dive_index, true)
	if normal_index >= 0:
		return _candidate(fielder, traj, normal_index, false)
	# Nobody intercepted it in flight: run it down where it stops.
	var rest := traj.rest_point()
	var gap_rest := maxf(Vector2(rest.x - fielder.start.x, rest.z - fielder.start.z).length() - fielder.reach, 0.0)
	var t_rest := maxf(traj.end_time(), fielder.reaction + gap_rest / fielder.speed)
	return {"id": fielder.id, "time": t_rest, "point": rest, "dive": false}


static func _candidate(fielder: FielderState, traj: BallTrajectory, index: int, dive: bool) -> Dictionary:
	return {"id": fielder.id, "time": traj.times[index], "point": traj.points[index], "dive": dive}
