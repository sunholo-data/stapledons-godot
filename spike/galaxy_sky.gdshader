// SPIKE v3: the furthest layer — a full-sky Milky Way, relativistically correct per pixel.
// The band itself is SYNTHETIC (placeholder until M1.4's real all-sky model); the physics is not:
//   1. the pixel's view direction n' is where light APPEARS to come from in the ship frame;
//   2. inverse aberration gives the rest-frame direction n it really came from;
//   3. D = 1 / (gamma (1 - beta n'.bh)); a thermal source at T is seen as one at D*T, and
//      extended-source visual radiance scales as Y(D T) / Y(T) (sunholo/relativity blackbody).
// Starfield world frame: travel is -Z here; galactic centre = -Z, north galactic pole = +Y.
shader_type sky;

uniform vec3 beta_dir = vec3(0.0, 0.0, -1.0);
uniform float beta_mag = 0.0;
uniform float gamma_f = 1.0;
uniform float one_minus_beta = 1.0;
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
uniform float exposure = 0.05;
uniform float band_temp_k = 4600.0; // integrated old-disc starlight, roughly

vec4 lut(float t) {
	float u = (log(t) - lut_log_tmin) / (lut_log_tmax - lut_log_tmin);
	return texture(bb_lut, vec2(clamp(u, 0.0, 1.0), 0.5));
}

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float s = 0.0, a = 0.5;
	for (int k = 0; k < 5; k++) { s += a * vnoise(p); p *= 2.03; a *= 0.5; }
	return s;
}

// Rest-frame surface brightness of the synthetic Milky Way in direction n (unit).
float galaxy(vec3 n) {
	float lat = asin(clamp(n.y, -1.0, 1.0));
	float lon = atan(n.x, -n.z); // 0 at the galactic centre
	float disc = exp(-abs(lat) / 0.09);
	float bulge = exp(-(lon * lon + lat * lat * 4.0) / 0.35);
	float clumps = 0.55 + 0.45 * fbm(vec2(lon * 6.0, lat * 18.0));
	float dust = 1.0 - 0.75 * exp(-lat * lat / 0.0012) * fbm(vec2(lon * 9.0 + 3.0, lat * 40.0));
	return (disc * clumps + 1.6 * bulge) * dust;
}

void sky() {
	vec3 np = normalize(EYEDIR);
	float b = beta_mag;
	vec3 n = np;
	float d = 1.0;
	if (b > 0.0) {
		float g = gamma_f;
		vec3 bh = -beta_dir;                 // inverse aberration: aberrate with -beta
		float c = dot(np, bh);
		float one_plus_bc = c < 0.0 ? one_minus_beta + b * (1.0 + c) : 1.0 + b * c;
		n = normalize((np + ((g - 1.0) * c + g * b) * bh) / (g * one_plus_bc));
		d = 1.0 / (g * one_plus_bc);         // = 1/(gamma (1 - beta n'.beta_dir))
	}
	vec4 rest = lut(band_temp_k);
	vec4 seen = lut(band_temp_k * d);
	float ratio = pow(10.0, seen.a - rest.a);
	COLOR = seen.rgb * galaxy(n) * ratio * exposure;
}
