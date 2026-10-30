extends SceneTree
## R3-EARTH-LINK EL4 (F6; design r3/earth-link.md EL4, AC12): Earth's beams on the galaxy map.
## make earth-beams-test (in make ui).
##   fixtures  every element from its earth.* field: the heard beam through its port and on, its
##             light-front at clock.t - heard_t; a plan in flight home, its front heard_t - clock.t
##             from Sol along the line it was sent from; a stale beam; the wait at the port (open or
##             not); the silence ring; every number a binding
##   AC12      while a plan is uncommitted the layer reads earth.preview and nothing else of earth.*
##   project   the elements land where the camera puts their sim positions; behind it, nothing
##   real sim  through GalaxyMap at protocol 2.16: the preview while planning, the beam and the window
##             once committed; below 2.16 no earth section and nothing drawn

var failures := 0
var passes := 0
const ALPHA := {"index": 1, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func p(x: float, y: float, z: float) -> Dictionary:
	return {"x": x, "y": y, "z": z}


## In transit to B after a re-plan at A: Earth still aims at A (stale until it hears the new plan),
## the plan to B is in flight home, the ship is out of beam, and it will wait at B.
func transit() -> Dictionary:
	return {"tick": 9, "clock": {"t": 7.0, "tau": 2.0}, "journey": {"state": "committed"}, "ship": {"pos": p(4.6, 0.8, 0.0)},
		"earth": {"in_beam": false, "last_beam_t": 3.0, "last_beam_year": 3.0, "rate": 0.07,
			"beam": {"port_id": "A", "port": p(4.0, 0.0, 0.0), "heard_t": 1.0, "heard_year": 1.0},
			"pending": [{"port_id": "B", "port": p(0.0, 6.0, 0.0), "sent_t": 5.0, "heard_t": 9.37, "heard_year": 9.37}],
			"stale": [{"port_id": "A", "port": p(4.0, 0.0, 0.0), "until_t": 9.37, "until_year": 9.37}],
			"window": {"port": p(0.0, 6.0, 0.0), "from_t": 15.37, "wait_years": 2.5},
			"messages": [{"plan_id": 2, "port_id": "B", "from": p(4.37, 0.0, 0.0), "port": p(0.0, 6.0, 0.0), "sent_t": 5.0, "heard_t": 9.37}],
			"preview": {"port": p(9.0, 9.0, 9.0), "wait_years": 99.0, "would_stale": null}}}


func near(a: Variant, b: Vector3) -> bool:
	return a is Vector3 and (a as Vector3).distance_to(b) < 1e-6


func of(layer: EarthBeams, kind: String) -> Array:
	return layer.elements.filter(func(e: Dictionary) -> bool: return e.kind == kind)


func shown(layer: EarthBeams) -> Array:
	return layer.get_children().filter(func(n: Node) -> bool: return n is ComposedBinding and (n as Control).visible).map(func(n: Node) -> String: return (n as Label).text)


func _run() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	get_root().add_child(host)
	var layer := EarthBeams.new()
	host.add_child(layer)
	var far := float(EarthBeams.copy().far)

	var v := transit()
	layer.refresh(v)
	var beam: Array = of(layer, "beam")
	check("the heard beam: Sol through its port and on to %.1f times its distance" % far, beam.size() == 1 and near(beam[0].a, Vector3.ZERO) and near(beam[0].b, Vector3(4, 0, 0) * far))
	check("its light-front at clock.t - heard_t = 6 ly along the ray", near(beam[0].front, Vector3(6, 0, 0)))
	var pend: Array = of(layer, "pending")
	check("the plan in flight home: dashed Sol -> its port", pend.size() == 1 and pend[0].dashed and near(pend[0].b, Vector3(0, 6, 0)))
	check("its light-front heard_t - clock.t = 2.37 ly from Sol, on the line it was sent from", near(pend[0].front, Vector3(2.37, 0, 0)))
	var st: Array = of(layer, "stale")
	check("the stale beam to the port the ship left", st.size() == 1 and near(st[0].b, Vector3(4, 0, 0) * far) and not st[0].dashed)
	check("Earth's beam is that stale beam: drawn faded, once (the beam's line, the stale row's label)", beam[0].left == true and st[0].line == false)
	var w: Array = of(layer, "window")
	check("the wait at the leg's port, not open", w.size() == 1 and near(w[0].a, Vector3(0, 6, 0)) and w[0].open == false)
	check("out of beam: the silence ring at clock.t - last_beam_t = 4 ly", of(layer, "silence").size() == 1 and is_equal_approx(layer.silence_radius, 4.0))
	check("not planning: the preview is not read", not layer.read.has("preview") and of(layer, "preview").is_empty())
	var texts := shown(layer)
	check("labels: the plan's arrival home, the stale beam's end, the wait, the silence (%s)" % [texts],
		texts == ["→ Earth +9.37 yr", "empty until Earth +9.37 yr", "wait 2.50 yr", "silent since Earth +3.00 yr"])
	check("every number on the layer is a binding", DisplayBinding.audit(layer).is_empty())

	v.earth.window.wait_years = 0.0
	v.earth.in_beam = true
	layer.refresh(v)
	check("Earth's light arrives first: the window is open and says nothing", of(layer, "window")[0].open == true and not shown(layer).has("wait 2.50 yr") and of(layer, "silence").is_empty())

	# AC12: planning reads only earth.preview, however much else the section carries
	var pl := transit()
	pl.journey.state = "planned"
	pl.earth.preview = {"port": p(0.0, 0.0, 40.0), "wait_years": 60.0, "would_stale": {"port_id": "A", "port": p(4.0, 0.0, 0.0), "until_t": 12.0, "until_year": 12.0}}
	layer.refresh(pl)
	check("AC12: while a plan is uncommitted only earth.preview is read (%s)" % [layer.read], layer.read == ["preview"])
	check("the preview: the dashed line to its port and the beam the commit would leave stale", layer.elements.map(func(e: Dictionary) -> String: return e.kind) == ["preview", "stale"] and near(layer.elements[0].b, Vector3(0, 0, 40)))
	check("its labels: the wait and the would-be stale beam's end (%s)" % [shown(layer)], shown(layer) == ["wait 60.00 yr", "empty until Earth +12.00 yr"] and DisplayBinding.audit(layer).is_empty())
	pl.earth.preview = {"port": p(0.0, 0.0, 40.0), "wait_years": 0.0, "would_stale": null}
	layer.refresh(pl)
	check("a covered plan: the line alone, no wait, nothing left stale", layer.elements.size() == 1 and shown(layer).is_empty())
	pl.earth.preview = null
	layer.refresh(pl)
	check("planning with no preview: nothing, and still nothing else read", layer.elements.is_empty() and layer.read == ["preview"])
	layer.refresh({"tick": 1, "clock": {"t": 1.0}, "journey": {"state": "committed"}})
	check("below 2.16 (no earth section): nothing drawn, no labels", layer.elements.is_empty() and shown(layer).is_empty())

	# project: the elements land where the camera puts their positions
	var cam := Camera3D.new()
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	get_root().add_child(vp)
	vp.add_child(cam)
	cam.position = Vector3(0, 0, 30)
	cam.current = true
	await process_frame
	layer.refresh(transit())
	var id := func(x: Vector3) -> Vector3: return x
	var rows := layer.project(cam, id)
	var bp: Array = rows.filter(func(r: Dictionary) -> bool: return r.kind == "beam")
	check("projected: the beam from Sol's pixel to its far end's", bp.size() == 1 and (bp[0].a as Vector2).distance_to(cam.unproject_position(Vector3.ZERO)) < 0.01 and (bp[0].b as Vector2).distance_to(cam.unproject_position(Vector3(4, 0, 0) * far)) < 0.01)
	check("projected: the front on the beam's line", bp[0].front != null and (bp[0].front as Vector2).distance_to(cam.unproject_position(Vector3(6, 0, 0))) < 0.01)
	cam.position = Vector3(0, 0, -30) # looking away (-z): everything is behind
	cam.look_at(Vector3(0, 0, -60))
	await process_frame
	check("behind the camera nothing is projected", layer.project(cam, id).is_empty())
	vp.queue_free()

	await _real_sim(host)
	host.queue_free()
	await process_frame
	print("earth-beams: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


## Through GalaxyMap on the real sim: plan Alpha Centauri from Earth (the preview), commit (a plan
## made at home is heard at once: the beam, and an open window); then a 2.15 session draws nothing.
func _real_sim(host: Control) -> void:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.EARTH_MINOR
	if not sim.start() or not sim.new_game(7, "free_nav", false, {}, "", "consent"):
		check("the real sim starts at 2.16 (%s)" % sim.last_error, false)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	host.add_child(vp)
	var map := GalaxyMap.new()
	map.auto_tick = false
	vp.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	map.attach(sim)
	check("the map has Earth's beams on by default, with its toggle", map.earth_beams.visible and map.earth_toggle.button_pressed and map.earth_beams.get_parent() != null)
	sim.send([{"k": "plan", "target": ALPHA, "cruise_phi": 2.6466524123622457}], 0.0)
	map.refresh()
	check("planning on the real sim: only the preview is read (%s)" % [map.earth_beams.read], map.journey_state() == "planned" and map.earth_beams.read == ["preview"] and of(map.earth_beams, "preview").size() == 1)
	check("a plan from home is covered: no wait, nothing stale (%s)" % [sim.world.earth.get("preview")], of(map.earth_beams, "stale").is_empty() and shown(map.earth_beams).is_empty())
	sim.send([{"k": "commit", "plan_id": int(sim.world.journey.plan_id)}], 0.0)
	sim.send([], 0.02)
	map.refresh()
	var kinds: Array = map.earth_beams.elements.map(func(e: Dictionary) -> String: return e.kind)
	check("committed: Earth's beam to Alpha Centauri and an open window (%s)" % [kinds], kinds.has("beam") and kinds.has("window") and of(map.earth_beams, "window")[0].open and not kinds.has("preview"))
	check("the beam's port is the sim's", near(of(map.earth_beams, "beam")[0].get("at"), Vector3(3.094521, -3.015404, -0.051608)))
	check("every number on the map's beams is a binding", DisplayBinding.audit(map.earth_beams).is_empty())
	map.set_earth_beams_visible(false)
	check("the toggle hides the layer and its legend (a display control)", not map.earth_beams.visible and not map.earth_legend.visible and map.earth_beams.draw_on(Control.new(), map.camera, func(x: Vector3) -> Vector3: return x) == 0)
	sim.stop()
	var old := SimBridge.new()
	old.want_minor = SimBridge.EARTH_MINOR - 1
	if old.start() and old.new_game(7, "free_nav", false):
		map.attach(old)
		old.send([{"k": "plan", "target": ALPHA, "cruise_phi": 2.6466524123622457}], 0.0)
		map.refresh()
		check("below 2.16: no earth section, nothing drawn", not old.world.has("earth") and map.earth_beams.elements.is_empty())
	else:
		check("a 2.15 session starts (%s)" % old.last_error, false)
	old.stop()
	vp.queue_free()
	await process_frame
