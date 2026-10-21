class_name PlayAnimator
extends RefCounted
## Reads a LivePlay every frame and decides how each body should look:
## runs, stop-and-turns, rundown jukes, chases, tag swipes, throws, slides,
## and runners going down when they are out. Presentation only: nothing
## here feeds back into the play. Pure (no nodes), so it can be tested.

const DOWN_TIME := 0.9
const TAG_TIME := 0.35
const THROW_TIME := 0.3
const SLIDE_DISTANCE := 4.5
const SLIDE_BALL_RANGE := 6.0
const RUNDOWN_RANGE := 12.0
const JUKE_RANGE := 6.0
## The fielder making the play shows how he gets the ball this long before
## it arrives, and holds it this long after (a diver stays down until up).
const CATCH_LEAD := 0.3
const CATCH_HOLD := 0.25
const HIGH_CATCH := 1.8
const LOW_CATCH := 0.6

## How the actor holding (or who just threw) the ball is identified:
## -1 = the fielder who made the play, LivePlay.CUTOFF, or a base 1..4.
var holder_cover := -1
var holder_pose := ActorView.Pose.IDLE
var holder_progress := 0.0
var holder_speed := 0.0
## Set while a throw animation plays on the actor who let it go.
var thrower_cover := -2
var thrower_progress := 0.0
## Runner the rundown is about, or &"" when none is on.
var rundown_runner: StringName = &""

var _event_cursor := 0
var _last_s := {}
var _last_dir := {}
var _turn_until := {}
var _in_rundown := {}
var _tag_until := -INF
var _throw_start := -INF
var _last_holder_pos := Vector3.ZERO
var _last_time := 0.0


## Cue for one runner: {pose, speed, juke, visible}.
func runner_cue(play: LivePlay, r: LivePlay.Runner) -> Dictionary:
	var cue := {"pose": ActorView.Pose.IDLE, "speed": 0.0, "juke": false, "visible": true}
	match r.state:
		LivePlay.State.SCORED:
			cue["visible"] = false
		LivePlay.State.OUT:
			cue["pose"] = ActorView.Pose.DOWN
			cue["visible"] = play.time - r.out_time < DOWN_TIME
		LivePlay.State.RUNNING:
			var paused := play.time < r.go_time
			var turning: bool = play.time < float(_turn_until.get(r.id, -INF))
			cue["speed"] = 0.0 if paused else play.tuning.runner_speed
			if turning:
				cue["pose"] = ActorView.Pose.TURN
			elif _sliding(play, r):
				cue["pose"] = ActorView.Pose.SLIDE
			else:
				cue["pose"] = ActorView.Pose.RUN if not paused else ActorView.Pose.IDLE
			cue["juke"] = r.id == rundown_runner and play.ball == LivePlay.Ball.HELD \
				and play.holder_pos.distance_to(play.runner_position(r)) < JUKE_RANGE
	return cue


## Advances the animator's memory to the play's current time.
func update(play: LivePlay) -> void:
	var dt := maxf(play.time - _last_time, 0.0)
	_last_time = play.time
	while _event_cursor < play.events.size():
		var e: Dictionary = play.events[_event_cursor]
		_event_cursor += 1
		match e["type"]:
			"throw":
				thrower_cover = holder_cover
				_throw_start = play.time
			"out":
				if e["kind"] == PlayOutcome.OUT_TAG:
					_tag_until = play.time + TAG_TIME
			"rundown":
				_in_rundown[e["runner"]] = true
	for r in play.runners:
		var s := r.s
		var dir := signf(r.target * LivePlay.BASE - s)
		var last_dir: float = _last_dir.get(r.id, dir)
		if r.state == LivePlay.State.RUNNING and dir != 0.0 and last_dir != 0.0 and dir != last_dir:
			_turn_until[r.id] = play.time + play.tuning.runner_reverse_time
		if dir != 0.0:
			_last_dir[r.id] = dir
		_last_s[r.id] = s
		if r.state != LivePlay.State.RUNNING:
			_in_rundown.erase(r.id)
	rundown_runner = &""
	var ball := play.ball_position()
	ball.y = 0.0
	for id: StringName in _in_rundown:
		var r := play.runner(id)
		if r != null and ball.distance_to(play.runner_position(r)) < RUNDOWN_RANGE:
			rundown_runner = id
			break
	# The holder: tag swipe, then chase when moving with the ball, else ready.
	holder_cover = play.holder_cover if play.ball == LivePlay.Ball.HELD else holder_cover
	holder_speed = 0.0 if dt <= 0.0 else play.holder_pos.distance_to(_last_holder_pos) / dt
	_last_holder_pos = play.holder_pos
	if play.time < _tag_until:
		holder_pose = ActorView.Pose.TAG
	elif play.ball == LivePlay.Ball.HELD and holder_speed > 0.5:
		holder_pose = ActorView.Pose.CHASE
	else:
		holder_pose = ActorView.Pose.IDLE
	thrower_progress = clampf((play.time - _throw_start) / THROW_TIME, 0.0, 1.0)
	if play.time - _throw_start > THROW_TIME:
		thrower_cover = -2


## How the fielder making the play takes the ball: dive, high catch or
## scoop around the moment he secures it (time is contact-relative), else -1 (run or stand as usual).
static func catch_pose(time: float, fielding: FieldingResult) -> int:
	if fielding == null or fielding.fielder_index < 0 or not is_finite(fielding.secure_time):
		return -1
	var until := fielding.ready_time if fielding.is_dive else fielding.secure_time + CATCH_HOLD
	if time < fielding.secure_time - CATCH_LEAD or time > until:
		return -1
	if fielding.is_dive:
		return ActorView.Pose.DIVE
	if fielding.secure_point.y > HIGH_CATCH:
		return ActorView.Pose.CATCH_HIGH
	if fielding.secure_point.y < LOW_CATCH and not fielding.caught_in_air:
		return ActorView.Pose.SCOOP
	return -1


func rundown_active() -> bool:
	return rundown_runner != &""


## Runners slide when the ball is about to beat them to a close bag.
func _sliding(play: LivePlay, r: LivePlay.Runner) -> bool:
	var to_bag := absf(r.target * LivePlay.BASE - r.s)
	if to_bag > SLIDE_DISTANCE or r.target == r.start_base and not r.must_retouch:
		return false
	var bag := FieldLayout.base_position(r.target)
	match play.ball:
		LivePlay.Ball.HELD:
			return play.holder_pos.distance_to(bag) < SLIDE_BALL_RANGE
		LivePlay.Ball.FLIGHT:
			return play.flight["base"] == r.target
	return false
