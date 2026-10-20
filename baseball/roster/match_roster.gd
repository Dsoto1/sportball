class_name MatchRoster
extends RefCounted
## The two clubs in a match, for looking up who a MatchState id is. Rules
## code works without one (placeholder lineups play at league average).

var teams: Array[TeamDef] = []


func _init(away: TeamDef, home: TeamDef) -> void:
	teams = [away, home]


func player(id: StringName) -> PlayerDef:
	for t in teams:
		var p := t.player(id)
		if p != null:
			return p
	return null


func team_of(id: StringName) -> TeamDef:
	for t in teams:
		if t.player(id) != null:
			return t
	return null
