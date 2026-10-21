class_name BattingStyles
extends RefCounted
## How each hitter stands, holds the bat, loads, strides and finishes.
## Every style is the classic swing (BaseballMoves) with its own changes,
## baked into three moves per style (and lefty copies):
##   Stance_<style>    the waggle while he waits (loops)
##   Approach_<style>  stance -> load (as the pitcher delivers) -> stride
##                     (as the ball comes), scrubbed 0..1 by the pitch
##   Swing_<style>     stride -> contact (CONTACT_AT) -> extension ->
##                     finish, scrubbed 0..1 from the press
## Plus how the bat sits and moves in his hands (BAT). Purely visual.

## Bat lag: the barrel is in the slot this far from the press to contact,
## having come only this share of the way around; its depth per style is
## BAT slot_lift (degrees below level). The slot depths are tuned so the
## swing path's tilt into contact (swing_tilt) lands on Statcast-like
## targets (TILT): MLB average 32, compact swings 30, big power 36.
const SLOT_AT := 0.55
const SLOT_YAW_SHARE := 0.35
const TILT := {&"classic": 32.0, &"crouch": 30.0, &"open": 32.0, &"leg_kick": 36.0, &"wrap": 32.0, &"slap": 30.0}

## Approach clock: the load peaks at the pitcher's release, the stride
## lands at STRIDE_AT, then he holds, cocked, until he swings or takes.
const LOAD_AT := 0.5
const STRIDE_AT := 0.85
## Swing clock: the barrel meets the ball here, the rest is follow-through.
const CONTACT_AT := 0.2
## A one-hand finish lets the top hand go only after this (well past contact).
const ONE_HAND_RELEASE := 0.5
## Body space (m, forward = toward the plate): no foot may reach the plate.
## The batter stands 0.85 m from its middle; its near edge is 0.63 away.
const PLATE_CLEAR := 0.45
## The lead hand sits at least this far in front of him (m) before the swing.
const HANDS_OUT := 0.2
## How open the lead foot lands at the plant (degrees toward the pitcher).
const LEAD_TOE := 30.0

## Style ids, in the order a roster's styles are handed out when a player
## sets none.
const ORDER := [&"classic", &"crouch", &"open", &"leg_kick", &"wrap", &"slap"]
const NAMES := {&"classic": "Classic", &"crouch": "Crouch", &"open": "Open", &"leg_kick": "Leg Kick", &"wrap": "Bat Wrap", &"slap": "Slap"}

## The bat in his hands, per style (degrees; yaw 90 = barrel back toward the
## catcher, 0 = across the plate; lift above level). load_* add to the
## stance at the top of the load. slot_lift is how far the barrel drops
## behind the hands before it whips through (bat lag). At contact the barrel points along
## attack_yaw (attack direction: + lags toward the opposite field, - is out
## front, pulling) and climbs at attack_lift (attack angle), the swing's
## signature per BATTING_STYLE_SPEC.md. finish_yaw ends the sweep. one_hand
## lets the top hand go after contact. choke (m) moves the hands up the
## handle.
const BAT := {
	&"classic": {"slot_lift": -60.0, "yaw": 100.0, "lift": 50.0, "load_yaw": 15.0, "load_lift": 5.0, "waggle": 6.0, "attack_yaw": -2.0, "attack_lift": 10.0, "finish_yaw": -170.0, "finish_lift": 40.0, "one_hand": false, "choke": 0.0},
	&"crouch": {"slot_lift": -59.0, "yaw": 105.0, "lift": 38.0, "load_yaw": 12.0, "load_lift": 0.0, "waggle": 4.0, "attack_yaw": -2.0, "attack_lift": 8.0, "finish_yaw": -165.0, "finish_lift": 30.0, "one_hand": false, "choke": 0.0},
	&"open": {"slot_lift": -57.0, "yaw": 92.0, "lift": 58.0, "load_yaw": 20.0, "load_lift": 2.0, "waggle": 9.0, "attack_yaw": -3.0, "attack_lift": 10.0, "finish_yaw": -170.0, "finish_lift": 42.0, "one_hand": false, "choke": 0.0},
	&"leg_kick": {"slot_lift": -70.0, "yaw": 100.0, "lift": 62.0, "load_yaw": 28.0, "load_lift": 8.0, "waggle": 3.0, "attack_yaw": -6.0, "attack_lift": 18.0, "finish_yaw": -185.0, "finish_lift": 48.0, "one_hand": false, "choke": 0.0},
	&"wrap": {"slot_lift": -80.0, "yaw": 145.0, "lift": 28.0, "load_yaw": 15.0, "load_lift": 0.0, "waggle": 2.0, "attack_yaw": -5.0, "attack_lift": 16.0, "finish_yaw": -180.0, "finish_lift": 25.0, "one_hand": true, "choke": 0.0},
	&"slap": {"slot_lift": -40.0, "yaw": 80.0, "lift": 32.0, "load_yaw": 6.0, "load_lift": 0.0, "waggle": 10.0, "attack_yaw": 11.0, "attack_lift": 4.0, "finish_yaw": -110.0, "finish_lift": 12.0, "one_hand": false, "choke": 0.08},
}


static func P(right: float, up: float, forward: float) -> Vector3:
	return PoseBaker.P(right, up, forward)


static func _with(base: Dictionary, changes: Dictionary) -> Dictionary:
	var out := base.duplicate()
	out.merge(changes, true)
	return out


## The style a player swings with: his own if set, else one that suits him
## (big power: leg kick or wrap; quick contact hitters: slap or open;
## everyone else spread over classic, crouch and open), steady per player.
static func for_player(p: PlayerDef) -> StringName:
	if p == null:
		return &"classic"
	if p.batting_style != &"" and BAT.has(p.batting_style):
		return p.batting_style
	var pick := absi(hash(String(p.id)))
	if p.power >= 75:
		return [&"leg_kick", &"wrap"][pick % 2]
	if p.contact >= 70 and p.speed >= 65 and p.power < 55:
		return [&"slap", &"open"][pick % 2]
	return [&"classic", &"crouch", &"open"][pick % 3]


## The six key poses of a style: stance, bob, load, stride, contact,
## extend, finish.
static func poses(style: StringName) -> Dictionary:
	var m := BaseballMoves
	var stance: Dictionary = m.STANCE
	var load := _with(m.STANCE, {
		"drop": 0.12, "shift": P(0.05, 0, 0), "hips": Vector3(8, -15, 0), "chest": Vector3(12, -30, 0),
		"foot_l": P(-0.32, 0.13, 0.05), "hand_r": P(0.26, 1.42, 0.04), "hand_l": P(0.2, 1.36, 0.08),
	})
	var stride: Dictionary = m.STRIDE
	var contact: Dictionary = m.CONTACT
	var extend: Dictionary = m.EXTEND
	var finish: Dictionary = m.FINISH
	match style:
		&"crouch":
			stance = _with(stance, {
				"drop": 0.22, "hips": Vector3(14, -5, 0), "chest": Vector3(26, -18, 0),
				"foot_l": P(-0.42, 0.1, 0.05), "foot_r": P(0.42, 0.1, -0.02),
				"hand_r": P(0.2, 1.22, 0.14), "hand_l": P(0.14, 1.15, 0.17),
			})
			load = _with(stance, {"drop": 0.24, "shift": P(0.04, 0, 0), "hips": Vector3(14, -14, 0), "chest": Vector3(26, -28, 0), "hand_r": P(0.25, 1.24, 0.1), "hand_l": P(0.19, 1.17, 0.13)})
			stride = _with(stride, {"drop": 0.24, "foot_l": P(-0.6, 0.1, 0.07), "foot_r": P(0.42, 0.1, -0.02), "hips": Vector3(14, 8, 0), "chest": Vector3(26, -24, 0)})
			contact = _with(contact, {"drop": 0.22, "foot_l": P(-0.6, 0.1, 0.07)})
			extend = _with(extend, {"drop": 0.2, "foot_l": P(-0.6, 0.1, 0.07)})
			finish = _with(finish, {"drop": 0.22, "foot_l": P(-0.6, 0.1, 0.07)})
		&"open":
			stance = _with(stance, {
				"hips": Vector3(6, 18, 0), "chest": Vector3(10, -2, 0), "head": Vector3(-8, 70, 0),
				"foot_l": P(-0.3, 0.1, -0.2), "toe_l": 35.0,
			})
			# A toe tap closes him up, then a short stride from there.
			load = _with(load, {"foot_l": P(-0.2, 0.17, -0.02), "toe_l": 0.0, "hips": Vector3(8, -12, 0), "chest": Vector3(12, -30, 0)})
			stride = _with(stride, {"foot_l": P(-0.46, 0.1, 0.06)})
			contact = _with(contact, {"foot_l": P(-0.46, 0.1, 0.06)})
			extend = _with(extend, {"foot_l": P(-0.46, 0.1, 0.06)})
			finish = _with(finish, {"foot_l": P(-0.46, 0.1, 0.06)})
		&"leg_kick":
			stance = _with(stance, {"drop": 0.06, "chest": Vector3(8, -18, 0)})
			load = _with(load, {
				"drop": 0.04, "shift": P(0.07, 0, 0), "hips": Vector3(6, -25, 0), "chest": Vector3(8, -38, 0),
				"foot_l": P(-0.1, 0.52, 0.14), "knee_l": P(0, 0.6, 1),
				"hand_r": P(0.28, 1.5, 0.0), "hand_l": P(0.22, 1.44, 0.04),
			})
			stride = _with(stride, {"drop": 0.22, "foot_l": P(-0.64, 0.1, 0.06)})
			contact = _with(contact, {"drop": 0.22, "foot_l": P(-0.64, 0.1, 0.06), "hips": Vector3(8, 58, 0), "chest": Vector3(18, -24, 0), "head": Vector3(-5, -4, 0)})
			extend = _with(extend, {"drop": 0.24, "foot_l": P(-0.64, 0.1, 0.06)})
			# The big turn carries the hands farther out, so the arms fold
			# outside the body.
			finish = _with(finish, {"drop": 0.26, "foot_l": P(-0.64, 0.1, 0.06), "hips": Vector3(4, 90, 0),
				"hand_r": P(-0.42, 1.58, -0.02), "hand_l": P(-0.46, 1.52, -0.05)})
		&"wrap":
			stance = _with(stance, {
				"chest": Vector3(12, -24, 0),
				"hand_r": P(0.12, 1.52, 0.0), "hand_l": P(0.07, 1.46, 0.04), "elbow_r": P(1, 0.2, -0.4),
			})
			load = _with(load, {"hand_r": P(0.18, 1.54, -0.04), "hand_l": P(0.13, 1.48, 0.0), "elbow_r": P(1, 0.2, -0.4)})
			# One-hand finish: the top hand lets go and drops to his side.
			finish = _with(finish, {"hand_r": P(0.02, 1.05, 0.42), "elbow_r": P(1, -0.6, 0.3), "chest": Vector3(0, 50, -5)})
		&"slap":
			stance = _with(stance, {
				"drop": 0.14, "chest": Vector3(16, -12, 0),
				"foot_l": P(-0.28, 0.1, 0.06), "foot_r": P(0.3, 0.1, -0.02),
				# Lower and out in front of the back shoulder, bat flatter.
				"hand_r": P(0.14, 1.18, 0.25), "hand_l": P(0.08, 1.13, 0.28),
				"elbow_r": P(1, -1, 0), "elbow_l": P(-0.2, -1, 0.3),
			})
			load = _with(stance, {"hips": Vector3(10, -8, 0), "chest": Vector3(16, -20, 0), "hand_r": P(0.18, 1.2, 0.22), "hand_l": P(0.12, 1.15, 0.25)})
			stride = _with(stride, {"drop": 0.15, "foot_l": P(-0.4, 0.1, 0.08), "foot_r": P(0.3, 0.1, -0.02), "hand_r": P(0.16, 1.18, 0.2), "hand_l": P(0.1, 1.13, 0.23)})
			contact = _with(contact, {"foot_l": P(-0.4, 0.1, 0.08), "hips": Vector3(8, 40, 0), "chest": Vector3(16, -8, 0), "head": Vector3(-5, -2, 0)})
			extend = _with(extend, {"foot_l": P(-0.4, 0.1, 0.08), "hips": Vector3(6, 55, 0), "chest": Vector3(12, 0, 0), "head": Vector3(-5, -25, 0)})
			# Compact: hands stay level and out front, he's already leaving the box.
			finish = _with(contact, {
				"foot_l": P(-0.4, 0.1, 0.08), "hips": Vector3(6, 62, 0), "chest": Vector3(10, 30, 0), "head": Vector3(-5, -10, 0),
				"hand_r": P(-0.32, 1.25, 0.22), "hand_l": P(-0.36, 1.2, 0.18),
			})
	# Hands: out in front of the chest while he waits, loads and strides, so
	# the lead forearm crosses the chest with room instead of on it.
	for pose: Dictionary in [stance, load, stride]:
		var out := HANDS_OUT - (pose["hand_l"] as Vector3).z
		if out > 0.0:
			pose["hand_l"] = (pose["hand_l"] as Vector3) + Vector3(0, 0, out)
			pose["hand_r"] = (pose["hand_r"] as Vector3) + Vector3(0, 0, out)
	# Feet: square to the plate while he waits and loads; from the plant on,
	# the lead foot lands a third open and braces there (it must not spin
	# with the hips), while the back foot pivots (its own toe_r per pose).
	for pose: Dictionary in [stance, load]:
		pose.get_or_add("toe_l", 0.0)
		pose.get_or_add("toe_r", 0.0)
	for pose: Dictionary in [stride, contact, extend, finish]:
		pose.get_or_add("toe_l", LEAD_TOE)
	stride.get_or_add("toe_r", 0.0)
	var bob := _with(stance, {"drop": float(stance.get("drop", 0.0)) + 0.02})
	return {"stance": stance, "bob": bob, "load": load, "stride": stride, "contact": contact, "extend": extend, "finish": finish}


## The baked moves for every style: {name: {keys, loop}} like MOVES.
static func moves() -> Dictionary:
	var out := {}
	for style: StringName in ORDER:
		var p := poses(style)
		out["Stance_%s" % style] = {"keys": [[0.0, p["stance"]], [0.9, p["bob"]], [1.8, p["stance"]]], "loop": true}
		out["Approach_%s" % style] = {"keys": [[0.0, p["stance"]], [LOAD_AT, p["load"]], [STRIDE_AT, p["stride"]], [1.0, p["stride"]]]}
		out["Swing_%s" % style] = {"keys": [[0.0, p["stride"]], [CONTACT_AT, p["contact"]], [0.45, p["extend"]], [1.0, p["finish"]]]}
	return out


## Bat (yaw, lift) during the approach (a = 0..1) for a style.
static func approach_bat(style: StringName, a: float, clock: float) -> Vector2:
	var b: Dictionary = BAT[style]
	var load := smoothstep(0.0, LOAD_AT, a) * (1.0 - 0.6 * smoothstep(LOAD_AT, STRIDE_AT, a))
	var waggle := sin(clock * 3.0) * float(b["waggle"]) * (1.0 - smoothstep(0.0, 0.3, a))
	return Vector2(float(b["yaw"]) + float(b["load_yaw"]) * load + waggle, float(b["lift"]) + float(b["load_lift"]) * load)


## Statcast-style "swing path tilt" (degrees, 0 flat, 90 vertical): how
## steep the plane the barrel travels in is on its way into contact, for a
## right-handed batter, measured from the bat path itself.
static func swing_tilt(style: StringName) -> float:
	var start := approach_bat(style, 1.0, 0.0)
	var d1 := direction(swing_bat(style, CONTACT_AT * 0.85, start))
	var d2 := direction(swing_bat(style, CONTACT_AT, start))
	var n := d1.cross(d2).normalized()
	return rad_to_deg(acos(clampf(absf(n.y), 0.0, 1.0)))


## World direction (right-handed batter) of a bat at (yaw, lift) degrees.
static func direction(bat: Vector2, side: float = 1.0) -> Vector3:
	var y := deg_to_rad(bat.x)
	var e := deg_to_rad(bat.y)
	return Vector3(cos(e) * cos(y) * side, sin(e), cos(e) * sin(y))


## Bat (yaw, lift) through the swing (p = 0..1) from where it started.
static func swing_bat(style: StringName, p: float, start: Vector2) -> Vector2:
	var b: Dictionary = BAT[style]
	p = clampf(p, 0.0, 1.0)
	var attack := Vector2(float(b["attack_yaw"]), float(b["attack_lift"]))
	if p < CONTACT_AT:
		# Bat lag: the hands lead and the barrel drops into the slot behind
		# them (knob at the ball), then whips through to the ball.
		var u := p / CONTACT_AT
		var slot := Vector2(lerpf(start.x, attack.x, SLOT_YAW_SHARE), float(b["slot_lift"]))
		if u < SLOT_AT:
			var k := smoothstep(0.0, 1.0, u / SLOT_AT)
			return Vector2(lerpf(start.x, slot.x, k), lerpf(start.y, slot.y, k))
		var w := (u - SLOT_AT) / (1.0 - SLOT_AT)
		return Vector2(lerpf(slot.x, attack.x, w * w), lerpf(slot.y, attack.y, w))
	var v := (p - CONTACT_AT) / (1.0 - CONTACT_AT)
	var out := 1.0 - (1.0 - v) * (1.0 - v)
	return Vector2(lerpf(attack.x, float(b["finish_yaw"]), out), lerpf(attack.y, float(b["finish_lift"]), smoothstep(0.0, 0.7, v)))
