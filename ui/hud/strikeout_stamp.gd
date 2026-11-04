class_name StrikeoutStamp
extends Control
## The strikeout moment: a big "K" stamped onto the screen, slamming in
## from huge with a shockwave ring, a shake as it lands, a hold and a
## fade. Swinging is a K; looking (a called strike three) is the
## scorekeeper's backwards K. A caption under it says which.

const TIME := 1.6
## Slam in, land (shake), hold, fade.
const SLAM := 0.14
const SHAKE := 0.22
const FADE_FROM := 0.75
const SIZE := 260
const INK := Color(0.05, 0.07, 0.14)

var _left := 0.0
var _looking := false
var _color := MenuStyle.GOLD
var _rim := Color.WHITE
var _caption := ""
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


## Stamps the K: `looking` mirrors it, `color` fills it (the pitching
## club's, gold by default), `rim` edges the ring, `caption` under it.
func stamp(looking: bool, color: Color = MenuStyle.GOLD, rim: Color = Color.WHITE, caption: String = "") -> void:
	_looking = looking
	_color = color
	_rim = rim
	_caption = caption if caption != "" else ("STRUCK OUT LOOKING" if looking else "STRUCK OUT SWINGING")
	_left = TIME
	visible = true
	queue_redraw()


func playing() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	if _left <= 0.0:
		return
	_left = maxf(_left - delta, 0.0)
	visible = _left > 0.0
	queue_redraw()


func _draw() -> void:
	if _left <= 0.0:
		return
	var u := 1.0 - _left / TIME  # 0..1 through the moment
	var age := u * TIME
	var center := size * Vector2(0.5, 0.42)
	# Slam: from 2.6x down to 1 with a small overshoot.
	var s := 1.0
	if age < SLAM:
		s = lerpf(2.6, 0.92, smoothstep(0.0, 1.0, age / SLAM))
	elif age < SLAM + 0.12:
		s = lerpf(0.92, 1.0, (age - SLAM) / 0.12)
	var alpha := 1.0 - smoothstep(FADE_FROM, 1.0, u)
	if age < SLAM:
		alpha *= smoothstep(0.0, SLAM * 0.6, age)
	# Landing shake.
	if age >= SLAM and age < SLAM + SHAKE:
		var k := 1.0 - (age - SLAM) / SHAKE
		center += Vector2(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1)) * 14.0 * k
	# The shockwave ring off the landing.
	if age >= SLAM:
		var r_age := (age - SLAM) / 0.45
		if r_age < 1.0:
			var radius := SIZE * (0.55 + 0.9 * r_age)
			draw_arc(center, radius, 0.0, TAU, 64, Color(_rim, 0.8 * (1.0 - r_age) * alpha), 10.0 * (1.0 - r_age) + 2.0, true)
	# The stamp: a disc and ring behind the letter, tilted a touch.
	var tilt := deg_to_rad(-8.0)
	draw_set_transform(center, tilt, Vector2.ONE * s)
	draw_circle(Vector2.ZERO, SIZE * 0.5, Color(INK, 0.78 * alpha))
	draw_arc(Vector2.ZERO, SIZE * 0.5, 0.0, TAU, 64, Color(_color, alpha), 9.0, true)
	draw_arc(Vector2.ZERO, SIZE * 0.5 - 16.0, 0.0, TAU, 64, Color(_rim, 0.55 * alpha), 3.0, true)
	var font: Font = MenuStyle.HEAD_FONT
	var font_size := int(SIZE * 0.92)
	var glyph := font.get_string_size("K", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	# Called third strike: the backwards K.
	draw_set_transform(center, tilt, Vector2(-s if _looking else s, s))
	var at := Vector2(-glyph.x * 0.5, (ascent - descent) * 0.5 - descent * 0.1)
	draw_string_outline(font, at, "K", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 18, Color(INK, alpha))
	draw_string(font, at, "K", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(_color, alpha))
	# Caption under the stamp, upright.
	draw_set_transform(center + Vector2(0, SIZE * 0.5 * s + 46.0), 0.0, Vector2.ONE)
	var cap_size := 44
	var cap := font.get_string_size(_caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_size)
	var cap_at := Vector2(-cap.x * 0.5, 0.0)
	var cap_alpha := alpha * smoothstep(SLAM, SLAM + 0.15, age)
	draw_string_outline(font, cap_at, _caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_size, 10, Color(INK, cap_alpha))
	draw_string(font, cap_at, _caption, HORIZONTAL_ALIGNMENT_LEFT, -1, cap_size, Color(Color.WHITE, cap_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
