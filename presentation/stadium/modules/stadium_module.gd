class_name StadiumModule
extends RefCounted
## A buildable ballpark piece. Each kind in StadiumModules.CATALOG has one
## subclass that turns a StadiumPiece (where, how big, its settings) into
## nodes under the Stadium, using the Stadium's kit (box, label, glow,
## point, profile) and the park's palette (stadium.def).


func build(_stadium: Stadium, _piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	pass
