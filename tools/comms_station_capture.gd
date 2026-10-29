extends SceneTree
## R3-EARTH-LINK EL3b.5 review frames: the comms station at four moments of a real voyage, from the
## real sim at protocol 2.16 (seed 7, a consent crew aboard), laid out at the project's logical
## 960 x 540 and captured at 1280 x 720:
##   home     just committed at Sol for Alpha Centauri: live, in beam, real time, one plan on the strip
##   away     cruising out at 0.99c: home slows (the warm, near-still feed), Earth's hand crawls
##   waiting  arrived, re-planned for CNS5:1676 off Alpha Centauri's ray and flying: out of beam, the
##            last week under static, the ring, the strip's plan light home and the wait at the port
##   homeward on the way home from CNS5:1676 at 0.99c: the blue, jumbled torrent of weeks
## Each frame asserts the station is on screen, the frame is not blank, no two frames are alike,
## and every number on the station is a binding (DisplayBinding.audit).
## Run:  make capture-comms-station  (needs a GPU window; open every frame)

const OUT := "res://renders/comms_station"
const LOGICAL := Vector2i(960, 540)
const RES := Vector2i(1280, 720)
const ALPHA := {"index": 1, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}
const OFF_RAY := {"index": 2, "id": "CNS5:1676", "pos": {"x": -5.770603, "y": -6.237832, "z": -1.328845}}
const SOL := {"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}
const PHI := 2.6466524123622457 # 0.99c
const STEP := 0.02 # ship years per tick

var failures := 0
var frames := 0
var sim: SimBridge
var station: CommsStation
var hashes := {}


func _initialize() -> void:
	_run.call_deferred()


func fail(why: String) -> void:
	failures += 1
	print("comms-station-capture: FAIL %s" % why)


func phase() -> String:
	return str(sim.world.get("ship", {}).get("phase", ""))


func journey() -> Dictionary:
	return sim.world.get("journey", {}) if sim.world.get("journey") is Dictionary else {}


## Plan and commit a leg from here; true when committed.
func fly(target: Dictionary) -> bool:
	if not sim.send([{"k": "plan", "target": target, "cruise_phi": PHI}], 0.0):
		return false
	var id := int(journey().get("plan_id", 0))
	return sim.send([{"k": "commit", "plan_id": id}], 0.0) and str(journey().get("state", "")) == "committed"


## Halfway through the newest leg in galaxy time (the sim's sent_t and arrive_t).
func mid_leg() -> bool:
	var ms: Array = sim.world.get("earth", {}).get("messages", [])
	var t := float(sim.world.get("clock", {}).get("t", 0.0))
	return not ms.is_empty() and t >= 0.5 * (float(ms[-1].sent_t) + float(ms[-1].arrive_t))


## Tick until pred() or the cap; true when pred() holds.
func until(pred: Callable, cap := 20000) -> bool:
	for i in cap:
		if pred.call():
			return true
		if not sim.send([], STEP):
			return false
	return pred.call()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.content_scale_size = LOGICAL
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.size = RES
	var bg := ColorRect.new()
	bg.color = StapledonTheme.INK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	root.add_child(margin)
	station = CommsStation.new()
	margin.add_child(station)
	sim = SimBridge.new()
	sim.want_minor = SimBridge.EARTH_MINOR
	var ok := sim.start() and sim.new_game(7, "free_nav", false, {}, "", "consent")
	ok = ok and fly(ALPHA)
	if ok: await shoot("home")
	ok = ok and until(func() -> bool: return phase() == "cruising")
	ok = ok and until(func() -> bool: return phase() != "cruising" or float(sim.world.get("earth", {}).get("light_age_years", 0.0)) > 2.0)
	if ok: await shoot("away")
	ok = ok and until(func() -> bool: return str(journey().get("state", "")) == "arrived")
	ok = ok and fly(OFF_RAY)
	ok = ok and until(mid_leg)
	if ok and sim.world.get("earth", {}).get("in_beam", true):
		fail("the off-ray leg should fly out of beam")
	if ok: await shoot("waiting")
	ok = ok and until(func() -> bool: return str(journey().get("state", "")) == "arrived")
	ok = ok and fly(SOL)
	ok = ok and until(mid_leg)
	if ok: await shoot("homeward")
	if not ok:
		fail("the voyage stopped: %s %s %s" % [sim.last_error, sim.last_refused, journey().get("state", "")])
	sim.stop()
	print("comms-station-capture: %d frames, %d failures" % [frames, failures])
	quit(1 if failures else 0)


func shoot(label: String) -> void:
	var view := sim.world.duplicate(true)
	station.feed.begin_visit()
	station.refresh(view)
	for i in 4:
		station.advance(1.0 / 30.0)
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT, label]
	img.save_png(ProjectSettings.globalize_path(path))
	var e: Dictionary = view.get("earth", {})
	var h := str(hash(img.get_data()))
	if hashes.has(h):
		fail("%s duplicates %s" % [label, hashes[h]])
	hashes[h] = label
	var stats := _spread(img)
	if stats < 0.02:
		fail("%s is blank (spread %.3f)" % [label, stats])
	var unbound := DisplayBinding.audit(station)
	if not unbound.is_empty():
		fail("%s has unbound numbers %s" % [label, unbound])
	frames += 1
	print("  t %s |p| %s phase %s journey %s messages %s" % [view.get("clock", {}).get("t"), e.get("light_age_years"), phase(), journey().get("state"),
		(e.get("messages", []) as Array).map(func(m: Dictionary) -> Array: return [m.port_id, snappedf(m.sent_t, 0.01), snappedf(m.arrive_t, 0.01), snappedf(m.heard_t, 0.01), snappedf(m.reply_t, 0.01), snappedf(m.port_ly, 0.01)])])
	print("comms-station-capture: ok frame %s rate %s in_beam %s at_home %s messages %d out %s -> %s" % [label, e.get("rate"), e.get("in_beam"),
		e.get("at_home"), (e.get("messages", []) as Array).size(), (e.get("out") as Dictionary).get("reason") if e.get("out") is Dictionary else "-", path])


## The luminance spread over a coarse grid: a blank frame has none.
func _spread(img: Image) -> float:
	var lo := 1.0
	var hi := 0.0
	for y in range(0, img.get_height(), 24):
		for x in range(0, img.get_width(), 24):
			var l := img.get_pixel(x, y).get_luminance()
			lo = minf(lo, l)
			hi = maxf(hi, l)
	return hi - lo
