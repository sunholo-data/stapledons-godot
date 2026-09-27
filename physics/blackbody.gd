class_name Blackbody
extends RefCounted
## Planck blackbody colour and luminance via the CIE 1931 2-degree observer.
##
## Colour matching functions use the multi-lobe Gaussian fit of
## Wyman, Sloan & Shirley (2013), JCGT 2(2), accurate to well under 1% of
## the tabulated CMFs. Output is linear sRGB (D65 white), so a ~6500 K
## source renders white, as for an eye adapted to daylight.

const LAMBDA_MIN := 360.0
const LAMBDA_MAX := 830.0
const LAMBDA_STEP := 1.0
const C2 := 1.4387769e7 # second radiation constant hc/k in nm*K

const LUT_T_MIN := 300.0
const LUT_T_MAX := 1.0e6
const LUT_SIZE := 1024

static var _cache := {}


static func _g(x: float, mu: float, s1: float, s2: float) -> float:
	var s := s1 if x < mu else s2
	var t := (x - mu) / s
	return exp(-0.5 * t * t)


static func cmf(lam: float) -> Vector3:
	var x := 1.056 * _g(lam, 599.8, 37.9, 31.0) + 0.362 * _g(lam, 442.0, 16.0, 26.7) - 0.065 * _g(lam, 501.1, 20.4, 26.2)
	var y := 0.821 * _g(lam, 568.8, 46.9, 40.5) + 0.286 * _g(lam, 530.9, 16.3, 31.1)
	var z := 1.217 * _g(lam, 437.0, 11.8, 36.0) + 0.681 * _g(lam, 459.0, 26.0, 13.8)
	return Vector3(x, y, z)


## Spectral radiance, arbitrary but fixed units (the 2hc^2 prefactor is dropped).
## Wavelength enters in micrometres so values stay far from float underflow
## (at 300 K the visible band is ~1e-25 in these units, ~1e-40 in nm units).
static func planck(lam_nm: float, t_kelvin: float) -> float:
	var e := C2 / (lam_nm * t_kelvin)
	if e > 700.0:
		return 0.0
	return pow(lam_nm * 1e-3, -5.0) / (exp(e) - 1.0)


## CIE XYZ of a blackbody at temperature T (absolute scale, consistent across T).
## Returned as a float64 array [X, Y, Z]: Godot's Vector3 is float32 and
## underflows for cool sources (it produced NaN colours below ~300 K).
static func xyz(t_kelvin: float) -> PackedFloat64Array:
	if _cache.has(t_kelvin):
		return _cache[t_kelvin]
	var x := 0.0
	var y := 0.0
	var z := 0.0
	var lam := LAMBDA_MIN
	while lam <= LAMBDA_MAX:
		var p := planck(lam, t_kelvin)
		var c := cmf(lam)
		x += c.x * p
		y += c.y * p
		z += c.z * p
		lam += LAMBDA_STEP
	var out := PackedFloat64Array([x * LAMBDA_STEP, y * LAMBDA_STEP, z * LAMBDA_STEP])
	_cache[t_kelvin] = out
	return out


static func luminance(t_kelvin: float) -> float:
	return xyz(t_kelvin)[1]


static func chromaticity(t_kelvin: float) -> Vector2:
	var v := xyz(t_kelvin)
	var s := v[0] + v[1] + v[2]
	return Vector2(v[0] / s, v[1] / s)


## x, y, z are float64 tristimulus values (callers normalise to Y = 1 first).
static func xyz_to_linear_srgb(x: float, y: float, z: float) -> Vector3:
	return Vector3(
		3.2404542 * x - 1.5371385 * y - 0.4985314 * z,
		-0.9692660 * x + 1.8760108 * y + 0.0415560 * z,
		0.0556434 * x - 0.2040259 * y + 1.0572252 * z)


## Linear sRGB colour with luminance Y = 1. Out-of-gamut (deep red/blue)
## colours are desaturated toward white at constant luminance.
static func rgb_unit_luminance(t_kelvin: float) -> Vector3:
	var v := xyz(t_kelvin)
	var rgb := xyz_to_linear_srgb(v[0] / v[1], 1.0, v[2] / v[1])
	var m := minf(rgb.x, minf(rgb.y, rgb.z))
	if m < 0.0:
		# Mix with white (Y = 1) until the most negative channel reaches zero.
		var k := -m / (1.0 - m)
		rgb = rgb * (1.0 - k) + Vector3.ONE * k
	return rgb


static func lut_u(t_kelvin: float) -> float:
	return (log(t_kelvin) - log(LUT_T_MIN)) / (log(LUT_T_MAX) - log(LUT_T_MIN))


## 1-D float texture: rgb = unit-luminance colour, a = log10(Y) absolute.
## Sampled by the starfield shader with u = lut_u(T).
static func build_lut() -> ImageTexture:
	var img := Image.create(LUT_SIZE, 1, false, Image.FORMAT_RGBAF)
	for i in LUT_SIZE:
		var u := (float(i) + 0.5) / LUT_SIZE
		var t := exp(log(LUT_T_MIN) + u * (log(LUT_T_MAX) - log(LUT_T_MIN)))
		var rgb := rgb_unit_luminance(t)
		img.set_pixel(i, 0, Color(rgb.x, rgb.y, rgb.z, log(luminance(t)) / log(10.0)))
	return ImageTexture.create_from_image(img)
