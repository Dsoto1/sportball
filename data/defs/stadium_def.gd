class_name StadiumDef
extends Resource
## A ballpark's look. Field dimensions stay in BaseballTuning (rules); this
## only drives presentation: seats, crowd colors, signage and landmarks.

@export var id: StringName
@export var display_name: String
@export var seat_color: Color = Color(0.3, 0.3, 0.4)
@export var seat_color_alt: Color = Color(0.25, 0.25, 0.32)
## Concrete, facades, dugouts and towers.
@export var structure_color: Color = Color(0.55, 0.55, 0.6)
## Neon accent: the halo, lamp trim, scoreboard frame.
@export var accent_color: Color = Color(1.0, 0.8, 0.3)
@export var outfield_wall_color: Color = Color(0.16, 0.22, 0.38)
## Fans in home colors, away colors and anything else (shares sum to ~1).
@export var home_fan_share: float = 0.6
@export var away_fan_share: float = 0.12
## Fraction of seats with someone in them.
@export var attendance: float = 0.85
## The Halo Dome's signature ring over the park.
@export var halo: bool = false
## Fictional sponsors on the boards (original names only).
@export var sponsors: PackedStringArray = []
@export var skyline: bool = true
@export var skyline_color: Color = Color(0.25, 0.27, 0.42)
@export var window_color: Color = Color(1.0, 0.85, 0.5)
