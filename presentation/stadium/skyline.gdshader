shader_type spatial;
// Distant city towers: flat color with a procedural grid of windows, some
// lit, picked per window from a hash of its world-space cell.

uniform vec4 wall_color : source_color = vec4(0.17, 0.17, 0.32, 1.0);
uniform vec4 window_color : source_color = vec4(1.0, 0.85, 0.5, 1.0);
uniform float lit_share = 0.35;
uniform float glow = 0.6;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float hash(vec2 c) {
	return fract(sin(dot(c, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	float along = abs(world_normal.x) > abs(world_normal.z) ? world_pos.z : world_pos.x;
	vec2 cell = floor(vec2(along / 3.2, world_pos.y / 4.0));
	vec2 f = fract(vec2(along / 3.2, world_pos.y / 4.0));
	float window = step(0.2, f.x) * step(f.x, 0.8) * step(0.25, f.y) * step(f.y, 0.75);
	float side = 1.0 - step(0.9, abs(world_normal.y));
	float lit = step(hash(cell + floor(world_pos.xz / 40.0)), lit_share) * window * side;
	ALBEDO = mix(wall_color.rgb, window_color.rgb * 0.6, window * side * 0.35);
	EMISSION = window_color.rgb * lit * glow;
	ROUGHNESS = 0.8;
}
