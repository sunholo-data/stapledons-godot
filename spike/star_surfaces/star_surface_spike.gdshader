// A resolved body (M5.2a): an exact ray-traced sphere on a camera-facing quad,
// lit by its star as a point source, drawn into the sky pre-exposed (one
// tonemap). Mirrors physics/planets.gd (and through it sunholo/celestial
// reflect.minnaertRadiance); keep them in sync.
//   centre_v   the body centre, placed PLACE units out (planets/system_view.gd), world
//   radius     PLACE R / d, so the angular radius is asin(R / d) exactly
//   star = 1   the star's own disc: limb-darkened, flux-normalised (u = 0.6)
// Each pixel is supersampled ss x ss over its footprint: ALPHA is the covered
// fraction and ALBEDO the mean radiance of the covered samples, so the pixel
// sum is the disc integral even at 2 px across (G-M5-6 point/disc handoff).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform vec3 centre_w = vec3(0.0, 0.0, -10.0);
uniform float radius = 1.0;
uniform vec3 sun_dir_w = vec3(0.0, 0.0, 1.0);   // unit, body -> star, world
uniform mat3 body_basis = mat3(1.0);            // columns: body x (prime meridian), y, z (pole) in world
uniform float rho = 0.0;                         // Minnaert normalisation, rhoFromGeometricAlbedo(p_V, k)
uniform float minnaert_k = 1.0;
uniform float lux = 0.0;                         // the star's illuminance at the body, starIlluminanceAt
uniform float exposure = 1.0;                    // linear pixel per cd/m^2 (Exposure.k)
uniform vec3 tint = vec3(1.0);                   // untextured: unit-luminance colour of the light
uniform bool textured = false;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float albedo_mean = 1.0;                 // the texture's disc-integrated mean luminance (data/planets/ALBEDO)
uniform bool clouds = false;                     // Earth: the cloud map composited over the day map
uniform sampler2D cloud_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tex_lod = 0.0;                     // mip level: about one texel per pixel at this disc size
uniform bool star = false;
uniform float star_mean = 0.0;                   // the star disc's mean radiance (cd/m^2)
uniform float emitter_temp_k = 5772.0;
uniform float limb_u = 0.6;
uniform int ss = 4;
// M5.3 inverse optics mirrors pinned relativity0.7 / existing sky background.
uniform vec3 beta_dir = vec3(0,0,-1);
uniform float beta_mag = 0.0;
uniform float gamma_f = 1.0;
uniform float one_minus_beta = 1.0;
// Draw bounds only; the fragment still traces the original rest sphere/rings.
uniform vec3 apparent_centre_w = vec3(0,0,-10);
uniform float apparent_radius_sin = 0.0;
uniform bool bounded_draw = false;
uniform sampler2D bb_lut : filter_linear, repeat_disable;
uniform float lut_log_tmin;
uniform float lut_log_tmax;
uniform float clip_max = 1024.0;                 // the Sun's disc is clipped here until row 6b's glare pass
// Auto view only (labelled on the HUD): lift a star's own blackbody chroma so its
// colour survives the tone mapper's highlight desaturation, then renormalise to unit
// luminance (Rec. 709 Y, as Blackbody.rgb_unit_luminance) so brightness is unchanged.
// 1 = the physical tint.
uniform float star_saturation = 1.0;
// ---- SPIKE (R2-STAR-SURFACES design, throwaway): resolved stellar surface ----
uniform bool surf_on = false;
uniform float px_per_radius = 1.0;      // apparent disc radius in pixels (CPU, from the angular radius and the FOV)
uniform float cells_across = 900.0;     // convection cells across one stellar diameter (Sun ~ 1.39e6 km / 1.3e3 km ~ 1000)
uniform float gran_contrast = 0.15;     // rms-ish intensity contrast at disc centre (Sun, 500 nm, ~0.13-0.15)
uniform float gran_seed = 0.0;
uniform float surf_time = 0.0;          // surface phase (cell lifetimes), from emission time
uniform int spot_count = 0;
uniform vec4 spots[12];                 // xyz unit dir on the star (world), w = spot angular radius (rad on the sphere)
uniform float umbra_i = 0.25;           // umbra / quiet photosphere, visible (Sun ~0.2-0.3)
uniform float penumbra_i = 0.8;         // penumbra / quiet photosphere (Sun ~0.75-0.85)
uniform float facula_c = 0.08;          // facular excess toward the limb
uniform float surf_norm = 1.0;          // divides the modulation so the disc integral is unchanged
uniform float corona_outer = 1.0;       // quad extent in stellar radii (1 = no corona)
uniform float corona_scale = 1.0;       // 1 = Baumbach (1937) K+F corona, relative to disc-centre radiance
uniform int prom_count = 0;
uniform vec4 proms[6];                  // xyz limb direction (world), w = height in R
uniform float prom_rel = 3.0e-5;        // prominence radiance / disc centre (H-alpha emission, broadband)

#include "res://planets/rings.gdshaderinc"

vec3 view_ray(vec2 frag, vec2 vp, mat4 inv_proj) {
	vec2 ndc = frag / vp * 2.0 - 1.0;
	vec4 v = inv_proj * vec4(ndc, 0.5, 1.0);
	return normalize(v.xyz / v.w);
}

void vertex() {
	vec3 draw_centre = beta_mag > 0.0 ? apparent_centre_w : centre_w;
	vec3 c = (VIEW_MATRIX * vec4(draw_centre, 1.0)).xyz;
	float dist = length(c);
	float s = beta_mag > 0.0 ? apparent_radius_sin : clamp(radius * max(ring_outer, corona_outer) / dist, 0.0, 0.999);
	if (beta_mag > 0.0 && (!bounded_draw || abs(c.z) <= dist*s)) {
		// Large caps and caps crossing the camera plane retain the safe fallback.
		POSITION = vec4(VERTEX.xy, 0.0, 1.0);
	} else {
	vec3 ax = c / dist;
	vec3 up = abs(ax.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 e1 = normalize(cross(up, ax));
	vec3 e2 = cross(ax, e1);
	float pix = 2.0 / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y); // the centre pixel's angle (rad); abs: the matrix carries the Y flip
	float half_w = dist * (s / sqrt(1.0 - s * s) + 3.0 * pix);
	vec3 p = c + (VERTEX.x * e1 + VERTEX.y * e2) * half_w;
	POSITION = PROJECTION_MATRIX * vec4(p, 1.0);
	}
}

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p + gran_seed) * 43758.5453123);
}
// 3D Worley: (F1, F2); cells drift slowly with surf_time (each cell's seed point orbits).
vec2 worley(vec3 x) {
	vec3 i = floor(x); vec3 f = fract(x);
	float f1 = 8.0, f2 = 8.0;
	for (int k = -1; k <= 1; k++) for (int j = -1; j <= 1; j++) for (int h = -1; h <= 1; h++) {
		vec3 g = vec3(float(h), float(j), float(k));
		vec3 o = hash3(i + g);
		o = 0.5 + 0.45 * sin(surf_time * 0.6 + 6.2831 * o);
		vec3 r = g + o - f;
		float d = dot(r, r);
		if (d < f1) { f2 = f1; f1 = d; } else if (d < f2) { f2 = d; }
	}
	return sqrt(vec2(f1, f2));
}
// Multiplicative radiance modulation of the quiet photosphere at world surface normal n, foreshortening mu.
float surface_mod(vec3 n, float mu) {
	if (!surf_on) return 1.0;
	float m = 1.0;
	// granulation: bright cell interiors, dark lanes; contrast falls toward the limb (foreshortening, opacity)
	float cell_px = 2.0 * px_per_radius / cells_across * max(mu, 0.05);
	float g_vis = smoothstep(1.2, 4.0, cell_px);
	if (g_vis > 0.0) {
		vec3 q = n * cells_across * 0.5;
		// domain warp: break the Voronoi straight edges into curved, irregular lanes
		vec3 wq = q + 0.32 * sin(q.yzx * 1.9 + gran_seed) + 0.16 * sin(q.zxy * 4.1 - gran_seed);
		vec2 w = worley(wq);
		float lane = smoothstep(0.02, 0.22, w.y - w.x);        // narrow dark lanes
		float body = exp(-1.6 * w.x * w.x);                      // bright, rounded cell centres
		vec2 w2 = worley(wq * 2.7 + 11.0);                       // sub-structure inside the cells
		float sub = smoothstep(0.0, 0.3, w2.y - w2.x) - 0.6;
		float g = lane * (0.5 + 0.5 * body) + 0.06 * sub * lane - 0.6;
		m += g_vis * gran_contrast * 2.2 * g * sqrt(mu);
	}
	// spots (umbra/penumbra) and faculae (bright toward the limb, around active regions)
	for (int k = 0; k < spot_count; k++) {
		vec3 d = spots[k].xyz; float r = spots[k].w;
		float a = acos(clamp(dot(n, d), -1.0, 1.0));
		float spot_px = r * px_per_radius * max(mu, 0.05);
		float s_vis = smoothstep(0.6, 2.0, spot_px);
		float pen = 1.0 - smoothstep(0.85 * r, r, a);
		float umb = 1.0 - smoothstep(0.35 * r, 0.45 * r, a);
		float f = mix(1.0, penumbra_i, pen);
		f = mix(f, umbra_i, umb);
		m *= mix(1.0, f, s_vis);
		float fac = (1.0 - smoothstep(r, 3.0 * r, a)) * (1.0 - pen);
		m += s_vis * facula_c * fac * pow(1.0 - mu, 1.5) * 2.0;
	}
	return m / surf_norm;
}
// Baumbach (1937) mean corona, radiance relative to the disc centre, r in stellar radii.
float baumbach(float r) {
	return 1.0e-6 * (0.0532 * pow(r, -2.5) + 1.425 * pow(r, -7.0) + 2.565 * pow(r, -17.0));
}

// Radiance (cd/m^2, luminance) and colour of the surface point with view-space unit normal n.
vec3 shade(vec3 n_v, vec3 ray, mat3 inv_view) {
	vec3 n = inv_view * n_v;
	float cos_e = dot(n_v, -ray);
	if (star) {
		float l = star_mean / (1.0 - limb_u / 3.0) * (1.0 - limb_u * (1.0 - cos_e)) * surface_mod(n, cos_e);
		vec3 t = max(vec3(0.0), vec3(1.0) + (tint - vec3(1.0)) * star_saturation);
		t /= max(dot(t, vec3(0.2126, 0.7152, 0.0722)), 1e-4);
		return t * min(l * exposure, clip_max);
	}
	float cos_i = dot(n, sun_dir_w);
	if (cos_i <= 0.0 || cos_e < 0.0) {
		return vec3(0.0);
	}
	float ce = minnaert_k < 1.0 ? max(cos_e, 1e-3) : cos_e;
	float l = minnaert_k == 1.0 ? rho * lux * cos_i / PI : rho * lux * pow(cos_i, minnaert_k) * pow(ce, minnaert_k - 1.0) / PI;
	if (ring_count>0) l *= ring_shadow(n*radius,sun_dir_w,body_basis[2]);
	vec3 col = tint;
	if (textured) {
		vec3 b = transpose(body_basis) * n;
		vec2 uv = vec2(0.5 + atan(b.y, b.x) / TAU, 0.5 - asin(clamp(b.z, -1.0, 1.0)) / PI);
		col = textureLod(albedo_tex, uv, tex_lod).rgb;
		if (clouds) {
			col = mix(col, vec3(1.0), textureLod(cloud_tex, uv, tex_lod).r); // tools/planet_textures.gd composites the same way
		}
		col /= albedo_mean;
	}
	return col * min(l * exposure, clip_max);
}

vec4 bb(float t) {
	float u=(log(t)-lut_log_tmin)/(lut_log_tmax-lut_log_tmin);
	return textureLod(bb_lut,vec2(clamp(u,0.0,1.0),0.5),0.0);
}

void fragment() {
	vec3 c = (VIEW_MATRIX * vec4(centre_w, 1.0)).xyz;
	mat3 inv_view = mat3(INV_VIEW_MATRIX);
	vec3 sum = vec3(0.0);
	float alpha_sum = 0.0;
	int n = max(ss, 1);
	for (int j = 0; j < n; j++) {
		for (int i = 0; i < n; i++) {
			vec2 off = (vec2(float(i), float(j)) + 0.5) / float(n) - 0.5;
			vec3 ray = view_ray(FRAGCOORD.xy + off, VIEWPORT_SIZE, INV_PROJECTION_MATRIX);
			float d = 1.0;
			if (beta_mag > 0.0) {
				vec3 np = normalize(inv_view * ray);
				vec3 bh = -beta_dir;
				float cc = dot(np,bh);
				float denominator = gamma_f * (cc < 0.0 ? one_minus_beta + beta_mag * (1.0 + cc) : 1.0 + beta_mag * cc);
				vec3 nr = normalize((np + ((gamma_f - 1.0) * cc + gamma_f * beta_mag) * bh) / denominator);
				d = 1.0 / denominator;
				ray = transpose(inv_view) * nr;
			}
			float b = dot(ray, c);
			vec3 perp = c - b * ray; // centre to ray: no cancellation of |c|^2 - r^2
			float h2 = radius * radius - dot(perp, perp);
			vec3 radiance=vec3(0.0);
			float sample_alpha=0.0;
			float globe_distance=1e30;
			if (b>0.0 && h2>=0.0) {
				globe_distance=b-sqrt(h2);
				vec3 hit=ray*globe_distance;
				radiance=shade((hit-c)/radius,ray,inv_view);
				sample_alpha=1.0;
			} else if (star && corona_outer > 1.0 && b > 0.0) {
				float rr = sqrt(dot(perp, perp)) / radius;
				if (rr < corona_outer) {
					float centre = star_mean / (1.0 - limb_u / 3.0);
					vec3 t = max(vec3(0.0), vec3(1.0) + (tint - vec3(1.0)) * star_saturation);
					t /= max(dot(t, vec3(0.2126, 0.7152, 0.0722)), 1e-4);
					// streamers: brighter in a few seeded position angles
					vec3 pw = normalize(inv_view * (-perp));
					float st = 0.55 + 0.45 * pow(0.5 + 0.5 * sin(dot(pw, vec3(3.1, 1.7, 2.3)) * 3.0 + gran_seed), 3.0);
					float fade = 1.0 - smoothstep(0.8 * corona_outer, corona_outer, rr);
					radiance = t * min(centre * corona_scale * baumbach(max(rr, 1.0)) * st * fade * exposure, clip_max);
					// prominences: H-alpha pink emission arcs at the limb
					for (int k = 0; k < prom_count; k++) {
						vec3 pd = proms[k].xyz; float hgt = proms[k].w;
						float along = dot(pw, pd);
						float side = length(cross(pw, pd));
						float loop = smoothstep(0.985, 0.999, along) * (1.0 - smoothstep(1.0, 1.0 + hgt, rr)) * step(1.0, rr);
						radiance += vec3(1.0, 0.22, 0.38) / 0.4 * centre * prom_rel * loop * exposure;
					}
					sample_alpha = clamp(dot(radiance, vec3(0.2126, 0.7152, 0.0722)) * 4.0, 0.0, 1.0);
				}
			}
			if (ring_count>0) {
				vec3 rw=normalize(inv_view*ray);
				vec3 pole=body_basis[2];
				float dn=dot(rw,pole);
				if (abs(dn)>1e-8) {
					float distance=dot(centre_w,pole)/dn;
					if (distance>0.0 && distance<globe_distance) {
						vec3 p=rw*distance-centre_w;
						vec4 band=band_at(length(p)/radius);
						if (band.z>0.0) {
							float mu=abs(dn);float mu0=abs(dot(sun_dir_w,pole));
							bool lit=dot(-rw,pole)*dot(sun_dir_w,pole)>0.0;
							float transmission=ring_trans(band.z,mu);
							float ring_light=globe_shadows_ring(p,sun_dir_w)?0.0:ring_radiance(band.w,band.z,mu0,mu,lit);
							radiance=ring_tint*ring_light*exposure+transmission*radiance;
							sample_alpha=1.0-transmission+transmission*sample_alpha;
						}
					}
				}
			}
			if (sample_alpha<=0.0) continue;
			if (beta_mag > 0.0) {
				float temp=star ? emitter_temp_k : 5772.0;
				vec4 rest=bb(temp); vec4 seen=bb(temp*d);
				radiance *= (seen.rgb/max(rest.rgb,vec3(1e-4))) * pow(10.0,seen.a-rest.a);
			}
			sum += min(radiance,vec3(60000.0));
			alpha_sum += sample_alpha;
		}
	}
	if (alpha_sum <= 0.0) {
		discard;
	}
	float cover = alpha_sum / float(n * n);
	ALBEDO = sum / alpha_sum;
	ALPHA = cover;
}
