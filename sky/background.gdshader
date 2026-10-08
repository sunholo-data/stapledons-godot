// Relativistic sky background (M1.4c): the destarred NOIRLab panorama (D-10) with a
// per-texel colour temperature from sim/tools/sky_model.ail.
// Mirrors SkyModel (sky/sky_model.gd) and Relativity (physics/relativity.gd); keep in sync.
// Per pixel, with n' = EYEDIR the direction light APPEARS to come from in the ship frame:
//   1. n = deaberrate(n', beta)              galaxy-frame direction, sampled from the panorama
//   2. D = 1 / (gamma (1 - beta n'.bh))      dopplerApparent
//   3. radiance = Y x surfaceBrightnessRatio(T_c, D) x rgb(D T_c) x tint  (Y un-stretched, M1.5a)
//   4. + the forward CMB (M1.8): photopicRadiance(T0 D) in cd/m^2 through the angular PSF,
//      a radial profile by theta' built on the CPU (sky/cmb.gd), times cmb_k (pixel per cd/m^2)
//      where tint = photo / (Y rgb(T_c)) carries the photo's off-locus colour (1 on the locus),
//      so D = 1 reproduces the photo exactly.
// World frame: SkyFrame (sky/sky_frame.gd, D-28) through sky_frame.gdshaderinc, the one shader copy.
// M3.5a (gr_on, sky/schwarzschild.gdshaderinc): beta_dir/beta_mag/gamma_f/one_minus_beta then hold
// the ship's motion relative to the LOCAL STATIC observer (the sim's gr.dir_local, beta_local,
// gamma_local, one_minus_beta_local), so step 1 lands in the static frame. Then:
//   1a. psi = angle(n, h) <= alpha_sh: captured, black (exact Synge, no table)
//   1b. n_inf = cos(psi - delta) h + sin(psi - delta) e_perp (the table lens; galaxy frame,
//       the hole is at rest); the mip level grows with |dF/dpsi| (from G = d delta/dx) and the
//       tangential stretch, so the photon ring does not sparkle
//   2'. D = D_g D_SR (D_g = gr.blueshift); surface brightness is conserved, so no mu here
//   + ring stars (M3.5b): up to 64 Gaussians of the PSF's angular size in the SOURCE plane,
//     evaluated at n_inf, so the lens itself draws their arcs and Einstein rings
// grid_on swaps the photo for the debug grid (lat/long every 10 deg, analytic anti-aliasing,
// constant surface brightness): the golden background (design M3.5 step 4).
shader_type sky;

#include "res://sky/sky_frame.gdshaderinc"
#include "res://sky/schwarzschild.gdshaderinc"

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
// M1.8 forward CMB: rgb = unit-luminance colour, a = log10 cd/m^2 (<= -59: none),
// sample i at theta' = i / (cmb_size - 1) x cmb_theta_max; nothing at or past cmb_theta_max.
uniform sampler2D cmb_profile : filter_linear, repeat_disable;
uniform float cmb_theta_max = 0.0;
uniform float cmb_size = 256.0;
uniform float cmb_k = 0.0;
// M3.5a debug grid and the pixel's angle at the centre of the view (rad), for its anti-aliasing
uniform bool grid_on = false;
uniform float screen_px_rad = 0.002;
const float GRID_STEP = 0.17453292519943295; // 10 deg
const float GRID_HALF_WIDTH = 0.0026179938779914945; // 0.15 deg
const float GRID_T = 6500.0; // the grid radiates as a 6500 K surface (its colour follows D)
// M3.5b ring stars: xyz = unit world direction of the source at infinity, w = T_eff (K);
// peak = linear splat peak at D = 1 (flux at the ship x the starfield's exposure).
uniform int gr_ring_count = 0;
uniform vec4 gr_ring[64];
uniform float gr_ring_peak[64];
uniform float gr_ring_sigma = 0.001; // rad: the PSF sigma (Exposure.psf_sigma_rad), source plane
// Golden probe (tools/gr_golden.gd GR10/GR11; 0 in play): the float32 bits of one quantity per
// pixel in three 11-bit integer channels, exact in the half-float target: 1 delta, 2 psi - alpha,
// 3 psi of the lens_inv image of F, 4 that F = (2 SCREEN_UV.x - 1) pi (orders 0 and 1).
uniform int gr_probe = 0;
// The HDR buffer is half float (max 65504): clamp so a blinding source stays finite.
const float MAX_RADIANCE = 60000.0;

vec4 lut(float t) {
	float u = (log(t) - lut_log_tmin) / (lut_log_tmax - lut_log_tmin);
	return texture(bb_lut, vec2(clamp(u, 0.0, 1.0), 0.5));
}

// Debug grid coverage at a galaxy-frame direction g (unit), pixel footprint fp (rad):
// a 0.3 deg line every 10 deg of latitude and longitude, box-filtered by the footprint, and
// its mean coverage once the footprint spans a whole grid cell.
float grid_cover(vec3 g, float fp) {
	float b = asin(clamp(g.z, -1.0, 1.0));
	float l = atan(g.y, g.x);
	float db = abs(b - round(b / GRID_STEP) * GRID_STEP);
	float dl = abs(l - round(l / GRID_STEP) * GRID_STEP) * cos(b);
	float w = max(fp, 1e-6);
	float c = max(clamp((GRID_HALF_WIDTH + 0.5 * w - db) / w, 0.0, 1.0), clamp((GRID_HALF_WIDTH + 0.5 * w - dl) / w, 0.0, 1.0));
	return mix(c, 4.0 * GRID_HALF_WIDTH / GRID_STEP, clamp(fp / GRID_STEP, 0.0, 1.0));
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
	float lens = 1.0; // source-plane angle per static-frame angle (M3.5a)
	float dcol = d;   // the Doppler factor of the colour: D_SR, times D_g under GR
	bool captured = false;
	float probe = 0.0;
	if (gr_on) {
		float psi = gr_angle(n, gr_h);
		float dpsi = (psi - gr_alpha_hi) - gr_alpha_lo;
		// captured: inside the shadow (Synge), nothing reaches us (the sky() processor has no return)
		captured = !(dpsi > 0.0);
		vec2 dl = gr_deflection(psi, captured ? gr_alpha() : dpsi);
		probe = gr_probe == 1 ? dl.x : dpsi;
		float f = psi - dl.x;
		vec3 e = gr_perp(n, gr_h);
		n = normalize(gr_h * cos(f) + e * sin(f));
		float radial = gr_weak ? 1.0 : abs(1.0 - dl.y / dpsi); // |dF/dpsi| = |1 - (d delta/dx)/dpsi|
		lens = max(radial, abs(sin(f)) / max(sin(psi), 1e-6));
		dcol = d * gr_dg;
	}
	vec3 gal = sky_world_to_galactic(n);
	vec4 seen;
	vec4 rest;
	vec3 lin;
	if (grid_on) {
		float cov = grid_cover(gal, screen_px_rad * d * lens);
		lin = vec3(0.2 + 0.8 * cov);
		rest = lut(GRID_T);
		seen = lut(GRID_T * dcol);
	} else {
		vec2 uv = vec2(0.5 - atan(gal.y, gal.x) / TAU, 0.5 - asin(clamp(gal.z, -1.0, 1.0)) / PI);
		// one ship pixel spans D (x the lens stretch) times more galaxy-frame angle (explicit lod: no seam at the wrap)
		float lod = max(0.0, log2(pano_px_per_screen_px * d * lens));
		lin = textureLod(photo, uv, lod).rgb;
		float y_photo = dot(lin, vec3(0.2126729, 0.7151522, 0.0721750));
		if (stretch != 1.0 && y_photo > 0.0) {
			lin *= pow(y_photo / y_dark, stretch - 1.0);
		}
		float t_c = exp(log(t_lo) + (log(t_hi) - log(t_lo)) * textureLod(model, uv, lod).r);
		rest = lut(t_c);
		seen = lut(t_c * dcol);
	}
	// lin x rgb(D T)/rgb(T) x Y(DT)/Y(T)  ==  Y x ratio x rgb(D T) x tint
	COLOR = lin * (seen.rgb / max(rest.rgb, vec3(1e-4))) * pow(10.0, seen.a - rest.a) * exposure;
	if (gr_on) {
		// M3.5b ring stars: Gaussians in the source plane at n_inf (surface brightness is
		// conserved, so the lens draws their arcs; the colour and Y ratio follow D = D_g D_SR)
		float cut = cos(5.0 * gr_ring_sigma);
		for (int i = 0; i < gr_ring_count; i++) {
			float cs = dot(n, gr_ring[i].xyz);
			if (cs > cut) {
				float th = gr_angle(n, gr_ring[i].xyz);
				vec4 r0 = lut(gr_ring[i].w);
				vec4 r1 = lut(gr_ring[i].w * dcol);
				COLOR += r1.rgb * gr_ring_peak[i] * pow(10.0, r1.a - r0.a) * exp(-0.5 * th * th / (gr_ring_sigma * gr_ring_sigma));
			}
		}
	}
	if (cmb_theta_max > 0.0 && !gr_on) {
		// theta' from atan2(|n' x v|, n'.v): exact near the pole, where acos loses digits
		float th = atan(length(cross(np, beta_dir)), dot(np, beta_dir));
		if (th < cmb_theta_max) {
			float x = th / cmb_theta_max * (cmb_size - 1.0);
			vec4 p = textureLod(cmb_profile, vec2((x + 0.5) / cmb_size, 0.5), 0.0);
			if (p.a > -59.0 && !any(isnan(p.rgb))) { // defence in depth (fix/cmb-ring)
				COLOR += p.rgb * pow(10.0, p.a) * cmb_k;
			}
		}
	}
	COLOR = captured ? vec3(0.0) : min(COLOR, vec3(MAX_RADIANCE));
	if (gr_probe > 0) {
		float fp = (2.0 * SCREEN_UV.x - 1.0) * GR_PI;
		float v = gr_probe <= 2 ? probe : (gr_probe == 3 ? gr_image(fp).x : fp);
		uint u = floatBitsToUint(v);
		COLOR = captured && gr_probe <= 2 ? vec3(0.0) : vec3(float(u & 2047u), float((u >> 11u) & 2047u), float(u >> 22u));
	}
}
