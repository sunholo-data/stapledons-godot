extends SceneTree
## Performance pass (Mark 2026-10-14): SimBridge.pipelined sends intent-free heartbeat ticks without
## waiting, and takes the reply at the next drain. Same inputs, same order: the pipelined run must end
## in the same world, the same journal and the same crew as a synchronous run, and a heartbeat must
## hand the main thread back quickly. Run:  make sim-pipeline-test

var failures := 0

func check(label: String, ok: bool) -> void:
	if not ok: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])

func drive(pipelined: bool) -> Dictionary:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.CREW_MINOR
	sim.record_sent = true
	var ok := sim.start() and sim.new_game(3, "free_nav", false, {}, "", "consent")
	sim.pipelined = pipelined
	var hb := 1.0 / (31557600.0 * 20.0)
	var heartbeat_ms := []
	for i in 60:
		if i == 20:
			ok = ok and sim.send([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": "critical_only"})], 0.0)
		elif i == 40:
			var page := CrewPage.new()
			page.show_crew(sim.crew)
			ok = ok and sim.send(page.offer_intents("pilot"), 0.0)
			page.free()
		else:
			var t0 := Time.get_ticks_usec()
			ok = ok and sim.send([], hb if i % 10 else 2.0 / 365.25, true) # a heartbeat that may be pipelined; every tenth spans crew days
			heartbeat_ms.append((Time.get_ticks_usec() - t0) / 1000.0)
			if pipelined:
				OS.delay_msec(25) # the frame the game renders while the sim computes
	ok = ok and sim.drain()
	var out := {"ok": ok, "world": JSON.stringify(sim.world), "crew": JSON.stringify(sim.crew), "sent": JSON.stringify(sim.sent_log), "tick": int(sim.world.get("tick", -1)), "heartbeat_ms": heartbeat_ms}
	sim.stop()
	return out

## The guided voyage pipelines its heartbeats too (SolarDeparture.step): skip to the first leg's
## approach, then step through the arrival into the dwell. A pipelined arrival is seen one step
## later, but the tick sequence must be the same.
func tour(pipelined: bool, catalogue) -> Dictionary:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.ISM_MINOR
	sim.record_sent = true
	var dep = load("res://demos/solar_departure.gd")
	if not (sim.start() and sim.new_game(42, "solar_departure", false, dep.guided_params())):
		return {"ok": false}
	var c = dep.new()
	c.attach(sim, catalogue)
	sim.pipelined = pipelined
	var ok: bool = c.advance()
	for i in 3:
		ok = ok and c.skip_stage()
	var steps := 0
	while ok and steps < 20000 and not (c.dwell_left > 0.0 and c.dwell_left < c.DWELL_SECONDS - 0.5):
		ok = c.step()
		steps += 1
	ok = ok and sim.drain()
	var out := {"ok": ok, "steps": steps, "state": str(sim.world.journey.state), "sent": JSON.stringify(sim.sent_log), "world": JSON.stringify(sim.world)}
	sim.stop()
	return out


func _initialize() -> void:
	var a := drive(false)
	var b := drive(true)
	check("both runs complete", a.ok and b.ok and a.tick == 60 and b.tick == 60)
	check("same inputs in the same order (sent journal)", a.sent == b.sent)
	check("same world at the end", a.world == b.world)
	check("same crew at the end", a.crew == b.crew)
	var sa: Array = a.heartbeat_ms.duplicate(); sa.sort()
	var sb: Array = b.heartbeat_ms.duplicate(); sb.sort()
	print("heartbeat send on the main thread: synchronous median %.2f ms, pipelined median %.2f ms" % [sa[sa.size() / 2], sb[sb.size() / 2]])
	check("a pipelined heartbeat hands the main thread back (median under a quarter of the synchronous one)", sb[sb.size() / 2] < sa[sa.size() / 2] * 0.25)
	var stars = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).stars
	var t1 := tour(false, stars)
	var t2 := tour(true, stars)
	print("guided voyage: %d steps synchronous, %d pipelined, state %s / %s" % [t1.get("steps", -1), t2.get("steps", -1), t1.get("state", "?"), t2.get("state", "?")])
	check("the guided voyage arrives and dwells, pipelined as synchronous", t1.ok and t2.ok and t1.state == "arrived" and t2.state == "arrived")
	check("the guided voyage's ticks and world are identical", t1.sent == t2.sent and t1.world == t2.world)
	print("sim-pipeline: %d failures" % failures)
	quit(1 if failures else 0)
