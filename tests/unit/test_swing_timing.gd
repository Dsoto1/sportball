extends TestCase

const FRAME := 1.0 / 60.0


func test_on_time_press_reads_zero() -> void:
	# Pressed exactly at arrival; delivered half a frame later on average.
	var release := 1_000_000
	var press := release + roundi((0.45 + 0.5 * FRAME) * 1000000.0)
	check_near(SwingTiming.offset(press, release, 0.45, FRAME), 0.0, 0.0001, "on time")


func test_early_and_late_sign() -> void:
	check(SwingTiming.offset(1_200_000, 1_000_000, 0.45, 0.0) < 0.0, "early is negative")
	check(SwingTiming.offset(1_700_000, 1_000_000, 0.45, 0.0) > 0.0, "late is positive")


func test_calibration_shifts_timing() -> void:
	var base := SwingTiming.offset(1_500_000, 1_000_000, 0.45, FRAME)
	check_near(SwingTiming.offset(1_500_000, 1_000_000, 0.45, FRAME, 0.03), base - 0.03, 0.0001, "calibration")


func test_hitch_does_not_shift_swing_by_more_than_cap() -> void:
	var normal := SwingTiming.offset(1_500_000, 1_000_000, 0.45, 0.0)
	var hitch := SwingTiming.offset(1_500_000, 1_000_000, 0.45, 0.5)
	check_near(normal - hitch, 0.5 * SwingTiming.MAX_FRAME_INTERVAL, 0.0001, "correction capped")


## Presses land anywhere inside a frame and are only seen at the next frame
## boundary. The corrected timing should be unbiased and within half a
## frame; the old per-frame polling was late by half a frame on average.
func test_removes_frame_delivery_bias() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var release := 0
	var travel := 0.45
	var corrected_sum := 0.0
	var naive_sum := 0.0
	var worst := 0.0
	var samples := 4000
	for i in samples:
		var true_offset := rng.randf_range(-0.1, 0.1)
		var pressed := travel + true_offset
		var delivered := ceilf(pressed / FRAME) * FRAME
		var press_usec := roundi(delivered * 1000000.0)
		var corrected := SwingTiming.offset(press_usec, release, travel, FRAME)
		var naive := delivered - travel
		corrected_sum += corrected - true_offset
		naive_sum += naive - true_offset
		worst = maxf(worst, absf(corrected - true_offset))
	check_near(corrected_sum / samples, 0.0, 0.0005, "corrected mean error")
	check_near(naive_sum / samples, 0.5 * FRAME, 0.0005, "naive polling was late by half a frame")
	check(worst <= 0.5 * FRAME + 0.0001, "error within half a frame (%.4f)" % worst)
