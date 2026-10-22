shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
// One fan per MultiMesh instance: an upright billboard flip-booking the
// baked crowd atlas (tools/bake_crowd.gd): the player mannequin seated,
// seated clapping, standing clapping, arms-up cheering, jumping, fist
// pumping, 4 frames each. Red is the body region, green the light; each
// fan is recolored here: shirt from the instance color (club or neutral),
// pants, shoes, skin and hair from the instance's own numbers.
// INSTANCE_CUSTOM: x = phase, y = tempo, z = temperament (who stands and
// who stays seated), w = skin tone.
// How excited the crowd is (0 calm .. 1 a home run) picks the poses.

uniform sampler2D atlas : filter_linear_mipmap, repeat_disable;
uniform float excitement : hint_range(0.0, 1.0) = 0.0;
uniform vec3 skin_light : source_color = vec3(0.96, 0.8, 0.66);
uniform vec3 skin_dark : source_color = vec3(0.36, 0.23, 0.15);
// Atlas layout: 8 cells across, 3 down; pose p frame f is cell p * 4 + f.
const float COLS = 8.0;
const float ROWS = 3.0;

varying flat int v_cell;
varying float v_skin;
varying float v_phase;
varying float v_shade;

int pose_for(float e, float temper, float phase) {
	// Calm: everyone seated, a few chatting. Building: the keen ones clap.
	// Big: most stand and clap or pump a fist. Huge: on their feet,
	// arms up, the young ones jumping.
	if (e < 0.18) {
		return 0;
	}
	if (e < 0.45) {
		return temper > 0.55 ? 1 : 0;
	}
	if (e < 0.75) {
		return temper > 0.7 ? 5 : (temper > 0.3 ? 2 : 1);
	}
	return temper > 0.65 ? 4 : (temper > 0.25 ? 3 : 2);
}

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 to_cam = vec3(cam.x - origin.x, 0.0, cam.z - origin.z);
	to_cam = length(to_cam) > 0.001 ? normalize(to_cam) : vec3(0.0, 0.0, 1.0);
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), to_cam));
	float phase = INSTANCE_CUSTOM.x;
	float tempo = 0.8 + INSTANCE_CUSTOM.y * 0.6;
	// Each fan reacts a beat late or early, so the stands ripple.
	float e = clamp(excitement + (phase - 0.5) * 0.15, 0.0, 1.0);
	int pose = pose_for(e, INSTANCE_CUSTOM.z, phase);
	float speed = pose == 0 ? 0.6 : (pose == 4 ? 5.5 : 4.0);
	int frame = int(mod(floor(TIME * speed * tempo + phase * 4.0), 4.0));
	v_cell = pose * 4 + frame;
	// Seated fans sink onto the chair (the chair in front hides their
	// shins); standing ones step forward off it, toward home plate (the
	// instance faces it: -Z).
	vec3 toward = -MODEL_MATRIX[2].xyz;
	toward = length(toward.xz) > 0.001 ? normalize(vec3(toward.x, 0.0, toward.z)) : vec3(0.0);
	origin += pose <= 1 ? vec3(0.0, -0.32, 0.0) : toward * 0.3;
	vec3 world = origin + right * VERTEX.x + vec3(0.0, VERTEX.y, 0.0);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	v_skin = INSTANCE_CUSTOM.w;
	v_phase = phase;
	v_shade = 0.85 + 0.15 * fract(phase * 7.0);
}

vec3 hair_color(float k) {
	if (k < 0.35) return vec3(0.06, 0.05, 0.04);
	if (k < 0.65) return vec3(0.25, 0.15, 0.08);
	if (k < 0.85) return vec3(0.55, 0.38, 0.2);
	return vec3(0.75, 0.62, 0.38);
}

void fragment() {
	vec2 cell = vec2(float(v_cell % 8), float(v_cell / 8));
	vec2 uv = (cell + vec2(UV.x, UV.y)) / vec2(COLS, ROWS);
	vec4 s = texture(atlas, uv);
	if (s.a < 0.5) {
		discard;
	}
	int region = int(round(s.r * 8.0));
	vec3 skin = mix(skin_light, skin_dark, v_skin);
	vec3 col = COLOR.rgb;
	if (region == 1) { col = COLOR.rgb * 0.75; }
	else if (region == 2 || region == 3 || region == 4) {
		// Jeans, khakis or black pants.
		float k = fract(v_phase * 13.0);
		col = k < 0.5 ? vec3(0.16, 0.22, 0.38) : (k < 0.8 ? vec3(0.42, 0.37, 0.28) : vec3(0.08, 0.08, 0.09));
	}
	else if (region == 5) { col = vec3(0.12, 0.12, 0.13); }
	else if (region == 6 || region == 7) { col = skin; }
	else if (region == 8) { col = hair_color(fract(v_phase * 31.0)); }
	ALBEDO = col * (0.45 + s.g * 0.75) * v_shade;
}
