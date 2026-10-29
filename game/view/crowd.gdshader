// The crowd (view/crowd.gd): one spectator mesh for everyone. The mesh's
// UV.x says which part a vertex is (0 shirt, 0.25 skin, 0.5
// trousers, 0.75 hair); each person's shirt is INSTANCE_CUSTOM.rgb, and
// .a packs their skin, trousers and hair (index / 64).
shader_type spatial;

uniform float dim = 1.0;  // FOCUS (ADR-013)

const vec3 SKINS[4] = vec3[](vec3(0.95, 0.78, 0.62), vec3(0.78, 0.56, 0.4), vec3(0.55, 0.37, 0.24), vec3(0.98, 0.84, 0.72));
const vec3 PANTS[4] = vec3[](vec3(0.15, 0.18, 0.3), vec3(0.2, 0.2, 0.22), vec3(0.42, 0.36, 0.28), vec3(0.3, 0.4, 0.55));
const vec3 HAIRS[4] = vec3[](vec3(0.12, 0.08, 0.05), vec3(0.3, 0.19, 0.1), vec3(0.62, 0.48, 0.28), vec3(0.6, 0.6, 0.6));

varying vec3 tint;

void vertex() {
	int idx = int(INSTANCE_CUSTOM.a * 64.0 + 0.5);
	float part = UV.x;
	if (part < 0.12) {
		tint = INSTANCE_CUSTOM.rgb;
	} else if (part < 0.37) {
		tint = SKINS[idx % 4];
	} else if (part < 0.62) {
		tint = PANTS[(idx / 4) % 4];
	} else {
		tint = HAIRS[(idx / 16) % 4];
	}
}

void fragment() {
	ALBEDO = tint * dim;
	ROUGHNESS = 0.9;
}
