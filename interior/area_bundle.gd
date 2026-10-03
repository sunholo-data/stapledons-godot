class_name AreaBundle
extends RefCounted
## M4.0 area bundle loader: the ship-interior brief §9 delivery format, read from a directory
## (assets/areas/<area>/ for the game, tests/fixtures/areas/<name>/ for tests):
##
##   manifest.json      the schema below
##   cam_<area>.json    the panorama camera (brief §5.2), ship frame (ShipFrame)
##   pano_<area>.png    RGBA, alpha exactly 0 wherever space shows
##   play_<area>.glb    the isometric play area: WALK_, SPAWN_, INTERACT_ (glTF: metres, Y up)
##   fg_<area>.png      RGBA foreground silhouettes
##
## Manifest schema = brief §9 field for field (design V17), all REQUIRED:
##   area: String
##   layers.panorama {file, parallax}   layers.play {file, iso_pitch_deg, iso_yaw_deg, iso_size_m}
##   layers.foreground {file, parallax} camera: String   focus_m: [x, y, z]   sky_visible: bool
## File names follow the brief: pano_/play_/fg_/cam_<area>. Optional, typed when present:
## layers.panorama/foreground.overscan_px [x, y] (m4-2-requirements §4: margin per side for
## the parallax pan; the camera then spans the whole panorama plate). The game-side extension is
## an optional `placeholder` (bool, default false): a placeholder bundle shows a small
## "placeholder art" tag in the HUD. Unknown keys are KEPT (manifest holds the whole document)
## and ignored, so a richer brief revision or the Blender side's extras do not break the loader.
## preview_rest.png / preview_099c.png are review-only and not required.
##
## A bundle with any schema error or a missing layer file is refused: ok() is false and
## errors lists every problem (not just the first), so an art hand-off gets one full report.
## Images and the GLB load at runtime from the files (no Godot import step): swapping a
## bundle is a data drop (AC14).

const CAMERA_FRAME := "ship: +Z = direction of travel (up), origin = bubble centre, metres"
const HUD_TAG := "placeholder art"
const UNIT_TOL := 1e-4 # cam forward/up are float32 out of Blender: unit and orthogonal to this

var dir := ""
var manifest := {}
var camera := {}
var errors := PackedStringArray()
var placeholder := false


static func load_dir(path: String) -> AreaBundle:
	var b := AreaBundle.new()
	b.dir = path.trim_suffix("/")
	var m: Variant = _read_json(b.dir.path_join("manifest.json"), b.errors, "manifest.json")
	if not m is Dictionary:
		return b
	b.manifest = m
	b.errors.append_array(check_manifest(b.manifest))
	if not b.errors.is_empty():
		return b
	b.placeholder = b.manifest.get("placeholder", false)
	for layer in ["panorama", "play", "foreground"]:
		if not FileAccess.file_exists(b.path(layer)):
			b.errors.append("missing layer %s: %s" % [layer, b.path(layer)])
	var c: Variant = _read_json(b.path("camera"), b.errors, "camera " + str(b.manifest["camera"]))
	if c is Dictionary:
		b.camera = c
		b.errors.append_array(check_camera(b.camera))
		if b.camera.get("panorama") is String and b.camera["panorama"] != b.manifest["layers"]["panorama"]["file"]:
			b.errors.append("camera.panorama %s != layers.panorama.file %s" % [b.camera["panorama"], b.manifest["layers"]["panorama"]["file"]])
	return b


func ok() -> bool:
	return errors.is_empty()


## The HUD tag for review builds: "placeholder art" for a placeholder bundle, else "".
func hud_tag() -> String:
	return HUD_TAG if placeholder else ""


## File path of a layer ("panorama", "play", "foreground") or "camera".
func path(layer: String) -> String:
	if layer == "camera":
		return dir.path_join(manifest["camera"])
	return dir.path_join(manifest["layers"][layer]["file"])


## Pixels of margin on EACH side of a plate ("panorama" or "foreground"), from the optional
## layers.<layer>.overscan_px (m4-2-requirements §4); (0, 0) when absent.
func overscan(layer: String) -> Vector2i:
	var os: Variant = manifest["layers"][layer].get("overscan_px")
	return Vector2i(int(os[0]), int(os[1])) if os is Array else Vector2i.ZERO


## The pan-0 view size: the camera spans the whole panorama plate (widened fov), so
## view = camera resolution - 2 x panorama overscan.
func view_size() -> Vector2i:
	return Vector2i(int(camera["resolution"][0]), int(camera["resolution"][1])) - 2 * overscan("panorama")


## Expected pixel size of a plate: view + 2 x its own overscan (the panorama's equals the
## camera resolution by construction).
func plate_size(layer: String) -> Vector2i:
	return view_size() + 2 * overscan(layer)


## The pan-0 view region inside a plate.
func view_rect(layer: String) -> Rect2i:
	return Rect2i(overscan(layer), view_size())


func area() -> String:
	return manifest["area"]


func load_image(layer: String) -> Image:
	return Image.load_from_file(path(layer))


## The play area as a node tree (glTF is metres, Y up; the caller adds it to the scene).
func instantiate_play() -> Node3D:
	return load_glb(path("play"))


static func load_glb(file: String) -> Node3D:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(file, st) != OK:
		return null
	return doc.generate_scene(st) as Node3D


## Every schema problem of a manifest dictionary (V17), empty when valid.
static func check_manifest(m: Dictionary) -> PackedStringArray:
	var e := PackedStringArray()
	_need(e, m, "area", TYPE_STRING, "")
	_need(e, m, "camera", TYPE_STRING, "")
	_need(e, m, "sky_visible", TYPE_BOOL, "")
	if m.has("placeholder") and typeof(m["placeholder"]) != TYPE_BOOL:
		e.append("placeholder must be a bool")
	if not _vec3(m.get("focus_m")):
		e.append("focus_m must be an array of 3 numbers")
	if typeof(m.get("layers")) != TYPE_DICTIONARY:
		e.append("missing layers")
		return e
	var spec := {
		"panorama": {"file": TYPE_STRING, "parallax": TYPE_FLOAT},
		"play": {"file": TYPE_STRING, "iso_pitch_deg": TYPE_FLOAT, "iso_yaw_deg": TYPE_FLOAT, "iso_size_m": TYPE_FLOAT},
		"foreground": {"file": TYPE_STRING, "parallax": TYPE_FLOAT},
	}
	for layer: String in spec:
		var l: Variant = m["layers"].get(layer)
		if typeof(l) != TYPE_DICTIONARY:
			e.append("missing layer layers.%s" % layer)
			continue
		for k: String in spec[layer]:
			_need(e, l, k, spec[layer][k], "layers.%s." % layer)
	if not e.is_empty() or typeof(m["area"]) != TYPE_STRING:
		return e
	var a: String = m["area"]
	var want := {"panorama": "pano_%s.png" % a, "play": "play_%s.glb" % a, "foreground": "fg_%s.png" % a}
	for layer: String in want:
		if m["layers"][layer]["file"] != want[layer]:
			e.append("layers.%s.file %s != brief name %s" % [layer, m["layers"][layer]["file"], want[layer]])
	if m["camera"] != "cam_%s.json" % a:
		e.append("camera %s != brief name cam_%s.json" % [m["camera"], a])
	for layer in ["panorama", "foreground"]:
		var os: Variant = m["layers"][layer].get("overscan_px")
		if os != null and not (os is Array and os.size() == 2 and _num(os[0]) and _num(os[1])
				and os[0] >= 0 and os[1] >= 0 and float(os[0]) == floorf(os[0]) and float(os[1]) == floorf(os[1])):
			e.append("layers.%s.overscan_px must be [x, y] non-negative integers" % layer)
		if not (float(m["layers"][layer]["parallax"]) > 0.0):
			e.append("layers.%s.parallax must be > 0" % layer)
	if not (float(m["layers"]["play"]["iso_size_m"]) > 0.0):
		e.append("layers.play.iso_size_m must be > 0")
	return e


## Every schema problem of a cam_<area>.json dictionary (brief §5.2), empty when valid.
static func check_camera(c: Dictionary) -> PackedStringArray:
	var e := PackedStringArray()
	_need(e, c, "shot", TYPE_STRING, "camera.")
	_need(e, c, "frame", TYPE_STRING, "camera.")
	_need(e, c, "panorama", TYPE_STRING, "camera.")
	_need(e, c, "fov_vertical_deg", TYPE_FLOAT, "camera.")
	if c.get("frame") is String and c["frame"] != CAMERA_FRAME:
		e.append("camera.frame is not the ship frame contract: %s" % c["frame"])
	for k in ["position_m", "forward", "up"]:
		if not _vec3(c.get(k)):
			e.append("camera.%s must be an array of 3 numbers" % k)
	var r: Variant = c.get("resolution")
	if not (r is Array and r.size() == 2 and _num(r[0]) and _num(r[1]) and r[0] >= 1 and r[1] >= 1
			and float(r[0]) == floorf(r[0]) and float(r[1]) == floorf(r[1])):
		e.append("camera.resolution must be [width, height] positive integers")
	if c.get("fov_vertical_deg") is float and not (c["fov_vertical_deg"] > 0.0 and c["fov_vertical_deg"] < 180.0):
		e.append("camera.fov_vertical_deg must be in (0, 180)")
	if _vec3(c.get("forward")) and _vec3(c.get("up")):
		var f: Array = c["forward"]
		var u: Array = c["up"]
		if absf(_dot(f, f) - 1.0) > UNIT_TOL:
			e.append("camera.forward is not a unit vector (|f|^2 = %.6f)" % _dot(f, f))
		if absf(_dot(u, u) - 1.0) > UNIT_TOL:
			e.append("camera.up is not a unit vector (|u|^2 = %.6f)" % _dot(u, u))
		if absf(_dot(f, u)) > UNIT_TOL:
			e.append("camera.up is not orthogonal to forward (f.u = %.6f)" % _dot(f, u))
	return e


## Project a ship-frame point (metres) through a camera: [px, py, depth], pixels with the
## origin top-left and pixel centres at +0.5, depth along forward (<= 0: behind the camera).
## Real perspective, vertical sensor fit, no shift, no distortion (brief §5.2). Camera right
## is forward x up (Blender: looks down -Z, up +Y, right +X). float64.
static func project(cam: Dictionary, p: Array) -> PackedFloat64Array:
	var fur := _basis(cam)
	var f: Array = fur[0]
	var u: Array = fur[1]
	var r: Array = fur[2]
	var o: Array = cam["position_m"]
	var d := [float(p[0]) - o[0], float(p[1]) - o[1], float(p[2]) - o[2]]
	var depth := _dot(d, f)
	var t := tan(deg_to_rad(float(cam["fov_vertical_deg"])) / 2.0)
	var w := float(cam["resolution"][0])
	var h := float(cam["resolution"][1])
	var nx := _dot(d, r) / depth / (t * w / h)
	var ny := _dot(d, u) / depth / t
	return PackedFloat64Array([(nx + 1.0) * 0.5 * w, (1.0 - ny) * 0.5 * h, depth])


## The unit ship-frame ray through pixel (px, py): the inverse of project.
static func unproject(cam: Dictionary, px: float, py: float) -> PackedFloat64Array:
	var fur := _basis(cam)
	var f: Array = fur[0]
	var u: Array = fur[1]
	var r: Array = fur[2]
	var t := tan(deg_to_rad(float(cam["fov_vertical_deg"])) / 2.0)
	var w := float(cam["resolution"][0])
	var h := float(cam["resolution"][1])
	var nx := (2.0 * px / w - 1.0) * t * w / h
	var ny := (1.0 - 2.0 * py / h) * t
	var d := [f[0] + nx * r[0] + ny * u[0], f[1] + nx * r[1] + ny * u[1], f[2] + nx * r[2] + ny * u[2]]
	var n := sqrt(_dot(d, d))
	return PackedFloat64Array([d[0] / n, d[1] / n, d[2] / n])


## [forward, up, right] made exactly orthonormal in float64: cam_*.json carries float32
## roundings of an orthonormal Blender camera (check_camera bounds the rounding at UNIT_TOL),
## so project and unproject are exact inverses.
static func _basis(cam: Dictionary) -> Array:
	var f: Array = cam["forward"]
	var u: Array = cam["up"]
	var fn := sqrt(_dot(f, f))
	f = [f[0] / fn, f[1] / fn, f[2] / fn]
	var r := _cross(f, u)
	var rn := sqrt(_dot(r, r))
	r = [r[0] / rn, r[1] / rn, r[2] / rn]
	return [f, _cross(r, f), r]


static func _read_json(file: String, e: PackedStringArray, label: String) -> Variant:
	if not FileAccess.file_exists(file):
		e.append("missing %s (%s)" % [label, file])
		return null
	var j := JSON.new()
	if j.parse(FileAccess.get_file_as_string(file)) != OK:
		e.append("%s is not valid JSON: line %d: %s" % [label, j.get_error_line(), j.get_error_message()])
		return null
	if typeof(j.data) != TYPE_DICTIONARY:
		e.append("%s is not a JSON object" % label)
		return null
	return j.data


static func _need(e: PackedStringArray, d: Dictionary, k: String, type: int, prefix: String) -> void:
	if not d.has(k):
		e.append("missing %s%s" % [prefix, k])
	elif type == TYPE_FLOAT and not _num(d[k]):
		e.append("%s%s must be a number" % [prefix, k])
	elif type != TYPE_FLOAT and typeof(d[k]) != type:
		e.append("%s%s must be a %s" % [prefix, k, type_string(type)])
	elif type == TYPE_STRING and (d[k] as String).is_empty():
		e.append("%s%s must not be empty" % [prefix, k])


static func _num(v: Variant) -> bool:
	return (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and is_finite(float(v))


static func _vec3(v: Variant) -> bool:
	return v is Array and v.size() == 3 and _num(v[0]) and _num(v[1]) and _num(v[2])


static func _dot(a: Array, b: Array) -> float:
	return float(a[0]) * b[0] + float(a[1]) * b[1] + float(a[2]) * b[2]


static func _cross(a: Array, b: Array) -> Array:
	return [float(a[1]) * b[2] - float(a[2]) * b[1], float(a[2]) * b[0] - float(a[0]) * b[2], float(a[0]) * b[1] - float(a[1]) * b[0]]
