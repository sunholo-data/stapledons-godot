class_name IsmLayer
extends RefCounted
## R1-ISM-DUST I6: the interstellar medium on the galaxy map (design ism-structure-and-dust.md
## section 7.2). A display layer (key D, D-56: an instant display control, never an intent):
## the Local Interstellar Cloud's surface as a wire mesh from its harmonic model, the 14
## Redfield & Linsky clouds as cone shells (a labelled game approximation), labelled and
## coloured by n_H on one logarithmic scale, the planned route coloured by the medium of each
## piece, and a legend with the sources and the assumptions.
##
## Everything drawn is data/ism/ism.json (generated with sim/data/ism.ail by the same tool,
## sim/tools/ism_build.ail: one truth) or a sim field (journey.plan.media). GDScript mirrors only
## the surface's shape: surface_radius() is celestial.ism.starSurfaceRadius (tested against the
## oracle's values in tests/test_ism_layer.gd). Lengths in light years, galactic.

const PATH := "res://data/ism/ism.json"
const N_LO := 0.001 # cm^-3: the colour scale's ends (log)
const N_HI := 10000.0
const HOT_NAME := "hot"

var model: Dictionary = {}
var visible := false
var last_drawn: Array = [] # names drawn by the last draw() (tests)


func load_model(path: String = PATH) -> bool:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if not parsed is Dictionary or not parsed.has("lic") or not parsed.has("clouds"):
		return false
	model = parsed
	return true


func toggle() -> bool:
	visible = not visible
	return visible


## celestial.ism.realSphericalHarmonicAt in float64 scalars: orthonormal real Y_lm of a unit vector
## (x, y, z), l <= 2, no Condon-Shortley phase (m > 0 cos, m < 0 sin).
static func ylm64(l: int, m: int, x: float, y: float, z: float) -> float:
	var s3 := sqrt(3.0 / (4.0 * PI))
	var h15 := 0.5 * sqrt(15.0 / PI)
	match [l, m]:
		[0, 0]: return 0.5 / sqrt(PI)
		[1, -1]: return s3 * y
		[1, 0]: return s3 * z
		[1, 1]: return s3 * x
		[2, -2]: return h15 * x * y
		[2, -1]: return h15 * y * z
		[2, 0]: return 0.25 * sqrt(5.0 / PI) * (3.0 * z * z - 1.0)
		[2, 1]: return h15 * x * z
		[2, 2]: return 0.5 * h15 * (x * x - y * y)
	return 0.0


const ORDER := [[0, 0], [1, -1], [1, 0], [1, 1], [2, -2], [2, -1], [2, 0], [2, 1], [2, 2]]


## celestial.ism.starSurfaceRadius, float64 scalars (dir need not be unit; Vector3 is float32, so
## the direction comes in as three floats).
static func surface_radius64(coeffs: Array, x: float, y: float, z: float) -> float:
	var n := sqrt(x * x + y * y + z * z)
	var r := 0.0
	for i in mini(coeffs.size(), 9):
		r += float(coeffs[i]) * ylm64(ORDER[i][0], ORDER[i][1], x / n, y / n, z / n)
	return r


## The same for drawing (float32 direction; ~1e-7 relative).
static func surface_radius(coeffs: Array, dir: Vector3) -> float:
	return surface_radius64(coeffs, dir.x, dir.y, dir.z)


static func _unit(theta: float, phi: float) -> Vector3:
	return Vector3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta))


## The LIC as polylines (galactic ly): 5 parallels and 12 meridians of its surface.
func lic_lines() -> Array:
	var lic: Dictionary = model.get("lic", {})
	var c: Array = lic.get("centre_ly", [0.0, 0.0, 0.0])
	var centre := Vector3(c[0], c[1], c[2])
	var coeffs: Array = lic.get("coeffs_ly", [])
	var out: Array = []
	for k in range(1, 6):
		var th := PI * k / 6.0
		var line := PackedVector3Array()
		for j in 49:
			var u := _unit(th, TAU * j / 48.0)
			line.append(centre + u * surface_radius(coeffs, u))
		out.append(line)
	for j in 12:
		var ph := TAU * j / 12.0
		var line := PackedVector3Array()
		for k in 25:
			var u := _unit(PI * k / 24.0, ph)
			line.append(centre + u * surface_radius(coeffs, u))
		out.append(line)
	return out


## A cone shell's outline (galactic ly): the cap circles at r_in and r_out and 6 generators.
static func cloud_lines(cl: Dictionary) -> Array:
	var ax: Array = cl.get("axis", [0.0, 0.0, 1.0])
	var a := Vector3(ax[0], ax[1], ax[2]).normalized()
	var e1 := a.cross(Vector3(0, 0, 1) if absf(a.z) < 0.9 else Vector3(1, 0, 0)).normalized()
	var e2 := a.cross(e1)
	var half := deg_to_rad(float(cl.get("half_angle_deg", 10.0)))
	var r_in := float(cl.get("r_in_ly", 0.0))
	var r_out := float(cl.get("r_out_ly", 0.0))
	var out: Array = []
	for r: float in [r_in, r_out]:
		if r <= 0.0:
			continue
		var ring := PackedVector3Array()
		for j in 33:
			var p := TAU * j / 32.0
			ring.append((a * cos(half) + (e1 * cos(p) + e2 * sin(p)) * sin(half)) * r)
		out.append(ring)
	for j in 6:
		var p := TAU * j / 6.0
		var g := a * cos(half) + (e1 * cos(p) + e2 * sin(p)) * sin(half)
		out.append(PackedVector3Array([g * r_in, g * r_out]))
	return out


## One logarithmic colour scale for n_H (cm^-3): the hot gas deep blue, the warm clouds amber,
## dense clouds white-pink.
static func colour_for(n_h: float, alpha: float = 0.8) -> Color:
	var f := clampf((log(maxf(n_h, N_LO)) - log(N_LO)) / (log(N_HI) - log(N_LO)), 0.0, 1.0)
	var lo := Color(0.25, 0.4, 0.95)
	var mid := Color(1.0, 0.7, 0.3)
	var hi := Color(1.0, 0.85, 0.95)
	var c := lo.lerp(mid, f * 2.0) if f < 0.5 else mid.lerp(hi, (f - 0.5) * 2.0)
	c.a = alpha
	return c


func n_h_of(name: String) -> float:
	if name == HOT_NAME:
		return float(model.get("hot", {}).get("n_h_cm3", 0.0039))
	if name == "LIC":
		return float(model.get("lic", {}).get("n_h_cm3", 0.2474))
	for cl: Dictionary in model.get("clouds", []):
		if cl.get("name") == name:
			return float(cl.get("n_h_cm3", 0.0))
	return 0.0


## Display name of a medium as the HUD and the map label it.
static func label_of(name: String) -> String:
	match name:
		"hot": return "Local Bubble hot gas"
		"LIC": return "Local Interstellar Cloud"
		"uniform": return "uniform medium"
	return "%s cloud" % name


## The route a -> b (galactic ly) cut into the plan's media pieces (journey.plan.media: name,
## n_h_cm3, length_ly in the order met; the sim's profile merges each medium's pieces, so a
## medium met twice is drawn where it was first met; the lengths sum to the leg).
static func route_pieces(a: Vector3, b: Vector3, media: Array) -> Array:
	var out: Array = []
	var total := 0.0
	for m: Dictionary in media:
		total += float(m.get("length_ly", 0.0))
	if not (total > 0.0):
		return out
	var s := 0.0
	for m: Dictionary in media:
		var l := float(m.get("length_ly", 0.0))
		out.append({"a": a.lerp(b, s / total), "b": a.lerp(b, (s + l) / total), "name": str(m.get("name", "")), "n_h": float(m.get("n_h_cm3", 0.0))})
		s += l
	return out


func legend() -> String:
	return str(model.get("legend", ""))


## Draw the layer on the map's overlay through its camera; to_world maps galactic ly to the
## map's 3D frame (Starfield.galactic_to_world). Returns the number of polylines drawn.
func draw(overlay: Control, camera: Camera3D, to_world: Callable, route: Array = []) -> int:
	last_drawn = []
	if not visible or model.is_empty():
		return 0
	var font := ThemeDB.fallback_font
	var n := 0
	n += _lines(overlay, camera, to_world, lic_lines(), colour_for(n_h_of("LIC"), 0.35))
	_label(overlay, camera, to_world, Vector3(model.lic.centre_ly[0], model.lic.centre_ly[1], model.lic.centre_ly[2]), "LIC (Local Interstellar Cloud)", colour_for(n_h_of("LIC")), font)
	last_drawn.append("LIC")
	for cl: Dictionary in model.get("clouds", []):
		var col := colour_for(float(cl.get("n_h_cm3", 0.0)), 0.45)
		n += _lines(overlay, camera, to_world, cloud_lines(cl), col)
		var ax: Array = cl.axis
		var mid := Vector3(ax[0], ax[1], ax[2]) * 0.5 * (float(cl.r_in_ly) + float(cl.r_out_ly))
		_label(overlay, camera, to_world, mid, label_of(str(cl.name)), colour_for(float(cl.get("n_h_cm3", 0.0))), font)
		last_drawn.append(str(cl.name))
	for p: Dictionary in route:
		var a: Vector3 = to_world.call(p.a)
		var b: Vector3 = to_world.call(p.b)
		if camera.is_position_behind(a) or camera.is_position_behind(b):
			continue
		overlay.draw_line(camera.unproject_position(a), camera.unproject_position(b), colour_for(p.n_h, 0.95), 4.0, true)
		n += 1
	var parts := legend().split(" Sources: ")
	var lines := ["Medium layer (D): " + parts[0]] + (["Sources: " + parts[1]] if parts.size() > 1 else [])
	var y := overlay.size.y - 22.0 - 16.0 * lines.size()
	for ln: String in lines:
		overlay.draw_string(font, Vector2(12, y), ln, HORIZONTAL_ALIGNMENT_LEFT, overlay.size.x - 480.0, 12, Color(0.75, 0.8, 0.9, 0.9))
		y += 16.0
	return n


func _lines(overlay: Control, camera: Camera3D, to_world: Callable, lines: Array, col: Color) -> int:
	var n := 0
	for line: PackedVector3Array in lines:
		var pts := PackedVector2Array()
		for q: Vector3 in line:
			var w: Vector3 = to_world.call(q)
			if camera.is_position_behind(w):
				pts = PackedVector2Array()
				break
			pts.append(camera.unproject_position(w))
		if pts.size() >= 2:
			overlay.draw_polyline(pts, col, 1.0, true)
			n += 1
	return n


func _label(overlay: Control, camera: Camera3D, to_world: Callable, at: Vector3, text: String, col: Color, font: Font) -> void:
	var w: Vector3 = to_world.call(at)
	if not camera.is_position_behind(w):
		overlay.draw_string(font, camera.unproject_position(w) + Vector2(4, -4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
