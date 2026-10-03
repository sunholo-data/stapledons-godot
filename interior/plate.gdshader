// M4.2 plate material (panorama, foreground and, for bridge v2, the projected play plate).
// v1 draws the plate unchanged. Bridge v2 hook: a live forward-glow tint/rim term slots in
// here without touching the composite. glow_rgb is the glow's exposed pixel at the forward pole
// (Interior pushes it every state), rim_mask an optional per-plate mask (R = how much the
// painted surface faces the direction of travel). rim_strength 0 (the default) leaves the
// plate byte-identical.
shader_type canvas_item;

uniform vec3 glow_rgb = vec3(0.0);
uniform sampler2D rim_mask : hint_default_black;
uniform float rim_strength = 0.0;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb += rim_strength * glow_rgb * texture(rim_mask, UV).r * c.a;
	COLOR = c;
}
