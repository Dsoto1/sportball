class_name MatchView
extends Node3D
## Presents authoritative match data. Every position here is sampled from
## resolver output (PitchResult, BallTrajectory, FieldingResult, RunnerPlan,
## PlayOutcome); nothing in this node decides a baseball outcome.

enum CameraMode { BAT, PITCH, FIELD, FLIGHT }

const AWAY_COLOR := Color(0.85, 0.22, 0.2)
const HOME_COLOR := Color(0.18, 0.42, 0.9)
## Where a right-handed batter stands (his hips), from Statcast's stance
## tracking: 27 in off the plate's inside edge and 28 in behind its front.
const BATTER_SPOT := Vector3(-0.91, 0.0, 0.49)
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
## The long-ball camera: a deep fly or a home run, followed from the bat
## to where it comes down (into the seats for a homer), then the trot.
var _flight: BallTrajectory
var _flight_hr := false
## A foul ball's flight: into the seats or onto the foul ground.
var _flight_foul := false
var _flight_t := 0.0
## Hand back to the field camera at this play time (a catch or a bounce).
var _flight_until := INF
## Where and when a homer comes down (seats or ground), presentation time.
var _flight_land_t := INF
var _flight_land := Vector3.ZERO
var _flight_cheered := false
var _flight_shot := -1
## What the video board celebrates when a homer lands.
var _flight_moment := {}
## The long ball's comet tail (recent positions) and the burst where a
## homer lands.
var _flight_tail: Array[MeshInstance3D] = []
var _flight_burst: CPUParticles3D
## Fired when a home run lands in the stands (the board's cue).
signal home_run_landed(distance_ft: int)
## Seconds a swing takes to come through the zone and follow through.
## The swing from the press: the barrel reaches the ball
## BattingStyles.CONTACT_AT into it (60 ms), the rest is follow-through.
const SWING_TIME := 0.3
## Frames of the barrel's swoosh.
const TRAIL_LENGTH := 10
## Hands apart on the handle (m): together to swing, spread to bunt.
const SWING_GRIP := 0.09
const BUNT_GRIP := 0.3
const BALL_SHADER := preload("res://presentation/props/baseball.gdshader")
## How fast the ball tumbles (radians per meter travelled), so its seams spin.
const BALL_SPIN := 9.0
const BALL_RADIUS := 0.045
## The ball is drawn at least this many degrees across (readability), so it
## grows with distance from the camera (up to BALL_MAX_SCALE).
const BALL_MIN_DEGREES := 0.32
const BALL_MAX_SCALE := 3.5
## Pitcher's follow-through after release (s), and the windup progress
## where his hands break and the ball leaves the glove.
const FOLLOW_TIME := 0.45
const HANDS_BREAK := 0.55
var _bat_pivot: Node3D
var _bat_swing_start := -1.0
var _bat_bunt := false
## Approach clock 0..1 (stance, load, stride), and the pitch's flight
## progress driving it (-1 when no pitch is in the air).
var _approach := 0.0
var _pitch_u := -1.0
## Bat (yaw, lift) this frame, and where the swing started from.
var _bat_now := Vector2(100, 50)
var _swing_from := Vector2(100, 50)
var _contact_tier := 0
## The batter's swing signature (PlayerSwing) and this swing's bat speed.
var _swing_profile: Dictionary = {}
var _swing_mph := 72.0
var _trail_mesh: ImmediateMesh
var _trail_points: Array = []
var _trail_color := Color(1, 1, 1, 0.55)
var _tossing := false
var _toss_velocity := Vector3.ZERO
var _toss_spin := Vector3.ZERO
var _view_clock := 0.0
var _timing_ring: MeshInstance3D
var _windup := -1.0
## View clock when the pitcher let go (his follow-through), or -1.
var _follow_start := -1.0
var _last_ball_position := Vector3.ZERO
## [axis, rate] while a pitch is in flight (its own spin), else empty.
var _pitch_spin: Array = []
## Whether the batting side is the home club (home whites, road grays).
var _batting_home := false
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
	# Never this close to anything; the depth buffer keeps the layered
	# field (grass, dirt, chalk a few cm apart) clean out to the stands.
	_camera.near = 0.25
	add_child(_camera)
	_camera.current = true
	_snap_camera()
	# Close to a real ball (3.7 cm radius); _update_shadow grows it with
	# distance from the camera so it stays readable far off, never huge.
	_ball = _sphere(BALL_RADIUS, Color(1, 1, 1), true)
	var ball_mat := ShaderMaterial.new()
	ball_mat.shader = BALL_SHADER
	_ball.material_override = ball_mat
	_ball_shadow = _disc(0.07, Color(0, 0, 0, 0.45))
	for id in tuning.fielder_ids:
		var actor := ActorView.new()
		add_child(actor)
		actor.setup(HOME_COLOR, String(id).to_upper())
		_fielders.append(actor)
	_build_zone()
	_build_bat()
	_build_aim_and_flash()
	_build_debug()


const CAMERA_FOV := {CameraMode.BAT: 34.0, CameraMode.PITCH: 50.0, CameraMode.FIELD: 55.0, CameraMode.FLIGHT: 50.0}


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
## Follows a long ball with the flight camera: from behind the plate as it
## leaves the bat, chasing it out over the field, and for a home run a cut
## to the wall to watch it drop into the crowd, then the trot from up high.
## A non-homer hands back to the field camera at `until` (catch, bounce).
func start_flight(traj: BallTrajectory, home_run: bool, until: float = INF, moment: Dictionary = {}) -> void:
	_flight = traj
	_flight_moment = moment
	_flight_hr = home_run
	_flight_t = 0.0
	_flight_until = until
	_flight_cheered = false
	_flight_shot = -1
	_flight_land_t = INF
	_flight_foul = false
	if home_run:
		# Where it comes down: the first seat row (or ground) under it.
		var t := traj.end_time()
		var stop := traj.end_time() + traj.tail_points.size() * traj.step
		while t < stop:
			t += traj.step * 0.5
			var p := traj.flight_position(t)
			var floor_h := _stadium.surface_height(p) if _stadium != null else 0.0
			if p.y <= floor_h:
				_flight_land_t = t
				_flight_land = Vector3(p.x, floor_h, p.z)
				break
		if _flight_land_t == INF:
			_flight_land_t = stop
			_flight_land = traj.flight_position(stop)
	_build_flight_fx()
	for ghost in _flight_tail:
		ghost.visible = false
	set_camera_mode(CameraMode.FLIGHT)


## A foul ball off the bat: followed until it comes down in the stands (a
## ripple through the crowd) or on the foul ground.
func start_foul(traj: BallTrajectory) -> void:
	start_flight(traj, false)
	_flight_foul = true
	_flight_until = INF
	var t := 0.0
	var stop := traj.end_time()
	_flight_land_t = stop
	_flight_land = traj.flight_position(stop)
	while t < stop:
		t += traj.step * 0.5
		var p := traj.flight_position(t)
		var floor_h := _stadium.surface_height(p) if _stadium != null else 0.0
		if t > 0.3 and p.y <= floor_h:
			_flight_land_t = t
			_flight_land = Vector3(p.x, floor_h, p.z)
			break
	_ball.visible = true


## When a foul ball's show is over (it landed a moment ago).
func foul_done_at() -> float:
	return _flight_land_t + 1.2


func _build_flight_fx() -> void:
	if not _flight_tail.is_empty():
		return
	for i in 14:
		var ghost := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.07 * (1.0 - i / 16.0)
		s.height = s.radius * 2.0
		s.radial_segments = 8
		s.rings = 4
		ghost.mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(1.0, 0.95, 0.8, 0.55 * (1.0 - i / 14.0))
		ghost.material_override = m
		ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ghost.visible = false
		add_child(ghost)
		_flight_tail.append(ghost)
	_flight_burst = CPUParticles3D.new()
	_flight_burst.emitting = false
	_flight_burst.one_shot = true
	_flight_burst.amount = 60
	_flight_burst.lifetime = 1.6
	_flight_burst.explosiveness = 0.95
	_flight_burst.direction = Vector3.UP
	_flight_burst.spread = 70.0
	_flight_burst.initial_velocity_min = 4.0
	_flight_burst.initial_velocity_max = 9.0
	_flight_burst.gravity = Vector3(0, -6, 0)
	_flight_burst.scale_amount_min = 0.15
	_flight_burst.scale_amount_max = 0.35
	var bit := BoxMesh.new()
	bit.size = Vector3(0.6, 0.6, 0.08)
	_flight_burst.mesh = bit
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flight_burst.material_override = bm
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.3))
	ramp.set_color(1, Color(1.0, 1.0, 1.0))
	_flight_burst.color_initial_ramp = ramp
	add_child(_flight_burst)


## Advances the long-ball camera to play time `t`: the ball (a homer flies
## on into the seats), the crowd going up as it lands, and the hand-back to
## the field camera for anything else.
func step_flight(t: float) -> void:
	_flight_t = t
	# The comet tail, gone once the ball comes down.
	var airborne := t < (_flight_land_t if (_flight_hr or _flight_foul) else _flight.first_bounce_time)
	for i in _flight_tail.size():
		var ghost := _flight_tail[i]
		var at := t - (i + 1) * 0.035
		ghost.visible = airborne and at > 0.05
		ghost.position = flight_ball(at)
	if _flight_hr:
		_ball.position = flight_ball(t)
		if t >= _flight_land_t and not _flight_cheered:
			_flight_cheered = true
			_flight_burst.position = _flight_land + Vector3.UP * 0.5
			_flight_burst.restart()
			cheer(1.0)
			var moment := _flight_moment.duplicate()
			moment["distance"] = roundi(_flight.projected_distance() * 3.28084)
			board_moment(&"home_run", moment)
			home_run_landed.emit(roundi(_flight.projected_distance() * 3.28084))
	elif _flight_foul:
		_ball.position = flight_ball(t)
		if t >= _flight_land_t and not _flight_cheered:
			_flight_cheered = true
			# In the seats: the fans there go up for a souvenir.
			if _flight_land.y > 0.5:
				cheer(0.4)
	elif t >= _flight_until:
		for ghost in _flight_tail:
			ghost.visible = false
		set_camera_mode(CameraMode.FIELD)


## The middle of the park's video board (straightaway center if none).
func _board_spot() -> Vector3:
	var board: Node3D = _stadium.find_child("Centerpiece", false, false) if _stadium != null else null
	return board.global_position if board != null else Vector3(0, 25, -130)


## Where the ball is drawn on a flight: a homer stops in the seats.
func flight_ball(t: float) -> Vector3:
	if _flight == null:
		return Vector3.ZERO
	if (_flight_hr or _flight_foul) and t >= _flight_land_t:
		return _flight_land + Vector3.UP * 0.12
	return _flight.flight_position(t)


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
		_fielders[i].set_look(fielding_color, _fielder_tag(state, tuning.fielder_ids[i]), fielding_trim, state.fielding_team() == MatchState.HOME)
		var fielder_id: StringName = state.defense[state.fielding_team()].get(tuning.fielder_ids[i], &"") if _roster != null else &""
		var fielder_def := _roster.player(fielder_id) if fielder_id != &"" else null
		_fielders[i].set_player(String(fielder_id) if fielder_def != null else String(tuning.fielder_ids[i]), fielder_def.number if fielder_def != null else -1)
		_fielders[i].position = FieldLayout.fielder_spot(i, tuning)
		_fielders[i].face(Vector3.ZERO)
		_fielders[i].set_crouch(tuning.fielder_ids[i] == &"c")
	_clear_runners()
	_batting_home = state.batting_team() == MatchState.HOME
	var batter := _runner_actor(state.current_batter(), batting_color, batting_trim)
	_batter_id = state.current_batter()
	batter.set_tag_visible(_camera_mode != CameraMode.BAT)
	var hitter := _roster.player(state.current_batter()) if _roster != null else null
	_bats_left = hitter != null and hitter.bats_left()
	batter.set_lefty(_bats_left)
	# The bat's grip tape is the batting club's second color.
	var tape := batting_trim if batting_trim.a > 0.0 else batting_color.darkened(0.4)
	(_bat_pivot.get_node("BatMesh").material_override as ShaderMaterial).set_shader_parameter("tape", tape)
	var pitcher_index := tuning.fielder_ids.find(&"p")
	var pitcher_def := _roster.player(state.pitcher(state.fielding_team())) if _roster != null else null
	if pitcher_index >= 0:
		_fielders[pitcher_index].set_lefty(pitcher_def != null and pitcher_def.throws == &"L")
	batter.position = _batter_spot()
	batter.face(batter.position + (Vector3.LEFT if _bats_left else Vector3.RIGHT))  # square to the plate
	set_bat(true)
	_pitch_u = -1.0
	_contact_tier = 0
	batter.style = BattingStyles.for_player(hitter)
	_swing_profile = PlayerSwing.for_player(hitter, batter.style)
	set_aim_preview(false)
	_windup = -1.0
	_follow_start = -1.0
	_pitch_spin = []
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
	_tossing = false
	_approach = 0.0
	_trail_points.clear()
	if not visible_now:
		_drop_bat()
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
		actor.animate(ActorView.Pose.LEAD, get_process_delta_time())


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
	_contact_tier = tier
	if tier < ContactFeedback.Tier.SOLID:
		return
	# The swoosh lights up on a barreled ball.
	_trail_color = Color(1.0, 0.85, 0.3, 0.9) if tier == ContactFeedback.Tier.SWEET else Color(1, 1, 1, 0.75)
	# Camera punch: a quick zoom-in kick and shake, bigger on the barrel.
	_punch_start = _view_clock
	_punch_strength = 1.0 if tier == ContactFeedback.Tier.SWEET else 0.5
	_flash.position = Vector3(location.x, location.y, 0.1)
	_flash_size = 0.9 if tier == ContactFeedback.Tier.SWEET else 0.45
	var color := Color(1.0, 0.9, 0.3, 0.9) if tier == ContactFeedback.Tier.SWEET else Color(1, 1, 1, 0.8)
	(_flash.material_override as StandardMaterial3D).albedo_color = color
	_flash_start = _view_clock


## Plays the swing (on contact and on a miss alike): from his stride, the
## barrel reaches the zone CONTACT_AT into it, right on the press.
func swing_bat(power: bool = false) -> void:
	_bat_swing_start = _view_clock
	_swing_from = _bat_now
	_swing_mph = PlayerSwing.swing_speed(_swing_profile, power) if not _swing_profile.is_empty() else PlayerSwing.LEAGUE_BAT_SPEED
	_trail_color = Color(1, 1, 1, 0.55)


## Pitcher's windup, 0..1, or -1 when not winding up. The ball sits in his
## glove until the pitch is released.
func show_windup(progress: float) -> void:
	if progress < 0.0 and _windup >= 0.0:
		_follow_start = _view_clock
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
func show_pitch(pitch: PitchResult, t: float, tell_color: Color = Color.WHITE, tell_trail: int = 0, family: PitchFamilyDef = null) -> void:
	_pitch_u = t / maxf(pitch.travel_time, 0.01)
	_pitch_spin = PitchSpin.for_family(family) if family != null else []
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
	if _bat_pivot.visible and not _tossing:
		_toss_bat()
	_aim.visible = false
	for ghost in _trail:
		ghost.visible = false
	_timing_ring.visible = false
	_windup = -1.0
	_follow_start = -1.0
	_pitch_spin = []
	var fielding := bip.fielding
	var secured := play != null and play.ball != LivePlay.Ball.LOOSE
	_ball.position = play.ball_position() if play != null else bip.trajectory.position_at(t)
	if _camera_mode == CameraMode.FLIGHT and _flight == bip.trajectory:
		step_flight(t)
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
	var backup := _backup_fielder(fielding)
	for i in _fielders.size():
		var start := FieldLayout.fielder_spot(i, tuning)
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
		elif i == backup:
			# The nearest other outfielder backs up the play, behind it.
			var behind := Vector3(fielding.secure_point.x, 0.0, fielding.secure_point.z)
			behind += Vector3(behind.x, 0.0, behind.z).normalized() * 9.0
			actor.position = start.move_toward(behind, since * tuning.fielder_speed)
			actor.face(_ball.position)
		else:
			# Not his ball: a few ready steps toward the play, then hold.
			var drift := Vector3(_ball.position.x, 0.0, _ball.position.z)
			actor.position = start.move_toward(drift, minf(since * tuning.fielder_speed * 0.5, 2.5))
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
		var catch_pose := PlayAnimator.catch_pose(play.time, fielding) if i == fielding.fielder_index else -1
		if i == thrower:
			actor.animate(ActorView.Pose.THROW, delta, 0.0, false, _animator.thrower_progress)
		elif catch_pose >= 0:
			actor.animate(catch_pose, delta)
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
	_spin_ball()
	if _camera_mode == CameraMode.FLIGHT and _flight != null:
		_flight_camera(delta, kick)
		return
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


## The long-ball shots. 0 rise: from behind and above the plate as it leaves
## the bat. 1 chase: trailing it out over the field, leading it a little.
## For a homer, 2 the wall: a cut to the warning track to watch it sail
## over the wall into the crowd, held while they celebrate; 3 the trot: up
## high behind first base looking over the diamond.
func _flight_camera(delta: float, kick: float) -> void:
	var t := _flight_t
	var ball := flight_ball(t)
	var aim := _flight_land if (_flight_hr or _flight_foul) else _flight.landing_point
	var dir := Vector3(aim.x, 0.0, aim.z).normalized()
	if dir.length() < 0.5:
		dir = Vector3(0, 0, -1)
	var side := dir.cross(Vector3.UP).normalized()
	var shot := 0
	var wall_cut := (_flight.fence_time if _flight.fence_time != INF else _flight.end_time()) - 0.9
	if t > 0.45:
		shot = 1
	if _flight_hr and t > wall_cut:
		shot = 2
	if _flight_hr and t > _flight_land_t + 2.2:
		shot = 3
	var goal: Vector3
	var look: Vector3
	var fov := 50.0
	match shot:
		0:
			goal = Vector3(0, 0, 0) - dir * 9.0 + Vector3.UP * 5.0 + side * 1.5
			look = ball
			fov = 46.0
		1:
			var flat := Vector3(ball.x, 0.0, ball.z)
			goal = flat - dir * 26.0 + side * 6.0 + Vector3.UP * (ball.y * 0.55 + 7.0)
			look = ball + dir * 10.0
			fov = 52.0
		2:
			# From short of the wall and off to one side, looking up past it
			# to where the ball comes down, the big screen in the frame.
			var wall := dir * FieldLayout.fence_distance(FieldLayout.spray_angle_of(dir), tuning)
			var falling := (ball if t < _flight_land_t else _flight_land).lerp(_flight_land, 0.5)
			goal = wall - dir * 58.0 + side * 10.0 + Vector3.UP * 4.0
			look = falling.lerp(_board_spot(), 0.45) + Vector3.UP * 2.0
			fov = 56.0
		3:
			goal = Vector3(26.0, 20.0, 16.0)
			look = Vector3(-4.0, 0.0, -16.0)
			fov = 50.0
	if _flight_foul and t > 0.35:
		# A foul: from beside the plate, high, panning after it into the
		# seats (or back over the screen).
		shot = 4
		goal = Vector3(0, 0, 0) - dir * 6.0 + side * 9.0 + Vector3.UP * 7.0
		look = ball.lerp(_flight_land, 0.35)
		fov = 58.0
	var weight := 1.0 - exp(-delta * (2.5 if shot == 1 or shot == 4 else 5.0))
	if shot != _flight_shot:
		# A cut, not a pan: each shot starts framed.
		weight = 1.0
		_flight_shot = shot
		_camera.fov = fov
	_camera.fov = lerpf(_camera.fov, fov - 5.0 * kick, 1.0 - exp(-delta * 4.0))
	_camera.position = _camera.position.lerp(goal, weight)
	var forward := -_camera.global_transform.basis.z
	var wanted := (look - _camera.position).normalized()
	_camera.look_at(_camera.position + (wanted if weight >= 1.0 else forward.slerp(wanted, 1.0 - exp(-delta * 8.0))), Vector3.UP)


## Tumbles the ball about the axis across its travel, so its seams spin in
## flight and roll on the ground.
func _spin_ball() -> void:
	var moved := _ball.position - _last_ball_position
	_last_ball_position = _ball.position
	var distance := moved.length()
	if distance < 0.001 or distance > 5.0:
		return
	if not _pitch_spin.is_empty():
		# A pitch keeps the spin its family puts on it.
		_ball.rotate(_pitch_spin[0], _pitch_spin[1] * get_process_delta_time())
		return
	var axis := moved.cross(Vector3.UP)
	if axis.length() < 0.0001:
		axis = Vector3.RIGHT
	_ball.rotate(axis.normalized(), -distance * BALL_SPIN)


## The batter lets go of the bat (he runs, or the bat is put away).
func _drop_bat() -> void:
	var batter: ActorView = _runners.get(_batter_id)
	if batter != null:
		batter.grip_bat(null)


func _update_bat() -> void:
	if _tossing:
		_update_toss(get_process_delta_time())
		return
	if not _bat_pivot.visible:
		return
	var batter: ActorView = _runners.get(_batter_id)
	var delta := get_process_delta_time()
	var style: StringName = batter.style if batter != null else &"classic"
	var side := -1.0 if _bats_left else 1.0
	# The approach: he loads as the pitcher delivers and strides as the ball
	# comes, then holds, cocked. A take lets it go and settles back.
	var target := 0.0
	if _windup >= 0.0:
		target = BattingStyles.LOAD_AT * smoothstep(0.35, 1.0, _windup)
	elif _pitch_u >= 0.0:
		target = lerpf(BattingStyles.LOAD_AT, 1.0, clampf(_pitch_u / 0.5, 0.0, 1.0))
		if _pitch_u >= 1.0 and _bat_swing_start < 0.0:
			target = 0.0
	_approach = move_toward(_approach, target, delta * (6.0 if target > _approach else 2.5))
	var bat := BattingStyles.approach_bat(style, _approach, _view_clock)
	var gap := SWING_GRIP
	var one_hand := false
	if _bat_bunt:
		bat = Vector2(0.0, 6.0)  # flat across the front of the plate
		gap = BUNT_GRIP
		if batter != null:
			batter.animate(ActorView.Pose.BUNT, delta)
	elif _bat_swing_start >= 0.0:
		var p := _swing_progress()
		bat = BattingStyles.swing_bat(style, p, _swing_from, _swing_profile)
		one_hand = bool(BattingStyles.BAT[style]["one_hand"]) and p > BattingStyles.ONE_HAND_RELEASE
		if batter != null:
			batter.animate(ActorView.Pose.SWING, delta, 0.0, false, p)
	elif batter != null:
		if _approach > 0.001:
			batter.animate(ActorView.Pose.APPROACH, delta, 0.0, false, _approach)
		else:
			batter.animate(ActorView.Pose.BAT_STANCE, delta)
	_bat_now = bat
	# Yaw 90 = barrel back toward the catcher, 0 = across the plate, -90 =
	# toward the pitcher. Lift in degrees above level.
	var y := deg_to_rad(bat.x)
	var e := deg_to_rad(bat.y)
	var dir := Vector3(cos(e) * cos(y) * side, sin(e), cos(e) * sin(y))
	if batter != null:
		# His hands hold the handle; the grip places the bat.
		batter.grip_bat(_bat_pivot, dir, gap, one_hand, float(BattingStyles.BAT[style]["choke"]))
	else:
		_bat_pivot.position = _batter_spot() + Vector3(0.3 * side, 1.0, 0.05)
		_bat_pivot.look_at(_bat_pivot.global_position + dir, Vector3.UP)
	_update_trail()


## Swing clock (0..1): contact always lands CONTACT_AT in, on the press's
## timing; after it a faster bat whips through the follow-through sooner.
func _swing_progress() -> float:
	var t := _view_clock - _bat_swing_start
	var at := SWING_TIME * BattingStyles.CONTACT_AT
	if t <= at:
		return t / SWING_TIME
	return BattingStyles.CONTACT_AT + (t - at) / SWING_TIME * (_swing_mph / PlayerSwing.LEAGUE_BAT_SPEED)


## The last swing in Statcast terms: {bat_speed mph, attack_angle deg}.
func swing_readout() -> Dictionary:
	if _swing_profile.is_empty():
		return {}
	return {"bat_speed": _swing_mph, "attack_angle": float(_swing_profile["attack_lift"])}


## The barrel's swoosh: a ribbon through the last few spots of the bat,
## from just above the hands to the end of the barrel, fading behind.
func _update_trail() -> void:
	var swinging := _bat_swing_start >= 0.0 and _view_clock - _bat_swing_start < SWING_TIME * 0.75
	var tip := _bat_pivot.global_transform * Vector3(0, 0, -BatMesh.LENGTH + 0.06)
	var mid := _bat_pivot.global_transform * Vector3(0, 0, -0.45)
	if swinging:
		_trail_points.push_front([mid, tip])
		if _trail_points.size() > TRAIL_LENGTH:
			_trail_points.pop_back()
	elif not _trail_points.is_empty():
		_trail_points.pop_back()
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in _trail_points.size():
		var fade := 1.0 - float(i) / _trail_points.size()
		var c := Color(_trail_color, _trail_color.a * fade)
		_trail_mesh.surface_set_color(Color(c, 0.0))
		_trail_mesh.surface_add_vertex(_trail_points[i][0])
		_trail_mesh.surface_set_color(c)
		_trail_mesh.surface_add_vertex(_trail_points[i][1])
	_trail_mesh.surface_end()


## The bat leaves his hands when the ball is put in play: tossed aside on
## most hits, flipped high on one he barreled.
func _toss_bat() -> void:
	var batter: ActorView = _runners.get(_batter_id)
	_drop_bat()
	_tossing = true
	var side := -1.0 if _bats_left else 1.0
	var big := _contact_tier >= ContactFeedback.Tier.SWEET
	# Toward the first-base side for a righty, high and spinning for a flip.
	_toss_velocity = Vector3(side * (1.2 if big else 2.4), 5.5 if big else 1.6, 0.9 if big else 0.4)
	_toss_spin = Vector3(side * (14.0 if big else 4.0), 2.0, 3.0 if big else 1.0)
	if batter == null:
		_tossing = false
		_bat_pivot.visible = false


func _update_toss(delta: float) -> void:
	_toss_velocity.y -= 9.8 * delta
	var p := _bat_pivot.global_position + _toss_velocity * delta
	if p.y < 0.06:
		p.y = 0.06
		# A dead bounce, then it lies still on the dirt.
		_toss_velocity = Vector3(_toss_velocity.x * 0.4, absf(_toss_velocity.y) * 0.25, _toss_velocity.z * 0.4)
		_toss_spin *= 0.4
		if _toss_velocity.length() < 0.4:
			_toss_velocity = Vector3.ZERO
			_toss_spin = Vector3.ZERO
			var flat := _bat_pivot.global_transform.basis.z
			flat.y = 0.0
			if flat.length() > 0.01:
				_bat_pivot.look_at(p - flat, Vector3.UP)
	_bat_pivot.global_position = p
	if _toss_spin.length() > 0.0:
		_bat_pivot.rotate(_toss_spin.normalized(), _toss_spin.length() * delta)
	_update_trail()


func _update_windup(delta: float) -> void:
	var pitcher := tuning.fielder_ids.find(&"p")
	if pitcher < 0:
		return
	var actor := _fielders[pitcher]
	if _windup < 0.0:
		# After the release: the arm sweeps through and he lands ready.
		if _follow_start < 0.0:
			return
		var u := (_view_clock - _follow_start) / FOLLOW_TIME
		if u >= 1.0:
			_follow_start = -1.0
			return
		actor.animate(ActorView.Pose.PITCH, delta, 0.0, false, lerpf(BaseballMoves.PITCH_RELEASE, BaseballMoves.PITCH_LENGTH, u))
		return
	actor.face(Vector3.ZERO)
	actor.animate(ActorView.Pose.PITCH, delta, 0.0, false, _windup)
	# The ball sits in the glove until his hands break.
	_ball.position = actor.grip_position() if _windup > HANDS_BREAK else actor.hand_position()
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
		var ghost := _sphere(BALL_RADIUS, Color(1, 1, 1, 0.5), false)
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
	bat.name = "BatMesh"
	bat.mesh = BatMesh.build()  # along -Z, the pivot's facing
	# The hands grip a little above the knob.
	bat.position = Vector3(0.0, 0.0, 0.06)
	bat.material_override = BatMesh.material()
	_bat_pivot.add_child(bat)
	var trail := MeshInstance3D.new()
	trail.name = "BatTrail"
	_trail_mesh = ImmediateMesh.new()
	trail.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	trail_mat.vertex_color_use_as_albedo = true
	trail_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	trail.material_override = trail_mat
	trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(trail)
	_timing_ring = _ring(Color(1, 1, 1, 0.8))
	_timing_ring.position = Vector3(0.0, (tuning.zone_top + tuning.zone_bottom) * 0.5, 0.04)
	_timing_ring.visible = false
	_zone.add_child(_timing_ring)


func _snap_camera() -> void:
	var spot: Array = CAMERA_SPOTS[_camera_mode]
	_camera.position = spot[0]
	_camera.look_at(spot[1], Vector3.UP)


## The outfielder who backs up a ball hit to the outfield: the nearest
## other outfielder to where it's fielded (-1 for a ball in the infield).
func _backup_fielder(fielding: FieldingResult) -> int:
	var at := Vector3(fielding.secure_point.x, 0.0, fielding.secure_point.z)
	if at.length() < 45.0:
		return -1
	var best := -1
	var best_d := INF
	for id: StringName in [&"lf", &"cf", &"rf"]:
		var i := tuning.fielder_ids.find(id)
		if i < 0 or i == fielding.fielder_index:
			continue
		var d := FieldLayout.fielder_spot(i, tuning).distance_to(at)
		if d < best_d:
			best = i
			best_d = d
	return best


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


## Rebuilds the field and the park around it for a venue. p_tuning carries
## the park's walls (its field shape); the view draws from it from now on.
func set_park(p_tuning: BaseballTuning, park: StadiumDef) -> void:
	tuning = p_tuning
	_field.build(tuning, park)
	if _stadium != null:
		_stadium.queue_free()
		_stadium = null
	if park != null and _roster != null:
		_stadium = Stadium.new()
		_stadium.name = "Stadium"
		add_child(_stadium)
		_stadium.build(tuning, park, _roster.teams[MatchState.HOME], _roster.teams[MatchState.AWAY])


## The crowd reacts to a moment (0..1): the roar and the fans jumping.
## Takes the park's video board over for a celebration.
func board_moment(kind: StringName, data: Dictionary = {}) -> void:
	if _stadium != null:
		_stadium.board_moment(kind, data)


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
		actor.set_look(color, "#%d %s" % [p.number, p.display_name.to_upper()], trim, _batting_home)
	else:
		actor.set_look(color, String(id).get_slice("_", 1), trim, _batting_home)
	actor.set_player(String(id), p.number if p != null else -1)
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
		var wanted := deg_to_rad(BALL_MIN_DEGREES) * _camera.position.distance_to(_ball.position) * 0.5 / BALL_RADIUS
		var grow := clampf(wanted, 1.0, BALL_MAX_SCALE)
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
