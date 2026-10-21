class_name BallInPlay
extends RefCounted
## One ball in play from contact to outcome:
##   create(): trajectory -> projected fielder intercept -> runners' read
##   start_live(): a LivePlay for runners, throws, forces, tags, rundowns
##   create_steal(): the same for a stolen-base attempt on a pitch not put
##   in play (the catcher has the ball, nobody batting)
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
## A steal: start base -> meters off the bag when the catcher has the ball.
var steal_heads: Dictionary = {}
## A pickoff: the base thrown to (0 = not a pickoff), the runner's lead and
## how fast he gets back.
var pickoff_base: int = 0
var pickoff_lead: float = 0.0
var pickoff_reaction: float = 0.0


func is_steal() -> bool:
	return not steal_heads.is_empty()


func is_pickoff() -> bool:
	return pickoff_base > 0


## Between pitches: a steal or a pickoff, not a batted ball.
func is_runner_play() -> bool:
	return is_steal() or is_pickoff()


## A runner's lead off his bag: the normal lead, less what pickoff throws
## have taken off it this plate appearance.
static func lead_for(state: MatchState, runner_id: StringName, p_tuning: BaseballTuning) -> float:
	return maxf(p_tuning.runner_lead_distance - state.lead_cut.get(runner_id, 0.0), p_tuning.min_lead)


## A pickoff throw to `base`. leaning: the runner there was about to steal.
## rng varies how quickly he reads the move.
static func create_pickoff(state: MatchState, p_tuning: BaseballTuning, roster: MatchRoster, base: int, leaning: bool, rng: MatchRng = null) -> BallInPlay:
	var id := state.runner_on(base) if base >= 1 and base <= 3 else &""
	if id == &"" or state.game_over:
		return null
	var bip := BallInPlay.new()
	bip.tuning = p_tuning
	bip.batter_id = state.current_batter()
	bip.outs_before = state.outs
	bip.bases_before = state.bases.duplicate()
	bip._read_roster(state, roster)
	bip.contact = ContactResult.new()
	bip.pickoff_base = base
	bip.pickoff_lead = lead_for(state, id, p_tuning) + (p_tuning.lean_distance if leaning else 0.0)
	bip.pickoff_reaction = p_tuning.lean_reaction if leaning else p_tuning.pickoff_runner_reaction
	if rng != null:
		bip.pickoff_reaction = maxf(bip.pickoff_reaction + rng.randfn(0.0, p_tuning.pickoff_reaction_sigma), 0.05)
	var play := bip.start_live(false)
	bip.trajectory = play.trajectory
	bip.fielding = play.projection
	return bip


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
	bip._read_roster(state, roster)
	if p_contact.is_bunt:
		# The catcher has to come up out of his crouch to field a bunt.
		var c := p_tuning.fielder_ids.find(&"c")
		if c >= 0:
			bip.fielders[c].reaction = maxf(bip.fielders[c].reaction, p_tuning.bunt_catcher_reaction)
	bip.fielding = FieldingResolver.resolve(bip.trajectory, bip.fielders, p_tuning)
	return bip


## A steal attempt after a pitch that was not put in play. stealers: start
## base -> jump delay (s), for runners who are still there to go; travel:
## the pitch's flight time. Returns null when nobody is left to steal.
static func create_steal(state: MatchState, p_tuning: BaseballTuning, roster: MatchRoster, stealers: Dictionary, travel: float) -> BallInPlay:
	if state.game_over:
		return null
	var bip := BallInPlay.new()
	bip.tuning = p_tuning
	bip.batter_id = state.current_batter()
	bip.outs_before = state.outs
	bip.bases_before = state.bases.duplicate()
	bip._read_roster(state, roster)
	for base: int in stealers:
		var id := state.bases[base - 1]
		var open := base == 3 or state.bases[base] == &"" or stealers.has(base + 1)
		if id != &"" and open:
			var speed: float = bip.runner_speeds.get(id, p_tuning.runner_speed)
			bip.steal_heads[base] = LivePlay.steal_head_start(speed, travel, stealers[base], p_tuning, lead_for(state, id, p_tuning))
	if bip.steal_heads.is_empty():
		return null
	bip.contact = ContactResult.new()
	var play := LivePlay.steal_play(bip.bases_before, bip.steal_heads, bip.outs_before, p_tuning, bip.fielders, bip.runner_speeds, bip.runner_aggression)
	bip.trajectory = play.trajectory
	bip.fielding = play.projection
	return bip


## Speeds for everyone on base and the batter, the defense's fielders and
## the offense's aggression.
func _read_roster(state: MatchState, roster: MatchRoster) -> void:
	var players := {}
	if roster != null:
		for pos: StringName in state.defense[state.fielding_team()]:
			players[pos] = roster.player(state.defense[state.fielding_team()][pos])
		for id in [batter_id] + Array(bases_before):
			if id != &"":
				runner_speeds[id] = Ratings.runner_speed(roster.player(id), tuning)
		runner_aggression = roster.teams[state.batting_team()].runner_aggression
	else:
		for id in [batter_id] + Array(bases_before):
			if id != &"":
				runner_speeds[id] = tuning.runner_speed
	fielders = FielderState.default_defense(tuning, players)


func is_home_run() -> bool:
	return trajectory.result == BallTrajectory.Result.HOME_RUN


## rng enables fielding errors; without one the play is error-free.
func start_live(auto_secure: bool = true, rng: MatchRng = null) -> LivePlay:
	if is_pickoff():
		return LivePlay.pickoff_play(bases_before, pickoff_base, pickoff_lead, pickoff_reaction, outs_before, tuning, fielders, runner_speeds, runner_aggression, rng)
	if is_steal():
		var steal := LivePlay.steal_play(bases_before, steal_heads, outs_before, tuning, fielders, runner_speeds, runner_aggression)
		steal.rng = rng
		return steal
	var play := LivePlay.new(bases_before, batter_id, outs_before, contact.launch_angle, trajectory, fielding, tuning, auto_secure,
		fielders, runner_speeds, runner_aggression)
	play.rng = rng
	if contact.is_bunt:
		play.start_bunt()
	return play


## Resolves the whole play with the AI on both sides.
func resolve_ai(rng: MatchRng = null) -> PlayOutcome:
	if not is_runner_play() and is_home_run():
		return RunnerResolver.home_run(bases_before, batter_id)
	return start_live(true, rng).run_ai(tuning.sim_play_step)


## Seconds the home run trot takes (presentation pacing).
func home_run_settle_time() -> float:
	var trot := RunnerResolver.arrival_between(FieldLayout.HOME, FieldLayout.SCORED, tuning.batter_start_delay, tuning)
	return maxf(trajectory.end_time(), trot)
