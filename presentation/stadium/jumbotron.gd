class_name Jumbotron
extends SubViewport
## The park's video board: a 2D display drawn off-screen and shown on the
## centerpiece's screen. Between plays it is the scoreboard (the two clubs
## and the score across the top with the inning, the batter's card in the
## batting club's colors, the count and outs along the bottom). After a
## big moment it takes over with a full-screen celebration: HOME RUN (and
## GRAND SLAM) with burst rays, confetti and the Statcast line (distance,
## exit velocity, launch angle), or a strikeout's big K.

const FONT := preload("res://assets/third_party/fonts/bungee/Bungee-Regular.ttf")
const W := 1280
const H := 720
## How long each celebration holds the board.
const MOMENT_SECONDS := {&"home_run": 7.5, &"strikeout": 2.6, &"double_play": 2.8}

var _home: TeamDef
var _away: TeamDef
var _root: Control
var _board: Control
var _moment: Control
var _rays: _Rays
var _confetti: _Confetti
var _labels := {}
var _moment_kind: StringName = &""
var _moment_age := 0.0
var _moment_data := {}
var _dots := {}
var _batting := 0
var _key := ""


func setup(home: TeamDef, away: TeamDef) -> void:
	_home = home
	_away = away
	size = Vector2i(W, H)
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	transparent_bg = false
	_root = Control.new()
	_root.size = Vector2(W, H)
	add_child(_root)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.05)
	bg.size = Vector2(W, H)
	_root.add_child(bg)
	_build_board()
	_build_moment()


## Shows the match: called whenever the state may have changed (cheap when
## it has not).
func show_state(state: MatchState, roster: MatchRoster) -> void:
	var p := roster.player(state.current_batter()) if roster != null else null
	var key := "%s|%s|%d%d%d|%s|%d%s|%d" % [state.score, state.line_score.size(), state.balls, state.strikes, state.outs, state.current_batter(), state.inning, state.is_top, state.pitch_count]
	if key == _key:
		return
	_key = key
	_batting = state.batting_team()
	var club: TeamDef = _away if _batting == MatchState.AWAY else _home
	_labels["away_score"].text = str(state.score[MatchState.AWAY])
	_labels["home_score"].text = str(state.score[MatchState.HOME])
	_labels["inning"].text = ("TOP" if state.is_top else "BOT") + "\n" + _ordinal(state.inning)
	if state.game_over:
		_labels["inning"].text = "FINAL"
	_labels["card_bg"].color = club.primary_color
	_labels["card_stripe"].color = club.secondary_color
	_labels["band"].color = club.dark_color.lerp(Color.BLACK, 0.3)
	if p != null:
		var line := SeasonLine.for_player(p)
		_labels["number"].text = "#%d" % p.number
		_labels["name"].text = p.display_name.to_upper()
		var position: StringName = &"DH"
		var defense: Dictionary = state.defense[_batting]
		for pos: StringName in defense:
			if defense[pos] == p.id:
				position = StringName(String(pos).to_upper())
		_labels["position"].text = "%s  ·  BATS %s" % [position, String(p.bats)]
		_labels["avg"].text = SeasonLine.avg_text(line["avg"])
		_labels["hr"].text = str(line["hr"])
		_labels["rbi"].text = str(line["rbi"])
	var pitcher_id := state.pitcher(state.fielding_team())
	var pitcher := roster.player(pitcher_id) if roster != null else null
	_labels["pitcher"].text = "PITCHING\n%s  ·  %d P" % [pitcher.display_name.to_upper().get_slice(" ", pitcher.display_name.get_slice_count(" ") - 1), state.pitches_thrown(pitcher_id)] if pitcher != null else ""
	var counts := {"B": state.balls, "S": state.strikes, "O": state.outs}
	for k: String in _dots:
		var row: Array = _dots[k]
		for i in row.size():
			(row[i] as Panel).modulate = Color.WHITE if i < counts[k] else Color(1, 1, 1, 0.12)


## Takes the board over for a celebration. data: name, number, team (the
## batting club), distance (ft), exit_velocity (mph), launch (deg), runs.
func play_moment(kind: StringName, data: Dictionary = {}) -> void:
	_moment_kind = kind
	_moment_age = 0.0
	_moment_data = data
	var club: TeamDef = data.get("team", _home)
	_rays.color_a = club.primary_color
	_rays.color_b = club.secondary_color.lerp(Color.WHITE, 0.15)
	_confetti.colors = [club.primary_color.lightened(0.2), club.secondary_color, club.highlight_color, club.accent_color]
	_confetti.reset()
	var title: Label = _labels["title"]
	var sub: Label = _labels["subtitle"]
	match kind:
		&"home_run":
			title.text = "GRAND SLAM!" if int(data.get("runs", 1)) >= 4 else "HOME RUN!"
			sub.text = "#%d %s" % [int(data.get("number", 0)), String(data.get("name", "")).to_upper()]
			_labels["s1"].text = "%d FT" % int(data.get("distance", 0))
			_labels["s2"].text = "%d MPH" % int(data.get("exit_velocity", 0))
			_labels["s3"].text = "%d°" % int(data.get("launch", 0))
		&"strikeout":
			title.text = "K"
			sub.text = "STRUCK OUT"
		&"double_play":
			title.text = "TWO!"
			sub.text = "DOUBLE PLAY"
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.3) if kind == &"home_run" else club.highlight_color)
	title.add_theme_color_override("font_outline_color", club.dark_color)
	_moment.visible = true
	_board.visible = false


func _process(delta: float) -> void:
	if _moment_kind == &"":
		return
	_moment_age += delta
	var age := _moment_age
	var total: float = MOMENT_SECONDS.get(_moment_kind, 3.0)
	_rays.spin += delta * 0.35
	_rays.queue_redraw()
	_confetti.advance(delta)
	# The title springs in, overshoots, settles, then pulses on the beat.
	var title: Label = _labels["title"]
	var pop := 1.0
	if age < 0.6:
		var u := age / 0.6
		pop = 1.0 + sin(u * PI * 2.5) * (1.0 - u) * 0.6
		pop *= minf(u * 3.0, 1.0)
	else:
		pop = 1.0 + 0.04 * sin(age * 8.0)
	title.pivot_offset = title.size * 0.5
	title.scale = Vector2.ONE * pop
	# The stat tiles slide up after the title lands (home runs).
	var stats: Control = _labels["stats"]
	stats.visible = _moment_kind == &"home_run"
	var slide := clampf((age - 1.1) / 0.45, 0.0, 1.0)
	stats.position.y = lerpf(H + 20.0, 470.0, 1.0 - pow(1.0 - slide, 3.0))
	var sub: Label = _labels["subtitle"]
	sub.modulate.a = clampf((age - 0.5) / 0.4, 0.0, 1.0)
	# Flash the whole board white for a beat on the hit.
	_labels["flash"].color.a = maxf(0.0, 0.85 - age * 2.5)
	if age > total:
		_moment_kind = &""
		_moment.visible = false
		_board.visible = true


func _build_board() -> void:
	_board = Control.new()
	_board.size = Vector2(W, H)
	_root.add_child(_board)
	# Top: the two clubs and the score, the inning between them.
	for side in 2:
		var club: TeamDef = _away if side == 0 else _home
		var panel := ColorRect.new()
		panel.color = club.primary_color.darkened(0.15)
		panel.position = Vector2(0 if side == 0 else W * 0.5 + 70, 0)
		panel.size = Vector2(W * 0.5 - 70, 130)
		_board.add_child(panel)
		var stripe := ColorRect.new()
		stripe.color = club.secondary_color
		stripe.position = panel.position + Vector2(0, 122)
		stripe.size = Vector2(panel.size.x, 8)
		_board.add_child(stripe)
		var abbr := _label(club.abbreviation, 66, Color(1, 1, 1, 0.92))
		abbr.add_theme_constant_override("outline_size", 10)
		abbr.add_theme_color_override("font_outline_color", club.dark_color)
		abbr.position = panel.position + Vector2(30 if side == 0 else panel.size.x - 330, 22)
		abbr.size = Vector2(300, 90)
		abbr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if side == 0 else HORIZONTAL_ALIGNMENT_RIGHT
		_board.add_child(abbr)
		var score := _label("0", 96, Color.WHITE)
		score.position = panel.position + Vector2(panel.size.x - 190 if side == 0 else 20, 4)
		score.size = Vector2(170, 120)
		score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_board.add_child(score)
		_labels["away_score" if side == 0 else "home_score"] = score
	var mid := ColorRect.new()
	mid.color = Color(0.08, 0.08, 0.1)
	mid.position = Vector2(W * 0.5 - 70, 0)
	mid.size = Vector2(140, 130)
	_board.add_child(mid)
	var inning := _label("TOP\n1ST", 34, Color(1.0, 0.85, 0.3))
	inning.position = mid.position + Vector2(0, 14)
	inning.size = Vector2(140, 100)
	inning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board.add_child(inning)
	_labels["inning"] = inning
	# Middle: the batter's card in his club's colors.
	var band := ColorRect.new()
	band.position = Vector2(0, 150)
	band.size = Vector2(W, 410)
	_board.add_child(band)
	_labels["band"] = band
	var card := ColorRect.new()
	card.position = Vector2(40, 170)
	card.size = Vector2(330, 370)
	_board.add_child(card)
	_labels["card_bg"] = card
	var card_stripe := ColorRect.new()
	card_stripe.position = Vector2(40, 520)
	card_stripe.size = Vector2(330, 20)
	_board.add_child(card_stripe)
	_labels["card_stripe"] = card_stripe
	var number := _label("#0", 150, Color.WHITE)
	number.position = Vector2(40, 230)
	number.size = Vector2(330, 220)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	number.add_theme_constant_override("outline_size", 18)
	number.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	_board.add_child(number)
	_labels["number"] = number
	var at_bat := _label("NOW BATTING", 30, Color(1, 1, 1, 0.65))
	at_bat.position = Vector2(410, 185)
	_board.add_child(at_bat)
	var name := _label("", 76, Color.WHITE)
	name.position = Vector2(410, 222)
	name.size = Vector2(840, 100)
	name.clip_text = true
	_board.add_child(name)
	_labels["name"] = name
	var position := _label("", 32, Color(1.0, 0.85, 0.3))
	position.position = Vector2(410, 320)
	_board.add_child(position)
	_labels["position"] = position
	for i in 3:
		var tile := ColorRect.new()
		tile.color = Color(0, 0, 0, 0.35)
		tile.position = Vector2(410 + i * 285, 385)
		tile.size = Vector2(265, 150)
		_board.add_child(tile)
		var head := _label(["AVG", "HR", "RBI"][i], 28, Color(1, 1, 1, 0.6))
		head.position = tile.position + Vector2(0, 12)
		head.size = Vector2(265, 40)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_board.add_child(head)
		var value := _label("", 70, Color.WHITE)
		value.position = tile.position + Vector2(0, 46)
		value.size = Vector2(265, 96)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_board.add_child(value)
		_labels[["avg", "hr", "rbi"][i]] = value
	# Bottom: balls, strikes and outs as lamps.
	var foot := ColorRect.new()
	foot.color = Color(0.06, 0.06, 0.08)
	foot.position = Vector2(0, 580)
	foot.size = Vector2(W, 140)
	_board.add_child(foot)
	var groups := [["B", 3, Color(0.3, 1.0, 0.45)], ["S", 2, Color(1.0, 0.3, 0.25)], ["O", 2, Color(1.0, 0.75, 0.2)]]
	var x := 60.0
	for g: Array in groups:
		var tag := _label(g[0], 64, Color.WHITE)
		tag.position = Vector2(x, 598)
		_board.add_child(tag)
		var row: Array = []
		for i in int(g[1]):
			var dot := Panel.new()
			var style := StyleBoxFlat.new()
			style.bg_color = g[2]
			style.set_corner_radius_all(40)
			style.shadow_color = Color(g[2], 0.6)
			style.shadow_size = 12
			dot.add_theme_stylebox_override("panel", style)
			dot.position = Vector2(x + 80 + i * 78, 612)
			dot.size = Vector2(60, 60)
			_board.add_child(dot)
			row.append(dot)
		_dots[g[0]] = row
		x += 80 + int(g[1]) * 78 + 60
	var pitcher := _label("", 30, Color(1, 1, 1, 0.85))
	pitcher.position = Vector2(960, 600)
	pitcher.size = Vector2(290, 100)
	pitcher.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pitcher.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board.add_child(pitcher)
	_labels["pitcher"] = pitcher


func _build_moment() -> void:
	_moment = Control.new()
	_moment.size = Vector2(W, H)
	_moment.visible = false
	_root.add_child(_moment)
	_rays = _Rays.new()
	_rays.size = Vector2(W, H)
	_moment.add_child(_rays)
	_confetti = _Confetti.new()
	_confetti.size = Vector2(W, H)
	_moment.add_child(_confetti)
	var title := _label("HOME RUN!", 190, Color.WHITE)
	title.position = Vector2(0, 90)
	title.size = Vector2(W, 260)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 36)
	_moment.add_child(title)
	_labels["title"] = title
	var sub := _label("", 54, Color.WHITE)
	sub.position = Vector2(0, 345)
	sub.size = Vector2(W, 80)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_constant_override("outline_size", 14)
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_moment.add_child(sub)
	_labels["subtitle"] = sub
	var stats := Control.new()
	stats.size = Vector2(W, 220)
	_moment.add_child(stats)
	_labels["stats"] = stats
	for i in 3:
		var tile := ColorRect.new()
		tile.color = Color(0, 0, 0, 0.55)
		tile.position = Vector2(70 + i * 390, 0)
		tile.size = Vector2(360, 200)
		stats.add_child(tile)
		var head := _label(["DISTANCE", "EXIT VELO", "LAUNCH"][i], 30, Color(1, 1, 1, 0.7))
		head.position = tile.position + Vector2(0, 18)
		head.size = Vector2(360, 40)
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_child(head)
		var value := _label("", 84, Color.WHITE)
		value.position = tile.position + Vector2(0, 62)
		value.size = Vector2(360, 120)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats.add_child(value)
		_labels["s%d" % (i + 1)] = value
	var flash := ColorRect.new()
	flash.size = Vector2(W, H)
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment.add_child(flash)
	_labels["flash"] = flash


static func _label(text: String, size_px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", color)
	return l


static func _ordinal(n: int) -> String:
	var suffix := "TH"
	if n % 100 < 11 or n % 100 > 13:
		suffix = ["TH", "ST", "ND", "RD", "TH", "TH", "TH", "TH", "TH", "TH"][n % 10]
	return "%d%s" % [n, suffix]


## Burst rays turning behind the title.
class _Rays extends Control:
	var color_a := Color.RED
	var color_b := Color.WHITE
	var spin := 0.0

	func _draw() -> void:
		var c := size * 0.5 + Vector2(0, -60)
		draw_rect(Rect2(Vector2.ZERO, size), color_a.darkened(0.25))
		var n := 18
		for i in n:
			var a0 := spin + TAU * i / n
			var a1 := a0 + TAU / n * 0.5
			var r := size.length()
			draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r]), Color(color_b, 0.22))
		draw_circle(c, 170.0, Color(color_b, 0.18))


## Confetti falling and fluttering.
class _Confetti extends Control:
	var colors: Array = [Color.WHITE]
	var _bits: Array = []

	func reset() -> void:
		_bits.clear()
		var rng := RandomNumberGenerator.new()
		for i in 120:
			_bits.append([Vector2(rng.randf() * size.x, -rng.randf() * size.y), Vector2(rng.randf_range(-40, 40), rng.randf_range(160, 320)), rng.randf() * TAU, rng.randf_range(-6, 6), colors[i % colors.size()], rng.randf_range(10, 22)])

	func advance(delta: float) -> void:
		for b: Array in _bits:
			b[0] += b[1] * delta + Vector2(sin(b[2]) * 30.0 * delta, 0)
			b[2] += b[3] * delta
		queue_redraw()

	func _draw() -> void:
		for b: Array in _bits:
			var p: Vector2 = b[0]
			var s: float = b[5]
			var w := s * absf(cos(b[2]))
			draw_rect(Rect2(p - Vector2(w, s * 0.5) * 0.5, Vector2(maxf(w, 2.0), s * 0.5)), b[4])
