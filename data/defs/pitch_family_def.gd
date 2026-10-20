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
