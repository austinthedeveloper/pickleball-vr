// A Body's hair and brows (ADR-018): the texture's light and shade in the
// person's hair colour.
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D hair_tex : source_color, filter_linear_mipmap;
uniform vec4 hair : source_color = vec4(0.24, 0.15, 0.09, 1.0);

void fragment() {
	vec4 t = texture(hair_tex, UV);
	float lum = dot(t.rgb, vec3(0.3, 0.59, 0.11));
	ALBEDO = hair.rgb * clamp(lum * 2.2, 0.35, 1.6);
	ROUGHNESS = 0.7;
}
