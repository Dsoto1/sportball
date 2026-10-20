class_name SwingIntent
extends RefCounted
## What the batter (human or AI) did on one pitch.

enum Type { NONE, CONTACT, POWER }

var type: Type = Type.NONE
## Seconds relative to the pitch reaching the plate. Negative = early.
var timing_offset: float = 0.0
## Where the batter aimed the bat in the plate plane (x, height).
var cursor: Vector2 = Vector2.ZERO
var bats_left: bool = false


static func take() -> SwingIntent:
	return SwingIntent.new()


static func swing(p_type: Type, p_timing_offset: float, p_cursor: Vector2, p_bats_left: bool = false) -> SwingIntent:
	var intent := SwingIntent.new()
	intent.type = p_type
	intent.timing_offset = p_timing_offset
	intent.cursor = p_cursor
	intent.bats_left = p_bats_left
	return intent
