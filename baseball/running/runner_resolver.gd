class_name RunnerResolver
extends RefCounted
## Base running and base/tag resolution.
##
## plan(): every runner commits to a target base the moment the ball is
## read. They take an extra base only if they beat the projected throw to
## it by a safety margin; forced runners must advance.
## resolve(): the defense makes one throw. A runner heading to that base is
## out if the ball beats them (plus tag time when not forced). Third-out
## rules decide which runs count.


static func plan(bases: Array[StringName], batter_id: StringName, fielding: FieldingResult, outs_before: int, tuning: BaseballTuning) -> Array[RunnerPlan]:
	var plans: Array[RunnerPlan] = []
	var occupied := [false, bases[0] != &"", bases[1] != &"", bases[2] != &""]
	var margin := tuning.two_out_safety_margin if outs_before == 2 else tuning.runner_safety_margin
	var limit := FieldLayout.SCORED
	var caught := fielding.caught_in_air
	var inning_over := caught and outs_before + 1 >= MatchState.OUTS_PER_HALF

	for base: int in [3, 2, 1]:
		if not occupied[base]:
			continue
		var p := RunnerPlan.new()
		p.runner_id = bases[base - 1]
		p.start_base = base
		p.is_batter = false
		if caught:
			# Fly ball caught: retouch, then tag up for at most one base.
			p.forced = false
			p.start_time = fielding.secure_time + tuning.tag_up_delay
			var tag_limit := mini(base + 1, limit)
			p.target_base = base if inning_over else _choose_target(p, base, tag_limit, fielding, margin, tuning)
		else:
			p.forced = _is_forced(base, occupied)
			p.start_time = tuning.runner_read_delay
			p.lead = tuning.runner_lead_distance
			var min_target := base + 1 if p.forced else base
			p.target_base = _choose_target(p, min_target, limit, fielding, margin, tuning)
		p.arrival_time = arrival_between(p.start_base, p.target_base, p.start_time, tuning, p.lead)
		plans.append(p)
		limit = FieldLayout.SCORED if p.target_base == FieldLayout.SCORED else p.target_base - 1

	if not caught:
		var b := RunnerPlan.new()
		b.runner_id = batter_id
		b.start_base = FieldLayout.HOME
		b.is_batter = true
		b.forced = true
		b.start_time = tuning.batter_start_delay
		b.target_base = _choose_target(b, FieldLayout.FIRST, limit, fielding, margin, tuning)
		b.arrival_time = arrival_between(b.start_base, b.target_base, b.start_time, tuning)
		plans.append(b)
	return plans


static func resolve(plans: Array[RunnerPlan], batter_id: StringName, fielding: FieldingResult, throw_base: int, outs_before: int, launch_angle: float, tuning: BaseballTuning) -> PlayOutcome:
	var outcome := PlayOutcome.new()
	outcome.batter_id = batter_id
	var outs := outs_before
	if fielding.caught_in_air:
		outcome.outs.append({"runner_id": batter_id, "base": FieldLayout.HOME, "kind": PlayOutcome.OUT_CATCH, "time": fielding.secure_time})
		outs += 1

	var out_plan: RunnerPlan = null
	var out_time := INF
	var out_kind := &""
	if throw_base > 0 and outs < MatchState.OUTS_PER_HALF:
		outcome.throw_base = throw_base
		outcome.throw_arrival = ThrowModel.arrival_at_base(fielding, throw_base, tuning)
		var targeting := plans.filter(func(p: RunnerPlan) -> bool: return p.is_moving() and p.target_base == throw_base)
		targeting.sort_custom(func(a: RunnerPlan, b: RunnerPlan) -> bool: return a.arrival_time < b.arrival_time)
		for p: RunnerPlan in targeting:
			var needed := outcome.throw_arrival + (0.0 if p.forced else tuning.tag_time)
			if needed < p.arrival_time:
				out_plan = p
				out_time = needed
				out_kind = PlayOutcome.OUT_FORCE if p.forced else PlayOutcome.OUT_TAG
				break
	if out_plan != null:
		outcome.outs.append({"runner_id": out_plan.runner_id, "base": out_plan.target_base, "kind": out_kind, "time": out_time})
		outs += 1

	var inning_over := outs >= MatchState.OUTS_PER_HALF
	var last_out_kind: StringName = outcome.outs[-1]["kind"] if not outcome.outs.is_empty() else &""
	var last_out_time: float = outcome.outs[-1]["time"] if not outcome.outs.is_empty() else INF
	var scoring := plans.filter(func(p: RunnerPlan) -> bool: return p.target_base == FieldLayout.SCORED and p != out_plan)
	scoring.sort_custom(func(a: RunnerPlan, b: RunnerPlan) -> bool: return a.arrival_time < b.arrival_time)
	for p: RunnerPlan in scoring:
		if inning_over:
			# No run scores on a third out that is a force or the batter's catch;
			# on a tag out, only runners who crossed before the tag count.
			if last_out_kind != PlayOutcome.OUT_TAG or p.arrival_time >= last_out_time:
				continue
		outcome.runs.append(p.runner_id)

	for p in plans:
		var safe := p != out_plan
		outcome.advances.append({"runner_id": p.runner_id, "from": p.start_base, "to": p.target_base, "safe": safe})
		if safe and p.target_base >= FieldLayout.FIRST and p.target_base <= FieldLayout.THIRD:
			outcome.final_bases[p.target_base - 1] = p.runner_id
		if p.is_batter:
			outcome.batter_base = p.target_base if safe else 0
	outcome.kind = _classify(outcome, fielding, out_plan, launch_angle)
	return outcome


## Outcome for a ball that left the park: everyone scores.
static func home_run(bases: Array[StringName], batter_id: StringName) -> PlayOutcome:
	var outcome := PlayOutcome.new()
	outcome.kind = PlayOutcome.KIND_HOME_RUN
	outcome.batter_id = batter_id
	for base: int in [3, 2, 1]:
		var runner := bases[base - 1]
		if runner != &"":
			outcome.runs.append(runner)
			outcome.advances.append({"runner_id": runner, "from": base, "to": FieldLayout.SCORED, "safe": true})
	outcome.runs.append(batter_id)
	outcome.advances.append({"runner_id": batter_id, "from": FieldLayout.HOME, "to": FieldLayout.SCORED, "safe": true})
	outcome.batter_base = FieldLayout.SCORED
	return outcome


## Contact-relative time a throw would reach each base, indexed 1..4.
static func ball_arrival(fielding: FieldingResult, base: int, tuning: BaseballTuning) -> float:
	return ThrowModel.arrival_at_base(fielding, base, tuning)


static func _is_forced(base: int, occupied: Array) -> bool:
	match base:
		1:
			return true
		2:
			return occupied[1]
		3:
			return occupied[1] and occupied[2]
	return false


static func arrival_between(from_base: int, to_base: int, start_time: float, tuning: BaseballTuning, lead: float = 0.0) -> float:
	var legs := to_base - from_base
	if legs <= 0:
		return start_time
	var run := legs * FieldLayout.BASE_DISTANCE - lead
	return start_time + run / tuning.runner_speed + (legs - 1) * tuning.base_turn_penalty


static func _choose_target(p: RunnerPlan, min_target: int, limit: int, fielding: FieldingResult, margin: float, tuning: BaseballTuning) -> int:
	var target := min_target
	for t in range(min_target + 1, limit + 1):
		var arrive := arrival_between(p.start_base, t, p.start_time, tuning, p.lead)
		if arrive + margin < ball_arrival(fielding, t, tuning):
			target = t
		else:
			break
	return target


static func _classify(outcome: PlayOutcome, fielding: FieldingResult, out_plan: RunnerPlan, launch_angle: float) -> StringName:
	if fielding.caught_in_air:
		if launch_angle >= 50.0:
			return PlayOutcome.KIND_POP_OUT
		if launch_angle < 15.0:
			return PlayOutcome.KIND_LINE_OUT
		return PlayOutcome.KIND_FLY_OUT
	if outcome.batter_base == 0:
		return PlayOutcome.KIND_GROUND_OUT
	if out_plan != null:
		return PlayOutcome.KIND_FIELDERS_CHOICE
	match outcome.batter_base:
		1:
			return PlayOutcome.KIND_SINGLE
		2:
			return PlayOutcome.KIND_DOUBLE
		3:
			return PlayOutcome.KIND_TRIPLE
	return PlayOutcome.KIND_INSIDE_PARK_HR
