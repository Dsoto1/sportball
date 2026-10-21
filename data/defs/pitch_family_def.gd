class_name PitchFamilyDef
extends Resource
## A pitch family. The aim point is where the pitch is meant to finish;
## break describes how far it moves late in flight to get there.

@export var id: StringName
@export var display_name: String
## Release speed in m/s.
@export var speed: float = 38.0
## Late movement in the plate plane (meters). +X toward first base, +Y up.
@export var break_amount: Vector2 = Vector2.ZERO
## 0..1. How much the pitch degrades an AI batter's read and timing.
@export var deception: float = 0.0
## Multiplier on command scatter; harder pitches miss by more.
@export var scatter_scale: float = 1.0
## Readability tell for the batter: trail colour and trail length (number
## of ghost balls), so the cue does not rely on colour alone.
@export var tell_color: Color = Color(1, 1, 1)
@export var tell_trail: int = 4
## fastball / breaking / offspeed / signature: how the AI uses it.
@export var category: StringName = &"fastball"
## Where the AI likes to locate it, in zone half-heights (- = down).
@export var aim_height: float = 0.0
## Degrees added to launch angle off this pitch (sinkers make grounders).
@export var launch_bias: float = 0.0
## Special flight: &"" straight math, &"knuckle" wobbles on the way in,
## &"hesitation" hangs mid-flight then rushes the plate.
@export var motion: StringName = &""
## Knuckle wobble (meters) or hesitation strength (0..0.9).
@export var motion_strength: float = 0.0
## Relative weight in the AI's pitch choice (before count and matchup).
@export var usage: float = 1.0
