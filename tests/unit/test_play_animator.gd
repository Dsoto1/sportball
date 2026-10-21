extends TestCase
## Presentation cues for live plays (no nodes needed).


func _fielded(point: Vector3, time: float, in_air: bool = false) -> FieldingResult:
	var f := FieldingResult.new()
	f.fielder_index = 0
	f.fielder_id = &"test"
	f.secure_point = point
	f.secure_time = time
	f.ready_time = time
	f.caught_in_air = in_air
	return f


func _rundown_play() -> LivePlay:
	var traj := BallTrajectory.simulate(30.0, -6.0, -15.0, tuning())
	var bases: Array[StringName] = [&"", &"r2", &""]
	var play := LivePlay.new(bases, &"bat", 0, -6.0, traj, _fielded(Vector3(-9, 0, -34), 1.0), tuning(), true)
	while play.time < 0.3:
		play.step(tuning().sim_play_step)
	play._set_target(play.runner(&"r2"), 3, 0.0)
	return play


func test_rundown_gets_turns_jukes_and_a_finish() -> void:
	var play := _rundown_play()
	var anim := PlayAnimator.new()
	var saw := {"turn": false, "juke": false, "rundown": false, "chase": false, "tag": false, "down": false}
	while not play.is_done():
		play.step(tuning().sim_play_step)
		anim.update(play)
		var cue := anim.runner_cue(play, play.runner(&"r2"))
		saw["turn"] = saw["turn"] or cue["pose"] == ActorView.Pose.TURN
		saw["juke"] = saw["juke"] or cue["juke"]
		saw["rundown"] = saw["rundown"] or anim.rundown_active()
		saw["chase"] = saw["chase"] or anim.holder_pose == ActorView.Pose.CHASE
		saw["tag"] = saw["tag"] or anim.holder_pose == ActorView.Pose.TAG
		saw["down"] = saw["down"] or (cue["pose"] == ActorView.Pose.DOWN and cue["visible"])
	check(saw["turn"], "runner plants and turns")
	check(saw["rundown"], "rundown is recognised")
	check(saw["chase"] or saw["juke"], "someone chases or the runner jukes")
	if play.runner(&"r2").state == LivePlay.State.OUT:
		check(saw["down"], "tagged runner goes down before leaving")


func test_out_runner_disappears_after_going_down() -> void:
	var play := _rundown_play()
	var anim := PlayAnimator.new()
	play.run_ai(tuning().sim_play_step)
	anim.update(play)
	var out: LivePlay.Runner = null
	for r in play.runners:
		if r.state == LivePlay.State.OUT:
			out = r
	if out == null:
		return  # nobody was put out on this play
	var later := play.time
	play.time = out.out_time + 0.1
	check(anim.runner_cue(play, out)["visible"], "still visible right after the out")
	play.time = out.out_time + PlayAnimator.DOWN_TIME + 0.1
	check(not anim.runner_cue(play, out)["visible"], "gone once the fall has played")
	play.time = later


func test_throw_sets_a_short_throw_cue() -> void:
	var traj := BallTrajectory.simulate(30.0, -6.0, -15.0, tuning())
	var bases: Array[StringName] = ["", "", ""]
	var play := LivePlay.new(bases, &"bat", 0, -6.0, traj, _fielded(Vector3(-9, 0, -34), 1.0), tuning(), true)
	var anim := PlayAnimator.new()
	var seen_throw := false
	while not play.is_done():
		play.step(tuning().sim_play_step)
		anim.update(play)
		if anim.thrower_cover == -1:
			seen_throw = true
			check(anim.thrower_progress >= 0.0 and anim.thrower_progress <= 1.0, "progress in range")
	check(seen_throw, "the shortstop's throw is animated on him")
	check_eq(anim.thrower_cover, -2, "throw cue clears afterwards")


func test_runner_slides_into_a_close_play() -> void:
	var traj := BallTrajectory.simulate(30.0, -6.0, -15.0, tuning())
	var bases: Array[StringName] = [&"r1", &"", &""]
	# Shortstop gets to it late in the hole: a bang-bang force at second.
	var play := LivePlay.new(bases, &"bat", 0, -6.0, traj, _fielded(Vector3(-14, 0, -40), 1.75), tuning(), true)
	var anim := PlayAnimator.new()
	var slid := false
	while not play.is_done():
		play.step(tuning().sim_play_step)
		anim.update(play)
		var r := play.runner(&"r1")
		if r.state == LivePlay.State.RUNNING and anim.runner_cue(play, r)["pose"] == ActorView.Pose.SLIDE:
			slid = true
	check(slid, "runner from first slides into second on a close play")


func test_catch_pose_matches_how_the_ball_is_taken() -> void:
	var f := FieldingResult.new()
	f.fielder_index = 5
	f.secure_time = 2.0
	f.ready_time = 2.8
	f.secure_point = Vector3(0, 0.2, -30)
	var t := 1.0
	check_eq(PlayAnimator.catch_pose(t, f), -1, "still running to it")
	t = 1.9
	check_eq(PlayAnimator.catch_pose(t, f), ActorView.Pose.SCOOP, "scoops a grounder")
	f.secure_point.y = 2.2
	f.caught_in_air = true
	check_eq(PlayAnimator.catch_pose(t, f), ActorView.Pose.CATCH_HIGH, "reaches up for a high one")
	f.is_dive = true
	t = 2.6
	check_eq(PlayAnimator.catch_pose(t, f), ActorView.Pose.DIVE, "stays down until he is up")
	t = 3.0
	check_eq(PlayAnimator.catch_pose(t, f), -1, "back up after the dive")
