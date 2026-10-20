class_name ContactSound
extends AudioStreamPlayer
## Bat-on-ball crack synthesized in code (no third-party audio): a short
## noise burst with a fast decay. Better contact is louder, brighter and
## shorter; a miss is a soft whoosh. Cosmetic randomness only.

const RATE := 22050

var _rng := RandomNumberGenerator.new()
var _cache := {}


func _ready() -> void:
	_rng.seed = 1
	bus = &"Master"


## tier: ContactFeedback.Tier
func play_tier(tier: int) -> void:
	if not _cache.has(tier):
		_cache[tier] = _make(tier)
	stream = _cache[tier]
	volume_db = [-14.0, -12.0, -8.0, -4.0, 0.0][clampi(tier, 0, 4)]
	play()


func _make(tier: int) -> AudioStreamWAV:
	var miss := tier == ContactFeedback.Tier.MISS
	var length := 0.22 if miss else lerpf(0.16, 0.08, tier / 4.0)
	var decay := 18.0 if miss else lerpf(30.0, 60.0, tier / 4.0)
	var brightness := 0.15 if miss else lerpf(0.35, 0.95, tier / 4.0)
	var frames := int(RATE * length)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var low := 0.0
	for i in frames:
		var t := float(i) / RATE
		var noise := _rng.randf_range(-1.0, 1.0)
		# One-pole low-pass: duller for weak contact, sharper for the barrel.
		low = lerpf(low, noise, brightness)
		var env := exp(-t * decay) * (minf(t * 400.0, 1.0) if miss else 1.0)
		var value := clampi(int(low * env * 30000.0), -32768, 32767)
		data.encode_s16(i * 2, value)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
