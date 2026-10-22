shader_type spatial;
render_mode unshaded, cull_back;
// Bakes a fan for the crowd atlas: the body region in red (UniformLook's
// region / 8; hair is 8), soft light from the front in green. The crowd
// shader recolors each fan from these (shirt, pants, skin, hair).

uniform float forced_region = -1.0;
varying float v_region;

void vertex() {
	v_region = UV2.x;
}

void fragment() {
	float r = forced_region >= 0.0 ? forced_region : round(v_region);
	float shade = clamp(dot(NORMAL, normalize(vec3(0.35, 0.55, 0.75))) * 0.55 + 0.5, 0.0, 1.0);
	ALBEDO = vec3(r / 8.0, shade, 0.0);
}
