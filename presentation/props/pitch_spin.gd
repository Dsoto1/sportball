class_name PitchSpin
extends RefCounted
## How each pitch spins on its way in, for the look only (the break itself
## comes from the pitch family). Axis is in field space for a pitch
## travelling toward home (+Z): -X is backspin, +X topspin, Z is a bullet
## (gyro) spin. Rates are slowed far below real rpm so the seams read at
## 60 fps instead of strobing.

const BY_FAMILY := {
	&"fastball": [Vector3(-1, 0, 0), 44.0],
	&"cutter": [Vector3(-0.6, 0.3, 0.75), 40.0],
	&"sinker": [Vector3(-0.7, -0.7, 0), 38.0],
	&"slider": [Vector3(0.25, 0.35, 0.9), 36.0],
	&"curveball": [Vector3(1, 0.2, 0), 34.0],
	&"changeup": [Vector3(-0.8, -0.5, 0), 24.0],
	&"splitter": [Vector3(1, 0, 0), 7.0],
	&"junkball": [Vector3(0.3, 1, 0), 1.5],  # knuckler: barely turns over
	&"showstopper": [Vector3(-1, 0, 0), 60.0],
}
const BY_CATEGORY := {&"fastball": [Vector3(-1, 0, 0), 42.0], &"breaking": [Vector3(1, 0, 0), 34.0], &"offspeed": [Vector3(-1, 0, 0), 22.0]}


## [axis (normalized), rate rad/s] for a pitch family.
static func for_family(family: PitchFamilyDef) -> Array:
	var spin: Array = BY_FAMILY.get(family.id, BY_CATEGORY.get(family.category, [Vector3(-1, 0, 0), 40.0]))
	return [(spin[0] as Vector3).normalized(), spin[1]]
