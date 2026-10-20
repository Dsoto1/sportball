class_name PlayerDef
extends Resource
## One player. Ratings are 0..100 with 50 as league average; how they
## change play is decided in baseball/roster/ratings.gd, not here.

@export var id: StringName
@export var display_name: String
@export var nickname: String
@export var number: int
## &"R" or &"L".
@export var bats: StringName = &"R"
@export var throws: StringName = &"R"
## Positions this player can field, primary first. &"p" for pitchers.
@export var positions: Array[StringName] = []

@export_group("Hitting and Running")
@export_range(0, 100) var contact: int = 50
@export_range(0, 100) var power: int = 50
## Plate discipline: how well the AI reads pitches when this player bats.
@export_range(0, 100) var eye: int = 50
@export_range(0, 100) var speed: int = 50

@export_group("Fielding")
@export_range(0, 100) var arm: int = 50
@export_range(0, 100) var glove: int = 50

@export_group("Pitching")
@export_range(0, 100) var velocity: int = 50
@export_range(0, 100) var control: int = 50
## Movement and deception on breaking pitches.
@export_range(0, 100) var stuff: int = 50
@export_range(0, 100) var stamina: int = 50
@export var pitches: Array[StringName] = [&"fastball", &"breaking_ball", &"changeup"]


func is_pitcher() -> bool:
	return positions.has(&"p")


func bats_left() -> bool:
	return bats == &"L"
