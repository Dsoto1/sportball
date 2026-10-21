class_name StadiumSurfaces
## The park's material kit: tileable CC0 surfaces (ambientCG) stored as
## grayscale detail + normal maps and tinted by the park's palette, so every
## park stays in its own colors. Mapped in world space (triplanar), because
## the stadium's geometry is built in code without UVs. A designer picks a
## surface per layer (facade, structure, ground) by name.

## name: [detail texture, normal texture, meters per tile, roughness, metallic]
const KINDS := {
	&"brick": [preload("res://assets/third_party/ambientcg/Bricks085/Bricks085_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Bricks085/Bricks085_512_NormalGL.jpg"), 2.4, 0.9, 0.0],
	&"stone": [preload("res://assets/third_party/ambientcg/Bricks084/Bricks084_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Bricks084/Bricks084_512_NormalGL.jpg"), 3.0, 0.9, 0.0],
	&"concrete": [preload("res://assets/third_party/ambientcg/Concrete034/Concrete034_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Concrete034/Concrete034_512_NormalGL.jpg"), 4.0, 0.85, 0.0],
	&"steel": [preload("res://assets/third_party/ambientcg/MetalPlates013/MetalPlates013_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/MetalPlates013/MetalPlates013_512_NormalGL.jpg"), 3.0, 0.5, 0.55],
	&"wood": [preload("res://assets/third_party/ambientcg/Planks037A/Planks037A_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Planks037A/Planks037A_512_NormalGL.jpg"), 2.5, 0.8, 0.0],
	&"rock": [preload("res://assets/third_party/ambientcg/Rock051/Rock051_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Rock051/Rock051_512_NormalGL.jpg"), 14.0, 0.95, 0.0],
	&"snow": [preload("res://assets/third_party/ambientcg/Snow004/Snow004_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Snow004/Snow004_512_NormalGL.jpg"), 8.0, 0.7, 0.0],
	&"marble": [preload("res://assets/third_party/ambientcg/Marble012/Marble012_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Marble012/Marble012_512_NormalGL.jpg"), 3.0, 0.35, 0.0],
	&"sand": [preload("res://assets/third_party/ambientcg/Ground054/Ground054_512_Detail.jpg"), preload("res://assets/third_party/ambientcg/Ground054/Ground054_512_NormalGL.jpg"), 6.0, 0.95, 0.0],
}

static var _cache := {}


static func kinds() -> Array:
	return KINDS.keys()


## A material of this surface tinted to `color` (plain color for an unknown
## or empty name). `vertex_color` multiplies in mesh vertex colors (the bowl).
static func material(kind: StringName, color: Color, vertex_color: bool = false, scale: float = 1.0) -> StandardMaterial3D:
	if not KINDS.has(kind):
		var plain := GrayboxField._mat(color)
		plain.vertex_color_use_as_albedo = vertex_color
		return plain
	var key := "%s|%s|%s|%s" % [kind, color.to_html(), vertex_color, scale]
	if _cache.has(key):
		return _cache[key]
	var spec: Array = KINDS[kind]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = spec[0]
	m.normal_enabled = true
	m.normal_texture = spec[1]
	m.normal_scale = 0.8
	m.roughness = spec[3]
	m.metallic = spec[4]
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / (float(spec[2]) * scale)
	m.vertex_color_use_as_albedo = vertex_color
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m
