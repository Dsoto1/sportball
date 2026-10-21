shader_type spatial;
// A ballplayer's kit on the mannequin. Each vertex carries its body region
// in COLOR.r (see UniformLook): jersey, sleeve trim, belt, pants, socks,
// cleats, skin, hands. Colors come from the team and the player.

uniform vec4 jersey : source_color = vec4(0.2, 0.3, 0.7, 1.0);
uniform vec4 trim : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform vec4 pants : source_color = vec4(0.93, 0.93, 0.9, 1.0);
uniform vec4 socks : source_color = vec4(0.15, 0.2, 0.5, 1.0);
uniform vec4 cleats : source_color = vec4(0.08, 0.08, 0.09, 1.0);
uniform vec4 skin : source_color = vec4(0.85, 0.65, 0.5, 1.0);
// Batting gloves (trim color) or bare hands (skin).
uniform bool gloved = false;

varying float v_region;

void vertex() {
	v_region = UV2.x;
}

void fragment() {
	int r = int(round(v_region));
	vec3 col = jersey.rgb;
	float rough = 0.75;
	if (r == 1) { col = trim.rgb; }
	else if (r == 2) { col = trim.rgb * 0.55; rough = 0.4; }  // belt
	else if (r == 3) { col = pants.rgb; rough = 0.85; }
	else if (r == 4) { col = socks.rgb; }
	else if (r == 5) { col = cleats.rgb; rough = 0.35; }
	else if (r == 6) { col = skin.rgb; rough = 0.6; }
	else if (r == 7) { col = gloved ? trim.rgb : skin.rgb; rough = gloved ? 0.5 : 0.6; }
	ALBEDO = col;
	ROUGHNESS = rough;
}
