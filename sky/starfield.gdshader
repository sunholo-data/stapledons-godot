// Relativistic starfield. Each MultiMesh instance is one catalogue star:
//   instance origin  = galaxy-frame unit direction observer -> star (n)
//   INSTANCE_CUSTOM  = (T_eff kelvin, relative flux, 0, 0)
// Mirrors physics/relativity.gd and physics/blackbody.gd; keep them in sync.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled;

uniform vec3 beta_dir = vec3(0.0, 0.0, -1.0); // unit direction of ship velocity, galaxy frame
uniform float beta_mag = 0.0;                   // |beta|
uniform float gamma_f = 1.0;                    // Lorentz factor, computed in float64 on the CPU
uniform float one_minus_beta = 1.0;             // 1 - |beta|, float64 on the CPU (precision near c)
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
uniform float exposure = 5.0;             // linear radiance of a mag-0 star's splat peak
uniform float psf_sigma_px = 0.9;         // point-spread sigma in pixels
uniform float sky_radius = 100.0;

varying vec3 v_color;

vec4 lut(float t) {
	float u = (log(t) - lut_log_tmin) / (lut_log_tmax - lut_log_tmin);
	return texture(bb_lut, vec2(clamp(u, 0.0, 1.0), 0.5));
}

void vertex() {
	vec3 n = normalize(MODEL_MATRIX[3].xyz);
	float t_eff = INSTANCE_CUSTOM.x;
	float flux = INSTANCE_CUSTOM.y;

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

	// Blackbody at T is seen as a blackbody at D*T with solid angle / D^2.
	vec4 rest = lut(t_eff);
	vec4 seen = lut(t_eff * d);
	float band_ratio = pow(10.0, seen.a - rest.a) / (d * d);
	v_color = seen.rgb * flux * band_ratio * exposure;

	// Project the apparent direction (rotation only: stars are at infinity),
	// then expand the quad to a fixed pixel footprint around it.
	vec3 view_dir = mat3(VIEW_MATRIX) * n_app;
	if (view_dir.z >= 0.0) {
		// Behind the camera (which looks down -Z): with clip.w <= 0 the
		// projection would mirror the star back into view. Discard it.
		POSITION = vec4(0.0, 0.0, 2.0, 1.0);
		v_color = vec3(0.0);
		UV = VERTEX.xy;
	} else {
	vec4 clip = PROJECTION_MATRIX * vec4(view_dir * sky_radius, 1.0);
	vec2 px = VERTEX.xy * (psf_sigma_px * 4.0);
	clip.xy += px * 2.0 / VIEWPORT_SIZE * clip.w;
	POSITION = clip;
	UV = VERTEX.xy;
	}
}

void fragment() {
	// Gaussian point-spread function: integrated splat energy is
	// proportional to the star's flux (2 pi sigma^2 x peak).
	float r2 = dot(UV, UV) * 16.0; // UV in [-1,1] spans +-4 sigma
	float psf = exp(-0.5 * r2);
	ALBEDO = v_color * psf;
}
