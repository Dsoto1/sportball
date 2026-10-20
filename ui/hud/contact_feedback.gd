class_name ContactFeedback
extends RefCounted
## Turns a resolved swing into words a player can learn from: how good the
## contact was, and why (timing, pitch location). Pure, so it can be tested.

enum Tier { MISS, WEAK, OK, SOLID, SWEET }

## Contact quality at or above this is the sweet spot.
const SWEET := 0.9
const SOLID := 0.7
const OK := 0.45
## Timing within this fraction of the swing's window is sweet-spot timing
## ("perfect"); within HAIR it is "a hair" off.
const PERFECT_NORM := 0.12
const HAIR_NORM := 0.35


static func tier(contact: ContactResult) -> Tier:
	if contact.outcome == ContactResult.Outcome.WHIFF or contact.outcome == ContactResult.Outcome.TAKE:
		return Tier.MISS
	if contact.quality >= SWEET:
		return Tier.SWEET
	if contact.quality >= SOLID:
		return Tier.SOLID
	if contact.quality >= OK:
		return Tier.OK
	return Tier.WEAK


## {headline, detail, tier}. headline is empty except for a sweet-spot hit
## (kept rare, per the UI brief); detail always explains the swing.
static func describe(contact: ContactResult, tuning: BaseballTuning) -> Dictionary:
	var t := tier(contact)
	var ms := roundi(contact.timing_offset * 1000.0)
	var off := absf(contact.timing_norm)
	var side := "early" if ms < 0 else "late"
	var timing := "PERFECT timing"
	if off > HAIR_NORM:
		timing = "%s %d ms" % [side, absi(ms)]
	elif off > PERFECT_NORM:
		timing = "a hair %s (%d ms)" % [side, absi(ms)]
	var spot := "middle of the zone"
	if contact.location_norm > tuning.reach_limit:
		spot = "way off the plate"
	elif contact.location_norm > 1.05:
		spot = "chased it outside the zone"
	elif contact.location_norm > tuning.sweet_zone:
		spot = "on the edge of the zone"
	var label: String = {
		Tier.MISS: "MISSED",
		Tier.WEAK: "WEAK contact",
		Tier.OK: "OK contact",
		Tier.SOLID: "SOLID contact",
		Tier.SWEET: "SWEET SPOT",
	}[t]
	var headline := ""
	if t == Tier.SWEET and contact.outcome == ContactResult.Outcome.IN_PLAY:
		headline = "CRUSHED!" if contact.swing_type == SwingIntent.Type.POWER else "BARRELED!"
	var detail := "%s · %s · %s" % [label, timing, spot]
	if t != Tier.MISS and contact.outcome == ContactResult.Outcome.IN_PLAY:
		detail += " · %.0f m/s, %d°" % [contact.exit_velocity, roundi(contact.launch_angle)]
	return {"headline": headline, "detail": detail, "tier": t}
