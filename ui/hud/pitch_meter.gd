class_name PitchMeter
extends Control
## Horizontal pitch meter with a marked sweet spot.

var value := 0.0
var sweet_spot := 0.88
## The release flash: its colour and how much is left (1 -> 0).
var _flash_color := Color.WHITE
var _flash := 0.0
## How close the fill is to the sweet spot this frame (glow).
const GLOW_RANGE := 0.12


## Flashes the meter on release: gold and bright on a clean one, fading to
## red the further off it was (error 0..1).
func release(error: float) -> void:
	_flash_color = Color(1.0, 0.95, 0.6).lerp(Color(1.0, 0.25, 0.2), clampf(error * 2.5, 0.0, 1.0))
	_flash = 1.0
	queue_redraw()


func flashing() -> bool:
	return _flash > 0.0


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta * 2.5, 0.0)
		queue_redraw()


## Navy track, gold fill (the UI reference), a white sweet-spot mark.
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_colored_polygon(MenuStyle.slanted(rect.grow(3.0), 0.35), Color(MenuStyle.DEEP, 0.85))
	var fill := Rect2(Vector2.ZERO, Vector2(size.x * value, size.y))
	draw_rect(fill, MenuStyle.GOLD)
	draw_rect(Rect2(fill.position, Vector2(fill.size.x, size.y * 0.4)), Color(1, 1, 1, 0.25))
	var x := size.x * sweet_spot
	# The sweet spot glows as the fill closes on it.
	var near := 1.0 - clampf(absf(value - sweet_spot) / GLOW_RANGE, 0.0, 1.0)
	if near > 0.0:
		for k in 3:
			var g := 6.0 + 7.0 * (k + 1) * near
			draw_rect(Rect2(Vector2(x - g, -6 - g * 0.4), Vector2(g * 2.0, size.y + 12 + g * 0.8)), Color(1.0, 0.95, 0.6, 0.18 * near))
	draw_rect(Rect2(Vector2(x - 3, -6), Vector2(6, size.y + 12)), Color.WHITE)
	if _flash > 0.0:
		# A bright wash over the bar and a ring bursting out from it.
		draw_colored_polygon(MenuStyle.slanted(rect.grow(3.0), 0.35), Color(Color.WHITE.lerp(_flash_color, 0.4), 0.7 * _flash))
		var grow := 18.0 * (1.0 - _flash)
		var ring := MenuStyle.slanted(rect.grow(5.0 + grow), 0.35)
		ring.append(ring[0])
		draw_polyline(ring, Color(_flash_color, _flash), 4.0, true)
	var loop := MenuStyle.slanted(rect.grow(3.0), 0.35)
	loop.append(loop[0])
	draw_polyline(loop, Color(0.31, 0.5, 0.85, 0.8), 2.0, true)
