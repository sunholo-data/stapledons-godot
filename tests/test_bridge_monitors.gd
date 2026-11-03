extends SceneTree
## R3-COMMS-V2 CV6 (design r3/comms-station-v2.md §D3-§D5, AC8): the bridge's ambient monitors.
## make bridge-monitors-test (headless).
##   build    the manifest's four monitors (clocks, signal, course, crew) at their anchors on the bow
##            rail, each face turned to the deck, each screen a camera occluder (it fades like a frond)
##   bound    on the real sim at 2.17 (seed 7: outbound at 0.99c, then off Earth's beam), every number
##            on every face is a binding (the display audit finds nothing unbound) and the faces follow
##            the world (Earth or no signal; the target; the crew's feelings)
##   gated    a face renders only while its screen is on screen; off screen the signal face does no
##            work (no refresh, no waterfall column, its taps stopped); on screen it refreshes at 30 Hz,
##            the clocks at 10 Hz
##   bed      the ambient bed comes from the frame's sim fields (EarthFeed.bed_of), no station needed
## The test compares the faces with sim fields; it computes nothing the game would show.

const ALPHA := {"index": 1, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}
const OFF_RAY := {"index": 2, "id": "CNS5:1676", "pos": {"x": -5.770603, "y": -6.237832, "z": -1.328845}}
const PHI := 2.6466524123622457
var failures := 0
var passes := 0
var sim: SimBridge


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func journey() -> Dictionary:
	return sim.world.get("journey", {}) if sim.world.get("journey") is Dictionary else {}


func fly(target: Dictionary) -> bool:
	if not sim.send([{"k": "plan", "target": target, "cruise_phi": PHI}], 0.0):
		return false
	return sim.send([{"k": "commit", "plan_id": int(journey().get("plan_id", 0))}], 0.0)


func faces_ok(mons: Array[BridgeMonitor], view: Dictionary, label: String) -> void:
	for m in mons:
		m.refresh(view, true, "")
		m.face.refresh(view, true, "")
	var bad: Array = []
	for m in mons:
		bad.append_array(DisplayBinding.audit(m.face))
	check("%s: every number on the four faces is a binding (%s)" % [label, bad.map(func(n: Node) -> String: return n.text)], bad.is_empty())


func _run() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ship_demo/manifest.json"))
	var spec: Dictionary = manifest.get("monitors", {}).duplicate()
	spec.erase("about")
	var holder := Node3D.new()
	root.add_child(holder)
	var mons := BridgeMonitor.build(holder, spec)
	check("build: four monitors from the manifest", mons.size() == 4)
	check("build: faces clocks, signal, course, crew", mons.map(func(m: BridgeMonitor) -> String: return m.kind) == ["clocks", "signal", "course", "crew"])
	var placed := true
	for m in mons:
		var c: Array = spec[m.id].screen_ship_m
		placed = placed and m.position.is_equal_approx(Vector3(float(c[0]), float(c[2]), -float(c[1])))
		var to_deck := (Vector3(0.0, m.position.y, -6.0) - m.position).normalized()
		placed = placed and m.global_transform.basis.z.normalized().dot(to_deck) > 0.999
	check("build: at the manifest's anchors, each face turned to the deck", placed)
	check("build: every screen is a camera occluder", mons.all(func(m: BridgeMonitor) -> bool: return m.quad.is_in_group(CameraDirector.OCCLUDER_GROUP)))
	sim = SimBridge.new()
	sim.want_minor = SimBridge.EARTH_LOG_MINOR
	var ok := sim.start() and sim.new_game(7, "free_nav", false, {}, "", "consent") and fly(ALPHA)
	for i in 80:
		ok = ok and sim.send([], 0.004)
	check("sim: the voyage ran (%s)" % sim.last_error, ok)
	var out := sim.world.duplicate(true)
	faces_ok(mons, out, "outbound")
	var sig: BridgeScreens.SignalFace = mons[1].face
	check("follow: outbound, the signal face reads Earth (in beam)", out.earth.in_beam == true and sig.tag.text == EarthFeed.format("feed_signal", true))
	var course: BridgeScreens.CourseFace = mons[2].face
	check("follow: the course face names the target", course.target.text == str(out.journey.plan.target.id))
	check("follow: the course face shows the ship time left, bound to course.ship_years_left (OQ12)", course.left.visible and course.left.field == "course.ship_years_left" and float(out.course.ship_years_left) > 0.0)
	var crew: BridgeScreens.CrewFace = mons[3].face
	check("follow: the crew face shows each member's feeling", crew.faces.get_child_count() == (out.earth.crew as Array).size())
	n_arrive(ok)
	ok = ok and fly(OFF_RAY)
	for i in 120:
		ok = ok and sim.send([], 0.004)
	var off := sim.world.duplicate(true)
	sim.stop()
	faces_ok(mons, off, "off the beam")
	check("follow: off the beam, the signal face reads no signal", off.earth.in_beam == false and sig.tag.text == EarthFeed.format("feed_signal", false))
	# gated rendering
	var m: BridgeMonitor = mons[0]
	m.on_screen = false
	m._process(0.2)
	check("gated: off screen, the face does not render", m.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED)
	m.on_screen = true
	m._process(0.2)
	check("gated: on screen, the face renders", m.viewport.render_target_update_mode == SubViewport.UPDATE_ONCE)
	# the signal monitor off screen does no work (Codex review): no refresh, no column, no tap
	var sm: BridgeMonitor = mons[1]
	sm.set_process(false)
	var wf: CommsWaterfall = (sm.face as BridgeScreens.SignalFace).wf
	sm.refresh(out, false, EarthFeed.bed_of(out)) # in beam, True: the taps would play
	sm.on_screen = true
	for i in 30:
		sm._process(1.0 / 120.0)
		await process_frame
	check("gated: on screen in beam, the signal plays its taps (carrier playing %s)" % wf._carrier.playing, wf._carrier.playing)
	sm.on_screen = false
	var r0 := sm.refreshes
	var s0 := wf.steps
	for i in 120:
		sm._process(1.0 / 120.0)
		await process_frame
	check("gated: off screen, 120 frames: %d refreshes, %d waterfall columns, carrier playing %s" % [sm.refreshes - r0, wf.steps - s0, wf._carrier.playing], sm.refreshes == r0 and wf.steps == s0 and not wf._carrier.playing and not wf._bed.playing and not wf.is_processing())
	sm.on_screen = true
	r0 = sm.refreshes
	s0 = wf.steps
	for i in 240: # two seconds at 120 frames a second
		sm._process(1.0 / 120.0)
	check("gated: on screen at 120 fps for 2 s the signal face refreshes at 30 Hz (%d refreshes, %d columns; want 60, plus one on coming into view)" % [sm.refreshes - r0, wf.steps - s0], sm.refreshes - r0 == 61 and wf.steps - s0 == 61)
	var cm: BridgeMonitor = mons[0]
	cm.set_process(false)
	cm.on_screen = true
	r0 = cm.refreshes
	for i in 240:
		cm._process(1.0 / 120.0)
	check("gated: the clocks face refreshes at 10 Hz (%d in 2 s; want 20)" % (cm.refreshes - r0), cm.refreshes - r0 == 20)
	sm.on_screen = false
	check("bed: the ambient bed comes from the frame alone (outbound in beam: %s)" % EarthFeed.bed_of(out), not EarthFeed.bed_of(out).is_empty() and EarthFeed.bed_of(off) == str(EarthFeed.copy().sound.beds.static))
	print("bridge-monitors: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func n_arrive(ok: bool) -> void:
	var n := 0
	while ok and n < 400 and str(journey().get("state", "")) != "arrived":
		ok = sim.send([], 0.004)
		n += 1
