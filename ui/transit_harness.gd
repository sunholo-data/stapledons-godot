class_name TransitHarness
extends Node
## The M4.3a sky-only transit harness: the HUD and the arrival card over the real sim, driven by
## Transit (warp, dtau pacing). No interior (M4.3b moves the HUD into it). `run_session` is the
## scripted flight behind tests/test_transit.gd and tests/replays/m4_transit_harness.ndjson.

const TICK_DT := 1.0 / 20.0
const MAX_TICKS := 6000
## Alpha Cen A (the map's CNS5:3627 row), docked at Sol, planned at the sim's default 0.99c.
const TARGET := {"index": 2, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}

var sim: SimBridge
var transit := Transit.new()
var hud: JourneyHud = load("res://ui/journey_hud.tscn").instantiate()
var card: ArrivalCard = load("res://ui/arrival_card.tscn").instantiate()
var auto := false # interactive: tick at TICK_DT of real time, keys 1-3 set the warp level
var _queue: Array = []
var _accum := 0.0


func attach(s: SimBridge) -> void:
	sim = s
	add_child(hud)
	add_child(card)
	refresh()


func _process(delta: float) -> void:
	if not auto or sim == null:
		return
	_accum = minf(_accum + delta, 4.0 * TICK_DT)
	while _accum >= TICK_DT:
		_accum -= TICK_DT
		tick(TICK_DT)


func _unhandled_key_input(event: InputEvent) -> void:
	if auto and event.pressed and event.keycode >= KEY_1 and event.keycode <= KEY_3:
		transit.request_warp(Transit.WARP_LEVELS[event.keycode - KEY_1], sim.world)


func queue(intent: Dictionary) -> void:
	_queue.append(intent)


## The sim's world plus the client's own state (the warp level) for the bindings.
func view() -> Dictionary:
	var v := sim.world.duplicate()
	v["client"] = {"warp": transit.warp}
	return v


func refresh() -> void:
	hud.show_world(view())
	card.show_world(view())


## One tick over `real_dt` seconds of real time. Returns {"sent", "dtau", "intents"}.
func tick(real_dt: float) -> Dictionary:
	var s := transit.step(sim.world, real_dt, _queue)
	var offset := _queue.size()
	var intents: Array = _queue + s["intents"]
	_queue = []
	var sent := sim.send(intents, s["dtau"])
	if sent:
		transit.settle(sim.last_refused, offset)
	refresh()
	return {"sent": sent, "dtau": s["dtau"], "intents": intents}


func _state() -> String:
	return GalaxyMap.field_value(sim.world, "journey.state")


## The scripted flight: dock a moment, plan, try warp (refused: nothing committed), commit, fly
## boost -> cruise (3 s at the default warp, then 0.05) -> brake -> arrival, try warp again
## (refused). Returns what the tests read.
func run_session(real_dt: float = TICK_DT) -> Dictionary:
	var out := {"ticks": 0, "phase_ticks": {}, "phases": [], "events": [], "legacy": [], "refusals": [],
		"cruise_dtau": [], "notice_in_brake": false, "snap": {}, "ok": true}
	var warped := false
	var cruise_ticks := 0
	var n := 0
	while n < MAX_TICKS:
		n += 1
		match n:
			4: queue({"k": "plan", "target": TARGET, "cruise_phi": sim.world["params"]["cruise_phi_default"]})
			6: queue({"k": "warp", "level": 0.05}) # nothing committed yet: the sim refuses it
			8: queue({"k": "commit", "plan_id": sim.world["journey"]["plan_id"]})
		var before := _state()
		var phase: String = sim.world["ship"]["phase"]
		if before == "committed":
			if phase == "at_rest":
				phase = "boosting"
			out["phase_ticks"][phase] = out["phase_ticks"].get(phase, 0) + 1
			if phase == "cruising":
				cruise_ticks += 1
				if cruise_ticks == 61 and not warped: # 3 s of cruise at 0.01 elapsed
					warped = transit.request_warp(0.05, sim.world)
		var r := tick(real_dt)
		out["ticks"] = n
		if not r["sent"]:
			out["ok"] = false
			break
		if before == "committed" and phase == "cruising" and out["cruise_dtau"].size() < 3:
			out["cruise_dtau"].append(r["dtau"])
		if not sim.last_refused.is_empty():
			out["refusals"].append([n, sim.last_refused.map(func(x): return x["reason"])])
		for e in sim.last_events:
			out["events"].append(e["k"])
		var legacy: Variant = GalaxyMap.field_value(sim.world, "consequence.legacy.appended")
		if legacy is Array:
			for entry in legacy:
				out["legacy"].append(entry["kind"])
		var after: String = sim.world["ship"]["phase"]
		if _state() == "committed" and (out["phases"].is_empty() or out["phases"][-1] != after) and after != "at_rest":
			out["phases"].append(after)
			out["snap"][after] = sim.world.duplicate(true)
		if after == "braking" and hud.notice.text != "":
			out["notice_in_brake"] = true
		if _state() == "arrived" and not out["snap"].has("arrived"):
			out["snap"]["arrived"] = sim.world.duplicate(true)
			queue({"k": "warp", "level": 0.01}) # arrived: warp exists only while committed
			for i in 3: # then a moment at rest, the host clock still running (D-12)
				tick(real_dt)
				if not sim.last_refused.is_empty():
					out["refusals"].append([n, sim.last_refused.map(func(x): return x["reason"])])
			break
	return out
