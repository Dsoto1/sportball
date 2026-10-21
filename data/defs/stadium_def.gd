class_name StadiumDef
extends Resource
## A ballpark's look. Field dimensions stay in BaseballTuning (rules); this
## only drives presentation. It comes in layers a stadium designer can edit
## one at a time: the field shape (rules), the palette (colors), the bowl
## and crowd (rows, attendance), the setting (night, turf) and the pieces,
## a list of placed modules (halo, bay, warehouse, dome...; see
## StadiumModules for the catalog).

@export var id: StringName
@export var display_name: String
## One line for the venue picker ("short porch in right, thin air").
@export var blurb: String
## Playing dimensions: wall distances and heights, air (rules of the park).
@export var field_shape: FieldShape
@export var seat_color: Color = Color(0.3, 0.3, 0.4)
@export var seat_color_alt: Color = Color(0.25, 0.25, 0.32)
## Concrete, facades, dugouts and towers.
@export var structure_color: Color = Color(0.55, 0.55, 0.6)
## Neon accent: the halo, lamp trim, scoreboard frame.
@export var accent_color: Color = Color(1.0, 0.8, 0.3)
@export var outfield_wall_color: Color = Color(0.16, 0.22, 0.38)
## &"padded", &"iron", &"ivy", &"brick" or &"stone": how the outfield wall is dressed.
@export var wall_style: StringName = &"padded"
## Rows of seats in the foul-territory stands and the outfield bleachers.
@export var foul_rows: int = 26
@export var outfield_rows: int = 16
## Decks in the foul stands (1-3), each with a fascia band of wordmarks.
@export_range(1, 3) var decks: int = 1
## Fans in home colors, away colors and anything else (shares sum to ~1).
@export var home_fan_share: float = 0.6
@export var away_fan_share: float = 0.12
## Fraction of seats with someone in them.
@export var attendance: float = 0.85
## Played under the lights: night sky, floodlights, glowing landmarks.
@export var night: bool = false
## Artificial turf instead of grass (look only; its speed is in field_shape).
@export var turf: bool = false
## Fictional sponsors on the boards (original names only).
@export var sponsors: PackedStringArray = []
@export var skyline_color: Color = Color(0.25, 0.27, 0.42)
## The ground around the park (red sand, snow...); transparent for the
## default, a dark shade of the skyline color.
@export var ground_color: Color = Color(0, 0, 0, 0)
@export var window_color: Color = Color(1.0, 0.85, 0.5)
## Surfaces (StadiumSurfaces kinds, tinted by the colors above): the
## stands' steps, the back facade of the bowl, structural pieces (frames,
## piers, towers) and the ground around the park. Empty for flat color.
## The facade's own tint; transparent to use structure_color.
@export var facade_color: Color = Color(0, 0, 0, 0)
@export var stand_surface: StringName = &"concrete"
@export var facade_surface: StringName = &"concrete"
@export var structure_surface: StringName = &"concrete"
@export var ground_surface: StringName = &""
## The placed modules, built in order (the first scoreboard is the main
## one the match updates first).
@export var pieces: Array[StadiumPiece] = []


func facade_tint() -> Color:
	return structure_color if facade_color.a == 0.0 else facade_color


func has_piece(kind: StringName) -> bool:
	return not pieces_of(kind).is_empty()


func pieces_of(kind: StringName) -> Array[StadiumPiece]:
	var out: Array[StadiumPiece] = []
	for piece in pieces:
		if piece != null and piece.kind == kind:
			out.append(piece)
	return out


## Sealed under a dome: indoor light, no sky, skyline or light towers.
func is_roofed() -> bool:
	return has_piece(&"dome")


## Adds a module with its defaults (a designer's "place" action).
func add_piece(kind: StringName, angle: float = NAN, params: Dictionary = {}, mirrored: bool = false) -> StadiumPiece:
	var piece := StadiumPiece.make(kind, StadiumModules.default_angle(kind) if is_nan(angle) else angle, params, mirrored)
	pieces.append(piece)
	return piece


func remove_piece(piece: StadiumPiece) -> void:
	pieces.erase(piece)


## Problems a designer should fix before saving (empty when the park is
## buildable): unknown modules, duplicates of one-per-park pieces, clashes.
func validate() -> PackedStringArray:
	return StadiumModules.validate(self)


## The park recolored from a club's colors (a team designer's starting
## point): seats in the primary, the accent and walls from the secondary.
func recolored(primary: Color, secondary: Color) -> StadiumDef:
	var park: StadiumDef = duplicate(true)
	park.seat_color = primary.darkened(0.35)
	park.seat_color_alt = primary.darkened(0.5)
	park.accent_color = secondary.lightened(0.15)
	park.outfield_wall_color = primary.darkened(0.6)
	return park
