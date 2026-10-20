extends SceneTree
## Hit rate and exit velocity by launch-angle bucket, AI vs AI.
##   godot --headless --path . -s res://tools/launch_angle_report.gd
func _initialize() -> void:
	var content := ContentLibrary.load_default()
	var t := content.tuning
	var buckets := {}
	for seed_value in 8:
		var sim := AutoMatch.new(500 + seed_value, content)
		var n := 0
		while not sim.state.game_over and n < 600:
			n += 1
			var intent := AiPitcher.choose(sim.state, content.pitches, t, sim.rng)
			var fam := content.pitch(intent.family_id)
			var pitch := PitchResolver.resolve(intent, fam, t, sim.rng)
			var swing := AiBatter.decide(pitch, fam, sim.state, t, sim.rng)
			var c := ContactResolver.resolve(pitch, swing, t, sim.rng)
			if c.outcome != ContactResult.Outcome.IN_PLAY:
				sim.state.apply_pitch_call(ContactResolver.call_for(pitch, c))
				continue
			var bip := BallInPlay.create(c, sim.state, t)
			var o := bip.resolve_ai()
			var key := "LA %+03d" % (floori(c.launch_angle / 10.0) * 10)
			var b: Array = buckets.get(key, [0, 0, 0.0])
			b[0] += 1
			b[1] += 1 if o.is_hit() else 0
			b[2] += c.exit_velocity
			buckets[key] = b
			sim.state.apply_play(o)
	var keys := buckets.keys()
	keys.sort()
	for k in keys:
		var b: Array = buckets[k]
		print("%s n=%4d hit%%=%5.1f avgEV=%.1f" % [k, b[0], 100.0 * b[1] / b[0], b[2] / b[0]])
	quit()
