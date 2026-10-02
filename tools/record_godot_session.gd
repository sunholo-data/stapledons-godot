extends SceneTree
## Records a Godot-driven input log through SimBridge.record_path (the bridge
## tee, M2.1b) for the replay harness (M2.5): the real galaxy map on a play
## session selects Sirius A, moves the cruise slider, replans to alpha Cen A
## (catalogue index 1) at the 0.99c default, ticks at the host rate, then
## commits and flies to arrival in 0.01-yr ticks (the host rate would take
## ~4,500 ticks and a multi-MB golden). Every float in the log is written by
## SimBridge.number from the parsed catalogue doubles and the slider.
## Run:  godot --headless --path . --script tools/record_godot_session.gd -- OUT.ndjson
## then  make replay-record LOG=OUT.ndjson  (review the golden diff).

const ALPHA_CEN_A := 1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("usage: ... -- OUT.ndjson")
		quit(2)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(800, 600)
	root.add_child(vp)
	await process_frame
	var sim := SimBridge.new()
	sim.record_path = args[0]
	if not sim.start() or not sim.new_game(0, "sol", false):
		push_error("sim session failed: %s" % sim.last_error)
		quit(2)
		return
	var map: GalaxyMap = load("res://ui/galaxy_map.tscn").instantiate()
	map.auto_tick = false
	vp.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	map.attach(sim)
	var sirius := -1
	for i in map.catalogue.size():
		if str(map.catalogue[i]["id"]).begins_with("Sirius") or str(map.catalogue[i]["id"]) == "Gl 244":
			sirius = i
			break
	if sirius >= 0:
		map.select(sirius)
	else:
		map.select(3)
	map.set_cruise_phi(map.phi_min + 0.37 * (map.phi_max - map.phi_min))
	for i in 3:
		map.tick()
	map.select(ALPHA_CEN_A)
	map.set_cruise_phi(map.phi_default)
	map.tick()
	var plan_id: int = sim.world["journey"]["plan_id"]
	sim.send([{"k": "commit", "plan_id": plan_id}], 0.0)
	var n := 0
	while sim.world["journey"]["state"] != "arrived" and n < 1000:
		sim.send([], 0.01)
		n += 1
	for i in 3:
		map.tick()
	var state: String = sim.world["journey"]["state"]
	sim.stop()
	print("recorded %s: plan %d, %s after %d voyage ticks" % [args[0], plan_id, state, n])
	quit(0 if state == "arrived" else 1)
