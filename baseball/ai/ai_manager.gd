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


static func _available(state: MatchState, team: int, id: StringName) -> bool:
	return id != &"" and not state.removed.has(id) and state.pitcher(team) != id
