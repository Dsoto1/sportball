class_name StadiumDef
extends Resource
## A ballpark's look. Field dimensions stay in BaseballTuning (rules); this
## only drives presentation: seats, crowd colors, signage and landmarks.

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
## &"padded", &"iron", &"ivy" or &"brick": how the outfield wall is dressed.
@export var wall_style: StringName = &"padded"
## Rows of seats in the foul-territory stands and the outfield bleachers.
@export var foul_rows: int = 26
@export var outfield_rows: int = 16
## A hand-operated scoreboard built into the outfield wall at this angle.
@export var wall_scoreboard: bool = false
@export var wall_scoreboard_angle: float = -30.0
## Water beyond the stands on one side: 1 = right field, -1 = left, 0 = none.
@export var water_side: int = 0
## Skyline tower height multiplier (0.4 = low desert town).
@export var skyline_height: float = 1.0
## Fans in home colors, away colors and anything else (shares sum to ~1).
@export var home_fan_share: float = 0.6
@export var away_fan_share: float = 0.12
## Fraction of seats with someone in them.
@export var attendance: float = 0.85
## The Halo Dome's signature ring over the park.
@export var halo: bool = false
## Played under the lights: night sky, floodlights, glowing landmarks.
@export var night: bool = false
## A sealed dome over the whole park (indoor lighting, no sky or skyline).
@export var roof: bool = false
## Artificial turf instead of grass (look only; its speed is in field_shape).
@export var turf: bool = false
## A signature structure beyond the stands: &"warehouse" (a long brick
## warehouse over right field), &"fountains" (beyond the outfield wall), or
## &"" for none.
@export var landmark: StringName = &""
## Fictional sponsors on the boards (original names only).
@export var sponsors: PackedStringArray = []
@export var skyline: bool = true
@export var skyline_color: Color = Color(0.25, 0.27, 0.42)
@export var window_color: Color = Color(1.0, 0.85, 0.5)
