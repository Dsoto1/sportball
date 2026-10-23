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
## swing path's tilt into contact (swing_tilt) lands on each style's tilt
## (style_tilt): MLB average 32, compact swings 30, big power 36.
const SLOT_AT := 0.55
const SLOT_YAW_SHARE := 0.35

## Approach clock: the load peaks at the pitcher's release, the stride
## lands at STRIDE_AT, then he holds, cocked, until he swings or takes.
const LOAD_AT := 0.5
const STRIDE_AT := 0.85
## Swing clock: the barrel meets the ball here, the rest is follow-through.
const CONTACT_AT := 0.2
## A one-hand finish lets the top hand go only after this (well past contact).
const ONE_HAND_RELEASE := 0.5
## Body space (m, forward = toward the plate): no foot may reach the plate.
## The batter stands 0.91 m from its middle; its near edge is 0.69 away.
const PLATE_CLEAR := 0.5
## The batter's box in his body space (m along the pitcher axis, - toward
## the pitcher): 6 ft long, centered on the plate, with him standing 0.49 m
## behind the plate's middle.
const BOX_TOWARD_PITCHER := -1.4
const BOX_TOWARD_CATCHER := 0.42
## The lead hand sits at least this far in front of him (m) before the swing.
const HANDS_OUT := 0.12
## Feet per style, fit to Statcast's batting-stance tracking (229 MLB
## hitters, Baseball Savant): stance width (m between the feet), stance
## angle (degrees open: the lead foot set back from the plate) and stride
## (m the lead foot travels toward the pitcher). League: width 30 in (0.76),
## 10-90% 23-37 in; angle 10 open (median), 10% open 30+; stride 16 in
## (0.40) average, 8-25 in; 42 in between the feet at contact.
## Classic is the median hitter, Crouch the wide end, Open the most open
## tenth, Leg Kick the longest strides, Slap narrow and short; Bat Wrap's
## difference is in the hands.
const FEET := {
	&"classic": {"width": 0.76, "open": 8.0, "stride": 0.31},
	&"crouch": {"width": 0.82, "open": 5.0, "stride": 0.28},
	&"open": {"width": 0.74, "open": 30.0, "stride": 0.30},
	&"leg_kick": {"width": 0.68, "open": 10.0, "stride": 0.49},
	&"wrap": {"width": 0.76, "open": 10.0, "stride": 0.31},
	&"slap": {"width": 0.62, "open": 12.0, "stride": 0.26},
}
## Where the feet line sits (m toward the plate from his spot), how square
## the lead foot plants (degrees still open), and how much of the stride
## his hips travel (weight shift).
const FOOT_LINE := 0.02
const PLANT_OPEN := 6.0
const WEIGHT_SHIFT := 0.45
## How open the lead foot lands at the plant (degrees toward the pitcher).
const LEAD_TOE := 30.0

## Style ids, in the order a roster's styles are handed out when a player
## sets none.
const ORDER := [&"classic", &"crouch", &"open", &"leg_kick", &"wrap", &"slap"]
const NAMES := {&"classic": "Classic", &"crouch": "Crouch", &"open": "Open", &"leg_kick": "Leg Kick", &"wrap": "Bat Wrap", &"slap": "Slap"}

## The bat in his hands, per style (degrees; yaw 90 = barrel back toward the
## catcher, 0 = across the plate; lift above level). load_* add to the
## stance at the top of the load. slot_lift is how far the barrel drops
## behind the hands before it whips through (bat lag). The barrel meets the
## ball at the style's attack direction and angle (style_attack, from the
## rules' SwingProfile), or a hitter's own (PlayerSwing). finish_yaw ends the sweep. one_hand
## lets the top hand go after contact. choke (m) moves the hands up the
## handle.
const BAT := {
	&"classic": {"slot_lift": -60.0, "yaw": 118.0, "lift": 48.0, "load_yaw": 15.0, "load_lift": 5.0, "waggle": 6.0, "finish_yaw": -170.0, "finish_lift": 40.0, "one_hand": false, "choke": 0.0},
	&"crouch": {"slot_lift": -59.0, "yaw": 105.0, "lift": 38.0, "load_yaw": 12.0, "load_lift": 0.0, "waggle": 4.0, "finish_yaw": -165.0, "finish_lift": 30.0, "one_hand": false, "choke": 0.0},
	&"open": {"slot_lift": -57.0, "yaw": 112.0, "lift": 52.0, "load_yaw": 20.0, "load_lift": 2.0, "waggle": 9.0, "finish_yaw": -170.0, "finish_lift": 42.0, "one_hand": false, "choke": 0.0},
	&"leg_kick": {"slot_lift": -70.0, "yaw": 115.0, "lift": 54.0, "load_yaw": 28.0, "load_lift": 8.0, "waggle": 3.0, "finish_yaw": -185.0, "finish_lift": 48.0, "one_hand": false, "choke": 0.0},
	&"wrap": {"slot_lift": -80.0, "yaw": 145.0, "lift": 28.0, "load_yaw": 15.0, "load_lift": 0.0, "waggle": 2.0, "finish_yaw": -180.0, "finish_lift": 25.0, "one_hand": true, "choke": 0.0},
	&"slap": {"slot_lift": -40.0, "yaw": 80.0, "lift": 32.0, "load_yaw": 6.0, "load_lift": 0.0, "waggle": 10.0, "finish_yaw": -110.0, "finish_lift": 12.0, "one_hand": false, "choke": 0.08},
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
	return SwingProfile.style_for(p)


## A style's typical attack in the bat path's terms: attack_yaw (+ lags
## toward the opposite field, - pulls) and attack_lift (attack angle).
static func style_attack(style: StringName) -> Dictionary:
	var s: Dictionary = SwingProfile.STYLES[style]
	return {"attack_yaw": -float(s["pull"]), "attack_lift": float(s["attack_angle"])}


## A style's typical swing path tilt.
static func style_tilt(style: StringName) -> float:
	return float(SwingProfile.STYLES[style]["tilt"])


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
				"hand_r": P(0.24, 1.46, 0.08), "hand_l": P(0.19, 1.39, 0.11),
			})
			load = _with(stance, {"drop": 0.24, "shift": P(0.04, 0, 0), "hips": Vector3(14, -14, 0), "chest": Vector3(26, -28, 0), "hand_r": P(0.28, 1.48, 0.05), "hand_l": P(0.22, 1.41, 0.08)})
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
				"hand_r": P(0.18, 1.4, 0.14), "hand_l": P(0.12, 1.34, 0.17),
				"elbow_r": P(1, -1, 0), "elbow_l": P(-0.2, -1, 0.3),
			})
			load = _with(stance, {"hips": Vector3(10, -8, 0), "chest": Vector3(16, -20, 0), "hand_r": P(0.22, 1.42, 0.11), "hand_l": P(0.16, 1.36, 0.14)})
			stride = _with(stride, {"drop": 0.15, "foot_l": P(-0.4, 0.1, 0.08), "foot_r": P(0.3, 0.1, -0.02), "hand_r": P(0.16, 1.18, 0.2), "hand_l": P(0.1, 1.13, 0.23)})
			contact = _with(contact, {"foot_l": P(-0.4, 0.1, 0.08), "hips": Vector3(8, 40, 0), "chest": Vector3(16, -8, 0), "head": Vector3(-5, -2, 0)})
			extend = _with(extend, {"foot_l": P(-0.4, 0.1, 0.08), "hips": Vector3(6, 55, 0), "chest": Vector3(12, 0, 0), "head": Vector3(-5, -25, 0)})
			# Compact: hands stay level and out front, he's already leaving the box.
			finish = _with(contact, {
				"foot_l": P(-0.4, 0.1, 0.08), "hips": Vector3(6, 62, 0), "chest": Vector3(10, 30, 0), "head": Vector3(-5, -10, 0),
				"hand_r": P(-0.32, 1.25, 0.22), "hand_l": P(-0.36, 1.2, 0.18),
			})
	# Own copies: the styles share dictionaries (and BaseballMoves' consts).
	stance = stance.duplicate(true)
	load = load.duplicate(true)
	stride = stride.duplicate(true)
	contact = contact.duplicate(true)
	extend = extend.duplicate(true)
	finish = finish.duplicate(true)
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
	_place_feet(style, stance, load, stride, contact, extend, finish)
	var bob := _with(stance, {"drop": float(stance.get("drop", 0.0)) + 0.02})
	return {"stance": stance, "bob": bob, "load": load, "stride": stride, "contact": contact, "extend": extend, "finish": finish}


## Feet from FEET (Statcast-measured): the stance is the style's width and
## open angle around his spot; the load lifts, taps or barely moves the
## lead foot; the stride carries it toward the pitcher and plants it nearly
## square; the rear foot stays put, then pivots up on its toe. The hips
## carry his weight forward over the stride.
static func _place_feet(style: StringName, stance: Dictionary, load: Dictionary, stride: Dictionary,
		contact: Dictionary, extend: Dictionary, finish: Dictionary) -> void:
	var f: Dictionary = FEET[style]
	var half := float(f["width"]) * 0.5
	var open := deg_to_rad(float(f["open"]))
	var rear := Vector2(half * cos(open), FOOT_LINE + half * sin(open))  # (right, forward)
	var lead := Vector2(-half * cos(open), FOOT_LINE - half * sin(open))
	var plant_r := lead.x - float(f["stride"])
	var plant := Vector2(plant_r, rear.y - (rear.x - plant_r) * tan(deg_to_rad(PLANT_OPEN)))
	stance["foot_l"] = P(lead.x, 0.1, lead.y)
	stance["foot_r"] = P(rear.x, 0.1, rear.y)
	stance["toe_l"] = float(f["open"])
	match style:
		&"leg_kick":
			# The knee comes up high and the foot is drawn back under him.
			load["foot_l"] = P(lead.x + 0.26, 0.52, lead.y + 0.1)
			load["toe_l"] = float(f["open"])
		&"open":
			# A toe tap closes him up, level with the back foot.
			load["foot_l"] = P(lead.x + 0.06, 0.17, rear.y - 0.02)
			load["toe_l"] = 0.0
		&"slap":
			load["foot_l"] = P(lead.x + 0.02, 0.12, lead.y)
			load["toe_l"] = float(f["open"])
		_:
			# Lead heel comes up as he gathers.
			load["foot_l"] = P(lead.x + 0.03, 0.13, lead.y)
			load["toe_l"] = float(f["open"])
	load["foot_r"] = stance["foot_r"]
	var weight := P(-float(f["stride"]) * WEIGHT_SHIFT, 0, 0)
	for pose: Dictionary in [stride, contact, extend, finish]:
		pose["foot_l"] = P(plant.x, 0.1, plant.y)
		# The hands ride along with the hips, so the arms keep their shape.
		pose["shift"] = (pose.get("shift", Vector3.ZERO) as Vector3) + weight
		for hand in ["hand_l", "hand_r"]:
			if pose.has(hand):
				pose[hand] = (pose[hand] as Vector3) + weight
	stride["foot_r"] = stance["foot_r"]
	contact["foot_r"] = P(rear.x - 0.04, 0.14, rear.y)
	extend["foot_r"] = contact["foot_r"]
	finish["foot_r"] = P(rear.x - 0.14, 0.18, rear.y + 0.02)


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
static func swing_tilt(style: StringName, profile: Dictionary = {}) -> float:
	var start := approach_bat(style, 1.0, 0.0)
	var d1 := direction(swing_bat(style, CONTACT_AT * 0.85, start, profile))
	var d2 := direction(swing_bat(style, CONTACT_AT, start, profile))
	var n := d1.cross(d2).normalized()
	return rad_to_deg(acos(clampf(absf(n.y), 0.0, 1.0)))


## World direction (right-handed batter) of a bat at (yaw, lift) degrees.
static func direction(bat: Vector2, side: float = 1.0) -> Vector3:
	var y := deg_to_rad(bat.x)
	var e := deg_to_rad(bat.y)
	return Vector3(cos(e) * cos(y) * side, sin(e), cos(e) * sin(y))


## How deep the barrel must drop into the slot for a style's swing to have
## this tilt with these attack numbers (profile: attack_yaw, attack_lift).
static func slot_for_tilt(style: StringName, tilt: float, profile: Dictionary = {}) -> float:
	var lo := -5.0
	var hi := -89.0
	var probe := profile.duplicate()
	for i in 24:
		var mid := (lo + hi) * 0.5
		probe["slot_lift"] = mid
		if swing_tilt(style, probe) < tilt:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## Bat (yaw, lift) through the swing (p = 0..1) from where it started.
## profile (PlayerSwing) can override the style's attack_yaw, attack_lift
## and slot_lift with a hitter's own.
static func swing_bat(style: StringName, p: float, start: Vector2, profile: Dictionary = {}) -> Vector2:
	var b: Dictionary = BAT[style].duplicate()
	b.merge(style_attack(style), true)
	b.merge(profile, true)
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
