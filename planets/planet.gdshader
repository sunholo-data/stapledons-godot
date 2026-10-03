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
uniform float limb_u = 0.6;
uniform int ss = 4;
uniform float clip_max = 1024.0;                 // the Sun's disc is clipped here until row 6b's glare pass

vec3 view_ray(vec2 frag, vec2 vp, mat4 inv_proj) {
	vec2 ndc = frag / vp * 2.0 - 1.0;
	vec4 v = inv_proj * vec4(ndc, 0.5, 1.0);
	return normalize(v.xyz / v.w);
}

void vertex() {
	vec3 c = (VIEW_MATRIX * vec4(centre_w, 1.0)).xyz;
	float dist = length(c);
	vec3 ax = c / dist;
	vec3 up = abs(ax.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0);
	vec3 e1 = normalize(cross(up, ax));
	vec3 e2 = cross(ax, e1);
	float s = clamp(radius / dist, 0.0, 0.999);
	float pix = 2.0 / (abs(PROJECTION_MATRIX[1][1]) * VIEWPORT_SIZE.y); // the centre pixel's angle (rad); abs: the matrix carries the Y flip
	float half_w = dist * (s / sqrt(1.0 - s * s) + 3.0 * pix);
	vec3 p = c + (VERTEX.x * e1 + VERTEX.y * e2) * half_w;
	POSITION = PROJECTION_MATRIX * vec4(p, 1.0);
}

// Radiance (cd/m^2, luminance) and colour of the surface point with view-space unit normal n.
vec3 shade(vec3 n_v, vec3 ray, mat3 inv_view) {
	vec3 n = inv_view * n_v;
	float cos_e = dot(n_v, -ray);
	if (star) {
		float l = star_mean / (1.0 - limb_u / 3.0) * (1.0 - limb_u * (1.0 - cos_e));
		return tint * min(l * exposure, clip_max);
	}
	float cos_i = dot(n, sun_dir_w);
	if (cos_i <= 0.0 || cos_e < 0.0) {
		return vec3(0.0);
	}
	float ce = minnaert_k < 1.0 ? max(cos_e, 1e-3) : cos_e;
	float l = minnaert_k == 1.0 ? rho * lux * cos_i / PI : rho * lux * pow(cos_i, minnaert_k) * pow(ce, minnaert_k - 1.0) / PI;
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
	int hits = 0;
	int n = max(ss, 1);
	for (int j = 0; j < n; j++) {
		for (int i = 0; i < n; i++) {
			vec2 off = (vec2(float(i), float(j)) + 0.5) / float(n) - 0.5;
			vec3 ray = view_ray(FRAGCOORD.xy + off, VIEWPORT_SIZE, INV_PROJECTION_MATRIX);
			float b = dot(ray, c);
			vec3 perp = c - b * ray; // centre to ray: no cancellation of |c|^2 - r^2
			float h2 = radius * radius - dot(perp, perp);
			if (b <= 0.0 || h2 < 0.0) {
				continue;
			}
			vec3 hit = ray * (b - sqrt(h2));
			sum += shade((hit - c) / radius, ray, inv_view);
			hits++;
		}
	}
	if (hits == 0) {
		discard;
	}
	float cover = float(hits) / float(n * n);
	ALBEDO = sum / float(hits);
	ALPHA = cover;
}
