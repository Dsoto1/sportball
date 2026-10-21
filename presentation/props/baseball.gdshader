shader_type spatial;
// A baseball: off-white leather with the figure-eight seam and red double
// stitching, drawn on any sphere from its own surface direction. The seam
// is the classic tennis-ball curve, which lies exactly on the unit sphere:
//   (a cos t + b cos 3t, a sin t - b sin 3t, 2 sqrt(ab) sin 2t), a + b = 1.

uniform vec4 leather : source_color = vec4(0.95, 0.93, 0.86, 1.0);
uniform vec4 stitch : source_color = vec4(0.82, 0.08, 0.08, 1.0);
uniform float seam_b = 0.36;
uniform float stitches = 108.0;

varying vec3 dir;

void vertex() {
	dir = normalize(VERTEX);
}

vec3 seam(float t) {
	float a = 1.0 - seam_b;
	return vec3(a * cos(t) + seam_b * cos(3.0 * t), a * sin(t) - seam_b * sin(3.0 * t), 2.0 * sqrt(a * seam_b) * sin(2.0 * t));
}

void fragment() {
	vec3 p = normalize(dir);
	// Nearest point on the seam: coarse search, then refine around the best.
	float best_t = 0.0;
	float best_d = 10.0;
	for (int i = 0; i < 48; i++) {
		float t = float(i) / 48.0 * TAU;
		float d = distance(p, seam(t));
		if (d < best_d) { best_d = d; best_t = t; }
	}
	float step_t = TAU / 48.0;
	for (int k = 0; k < 2; k++) {
		step_t *= 0.25;
		for (int j = -3; j <= 3; j++) {
			float t = best_t + float(j) * step_t;
			float d = distance(p, seam(t));
			if (d < best_d) { best_d = d; best_t = t; }
		}
	}
	vec3 col = leather.rgb;
	// The seam itself: a thin shaded groove.
	float groove = 1.0 - smoothstep(0.012, 0.022, best_d);
	col *= 1.0 - 0.35 * groove;
	// V-shaped stitches either side of the groove.
	float along = fract(best_t / TAU * stitches);
	float across = (best_d - 0.03) / 0.05;
	float v_mark = abs(along - 0.5 - across * 0.25);
	float stitched = step(0.0, across) * step(across, 1.0) * (1.0 - smoothstep(0.12, 0.2, v_mark));
	col = mix(col, stitch.rgb, stitched);
	ALBEDO = col;
	ROUGHNESS = 0.6;
}
