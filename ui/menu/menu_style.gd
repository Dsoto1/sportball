class_name MenuStyle
extends RefCounted
## The menus' look, from the owner's UI/UX design reference: a navy and
## gold broadcast style, slanted panels with a fine carbon weave, gold for
## whatever is selected, Bebas Neue for headings and Montserrat for text,
## and a set of simple line icons. Everything is drawn in code (no image
## assets), so it scales to any window.

const NAVY := Color("0B1F3D")
const GOLD := Color("F5C23D")
const BLUE := Color("1E4178")
const HIGHLIGHT := Color("4FA7FF")
const SUCCESS := Color("36C276")
const WARNING := Color("F59E0B")
const DANGER := Color("D94B4B")
const NEUTRAL := Color("E6EBED")
## Darker navy for panel interiors and the screen's edges.
const DEEP := Color("061226")

const HEAD_FONT := preload("res://assets/third_party/fonts/bebas_neue/BebasNeue-Regular.ttf")
const BODY_FONT := preload("res://assets/third_party/fonts/montserrat/Montserrat.ttf")

## Panels lean this far (px of slant per px of height).
const SLANT := 0.28

static var _body_bold: FontVariation


## Montserrat at a weight (variable font): 400 regular, 600 semibold.
static func body(weight: int = 600) -> Font:
	if weight == 600:
		if _body_bold == null:
			_body_bold = _weighted(600)
		return _body_bold
	return _weighted(weight)


static func _weighted(weight: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = BODY_FONT
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f


## A parallelogram filling `r`, leaning right by `slant` of its height.
static func slanted(r: Rect2, slant: float = SLANT) -> PackedVector2Array:
	var s := r.size.y * slant
	return PackedVector2Array([
		Vector2(r.position.x + s, r.position.y), Vector2(r.end.x, r.position.y),
		Vector2(r.end.x - s, r.end.y), Vector2(r.position.x, r.end.y)])


## A panel: a navy-to-deep fill, a fine diagonal weave, a rim (gold when
## lit), an inner sheen along the top. `fill` tints the body.
static func draw_panel(ci: CanvasItem, r: Rect2, fill: Color, rim: Color, rim_width: float = 2.0, slant: float = SLANT, weave: bool = true) -> void:
	var pts := slanted(r, slant)
	var top := fill.lightened(0.12)
	var bottom := fill.darkened(0.35)
	ci.draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))
	if weave:
		# Carbon weave: short diagonal ticks clipped to the panel's band.
		var step := 7.0
		var ink := Color(1, 1, 1, 0.035)
		var y := r.position.y + 2.0
		var row := 0
		while y < r.end.y - 2.0:
			var t := (y - r.position.y) / r.size.y
			var x0 := lerpf(pts[0].x, pts[3].x, t) + 4.0 + (step * 0.5 if row % 2 == 1 else 0.0)
			var x1 := lerpf(pts[1].x, pts[2].x, t) - 4.0
			var x := x0
			while x < x1 - 4.0:
				ci.draw_line(Vector2(x, y), Vector2(x + 3.0, y + 3.0), ink, 1.0)
				x += step
			y += step * 0.5
			row += 1
	# A soft sheen across the top third.
	var sheen := PackedVector2Array([pts[0], pts[1], pts[1].lerp(pts[2], 0.35), pts[0].lerp(pts[3], 0.35)])
	ci.draw_polygon(sheen, PackedColorArray([Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.0)]))
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, rim, rim_width, true)


## A gold accent stripe: a thin slanted bar (the reference's flashes).
static func draw_stripe(ci: CanvasItem, from: Vector2, length: float, height: float, color: Color) -> void:
	ci.draw_polygon(slanted(Rect2(from, Vector2(length, height)), 1.2), PackedColorArray([color]))


## Text with its top-left at `at`, in a font and size, optionally with a
## dark drop shadow for legibility over the stadium.
static func draw_text(ci: CanvasItem, at: Vector2, text: String, font: Font, size: int, color: Color, shadow: bool = true) -> void:
	var base := at + Vector2(0, font.get_ascent(size))
	if shadow:
		ci.draw_string(font, base + Vector2(2, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0, 0, 0, 0.55))
	ci.draw_string(font, base, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func text_width(text: String, font: Font, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## A line icon centered at `c`, `s` px across: play, person, sound, mute,
## power, cap, tools, gear, trophy, batter, diamond (ballpark), jersey,
## bats (league), back, lock.
static func draw_icon(ci: CanvasItem, name: StringName, c: Vector2, s: float, color: Color) -> void:
	var w := maxf(2.0, s * 0.09)
	var h := s * 0.5
	match name:
		&"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.6, -h * 0.8), c + Vector2(h * 0.8, 0), c + Vector2(-h * 0.6, h * 0.8)]), color)
		&"person":
			ci.draw_arc(c, h * 0.95, 0, TAU, 32, color, w, true)
			ci.draw_circle(c + Vector2(0, -h * 0.25), h * 0.3, color)
			ci.draw_arc(c + Vector2(0, h * 0.55), h * 0.5, PI * 1.12, PI * 1.88, 16, color, w * 1.6, true)
		&"sound", &"mute":
			var body := PackedVector2Array([c + Vector2(-h * 0.9, -h * 0.3), c + Vector2(-h * 0.45, -h * 0.3), c + Vector2(0, -h * 0.75), c + Vector2(0, h * 0.75), c + Vector2(-h * 0.45, h * 0.3), c + Vector2(-h * 0.9, h * 0.3)])
			ci.draw_colored_polygon(body, color)
			if name == &"mute":
				ci.draw_line(c + Vector2(h * 0.3, -h * 0.35), c + Vector2(h * 0.9, h * 0.35), color, w, true)
				ci.draw_line(c + Vector2(h * 0.3, h * 0.35), c + Vector2(h * 0.9, -h * 0.35), color, w, true)
			else:
				ci.draw_arc(c + Vector2(h * 0.05, 0), h * 0.45, -0.9, 0.9, 12, color, w, true)
				ci.draw_arc(c + Vector2(h * 0.05, 0), h * 0.8, -0.9, 0.9, 12, color, w, true)
		&"power":
			ci.draw_arc(c, h * 0.8, -PI * 0.5 + 0.55, PI * 1.5 - 0.55, 28, color, w, true)
			ci.draw_line(c + Vector2(0, -h * 0.95), c + Vector2(0, -h * 0.15), color, w, true)
		&"cap":
			ci.draw_colored_polygon(_half_disc(c + Vector2(0, h * 0.2), h * 0.7, 18), color)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.4, h * 0.2), c + Vector2(h * 1.0, h * 0.25), c + Vector2(h * 0.95, h * 0.42), c + Vector2(h * 0.35, h * 0.38)]), color)
			ci.draw_circle(c + Vector2(0, -h * 0.52), h * 0.1, color)
		&"tools":
			ci.draw_line(c + Vector2(-h * 0.8, h * 0.8), c + Vector2(h * 0.55, -h * 0.55), color, w * 1.6, true)
			ci.draw_line(c + Vector2(h * 0.8, h * 0.8), c + Vector2(-h * 0.55, -h * 0.55), color, w * 1.6, true)
			ci.draw_arc(c + Vector2(h * 0.62, -h * 0.62), h * 0.28, PI * 0.25, PI * 1.85, 12, color, w * 1.3, true)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.95, -h * 0.95), Vector2(h * 0.55, h * 0.3)), color)
		&"gear":
			for i in 8:
				var a := TAU * i / 8.0
				ci.draw_line(c + Vector2(cos(a), sin(a)) * h * 0.6, c + Vector2(cos(a), sin(a)) * h * 0.95, color, w * 2.2)
			ci.draw_arc(c, h * 0.62, 0, TAU, 28, color, w * 1.8, true)
			ci.draw_arc(c, h * 0.25, 0, TAU, 20, color, w, true)
		&"trophy":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.55, -h * 0.8), c + Vector2(h * 0.55, -h * 0.8), c + Vector2(h * 0.35, h * 0.05), c + Vector2(-h * 0.35, h * 0.05)]), color)
			ci.draw_arc(c + Vector2(-h * 0.55, -h * 0.45), h * 0.3, PI * 0.5, PI * 1.5, 10, color, w, true)
			ci.draw_arc(c + Vector2(h * 0.55, -h * 0.45), h * 0.3, -PI * 0.5, PI * 0.5, 10, color, w, true)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.1, h * 0.05), Vector2(h * 0.2, h * 0.45)), color)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.45, h * 0.5), Vector2(h * 0.9, h * 0.25)), color)
		&"batter":
			ci.draw_circle(c + Vector2(-h * 0.1, -h * 0.65), h * 0.2, color)
			ci.draw_line(c + Vector2(-h * 0.1, -h * 0.4), c + Vector2(0, h * 0.25), color, w * 2.0, true)
			ci.draw_line(c + Vector2(0, h * 0.25), c + Vector2(-h * 0.45, h * 0.9), color, w * 1.6, true)
			ci.draw_line(c + Vector2(0, h * 0.25), c + Vector2(h * 0.4, h * 0.9), color, w * 1.6, true)
			ci.draw_line(c + Vector2(-h * 0.1, -h * 0.25), c + Vector2(h * 0.35, -h * 0.45), color, w * 1.4, true)
			ci.draw_line(c + Vector2(h * 0.3, -h * 0.4), c + Vector2(h * 0.95, -h * 0.98), color, w * 1.2, true)
		&"diamond":
			var d := PackedVector2Array([c + Vector2(0, -h * 0.9), c + Vector2(h * 0.9, 0), c + Vector2(0, h * 0.9), c + Vector2(-h * 0.9, 0), c + Vector2(0, -h * 0.9)])
			ci.draw_polyline(d, color, w * 1.4, true)
			for p: Vector2 in [d[0], d[1], d[3]]:
				ci.draw_rect(Rect2(p - Vector2(h * 0.12, h * 0.12), Vector2(h * 0.24, h * 0.24)), color)
			ci.draw_circle(c, h * 0.12, color)
		&"jersey":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.35, -h * 0.85), c + Vector2(-h * 0.95, -h * 0.5), c + Vector2(-h * 0.7, -h * 0.1), c + Vector2(-h * 0.5, -h * 0.25), c + Vector2(-h * 0.5, h * 0.9), c + Vector2(h * 0.5, h * 0.9), c + Vector2(h * 0.5, -h * 0.25), c + Vector2(h * 0.7, -h * 0.1), c + Vector2(h * 0.95, -h * 0.5), c + Vector2(h * 0.35, -h * 0.85), c + Vector2(0, -h * 0.6)]), color)
		&"bats":
			ci.draw_line(c + Vector2(-h * 0.85, h * 0.85), c + Vector2(h * 0.75, -h * 0.75), color, w * 2.2, true)
			ci.draw_line(c + Vector2(h * 0.85, h * 0.85), c + Vector2(-h * 0.75, -h * 0.75), color, w * 2.2, true)
			ci.draw_circle(c + Vector2(0, h * 0.5), h * 0.2, color)
		&"back":
			ci.draw_polyline(PackedVector2Array([c + Vector2(h * 0.3, -h * 0.7), c + Vector2(-h * 0.4, 0), c + Vector2(h * 0.3, h * 0.7)]), color, w * 1.6, true)
		&"lock":
			ci.draw_rect(Rect2(c + Vector2(-h * 0.6, -h * 0.1), Vector2(h * 1.2, h * 0.95)), color)
			ci.draw_arc(c + Vector2(0, -h * 0.15), h * 0.4, PI, TAU, 14, color, w * 1.3, true)
		&"resume":
			draw_icon(ci, &"play", c, s, color)
		&"restart":
			ci.draw_arc(c, h * 0.75, -PI * 0.4, PI * 1.5, 26, color, w * 1.3, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.25, -h * 1.0), c + Vector2(h * 0.75, -h * 0.75), c + Vector2(h * 0.25, -h * 0.45)]), color)


static func _half_disc(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := PI + PI * i / n
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts
