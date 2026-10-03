class_name CmbGlow
extends RefCounted
## The forward CMB disc (M1.8, queue row 6a, D-11). The CMB is a blackbody at
## T0 = 2.725 K in every galaxy-frame direction, so in the ship frame each ray
## sees a blackbody at T0 D(theta'), D = 1 / (gamma (1 - beta cos theta')), and
## its radiance is photopicRadiance(T0 D) in cd/m^2 (sunholo/relativity 0.5.x:
## optics.cmbSeenTemperatureApparent, blackbody.photopicRadiance; mirrored in
## physics/relativity.gd and physics/blackbody.gd). Nothing is a ratio against
## 2.725 K: at rest the radiance underflows to exactly 0.
##
## The disc is tiny: T halves at theta' ~ 1/gamma (4.9 arcmin at gamma 707),
## i.e. a few pixels. It is drawn through the same angular point-spread
## function as the stars (sky/exposure.gd psf_sigma_rad), so a sub-pixel core
## does not alias and its illuminance (the integral of L over the solid angle)
## is kept. CPU builds the radial profile once per speed:
##   L_psf(r) = (1 / s^2) integral L(r') exp(-(r - r')^2 / 2 s^2) I0e(r r' / s^2) r' dr'
## (a radially symmetric image convolved with a 2-D Gaussian; I0e the
## exponentially scaled Bessel I0), and the sky shader samples it by theta'.

## Finite lookup over T in [0, T_MAX] (gate 5): log10 photopicRadiance, linear in T.
const T_MAX := 5000.0
const LUT_SIZE := 1025
const LOG_FLOOR := -60.0 # stored for radiance <= 1e-60 cd/m^2; read back as exactly 0
const PROFILE_SIZE := 256
const CORE_CUT := 1e-15 # the core ends where L < CORE_CUT x the pole value
const TAIL_SIGMAS := 9.0 # the blurred profile runs this many sigmas past the core

static var _lut := PackedFloat64Array()

var theta_max := 0.0 # rad; the profile is 0 beyond it
var illuminance := 0.0 # lux: integral of L over the disc (blurred or not)
var pole_temperature := 0.0 # K
var sigma := 0.0 # PSF sigma (rad) the profile was built with
var image: Image = null # PROFILE_SIZE x 1 RGBAF: rgb unit-luminance colour, a = log10 L
var texture: ImageTexture = null
var _omb := -1.0
var _logl := PackedFloat64Array()


static func lut() -> PackedFloat64Array:
	if _lut.is_empty():
		_lut.resize(LUT_SIZE)
		for i in LUT_SIZE:
			var l := Blackbody.photopic_radiance(T_MAX * i / (LUT_SIZE - 1.0))
			_lut[i] = maxf(log(l) / log(10.0), LOG_FLOOR) if l > 0.0 else LOG_FLOOR
	return _lut


## photopicRadiance(T) through the lookup (exact above T_MAX).
static func radiance(t: float) -> float:
	if not (t > 0.0):
		return 0.0
	if t >= T_MAX:
		return Blackbody.photopic_radiance(t)
	var x := t / T_MAX * (LUT_SIZE - 1.0)
	var i := mini(int(x), LUT_SIZE - 2)
	var a := lerpf(lut()[i], _lut[i + 1], x - i)
	return 0.0 if a <= LOG_FLOOR + 1.0 else pow(10.0, a)


## Sharp CMB radiance (cd/m^2) at apparent angle theta' from the direction of travel.
static func sharp(theta_app: float, omb: float) -> float:
	return radiance(Relativity.cmb_temperature_apparent(theta_app, omb))


## Exponentially scaled modified Bessel I0: e^-x I0(x), x >= 0 (Abramowitz &
## Stegun 9.8.1-9.8.2, |error| < 2e-7 relative).
static func i0e(x: float) -> float:
	if x < 3.75:
		var t := x * x / 14.0625
		return exp(-x) * (1.0 + t * (3.5156229 + t * (3.0899424 + t * (1.2067492 + t * (0.2659732 + t * (0.0360768 + t * 0.0045813))))))
	var u := 3.75 / x
	return (0.39894228 + u * (0.01328592 + u * (0.00225319 + u * (-0.00157565 + u * (0.00916281 + u * (-0.02057706 + u * (0.02635537 + u * (-0.01647633 + u * 0.00392377)))))))) / sqrt(x)


## True when the profile would change visibly: speed moved by > 0.5% in gamma, or a new sigma.
func needs_build(omb: float, sigma_rad: float) -> bool:
	if image == null or _omb <= 0.0 or sigma_rad != sigma:
		return true
	return absf(Relativity.gamma_of_one_minus_beta(omb) / Relativity.gamma_of_one_minus_beta(_omb) - 1.0) > 0.005


## Builds the profile for 1 - beta = omb through a Gaussian PSF of sigma_rad
## (0: the sharp disc). Below about gamma 70 the pole is under 400 K and the
## profile is empty (illuminance 0, theta_max 0).
func build(omb: float, sigma_rad: float) -> void:
	_omb = omb
	sigma = sigma_rad
	pole_temperature = Relativity.cmb_temperature_apparent(0.0, omb)
	var peak := radiance(pole_temperature)
	_logl.resize(PROFILE_SIZE)
	_logl.fill(LOG_FLOOR)
	image = Image.create(PROFILE_SIZE, 1, false, Image.FORMAT_RGBAF)
	theta_max = 0.0
	illuminance = 0.0
	if peak > 0.0:
		var g := Relativity.gamma_of_one_minus_beta(omb)
		var core := 0.0 # where L falls below CORE_CUT x peak (L is monotone in theta')
		var step := 0.05 / g
		while sharp(core, omb) > CORE_CUT * peak and core < PI:
			core += step
		var h := minf(sigma_rad, 1.0 / g) / 16.0 if sigma_rad > 0.0 else core / 512.0
		var n_in := int(ceil(core / h)) + 1
		var r_in := PackedFloat64Array()
		var l_in := PackedFloat64Array()
		var c_in := []
		for j in n_in:
			var r := j * h
			var t := Relativity.cmb_temperature_apparent(r, omb)
			r_in.append(r)
			l_in.append(radiance(t))
			c_in.append(Blackbody.lut_rgb(maxf(t, Blackbody.LUT_T_MIN)))
		var fine := core / 2048.0 # illuminance on a grid of its own, the same with or without the PSF
		for j in 2048:
			var r := (j + 0.5) * fine
			illuminance += TAU * sin(r) * sharp(r, omb) * fine
		theta_max = core + (TAIL_SIGMAS * sigma_rad if sigma_rad > 0.0 else 0.0)
		for i in PROFILE_SIZE:
			var r := theta_max * i / (PROFILE_SIZE - 1.0)
			var l := 0.0
			var rgb := Vector3.ZERO
			if sigma_rad > 0.0:
				var s2 := sigma_rad * sigma_rad
				for j in n_in:
					var w: float = l_in[j] * r_in[j] * h * (0.5 if j == 0 or j == n_in - 1 else 1.0) / s2 \
						* exp(-(r - r_in[j]) * (r - r_in[j]) / (2.0 * s2)) * i0e(r * r_in[j] / s2)
					l += w
					rgb += c_in[j] * w
			else:
				l = sharp(r, omb)
				rgb = Blackbody.lut_rgb(maxf(Relativity.cmb_temperature_apparent(r, omb), Blackbody.LUT_T_MIN)) * l
			_logl[i] = maxf(log(l) / log(10.0), LOG_FLOOR) if l > 0.0 else LOG_FLOOR
			var c := rgb / l if l > 0.0 else Vector3.ONE
			image.set_pixel(i, 0, Color(c.x, c.y, c.z, _logl[i]))
	if texture == null:
		texture = ImageTexture.create_from_image(image)
	else:
		texture.set_image(image)


## Radiance (cd/m^2) of the built profile at theta': the CPU mirror of the sky
## shader's lookup (linear in log10 L between samples, 0 at and past theta_max).
func profile(theta_app: float) -> float:
	if theta_max <= 0.0 or theta_app >= theta_max:
		return 0.0
	var x := theta_app / theta_max * (PROFILE_SIZE - 1.0)
	var i := mini(int(x), PROFILE_SIZE - 2)
	var a := lerpf(_logl[i], _logl[i + 1], x - i)
	return 0.0 if a <= LOG_FLOOR + 1.0 else pow(10.0, a)
