class_name LivePlay
extends RefCounted
## Everything on a ball in play except the batted ball itself, stepped at a
## fixed rate: runners, the ball once a fielder has it, throws, base covers,
## forces and tags. Runners decide live (hold on a fly, retouch after a
## catch, take the extra base on a throw, retreat, break out of a rundown).
## The defense throws, runs the ball to a bag or chases a runner. Either
## side can be driven by a human through intents; otherwise the built-in AI
## decides. Deterministic for a given sequence of step() calls.
##
## Rules modelled: force outs (a force holds only while every runner behind
## in the chain is alive), tag outs (ball holder within tag reach of a
## runner who is off a base), doubled off (a runner who has not retouched
## after a catch is out if the ball beats them back), ties go to the runner,
## third-out run rules by time.
##
## Errors (only when an rng is given): a ground ball can be bobbled, a dive
## that reaches the ball can still fail to hold it (the ball gets past), and
## any throw can sail. Runners standing on a base read a misplay and may take
## the next one.

enum State { WAITING, RUNNING, ON_BASE, OUT, SCORED }
enum Ball { LOOSE, HELD, FLIGHT }

const BASE := FieldLayout.BASE_DISTANCE
const HOME_PLATE := 4
## Holder counts as on the bag within this distance of it.
const ON_BAG := 0.8
## covers[CUTOFF] is the cutoff man's spot; flight base CUTOFF means a throw to him.
const CUTOFF := 0
## A human throw with no base picked: throw where the AI would.
const AUTO_THROW := 0


class Runner:
	extends RefCounted
	var id: StringName
	var start_base: int
	var is_batter := false
	## Meters along the base path from home plate (0) to scoring (4 * BASE).
	var s := 0.0
	## Base the runner is heading to, or standing on when ON_BASE.
	var target := 0
	var state := 0
	var go_time := 0.0
	var lock_until := 0.0
	var forced := false
	var must_retouch := false
	## Set once a human has given this runner an order; the AI leaves it alone.
	var human := false
	var out_time := INF
	var score_time := INF
	## Furthest base reached safely (for scoring a batter's hit).
	var reached := 0
	var speed := 8.0


var tuning: BaseballTuning
var trajectory: BallTrajectory
var projection: FieldingResult
var fielding: FieldingResult
var batter_id: StringName
var outs_before: int
var launch_angle: float
var runners: Array[Runner] = []
var time := 0.0
var ball := Ball.LOOSE
var holder_pos := Vector3.ZERO
## Base whose cover holds the ball; -1 while the fielder who got it has
## it; CUTOFF while the cutoff man has it.
var holder_cover := -1
var busy_until := 0.0
var windup := 0.0
var flight := {}
## Cover positions by base 1..4 (4 = home plate); index 0 is the cutoff man.
var covers: Array[Vector3] = []
## Base the throw to the cutoff man was meant for (-1 when no relay is on).
var relay_target := -1
var cutoff_active := false
var outs: Array[Dictionary] = []
## Throws made: {from, base, release, arrival}
var legs: Array[Dictionary] = []
## Things presentation may want to call out: {type, ...}
var events: Array[Dictionary] = []
var auto_secure := true
var human_defense := false
## Gameplay randomness for errors; null plays error-free (tests, old sims).
var rng: MatchRng = null
## Multiplier on every error chance (Rookie assist lowers it for a human).
var error_scale := 1.0
## Misplays so far: {type: "bobble"|"wild_throw"|"dive_miss", on_batter, base}
var errors: Array[Dictionary] = []
## The defense's fielders (arms, error scales); empty = league average.
var fielders: Array[FielderState] = []
## Seconds the batting team's runners shave off their safety margins.
var runner_aggression := 0.0
## A bunt: runners had their secondary lead and break as soon as it is down.
var is_bunt := false
## A steal between pitches: the catcher has the ball, nobody is batting.
var is_steal := false

var _went := false
var _ground_targets := {}
var _ground_forced := {}
var _pending_throw := -1
var _last_human_input := -INF
var _settled_since := INF
var _done := false
## While the ball is held after a misplay it rolls from here into the
## fielder's hands; standing runners may run on it until _scramble_until.
var _loose_from := Vector3.ZERO
var _loose_start := 0.0
var _loose_until := -INF
var _scramble_until := -INF


func _init(bases: Array[StringName], p_batter_id: StringName, p_outs_before: int, p_launch_angle: float,
		p_trajectory: BallTrajectory, p_projection: FieldingResult, p_tuning: BaseballTuning, p_auto_secure: bool = true,
		p_fielders: Array[FielderState] = [], speeds: Dictionary = {}, p_aggression: float = 0.0) -> void:
	tuning = p_tuning
	fielders = p_fielders
	runner_aggression = p_aggression
	trajectory = p_trajectory
	projection = p_projection
	batter_id = p_batter_id
	outs_before = p_outs_before
	launch_angle = p_launch_angle
	auto_secure = p_auto_secure
	covers.resize(5)
	for b in range(1, 5):
		covers[b] = FieldLayout.base_position(b)
	# The runners' read if the ball lands: targets and forces from the
	# projected fielding treated as a ball on the ground.
	var ground := _as_ground_ball(projection)
	var arm := fielders[projection.fielder_index].arm if projection.fielder_index >= 0 and projection.fielder_index < fielders.size() else 1.0
	for plan in RunnerResolver.plan(bases, batter_id, ground, outs_before, tuning, speeds, runner_aggression, arm):
		_ground_targets[plan.runner_id] = plan.target_base
		_ground_forced[plan.runner_id] = plan.forced
	for base in [3, 2, 1]:
		var id: StringName = bases[base - 1]
		if id == &"":
			continue
		var r := Runner.new()
		r.id = id
		r.start_base = base
		r.s = base * BASE + tuning.runner_lead_distance
		r.target = base
		r.state = State.WAITING
		r.speed = speeds.get(id, tuning.runner_speed)
		runners.append(r)
	var batter := Runner.new()
	batter.id = batter_id
	batter.start_base = FieldLayout.HOME
	batter.is_batter = true
	batter.target = FieldLayout.FIRST
	batter.state = State.RUNNING
	batter.forced = true
	batter.go_time = tuning.batter_start_delay
	batter.speed = speeds.get(batter_id, tuning.runner_speed)
	runners.append(batter)


## A stolen-base play: the moment the catcher gloves the pitch. stealers:
## start base -> meters the runner is off the bag already (lead + jump).
static func steal_play(bases: Array[StringName], stealers: Dictionary, outs_before: int, p_tuning: BaseballTuning,
		p_fielders: Array[FielderState] = [], speeds: Dictionary = {}, p_aggression: float = 0.0) -> LivePlay:
	var f := FieldingResult.new()
	f.fielder_index = p_tuning.fielder_ids.find(&"c")
	f.fielder_id = &"c"
	f.secure_point = Vector3(0.0, 0.0, 0.9)
	f.secure_time = 0.0
	f.ready_time = p_tuning.catcher_transfer_time
	var traj := BallTrajectory.simulate(1.0, -60.0, 0.0, p_tuning)  # unused: the ball starts in the mitt
	var play := LivePlay.new(bases, &"", outs_before, 0.0, traj, f, p_tuning, false, p_fielders, speeds, p_aggression)
	play._setup_steal(stealers)
	return play


func _setup_steal(stealers: Dictionary) -> void:
	is_steal = true
	_went = true
	runners = runners.filter(func(r: Runner) -> bool: return not r.is_batter)
	for r in runners:
		r.forced = false
		if stealers.has(r.start_base):
			r.s = r.start_base * BASE + stealers[r.start_base]
			r.target = r.start_base + 1
			r.state = State.RUNNING
			r.go_time = 0.0
			r.lock_until = INF  # committed: a stealer does not turn back
			events.append({"type": "steal", "runner": r.id, "base": r.target})
		else:
			r.s = r.start_base * BASE
			r.target = r.start_base
			r.state = State.ON_BASE
	secure(projection)
	windup = tuning.catcher_release_time


## Meters a stealing runner is off his bag when the pitch reaches the plate.
static func steal_head_start(speed: float, travel_time: float, jump_delay: float, p_tuning: BaseballTuning) -> float:
	return p_tuning.runner_lead_distance + speed * maxf(p_tuning.steal_delivery_time + travel_time - jump_delay - p_tuning.steal_start_penalty, 0.0)


## A runner who was stealing when the ball was put in play is already on his way.
func set_running_start(base: int, head: float) -> void:
	for r in runners:
		if not r.is_batter and r.start_base == base:
			r.s = base * BASE + head
			r.target = base + 1
			r.state = State.RUNNING
			r.go_time = 0.0


## Call right after construction on a bunt.
func start_bunt() -> void:
	is_bunt = true
	for r in runners:
		if not r.is_batter:
			r.s += tuning.bunt_runner_jump


# --- Queries ----------------------------------------------------------------

func is_done() -> bool:
	return _done


func inning_over() -> bool:
	return outs_before + outs.size() >= MatchState.OUTS_PER_HALF


func runner(id: StringName) -> Runner:
	for r in runners:
		if r.id == id:
			return r
	return null


func runner_position(r: Runner) -> Vector3:
	var s := clampf(r.s, 0.0, 4.0 * BASE)
	var leg := mini(int(s / BASE), 3)
	return FieldLayout.base_position(leg).lerp(FieldLayout.base_position(leg + 1), (s - leg * BASE) / BASE)


func ball_position() -> Vector3:
	match ball:
		Ball.LOOSE:
			return trajectory.position_at(time)
		Ball.FLIGHT:
			if time < flight["release"]:
				return holder_pos + Vector3.UP * 1.3
			var u := clampf((time - flight["release"]) / maxf(flight["arrival"] - flight["release"], 0.01), 0.0, 1.0)
			return ThrowModel.position_at(flight["from"], flight["to"], u, tuning)
	if time < _loose_until:
		# A misplayed ball skipping away before the fielder picks it up.
		var u := clampf((time - _loose_start) / maxf(_loose_until - _loose_start, 0.01), 0.0, 1.0)
		return _loose_from.lerp(holder_pos, u) + Vector3.UP * 0.12
	return holder_pos + Vector3.UP * 1.3


## Seconds until a runner can reach a base from where they are now.
func runner_eta(r: Runner, base: int) -> float:
	var goal := base * BASE
	var wait := maxf(r.go_time - time, 0.0)
	var penalty := 0.0
	if r.state == State.RUNNING:
		var now_dir := signf(r.target * BASE - r.s)
		var new_dir := signf(goal - r.s)
		if now_dir != 0.0 and new_dir != 0.0 and now_dir != new_dir:
			penalty = tuning.runner_reverse_time
	return wait + penalty + absf(goal - r.s) / r.speed


## Seconds until the defense can have the ball on a base (run or throw).
func ball_eta(base: int) -> float:
	match ball:
		Ball.LOOSE:
			var f := fielders[projection.fielder_index] if projection.fielder_index >= 0 and projection.fielder_index < fielders.size() else null
			return maxf(ThrowModel.arrival_at_base(projection, base, tuning, f.arm if f != null else 1.0) - time, 0.0)
		Ball.FLIGHT:
			var to_base: int = flight["base"]
			var land: float = flight["arrival"] - time
			if to_base == base:
				return maxf(land, 0.0)
			var pivot := tuning.cutoff_release_time if to_base == CUTOFF else tuning.relay_release_time
			return maxf(land, 0.0) + pivot + ThrowModel.flight_time(flight["to"], covers[base], tuning, _team_arm())
	var wait := maxf(busy_until - time, 0.0)
	return wait + minf(_run_time(base), _throw_time(base))


## A force holds only toward the next base and only while every runner
## behind in the force chain is still alive.
func forced_now(r: Runner, base: int) -> bool:
	if not r.forced or base != r.start_base + 1 or r.s >= base * BASE:
		return false
	for q in runners:
		if q.forced and q.start_base < r.start_base and q.state == State.OUT:
			return false
	return true


# --- Driving the play ---------------------------------------------------------

## The ball is in a fielder's hands (from the projection or LiveFielding).
func secure(f: FieldingResult) -> void:
	if ball != Ball.LOOSE:
		return
	fielding = f
	ball = Ball.HELD
	holder_pos = f.secure_point
	holder_cover = -1
	busy_until = f.ready_time
	windup = tuning.throw_release_time
	if f.caught_in_air and f.is_dive and _roll(tuning.dive_drop_chance):
		# The dive gets a glove on it but the ball squirts past.
		fielding = _copy(f)
		fielding.caught_in_air = false
		_misplay("dive_miss", tuning.dive_miss_roll, tuning.dive_miss_delay)
	elif not f.caught_in_air and _roll((tuning.bobble_chance + tuning.bobble_chance_per_speed * _ball_speed(f.secure_time)) * _holder_fielder_scale(false)):
		_misplay("bobble", tuning.bobble_roll, tuning.bobble_time)
	if fielding.caught_in_air:
		var batter := runner(batter_id)
		_record_out(batter, FieldLayout.HOME, PlayOutcome.OUT_CATCH)
		events.append({"type": "catch"})
		for r in runners:
			if r.is_batter or r.state == State.OUT:
				continue
			# Every runner has to get back to the bag before tagging up.
			r.forced = false
			var was_going := r.state == State.RUNNING and r.target > r.start_base
			r.must_retouch = r.s > r.start_base * BASE + 0.01
			r.target = r.start_base
			r.state = State.RUNNING if r.must_retouch else State.ON_BASE
			r.go_time = maxf(r.go_time, time + (tuning.runner_reverse_time if was_going else 0.0))
			r.human = false
	elif not _went:
		_go_ground()


## defense: {throw: base, move: Vector2} from a human (or {} for AI).
## offense: {advance: bool, retreat: bool} from a human (or {} for AI).
func step(dt: float, defense: Dictionary = {}, offense: Dictionary = {}) -> void:
	if _done:
		return
	time += dt
	if ball == Ball.LOOSE:
		if auto_secure and projection.has_fielder() and time >= projection.secure_time:
			secure(projection)
		elif not _went and (time >= trajectory.first_bounce_time or outs_before == MatchState.OUTS_PER_HALF - 1):
			_go_ground()  # with two outs everyone runs on contact
	_apply_offense(offense)
	if ball != Ball.LOOSE:
		for r in runners:
			_ai_runner(r)
	_apply_defense(dt, defense)
	if ball == Ball.FLIGHT and time >= flight["arrival"]:
		_catch_throw()
	_move_runners(dt)
	_update_covers(dt)
	_resolve_arrivals()
	_resolve_outs()
	_check_done()


## Runs the whole play with the AI on both sides.
func run_ai(step_size: float) -> PlayOutcome:
	var guard := 0
	while not _done and guard < 100000:
		step(step_size)
		guard += 1
	return outcome()


# --- Offense ------------------------------------------------------------------

func _go_ground() -> void:
	_went = true
	for r in runners:
		if r.state == State.OUT or r.state == State.SCORED:
			continue
		r.forced = _ground_forced.get(r.id, r.forced)
		if r.human:
			continue  # keeps whatever the player told them
		r.target = _ground_targets.get(r.id, r.target)
		r.state = State.RUNNING
		if not r.is_batter:
			r.go_time = maxf(r.go_time, time + (0.0 if is_bunt else tuning.runner_read_delay))


## offense: {advance, retreat, base}. base 0 (or absent) orders every
## runner; 1..4 orders only the runner on, heading to, or just off that base.
## A runner given an order is no longer steered by the AI.
func _apply_offense(offense: Dictionary) -> void:
	var advance: bool = offense.get("advance", false)
	var retreat: bool = offense.get("retreat", false)
	if not advance and not retreat:
		return
	var base: int = offense.get("base", 0)
	var picked := runner_for_base(base) if base > 0 else null
	if base > 0 and picked == null:
		return
	if advance:
		# Lead runner first so trailing runners never pass them.
		for r in _ordered(true):
			if picked == null or r == picked:
				_order_advance(r)
	if retreat:
		for r in _ordered(false):
			if picked == null or r == picked:
				_order_retreat(r)


## The runner a base button refers to: standing on it, else heading to it,
## else the one who just left it.
func runner_for_base(base: int) -> Runner:
	for pass_kind in 3:
		for r in runners:
			if r.state == State.OUT or r.state == State.SCORED:
				continue
			match pass_kind:
				0:
					if (r.state == State.ON_BASE or r.state == State.WAITING) and r.target == base:
						return r
				1:
					if r.state == State.RUNNING and r.target == base:
						return r
				2:
					if r.state == State.RUNNING and floori((r.s - 0.01) / BASE) == base:
						return r
	return null


func _order_advance(r: Runner) -> void:
	var next := r.target + 1
	if r.state == State.WAITING:
		next = r.start_base + 1
	elif r.state == State.RUNNING and r.target * BASE < r.s:
		next = ceili((r.s + 0.01) / BASE)  # turn around and go forward
	next = mini(next, HOME_PLATE)
	if next != r.target and not _blocked(r, next):
		_set_target(r, next, 0.0)
	r.human = true


func _order_retreat(r: Runner) -> void:
	r.human = true  # on a bag this means "stay"
	if r.state != State.RUNNING or forced_now(r, r.target):
		return
	var back := floori((r.s - 0.01) / BASE)
	if back >= 1 and back != r.target and not _blocked(r, back):
		_set_target(r, back, tuning.runner_reverse_time)


func _ai_runner(r: Runner) -> void:
	if r.human or time < r.lock_until or r.state == State.WAITING:
		return
	if r.state == State.ON_BASE:
		# Standing runners only go on a throw to another base (taking the base
		# on the throw) or to tag up; stretching a hit was decided at the read.
		var next := r.target + 1
		if next > HOME_PLATE or r.must_retouch or _blocked(r, next) or inning_over():
			return
		var tagging := fielding != null and fielding.caught_in_air and ball == Ball.HELD and holder_cover == -1
		var scramble := time < _scramble_until
		if not tagging and not scramble and not (ball == Ball.FLIGHT and flight["base"] != next):
			return
		var slack := ball_eta(next) - runner_eta(r, next) - _tag_margin()
		if slack > (tuning.runner_safety_margin if scramble else tuning.runner_take_base_margin) - runner_aggression:
			_set_target(r, next, tuning.runner_read_delay)
			events.append({"type": "advance", "runner": r.id, "base": next})
	elif r.state == State.RUNNING:
		var cur := r.target
		var dir := signf(cur * BASE - r.s)
		if time < _scramble_until and dir > 0.0 and cur < HOME_PLATE and not _blocked(r, cur + 1) and not inning_over():
			# The ball got away: keep going past the base if it is there to take.
			var slack_on := ball_eta(cur + 1) - runner_eta(r, cur + 1) - tuning.base_turn_penalty - _tag_margin()
			if slack_on > tuning.runner_safety_margin - runner_aggression:
				_set_target(r, cur + 1, 0.0)
				events.append({"type": "advance", "runner": r.id, "base": cur + 1})
				return
		if dir == 0.0 or (r.must_retouch and cur == r.start_base) or forced_now(r, cur):
			return
		var slack_cur := ball_eta(cur) - runner_eta(r, cur) - _tag_margin()
		if slack_cur >= 0.0:
			return
		var alt := floori((r.s - 0.01) / BASE) if dir > 0.0 else ceili((r.s + 0.01) / BASE)
		if alt < 1 or alt > HOME_PLATE or alt == cur or _blocked(r, alt):
			return
		var slack_alt := ball_eta(alt) - runner_eta(r, alt) - _tag_margin()
		if slack_alt > slack_cur + 0.05:
			_set_target(r, alt, tuning.runner_reverse_time)
			if ball == Ball.HELD and holder_pos.distance_to(runner_position(r)) < tuning.rundown_chase_range:
				events.append({"type": "rundown", "runner": r.id})


func _set_target(r: Runner, base: int, pause: float) -> void:
	r.target = base
	r.state = State.RUNNING
	r.go_time = maxf(r.go_time, time + pause)
	r.lock_until = time + pause + tuning.runner_decision_lock


func _blocked(r: Runner, base: int) -> bool:
	if base >= HOME_PLATE or base == r.start_base and not r.is_batter:
		return false
	for q in runners:
		if q != r and (q.state == State.ON_BASE or q.state == State.RUNNING or q.state == State.WAITING) and q.target == base:
			return true
	return false


func _ordered(lead_first: bool) -> Array[Runner]:
	var list: Array[Runner] = []
	for r in runners:
		if r.state != State.OUT and r.state != State.SCORED:
			list.append(r)
	list.sort_custom(func(a: Runner, b: Runner) -> bool: return a.s > b.s if lead_first else a.s < b.s)
	return list


func _move_runners(dt: float) -> void:
	for r in runners:
		if r.state != State.RUNNING or time < r.go_time:
			continue
		r.s = move_toward(r.s, r.target * BASE, r.speed * dt)
		if r.must_retouch and r.s <= r.start_base * BASE + 0.01:
			r.must_retouch = false


func _resolve_arrivals() -> void:
	for r in runners:
		if r.state != State.RUNNING or absf(r.s - r.target * BASE) > 0.001:
			continue
		r.reached = maxi(r.reached, r.target)
		if r.target == HOME_PLATE:
			r.state = State.SCORED
			r.score_time = time
			events.append({"type": "run", "runner": r.id})
		else:
			r.state = State.ON_BASE


# --- Defense ------------------------------------------------------------------

func _apply_defense(dt: float, defense: Dictionary) -> void:
	if human_defense and defense.get("throw", -1) >= AUTO_THROW:
		# Buffered before the catch and mid-throw: pressing a base while the
		# ball is on its way to the cutoff man redirects his relay.
		_pending_throw = defense["throw"]
		_last_human_input = time
	if ball != Ball.HELD:
		return
	var action := {}
	if human_defense:
		var move: Vector2 = defense.get("move", Vector2.ZERO)
		if move.length() > 0.2:
			_last_human_input = time
			action = {"kind": "move", "dir": move}
		if _pending_throw >= AUTO_THROW and time >= busy_until:
			action = {"kind": "throw", "base": _pending_throw if _pending_throw > 0 else _best_throw_base()}
			_pending_throw = -1
		elif action.is_empty() and time >= maxf(busy_until, _last_human_input) + tuning.human_throw_decision_window:
			action = ai_defense_action()
	elif time >= busy_until:
		action = ai_defense_action()
	match action.get("kind", ""):
		"throw":
			_throw(action["base"])
		"run":
			_move_holder(FieldLayout.base_position(action["base"]), dt)
		"chase":
			_move_holder(action["point"], dt)
		"move":
			var dir: Vector2 = action["dir"]
			var world := Vector3(dir.x, 0.0, -dir.y).limit_length(1.0)
			_move_holder(holder_pos + world * 10.0, dt)


## The defense AI: best force/tag available by throwing or running the ball
## there; otherwise chase a runner caught off base; otherwise hold.
func ai_defense_action() -> Dictionary:
	if ball != Ball.HELD or inning_over():
		return {}
	var outs_now := outs_before + outs.size()
	var best := {}
	var best_score := -INF
	for r in runners:
		var stuck := r.state == State.ON_BASE and forced_now(r, r.start_base + 1)
		if r.state != State.RUNNING and not stuck:
			continue
		var bases: Array[int] = [r.start_base + 1 if stuck else r.target]
		if r.must_retouch and r.target != r.start_base:
			bases.append(r.start_base)
		for b in bases:
			if b < 1:
				continue
			var appeal := r.must_retouch and b == r.start_base
			if not appeal and signf(b * BASE - r.s) == 0.0:
				continue
			var forced := forced_now(r, b) or appeal
			var wait := maxf(busy_until - time, 0.0)
			var run := wait + _run_time(b)
			var throw := wait + _throw_time(b)
			var eta := minf(run, throw)
			var margin := runner_eta(r, b) - eta - (0.0 if forced else _tag_margin())
			if margin <= tuning.ai_throw_min_margin:
				continue
			var score := margin + b * tuning.ai_throw_lead_runner_bias
			if b == HOME_PLATE:
				score += tuning.ai_throw_run_prevention_bias
			if outs_now == MatchState.OUTS_PER_HALF - 1 and forced:
				score += 10.0  # a sure force ends the inning and cancels runs
			if score > best_score:
				best_score = score
				best = {"kind": "run" if run <= throw else "throw", "base": b}
	if not best.is_empty():
		return best
	# Nothing to throw at: run at the nearest runner hung up off a base.
	var chase: Runner = null
	var chase_d := tuning.rundown_chase_range
	for r in runners:
		if r.state != State.RUNNING or r.must_retouch:
			continue
		var d := holder_pos.distance_to(runner_position(r))
		if d < chase_d:
			chase = r
			chase_d = d
	if chase != null:
		return {"kind": "chase", "point": runner_position(chase)}
	# Otherwise get the ball back in: throw ahead of the lead runner so
	# nobody keeps running on a fielder who is just holding it. On a steal
	# with no play the catcher just holds it.
	if holder_cover == -1 and not is_steal:
		return {"kind": "throw", "base": _hold_base()}
	return {}


## Base for a "best play" throw: the AI's choice, else ahead of the lead runner.
func _best_throw_base() -> int:
	var pick := ai_defense_action()
	if pick.get("kind", "") in ["throw", "run"]:
		return pick["base"]
	return _hold_base()


func _hold_base() -> int:
	var lead: Runner = null
	for r in runners:
		# Runners already scoring are not worth a throw; hold the others.
		if (r.state == State.RUNNING or r.state == State.ON_BASE) and r.target < HOME_PLATE and (lead == null or r.s > lead.s):
			lead = r
	if lead == null:
		return FieldLayout.SECOND
	# Throw ahead of the lead runner so he cannot take another base on it.
	return clampi(lead.target + 1, FieldLayout.FIRST, HOME_PLATE)


func _throw(base: int) -> void:
	if _holder_on_bag() == base or base < 1 or base > HOME_PLATE:
		return
	var route := _route(base)
	var to: Vector3 = route["to"]
	var release := maxf(time, busy_until) + windup
	var arrival := release + ThrowModel.flight_time(holder_pos, to, tuning, _holder_arm())
	var aim := CUTOFF if route["cutoff"] else base
	if route["cutoff"]:
		covers[CUTOFF] = to
		cutoff_active = true
		relay_target = base
	var flat := Vector2(to.x - holder_pos.x, to.z - holder_pos.z).length()
	var wild := _roll((tuning.throw_error_chance + tuning.throw_error_per_meter * flat) * _holder_fielder_scale(true))
	if wild:
		# It sails: off to one side and past the target.
		var along := Vector3(to.x - holder_pos.x, 0.0, to.z - holder_pos.z).normalized()
		var side := along.cross(Vector3.UP) * (1.0 if rng.chance(0.5) else -1.0)
		var off := side * rng.randf_range(0.0, tuning.wild_throw_side) + along * rng.randf_range(tuning.wild_throw_past_min, tuning.wild_throw_past_max)
		flight = {"from": holder_pos, "to": to + off, "base": aim, "release": release, "arrival": arrival, "wild": true, "missed_by": off.length()}
	else:
		flight = {"from": holder_pos, "to": to, "base": aim, "release": release, "arrival": arrival}
	legs.append(flight.duplicate())
	ball = Ball.FLIGHT
	events.append({"type": "throw", "base": aim, "relay_to": base if route["cutoff"] else -1})


## Long throws from the outfield go through a cutoff man lined up between
## the thrower and the base: {cutoff: bool, to: Vector3}.
func _route(base: int) -> Dictionary:
	var bag := covers[base]
	var flat := Vector2(bag.x - holder_pos.x, bag.z - holder_pos.z).length()
	if holder_cover != -1 or flat < tuning.cutoff_min_throw:
		return {"cutoff": false, "to": bag}
	var from_base := minf(tuning.cutoff_distance_from_base, flat * 0.5)
	var spot := bag.move_toward(Vector3(holder_pos.x, 0.0, holder_pos.z), from_base)
	return {"cutoff": true, "to": spot}


func _catch_throw() -> void:
	var base: int = flight["base"]
	ball = Ball.HELD
	holder_cover = base
	holder_pos = flight["to"]
	covers[base] = holder_pos
	busy_until = time
	if flight.get("wild", false):
		# The cover chases it down off the bag; runners can take a base.
		# A backup chases it down where it stopped.
		busy_until = time + tuning.wild_throw_pickup + tuning.wild_throw_run_share * flight["missed_by"] / tuning.fielder_speed
		_scramble_until = busy_until + tuning.runner_take_base_margin
		var batter := runner(batter_id)
		var on_batter := batter != null and base == FieldLayout.FIRST and batter.state == State.RUNNING and batter.target == FieldLayout.FIRST
		errors.append({"type": "wild_throw", "base": base, "on_batter": on_batter})
		events.append({"type": "error", "kind": "wild_throw", "base": base})
	if base == CUTOFF:
		windup = tuning.cutoff_release_time
		events.append({"type": "cutoff", "relay_to": relay_target})
		# A human's relay goes through to the original base unless they
		# pressed another one while the ball was coming in.
		if human_defense and _pending_throw <= 0:
			_pending_throw = relay_target
	else:
		windup = tuning.relay_release_time
		relay_target = -1


func _move_holder(goal: Vector3, dt: float) -> void:
	holder_pos = holder_pos.move_toward(Vector3(goal.x, 0.0, goal.z), tuning.fielder_speed * dt)
	if holder_cover >= 0:
		covers[holder_cover] = holder_pos
	windup = tuning.relay_release_time


func _holder_on_bag() -> int:
	for b in range(1, 5):
		if holder_pos.distance_to(FieldLayout.base_position(b)) <= ON_BAG:
			return b
	return -1


func _run_time(base: int) -> float:
	var d := holder_pos.distance_to(FieldLayout.base_position(base))
	return 0.0 if d <= ON_BAG else d / tuning.fielder_speed


func _throw_time(base: int) -> float:
	if _holder_on_bag() == base:
		return 0.0
	var route := _route(base)
	if not route["cutoff"]:
		return windup + ThrowModel.flight_time(holder_pos, covers[base], tuning, _holder_arm())
	var cut: Vector3 = route["to"]
	return windup + ThrowModel.flight_time(holder_pos, cut, tuning, _holder_arm()) + tuning.cutoff_release_time + ThrowModel.flight_time(cut, covers[base], tuning, _team_arm())


## Arm of whoever holds the ball: the fielder who made the play, else a
## cover or the cutoff man (the defense's average arm).
func _holder_arm() -> float:
	var f := _first_fielder()
	return f.arm if holder_cover == -1 and f != null else _team_arm()


func _team_arm() -> float:
	if fielders.is_empty():
		return 1.0
	var total := 0.0
	for f in fielders:
		total += f.arm
	return total / fielders.size()


func _holder_fielder_scale(throwing: bool) -> float:
	var f := _first_fielder()
	if holder_cover != -1 or f == null:
		return 1.0
	return f.throw_error_scale if throwing else f.error_scale


func _first_fielder() -> FielderState:
	if fielding == null or fielding.fielder_index < 0 or fielding.fielder_index >= fielders.size():
		return null
	return fielders[fielding.fielder_index]


func _roll(probability: float) -> bool:
	return rng != null and rng.chance(probability * error_scale)


## The fielder who just got the ball fumbles it: it ends up `roll` meters
## further along its path and he is busy for `delay` seconds.
func _misplay(kind: String, roll: float, delay: float) -> void:
	var along := trajectory.position_at(fielding.secure_time + 0.1) - trajectory.position_at(fielding.secure_time)
	along.y = 0.0
	_loose_from = holder_pos
	_loose_start = time
	holder_pos += along.normalized() * roll if along.length() > 0.001 else Vector3.ZERO
	busy_until = maxf(busy_until, time) + delay
	_loose_until = busy_until
	_scramble_until = busy_until + tuning.runner_take_base_margin
	errors.append({"type": kind, "base": -1, "on_batter": kind == "bobble"})
	events.append({"type": "error", "kind": kind, "base": -1})


func _ball_speed(t: float) -> float:
	return (trajectory.position_at(t + 0.05) - trajectory.position_at(t)).length() / 0.05


static func _copy(f: FieldingResult) -> FieldingResult:
	var c := FieldingResult.new()
	c.fielder_index = f.fielder_index
	c.fielder_id = f.fielder_id
	c.secure_time = f.secure_time
	c.ready_time = f.ready_time
	c.secure_point = f.secure_point
	c.caught_in_air = f.caught_in_air
	c.is_dive = f.is_dive
	c.candidates = f.candidates.duplicate()
	return c


func _tag_margin() -> float:
	return tuning.tag_reach / tuning.runner_speed


## Covers next to a runner hung up between bases close in on him.
func _update_covers(dt: float) -> void:
	if ball == Ball.LOOSE:
		return
	for b in range(1, 5):
		if b == holder_cover and ball == Ball.HELD:
			continue
		if ball == Ball.FLIGHT and flight["base"] == b:
			continue
		var bag := FieldLayout.base_position(b)
		var goal := bag
		for r in runners:
			if r.state != State.RUNNING or r.must_retouch:
				continue
			var away := signf(b * BASE - r.s) != signf(r.target * BASE - r.s)
			if absf(b * BASE - r.s) < BASE and away and ball == Ball.HELD:
				goal = bag.move_toward(runner_position(r), tuning.cover_close_in)
		covers[b] = covers[b].move_toward(goal, tuning.fielder_speed * dt)


# --- Outs and the end of the play -------------------------------------------

func _resolve_outs() -> void:
	if ball != Ball.HELD or inning_over():
		return
	var bag := _holder_on_bag()
	for r in runners:
		if inning_over():
			break
		if r.state == State.ON_BASE and bag > 0 and forced_now(r, bag):
			_record_out(r, bag, PlayOutcome.OUT_FORCE)  # stayed put while forced
			continue
		if r.state != State.RUNNING:
			continue
		if bag > 0 and forced_now(r, bag):
			_record_out(r, bag, PlayOutcome.OUT_FORCE)
		elif bag > 0 and r.must_retouch and bag == r.start_base:
			_record_out(r, bag, PlayOutcome.OUT_DOUBLED_OFF)
		elif holder_pos.distance_to(runner_position(r)) <= tuning.tag_reach:
			_record_out(r, r.target, PlayOutcome.OUT_TAG)


func _record_out(r: Runner, base: int, kind: StringName) -> void:
	r.state = State.OUT
	r.out_time = time
	outs.append({"runner_id": r.id, "base": base, "kind": kind, "time": time})
	events.append({"type": "out", "runner": r.id, "base": base, "kind": kind})


func _check_done() -> void:
	if inning_over():
		_done = true
		return
	if ball == Ball.LOOSE:
		return
	var moving := runners.any(func(r: Runner) -> bool: return r.state == State.RUNNING)
	if not moving and ball == Ball.HELD and time >= busy_until:
		if _settled_since == INF:
			_settled_since = time
		if time - _settled_since >= tuning.play_settle_time:
			_done = true
	else:
		_settled_since = INF
	if not _done and time > tuning.max_play_time:
		# A rundown that never ends: the runner is ruled tagged.
		for r in runners:
			if r.state == State.RUNNING and not inning_over():
				_record_out(r, r.target, PlayOutcome.OUT_TAG)
		_done = true


func outcome() -> PlayOutcome:
	var result := PlayOutcome.new()
	result.batter_id = batter_id
	result.outs = outs.duplicate(true)
	result.throws = legs.duplicate(true)
	result.errors = errors.duplicate(true)
	if not legs.is_empty():
		result.throw_base = legs[0]["base"]
		result.throw_arrival = legs[0]["arrival"]
	var over := inning_over()
	var third_out: Dictionary = outs[MatchState.OUTS_PER_HALF - outs_before - 1] if over else {}
	var scored := runners.filter(func(r: Runner) -> bool: return r.state == State.SCORED)
	scored.sort_custom(func(a: Runner, b: Runner) -> bool: return a.score_time < b.score_time)
	for r: Runner in scored:
		if over:
			# No run on a third out that is a force or a catch; on a time play
			# (tag, doubled off) only runners who crossed before it count.
			var kind: StringName = third_out["kind"]
			if kind == PlayOutcome.OUT_FORCE or kind == PlayOutcome.OUT_CATCH or r.score_time >= third_out["time"]:
				continue
		result.runs.append(r.id)
	for r in runners:
		var safe := r.state != State.OUT
		var final := r.target
		if r.state == State.WAITING:
			final = r.start_base
		elif r.state == State.SCORED:
			final = HOME_PLATE
		result.advances.append({"runner_id": r.id, "from": r.start_base, "to": final, "safe": safe})
		if safe and not over and final >= FieldLayout.FIRST and final <= FieldLayout.THIRD:
			result.final_bases[final - 1] = r.id
		if r.is_batter:
			result.batter_base = final if safe and r.state != State.RUNNING else 0
	result.kind = _classify(result)
	return result


func _classify(result: PlayOutcome) -> StringName:
	if is_steal:
		return PlayOutcome.KIND_STEAL
	if result.outs.size() >= 3:
		return PlayOutcome.KIND_TRIPLE_PLAY
	if result.outs.size() == 2:
		return PlayOutcome.KIND_DOUBLE_PLAY
	if fielding != null and fielding.caught_in_air:
		if launch_angle >= 50.0:
			return PlayOutcome.KIND_POP_OUT
		if launch_angle < 15.0:
			return PlayOutcome.KIND_LINE_OUT
		return PlayOutcome.KIND_FLY_OUT
	var batter := runner(batter_id)
	var hit_base := result.batter_base if result.batter_base > 0 else batter.reached
	if hit_base == 0:
		var moved_up := result.advances.any(func(a: Dictionary) -> bool: return a["runner_id"] != batter_id and a["safe"] and a["to"] > a["from"])
		if is_bunt and result.outs.size() == 1 and moved_up:
			return PlayOutcome.KIND_SACRIFICE
		return PlayOutcome.KIND_GROUND_OUT
	if result.batter_base > 0 and errors.any(func(e: Dictionary) -> bool: return e["on_batter"]):
		return PlayOutcome.KIND_REACHED_ON_ERROR
	# A runner forced out means the batter reached on the fielder's choice,
	# however far he got afterwards.
	var forced_runner := result.outs.any(func(o: Dictionary) -> bool: return o["kind"] == PlayOutcome.OUT_FORCE and o["runner_id"] != batter_id)
	if forced_runner or not result.outs.is_empty() and result.batter_base == FieldLayout.FIRST:
		return PlayOutcome.KIND_FIELDERS_CHOICE
	match hit_base:
		1:
			return PlayOutcome.KIND_SINGLE
		2:
			return PlayOutcome.KIND_DOUBLE
		3:
			return PlayOutcome.KIND_TRIPLE
	return PlayOutcome.KIND_INSIDE_PARK_HR


static func _as_ground_ball(f: FieldingResult) -> FieldingResult:
	var g := FieldingResult.new()
	g.fielder_index = f.fielder_index
	g.fielder_id = f.fielder_id
	g.secure_time = f.secure_time
	g.ready_time = f.ready_time
	g.secure_point = f.secure_point
	g.caught_in_air = false
	return g
