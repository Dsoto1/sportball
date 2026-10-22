shader_type spatial;
render_mode cull_disabled;
// The land (and open water) around a park, out to the horizon:
// - the park's surface texture (world-space, top-down) tinted by the
//   vertex color, broken up by large soft patches so it never reads as
//   one flat color;
// - in a city, a street grid: asphalt roads with lane dashes and pale
//   sidewalks, on the same blocks the skyline's buildings stand on;
// - haze: from `haze_start` to `haze_end` m off the middle of the field it
//   fades into the sky's horizon color, so the land meets the sky instead
//   of ending at an edge.
// - inside a city's streets, parkland lawn round the park.
// Water uses it too ("water" > 0): flat color with a slow shimmer.

uniform sampler2D detail : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float tile = 6.0;
uniform float has_detail = 0.0;
uniform float roughness_value = 0.9;
uniform float water = 0.0;
uniform vec3 water_color : source_color = vec3(0.06, 0.22, 0.36);
uniform float water_glow = 0.0;
uniform float streets = 0.0;
uniform float block = 72.0;
uniform float street_width = 12.0;
uniform vec2 grid_origin = vec2(0.0, -45.0);
uniform vec3 asphalt : source_color = vec3(0.16, 0.16, 0.18);
uniform vec3 sidewalk : source_color = vec3(0.55, 0.54, 0.52);
uniform float streets_from = 0.0;
// In a city, the ring inside the streets is parkland lawn.
uniform vec3 lawn : source_color = vec3(0.3, 0.45, 0.22);
uniform vec3 haze_color : source_color = vec3(0.72, 0.84, 0.95);
uniform float haze_start = 700.0;
uniform float haze_end = 2300.0;
uniform vec2 center = vec2(0.0, -45.0);

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
	vec2 p = world_pos.xz;
	float macro = noise(p / 140.0) * 0.6 + noise(p / 37.0) * 0.4;
	vec3 col;
	vec3 emission = vec3(0.0);
	float rough = roughness_value;
	if (water > 0.0) {
		float shimmer = noise(p / 9.0 + vec2(TIME * 0.15, TIME * 0.1)) * 0.5 + noise(p / 23.0 - vec2(TIME * 0.07, 0.0)) * 0.5;
		col = water_color * (0.85 + 0.3 * shimmer);
		rough = 0.25;
		emission = water_color * water_glow;
	} else {
		col = COLOR.rgb * (0.86 + 0.28 * macro);
		if (has_detail > 0.0) {
			vec3 d = texture(detail, p / tile).rgb;
			col *= 0.55 + 0.9 * d.r;
			NORMAL_MAP = texture(detail_normal, p / tile).rgb;
			NORMAL_MAP_DEPTH = 0.6;
		}
		float from_center = length(p - center);
		if (streets > 0.0) {
			float grass = 1.0 - smoothstep(streets_from - 30.0, streets_from - 6.0, from_center);
			col = mix(col, lawn * (0.8 + 0.35 * macro), grass);
		}
		if (streets > 0.0 && from_center > streets_from) {
			vec2 g = abs(fract((p - grid_origin) / block + 0.5) - 0.5) * block;
			float edge = min(g.x, g.y);
			float half_w = street_width * 0.5;
			if (edge < half_w) {
				col = asphalt * (0.9 + 0.2 * macro) * 0.5;
				rough = 0.75;
				// Dashed center lines along whichever street this is.
				float along = g.x < g.y ? p.y : p.x;
				float line_d = g.x < g.y ? g.x : g.y;
				if (line_d < 0.18 && fract(along / 9.0) < 0.5) {
					col = vec3(0.85, 0.75, 0.35);
				}
			} else if (edge < half_w + 3.0) {
				col = sidewalk * (0.9 + 0.2 * macro) * 0.6;
			}
		}
	}
	float haze = smoothstep(haze_start, haze_end, length(p - center));
	ALBEDO = col * (1.0 - haze);
	EMISSION = emission * (1.0 - haze) + haze_color * haze;
	ROUGHNESS = mix(rough, 1.0, haze);
	SPECULAR = 0.5 * (1.0 - haze);
}
