extends SceneTree
## Actual first information entry, before this Demo has a navigation host.
## Inspect the recorded wire requests, including the construction heartbeat:
## checking the pending queue alone misses intents already sent and consumed.
const Index = preload("res://ui/observation_index.gd")
const RECORD := "user://telescope-first-entry.ndjson"
var passed := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failures += 1
		printerr("FAIL ", label)

func _initialize() -> void: run.call_deferred()

func inputs() -> Array:
	var result: Array = []
	check(FileAccess.file_exists(RECORD), "actual simulation request recording exists")
	if not FileAccess.file_exists(RECORD):return result
	for line in FileAccess.get_file_as_string(RECORD).split("\n", false):
		var request: Variant = JSON.parse_string(line)
		check(request is Dictionary, "recorded outgoing NDJSON parses")
		if request is Dictionary and request.get("type") == "input":
			check(request.get("intents") is Array, "recorded input carries an intent array")
			if request.get("intents") is Array:result.append(request)
	return result

func no_plan(world: Dictionary) -> bool:
	var plan: Variant = world.get("journey", {}).get("plan")
	return plan == null or (plan is Dictionary and plan.is_empty())

func captain_unchanged(demo: Node, position: Vector3, rendered: Vector3) -> bool:
	return demo.avatar_pos.is_equal_approx(position) and demo.avatar.position.is_equal_approx(rendered)

func run() -> void:
	for suffix in ["", ".observations.json"]:
		if FileAccess.file_exists(RECORD + suffix):DirAccess.remove_absolute(RECORD + suffix)
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	# No live_start and no crew override: the real default consent crew is needed
	# to expose an accidental constructor crew_orders request.
	demo.setup_options = {"stars":false, "background":false, "sky_state":"rest", "sound":false, "record":RECORD}
	root.add_child(demo)
	demo.auto = false
	demo.journey_auto_tick = false
	demo.set_process(false)
	await process_frame
	check(demo.ready_ok and demo.journey_map == null and demo.journey_sim == null, "actual Demo starts without a navigation session")
	if not demo.ready_ok or demo.journey_map != null:
		await finish(demo)
		return
	var position: Vector3 = demo.avatar_pos
	var rendered: Vector3 = demo.avatar.position
	var reference := {"kind":"body", "id":"sun"}
	demo.open_telescope_reference(reference)
	await process_frame
	check(demo.journey_map != null and demo.journey_sim != null, "first telescope entry creates actual host session")
	if demo.journey_map == null or demo.journey_sim == null:
		await finish(demo)
		return
	var map: Variant = demo.journey_map
	var sim: Variant = demo.journey_sim
	check(sim.crew.get("captaincy") == "consent" and not sim.crew.get("members", []).is_empty(), "default consent crew is genuinely present")
	check(no_plan(sim.world), "constructor heartbeat creates no implicit journey plan")
	check(captain_unchanged(demo, position, rendered), "first information entry does not relocate the Captain")
	var panel: Variant = map.observation_panel
	check(panel != null and panel.visible and panel.reference == reference, "first telescope panel retains exact Sun body reference")
	if panel == null:
		await finish(demo)
		return
	if panel != null:
		var resolved := false
		for body: Dictionary in panel.world.get("system", {}).get("bodies", []):
			if body.get("id") == "sun" and body.get("kind") == "star":resolved = true
		check((resolved and panel.mode == "live" and panel.live_view.requested_star_id == "sun") or (not resolved and panel.detail.text.to_lower().contains("unavailable") and panel.plate.is_empty()), "first entry shows true live Sun or explicit unavailable state")
	var expected := Index.new()
	check(expected.load_files(), "independent actual-source index supplies expected host pin")
	var expected_pin: Dictionary = expected.pin()
	check(not expected_pin.is_empty() and sim.get_meta("observation_pack", {}) == expected_pin and map.observation_metadata == expected_pin and panel.session_pin == expected_pin, "host and first panel retain both exact content hashes")
	var sidecar_path := RECORD + ".observations.json"
	check(FileAccess.file_exists(sidecar_path), "host writes observation metadata beside actual recording")
	if FileAccess.file_exists(sidecar_path):
		var sidecar: Variant = JSON.parse_string(FileAccess.get_file_as_string(sidecar_path))
		check(sidecar is Dictionary and sidecar.get("observation_pack") == expected_pin, "recording sidecar matches expected host pin")
	check(demo.journey_tick() and demo.journey_tick(), "actual information-host heartbeats succeed")
	var readonly_inputs := inputs()
	check(readonly_inputs.size() >= 3, "record includes construction and later observation heartbeats")
	var all_empty := true
	for request: Dictionary in readonly_inputs:
		all_empty = all_empty and request.get("intents") is Array and request.intents.is_empty()
	check(all_empty, "ALL outgoing information-entry input intents are empty, including constructor")
	check(no_plan(sim.world), "information heartbeats still leave no journey plan")
	check(captain_unchanged(demo, position, rendered), "observation heartbeats preserve Captain position")
	check(map.close_observation(), "information panel closes normally")
	demo.open_navigation()
	check(map.mode == "helm" and not panel.visible, "normal navigation remains available after information entry")
	var target := "CNS5:3627"
	check(map.select(map.index_of(target)) and map._pending.get("k") == "plan" and map._pending.target.id == target, "explicit catalogue selection retains normal plan authority")
	check(demo.journey_tick() and map.journey_state() == "planned" and sim.world.journey.plan.target.id == target, "explicit selection reaches actual simulation as the requested plan")
	var recorded_after := inputs()
	var seen_plan := false
	var only_explicit_plan := true
	for i in recorded_after.size():
		var intents: Array = recorded_after[i].intents
		if i < readonly_inputs.size():only_explicit_plan = only_explicit_plan and intents.is_empty()
		for intent: Dictionary in intents:
			seen_plan = seen_plan or (intent.get("k") == "plan" and intent.get("target", {}).get("id") == target)
			only_explicit_plan = only_explicit_plan and intent.get("k") == "plan" and intent.get("target", {}).get("id") == target
	check(seen_plan and only_explicit_plan, "recorded wire decisions begin only with explicit selected plan; no startup crew_orders")
	check(captain_unchanged(demo, position, rendered), "opening navigation and planning never relocates Captain")
	await finish(demo)

func finish(demo: Node) -> void:
	demo.queue_free()
	await process_frame
	await physics_frame
	await process_frame
	print("telescope-first-entry-test: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
