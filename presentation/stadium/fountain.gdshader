shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// Moving water: fountain jets rise and fall (a unit cylinder stretched to
// a pulsing height above its base) and cascade sheets shimmer downward.

uniform vec4 color : source_color = vec4(0.7, 0.9, 1.0, 1.0);
uniform float glow = 0.3;
instance uniform float phase = 0.0;
instance uniform float peak = 0.0;

varying float v_height;

void vertex() {
	if (peak > 0.0) {
		float h = peak * (0.55 + 0.45 * sin(TIME * 1.7 + phase));
		// Unit cylinder centered on the origin: base on the water, top at h.
		VERTEX.y = (VERTEX.y + 0.5) * h;
		VERTEX.xz *= mix(1.0, 1.8, VERTEX.y / max(h, 0.01));
	}
	v_height = VERTEX.y;
}

void fragment() {
	float ripple = 0.75 + 0.25 * sin(v_height * 3.0 - TIME * 9.0 + UV.x * 20.0);
	ALBEDO = color.rgb * ripple;
	EMISSION = color.rgb * glow * ripple;
	ROUGHNESS = 0.15;
	ALPHA = 0.55;
}
