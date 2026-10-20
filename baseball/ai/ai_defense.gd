class_name AiDefense
extends RefCounted
## Chooses the defense's throws. Tactical evaluation only (personality
## weights arrive in Phase 4): every candidate base is tried on a copy of
## the ThrowPlay with one further throw of look-ahead, and the line with the
## best outs-versus-runs value wins. Stopping is also a candidate.

const NO_THROW := -1
const BASES: Array[int] = [1, 2, 3, 4]


## Next base to throw to, or NO_THROW to stop.
static func next_throw(play: ThrowPlay) -> int:
	if not play.can_throw():
		return NO_THROW
	var best_base := NO_THROW
	var best_score := _score(play)
	for base in BASES:
		if base == play.holder_base():
			continue
		var sim := play.copy()
		sim.throw_to(base)
		var score := _best_line(sim, 1)
		if score > best_score + 0.001:
			best_score = score
			best_base = base
	if best_base == NO_THROW and play.legs.is_empty():
		return hold_base(play.plans)
	return best_base


## First throw for a play that has not started (kept for simple callers).
static func choose_throw(plans: Array[RunnerPlan], fielding: FieldingResult, outs_before: int, tuning: BaseballTuning) -> int:
	return next_throw(ThrowPlay.new(plans, &"batter", fielding, outs_before, 0.0, tuning))


## With no out available, throw ahead of the lead runner to hold them.
static func hold_base(plans: Array[RunnerPlan]) -> int:
	var lead := NO_THROW
	for p in plans:
		if p.is_moving():
			lead = maxi(lead, p.target_base)
	return lead


static func _best_line(play: ThrowPlay, depth: int) -> float:
	var best := _score(play)
	if depth <= 0 or not play.can_throw():
		return best
	for base in BASES:
		if base == play.holder_base():
			continue
		var sim := play.copy()
		sim.throw_to(base)
		best = maxf(best, _best_line(sim, depth - 1))
	return best


static func _score(play: ThrowPlay) -> float:
	var result := play.outcome()
	var lead_bonus := 0.0
	for out in result.outs:
		lead_bonus += out["base"] * 0.1  # between equal lines, retire lead runners
	return result.outs.size() * 10.0 - result.runs.size() * 12.0 + lead_bonus - play.legs.size() * 0.05
