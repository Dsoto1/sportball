class_name StreakFlames
extends Node3D
## Flames for a hitter on a streak (hits in a row today): fire licking off
## the barrel, left behind in the air as the bat moves, and on the ball he
## hits. Hotter the longer the streak: orange at 2, a white-hot core and
## more fire from 3. Presentation only.

## Hits in a row before the bat catches fire.
const HOT_FROM := 2
const BLAZING_FROM := 3

var level := 0
var _fire: CPUParticles3D
var _embers: CPUParticles3D
static var _puffs := {}


func _init() -> void:
	_fire = _particles(48, 0.42)
	_embers = _particles(16, 0.7)
	_embers.scale_amount_min = 0.12
	_embers.scale_amount_max = 0.25
	_embers.initial_velocity_min = 0.6
	_embers.initial_velocity_max = 1.4
	set_level(0)


## Lights the flames for a streak of `streak` hits (out below HOT_FROM).
## `extent`: half length of the burning part (along Z, round this node's
## origin; 0 = a ball of fire), `size` scales it.
func set_level(streak: int, extent: float = 0.0, size: float = 1.0) -> void:
	level = 0 if streak < HOT_FROM else (2 if streak >= BLAZING_FROM else 1)
	var on := level > 0
	for p: CPUParticles3D in [_fire, _embers]:
		if extent > 0.0:
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
			p.emission_box_extents = Vector3(0.025, 0.025, extent) * size
		else:
			p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			p.emission_sphere_radius = 0.05 * size
		p.scale_amount_min = (0.35 if p == _fire else 0.12) * size
		p.scale_amount_max = (0.75 if p == _fire else 0.25) * size
		if p.emitting != on:
			p.emitting = on
	_fire.amount = 80 if level >= 2 else 48
	_fire.color_ramp = _ramp(level >= 2)
	_embers.color_ramp = _ramp(false)


func lit() -> bool:
	return level > 0


func _particles(amount: int, lifetime: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.local_coords = false  # left behind as the bat or ball moves
	p.direction = Vector3.UP
	p.spread = 25.0
	p.initial_velocity_min = 0.3
	p.initial_velocity_max = 0.8
	p.gravity = Vector3(0, 2.2, 0)  # flames rise
	p.damping_min = 0.5
	p.damping_max = 1.5
	p.mesh = _puff_mesh(lifetime < 0.5)
	var shrink := Curve.new()
	shrink.add_point(Vector2(0, 0.6))
	shrink.add_point(Vector2(0.25, 1.0))
	shrink.add_point(Vector2(1, 0.1))
	p.scale_amount_curve = shrink
	p.emitting = false
	add_child(p)
	return p


## Yellow-white at the root through orange to a dark red that fades;
## `blazing` starts white-hot.
static func _ramp(blazing: bool) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.6, 1.0])
	g.colors = PackedColorArray([
		Color(1.0, 0.98, 0.85, 1.0) if blazing else Color(1.0, 0.85, 0.35, 1.0),
		Color(1.0, 0.7, 0.2, 0.95),
		Color(0.95, 0.28, 0.05, 0.7),
		Color(0.5, 0.05, 0.0, 0.0),
	])
	return g


## A soft round billboard: `solid` blends normally (the flame body, so it
## shows against bright stands and sky), else adds light (embers).
static func _puff_mesh(solid: bool) -> QuadMesh:
	if _puffs.has(solid):
		return _puffs[solid]
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX if solid else BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	q.material = m
	_puffs[solid] = q
	return q
