class_name SwingPath
extends RefCounted
## The bat's way into contact as Baseball Savant's bat tracking measures
## it, built from a hitter's own numbers (PlayerSwing): the sweet spot
## travels a circular arc in a plane tilted to his swing path tilt, meeting
## the contact point at his bat speed, moving at his attack angle (up) and
## attack direction (across: + toward the opposite field, as attack_yaw).
## The press starts it from wherever the bat is; the swing's first part
## eases it into the arc. Visual only: the rules decide the outcome.

## Arc radius of the sweet spot round the swing's center (m): hands plus
## bat, swinging about the body.
const RADIUS := 1.15
## The sweet spot from the barrel's end (m), and from the grip's middle
## (hands choked to the knob): where the hands hold it from the sweet spot.
const SWEET_FROM_TIP := 0.15
const GRIP_TO_SWEET := 0.75
## Bat lag: the barrel trails the arc's radius by this much at the press,
## easing to none at contact (degrees).
const LAG := 25.0
## The press's bat eases onto the arc over this share of the way to
## contact, so the last 40 ms (what Savant measures) are the pure arc.
const EASE_IN := 0.33
## Contact depth (in, + in front of the plate's front edge), fit to
## Savant's 2025 leaderboard (207 hitters, residual about 4 in): pulled
## and uppercut swings meet it farther out front.
const DEPTH_BASE := -0.27
const DEPTH_PER_DIRECTION := -0.382
const DEPTH_PER_ATTACK := 0.253
## Middle of the zone: where the arc meets the ball when no pitch says.
const DEFAULT_HEIGHT := 0.78
const PLATE_FRONT_Z := -0.2159

var center := Vector3.ZERO
var normal := Vector3.UP
## In-plane unit vectors: m from the center to contact, u along the travel
## at contact.
var m := Vector3.RIGHT
var u := Vector3.FORWARD
var contact := Vector3.ZERO
## Seconds from the press to contact, and the arc's angle back from
## contact at the press (radians).
var to_contact := 0.06
var start_angle := 1.0
var _shape := 2.0
var _omega := 25.0
var _start_offset := Vector3.ZERO
var _start_axis := Vector3.FORWARD


## Contact depth (m, toward the pitcher from the plate's front edge) for a
## hitter's attack (PlayerSwing: attack_yaw, attack_lift).
static func contact_depth(profile: Dictionary) -> float:
	var inches := DEPTH_BASE + DEPTH_PER_DIRECTION * float(profile.get("attack_yaw", 0.0)) + DEPTH_PER_ATTACK * float(profile.get("attack_lift", 10.0))
	return inches * 0.0254


## The contact point for a hitter: in front of the plate by his depth, at
## the pitch's side and height (plate x, height), or the zone's middle.
static func contact_point(profile: Dictionary, at: Vector2 = Vector2(0.0, DEFAULT_HEIGHT)) -> Vector3:
	return Vector3(at.x, at.y, PLATE_FRONT_Z - contact_depth(profile))


## A path for this hitter (profile: tilt, attack_lift, attack_yaw,
## bat_speed mph) to `contact`, from a bat whose sweet spot is at
## `sweet_now` along `axis_now` when he presses; `side` +1 bats right.
static func build(profile: Dictionary, contact_at: Vector3, side: float, sweet_now: Vector3, axis_now: Vector3, seconds: float, mph: float) -> SwingPath:
	var path := SwingPath.new()
	path.contact = contact_at
	path.to_contact = seconds
	var attack := deg_to_rad(float(profile.get("attack_lift", 10.0)))
	var direction := deg_to_rad(float(profile.get("attack_yaw", 0.0)))
	var tilt := deg_to_rad(float(profile.get("tilt", 32.0)))
	# Travel at contact: toward the pitcher (-z), up by the attack angle,
	# across by the attack direction (+ toward his opposite field: first
	# base's side, +x, for a righty).
	path.u = Vector3(cos(attack) * sin(direction) * side, sin(attack), -cos(attack) * cos(direction)).normalized()
	# The plane holds u and leans `tilt` from level: its normal is `tilt`
	# from straight up. Of the planes that do, the one whose arc comes down
	# into the zone from above and behind (center above contact, on his
	# side of the ball).
	var e1 := (Vector3.UP - path.u * Vector3.UP.dot(path.u)).normalized()
	var e2 := path.u.cross(e1).normalized()
	var cos_b := clampf(cos(tilt) / maxf(e1.dot(Vector3.UP), 0.001), -1.0, 1.0)
	var beta := acos(cos_b)
	var best := -INF
	for b: float in [beta, -beta]:
		for flip: float in [1.0, -1.0]:
			var n := (e1 * cos(b) + e2 * sin(b)) * flip
			var mm := n.cross(path.u).normalized()
			# Toward the plate from his side (+x for a righty) and down.
			var score := mm.x * side - mm.y * 2.0
			if mm.x * side > 0.0 and mm.y < 0.0 and score > best:
				best = score
				path.normal = n
				path.m = mm
	path.center = contact_at - path.m * RADIUS
	# Where the bat is now, as an angle back along the arc; a short way in
	# needs a sharp start, a long one an even pull through.
	var rel := sweet_now - path.center
	var back := -atan2(rel.dot(path.u), rel.dot(path.m))
	if back < deg_to_rad(30.0):
		back += TAU
	path.start_angle = clampf(back, deg_to_rad(35.0), deg_to_rad(220.0))
	path._omega = mph * 0.44704 / RADIUS
	path._shape = clampf(path._omega * seconds / path.start_angle, 0.2, 3.0)
	path._start_offset = sweet_now - path._arc(-path.start_angle)
	path._start_axis = axis_now.normalized()
	return path


## Sweet spot on the arc `angle` radians from contact (- before it).
func _arc(angle: float) -> Vector3:
	return center + (m * cos(angle) + u * sin(angle)) * RADIUS


## How far along the arc (0 at the press, 1 at contact) at fraction x of
## the time to contact: eases in, arriving at full bat speed.
func _progress(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return (_shape - 2.0) * x * x * x + (3.0 - _shape) * x * x


## {sweet, axis} `t` seconds after the press, up to contact and on past it
## (the arc carries on, slowing), for the bat's first part.
func at(t: float) -> Dictionary:
	var angle: float
	var x := t / to_contact
	if t <= to_contact:
		angle = -start_angle * (1.0 - _progress(x))
	else:
		var after := t - to_contact
		angle = _omega * after - 0.5 * _omega / 0.25 * after * after
	var sweet := _arc(angle)
	var radial := (sweet - center).normalized()
	# The barrel trails the radius before contact (bat lag).
	var lag := deg_to_rad(LAG) * (1.0 - _progress(x)) if t <= to_contact else 0.0
	var axis := radial.rotated(normal, -lag * signf(normal.dot(m.cross(u))))
	# Eased in from where the bat really was at the press.
	var blend := 1.0 - smoothstep(0.0, EASE_IN, x)
	sweet += _start_offset * blend
	axis = axis.slerp(_start_axis, blend).normalized() if _start_axis.dot(axis) > -0.99 else axis
	return {"sweet": sweet, "axis": axis}


## Where the middle of the grip is for a sweet spot and axis (world).
static func grip_for(sweet: Vector3, axis: Vector3, choke: float) -> Vector3:
	return sweet - axis.normalized() * (GRIP_TO_SWEET - choke)
