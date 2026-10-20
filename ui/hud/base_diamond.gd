class_name BaseDiamond
extends Control
## Base occupancy indicator. Occupied bases are filled AND labelled so the
## state never relies on color alone.

var occupied: Array[bool] = [false, false, false]


func set_bases(bases: Array[StringName]) -> void:
	for i in 3:
		occupied[i] = bases[i] != &""
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.28
	var spots := [c + Vector2(r, 0), c + Vector2(0, -r), c + Vector2(-r, 0)]
	var font := get_theme_default_font()
	for i in 3:
		var p: Vector2 = spots[i]
		var square := PackedVector2Array([p + Vector2(0, -12), p + Vector2(12, 0), p + Vector2(0, 12), p + Vector2(-12, 0), p + Vector2(0, -12)])
		if occupied[i]:
			draw_colored_polygon(square, Color(1.0, 0.82, 0.2))
		draw_polyline(square, Color.WHITE, 2.0)
		if occupied[i]:
			draw_string(font, p + Vector2(-6, 30), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color.WHITE)
