// R2-BRIDGE-STYLE S2 (design_docs/implemented/r2/bridge-styling-pass.md, D-100): the art bible's banded
// toon shading for the bridge (art/ship-interior-blender-brief.md §4). Keeps the albedo (texture x
// colour) and the normal map; every light's diffuse falls into three bands, with a soft edge against
// aliasing at the slide's motion; no specular. The ink outline (interior/outline.gdshader) is this
// material's next_pass. Ambient stays flat. Never applied to the sky (its own viewport).
// Card mode (D-106 painted foliage, merged from the plants spike, PR #299): a painted card is alpha-cut
// at `scissor`, its painted ink edge kept, lit through a rounded normal centred on the plant (so it bands
// under the spire and the star like a volume), and turned about its up axis toward the camera, clamped
// to +-clamp_deg of its authored facing (+z), so the slide never shows it edge-on.
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
// Card mode.
uniform bool card = false;
uniform sampler2D card_tex : source_color, filter_linear_mipmap;
uniform float scissor = 0.55;
uniform float sphere_mix = 0.75;
uniform float card_bias = 0.9;
uniform float clamp_deg = 25.0;
uniform bool card_flip = false;
uniform vec4 card_ink : source_color = vec4(0.24, 0.13, 0.33, 1.0);
instance uniform vec3 cloud_center = vec3(0.0);
instance uniform vec3 cloud_radii = vec3(1.0);
varying vec3 world_pos;

void vertex() {
	if (card) {
		// The camera in the card's frame; turn the card about +y toward it, clamped.
		vec3 cam = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
		float a = clamp(atan(cam.x, cam.z), -radians(clamp_deg), radians(clamp_deg));
		mat2 r = mat2(vec2(cos(a), -sin(a)), vec2(sin(a), cos(a)));
		VERTEX.xz = r * VERTEX.xz;
		NORMAL.xz = r * NORMAL.xz;
	}
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = UV * uv_scale.xy + uv_offset.xy;
	vec3 c = albedo.rgb;
	if (has_tex) {
		c *= texture(albedo_tex, uv).rgb;
	}
	if (card) {
		vec4 t = texture(card_tex, card_flip ? vec2(1.0 - UV.x, UV.y) : UV);
		if (t.a < scissor) {
			discard;
		}
		c = mix(card_ink.rgb, t.rgb, smoothstep(scissor, 0.97, t.a)) * albedo.rgb;
		vec3 d = (world_pos - cloud_center) / cloud_radii;
		vec3 nw = normalize(normalize(d + vec3(1e-4)) + INV_VIEW_MATRIX[2].xyz * card_bias);
		NORMAL = normalize(mix(FRONT_FACING ? NORMAL : -NORMAL, normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz), sphere_mix));
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
	// The darkest band holds wherever the light reaches at all, and fades out only as the attenuation
	// goes to zero (in a shadow, and in the last metres of an omni light's range), so a shadow reads as
	// a shadow, the range ends without a hard ring, and the bridge's rim, far from the spire, stays lit.
	float lo = value_lo * smoothstep(0.0, 0.02, ATTENUATION);
	float b = mix(lo, value_mid, smoothstep(band_lo - band_edge, band_lo + band_edge, ndl));
	b = mix(b, value_hi, smoothstep(band_hi - band_edge, band_hi + band_edge, ndl));
	DIFFUSE_LIGHT += b * LIGHT_COLOR * ALBEDO / PI;
}
