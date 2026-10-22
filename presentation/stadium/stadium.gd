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
## Fans baked from the player mannequin (tools/bake_crowd.gd).
const CROWD_ATLAS := preload("res://assets/generated/crowd/crowd_atlas.png")
const SKYLINE_SHADER := preload("res://presentation/stadium/skyline.gdshader")
const FOUNTAIN_SHADER := preload("res://presentation/stadium/fountain.gdshader")
const DISPLAY_FONT := preload("res://assets/third_party/fonts/bungee/Bungee-Regular.ttf")

const ROW_DEPTH := 0.9
const ROW_RISE := 0.45
## Each deck above the first starts this much higher than the row below it
## would: its front is the fascia band that carries the club's wordmarks.
const DECK_JUMP := 2.6
## How far an upper deck reaches out over the one below (in the foul
## stands; it fades out past the foul poles with the decks' split), and its
## fascia's depth below the tread and parapet above it.
const OVERHANG := 2.2
const FASCIA_DROP := 0.9
const PARAPET := 0.9
const ANGLE_STEP := 1.0
## Inner edge of the stands (meters from home) by |spray angle| past the
## foul poles; inside the poles the bleachers start just behind the wall.
const FOUL_EDGE := [[45.0, 97.0], [55.0, 72.0], [65.0, 52.0], [80.0, 40.0], [100.0, 34.0], [130.0, 27.0], [180.0, 24.0]]
const BATTERS_EYE := 6.0
const AISLE_EVERY := 8.0
const SEAT_SPACING := 0.62
## A chair on each tread, m from the tread's front edge: the pan's front,
## its height, the back's face and its top.
const SEAT_FRONT := 0.42
const SEAT_PAN := 0.42
const SEAT_BACK := 0.72
const SEAT_TOP := 0.85
## The dugouts: centered this far round from center field on each side
## (first-base side home, third-base side visitors), DUGOUT_WIDTH m wide,
## sunk into the front of the stands, whose first rows lift to
## DUGOUT_ROOF m over them.
const DUGOUT_ANGLE := 95.0
const DUGOUT_WIDTH := 18.0
const DUGOUT_ROOF := 2.9
## The padded wall round the foul territory, foul pole to foul pole behind
## home (the stands start on top of it), taller behind the plate, with a
## dirt track in front as along the outfield wall.
const FIELD_WALL := 2.0
const BACKSTOP_WALL := 3.0
const TRACK_WIDTH := 4.4
## The grandstand behind home plate (between the dugouts, full by
## GRAND_FULL degrees off center): GRAND_ROWS more rows (a deck more), each
## deck lifted SUITE_LIFT m more for a glazed suite level under it, and a
## roof over the top.
const GRAND_FROM := 112.0
const GRAND_FULL := 135.0
const GRAND_ROWS := 12
const SUITE_LIFT := 2.6
const GRAND_ROOF_DEPTH := 16.0
const FIELD_CENTER := Vector3(0.0, 0.0, -45.0)
const WATER := Color(0.06, 0.22, 0.36)
## How far out the bay reaches (meters from home).
const WATER_EDGE := 420.0
## How far the land runs: past the haze, so it meets the sky with no edge.
const GROUND_RIM := 2600.0
## The paved concourse round the back of the stands.
const PLAZA_WIDTH := 22.0
const GROUND_SHADER := preload("res://presentation/stadium/ground.gdshader")
## City blocks (m, street to street) and street width: the ground's grid and
## the skyline's lots share them.
const CITY_BLOCK := 72.0
const CITY_STREET := 12.0

## The park being built and its rules (for wall distances and heights).
var def: StadiumDef
var tuning: BaseballTuning
## Seeded from the park, so a park looks the same every visit.
var rng := RandomNumberGenerator.new()
var _crowd_mat: ShaderMaterial
var _home: TeamDef
var _away: TeamDef
## The visiting club the park is dressed against (the video board).
var away_team: TeamDef
var _excitement := 0.0
var _water: Array[StadiumPiece] = []
var _names := {}
## Every scoreboard in the park: {cells, lamps, batter, first_column}.
var _boards: Array[Dictionary] = []
var _board_key := ""


func build(p_tuning: BaseballTuning, p_def: StadiumDef, home: TeamDef, away: TeamDef) -> void:
	away_team = away
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
	_build_grandstand()
	_build_markers(home)
	_build_fascia(home)
	# The city goes up last, on the lots the park's own pieces left free.
	for piece in def.pieces:
		if piece != null and piece.kind != &"skyline":
			StadiumModules.build(self, piece, home, away)
	for piece in def.pieces_of(&"skyline"):
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
	var inner := FieldLayout.fence_distance(angle, tuning) + 5.0 if a <= 45.0 else profile_inner(angle)
	var foul := smoothstep(40.0, 60.0, a)
	var first := lerpf(FieldLayout.fence_height(clampf(angle, -45.0, 45.0), tuning) + 0.6, field_wall_height(angle) + 0.3, foul)
	var outfield := float(def.outfield_rows)
	if def.outfield_open > 0.0:
		outfield *= smoothstep(def.outfield_open, def.outfield_open + 10.0, a)
	var rows := roundf(lerpf(outfield, float(def.foul_rows), foul) + GRAND_ROWS * grandstand(angle))
	# Over the dugouts the stands start higher, easing in at the ends.
	var dug := 1.0 - smoothstep(dugout_half_angle(), dugout_half_angle() + 4.0, absf(a - DUGOUT_ANGLE))
	first = maxf(first, lerpf(first, DUGOUT_ROOF, dug))
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


## How far the decks overhang at a spray angle (0 where they don't split).
func overhang(angle: float) -> float:
	return OVERHANG * smoothstep(45.0, 60.0, absf(wrapf(angle, -180.0, 180.0)))


## The front of deck row k (a deck front, k > 0) at a spray angle: the
## radius of its fascia's face and the height of its tread. Bunting,
## wordmarks and icicles hang here.
func deck_front(angle: float, p: Vector3, k: int) -> Vector2:
	return Vector2(p.x + k * ROW_DEPTH - overhang(angle), row_height(angle, p, k))


func is_deck_front(k: int) -> bool:
	return def.decks > 1 and k % rows_per_deck() == 0


## Height of row k's tread at a spray angle (p = profile(angle)). The decks
## step up in the foul stands; the outfield bleachers are one deck, and
## the jump fades in past the foul poles so the bowl stays closed.
func row_height(angle: float, p: Vector3, k: int) -> float:
	var deck := floori(float(k) / rows_per_deck()) if def.decks > 1 else 0
	return p.y + k * ROW_RISE + deck * (DECK_JUMP + SUITE_LIFT * grandstand(angle)) * smoothstep(45.0, 60.0, absf(angle))


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
				best = maxf(best, float(piece.param("height")) * piece.size * facade_factor(piece, sp[0], sp[1], a) + 0.7)
	return best


## Facade massing: an arcade run is grouped into blocks of "block" bays,
## each standing a step taller or lower (up to "massing" of its height), so
## it reads as a row of buildings rather than one wall. The factor for the
## bay of the run (from start across span) that holds this angle; a mirror
## twin gets the mirror pattern.
const MASSING_STEPS := [0.0, 1.0, -0.55, 0.6, -0.25, 0.85, 0.3]


func facade_factor(piece: StadiumPiece, start: float, span: float, angle: float) -> float:
	var m := float(piece.param("massing"))
	if m <= 0.0 or span == 0.0:
		return 1.0
	var bay := float(piece.param("bay"))
	var radius_mid := stand_top(start + span * 0.5).x
	var steps := maxi(1, int(absf(deg_to_rad(span)) * radius_mid / bay))
	var i := clampi(int((angle - start) / span * steps), 0, steps - 1)
	var block := maxi(1, int(piece.param("block")))
	var k := absi(hash(str(absf(start)) + ":" + str(i / block))) % MASSING_STEPS.size()
	return 1.0 + m * float(MASSING_STEPS[k])


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


## The height of whatever a falling ball would land on at a point: the
## tread of the row of seats there, the top of the back wall, or the
## ground (0) beyond the stands and inside the field.
func surface_height(at: Vector3) -> float:
	var angle := FieldLayout.spray_angle_of(at)
	var radius := Vector2(at.x, at.z).length()
	var p := profile(angle)
	var rows := int(p.z)
	if radius < p.x or rows <= 0:
		return 0.0
	var k := int((radius - p.x) / ROW_DEPTH)
	if k >= rows:
		return 0.0 if radius > p.x + rows * ROW_DEPTH + 1.0 else row_height(angle, p, rows - 1) + 1.2
	return row_height(angle, p, k)


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
	var plaza := SurfaceTool.new()
	plaza.begin(Mesh.PRIMITIVE_TRIANGLES)
	var riser := def.structure_color.darkened(0.35)
	var eye := Color(0.06, 0.1, 0.09)
	# Concrete treads (vertex colors are used as they are: this is mid-gray).
	var tread := def.structure_color.lerp(Color(0.3, 0.3, 0.29), 0.6).darkened(0.25)
	var concourse := def.structure_color.darkened(0.7)
	var fascia := def.accent_color.lerp(def.structure_color, 0.25)
	var prev_back := -1.0
	var prev_top := 0.0
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
				# Under an overhanging deck: the concourse's back wall, in shade.
				face = concourse if overhang(mid) > 0.05 else def.accent_color.lerp(def.structure_color, 0.25)
			# The front wall opens onto the dugouts.
			if k > 0 or absf(absf(mid) - DUGOUT_ANGLE) > dugout_half_angle():
				_quad(st, point(a, ra, below_a), point(b, rb, below_b), point(b, rb, hb), point(a, ra, ha), face)
			# An upper deck reaches out over the one below: its slab (the
			# soffit under it in shade), the fascia across its front and a
			# parapet on top.
			var oa := overhang(a)
			var ob := overhang(b)
			if k > 0 and is_deck_front(k) and maxf(oa, ob) > 0.05:
				var fa := ra - oa
				var fb := rb - ob
				_quad(st, point(a, fa, ha), point(b, fb, hb), point(b, rb, hb), point(a, ra, ha), tread)
				_quad(st, point(b, fb, hb - FASCIA_DROP), point(a, fa, ha - FASCIA_DROP), point(a, ra, ha - FASCIA_DROP), point(b, rb, hb - FASCIA_DROP), concourse)
				_quad(st, point(a, fa, ha - FASCIA_DROP), point(b, fb, hb - FASCIA_DROP), point(b, fb, hb + PARAPET), point(a, fa, ha + PARAPET), fascia)
				_quad(st, point(a, fa, ha + PARAPET), point(b, fb, hb + PARAPET), point(b, fb + 0.3, hb + PARAPET), point(a, fa + 0.3, ha + PARAPET), fascia.darkened(0.3))
				_quad(st, point(a, fa + 0.3, ha + PARAPET), point(b, fb + 0.3, hb + PARAPET), point(b, fb + 0.3, hb), point(a, fa + 0.3, ha), fascia.darkened(0.45))
			# The tread is concrete; the seats are a row of chairs on it (a
			# pan and a back), one per step of the sweep, a shade apart so
			# they read as single seats. Fans sit just in front of them.
			var seated := not _is_aisle(mid) and absf(mid) >= BATTERS_EYE and not _is_walkway(a, k)
			_quad(st, point(a, ra, ha), point(b, rb, hb), point(b, rb + ROW_DEPTH, hb), point(a, ra + ROW_DEPTH, ha), tread if seated or absf(mid) >= BATTERS_EYE else seat)
			if seated:
				# Vertex colors are used as they are (linear): convert, so the
				# chairs keep the park's own (dark) seat colors and never read
				# as grass from above.
				var chair := (seat.darkened(0.12) if int(a) % 2 == 0 else seat).srgb_to_linear()
				for part: Vector4 in [Vector4(SEAT_FRONT, 0.0, SEAT_FRONT, SEAT_PAN), Vector4(SEAT_FRONT, SEAT_PAN, SEAT_BACK, SEAT_PAN), Vector4(SEAT_BACK, SEAT_PAN, SEAT_BACK, SEAT_TOP), Vector4(SEAT_BACK, SEAT_TOP, SEAT_BACK + 0.08, SEAT_TOP)]:
					# Each part runs from (radius x, height y) to (z, w) off the tread's front edge.
					_quad(st, point(a, ra + part.x, ha + part.y), point(b, rb + part.x, hb + part.y), point(b, rb + part.z, hb + part.w), point(a, ra + part.z, ha + part.w), chair if part.y < SEAT_TOP else chair.darkened(0.2))
		# Back of the stand: a facade down to the ground with a trim band.
		var top_a := row_height(a, pa, rows - 1)
		var top_b := row_height(b, pb, rows - 1)
		var back_a := pa.x + rows * ROW_DEPTH
		var back_b := pb.x + rows * ROW_DEPTH
		_quad(st, point(a, back_a, top_a), point(b, back_b, top_b), point(b, back_b, top_b + 1.2), point(a, back_a, top_a + 1.2), def.accent_color.darkened(0.2))
		_quad(facade, point(b, back_b, 0.0), point(a, back_a, 0.0), point(a, back_a, top_a + 1.2), point(b, back_b, top_b + 1.2), Color.WHITE)
		# Where the stands step deeper or shallower from one degree to the
		# next, a wall closes the step (no slit through to the ground).
		if prev_back > 0.0 and absf(prev_back - back_a) > 0.01:
			var hi := maxf(prev_top, top_a) + 1.2
			_quad(facade, point(a, minf(prev_back, back_a), 0.0), point(a, maxf(prev_back, back_a), 0.0), point(a, maxf(prev_back, back_a), hi), point(a, minf(prev_back, back_a), hi), Color.WHITE)
			_quad(st, point(a, minf(prev_back, back_a), hi), point(a, maxf(prev_back, back_a), hi), point(a, maxf(prev_back, back_a), hi - 1.2), point(a, minf(prev_back, back_a), hi - 1.2), def.accent_color.darkened(0.2))
		prev_back = back_b
		prev_top = top_b
		# Outside the park: the bay on the water side, ground everywhere else.
		var outside := def.skyline_color.darkened(0.45) if def.ground_color.a == 0.0 else def.ground_color
		if is_city():
			# Paved city lots, a little of the skyline's tone in the gray
			# (vertex colors are used as they are, linear: this is mid-gray).
			outside = Color(0.15, 0.145, 0.14).lerp(def.skyline_color.darkened(0.6), 0.2)
		# Behind the outfield wall, up to the bleachers' front (or the
		# plaza where none stand): a paved gangway, never bare field grass.
		if absf(mid) <= 46.0:
			var wa := FieldLayout.fence_distance(clampf(a, -45.0, 45.0), tuning) + 0.25
			var wb := FieldLayout.fence_distance(clampf(b, -45.0, 45.0), tuning) + 0.25
			var to_a := pa.x if pa.z > 0 else back_a
			var to_b := pb.x if pb.z > 0 else back_b
			_quad(st, point(a, wa, 0.13), point(a, to_a + 0.05, 0.13), point(b, to_b + 0.05, 0.13), point(b, wb, 0.13), tread)
		# The plaza (or water) runs right up to the back wall.
		var edge_a := back_a - 0.05
		var edge_b := back_b - 0.05
		if is_water(mid):
			_quad(st, point(a, edge_a, 0.14), point(a, WATER_EDGE, 0.14), point(b, WATER_EDGE, 0.14), point(b, edge_b, 0.14), WATER)
			edge_a = WATER_EDGE
			edge_b = WATER_EDGE
		else:
			# The concourse: paving round the back of the stands, a step up
			# from the land so the two never flicker.
			# From under the stands (hidden by them) so a step in their depth
			# never opens a slit; the land starts under the plaza for the same
			# reason.
			_quad(plaza, point(a, pa.x, 0.12), point(a, edge_a + PLAZA_WIDTH, 0.12), point(b, edge_b + PLAZA_WIDTH, 0.12), point(b, pb.x, 0.12), Color.WHITE)
			edge_a += PLAZA_WIDTH * 0.5
			edge_b += PLAZA_WIDTH * 0.5
		# Above the field's 320 m grass slab (top at -0.01), so the two never flicker.
		_quad(ground, point(a, edge_a, 0.1), point(a, GROUND_RIM, 0.1), point(b, GROUND_RIM, 0.1), point(b, edge_b, 0.1), outside)
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
		# Its own copy, drawn from both sides: the bowl's faces wind either
		# way round the circle, and a culled tread shows the grass under it.
		var stand_mat: StandardMaterial3D = StadiumSurfaces.material(def.stand_surface, Color.WHITE, true).duplicate()
		stand_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = stand_mat
	var paving: StringName = &"stone" if def.structure_surface == &"stone" else &"concrete"
	for part: Array in [[facade, "Facade", def.facade_surface, def.facade_tint()], [plaza, "Plaza", paving, def.structure_color.lerp(Color(0.78, 0.76, 0.72), 0.6)]]:
		var tool: SurfaceTool = part[0]
		tool.generate_normals()
		var piece := MeshInstance3D.new()
		piece.name = part[1]
		piece.mesh = tool.commit()
		var surface_mat := StadiumSurfaces.material(part[2], part[3])
		surface_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		piece.material_override = surface_mat
		add_child(piece)
	ground.generate_normals()
	var land := MeshInstance3D.new()
	land.name = "Ground"
	land.mesh = ground.commit()
	land.material_override = ground_material()
	add_child(land)


## The land round the park (or, with `water`, open water in it): its
## surface texture, a street grid in a city, and haze into the horizon.
func ground_material(water: bool = false, water_color: Color = WATER, glow: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GROUND_SHADER
	if StadiumSurfaces.KINDS.has(def.ground_surface):
		var spec: Array = StadiumSurfaces.KINDS[def.ground_surface]
		m.set_shader_parameter("detail", spec[0])
		m.set_shader_parameter("detail_normal", spec[1])
		m.set_shader_parameter("tile", float(spec[2]) * 1.5)
		m.set_shader_parameter("has_detail", 1.0)
	elif is_city():
		var concrete: Array = StadiumSurfaces.KINDS[&"concrete"]
		m.set_shader_parameter("detail", concrete[0])
		m.set_shader_parameter("detail_normal", concrete[1])
		m.set_shader_parameter("tile", 6.0)
		m.set_shader_parameter("has_detail", 1.0)
	m.set_shader_parameter("water", 1.0 if water else 0.0)
	m.set_shader_parameter("water_color", water_color)
	m.set_shader_parameter("water_glow", glow)
	if is_city() and not water:
		m.set_shader_parameter("streets", 1.0)
		m.set_shader_parameter("block", CITY_BLOCK)
		m.set_shader_parameter("street_width", CITY_STREET)
		m.set_shader_parameter("grid_origin", Vector2(FIELD_CENTER.x, FIELD_CENTER.z))
		m.set_shader_parameter("streets_from", city_from())
		m.set_shader_parameter("asphalt", def.skyline_color.darkened(0.7).lerp(Color(0.15, 0.15, 0.16), 0.6))
		m.set_shader_parameter("sidewalk", def.structure_color.lerp(Color(0.6, 0.59, 0.56), 0.7))
		m.set_shader_parameter("lawn", Color(0.2, 0.31, 0.13).darkened(0.35 if def.night else 0.0))
	m.set_shader_parameter("haze_color", horizon_color())
	m.set_shader_parameter("center", Vector2(FIELD_CENTER.x, FIELD_CENTER.z))
	return m


## A city park: its skyline stands on a street grid (land without a surface
## of its own reads as paved city).
func is_city() -> bool:
	return not def.pieces_of(&"skyline").is_empty() and def.ground_color.a == 0.0


## Where the city's streets begin, m from the middle of the field: past the
## park's own landmark ring.
func city_from() -> float:
	return 300.0


## The sky's color at the horizon, which the land fades into.
func horizon_color() -> Color:
	if def.is_roofed():
		return Color(0.05, 0.05, 0.07)
	var look: Array = GrayboxField.SKIES.get(def.sky_kind(), GrayboxField.SKIES[&"day"])
	return look[1]


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
			# On the chair's pan (the shader steps standing fans forward).
			var radius := p.x + k * ROW_DEPTH + (SEAT_FRONT + SEAT_BACK) * 0.5
			var step_deg := rad_to_deg(SEAT_SPACING / radius)
			var s := a
			while s < a + ANGLE_STEP:
				if not _is_aisle(s) and absf(s) >= BATTERS_EYE + 1.0 and not _is_walkway(a, k) and rng.randf() < def.attendance:
					seats.append(point(s + rng.randf_range(-0.1, 0.1) * step_deg, radius, row_height(a, p, k)))
				s += step_deg
		a += ANGLE_STEP
	_home = home
	_away = away
	add_fans(seats, "Crowd")


## Fans standing at these spots (one billboard each), dressed in the home,
## away and neutral colors at the park's fan shares, all cheering together
## with the main crowd. Used by the bowl and by modules that put fans on
## balconies and terraces.
## With `club`, they are its players instead (its jerseys, sitting tight).
func add_fans(seats: Array[Vector3], node_name: String = "Fans", club: TeamDef = null) -> void:
	if seats.is_empty() or _home == null:
		return
	var home := _home
	var away := _away
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	# The atlas cell: 2.4 m tall, 1.2 wide, a standing fan's feet 0.22 m
	# above its bottom (baked from a little above).
	quad.size = Vector2(1.2, 2.4)
	quad.center_offset = Vector3(0.0, 0.98, 0.0)
	mm.mesh = quad
	mm.instance_count = seats.size()
	var neutral := [Color(0.92, 0.92, 0.9), Color(0.35, 0.35, 0.38), Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.6, 0.65), Color(0.15, 0.15, 0.18)]
	for i in seats.size():
		# Turned to face home plate: the shader steps standing fans that way.
		var toward := Vector3(-seats[i].x, 0.0, -seats[i].z)
		var basis := Basis.looking_at(toward.normalized()) if toward.length() > 0.1 else Basis()
		mm.set_instance_transform(i, Transform3D(basis, seats[i]))
		var roll := rng.randf()
		var shirt: Color
		if roll < def.home_fan_share:
			shirt = home.primary_color if rng.randf() < 0.65 else home.secondary_color
		elif roll < def.home_fan_share + def.away_fan_share:
			shirt = away.primary_color if rng.randf() < 0.7 else away.secondary_color
		else:
			shirt = neutral[rng.randi_range(0, neutral.size() - 1)]
		var temper := rng.randf()
		if club != null:
			shirt = club.primary_color
			temper = rng.randf_range(0.3, 0.6)
		mm.set_instance_color(i, shirt.lightened(rng.randf_range(-0.1, 0.1)) if club == null else shirt)
		mm.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), temper, rng.randf()))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = unique_name(node_name)
	mmi.multimesh = mm
	if _crowd_mat == null:
		_crowd_mat = ShaderMaterial.new()
		_crowd_mat.shader = CROWD_SHADER
		_crowd_mat.set_shader_parameter("atlas", CROWD_ATLAS)
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


## How much of the home-plate grandstand stands at a spray angle (0..1).
func grandstand(angle: float) -> float:
	return smoothstep(GRAND_FROM, GRAND_FULL, absf(wrapf(angle, -180.0, 180.0)))


## The grandstand behind home, in the park's architecture
## (StadiumDef.grandstand): the suites' fronts on the back wall under each
## overhanging deck (glass, arches, timber screens or portholes, lit from
## inside), a roof over the top rows on columns (flat, gable, barrel, sail,
## pagoda, sawtooth or battlement, in the park's roof material and color)
## and the architecture set's towers at its two ends.
func _build_grandstand() -> void:
	var style: Dictionary = def.grandstand
	var roof_kind: StringName = style.get("roof", &"flat")
	var suites: StringName = style.get("suites", &"glass")
	var glass := SurfaceTool.new()
	glass.begin(Mesh.PRIMITIVE_TRIANGLES)
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	var roof := SurfaceTool.new()
	roof.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mullion := def.structure_color.darkened(0.5).srgb_to_linear()
	var wall := def.facade_tint().srgb_to_linear()
	var trim := def.accent_color.srgb_to_linear()
	var timber := Color(0.36, 0.22, 0.12).srgb_to_linear()
	var roofed := not def.is_roofed()
	var a := GRAND_FROM
	while a < 180.0 - 0.01:
		var b := a + 1.0
		for side: float in [-1.0, 1.0]:
			# Always in increasing spray angle, so both sides face the same way.
			var sa := a * side if side > 0.0 else -b
			var sb := b * side if side > 0.0 else -a
			var ga := grandstand(sa)
			var gb := grandstand(sb)
			if maxf(ga, gb) < 0.3:
				continue
			var pa := profile(sa)
			var pb := profile(sb)
			for k in int(minf(pa.z, pb.z)):
				if k == 0 or not is_deck_front(k):
					continue
				var ra := pa.x + k * ROW_DEPTH - 0.06
				var rb := pb.x + k * ROW_DEPTH - 0.06
				var lo_a := row_height(sa, pa, k - 1) + 0.25
				var lo_b := row_height(sb, pb, k - 1) + 0.25
				var hi_a := row_height(sa, pa, k) - FASCIA_DROP - 0.15
				var hi_b := row_height(sb, pb, k) - FASCIA_DROP - 0.15
				if hi_a - lo_a < 1.0:
					continue
				_suite_bay(suites, glass, frame, sa, sb, ra, rb, lo_a, lo_b, hi_a, hi_b, int(a), mullion, wall, timber)
			if roofed:
				_roof_bay(roof_kind, roof, frame, sa, sb, ga, gb, int(a), mullion, trim)
		a = b
	for part: Array in [[glass, "Suites"], [frame, "GrandstandFrame"], [roof, "GrandstandRoof"]]:
		var tool: SurfaceTool = part[0]
		tool.generate_normals()
		var mi := MeshInstance3D.new()
		mi.name = part[1]
		mi.mesh = tool.commit()
		var m: BaseMaterial3D
		if part[1] == "Suites":
			m = glow(def.window_color.lerp(Color(0.55, 0.7, 0.85), 0.6 if suites == &"glass" else 0.2), 1.4 if def.night else 0.6)
			m.albedo_color = Color(0.2, 0.3, 0.42)
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		elif part[1] == "GrandstandRoof":
			var tint: Color = style.get("roof_color", def.structure_color)
			m = StadiumSurfaces.material(style.get("surface", &""), tint).duplicate()
			m.albedo_color = tint
			m.vertex_color_use_as_albedo = false
		else:
			m = StandardMaterial3D.new()
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.7
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		add_child(mi)
	_grandstand_towers(StringName(style.get("set", &"")))


## One degree of suite front between spray angles sa and sb.
func _suite_bay(kind: StringName, glass: SurfaceTool, frame: SurfaceTool, sa: float, sb: float, ra: float, rb: float, lo_a: float, lo_b: float, hi_a: float, hi_b: float, step: int, mullion: Color, wall: Color, timber: Color) -> void:
	var sill := func() -> void: _quad(frame, point(sa, ra - 0.05, lo_a - 0.2), point(sb, rb - 0.05, lo_b - 0.2), point(sb, rb - 0.05, lo_b), point(sa, ra - 0.05, lo_a), mullion)
	match kind:
		&"arches":
			# Bays three degrees wide between piers, each glazed under a
			# round-headed arch: the spandrels fill the corners above it.
			_quad(glass, point(sa, ra, lo_a), point(sb, rb, lo_b), point(sb, rb, hi_b), point(sa, ra, hi_a), Color.WHITE)
			var u0 := float(step % 3) / 3.0
			var u1 := u0 + 1.0 / 3.0
			var spring_a := lerpf(lo_a, hi_a, 0.62)
			var spring_b := lerpf(lo_b, hi_b, 0.62)
			# The arch's curve over the bay: height at u (0..1 across it).
			var curve := func(u: float, lo: float, hi: float) -> float: return lerpf(lerpf(lo, hi, 0.62), hi - 0.1, sqrt(maxf(0.0, 1.0 - pow(u * 2.0 - 1.0, 2.0))))
			var ya: float = curve.call(u0, lo_a, hi_a)
			var yb: float = curve.call(u1, lo_b, hi_b)
			_quad(frame, point(sa, ra - 0.05, ya), point(sb, rb - 0.05, yb), point(sb, rb - 0.05, hi_b + 0.05), point(sa, ra - 0.05, hi_a + 0.05), wall)
			if step % 3 == 0:
				_quad(frame, point(sa, ra - 0.06, lo_a - 0.2), point(sa, ra - 0.06, hi_a), point(sa + 0.45, ra - 0.06, hi_a), point(sa + 0.45, ra - 0.06, lo_a - 0.2), wall)
				_quad(frame, point(sa - 0.05, ra - 0.07, spring_a - 0.15), point(sa - 0.05, ra - 0.07, spring_a + 0.1), point(sa + 0.5, ra - 0.07, spring_a + 0.1), point(sa + 0.5, ra - 0.07, spring_a - 0.15), wall.darkened(0.25))
			sill.call()
		&"screens":
			# Timber slats over warm-lit rooms, a rail top and bottom.
			_quad(glass, point(sa, ra, lo_a), point(sb, rb, lo_b), point(sb, rb, hi_b), point(sa, ra, hi_a), Color.WHITE)
			for t in [0.0, 0.5]:
				var s0 := lerpf(sa, sb, t)
				_quad(frame, point(s0, ra - 0.05, lo_a), point(s0, ra - 0.05, hi_a), point(s0 + 0.12, ra - 0.05, hi_a), point(s0 + 0.12, ra - 0.05, lo_a), timber)
			for y: float in [0.0, 0.5, 1.0]:
				var ha := lerpf(lo_a, hi_a, y)
				var hb := lerpf(lo_b, hi_b, y)
				_quad(frame, point(sa, ra - 0.08, ha - 0.08), point(sb, rb - 0.08, hb - 0.08), point(sb, rb - 0.08, hb + 0.08), point(sa, ra - 0.08, ha + 0.08), timber)
		&"portholes":
			# A plated wall with a round window every three degrees.
			_quad(frame, point(sa, ra - 0.03, lo_a - 0.2), point(sb, rb - 0.03, lo_b - 0.2), point(sb, rb - 0.03, hi_b), point(sa, ra - 0.03, hi_a), wall)
			if step % 3 == 1:
				var mid := (sa + sb) * 0.5
				var r := (ra + rb) * 0.5 - 0.08
				var cy := (lo_a + hi_a) * 0.5
				var rad := minf((hi_a - lo_a) * 0.36, 0.9)
				var deg := rad_to_deg(rad / r)
				for i in 10:
					var t0 := TAU * i / 10.0
					var t1 := TAU * (i + 1) / 10.0
					var c := point(mid, r, cy)
					var p0 := point(mid + cos(t0) * deg, r, cy + sin(t0) * rad)
					var p1 := point(mid + cos(t1) * deg, r, cy + sin(t1) * rad)
					_quad(glass, c, p0, p1, c, Color.WHITE)
					var q0 := point(mid + cos(t0) * deg * 1.25, r + 0.01, cy + sin(t0) * rad * 1.25)
					var q1 := point(mid + cos(t1) * deg * 1.25, r + 0.01, cy + sin(t1) * rad * 1.25)
					_quad(frame, p0, q0, q1, p1, mullion)
		_:
			_quad(glass, point(sa, ra, lo_a), point(sb, rb, lo_b), point(sb, rb, hi_b), point(sa, ra, hi_a), Color.WHITE)
			if step % 3 == 0:
				_quad(frame, point(sa, ra - 0.04, lo_a), point(sa, ra - 0.04, hi_a), point(sa + 0.15, ra - 0.04, hi_a), point(sa + 0.15, ra - 0.04, lo_a), mullion)
			sill.call()


## The roof's rise over the top rows at depth u (0 at the back, 1 at the
## front edge), in multiples of the roof's depth, and at spray angle s.
func _roof_rise(kind: StringName, u: float, s: float) -> float:
	match kind:
		&"gable":
			return 0.06 + 0.2 * (1.0 - absf(u * 2.0 - 1.0))
		&"barrel":
			return 0.05 + 0.26 * sin(PI * u)
		&"sail":
			# Cloth pulled up to the masts every six degrees, sagging between.
			var mast := absf(cos(deg_to_rad(s) * 30.0))
			return 0.1 * u + (0.22 * mast - 0.05) * sin(PI * clampf(u * 1.1, 0.0, 1.0))
		&"pagoda":
			return 0.12 + 0.06 * u + 0.32 * pow(u, 4.0) - 0.12 * pow(1.0 - u, 2.0) * 0.0
		&"sawtooth":
			return 0.04 + 0.14 * fmod(u * 3.0, 1.0)
	return 0.12 * u


func _roof_bay(kind: StringName, roof: SurfaceTool, frame: SurfaceTool, sa: float, sb: float, ga: float, gb: float, step: int, column: Color, trim: Color) -> void:
	var ta := stand_top(sa)
	var tb := stand_top(sb)
	var da := GRAND_ROOF_DEPTH * ga
	var db := GRAND_ROOF_DEPTH * gb
	if maxf(da, db) < 1.0:
		return
	var base_a := ta.y + 6.5
	var base_b := tb.y + 6.5
	var n := 12
	var edge_a := Vector3.ZERO
	var edge_b := Vector3.ZERO
	for i in n:
		var u0 := float(i) / n
		var u1 := float(i + 1) / n
		var p0a := point(sa, ta.x + 0.5 - (da + 0.5) * u0, base_a + _roof_rise(kind, u0, sa) * GRAND_ROOF_DEPTH)
		var p0b := point(sb, tb.x + 0.5 - (db + 0.5) * u0, base_b + _roof_rise(kind, u0, sb) * GRAND_ROOF_DEPTH)
		var p1a := point(sa, ta.x + 0.5 - (da + 0.5) * u1, base_a + _roof_rise(kind, u1, sa) * GRAND_ROOF_DEPTH)
		var p1b := point(sb, tb.x + 0.5 - (db + 0.5) * u1, base_b + _roof_rise(kind, u1, sb) * GRAND_ROOF_DEPTH)
		# Sawtooth: the steep faces are glazed north-lights.
		_quad(roof, p0a, p0b, p1b, p1a, Color.WHITE)
		edge_a = p1a
		edge_b = p1b
	# The front edge: a fascia in the park's accent; a battlement's is a
	# crenellated parapet.
	var h := 0.9
	if kind == &"battlement":
		h = 2.4 if step % 2 == 0 else 1.2
	_quad(frame, edge_a, edge_b, edge_b + Vector3.UP * h, edge_a + Vector3.UP * h, trim if kind != &"battlement" else column.lightened(0.15))
	if kind == &"pagoda" and step % 4 == 0:
		# A ridge ornament along the eaves.
		_quad(frame, edge_a + Vector3.UP * 0.9, edge_b + Vector3.UP * 0.9, edge_b + Vector3.UP * 1.5, edge_a + Vector3.UP * 1.5, trim)
	# Columns from the back of the stands every six degrees (masts for a
	# sail, standing on up through it).
	if step % 6 == 0:
		var foot := point(sa, ta.x + 0.3, ta.y)
		var across := (point(sa + 0.5, ta.x, 0.0) - point(sa - 0.5, ta.x, 0.0)).normalized() * 0.3
		var outward := point(sa, 1.0, 0.0).normalized() * 0.3
		var top := Vector3(foot.x, base_a + (9.0 if kind == &"sail" else 0.0), foot.z)
		_quad(frame, foot - across, foot + across, top + across, top - across, column)
		_quad(frame, foot - across - outward, foot - across, top - across, top - across - outward, column)


## The park's architecture-set towers standing at the grandstand's two
## ends, on the back of the stands, a little taller than its roof.
func _grandstand_towers(set_name: StringName) -> void:
	var role := StringName("set_%s_tower" % set_name)
	if set_name == &"" or not ModelKit.has(role):
		return
	for side: float in [-1.0, 1.0]:
		var angle := (GRAND_FROM + 6.0) * side
		var top := stand_top(angle)
		var tower := ModelKit.spawn(role, top.y + 16.0, RandomNumberGenerator.new())
		tower.name = "GrandstandTower"
		add_child(tower)
		var at := point(angle, top.x + 4.0, 0.0)
		tower.look_at_from_position(at, Vector3(0, 0, 0), Vector3.UP)
		tower.rotate_object_local(Vector3.UP, PI)


## The foul-territory wall's height at a spray angle: taller behind home.
func field_wall_height(angle: float) -> float:
	return lerpf(FIELD_WALL, BACKSTOP_WALL, smoothstep(130.0, 150.0, absf(wrapf(angle, -180.0, 180.0))))


## Half the dugout's opening in the stands' front wall, in degrees.
func dugout_half_angle() -> float:
	return rad_to_deg(asin(DUGOUT_WIDTH * 0.5 / profile_inner(DUGOUT_ANGLE)))


## The foul stands' inner edge at a spray angle (past the foul poles):
## from this side's own corner, closing in behind home.
func profile_inner(angle: float) -> float:
	var a := absf(wrapf(angle, -180.0, 180.0))
	var corner := FieldLayout.fence_distance(signf(angle) * 45.0, tuning) + 5.0
	for i in range(1, FOUL_EDGE.size()):
		if a <= FOUL_EDGE[i][0]:
			var t: float = (a - FOUL_EDGE[i - 1][0]) / (FOUL_EDGE[i][0] - FOUL_EDGE[i - 1][0])
			var start: float = corner if i == 1 else FOUL_EDGE[i - 1][1]
			return lerpf(start, FOUL_EDGE[i][1], t)
	return FOUL_EDGE[-1][1]


func _build_dugouts(home: TeamDef, away: TeamDef) -> void:
	# Home on the first-base side, visitors on third (the reference sheets):
	# sunk into the front of the stands under the first rows, a step down
	# from the field, the club's name on the roof's fascia, its emblem on
	# the back wall and the players on the bench. The visitors' fascia
	# reads VISITORS.
	for side: float in [-1.0, 1.0]:
		var is_home := side > 0.0
		var club := home if is_home else away
		# Flush with the stands' front edge, which slants here (out toward
		# the foul pole): along the chord across the opening.
		var h := dugout_half_angle()
		var p1 := point((DUGOUT_ANGLE - h) * side, profile_inner((DUGOUT_ANGLE - h) * side), 0.0)
		var p2 := point((DUGOUT_ANGLE + h) * side, profile_inner((DUGOUT_ANGLE + h) * side), 0.0)
		var front := (p1 + p2) * 0.5
		var along := (p2 - p1).normalized()
		var out := along.cross(Vector3.UP)
		if out.dot(front) < 0.0:
			out = -out
		var dugout := Node3D.new()
		dugout.name = "Dugout_%s" % club.abbreviation
		add_child(dugout)
		# -Z faces the field; +Z runs back under the stands.
		dugout.look_at_from_position(front, front - out, Vector3.UP)
		var w := p1.distance_to(p2)
		var inside := def.structure_color.darkened(0.55)
		var floor_y := -0.6
		var floor_slab := box(Vector3(w, 0.1, 4.2), inside.darkened(0.3), dugout, &"concrete")
		floor_slab.position = Vector3(0, floor_y - 0.05, 1.5)
		var back := box(Vector3(w, DUGOUT_ROOF - floor_y, 0.3), inside, dugout, &"facade")
		back.position = Vector3(0, (DUGOUT_ROOF + floor_y) * 0.5, 3.6)
		var ceiling := box(Vector3(w + 0.6, 0.3, 4.6), inside.darkened(0.3), dugout)
		ceiling.position = Vector3(0, DUGOUT_ROOF - 0.15, 1.4)
		for end: float in [-1.0, 1.0]:
			var wall := box(Vector3(0.4, DUGOUT_ROOF - floor_y, 5.4), def.structure_color.darkened(0.2), dugout, &"facade")
			wall.position = Vector3(end * (w * 0.5 + 0.2), (DUGOUT_ROOF + floor_y) * 0.5, 1.1)
		# The lip at field level and the padded rail the players lean on.
		var lip := box(Vector3(w, -floor_y, 0.3), inside, dugout)
		lip.position = Vector3(0, floor_y * 0.5, -0.15)
		var rail := box(Vector3(w, 0.16, 0.16), def.accent_color, dugout)
		rail.position = Vector3(0, 1.05, -0.2)
		for k in 7:
			var post := box(Vector3(0.1, 1.05, 0.1), def.accent_color.darkened(0.3), dugout)
			post.position = Vector3(-w * 0.5 + 0.5 + k * (w - 1.0) / 6.0, 0.52, -0.2)
		var fascia := box(Vector3(w + 1.0, 0.8, 0.3), home.primary_color if is_home else home.dark_color, dugout)
		fascia.position = Vector3(0, DUGOUT_ROOF - 0.3, -0.35)
		var sign := label(home.team_name.to_upper() if is_home else "VISITORS", 84, home.highlight_color, dugout)
		sign.position = Vector3(0, DUGOUT_ROOF - 0.3, -0.52)
		sign.rotation.y = PI
		var lamp := box(Vector3(w, 0.08, 0.08), Color.WHITE, dugout)
		lamp.position = Vector3(0, DUGOUT_ROOF - 0.35, 0.2)
		lamp.material_override = glow(Color(1.0, 0.92, 0.75), 2.0)
		var bench := box(Vector3(w - 1.0, 0.45, 0.6), club.secondary_color.darkened(0.2), dugout)
		bench.position = Vector3(0, floor_y + 0.22, 3.1)
		var mark := Emblem.build(club, 1.8, 0.4)
		mark.position = Vector3(0, 1.4, 3.44)
		mark.rotation.y = PI
		dugout.add_child(mark)
		# The bench: the players, in their club's jerseys.
		var spots: Array[Vector3] = []
		var x := -w * 0.5 + 1.0
		while x < w * 0.5 - 1.0:
			if rng.randf() < 0.7:
				spots.append(dugout.transform * Vector3(x, floor_y, 2.85))
			x += 0.85
		add_fans(spots, "Bench_%s" % club.abbreviation, club)


## The field's wall round the foul territory: from each foul pole round
## behind home, at the front of the stands, padded in the outfield wall's
## color with a cap rail and a dirt track in front, open at the dugouts;
## behind the plate it stands taller with the backstop net above it.
func _build_backstop() -> void:
	var pad := SurfaceTool.new()
	pad.begin(Mesh.PRIMITIVE_TRIANGLES)
	var track := SurfaceTool.new()
	track.begin(Mesh.PRIMITIVE_TRIANGLES)
	var net := SurfaceTool.new()
	net.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall_color := def.outfield_wall_color
	var cap := def.accent_color.darkened(0.35)
	for side: float in [-1.0, 1.0]:
		var a := 45.0
		while a < 180.0 - 0.01:
			var b := minf(a + 1.0, 180.0)
			# Always in increasing spray angle, so both sides wind (and are
			# lit) the same way.
			var sa := a * side if side > 0.0 else -b
			var sb := b * side if side > 0.0 else -a
			var ra := profile(sa).x - 0.15
			var rb := profile(sb).x - 0.15
			var mid := (a + b) * 0.5
			# Out past the poles the outfield wall's own track runs on.
			if a >= 44.0:
				var t0 := smoothstep(45.0, 50.0, absf(sa))
				var t1 := smoothstep(45.0, 50.0, absf(sb))
				_quad(track, point(sa, ra - TRACK_WIDTH * t0, GrayboxField.TRACK_TOP), point(sa, ra, GrayboxField.TRACK_TOP), point(sb, rb, GrayboxField.TRACK_TOP), point(sb, rb - TRACK_WIDTH * t1, GrayboxField.TRACK_TOP), Color.WHITE)
			if absf(mid - DUGOUT_ANGLE) > dugout_half_angle() and not is_water(sa):
				var ha := profile(sa).y - 0.3
				var hb := profile(sb).y - 0.3
				_quad(pad, point(sa, ra, 0.0), point(sb, rb, 0.0), point(sb, rb, hb), point(sa, ra, ha), wall_color)
				_quad(pad, point(sa, ra - 0.12, ha), point(sb, rb - 0.12, hb), point(sb, rb - 0.12, hb + 0.18), point(sa, ra - 0.12, ha + 0.18), cap)
				_quad(pad, point(sa, ra - 0.12, ha + 0.18), point(sb, rb - 0.12, hb + 0.18), point(sb, rb + 0.3, hb + 0.18), point(sa, ra + 0.3, ha + 0.18), cap.darkened(0.2))
				_quad(pad, point(sa, ra - 0.12, ha), point(sb, rb - 0.12, hb), point(sb, rb, hb), point(sa, ra, ha), cap.darkened(0.3))
			# The backstop net over the wall behind the plate.
			if a >= 140.0:
				var h := BACKSTOP_WALL + 0.2
				_quad(net, point(sa, ra, h), point(sb, rb, h), point(sb, rb + 1.5, h + 9.0), point(sa, ra + 1.5, h + 9.0), Color.WHITE)
			a = b
	pad.generate_normals()
	var walls := MeshInstance3D.new()
	walls.name = "FieldWall"
	walls.mesh = pad.commit()
	var pad_mat := StandardMaterial3D.new()
	pad_mat.vertex_color_use_as_albedo = true
	pad_mat.vertex_color_is_srgb = true
	pad_mat.roughness = 0.75
	pad_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	walls.material_override = pad_mat
	add_child(walls)
	track.generate_normals()
	var dirt := MeshInstance3D.new()
	dirt.name = "FoulTrack"
	dirt.mesh = track.commit()
	var dirt_mat := GrayboxField._surface(GrayboxField.DIRT, GrayboxField.DIRT_TEX, GrayboxField.DIRT_NORMAL, 0.556, 3.0, 0.0)
	dirt_mat.set_shader_parameter("detail_strength", 0.45)
	dirt.material_override = dirt_mat
	add_child(dirt)
	net.generate_normals()
	var netting := MeshInstance3D.new()
	netting.name = "Backstop"
	netting.mesh = net.commit()
	var net_mat := StandardMaterial3D.new()
	net_mat.albedo_color = Color(0.08, 0.08, 0.1, 0.32)
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	net_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	netting.material_override = net_mat
	add_child(netting)


## The wall's dressing: distances in big numbers (the foul-pole distances
## near each pole, as on the sheets, and center field) and the home club's
## emblem near each pole and in the alleys. A park whose wall art has a
## sheet layout paints its own emblems, and may set the numbers' color.
func _build_markers(home: TeamDef) -> void:
	var art := def.pieces_of(&"wall_art")
	var laid_out := not art.is_empty() and not (art[0].param("layout") as Array).is_empty()
	var color := def.accent_color
	if not art.is_empty() and Color(art[0].param("numbers")).a > 0.0:
		color = Color(art[0].param("numbers"))
	for spot_angle: float in [-37.0, 0.0, 37.0]:
		var at_pole := signf(spot_angle) * 45.0
		var d := FieldLayout.fence_distance(at_pole, tuning)
		var h := FieldLayout.fence_height(spot_angle, tuning)
		var marker := label(str(roundi(d * 3.2808)), 200, color)
		marker.pixel_size = 0.012 * clampf(h / 3.0, 0.5, 1.0)
		marker.outline_size = 12
		marker.outline_modulate = Color(0, 0, 0, 0.6)
		var inward := wall_inward(spot_angle)
		# Off the wall face by enough that the wall either side (which turns
		# toward home at the center-field peak) never cuts into the digits.
		var spot := point(spot_angle, FieldLayout.fence_distance(spot_angle, tuning), minf(h * 0.55, 2.2)) + inward * 0.75
		marker.look_at_from_position(spot, spot - inward, Vector3.UP)
	if laid_out:
		return
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
				# The low wall opens onto the dugout: no words across it.
				var gap := dugout_half_angle() + 1.0
				if d == 0 and a < DUGOUT_ANGLE + gap and a + span > DUGOUT_ANGLE - gap:
					a = DUGOUT_ANGLE + gap
					continue
				var placed := false
				for i in text.length():
					var angle := (a + span * (i + 0.5) / text.length()) * side
					var p := profile(angle)
					if k >= int(p.z):
						continue
					var height := (row_height(angle, p, k) + (0.0 if k == 0 else row_height(angle, p, k - 1))) * 0.5
					var radius := p.x + k * ROW_DEPTH
					if k > 0 and overhang(angle) > 0.05:
						# On the overhanging deck's fascia.
						var front := deck_front(angle, p, k)
						radius = front.x
						height = front.y
					# Seen from the field, the third-base words run toward home.
					var letter := label(text[i] if side > 0.0 else text[text.length() - 1 - i], 110, home.dark_color if d > 0 else Color.WHITE, root)
					letter.pixel_size = pixel
					letter.position = point(angle, radius - 0.15, height)
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


## Takes the video board over for a celebration (see Jumbotron.play_moment).
func board_moment(kind: StringName, data: Dictionary = {}) -> void:
	for board in _boards:
		if board.has("jumbo"):
			(board["jumbo"] as Jumbotron).play_moment(kind, data)


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
		if board.has("jumbo"):
			(board["jumbo"] as Jumbotron).show_state(state, roster)
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
