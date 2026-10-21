shader_type spatial;
render_mode unshaded, cull_disabled;
// One fan per MultiMesh instance: an upright billboard drawn as a simple
// silhouette (head, shoulders, raised arms when the crowd is excited).
// INSTANCE_CUSTOM: x = phase, y = bounce speed, z = arm-raiser, w = skin tone.

uniform float excitement : hint_range(0.0, 1.0) = 0.0;
uniform vec3 skin_light : source_color = vec3(0.96, 0.8, 0.66);
uniform vec3 skin_dark : source_color = vec3(0.42, 0.27, 0.17);

varying float v_arms;
varying float v_skin;
varying float v_shade;

void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 to_cam = vec3(cam.x - origin.x, 0.0, cam.z - origin.z);
	to_cam = length(to_cam) > 0.001 ? normalize(to_cam) : vec3(0.0, 0.0, 1.0);
	vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), to_cam));
	float phase = INSTANCE_CUSTOM.x * 6.2831;
	float hop = excitement * max(0.0, sin(TIME * (5.0 + INSTANCE_CUSTOM.y * 4.0) + phase)) * 0.5;
	float sway = sin(TIME * 1.3 + phase) * 0.03;
	vec3 world = origin + right * (VERTEX.x + sway) + vec3(0.0, VERTEX.y + hop, 0.0);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world, 1.0);
	v_arms = step(0.5, INSTANCE_CUSTOM.z) * smoothstep(0.25, 0.6, excitement);
	v_skin = INSTANCE_CUSTOM.w;
	v_shade = 0.8 + 0.2 * fract(INSTANCE_CUSTOM.x * 7.0);
}

void fragment() {
	vec2 p = UV;  // (0,0) top-left
	float head = step(length((p - vec2(0.5, 0.2)) * vec2(1.0, 1.25)), 0.15);
	float body = step(0.22, p.x) * step(p.x, 0.78) * step(0.36, p.y);
	float shoulders = step(length((p - vec2(0.5, 0.44)) * vec2(0.9, 2.0)), 0.3);
	float arm_l = step(0.1, p.x) * step(p.x, 0.22) * step(0.0, p.y) * step(p.y, 0.48);
	float arm_r = step(0.78, p.x) * step(p.x, 0.9) * step(0.0, p.y) * step(p.y, 0.48);
	float arms = (arm_l + arm_r) * v_arms;
	float shirt = max(body, shoulders);
	float mask = max(max(head, shirt), arms);
	if (mask < 0.5) {
		discard;
	}
	vec3 skin = mix(skin_light, skin_dark, v_skin);
	vec3 col = head > 0.5 ? skin : (shirt > 0.5 ? COLOR.rgb : skin);
	ALBEDO = col * v_shade * mix(1.0, 0.75, p.y);
}
