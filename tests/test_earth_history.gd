extends SceneTree
## R3-COMMS-V2 CV2 (design r3/comms-station-v2.md §D1.4, §D1.6, AC5, AC6): the history wall and the
## frame diagram at the comms station, on the real sim at 2.17 (seed 7: Sol to Alpha Cen A at 0.99c, a
## wait, the off-ray leg out of beam). make comms-history-test (in make ui).
##   wall     the wall holds exactly the sim's records; x follows arrived.tau (monotone) and nothing is
##            placed after the ship's clock; static only where records came unbeamed; every stamp a
##            binding (the display audit finds nothing unbound)
##   select   selecting a beamed week pins it in the feed and turns the strip to frame mode; selecting
##            it again (or an unbeamed record) returns both; Escape deselects
##   diagram  frame mode on equal axes: the light from the send event to the arrival runs at 45 degrees
##            (|dx| = |dy| in pixels); its numbers are bindings on the record's fields
##   stacks   (D1.3) homeward at 0.99c several weeks arrive in a ship day: selecting such a stack asks the
##            sim for its weeks (earth_weeks, at most 52, the newest); the sim's answer lists only beamed,
##            arrived weeks, each dated epoch + frame x week; each week is selectable, and the feed, the
##            stack's stamp and the diagram's send label then carry that week's own Earth date (bindings)
##   stamps   a picture's Earth stamp is its own week's date (earth_year), not the stack's first week's
##   guards   the wall never opens an AI request; the frame inset never reads Earth's current beam
## The test compares sim fields with what is placed; it computes nothing the game would show.

const ALPHA := {"index": 1, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}
const OFF_RAY := {"index": 2, "id": "CNS5:1676", "pos": {"x": -5.770603, "y": -6.237832, "z": -1.328845}}
const PHI := 2.6466524123622457
const SOL := {"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}
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


func voyage() -> bool:
	sim = SimBridge.new()
	sim.want_minor = SimBridge.EARTH_LOG_MINOR
	var ok := sim.start() and sim.new_game(7, "free_nav", false, {}, "", "") and fly(ALPHA)
	var n := 0
	while ok and n < 400 and str(journey().get("state", "")) != "arrived":
		ok = sim.send([], 0.004)
		n += 1
	for i in 60:
		ok = ok and sim.send([], 0.004)
	ok = ok and fly(OFF_RAY)
	for i in 80:
		ok = ok and sim.send([], 0.004)
	return ok


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var ok := voyage()
	check("the real voyage ran (%s)" % sim.last_error, ok)
	var view := sim.world.duplicate(true)
	var station := CommsStation.new()
	station.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(station)
	station.refresh(view)
	for i in 3:
		await process_frame
	var h := station.history
	var recs: Array = view.earth_log.records
	check("wall: it holds exactly the sim's records (%d)" % recs.size(), h.records == recs and h.visible)
	var mono := true
	var past := true
	var now_x := h.tx(float(view.clock.tau))
	for k in range(1, recs.size()):
		mono = mono and h.tx(float(recs[k].arrived.tau)) >= h.tx(float(recs[k - 1].arrived.tau))
	for r: Dictionary in recs:
		past = past and h.tx(float(r.arrived.tau)) <= now_x + 1e-6
	check("wall: x follows arrived.tau, oldest left", mono)
	check("wall: nothing placed after the ship's clock", past)
	var unbeamed := recs.filter(func(r: Dictionary) -> bool: return r.beamed != true)
	check("wall: the off-ray leg's weeks are unbeamed (static), the outbound weeks beamed", not unbeamed.is_empty() and recs[1].beamed == true)
	var bad := DisplayBinding.audit(station)
	check("wall: every number on the station is a binding (%s)" % [bad.map(func(n: Node) -> String: return n.text)], bad.is_empty())
	check("wall: stamps drawn for the pictures in full", h._stamps.filter(func(b: ComposedBinding) -> bool: return b.visible).size() >= 2)
	# select a beamed week (outbound week 1)
	var k := 1
	h.select(k)
	station.refresh(view)
	await process_frame
	check("select: the feed pins the week and the strip turns to frame mode", station.feed.pinned == k and station.strip.frame == k and h.selected == k)
	check("select: the feed shows the week's words", station.feed.caption.text == str(recs[k].feed.event.words))
	var box := station.strip._frame_box()
	var sent := station.strip.eq(box, Vector2(float(recs[k].sent.t), 0.0))
	var hit := station.strip.eq(box, Vector2(float(recs[k].arrived.t), float(recs[k].arrived.ly)))
	check("diagram: light at 45 degrees on equal axes (dx %.3f, dy %.3f)" % [hit.x - sent.x, sent.y - hit.y], absf(absf(hit.x - sent.x) - absf(sent.y - hit.y)) < 1e-3)
	bad = DisplayBinding.audit(station)
	check("diagram: its numbers are bindings (%s)" % [bad.map(func(n: Node) -> String: return n.text)], bad.is_empty() and station.strip.tags[2].visible and station.strip.inset.visible)
	check("diagram: x D is the record's arrival rate", station.strip.tags[2].field == "earth_log.records.%d.arrived.rate" % k)
	h.select(k)
	station.refresh(view)
	check("select: selecting it again returns the live feed and the strip", station.feed.pinned == -1 and station.strip.frame == -1 and not station.strip.inset.visible)
	h.select(recs.find(unbeamed[0]))
	check("select: an unbeamed record cannot be selected", h.selected == -1)
	h.select(k)
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	h._gui_input(esc)
	check("select: Escape deselects", h.selected == -1 and station.feed.pinned == -1)
	check("stamps: a picture's Earth stamp is its own week's date (earth_year)", h._stamps[0].field.ends_with(".earth_year"))
	await stacks(station)
	sim.stop()
	var src := FileAccess.get_file_as_string("res://ui/earth_history.gd")
	check("guard: the wall never opens an AI request", not src.contains(".open(") and not src.contains("live_source"))
	var strip_src := FileAccess.get_file_as_string("res://ui/earth_strip.gd")
	var inset_src := strip_src.substr(strip_src.find("class FrameInset"))
	check("guard: the frame inset never reads Earth's current beam", not inset_src.contains("earth.beam") and not inset_src.contains("\"beam\""))
	print("comms-history: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


## D1.3: homeward, a stack's weeks through the sim's earth_weeks.
func stacks(station: CommsStation) -> void:
	sim.stop() # a second voyage: out to Alpha Cen A and straight home along Earth's beam
	sim = SimBridge.new()
	sim.want_minor = SimBridge.EARTH_LOG_MINOR
	var ok := sim.start() and sim.new_game(7, "free_nav", false, {}, "", "") and fly(ALPHA)
	var n := 0
	while ok and n < 400 and str(journey().get("state", "")) != "arrived":
		ok = sim.send([], 0.004)
		n += 1
	ok = ok and fly(SOL)
	for i in 120:
		ok = ok and sim.send([], 0.004)
	check("stacks: the homeward leg ran (rate %s, in beam %s)" % [sim.world.get("earth", {}).get("rate"), sim.world.get("earth", {}).get("in_beam")], ok and float(sim.world.earth.rate) > 1.0)
	var recs: Array = sim.world.earth_log.records
	var k := -1
	for i in range(recs.size() - 1, -1, -1):
		if recs[i].beamed == true and int(recs[i].to_frame) > int(recs[i].from_frame):
			k = i
			break
	check("stacks: homeward, a beamed record holds several weeks (record %d)" % k, k >= 0)
	if k < 0:
		return
	var asked := []
	station.weeks_requested.connect(func(a: int, b: int) -> void: asked.append([a, b]))
	station.refresh(sim.world.duplicate(true))
	station.history.select(k)
	var r: Dictionary = recs[k]
	var want := [maxi(int(r.from_frame), int(r.to_frame) - 51), int(r.to_frame)]
	check("stacks: selecting it asks the sim for its newest weeks %s (asked %s)" % [want, asked], asked.size() == 1 and asked[0] == want and station.stack.visible)
	ok = sim.send([{"k": "earth_weeks", "from": want[0], "to": want[1]}], 0.0)
	var v := sim.world.duplicate(true)
	var ew: Dictionary = v.get("earth_weeks", {})
	var rows: Array = ew.get("weeks", [])
	var wy := float(v.earth_log.week_years)
	var dated := true
	var clipped := true
	var newest := int(v.earth.feed.frame)
	for row: Dictionary in rows:
		dated = dated and absf(float(row.earth_year) - float(row.frame) * wy) <= 1e-9 * maxf(1.0, float(row.earth_year))
		clipped = clipped and int(row.frame) >= want[0] and int(row.frame) <= want[1] and int(row.frame) <= newest
	check("stacks: the sim answers %d weeks, every one in the stack, arrived, at most 52" % rows.size(), ok and rows.size() == want[1] - want[0] + 1 and rows.size() <= 52 and clipped)
	check("stacks: each week dated epoch + frame x week (its own Earth date)", dated and not rows.is_empty())
	var past := sim.send([{"k": "earth_weeks", "from": newest + 1, "to": newest + 400}], 0.0)
	check("stacks: weeks not yet arrived are never answered (D-68)", past and (sim.world.get("earth_weeks", {}).get("weeks", [1]) as Array).is_empty())
	station.refresh(v)
	await process_frame
	check("stacks: the stack shows the sim's weeks", station.stack.rows.size() == rows.size())
	var j := rows.size() / 2 if rows.size() > 1 else 0
	station.stack.pick(j)
	station.refresh(v)
	await process_frame
	var path := "earth_weeks.weeks.%d.earth_year" % j
	check("stacks: the picked week's Earth date on the feed (%s)" % station.feed.signal_tag.field, station.feed.signal_tag.field == path and station.feed.pinned_week == j)
	check("stacks: the stack's stamp and the diagram's send label carry the same week's date", station.stack.stamp != null and station.stack.stamp.field == path and station.strip.tags[0].field == path)
	check("stacks: the feed shows that week's words", station.feed.caption.text == str(rows[j].event.words))
	var bad := DisplayBinding.audit(station)
	check("stacks: every number a binding (%s)" % [bad.map(func(n: Node) -> String: return n.text)], bad.is_empty())
