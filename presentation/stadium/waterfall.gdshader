shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// A falling sheet of water on a quad: streaks of white water scroll down
// over a deeper blue body, with foam at the lip and the splash. "flow" is
// the fall speed (0 freezes it into ice); "lava" turns it to molten metal.

uniform vec4 color : source_color = vec4(0.4, 0.72, 0.95, 1.0);
uniform vec4 foam : source_color = vec4(0.95, 0.98, 1.0, 1.0);
uniform float glow = 0.3;
uniform float flow = 1.0;
uniform float streaks = 9.0;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i.x + i.y * 57.0);
	float b = hash(i.x + 1.0 + i.y * 57.0);
	float c = hash(i.x + (i.y + 1.0) * 57.0);
	float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * flow;
	// Columns of water fall at slightly different speeds.
	float col = floor(uv.x * streaks);
	float speed = 0.8 + 0.6 * hash(col);
	float n = noise(vec2(uv.x * streaks * 2.0, uv.y * 6.0 - t * 2.5 * speed));
	n = n * 0.6 + 0.4 * noise(vec2(uv.x * streaks * 5.0, uv.y * 14.0 - t * 4.0 * speed));
	float white = smoothstep(0.55, 0.85, n);
	// Foam where it leaves the lip (top) and where it lands (bottom).
	float lip = smoothstep(0.12, 0.0, uv.y);
	float splash = smoothstep(0.8, 1.0, uv.y);
	white = clamp(white + lip * 0.8 + splash * 0.7, 0.0, 1.0);
	// Thinner, see-through water at the ragged side edges.
	float edge = smoothstep(0.0, 0.08, uv.x) * smoothstep(1.0, 0.92, uv.x);
	vec3 body = mix(color.rgb * 0.75, color.rgb, n);
	vec3 c = mix(body, foam.rgb, white);
	ALBEDO = c;
	EMISSION = c * glow;
	ROUGHNESS = 0.1;
	SPECULAR = 0.7;
	ALPHA = (0.72 + 0.28 * white) * edge;
}
