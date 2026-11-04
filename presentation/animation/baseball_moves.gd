class_name BaseballMoves
extends RefCounted
## The game's own baseball animations, authored as body-space poses and
## baked by PoseBaker into one AnimationLibrary ("bb") shared by every
## player. All moves are written right-handed; each also gets a mirrored
## "_L" copy for lefties. Scrubbed moves (swing, pitch, throw) are keyed on
## a 0..1 progress clock so gameplay timing drives them directly.

const LIBRARY := &"bb"
## Normalized progress where the moves hit their key moment.
const SWING_CONTACT := 0.42
const PITCH_RELEASE := 1.0
const PITCH_LENGTH := 1.5
const THROW_RELEASE := 0.3

static var _library: AnimationLibrary


## The baked library (built once, from the given rig).
static func library(skeleton: Skeleton3D, player: AnimationPlayer) -> AnimationLibrary:
	if _library != null:
		return _library
	var fist := player.get_animation(&"Punch_Jab") if player.has_animation(&"Punch_Jab") else null
	var baker := PoseBaker.new(skeleton, fist)
	_library = AnimationLibrary.new()
	var all := MOVES.duplicate()
	all.merge(BattingStyles.moves())
	for move: String in all:
		var spec: Dictionary = all[move]
		var keys: Array = spec["keys"]
		var loop: bool = spec.get("loop", false)
		var length: float = spec.get("length", -1.0)
		_library.add_animation(StringName(move), baker.bake(keys, loop, length))
		var mirrored := []
		for k: Array in keys:
			mirrored.append([k[0], PoseBaker.mirror(k[1])])
		_library.add_animation(StringName(move + "_L"), baker.bake(mirrored, loop, length))
	# Motion capture (the owner's Mixamo clips): the batter's stance, load
	# and swing, and the lefty versions mirrored from the same capture.
	for spec: Array in MOCAP:
		for lefty: bool in [false, true]:
			var anim := MixamoRetarget.bake(spec[1], skeleton, spec[2], spec[3], spec[4], lefty, spec[5], _two_hands_on_bat(String(spec[0])))
			if anim != null and spec.size() > 6 and spec[6]:
				# A short hold played back and forth, so it never pops.
				anim.loop_mode = Animation.LOOP_PINGPONG
			if anim != null and String(spec[0]) == "Bat_WalkUp":
				# He walks into his stance spot: the walk ends where the
				# stance's hips stand.
				_end_at(anim, _library.get_animation(StringName("Bat_Stance" + ("_L" if lefty else ""))))
			if anim != null and String(spec[0]) == "Bat_Strike":
				# Starts on the stance; eased so it ends back on its spot too.
				_end_at(anim, _library.get_animation(StringName("Bat_Stance" + ("_L" if lefty else ""))), true)
			if anim != null and String(spec[0]) == "Milling_Mocap":
				# Standing about on one spot (at the dugout rail): no drift.
				_in_place(anim)
			if anim != null:
				_library.add_animation(StringName(String(spec[0]) + ("_L" if lefty else "")), anim)
	return _library


## The batting captures face this far (degrees) off the players' clips.
const BAT_YAW := 87.0
## Captured swings per batting style: [Mixamo file, launch s, contact s
## after the launch, swing end s after the launch]. Classic, crouch and
## open swing Hit; the power styles the bigger load and coil of Hit 2; the
## slap the short, compact Hit 3.
const SWINGS := {
	&"hit": ["Baseball_Hit", 1.12, 0.21, 0.66],
	&"power": ["Baseball_Hit_2", 1.12, 0.21, 0.73],
	&"compact": ["Baseball_Hit_3", 0.76, 0.22, 0.56],
}
const STYLE_SWING := {&"classic": &"hit", &"crouch": &"hit", &"open": &"hit", &"leg_kick": &"power", &"wrap": &"power", &"slap": &"compact"}
## The bunt capture's square-around: from the stance to squared up,
## before he runs off (Baseball_Bunt, seconds).
const BUNT_FROM := 0.4
const BUNT_TO := 1.35
## The full windup (bases empty; Baseball_Pitching): release and end.
const WINDUP_RELEASE := 1.89
const WINDUP_END := 2.9
## The next batter's walk-up (Baseball_Walk_In): about a metre from
## outside the box into his stance, hands up; played WALKUP_SPEED times
## faster than captured.
const WALKUP_FROM := 0.4
const WALKUP_TO := 4.6
const WALKUP_SPEED := 1.75
const WALKUP_TIME := (WALKUP_TO - WALKUP_FROM) / WALKUP_SPEED
## The umpire's called strike (Baseball_Umpire from his set to the end,
## 2.17 s) as played (ActorView.UMP_CALL_SPEED).
const UMP_CALL_TIME := 2.17 / 1.3
## The batter's reaction to a called strike (Baseball_Strike: turns away,
## steps out, back into his stance), played STRIKE_SPEED times faster.
const STRIKE_TO := 6.5
const STRIKE_SPEED := 1.8
const STRIKE_TIME := STRIKE_TO / STRIKE_SPEED
## Captured clips: [name, Mixamo file, from s, to s, loop, yaw, pingpong].
static var MOCAP := _mocap_specs()
const MOCAP_RELEASE := 1.46
const MOCAP_PITCH := 2.43


static func _mocap_specs() -> Array:
	var out := [["Bat_Stance", "Baseball_Idle", 0.0, -1.0, true, BAT_YAW],
		# The delivery: set, kick, stride, release (MOCAP_RELEASE), follow-through.
		["Pitch_Mocap", "Baseball_Pitching_2", 0.0, MOCAP_PITCH, false, 0.0],
		# The catcher's squat behind the plate.
		# (Only its first second: from 1.1 s he stands up and raises both
		# hands, as for a pop-up; played back and forth.)
		["Catcher_Mocap", "Baseball_Catcher", 0.0, 1.0, true, 0.0, true],
		# Squaring around to bunt, held squared (a batting capture).
		["Bunt_Mocap", "Baseball_Bunt", BUNT_FROM, BUNT_TO, false, BAT_YAW],
		# From the windup (bases empty): hands together, rock, kick, release.
		["Windup_Mocap", "Baseball_Pitching", 0.0, WINDUP_END, false, 0.0],
		# Fielders between pitches, hands on knees (the umpire capture's
		# set, before his call).
		["Knees_Mocap", "Baseball_Umpire", 0.0, 0.45, true, 0.0, true],
		# The home-plate umpire's called strike: from his set, the punch
		# out and back to the set.
		["Ump_Call", "Baseball_Umpire", 0.45, -1.0, false, 0.0],
		# The next batter in the on-deck circle: stretching with the bat,
		# practice swings (loops over its whole 37 s).
		["OnDeck_Mocap", "Batter_On_Deck", 0.0, -1.0, true, BAT_YAW],
		# Players standing about at the dugout rail.
		["Milling_Mocap", "Baseball_Milling_Idle", 0.0, -1.0, true, BAT_YAW],
		# A called strike: the batter turns away, steps out and back in.
		["Bat_Strike", "Baseball_Strike", 0.0, STRIKE_TO, false, BAT_YAW],
		# The next batter walking up into the box (after Bat_Stance, which
		# it ends on).
		["Bat_WalkUp", "Baseball_Walk_In", WALKUP_FROM, WALKUP_TO, false, BAT_YAW]]
	for key: StringName in SWINGS:
		var s: Array = SWINGS[key]
		out.append(["Bat_Approach_%s" % key, s[0], 0.0, s[1], false, BAT_YAW])
		out.append(["Bat_Swing_%s" % key, s[0], s[1], float(s[1]) + float(s[3]), false, BAT_YAW])
	return out


## Shifts a clip's pelvis track so its last frame stands
## where `to`'s first frame does (`eased`: gradually, from none at its
## first frame).
static func _end_at(anim: Animation, to: Animation, eased: bool = false) -> void:
	var a := _pelvis_track(anim)
	var b := _pelvis_track(to)
	if a < 0 or b < 0 or anim.track_get_key_count(a) == 0:
		return
	var last: Vector3 = anim.track_get_key_value(a, anim.track_get_key_count(a) - 1)
	# (The keys are in the root bone's frame, which is Z-up; the walk ends
	# at the stance's own hip height, so the whole offset is along the
	# ground.)
	var shift: Vector3 = to.track_get_key_value(b, 0) - last
	var n := anim.track_get_key_count(a)
	for k in n:
		# Eased: the shift grows over the clip, so its first frame stays put.
		var w := float(k) / maxf(n - 1, 1) if eased else 1.0
		anim.track_set_key_value(a, k, (anim.track_get_key_value(a, k) as Vector3) + shift * w)


## Keeps a clip's hips over their first spot (their height still moves).
static func _in_place(anim: Animation) -> void:
	var a := _pelvis_track(anim)
	if a < 0 or anim.track_get_key_count(a) == 0:
		return
	var first: Vector3 = anim.track_get_key_value(a, 0)
	for k in anim.track_get_key_count(a):
		var v: Vector3 = anim.track_get_key_value(a, k)
		# (The root bone's frame is Z-up: x and y run along the ground.)
		anim.track_set_key_value(a, k, Vector3(first.x, first.y, v.z))


static func _pelvis_track(anim: Animation) -> int:
	for tr in anim.get_track_count():
		if anim.track_get_type(tr) == Animation.TYPE_POSITION_3D and String(anim.track_get_path(tr).get_concatenated_subnames()) == "pelvis":
			return tr
	return -1


## The clips where both hands hold the bat (their bottom hand is posed
## onto the grip; not the walk-up, step-out or on-deck clips).
static func _two_hands_on_bat(name: String) -> bool:
	return name == "Bat_Stance" or name == "Bunt_Mocap" or name.begins_with("Bat_Approach_") or name.begins_with("Bat_Swing_")


## A style's captured swing: [clip key, launch, contact after, swing length].
static func swing_for(style: StringName) -> Array:
	var key: StringName = STYLE_SWING.get(style, &"hit")
	var s: Array = SWINGS[key]
	return [key, s[1], s[2], s[3]]


## Whether the captured batting clips are in (the Mixamo files exist).
static func has_mocap() -> bool:
	return ResourceLoader.exists(MixamoRetarget.DIR + "Baseball_Hit.fbx")


static func clip(move: String, lefty: bool = false) -> StringName:
	return StringName("%s/%s%s" % [LIBRARY, move, "_L" if lefty else ""])


static func P(right: float, up: float, forward: float) -> Vector3:
	return PoseBaker.P(right, up, forward)


# --- Poses -----------------------------------------------------------------
# A right-handed batter faces the plate with the pitcher off his left side.

static var STANCE := {
	"drop": 0.1, "hips": Vector3(8, -5, 0), "chest": Vector3(12, -18, 0), "head": Vector3(-8, 85, 0),
	"foot_l": P(-0.34, 0.1, 0.05), "foot_r": P(0.34, 0.1, -0.02),
	# Knees over the feet, a touch out: an athletic set, not a squat.
	"knee_l": P(-0.15, 0, 1), "knee_r": P(0.15, 0, 1),
	# Hands at about shoulder height (the shoulders sit about 1.44 m up the
	# rig), over the back foot, 10-12 in out in front of the body, the back
	# elbow down (VanSuch, Baseball Swing Mechanics, Fig. 1-1, 1-2, 2-14a).
	"hand_r": P(0.2, 1.41, 0.26), "hand_l": P(0.15, 1.36, 0.29),
	"elbow_r": P(0.6, -1, -0.4), "elbow_l": P(-0.15, -1, 0.8),
}
static var STANCE_BOB := _with(STANCE, {"drop": 0.12, "hand_r": P(0.21, 1.46, 0.25), "hand_l": P(0.16, 1.41, 0.28)})
static var STRIDE := _with(STANCE, {
	"drop": 0.14, "hips": Vector3(8, 8, 0), "chest": Vector3(12, -26, 0), "head": Vector3(-8, 85, 0),
	"foot_l": P(-0.52, 0.1, 0.07), "hand_r": P(0.27, 1.46, 0.13), "hand_l": P(0.22, 1.41, 0.16),
})
static var CONTACT := _with(STANCE, {
	# The chest open to the pitcher and upright, tilted back off the plate
	# (VanSuch Fig. 4-43, 5-6a): the front arm reaches straight to the ball
	# (about 174 degrees at the elbow) and the back elbow stays bent (about
	# 130), not the other way round. Eyes on the contact point.
	"drop": 0.14, "hips": Vector3(8, 50, 0), "chest": Vector3(4, 32, -10), "head": Vector3(-5, -5, 0),
	"foot_l": P(-0.52, 0.1, 0.07), "foot_r": P(0.3, 0.14, -0.02), "toe_r": 50.0,
	# Hands out in front toward the pitcher, below the chest, where the grip
	# puts them on the ball (tools/stance_probe.gd).
	"hand_r": P(-0.4, 1.12, 0.3), "hand_l": P(-0.45, 1.09, 0.26),
	"elbow_r": P(0.5, -1, 0), "elbow_l": P(-0.5, -1, 0),
})
static var EXTEND := _with(CONTACT, {
	"hips": Vector3(6, 72, 0), "chest": Vector3(12, 5, 0), "head": Vector3(-5, -47, 0),
	"hand_r": P(-0.42, 1.22, 0.3), "hand_l": P(-0.45, 1.2, 0.22), "elbow_l": P(-1, -0.5, 0),
})
static var FINISH := _with(CONTACT, {
	"drop": 0.16, "hips": Vector3(4, 85, 0), "chest": Vector3(0, 45, -8), "head": Vector3(0, -40, 0),
	"foot_r": P(0.2, 0.18, 0.0), "toe_r": 85.0,
	"hand_r": P(-0.32, 1.55, -0.08), "hand_l": P(-0.36, 1.48, -0.12),
	"elbow_r": P(0, -0.3, 1), "elbow_l": P(-1, -0.5, 0),
})
# Squared around facing the pitcher, bat flat out over the plate.
static var BUNT := {
	"drop": 0.2, "hips": Vector3(10, 75, 0), "chest": Vector3(15, 10, 0), "head": Vector3(-10, 0, 0),
	"foot_l": P(-0.05, 0.1, -0.24), "foot_r": P(0.0, 0.1, 0.26), "toe_l": 70.0, "toe_r": 70.0,
	"knee_l": P(-1, 0, 0), "knee_r": P(-1, 0, 0.2),
	"hand_r": P(-0.42, 1.18, 0.1), "hand_l": P(-0.42, 1.12, -0.1),
	"elbow_r": P(0, -1, 0.5), "elbow_l": P(0, -1, -0.5),
}

# A right-handed pitcher from the stretch, facing home: left side to the
# plate, leg kick, stride and drive, release out front, follow-through.
static var SET := {
	"hips": Vector3(0, -80, 0), "chest": Vector3(5, -10, 0), "head": Vector3(-5, 85, 0),
	"foot_l": P(0.0, 0.1, 0.2), "foot_r": P(0.0, 0.1, -0.14), "toe_l": -80.0, "toe_r": -90.0,
	"knee_l": P(1, 0, 0), "knee_r": P(1, 0, 0),
	"hand_r": P(0.24, 1.2, 0.04), "hand_l": P(0.24, 1.22, 0.1),
	"elbow_r": P(0, -1, -0.6), "elbow_l": P(0, -1, 0.6),
}
static var KICK := _with(SET, {
	"chest": Vector3(-6, -14, 0),
	"foot_l": P(0.18, 0.6, 0.05), "knee_l": P(0.6, 0.6, 0.3),
	"hand_r": P(0.22, 1.32, 0.0), "hand_l": P(0.22, 1.34, 0.06),
})
static var COCK := _with(SET, {
	# Sitting into the stride: the hips drop enough for the lead leg to
	# reach the ground (else the stride foot hangs in the air).
	"drop": 0.3, "hips": Vector3(5, -45, 0), "chest": Vector3(0, -45, 0), "head": Vector3(-5, 90, 0),
	"foot_l": P(0.02, 0.1, 0.78), "toe_l": -30.0, "knee_l": P(0, 0.2, 1),
	"hand_r": P(0.42, 1.62, -0.38), "elbow_r": P(1, -0.4, -0.4),
	"hand_l": P(-0.1, 1.38, 0.55), "elbow_l": P(-0.5, 0.3, 0),
})
static var RELEASE := _with(COCK, {
	"drop": 0.34, "hips": Vector3(10, 0, 0), "chest": Vector3(25, 25, 0), "head": Vector3(-25, -20, 0),
	"foot_r": P(0.12, 0.22, -0.2), "toe_r": -40.0,
	"hand_r": P(0.08, 1.55, 0.5), "elbow_r": P(1, 0.2, 0),
	"hand_l": P(-0.22, 1.1, 0.2), "elbow_l": P(-1, -0.4, 0),
})
static var FOLLOW := _with(RELEASE, {
	"drop": 0.38, "hips": Vector3(15, 20, 0), "chest": Vector3(40, 30, 0), "head": Vector3(-40, -20, 0),
	"foot_r": P(0.28, 0.2, 0.32), "toe_r": 0.0, "knee_r": P(0, 0, 1),
	"hand_r": P(-0.3, 0.7, 0.42), "elbow_r": P(0, -0.2, 1),
})

# A fielder's overhand throw: glove pointed at the target, arm cocked,
# release over the top, and the arm swept through.
static var THROW_COCK := {
	"drop": 0.08, "hips": Vector3(0, -60, 0), "chest": Vector3(-5, -20, 0), "head": Vector3(-5, 75, 0),
	"foot_l": P(-0.04, 0.1, 0.36), "foot_r": P(0.06, 0.1, -0.26), "toe_l": -45.0, "toe_r": -80.0,
	"knee_l": P(0, 0, 1), "knee_r": P(1, 0, 0),
	"hand_l": P(-0.22, 1.42, 0.48), "elbow_l": P(-0.5, 0.2, 0),
	"hand_r": P(0.38, 1.62, -0.4), "elbow_r": P(1, -0.4, -0.4),
}
static var THROW_RELEASE_POSE := _with(THROW_COCK, {
	"drop": 0.12, "hips": Vector3(8, 10, 0), "chest": Vector3(20, 25, 0), "head": Vector3(-20, -30, 0),
	"hand_r": P(0.1, 1.55, 0.5), "elbow_r": P(1, 0.2, 0),
	"hand_l": P(-0.22, 1.1, 0.16), "elbow_l": P(-1, -0.4, 0),
})
static var THROW_FOLLOW := _with(THROW_RELEASE_POSE, {
	"drop": 0.16, "hips": Vector3(14, 25, 0), "chest": Vector3(32, 30, 0), "head": Vector3(-30, -25, 0),
	"foot_r": P(0.18, 0.22, 0.05), "toe_r": 0.0,
	"hand_r": P(-0.26, 0.82, 0.44), "elbow_r": P(0, -0.2, 1),
})

# Fielding.
static var READY := {
	"drop": 0.14, "hips": Vector3(22, 0, 0), "chest": Vector3(14, 0, 0), "head": Vector3(-30, 0, 0),
	"foot_l": P(-0.3, 0.1, 0.03), "foot_r": P(0.3, 0.1, 0.0), "toe_l": 12.0, "toe_r": -12.0,
	"knee_l": P(-0.3, 0, 1), "knee_r": P(0.3, 0, 1),
	"hand_l": P(-0.2, 0.7, 0.34), "hand_r": P(0.2, 0.7, 0.34),
	"elbow_l": P(-1, 0, 0), "elbow_r": P(1, 0, 0),
}
static var READY_BOB := _with(READY, {"drop": 0.17, "hand_l": P(-0.2, 0.67, 0.36), "hand_r": P(0.2, 0.67, 0.36)})
static var SCOOP := _with(READY, {
	"drop": 0.36, "hips": Vector3(38, 0, 0), "chest": Vector3(22, 0, 0), "head": Vector3(-40, 0, 0),
	"foot_l": P(-0.36, 0.1, 0.1), "foot_r": P(0.36, 0.1, -0.06),
	"hand_l": P(-0.04, 0.2, 0.62), "hand_r": P(0.1, 0.26, 0.56),
	"elbow_l": P(-1, 0, 0.2), "elbow_r": P(1, 0, 0.2),
})
static var CATCH_HIGH := {
	"hips": Vector3(-4, 0, 0), "chest": Vector3(-10, 10, 0), "head": Vector3(30, 0, 0),
	"foot_l": P(-0.14, 0.14, 0.06), "foot_r": P(0.16, 0.12, -0.08),
	"hand_l": P(-0.12, 1.95, 0.16), "elbow_l": P(-1, 0, 0),
	"hand_r": P(0.06, 1.8, 0.2), "elbow_r": P(1, 0, 0),
}
# Glove-side lunge, body flat out toward the ball.
static var DIVE := {
	"drop": 0.62, "hips": Vector3(75, 0, -15), "chest": Vector3(10, 0, 0), "head": Vector3(-60, 0, 0),
	"foot_l": P(-0.15, 0.25, -0.62), "foot_r": P(0.18, 0.32, -0.55),
	"knee_l": P(0, -1, 0), "knee_r": P(0, -1, 0),
	"hand_l": P(-0.2, 0.42, 1.05), "elbow_l": P(-1, 0, 0),
	"hand_r": P(0.25, 0.3, 0.5), "elbow_r": P(1, 0, 0),
}
static var TAG_DOWN := _with(READY, {
	"drop": 0.34, "hips": Vector3(40, 0, 0), "chest": Vector3(20, 0, 0), "head": Vector3(-40, 0, 0),
	"foot_l": P(-0.36, 0.1, 0.12), "foot_r": P(0.36, 0.1, -0.06),
	"hand_l": P(-0.06, 0.18, 0.66), "hand_r": P(0.2, 0.5, 0.3),
})
static var CATCHER := {
	"drop": 0.5, "hips": Vector3(10, 0, 0), "chest": Vector3(15, 0, 0), "head": Vector3(-20, 0, 0),
	"foot_l": P(-0.32, 0.1, 0.04), "foot_r": P(0.32, 0.1, 0.0), "toe_l": 25.0, "toe_r": -25.0,
	"knee_l": P(-0.6, 0, 1), "knee_r": P(0.6, 0, 1),
	"hand_l": P(-0.08, 0.82, 0.46), "elbow_l": P(-1, -0.5, 0),
	"hand_r": P(0.3, 0.6, 0.1), "elbow_r": P(1, 0, 0),
}

# Running game.
static var LEAD := {
	"drop": 0.18, "hips": Vector3(18, 0, 0), "chest": Vector3(12, 0, 0), "head": Vector3(-25, 0, 0),
	"foot_l": P(-0.36, 0.1, 0.0), "foot_r": P(0.36, 0.1, 0.0),
	"knee_l": P(-0.5, 0, 1), "knee_r": P(0.5, 0, 1),
	"hand_l": P(-0.28, 0.82, 0.24), "hand_r": P(0.28, 0.82, 0.24),
	"elbow_l": P(-1, 0, 0), "elbow_r": P(1, 0, 0),
}
static var LEAD_SHUFFLE := _with(LEAD, {"drop": 0.2, "foot_l": P(-0.3, 0.12, 0.0), "foot_r": P(0.4, 0.1, 0.0)})
# Feet first: lead leg straight at the bag, the other tucked under, leaning
# back with the hands up.
static var SLIDE_IN := _with(LEAD, {"drop": 0.4, "hips": Vector3(-30, 0, 0), "chest": Vector3(-10, 0, 0), "head": Vector3(20, 0, 0)})
static var SLIDE := {
	"drop": 0.74, "hips": Vector3(-60, 0, 0), "chest": Vector3(-5, 0, 0), "head": Vector3(50, 0, 0),
	"foot_l": P(-0.05, 0.12, 0.86), "knee_l": P(0, 1, 0),
	"foot_r": P(0.18, 0.08, 0.3), "knee_r": P(1, 0.4, 0),
	"hand_l": P(-0.32, 0.95, -0.3), "elbow_l": P(-1, 0, 0),
	"hand_r": P(0.32, 0.95, -0.3), "elbow_r": P(1, 0, 0),
}

static var MOVES := {
	"Stance": {"keys": [[0.0, STANCE], [0.9, STANCE_BOB], [1.8, STANCE]], "loop": true},
	"Swing": {"keys": [[0.0, STANCE], [0.22, STRIDE], [SWING_CONTACT, CONTACT], [0.68, EXTEND], [1.0, FINISH]]},
	"Bunt": {"keys": [[0.0, STANCE], [0.25, BUNT]]},
	"Pitch": {"keys": [[0.0, SET], [0.4, KICK], [0.72, COCK], [PITCH_RELEASE, RELEASE], [PITCH_LENGTH, FOLLOW]]},
	"Throw": {"keys": [[0.0, THROW_COCK], [THROW_RELEASE, THROW_RELEASE_POSE], [1.0, THROW_FOLLOW]]},
	"Ready": {"keys": [[0.0, READY], [0.7, READY_BOB], [1.4, READY]], "loop": true},
	"Scoop": {"keys": [[0.0, READY], [0.25, SCOOP], [0.6, SCOOP]]},
	"Catch_High": {"keys": [[0.0, READY], [0.25, CATCH_HIGH], [0.6, CATCH_HIGH]]},
	"Dive": {"keys": [[0.0, READY], [0.18, DIVE], [0.8, DIVE]]},
	"Tag": {"keys": [[0.0, READY], [0.12, TAG_DOWN], [0.35, TAG_DOWN], [0.6, READY]]},
	"Catcher": {"keys": [[0.0, CATCHER], [1.0, _with(CATCHER, {"drop": 0.52})], [2.0, CATCHER]], "loop": true},
	"Lead": {"keys": [[0.0, LEAD], [0.5, LEAD_SHUFFLE], [1.0, LEAD]], "loop": true},
	"Slide": {"keys": [[0.0, SLIDE_IN], [0.2, SLIDE], [1.0, SLIDE]]},
}


static func _with(base: Dictionary, changes: Dictionary) -> Dictionary:
	var out := base.duplicate()
	out.merge(changes, true)
	return out
