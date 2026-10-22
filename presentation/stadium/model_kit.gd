class_name ModelKit
## Third-party scenery models (CC0, Kenney Nature Kit and City Kit
## Commercial; see docs/13_ASSET_MANIFEST.md), grouped by role so modules
## ask for "a palm" or "a skyscraper" and get a random variant scaled to a
## height in meters.

const NATURE := "res://assets/third_party/kenney/nature-kit/"
const CITY := "res://assets/third_party/kenney/city-kit-commercial/"
## Hero props and facade bays generated for this game (Artlist AI,
## Hyper3D Rodin; see docs/ARTLIST_CREDITS.md and the asset manifest).
const ART := "res://assets/generated/artlist/stadium/"
## Signature landmarks generated with Meshy (text-to-3D, simplified to
## about 60-100k triangles with gltf-transform; see docs/ARTLIST_CREDITS.md).
const MESHY := "res://assets/generated/meshy/stadium/"

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
	&"kitsune_statue": [ART + "kitsune_statue.glb"],
	&"sea_king": [ART + "sea_king_statue.glb"],
	&"knight": [ART + "knight_statue.glb"],
	&"scorpion_idol": [ART + "scorpion_idol.glb"],
	&"airship": [ART + "airship.glb"],
	&"tall_ship": [ART + "tall_ship.glb"],
	&"locomotive": [ART + "locomotive.glb"],
	&"pagoda": [ART + "pagoda.glb"],
	&"bay_colosseum": [ART + "bay_colosseum.glb"],
	&"bay_gothic": [ART + "bay_gothic.glb"],
	&"bay_temple": [ART + "bay_temple.glb"],
	&"bay_victorian": [ART + "bay_victorian.glb"],
	&"lantern_cluster": [ART + "lantern_cluster.glb"],
	&"column": [ART + "column.glb"],
	&"planter_urn": [ART + "planter_urn.glb"],
	&"sakura_cliff": [MESHY + "sakura_cliff.glb"],
	&"cathedral_spires": [MESHY + "cathedral_spires.glb"],
	&"domed_bank": [MESHY + "domed_bank.glb"],
	# Architecture sets: one style per park, in sections (stand bay, tower,
	# backdrop block, scoreboard gate) so the whole park reads as one build.
	&"bay_gothic_set": [MESHY + "gothic_bay.glb"],
	&"set_gothic_tower": [MESHY + "gothic_tower.glb"],
	&"set_gothic_block": [MESHY + "gothic_block.glb"],
	&"set_gothic_gate": [MESHY + "gothic_gate.glb"],
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


## The first mesh of a role's first variant, with its transform inside the
## model and its bounds (for batching repeated pieces into a MultiMesh).
static func mesh_of(role: StringName) -> Dictionary:
	var path: String = SETS[role][0]
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var node: Node3D = (_scenes[path] as PackedScene).instantiate()
	var out := {}
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != node and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		out = {"mesh": mi.mesh, "transform": xf, "aabb": xf * mi.get_aabb()}
		break
	node.free()
	return out


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


## Tinted copies of meshes, one per mesh and tint, shared by every spawn.
static var _tinted := {}


static func _tint_leaves(node: Node, tint: Color) -> void:
	# A tinted copy of the mesh (not a per-surface override, which the
	# renderer logs as a null material on some drivers).
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var key := [mi.mesh, tint]
		if not _tinted.has(key):
			var copy: Mesh = mi.mesh.duplicate()
			for s in copy.get_surface_count():
				var mat := copy.surface_get_material(s)
				if mat != null and String(mat.resource_name).to_lower().contains("leaf"):
					var m := StandardMaterial3D.new()
					m.albedo_color = tint
					m.roughness = 0.8
					copy.surface_set_material(s, m)
			_tinted[key] = copy
		mi.mesh = _tinted[key]


static func _no_shadows(node: Node) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
