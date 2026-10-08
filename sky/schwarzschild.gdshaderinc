// The Schwarzschild lens on the GPU (M3.5 of R1-M3-BLACK-HOLES; relativity spec §3).
// Mirrors physics/schwarzschild.gd (class Schwarzschild) function for function on the same
// float32 texels (data/lens, sunholo/relativity 0.10.0); keep the two in sync. The CPU sets
// every uniform from the sim's gr state through sky/gr_lens.gd (GrLens.uniforms), in float64.
// Included by sky/background.gdshader (the per-pixel sky) and sky/starfield.gdshader (stars).
//
// Conventions: r in r_s; h = the static observer's unit direction TOWARD the hole (world
// frame); psi = a ray's angle from h; alpha = the Synge shadow half-angle; F = psi - delta is
// the source's angle from h at infinity in the same plane (F < 0: the far side).
// Precision (plan review N-2): Godot uniforms are float32, so alpha arrives as a hi/lo pair
// formed in float64, and dpsi = (atan2(|h x n|, h.n) - alpha_hi) - alpha_lo keeps the edge to
// ~1e-7 rad. The three interpolation rules of the M3.2 as-built note are mirrored exactly:
//   1. every row is read at the observer's fractional column (one texture coordinate);
//   2. within a column interval the weight is linear in cot(psi / 2);
//   3. Catmull-Rom across rows, with the linear ghost point 2 p1 - p2 beyond the end rows.

uniform bool gr_on = false;
uniform sampler2D gr_fwd : filter_nearest, repeat_disable; // lens_fwd: (R regular part, G d delta/dx)
uniform sampler2D gr_inv : filter_nearest, repeat_disable; // lens_inv: (R psi - alpha, G d psi/dF)
uniform vec3 gr_h = vec3(0.0, 0.0, -1.0);
uniform float gr_alpha_hi = 0.0;
uniform float gr_alpha_lo = 0.0;
uniform float gr_row = 0.0;      // fractional row of r: (ln(r - 1.5) - y_min) / (y_max - y_min) x 255
// psi_i - alpha of every column i at this r, formed in float64 (GrLens.column_image): the column
// fraction is then ln-free and well conditioned. Formed in float32 from x_min + dx i, the grid
// itself would carry ~2e-6 of x (the ulp of 20), i.e. 1e-4 of a column: 1.5e-4 relative in delta.
uniform sampler2D gr_cols : filter_nearest, repeat_disable;
uniform float gr_x_min = -18.420680743952367;
uniform float gr_x_max = 1.0;    // ln((pi - alpha) / alpha), the row's last column
uniform bool gr_weak = false;    // r > 1e6: first-order weakDeflectionFinite, no table
uniform float gr_weak_k = 0.0;   // Schwarzschild.weak_k(r): delta = k cot(psi / 2) when gr_weak
uniform float gr_dg = 1.0;       // D_g, the static blueshift (the sim's gr.blueshift)
// Golden only (tools/gr_golden.gd GR12; 0 in play): break one interpolation rule so the mirror
// goldens can show they notice. 1 x-linear column weight, 2 repeated first row, 3 repeated last row.
uniform int gr_mutant = 0;

const int GR_COLS = 2048;
const int GR_ROWS = 256;
const float GR_PI = 3.141592653589793;

float gr_alpha() {
	return gr_alpha_hi + gr_alpha_lo;
}

// Angle between unit vectors, atan2 form (Schwarzschild.angle).
float gr_angle(vec3 a, vec3 b) {
	return atan(length(cross(a, b)), dot(a, b));
}

// Unit vector perpendicular to h in the plane of h and n (Schwarzschild._perp).
vec3 gr_perp(vec3 n, vec3 h) {
	vec3 p = n - h * dot(n, h);
	if (length(p) < 1e-7) {
		p = cross(h, abs(h.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0));
	}
	return normalize(p);
}

vec2 gr_fetch(bool inv, int i, int j) {
	return inv ? texelFetch(gr_inv, ivec2(i, j), 0).rg : texelFetch(gr_fwd, ivec2(i, j), 0).rg;
}

// Linear in the column (Schwarzschild._texel_lerp), both channels, between columns i0 and i0 + 1
// at weight f. The column is carried as (i0, f), never as the float i0 + f: near column 2047 a
// float32 holds a fraction only to 2.4e-4, which left 4e-4 relative in delta at the antipode.
vec2 gr_texel_lerp(bool inv, int j, int i0, float f) {
	return gr_fetch(inv, i0, j) * (1.0 - f) + gr_fetch(inv, i0 + 1, j) * f;
}

vec2 gr_catmull_rom(vec2 p0, vec2 p1, vec2 p2, vec2 p3, float t) {
	return 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t);
}

// Catmull-Rom across rows at the column (i0, f) (Schwarzschild._rows_cr): rule 3.
vec2 gr_rows(bool inv, int i0, float f) {
	float fy = clamp(gr_row, 0.0, float(GR_ROWS - 1));
	int j1 = min(int(floor(fy)), GR_ROWS - 2);
	float t = fy - float(j1);
	vec2 p1 = gr_texel_lerp(inv, j1, i0, f);
	vec2 p2 = gr_texel_lerp(inv, j1 + 1, i0, f);
	vec2 p0 = j1 > 0 ? gr_texel_lerp(inv, j1 - 1, i0, f) : (gr_mutant == 2 ? p1 : 2.0 * p1 - p2);
	vec2 p3 = j1 + 2 < GR_ROWS ? gr_texel_lerp(inv, j1 + 2, i0, f) : (gr_mutant == 3 ? p2 : 2.0 * p2 - p1);
	return gr_catmull_rom(p0, p1, p2, p3, t);
}

// ln tanh(t) without tanh's overflow for large t (tanh(9) is 1 in float32).
float gr_log_tanh(float t) {
	return t < 9.0 ? log(tanh(t)) : -2.0 * exp(-2.0 * t);
}

// (delta, d delta/dx) seen at the static observer for a ray at psi, dpsi = psi - alpha > 0
// (Schwarzschild.deflection and deflection_slope): the table's regular part plus the analytic
// singular part -ln tanh(dpsi / alpha). Rules 1 and 2: the fractional column c of x is shared by
// every row; within the column interval [i0, i0 + 1] the weight is linear in cot(psi / 2),
// formed as [sin((psi - psi0)/2) / sin(psi/2)] / [sin((psi1 - psi0)/2) / sin(psi1/2)]
// (the identity cot a - cot b = sin(b - a) / (sin a sin b)), which keeps float32 digits where
// adjacent columns' cotangents nearly cancel.
vec2 gr_deflection(float psi, float dpsi) {
	if (gr_weak) {
		return vec2(gr_weak_k / tan(0.5 * psi), 0.0);
	}
	float a = gr_alpha();
	float tt = dpsi / a;
	float span = gr_x_max - gr_x_min;
	float c = clamp((log(tt) - gr_x_min) / span * float(GR_COLS - 1), 0.0, float(GR_COLS - 1));
	int i0 = min(int(floor(c)), GR_COLS - 2);
	float e0 = texelFetch(gr_cols, ivec2(i0, 0), 0).r; // psi0 - alpha
	float e1 = texelFetch(gr_cols, ivec2(i0 + 1, 0), 0).r;
	// the float32 column c can sit one off near a column edge: step to the interval holding dpsi
	if (dpsi < e0 && i0 > 0) {
		i0 -= 1;
		e1 = e0;
		e0 = texelFetch(gr_cols, ivec2(i0, 0), 0).r;
	} else if (dpsi >= e1 && i0 < GR_COLS - 2) {
		i0 += 1;
		e0 = e1;
		e1 = texelFetch(gr_cols, ivec2(i0 + 1, 0), 0).r;
	}
	float ps = min(a + dpsi, GR_PI);
	float psi1 = i0 + 1 == GR_COLS - 1 ? GR_PI : a + e1;
	float num = sin(0.5 * max(dpsi - e0, 0.0)) / sin(0.5 * ps);
	float den = sin(0.5 * (e1 - e0)) / sin(0.5 * psi1);
	float w = gr_mutant == 1 ? log(max(dpsi, 1e-30) / e0) / log(e1 / e0) : num / den;
	vec2 rg = gr_rows(false, i0, clamp(w, 0.0, 1.0));
	return vec2(rg.x - gr_log_tanh(tt), rg.y);
}

// (psi, d psi/dF) of the image of a source at F (order 0: F = beta, order 1: F = -beta)
// (Schwarzschild.image): lens_inv up to r = 1e6; beyond, Newton on the first-order map
// F = psi - k cot(psi/2) from the small-angle root (F + sqrt(F^2 + 8k)) / 2 (the CPU bisects
// the same function; both converge to its one root on (alpha, pi]).
vec2 gr_image(float f) {
	if (gr_weak) {
		float k = gr_weak_k;
		// the small-angle root (F + sqrt(F^2 + 8k)) / 2, rationalised for F < 0 (no cancellation)
		float q = sqrt(f * f + 8.0 * k);
		float psi = f >= 0.0 ? 0.5 * (f + q) : 4.0 * k / (q - f);
		for (int i = 0; i < 4; i++) {
			float s = sin(0.5 * psi);
			float g = psi - k / tan(0.5 * psi) - f;
			psi = clamp(psi - g / (1.0 + k / (2.0 * s * s)), 1e-12, GR_PI);
		}
		psi = max(psi, gr_alpha()); // as the CPU's bisection, which starts at alpha_sh
		float s = sin(0.5 * psi);
		return vec2(psi, 1.0 / (1.0 + k / (2.0 * s * s)));
	}
	// column c = (F + pi) / 2pi x 2047 = 1023.5 + F k; the fraction is formed as
	// (F - F_i0) k, F_i0 the column's own F, so that a small F keeps its digits (c itself, near
	// 1024, holds a fraction only to 6e-5: 1e-7 rad of psi near the Einstein ring at r = 1e6)
	float k = float(GR_COLS - 1) / (2.0 * GR_PI);
	float half_cols = 0.5 * float(GR_COLS - 1);
	float c = clamp(half_cols + f * k, 0.0, float(GR_COLS - 1));
	int i0 = min(int(floor(c)), GR_COLS - 2);
	float f_i0 = (float(i0) - half_cols) / k;
	vec2 rg = gr_rows(true, i0, clamp((f - f_i0) * k, 0.0, 1.0));
	return vec2(gr_alpha_hi + (rg.x + gr_alpha_lo), rg.y);
}
