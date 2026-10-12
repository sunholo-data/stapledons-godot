// M4.2 (from spike/iso-bridge): banded toon shading for Blender-built isometric sets (Moebius-ish flat colour).
shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 emission : source_color = vec4(0.0);
uniform float emission_energy = 0.0;

void fragment() {
	ALBEDO = albedo.rgb;
	EMISSION = emission.rgb * emission_energy;
}

void light() {
	float n = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION;
	float band = n > 0.55 ? 1.0 : (n > 0.15 ? 0.7 : 0.45);
	DIFFUSE_LIGHT += band * LIGHT_COLOR / PI * ALBEDO;
}
