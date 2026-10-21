class_name BaseballTuning
extends Resource
## Balance values for Phase 0 baseball. Every gameplay number that is a
## matter of feel (not a rule of baseball) belongs here, not in code.
## Distances are meters, speeds m/s, times seconds, angles degrees.
## Coordinates: home plate at origin, +Y up, center field toward -Z,
## first-base side toward +X.

@export_group("Match Format")
@export var innings: int = 6
@export var max_pitches_per_match: int = 3000

@export_group("Strike Zone")
## Half width of the zone in the plate plane, ball radius included.
@export var zone_half_width: float = 0.26
@export var zone_bottom: float = 0.48
@export var zone_top: float = 1.10
## Furthest a pitch can end up from the zone center (wild pitch clamp).
@export var wild_limit: Vector2 = Vector2(0.9, 0.9)
## Bounds of the pitcher's aim cursor in the plate plane.
@export var cursor_min: Vector2 = Vector2(-0.55, 0.15)
@export var cursor_max: Vector2 = Vector2(0.55, 1.55)

@export_group("Pitching")
@export var release_distance: float = 17.5
@export var release_height: float = 1.85
@export var release_side: float = -0.35
## Gaussian sigma of pitch scatter at a perfect and at a fully missed meter.
@export var pitch_scatter_min: float = 0.025
@export var pitch_scatter_max: float = 0.30
## Velocity multiplier when the meter is fully missed (lerped by error).
@export var pitch_speed_at_max_error: float = 0.92
## Seconds for one full sweep of the pitch meter (0 -> 1).
@export var pitch_meter_sweep_time: float = 1.1
## Meter position that produces a perfect pitch.
@export var pitch_meter_sweet_spot: float = 0.88

@export_group("Batting")
@export var contact_timing_window: float = 0.078
@export var power_timing_window: float = 0.052
## Normalized timing error beyond the hit window that still produces a foul.
@export var foul_timing_band: float = 1.5
## Pitches within this many zone half-sizes of center cost no quality.
@export var sweet_zone: float = 0.5
## Quality lost per zone half-size beyond the sweet zone.
@export var location_penalty: float = 0.5
@export var power_location_penalty_scale: float = 1.35
## Pitches farther than this (zone half-sizes) cannot be reached: whiff.
@export var reach_limit: float = 2.1
## Weight of squared timing error in the quality calculation.
@export var timing_weight: float = 0.8
## Quality below this is a foul tip / dribbler foul instead of a fair ball.
@export var min_fair_quality: float = 0.22
@export var exit_velocity_min: float = 27.0
@export var contact_exit_velocity_max: float = 42.0
@export var power_exit_velocity_max: float = 51.0
## Exponent on quality when mapping to exit velocity (<1 = forgiving).
@export var exit_velocity_curve: float = 0.7
@export var contact_base_launch: float = 9.0
@export var power_base_launch: float = 19.0
## Degrees of loft from a full stick up (or chop from full down).
@export var stick_lift: float = 20.0
## Degrees of launch per zone half-height above center (high pitches lift).
@export var launch_per_height: float = 8.0
@export var launch_noise: float = 4.0
## Extra launch sigma (degrees) for a total mishit (quality 0).
@export var mishit_launch_spread: float = 34.0
## Degrees of spray per normalized timing error (early = pull).
@export var spray_per_timing: float = 40.0
## Degrees of spray from pitch horizontal location (outside = opposite field).
@export var spray_per_location: float = 9.0
@export var spray_noise: float = 4.0
## Degrees of spray from a full stick left/right.
@export var stick_spray: float = 15.0
## Extra spray sigma (degrees) for a total mishit.
@export var mishit_spray_spread: float = 12.0
@export var contact_height: float = 0.9
## Seconds of display + input latency subtracted from human swing timing.
## A per-player calibration value; 0 until a calibration screen exists.
@export var swing_latency_calibration: float = 0.0
## Seconds after the batter is allowed to swing before a no-swing is a take.
@export var swing_late_cutoff: float = 0.22

@export_group("Bunting")
## Bunts square early: a wide timing window, but they reach less of the plate.
@export var bunt_timing_window: float = 0.075
@export var bunt_reach_limit: float = 1.7
@export var bunt_min_fair_quality: float = 0.5
## Exit velocity of a good bunt, plus more for a poor one (it gets on a fielder).
@export var bunt_exit_velocity: float = 9.5
@export var bunt_mishit_velocity: float = 13.0
@export var bunt_velocity_noise: float = 1.2
@export var bunt_launch: float = -14.0
## Degrees of loft per zone half-height above center: high pitches pop up.
@export var bunt_launch_per_height: float = 22.0
@export var bunt_launch_noise: float = 5.0
@export var bunt_mishit_launch: float = 22.0
## Degrees of spray from a full stick left/right (placing the bunt).
@export var bunt_placement: float = 32.0
@export var bunt_spray_per_timing: float = 10.0
@export var bunt_spray_noise: float = 5.0
## On a bunt the runners have their secondary lead and break at once.
@export var bunt_runner_jump: float = 2.5
## Catcher's first step on a bunt in front of the plate (he has to get up).
@export var bunt_catcher_reaction: float = 0.85

@export_group("Assists")
## Rookie assist for a human batter (toggle in game with T).
@export var rookie_assist: bool = true
@export var assist_pitch_speed_scale: float = 0.85
@export var assist_timing_window_scale: float = 1.3
## Human fielder under Rookie assist: speed multiplier, extra glove reach,
## and auto-routing to the ball while the stick is at rest.
@export var assist_fielder_speed_scale: float = 1.12
@export var assist_reach_bonus: float = 0.35

@export_group("Ball Flight")
@export var gravity: float = 9.81
## Quadratic drag coefficient k in a = -k|v|v.
@export var drag: float = 0.0042
@export var sim_step: float = 0.0083333
@export var max_flight_time: float = 12.0
@export var bounce_restitution: float = 0.38
@export var bounce_friction: float = 0.88
@export var bounce_min_speed: float = 3.0
@export var roll_deceleration: float = 4.0
@export var stop_speed: float = 0.35
@export var foul_line_angle: float = 45.0

@export_group("Field")
@export var fence_center: float = 112.0
@export var fence_line: float = 92.0
@export var fence_height: float = 3.2
@export var fence_restitution: float = 0.3
## The park being played in: wall distances and heights by angle, and the
## air. Null uses fence_center / fence_line / fence_height above.
@export var field_shape: FieldShape
## A ball played off the wall costs the fielder this long to pick up.
@export var wall_carom_delay: float = 0.8

@export_group("Fielding")
@export var fielder_ids: Array[StringName] = [&"p", &"c", &"1b", &"2b", &"ss", &"3b", &"lf", &"cf", &"rf"]
@export var fielder_spots: PackedVector3Array = PackedVector3Array([
	Vector3(0.0, 0.0, -18.0),
	Vector3(0.0, 0.0, 1.4),
	Vector3(20.5, 0.0, -25.0),
	Vector3(9.0, 0.0, -37.0),
	Vector3(-10.0, 0.0, -36.0),
	Vector3(-20.5, 0.0, -24.0),
	Vector3(-42.0, 0.0, -70.0),
	Vector3(0.0, 0.0, -86.0),
	Vector3(42.0, 0.0, -70.0),
])
@export var fielder_speed: float = 6.2
@export var fielder_reaction: float = 0.5
@export var catch_reach: float = 0.75
## Extra horizontal reach available by diving.
@export var dive_reach: float = 1.4
@export var dive_recovery: float = 0.7
@export var catch_max_height: float = 2.6
## Control passes to a teammate on a ball on the ground once the human's
## fielder is this far from it and the teammate is within this share of that.
@export var auto_switch_min_gap: float = 8.0
@export var auto_switch_ratio: float = 0.5
@export var throw_release_time: float = 0.6
@export var throw_speed: float = 31.0
## Extra seconds per meter squared: long throws lose carry and need an arc.
@export var throw_long_penalty: float = 0.00012
@export var throw_arc_height: float = 2.0
## Catch-to-release time for a fielder receiving a throw and throwing on
## (the double-play pivot).
@export var relay_release_time: float = 0.45
## Outfield throws at least this long go through a cutoff man.
@export var cutoff_min_throw: float = 45.0
## Where the cutoff lines up: this far from the target base (at most halfway).
@export var cutoff_distance_from_base: float = 30.0
## Cutoff man's catch-and-relay time (quicker than a full pivot).
@export var cutoff_release_time: float = 0.3
## A fielder this close to the target base runs it there instead of throwing.
@export var unassisted_distance: float = 5.0

@export_group("Errors")
## Chance a ground ball is bobbled, plus more per m/s of ball speed.
@export var bobble_chance: float = 0.008
@export var bobble_chance_per_speed: float = 0.0006
## A bobbled ball ends up this far along its path; the fielder loses this long.
@export var bobble_roll: float = 1.8
@export var bobble_time: float = 0.75
## Chance a dive that reaches the ball fails to hold it (the ball gets past).
@export var dive_drop_chance: float = 0.3
@export var dive_miss_roll: float = 7.0
@export var dive_miss_delay: float = 1.3
## Chance a throw sails, plus more per meter of throw.
@export var throw_error_chance: float = 0.006
@export var throw_error_per_meter: float = 0.0003
## Where a wild throw ends up: up to this far to one side, and this far
## past the target (into foul ground or the gap, where a backup gets it).
@export var wild_throw_side: float = 5.0
@export var wild_throw_past_min: float = 6.0
@export var wild_throw_past_max: float = 22.0
## Backup's pickup time plus his run, as a share of the distance it got away.
@export var wild_throw_pickup: float = 0.4
@export var wild_throw_run_share: float = 0.6
## Error chances for a human fielder under Rookie assist are scaled by this.
@export var assist_error_scale: float = 0.5

@export_group("Base Running")
@export var runner_speed: float = 8.0
@export var batter_start_delay: float = 0.25
@export var runner_read_delay: float = 0.12
## Lead off the bag runners already have when the ball is put on the ground.
@export var runner_lead_distance: float = 4.0
@export var tag_up_delay: float = 0.15
@export var base_turn_penalty: float = 0.25
## Runners only take a base when they beat the projected throw by this much.
@export var runner_safety_margin: float = 0.35
@export var two_out_safety_margin: float = 0.15
## A runner standing on a base takes the next one on a throw (or tags up)
## only when beating the ball there by this much.
@export var runner_take_base_margin: float = 0.7
## Time a fielder needs to apply a tag after the ball arrives (planning).
@export var tag_time: float = 0.18
## Ball holder tags a runner off the bag within this distance.
@export var tag_reach: float = 1.1
## Stop-and-turn time when a runner reverses direction.
@export var runner_reverse_time: float = 0.3
## After a decision, AI runners wait this long before changing their minds.
@export var runner_decision_lock: float = 0.25
## How far a cover steps off the bag toward a runner hung up nearby.
@export var cover_close_in: float = 7.0
## The ball holder chases runners off a bag within this distance.
@export var rundown_chase_range: float = 20.0
## A human holder idle for this long gets the AI throw.
@export var human_throw_decision_window: float = 0.6
## Play ends once every runner has been standing still this long.
@export var play_settle_time: float = 0.2
## Safety net: a rundown still going after this long ends with a tag.
@export var max_play_time: float = 25.0
## Fixed step for the live play when no human is driving it (AI sims).
@export var sim_play_step: float = 0.0166667

@export_group("Ratings")
## Each value is the effect of a 100 rating (a 0 rating is the mirror
## image); 50 is league average and changes nothing.
@export var rating_velocity_spread: float = 0.06
@export var rating_control_spread: float = 0.35
@export var rating_stuff_break_spread: float = 0.35
@export var rating_stuff_deception_spread: float = 0.15
@export var rating_contact_window_spread: float = 0.18
@export var rating_power_ev_spread: float = 0.07
@export var rating_eye_spread: float = 0.35
@export var rating_speed_spread: float = 0.1
@export var rating_fielder_speed_spread: float = 0.08
@export var rating_glove_reach_spread: float = 0.15
@export var rating_glove_reaction_spread: float = 0.06
@export var rating_arm_spread: float = 0.1
@export var rating_error_spread: float = 0.6
## Seconds of steal jump a 100-speed runner gains reading the pitcher.
@export var rating_jump_spread: float = 0.12
## Pitches thrown before fatigue sets in, for stamina 0 and 100.
@export var stamina_pitches_min: float = 20.0
@export var stamina_pitches_max: float = 90.0
## Pitches from first fatigue to empty.
@export var fatigue_ramp_pitches: float = 30.0
@export var fatigue_speed_loss: float = 0.06
@export var fatigue_scatter_gain: float = 0.9
@export var fatigue_break_loss: float = 0.3

@export_group("Stealing")
## Seconds from a stealing runner's first move to the pitch's release.
@export var steal_delivery_time: float = 0.95
## Spread of the runner's jump (seconds lost reading the pitcher).
@export var steal_jump_sigma: float = 0.25
## Average jump delay for the AI (a human pays for pressing late instead).
@export var steal_jump_delay: float = 0.15
## Ground lost getting up to speed from a standing lead (in seconds of running).
@export var steal_start_penalty: float = 0.55
## Catcher: catch-to-throw transfer, then a quick release.
@export var catcher_transfer_time: float = 0.3
@export var catcher_release_time: float = 0.35

@export_group("Slide Step")
## A slide step (quick delivery) gives a stealing runner this much less time.
@export var slide_step_time_saved: float = 0.18
## ...and costs command (scatter multiplier) and a little velocity.
@export var slide_step_scatter: float = 1.4
@export var slide_step_speed: float = 0.97
## Share of the normal windup the quick delivery takes on screen.
@export var slide_step_windup_share: float = 0.55
## AI pitcher: chance of a slide step with a dangerous runner on (times his
## speed threat), and when he reads a runner leaning to steal.
@export var ai_slide_step_rate: float = 0.15
@export var ai_slide_step_read: float = 0.25

@export_group("Pickoffs")
## Pitcher's step-off-and-throw time to a base.
@export var pickoff_release_time: float = 0.3
## A runner with a normal lead reacts this fast and dives back.
@export var pickoff_runner_reaction: float = 0.2
## A runner leaning to steal is this much farther off and slower to react.
@export var lean_distance: float = 1.8
@export var lean_reaction: float = 0.35
## Spread of a runner's reaction to the pickoff move.
@export var pickoff_reaction_sigma: float = 0.12
## Each throw over shrinks that runner's lead (for the rest of the at-bat).
@export var pickoff_lead_shrink: float = 0.6
@export var min_lead: float = 2.5
## AI pitcher: chance per pitch of a throw over to a dangerous runner, and
## of reading a runner who is leaning to steal.
@export var ai_pickoff_rate: float = 0.025
@export var ai_pickoff_read: float = 0.12

@export_group("AI")
@export var ai_pitcher_meter_sigma: float = 0.22
@export var ai_pitcher_edge_bias: float = 1.7
@export var ai_batter_read_sigma: float = 0.07
@export var ai_batter_timing_sigma: float = 0.055
## Sigma of the AI's stick input on each axis.
@export var ai_batter_stick_sigma: float = 0.35
@export var ai_swing_in_zone: float = 0.7
@export var ai_swing_chase: float = 0.2
@export var ai_two_strike_protect: float = 0.15
## Swing chance multiplier on the first pitch of a plate appearance.
@export var ai_first_pitch_patience: float = 0.75
@export var ai_power_swing_rate: float = 0.35
## Chance per pitch an AI runner with a good read goes (times the team's steal rate).
@export var ai_steal_attempt_rate: float = 0.14
## Estimated success the AI needs before it runs (lower for aggressive clubs).
@export var ai_steal_min_success: float = 0.68
## Chance per pitch of a sacrifice bunt in a bunting spot (times the team's rate).
@export var ai_sac_bunt_rate: float = 0.22
## Chance a fast batter (speed 75+) bunts for a hit on a given pitch.
@export var ai_bunt_hit_rate: float = 0.06
@export var ai_throw_min_margin: float = 0.05
@export var ai_throw_lead_runner_bias: float = 0.35
@export var ai_throw_run_prevention_bias: float = 0.6
