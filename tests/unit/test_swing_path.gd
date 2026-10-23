extends TestCase
## The bat's way into contact (SwingPath) measured as Baseball Savant
## measures a swing: the sweet spot's tilt, attack angle and direction and
## speed at contact, and where contact happens.


func _measure(path: SwingPath, side: float) -> Dictionary:
	var dt := 0.0005
	var a: Vector3 = path.at(path.to_contact - dt)["sweet"]
	var b: Vector3 = path.at(path.to_contact + dt)["sweet"]
	var v := (b - a) / (2.0 * dt)
	var flat := Vector2(v.x, v.z).length()
	# Tilt from three points across the last 40 ms.
	var p0: Vector3 = path.at(path.to_contact - 0.04)["sweet"]
	var p1: Vector3 = path.at(path.to_contact - 0.02)["sweet"]
	var p2: Vector3 = path.at(path.to_contact)["sweet"]
	var n := (p1 - p0).cross(p2 - p1).normalized()
	return {
		"attack": rad_to_deg(atan2(v.y, flat)),
		"direction": rad_to_deg(atan2(v.x * side, -v.z)),
		"mph": v.length() / 0.44704,
		"tilt": rad_to_deg(acos(absf(n.y))),
	}


func test_path_matches_the_hitters_numbers() -> void:
	for side: float in [1.0, -1.0]:
		for profile: Dictionary in [
				{"tilt": 32.0, "attack_lift": 10.0, "attack_yaw": -2.0},
				{"tilt": 44.0, "attack_lift": 18.0, "attack_yaw": -14.0},
				{"tilt": 24.0, "attack_lift": 3.0, "attack_yaw": 9.0}]:
			var at := SwingPath.contact_point(profile)
			var path := SwingPath.build(profile, at, side, at + Vector3(-0.3 * side, 0.7, 0.8), Vector3.UP, 0.06, 74.0)
			var m := _measure(path, side)
			var label := "%s side %d" % [profile, side]
			check_near(m["tilt"], profile["tilt"], 1.0, "tilt " + label)
			check_near(m["attack"], profile["attack_lift"], 0.5, "attack angle " + label)
			check_near(m["direction"], profile["attack_yaw"], 0.5, "attack direction " + label)
			check_near(m["mph"], 74.0, 1.0, "bat speed " + label)
			check_near(path.at(path.to_contact)["sweet"].distance_to(at), 0.0, 0.01, "meets the ball " + label)


func test_contact_depth_follows_savant() -> void:
	# League average: about 3 in in front of the plate's front edge.
	var league := SwingPath.contact_depth({"attack_yaw": -2.0, "attack_lift": 10.2}) / 0.0254
	check_near(league, 3.0, 0.5, "league depth (in)")
	# Pull and uppercut swings meet it farther out front.
	check(SwingPath.contact_depth({"attack_yaw": -12.0, "attack_lift": 15.0}) > SwingPath.contact_depth({"attack_yaw": 8.0, "attack_lift": 4.0}), "pull hitters out front")
