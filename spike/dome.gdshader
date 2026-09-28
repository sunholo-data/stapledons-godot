// SPIKE: observation-dome glass — nearly invisible, a faint fresnel sheen so it reads as glass.
shader_type spatial;
render_mode unshaded, blend_mix, cull_back, depth_draw_never;

uniform vec4 tint : source_color = vec4(0.65, 0.9, 1.0, 1.0);

void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = tint.rgb;
	ALPHA = 0.012 + 0.16 * f;
}
