class_name ContentLibrary
extends RefCounted
## Loads versioned definitions from res://data. Passed explicitly to the
## systems that need it rather than living in a global autoload.

const TUNING_PATH := "res://data/tuning/baseball_tuning.tres"
const PITCH_PATHS: Array[String] = [
	"res://data/pitches/fastball.tres",
	"res://data/pitches/sinker.tres",
	"res://data/pitches/cutter.tres",
	"res://data/pitches/splitter.tres",
	"res://data/pitches/slider.tres",
	"res://data/pitches/curveball.tres",
	"res://data/pitches/changeup.tres",
	"res://data/pitches/junkball.tres",
	"res://data/pitches/showstopper.tres",
]
const RULES_PATH := "res://data/rules/arcade.tres"
const TEAM_PATHS: Array[String] = [
	"res://data/teams/gearheads.tres",
	"res://data/teams/glitterati.tres",
]
## Every field position a defense must fill.
const FIELD_POSITIONS: Array[StringName] = [&"p", &"c", &"1b", &"2b", &"ss", &"3b", &"lf", &"cf", &"rf"]

var tuning: BaseballTuning
var pitches: Array[PitchFamilyDef] = []
var rules: MatchRules
var teams: Array[TeamDef] = []


static func load_default() -> ContentLibrary:
	var lib := ContentLibrary.new()
	lib.tuning = load(TUNING_PATH) as BaseballTuning
	assert(lib.tuning != null, "Missing tuning resource at %s" % TUNING_PATH)
	for path in PITCH_PATHS:
		var def := load(path) as PitchFamilyDef
		assert(def != null, "Missing pitch definition at %s" % path)
		lib.pitches.append(def)
	lib.rules = load(RULES_PATH) as MatchRules
	assert(lib.rules != null, "Missing rules at %s" % RULES_PATH)
	for path in TEAM_PATHS:
		var team := load(path) as TeamDef
		assert(team != null, "Missing team at %s" % path)
		lib.teams.append(team)
	return lib


func team(id: StringName) -> TeamDef:
	for t in teams:
		if t.id == id:
			return t
	push_error("Unknown team '%s'" % id)
	return null


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
	if rules == null:
		problems.append("rules missing")
	for t in teams:
		problems.append_array(_validate_team(t, seen))
	return problems


func _validate_team(t: TeamDef, pitch_ids: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var ids := {}
	for p in t.roster:
		if ids.has(p.id):
			problems.append("%s: duplicate player id '%s'" % [t.id, p.id])
		ids[p.id] = true
		for f in p.pitches:
			if p.is_pitcher() and not pitch_ids.has(f):
				problems.append("%s: %s throws unknown pitch '%s'" % [t.id, p.id, f])
	if t.batting_order.size() != 9 or t.lineup_positions.size() != 9:
		problems.append("%s: batting order needs nine hitters with positions" % t.id)
	for i in t.batting_order.size():
		var p := t.player(t.batting_order[i])
		if p == null:
			problems.append("%s: lineup player '%s' not on roster" % [t.id, t.batting_order[i]])
		elif p.is_pitcher():
			problems.append("%s: pitcher '%s' in the lineup (universal DH)" % [t.id, p.id])
	for pos in FIELD_POSITIONS:
		if pos != &"p" and not t.lineup_positions.has(pos):
			problems.append("%s: nobody plays %s" % [t.id, pos])
	for pid in [t.starting_pitcher] + Array(t.bullpen):
		var p := t.player(pid)
		if p == null or not p.is_pitcher():
			problems.append("%s: '%s' is not a pitcher on the roster" % [t.id, pid])
	return problems
