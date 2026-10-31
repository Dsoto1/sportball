class_name Sfx
extends Node
## Game sound effects: Kenney CC0 samples (glove pops, ball thuds, bag
## touches, menu clicks) with pitch and pick variation, plus a crowd made
## in code: a looping murmur and cheers that swell with the moment.
## Cosmetic randomness only.

const KENNEY := "res://assets/third_party/kenney/"
const BANKS := {
	&"glove": ["impact-sounds/impactPunch_medium_000", "impact-sounds/impactPunch_medium_001", "impact-sounds/impactPunch_medium_002", "impact-sounds/impactPunch_medium_003", "impact-sounds/impactPunch_medium_004"],
	&"glove_big": ["impact-sounds/impactPunch_heavy_000", "impact-sounds/impactPunch_heavy_001", "impact-sounds/impactPunch_heavy_002"],
	&"bat": ["impact-sounds/impactWood_heavy_000", "impact-sounds/impactWood_heavy_001", "impact-sounds/impactWood_heavy_002", "impact-sounds/impactWood_heavy_003", "impact-sounds/impactWood_heavy_004"],
	&"ball_land": ["impact-sounds/impactSoft_medium_000", "impact-sounds/impactSoft_medium_001", "impact-sounds/impactSoft_medium_002", "impact-sounds/impactSoft_medium_003"],
	&"slide": ["impact-sounds/impactSoft_heavy_000", "impact-sounds/impactSoft_heavy_001", "impact-sounds/impactSoft_heavy_002"],
	&"bag": ["impact-sounds/impactPlate_light_000", "impact-sounds/impactPlate_light_001", "impact-sounds/impactPlate_light_002"],
	&"step": ["impact-sounds/footstep_grass_000", "impact-sounds/footstep_grass_001", "impact-sounds/footstep_grass_002", "impact-sounds/footstep_grass_003", "impact-sounds/footstep_grass_004"],
	&"ui_tick": ["interface-sounds/tick_001", "interface-sounds/tick_002"],
	&"ui_select": ["interface-sounds/select_001", "interface-sounds/select_002"],
	&"ui_confirm": ["interface-sounds/confirmation_001", "interface-sounds/confirmation_002"],
	&"ui_error": ["interface-sounds/error_004"],
	&"ui_toggle": ["interface-sounds/toggle_001", "interface-sounds/toggle_002"],
	&"out": ["interface-sounds/bong_001"],
}
const VOLUME := {&"glove": -4.0, &"glove_big": -2.0, &"bat": -10.0, &"ball_land": -8.0, &"slide": -6.0, &"bag": -9.0,
	&"step": -16.0, &"ui_tick": -10.0, &"ui_select": -8.0, &"ui_confirm": -6.0, &"ui_error": -6.0, &"ui_toggle": -8.0, &"out": -10.0}
const VOICES := 10
const RATE := 22050

var _rng := RandomNumberGenerator.new()
var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _crowd: AudioStreamPlayer
var _cheer: AudioStreamPlayer
var _cheer_level := 0.0


func _ready() -> void:
	_rng.seed = 7
	for name: StringName in BANKS:
		var list: Array[AudioStream] = []
		for path: String in BANKS[name]:
			var stream := load(KENNEY + path + ".ogg") as AudioStream
			if stream != null:
				list.append(stream)
		_streams[name] = list
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"Effects"
		add_child(p)
		_players.append(p)
	_crowd = AudioStreamPlayer.new()
	_crowd.stream = _crowd_loop()
	_crowd.volume_db = -26.0
	_crowd.bus = &"Crowd"
	add_child(_crowd)
	_crowd.play()
	_cheer = AudioStreamPlayer.new()
	_cheer.stream = _cheer_burst()
	_cheer.bus = &"Crowd"
	add_child(_cheer)


## Plays one sample from a bank with a little pitch variation.
func play(name: StringName, volume_offset: float = 0.0, pitch: float = 1.0) -> void:
	var list: Array = _streams.get(name, [])
	if list.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = list[_rng.randi_range(0, list.size() - 1)]
	p.volume_db = VOLUME.get(name, -8.0) + volume_offset
	p.pitch_scale = pitch * _rng.randf_range(0.93, 1.07)
	p.play()


## The crowd reacts: 0..1 (a single ~0.4, a home run 1.0).
func cheer(level: float) -> void:
	if level < _cheer_level and _cheer.playing:
		return
	_cheer_level = level
	_cheer.volume_db = lerpf(-24.0, -6.0, clampf(level, 0.0, 1.0))
	_cheer.pitch_scale = lerpf(0.9, 1.05, level)
	_cheer.play()


func _process(delta: float) -> void:
	if not _cheer.playing:
		_cheer_level = 0.0
	_crowd.volume_db = lerpf(_crowd.volume_db, -26.0, 1.0 - exp(-delta))


## A low murmur: band-limited noise with slow swells, looped seamlessly.
func _crowd_loop() -> AudioStreamWAV:
	var seconds := 4.0
	var frames := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var low := 0.0
	var lower := 0.0
	for i in frames:
		var t := float(i) / RATE
		low = lerpf(low, _rng.randf_range(-1.0, 1.0), 0.12)
		lower = lerpf(lower, low, 0.25)
		var swell := 0.75 + 0.25 * sin(TAU * t / seconds) * sin(TAU * 3.0 * t / seconds)
		data.encode_s16(i * 2, clampi(int(lower * swell * 52000.0), -32768, 32767))
	return _wav(data, true)


## A cheer: a broadband roar that rises fast and dies away.
func _cheer_burst() -> AudioStreamWAV:
	var seconds := 2.6
	var frames := int(RATE * seconds)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var low := 0.0
	var mid := 0.0
	for i in frames:
		var t := float(i) / RATE
		var n := _rng.randf_range(-1.0, 1.0)
		low = lerpf(low, n, 0.08)
		mid = lerpf(mid, n, 0.35)
		var env := minf(t / 0.18, 1.0) * exp(-maxf(t - 0.4, 0.0) * 1.6)
		var flutter := 0.85 + 0.15 * sin(TAU * 7.0 * t + sin(TAU * 1.3 * t))
		data.encode_s16(i * 2, clampi(int((low * 1.6 + mid * 0.5) * env * flutter * 26000.0), -32768, 32767))
	return _wav(data, false)


func _wav(data: PackedByteArray, loop: bool) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = data.size() / 2
	return wav
