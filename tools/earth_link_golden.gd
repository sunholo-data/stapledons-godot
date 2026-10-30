extends RefCounted
## R3-EARTH-LINK EL5 golden G-EL-1 (design r3/earth-link.md EL5, AC10; make golden; main.gd loads it by
## path, tools/ is not exported). Earth's beams are a 2D overlay with no shader, so the golden is their
## projected geometry: EarthBeams draws its light-front markers and window rings (markers_only) on the
## GPU over a Camera3D's view, and each marker's rendered centroid must land within 0.5 px of a CPU
## reference computed independently in float64 from the sim fixture: the front's distance along its
## ray (clock.t - heard_t for Earth's beam, heard_t - clock.t for a plan on its way home, clamped to
## the line), SkyFrame.to_world64, then a pinhole projection from the camera's own pose and fov.
## Three fixture states (in transit after a re-plan, later on the same leg from an oblique camera,
## homeward); in each, Earth's beam front, the plan's front and the window ring: 9 cases.

const TOL_PX := 0.5
const SIZE := Vector2i(1280, 720)

var main: Node
var vp: SubViewport
var cam: Camera3D
var layer: EarthBeams
var overlay: Control


static func p(x: float, y: float, z: float) -> Dictionary:
	return {"x": x, "y": y, "z": z}


func states() -> Array:
	var transit := func(t: float, beam_port: Dictionary, wait: float) -> Dictionary:
		return {"clock": {"t": t}, "journey": {"state": "committed"}, "ship": {"pos": p(3.0, 2.0, 0.0)},
			"earth": {"in_beam": true, "beam": {"port_id": "A", "port": beam_port, "heard_t": 1.0},
				"pending": [{"port_id": "B", "port": p(0.0, 6.0, 0.0), "sent_t": 5.0, "heard_t": 9.37}],
				"messages": [{"port_id": "B", "from": p(4.37, 0.0, 0.0), "port": p(0.0, 6.0, 0.0), "sent_t": 5.0, "heard_t": 9.37}],
				"window": {"port": p(0.0, 6.0, 0.0), "from_t": 15.37, "wait_years": wait}}}
	var home := {"clock": {"t": 18.0}, "journey": {"state": "committed"}, "ship": {"pos": p(-4.0, -4.5, -0.9)},
		"earth": {"in_beam": true, "beam": {"port_id": "B", "port": p(-5.0, -6.0, -1.0), "heard_t": 9.0},
			"pending": [{"port_id": "Sol", "port": p(0.0, 0.0, 0.0), "sent_t": 16.5, "heard_t": 25.0}],
			"messages": [{"port_id": "Sol", "from": p(-5.770603, -6.237832, -1.328845), "port": p(0.0, 0.0, 0.0), "sent_t": 16.5, "heard_t": 25.0}],
			"window": {"port": p(0.0, 0.0, 0.0), "from_t": 25.0, "wait_years": 0.0}}}
	return [
		{"name": "transit", "view": transit.call(7.0, p(4.0, 0.0, 0.0), 2.5), "eye": Vector3(20, 6, -4), "at": Vector3(0, 2, -4)},
		{"name": "oblique", "view": transit.call(8.5, p(5.0, 1.0, 0.0), 0.0), "eye": Vector3(-14, 10, 12), "at": Vector3(-2, 2, 0)},
		{"name": "homeward", "view": home, "eye": Vector3(8, 4, 20), "at": Vector3(5, 0, 0)}]


func run(m: Node) -> int:
	main = m
	vp = SubViewport.new()
	vp.size = SIZE
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	main.add_child(vp)
	cam = Camera3D.new()
	cam.fov = 60.0
	vp.add_child(cam)
	cam.current = true
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.size = Vector2(SIZE)
	vp.add_child(bg)
	overlay = Control.new()
	overlay.size = Vector2(SIZE)
	vp.add_child(overlay)
	layer = EarthBeams.new()
	layer.markers_only = true
	overlay.add_child(layer)
	overlay.draw.connect(func() -> void: layer.draw_on(overlay, cam, func(g: Vector3) -> Vector3: return SkyFrame.to_world(g)))
	var f := 0
	for s: Dictionary in states():
		f += await _state(s)
	vp.queue_free()
	await main.get_tree().process_frame
	print("earth link golden: %d failures" % f)
	return f


func _state(s: Dictionary) -> int:
	cam.look_at_from_position(s.eye, s.at, Vector3.UP)
	layer.refresh(s.view)
	overlay.queue_redraw()
	for i in 3:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	var e: Dictionary = s.view.earth
	var t := float(s.view.clock.t)
	var beam_port := _arr(e.beam.port)
	var m: Dictionary = e.messages[0]
	var from := _arr(m.from)
	var cases := [
		["Earth's beam front", _scale(beam_port, (t - float(e.beam.heard_t)) / _norm(beam_port)), 10],
		["plan's front home", _scale(from, clampf(float(m.heard_t) - t, 0.0, _norm(from)) / _norm(from)), 10],
		["window ring", _arr(e.window.port), 22]]
	var f := 0
	for c: Array in cases:
		var want := _project(SkyFrame.to_world64(c[1]))
		var got := _centroid(img, want, int(c[2]))
		var d := got.distance_to(want) if got.x >= 0.0 else INF
		var ok := d <= TOL_PX
		print("%s  G-EL-1 %s %s: GPU (%.2f, %.2f) CPU (%.2f, %.2f) d = %.3f px" % ["ok   " if ok else "FAIL ", s.name, c[0], got.x, got.y, want.x, want.y, d])
		f += 0 if ok else 1
	if s.name == "transit": # negative control: a reference 0.05 ly further along the beam must miss
		var off := _project(SkyFrame.to_world64(_scale(beam_port, (t - float(e.beam.heard_t) + 0.05) / _norm(beam_port))))
		var miss := _centroid(img, off, 10).distance_to(off) > TOL_PX
		print("%s  G-EL-1 mutant: a front 0.05 ly off is caught" % ("ok   " if miss else "FAIL "))
		f += 0 if miss else 1
	return f


## The float64 pinhole: the camera's pose and vertical fov (keep height), pixels from the top left.
func _project(w: PackedFloat64Array) -> Vector2:
	var b := cam.global_transform.basis
	var o := cam.global_transform.origin
	var d := [w[0] - float(o.x), w[1] - float(o.y), w[2] - float(o.z)]
	var fwd := [-float(b.z.x), -float(b.z.y), -float(b.z.z)]
	var r := [float(b.x.x), float(b.x.y), float(b.x.z)]
	var u := [float(b.y.x), float(b.y.y), float(b.y.z)]
	var depth := _dot(d, fwd)
	var tn := tan(deg_to_rad(float(cam.fov)) / 2.0)
	var wpx := float(SIZE.x)
	var hpx := float(SIZE.y)
	var nx := _dot(d, r) / depth / (tn * wpx / hpx)
	var ny := _dot(d, u) / depth / tn
	return Vector2((nx + 1.0) * 0.5 * wpx, (1.0 - ny) * 0.5 * hpx)


## The luminance-weighted centroid of the lit pixels within r px of at (pixel centres at +0.5).
func _centroid(img: Image, at: Vector2, r: int) -> Vector2:
	var sx := 0.0
	var sy := 0.0
	var sw := 0.0
	for y in range(int(at.y) - r, int(at.y) + r + 1):
		for x in range(int(at.x) - r, int(at.x) + r + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var l := img.get_pixel(x, y).get_luminance()
			if l > 0.02:
				sx += l * (x + 0.5)
				sy += l * (y + 0.5)
				sw += l
	return Vector2(sx / sw, sy / sw) if sw > 0.0 else Vector2(-1, -1)


static func _arr(d: Dictionary) -> Array:
	return [float(d.x), float(d.y), float(d.z)]


static func _norm(a: Array) -> float:
	return sqrt(_dot(a, a))


static func _dot(a: Array, b: Array) -> float:
	return float(a[0]) * b[0] + float(a[1]) * b[1] + float(a[2]) * b[2]


static func _scale(a: Array, k: float) -> Array:
	return [float(a[0]) * k, float(a[1]) * k, float(a[2]) * k]
