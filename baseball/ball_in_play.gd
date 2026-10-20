class_name BallInPlay
extends RefCounted
## One ball in play from contact to outcome, split in two stages so a human
## defender can choose the throw between them:
##   create(): trajectory -> projected fielder intercept -> runner commitments
##   resolve(throw_base): single throw -> outs, runs, final bases
## When a human steers a fielder, the projection is replaced by the result
## of LiveFielding via set_fielding() before resolve().

var contact: ContactResult
var trajectory: BallTrajectory
var fielders: Array[FielderState]
var fielding: FieldingResult
var plans: Array[RunnerPlan] = []
var batter_id: StringName
var outs_before: int
var bases_before: Array[StringName]
var tuning: BaseballTuning


static func create(p_contact: ContactResult, state: MatchState, p_tuning: BaseballTuning) -> BallInPlay:
	var bip := BallInPlay.new()
	bip.contact = p_contact
	bip.tuning = p_tuning
	bip.batter_id = state.current_batter()
	bip.outs_before = state.outs
	bip.bases_before = state.bases.duplicate()
	bip.trajectory = BallTrajectory.simulate(p_contact.exit_velocity, p_contact.launch_angle, p_contact.spray_angle, p_tuning)
	bip.fielders = FielderState.default_defense(p_tuning)
	bip.fielding = FieldingResolver.resolve(bip.trajectory, bip.fielders, p_tuning)
	if not bip.is_home_run():
		bip.plans = RunnerResolver.plan(bip.bases_before, bip.batter_id, bip.fielding, bip.outs_before, p_tuning)
	return bip


## Replaces the projected fielding with what actually happened on the field
## and lets runners re-read the play (e.g. a fly the projection called a
## catch was dropped).
func set_fielding(actual: FieldingResult) -> void:
	fielding = actual
	if not is_home_run():
		plans = RunnerResolver.plan(bases_before, batter_id, fielding, outs_before, tuning)


func is_home_run() -> bool:
	return trajectory.result == BallTrajectory.Result.HOME_RUN


func ai_throw_target() -> int:
	if is_home_run():
		return AiDefense.NO_THROW
	return AiDefense.choose_throw(plans, fielding, outs_before, tuning)


func resolve(throw_base: int) -> PlayOutcome:
	if is_home_run():
		return RunnerResolver.home_run(bases_before, batter_id)
	return RunnerResolver.resolve(plans, batter_id, fielding, throw_base, outs_before, contact.launch_angle, tuning)


## Contact-relative time by which every visible movement has finished.
func settle_time(outcome: PlayOutcome) -> float:
	if is_home_run():
		var trot := 0.0
		for advance in outcome.advances:
			trot = maxf(trot, RunnerResolver.arrival_between(advance["from"], FieldLayout.SCORED, tuning.batter_start_delay, tuning))
		return maxf(trajectory.end_time(), trot)
	var t := fielding.secure_time
	if outcome.throw_arrival != INF:
		t = maxf(t, outcome.throw_arrival)
	for p in plans:
		t = maxf(t, p.arrival_time)
	return t
