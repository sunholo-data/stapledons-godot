// R2-BRIDGE-STYLE S2 (design_docs/planned/r2/bridge-styling-pass.md, D-100): the art bible's banded
// toon shading for the bridge (art/ship-interior-blender-brief.md §4). Keeps the albedo (texture x
// colour) and the normal map; every light's diffuse falls into three bands, with a soft edge against
// aliasing at the slide's motion; no specular. The ink outline (interior/outline.gdshader) is this
// material's next_pass. Ambient stays flat. Never applied to the sky (its own viewport).
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_tex = false;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = false;
uniform float normal_scale = 1.0;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
// The bands: NdotL x attenuation above band_hi -> value_hi, above band_lo -> value_mid, else value_lo.
// Uniforms so an authored sky framing (D-96) can override them per shot.
uniform float band_hi = 0.55;
uniform float band_lo = 0.12;
uniform float value_hi = 1.0;
uniform float value_mid = 0.55;
uniform float value_lo = 0.18;
uniform float band_edge = 0.02;

void fragment() {
	vec2 uv = UV * uv_scale.xy + uv_offset.xy;
	vec3 c = albedo.rgb;
	if (has_tex) {
		c *= texture(albedo_tex, uv).rgb;
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	if (has_normal) {
		NORMAL_MAP = texture(normal_tex, uv).rgb;
		NORMAL_MAP_DEPTH = normal_scale;
	}
}

void light() {
	float ndl = max(dot(NORMAL, LIGHT), 0.0) * ATTENUATION;
	// The darkest band fades out with the attenuation (shadow and range), so a shadow reads as a
	// shadow and an omni light's range ends without a hard ring.
	float lo = value_lo * smoothstep(0.0, 0.1, ATTENUATION);
	float b = mix(lo, value_mid, smoothstep(band_lo - band_edge, band_lo + band_edge, ndl));
	b = mix(b, value_hi, smoothstep(band_hi - band_edge, band_hi + band_edge, ndl));
	DIFFUSE_LIGHT += b * LIGHT_COLOR * ALBEDO / PI;
}
