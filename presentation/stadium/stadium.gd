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
const ANGLE_STEP := 1.0
## Inner edge of the stands (meters from home) by |spray angle| past the
## foul poles; inside the poles the bleachers start just behind the wall.
const FOUL_EDGE := [[45.0, 97.0], [55.0, 72.0], [65.0, 52.0], [80.0, 40.0], [100.0, 34.0], [130.0, 27.0], [180.0, 24.0]]
const BATTERS_EYE := 6.0
const AISLE_EVERY := 8.0
const SEAT_SPACING := 0.62
const FIELD_CENTER := Vector3(0.0, 0.0, -45.0)
const WATER := Color(0.12, 0.4, 0.58)
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
	_build_markers()
	for piece in def.pieces:
		if piece != null:
			StadiumModules.build(self, piece, home, away)


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
			var ha := pa.y + k * ROW_RISE
			var hb := pb.y + k * ROW_RISE
			var below_a := 0.0 if k == 0 else ha - ROW_RISE
			var below_b := 0.0 if k == 0 else hb - ROW_RISE
			# Riser (the step's face), then the tread (where fans sit).
			_quad(st, point(a, ra, below_a), point(b, rb, below_b), point(b, rb, hb), point(a, ra, ha), riser if absf(mid) >= BATTERS_EYE else eye)
			_quad(st, point(a, ra, ha), point(b, rb, hb), point(b, rb + ROW_DEPTH, hb), point(a, ra + ROW_DEPTH, ha), seat)
		# Back of the stand: a facade down to the ground with a trim band.
		var top_a := pa.y + (rows - 1) * ROW_RISE
		var top_b := pb.y + (rows - 1) * ROW_RISE
		var back_a := pa.x + rows * ROW_DEPTH
		var back_b := pb.x + rows * ROW_DEPTH
		_quad(st, point(a, back_a, top_a), point(b, back_b, top_b), point(b, back_b, top_b + 1.2), point(a, back_a, top_a + 1.2), def.accent_color.darkened(0.2))
		_quad(st, point(b, back_b, 0.0), point(a, back_a, 0.0), point(a, back_a, top_a + 1.2), point(b, back_b, top_b + 1.2), def.structure_color)
		# Outside the park: the bay on the water side, ground everywhere else.
		var outside := def.skyline_color.darkened(0.45)
		var edge := back_a + 1.0
		if is_water(mid):
			_quad(st, point(a, edge, 0.02), point(a, WATER_EDGE, 0.02), point(b, WATER_EDGE, 0.02), point(b, back_b + 1.0, 0.02), WATER)
			edge = WATER_EDGE
		_quad(st, point(a, edge, 0.0), point(a, 950.0, 0.0), point(b, 950.0, 0.0), point(b, edge if edge == WATER_EDGE else back_b + 1.0, 0.0), outside)
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
				if not _is_aisle(s) and absf(s) >= BATTERS_EYE + 1.0 and rng.randf() < def.attendance:
					seats.append(point(s + rng.randf_range(-0.1, 0.1) * step_deg, radius, p.y + k * ROW_RISE))
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
	var top := p.y + p.z * ROW_RISE
	var eye := box(Vector3(2.0 * BATTERS_EYE * PI / 180.0 * (p.x + p.z * ROW_DEPTH), 6.0, 1.0), Color(0.06, 0.1, 0.09))
	eye.position = point(0.0, p.x + p.z * ROW_DEPTH, top + 3.0)
	eye.name = "BattersEye"


func _build_dugouts(home: TeamDef, away: TeamDef) -> void:
	# Home team on the first-base side, visitors on third (the reference sheets).
	for side: float in [-1.0, 1.0]:
		var club := away if side < 0.0 else home
		var angle := 82.0 * side
		var radius := profile(angle).x - 4.5
		var center := point(angle, radius, 0.0)
		var dugout := Node3D.new()
		dugout.name = "Dugout_%s" % club.abbreviation
		add_child(dugout)
		dugout.look_at_from_position(center, Vector3.ZERO, Vector3.UP)
		var back := box(Vector3(14.0, 2.4, 0.4), def.structure_color.darkened(0.5), dugout)
		back.position = Vector3(0, 1.0, 1.6)
		var bench := box(Vector3(13.0, 0.5, 1.0), club.secondary_color, dugout)
		bench.position = Vector3(0, 0.25, 1.0)
		var roof := box(Vector3(14.6, 0.35, 3.6), club.primary_color, dugout)
		roof.position = Vector3(0, 2.3, 0.2)
		var rail := box(Vector3(14.6, 0.12, 0.12), def.accent_color, dugout)
		rail.position = Vector3(0, 1.1, -1.4)
		var sign := label(club.team_name.to_upper(), 64, Color.WHITE, dugout)
		sign.position = Vector3(0, 2.3, -1.65)
		sign.rotation.y = PI


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


## Distances painted on the wall, in feet as on any ballpark wall.
func _build_markers() -> void:
	for angle: float in [-45.0, -22.0, 0.0, 22.0, 45.0]:
		var d := FieldLayout.fence_distance(angle, tuning)
		var marker := label(str(roundi(d * 3.2808)), 110, def.accent_color)
		# Flat against the wall: its facing follows the wall's curve here.
		var inward := wall_inward(angle)
		var spot := point(angle, d, minf(FieldLayout.fence_height(angle, tuning) * 0.55, 2.2)) + inward * 0.7
		marker.look_at_from_position(spot, spot - inward, Vector3.UP)


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


# --- Kit for modules --------------------------------------------------------

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


func box(size: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = GrayboxField._mat(color)
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
