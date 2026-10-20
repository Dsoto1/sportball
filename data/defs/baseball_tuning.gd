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
@export var throw_release_time: float = 0.6
@export var throw_speed: float = 31.0
## Extra seconds per meter squared: long throws lose carry and need an arc.
@export var throw_long_penalty: float = 0.00012
@export var throw_arc_height: float = 2.0

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
## Time a fielder needs to apply a tag after the ball arrives.
@export var tag_time: float = 0.18

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
@export var ai_throw_min_margin: float = 0.05
@export var ai_throw_lead_runner_bias: float = 0.35
@export var ai_throw_run_prevention_bias: float = 0.6
