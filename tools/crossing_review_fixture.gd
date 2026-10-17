extends SceneTree
## R2-INTERLUDE I3: records the crossing review's fixtures from the real sim (protocol 2.10) on the
## guided voyage, as the host crosses them (demos/solar_departure.gd, chunk by chunk). Each line of
## tests/fixtures/crossing_review/<case>.ndjson is one frame the review is shown for:
##   {"case", "at": "hold" | "crossed", "leg", "target", "world": {tick, clock, consequence, journey,
##    cruise, crew, ship {phase, ism}}}
## The world sections are the sim's own (SimBridge.world), trimmed to what the review reads.
## Cases (seed 42, an orders crew under critical_only unless said; Rulings §4 is critical_only):
##   acen       Alpha Centauri leg: every hold raised in the crossing, then the crossing's end
##   trappist   TRAPPIST-1 then Aldebaran, chained from Earth (the Earth years add up across legs)
##   nocrew     Alpha Centauri leg with no crew aboard
## Run:  make crossing-review-fixtures  (headless; rewrites the fixtures, review the diff)

const OUT := "res://tests/fixtures/crossing_review"
const SECTIONS := ["tick", "clock", "consequence", "journey", "cruise", "crew"]
const Tour := preload("res://demos/solar_departure.gd")

var failures := 0


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	record("acen", catalogue.stars, "orders", 3, 1)
	record("trappist", catalogue.stars, "orders", 4, 2)
	record("nocrew", catalogue.stars, "", 3, 1)
	print("crossing-review-fixture: %d failures" % failures)
	quit(1 if failures else 0)


func trimmed(sim: SimBridge, tour, at: String, name: String) -> Dictionary:
	var w := {}
	for k: String in SECTIONS:
		if sim.world.has(k): w[k] = sim.world[k].duplicate(true) if sim.world[k] is Dictionary else sim.world[k]
	var ship: Dictionary = sim.world.get("ship", {})
	w["ship"] = {"phase": ship.get("phase", ""), "ism": {"model": ship.get("ism", {}).get("model", "")}}
	return {"case": name, "at": at, "leg": tour.leg_name(), "target": tour.leg_name(), "world": w}


## Fly `legs` star legs from leg_index `from` (the next leg is from + 1), resuming each hold as a
## captain would once it is recorded, and recording every hold and each crossing's end.
func record(name: String, catalogue: Array, captaincy: String, from: int, legs: int) -> void:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.INTERLUDE_MINOR
	var ok := sim.start() and sim.new_game(42, "solar_departure", false, Tour.guided_params(), "", captaincy)
	if not ok:
		failures += 1; print("FAIL %s: no session (%s)" % [name, sim.last_error]); return
	if captaincy != "":
		sim.queue([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": "critical_only"})])
	var tour = Tour.new()
	if not tour.attach(sim, catalogue):
		failures += 1; print("FAIL %s: attach" % name); sim.stop(); return
	tour.leg_index = from
	var rows: Array = []
	for leg in legs:
		if not tour.advance():
			failures += 1; print("FAIL %s: commit leg %d (%s)" % [name, leg, tour.failed]); break
		var done_before: int = tour.interludes_done
		for i in 200000:
			if not tour.failed.is_empty(): break
			if tour.crew_held():
				if tour.interlude != null: rows.append(trimmed(sim, tour, "hold", name))
				for h: Dictionary in sim.crew.holds:
					sim.queue([SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": h.id})])
			var in_crossing: bool = tour.interlude != null
			if not tour.step(): break
			if in_crossing and tour.interludes_done > done_before:
				rows.append(trimmed(sim, tour, "crossed", name))
				break
		# On to the arrival (real time, stage by stage) so the next leg starts where this one ends.
		for i in 200:
			if sim.world.journey.state == "arrived" or not tour.failed.is_empty(): break
			if tour.crew_held():
				for h: Dictionary in sim.crew.holds:
					sim.queue([SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": h.id})])
				tour.step(); continue
			if not tour.skip_stage(): tour.step()
		tour.dwell_left = 0.0
	if not tour.failed.is_empty():
		failures += 1; print("FAIL %s: %s" % [name, tour.failed])
	var f := FileAccess.open(OUT.path_join(name + ".ndjson"), FileAccess.WRITE)
	for r: Dictionary in rows: f.store_line(SimBridge.encode(r))
	f.close()
	print("fixture %s: %d frames (%s)" % [name, rows.size(), ", ".join(rows.map(func(r): return "%s %s" % [r.at, r.leg]))])
	sim.stop()
