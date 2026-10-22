shader_type spatial;
// A sculpted facade bay recolored for its park: the texture's lightness is
// kept (all the carved detail) and its hue shifted toward the instance
// color. The instance color's alpha is how far (0 = untouched).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform sampler2D orm_tex : hint_default_white, filter_linear_mipmap;
uniform bool has_normal = false;
uniform bool has_orm = false;

varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec3 base = texture(albedo_tex, UV).rgb;
	float light = dot(base, vec3(0.299, 0.587, 0.114));
	vec3 tinted = tint.rgb * (0.35 + light * 1.3);
	ALBEDO = mix(base, tinted, tint.a);
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	if (has_orm) {
		vec3 orm = texture(orm_tex, UV).rgb;
		ROUGHNESS = orm.g;
		METALLIC = orm.b;
	} else {
		ROUGHNESS = 0.85;
	}
}
