class_name Stadium
extends Node3D
## The ballpark around the field, built in code from a StadiumDef. The core
## every park has: a stepped seating bowl (outfield bleachers, a dark
## batter's eye in center, aisles), a crowd of billboard fans that jumps on
## big moments, dugouts, a backstop net and distance markers. Everything
## else is a module placed by the park's pieces (StadiumModules: scoreboards,
## light towers, skyline, halo, bay, warehouse, fountains, dome), built with
## the kit below (box, label, glow, point, profile). Presentation only: the
## field's rules live in BaseballTuning.

const CROWD_SHADER := preload("res://presentation/stadium/crowd.gdshader")
const SKYLINE_SHADER := preload("res://presentation/stadium/skyline.gdshader")
const FOUNTAIN_SHADER := preload("res://presentation/stadium/fountain.gdshader")
const DISPLAY_FONT := preload("res://assets/third_party/fonts/bungee/Bungee-Regular.ttf")

const ROW_DEPTH := 0.9
const ROW_RISE := 0.45
## Each deck above the first starts this much higher than the row below it
## would: its front is the fascia band that carries the club's wordmarks.
const DECK_JUMP := 2.6
const ANGLE_STEP := 1.0
## Inner edge of the stands (meters from home) by |spray angle| past the
## foul poles; inside the poles the bleachers start just behind the wall.
const FOUL_EDGE := [[45.0, 97.0], [55.0, 72.0], [65.0, 52.0], [80.0, 40.0], [100.0, 34.0], [130.0, 27.0], [180.0, 24.0]]
const BATTERS_EYE := 6.0
const AISLE_EVERY := 8.0
const SEAT_SPACING := 0.62
const FIELD_CENTER := Vector3(0.0, 0.0, -45.0)
const WATER := Color(0.06, 0.22, 0.36)
## How far out the bay reaches (meters from home).
const WATER_EDGE := 420.0

## The park being built and its rules (for wall distances and heights).
var def: StadiumDef
var tuning: BaseballTuning
## Seeded from the park, so a park looks the same every visit.
var rng := RandomNumberGenerator.new()
var _crowd_mat: ShaderMaterial
var _excitement := 0.0
var _water: Array[StadiumPiece] = []
var _names := {}
## Every scoreboard in the park: {cells, lamps, batter, first_column}.
var _boards: Array[Dictionary] = []
var _board_key := ""


func build(p_tuning: BaseballTuning, p_def: StadiumDef, home: TeamDef, away: TeamDef) -> void:
	tuning = p_tuning
	def = p_def
	rng.seed = hash(def.id)
	_boards.clear()
	_names.clear()
	_board_key = ""
	for child in get_children():
		child.queue_free()
	_water = def.pieces_of(&"bay")
	# The core every park has: the bowl and its crowd, the batter's eye,
	# dugouts, backstop and wall markers. Then its modules, in order.
	_build_bowl()
	_build_crowd(home, away)
	_build_batters_eye()
	_build_dugouts(home, away)
	_build_backstop()
	_build_markers(home)
	_build_fascia(home)
	for piece in def.pieces:
		if piece != null:
			StadiumModules.build(self, piece, home, away)
	# The park casts no shadows on the field: the sheets' fields are evenly
	# lit, and low suns would rake the stands' shadows across the infield.
	# Players keep theirs.
	for gi: GeometryInstance3D in find_children("*", "GeometryInstance3D", true, false):
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## The crowd reacts (0..1); it settles back over a couple of seconds.
func cheer(level: float) -> void:
	_excitement = maxf(_excitement, clampf(level, 0.0, 1.0))


func _process(delta: float) -> void:
	_excitement = move_toward(_excitement, 0.08, delta * 0.4)
	if _crowd_mat != null:
		_crowd_mat.set_shader_parameter("excitement", _excitement)


# --- Bowl ---------------------------------------------------------------

## Inner edge radius, first row height and row count at a spray angle.
## Modules use it to stand behind or on top of the stands.
func profile(angle: float) -> Vector3:
	angle = wrapf(angle, -180.0, 180.0)
	var a := absf(angle)
	var inner := 0.0
	if a <= 45.0:
		inner = FieldLayout.fence_distance(angle, tuning) + 5.0
	else:
		# Start from this side's own corner, then close in behind home.
		var corner := FieldLayout.fence_distance(signf(angle) * 45.0, tuning) + 5.0
		for i in range(1, FOUL_EDGE.size()):
			if a <= FOUL_EDGE[i][0]:
				var t: float = (a - FOUL_EDGE[i - 1][0]) / (FOUL_EDGE[i][0] - FOUL_EDGE[i - 1][0])
				var start: float = corner if i == 1 else FOUL_EDGE[i - 1][1]
				inner = lerpf(start, FOUL_EDGE[i][1], t)
				break
	var foul := smoothstep(40.0, 60.0, a)
	var first := lerpf(FieldLayout.fence_height(clampf(angle, -45.0, 45.0), tuning) + 0.6, 1.3, foul)
	var rows := roundf(lerpf(float(def.outfield_rows), float(def.foul_rows), foul))
	if is_water(angle):
		rows = minf(rows, 5.0)  # a low wall of seats along the water
	return Vector3(inner, first, rows)


## Rows per deck: the foul stands split evenly into def.decks decks.
func rows_per_deck() -> int:
	return maxi(1, ceili(float(def.foul_rows) / maxi(def.decks, 1)))


## The last row under a deck front is a walkway: no fans standing in
## front of the fascia's wordmarks.
func _is_walkway(angle: float, k: int) -> bool:
	return absf(angle) > 50.0 and is_deck_front(k + 1)


func is_deck_front(k: int) -> bool:
	return def.decks > 1 and k % rows_per_deck() == 0


## Height of row k's tread at a spray angle (p = profile(angle)). The decks
## step up in the foul stands; the outfield bleachers are one deck, and
## the jump fades in past the foul poles so the bowl stays closed.
func row_height(angle: float, p: Vector3, k: int) -> float:
	var deck := floori(float(k) / rows_per_deck()) if def.decks > 1 else 0
	return p.y + k * ROW_RISE + deck * DECK_JUMP * smoothstep(45.0, 60.0, absf(angle))


## The back and top of the stands at a spray angle: (radius, height of the
## last row's tread). Modules stand on or behind this.
func stand_top(angle: float) -> Vector2:
	var p := profile(angle)
	var rows := int(p.z)
	return Vector2(p.x + rows * ROW_DEPTH, row_height(angle, p, rows - 1))


## How tall the park's arcade facades stand at a spray angle (0 where
## there is none), cornice included.
func facade_height(angle: float) -> float:
	angle = wrapf(angle, -180.0, 180.0)
	var best := 0.0
	for piece in def.pieces_of(&"arcade"):
		var spans := [[piece.angle, float(piece.param("span"))]]
		if piece.mirrored:
			spans.append([-piece.angle, -float(piece.param("span"))])
		for sp: Array in spans:
			var lo := minf(sp[0], sp[0] + sp[1])
			var hi := maxf(sp[0], sp[0] + sp[1])
			var a := angle
			if a < lo:
				a += 360.0
			if a >= lo and a <= hi:
				best = maxf(best, float(piece.param("height")) * piece.size + 0.7)
	return best


## The top of everything standing on the back of the stands at an angle:
## (radius, height) of the stands' last row raised by any facade there.
## Boards, signs, flags and lamps stand on this so a facade never hides them.
func skyline_top(angle: float) -> Vector2:
	var top := stand_top(angle)
	return Vector2(top.x, top.y + facade_height(angle))


## Open water at this spray angle: within 22 degrees of a bay piece.
func is_water(angle: float) -> bool:
	for bay in _water:
		var side := signf(bay.angle) if bay.angle != 0.0 else 1.0
		if signf(angle) == side and absf(absf(angle) - absf(bay.angle)) < 22.0:
			return true
	return false


func _is_aisle(angle: float) -> bool:
	return fmod(absf(angle) + 0.5, AISLE_EVERY) < 1.0


func point(angle: float, radius: float, height: float) -> Vector3:
	return FieldLayout.direction_for_spray(angle) * radius + Vector3.UP * height


func _build_bowl() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The facade and the ground outside are their own meshes, each in its
	# own surface.
	var facade := SurfaceTool.new()
	facade.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ground := SurfaceTool.new()
	ground.begin(Mesh.PRIMITIVE_TRIANGLES)
	var riser := def.structure_color.darkened(0.35)
	var eye := Color(0.06, 0.1, 0.09)
	var a := -180.0
	while a < 180.0:
		var b := a + ANGLE_STEP
		var pa := profile(a)
		var pb := profile(b)
		var mid := (a + b) * 0.5
		var rows := int(maxf(pa.z, pb.z))
		for k in rows:
			var seat := def.seat_color if k % 2 == 0 else def.seat_color_alt
			if _is_aisle(mid):
				seat = def.structure_color
			if absf(mid) < BATTERS_EYE:
				seat = eye
			var ra := pa.x + k * ROW_DEPTH
			var rb := pb.x + k * ROW_DEPTH
			var ha := row_height(a, pa, k)
			var hb := row_height(b, pb, k)
			var below_a := 0.0 if k == 0 else row_height(a, pa, k - 1)
			var below_b := 0.0 if k == 0 else row_height(b, pb, k - 1)
			# Riser (the step's face), then the tread (where fans sit). A
			# deck's front is its fascia band, in the park's accent.
			var face := riser
			if absf(mid) < BATTERS_EYE:
				face = eye
			elif k > 0 and is_deck_front(k):
				face = def.accent_color.lerp(def.structure_color, 0.25)
			_quad(st, point(a, ra, below_a), point(b, rb, below_b), point(b, rb, hb), point(a, ra, ha), face)
			_quad(st, point(a, ra, ha), point(b, rb, hb), point(b, rb + ROW_DEPTH, hb), point(a, ra + ROW_DEPTH, ha), seat)
		# Back of the stand: a facade down to the ground with a trim band.
		var top_a := row_height(a, pa, rows - 1)
		var top_b := row_height(b, pb, rows - 1)
		var back_a := pa.x + rows * ROW_DEPTH
		var back_b := pb.x + rows * ROW_DEPTH
		_quad(st, point(a, back_a, top_a), point(b, back_b, top_b), point(b, back_b, top_b + 1.2), point(a, back_a, top_a + 1.2), def.accent_color.darkened(0.2))
		_quad(facade, point(b, back_b, 0.0), point(a, back_a, 0.0), point(a, back_a, top_a + 1.2), point(b, back_b, top_b + 1.2), Color.WHITE)
		# Outside the park: the bay on the water side, ground everywhere else.
		var outside := def.skyline_color.darkened(0.45) if def.ground_color.a == 0.0 else def.ground_color
		var edge := back_a + 1.0
		if is_water(mid):
			_quad(st, point(a, edge, 0.14), point(a, WATER_EDGE, 0.14), point(b, WATER_EDGE, 0.14), point(b, back_b + 1.0, 0.14), WATER)
			edge = WATER_EDGE
		# Above the field's 320 m grass slab (top at -0.01), so the two never flicker.
		_quad(ground, point(a, edge, 0.1), point(a, 950.0, 0.1), point(b, 950.0, 0.1), point(b, edge if edge == WATER_EDGE else back_b + 1.0, 0.1), outside)
		a = b
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "SeatingBowl"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	add_child(mi)
	if StadiumSurfaces.KINDS.has(def.stand_surface):
		mi.material_override = StadiumSurfaces.material(def.stand_surface, Color.WHITE, true)
	for part: Array in [[facade, "Facade", def.facade_surface, def.facade_tint()], [ground, "Ground", def.ground_surface, Color.WHITE]]:
		var tool: SurfaceTool = part[0]
		tool.generate_normals()
		var piece := MeshInstance3D.new()
		piece.name = part[1]
		piece.mesh = tool.commit()
		var surface_mat := StadiumSurfaces.material(part[2], part[3], part[1] == "Ground")
		surface_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		piece.material_override = surface_mat
		add_child(piece)


func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, color: Color) -> void:
	st.set_color(color)
	st.add_vertex(p0)
	st.add_vertex(p1)
	st.add_vertex(p2)
	st.add_vertex(p0)
	st.add_vertex(p2)
	st.add_vertex(p3)


# --- Crowd --------------------------------------------------------------

func _build_crowd(home: TeamDef, away: TeamDef) -> void:
	var seats: Array[Vector3] = []
	var a := -180.0
	while a < 180.0:
		var p := profile(a)
		for k in int(p.z):
			var radius := p.x + k * ROW_DEPTH + ROW_DEPTH * 0.55
			var step_deg := rad_to_deg(SEAT_SPACING / radius)
			var s := a
			while s < a + ANGLE_STEP:
				if not _is_aisle(s) and absf(s) >= BATTERS_EYE + 1.0 and not _is_walkway(a, k) and rng.randf() < def.attendance:
					seats.append(point(s + rng.randf_range(-0.1, 0.1) * step_deg, radius, row_height(a, p, k)))
				s += step_deg
		a += ANGLE_STEP
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.62, 1.0)
	quad.center_offset = Vector3(0.0, 0.5, 0.0)
	mm.mesh = quad
	mm.instance_count = seats.size()
	var neutral := [Color(0.92, 0.92, 0.9), Color(0.35, 0.35, 0.38), Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.6, 0.65), Color(0.15, 0.15, 0.18)]
	for i in seats.size():
		mm.set_instance_transform(i, Transform3D(Basis(), seats[i]))
		var roll := rng.randf()
		var shirt: Color
		if roll < def.home_fan_share:
			shirt = home.primary_color if rng.randf() < 0.65 else home.secondary_color
		elif roll < def.home_fan_share + def.away_fan_share:
			shirt = away.primary_color if rng.randf() < 0.7 else away.secondary_color
		else:
			shirt = neutral[rng.randi_range(0, neutral.size() - 1)]
		mm.set_instance_color(i, shirt.lightened(rng.randf_range(-0.1, 0.1)))
		mm.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), 1.0 if rng.randf() < 0.55 else 0.0, rng.randf()))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Crowd"
	mmi.multimesh = mm
	_crowd_mat = ShaderMaterial.new()
	_crowd_mat.shader = CROWD_SHADER
	mmi.material_override = _crowd_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


# --- Field-level pieces ---------------------------------------------------

## A dark wall above the center-field bleachers so the pitch reads cleanly.
func _build_batters_eye() -> void:
	var p := profile(0.0)
	var top := stand_top(0.0)
	var eye := box(Vector3(2.0 * BATTERS_EYE * PI / 180.0 * top.x, 6.0, 1.0), Color(0.06, 0.1, 0.09))
	eye.position = point(0.0, top.x, top.y + 3.0 + ROW_RISE)
	eye.name = "BattersEye"


func _build_dugouts(home: TeamDef, away: TeamDef) -> void:
	# Home on the first-base side, visitors on third (the reference sheets):
	# the same dugout twice, the home one in its club's colors with its
	# wordmark and emblem, the visitors' marked VISITORS.
	for side: float in [-1.0, 1.0]:
		var is_home := side > 0.0
		var club := home if is_home else away
		var angle := 82.0 * side
		var radius := profile(angle).x - 4.5
		var center := point(angle, radius, 0.0)
		var dugout := Node3D.new()
		dugout.name = "Dugout_%s" % club.abbreviation
		add_child(dugout)
		dugout.look_at_from_position(center, Vector3.ZERO, Vector3.UP)
		var back := box(Vector3(14.0, 2.4, 0.4), def.structure_color.darkened(0.3), dugout, &"facade")
		back.position = Vector3(0, 1.0, 1.6)
		var bench := box(Vector3(13.0, 0.5, 1.0), club.secondary_color, dugout)
		bench.position = Vector3(0, 0.25, 1.0)
		var roof := box(Vector3(14.6, 0.35, 3.6), home.primary_color if is_home else home.dark_color, dugout)
		roof.position = Vector3(0, 2.3, 0.2)
		var plaque := box(Vector3(14.6, 0.9, 0.1), home.dark_color, dugout)
		plaque.position = Vector3(0, 2.3, -1.98)
		var glow_strip := box(Vector3(14.0, 0.08, 0.08), Color.WHITE, dugout)
		glow_strip.position = Vector3(0, 2.05, -1.6)
		glow_strip.material_override = glow(Color(1.0, 0.92, 0.75), 2.0)
		var rail := box(Vector3(14.6, 0.12, 0.12), def.accent_color, dugout)
		rail.position = Vector3(0, 1.1, -1.4)
		var sign := label(home.team_name.to_upper() if is_home else "VISITORS", 64, home.highlight_color, dugout)
		sign.position = Vector3(0, 2.3, -2.05)
		sign.rotation.y = PI
		var mark := Emblem.build(club, 1.4, 0.4)
		mark.position = Vector3(0, 1.4, 1.38)
		mark.rotation.y = PI
		dugout.add_child(mark)


func _build_backstop() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := profile(180.0).x - 1.5
	var a := 140.0
	while a < 220.0:
		var b := a + 4.0
		_quad(st, point(a, radius, 0.0), point(b, radius, 0.0), point(b, radius, 9.0), point(a, radius, 9.0), Color(0.1, 0.1, 0.12, 0.28))
		a = b
	var mi := MeshInstance3D.new()
	mi.name = "Backstop"
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	add_child(mi)


## The wall's dressing: distances in big numbers (left, center, right) and
## the home club's emblem near each pole and in the alleys.
func _build_markers(home: TeamDef) -> void:
	for angle: float in [-38.0, 0.0, 38.0]:
		var d := FieldLayout.fence_distance(angle, tuning)
		var h := FieldLayout.fence_height(angle, tuning)
		var marker := label(str(roundi(d * 3.2808)), 200, def.accent_color)
		marker.pixel_size = 0.012 * clampf(h / 3.0, 0.5, 1.0)
		var inward := wall_inward(angle)
		var spot := point(angle, d, minf(h * 0.55, 2.2)) + inward * 0.4
		marker.look_at_from_position(spot, spot - inward, Vector3.UP)
	for angle: float in [-43.0, -20.0, 20.0, 43.0]:
		var h := FieldLayout.fence_height(angle, tuning)
		if h < 1.2:
			continue
		var mark := Emblem.build(home, minf(h * 0.75, 3.2), 0.4)
		mark.name = "WallEmblem"
		add_child(mark)
		var inward := wall_inward(angle)
		var spot := point(angle, FieldLayout.fence_distance(angle, tuning), minf(h * 0.5, 2.0)) + inward * 0.35
		mark.look_at_from_position(spot, spot - inward, Vector3.UP)


## Club wordmarks along the deck fronts (and the low wall of the first
## deck), alternating the club name and city, facing the field.
func _build_fascia(home: TeamDef) -> void:
	var root := Node3D.new()
	root.name = "Fascia"
	add_child(root)
	var words := [home.team_name.to_upper(), home.city.to_upper()]
	var n := 0
	for d in def.decks:
		var k := d * rows_per_deck()
		var pixel := 0.014 if d > 0 else 0.009
		# Letter by letter, each on the band at its own angle, so the words
		# follow the curve of the stands. About 0.62 em per glyph.
		var glyph := 110.0 * pixel * 0.62
		for side: float in [-1.0, 1.0]:
			var a := 62.0
			while true:
				var text: String = words[n % 2]
				var span := rad_to_deg((text.length() * glyph) / maxf(profile(a * side).x, 10.0))
				if a + span > 172.0:
					break
				var placed := false
				for i in text.length():
					var angle := (a + span * (i + 0.5) / text.length()) * side
					var p := profile(angle)
					if k >= int(p.z):
						continue
					var height := (row_height(angle, p, k) + (0.0 if k == 0 else row_height(angle, p, k - 1))) * 0.5
					# Seen from the field, the third-base words run toward home.
					var letter := label(text[i] if side > 0.0 else text[text.length() - 1 - i], 110, home.dark_color if d > 0 else Color.WHITE, root)
					letter.pixel_size = pixel
					letter.position = point(angle, p.x + k * ROW_DEPTH - 0.15, height)
					face_home(letter)
					placed = true
				if placed:
					n += 1
				a += span + rad_to_deg(6.0 / maxf(profile(a * side).x, 10.0))


# --- Scoreboard -----------------------------------------------------------

## Line score grid (9 innings, R H E), team names and count lamps on a board
## whose local +Z faces the field. Returns the board's updatable parts.
func board_face(board: Node3D, home: TeamDef, away: TeamDef, number_color: Color, header_color: Color, with_batter: bool) -> Dictionary:
	var cells := {}
	for c in 12:
		var x := -9.0 + c * 2.1
		var header: String = "%d" % (c + 1) if c < 9 else ["R", "H", "E"][c - 9]
		var h := label(header, 72, header_color, board)
		h.position = Vector3(x, 3.6, 0.3)
		for row in 2:
			var cell := label("", 88, number_color, board)
			cell.position = Vector3(x, 1.4 - row * 2.4, 0.3)
			cells[Vector2i(c, row)] = cell
	for row in 2:
		var club := away if row == 0 else home
		var name := label(club.abbreviation, 88, MatchHud.text_color(club), board)
		name.position = Vector3(-13.0, 1.4 - row * 2.4, 0.3)
	# Count lamps: balls, strikes, outs.
	var lamps := {}
	var groups := {"B": [3, Color(0.3, 1.0, 0.4)], "S": [2, Color(1.0, 0.3, 0.25)], "O": [2, Color(1.0, 0.75, 0.2)]}
	var gx := -12.0
	for key in ["B", "S", "O"]:
		var tag := label(key, 72, Color.WHITE, board)
		tag.position = Vector3(gx, -3.6, 0.3)
		var bulbs: Array[MeshInstance3D] = []
		for i in groups[key][0]:
			var lamp := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.45
			sphere.height = 0.9
			lamp.mesh = sphere
			lamp.position = Vector3(gx + 1.4 + i * 1.15, -3.6, 0.3)
			board.add_child(lamp)
			bulbs.append(lamp)
		lamps[key] = [bulbs, groups[key][1]]
		gx += 7.5
	var batter: Label3D = null
	if with_batter:
		batter = label("", 72, Color.WHITE, board)
		batter.position = Vector3(0, -5.8, 0.3)
	return {"cells": cells, "lamps": lamps, "batter": batter}


## Updates the board from the match (cheap when nothing changed).
func update_scoreboard(state: MatchState, roster: MatchRoster) -> void:
	if _boards.is_empty():
		return
	var p := roster.player(state.current_batter()) if roster != null else null
	var key := "%s|%s|%s|%s|%d%d%d|%s" % [state.line_score, state.score, state.hits, state.errors, state.balls, state.strikes, state.outs, state.current_batter()]
	if key == _board_key:
		return
	_board_key = key
	var first := maxi(state.inning - 8, 1)  # extra innings scroll the window
	var lit := {"B": state.balls, "S": state.strikes, "O": state.outs}
	for board in _boards:
		if board.has("card"):
			_fill_card(board["card"], p, state)
		if not board.has("cells"):
			continue
		var cells: Dictionary = board["cells"]
		for row in 2:
			var line: Array = state.line_score[row]
			for c in 9:
				var inning := first + c
				var text := ""
				if inning - 1 < line.size():
					text = str(line[inning - 1])
				elif inning == state.inning and (row == 0) == state.is_top and not state.game_over:
					text = "-"
				cells[Vector2i(c, row)].text = text
			cells[Vector2i(9, row)].text = str(state.score[row])
			cells[Vector2i(10, row)].text = str(state.hits[row])
			cells[Vector2i(11, row)].text = str(state.errors[row])
		var lamps: Dictionary = board["lamps"]
		for k in lamps:
			var bulbs: Array = lamps[k][0]
			for i in bulbs.size():
				var on: bool = i < lit[k]
				(bulbs[i] as MeshInstance3D).material_override = glow(lamps[k][1], 2.2) if on else GrayboxField._mat(Color(0.12, 0.12, 0.14))
		if board["batter"] != null:
			board["batter"].text = "AT BAT  #%d %s" % [p.number, p.display_name.to_upper()] if p != null else ""


## The centerpiece's batter card: number, name, position and season line.
func _fill_card(card: Dictionary, p: PlayerDef, state: MatchState) -> void:
	if p == null:
		for key in card:
			card[key].text = ""
		return
	var position: StringName = &"dh"
	var defense: Dictionary = state.defense[state.batting_team()]
	for pos: StringName in defense:
		if defense[pos] == p.id:
			position = pos
	var line := SeasonLine.for_player(p)
	card["number"].text = "#%d" % p.number
	card["name"].text = p.display_name.to_upper()
	card["position"].text = String(position).to_upper()
	card["avg"].text = SeasonLine.avg_text(line["avg"])
	card["hr"].text = str(line["hr"])
	card["rbi"].text = str(line["rbi"])


# --- Kit for modules --------------------------------------------------------

## A material for a surface name: a StadiumSurfaces kind, or &"structure",
## &"facade", &"stand" or &"ground" for the park's own picks.
func surface_mat(surface: StringName, color: Color) -> StandardMaterial3D:
	match surface:
		&"structure":
			surface = def.structure_surface
		&"facade":
			surface = def.facade_surface
			color = def.facade_tint() if color == def.structure_color else color
		&"stand":
			surface = def.stand_surface
		&"ground":
			surface = def.ground_surface
	return StadiumSurfaces.material(surface, color)


## A node name not yet used in this park ("Warehouse", "Warehouse2", ...),
## so a park can hold more than one of a module.
func unique_name(base: String) -> String:
	var n: int = _names.get(base, 0) + 1
	_names[base] = n
	return base if n == 1 else "%s%d" % [base, n]


## A scoreboard face (from board_face) the match keeps up to date.
func add_board(board: Dictionary) -> void:
	_boards.append(board)


## The direction off the outfield wall toward the field at a spray angle
## (the wall's own facing, following its curve).
func wall_inward(angle: float) -> Vector3:
	var before := FieldLayout.direction_for_spray(angle - 1.0) * FieldLayout.fence_distance(angle - 1.0, tuning)
	var after := FieldLayout.direction_for_spray(angle + 1.0) * FieldLayout.fence_distance(angle + 1.0, tuning)
	var inward := (after - before).cross(Vector3.UP).normalized()
	if inward.dot(-FieldLayout.direction_for_spray(angle)) < 0.0:
		inward = -inward
	return inward


## A box in a flat color, or in one of the park's surfaces (a
## StadiumSurfaces kind such as &"brick", or &"structure" / &"facade" for the
## park's own choice) tinted to that color.
func box(size: Vector3, color: Color, parent: Node = null, surface: StringName = &"") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = surface_mat(surface, color)
	(parent if parent != null else self).add_child(mi)
	return mi


func label(text: String, size: int, color: Color, parent: Node = null) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = DISPLAY_FONT
	l.font_size = size
	l.pixel_size = 0.012
	l.modulate = color
	l.outline_size = 0
	l.double_sided = false
	(parent if parent != null else self).add_child(l)
	return l


func face_home(node: Node3D) -> void:
	var p := node.position
	node.look_at_from_position(p, p + (p - Vector3(0, p.y, 0)), Vector3.UP)


static func glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m
