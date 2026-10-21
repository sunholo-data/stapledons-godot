// A resolved body (M5.2a): an exact ray-traced sphere on a camera-facing quad,
// lit by its star as a point source, drawn into the sky pre-exposed (one
// tonemap). Mirrors physics/planets.gd (and through it sunholo/celestial
// reflect.minnaertRadiance); keep them in sync.
//   centre_v   the body centre, placed PLACE units out (planets/system_view.gd), world
//   radius     PLACE R / d, so the angular radius is asin(R / d) exactly
//   star = 1   the star's own disc: limb-darkened, flux-normalised (u = 0.6); R2-STAR-SURFACES: a
//              quadratic law per star (ld_quad) and, where its features resolve on screen (surf_on),
//              a map of local temperature T(x) (granulation, spots, faculae): each element is a
//              blackbody at T(x), seen at D T(x), normalised by surf_norm so the disc's light is the
//              uniform disc's (RS-24). Mirrors physics/star_surface.gd; keep them in sync.
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
// R2-STAR-SURFACES (physics/star_surface.gd is the CPU mirror; the sim's protocol-2.13 surface record
// supplies every number): the law, the gate's inputs, the pattern's salts and weight, the spots.
uniform bool ld_quad = false;                   // false: the linear law limb_u (the Sun keeps it)
uniform float ld_a = 0.0;
uniform float ld_b = 0.0;
uniform bool surf_on = false;                   // false: no layer resolves; today's disc exactly
uniform float px_per_radius = 1.0;              // the disc's apparent radius in pixels
uniform float cells_across = 1.0;               // convection cells across the stellar diameter
uniform float sigma_t = 0.0;                    // rms relative temperature fluctuation of the cells
uniform float facula_sigma_t = 0.0;
uniform uint salt0 = 0u;                        // the pattern of this epoch and the next (float64-reduced on the CPU)
uniform uint salt1 = 0u;
uniform float fade_w = 0.0;                     // cross-fade weight between them, [0, 1)
uniform float surf_norm = 1.0;                  // N: the map's disc mean (StarSurface.normaliser)
uniform int spot_count = 0;
uniform vec4 spots[12];                         // star-frame unit direction, spot radius (rad on the sphere)
uniform vec2 spot_temps[12];                    // umbra, penumbra (K)
// SS3 eclipse layers (design §D6): drawn only while a body covers part of the photosphere, so an
// unoccluded star is unchanged. The mean K+F corona (Baumbach 1937, sunholo/celestial stellar) out
// to corona_outer radii with a chosen streamer modulation; H-alpha prominences at the limb, coloured
// by the line at 656.28 nm / D (relativity's cmf; black outside 360-830 nm).
uniform bool corona_on = false;
uniform float corona_outer = 10.0;
uniform int prom_count = 0;
uniform vec4 proms[6];                          // star-frame unit direction, height (stellar radii)
uniform vec3 prom_rgb = vec3(0.0);              // unit-luminance colour of the line as seen
uniform float prom_rel = 1.0e-5;                // prominence radiance / disc centre (assumed)
uniform float streamer_seed = 0.0;
uniform float streamer_amp = 0.4;              // the streamers' depth (chosen)

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
	float s = beta_mag > 0.0 ? apparent_radius_sin : clamp(radius * max(ring_outer, corona_on ? corona_outer : 1.0) / dist, 0.0, 0.999);
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

vec4 bb(float t) {
	float u=(log(t)-lut_log_tmin)/(lut_log_tmax-lut_log_tmin);
	return textureLod(bb_lut,vec2(clamp(u,0.0,1.0),0.5),0.0);
}

// ---- R2-STAR-SURFACES: the temperature map (mirrors physics/star_surface.gd) ----
uvec3 pcg3d(uvec3 v) {
	v = v * 1664525u + 1013904223u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	v ^= v >> 16u;
	v.x += v.y * v.z; v.y += v.z * v.x; v.z += v.x * v.y;
	return v;
}
vec3 hash01(ivec3 c, uint salt) {
	uvec3 h = pcg3d(uvec3(c) + uvec3(salt, salt * 7u, salt * 13u));
	return vec3(h) / 4294967296.0;
}
vec2 worley(vec3 p, uint salt) {
	ivec3 i = ivec3(floor(p));
	float f1 = 8.0, f2 = 8.0;
	for (int k = -1; k <= 1; k++) for (int j = -1; j <= 1; j++) for (int h = -1; h <= 1; h++) {
		ivec3 c = i + ivec3(h, j, k);
		float d = distance(vec3(c) + hash01(c, salt), p);
		if (d < f1) { f2 = f1; f1 = d; } else if (d < f2) { f2 = d; }
	}
	return vec2(f1, f2);
}
float gran_shape(vec3 p, uint salt) {
	float s = float(salt & 1023u) * (6.283185307179586 / 1024.0);
	vec3 w = p + 0.32 * sin(p.yzx * 1.9 + s) + 0.16 * sin(p.zxy * 4.1 - s);
	vec2 f = worley(w, salt);
	float lane = smoothstep(0.02, 0.22, f.y - f.x);
	float body = exp(-1.6 * f.x * f.x);
	return lane * (0.5 + 0.5 * body);
}
const float SHAPE_MEAN = 0.5176;
const float SHAPE_STD = 0.3616;
// Local temperature at star-frame unit normal b, foreshortening mu (StarSurface.temperature).
float surface_temp(vec3 b, float mu) {
	float teff = emitter_temp_k;
	float cell_px = 2.0 * px_per_radius / cells_across * mu;
	float gg = smoothstep(1.2, 4.0, cell_px);
	float delta = 0.0;
	if (gg > 0.0) {
		vec3 q = b * (cells_across * 0.5);
		float g0 = (gran_shape(q, salt0) - SHAPE_MEAN) / SHAPE_STD;
		float g1 = fade_w > 0.0 ? (gran_shape(q, salt1) - SHAPE_MEAN) / SHAPE_STD : 0.0;
		delta = gg * sigma_t * ((1.0 - fade_w) * g0 + fade_w * g1) / sqrt((1.0 - fade_w) * (1.0 - fade_w) + fade_w * fade_w) * sqrt(mu);
	}
	float spot_mix = 0.0;
	float spot_t = teff;
	for (int k = 0; k < spot_count; k++) {
		float r = spots[k].w;
		float vis = smoothstep(0.6, 2.0, r * px_per_radius);
		if (vis <= 0.0) continue;
		float a = acos(clamp(dot(b, spots[k].xyz), -1.0, 1.0));
		float pen = 1.0 - smoothstep(0.85 * r, r, a);
		float umb = 1.0 - smoothstep(0.35 * r, 0.45 * r, a);
		if (facula_sigma_t > 0.0) {
			delta += vis * facula_sigma_t * (1.0 - smoothstep(r, 3.0 * r, a)) * (1.0 - pen) * pow(1.0 - mu, 1.5);
		}
		if (pen * vis > spot_mix) {
			spot_mix = pen * vis;
			spot_t = mix(spot_temps[k].y, spot_temps[k].x, umb);
		}
	}
	return mix(teff * (1.0 + delta), spot_t, spot_mix);
}

// Radiance (cd/m^2, luminance) and colour of the surface point with view-space unit normal n.
// t_loc: the element's temperature for the Doppler step (the star's Teff unless its map is on).
vec3 shade(vec3 n_v, vec3 ray, mat3 inv_view, out float t_loc) {
	vec3 n = inv_view * n_v;
	float cos_e = dot(n_v, -ray);
	t_loc = emitter_temp_k;
	if (star) {
		float l;
		if (ld_quad) {
			float s = 1.0 - cos_e;
			l = star_mean / (1.0 - ld_a / 3.0 - ld_b / 6.0) * max(0.0, 1.0 - ld_a * s - ld_b * s * s);
		} else {
			l = star_mean / (1.0 - limb_u / 3.0) * (1.0 - limb_u * (1.0 - cos_e));
		}
		if (surf_on) {
			vec3 b = transpose(body_basis) * n;
			float temp = surface_temp(b, cos_e);
			t_loc = temp;
			vec4 e = bb(temp);
			float yr = pow(10.0, e.a - bb(emitter_temp_k).a) / surf_norm;
			vec3 t = max(vec3(0.0), vec3(1.0) + (e.rgb - vec3(1.0)) * star_saturation);
			t /= max(dot(t, vec3(0.2126, 0.7152, 0.0722)), 1e-4);
			return t * min(l * yr * exposure, clip_max);
		}
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
			float t_loc=emitter_temp_k;
			if (b>0.0 && h2>=0.0) {
				globe_distance=b-sqrt(h2);
				vec3 hit=ray*globe_distance;
				radiance=shade((hit-c)/radius,ray,inv_view,t_loc);
				sample_alpha=1.0;
			} else if (star && corona_on && b > 0.0) {
				float rr = sqrt(dot(perp, perp)) / radius;
				if (rr < corona_outer) {
					float centre = ld_quad ? star_mean / (1.0 - ld_a / 3.0 - ld_b / 6.0) : star_mean / (1.0 - limb_u / 3.0);
					float r1 = max(rr, 1.0);
					float k_corona = 1.0e-6 * (0.0532 * pow(r1, -2.5) + 1.425 * pow(r1, -7.0) + 2.565 * pow(r1, -17.0));
					vec3 pw = normalize(inv_view * (-perp));
					vec3 pb = transpose(body_basis) * pw;
					float st = 1.0 - streamer_amp + streamer_amp * pow(0.5 + 0.5 * sin(dot(pb, vec3(3.1, 1.7, 2.3)) * 3.0 + streamer_seed), 3.0);
					float fade = 1.0 - smoothstep(0.85 * corona_outer, corona_outer, rr);
					vec3 col = tint;
					radiance = col * min(centre * k_corona * st * fade * exposure, clip_max);
					for (int k = 0; k < prom_count; k++) {
						float along = dot(pb, proms[k].xyz);
						float loop_ = smoothstep(0.985, 0.999, along) * (1.0 - smoothstep(1.0, 1.0 + proms[k].w, rr));
						radiance += prom_rgb * min(centre * prom_rel * loop_ * exposure, clip_max);
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
				float temp=star ? t_loc : 5772.0;
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
