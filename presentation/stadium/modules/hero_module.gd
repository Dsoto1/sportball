extends StadiumModule
## A signature landmark: one sculpted model (a ModelKit role, "model")
## standing behind the outfield stands at the piece's angle, "distance" m
## beyond them, "height" m tall, turned to face home plate ("turn" adds
## degrees of yaw so a building can show a three-quarter view). It stands
## on the back of the stands ("base" m above their top row), in front of
## any landmark rows, so it rises over the bowl as the sheets' hero does.


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var role := StringName(piece.param("model"))
	if not ModelKit.has(role):
		return
	var height := float(piece.param("height")) * piece.size
	var node := ModelKit.spawn(role, height, RandomNumberGenerator.new())
	node.name = stadium.unique_name("Hero")
	# Sculpted models are centered on their origin: stand them on their base.
	var box := ModelKit._aabb(node)
	var holder := Node3D.new()
	holder.name = stadium.unique_name("HeroSpot")
	stadium.add_child(holder)
	var top := stadium.stand_top(piece.angle)
	holder.position = stadium.point(piece.angle, top.x + float(piece.param("distance")), top.y + float(piece.param("base")))
	stadium.face_home(holder)
	holder.rotation.y += deg_to_rad(float(piece.param("turn")))
	node.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * node.scale
	holder.add_child(node)
