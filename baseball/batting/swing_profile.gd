class_name SwingProfile
extends RefCounted
## A hitter's swing, in Statcast terms, as a rule of the game: bat speed
## (mph), attack angle (deg up at contact), attack direction (deg toward
## his pull field; negative = opposite field) and swing path tilt (deg).
## It comes from his batting style, his power and contact, and a small
## steady per-player variation, inside the league's real range (Baseball
## Savant 2025). Ratings.apply_batter puts it on every swing, and the
## contact model uses it: bat speed drives exit velocity, attack angle
## lifts or flattens the launch, attack direction pulls or pushes the
## spray, tilt sets how much the launch follows the pitch height. The
## swing animation (PlayerSwing, BattingStyles) draws the same numbers.

## League averages: a swing like this changes nothing.
const LEAGUE_BAT_SPEED := 72.0
const LEAGUE_ATTACK_ANGLE := 10.0
const LEAGUE_PULL := 2.0
const LEAGUE_TILT := 32.0
## League extremes (about Vlad Jr. 1 deg, Suarez 20; Paredes 15 pull,
## Turang 11 oppo; Diaz 24 to Greene 46 tilt).
const BAT_SPEED := Vector2(62.0, 81.0)
const ATTACK_ANGLE := Vector2(0.0, 20.0)
const PULL := Vector2(-11.0, 15.0)
const TILT := Vector2(22.0, 46.0)

## Each style's typical swing (the owner's Statcast anchors).
const STYLES := {
	&"classic": {"attack_angle": 10.0, "pull": 2.0, "tilt": 32.0},
	&"crouch": {"attack_angle": 8.0, "pull": 2.0, "tilt": 30.0},
	&"open": {"attack_angle": 10.0, "pull": 3.0, "tilt": 32.0},
	&"leg_kick": {"attack_angle": 18.0, "pull": 6.0, "tilt": 36.0},
	&"wrap": {"attack_angle": 16.0, "pull": 5.0, "tilt": 32.0},
	&"slap": {"attack_angle": 4.0, "pull": -11.0, "tilt": 30.0},
}

static var _cache := {}


## The style a player swings with: his own if set, else one that suits him
## (big power: leg kick or wrap; quick contact hitters: slap or open;
## everyone else spread over classic, crouch and open), steady per player.
static func style_for(p: PlayerDef) -> StringName:
	if p == null:
		return &"classic"
	if p.batting_style != &"" and STYLES.has(p.batting_style):
		return p.batting_style
	var pick := absi(hash(String(p.id)))
	if p.power >= 75:
		return [&"leg_kick", &"wrap"][pick % 2]
	if p.contact >= 70 and p.speed >= 65 and p.power < 55:
		return [&"slap", &"open"][pick % 2]
	return [&"classic", &"crouch", &"open"][pick % 3]


## {style, bat_speed, attack_angle, pull, tilt} for a hitter.
static func for_player(p: PlayerDef) -> Dictionary:
	var style := style_for(p)
	var id := String(p.id) if p != null else ""
	var key := "%s/%s/%d/%d" % [id, style, p.power if p != null else 50, p.contact if p != null else 50]
	if _cache.has(key):
		return _cache[key]
	var base: Dictionary = STYLES[style]
	var power := float(p.power) if p != null else 50.0
	var contact := float(p.contact) if p != null else 50.0
	var out := {
		"style": style,
		"bat_speed": clampf(LEAGUE_BAT_SPEED + (power - 50.0) * 0.16 - (contact - 50.0) * 0.03 + _wobble(id, "bs") * 1.5, BAT_SPEED.x, BAT_SPEED.y),
		"attack_angle": clampf(float(base["attack_angle"]) + (power - 50.0) * 0.08 + _wobble(id, "aa") * 3.0, ATTACK_ANGLE.x, ATTACK_ANGLE.y),
		"pull": clampf(float(base["pull"]) - _wobble(id, "dir") * 4.0, PULL.x, PULL.y),
		"tilt": clampf(float(base["tilt"]) + (power - 50.0) * 0.05 + _wobble(id, "tilt") * 3.0, TILT.x, TILT.y),
	}
	_cache[key] = out
	return out


## A steady value in -1..1 for a player and a trait.
static func _wobble(id: String, what: String) -> float:
	return float(absi(hash(id + "/" + what)) % 2001) / 1000.0 - 1.0
