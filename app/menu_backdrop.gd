class_name MenuBackdrop
extends Node3D
## What the main menu sits on: a park dressed for its own club (a random
## one each launch), seen from a camera drifting slowly round behind home
## plate and up over the infield, the crowd stirring now and then.

## Seconds per lap of the slow orbit, and its shape (m).
const LAP := 150.0
const RADIUS := 48.0
const HEIGHT := 1.5
const CENTER := Vector3(0, 4, -40)

var _view: MatchView
var _camera: Camera3D
var _t := 0.0
var _next_cheer := 4.0
var _rng := RandomNumberGenerator.new()


## Dresses `view` in a random park and takes over the camera.
func start(view: MatchView, content: ContentLibrary) -> void:
	_view = view
	_rng.randomize()
	if not content.parks.is_empty():
		# A park under the lights or the evening sky, as the reference.
		var evening := content.parks.filter(func(p: StadiumDef) -> bool: return p.night or p.sky_kind() in [&"sunset", &"dusk", &"night"])
		var pool: Array = evening if not evening.is_empty() else content.parks
		var park: StadiumDef = pool[_rng.randi_range(0, pool.size() - 1)]
		var home: TeamDef = content.teams[0]
		for team in content.teams:
			if team.stadium_def == park:
				home = team
		var away: TeamDef = content.teams[(content.teams.find(home) + 1) % content.teams.size()]
		view.set_roster(MatchRoster.new(away, home))
		view.set_park(content.tuning_for(park), park)
	_camera = Camera3D.new()
	_camera.fov = 52.0
	_camera.near = 0.25
	_camera.far = 4000.0
	view.add_child(_camera)
	_camera.make_current()
	# Start the orbit behind home plate, the park's best side.
	_t = LAP * 0.5
	_place()


## Hands the camera back to the match.
func stop() -> void:
	if _camera != null:
		_camera.queue_free()
		_camera = null
	if _view != null:
		_view._camera.make_current()


func _process(delta: float) -> void:
	if _camera == null:
		return
	_t += delta
	_place()
	_next_cheer -= delta
	if _next_cheer <= 0.0:
		_view.cheer(_rng.randf_range(0.2, 0.55))
		_next_cheer = _rng.randf_range(6.0, 12.0)


func _place() -> void:
	# A slow sweep across the home-plate side (not a full lap: the outfield
	# side looks at the backs of the stands' landmarks).
	var a := PI * 0.5 + sin(_t / LAP * TAU) * 0.45
	var at := CENTER + Vector3(cos(a) * RADIUS, HEIGHT + sin(_t / LAP * TAU * 2.0) * 1.0, sin(a) * RADIUS)
	_camera.position = at
	_camera.look_at(CENTER + Vector3(0, 6, -50), Vector3.UP)
