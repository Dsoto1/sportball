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
			var size := minf(h * 0.7, 2.6) * piece.size * (float(entry[2]) if entry.size() > 2 else 1.0)
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
			for row in 2:
				var pts := PackedVector2Array()
				var n := 24
				for i in n + 1:
					var x := lerpf(-r * 2.2, r * 2.2, float(i) / n)
					pts.append(Vector2(x, sin(x / r * PI * 1.5) * r * 0.22 + (row - 0.5) * r * 0.55))
				for i in range(n, -1, -1):
					var x := lerpf(-r * 2.2, r * 2.2, float(i) / n)
					pts.append(Vector2(x, sin(x / r * PI * 1.5) * r * 0.22 + (row - 0.5) * r * 0.55 - r * 0.16))
				Emblem._layer(root, Emblem._poly(pts), main if row == 0 else second, glow, 0.0)
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
			root.add_child(Emblem.build(home, size, 0.3))
		&"peaks":
			var snow := tint if tint.a > 0.0 else Color(0.92, 0.96, 1.0)
			for k in 3:
				var cx := (k - 1) * r * 1.3
				var hh := r * (1.6 if k == 1 else 1.1)
				var base_w := hh * 1.3
				Emblem._layer(root, Emblem._poly(Emblem._ccw(PackedVector2Array([Vector2(cx - base_w, floor_y), Vector2(cx + base_w, floor_y), Vector2(cx, floor_y + hh)]))), snow.darkened(0.25 + 0.1 * k), glow, 0.0)
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
			_bar(root, Vector2(0, -r * 0.3), r * 1.6, r * 0.1, PI * 0.5, Color(0.12, 0.12, 0.14), 0.0)
			_bar(root, Vector2(0, r * 0.55), r * 0.5, r * 0.08, 0.0, Color(0.12, 0.12, 0.14), 0.0)
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
			var w := r * (0.55 * text.length() + 0.6)
			var plate := tint if tint.a > 0.0 else Color(0.9, 0.86, 0.74)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2.ZERO, w, r * 1.2))), plate.darkened(0.5), 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(_rect_pts(Vector2.ZERO, w - r * 0.15, r * 1.05))), plate, glow * 0.3, 0.01)
			var label := stadium.label(text, 64, plate.darkened(0.75), root)
			label.pixel_size = r * 0.0095
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
		&"shield":
			var c := tint if tint.a > 0.0 else home.primary_color
			Emblem._layer(root, Emblem._poly(Emblem._ccw(Emblem._outline(&"shield", r * 0.9))), home.accent_color, 0.0, 0.0)
			Emblem._layer(root, Emblem._poly(Emblem._ccw(Emblem._outline(&"shield", r * 0.75))), c, glow * 0.3, 0.01)
			_bar(root, Vector2(0, r * 0.05), r * 1.0, r * 0.12, PI * 0.5, home.highlight_color, 0.0)
		_:
			_draw(root, motif, size, home, glow)


static func _rect_pts(c: Vector2, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-w * 0.5, -h * 0.5), c + Vector2(w * 0.5, -h * 0.5), c + Vector2(w * 0.5, h * 0.5), c + Vector2(-w * 0.5, h * 0.5)])


static func _bar(root: Node3D, center: Vector2, length: float, width: float, angle: float, color: Color, glow: float) -> void:
	var d := Vector2(cos(angle), sin(angle)) * length * 0.5
	var n := Vector2(-d.y, d.x).normalized() * width * 0.5
	var pts := PackedVector2Array([center - d - n, center + d - n, center + d + n, center - d + n])
	Emblem._layer(root, Emblem._poly(Emblem._ccw(pts)), color, glow, 0.0)


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
