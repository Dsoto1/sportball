shader_type spatial;
render_mode cull_disabled;
// The uniform as cloth over the mannequin (UniformLook.shell_for). UV is
// the rest-pose position across the body (x, z: +Z the front), UV2 the
// region (jersey, sleeve trim, belt, pants) and rest height. On top of the
// team colors: a woven fabric grain, folds where kits gather (the waist,
// behind the knee, the blousing over the socks, the inside of the elbow),
// the button placket down the jersey's front, and piping down the pants'
// sides. Inside a sleeve or a pant leg it is in shadow.

uniform vec4 jersey : source_color = vec4(0.2, 0.3, 0.7, 1.0);
uniform vec4 trim : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 pants : source_color = vec4(0.93, 0.93, 0.9, 1.0);

varying vec3 v_rest;
varying float v_region;

void vertex() {
	v_rest = vec3(UV.x, UV2.y, UV.y);
	v_region = UV2.x;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	int r = int(round(v_region));
	vec3 p = v_rest;
	vec3 col = jersey.rgb;
	float rough = 0.82;
	if (r == 1) { col = trim.rgb; }
	else if (r == 2) { col = trim.rgb * 0.55; rough = 0.4; }
	else if (r == 3) { col = pants.rgb; rough = 0.88; }
	// Folds: soft bands across the body, strongest where the kit gathers.
	float gather = 0.0;
	float along = p.y;
	if (r == 0) {
		gather = smoothstep(1.16, 1.02, p.y);
	} else if (r == 3) {
		gather = max(smoothstep(0.62, 0.5, p.y) * smoothstep(0.38, 0.45, p.y) * (p.z < 0.0 ? 1.0 : 0.45), smoothstep(0.86, 0.95, p.y) * 0.4);
	}
	float wobble = noise(vec2(p.x * 9.0 + p.z * 7.0, p.y * 3.0)) * 0.6;
	float fold = sin((along + wobble * 0.02) * 120.0 + p.x * 14.0) * 0.5 + 0.5;
	col *= 1.0 - gather * 0.16 * fold;
	// The button placket and buttons down the jersey's front.
	if (r == 0 && p.z > 0.05 && p.y > 1.0 && p.y < 1.43) {
		float edge = abs(p.x);
		if (edge < 0.016 && edge > 0.009) { col = mix(col, trim.rgb, 0.85); }
		float button = length(vec2(p.x, mod(p.y - 1.02, 0.075) - 0.0375));
		if (button < 0.006) { col = vec3(0.92, 0.91, 0.88); rough = 0.3; }
	}
	// Piping down the outside of each pant leg.
	if (r == 3 && abs(p.z) < 0.012 && abs(p.x) > 0.06) { col = trim.rgb; }
	// A fine woven grain.
	float grain = noise(vec2(p.x + p.z, p.y) * 900.0) - 0.5;
	col *= 1.0 + grain * 0.06;
	if (!FRONT_FACING) {
		col *= 0.35;
	}
	ALBEDO = col;
	ROUGHNESS = rough;
	SPECULAR = 0.25;
}
