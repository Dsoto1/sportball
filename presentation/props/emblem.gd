class_name Emblem
## A club's mark built in code from TeamDef (emblem_shape, emblem_glyph and
## its colors): a flat badge in the local XY plane, facing +Z, `size` meters
## across. A club with an emblem_texture shows that image instead, so a
## finished logo drops in without code. Used on boards, walls, dugouts and
## banners.

const SHAPES := [&"disc", &"shield", &"gear", &"halo", &"diamond", &"laurel", &"star", &"atom", &"blossom", &"trident", &"wings", &"flame"]
const FONT := preload("res://assets/third_party/fonts/bungee/Bungee-Regular.ttf")


static func build(team: TeamDef, size: float = 1.0, glow: float = 0.3) -> Node3D:
	var root := Node3D.new()
	root.name = "Emblem"
	if team.emblem_texture != null:
		var quad := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(size, size)
		quad.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = team.emblem_texture
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		quad.material_override = mat
		root.add_child(quad)
		return root
	var r := size * 0.5
	var shape: StringName = team.emblem_shape if team.emblem_shape in SHAPES else &"disc"
	var lift := size * 0.004
	match shape:
		&"halo":
			# A tilted ring of light with the mark rising through it.
			_layer(root, _ring(_ellipse(r, r * 0.42, 48), _ellipse(r * 0.8, r * 0.27, 48)), team.secondary_color, glow * 2.0, 0.0)
		&"atom":
			# Three orbits around a nucleus (a ball).
			for i in 3:
				var orbit := _ring(_ellipse(r, r * 0.34, 40), _ellipse(r * 0.86, r * 0.24, 40))
				var turned := PackedVector3Array()
				var basis := Basis(Vector3.BACK, PI * i / 3.0)
				for v in orbit:
					turned.append(basis * v)
				_layer(root, turned, team.primary_color, glow * 2.0, lift * i)
			_layer(root, _poly(_circle(r * 0.26, 24)), team.highlight_color, glow, lift * 4.0)
			_layer(root, _ring(_circle(r * 0.26, 24), _circle(r * 0.22, 24)), team.secondary_color, glow, lift * 5.0)
		&"blossom":
			# Five petals on a dark disc, a gold heart.
			_layer(root, _poly(_circle(r, 40)), team.dark_color, glow, 0.0)
			for k in 5:
				var a := PI * 0.5 + TAU * k / 5.0
				_layer(root, _poly(_leaf(Vector2(cos(a), sin(a)) * r * 0.42, r * 0.4, r * 0.28, a)), team.primary_color, glow, lift)
			_layer(root, _poly(_circle(r * 0.2, 20)), team.accent_color, glow * 1.5, lift * 2.0)
		&"trident":
			_layer(root, _poly(_circle(r, 40)), team.primary_color, glow, 0.0)
			_layer(root, _ring(_circle(r, 40), _circle(r * 0.9, 40)), team.accent_color, glow, lift)
			var gold := team.support_color
			_layer(root, _poly(_rect(Vector2(0, -r * 0.15), r * 0.12, r * 1.3)), gold, glow, lift * 2.0)
			_layer(root, _poly(_rect(Vector2(0, r * 0.2), r * 0.9, r * 0.1)), gold, glow, lift * 2.0)
			for x in [-0.42, 0.0, 0.42]:
				_layer(root, _poly(_rect(Vector2(x * r, r * 0.38), r * 0.1, r * 0.4)), gold, glow, lift * 2.0)
				_layer(root, _poly(PackedVector2Array([Vector2(x * r - r * 0.11, r * 0.58), Vector2(x * r + r * 0.11, r * 0.58), Vector2(x * r, r * 0.8)])), gold, glow, lift * 2.0)
		&"wings":
			for side: float in [-1.0, 1.0]:
				for f in 4:
					var y := r * (0.25 - f * 0.17)
					var len := r * (0.95 - f * 0.12)
					var pts := PackedVector2Array([Vector2(side * r * 0.12, y), Vector2(side * len, y + r * 0.12), Vector2(side * len * 0.92, y - r * 0.05), Vector2(side * r * 0.12, y - r * 0.12)])
					_layer(root, _poly(_ccw(pts)), team.secondary_color if f % 2 == 0 else team.primary_color, glow, lift)
			_layer(root, _poly(_circle(r * 0.3, 28)), team.dark_color, glow, lift * 2.0)
			_layer(root, _ring(_circle(r * 0.3, 28), _circle(r * 0.24, 28)), team.secondary_color, glow * 1.5, lift * 3.0)
		&"flame":
			# A teardrop flame, tip up, in three nested layers.
			var drop := PackedVector2Array()
			for i in 36:
				var t := TAU * i / 36.0
				drop.append(Vector2(sin(t) * pow(absf(sin(t * 0.5)), 1.1) * r * 0.85, cos(t) * r * 0.95))
			drop = _ccw(drop)
			_layer(root, _poly(drop), team.secondary_color, glow, 0.0)
			_layer(root, _poly(_scaled(drop, 0.74)), team.primary_color, glow * 1.6, lift)
			_layer(root, _poly(_scaled(drop, 0.42)), team.highlight_color, glow * 2.0, lift * 2.0)
		&"laurel":
			_layer(root, _poly(_circle(r * 0.62, 40)), team.primary_color, glow, 0.0)
			_layer(root, _ring(_circle(r * 0.62, 40), _circle(r * 0.56, 40)), team.secondary_color, glow, lift)
			for side: float in [-1.0, 1.0]:
				# Leaves up each side, following the arc, open at the top.
				for i in 7:
					var a := deg_to_rad(-70.0 + i * 22.0)
					var c := Vector2(side * cos(a), sin(a)) * r * 0.8
					var along := a + PI * 0.5
					_layer(root, _poly(_leaf(c, r * 0.17, r * 0.07, along if side > 0.0 else PI - along)), team.secondary_color, glow, lift)
		_:
			var outline := _outline(shape, r)
			_layer(root, _poly(outline), team.dark_color, glow, 0.0)
			_layer(root, _poly(_scaled(outline, 0.86)), team.primary_color, glow, lift)
			_layer(root, _ring(_scaled(outline, 0.78), _scaled(outline, 0.72)), team.accent_color, glow * 1.5, lift * 2.0)
	var glyph := team.emblem_glyph
	if glyph == "*" or shape == &"star" and glyph.is_empty():
		_layer(root, _poly(_star(r * 0.45, r * 0.12, 4)), team.secondary_color if shape != &"star" else team.highlight_color, glow * 2.0, lift * 3.0)
	elif not glyph.is_empty():
		var label := Label3D.new()
		label.text = glyph
		label.font = FONT
		label.pixel_size = size / 160.0 / maxf(1.0, glyph.length() * 0.75)
		label.font_size = 96
		label.modulate = team.secondary_color if shape in [&"laurel", &"halo"] else team.highlight_color
		label.outline_size = 0
		label.double_sided = false
		label.position = Vector3(0.0, size * 0.02, lift * 4.0)
		root.add_child(label)
	return root


## The badge outline (unit-free, radius r, counter-clockwise).
static func _outline(shape: StringName, r: float) -> PackedVector2Array:
	match shape:
		&"shield":
			# Flat top, straight sides, a rounded point at the bottom.
			var pts := PackedVector2Array([Vector2(-r * 0.85, r * 0.9), Vector2(r * 0.85, r * 0.9)])
			for i in 17:
				var t := i / 16.0
				pts.append(Vector2(r * 0.85 * cos(t * PI), -pow(sin(t * PI), 0.8) * r))
			return _ccw(pts)
		&"gear":
			var pts := PackedVector2Array()
			var teeth := 10
			for i in teeth * 4:
				var a := TAU * i / (teeth * 4)
				pts.append(Vector2(cos(a), sin(a)) * (r if (i % 4) < 2 else r * 0.82))
			return pts
		&"diamond":
			return PackedVector2Array([Vector2(r, 0), Vector2(0, r), Vector2(-r, 0), Vector2(0, -r)])
		&"star":
			return _star(r, r * 0.45, 5)
		_:
			return _circle(r, 48)


static func _circle(r: float, n: int) -> PackedVector2Array:
	return _ellipse(r, r, n)


static func _ellipse(rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _rect(c: Vector2, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-w, -h) * 0.5, c + Vector2(w, -h) * 0.5, c + Vector2(w, h) * 0.5, c + Vector2(-w, h) * 0.5])


static func _star(outer: float, inner: float, points: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in points * 2:
		var a := PI * 0.5 + PI * i / points
		pts.append(Vector2(cos(a), sin(a)) * (outer if i % 2 == 0 else inner))
	return pts


static func _leaf(center: Vector2, length: float, width: float, angle: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(center + Vector2(cos(a) * length, sin(a) * width).rotated(angle))
	return pts


static func _scaled(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p * k)
	return out


static func _ccw(pts: PackedVector2Array) -> PackedVector2Array:
	if Geometry2D.is_polygon_clockwise(pts):
		pts.reverse()
	return pts


## Triangles filling a simple polygon.
static func _poly(pts: PackedVector2Array) -> PackedVector3Array:
	var tris := PackedVector3Array()
	var idx := Geometry2D.triangulate_polygon(pts)
	for i in idx:
		tris.append(Vector3(pts[i].x, pts[i].y, 0.0))
	return tris


## Triangles between two outlines with the same point count.
static func _ring(outer: PackedVector2Array, inner: PackedVector2Array) -> PackedVector3Array:
	var tris := PackedVector3Array()
	var n := outer.size()
	for i in n:
		var j := (i + 1) % n
		for p in [outer[i], outer[j], inner[j], outer[i], inner[j], inner[i]]:
			tris.append(Vector3(p.x, p.y, 0.0))
	return tris


static func _layer(root: Node3D, tris: PackedVector3Array, color: Color, glow: float, z: float) -> void:
	if tris.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tris
	var normals := PackedVector3Array()
	normals.resize(tris.size())
	normals.fill(Vector3.BACK)
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if glow > 0.0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position.z = z
	root.add_child(mi)
