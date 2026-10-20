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
## Runner id -> m/s from ratings; the batting team's run aggression.
var runner_speeds: Dictionary = {}
var runner_aggression: float = 0.0


## roster: who the MatchState ids are (ratings, personalities); null plays
## everyone at league average.
static func create(p_contact: ContactResult, state: MatchState, p_tuning: BaseballTuning, roster: MatchRoster = null) -> BallInPlay:
	var bip := BallInPlay.new()
	bip.contact = p_contact
	bip.tuning = p_tuning
	bip.batter_id = state.current_batter()
	bip.outs_before = state.outs
	bip.bases_before = state.bases.duplicate()
	bip.trajectory = BallTrajectory.simulate(p_contact.exit_velocity, p_contact.launch_angle, p_contact.spray_angle, p_tuning)
	var players := {}
	if roster != null:
		for pos: StringName in state.defense[state.fielding_team()]:
			players[pos] = roster.player(state.defense[state.fielding_team()][pos])
		for id in [bip.batter_id] + Array(bip.bases_before):
			if id != &"":
				bip.runner_speeds[id] = Ratings.runner_speed(roster.player(id), p_tuning)
		var club := roster.teams[state.batting_team()]
		bip.runner_aggression = club.runner_aggression
	bip.fielders = FielderState.default_defense(p_tuning, players)
	bip.fielding = FieldingResolver.resolve(bip.trajectory, bip.fielders, p_tuning)
	return bip


func is_home_run() -> bool:
	return trajectory.result == BallTrajectory.Result.HOME_RUN


## rng enables fielding errors; without one the play is error-free.
func start_live(auto_secure: bool = true, rng: MatchRng = null) -> LivePlay:
	var play := LivePlay.new(bases_before, batter_id, outs_before, contact.launch_angle, trajectory, fielding, tuning, auto_secure,
		fielders, runner_speeds, runner_aggression)
	play.rng = rng
	return play


## Resolves the whole play with the AI on both sides.
func resolve_ai(rng: MatchRng = null) -> PlayOutcome:
	if is_home_run():
		return RunnerResolver.home_run(bases_before, batter_id)
	return start_live(true, rng).run_ai(tuning.sim_play_step)


## Seconds the home run trot takes (presentation pacing).
func home_run_settle_time() -> float:
	var trot := RunnerResolver.arrival_between(FieldLayout.HOME, FieldLayout.SCORED, tuning.batter_start_delay, tuning)
	return maxf(trajectory.end_time(), trot)
