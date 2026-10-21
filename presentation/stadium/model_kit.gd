class_name ModelKit
## Third-party scenery models (CC0, Kenney Nature Kit and City Kit
## Commercial; see docs/13_ASSET_MANIFEST.md), grouped by role so modules
## ask for "a palm" or "a skyscraper" and get a random variant scaled to a
## height in meters.

const NATURE := "res://assets/third_party/kenney/nature-kit/"
const CITY := "res://assets/third_party/kenney/city-kit-commercial/"

const SETS := {
	&"palm": [NATURE + "tree_palmDetailedTall.glb", NATURE + "tree_palmTall.glb", NATURE + "tree_palmBend.glb"],
	&"pine": [NATURE + "tree_pineTallA_detailed.glb", NATURE + "tree_pineTallB_detailed.glb", NATURE + "tree_pineRoundC.glb"],
	&"cactus": [NATURE + "cactus_tall.glb", NATURE + "cactus_short.glb"],
	&"round": [NATURE + "tree_oak.glb", NATURE + "tree_detailed.glb"],
	&"cypress": [NATURE + "tree_cone.glb"],
	&"blossom": [NATURE + "tree_fat.glb", NATURE + "tree_oak.glb"],
	&"rock": [NATURE + "rock_tallA.glb", NATURE + "rock_tallB.glb", NATURE + "rock_tallC.glb", NATURE + "stone_tallA.glb"],
	&"cliff": [NATURE + "cliff_large_rock.glb"],
	&"bush": [NATURE + "plant_bushLarge.glb"],
	&"tower": [CITY + "building-skyscraper-a.glb", CITY + "building-skyscraper-b.glb", CITY + "building-skyscraper-c.glb", CITY + "building-skyscraper-d.glb", CITY + "building-skyscraper-e.glb"],
	&"building": [CITY + "building-a.glb", CITY + "building-b.glb", CITY + "building-c.glb", CITY + "building-d.glb", CITY + "building-e.glb", CITY + "building-f.glb", CITY + "building-g.glb", CITY + "building-h.glb"],
	&"block": [CITY + "low-detail-building-a.glb", CITY + "low-detail-building-b.glb", CITY + "low-detail-building-c.glb", CITY + "low-detail-building-d.glb", CITY + "low-detail-building-wide-a.glb"],
}

static var _scenes := {}
static var _heights := {}


static func has(role: StringName) -> bool:
	return SETS.has(role)


## A random variant of a role, scaled uniformly to `height` m, base on the
## ground at its origin. `tint` recolors foliage-like surfaces (any material
## whose name says leaf) when its alpha is above zero.
static func spawn(role: StringName, height: float, rng: RandomNumberGenerator, tint: Color = Color(0, 0, 0, 0)) -> Node3D:
	var list: Array = SETS[role]
	var path: String = list[rng.randi_range(0, list.size() - 1)]
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var node: Node3D = (_scenes[path] as PackedScene).instantiate()
	var h: float = _heights.get(path, -1.0)
	if h < 0.0:
		h = maxf(_aabb(node).size.y, 0.001)
		_heights[path] = h
	node.scale = Vector3.ONE * (height / h)
	if tint.a > 0.0:
		_tint_leaves(node, tint)
	_no_shadows(node)
	return node


static func _aabb(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).get_aabb()
		if first:
			box = b
			first = false
		else:
			box = box.merge(b)
	return box


static func _tint_leaves(node: Node, tint: Color) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			var mat := mi.mesh.surface_get_material(s)
			if mat != null and String(mat.resource_name).to_lower().contains("leaf"):
				var m := StandardMaterial3D.new()
				m.albedo_color = tint
				m.roughness = 0.8
				mi.set_surface_override_material(s, m)


static func _no_shadows(node: Node) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
