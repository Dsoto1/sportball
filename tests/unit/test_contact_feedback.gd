extends TestCase


func _contact(timing: float, location: Vector2, type: SwingIntent.Type = SwingIntent.Type.CONTACT) -> ContactResult:
	var intent := PitchIntent.new(&"fastball", location, 0.0)
	var pitch := PitchResolver.resolve(intent, content().pitch(&"fastball"), tuning(), MatchRng.new(1))
	pitch.location = location
	return ContactResolver.resolve(pitch, SwingIntent.swing(type, timing), tuning(), MatchRng.new(1))


func test_perfect_swing_down_the_middle_is_the_sweet_spot() -> void:
	var c := _contact(0.0, PitchResolver.zone_center(tuning()), SwingIntent.Type.POWER)
	var f := ContactFeedback.describe(c, tuning())
	check_eq(f["tier"], ContactFeedback.Tier.SWEET, "sweet spot")
	check_eq(f["headline"], "CRUSHED!", "power barrel is crushed")
	check(f["detail"].contains("PERFECT timing"), "explains timing: %s" % f["detail"])
	check(f["detail"].contains("middle of the zone"), "explains location: %s" % f["detail"])


func test_edge_pitch_explains_why_it_was_not_barreled() -> void:
	var c := _contact(0.0, Vector2(0.26, 1.1))
	var f := ContactFeedback.describe(c, tuning())
	check(f["tier"] < ContactFeedback.Tier.SWEET, "not the sweet spot")
	check_eq(f["headline"], "", "no big callout")
	check(f["detail"].contains("edge") or f["detail"].contains("chased"), "names the location: %s" % f["detail"])


func test_late_swing_is_called_late() -> void:
	var c := _contact(0.06, PitchResolver.zone_center(tuning()))
	var f := ContactFeedback.describe(c, tuning())
	check(f["detail"].contains("late 60 ms"), "timing in ms: %s" % f["detail"])


func test_whiff_is_a_miss() -> void:
	var c := _contact(0.4, PitchResolver.zone_center(tuning()))
	check_eq(ContactFeedback.tier(c), ContactFeedback.Tier.MISS)


func test_slightly_off_is_a_hair_not_perfect() -> void:
	var window := tuning().contact_timing_window
	var c := _contact(window * 0.2, PitchResolver.zone_center(tuning()))
	var f := ContactFeedback.describe(c, tuning())
	check(f["detail"].contains("a hair late"), "close but not perfect: %s" % f["detail"])
