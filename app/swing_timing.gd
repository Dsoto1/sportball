class_name SwingTiming
extends RefCounted
## Turns a swing press into a timing offset against the pitch from
## microsecond timestamps, rather than from the frame the press was
## noticed on.
##
## Godot delivers input events at the start of the frame after they
## happen and does not timestamp them. A press stamped on delivery therefore
## happened, on average, half a frame earlier. Uncorrected, every swing
## reads late by 0..1 frame (up to ~17 ms at 60 fps, a third of the power
## window). Subtracting half the frame interval removes that bias and leaves
## +/- half a frame of jitter.

## Longest frame interval trusted for the correction (a hitch should not
## shift a swing by more than this much).
const MAX_FRAME_INTERVAL := 1.0 / 30.0


## press_usec / release_usec: same clock, microseconds. travel_time: pitch
## flight in seconds. frame_interval: seconds between the last two frames.
## calibration: display/input latency the player has calibrated out (s).
## Returns seconds relative to the pitch reaching the plate (negative = early).
static func offset(press_usec: int, release_usec: int, travel_time: float, frame_interval: float, calibration: float = 0.0) -> float:
	var delivered := float(press_usec - release_usec) / 1000000.0
	var pressed := delivered - 0.5 * clampf(frame_interval, 0.0, MAX_FRAME_INTERVAL)
	return pressed - calibration - travel_time
