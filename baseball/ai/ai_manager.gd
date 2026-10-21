class_name AiManager
extends RefCounted
## The dugout AI: when to go to the bullpen. Called between batters.
## Pulls a tired pitcher once fatigue passes the team's hook, and brings
## the closer in to protect a close lead in the last scheduled inning.

const CLOSE_LEAD := 3


## Reliever id the fielding team should bring in now, or &"" to stay.
static func pitching_change(state: MatchState, roster: MatchRoster, tuning: BaseballTuning) -> StringName:
	if roster == null or state.game_over or state.balls != 0 or state.strikes != 0:
		return &""
	var team := state.fielding_team()
	var club := roster.teams[team]
	var current := state.pitcher(team)
	if current == &"":
		return &""
	var closer: StringName = club.bullpen[club.bullpen.size() - 1] if not club.bullpen.is_empty() else &""
	var lead := state.score[team] - state.score[state.batting_team()]
	var save_spot := state.inning >= state.innings_scheduled and lead > 0 and lead <= CLOSE_LEAD
	if save_spot and closer != &"" and current != closer and _available(state, team, closer):
		return closer
	var tired := Ratings.fatigue(roster.player(current), state.pitches_thrown(current), tuning)
	if tired < club.bullpen_hook:
		return &""
	for id in club.bullpen:
		if id != closer and _available(state, team, id):
			return id
	return closer if _available(state, team, closer) else &""


## Runners the offense sends on this pitch: start base -> jump delay (s).
## The AI runs when its estimate of success clears the bar, more often for
## clubs with a high steal rate; never steals home or third with two outs.
static func steal_attempts(state: MatchState, roster: MatchRoster, tuning: BaseballTuning, rng: MatchRng) -> Dictionary:
	var sends := {}
	if state.game_over or state.balls == 3 and state.runner_on(1) != &"":
		return sends  # ball four moves him anyway
	var club := roster.teams[state.batting_team()] if roster != null else null
	var rate := club.steal_rate if club != null else 1.0
	var bar := tuning.ai_steal_min_success - 0.06 * (rate - 1.0)
	var catcher := roster.player(state.defense[state.fielding_team()].get(&"c", &"")) if roster != null else null
	var arm := 1.0 + tuning.rating_arm_spread * Ratings.norm(catcher.arm) if catcher != null else 1.0
	for base in [2, 1]:
		var id := state.runner_on(base)
		if id == &"" or (state.runner_on(base + 1) != &"" and not sends.has(base + 1)):
			continue
		if base == 2 and state.outs == 2:
			continue
		var runner := roster.player(id) if roster != null else null
		var speed := Ratings.runner_speed(runner, tuning)
		var jump := Ratings.steal_jump(runner, tuning)
		# Runners know pitchers slide-step on threats about half the time.
		var chance := 0.5 * (success_chance(base, speed, arm, tuning, false, jump) + success_chance(base, speed, arm, tuning, true, jump))
		if chance < bar:
			continue
		if sends.has(base + 1) or rng.chance(tuning.ai_steal_attempt_rate * rate):
			sends[base] = maxf(jump + rng.randfn(0.0, tuning.steal_jump_sigma), -0.2)
	return sends


## Base the AI pitcher throws over to before this pitch, or 0. He reads a
## runner who is leaning to steal (leaning: start base -> anything) some of
## the time, and otherwise keeps fast runners with an open base honest.
static func pickoff_choice(state: MatchState, roster: MatchRoster, tuning: BaseballTuning, rng: MatchRng, leaning: Dictionary = {}) -> int:
	if not state.can_pickoff():
		return 0
	for base: int in leaning:
		if state.runner_on(base) != &"" and rng.chance(tuning.ai_pickoff_read):
			return base
	for base in [1, 2]:
		var id := state.runner_on(base)
		if id == &"" or state.runner_on(base + 1) != &"":
			continue
		var p := roster.player(id) if roster != null else null
		var threat := 1.0 + (Ratings.norm(p.speed) if p != null else 0.0)
		if rng.chance(tuning.ai_pickoff_rate * threat):
			return base
	return 0


## Does the AI pitcher use the slide step on this pitch? More often with a
## fast runner who has an open base, and usually when he reads a lean.
static func slide_step(state: MatchState, roster: MatchRoster, tuning: BaseballTuning, rng: MatchRng, leaning: Dictionary = {}) -> bool:
	for base: int in leaning:
		if state.runner_on(base) != &"" and rng.chance(tuning.ai_slide_step_read):
			return true
	for base in [1, 2]:
		var id := state.runner_on(base)
		if id == &"" or state.runner_on(base + 1) != &"":
			continue
		var p := roster.player(id) if roster != null else null
		var threat := maxf(Ratings.norm(p.speed) if p != null else 0.0, 0.0)
		if threat > 0.0 and rng.chance(tuning.ai_slide_step_rate * threat):
			return true
	return false


## Rough chance a runner steals the next base against a catcher's arm,
## from the same race the live play runs (average jump, average pitch).
static func success_chance(base: int, speed: float, arm: float, tuning: BaseballTuning, slide_step: bool = false, jump: float = -1.0) -> float:
	var head := LivePlay.steal_head_start(speed, 0.48, jump if jump >= 0.0 else tuning.steal_jump_delay, tuning, -1.0, slide_step)
	var runner := (FieldLayout.BASE_DISTANCE - head) / speed
	var throw := tuning.catcher_transfer_time + tuning.catcher_release_time \
		+ ThrowModel.flight_time(Vector3(0, 0, 0.9), FieldLayout.base_position(base + 1), tuning, arm) + tuning.tag_reach / speed
	var margin := throw - runner
	return 1.0 / (1.0 + exp(-1.7 * margin / tuning.steal_jump_sigma))


static func _available(state: MatchState, team: int, id: StringName) -> bool:
	return id != &"" and not state.removed.has(id) and state.pitcher(team) != id
