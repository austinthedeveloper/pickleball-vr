// A Body's skin and clothes (ADR-018): the clothes are painted by where
// each spot sits in the model's T-pose (metres, from the vertex colour).
shader_type spatial;

uniform sampler2D skin_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec4 shirt : source_color = vec4(0.95, 0.55, 0.12, 1.0);
uniform vec4 shorts : source_color = vec4(0.15, 0.18, 0.3, 1.0);
uniform vec3 box_pos;
uniform vec3 box_size;
uniform bool female = false;

const vec3 SHOE = vec3(0.92, 0.92, 0.94);
const vec3 SOLE = vec3(0.3, 0.3, 0.32);
const vec3 SOCK = vec3(0.97, 0.97, 0.97);

varying vec3 bind;

void vertex() {
	bind = box_pos + COLOR.rgb * box_size;
}

void fragment() {
	vec3 skin = texture(skin_tex, UV).rgb * tint.rgb;
	float ax = abs(bind.x);
	float y = bind.y;
	vec3 c = skin;
	float cloth = 0.0;
	// Crew neck, lower at the front; short sleeves; the hem over the shorts.
	float neck = (female ? 1.45 : 1.49) - 0.05 * smoothstep(0.0, 0.1, bind.z);
	float collar = neck + 4.0 * pow(max(ax - 0.04, 0.0), 2.0);    // round, over the shoulders
	if (y < 0.012) {
		c = SOLE; cloth = 1.0;
	} else if (y < 0.13) {
		c = SHOE; cloth = 1.0;
	} else if (y < 0.2) {
		c = SOCK; cloth = 1.0;
	} else if (y > 0.66 && y < 1.0) {
		c = shorts.rgb; cloth = 1.0;
	} else if (y >= 1.0 && y < collar && ax < (female ? 0.31 : 0.37)) {
		c = shirt.rgb; cloth = 1.0;
	}
	// Cloth keeps a little of the body's shading (folds), not its colour.
	float lum = dot(texture(skin_tex, UV).rgb, vec3(0.3, 0.59, 0.11));
	c = mix(c, c * clamp(lum * 1.8, 0.6, 1.15), cloth * 0.15);
	ALBEDO = c;
	ROUGHNESS = mix(0.6, 0.92, cloth);
	NORMAL_MAP = mix(texture(normal_tex, UV).rgb, vec3(0.5, 0.5, 1.0), cloth * 0.95);
}
