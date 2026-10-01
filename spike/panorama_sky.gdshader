// M1.4a PREVIEW (D-10): the destarred NOIRLab panorama as a relativistic sky.
// Not M1.4c. Physics per pixel, as in the iso-bridge spike's galaxy_sky:
//   1. the pixel's view direction n' is where light APPEARS to come from in the ship frame;
//   2. inverse aberration gives the galaxy-frame direction n, which is sampled from the panorama;
//   3. D = 1 / (gamma (1 - beta n'.bh)); thermal light at T is seen as at D*T, and the
//      visual radiance of an extended source scales as Y(D T) / Y(T).
// PREVIEW SIMPLIFICATIONS (M1.4b replaces them): one colour temperature for every texel
// (band_temp_k), the photo's tone-mapped 8-bit pixels treated as linear-ish sRGB, and a
// hand-set exposure (M1.5 calibrates it).
// World frame matches sky/starfield.gd: galactic (x, y, z) -> world (y, z, -x).
shader_type sky;

uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform float pano_px_per_screen_px = 1.0; // at rest; mip level grows with D
uniform vec3 beta_dir = vec3(0.0, 0.0, -1.0);
uniform float beta_mag = 0.0;
uniform float gamma_f = 1.0;
uniform float one_minus_beta = 1.0;
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
uniform float exposure = 1.0;
uniform float band_temp_k = 4600.0; // integrated old-disc starlight, roughly

vec4 lut(float t) {
	float u = (log(t) - lut_log_tmin) / (lut_log_tmax - lut_log_tmin);
	return texture(bb_lut, vec2(clamp(u, 0.0, 1.0), 0.5));
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
	// world -> galactic, then equirect (l = 0 at the centre, l increasing to the left)
	vec3 gal = vec3(-n.z, n.x, n.y);
	float l = atan(gal.y, gal.x);
	float bb = asin(clamp(gal.z, -1.0, 1.0));
	vec2 uv = vec2(0.5 - l / (2.0 * PI), 0.5 - bb / PI);
	// one ship pixel spans D times more galaxy-frame angle: pick the mip to match (no seam, no sparkle)
	float lod = max(0.0, log2(pano_px_per_screen_px * d));
	vec3 tex = textureLod(panorama, uv, lod).rgb;
	vec4 rest = lut(band_temp_k);
	vec4 seen = lut(band_temp_k * d);
	float ratio = pow(10.0, seen.a - rest.a);
	COLOR = tex * (seen.rgb / max(rest.rgb, vec3(1e-4))) * ratio * exposure;
}
