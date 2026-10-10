// R1-ISM-DUST I5: dust-grain flashes on the forward wall, drawn additively in the sky
// SubViewport before its one tonemap, beside glow_overlay.gdshader (design
// ism-structure-and-dust.md section 6; higgs-bubble.md section 6b). CPU reference:
// interior/dust_flash.gd; make golden G-ISM-1..4 checks this shader against it.
//
// Each flash gets a small conservative projected quad. Within it, as the glow does,
// the view ray is turned into the ship frame (+Z = travel), traced
// from the panorama camera's ship-frame position to the wall (sphere of radius R), giving the
// wall point P. Each live flash i is a disc of radius r_spot on the wall about R n_i (the wall
// afterglow G-AG, a labelled game approximation); a pixel whose wall point lies within r_spot of
// it adds E_i / pi x rgb(T_i) x eta(T_i) x scale (scale = k / pi as the glow's: Lambertian
// radiance through the M1.5a exposure k), rgb and eta from Blackbody's lookup. E_i (W/m^2) and
// T_i (K) are the CPU's (DustFlash.live) for this frame. At most 64 flashes. debug_unit writes
// the summed E (W/m^2) for the absolute golden; debug_colour writes rgb x eta x scale.
shader_type spatial;
render_mode unshaded, blend_add, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 ship_x = vec3(1.0, 0.0, 0.0);
uniform vec3 ship_y = vec3(0.0, 1.0, 0.0);
uniform vec3 ship_z = vec3(0.0, 0.0, 1.0);
uniform vec3 cam_ship = vec3(0.0);
uniform float radius = 100.0;
uniform float r_spot = 0.5;
uniform int count = 0;
uniform vec4 flash[64];      // xyz: the wall normal n_i (ship frame, unit); w: E_i (W/m^2)
uniform float flash_t[64];   // T_i (K)
uniform int neighbour_lo[64]; // possible physical overlaps, ids 0..31
uniform int neighbour_hi[64]; // ids 32..63; CPU's enclosing-ball test
uniform float scale = 0.0;   // k / pi
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
uniform float log10_eff_k;
uniform bool debug_unit = false;
uniform bool debug_colour = false;
varying flat int sprite_id;

void vertex() {
	sprite_id = int(VERTEX.z + 0.5);
	if (sprite_id >= count) {
		POSITION = vec4(2.0, 2.0, 0.5, 1.0);
	} else {
		// The physical spot is a subset of the radius-r_spot ball at R*n.
		// Project the ball's enclosing camera-space box: every accepted wall ray
		// is inside this quad, including oblique views and off-centre observers.
		vec3 delta = radius * flash[sprite_id].xyz - cam_ship;
		vec3 centre = mat3(VIEW_MATRIX) * (ship_x * delta.x + ship_y * delta.y + ship_z * delta.z);
		vec2 lo = vec2(-1.0);
		vec2 hi = vec2(1.0);
		if (centre.z - r_spot >= 0.0) {
			lo = vec2(2.0);
			hi = lo; // wholly behind the camera: degenerate, no fragment work
		} else if (centre.z + r_spot < 0.0) {
			lo = vec2(1e20);
			hi = vec2(-1e20);
			for (int k = 0; k < 8; k++) {
				vec3 corner = centre + r_spot * vec3((k & 1) == 0 ? -1.0 : 1.0, (k & 2) == 0 ? -1.0 : 1.0, (k & 4) == 0 ? -1.0 : 1.0);
				vec4 clip = PROJECTION_MATRIX * vec4(corner, 1.0);
				vec2 ndc = clip.xy / clip.w;
				lo = min(lo, ndc);
				hi = max(hi, ndc);
			}
			lo = clamp(lo, vec2(-1.0), vec2(1.0));
			hi = clamp(hi, vec2(-1.0), vec2(1.0));
		}
		POSITION = vec4(mix(lo, hi, VERTEX.xy * 0.5 + 0.5), 0.5, 1.0);
	}
}

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
	vec3 p = cam_ship + t * d;
	vec3 q = p - radius * flash[sprite_id].xyz;
	if (dot(q, q) > r_spot * r_spot) {
		discard;
	}
	// Only the first physical spot covering this pixel writes. Sum overlapping
	// lights in float32 before the one half-float target write; independent
	// per-sprite blending would round away faint flashes beneath a bright one.
	// This loop runs inside small projected spots, never across the full screen.
	vec3 sum = vec3(0.0);
	float e_sum = 0.0;
	int lo = neighbour_lo[sprite_id];
	int hi = neighbour_hi[sprite_id];
	bool isolated = sprite_id < 32 ? (lo == (1 << sprite_id) && hi == 0) : (hi == (1 << (sprite_id - 32)) && lo == 0);
	if (isolated) {
		float e = flash[sprite_id].w;
		e_sum = e;
		sum = lit(flash_t[sprite_id]) * (debug_colour ? scale : e * scale);
	} else {
		for (int i = 0; i < 64; i++) {
			if (i >= count) { break; }
			bool neighbour = i < 32 ? (lo & (1 << i)) != 0 : (hi & (1 << (i - 32))) != 0;
			if (!neighbour) { continue; }
			vec3 other = p - radius * flash[i].xyz;
			if (dot(other, other) <= r_spot * r_spot) {
				if (i < sprite_id) { discard; }
				e_sum += flash[i].w;
				sum += lit(flash_t[i]) * (debug_colour ? scale : flash[i].w * scale);
			}
		}
	}
	ALBEDO = debug_unit ? vec3(e_sum) : sum;
}
