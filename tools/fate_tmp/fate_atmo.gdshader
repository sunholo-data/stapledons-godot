// SPIKE (scratch): the Earth's atmosphere over the game's sky, drawn additively in the sky
// SubViewport before its one AgX tonemap (as interior/glow_overlay.gdshader does). APPROXIMATE,
// hand-shaped luminance models in cd/m^2 (not a radiative-transfer model), labelled in notes.md:
//   mode 1 day      clear sky, brighter and whiter to the horizon and round the Sun, plus the
//                   Sun's disc at its true angular radius, limb-darkened L(mu) = L0 (1 - u (1 - mu)),
//                   u = 0.6 (Planets.SUN_LIMB_U), mean disc luminance sun_l
//   mode 2 dusk     twilight: warm low in the Sun's azimuth, blue overhead, anti-twilight opposite
//   mode 3 airglow  natural night sky: airglow, van Rhijn brightening to the horizon
//   mode 4 pointlit Rayleigh sky lit by a distant point Sun (like a moonlit sky), (1 + cos^2) phase
// The pixel is L x k (k = Exposure.k(), linear pixel per cd/m^2), colour of unit luminance.
shader_type spatial;
render_mode unshaded, blend_add, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform int mode = 0;
uniform vec3 zenith = vec3(0.0, 1.0, 0.0); // world
uniform vec3 sun = vec3(0.0, 0.0, -1.0);   // world, toward the Sun
uniform float k = 1.0;
uniform float l0 = 1.0;        // cd/m^2: the model's reference luminance (zenith, or the point-lit scale)
uniform float sun_r = 0.0;     // rad, the Sun's angular radius (mode 1)
uniform float sun_l = 0.0;     // cd/m^2, mean luminance of the disc (mode 1)
uniform float limb_u = 0.6;
uniform float max_px = 60000.0;

void vertex() {
	POSITION = vec4(VERTEX.xy, 0.5, 1.0);
}

vec3 unit_y(vec3 c) {
	return c / dot(c, vec3(0.2126729, 0.7151522, 0.0721750));
}

float ang(vec3 a, vec3 b) {
	return atan(length(cross(a, b)), dot(a, b));
}

void fragment() {
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, 0.5, 1.0);
	vec3 w = normalize(mat3(INV_VIEW_MATRIX) * normalize(v.xyz / v.w));
	float sa = dot(w, zenith);              // sin(altitude)
	float alt = asin(clamp(sa, -1.0, 1.0));
	float altc = max(alt, 0.0);
	float g = ang(w, sun);                  // angle from the Sun
	// azimuth difference from the Sun (horizontal plane)
	vec3 wh = normalize(w - zenith * sa + 1e-6 * zenith);
	vec3 sh = normalize(sun - zenith * dot(sun, zenith) + 1e-6 * zenith);
	float daz = acos(clamp(dot(wh, sh), -1.0, 1.0));
	vec3 col = vec3(0.0);
	if (mode == 1) {
		float horizon = 1.0 + 1.8 * exp(-altc / 0.10);
		float aureole = 1.0 + 6.0 * exp(-g / 0.06) + 2.0 * exp(-g / 0.35);
		float lum = l0 * horizon * aureole;
		float whiten = clamp((horizon - 1.0) / 1.8 * 0.8 + (aureole - 1.0) / 9.0, 0.0, 1.0);
		vec3 c = mix(unit_y(vec3(0.42, 0.66, 1.0)), unit_y(vec3(0.97, 0.98, 1.0)), whiten);
		col = c * lum;
		if (g < sun_r) {
			float q = g / sun_r;
			float mu = sqrt(max(1.0 - q * q, 0.0));
			float ld = sun_l / (1.0 - limb_u / 3.0) * (1.0 - limb_u * (1.0 - mu));
			col += unit_y(vec3(1.0, 0.96, 0.92)) * ld;
		}
	} else if (mode == 2) {
		float low = exp(-altc / 0.14);
		float toward = exp(-daz / 0.7);
		float lum = l0 * (0.55 + 0.45 * (1.0 - altc / 1.5708)) + l0 * 4.0 * low * toward + l0 * 0.6 * low * (1.0 - toward);
		vec3 warm = unit_y(vec3(1.0, 0.55, 0.30));
		vec3 blue = unit_y(vec3(0.22, 0.40, 1.0));
		vec3 belt = unit_y(vec3(0.70, 0.55, 0.85));
		vec3 c = mix(blue, belt, low * (1.0 - toward) * 0.8);
		c = mix(c, warm, clamp(low * toward * 1.3, 0.0, 1.0));
		col = c * lum;
	} else if (mode == 3) {
		float z = 1.5708 - altc; // van Rhijn: 1 / sqrt(1 - (R/(R+h))^2 sin^2 z), h = 90 km
		float s = 0.98604 * sin(z);
		col = unit_y(vec3(0.85, 1.0, 0.85)) * l0 / sqrt(1.0 - s * s);
	} else if (mode == 4) {
		float airmass = 1.0 / (max(sa, 0.0) + 0.15 * pow(degrees(altc) + 3.885, -1.253)); // Kasten-Young; the sea horizon (alt -0.26) takes alt 0
		float phase = 0.75 * (1.0 + cos(g) * cos(g));
		// single scattering in an optically thin-to-thick column: (1 - exp(-tau X)) / (1 - exp(-tau)), tau_z = 0.1 (Rayleigh, V)
		col = unit_y(vec3(0.50, 0.68, 1.0)) * l0 * phase * (1.0 - exp(-0.1 * min(airmass, 40.0))) / (1.0 - exp(-0.1));
	}
	ALBEDO = min(col * k, vec3(max_px));
}
