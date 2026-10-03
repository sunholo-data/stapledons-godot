class_name Exposure
extends RefCounted
## Photometric exposure (M1.5a, F5). Scene units are physical: the starfield
## carries each star's illuminance E_v in lux, the background its luminance in
## cd/m^2 (SkyBackground calibrates the panorama's dark-sky patch to
## DARK_SKY_MAG). The camera maps luminance to a linear pixel value with an
## EV100 exposure (saturation-based, ISO 100, Lagarde & de Rousiers 2014):
##   pixel = L / L_white,   L_white = 1.2 x 2^EV
## A star's splat integrates to E_v over its pixels: peak luminance
## E_v / (2 pi sigma^2 Omega_px), Omega_px the centre pixel's solid angle.
##
## Modes (Q8, D-19: the default is the dark-adapted naked eye; camera-like is a
## labelled setting):
##   EYE     the eye is fully dark-adapted at EV_dark and light-adapts only when
##           the metered scene asks for less sensitivity: EV = max(EV_dark, EV_meter).
##           EV_dark puts a star at the naked-eye threshold (Crumey 2014,
##           pointThresholdIlluminance at field factor FIELD_FACTOR against the
##           dark-sky luminance) exactly at the display's lowest visible level.
##   CAMERA  log-average metering, EV = log2(L_avg x 100 / K), K = 12.5 (ISO 2720).
## Fixed EV locks the exposure at the rest-frame value, so a change on screen is
## physics, not metering. Player bias and the magnitude floor are readability
## aids: labelled on the HUD and off by default.

enum Mode { EYE, CAMERA }

## V mag/arcsec^2 of the panorama's dark-sky reference patch (D-25): the
## deep-space sky at the galactic caps, i.e. integrated starlight + diffuse
## galactic light + extragalactic background, with no airglow and no zodiacal
## light (Leinert et al. 1998, A&AS 127, 1). Not the 22 of a ground dark site.
const DARK_SKY_MAG := 23.5
## AC8 naked-eye window for the measured V_lim: around Crumey's V_lim(F = 2)
## = 6.897 at 23.5 mag/arcsec^2, moved with the dark sky (D-25).
const AC8 := Vector2(6.6, 7.4)
const FIELD_FACTOR := 2.0 # Crumey's typical field factor for real observing
## The display's lowest visible level: on a typical 1000:1 panel the black
## glows at ~0.1% of white, and code VIS_LEVELS (sRGB 7/255 = 0.21% of white,
## about twice the panel's black) is the first level that stands out from it.
## DISPLAY_FLOOR is the linear pre-tonemap value the production chain (AgX +
## glow, 8-bit sRGB) shows at that code; make golden re-measures it.
const DISPLAY_FLOOR := 0.0041
const VIS_LEVELS := 7
const METER_K := 12.5
const SAT := 1.2 # 78 / (S q), S = 100, q = 0.65
const PSF_SIGMA_PX := 0.9 # sky/starfield.gdshader psf_sigma_px
## Player clamp default: a physical camera's limits. The floor is about ISO
## 102400, f/1.4, 30 s (EV100 = log2(1.4^2 / 30) - log2(1024) = -13.9).
const EV_CLAMP := Vector2(-14.0, 20.0)
const FLOOR_MAG := 8.0 # magnitude-floor aid: stars to V 8 shown at the display floor

var mode := Mode.EYE
var fixed := false
var fixed_ev := 0.0
var bias := 0.0 # readability aid, EV
var floor_on := false # readability aid
var clamp_ev := EV_CLAMP
var pixel_sr := 1.0 # solid angle of the centre pixel
var ev := 0.0 # in use
var ev_meter := 0.0 # what the meter asked for (log-average)


## Pinhole camera: the centre pixel spans 2 tan(fov/2) / height radians.
static func centre_pixel_sr(fov_deg: float, height_px: float) -> float:
	var a := 2.0 * tan(deg_to_rad(fov_deg) * 0.5) / height_px
	return a * a


static func l_white(e: float) -> float:
	return SAT * pow(2.0, e)


static func metered_ev(l_avg: float) -> float:
	return log(maxf(l_avg, 1e-12) * 100.0 / METER_K) / log(2.0)


static func dark_sky_luminance() -> float:
	return Relativity.luminance_from_surface_mag(DARK_SKY_MAG)


## Illuminance of the faintest star the dark-adapted eye sees against the dark sky.
static func threshold_lux() -> float:
	return FIELD_FACTOR * Relativity.point_threshold_illuminance(dark_sky_luminance())


## Peak luminance (cd/m^2) of a star of illuminance e (lux) on a pixel of solid angle sr.
static func peak_luminance(e: float, sr: float) -> float:
	return e / (TAU * PSF_SIGMA_PX * PSF_SIGMA_PX * sr)


## EV at which the threshold star's splat peak lands on DISPLAY_FLOOR.
static func dark_adapted_ev(sr: float) -> float:
	return log(peak_luminance(threshold_lux(), sr) / DISPLAY_FLOOR / SAT) / log(2.0)


func configure(fov_deg: float, height_px: float) -> void:
	pixel_sr = centre_pixel_sr(fov_deg, height_px)
	update(dark_sky_luminance())


func ev_dark() -> float:
	return dark_adapted_ev(pixel_sr)


## The EV the active mode asks for at log-average scene luminance l_avg, before bias and clamp.
func mode_ev(l_avg: float) -> float:
	return maxf(ev_dark(), metered_ev(l_avg)) if mode == Mode.EYE else metered_ev(l_avg)


func update(l_avg: float) -> void:
	ev_meter = metered_ev(l_avg)
	ev = fixed_ev if fixed else clampf(mode_ev(l_avg) + bias, clamp_ev.x, clamp_ev.y)


## Lock at the rest-frame value (l_rest: the meter's reading of the same view at beta 0).
func set_fixed(on: bool, l_rest: float) -> void:
	fixed = false
	if on:
		update(l_rest)
		fixed_ev = ev
	fixed = on


## Linear pixel per cd/m^2.
func k() -> float:
	return 1.0 / l_white(ev)


## Starfield exposure uniform: linear splat peak per lux at the centre pixel.
func star_scale() -> float:
	return k() / (TAU * PSF_SIGMA_PX * PSF_SIGMA_PX * pixel_sr)


## Magnitude-floor aid: [illuminance of V FLOOR_MAG, peak it is lifted to], or zeros when off.
func floor_params() -> Vector2:
	return Vector2(Relativity.illuminance_from_v(FLOOR_MAG), DISPLAY_FLOOR) if floor_on else Vector2.ZERO


func mode_name() -> String:
	return "eye (dark-adapted)" if mode == Mode.EYE else "camera (log-average)"


## Metering state for the HUD: never "auto" when the eye is pinned at EV_dark.
func state_name() -> String:
	if fixed:
		return "FIXED at rest"
	if mode == Mode.EYE:
		return "pinned at EV_dark" if ev_meter <= ev_dark() else "light-adapted"
	return "auto"


func hud_line() -> String:
	var s := "EV %+.1f  %s  %s" % [ev, mode_name(), state_name()]
	var aids := PackedStringArray()
	if bias != 0.0:
		aids.append("bias %+.1f EV" % bias)
	if floor_on:
		aids.append("mag floor V %.0f" % FLOOR_MAG)
	if clamp_ev != EV_CLAMP:
		aids.append("clamp %.0f..%.0f" % [clamp_ev.x, clamp_ev.y])
	return s + ("\naid: " + ", ".join(aids) if not aids.is_empty() else "")
