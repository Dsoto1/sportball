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

## Approach clock: the load peaks at the pitcher's release, the stride
## lands at STRIDE_AT, then he holds, cocked, until he swings or takes.
const LOAD_AT := 0.5
const STRIDE_AT := 0.85
## Swing clock: the barrel meets the ball here, the rest is follow-through.
const CONTACT_AT := 0.2

## Style ids, in the order a roster's styles are handed out when a player
## sets none.
const ORDER := [&"classic", &"crouch", &"open", &"leg_kick", &"wrap", &"slap"]
const NAMES := {&"classic": "Classic", &"crouch": "Crouch", &"open": "Open", &"leg_kick": "Leg Kick", &"wrap": "Bat Wrap", &"slap": "Slap"}

## The bat in his hands, per style (degrees; yaw 90 = barrel back toward the
## catcher, 0 = across the plate; lift above level). load_* add to the
## stance at the top of the load. finish_yaw ends the sweep. one_hand lets
## the top hand go after contact. choke (m) moves the hands up the handle.
const BAT := {
	&"classic": {"yaw": 100.0, "lift": 50.0, "load_yaw": 15.0, "load_lift": 5.0, "waggle": 6.0, "finish_yaw": -170.0, "finish_lift": 40.0, "one_hand": false, "choke": 0.0},
	&"crouch": {"yaw": 105.0, "lift": 38.0, "load_yaw": 12.0, "load_lift": 0.0, "waggle": 4.0, "finish_yaw": -165.0, "finish_lift": 35.0, "one_hand": false, "choke": 0.0},
	&"open": {"yaw": 92.0, "lift": 58.0, "load_yaw": 20.0, "load_lift": 2.0, "waggle": 9.0, "finish_yaw": -170.0, "finish_lift": 42.0, "one_hand": false, "choke": 0.0},
	&"leg_kick": {"yaw": 100.0, "lift": 62.0, "load_yaw": 28.0, "load_lift": 8.0, "waggle": 3.0, "finish_yaw": -185.0, "finish_lift": 48.0, "one_hand": false, "choke": 0.0},
	&"wrap": {"yaw": 145.0, "lift": 28.0, "load_yaw": 15.0, "load_lift": 0.0, "waggle": 2.0, "finish_yaw": -180.0, "finish_lift": 25.0, "one_hand": true, "choke": 0.0},
	&"slap": {"yaw": 88.0, "lift": 45.0, "load_yaw": 8.0, "load_lift": 0.0, "waggle": 10.0, "finish_yaw": -120.0, "finish_lift": 15.0, "one_hand": false, "choke": 0.08},
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
			stride = _with(stride, {"drop": 0.24, "foot_l": P(-0.52, 0.1, 0.07), "foot_r": P(0.42, 0.1, -0.02), "hips": Vector3(14, 8, 0), "chest": Vector3(26, -24, 0)})
			contact = _with(contact, {"drop": 0.22, "foot_l": P(-0.52, 0.1, 0.07)})
			extend = _with(extend, {"drop": 0.2, "foot_l": P(-0.52, 0.1, 0.07)})
			finish = _with(finish, {"drop": 0.16, "foot_l": P(-0.52, 0.1, 0.07)})
		&"open":
			stance = _with(stance, {
				"hips": Vector3(6, 18, 0), "chest": Vector3(10, -2, 0), "head": Vector3(-8, 70, 0),
				"foot_l": P(-0.3, 0.1, -0.2), "toe_l": 35.0,
			})
			# A toe tap closes him up before he strides.
			load = _with(load, {"foot_l": P(-0.2, 0.17, -0.02), "toe_l": 0.0, "hips": Vector3(8, -12, 0), "chest": Vector3(12, -30, 0)})
		&"leg_kick":
			stance = _with(stance, {"drop": 0.06, "chest": Vector3(8, -18, 0)})
			load = _with(load, {
				"drop": 0.04, "shift": P(0.07, 0, 0), "hips": Vector3(6, -25, 0), "chest": Vector3(8, -38, 0),
				"foot_l": P(-0.1, 0.52, 0.14), "knee_l": P(0, 0.6, 1),
				"hand_r": P(0.28, 1.5, 0.0), "hand_l": P(0.22, 1.44, 0.04),
			})
			stride = _with(stride, {"drop": 0.18, "foot_l": P(-0.58, 0.1, 0.06)})
			contact = _with(contact, {"drop": 0.18, "foot_l": P(-0.58, 0.1, 0.06), "hips": Vector3(8, 58, 0)})
			extend = _with(extend, {"drop": 0.16, "foot_l": P(-0.58, 0.1, 0.06)})
			finish = _with(finish, {"drop": 0.12, "foot_l": P(-0.58, 0.1, 0.06), "hips": Vector3(4, 95, 0)})
		&"wrap":
			stance = _with(stance, {
				"chest": Vector3(12, -24, 0),
				"hand_r": P(0.12, 1.52, 0.0), "hand_l": P(0.07, 1.46, 0.04), "elbow_r": P(1, 0.2, -0.4),
			})
			load = _with(load, {"hand_r": P(0.18, 1.54, -0.04), "hand_l": P(0.13, 1.48, 0.0), "elbow_r": P(1, 0.2, -0.4)})
			# One-hand finish: the top hand lets go and drops to his side.
			finish = _with(finish, {"hand_r": P(0.05, 1.05, 0.25), "elbow_r": P(1, -0.5, 0), "chest": Vector3(0, 50, -5)})
		&"slap":
			stance = _with(stance, {
				"drop": 0.14, "chest": Vector3(16, -12, 0),
				"foot_l": P(-0.28, 0.1, 0.06), "foot_r": P(0.3, 0.1, -0.02),
				"hand_r": P(0.18, 1.3, 0.17), "hand_l": P(0.12, 1.25, 0.2),
			})
			load = _with(stance, {"hips": Vector3(10, -8, 0), "chest": Vector3(16, -20, 0), "hand_r": P(0.21, 1.31, 0.14), "hand_l": P(0.15, 1.26, 0.17)})
			stride = _with(stride, {"drop": 0.15, "foot_l": P(-0.36, 0.1, 0.08), "foot_r": P(0.3, 0.1, -0.02), "hand_r": P(0.16, 1.26, 0.12), "hand_l": P(0.1, 1.2, 0.15)})
			contact = _with(contact, {"foot_l": P(-0.36, 0.1, 0.08), "hips": Vector3(8, 40, 0), "chest": Vector3(16, 22, 0)})
			extend = _with(extend, {"foot_l": P(-0.36, 0.1, 0.08), "hips": Vector3(6, 55, 0), "chest": Vector3(12, 30, 0)})
			# Compact: hands stay level and out front, he's already leaving the box.
			finish = _with(contact, {
				"foot_l": P(-0.36, 0.1, 0.08), "hips": Vector3(6, 62, 0), "chest": Vector3(10, 30, 0), "head": Vector3(-5, -10, 0),
				"hand_r": P(-0.32, 1.25, 0.22), "hand_l": P(-0.36, 1.2, 0.18),
			})
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


## Bat (yaw, lift) through the swing (p = 0..1) from where it started.
static func swing_bat(style: StringName, p: float, start: Vector2) -> Vector2:
	var b: Dictionary = BAT[style]
	p = clampf(p, 0.0, 1.0)
	if p < CONTACT_AT:
		# Accelerating into the zone: slow off the shoulder, fast at the ball.
		var u := p / CONTACT_AT
		return Vector2(lerpf(start.x, 0.0, u * u), lerpf(start.y, 5.0, u))
	var v := (p - CONTACT_AT) / (1.0 - CONTACT_AT)
	var out := 1.0 - (1.0 - v) * (1.0 - v)
	return Vector2(lerpf(0.0, float(b["finish_yaw"]), out), lerpf(5.0, float(b["finish_lift"]), smoothstep(0.0, 0.7, v)))
