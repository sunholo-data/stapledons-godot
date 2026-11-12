extends SceneTree
## R3-COMMS-V2 CV1 (design r3/comms-station-v2.md §D1.2, AC2, AC4): the bridge keeps the 2.18
## received-frame log. make comms-log-bridge-test (in make test).
##   tail    take_earth_log_tail files a tick's open record by from_frame: the same from_frame
##           replaces the newest record, a new one is appended, and nothing is filed without a
##           full-state log (synthetic dictionaries)
##   voyage  the real sim at 2.18 (seed 7): Sol to Alpha Cen A at 0.99c, a wait, the start of the
##           off-ray leg. At every tick the stored records run contiguously from week 0, the newest
##           ends at earth.feed.frame, no record arrived after the ship's clock, and each send event is
##           on the light cone (sent.t = arrived.t - arrived.ly, the sim's fields)
## Every value read here is the sim's; the test compares fields with each other, it computes nothing
## the game would show.

const ALPHA := {"index": 2, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}
const OFF_RAY := {"index": 9, "id": "CNS5:1676", "pos": {"x": -5.770603, "y": -6.237832, "z": -1.328845}}
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


func _run() -> void:
	test_tail()
	test_voyage()
	print("comms-log-bridge: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func rec(from: int, to: int) -> Dictionary:
	return {"from_frame": from, "to_frame": to}


func test_tail() -> void:
	var w := {"earth_log": {"records": [rec(0, 0), rec(1, 3)]}}
	SimBridge.take_earth_log_tail(w, [rec(1, 5)])
	check("tail: the same from_frame replaces the open record", w.earth_log.records.size() == 2 and int(w.earth_log.records[-1].to_frame) == 5)
	SimBridge.take_earth_log_tail(w, [rec(6, 6)])
	check("tail: a new from_frame is appended", w.earth_log.records.size() == 3 and int(w.earth_log.records[-1].from_frame) == 6)
	var bare := {}
	SimBridge.take_earth_log_tail(bare, [rec(0, 0)])
	check("tail: never filed without a full-state log", not bare.has("earth_log"))
	SimBridge.take_earth_log_tail(w, null)
	check("tail: no tail, no change", w.earth_log.records.size() == 3)


func journey() -> Dictionary:
	return sim.world.get("journey", {}) if sim.world.get("journey") is Dictionary else {}


func fly(target: Dictionary) -> bool:
	if not sim.send([{"k": "plan", "target": target, "cruise_phi": PHI}], 0.0):
		return false
	return sim.send([{"k": "commit", "plan_id": int(journey().get("plan_id", 0))}], 0.0)


## The stored log against the sim's own fields at this tick; "" when it holds.
func log_fault() -> String:
	var lg: Variant = sim.world.get("earth_log")
	if not lg is Dictionary:
		return "no earth_log"
	var recs: Array = lg.get("records", [])
	if recs.is_empty():
		return "no records"
	var next := 0
	for r: Dictionary in recs:
		if int(r.from_frame) != next or int(r.to_frame) < int(r.from_frame):
			return "gap at %d" % next
		next = int(r.to_frame) + 1
		if float(r.arrived.tau) > float(sim.world.clock.tau) + 1e-12:
			return "arrived after the ship's clock"
		if absf(float(r.sent.t) - (float(r.arrived.t) - float(r.arrived.ly))) > 1e-9:
			return "send event off the light cone"
	if int(recs[-1].to_frame) != int(sim.world.earth.feed.frame):
		return "newest %d, feed %d" % [int(recs[-1].to_frame), int(sim.world.earth.feed.frame)]
	return ""


func test_voyage() -> void:
	sim = SimBridge.new()
	sim.want_minor = SimBridge.EARTH_LOG_MINOR
	var ok := sim.start() and sim.new_game(7, "free_nav", false, {}, "", "")
	check("voyage: a 2.18 session starts with the log (week 0)", ok and log_fault() == "")
	ok = ok and fly(ALPHA)
	var fault := ""
	var ticks := 0
	while ok and fault == "" and ticks < 400 and str(journey().get("state", "")) != "arrived":
		ok = sim.send([], 0.004)
		fault = log_fault()
		ticks += 1
	for i in 40:
		if not ok or fault != "":
			break
		ok = sim.send([], 0.004)
		fault = log_fault()
	ok = ok and fly(OFF_RAY)
	for i in 60:
		if not ok or fault != "":
			break
		ok = sim.send([], 0.004)
		fault = log_fault()
	var recs: Array = sim.world.get("earth_log", {}).get("records", [])
	check("voyage: the session ran (%s)" % [sim.last_error], ok)
	check("voyage: the stored log holds at every tick (%s)" % [fault if fault != "" else "contiguous, newest = feed frame, on the light cone"], fault == "")
	check("voyage: the off-ray leg's weeks arrive unbeamed", not recs.is_empty() and recs[-1].get("beamed") == false)
	check("voyage: the outbound weeks arrived beamed", recs.size() > 2 and recs[1].get("beamed") == true)
	sim.stop()
