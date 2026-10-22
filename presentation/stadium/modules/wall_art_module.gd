extends StadiumModule
## Motifs painted along the outfield wall between the distance numbers and
## the emblems, every "every" degrees: waves, snowflakes, zigzag bolts,
## blossoms, gears, stars or crossed bars, in the home club's colors (the
## accent glows when "glow" is above zero).

## Angles the wall already uses (distance numbers and emblems).
const TAKEN := [-43.0, -38.0, -20.0, 0.0, 20.0, 38.0, 43.0]


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var motif := StringName(piece.param("motif"))
	var glow := float(piece.param("glow"))
	var root := Node3D.new()
	root.name = stadium.unique_name("WallArt")
	stadium.add_child(root)
	var every := float(piece.param("every"))
	var a := -45.0 + every * 0.5
	while a < 45.0:
		var clear := true
		for t: float in TAKEN:
			if absf(a - t) < 3.5:
				clear = false
		var h := FieldLayout.fence_height(a, stadium.tuning)
		if clear and h >= 1.4:
			var size := minf(h * 0.8, 2.8) * piece.size
			var mark := Node3D.new()
			root.add_child(mark)
			var inward := stadium.wall_inward(a)
			var spot := stadium.point(a, FieldLayout.fence_distance(a, stadium.tuning), minf(h * 0.5, 2.0)) + inward * 0.3
			mark.look_at_from_position(spot, spot - inward, Vector3.UP)
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
