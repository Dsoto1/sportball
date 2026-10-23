shader_type spatial;
render_mode cull_disabled;
// Stylized field surface: the project's flat palette color, with a CC0
// photo texture (ambientCG) used only as low-contrast detail, sampled in
// world space so the field never shows stretched UVs. Grass carries a
// mowing pattern (pattern: 0 none, 1 checker along the baselines, 2 diamond,
// 3 stripes across the line to center, 4 diagonal, 5 rings round home, 6
// sunburst from home), with soft edges as cut grass has.

uniform vec4 base_color : source_color = vec4(0.22, 0.46, 0.25, 1.0);
uniform sampler2D detail : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
// Average brightness of the detail texture (so it neither darkens nor lightens overall).
uniform float detail_mid = 0.5;
// Meters per texture repeat.
uniform float tile = 3.0;
uniform float detail_strength = 0.6;
// +/- brightness of the mowing pattern (0 = none) and its band width.
uniform float stripe_strength = 0.0;
uniform float stripe_width = 7.0;
uniform int pattern = 1;
uniform float normal_strength = 0.4;
uniform float roughness_value = 0.92;
// Grass and dirt hardly shine: at grazing angles the default specular
// mirrors the sky across the whole field and washes it out.
uniform float specular_value = 0.12;
// Walls: map the texture along the wall and up it instead of across the ground.
uniform bool vertical_uv = false;

varying vec3 world_pos;

// Which surface draws on top where they overlap (dirt over grass, chalk
// over dirt): each layer is pulled this fraction of the way toward the
// camera. That leaves it where it is on screen and only wins the depth
// test, so the layers can lie within millimetres of each other (players'
// feet and the ball on the dirt, lines flat on it) without flickering.
uniform float pull = 0.0;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Always written: a shader that writes POSITION anywhere loses the
	// engine's own projection.
	vec4 view = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	view.xyz *= 1.0 - pull;
	POSITION = PROJECTION_MATRIX * view;
}

void fragment() {
	vec2 uv = (vertical_uv ? vec2(world_pos.x + world_pos.z, world_pos.y) : world_pos.xz) / tile;
	float near = dot(texture(detail, uv).rgb, vec3(0.299, 0.587, 0.114)) - detail_mid;
	// A second, larger sample breaks up visible tiling.
	float far = dot(texture(detail, uv * 0.21 + vec2(0.37, 0.61)).rgb, vec3(0.299, 0.587, 0.114)) - detail_mid;
	float shade = 1.0 + (near * 0.7 + far * 0.6) * detail_strength * 2.0;
	vec2 p = world_pos.xz;
	float w = PI / stripe_width;
	float m = 0.0;
	if (pattern == 1) {
		m = sin((p.x + p.y) * w * 0.7071) * sin((p.x - p.y) * w * 0.7071);
	} else if (pattern == 2) {
		m = sin(p.x * w) * sin(p.y * w);
	} else if (pattern == 3) {
		m = sin(p.y * w);
	} else if (pattern == 4) {
		m = sin((p.x + p.y) * w * 0.7071);
	} else if (pattern == 5) {
		m = sin(length(p) * w);
	} else if (pattern == 6) {
		m = sin(atan(p.x, -p.y) * 18.0);
	}
	// Soft-edged bands: the blades lean one way, then the other.
	float band = pattern == 0 ? 0.0 : smoothstep(-0.25, 0.25, m) * 2.0 - 1.0;
	shade += band * stripe_strength;
	ALBEDO = base_color.rgb * shade;
	NORMAL_MAP = texture(detail_normal, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
}
