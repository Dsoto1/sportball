class_name PitchMeter
extends Control
## Horizontal pitch meter with a marked sweet spot.

var value := 0.0
var sweet_spot := 0.88


## Navy track, gold fill (the UI reference), a white sweet-spot mark.
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_colored_polygon(MenuStyle.slanted(rect.grow(3.0), 0.35), Color(MenuStyle.DEEP, 0.85))
	var fill := Rect2(Vector2.ZERO, Vector2(size.x * value, size.y))
	draw_rect(fill, MenuStyle.GOLD)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, size.y * 0.4)), Color(1, 1, 1, 0.25))
	var x := size.x * sweet_spot
	draw_rect(Rect2(Vector2(x - 3, -6), Vector2(6, size.y + 12)), Color.WHITE)
	var loop := MenuStyle.slanted(rect.grow(3.0), 0.35)
	loop.append(loop[0])
	draw_polyline(loop, Color(0.31, 0.5, 0.85, 0.8), 2.0, true)
