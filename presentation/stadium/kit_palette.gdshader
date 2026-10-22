shader_type spatial;
// Kenney kits share one palette texture of a few swatch families. This
// remaps each family to a park color role, keeping each swatch's lightness
// so the kit's shading and contrast survive:
//   warm stone and orange -> stone
//   grays and slate        -> metal
//   blues                  -> roof (pale blue window glass -> window;
//                             all blues are glass with blue_is_window)
//   reds                   -> accent
//   yellows                -> trim
//   greens and the rest    -> kept
// "haze" fades a far building toward the horizon color.

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform vec4 stone : source_color = vec4(0.8, 0.7, 0.55, 1.0);
uniform vec4 metal : source_color = vec4(0.45, 0.47, 0.52, 1.0);
uniform vec4 roof : source_color = vec4(0.25, 0.35, 0.6, 1.0);
uniform vec4 accent : source_color = vec4(0.7, 0.15, 0.15, 1.0);
uniform vec4 trim : source_color = vec4(0.9, 0.75, 0.3, 1.0);
uniform vec4 window : source_color = vec4(1.0, 0.85, 0.55, 1.0);
uniform float window_glow = 0.0;
// Kits without blue roofs (townhouses) use blue only for window glass.
uniform bool blue_is_window = false;
uniform vec4 haze_color : source_color = vec4(0.7, 0.75, 0.85, 1.0);
uniform float haze = 0.0;

vec3 hsv(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float d = mx - mn;
	float h = 0.0;
	if (d > 0.0001) {
		if (mx == c.r) {
			h = mod((c.g - c.b) / d, 6.0);
		} else if (mx == c.g) {
			h = (c.b - c.r) / d + 2.0;
		} else {
			h = (c.r - c.g) / d + 4.0;
		}
		h *= 60.0;
	}
	return vec3(h, mx > 0.0 ? d / mx : 0.0, mx);
}

void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb;
	vec3 c = hsv(base);
	float light = dot(base, vec3(0.299, 0.587, 0.114));
	float shade = 0.3 + light * 0.8;
	vec3 out_color = base;
	vec3 emit = vec3(0.0);
	bool warm = c.x > 10.0 && c.x < 50.0 && c.y > 0.12;
	if (!warm && c.y < 0.3 && !(c.x > 190.0 && c.x < 240.0 && light > 0.8)) {
		// Grays (pure white and black stay as they are).
		if (light > 0.04 && light < 0.97) {
			out_color = metal.rgb * shade;
		}
	} else if (c.x > 190.0 && c.x < 260.0) {
		if (light > 0.8 || blue_is_window) {
			out_color = window.rgb * (blue_is_window ? 0.55 + light * 0.5 : 1.0);
			emit = window.rgb * window_glow;
		} else {
			out_color = roof.rgb * shade;
		}
	} else if (c.x < 12.0 || c.x > 340.0) {
		out_color = accent.rgb * shade;
	} else if (c.x < 38.0) {
		out_color = stone.rgb * shade;
	} else if (c.x < 60.0) {
		out_color = trim.rgb * shade;
	}
	ALBEDO = mix(out_color, haze_color.rgb, haze);
	EMISSION = emit * (1.0 - haze);
	ROUGHNESS = 0.85;
}
