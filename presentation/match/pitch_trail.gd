class_name PitchTrail
extends MeshInstance3D
## The pitch's streak: a glowing ribbon behind the ball in the pitch's tell
## colour, drawn facing the camera, with a look per pitch kind so the
## batter reads the pitch from its trail as well as its colour (the ghost
## balls in MatchView still carry the count cue). Presentation only.
##   fastball:  a long straight streak with a white-hot core;
##   breaking:  two strands twisting round the path (it spins);
##   offspeed:  soft, wide and pulsing (it floats);
##   signature: a gold-edged streak shedding sparks (the knuckler's
##              wobbles with it, the showstopper's flares as it hangs).

const STYLE_FASTBALL := &"fastball"
const STYLE_BREAKING := &"breaking"
const STYLE_OFFSPEED := &"offspeed"
const STYLE_SIGNATURE := &"signature"
## Seconds of flight behind the ball, per ghost ball of the tell.
const SECONDS_PER_TELL := 0.028
const MIN_SECONDS := 0.08
const SAMPLES := 18
## Ribbon half width in ball radii (grown with the ball, so it reads from
## the box and from the mound alike).
const WIDTH := {STYLE_FASTBALL: 0.9, STYLE_BREAKING: 0.55, STYLE_OFFSPEED: 1.5, STYLE_SIGNATURE: 1.0}
const CORE := Color(1.0, 1.0, 1.0)
const SPARK_GOLD := Color(1.0, 0.85, 0.35)

var _mesh := ImmediateMesh.new()
var _sparks: CPUParticles3D


func _init() -> void:
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false
	material_override = m
	_sparks = CPUParticles3D.new()
	_sparks.emitting = false
	_sparks.amount = 40
	_sparks.lifetime = 0.35
	_sparks.local_coords = false
	_sparks.direction = Vector3.UP
	_sparks.spread = 180.0
	_sparks.initial_velocity_min = 0.2
	_sparks.initial_velocity_max = 0.8
	_sparks.gravity = Vector3(0, -3.0, 0)
	_sparks.scale_amount_min = 0.5
	_sparks.scale_amount_max = 1.0
	var bit := QuadMesh.new()
	bit.size = Vector2(0.035, 0.035)
	var bm := StandardMaterial3D.new()
	var dot := GradientTexture2D.new()
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	var dot_fade := Gradient.new()
	dot_fade.set_color(0, Color(1, 1, 1, 1))
	dot_fade.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = dot_fade
	bm.albedo_texture = dot
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	bm.vertex_color_use_as_albedo = true
	bit.material = bm
	_sparks.mesh = bit
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	_sparks.color_ramp = fade
	add_child(_sparks)


## The style for a pitch family (by category; unknown kinds draw as a
## fastball).
static func style_for(family: PitchFamilyDef) -> StringName:
	if family == null:
		return STYLE_FASTBALL
	if family.category in [STYLE_BREAKING, STYLE_OFFSPEED, STYLE_SIGNATURE]:
		return family.category
	return STYLE_FASTBALL


## How many seconds of flight the trail covers for `tell_trail` ghosts.
static func trail_seconds(tell_trail: int) -> float:
	return maxf(MIN_SECONDS, tell_trail * SECONDS_PER_TELL)


func hide_trail() -> void:
	_mesh.clear_surfaces()
	_sparks.emitting = false


## Redraws the trail for `pitch` at flight time `t`, the ball drawn at
## `ball` (`ball_scale` its growth with distance), seen from `camera`.
## `lead_offset` is the presentation gap eased out of the first instant
## of flight (the ball leaving the hand); the trail follows it.
func draw(pitch: PitchResult, t: float, ball: Vector3, ball_scale: float, color: Color, tell_trail: int, family: PitchFamilyDef, camera: Camera3D, lead_offset: Callable = Callable()) -> void:
	_mesh.clear_surfaces()
	if camera == null or t <= 0.0 or t >= pitch.travel_time:
		_sparks.emitting = false
		return
	var style := style_for(family)
	var span := minf(trail_seconds(tell_trail), t)
	if span <= 0.005:
		return
	var points := PackedVector3Array()
	for i in SAMPLES + 1:
		var at := t - span * float(i) / SAMPLES
		var p := pitch.position_at(maxf(at, 0.0))
		if lead_offset.is_valid():
			p += lead_offset.call(at)
		points.append(p)
	# The head of the ribbon sits on the ball as drawn.
	points[0] = ball
	var radius := MatchView.BALL_RADIUS * ball_scale
	var eye := to_local(camera.global_position)
	var half: float = WIDTH[style] * radius
	match style:
		STYLE_BREAKING:
			# Two strands winding round the path: the spin you can see.
			# About two turns along the trail whatever its length, tight to
			# the ball at the head, opening a little behind it.
			var turns := 2.0 * TAU
			for strand in 2:
				_strip(points, eye, half, color, 0.85, func(i: int, side: Vector3, up: Vector3) -> Vector3:
					var u := float(i) / SAMPLES
					var phase := turns * u - t * 30.0 + PI * strand
					return (side * cos(phase) + up * sin(phase)) * radius * lerpf(0.5, 0.9, u))
			_strip(points, eye, half * 0.45, CORE, 0.5)
		STYLE_OFFSPEED:
			# Soft and wide, pulsing along its length (it floats in).
			_strip(points, eye, half, color, 0.45, Callable(), 3.0)
			_strip(points, eye, half * 0.35, CORE, 0.35)
		STYLE_SIGNATURE:
			var wobble := family != null and family.motion == &"knuckle"
			_strip(points, eye, half * 1.5, SPARK_GOLD, 0.35)
			_strip(points, eye, half, color, 0.8, (func(i: int, side: Vector3, up: Vector3) -> Vector3:
				var at := t - span * float(i) / SAMPLES
				return (side * sin(at * 41.0) + up * cos(at * 29.0)) * radius * 0.9) if wobble else Callable())
			_strip(points, eye, half * 0.4, CORE, 0.9)
		_:
			# Fastball: a hot white core inside a long colored glow.
			_strip(points, eye, half * 1.6, color, 0.4)
			_strip(points, eye, half * 0.8, color, 0.85)
			_strip(points, eye, half * 0.3, CORE, 1.0)
	_update_sparks(style, ball, color, radius)


func _update_sparks(style: StringName, ball: Vector3, color: Color, radius: float) -> void:
	var on := style == STYLE_SIGNATURE
	if on:
		_sparks.global_position = to_global(ball)
		_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		_sparks.emission_sphere_radius = radius * 0.8
		(_sparks.mesh as QuadMesh).size = Vector2.ONE * radius * 0.55
		_sparks.color = SPARK_GOLD.lerp(color, 0.3)
	if on and not _sparks.emitting:
		_sparks.restart()
	_sparks.emitting = on


## One camera-facing strip through `points` (head first), `half` wide at
## the head, tapering and fading to nothing at the tail. `offset` moves
## each point (strand twists); `pulses` > 0 beads its brightness.
func _strip(points: PackedVector3Array, eye: Vector3, half: float, color: Color, alpha: float, offset: Callable = Callable(), pulses: float = 0.0) -> void:
	var n := points.size()
	if n < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in n:
		var p := points[i]
		var ahead := points[maxi(i - 1, 0)]
		var behind := points[mini(i + 1, n - 1)]
		var along := (ahead - behind)
		if along.length_squared() < 1e-10:
			along = Vector3.FORWARD
		along = along.normalized()
		var view := (eye - p).normalized()
		var side := along.cross(view)
		if side.length_squared() < 1e-8:
			side = Vector3.RIGHT
		side = side.normalized()
		var up := view.cross(along).normalized()
		if offset.is_valid():
			p += offset.call(i, side, up)
		var u := float(i) / (n - 1)
		var taper := 1.0 - u
		var a := alpha * taper * taper
		if pulses > 0.0:
			a *= 0.55 + 0.45 * cos(u * pulses * TAU)
		var c := Color(color, a)
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(p + side * half * (0.25 + 0.75 * taper))
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(p - side * half * (0.25 + 0.75 * taper))
	_mesh.surface_end()
