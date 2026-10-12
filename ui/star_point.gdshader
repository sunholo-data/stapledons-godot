// Galaxy-map star: a disc of fixed pixel radius at the instance origin.
//   INSTANCE_CUSTOM = (r, g, b, radius in px). Cosmetic only; no physics.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

varying vec2 q;
varying vec3 tint;

void vertex() {
	q = VERTEX.xy * 2.0;
	tint = INSTANCE_CUSTOM.rgb;
	vec4 c = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0));
	if (c.w <= 0.0) {
		POSITION = vec4(0.0, 0.0, 2.0, 1.0); // behind the camera: never mirrored into view
	} else {
		c.xy += q * INSTANCE_CUSTOM.a * 2.0 / VIEWPORT_SIZE * c.w;
		POSITION = c;
	}
}

void fragment() {
	float r = length(q);
	if (r > 1.0) {
		discard;
	}
	ALBEDO = tint * (1.0 - r * r);
}
