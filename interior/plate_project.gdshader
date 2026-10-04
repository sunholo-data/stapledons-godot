// Bridge v2 play plate (m4-2-requirements §9): the illustrated plate projected through the
// fixed iso camera onto the play GLB. The camera is orthographic and only pans, so the
// projection is exact on every visible surface at every pan; the GLB supplies coverage, depth
// (the captain sprite is occluded by the set) and the normals for the live glow term.
//
// Plate pixel of a world (GLB-frame, +Y = ship +Z) point P, for the pan-0 camera at cam_origin
// with basis (cam_right, cam_up), plate vertical extent size_m, aspect = width / height:
//     u = 0.5 + dot(P - cam_origin, cam_right) / (size_m * aspect)
//     v = 0.5 - (dot(P - cam_origin, cam_up) - v_offset) / size_m
// interior/interior.gd plate_uv() is the CPU mirror (tests and make golden G-M4-5).
//
// The plate is painted with static spire light only (baked). The light from outside the ship
// is live: the forward bubble-wall glow adds albedo x glow_rgb x facing (+ a rim term), where
// glow_rgb is the glow's exposed pixel at the forward pole (ForwardGlow: the sim's
// ship.ism.glow_pole_w_m2 / pi x lm/W x the sky exposure k; 0 while the sim sends no pole) and
// facing = max(n . +Y, 0): a diffuse surface under the glowing forward cap reflects
// albedo x L x its cosine to the cap. The plate keeps highlight headroom (white point 0.88).
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled, shadows_disabled;

uniform sampler2D plate : source_color, filter_linear_mipmap, repeat_disable;
uniform vec3 cam_origin = vec3(0.0);
uniform vec3 cam_right = vec3(1.0, 0.0, 0.0);
uniform vec3 cam_up = vec3(0.0, 1.0, 0.0);
uniform float size_m = 22.0;
uniform float aspect = 1.8383838;
uniform float v_offset = 0.0;
uniform vec3 glow_rgb = vec3(0.0);
uniform float glow_strength = 1.0;
uniform float rim_strength = 0.5;
uniform vec3 fallback = vec3(0.0); // outside the plate (never on screen within the pan range)
varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 d = wpos - cam_origin;
	vec2 uv = vec2(0.5 + dot(d, cam_right) / (size_m * aspect), 0.5 - (dot(d, cam_up) - v_offset) / size_m);
	bool inside = all(greaterThanEqual(uv, vec2(0.0))) && all(lessThanEqual(uv, vec2(1.0)));
	vec3 base = inside ? texture(plate, uv).rgb : fallback;
	vec3 n = normalize(wnrm);
	float facing = max(n.y, 0.0);
	vec3 view = normalize(cross(cam_right, cam_up)); // toward the camera (+Z of its basis)
	float rim = pow(1.0 - clamp(abs(dot(n, view)), 0.0, 1.0), 3.0) * facing;
	ALBEDO = base + glow_rgb * base * (glow_strength * facing + rim_strength * rim);
}
