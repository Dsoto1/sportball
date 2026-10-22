extends StadiumModule
## Floodlight towers behind the stands, their lamps aimed at the middle of
## the field (they blaze at night): six around the bowl and a pair flanking
## the centerpiece at +-flank degrees (0 for none).
## Modular: any "mast" (lattice steel, deco pylon, stone tower, or "built"
## for the plain box pole) carries any "head" (floodlight bank, halo ring
## of lamps, crown lantern, or "built"), "heads" of them side by side.
## "paint" recolors the mast and head metal toward a color (alpha is how
## far), and "lamp" is the lamps' light color, so every park can theme
## its lights: warm gaslight, green reactor glow, neon purple...

const ANGLES := [-128.0, -72.0, -32.0, 32.0, 72.0, 128.0]
## Where each head's lamps are, as shares of its bounds (x across, y up,
## from the center), so the glow sits on the model's own lamps.
const LAMPS := {
	&"head_bank": "grid",
	&"head_halo": "ring",
	&"head_crown": "core",
}


func build(stadium: Stadium, piece: StadiumPiece, _home: TeamDef, _away: TeamDef) -> void:
	var def := stadium.def
	var height := float(piece.param("height")) * piece.size
	var root := Node3D.new()
	root.name = stadium.unique_name("LightTowers")
	stadium.add_child(root)
	var angles: Array = ANGLES.duplicate()
	var flank := float(piece.param("flank"))
	if flank > 0.0:
		angles.append_array([-flank, flank])
	var mast := StringName("mast_%s" % piece.param("mast"))
	var head := StringName("head_%s" % piece.param("head"))
	var paint := Color(piece.param("paint"))
	var lamp_color := Color(piece.param("lamp"))
	var glow := Stadium.glow(lamp_color, 6.0 if def.night else 2.5)
	var rng := RandomNumberGenerator.new()
	for angle: float in angles:
		var p := stadium.profile(angle)
		var base := stadium.point(angle, p.x + p.z * Stadium.ROW_DEPTH + 4.0, 0.0)
		var tower := Node3D.new()
		root.add_child(tower)
		tower.position = base
		# Face the field (yaw only); the head tilts down toward it.
		var flat := Stadium.FIELD_CENTER - base
		flat.y = 0.0
		tower.rotation.y = atan2(flat.x, flat.z)
		var top := height
		if ModelKit.has(mast):
			var m := _stand(mast, height, rng, paint)
			tower.add_child(m)
		else:
			var pole := stadium.box(Vector3(1.4, height, 1.4), def.structure_color.darkened(0.2), tower, &"steel")
			pole.position = Vector3.UP * height * 0.5
		var count := int(piece.param("heads"))
		var head_w := float(piece.param("head_size")) * piece.size
		for h in count:
			var holder := Node3D.new()
			tower.add_child(holder)
			holder.position = Vector3((h - (count - 1) * 0.5) * head_w * 1.05, top, 0.0)
			holder.rotation.x = deg_to_rad(float(piece.param("tilt")))
			if ModelKit.has(head):
				var hm := _stand(head, head_w, rng, paint)
				holder.add_child(hm)
				_lamps(holder, head, ModelKit._aabb(hm), hm.scale.x, glow)
			else:
				var bank := stadium.box(Vector3(9.0, 5.0, 0.8), def.structure_color.darkened(0.4), holder)
				bank.position.y = 2.5
				for row in 3:
					for col in 6:
						var lamp := stadium.box(Vector3(1.2, 1.2, 0.3), Color.WHITE, holder)
						lamp.position = Vector3(-3.75 + col * 1.5, 1.0 + row * 1.5, 0.5)
						lamp.material_override = glow
	# Low suns would rake their shadows across the whole field.
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## A model stood on its base at the origin, `size` m tall, painted toward
## `paint` (alpha is how far) keeping its texture's light and shade.
static func _stand(role: StringName, size: float, rng: RandomNumberGenerator, paint: Color) -> Node3D:
	var m := ModelKit.spawn(role, size, rng)
	var box := ModelKit._aabb(m)
	m.position = Vector3(-box.get_center().x, -box.position.y, -box.get_center().z) * m.scale
	if paint.a > 0.0:
		for mi: MeshInstance3D in m.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var src := mi.mesh.surface_get_material(s) as StandardMaterial3D
				if src != null:
					var c: StandardMaterial3D = src.duplicate()
					c.albedo_color = Color.WHITE.lerp(paint * 1.6, paint.a)
					mi.set_surface_override_material(s, c)
	return m


## Glowing lamp faces on a head model, laid out to sit on its own lamps.
static func _lamps(holder: Node3D, head: StringName, box: AABB, k: float, glow: Material) -> void:
	var size := box.size * k
	var front := size.z * 0.5 + 0.05
	var mid := Vector3(0, size.y * 0.5, 0)
	var dots: Array[Vector3] = []
	var r := 0.0
	match LAMPS.get(head, ""):
		"grid":
			# Three rows of four round lamps across the upper face.
			r = size.x * 0.085
			for row in 3:
				for col in 4:
					dots.append(Vector3((col - 1.5) * size.x * 0.2, size.y * (0.47 + row * 0.2), front))
		"ring":
			r = size.x * 0.045
			var ring := size.x * 0.4
			var c := Vector3(0, size.y * 0.55, front)
			for i in 20:
				var a := TAU * i / 20.0
				dots.append(c + Vector3(cos(a) * ring, sin(a) * ring, 0))
		"core":
			r = size.x * 0.28
			dots.append(Vector3(0, size.y * 0.5, 0))
	for d in dots:
		var lamp := MeshInstance3D.new()
		var disc := SphereMesh.new()
		disc.radius = r
		disc.height = r * (0.6 if LAMPS[head] != "core" else 2.0)
		disc.radial_segments = 12
		disc.rings = 6
		lamp.mesh = disc
		lamp.material_override = glow
		lamp.position = d
		holder.add_child(lamp)
