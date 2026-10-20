class_name MatchRng
extends RefCounted
## Gameplay randomness for one match. The seed is recorded so any outcome
## can be reproduced. Cosmetic randomness must use its own generator.

var seed_value: int
var _rng := RandomNumberGenerator.new()


func _init(p_seed: int) -> void:
	seed_value = p_seed
	_rng.seed = p_seed


func randf() -> float:
	return _rng.randf()


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func randfn(mean: float = 0.0, deviation: float = 1.0) -> float:
	return _rng.randfn(mean, deviation)


func chance(probability: float) -> bool:
	return _rng.randf() < probability


func pick_index(count: int) -> int:
	return _rng.randi_range(0, count - 1)
