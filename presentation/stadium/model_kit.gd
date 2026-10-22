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
## Modular light towers (Artlist, Hyper3D Rodin): masts and lamp heads that
## mix and match; see the light_towers module.
const LIGHTS := "res://assets/generated/artlist/lights/"

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
	&"mast_lattice": [LIGHTS + "mast_lattice.glb"],
	&"mast_deco": [LIGHTS + "mast_deco.glb"],
	&"mast_stone": [LIGHTS + "mast_stone.glb"],
	&"head_bank": [LIGHTS + "head_bank.glb"],
	&"head_halo": [LIGHTS + "head_halo.glb"],
	&"head_crown": [LIGHTS + "head_crown.glb"],
	&"sakura_cliff": [MESHY + "sakura_cliff.glb"],
	&"cathedral_spires": [MESHY + "cathedral_spires.glb"],
	&"domed_bank": [MESHY + "domed_bank.glb"],
	&"block": [CITY + "low-detail-building-a.glb", CITY + "low-detail-building-b.glb", CITY + "low-detail-building-c.glb", CITY + "low-detail-building-d.glb", CITY + "low-detail-building-wide-a.glb"],
}

## Architecture sets: one style per park in four sections, so a whole park
## reads as one build. Each set name gives four roles: "set_<name>_bay"
## (the stand facade bay, also the arcade kit "<name>_set"), "_tower",
## "_block" (backdrop rows) and "_gate" (the scoreboard frame), from
## MESHY + "<name>_<section>.glb".
const ARCH_SETS := [&"gothic", &"deco", &"foundry", &"bank", &"pier", &"kiln", &"alpine", &"reactor", &"lamp", &"rail", &"garden", &"vault", &"temple", &"atlantis", &"sky", &"forum", &"volcano", &"desert"]
const SECTIONS := [&"bay", &"tower", &"block", &"gate"]

static var _scenes := {}
static var _heights := {}
static var _roles := {}


## Every role: SETS plus the architecture-set sections.
static func roles() -> Dictionary:
	if _roles.is_empty():
		_roles = SETS.duplicate()
		for set_name: StringName in ARCH_SETS:
			for section: StringName in SECTIONS:
				var path := MESHY + "%s_%s.glb" % [set_name, section]
				_roles[StringName("set_%s_%s" % [set_name, section])] = [path]
			_roles[StringName("bay_%s_set" % set_name)] = [MESHY + "%s_bay.glb" % set_name]
	return _roles


static func has(role: StringName) -> bool:
	var list: Array = roles().get(role, [])
	return not list.is_empty() and ResourceLoader.exists(list[0])


## A random variant of a role, scaled uniformly to `height` m, base on the
## ground at its origin. `tint` recolors foliage-like surfaces (any material
## whose name says leaf) when its alpha is above zero.
static func spawn(role: StringName, height: float, rng: RandomNumberGenerator, tint: Color = Color(0, 0, 0, 0)) -> Node3D:
	var list: Array = roles()[role]
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
	var path: String = roles()[role][0]
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
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mi.mesh = tinted_leaves(mi.mesh, tint)


## A copy of a mesh with its leaf surfaces in `tint`, cached per mesh and
## tint (a tinted copy, not a per-surface override, which the renderer logs
## as a null material on some drivers).
static func tinted_leaves(mesh: Mesh, tint: Color) -> Mesh:
	var key := [mesh, tint]
	if not _tinted.has(key):
		var copy: Mesh = mesh.duplicate()
		for s in copy.get_surface_count():
			var mat := copy.surface_get_material(s)
			if mat != null and String(mat.resource_name).to_lower().contains("leaf"):
				var m := StandardMaterial3D.new()
				m.albedo_color = tint
				m.roughness = 0.8
				copy.surface_set_material(s, m)
		_tinted[key] = copy
	return _tinted[key]


## Shows only the faces turned toward the camera on every mesh in `node`
## (cached copies of its meshes, with back-face culling on): a model turned
## round to fill in another's missing back must not show through the front.
static func single_sided(node: Node) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		var key := [mi.mesh, &"single_sided"]
		if not _tinted.has(key):
			var copy: Mesh = mi.mesh.duplicate()
			for s in copy.get_surface_count():
				var mat := copy.surface_get_material(s)
				if mat is BaseMaterial3D:
					var m: BaseMaterial3D = mat.duplicate()
					m.cull_mode = BaseMaterial3D.CULL_BACK
					copy.surface_set_material(s, m)
			_tinted[key] = copy
		mi.mesh = _tinted[key]


static func _no_shadows(node: Node) -> void:
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
