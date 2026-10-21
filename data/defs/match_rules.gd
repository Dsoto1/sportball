class_name MatchRules
extends Resource
## The league's rules package. These are rules, not feel: MatchState reads
## them. Arcade rules: 6 innings, universal DH, a mercy rule, a runner on
## second in extra innings and a pitch clock for human pitchers.

@export var display_name: String = "Arcade"
@export var innings: int = 6
@export var balls_for_walk: int = 4
@export var strikes_for_out: int = 3
## Pitchers never bat; every lineup is nine hitters.
@export var designated_hitter: bool = true
## The game ends once a team leads by this many runs after this many
## innings (0 runs = no mercy rule).
@export var mercy_runs: int = 10
@export var mercy_after_inning: int = 4
## Each extra-inning half starts with a runner on second.
@export var extras_runner_on_second: bool = true
## Seconds a human pitcher has to start the pitch before an automatic
## ball (0 = no clock).
@export var pitch_clock: float = 15.0
## Pickoff throws a pitcher may make per batter.
@export var pickoff_limit: int = 2
## Removed players cannot come back into the game.
@export var no_reentry: bool = true


static func classic(innings_count: int) -> MatchRules:
	var r := MatchRules.new()
	r.display_name = "Classic"
	r.innings = innings_count
	r.mercy_runs = 0
	r.extras_runner_on_second = false
	r.pitch_clock = 0.0
	return r
