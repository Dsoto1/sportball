extends StadiumModule
## Statues on pedestals atop the outfield stands, facing the field: a
## bronze bull, a figure, a marble swan, a white fox spirit, a sea king with a trident, a
## knight, or a sandstone scorpion. "size" scales them.


func build(stadium: Stadium, piece: StadiumPiece, home: TeamDef, _away: TeamDef) -> void:
	var bronze := Color(0.55, 0.38, 0.2)
	var root := Node3D.new()
	root.name = stadium.unique_name("Statue")
	stadium.add_child(root)
	var top := stadium.skyline_top(piece.angle)
	var spot := stadium.point(piece.angle, top.x - 1.0, top.y + 0.6)
	root.look_at_from_position(spot, Vector3(0, spot.y, -45.0), Vector3.UP)
	# Monumental: readable from home plate across the park.
	root.scale = Vector3.ONE * piece.size * 2.2 * float(piece.param("scale"))
	var pedestal := stadium.box(Vector3(5.0, 2.4, 3.0), stadium.def.structure_color.lightened(0.15), root, &"marble")
	pedestal.position.y = 1.2
	var figure := StringName(piece.param("figure"))
	var modeled: StringName = {&"fox": &"kitsune_statue", &"titan": &"sea_king", &"knight": &"knight", &"scorpion": &"scorpion_idol"}.get(figure, &"")
	if modeled != &"":
		# A sculpted model on its own plinth (it replaces the pedestal). At
		# monumental scale its footprint is many meters deep, so it stands
		# back from the stands' top with its front edge on the back wall,
		# never reaching over the seats toward the field, on a rock plinth
		# up from the ground (as the sheets' statues stand on cliffs).
		pedestal.queue_free()
		var model := ModelKit.spawn(modeled, 11.0, RandomNumberGenerator.new())
		model.rotation.y = PI
		root.add_child(model)
		var box := ModelKit._aabb(model)
		var k := root.scale.x * model.scale.x
		var depth := box.size.z * k
		var width := box.size.x * k
		# Centered on its bounds (the model's origin need not be).
		model.position = Vector3(box.get_center().x * model.scale.x, -box.position.y * model.scale.y, box.get_center().z * model.scale.z)
		var back := stadium.stand_top(piece.angle)
		var radius := maxf(top.x, back.x) + depth * 0.5 + 0.5
		var base := stadium.point(piece.angle, radius, back.y + 0.6)
		root.look_at_from_position(base, Vector3(0, base.y, -45.0), Vector3.UP)
		root.scale = Vector3.ONE * piece.size * 2.2 * float(piece.param("scale"))
		var plinth := MeshInstance3D.new()
		var slab := BoxMesh.new()
		slab.size = Vector3(width * 1.05, base.y, depth * 1.05)
		plinth.mesh = slab
		plinth.material_override = StadiumSurfaces.material(&"rock", stadium.def.structure_color.lerp(Color(0.45, 0.45, 0.48), 0.6), false, 2.0)
		plinth.name = "Plinth"
		stadium.add_child(plinth)
		plinth.transform = Transform3D(root.transform.basis.orthonormalized(), base - Vector3(0, base.y * 0.5, 0))
		return
	match figure:
		&"bull":
			if ModelKit.has(&"bull_statue"):
				# The sculpted bronze (Meshy), charging off the pedestal.
				var bull := ModelKit.spawn(&"bull_statue", 4.2, RandomNumberGenerator.new())
				bull.rotation.y = PI
				var box := ModelKit._aabb(bull)
				# Hooves on the pedestal's top (the model's origin is its middle).
				bull.position = Vector3(box.get_center().x * bull.scale.x, 2.4 - box.position.y * bull.scale.y, box.get_center().z * bull.scale.z)
				root.add_child(bull)
				var size := box.size * bull.scale.x
				pedestal.scale = Vector3(maxf(1.0, size.x * 1.15 / 5.0), 1.0, maxf(1.0, size.z * 1.15 / 3.0))
			else:
				_bull(root, bronze)
		&"fox":
			_fox(root, Color(0.95, 0.93, 0.88))
		&"titan":
			_titan(stadium, root, Color(0.62, 0.7, 0.68), home)
		&"knight":
			_knight(stadium, root, Color(0.55, 0.57, 0.6), home)
		&"scorpion":
			_scorpion(root, Color(0.82, 0.62, 0.32))
		&"swan":
			_swan(root, Color(0.96, 0.95, 0.92))
		_:
			_figure(root, bronze)


## A marble swan with raised wings and an arched neck (Swans).
func _swan(root: Node3D, white: Color) -> void:
	var body := Scenery.sphere(root, 1.5, white, 0.75)
	body.scale = Vector3(1.0, 1.0, 1.6)
	body.position = Vector3(0, 3.6, 0.3)
	# The neck: a chain of shrinking spheres curving up and forward.
	for i in 7:
		var t := i / 6.0
		var seg := Scenery.sphere(root, lerpf(0.55, 0.32, t), white)
		seg.position = Vector3(0, 4.0 + sin(t * PI * 0.9) * 2.6 + t * 1.2, -1.6 - sin(t * PI) * 0.9 + t * 0.7)
	var head := Scenery.sphere(root, 0.45, white)
	head.scale = Vector3(1.0, 0.9, 1.4)
	head.position = Vector3(0, 7.9, -1.2)
	var beak := Scenery.cylinder(root, 0.18, 0.04, 0.8, Color(0.95, 0.55, 0.15), 6)
	beak.rotation.x = -PI * 0.6
	beak.position = Vector3(0, 7.75, -1.85)
	for side: float in [-1.0, 1.0]:
		# Raised wings: fanned feather slabs.
		for f in 4:
			var feather := Scenery.sphere(root, 1.0, white, 0.2)
			feather.scale = Vector3(0.5, 1.0, 2.2 - f * 0.35)
			feather.rotation = Vector3(0.2, 0.0, side * (0.5 + f * 0.25))
			feather.position = Vector3(side * (1.0 + f * 0.35), 4.6 + f * 0.6, 0.8 + f * 0.15)


## A robed marble figure holding an urn aloft.
func _figure(root: Node3D, color: Color) -> void:
	var robe := Scenery.cylinder(root, 1.1, 0.55, 3.6, color, 10)
	robe.position.y = 4.2
	var torso := Scenery.cylinder(root, 0.55, 0.5, 1.4, color, 10)
	torso.position.y = 6.7
	var head := Scenery.sphere(root, 0.45, color)
	head.position.y = 7.9
	for side: float in [-1.0, 1.0]:
		var arm := Scenery.cylinder(root, 0.16, 0.14, 1.7, color, 6)
		arm.position = Vector3(side * 0.55, 7.8, 0)
		arm.rotation.z = -side * 0.35
	var urn := Scenery.sphere(root, 0.5, color, 0.8)
	urn.position.y = 9.0


func _bull(root: Node3D, bronze: Color) -> void:
	var body := Scenery.sphere(root, 1.6, bronze, 0.8)
	body.scale = Vector3(1.0, 1.0, 1.9)
	body.position = Vector3(0, 4.4, 0)
	var head := Scenery.sphere(root, 0.9, bronze)
	head.position = Vector3(0, 4.4, -3.0)
	for side: float in [-1.0, 1.0]:
		var horn := Scenery.cylinder(root, 0.18, 0.04, 1.4, Color(0.85, 0.8, 0.6), 6)
		horn.position = Vector3(side * 0.9, 5.2, -3.2)
		horn.rotation.z = -side * 0.9
		for end: float in [-1.0, 1.0]:
			var leg := Scenery.cylinder(root, 0.3, 0.25, 1.8, bronze, 6)
			leg.position = Vector3(side * 0.8, 3.0, end * 1.6)


## A seated fox spirit with fanned tails (Kitsune).
func _fox(root: Node3D, white: Color) -> void:
	var body := Scenery.sphere(root, 1.5, white, 1.4)
	body.position = Vector3(0, 4.6, 0)
	var head := Scenery.sphere(root, 0.95, white)
	head.position = Vector3(0, 7.0, -0.5)
	var snout := Scenery.cylinder(root, 0.45, 0.1, 1.2, white, 8)
	snout.rotation.x = PI * 0.5
	snout.position = Vector3(0, 6.85, -1.5)
	for side: float in [-1.0, 1.0]:
		var ear := Scenery.cylinder(root, 0.35, 0.0, 1.1, white, 6)
		ear.position = Vector3(side * 0.5, 8.1, -0.4)
		var mark := Scenery.sphere(root, 0.18, Color(0.8, 0.12, 0.1))
		mark.position = Vector3(side * 0.35, 7.25, -1.25)
	for t in 5:
		var tail := Scenery.cylinder(root, 0.55, 0.15, 3.6, white, 8)
		tail.position = Vector3((t - 2) * 0.8, 5.2, 1.6)
		tail.rotation = Vector3(-0.6, 0.0, (t - 2) * 0.35)


## A sea king with a crown and trident (Krakens).
func _titan(stadium: Stadium, root: Node3D, stone: Color, home: TeamDef) -> void:
	var body := Scenery.cylinder(root, 1.6, 1.1, 6.0, stone, 12)
	body.position.y = 5.4
	var head := Scenery.sphere(root, 1.0, stone)
	head.position.y = 9.2
	var beard := Scenery.cylinder(root, 0.9, 0.2, 1.6, stone.darkened(0.15), 10)
	beard.rotation.x = PI
	beard.position = Vector3(0, 8.2, -0.5)
	var crown := Scenery.cylinder(root, 0.9, 1.1, 0.7, home.support_color, 10)
	crown.position.y = 10.3
	crown.material_override = Stadium.glow(home.support_color, 0.4)
	var shaft := Scenery.cylinder(root, 0.12, 0.12, 10.0, home.support_color, 6)
	shaft.position = Vector3(2.0, 7.0, -0.4)
	for x in [-0.6, 0.0, 0.6]:
		var tine := Scenery.cylinder(root, 0.12, 0.02, 1.4, home.support_color, 6)
		tine.position = Vector3(2.0 + x, 12.6, -0.4)
	var bar := stadium.box(Vector3(1.4, 0.2, 0.2), home.support_color, root)
	bar.position = Vector3(2.0, 11.9, -0.4)


## A knight with a shield and sword, standing guard (Sentinels).
func _knight(stadium: Stadium, root: Node3D, steel: Color, home: TeamDef) -> void:
	var body := Scenery.cylinder(root, 1.2, 1.0, 5.0, steel, 10)
	body.position.y = 4.9
	var helm := Scenery.cylinder(root, 0.75, 0.6, 1.4, steel, 10)
	helm.position.y = 8.1
	var plume := Scenery.cylinder(root, 0.15, 0.3, 1.2, home.accent_color, 6)
	plume.position.y = 9.3
	var shield := stadium.box(Vector3(2.2, 3.0, 0.3), home.secondary_color, root)
	shield.position = Vector3(-1.4, 5.2, -0.9)
	var cross := stadium.box(Vector3(0.3, 2.4, 0.35), home.support_color, root)
	cross.position = Vector3(-1.4, 5.2, -1.0)
	var blade := stadium.box(Vector3(0.25, 4.5, 0.12), Color(0.85, 0.87, 0.9), root)
	blade.position = Vector3(1.4, 5.0, -0.6)
	var guard := stadium.box(Vector3(1.2, 0.25, 0.25), home.support_color, root)
	guard.position = Vector3(1.4, 7.1, -0.6)


## A great scorpion with raised tail (Scorpions).
func _scorpion(root: Node3D, sand: Color) -> void:
	var body := Scenery.sphere(root, 1.6, sand, 0.55)
	body.scale = Vector3(1.0, 1.0, 1.5)
	body.position = Vector3(0, 3.3, 0)
	for seg in 5:
		var t := float(seg) / 4.0
		var piece := Scenery.sphere(root, 0.6 - t * 0.2, sand)
		piece.position = Vector3(0, 3.6 + sin(t * PI * 0.9) * 3.4, 2.0 + cos(t * PI * 0.9) * 1.6 - 1.2 * t)
	var sting := Scenery.cylinder(root, 0.3, 0.0, 1.0, sand.darkened(0.3), 6)
	sting.position = Vector3(0, 6.2, -0.4)
	sting.rotation.x = PI * 0.7
	for side: float in [-1.0, 1.0]:
		var claw := Scenery.sphere(root, 0.7, sand, 0.6)
		claw.scale = Vector3(1.0, 1.0, 1.6)
		claw.position = Vector3(side * 1.4, 3.3, -2.6)
		for l in 3:
			var leg := Scenery.cylinder(root, 0.15, 0.1, 1.8, sand.darkened(0.15), 6)
			leg.position = Vector3(side * 1.6, 2.7, -0.6 + l * 0.7)
			leg.rotation.z = side * 0.9
