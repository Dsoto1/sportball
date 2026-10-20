class_name ContentLibrary
extends RefCounted
## Loads versioned definitions from res://data. Passed explicitly to the
## systems that need it rather than living in a global autoload.

const TUNING_PATH := "res://data/tuning/baseball_tuning.tres"
const PITCH_PATHS: Array[String] = [
	"res://data/pitches/fastball.tres",
	"res://data/pitches/breaking_ball.tres",
	"res://data/pitches/changeup.tres",
]

var tuning: BaseballTuning
var pitches: Array[PitchFamilyDef] = []


static func load_default() -> ContentLibrary:
	var lib := ContentLibrary.new()
	lib.tuning = load(TUNING_PATH) as BaseballTuning
	assert(lib.tuning != null, "Missing tuning resource at %s" % TUNING_PATH)
	for path in PITCH_PATHS:
		var def := load(path) as PitchFamilyDef
		assert(def != null, "Missing pitch definition at %s" % path)
		lib.pitches.append(def)
	return lib


func pitch(id: StringName) -> PitchFamilyDef:
	for def in pitches:
		if def.id == id:
			return def
	push_error("Unknown pitch family '%s'" % id)
	return null


## Returns a list of human-readable problems with the loaded content.
func validate() -> PackedStringArray:
	var problems := PackedStringArray()
	if tuning == null:
		problems.append("tuning missing")
		return problems
	if tuning.fielder_ids.size() != tuning.fielder_spots.size():
		problems.append("fielder_ids and fielder_spots differ in length")
	if tuning.zone_bottom >= tuning.zone_top:
		problems.append("zone_bottom must be below zone_top")
	if tuning.innings < 1:
		problems.append("innings must be >= 1")
	var seen := {}
	for def in pitches:
		if def.id == &"":
			problems.append("pitch with empty id")
		elif seen.has(def.id):
			problems.append("duplicate pitch id '%s'" % def.id)
		seen[def.id] = true
		if def.speed <= 0.0:
			problems.append("pitch '%s' speed must be positive" % def.id)
	return problems
