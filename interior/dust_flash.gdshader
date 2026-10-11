// R1-ISM-DUST I5: dust-grain flashes on the forward wall, drawn additively in the sky
// SubViewport before its one tonemap, beside glow_overlay.gdshader (design
// ism-structure-and-dust.md section 6; higgs-bubble.md section 6b). CPU reference:
// interior/dust_flash.gd; make golden G-ISM-1..5 checks this shader against it.
//
// Each flash gets a small conservative projected quad. Within it, as the glow does,
// the view ray is turned into the ship frame (+Z = travel), traced
// from the panorama camera's ship-frame position to the wall (sphere of radius R), giving the
// wall point P. Each live flash is a curved, equal-area G-AG footprint about R n_i:
// area pi*r_spot^2, oriented by incidence. Legacy circular mode remains for comparison.
// Covered pixels add E_i / pi x rgb(T_i) x eta(T_i) x scale (scale = k / pi as the glow's: Lambertian
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
uniform bool surface_marks = true; // labelled equal-area G-AG surface footprint; false = original circles
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
		// The footprint is enclosed by the extent ball at R*n (3.2*r_spot for surface marks).
		// Project the ball's enclosing camera-space box: every accepted wall ray
		// is inside this quad, including oblique views and off-centre observers.
		vec3 delta = radius * flash[sprite_id].xyz - cam_ship;
		float extent = r_spot * (surface_marks ? 3.2 : 1.0);
		vec3 centre = mat3(VIEW_MATRIX) * (ship_x * delta.x + ship_y * delta.y + ship_z * delta.z);
		vec2 lo = vec2(-1.0);
		vec2 hi = vec2(1.0);
		if (centre.z - extent >= 0.0) {
			lo = vec2(2.0);
			hi = lo; // wholly behind the camera: degenerate, no fragment work
		} else if (centre.z + extent < 0.0) {
			lo = vec2(1e20);
			hi = vec2(-1e20);
			for (int k = 0; k < 8; k++) {
				vec3 corner = centre + extent * vec3((k & 1) == 0 ? -1.0 : 1.0, (k & 2) == 0 ? -1.0 : 1.0, (k & 4) == 0 ? -1.0 : 1.0);
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

// Unit-area stretch and shear of a Lambert equal-area wall patch. The emitter
// stays on the sphere: these are surface marks, not particle trails through space.
float footprint_distance(vec3 p, vec3 n) {
	if (!surface_marks) { return length(p - radius * n) / r_spot; }
	float cosine = dot(p, n) / radius;
	if (cosine < -0.9) { return 1e10; }
	vec3 axis = n * n.z - vec3(0.0, 0.0, 1.0);
	axis = dot(axis, axis) > 1e-8 ? normalize(axis) : vec3(1.0, 0.0, 0.0);
	vec3 delta = p - radius * n;
	vec2 xy = vec2(dot(delta, axis), dot(delta, cross(n, axis))) * sqrt(2.0 / max(1.0 + cosine, 1e-7)) / r_spot;
	float aspect = 1.2 + 1.6 * sqrt(max(0.0, 1.0 - n.z * n.z));
	float v = xy.y * aspect;
	return length(vec2((xy.x - 0.18 * v * v) / aspect, v));
}

float coverage(float distance) {
	if (!surface_marks) { return distance <= 1.0 ? 1.0 : 0.0; }
	// Pixel coverage only: smooth the silhouette without adding a halo or energy.
	return clamp(0.5 - (distance - 1.0) / max(fwidth(distance), 1e-5), 0.0, 1.0);
}

void fragment() {
	vec4 v = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, 0.5, 1.0);
	vec3 w = normalize(mat3(INV_VIEW_MATRIX) * normalize(v.xyz / v.w));
	vec3 d = vec3(dot(w, ship_x), dot(w, ship_y), dot(w, ship_z));
	float b = dot(cam_ship, d);
	float t = -b + sqrt(max(b * b + radius * radius - dot(cam_ship, cam_ship), 0.0));
	vec3 p = cam_ship + t * d;
	float own = coverage(footprint_distance(p, flash[sprite_id].xyz));
	if (own <= 0.0) {
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
		float e = flash[sprite_id].w * own;
		e_sum = e;
		sum = lit(flash_t[sprite_id]) * (debug_colour ? own * scale : e * scale);
	} else {
		for (int i = 0; i < 64; i++) {
			if (i >= count) { break; }
			bool neighbour = i < 32 ? (lo & (1 << i)) != 0 : (hi & (1 << (i - 32))) != 0;
			if (!neighbour) { continue; }
			float weight = coverage(footprint_distance(p, flash[i].xyz));
			if (weight > 0.0) {
				if (i < sprite_id) { discard; }
				e_sum += flash[i].w * weight;
				sum += lit(flash_t[i]) * weight * (debug_colour ? scale : flash[i].w * scale);
			}
		}
	}
	ALBEDO = debug_unit ? vec3(e_sum) : sum;
}
