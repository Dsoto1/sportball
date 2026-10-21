shader_type spatial;
// Turned wood bat: grain runs along the length (UV.y, 0 = knob end) and
// wraps around (UV.x). The handle wears grip tape wound in a spiral.

uniform vec4 wood : source_color = vec4(0.86, 0.66, 0.4, 1.0);
uniform vec4 grain : source_color = vec4(0.62, 0.42, 0.22, 1.0);
uniform vec4 tape : source_color = vec4(0.1, 0.1, 0.12, 1.0);
uniform float tape_end = 0.3;

float hash(float n) { return fract(sin(n) * 43758.5453); }
float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	return mix(hash(i), hash(i + 1.0), f * f * (3.0 - 2.0 * f));
}

void fragment() {
	float u = UV.x;
	float v = UV.y;
	// Long streaks of grain that wander slowly around the bat.
	float lines = sin((u * 38.0 + noise(v * 6.0 + u * 3.0) * 2.5) * 6.2831);
	float streak = smoothstep(0.55, 1.0, lines) * (0.5 + 0.5 * noise(u * 40.0 + v * 4.0));
	vec3 col = mix(wood.rgb, grain.rgb, streak * 0.7);
	float rough = 0.35;
	if (v < tape_end) {
		float wrap = fract(v * 34.0 + u);
		col = tape.rgb * (0.8 + 0.25 * smoothstep(0.0, 0.15, wrap) * (1.0 - smoothstep(0.85, 1.0, wrap)));
		rough = 0.9;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
}
