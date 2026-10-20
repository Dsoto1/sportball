class_name BallInPlay
extends RefCounted
## One ball in play from contact to outcome:
##   create(): trajectory -> projected fielder intercept -> runners' read
##   start_live(): a LivePlay for runners, throws, forces, tags, rundowns
## Interactive play steps the LivePlay itself (with LiveFielding when a
## human fields); resolve_ai() runs it to the end with the AI on both sides.

var contact: ContactResult
var trajectory: BallTrajectory
var fielders: Array[FielderState]
var fielding: FieldingResult
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
	return bip


func is_home_run() -> bool:
	return trajectory.result == BallTrajectory.Result.HOME_RUN


func start_live(auto_secure: bool = true) -> LivePlay:
	return LivePlay.new(bases_before, batter_id, outs_before, contact.launch_angle, trajectory, fielding, tuning, auto_secure)


## Resolves the whole play with the AI on both sides.
func resolve_ai() -> PlayOutcome:
	if is_home_run():
		return RunnerResolver.home_run(bases_before, batter_id)
	return start_live().run_ai(tuning.sim_play_step)


## Seconds the home run trot takes (presentation pacing).
func home_run_settle_time() -> float:
	var trot := RunnerResolver.arrival_between(FieldLayout.HOME, FieldLayout.SCORED, tuning.batter_start_delay, tuning)
	return maxf(trajectory.end_time(), trot)
