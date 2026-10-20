class_name ContactResult
extends RefCounted
## Authoritative outcome of a swing decision against a pitch.

enum Outcome { TAKE, WHIFF, FOUL, IN_PLAY }

var outcome: Outcome = Outcome.TAKE
var swing_type: SwingIntent.Type = SwingIntent.Type.NONE
var timing_offset: float = 0.0
## Timing error divided by the swing's window (|x| <= 1 is a hit window).
var timing_norm: float = 0.0
## Pitch distance from the zone center, in zone half-sizes (1 = edge).
var location_norm: float = 0.0
## 0..1 contact quality.
var quality: float = 0.0
var exit_velocity: float = 0.0
var launch_angle: float = 0.0
var spray_angle: float = 0.0


func to_dict() -> Dictionary:
	return {
		"outcome": Outcome.keys()[outcome],
		"timing_ms": roundi(timing_offset * 1000.0),
		"quality": snappedf(quality, 0.01),
		"exit_velocity": snappedf(exit_velocity, 0.1),
		"launch_angle": snappedf(launch_angle, 0.1),
		"spray_angle": snappedf(spray_angle, 0.1),
	}
