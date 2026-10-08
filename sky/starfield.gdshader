// Relativistic starfield. Each MultiMesh instance is one catalogue star
// (sky/starfield.gd, M1.3):
//   instance origin       = hi = f32(p - O), star position from the rebase origin O, world ly
//   instance basis col x  = lo = f32(p - O - hi), the rounding error of hi
//   INSTANCE_CUSTOM       = (T_eff kelvin, E_v at Sol (lux, illuminanceFromV), flags, |p|^2 ly^2)
// The ship's offset from O arrives as the same hi/lo pair; rel = (hi - ship_hi)
// + (lo - ship_lo) keeps a nearby star's direction to float32 precision of r.
// Mirrors physics/relativity.gd and physics/blackbody.gd; keep them in sync.
// M3.5b (gr_on, sky/schwarzschild.gdshaderinc, mirrors Schwarzschild.star_images): the star's
// direction n_src at infinity gives beta = angle(n_src, h); image_order k (0: F = beta, this
// instance; 1: F = -beta, a second MultiMeshInstance3D on the same multimesh that exists only
// while GR is on) takes psi_k from lens_inv, n_s,k = cos psi_k h +- sin psi_k e_perp, then the
// SR step below with the motion relative to the local static observer, and flux
//   mu_k Y(D_k T)/Y(T) / D_SR,k^2,  D_k = D_g D_SR,k,  mu_k = (sin psi / |sin F|) |d psi/dF|.
// A star whose tangential stretch sin psi / |sin F| exceeds 8 belongs to the ring-star path
// (sky/background.gdshader): the CPU flags up to 64 of them (flags bit RING_FLAG) and they draw
// no splat here; the overflow keeps its splat with mu capped at 8.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

#include "res://sky/schwarzschild.gdshaderinc"

uniform int image_order = 0;
const float RING_FLAG = 64.0;
const float RING_STRETCH = 8.0;

uniform vec3 beta_dir = vec3(0.0, 0.0, -1.0); // unit direction of ship velocity, galaxy frame
uniform float beta_mag = 0.0;                   // |beta|
uniform float gamma_f = 1.0;                    // Lorentz factor, computed in float64 on the CPU
uniform float one_minus_beta = 1.0;             // 1 - |beta|, float64 on the CPU (precision near c)
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
// Linear splat peak per lux (sky/exposure.gd star_scale):
// 1 / (L_white 2 pi sigma_rad^2), sigma_rad = psf_sigma_px x the CENTRE pixel's angle.
// Deliberately the same across the frame: a star's on-screen brightness never
// depends on where it sits (the pinhole's off-axis pixels span up to cos^3 less
// solid angle, 0.38 at Sirius in the port view; not applied, so brightness
// ordering reads true anywhere on screen).
uniform float exposure = 5.0;
// Magnitude-floor readability aid (off when floor_flux = 0): a star whose seen
// illuminance is at least floor_flux lux is lifted to a splat peak of floor_peak.
uniform float floor_flux = 0.0;
uniform float floor_peak = 0.0;
uniform float psf_sigma_px = 0.9;         // point-spread sigma in pixels (fixed in angle, sky/exposure.gd)
uniform float sky_radius = 100.0;
uniform vec3 ship_hi = vec3(0.0);         // ship - O, float32 pair (see header)
uniform vec3 ship_lo = vec3(0.0);
uniform float min_r2 = 1e-6;              // ly^2 floor of the 1/r^2 rescale (63 AU)
// Stars whose splat peak (linear, after beaming and exposure) is below this are
// collapsed before rasterisation; 1e-4 is ~40x below one 8-bit step at the top
// of the tonemapper, so nothing visible is lost and most of the 324k faint
// GCNS stars cost only their vertices.
uniform float cull_peak = 1e-4;

varying vec3 v_color;
varying flat float v_extent; // quad half-width in PSF sigmas

vec4 lut(float t) {
	float u = (log(t) - lut_log_tmin) / (lut_log_tmax - lut_log_tmin);
	return texture(bb_lut, vec2(clamp(u, 0.0, 1.0), 0.5));
}

void vertex() {
	vec3 rel = (MODEL_MATRIX[3].xyz - ship_hi) + (MODEL_MATRIX[0].xyz - ship_lo);
	vec3 n = normalize(rel);
	float t_eff = INSTANCE_CUSTOM.x;
	// E_v at Sol rescaled by inverse square to the ship
	float flux = INSTANCE_CUSTOM.y * INSTANCE_CUSTOM.w / max(dot(rel, rel), min_r2);

	float mu = 1.0;
	bool hide = image_order == 1 && !gr_on;
	if (gr_on) {
		float beta_s = gr_angle(n, gr_h);
		float f = image_order == 0 ? beta_s : -beta_s;
		vec2 im = gr_image(f);
		float stretch = sin(im.x) / max(abs(sin(f)), 1e-30);
		mu = stretch * abs(im.y);
		if (mod(floor(INSTANCE_CUSTOM.z / RING_FLAG), 2.0) > 0.5) {
			hide = true; // drawn by the sky pass's ring-star path
		} else if (stretch > RING_STRETCH) {
			mu = min(mu, RING_STRETCH);
		}
		vec3 e = gr_perp(n, gr_h);
		n = normalize(gr_h * cos(im.x) + (image_order == 0 ? e : -e) * sin(im.x));
	}

	float b = beta_mag;
	vec3 n_app = n;
	float d = 1.0;
	if (b > 0.0) {
		float g = gamma_f;
		float c = dot(n, beta_dir);
		// 1 + b c rewritten to avoid cancellation when b -> 1 and c -> -1
		float one_plus_bc = 1.0 + b * c;
		if (c < 0.0) {
			one_plus_bc = one_minus_beta + b * (1.0 + c);
		}
		n_app = normalize((n + ((g - 1.0) * c + g * b) * beta_dir) / (g * one_plus_bc));
		d = g * one_plus_bc;
	}

	// Blackbody at T is seen as a blackbody at D*T with solid angle / D^2:
	// splat energy = E_v x pointFluxRatio(T, D).
	vec4 rest = lut(t_eff);
	vec4 seen = lut(t_eff * d * (gr_on ? gr_dg : 1.0));
	float band_ratio = mu * pow(10.0, seen.a - rest.a) / (d * d);
	// Project the apparent direction (rotation only: stars are at infinity),
	// then expand the quad to a fixed pixel footprint around it.
	vec3 view_dir = mat3(VIEW_MATRIX) * n_app;
	v_color = seen.rgb * flux * band_ratio * exposure;
	float peak = max(v_color.r, max(v_color.g, v_color.b));
	if (floor_flux > 0.0 && flux * band_ratio >= floor_flux && peak < floor_peak && peak > 0.0) {
		v_color *= floor_peak / peak;
		peak = floor_peak;
	}
	// The splat reaches out to where the PSF falls to cull_peak (at most 4
	// sigma): faint stars get small quads, so overdraw scales with brightness.
	// Truncation cost: a 2-D Gaussian keeps 1 - exp(-k^2/2) of its energy inside
	// radius k sigma, so a star of peak p loses at most cull_peak / p of its
	// energy (less, as the square quad also keeps its corners): <= 1% once
	// p >= 100 cull_peak, and the 4-sigma cap loses 3.4e-4 for bright stars.
	v_extent = clamp(sqrt(2.0 * log(max(peak, cull_peak) / cull_peak)), 1.0, 4.0);
	if (view_dir.z >= 0.0 || peak < cull_peak || hide) {
		// Behind the camera (which looks down -Z): with clip.w <= 0 the
		// projection would mirror the star back into view. Discard it, and
		// any star too faint to reach the display (cull_peak).
		POSITION = vec4(0.0, 0.0, 2.0, 1.0);
		v_color = vec3(0.0);
		UV = VERTEX.xy;
	} else {
	vec4 clip = PROJECTION_MATRIX * vec4(view_dir * sky_radius, 1.0);
	vec2 px = VERTEX.xy * (psf_sigma_px * v_extent);
	clip.xy += px * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
	UV = VERTEX.xy;
	}
}

void fragment() {
	// Gaussian point-spread function: integrated splat energy is
	// proportional to the star's flux (2 pi sigma^2 x peak).
	float r2 = dot(UV, UV) * v_extent * v_extent; // UV in [-1,1] spans +-v_extent sigma
	float psf = exp(-0.5 * r2);
	ALBEDO = v_color * psf;
}
