class_name SkyModel
extends RefCounted
## CPU reference for the sky background (M1.4b/c). Mirrors sky/background.gdshader
## and the texture contract written by sim/tools/sky_model.ail (T_c code range);
## tests/test_physics.gd checks all three agree.
##
## Panorama: galactic equirect, l = 0 at the centre, l increasing to the LEFT,
## north galactic pole on the top row (D-10, registration in m1-4a-background-options.md).
## World frame: SkyFrame (sky/sky_frame.gd, D-28), galactic (x, y, z) -> world (-y, z, -x).

const T_LO := 1500.0
const T_HI := 30000.0


## Panorama (u, v) for a galaxy-frame world direction.
static func equirect_uv(n: Vector3) -> Vector2:
	var g := SkyFrame.to_galactic(n)
	var l := atan2(g.y, g.x)
	var b := asin(clampf(g.z, -1.0, 1.0))
	return Vector2(fposmod(0.5 - l / TAU, 1.0), 0.5 - b / PI)


## Inverse of equirect_uv: the world direction at panorama (u, v).
static func equirect_dir(uv: Vector2) -> Vector3:
	var l := (0.5 - uv.x) * TAU
	var b := (0.5 - uv.y) * PI
	return SkyFrame.to_world(Vector3(cos(b) * cos(l), cos(b) * sin(l), sin(b)))


static func decode_t(code: int) -> float:
	return exp(log(T_LO) + (log(T_HI) - log(T_LO)) * code / 255.0)


static func encode_t(t: float) -> int:
	var u := (log(maxf(t, 1e-9)) - log(T_LO)) / (log(T_HI) - log(T_LO))
	return clampi(roundi(u * 255.0), 0, 255)


## Per-channel ratio of a texel's linear colour to the Planck colour of its T_c
## at the same luminance. 1 for a texel on the locus; it carries the photo's
## off-locus colour (residual, emission lines) so the rest frame reproduces it.
static func tint(lin: Vector3, t_c: float) -> Vector3:
	var y := lin.dot(Vector3(0.2126729, 0.7151522, 0.0721750))
	var p := Blackbody.rgb_unit_luminance(t_c) * y
	return Vector3(lin.x / maxf(p.x, 1e-6), lin.y / maxf(p.y, 1e-6), lin.z / maxf(p.z, 1e-6))


## Seen linear radiance of a texel under Doppler factor d:
## Y x surfaceBrightnessRatio(T_c, d) x rgb(d T_c) x tint (spec §2, extended sources).
static func radiance(lin: Vector3, t_c: float, d: float) -> Vector3:
	var y := lin.dot(Vector3(0.2126729, 0.7151522, 0.0721750))
	return Blackbody.rgb_unit_luminance(t_c * d) * tint(lin, t_c) * (y * Relativity.surface_brightness_ratio(t_c, d))
