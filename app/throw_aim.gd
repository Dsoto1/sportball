class_name ThrowAim
extends RefCounted
## Directional throwing: the stick (or WASD) picks the base the way the
## diamond looks from behind home plate. Right = first, up = second,
## left = third, down = home. A centered stick means "best play" (0).

const AUTO := 0
const DEADZONE := 0.5


static func base_for(dir: Vector2) -> int:
	if dir.length() < DEADZONE:
		return AUTO
	if absf(dir.x) >= absf(dir.y):
		return FieldLayout.FIRST if dir.x > 0.0 else FieldLayout.THIRD
	return FieldLayout.SECOND if dir.y > 0.0 else 4
