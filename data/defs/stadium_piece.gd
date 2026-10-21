class_name StadiumPiece
extends Resource
## One module placed in a ballpark: a landmark, a scoreboard, a dome, the
## bay. StadiumDef.pieces lists them; StadiumModules knows how to build each
## kind and which settings it takes, so a stadium designer only edits this
## list. Presentation only: nothing here changes how the ball plays.

## Which module (StadiumModules.CATALOG key), e.g. &"halo", &"fountains".
@export var kind: StringName
## Where it sits, as a spray angle in degrees (-45 left-field line, 0 center,
## +45 right-field line, +-180 behind home). Modules that wrap the whole park
## ignore it.
@export var angle: float = 0.0
## Overall scale (1 = the module's standard size).
@export var size: float = 1.0
## Build a mirror-image copy on the other side too (angle -> -angle).
@export var mirrored: bool = false
## Kind-specific settings (see StadiumModules.CATALOG[kind]["params"]);
## anything left out takes the module's default.
@export var params: Dictionary = {}


static func make(p_kind: StringName, p_angle: float = 0.0, p_params: Dictionary = {}, p_mirrored: bool = false) -> StadiumPiece:
	var piece := StadiumPiece.new()
	piece.kind = p_kind
	piece.angle = p_angle
	piece.params = p_params.duplicate()
	piece.mirrored = p_mirrored
	return piece


## A setting, falling back to the module's default.
func param(key: String) -> Variant:
	if params.has(key):
		return params[key]
	return StadiumModules.default_param(kind, key)
