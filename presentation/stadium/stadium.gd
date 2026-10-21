class_name Stadium
extends Node3D
## The ballpark around the field, built in code from a StadiumDef: a
## stepped seating bowl (outfield bleachers, a dark batter's eye in center,
## aisles), a crowd of billboard fans that jumps on big moments, a live
## scoreboard, dugouts, a backstop net, distance markers, light towers and,
## for the Halo Dome, the glowing halo ring hung with sponsor boards over a
## city skyline. Presentation only: the field's rules live in BaseballTuning.

const CROWD_SHADER := preload("res://presentation/stadium/crowd.gdshader")
const SKYLINE_SHADER := preload("res://presentation/stadium/skyline.gdshader")
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

var _def: StadiumDef
var _tuning: BaseballTuning
var _crowd_mat: ShaderMaterial
var _excitement := 0.0
var _rng := RandomNumberGenerator.new()
var _board_cells := {}
var _board_lamps := {}
var _board_batter: Label3D
var _board_key := ""


func build(tuning: BaseballTuning, def: StadiumDef, home: TeamDef, away: TeamDef) -> void:
	_tuning = tuning
	_def = def
	_rng.seed = hash(def.id)
	for child in get_children():
		child.queue_free()
	_build_bowl()
	_build_crowd(home, away)
	_build_batters_eye()
	_build_dugouts(home, away)
	_build_backstop()
	_build_markers()
	_build_towers()
	_build_scoreboard(home, away)
	if def.halo:
		_build_halo()
	if def.skyline:
		_build_skyline()


## The crowd reacts (0..1); it settles back over a couple of seconds.
func cheer(level: float) -> void:
	_excitement = maxf(_excitement, clampf(level, 0.0, 1.0))


func _process(delta: float) -> void:
	_excitement = move_toward(_excitement, 0.08, delta * 0.4)
	if _crowd_mat != null:
		_crowd_mat.set_shader_parameter("excitement", _excitement)


# --- Bowl ---------------------------------------------------------------

## Inner edge radius, first row height and row count at a spray angle.
func _profile(angle: float) -> Vector3:
	var a := absf(angle)
	var inner := 0.0
	if a <= 45.0:
		inner = FieldLayout.fence_distance(a, _tuning) + 5.0
	else:
		for i in range(1, FOUL_EDGE.size()):
			if a <= FOUL_EDGE[i][0]:
				var t: float = (a - FOUL_EDGE[i - 1][0]) / (FOUL_EDGE[i][0] - FOUL_EDGE[i - 1][0])
				inner = lerpf(FOUL_EDGE[i - 1][1], FOUL_EDGE[i][1], t)
				break
	var foul := smoothstep(40.0, 60.0, a)
	var first := lerpf(_tuning.fence_height + 0.6, 1.3, foul)
	var rows := roundf(lerpf(16.0, 26.0, foul))
	return Vector3(inner, first, rows)


func _is_aisle(angle: float) -> bool:
	return fmod(absf(angle) + 0.5, AISLE_EVERY) < 1.0


func _point(angle: float, radius: float, height: float) -> Vector3:
	return FieldLayout.direction_for_spray(angle) * radius + Vector3.UP * height


func _build_bowl() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var riser := _def.structure_color.darkened(0.35)
	var eye := Color(0.06, 0.1, 0.09)
	var a := -180.0
	while a < 180.0:
		var b := a + ANGLE_STEP
		var pa := _profile(a)
		var pb := _profile(b)
		var mid := (a + b) * 0.5
		var rows := int(maxf(pa.z, pb.z))
		for k in rows:
			var seat := _def.seat_color if k % 2 == 0 else _def.seat_color_alt
			if _is_aisle(mid):
				seat = _def.structure_color
			if absf(mid) < BATTERS_EYE:
				seat = eye
			var ra := pa.x + k * ROW_DEPTH
			var rb := pb.x + k * ROW_DEPTH
			var ha := pa.y + k * ROW_RISE
			var hb := pb.y + k * ROW_RISE
			var below_a := 0.0 if k == 0 else ha - ROW_RISE
			var below_b := 0.0 if k == 0 else hb - ROW_RISE
			# Riser (the step's face), then the tread (where fans sit).
			_quad(st, _point(a, ra, below_a), _point(b, rb, below_b), _point(b, rb, hb), _point(a, ra, ha), riser if absf(mid) >= BATTERS_EYE else eye)
			_quad(st, _point(a, ra, ha), _point(b, rb, hb), _point(b, rb + ROW_DEPTH, hb), _point(a, ra + ROW_DEPTH, ha), seat)
		# Back of the stand: a facade down to the ground with a trim band.
		var top_a := pa.y + (rows - 1) * ROW_RISE
		var top_b := pb.y + (rows - 1) * ROW_RISE
		var back_a := pa.x + rows * ROW_DEPTH
		var back_b := pb.x + rows * ROW_DEPTH
		_quad(st, _point(a, back_a, top_a), _point(b, back_b, top_b), _point(b, back_b, top_b + 1.2), _point(a, back_a, top_a + 1.2), _def.accent_color.darkened(0.2))
		_quad(st, _point(b, back_b, 0.0), _point(a, back_a, 0.0), _point(a, back_a, top_a + 1.2), _point(b, back_b, top_b + 1.2), _def.structure_color)
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
	# Ground outside the park.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(2400, 2400)
	ground.mesh = plane
	ground.position = Vector3(0, -0.12, 0)
	ground.material_override = GrayboxField._mat(_def.skyline_color.darkened(0.45))
	add_child(ground)


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
		var p := _profile(a)
		for k in int(p.z):
			var radius := p.x + k * ROW_DEPTH + ROW_DEPTH * 0.55
			var step_deg := rad_to_deg(SEAT_SPACING / radius)
			var s := a
			while s < a + ANGLE_STEP:
				if not _is_aisle(s) and absf(s) >= BATTERS_EYE + 1.0 and _rng.randf() < _def.attendance:
					seats.append(_point(s + _rng.randf_range(-0.1, 0.1) * step_deg, radius, p.y + k * ROW_RISE))
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
		var roll := _rng.randf()
		var shirt: Color
		if roll < _def.home_fan_share:
			shirt = home.primary_color if _rng.randf() < 0.65 else home.secondary_color
		elif roll < _def.home_fan_share + _def.away_fan_share:
			shirt = away.primary_color if _rng.randf() < 0.7 else away.secondary_color
		else:
			shirt = neutral[_rng.randi_range(0, neutral.size() - 1)]
		mm.set_instance_color(i, shirt.lightened(_rng.randf_range(-0.1, 0.1)))
		mm.set_instance_custom_data(i, Color(_rng.randf(), _rng.randf(), 1.0 if _rng.randf() < 0.55 else 0.0, _rng.randf()))
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
	var p := _profile(0.0)
	var top := p.y + p.z * ROW_RISE
	var box := _box(Vector3(2.0 * BATTERS_EYE * PI / 180.0 * (p.x + p.z * ROW_DEPTH), 6.0, 1.0), Color(0.06, 0.1, 0.09))
	box.position = _point(0.0, p.x + p.z * ROW_DEPTH, top + 3.0)
	box.name = "BattersEye"


func _build_dugouts(home: TeamDef, away: TeamDef) -> void:
	# Home team on the third-base side, visitors on first.
	for side: float in [-1.0, 1.0]:
		var club := home if side < 0.0 else away
		var angle := 82.0 * side
		var radius := _profile(angle).x - 4.5
		var center := _point(angle, radius, 0.0)
		var dugout := Node3D.new()
		dugout.name = "Dugout_%s" % club.abbreviation
		add_child(dugout)
		dugout.look_at_from_position(center, Vector3.ZERO, Vector3.UP)
		var back := _box(Vector3(14.0, 2.4, 0.4), _def.structure_color.darkened(0.5), dugout)
		back.position = Vector3(0, 1.0, 1.6)
		var bench := _box(Vector3(13.0, 0.5, 1.0), club.secondary_color, dugout)
		bench.position = Vector3(0, 0.25, 1.0)
		var roof := _box(Vector3(14.6, 0.35, 3.6), club.primary_color, dugout)
		roof.position = Vector3(0, 2.3, 0.2)
		var rail := _box(Vector3(14.6, 0.12, 0.12), _def.accent_color, dugout)
		rail.position = Vector3(0, 1.1, -1.4)
		var sign := _label(club.team_name.to_upper(), 64, Color.WHITE, dugout)
		sign.position = Vector3(0, 2.3, -1.65)
		sign.rotation.y = PI


func _build_backstop() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var radius := _profile(180.0).x - 1.5
	var a := 140.0
	while a < 220.0:
		var b := a + 4.0
		_quad(st, _point(a, radius, 0.0), _point(b, radius, 0.0), _point(b, radius, 9.0), _point(a, radius, 9.0), Color(0.1, 0.1, 0.12, 0.28))
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
		var d := FieldLayout.fence_distance(angle, _tuning)
		var label := _label(str(roundi(d * 3.2808)), 110, _def.accent_color)
		# Flat against the wall: its facing follows the wall's curve here.
		var before := FieldLayout.direction_for_spray(angle - 1.0) * FieldLayout.fence_distance(angle - 1.0, _tuning)
		var after := FieldLayout.direction_for_spray(angle + 1.0) * FieldLayout.fence_distance(angle + 1.0, _tuning)
		var inward := (after - before).cross(Vector3.UP).normalized()
		if inward.dot(-FieldLayout.direction_for_spray(angle)) < 0.0:
			inward = -inward
		var spot := _point(angle, d, _tuning.fence_height * 0.55) + inward * 0.4
		label.look_at_from_position(spot, spot - inward, Vector3.UP)


func _build_towers() -> void:
	for angle: float in [-128.0, -72.0, -32.0, 32.0, 72.0, 128.0]:
		var p := _profile(angle)
		var radius := p.x + p.z * ROW_DEPTH + 4.0
		var base := _point(angle, radius, 0.0)
		var height := 46.0
		var pole := _box(Vector3(1.4, height, 1.4), _def.structure_color.darkened(0.2))
		pole.position = base + Vector3.UP * height * 0.5
		var bank := Node3D.new()
		add_child(bank)
		bank.look_at_from_position(base + Vector3.UP * height, FIELD_CENTER, Vector3.UP)
		var frame := _box(Vector3(9.0, 5.0, 0.8), _def.structure_color.darkened(0.4), bank)
		frame.position = Vector3.ZERO
		for row in 3:
			for col in 6:
				var lamp := _box(Vector3(1.2, 1.2, 0.3), Color.WHITE, bank)
				lamp.position = Vector3(-3.75 + col * 1.5, -1.5 + row * 1.5, -0.5)
				lamp.material_override = _glow(Color(1.0, 0.97, 0.85), 2.5)


# --- Scoreboard -----------------------------------------------------------

func _build_scoreboard(home: TeamDef, away: TeamDef) -> void:
	var angle := 27.0
	var p := _profile(angle)
	var center := _point(angle, p.x + p.z * ROW_DEPTH + 3.0, p.y + p.z * ROW_RISE + 9.5)
	var board := Node3D.new()
	board.name = "Scoreboard"
	add_child(board)
	# Local +Z faces home plate, so labels read from the field.
	board.look_at_from_position(center, center + (center - Vector3(0, center.y, 0)), Vector3.UP)
	var frame := _box(Vector3(34.0, 17.0, 1.2), _def.structure_color.darkened(0.55), board)
	frame.position = Vector3(0, 0, -0.6)
	var trim := _box(Vector3(34.6, 0.5, 1.4), _def.accent_color, board)
	trim.position = Vector3(0, 8.6, -0.5)
	trim.material_override = _glow(_def.accent_color, 1.4)
	var screen := _box(Vector3(32.0, 13.0, 0.2), Color(0.03, 0.04, 0.08), board)
	screen.position = Vector3(0, -0.8, 0.05)
	var legs := _box(Vector3(30.0, 6.0, 0.8), _def.structure_color.darkened(0.3), board)
	legs.position = Vector3(0, -11.0, -0.6)
	var title := _label(_def.display_name.to_upper(), 120, _def.accent_color, board)
	title.position = Vector3(0, 6.6, 0.3)
	var columns := 9 + 3
	for c in columns:
		var x := -9.0 + c * 2.1
		var header: String = "%d" % (c + 1) if c < 9 else ["R", "H", "E"][c - 9]
		var h := _label(header, 72, Color(0.75, 0.8, 0.95), board)
		h.position = Vector3(x, 3.6, 0.3)
		for row in 2:
			var cell := _label("", 88, Color(1.0, 0.92, 0.6), board)
			cell.position = Vector3(x, 1.4 - row * 2.4, 0.3)
			_board_cells[Vector2i(c, row)] = cell
	for row in 2:
		var club := away if row == 0 else home
		var name := _label(club.abbreviation, 88, MatchHud.text_color(club), board)
		name.position = Vector3(-13.0, 1.4 - row * 2.4, 0.3)
	# Count lamps: balls, strikes, outs.
	var groups := {"B": [3, Color(0.3, 1.0, 0.4)], "S": [2, Color(1.0, 0.3, 0.25)], "O": [2, Color(1.0, 0.75, 0.2)]}
	var gx := -12.0
	for key in ["B", "S", "O"]:
		var tag := _label(key, 72, Color.WHITE, board)
		tag.position = Vector3(gx, -3.6, 0.3)
		var lamps: Array[MeshInstance3D] = []
		for i in groups[key][0]:
			var lamp := MeshInstance3D.new()
			var sphere := SphereMesh.new()
			sphere.radius = 0.45
			sphere.height = 0.9
			lamp.mesh = sphere
			lamp.position = Vector3(gx + 1.4 + i * 1.15, -3.6, 0.3)
			board.add_child(lamp)
			lamps.append(lamp)
		_board_lamps[key] = [lamps, groups[key][1]]
		gx += 7.5
	_board_batter = _label("", 72, Color.WHITE, board)
	_board_batter.position = Vector3(0, -5.8, 0.3)


## Updates the board from the match (cheap when nothing changed).
func update_scoreboard(state: MatchState, roster: MatchRoster) -> void:
	if _board_batter == null:
		return
	var p := roster.player(state.current_batter()) if roster != null else null
	var key := "%s|%s|%s|%s|%d%d%d|%s" % [state.line_score, state.score, state.hits, state.errors, state.balls, state.strikes, state.outs, state.current_batter()]
	if key == _board_key:
		return
	_board_key = key
	var first := maxi(state.inning - 8, 1)  # extra innings scroll the window
	for row in 2:
		var line: Array = state.line_score[row]
		for c in 9:
			var inning := first + c
			var text := ""
			if inning - 1 < line.size():
				text = str(line[inning - 1])
			elif inning == state.inning and (row == 0) == state.is_top and not state.game_over:
				text = "-"
			_board_cells[Vector2i(c, row)].text = text
		_board_cells[Vector2i(9, row)].text = str(state.score[row])
		_board_cells[Vector2i(10, row)].text = str(state.hits[row])
		_board_cells[Vector2i(11, row)].text = str(state.errors[row])
	var lit := {"B": state.balls, "S": state.strikes, "O": state.outs}
	for k in _board_lamps:
		var lamps: Array = _board_lamps[k][0]
		for i in lamps.size():
			var on: bool = i < lit[k]
			(lamps[i] as MeshInstance3D).material_override = _glow(_board_lamps[k][1], 2.2) if on else GrayboxField._mat(Color(0.12, 0.12, 0.14))
	_board_batter.text = "AT BAT  #%d %s" % [p.number, p.display_name.to_upper()] if p != null else ""


# --- Halo and skyline ------------------------------------------------------

## The Halo Dome's landmark: a glowing ring over the park on four pylons,
## its underside hung with sponsor boards.
func _build_halo() -> void:
	var height := 58.0
	var radius := 150.0
	var ring := MeshInstance3D.new()
	ring.name = "Halo"
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 3.0
	torus.outer_radius = radius + 3.0
	torus.rings = 96
	torus.ring_segments = 12
	ring.mesh = torus
	ring.position = FIELD_CENTER + Vector3.UP * height
	ring.material_override = _glow(_def.accent_color, 1.8)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ring)
	for i in 4:
		var a := TAU * (i + 0.5) / 4.0
		var foot := FIELD_CENTER + Vector3(cos(a), 0.0, sin(a)) * radius
		var pylon := _box(Vector3(4.0, height, 4.0), _def.structure_color)
		pylon.position = foot + Vector3.UP * height * 0.5
		var stripe := _box(Vector3(4.2, height, 0.6), _def.accent_color)
		stripe.position = foot + Vector3.UP * height * 0.5
		stripe.material_override = _glow(_def.seat_color.lightened(0.3), 1.2)
		stripe.look_at_from_position(stripe.position, Vector3(FIELD_CENTER.x, stripe.position.y, FIELD_CENTER.z), Vector3.UP)
	var count := _def.sponsors.size()
	for i in count:
		var a := TAU * i / count
		var spot := FIELD_CENTER + Vector3(cos(a), 0.0, sin(a)) * (radius - 1.0) + Vector3.UP * (height - 6.5)
		var board := Node3D.new()
		add_child(board)
		# Local +Z toward the middle of the park, so the text reads from inside.
		board.look_at_from_position(spot, spot + (spot - Vector3(FIELD_CENTER.x, spot.y, FIELD_CENTER.z)), Vector3.UP)
		var panel := _box(Vector3(34.0, 7.0, 0.8), _def.seat_color.darkened(0.3), board)
		panel.position = Vector3(0, 0, -0.4)
		var edge := _box(Vector3(34.4, 0.4, 1.0), _def.accent_color, board)
		edge.position = Vector3(0, -3.6, -0.3)
		edge.material_override = _glow(_def.accent_color, 1.5)
		var text := _label(_def.sponsors[i], 230, Color.WHITE, board)
		text.position = Vector3(0, 0, 0.1)
		text.modulate = Color(1.0, 0.97, 0.9)


func _build_skyline() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SKYLINE_SHADER
	mat.set_shader_parameter("wall_color", _def.skyline_color)
	mat.set_shader_parameter("window_color", _def.window_color)
	mat.set_shader_parameter("lit_share", 0.22)
	mat.set_shader_parameter("glow", 0.35)
	var count := 40
	for i in count:
		var a := TAU * (i + _rng.randf_range(-0.3, 0.3)) / count
		var radius := _rng.randf_range(520.0, 700.0)
		# Taller toward the far side so the city peeks over the outfield.
		var behind_center := maxf(-sin(a), 0.0)
		var size := Vector3(_rng.randf_range(26.0, 55.0), _rng.randf_range(30.0, 70.0) + 90.0 * behind_center * _rng.randf(), _rng.randf_range(26.0, 55.0))
		var tower := _box(size, _def.skyline_color)
		tower.material_override = mat
		tower.position = FIELD_CENTER + Vector3(cos(a) * radius, size.y * 0.5, sin(a) * radius)
		tower.rotation.y = _rng.randf_range(0.0, PI)
		tower.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


# --- Helpers ----------------------------------------------------------------

func _box(size: Vector3, color: Color, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = GrayboxField._mat(color)
	(parent if parent != null else self).add_child(mi)
	return mi


func _label(text: String, size: int, color: Color, parent: Node = null) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font = DISPLAY_FONT
	label.font_size = size
	label.pixel_size = 0.012
	label.modulate = color
	label.outline_size = 0
	label.double_sided = false
	(parent if parent != null else self).add_child(label)
	return label


func _face_home(node: Node3D) -> void:
	var p := node.position
	node.look_at_from_position(p, p + (p - Vector3(0, p.y, 0)), Vector3.UP)


static func _glow(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m
