// M4.2 forward glow: the bubble wall's inward glow over the whole sky, drawn additively in the
// sky SubViewport before its one tonemap (design m4-first-journey.md "M4.2"). The CPU
// reference is interior/forward_glow.gd; make golden (G-M4-4) checks this shader against it.
//
// Per pixel: the view ray (world = the sky's Godot frame) is turned into the ship frame
// (+Z = direction of travel) with the ship axes, traced from the panorama camera's ship-frame
// position to the wall (sphere of radius R about the bubble centre), and the wall point's
// cos(theta) gives the emittance E = pole x clamp(cos theta, 0, 1) (W/m^2; glowEmittanceAt's
// shape, the pole value is the sim's ship.ism.glow_pole_w_m2) and the blackbody temperature
// T = t_pole x cos^(1/4) theta (glowTemperatureAt's shape, D-30; t_pole = ship.ism.glow_pole_k).
// The pixel is E x scale x rgb(T) x eta(T): scale = k / pi (Lambertian radiance, M1.5a
// exposure k), rgb(T) the unit-luminance blackbody colour and eta(T) = EFF_K Y(T) / T^4 the
// luminous efficacy (blackbody.luminousEfficacy), both from Blackbody's lookup
// (rgb, a = log10 Y over log T in [300 K, 1e7 K]). Below 300 K the glow is black (eta < 1e-24).
// debug_unit writes E itself (unit gain, W/m^2) for the absolute golden; debug_colour writes
// rgb(T) x eta(T) x scale (scale = 1 / eta(T) there, so the pixel is the unit-luminance
// colour) for the colour-ramp golden (G-M4-5).
shader_type spatial;
render_mode unshaded, blend_add, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 ship_x = vec3(1.0, 0.0, 0.0); // ship axes as world (sky-frame) vectors
uniform vec3 ship_y = vec3(0.0, 1.0, 0.0);
uniform vec3 ship_z = vec3(0.0, 0.0, 1.0);
uniform vec3 cam_ship = vec3(0.0);         // panorama camera position, ship frame, metres
uniform float radius = 100.0;              // bubble radius, metres (sim params.bubble_radius_m)
uniform float pole = 0.0;                  // W/m^2, the sim's glow_pole_w_m2 (0 = off)
uniform float t_pole = 0.0;                // K, the sim's glow_pole_k
uniform float scale = 0.0;                 // pixel per W m^-2 sr^-1 ... x pi: k / pi
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
uniform float log10_eff_k;                 // log10(pi Km 2hc^2 / sigma)
uniform bool debug_unit = false;
uniform bool debug_colour = false;

void vertex() {
	POSITION = vec4(VERTEX.xy, 0.5, 1.0); // a full-screen quad (QuadMesh 2 x 2)
}

// rgb(T) x eta(T); 0 below the lookup's 300 K
vec3 lit(float t) {
	if (!(t >= exp(lut_log_tmin))) {
		return vec3(0.0);
	}
	float lt = log(min(t, exp(lut_log_tmax)));
	vec4 c = texture(bb_lut, vec2(clamp((lt - lut_log_tmin) / (lut_log_tmax - lut_log_tmin), 0.0, 1.0), 0.5));
	return c.rgb * pow(10.0, log10_eff_k + c.a - 4.0 * lt / log(10.0));
}

void fragment() {
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, 0.5, 1.0);
	vec3 w = normalize(mat3(INV_VIEW_MATRIX) * normalize(v.xyz / v.w));
	vec3 d = vec3(dot(w, ship_x), dot(w, ship_y), dot(w, ship_z));
	float b = dot(cam_ship, d);
	float t = -b + sqrt(max(b * b + radius * radius - dot(cam_ship, cam_ship), 0.0));
	float ct = clamp((cam_ship.z + t * d.z) / radius, 0.0, 1.0);
	float e = pole * ct;
	vec3 rgb = lit(t_pole * sqrt(sqrt(ct)));
	ALBEDO = debug_unit ? vec3(e) : (debug_colour ? rgb * scale : rgb * (e * scale));
}
