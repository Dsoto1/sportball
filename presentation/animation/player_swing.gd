class_name PlayerSwing
extends RefCounted
## The swing animation's view of a hitter's SwingProfile (the rules' copy):
## the same numbers in the bat path's terms (attack_lift, attack_yaw with +
## toward the opposite field), plus the slot depth that gives his tilt.

const LEAGUE_BAT_SPEED := SwingProfile.LEAGUE_BAT_SPEED
const BAT_SPEED := SwingProfile.BAT_SPEED
## How much the swing button changes the shown bat speed (mph).
const POWER_SWING := 3.0
const CONTACT_SWING := -2.0

static var _cache := {}


## {bat_speed, attack_lift, attack_yaw, tilt, slot_lift} for a hitter.
static func for_player(p: PlayerDef, style: StringName) -> Dictionary:
	var key := "%s/%s/%d/%d" % [p.id if p != null else &"", style, p.power if p != null else 50, p.contact if p != null else 50]
	if _cache.has(key):
		return _cache[key]
	var s := SwingProfile.for_player(p)
	var out := {"bat_speed": s["bat_speed"], "attack_lift": s["attack_angle"], "attack_yaw": -float(s["pull"]), "tilt": s["tilt"]}
	out["slot_lift"] = BattingStyles.slot_for_tilt(style, out["tilt"], out)
	_cache[key] = out
	return out


## Bat speed of one swing (mph): the power button swings harder.
static func swing_speed(profile: Dictionary, power_swing: bool) -> float:
	return clampf(float(profile["bat_speed"]) + (POWER_SWING if power_swing else CONTACT_SWING), BAT_SPEED.x, BAT_SPEED.y + POWER_SWING)
