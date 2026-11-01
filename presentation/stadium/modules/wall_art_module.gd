extends StadiumModule
## The outfield wall's artwork. With a "layout" (from the park's sheet, left
## to right), each entry [angle, motif, scale, text-or-color] paints one
## piece at its spot: the club emblem, painted scenery (peaks, mesas, a
## volcano, waves, rocks), signs with lettering, a clock, freight cars, a
## vault door, banners, a torii, coral, fish, lamps, a fountain, shields...
## Without one, a motif repeats every "every" degrees between the distance
## numbers. In the home club's colors; accents glow when "glow" is above 0.

## Angles the wall already uses (distance numbers and emblems).
const TAKEN := [-43.0, -38.0, -20.0, 0.0, 20.0, 38.0, 43.0]


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var motif := StringName(piece.param("motif"))
	var glow := float(piece.param("glow"))
	var root := Node3D.new()
	root.name = stadium.unique_name("WallArt")
	stadium.add_child(root)
	var layout: Array = piece.param("layout")
	if not layout.is_empty():
		for entry: Array in layout:
			var at := float(entry[0])
			var h := FieldLayout.fence_height(at, stadium.tuning)
			# As on the sheets, a piece fills most of the wall's height.
			var size := minf(h * 0.82, 3.5) * piece.size * (float(entry[2]) if entry.size() > 2 else 1.0)
			var mark := Node3D.new()
			root.add_child(mark)
			var inward := stadium.wall_inward(at)
			var spot := stadium.point(at, FieldLayout.fence_distance(at, stadium.tuning), minf(h * 0.5, 2.0)) + inward * (0.3 + 0.25 * float(entry[2] if entry.size() > 2 else 1.0))
			mark.look_at_from_position(spot, spot - inward, Vector3.UP)
			var extra: Variant = entry[3] if entry.size() > 3 else null
			# A sign takes its text in the fourth slot and its plate color in the fifth.
			if entry.size() > 4 and entry[4] is Color:
				extra = [entry[3], entry[4]]
			_draw_layout(stadium, mark, StringName(entry[1]), size, home, glow, extra, h)
			_clear_wall(stadium, mark, inward)
		return
	var every := float(piece.param("every"))
	var a := -45.0 + every * 0.5
	while a < 45.0:
		var clear := true
		for t: float in TAKEN:
			if absf(a - t) < 3.5:
				clear = false
		var h := FieldLayout.fence_height(a, stadium.tuning)
		if clear and h >= 1.4:
			var size := minf(h * 0.7, 2.6) * piece.size
			var mark := Node3D.new()
			root.add_child(mark)
			var inward := stadium.wall_inward(a)
			var spot := stadium.point(a, FieldLayout.fence_distance(a, stadium.tuning), minf(h * 0.5, 2.0)) + inward * 0.3
			mark.look_at_from_position(spot, spot - inward, Vector3.UP)
			if bool(piece.param("frame")):
				_frame(mark, motif, size, home, glow)
			_draw(mark, motif, size, home, glow)
		a += every


static func _draw(root: Node3D, motif: StringName, size: float, home: TeamDef, glow: float) -> void:
	var r := size * 0.5
	var main := home.sign_color()
	var second := home.highlight_color
	match motif:
		&"waves":
			# Two light swells cresting toward the middle (the sheets paint
			# them pale blue and white on the dark wall).
			for row in 2:
				var pts := PackedVector2Array()
				var n := 32
				var lift := (0.5 - row) * r * 0.5
				for i in n + 1:
					var x := lerpf(-r * 2.4, r * 2.4, float(i) / n)
					pts.append(Vector2(x, sin(x / r * PI * 0.9) * r * 0.35 + lift))
				for i in range(n, -1, -1):
					var x := lerpf(-r * 2.4, r * 2.4, float(i) / n)
					var taper := 1.0 - absf(x) / (r * 2.4)
					pts.append(Vector2(x, sin(x / r * PI * 0.9) * r * 0.35 + lift - r * (0.08 + 0.22 * taper)))
				Emblem._layer(root, Emblem._poly(pts), Color(0.62, 0.82, 0.96) if row == 0 else Color(0.94, 0.97, 1.0), glow, 0.005 * row)
		&"snowflake":
			for k in 3:
				_bar(root, Vector2.ZERO, r * 2.0, r * 0.12, PI * k / 3.0, second, glow)
				for side: float in [-1.0, 1.0]:
					for end: float in [-1.0, 1.0]:
						var base := Vector2(cos(PI * k / 3.0), sin(PI * k / 3.0)) * r * 0.62 * end
						_bar(root, base, r * 0.5, r * 0.09, PI * k / 3.0 + side * PI / 4.0 * end, second, glow)
		&"zigzag":
			var pts := [Vector2(-r * 2.0, 0), Vector2(-r * 1.2, r * 0.5), Vector2(-r * 0.4, -r * 0.5), Vector2(r * 0.4, r * 0.5), Vector2(r * 1.2, -r * 0.5), Vector2(r * 2.0, 0)]
			for i in pts.size() - 1:
				var p0: Vector2 = pts[i]
				var p1: Vector2 = pts[i + 1]
				_bar(root, (p0 + p1) * 0.5, p0.distance_to(p1) + r * 0.1, r * 0.16, (p1 - p0).angle(), home.accent_color if glow > 0.0 else main, maxf(glow, 0.0))
		&"blossom":
			for k in 5:
				var c := Vector2(cos(TAU * k / 5.0 + PI * 0.5), sin(TAU * k / 5.0 + PI * 0.5)) * r * 0.5
				Emblem._layer(root, Emblem._poly(_circle(c, r * 0.42)), Color(0.97, 0.7, 0.82), glow, 0.0)
			Emblem._layer(root, Emblem._poly(_circle(Vector2.ZERO, r * 0.25)), Color(0.98, 0.85, 0.4), glow, 0.01)
		&"gear":
			var gear := PackedVector2Array()
			for i in 40:
				var a := TAU * i / 40.0
				gear.append(Vector2(cos(a), sin(a)) * (r if (i % 4) < 2 else r * 0.8))
			Emblem._layer(root, Emblem._ring(gear, _scaled(_circle(Vector2.ZERO, r * 0.45, 40), 1.0)), main, glow, 0.0)
		&"star":
			Emblem._layer(root, Emblem._poly(Emblem._star(r, r * 0.42, 5)), main, glow, 0.0)
		&"wings":
			for side: float in [-1.0, 1.0]:
				for f in 3:
					_bar(root, Vector2(side * r * (0.55 + f * 0.25), r * (0.2 - f * 0.2)), r * 1.1, r * 0.14, side * 0.25, main if f == 0 else second, glow)
		&"flame":
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.6, -r), Vector2(r * 0.6, -r), Vector2(r * 0.45, 0), Vector2(r * 0.15, r), Vector2(0, r * 0.2), Vector2(-r * 0.25, r * 0.7), Vector2(-r * 0.5, 0)]))), home.accent_color, maxf(glow, 0.8), 0.0)
		&"trident":
			_bar(root, Vector2(0, -r * 0.2), r * 1.6, r * 0.12, PI * 0.5, main, glow)
			_bar(root, Vector2(0, r * 0.35), r * 1.0, r * 0.12, 0.0, main, glow)
			for x in [-0.45, 0.0, 0.45]:
				_bar(root, Vector2(x * r, r * 0.65), r * 0.6, r * 0.12, PI * 0.5, main, glow)
		&"crossed":
			_bar(root, Vector2.ZERO, r * 2.2, r * 0.22, PI / 4.0, main, glow)
			_bar(root, Vector2.ZERO, r * 2.2, r * 0.22, -PI / 4.0, main, glow)
		_:
			var mark := Emblem.build(home, size, 0.3)
			root.add_child(mark)


## A thin border in the club's highlight color around a motif, so each
## one reads as its own padded wall panel, as on the sheets.
static func _frame(root: Node3D, motif: StringName, size: float, home: TeamDef, glow: float) -> void:
	var r := size * 0.5
	var half_w := r * (2.5 if motif in [&"waves", &"zigzag"] else 1.35)
	var half_h := r * 1.2
	var line := r * 0.12
	var color := home.highlight_color
	var g := glow * 0.5
	_bar(root, Vector2(0, half_h), half_w * 2.0 + line, line, 0.0, color, g)
	_bar(root, Vector2(0, -half_h), half_w * 2.0 + line, line, 0.0, color, g)
	_bar(root, Vector2(-half_w, 0), half_h * 2.0, line, PI * 0.5, color, g)
	_bar(root, Vector2(half_w, 0), half_h * 2.0, line, PI * 0.5, color, g)
	# Corner studs.
	for x: float in [-half_w, half_w]:
		for y: float in [-half_h, half_h]:
			Emblem._layer(root, Emblem._poly(_circle(Vector2(x, y), line * 1.3, 10)), color, g, 0.005)


## One layout piece. `extra` is a sign's text or a color override; `wall_h`
## lets scenery sit on the bottom edge of the wall.
static func _draw_layout(stadium: Stadium, root: Node3D, motif: StringName, size: float, home: TeamDef, glow: float, extra: Variant, wall_h: float) -> void:
	var r := size * 0.5
	var tint: Color = extra if extra is Color else Color(0, 0, 0, 0)
	if extra is Array:
		tint = extra[1]
		extra = extra[0]
	var floor_y := -minf(wall_h * 0.5, 2.0) + 0.15
	match motif:
		&"club":
			# The badge's own disc is about 0.6 of its size: a little over
			# size makes the whole badge most of the wall's height.
			root.add_child(Emblem.build(home, size * 1.15, 0.3))
		&"peaks":
			var snow := tint if tint.a > 0.0 else Color(0.92, 0.96, 1.0)
			for k in 3:
				var cx := (k - 1) * r * 1.3
				var hh := r * (1.6 if k == 1 else 1.1)
				var base_w := hh * 1.3
				Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(cx - base_w, floor_y), Vector2(cx + base_w, floor_y), Vector2(cx, floor_y + hh)]))), snow.darkened(0.08 + 0.06 * k).lerp(Color(0.55, 0.7, 0.9), 0.35), glow, 0.0)
				Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(cx - base_w * 0.35, floor_y + hh * 0.65), Vector2(cx + base_w * 0.35, floor_y + hh * 0.65), Vector2(cx, floor_y + hh)]))), snow, glow, 0.01)
		&"mesa":
			# A stepped desert skyline: buttes and a tall mesa, flat-topped.
			var rock := tint if tint.a > 0.0 else Color(0.85, 0.4, 0.18)
			var sky := [[-2.6, 0.0], [-2.6, 0.45], [-2.0, 0.45], [-2.0, 0.85], [-1.3, 0.85], [-1.3, 0.55], [-0.4, 0.55], [-0.4, 1.3], [0.7, 1.3], [0.7, 0.7], [1.6, 0.7], [1.6, 0.35], [2.6, 0.35], [2.6, 0.0]]
			var pts := PackedVector2Array()
			for p in sky:
				pts.append(Vector2(r * float(p[0]), floor_y + r * float(p[1])))
			Emblem._layer(root, Emblem._poly(Emblem._ccw(pts)), rock, glow, 0.0)
		&"volcano":
			var rock := tint if tint.a > 0.0 else Color(0.3, 0.12, 0.1)
			var hh := r * 1.9
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 2.2, floor_y), Vector2(r * 2.2, floor_y), Vector2(r * 0.35, floor_y + hh), Vector2(-r * 0.35, floor_y + hh)]))), rock, glow, 0.0)
			for k in 3:
				var x0 := (k - 1) * r * 0.25
				_bar(root, Vector2(x0 + (k - 1) * r * 0.5, floor_y + hh * 0.55), hh * 0.85, r * 0.08, PI * 0.5 + (k - 1) * 0.35, Color(1.0, 0.45, 0.08), maxf(glow, 1.2))
			Emblem._layer(root, Emblem._poly(_circle(Vector2(0, floor_y + hh), r * 0.3, 12)), Color(1.0, 0.55, 0.1), maxf(glow, 1.5), 0.01)
		&"rocks":
			var rock := tint if tint.a > 0.0 else Color(0.78, 0.66, 0.5)
			for k in 3:
				var c := Vector2((k - 1) * r * 0.9, floor_y + r * 0.45)
				var blob := PackedVector2Array()
				for i in 9:
					var a := TAU * i / 9.0
					blob.append(c + Vector2(cos(a) * r * 0.65, maxf(sin(a), -0.2) * r * (0.6 + 0.2 * (k % 2))))
				Emblem._layer(root, Emblem._poly(Emblem._ccw(blob)), rock.darkened(0.12 * k), glow, 0.005 * k)
		&"lamp":
			# A gaslamp post painted in gold (the sheets' lamp-lined walls).
			var post := tint if tint.a > 0.0 else Color(0.82, 0.66, 0.32)
			_bar(root, Vector2(0, -r * 0.3), r * 1.6, r * 0.12, PI * 0.5, post, 0.0)
			_bar(root, Vector2(0, r * 0.55), r * 0.5, r * 0.08, 0.0, post, 0.0)
			_bar(root, Vector2(0, -r * 1.05), r * 0.45, r * 0.12, 0.0, post, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.22, r * 0.5), Vector2(r * 0.22, r * 0.5), Vector2(r * 0.3, r * 0.95), Vector2(-r * 0.3, r * 0.95)]))), Color(1.0, 0.82, 0.45), maxf(glow, 1.2), 0.01)
		&"clock":
			Emblem._layer(root, Emblem._poly(_circle(Vector2.ZERO, r * 0.95, 32)), Color(0.15, 0.13, 0.1), 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(_circle(Vector2.ZERO, r * 0.82, 32)), Color(0.96, 0.93, 0.85), glow * 0.5, 0.01)
			for k in 12:
				var a := TAU * k / 12.0
				_bar(root, Vector2(cos(a), sin(a)) * r * 0.7, r * 0.12, r * 0.04, a, Color(0.1, 0.1, 0.1), 0.0)
			_bar(root, Vector2(0, r * 0.22), r * 0.45, r * 0.06, PI * 0.5, Color(0.1, 0.1, 0.1), 0.0)
			_bar(root, Vector2(r * 0.2, 0), r * 0.4, r * 0.05, 0.0, Color(0.1, 0.1, 0.1), 0.0)
		&"sign":
			var text := String(extra) if extra is String else home.team_name.to_upper()
			# Long names stack on two lines, as the sheets letter them.
			var lines := _two_lines(text)
			var longest := 0
			for line: String in lines:
				longest = maxi(longest, line.length())
			var tall := lines.size() > 1
			var w := r * (0.5 * longest + 0.6) * (0.8 if tall else 1.0)
			var plate_h := r * (1.55 if tall else 1.2)
			var plate := tint if tint.a > 0.0 else Color(0.9, 0.86, 0.74)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2.ZERO, w, plate_h))), plate.darkened(0.5), 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2.ZERO, w - r * 0.15, plate_h - r * 0.15))), plate, glow * 0.3, 0.01)
			var label := stadium.label("\n".join(lines), 64, plate.darkened(0.75), root)
			label.pixel_size = r * (0.0076 if tall else 0.0095)
			label.line_spacing = -6.0
			label.position = Vector3(0, 0, 0.05)
		&"freight":
			for k in 2:
				var cx := (k - 0.5) * r * 2.3
				var car := Color(0.62, 0.16, 0.12) if k == 0 else Color(0.45, 0.25, 0.14)
				Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2(cx, 0), r * 2.1, r * 1.1))), car, glow * 0.2, 0.0)
				for rib in 5:
					_bar(root, Vector2(cx - r * 0.84 + rib * r * 0.42, 0), r * 1.0, r * 0.05, PI * 0.5, car.darkened(0.35), 0.0)
				for wheel: float in [-0.7, 0.7]:
					Emblem._layer(root, Emblem._poly(_circle(Vector2(cx + wheel * r, -r * 0.62), r * 0.17, 10)), Color(0.1, 0.1, 0.1), 0.0, 0.01)
		&"vault":
			Emblem._layer(root, Emblem._poly(_circle(Vector2.ZERO, r, 32)), Color(0.35, 0.37, 0.4), 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(_circle(Vector2.ZERO, r * 0.78, 32)), Color(0.55, 0.57, 0.6), 0.0, 0.01)
			for k in 3:
				_bar(root, Vector2.ZERO, r * 1.3, r * 0.1, PI * k / 3.0, Color(0.78, 0.65, 0.3), glow * 0.5)
			Emblem._layer(root, Emblem._poly(_circle(Vector2.ZERO, r * 0.18, 16)), Color(0.85, 0.7, 0.3), glow, 0.02)
		&"banner_x":
			var cloth := tint if tint.a > 0.0 else Color(0.75, 0.08, 0.1)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.5, r), Vector2(r * 0.5, r), Vector2(r * 0.5, -r * 0.8), Vector2(0, -r), Vector2(-r * 0.5, -r * 0.8)]))), cloth, glow * 0.3, 0.0)
			_bar(root, Vector2(0, r * 0.05), r * 1.0, r * 0.12, PI / 4.0, Color(0.95, 0.95, 0.92), 0.0)
			_bar(root, Vector2(0, r * 0.05), r * 1.0, r * 0.12, -PI / 4.0, Color(0.95, 0.95, 0.92), 0.0)
		&"torii":
			var red := Color(0.8, 0.12, 0.1)
			for side: float in [-1.0, 1.0]:
				_bar(root, Vector2(side * r * 0.6, -r * 0.1), r * 1.7, r * 0.14, PI * 0.5, red, glow * 0.3)
			_bar(root, Vector2(0, r * 0.75), r * 1.9, r * 0.16, 0.0, Color(0.15, 0.1, 0.1), 0.0)
			_bar(root, Vector2(0, r * 0.45), r * 1.5, r * 0.11, 0.0, red, glow * 0.3)
		&"coral":
			var c := tint if tint.a > 0.0 else Color(1.0, 0.42, 0.42)
			var branches := [[0.0, -0.3, 1.2, 0.0], [-0.25, 0.2, 0.6, -0.6], [0.25, 0.15, 0.7, 0.55], [-0.45, 0.45, 0.35, -0.2], [0.42, 0.5, 0.35, 0.25]]
			for b: Array in branches:
				_bar(root, Vector2(float(b[0]) * r, float(b[1]) * r), float(b[2]) * r, r * 0.13, PI * 0.5 + float(b[3]), c, glow * 0.5)
		&"fish":
			var c := tint if tint.a > 0.0 else Color(0.62, 0.7, 0.75)
			Emblem._layer(root, Emblem._poly(Emblem._ellipse(r * 1.1, r * 0.35, 20)), c, glow * 0.3, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(r * 1.0, 0), Vector2(r * 1.5, r * 0.45), Vector2(r * 1.4, 0), Vector2(r * 1.5, -r * 0.45)]))), c, glow * 0.3, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.1, r * 0.3), Vector2(r * 0.3, r * 0.3), Vector2(r * 0.05, r * 0.75)]))), c.darkened(0.15), 0.0, 0.01)
		&"fountain":
			var stone := Color(0.9, 0.88, 0.82)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2(0, -r * 0.7), r * 1.8, r * 0.3))), stone, 0.0, 0.0)
			_bar(root, Vector2(0, -r * 0.2), r * 0.8, r * 0.18, PI * 0.5, stone, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2(0, r * 0.25), r * 1.0, r * 0.18))), stone, 0.0, 0.01)
			for k in 3:
				_bar(root, Vector2((k - 1) * r * 0.35, r * 0.65), r * 0.75, r * 0.07, PI * 0.5 + (k - 1) * 0.3, Color(0.6, 0.85, 1.0), maxf(glow, 0.6))
		&"zigzag":
			# A glowing trace (the reactor's monitor line), in its own color.
			var line := tint if tint.a > 0.0 else Color(0.35, 1.0, 0.45)
			var pts := [Vector2(-r * 2.4, 0), Vector2(-r * 1.6, r * 0.6), Vector2(-r * 0.8, -r * 0.6), Vector2(0, r * 0.7), Vector2(r * 0.8, -r * 0.6), Vector2(r * 1.6, r * 0.6), Vector2(r * 2.4, 0)]
			for i in pts.size() - 1:
				var p0: Vector2 = pts[i]
				var p1: Vector2 = pts[i + 1]
				_bar(root, (p0 + p1) * 0.5, p0.distance_to(p1) + r * 0.08, r * 0.13, (p1 - p0).angle(), line, maxf(glow, 1.0))
		&"icicles":
			# Ice hanging from the wall's cap under a lip of snow, long and
			# short, across the piece's width.
			var cap_y := floor_y + wall_h - 0.2
			var span := r * 2.4
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2(0, cap_y - 0.12), span * 2.0 + r * 0.3, 0.32))), Color(0.97, 0.99, 1.0), glow * 0.3, 0.004)
			var n := 14
			for i in n:
				var x := lerpf(-span, span, (i + 0.5) / n)
				var long := r * (0.55 + 0.75 * float((i * 5) % 7) / 6.0)
				var half := r * 0.16 * (1.0 + 0.4 * float(i % 2))
				Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(x - half, cap_y), Vector2(x + half, cap_y), Vector2(x, cap_y - long)]))), Color(0.72, 0.88, 1.0), maxf(glow, 0.6), 0.008)
				Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(x - half * 0.3, cap_y), Vector2(x + half * 0.1, cap_y), Vector2(x - half * 0.1, cap_y - long * 0.8)]))), Color(1, 1, 1), maxf(glow, 0.4), 0.012)
		&"mural":
			# A painted portrait (the rail yard's conductor): a framed panel,
			# shoulders in a navy coat with brass buttons, a face, moustache,
			# and the peaked cap with its gold band.
			var frame := tint if tint.a > 0.0 else Color(0.18, 0.3, 0.36)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2.ZERO, r * 1.7, r * 2.0))), frame.darkened(0.3), 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2.ZERO, r * 1.55, r * 1.85))), frame, 0.0, 0.004)
			var coat := Color(0.12, 0.17, 0.32)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.72, -r * 0.92), Vector2(r * 0.72, -r * 0.92), Vector2(r * 0.6, -r * 0.3), Vector2(r * 0.2, -r * 0.15), Vector2(-r * 0.2, -r * 0.15), Vector2(-r * 0.6, -r * 0.3)]))), coat, 0.0, 0.008)
			for b in 3:
				Emblem._layer(root, Emblem._poly(_circle(Vector2(0, -r * 0.35 - b * r * 0.18), r * 0.05, 8)), Color(0.9, 0.72, 0.3), 0.0, 0.012)
			var skin := Color(0.86, 0.66, 0.5)
			Emblem._layer(root, Emblem._poly(Emblem._ellipse(r * 0.3, r * 0.36, 18)), skin, 0.0, 0.01)
			root.get_child(root.get_child_count() - 1).position.y = r * 0.15
			Emblem._layer(root, Emblem._poly(Emblem._ellipse(r * 0.18, r * 0.06, 10)), Color(0.35, 0.22, 0.14), 0.0, 0.014)
			root.get_child(root.get_child_count() - 1).position.y = r * 0.06
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2(0, r * 0.5), r * 0.62, r * 0.24))), coat, 0.0, 0.014)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2(0, r * 0.42), r * 0.62, r * 0.06))), Color(0.9, 0.72, 0.3), 0.0, 0.018)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.36, r * 0.36), Vector2(r * 0.3, r * 0.36), Vector2(r * 0.42, r * 0.3), Vector2(-r * 0.36, r * 0.3)]))), Color(0.05, 0.06, 0.08), 0.0, 0.018)
		&"posters":
			# A cluster of vintage bills pasted up: four plates in faded
			# colors, each with a band of lettering-like stripes.
			var colors := [Color(0.62, 0.22, 0.16), Color(0.85, 0.78, 0.58), Color(0.25, 0.45, 0.5), Color(0.78, 0.6, 0.25)]
			for k in 4:
				var c := Vector2((k % 2 - 0.5) * r * 1.05, (0.5 - k / 2) * r * 1.0)
				Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(c, r * 0.95, r * 0.88))), colors[k], 0.0, 0.004 * k)
				for line in 3:
					_bar(root, c + Vector2(0, r * (0.22 - line * 0.2)), r * (0.7 - line * 0.15), r * 0.07, 0.0, (colors[k] as Color).darkened(0.55) if k != 1 else Color(0.2, 0.15, 0.1), 0.0, 0.02)
		&"waterfall":
			# A painted cascade between two rock shoulders: bright water with
			# white streaks over it and foam at the foot, from the wall's top
			# to its floor.
			var top := floor_y + minf(wall_h - 0.35, r * 2.3)
			var mid := (top + floor_y) * 0.5
			var tall := top - floor_y
			var rock := tint if tint.a > 0.0 else Color(0.42, 0.36, 0.3)
			for side: float in [-1.0, 1.0]:
				var blob := PackedVector2Array()
				for i in 10:
					var a := TAU * i / 10.0
					blob.append(Vector2(side * r * 1.2 + cos(a) * r * 0.32, mid + sin(a) * tall * 0.52))
				Emblem._layer(root, Emblem._poly(Emblem._ccw(blob)), rock.darkened(0.08 * (side + 1.0)), 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2(0, mid), r * 2.0, tall))), Color(0.42, 0.74, 1.0), maxf(glow, 0.35), 0.008)
			var streaks := [[-0.75, 0.12], [-0.45, 0.22], [-0.12, 0.12], [0.15, 0.24], [0.48, 0.14], [0.74, 0.1]]
			for st: Array in streaks:
				_bar(root, Vector2(float(st[0]) * r, mid), tall, float(st[1]) * r, PI * 0.5, Color(0.96, 0.99, 1.0), maxf(glow, 0.5), 0.014)
			Emblem._layer(root, Emblem._poly(Emblem._ellipse(r * 1.2, r * 0.24, 18)), Color(0.97, 0.99, 1.0), maxf(glow, 0.5), 0.02)
			root.get_child(root.get_child_count() - 1).position.y = floor_y + r * 0.14
		&"swan":
			var white := Color(0.97, 0.96, 0.92)
			Emblem._layer(root, Emblem._poly(Emblem._ellipse(r * 0.85, r * 0.38, 22)), white, glow * 0.3, 0.0)
			root.get_child(root.get_child_count() - 1).position = Vector3(r * 0.15, -r * 0.35, 0)
			# The raised wing and the S of the neck.
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.2, -r * 0.2), Vector2(r * 0.85, -r * 0.25), Vector2(r * 0.55, r * 0.35), Vector2(r * 0.1, r * 0.15)]))), white.darkened(0.12), glow * 0.3, 0.01)
			var neck := [Vector2(-r * 0.55, -r * 0.3), Vector2(-r * 0.75, r * 0.1), Vector2(-r * 0.6, r * 0.45), Vector2(-r * 0.4, r * 0.7), Vector2(-r * 0.55, r * 0.9)]
			for i in neck.size() - 1:
				var a: Vector2 = neck[i]
				var b: Vector2 = neck[i + 1]
				_bar(root, (a + b) * 0.5, a.distance_to(b) + r * 0.08, r * 0.16, (b - a).angle(), white, glow * 0.3)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.6, r * 0.95), Vector2(-r * 0.6, r * 0.82), Vector2(-r * 0.98, r * 0.86)]))), Color(0.95, 0.55, 0.15), glow * 0.3, 0.02)
		&"scorpion":
			var gold := tint if tint.a > 0.0 else Color(0.86, 0.68, 0.3)
			for k in 3:
				Emblem._layer(root, Emblem._poly(Emblem._ellipse(r * (0.32 - k * 0.04), r * 0.22, 14)), gold.darkened(0.08 * k), glow * 0.3, 0.0)
				root.get_child(root.get_child_count() - 1).position = Vector3(-r * 0.3 + k * r * 0.42, -r * 0.45, 0)
			# The tail curls up over the back to the sting.
			var tail := [Vector2(r * 0.55, -r * 0.4), Vector2(r * 0.85, -r * 0.1), Vector2(r * 0.9, r * 0.3), Vector2(r * 0.7, r * 0.62), Vector2(r * 0.4, r * 0.7)]
			for i in tail.size() - 1:
				var a: Vector2 = tail[i]
				var b: Vector2 = tail[i + 1]
				_bar(root, (a + b) * 0.5, a.distance_to(b) + r * 0.05, r * (0.2 - i * 0.025), (b - a).angle(), gold, glow * 0.3)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(r * 0.42, r * 0.78), Vector2(r * 0.42, r * 0.6), Vector2(r * 0.18, r * 0.62)]))), gold.lightened(0.2), glow * 0.5, 0.01)
			for side: float in [-1.0, 1.0]:
				_bar(root, Vector2(-r * 0.8, -r * 0.45 + side * r * 0.22), r * 0.5, r * 0.1, side * 0.5, gold, glow * 0.3)
				Emblem._layer(root, Emblem._poly(Emblem._ellipse(r * 0.18, r * 0.1, 10)), gold, glow * 0.3, 0.01)
				root.get_child(root.get_child_count() - 1).position = Vector3(-r * 1.08, -r * 0.45 + side * r * 0.4, 0)
				for leg in 3:
					_bar(root, Vector2(-r * 0.15 + leg * r * 0.3, -r * 0.45 + side * r * 0.3), r * 0.35, r * 0.06, side * (1.2 + leg * 0.15), gold.darkened(0.15), 0.0)
		&"shark":
			var grey := tint if tint.a > 0.0 else Color(0.55, 0.66, 0.72)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 1.4, 0), Vector2(-r * 0.6, r * 0.32), Vector2(r * 0.8, r * 0.18), Vector2(r * 1.2, 0), Vector2(r * 0.8, -r * 0.2), Vector2(-r * 0.6, -r * 0.28)]))), grey, glow * 0.3, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.4, -r * 0.05), Vector2(r * 0.6, -r * 0.08), Vector2(r * 0.6, -r * 0.18), Vector2(-r * 0.4, -r * 0.22)]))), Color(0.92, 0.94, 0.95), 0.0, 0.01)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(-r * 0.2, r * 0.28), Vector2(r * 0.25, r * 0.22), Vector2(r * 0.05, r * 0.75)]))), grey.darkened(0.15), glow * 0.3, 0.01)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(r * 1.1, 0), Vector2(r * 1.55, r * 0.5), Vector2(r * 1.4, 0), Vector2(r * 1.55, -r * 0.45)]))), grey.darkened(0.1), glow * 0.3, 0.01)
			Emblem._layer(root, Emblem._poly(_circle(Vector2(-r * 1.0, r * 0.08), r * 0.05, 8)), Color(0.05, 0.05, 0.06), 0.0, 0.02)
		&"garden":
			# A flower bed painted along the wall's foot: a hedge of round
			# bushes with blossoms on them (the sheet's flowered walls).
			var bloom := tint if tint.a > 0.0 else Color(0.97, 0.62, 0.78)
			var span := r * 2.4
			var bushes := 7
			for i in bushes:
				var x := lerpf(-span, span, float(i) / (bushes - 1))
				var rr := r * (0.42 + 0.12 * float((i * 7) % 3))
				Emblem._layer(root, Emblem._poly(_circle(Vector2(x, floor_y + rr * 0.8), rr, 14)), Color(0.18, 0.42, 0.2).lightened(0.06 * float(i % 2)), 0.0, 0.0)
				for f in 4:
					var fa := TAU * f / 4.0 + i
					var fc := Vector2(x + cos(fa) * rr * 0.55, floor_y + rr * 0.8 + sin(fa) * rr * 0.5)
					Emblem._layer(root, Emblem._poly(_circle(fc, r * 0.11, 8)), bloom if f % 2 == 0 else Color(0.98, 0.95, 0.9), glow * 0.3, 0.01)
		&"shield":
			var c := tint if tint.a > 0.0 else home.primary_color
			Emblem._layer(root, Emblem._poly(Emblem._ccw(Emblem._outline(&"shield", r * 0.9))), home.accent_color, 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(Emblem._outline(&"shield", r * 0.75))), c, glow * 0.3, 0.01)
			_bar(root, Vector2(0, r * 0.05), r * 1.0, r * 0.12, PI * 0.5, home.highlight_color, 0.0)
		_:
			_draw(root, motif, size, home, glow)


static func _rect_pts(c: Vector2, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-w * 0.5, -h * 0.5), c + Vector2(w * 0.5, -h * 0.5), c + Vector2(w * 0.5, h * 0.5), c + Vector2(-w * 0.5, h * 0.5)])


static func _bar(root: Node3D, center: Vector2, length: float, width: float, angle: float, color: Color, glow: float, z: float = 0.0) -> void:
	var d := Vector2(cos(angle), sin(angle)) * length * 0.5
	var n := Vector2(-d.y, d.x).normalized() * width * 0.5
	var pts := PackedVector2Array([center - d - n, center + d - n, center + d + n, center - d + n])
	Emblem._layer(root, Emblem._poly(Emblem._ccw(pts)), color, glow, z)


static func _circle(c: Vector2, r: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		pts.append(c + Vector2(cos(TAU * i / n), sin(TAU * i / n)) * r)
	return pts


static func _scaled(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p * k)
	return out


## A sign's text on one line, or two (split at the space nearest the
## middle) when it runs past 12 letters.
static func _two_lines(text: String) -> PackedStringArray:
	if text.length() <= 12 or not text.contains(" "):
		return PackedStringArray([text])
	var mid := text.length() / 2
	var best := -1
	for i in text.length():
		if text[i] == " " and (best < 0 or absi(i - mid) < absi(best - mid)):
			best = i
	return PackedStringArray([text.substr(0, best), text.substr(best + 1)])


## Flat art against the curved wall: its ends would sink into the wall
## (the wall curves away behind a straight panel), so the piece moves out
## from the wall until both ends, and every corner, stand clear of it.
static func _clear_wall(stadium: Stadium, mark: Node3D, inward: Vector3) -> void:
	var box := AABB()
	var first := true
	for v: VisualInstance3D in mark.find_children("*", "VisualInstance3D", true, false):
		var local := _relative(mark, v) * v.get_aabb()
		box = local if first else box.merge(local)
		first = false
	if first:
		return
	var worst := 0.0
	for x: float in [box.position.x, box.end.x]:
		for y: float in [box.position.y, box.end.y]:
			var p := mark.transform * Vector3(x, y, 0.0)
			var angle := FieldLayout.spray_angle_of(p)
			var wall := FieldLayout.fence_distance(angle, stadium.tuning)
			worst = maxf(worst, Vector2(p.x, p.z).length() - (wall - 0.12))
	if worst > 0.0:
		mark.position += inward * worst


static func _relative(root: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		t = (n as Node3D).transform * t
		n = n.get_parent()
	return t
