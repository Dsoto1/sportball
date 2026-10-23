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
	return _library


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
	# Hands at the back shoulder (the shoulders sit about 1.44 m up the
	# rig), just in front of it, the back elbow up, so the bat rests back
	# behind the head, as every hitter sets up.
	"hand_r": P(0.27, 1.47, 0.04), "hand_l": P(0.23, 1.41, 0.08),
	"elbow_r": P(1, 0.25, -0.45), "elbow_l": P(-0.15, -1, 1.1),
}
static var STANCE_BOB := _with(STANCE, {"drop": 0.12, "hand_r": P(0.28, 1.49, 0.03), "hand_l": P(0.24, 1.43, 0.07)})
static var STRIDE := _with(STANCE, {
	"drop": 0.14, "hips": Vector3(8, 8, 0), "chest": Vector3(12, -26, 0), "head": Vector3(-8, 85, 0),
	"foot_l": P(-0.52, 0.1, 0.07), "hand_r": P(0.18, 1.3, 0.06), "hand_l": P(0.12, 1.24, 0.1),
})
static var CONTACT := _with(STANCE, {
	# Hips lead, shoulders lag (hip-shoulder separation): hips 50 degrees open,
	# shoulders 35, so the arms extend out in front instead of across the
	# chest. Eyes on the contact point.
	"drop": 0.14, "hips": Vector3(8, 50, 0), "chest": Vector3(18, -15, 0), "head": Vector3(-5, -5, 0),
	"foot_l": P(-0.52, 0.1, 0.07), "foot_r": P(0.3, 0.14, -0.02), "toe_r": 50.0,
	"hand_r": P(-0.05, 1.08, 0.48), "hand_l": P(-0.1, 1.05, 0.44),
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
