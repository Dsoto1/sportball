class_name TestCase
extends RefCounted
## Minimal dependency-free test base. Methods named test_* are run by
## tests/run_tests.gd. Each assertion failure is recorded, not thrown.

var failures: PackedStringArray = PackedStringArray()
var _current: String = ""
var _content: ContentLibrary


func content() -> ContentLibrary:
	if _content == null:
		_content = ContentLibrary.load_default()
	return _content


func tuning() -> BaseballTuning:
	return content().tuning


func begin(test_name: String) -> void:
	_current = test_name


func fail(message: String) -> void:
	failures.append("%s: %s" % [_current, message])


func check(condition: bool, message: String) -> void:
	if not condition:
		fail(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		fail("%s expected %s, got %s" % [message, str(expected), str(actual)])


func check_near(actual: float, expected: float, tolerance: float, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail("%s expected %.4f +/- %.4f, got %.4f" % [message, expected, tolerance, actual])


func new_match(innings: int = 6) -> MatchState:
	return MatchState.new(MatchState.placeholder_lineup("away"), MatchState.placeholder_lineup("home"), innings)
