class_name AiDefense
extends RefCounted
## Chooses where the fielder throws. Tactical evaluation only; personality
## weights arrive in Phase 4.

const NO_THROW := -1


static func choose_throw(plans: Array[RunnerPlan], fielding: FieldingResult, outs_before: int, tuning: BaseballTuning) -> int:
	var outs := outs_before + (1 if fielding.caught_in_air else 0)
	if not fielding.has_fielder() or outs >= MatchState.OUTS_PER_HALF:
		return NO_THROW
	var best_base := NO_THROW
	var best_score := -INF
	for p in plans:
		if not p.is_moving():
			continue
		var needed := RunnerResolver.ball_arrival(fielding, p.target_base, tuning)
		if not p.forced:
			needed += tuning.tag_time
		var margin := p.arrival_time - needed
		if margin <= tuning.ai_throw_min_margin:
			continue
		var score := margin + p.target_base * tuning.ai_throw_lead_runner_bias
		if p.target_base == FieldLayout.SCORED:
			score += tuning.ai_throw_run_prevention_bias
		if outs == MatchState.OUTS_PER_HALF - 1 and p.forced:
			# A sure force ends the inning and cancels every run on the play.
			score += 10.0
		if score > best_score:
			best_score = score
			best_base = p.target_base
	if best_base != NO_THROW:
		return best_base
	return hold_base(plans)


## With no out available, throw ahead of the lead runner to hold them.
static func hold_base(plans: Array[RunnerPlan]) -> int:
	var lead := NO_THROW
	for p in plans:
		if p.is_moving():
			lead = maxi(lead, p.target_base)
	return lead
