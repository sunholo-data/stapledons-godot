// R2-CAPTAIN-ANIMATION D-118: the captain billboard with a between-frame effect. Mark: "the jerkiness is
// kinda ok even if unintentional, alien a little. perhaps blurring or trails or something in between
// the frames will reinforce that?" The painted walk keeps its stepped cadence; this only adds:
//   mode 1  echo   the previous painted frame where the body was a frame ago, fading over `t`
//   mode 2  trail  a short smear of the current frame behind the travel, in the ink colour, while moving
//   mode 3  blur   a brief directional blur of the current frame on each frame change, fading over `t`
// cur_tex and prev_tex are the full cell canvas (so both frames share coordinates). `t` is 1 at a frame
// change and 0 after the effect's duration; the avatar computes it from the walk phase (deterministic).
// Billboard as BaseMaterial3D's: fixed Y in the upright walk views, full otherwise.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha, shadows_disabled;

uniform sampler2D cur_tex : source_color, filter_linear_mipmap;
uniform sampler2D prev_tex : source_color, filter_linear_mipmap;
uniform int mode = 0;
uniform float t = 0.0;          // 1 at a frame change -> 0
uniform float moving = 0.0;     // 1 while walking
uniform vec2 dir = vec2(1.0, 0.0); // the travel on the texture (u right, v down), unit; sampling at UV + k*dir draws the image k behind
uniform float px = 0.0052;      // one cell pixel in uv (1/192)
uniform float step_px = 16.0;   // one painted frame's travel on the canvas, cell px (the deck's 0.124 m)
uniform vec3 ink = vec3(0.259, 0.208, 0.333); // #423555
uniform bool fixed_y = true;

void vertex() {
	if (fixed_y) {
		vec3 up = vec3(0.0, 1.0, 0.0);
		vec3 right = normalize(cross(up, INV_VIEW_MATRIX[2].xyz));
		vec3 fwd = normalize(cross(right, up));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(right * length(MODEL_MATRIX[0].xyz), 0.0), vec4(up * length(MODEL_MATRIX[1].xyz), 0.0), vec4(fwd * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]);
	} else {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * length(MODEL_MATRIX[0].xyz), INV_VIEW_MATRIX[1] * length(MODEL_MATRIX[1].xyz), INV_VIEW_MATRIX[2] * length(MODEL_MATRIX[2].xyz), MODEL_MATRIX[3]);
	}
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

// a over b, straight alpha
vec4 over(vec4 a, vec4 b) {
	float o = a.a + b.a * (1.0 - a.a);
	vec3 c = (a.rgb * a.a + b.rgb * b.a * (1.0 - a.a)) / max(o, 1e-5);
	return vec4(c, o);
}

void fragment() {
	vec4 base = texture(cur_tex, UV);
	vec4 col = base;
	if (mode == 1) {
		vec4 echo = texture(prev_tex, UV + dir * step_px * px); // where the body was a frame ago
		echo.a *= 0.40 * t;
		col = over(base, echo);
	} else if (mode == 2) {
		vec4 trail = vec4(0.0);
		float w[4] = float[](0.30, 0.20, 0.12, 0.06);
		for (int k = 0; k < 4; k++) {
			vec4 s = texture(cur_tex, UV + dir * float(k + 1) * 0.25 * step_px * px);
			trail = over(trail, vec4(mix(s.rgb, ink, 0.7), s.a * w[k] * moving));
		}
		col = over(base, trail);
	} else if (mode == 3) {
		vec4 acc = vec4(0.0);
		float wsum = 0.0;
		for (int k = -2; k <= 2; k++) {
			float wk = 1.0 - abs(float(k)) * 0.3;
			vec4 s = texture(cur_tex, UV + dir * float(k) * 0.15 * step_px * px);
			acc += vec4(s.rgb * s.a, s.a) * wk;
			wsum += wk;
		}
		acc /= wsum;
		vec4 blurred = vec4(acc.rgb / max(acc.a, 1e-5), acc.a);
		col = mix(base, blurred, t);
	}
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
