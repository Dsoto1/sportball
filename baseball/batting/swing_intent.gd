class_name SwingIntent
extends RefCounted
## What the batter (human or AI) did on one pitch.

enum Type { NONE, CONTACT, POWER }

var type: Type = Type.NONE
## Seconds relative to the pitch reaching the plate. Negative = early.
var timing_offset: float = 0.0
## Stick held at the swing, each axis -1..1. +X sends the ball toward
## right field, -X toward left; +Y lifts it, -Y chops it down. The bat finds
## the pitch's height on its own; this only shapes direction and loft.
var stick: Vector2 = Vector2.ZERO
var bats_left: bool = false


static func take() -> SwingIntent:
	return SwingIntent.new()


static func swing(p_type: Type, p_timing_offset: float, p_stick: Vector2 = Vector2.ZERO, p_bats_left: bool = false) -> SwingIntent:
	var intent := SwingIntent.new()
	intent.type = p_type
	intent.timing_offset = p_timing_offset
	intent.stick = p_stick.limit_length(1.0)
	intent.bats_left = p_bats_left
	return intent
