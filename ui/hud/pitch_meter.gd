class_name PitchMeter
extends Control
## Horizontal pitch meter with a marked sweet spot.

var value := 0.0
var sweet_spot := 0.88


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0, 0, 0, 0.6))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * value, size.y)), Color(0.95, 0.55, 0.15))
	var x := size.x * sweet_spot
	draw_rect(Rect2(Vector2(x - 3, -4), Vector2(6, size.y + 8)), Color.WHITE)
	draw_rect(rect, Color.WHITE, false, 2.0)
