class_name MatchFx
extends Node3D
## The match's particle effects, from the owner's licensed Binbun3D VFX
## packs (assets/BinbunVFX_Vol2: Stylized Hit FX, Explosion FX;
## dust is drawn here). Each call spawns one effect, plays it once
## and frees it when it is done. Presentation only.
##   contact():  the bat meeting the ball, bigger and hotter the better the
##               contact;
##   fireworks(): a home run: bursts over the outfield stands;
##   dust():     a puff of infield dirt (a slide, a ball landing on dirt).

const HIT := "res://assets/BinbunVFX_Vol2/StylizedHitFX/effects/"
const BOOM := "res://assets/BinbunVFX_Vol2/ExplosionFX/effects/"
## Contact by tier (ContactFeedback.Tier WEAK, OK, SOLID, SWEET): scene, scale.
const CONTACT := [
	[HIT + "hit/vfx_hit_01.tscn", 0.16],
	[HIT + "hit/vfx_hit_03.tscn", 0.22],
	[HIT + "impact/vfx_impact_02.tscn", 0.34],
	[HIT + "big_impact/vfx_big_impact_01.tscn", 0.48],
]
## Fireworks: the hit pack's star bursts, blown up in the sky (they read
## as shells bursting: rays, a flash, a ring), with a burst explosion now
## and then for a bang.
const FIREWORKS := [HIT + "big_impact/vfx_big_impact_01.tscn", HIT + "big_impact/vfx_big_impact_03.tscn", HIT + "big_impact/vfx_big_impact_05.tscn", HIT + "big_impact/vfx_big_impact_07.tscn", BOOM + "burst/vfx_burst_explosion_01.tscn"]
## Firework colors cycle through the batting club's own and gold.
const GOLD := Color(1.0, 0.82, 0.3)

## No flashes (GameSettings "reduce_flashes"): contact and fireworks are
## skipped; dust stays.
var reduce_flashes := false
static var _scenes := {}
var _rng := RandomNumberGenerator.new()


func _scene(path: String) -> PackedScene:
	if not _scenes.has(path):
		_scenes[path] = load(path) if ResourceLoader.exists(path) else null
	return _scenes[path]


## Loads every effect now and draws each once, far too small to see, just
## in front of `camera`: their scenes load and their shaders compile here,
## at start-up, instead of the first time the bat meets the ball (a hitch
## right at contact) or the first home run.
func warm_up(camera: Camera3D) -> void:
	if camera == null or not camera.is_inside_tree():
		return
	var paths: Array = []
	for spec: Array in CONTACT:
		paths.append(spec[0])
	paths.append_array(FIREWORKS)
	var spot := camera.global_transform * Vector3(0, 0, -1.5)
	for path: String in paths:
		var fx := _spawn(path, spot, 0.002)
		if fx != null:
			_tint(fx, GOLD, GOLD)
	dust(spot, 0.002)


## The bat meeting the ball at `at`, `tier` 0..3 (sweet), tinted toward
## `color` (the batting club's).
func contact(at: Vector3, tier: int, color: Color) -> void:
	if reduce_flashes:
		return
	if tier <= ContactFeedback.Tier.MISS:
		return
	var spec: Array = CONTACT[clampi(tier - 1, 0, CONTACT.size() - 1)]
	var fx := _spawn(spec[0], at, spec[1])
	if fx != null and tier >= ContactFeedback.Tier.SWEET:
		_tint(fx, Color(1, 1, 1), GOLD.lerp(color, 0.35))


## The pitch leaving the hand: a small burst in the pitch's colour, bigger
## and brighter the cleaner the release (`strength` 0..1).
func release(at: Vector3, color: Color, strength: float) -> void:
	if reduce_flashes or strength < 0.2:
		return
	var spec: Array = CONTACT[0]
	var fx := _spawn(spec[0], at, float(spec[1]) * lerpf(0.35, 0.75, strength))
	if fx != null:
		_tint(fx, color.lightened(0.5), color)


## A home run's fireworks: `count` bursts over the outfield stands (round
## `center`, `radius` m out, `height` up), over `seconds`, in the batting
## club's colors and gold.
func fireworks(center: Vector3, radius: float, height: float, colors: Array[Color], count: int = 7, seconds: float = 2.6) -> void:
	if reduce_flashes:
		return
	for i in count:
		var delay := seconds * i / count + _rng.randf_range(0.0, 0.15)
		var a := deg_to_rad(_rng.randf_range(-40.0, 40.0))
		var at := center + Vector3(sin(a) * radius, height + _rng.randf_range(-6.0, 10.0), -cos(a) * radius)
		var color: Color = colors[i % colors.size()] if not colors.is_empty() else GOLD
		get_tree().create_timer(delay, false).timeout.connect(func() -> void:
			var pick := _rng.randi_range(0, FIREWORKS.size() - 1)
			var big := 14.0 if pick < FIREWORKS.size() - 1 else 6.0
			var fx := _spawn(FIREWORKS[pick], at, _rng.randf_range(0.8, 1.2) * big)
			if fx != null:
				_tint(fx, color.lightened(0.4), color))


## A puff of dirt at `at` (ground level), `size` 1 for a slide: soft
## brown billboards thrown up and out low, fading as they settle.
func dust(at: Vector3, size: float = 1.0, color: Color = Color(0.86, 0.72, 0.55)) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 28
	p.lifetime = 0.9
	p.mesh = _puff_mesh()
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.25 * size
	p.direction = Vector3(0, 1, 0)
	p.spread = 55.0
	p.initial_velocity_min = 1.2 * size
	p.initial_velocity_max = 3.0 * size
	p.gravity = Vector3(0, -2.5, 0)
	p.damping_min = 2.0
	p.damping_max = 3.5
	p.scale_amount_min = 0.5 * size
	p.scale_amount_max = 1.1 * size
	var grow := Curve.new()
	grow.add_point(Vector2(0, 0.5))
	grow.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = grow
	var fade := Gradient.new()
	fade.set_color(0, Color(color, 0.9))
	fade.set_color(1, Color(color.lightened(0.15), 0.0))
	p.color_ramp = fade
	add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(p.lifetime + 0.3, false).timeout.connect(p.queue_free)


static var _puff: QuadMesh


## A soft round billboard for dust (vertex color, alpha from a radial fade).
static func _puff_mesh() -> QuadMesh:
	if _puff == null:
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
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_puff = QuadMesh.new()
		_puff.size = Vector2(0.8, 0.8)
		_puff.material = m
	return _puff


## Spawns an effect scene at `at`, plays it once, frees it after.
func _spawn(path: String, at: Vector3, size: float) -> Node3D:
	var scene := _scene(path)
	if scene == null:
		return null
	var fx := scene.instantiate() as Node3D
	if "one_shot" in fx:
		fx.set("one_shot", true)
	if "autoplay" in fx:
		fx.set("autoplay", false)
	add_child(fx)
	fx.global_position = at
	fx.scale = Vector3.ONE * size
	if fx.has_method("play"):
		fx.call("play")
	# Freed once done (the controllers emit finished; a timer backs it up).
	if fx.has_signal("finished"):
		fx.connect("finished", fx.queue_free)
	# (By id, not the node: a lambda holding a node that `finished` already
	# freed errors when called, before any validity check inside it runs.)
	var id := fx.get_instance_id()
	get_tree().create_timer(4.0, false).timeout.connect(func() -> void:
		var node := instance_from_id(id) as Node
		if node != null and is_instance_valid(node):
			node.queue_free())
	return fx


static func _tint(fx: Node3D, primary: Color, secondary: Color) -> void:
	if "primary_color" in fx:
		fx.set("primary_color", primary)
	if "secondary_color" in fx:
		fx.set("secondary_color", secondary)
