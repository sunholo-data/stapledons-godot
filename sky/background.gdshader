// Relativistic sky background (M1.4c): the destarred NOIRLab panorama (D-10) with a
// per-texel colour temperature from sim/tools/sky_model.ail.
// Mirrors SkyModel (sky/sky_model.gd) and Relativity (physics/relativity.gd); keep in sync.
// Per pixel, with n' = EYEDIR the direction light APPEARS to come from in the ship frame:
//   1. n = deaberrate(n', beta)              galaxy-frame direction, sampled from the panorama
//   2. D = 1 / (gamma (1 - beta n'.bh))      dopplerApparent
//   3. radiance = Y x surfaceBrightnessRatio(T_c, D) x rgb(D T_c) x tint  (Y un-stretched, M1.5a)
//      where tint = photo / (Y rgb(T_c)) carries the photo's off-locus colour (1 on the locus),
//      so D = 1 reproduces the photo exactly.
// World frame as sky/starfield.gd: galactic (x, y, z) -> world (y, z, -x).
shader_type sky;

uniform sampler2D photo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D model : filter_linear_mipmap, repeat_enable; // r = T_c code / 255
uniform float t_lo = 1500.0;
uniform float t_hi = 30000.0;
uniform float pano_px_per_screen_px = 1.0; // at rest; the mip level grows with D
uniform vec3 beta_dir = vec3(0.0, 0.0, -1.0);
uniform float beta_mag = 0.0;
uniform float gamma_f = 1.0;
uniform float one_minus_beta = 1.0; // 1 - beta formed in float64 on the CPU
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
uniform float exposure = 1.0;
// M1.5a un-stretch of the tone-stretched photo (sky/background.gd): luminance
// Y -> y_dark (Y / y_dark)^stretch, chromaticity kept; stretch = 1 is the identity.
uniform float y_dark = 1.0;
uniform float stretch = 1.0;

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
		vec3 bh = -beta_dir;                 // inverse aberration = aberrate with -beta
		float c = dot(np, bh);
		// 1 + b c, rewritten to avoid cancellation when b -> 1 and c -> -1
		float one_plus_bc = c < 0.0 ? one_minus_beta + b * (1.0 + c) : 1.0 + b * c;
		n = normalize((np + ((g - 1.0) * c + g * b) * bh) / (g * one_plus_bc));
		d = 1.0 / (g * one_plus_bc);
	}
	vec3 gal = vec3(-n.z, n.x, n.y);
	vec2 uv = vec2(0.5 - atan(gal.y, gal.x) / TAU, 0.5 - asin(clamp(gal.z, -1.0, 1.0)) / PI);
	// one ship pixel spans D times more galaxy-frame angle (explicit lod: no seam at the wrap)
	float lod = max(0.0, log2(pano_px_per_screen_px * d));
	vec3 lin = textureLod(photo, uv, lod).rgb;
	float y_photo = dot(lin, vec3(0.2126729, 0.7151522, 0.0721750));
	if (stretch != 1.0 && y_photo > 0.0) {
		lin *= pow(y_photo / y_dark, stretch - 1.0);
	}
	float t_c = exp(log(t_lo) + (log(t_hi) - log(t_lo)) * textureLod(model, uv, lod).r);
	vec4 rest = lut(t_c);
	vec4 seen = lut(t_c * d);
	// lin x rgb(D T)/rgb(T) x Y(DT)/Y(T)  ==  Y x ratio x rgb(D T) x tint
	COLOR = lin * (seen.rgb / max(rest.rgb, vec3(1e-4))) * pow(10.0, seen.a - rest.a) * exposure;
}
