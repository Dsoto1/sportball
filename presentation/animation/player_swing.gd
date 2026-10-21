class_name PlayerSwing
extends RefCounted
## A hitter's own swing signature, in Statcast terms: bat speed, attack
## angle, attack direction and swing path tilt. It starts from his style
## (BattingStyles), then power adds bat speed and loft, and a small steady
## per-player variation makes two hitters of one style swing a little
## differently. Everything is clamped to the league's real range (Baseball
## Savant 2025: average 72 mph, 10 deg attack angle, 2 deg pull, 32 deg
## tilt; extremes about 62-81 mph, 1-20 deg, 15 pull to 11 oppo, 22-46).
## The bat path follows it; the ball still goes where aim and timing say.

const LEAGUE_BAT_SPEED := 72.0
const BAT_SPEED := Vector2(62.0, 81.0)
const ATTACK_ANGLE := Vector2(0.0, 20.0)
## attack_yaw: + is the opposite field, - is pull (BattingStyles).
const ATTACK_DIRECTION := Vector2(-15.0, 11.0)
const TILT := Vector2(22.0, 46.0)
## How much the swing button changes bat speed (mph).
const POWER_SWING := 3.0
const CONTACT_SWING := -2.0

static var _cache := {}


## {bat_speed, attack_lift, attack_yaw, tilt, slot_lift} for a hitter.
static func for_player(p: PlayerDef, style: StringName) -> Dictionary:
	var key := "%s/%s" % [p.id if p != null else &"", style]
	if _cache.has(key):
		return _cache[key]
	var b: Dictionary = BattingStyles.BAT[style]
	var id := String(p.id) if p != null else ""
	var power := float(p.power) if p != null else 50.0
	var contact := float(p.contact) if p != null else 50.0
	var lift := float(b["attack_lift"]) + (power - 50.0) * 0.08 + _wobble(id, "aa") * 3.0
	var yaw := float(b["attack_yaw"]) + _wobble(id, "dir") * 4.0
	var tilt := float(BattingStyles.TILT[style]) + (power - 50.0) * 0.05 + _wobble(id, "tilt") * 3.0
	var speed := LEAGUE_BAT_SPEED + (power - 50.0) * 0.16 - (contact - 50.0) * 0.03 + _wobble(id, "bs") * 1.5
	var out := {
		"bat_speed": clampf(speed, BAT_SPEED.x, BAT_SPEED.y),
		"attack_lift": clampf(lift, ATTACK_ANGLE.x, ATTACK_ANGLE.y),
		"attack_yaw": clampf(yaw, ATTACK_DIRECTION.x, ATTACK_DIRECTION.y),
		"tilt": clampf(tilt, TILT.x, TILT.y),
	}
	out["slot_lift"] = BattingStyles.slot_for_tilt(style, out["tilt"], out)
	_cache[key] = out
	return out


## Bat speed of one swing (mph): the power button swings harder.
static func swing_speed(profile: Dictionary, power_swing: bool) -> float:
	return clampf(float(profile["bat_speed"]) + (POWER_SWING if power_swing else CONTACT_SWING), BAT_SPEED.x, BAT_SPEED.y + POWER_SWING)


## A steady value in -1..1 for a player and a trait.
static func _wobble(id: String, what: String) -> float:
	return float(absi(hash(id + "/" + what)) % 2001) / 1000.0 - 1.0
