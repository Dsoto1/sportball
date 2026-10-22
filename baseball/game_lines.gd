class_name GameLines
extends RefCounted
## Today's lines, read from a match's events: a pitcher's IP, H, R, BB, K
## and a batter's hits in at-bats (with HR and RBI-free summary). Pure
## reads; nothing here feeds back into play.

const HITS := [PlayOutcome.KIND_SINGLE, PlayOutcome.KIND_DOUBLE, PlayOutcome.KIND_TRIPLE, PlayOutcome.KIND_HOME_RUN, PlayOutcome.KIND_INSIDE_PARK_HR]
## Plate appearances that are not at-bats.
const NOT_AT_BATS := [&"walk", PlayOutcome.KIND_SACRIFICE]


## {outs, ip ("2.1" style), h, r, bb, k} for a pitcher.
static func pitcher(state: MatchState, pitcher_id: StringName) -> Dictionary:
	var line := {"outs": 0, "h": 0, "r": 0, "bb": 0, "k": 0}
	for e in state.events:
		if e.data.get("pitcher", &"") != pitcher_id:
			continue
		match e.type:
			DomainEvent.OUT_RECORDED:
				line["outs"] += 1
			DomainEvent.RUN_SCORED:
				line["r"] += 1
			DomainEvent.PLATE_APPEARANCE_ENDED:
				var result: StringName = e.data.get("result", &"")
				if result in HITS:
					line["h"] += 1
				elif result == &"walk":
					line["bb"] += 1
				elif result == &"strikeout":
					line["k"] += 1
	line["ip"] = "%d.%d" % [line["outs"] / 3, line["outs"] % 3]
	return line


## {ab, h, hr} for a batter today.
static func batter(state: MatchState, batter_id: StringName) -> Dictionary:
	var line := {"ab": 0, "h": 0, "hr": 0}
	for e in state.events:
		if e.type != DomainEvent.PLATE_APPEARANCE_ENDED or e.data.get("batter", &"") != batter_id:
			continue
		var result: StringName = e.data.get("result", &"")
		if not result in NOT_AT_BATS:
			line["ab"] += 1
		if result in HITS:
			line["h"] += 1
		if result in [PlayOutcome.KIND_HOME_RUN, PlayOutcome.KIND_INSIDE_PARK_HR]:
			line["hr"] += 1
	return line
