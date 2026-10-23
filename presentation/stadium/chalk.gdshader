shader_type spatial;
render_mode cull_disabled;
// Flat marks on the field (chalk lines, the plate, its rim): a plain color
// pulled toward the camera like the field's layers (field_surface.gdshader)
// so they lie flat on the dirt without flickering.

uniform vec4 albedo : source_color = vec4(0.95, 0.95, 0.9, 1.0);
uniform float roughness_value = 0.9;
uniform float pull = 0.0018;

void vertex() {
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.xyz *= 1.0 - pull;
	POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.2;
}
