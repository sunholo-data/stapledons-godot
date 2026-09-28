// SPIKE: inverted-hull ink outline (drawn as next_pass of the toon material).
shader_type spatial;
render_mode unshaded, cull_front;

uniform vec4 ink : source_color = vec4(0.13, 0.08, 0.2, 1.0);
uniform float width = 0.05; // metres

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = ink.rgb;
}
