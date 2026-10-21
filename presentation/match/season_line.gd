class_name SeasonLine
## A hitter's season numbers for the boards (AVG, HR, RBI), drawn from his
## ratings with a steady per-player wobble. Presentation only: there is no
## season simulation yet, and nothing reads these back into play.


static func for_player(p: PlayerDef) -> Dictionary:
	var wobble := func(what: String) -> float: return float(absi(hash(String(p.id) + what)) % 1000) / 1000.0 - 0.5
	var avg := clampf(0.205 + p.contact * 0.0012 + wobble.call("avg") * 0.03, 0.160, 0.360)
	var hr := maxi(0, roundi(p.power * 0.42 - 4.0 + wobble.call("hr") * 8.0))
	var rbi := maxi(hr, roundi(hr * 2.1 + p.contact * 0.45 + 8.0 + wobble.call("rbi") * 12.0))
	return {"avg": avg, "hr": hr, "rbi": rbi}


## ".312" style.
static func avg_text(avg: float) -> String:
	return (".%03d" % roundi(avg * 1000.0)) if avg < 1.0 else "1.000"
