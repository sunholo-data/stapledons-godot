// M4.2 forward glow: the bubble wall's inward glow over the whole sky, drawn additively in the
// sky SubViewport before its one tonemap (design m4-first-journey.md "M4.2"). The CPU
// reference is interior/forward_glow.gd; make golden (G-M4-4) checks this shader against it.
//
// Per pixel: the view ray (world = the sky's Godot frame) is turned into the ship frame
// (+Z = direction of travel) with the ship axes, traced from the panorama camera's ship-frame
// position to the wall (sphere of radius R about the bubble centre), and the wall point's
// cos(theta) gives the emittance E = pole x clamp(cos theta, 0, 1) (W/m^2; glowEmittanceAt's
// shape, the pole value is the sim's ship.ism.glow_pole_w_m2). The pixel is
// E x scale x colour, scale = k / pi x lm/W (Lambertian radiance -> luminance -> M1.5a
// exposure k), colour of unit luminance. debug_unit writes E itself (unit gain, W/m^2) for
// the absolute golden.
shader_type spatial;
render_mode unshaded, blend_add, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 ship_x = vec3(1.0, 0.0, 0.0); // ship axes as world (sky-frame) vectors
uniform vec3 ship_y = vec3(0.0, 1.0, 0.0);
uniform vec3 ship_z = vec3(0.0, 0.0, 1.0);
uniform vec3 cam_ship = vec3(0.0);         // panorama camera position, ship frame, metres
uniform float radius = 100.0;              // bubble radius, metres (sim params.bubble_radius_m)
uniform float pole = 0.0;                  // W/m^2, the sim's glow_pole_w_m2 (0 = off)
uniform float scale = 0.0;                 // pixel per W/m^2 of emittance
uniform vec3 colour = vec3(1.0);
uniform bool debug_unit = false;

void vertex() {
	POSITION = vec4(VERTEX.xy, 0.5, 1.0); // a full-screen quad (QuadMesh 2 x 2)
}

void fragment() {
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, 0.5, 1.0);
	vec3 w = normalize(mat3(INV_VIEW_MATRIX) * normalize(v.xyz / v.w));
	vec3 d = vec3(dot(w, ship_x), dot(w, ship_y), dot(w, ship_z));
	float b = dot(cam_ship, d);
	float t = -b + sqrt(max(b * b + radius * radius - dot(cam_ship, cam_ship), 0.0));
	float ct = (cam_ship.z + t * d.z) / radius;
	float e = pole * clamp(ct, 0.0, 1.0);
	ALBEDO = debug_unit ? vec3(e) : colour * (e * scale);
}
