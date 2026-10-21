class_name Ratings
extends RefCounted
## How 0..100 player ratings change play. Every effect is a gentle scale
## around league average (50), so a star is better but not a different
## sport. The spreads are feel values and live in BaseballTuning.


## -1 at 0, 0 at 50, +1 at 100.
static func norm(rating: int) -> float:
	return clampf((rating - 50) / 50.0, -1.0, 1.0)


## Pitch speed, command scatter, break and deception for a pitcher who has
## thrown `pitches` so far. {speed, scatter, break, deception, fatigue}
static func pitcher_mods(p: PlayerDef, pitches: int, tuning: BaseballTuning) -> Dictionary:
	if p == null:
		return {}
	var tired := fatigue(p, pitches, tuning)
	return {
		"speed": (1.0 + tuning.rating_velocity_spread * norm(p.velocity)) * (1.0 - tuning.fatigue_speed_loss * tired),
		"scatter": (1.0 - tuning.rating_control_spread * norm(p.control)) * (1.0 + tuning.fatigue_scatter_gain * tired),
		"break": 1.0 + tuning.rating_stuff_break_spread * norm(p.stuff) - tuning.fatigue_break_loss * tired,
		"deception": tuning.rating_stuff_deception_spread * norm(p.stuff),
		"fatigue": tired,
		"lefty": p.throws == &"L",
	}


## 0 while fresh, 1 when out of gas. Stamina sets how many pitches come free.
static func fatigue(p: PlayerDef, pitches: int, tuning: BaseballTuning) -> float:
	var fresh := lerpf(tuning.stamina_pitches_min, tuning.stamina_pitches_max, p.stamina / 100.0)
	return clampf((pitches - fresh) / tuning.fatigue_ramp_pitches, 0.0, 1.0)


## Timing window and exit-velocity scales for a batter.
static func apply_batter(swing: SwingIntent, p: PlayerDef, tuning: BaseballTuning) -> void:
	if p == null:
		return
	swing.window_scale *= 1.0 + tuning.rating_contact_window_spread * norm(p.contact)
	swing.bats_left = p.bats_left()
	# His swing: bat speed (mostly from power) drives exit velocity, the
	# attack angle and direction shape the launch and spray.
	var s := SwingProfile.for_player(p)
	swing.power_scale = 1.0 + tuning.bat_speed_ev_per_mph * (float(s["bat_speed"]) - SwingProfile.LEAGUE_BAT_SPEED)
	swing.attack_angle = s["attack_angle"]
	swing.window_scale *= 1.0 - tuning.attack_angle_window * (float(s["attack_angle"]) - SwingProfile.LEAGUE_ATTACK_ANGLE)
	swing.attack_pull = s["pull"]
	swing.tilt = s["tilt"]


## Multiplier on the AI's read noise and chase rate when this player bats.
static func eye_scale(p: PlayerDef, tuning: BaseballTuning) -> float:
	return 1.0 if p == null else 1.0 - tuning.rating_eye_spread * norm(p.eye)


## A runner's average steal jump delay (fast runners read pitchers better).
static func steal_jump(p: PlayerDef, tuning: BaseballTuning) -> float:
	return tuning.steal_jump_delay - (tuning.rating_jump_spread * norm(p.speed) if p != null else 0.0)


static func runner_speed(p: PlayerDef, tuning: BaseballTuning) -> float:
	return tuning.runner_speed * (1.0 if p == null else 1.0 + tuning.rating_speed_spread * norm(p.speed))


## Fielder physicals from a player: speed, reach, first step, arm, glove.
static func apply_fielder(f: FielderState, p: PlayerDef, tuning: BaseballTuning) -> void:
	if p == null:
		return
	f.player_id = p.id
	f.speed *= 1.0 + tuning.rating_fielder_speed_spread * norm(p.speed)
	f.reach += tuning.rating_glove_reach_spread * norm(p.glove)
	f.reaction -= tuning.rating_glove_reaction_spread * norm(p.glove)
	f.arm = 1.0 + tuning.rating_arm_spread * norm(p.arm)
	f.error_scale = 1.0 - tuning.rating_error_spread * norm(p.glove)
	f.throw_error_scale = 1.0 - tuning.rating_error_spread * norm(p.arm)
