class_name ThrowPlay
extends RefCounted
## The defense's throws after the ball is secured, resolved one leg at a
## time. Each leg goes to a base. The first runner heading there is out if
## the ball beats them; a tag is needed unless the force is still on. The
## receiver can then throw again from that base, which makes double plays,
## triple plays and base-to-base relays possible. Runners do not react to
## throws: they keep the targets they committed to when the ball was read.
##
## Force rule: a runner is forced only while every runner behind them in
## the force chain is still alive. Once the batter is out at first, the
## runner going to second must be tagged.

const MAX_LEGS := 3

var plans: Array[RunnerPlan]
var fielding: FieldingResult
var batter_id: StringName
var outs_before: int
var launch_angle: float
var tuning: BaseballTuning
## Each leg: {from: Vector3, base: int, release: float, arrival: float,
## unassisted: bool, out_runner: StringName, out_kind: StringName, out_time: float}
var legs: Array[Dictionary] = []
## Each out: {runner_id, base, kind, time}, in the order they happened.
var outs: Array[Dictionary] = []


func _init(p_plans: Array[RunnerPlan], p_batter_id: StringName, p_fielding: FieldingResult, p_outs_before: int, p_launch_angle: float, p_tuning: BaseballTuning) -> void:
	plans = p_plans
	batter_id = p_batter_id
	fielding = p_fielding
	outs_before = p_outs_before
	launch_angle = p_launch_angle
	tuning = p_tuning
	if fielding.caught_in_air:
		outs.append({"runner_id": batter_id, "base": FieldLayout.HOME, "kind": PlayOutcome.OUT_CATCH, "time": fielding.secure_time})


## Independent copy for look-ahead (AI) without touching the real play.
func copy() -> ThrowPlay:
	var other := ThrowPlay.new(plans, batter_id, fielding, outs_before, launch_angle, tuning)
	other.legs = legs.duplicate(true)
	other.outs = outs.duplicate(true)
	return other


func inning_over() -> bool:
	return outs_before + outs.size() >= MatchState.OUTS_PER_HALF


func can_throw() -> bool:
	return fielding.has_fielder() and not inning_over() and legs.size() < MAX_LEGS


## Base the ball is held at (-1 while still with the fielder who got it).
func holder_base() -> int:
	return -1 if legs.is_empty() else legs[-1]["base"]


func holder_position() -> Vector3:
	return fielding.secure_point if legs.is_empty() else FieldLayout.base_position(legs[-1]["base"])


## Earliest contact-relative time the next leg can start.
func next_release_time() -> float:
	if legs.is_empty():
		return fielding.ready_time
	var last: Dictionary = legs[-1]
	var t: float = last["arrival"] + tuning.relay_release_time
	if last["out_kind"] == PlayOutcome.OUT_TAG:
		t += tuning.tag_time
	return t


func is_out(runner_id: StringName) -> bool:
	return outs.any(func(o: Dictionary) -> bool: return o["runner_id"] == runner_id)


## Throws (or, from close range, carries) the ball to a base. not_before
## lets a human hold the ball; holding costs that time.
func throw_to(base: int, not_before: float = 0.0) -> Dictionary:
	assert(can_throw(), "no throw allowed")
	var from := holder_position()
	var target := FieldLayout.base_position(base)
	var start := maxf(next_release_time(), not_before)
	var flat := Vector2(target.x - from.x, target.z - from.z).length()
	var unassisted := legs.is_empty() and flat <= tuning.unassisted_distance
	var leg := {"from": from, "base": base, "release": start, "arrival": 0.0, "unassisted": unassisted,
		"out_runner": &"", "out_kind": &"", "out_time": INF}
	if unassisted:
		# Close enough to run to the bag (or tag the runner) himself.
		leg["arrival"] = start + flat / tuning.fielder_speed
	else:
		leg["release"] = start + (tuning.throw_release_time if legs.is_empty() else 0.0)
		leg["arrival"] = leg["release"] + ThrowModel.flight_time(from, target, tuning)
	var arrival: float = leg["arrival"]
	var targeting := plans.filter(func(p: RunnerPlan) -> bool: return p.is_moving() and p.target_base == base and not is_out(p.runner_id))
	targeting.sort_custom(func(a: RunnerPlan, b: RunnerPlan) -> bool: return a.arrival_time < b.arrival_time)
	for p: RunnerPlan in targeting:
		var forced := is_forced_at(p, arrival)
		var needed := arrival + (0.0 if forced else tuning.tag_time)
		if needed < p.arrival_time:
			leg["out_runner"] = p.runner_id
			leg["out_kind"] = PlayOutcome.OUT_FORCE if forced else PlayOutcome.OUT_TAG
			leg["out_time"] = needed
			outs.append({"runner_id": p.runner_id, "base": base, "kind": leg["out_kind"], "time": needed})
			break
	legs.append(leg)
	return leg


## A force holds only while every runner behind in the force chain is alive.
func is_forced_at(p: RunnerPlan, time: float) -> bool:
	if not p.forced:
		return false
	for q in plans:
		if q.forced and q.start_base < p.start_base:
			for o in outs:
				if o["runner_id"] == q.runner_id and o["time"] <= time:
					return false
	return true


## Contact-relative time by which every throw has landed.
func last_arrival() -> float:
	return fielding.secure_time if legs.is_empty() else legs[-1]["arrival"]


func outcome() -> PlayOutcome:
	var result := PlayOutcome.new()
	result.batter_id = batter_id
	result.outs = outs.duplicate(true)
	result.throws = legs.duplicate(true)
	if not legs.is_empty():
		result.throw_base = legs[0]["base"]
		result.throw_arrival = legs[0]["arrival"]
	var over := inning_over()
	var third_out: Dictionary = outs[MatchState.OUTS_PER_HALF - outs_before - 1] if over else {}
	var scoring := plans.filter(func(p: RunnerPlan) -> bool: return p.target_base == FieldLayout.SCORED and not is_out(p.runner_id))
	scoring.sort_custom(func(a: RunnerPlan, b: RunnerPlan) -> bool: return a.arrival_time < b.arrival_time)
	for p: RunnerPlan in scoring:
		if over:
			# No run scores on a third out that is a force or a catch; on a tag
			# out, only runners who crossed before the tag count.
			if third_out["kind"] != PlayOutcome.OUT_TAG or p.arrival_time >= third_out["time"]:
				continue
		result.runs.append(p.runner_id)
	for p in plans:
		var safe := not is_out(p.runner_id)
		result.advances.append({"runner_id": p.runner_id, "from": p.start_base, "to": p.target_base, "safe": safe})
		if safe and p.target_base >= FieldLayout.FIRST and p.target_base <= FieldLayout.THIRD:
			result.final_bases[p.target_base - 1] = p.runner_id
		if p.is_batter:
			result.batter_base = p.target_base if safe else 0
	result.kind = _classify(result)
	return result


func _classify(result: PlayOutcome) -> StringName:
	if result.outs.size() >= 3:
		return PlayOutcome.KIND_TRIPLE_PLAY
	if result.outs.size() == 2:
		return PlayOutcome.KIND_DOUBLE_PLAY
	if fielding.caught_in_air:
		if launch_angle >= 50.0:
			return PlayOutcome.KIND_POP_OUT
		if launch_angle < 15.0:
			return PlayOutcome.KIND_LINE_OUT
		return PlayOutcome.KIND_FLY_OUT
	if result.batter_base == 0:
		return PlayOutcome.KIND_GROUND_OUT
	if not result.outs.is_empty():
		return PlayOutcome.KIND_FIELDERS_CHOICE
	match result.batter_base:
		1:
			return PlayOutcome.KIND_SINGLE
		2:
			return PlayOutcome.KIND_DOUBLE
		3:
			return PlayOutcome.KIND_TRIPLE
	return PlayOutcome.KIND_INSIDE_PARK_HR
