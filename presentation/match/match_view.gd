class_name MatchView
extends Node3D
## Presents authoritative match data. Every position here is sampled from
## resolver output (PitchResult, BallTrajectory, FieldingResult, RunnerPlan,
## PlayOutcome); nothing in this node decides a baseball outcome.

enum CameraMode { BAT, PITCH, FIELD }

const AWAY_COLOR := Color(0.85, 0.22, 0.2)
const HOME_COLOR := Color(0.18, 0.42, 0.9)
const BATTER_SPOT := Vector3(-0.85, 0.0, 0.15)
const CAMERA_SPOTS := {
	# Telephoto from behind and right of the plate: batter on the left,
	# pitcher and zone large and clear.
	CameraMode.BAT: [Vector3(1.5, 3.4, 9.0), Vector3(0.0, 1.0, -9.0)],
	CameraMode.PITCH: [Vector3(0.4, 2.7, -24.5), Vector3(0.0, 0.9, 0.0)],
	CameraMode.FIELD: [Vector3(0.0, 30.0, 40.0), Vector3.ZERO],  # offset from the field focus
}

var tuning: BaseballTuning
var debug_visible := true

var _field: GrayboxField
## The home team's park around the field (null until a roster is set).
var _stadium: Stadium
var _camera: Camera3D
var _camera_mode := CameraMode.BAT
var _ball: MeshInstance3D
var _ball_shadow: MeshInstance3D
var _fielders: Array[ActorView] = []
## Green ring on the base the stick is aiming a throw at.
var _throw_target: MeshInstance3D
var _roster: MatchRoster
## Current batter hits left-handed: he stands in the other box.
var _bats_left := false
var _batter_id: StringName = &""
var _runners := {}
var _zone: Node3D
var _cursor: MeshInstance3D
var _cursor_inner: MeshInstance3D
var _debug_root: Node3D
var _trajectory_line: MeshInstance3D
var _landing_marker: MeshInstance3D
var _intercept_marker: MeshInstance3D
var _pitch_marker: MeshInstance3D
var _control_ring: MeshInstance3D
var _landing_hint: MeshInstance3D
var _field_focus := Vector3(0.0, 0.0, -42.0)
## Seconds a swing takes to come through the zone and follow through.
const SWING_TIME := 0.28
var _bat_pivot: Node3D
var _bat_swing_start := -1.0
var _bat_bunt := false
var _view_clock := 0.0
var _timing_ring: MeshInstance3D
var _windup := -1.0
var _aim: Node3D
var _aim_shaft: MeshInstance3D
var _aim_head: MeshInstance3D
var _flash: MeshInstance3D
var _flash_start := -10.0
var _flash_size := 0.0
var _contact_sound: ContactSound
## Sound effects and the crowd.
var sfx: Sfx
var _trail: Array[MeshInstance3D] = []
var _punch_start := -10.0
var _punch_strength := 0.0
var _shake_rng := RandomNumberGenerator.new()
var _animator := PlayAnimator.new()
var _last_actor_pos := {}
var _rundown_focus := Vector3.ZERO
var _rundown_zoom := false


func setup(p_tuning: BaseballTuning) -> void:
	tuning = p_tuning
	_field = GrayboxField.new()
	_field.name = "GrayboxField"
	add_child(_field)
	_field.build(tuning)
	_camera = Camera3D.new()
	_camera.fov = 55.0
	add_child(_camera)
	_camera.current = true
	_snap_camera()
	_ball = _sphere(0.11, Color(1, 1, 1), true)
	_ball_shadow = _disc(0.18, Color(0, 0, 0, 0.45))
	for id in tuning.fielder_ids:
		var actor := ActorView.new()
		add_child(actor)
		actor.setup(HOME_COLOR, String(id).to_upper())
		_fielders.append(actor)
	_build_zone()
	_build_bat()
	_build_aim_and_flash()
	_build_debug()


const CAMERA_FOV := {CameraMode.BAT: 34.0, CameraMode.PITCH: 50.0, CameraMode.FIELD: 55.0}


func set_camera_mode(mode: CameraMode) -> void:
	_camera_mode = mode
	# The HUD names the batter; over his head the tag would cover the pitcher.
	var batter: ActorView = _runners.get(_batter_id)
	if batter != null:
		batter.set_tag_visible(mode != CameraMode.BAT)
	var catcher := tuning.fielder_ids.find(&"c")
	if catcher >= 0 and catcher < _fielders.size():
		_fielders[catcher].set_tag_visible(mode != CameraMode.BAT)


## Point the ball-in-play camera tracks.
func set_field_focus(point: Vector3) -> void:
	_field_focus = point


func set_debug_visible(value: bool) -> void:
	debug_visible = value
	_debug_root.visible = value


## Places everyone for the next pitch from the authoritative state.
func reset_for_pitch(state: MatchState) -> void:
	var fielding_color := HOME_COLOR if state.fielding_team() == MatchState.HOME else AWAY_COLOR
	var batting_color := AWAY_COLOR if state.batting_team() == MatchState.AWAY else HOME_COLOR
	var fielding_trim := Color(0, 0, 0, 0)
	var batting_trim := Color(0, 0, 0, 0)
	if _roster != null:
		fielding_color = _roster.teams[state.fielding_team()].primary_color
		fielding_trim = _roster.teams[state.fielding_team()].secondary_color
		batting_color = _roster.teams[state.batting_team()].primary_color
		batting_trim = _roster.teams[state.batting_team()].secondary_color
	_animator = PlayAnimator.new()
	_last_actor_pos.clear()
	_rundown_zoom = false
	for i in _fielders.size():
		_fielders[i].reset_pose()
		_fielders[i].set_look(fielding_color, _fielder_tag(state, tuning.fielder_ids[i]), fielding_trim)
		_fielders[i].position = tuning.fielder_spots[i]
		_fielders[i].face(Vector3.ZERO)
		_fielders[i].set_crouch(tuning.fielder_ids[i] == &"c")
	_clear_runners()
	var batter := _runner_actor(state.current_batter(), batting_color, batting_trim)
	_batter_id = state.current_batter()
	batter.set_tag_visible(_camera_mode != CameraMode.BAT)
	var hitter := _roster.player(state.current_batter()) if _roster != null else null
	_bats_left = hitter != null and hitter.bats_left()
	batter.position = _batter_spot()
	batter.face(batter.position + (Vector3.LEFT if _bats_left else Vector3.RIGHT))  # square to the plate
	set_bat(true)
	set_aim_preview(false)
	_windup = -1.0
	_timing_ring.visible = false
	for base in [1, 2, 3]:
		var id := state.runner_on(base)
		if id != &"":
			var actor := _runner_actor(id, batting_color, batting_trim)
			actor.position = FieldLayout.base_position(base)
			actor.face(FieldLayout.base_position(base + 1))
	_ball.position = Vector3(tuning.release_side, tuning.release_height, -tuning.release_distance)
	_update_shadow()
	_pitch_marker.visible = false
	_control_ring.visible = false
	_landing_hint.visible = false
	_throw_target.visible = false
	_field_focus = Vector3(0.0, 0.0, -42.0)
	_zone.visible = true


## The batter's bat: shown in his stance until the ball is put in play.
func set_bat(visible_now: bool) -> void:
	_bat_pivot.visible = visible_now
	_bat_swing_start = -1.0
	_bat_bunt = false


## Squares around: the bat held flat out over the plate.
func bunt_bat() -> void:
	_bat_bunt = true
	_bat_swing_start = -1.0


## A runner off his bag toward the next one: his lead before the pitch
## (standing), or stealing during it (running).
func set_runner_off_base(id: StringName, base: int, meters: float, running: bool = true) -> void:
	var actor: ActorView = _runners.get(id)
	if actor == null:
		return
	var from := FieldLayout.base_position(base)
	var to := FieldLayout.base_position(base + 1)
	actor.position = from.move_toward(to, meters)
	actor.face(to)
	if running:
		actor.animate(ActorView.Pose.RUN, get_process_delta_time(), tuning.runner_speed)
	else:
		actor.animate(ActorView.Pose.IDLE, get_process_delta_time())


## Aim preview while batting: an arrow from home plate in the direction the
## stick sends the ball, long and sky-blue for lift, short and brown for a
## chop. spray_deg as in FieldLayout (+ = right field); lift = stick y.
func set_aim_preview(show: bool, spray_deg: float = 0.0, lift: float = 0.0) -> void:
	_aim.visible = show
	if not show:
		return
	var dir := FieldLayout.direction_for_spray(spray_deg)
	_aim.position = Vector3(0.0, 0.06, -1.0)
	_aim.look_at(_aim.position + dir, Vector3.UP)
	var length := lerpf(14.0, 55.0, (clampf(lift, -1.0, 1.0) + 1.0) * 0.5)
	_aim_shaft.scale = Vector3(1.0, 1.0, length)
	_aim_shaft.position = Vector3(0.0, 0.0, -length * 0.5)
	_aim_head.position = Vector3(0.0, 0.0, -length - 1.2)
	var color := Color(1.0, 1.0, 1.0, 0.5)
	if lift > 0.3:
		color = Color(0.45, 0.8, 1.0, 0.6)  # in the air
	elif lift < -0.3:
		color = Color(0.85, 0.55, 0.25, 0.6)  # on the ground
	(_aim_shaft.material_override as StandardMaterial3D).albedo_color = color
	(_aim_head.material_override as StandardMaterial3D).albedo_color = color


## Contact feedback at the plate: a burst (solid contact and better) and
## the crack of the bat. tier: ContactFeedback.Tier.
func contact_feedback(location: Vector2, tier: int) -> void:
	_contact_sound.play_tier(tier)
	if tier != ContactFeedback.Tier.MISS:
		# Wood under the synthesized crack: fuller the better the contact.
		sfx.play(&"bat", -8.0 + 2.0 * tier, lerpf(0.85, 1.05, tier / 4.0))
	if tier < ContactFeedback.Tier.SOLID:
		return
	# Camera punch: a quick zoom-in kick and shake, bigger on the barrel.
	_punch_start = _view_clock
	_punch_strength = 1.0 if tier == ContactFeedback.Tier.SWEET else 0.5
	_flash.position = Vector3(location.x, location.y, 0.1)
	_flash_size = 0.9 if tier == ContactFeedback.Tier.SWEET else 0.45
	var color := Color(1.0, 0.9, 0.3, 0.9) if tier == ContactFeedback.Tier.SWEET else Color(1, 1, 1, 0.8)
	(_flash.material_override as StandardMaterial3D).albedo_color = color
	_flash_start = _view_clock


## Plays the swing (on contact and on a miss alike).
func swing_bat() -> void:
	_bat_swing_start = _view_clock


## Pitcher's windup, 0..1, or -1 when not winding up. The ball sits in his
## glove until the pitch is released.
func show_windup(progress: float) -> void:
	_windup = progress


## Timing aid: a ring on the plate that closes as the pitch arrives
## (u = flight / travel time; hidden outside 0..1.2).
func show_timing_ring(u: float) -> void:
	_timing_ring.visible = u >= 0.0 and u <= 1.2
	if not _timing_ring.visible:
		return
	var r := lerpf(0.75, tuning.zone_half_width * 0.6, clampf(u, 0.0, 1.0))
	_timing_ring.scale = Vector3.ONE * r
	var now := absf(u - 1.0) < 0.08
	(_timing_ring.material_override as StandardMaterial3D).albedo_color = Color(0.3, 1.0, 0.4) if now else Color(1, 1, 1, 0.8)


## tell: the pitch family's colour and trail length (batter's read).
func show_pitch(pitch: PitchResult, t: float, tell_color: Color = Color.WHITE, tell_trail: int = 0) -> void:
	_ball.position = pitch.position_at(t)
	_update_shadow()
	for i in _trail.size():
		var ghost := _trail[i]
		ghost.visible = i < tell_trail and t > 0.0 and t < pitch.travel_time
		if not ghost.visible:
			continue
		ghost.position = pitch.position_at(maxf(t - (i + 1) * 0.022, 0.0))
		var fade := 1.0 - float(i + 1) / (tell_trail + 1)
		# Same distance-based growth as the ball, so the tell reads from the box.
		ghost.scale = _ball.scale * (0.9 * fade + 0.35)
		(ghost.material_override as StandardMaterial3D).albedo_color = Color(tell_color, 0.35 + 0.6 * fade)


func show_pitch_marker(pitch: PitchResult) -> void:
	_pitch_marker.position = Vector3(pitch.location.x, pitch.location.y, 0.02)
	_pitch_marker.visible = debug_visible


## cursor_radius 0 hides the cursor.
func set_cursor(at: Vector2, outer_radius: float, inner_radius: float, color: Color) -> void:
	_cursor.visible = outer_radius > 0.0
	_cursor_inner.visible = inner_radius > 0.0
	_cursor.position = Vector3(at.x, at.y, 0.03)
	_cursor_inner.position = _cursor.position
	_cursor.scale = Vector3.ONE * outer_radius
	_cursor_inner.scale = Vector3.ONE * inner_radius
	(_cursor.material_override as StandardMaterial3D).albedo_color = color
	(_cursor_inner.material_override as StandardMaterial3D).albedo_color = color.lightened(0.4)


## Draws a ball in play at contact-relative time t from the LivePlay
## (runners, ball, holder, covers). play is null for a home run, which is
## drawn from the outcome. live is the LiveFielding while a human fields.
## Cutoff man by relay target: left side / right side of the field.
const CUTOFF_PREFERENCE := {1: [&"2b", &"2b"], 2: [&"ss", &"2b"], 3: [&"ss", &"ss"], 4: [&"3b", &"1b"]}
const COVER_PREFERENCE := {1: [&"1b", &"p", &"2b"], 2: [&"2b", &"ss"], 3: [&"3b", &"ss"], 4: [&"c", &"p"]}


func show_play(bip: BallInPlay, t: float, play: LivePlay, outcome: PlayOutcome, live: LiveFielding = null, selected_runner: StringName = &"") -> void:
	_zone.visible = false
	_bat_pivot.visible = false
	_aim.visible = false
	for ghost in _trail:
		ghost.visible = false
	_timing_ring.visible = false
	_windup = -1.0
	var fielding := bip.fielding
	var secured := play != null and play.ball != LivePlay.Ball.LOOSE
	_ball.position = play.ball_position() if play != null else bip.trajectory.position_at(t)
	_update_shadow()
	_control_ring.visible = live != null and not live.is_secured() and live.controlled >= 0
	# Gameplay aid for the human fielder: where a fly ball will come down.
	_landing_hint.visible = live != null and not live.is_secured() and bip.trajectory.is_airborne_at(t)
	_landing_hint.position = bip.trajectory.landing_point + Vector3.UP * 0.06
	var cutoff := -1
	if play != null and play.cutoff_active:
		cutoff = _cutoff_fielder(play.relay_target, fielding)
	var covers := _cover_assignments(fielding.fielder_index, cutoff)
	var holder := -1
	if secured:
		match play.holder_cover:
			-1:
				holder = fielding.fielder_index
			LivePlay.CUTOFF:
				holder = cutoff
			_:
				holder = covers.get(play.holder_cover, -1)
	for i in _fielders.size():
		var start := tuning.fielder_spots[i]
		var actor := _fielders[i]
		actor.set_crouch(false)
		var since := maxf(t - tuning.fielder_reaction, 0.0)
		if i == holder:
			actor.position = play.holder_pos
			actor.face(_ball.position)
		elif i == cutoff:
			actor.position = actor.position.move_toward(play.covers[LivePlay.CUTOFF], tuning.fielder_speed * 0.05)
			actor.face(_ball.position)
		elif secured and covers.values().has(i):
			actor.position = actor.position.move_toward(play.covers[covers.find_key(i)], tuning.fielder_speed * 0.05)
			actor.face(_ball.position)
		elif live != null:
			actor.position = live.positions[i]
			actor.face(_ball.position)
			if i == live.controlled:
				_control_ring.position = live.positions[i] + Vector3.UP * 0.05
		elif i == fielding.fielder_index and not secured:
			var u := clampf(since / maxf(fielding.secure_time - tuning.fielder_reaction, 0.01), 0.0, 1.0)
			var goal := Vector3(fielding.secure_point.x, 0.0, fielding.secure_point.z)
			actor.position = start.lerp(goal.move_toward(start, tuning.catch_reach), u)
			actor.face(_ball.position)
		elif covers.values().has(i):
			actor.position = start.move_toward(FieldLayout.base_position(covers.find_key(i)), since * tuning.fielder_speed)
			actor.face(_ball.position)
		else:
			var drift := Vector3(_ball.position.x, 0.0, _ball.position.z)
			actor.position = start.move_toward(drift, since * tuning.fielder_speed * 0.35)
			actor.face(_ball.position)
	if play != null:
		for r in play.runners:
			var actor: ActorView = _runners.get(r.id)
			if actor == null:
				continue
			if r.id == selected_runner:
				# The runner the held base button would order.
				_control_ring.visible = true
				_control_ring.position = play.runner_position(r) + Vector3.UP * 0.05
			actor.visible = r.state != LivePlay.State.OUT and r.state != LivePlay.State.SCORED
			actor.position = play.runner_position(r)
			actor.face(play.runner_position(r).move_toward(FieldLayout.base_position(r.target), 1.0) + Vector3(0.0, 0.0, 0.001))
	elif outcome != null:
		# Home run trot.
		for advance in outcome.advances:
			var actor: ActorView = _runners.get(advance["runner_id"])
			if actor == null:
				continue
			var trot := RunnerPlan.new()
			trot.start_base = advance["from"]
			trot.target_base = FieldLayout.SCORED
			trot.start_time = tuning.batter_start_delay
			trot.arrival_time = RunnerResolver.arrival_between(trot.start_base, trot.target_base, trot.start_time, tuning)
			actor.position = trot.position_at(t)
			actor.animate(ActorView.Pose.RUN, get_process_delta_time(), tuning.runner_speed * 0.7)
	_animate_play(play, fielding, holder, covers, cutoff)


## Poses every body for this frame and puts a held ball in the glove.
func _animate_play(play: LivePlay, fielding: FieldingResult, holder: int, covers: Dictionary, cutoff: int) -> void:
	var delta := maxf(get_process_delta_time(), 1.0 / 240.0)
	if play == null:
		return
	_animator.update(play)
	var thrower := _actor_for_cover(_animator.thrower_cover, fielding, covers, cutoff)
	for i in _fielders.size():
		var actor := _fielders[i]
		var moved: float = actor.position.distance_to(_last_actor_pos.get(actor, actor.position)) / delta
		_last_actor_pos[actor] = actor.position
		if i == thrower:
			actor.animate(ActorView.Pose.THROW, delta, 0.0, false, _animator.thrower_progress)
		elif i == holder:
			actor.animate(_animator.holder_pose, delta, _animator.holder_speed)
		else:
			actor.animate(ActorView.Pose.RUN if moved > 0.8 else ActorView.Pose.IDLE, delta, moved)
	if holder >= 0 and play.ball == LivePlay.Ball.HELD:
		_ball.position = _fielders[holder].hand_position()
		_update_shadow()
	for r in play.runners:
		var actor: ActorView = _runners.get(r.id)
		if actor == null:
			continue
		var cue := _animator.runner_cue(play, r)
		actor.visible = cue["visible"]
		actor.animate(cue["pose"], delta, cue["speed"], cue["juke"])
	_rundown_zoom = _animator.rundown_active()
	if _rundown_zoom:
		var r := play.runner(_animator.rundown_runner)
		var ball := _ball.position
		_rundown_focus = play.runner_position(r).lerp(Vector3(ball.x, 0.0, ball.z), 0.5)


func _actor_for_cover(cover: int, fielding: FieldingResult, covers: Dictionary, cutoff: int) -> int:
	match cover:
		-2:
			return -1
		-1:
			return fielding.fielder_index
		LivePlay.CUTOFF:
			return cutoff
	return covers.get(cover, -1)


func show_debug_play(bip: BallInPlay) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var stride := 4
	for i in range(0, bip.trajectory.points.size(), stride):
		mesh.surface_add_vertex(bip.trajectory.points[i])
	mesh.surface_add_vertex(bip.trajectory.rest_point())
	mesh.surface_end()
	_trajectory_line.mesh = mesh
	_landing_marker.position = bip.trajectory.landing_point + Vector3.UP * 0.05
	_landing_marker.visible = true
	_intercept_marker.visible = bip.fielding.has_fielder()
	if bip.fielding.has_fielder():
		_intercept_marker.position = bip.fielding.secure_point + Vector3.UP * 0.07


func clear_debug_play() -> void:
	_trajectory_line.mesh = null
	_landing_marker.visible = false
	_intercept_marker.visible = false


func _process(delta: float) -> void:
	if _camera == null:
		return
	_view_clock += delta
	var flash_age := _view_clock - _flash_start
	_flash.visible = flash_age < 0.18
	if _flash.visible:
		_flash.scale = Vector3.ONE * _flash_size * (0.4 + flash_age / 0.18)
	_camera.fov = lerpf(_camera.fov, CAMERA_FOV[_camera_mode], 1.0 - exp(-delta * 6.0))
	var punch_age := _view_clock - _punch_start
	var kick := 0.0
	if punch_age < 0.25:
		kick = _punch_strength * (1.0 - punch_age / 0.25)
		_camera.fov = CAMERA_FOV[_camera_mode] - 5.0 * kick
	_update_bat()
	_update_windup(delta)
	var spot: Array = CAMERA_SPOTS[_camera_mode]
	var weight := 1.0 - exp(-delta * 6.0)
	var goal: Vector3 = spot[0]
	if _camera_mode == CameraMode.BAT and _bats_left:
		goal.x = -goal.x  # look over the lefty's shoulder, not through him
	var target: Vector3 = spot[1]
	if _camera_mode == CameraMode.FIELD:
		# A rundown pulls the camera in tight on the runner and the ball.
		var focus := _rundown_focus if _rundown_zoom else _field_focus
		var flat := Vector3(focus.x, 0.0, focus.z)
		if _rundown_zoom:
			goal *= 0.45
		else:
			# Pull back a little as the play goes deep.
			goal *= lerpf(0.85, 1.15, clampf(flat.length() / 100.0, 0.0, 1.0))
		goal += flat
		target += flat + Vector3.UP * clampf(focus.y, 0.0, 30.0) * 0.6
	_camera.position = _camera.position.lerp(goal, weight)
	if kick > 0.0:
		_camera.position += Vector3(_shake_rng.randf_range(-1, 1), _shake_rng.randf_range(-1, 1), 0.0) * 0.06 * kick
	var forward := -_camera.global_transform.basis.z
	var wanted := (target - _camera.position).normalized()
	var look := forward.slerp(wanted, weight)
	_camera.look_at(_camera.position + look, Vector3.UP)


func _update_bat() -> void:
	if not _bat_pivot.visible:
		return
	var batter: ActorView = _runners.get(_batter_id)
	if batter != null:
		var swinging := _bat_swing_start >= 0.0 or _bat_bunt
		batter.animate(ActorView.Pose.SWING if swinging else ActorView.Pose.BAT_STANCE, get_process_delta_time())
	var side := -1.0 if _bats_left else 1.0
	_bat_pivot.position = _batter_spot() + Vector3(0.3 * side, 1.0, 0.05)
	if batter != null:
		_bat_pivot.position = batter.grip_position()
	# Yaw 90 = barrel back toward the catcher, 0 = across the plate, -90 =
	# toward the pitcher. Elevation in degrees above level.
	var yaw := 100.0 + sin(_view_clock * 3.0) * 6.0  # stance with a waggle
	var lift := 50.0
	if _bat_bunt:
		yaw = 0.0  # held flat across the front of the plate
		lift = 6.0
		_bat_pivot.position += Vector3(0.0, -0.1, -0.35)
	elif _bat_swing_start >= 0.0:
		var p := clampf((_view_clock - _bat_swing_start) / SWING_TIME, 0.0, 1.0)
		var eased := p * p * (3.0 - 2.0 * p)
		yaw = lerpf(100.0, -170.0, eased)
		lift = lerpf(50.0, 5.0, minf(p * 2.0, 1.0)) if p < 0.5 else lerpf(5.0, 40.0, (p - 0.5) * 2.0)
	var y := deg_to_rad(yaw)
	var e := deg_to_rad(lift)
	var dir := Vector3(cos(e) * cos(y) * side, sin(e), cos(e) * sin(y))
	if batter != null:
		# The torso turns with the bat, about half as far.
		batter.set_twist((100.0 - yaw) * 0.5 * side)
	_bat_pivot.look_at(_bat_pivot.global_position + dir, Vector3.UP)


func _update_windup(delta: float) -> void:
	var pitcher := tuning.fielder_ids.find(&"p")
	if pitcher < 0 or _windup < 0.0:
		return
	var actor := _fielders[pitcher]
	actor.face(Vector3.ZERO)
	actor.animate(ActorView.Pose.THROW, delta, 0.0, false, _windup)
	_ball.position = actor.hand_position()
	_update_shadow()


func _build_aim_and_flash() -> void:
	_aim = Node3D.new()
	_aim.name = "AimPreview"
	add_child(_aim)
	_aim_shaft = MeshInstance3D.new()
	var shaft := BoxMesh.new()
	shaft.size = Vector3(0.35, 0.02, 1.0)
	_aim_shaft.mesh = shaft
	_aim_shaft.material_override = _unshaded(Color(1, 1, 1, 0.5))
	_aim.add_child(_aim_shaft)
	_aim_head = MeshInstance3D.new()
	var head := CylinderMesh.new()
	head.top_radius = 0.0
	head.bottom_radius = 1.0
	head.height = 2.4
	_aim_head.mesh = head
	_aim_head.rotation_degrees.x = -90.0  # point along -Z
	_aim_head.scale = Vector3(1.0, 1.0, 0.05)  # flat on the ground
	_aim_head.material_override = _unshaded(Color(1, 1, 1, 0.5))
	_aim.add_child(_aim_head)
	_aim.visible = false
	for i in 8:
		var ghost := _sphere(0.11, Color(1, 1, 1, 0.5), false)
		ghost.visible = false
		_trail.append(ghost)
	_flash = _sphere(1.0, Color(1, 1, 1, 0.8), false)
	_flash.visible = false
	_contact_sound = ContactSound.new()
	_contact_sound.name = "ContactSound"
	add_child(_contact_sound)
	sfx = Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)


func _build_bat() -> void:
	_bat_pivot = Node3D.new()
	_bat_pivot.name = "Bat"
	add_child(_bat_pivot)
	var bat := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06  # barrel
	cyl.bottom_radius = 0.025  # handle
	cyl.height = 0.95
	bat.mesh = cyl
	bat.rotation_degrees.x = -90.0  # lie along -Z, the pivot's facing
	bat.position = Vector3(0.0, 0.0, -0.475)  # handle at the pivot (the hands)
	bat.material_override = GrayboxField._mat(Color(0.82, 0.62, 0.36))
	_bat_pivot.add_child(bat)
	_timing_ring = _ring(Color(1, 1, 1, 0.8))
	_timing_ring.position = Vector3(0.0, (tuning.zone_top + tuning.zone_bottom) * 0.5, 0.04)
	_timing_ring.visible = false
	_zone.add_child(_timing_ring)


func _snap_camera() -> void:
	var spot: Array = CAMERA_SPOTS[_camera_mode]
	_camera.position = spot[0]
	_camera.look_at(spot[1], Vector3.UP)


func _cutoff_fielder(target: int, fielding: FieldingResult) -> int:
	var side := 0 if fielding.secure_point.x < 0.0 else 1
	var options: Array = CUTOFF_PREFERENCE.get(target, [&"ss", &"2b"])
	for id: StringName in [options[side], options[1 - side], &"p"]:
		var i := tuning.fielder_ids.find(id)
		if i >= 0 and i != fielding.fielder_index:
			return i
	return -1


## Which fielder covers each base this play: {base: fielder_index}.
func _cover_assignments(fielder_index: int, cutoff: int = -1) -> Dictionary:
	var covers := {}
	var used := {fielder_index: true, cutoff: true}
	for base in [1, 2, 3, 4]:
		for id: StringName in COVER_PREFERENCE[base]:
			var i := tuning.fielder_ids.find(id)
			if i >= 0 and not used.has(i):
				covers[base] = i
				used[i] = true
				break
	return covers


## Highlights the base a directional throw would go to (0 hides it).
func set_throw_target(base: int) -> void:
	_throw_target.visible = base > 0
	if base > 0:
		_throw_target.position = FieldLayout.base_position(base) + Vector3.UP * 0.06
		_throw_target.scale = Vector3.ONE * (1.6 + 0.15 * sin(_view_clock * 10.0))


func set_roster(roster: MatchRoster) -> void:
	_roster = roster
	var home := roster.teams[MatchState.HOME]
	if _stadium != null:
		_stadium.queue_free()
		_stadium = null
	if home.stadium_def != null:
		_stadium = Stadium.new()
		_stadium.name = "Stadium"
		add_child(_stadium)
		_stadium.build(tuning, home.stadium_def, home, roster.teams[MatchState.AWAY])


## The crowd reacts to a moment (0..1): the roar and the fans jumping.
func cheer(level: float) -> void:
	sfx.cheer(level)
	if _stadium != null:
		_stadium.cheer(level)


func update_scoreboard(state: MatchState) -> void:
	if _stadium != null:
		_stadium.update_scoreboard(state, _roster)


func _batter_spot() -> Vector3:
	return Vector3(-BATTER_SPOT.x, BATTER_SPOT.y, BATTER_SPOT.z) if _bats_left else BATTER_SPOT


## Jersey number over a fielder (position code without a roster).
func _fielder_tag(state: MatchState, position: StringName) -> String:
	if _roster == null:
		return String(position).to_upper()
	var p := _roster.player(state.defense[state.fielding_team()].get(position, &""))
	return "#%d" % p.number if p != null else String(position).to_upper()


func _runner_actor(id: StringName, color: Color, trim: Color = Color(0, 0, 0, 0)) -> ActorView:
	var actor := ActorView.new()
	add_child(actor)
	var p := _roster.player(id) if _roster != null else null
	actor.setup(color, String(id).get_slice("_", 1))
	actor.set_glove_visible(false)
	if p != null:
		actor.set_look(color, "#%d %s" % [p.number, p.display_name.to_upper()], trim)
	elif trim.a > 0.0:
		actor.set_look(color, String(id).get_slice("_", 1), trim)
	_runners[id] = actor
	return actor


func _clear_runners() -> void:
	for actor in _runners.values():
		actor.queue_free()
	_runners.clear()


func _update_shadow() -> void:
	_ball_shadow.position = Vector3(_ball.position.x, 0.03, _ball.position.z)
	# Readability: the ball grows with camera distance (presentation only).
	if _camera != null:
		var grow := clampf(_camera.position.distance_to(_ball.position) / 14.0, 1.0, 5.0)
		_ball.scale = Vector3.ONE * grow
		_ball_shadow.scale = Vector3(grow, 1.0, grow)


func _build_zone() -> void:
	_zone = Node3D.new()
	_zone.name = "StrikeZone"
	add_child(_zone)
	var w := tuning.zone_half_width * 2.0
	var h := tuning.zone_top - tuning.zone_bottom
	var mid_y := (tuning.zone_top + tuning.zone_bottom) * 0.5
	var color := Color(1, 1, 1, 0.55)
	for spec in [
		[Vector3(w, 0.015, 0.01), Vector3(0, tuning.zone_top, 0)],
		[Vector3(w, 0.015, 0.01), Vector3(0, tuning.zone_bottom, 0)],
		[Vector3(0.015, h, 0.01), Vector3(-w * 0.5, mid_y, 0)],
		[Vector3(0.015, h, 0.01), Vector3(w * 0.5, mid_y, 0)],
	]:
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = spec[0]
		bar.mesh = box
		bar.position = spec[1]
		bar.material_override = _unshaded(color)
		_zone.add_child(bar)
	_control_ring = _ring(Color(1.0, 0.85, 0.2))
	_control_ring.rotation_degrees.x = 0.0
	_control_ring.scale = Vector3.ONE * 1.1
	_control_ring.visible = false
	add_child(_control_ring)
	_landing_hint = _ring(Color(1.0, 1.0, 1.0, 0.7))
	_landing_hint.rotation_degrees.x = 0.0
	_landing_hint.scale = Vector3.ONE * tuning.catch_reach * 1.5
	_landing_hint.visible = false
	add_child(_landing_hint)
	_throw_target = _ring(Color(0.3, 1.0, 0.45, 0.9))
	_throw_target.rotation_degrees.x = 0.0
	_throw_target.scale = Vector3.ONE * 1.6
	_throw_target.visible = false
	add_child(_throw_target)
	_cursor = _ring(Color(1.0, 0.85, 0.2))
	_cursor_inner = _ring(Color(1.0, 0.95, 0.6))
	_zone.add_child(_cursor)
	_zone.add_child(_cursor_inner)


func _build_debug() -> void:
	_debug_root = Node3D.new()
	_debug_root.name = "DebugDraw"
	add_child(_debug_root)
	_trajectory_line = MeshInstance3D.new()
	_trajectory_line.material_override = _unshaded(Color(1.0, 0.3, 0.9))
	_debug_root.add_child(_trajectory_line)
	_landing_marker = _disc(1.2, Color(1.0, 0.25, 0.25, 0.8))
	_intercept_marker = _disc(0.9, Color(1.0, 0.9, 0.1, 0.8))
	_pitch_marker = _sphere(0.04, Color(0.2, 1.0, 1.0), false)
	for node in [_landing_marker, _intercept_marker, _pitch_marker]:
		node.reparent(_debug_root)
	clear_debug_play()
	_pitch_marker.visible = false


func _ring(color: Color) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	ring.mesh = torus
	ring.rotation_degrees.x = 90.0
	ring.material_override = _unshaded(color)
	return ring


func _sphere(radius: float, color: Color, shaded: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mi.mesh = sphere
	mi.material_override = GrayboxField._mat(color) if shaded else _unshaded(color)
	add_child(mi)
	return mi


func _disc(radius: float, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.02
	mi.mesh = cyl
	mi.material_override = _unshaded(color)
	add_child(mi)
	return mi


static func _unshaded(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
