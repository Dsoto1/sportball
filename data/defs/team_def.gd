class_name TeamDef
extends Resource
## A club: identity, colors, roster, default lineup and how its AI plays.

@export var id: StringName
@export var city: String
@export var team_name: String
## Three-letter scoreboard abbreviation.
@export var abbreviation: String
## The club's color set (the six roles on its reference sheet): primary
## and secondary carry the uniform, accent the trim and neon, support a
## fourth color for signs, dark the backgrounds and outlines, highlight the
## lettering on dark.
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.BLACK
@export var accent_color: Color = Color.GRAY
@export var support_color: Color = Color(0.6, 0.62, 0.66)
@export var dark_color: Color = Color(0.1, 0.1, 0.12)
@export var highlight_color: Color = Color(0.96, 0.95, 0.92)
## The line on the club's signs ("Built Harder Together").
@export var slogan: String
@export_group("Emblem")
## The club's mark, used on boards, walls, dugouts and banners: a badge
## shape (&"disc", &"shield", &"gear", &"halo", &"diamond", &"laurel",
## &"star", &"atom") with a glyph on it (a letter or two, or "*" for a star).
## A texture, when set, replaces the drawn mark (a finished logo).
@export var emblem_shape: StringName = &"disc"
@export var emblem_glyph: String = ""
@export var emblem_texture: Texture2D
@export_group("")
@export var mascot: String
@export var stadium: String
## Look of the home park (presentation only).
@export var stadium_def: StadiumDef
@export_multiline var identity: String
@export var rival: StringName

@export_group("Roster")
@export var roster: Array[PlayerDef] = []
## Batting order (player ids, 9 with the universal DH) and the field
## position each one plays (&"dh" for the designated hitter).
@export var batting_order: Array[StringName] = []
@export var lineup_positions: Array[StringName] = []
@export var starting_pitcher: StringName
## Relievers in the order the AI brings them in; the last is the closer.
@export var bullpen: Array[StringName] = []

@export_group("AI Personality")
## Multiplier on how often AI batters swing.
@export var swing_aggression: float = 1.0
## Multiplier on how often AI batters chase pitches outside the zone.
@export var chase_scale: float = 1.0
@export var power_swing_rate: float = 0.35
## Seconds taken off runners' safety margins (+ = more aggressive).
@export var runner_aggression: float = 0.0
## Multiplier on how much AI pitchers work the edges (+ = nibbles more).
@export var edge_bias_scale: float = 1.0
## Fatigue (0..1) at which the AI goes to the bullpen.
@export var bullpen_hook: float = 0.6
## Multipliers on how often the AI runs and bunts (1 = league average).
@export var steal_rate: float = 1.0
@export var bunt_rate: float = 1.0


func player(player_id: StringName) -> PlayerDef:
	for p in roster:
		if p.id == player_id:
			return p
	return null


## The color set by role, for parks, signs and a future team designer.
func palette() -> Dictionary:
	return {"primary": primary_color, "secondary": secondary_color, "accent": accent_color,
		"support": support_color, "dark": dark_color, "highlight": highlight_color}


## The club's lettering color on dark signs: the brighter of secondary
## and accent.
func sign_color() -> Color:
	return secondary_color if secondary_color.get_luminance() >= accent_color.get_luminance() else accent_color


func full_name() -> String:
	return "%s %s" % [city, team_name]


func bench() -> Array[PlayerDef]:
	var list: Array[PlayerDef] = []
	for p in roster:
		if not p.is_pitcher() and not batting_order.has(p.id):
			list.append(p)
	return list
