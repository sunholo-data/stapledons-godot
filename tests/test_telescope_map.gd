extends SceneTree
const Map = preload("res://ui/galaxy_map.gd")
var passed := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok ", label)
	else: failed += 1; printerr("FAIL ", label)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var map := Map.new()
	map.auto_tick = false
	root.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	map.mode = "helm"
	map.selected_index = 1
	map._pending = {"k": "plan", "fixture": "preserve me"}
	map._queue = [{"k": "fixture-intent"}]
	var pending: Dictionary = map._pending.duplicate(true)
	var queue: Array = map._queue.duplicate(true)
	var before := [map.selected_index, map.pivot, map.yaw, map.pitch, map.dist]
	check(map.has_method("focus_object"), "map exposes separate read-only object focus")
	if map.has_method("focus_object"):
		var id: String = map.catalogue[2].id
		check(map.focus_object({"kind": "catalogue", "id": id}, false), "exact catalogue identity accepted")
		check(map.observation_selection.id == id, "observation focus preserves exact source")
		check(map._pending == pending and map._queue == queue, "focus queues no additional route or decision")
		check([map.selected_index, map.pivot, map.yaw, map.pitch, map.dist] == before, "route selection and map camera unchanged")
		check(not map.focus_object({"kind": "survey", "id": id}, false), "catalogue identity cannot be cast to survey")
		check(not map.focus_object({"kind": "catalogue", "id": "missing"}, false), "missing catalogue identity rejected")
		check(not map.focus_object({"kind": "catalogue", "id": 123}, false), "numeric identity rejected")
		check(map.inspection_index() == 2 and map.selected_index == 1, "observation marker is separate from planned selection")
		check(map.plot_inspection_button.visible, "helm exposes an explicit plot action for inspected local star")
		check(map.open_observation({"kind":"catalogue", "id":"missing"}), "missing observation opens its unavailable card")
		map.close_observation()
		check(map.observation_selection.is_empty() and not map.plot_inspection_button.visible, "missing observation clears the previous inspection marker and plot action")
	check(map.has_method("set_survey_context"), "survey sky context is explicit")
	if map.has_method("set_survey_context"):
		var camera_before := [map.pivot, map.yaw, map.pitch, map.dist]
		map.set_survey_context(true)
		check(map.survey_layer.active and not map._points.visible, "survey context hides local distance point cloud")
		check(map._pending == pending and map._queue == queue, "changing display context preserves navigation intents")
		check(map.open_observation(), "survey context opens its selected field")
		check(map.observation_panel.plate.get("id") == "abell3128-vis" and map.observation_panel.reference.is_empty(), "field observation never falls back to the old planned star")
		map.close_observation()
		map.press_cancel()
		check(map._queue == queue, "survey display cannot queue a cancel intent")
		var enter := InputEventKey.new()
		enter.keycode = KEY_ENTER; enter.pressed = true
		map._input(enter)
		check(not map.dialog.visible, "survey inspection cannot open route commit ritual")
		map.set_survey_context(false)
		check([map.pivot, map.yaw, map.pitch, map.dist] == camera_before, "leaving survey context restores local camera")
		check(map._points.visible and not map.survey_layer.active, "local points and context restored")
		map.set_survey_context(true)
		map.set_mode("helm", false)
		check(not map.survey_context, "entering helm restores local planning context")
	if not OS.get_cmdline_user_args().has("--focus-only"): await real_journey(map)
	map.queue_free()
	await process_frame
	print("telescope-map-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)

func real_journey(map: Node) -> void:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.SESSION_MINOR
	sim.record_sent = true
	check(sim.start() and sim.new_game(17, "sol", false), "real simulation starts for observation boundary test")
	if sim.world.is_empty(): sim.stop(); return
	map._pending = {}; map._queue = []
	map.attach(sim)
	check(sim.get_meta("observation_pack",{}) == map.observation_index.pin(), "host session retains pack ID and both exact content hashes")
	map.select(map.index_of("CNS5:3627"))
	check(map.tick() and map.journey_state() == "planned", "actual journey planned before observing")
	var selected: int = map.selected_index
	var other := {"kind":"catalogue","id":str(map.catalogue[2].id)}
	map.set_mode("chart"); map.focus_object(other)
	check(not map.plot_inspection_button.visible and map._pending.is_empty(), "chart inspection offers no plot action or implicit plan")
	map.set_mode("helm")
	check(map.selected_index == selected and map.inspection_index() == 2 and map._pending.is_empty(), "walking to helm retains inspection without silently changing destination")
	check(map.plot_inspected_star() and map._pending.get("k") == "plan" and map._pending.target.id == other.id, "explicit helm plot alone selects the inspected star")
	map.preselect(selected); map.tick()
	for stage in ["planned", "committed"]:
		if stage == "committed":
			check(map.open_commit_dialog() and map.hold_commit(1.5) and map.tick(), "actual journey committed before observing")
		var target: Dictionary = sim.world.journey.plan.target.duplicate(true)
		var clock: float = sim.world.clock.tau
		sim.sent_log.clear()
		var local_star: Dictionary = map.catalogue[2].duplicate(true)
		var ref := {"kind": "catalogue", "id": str(local_star.id)}
		check(map.open_observation(ref), "%s: exact catalogue opens shared panel" % stage)
		check(not map.telescope_button.is_visible_in_tree() and map.observation_panel.image_area.has_focus(), "%s: observation owns focus and hides underlying route controls" % stage)
		var map_camera := [map.pivot, map.yaw, map.pitch, map.dist]
		var zoom_event := InputEventMagnifyGesture.new(); zoom_event.factor = 2.
		map._unhandled_input(zoom_event)
		check([map.pivot, map.yaw, map.pitch, map.dist] == map_camera, "%s: archive owns zoom without moving map camera" % stage)
		var enter := InputEventKey.new(); enter.keycode = KEY_ENTER; enter.pressed = true
		map._input(enter)
		map.observation_panel.select_plate("abell3128-vis")
		var survey_id: String = map.observation_index.objects.keys()[0]
		map.observation_panel.select_object(survey_id)
		map.observation_panel.open_map.emit({"kind":"survey", "id":survey_id})
		check(map.survey_context and map.observation_selection.id == survey_id, "%s: archive to map preserves exact survey identity" % stage)
		map.press_cancel(); map.select(3)
		check(map.tick(), "%s: observer heartbeat runs" % stage)
		check(sim.sent_log.size() == 1 and sim.sent_log[0].intents.is_empty(), "%s: observing sends no decision intents to real sim" % stage)
		check(sim.world.clock.tau > clock and sim.world.journey.plan.target == target, "%s: clock advances and route target survives" % stage)
		check(map.catalogue[2] == local_star, "%s: survey cannot alter local xyz/facts" % stage)
		map.close_observation(); map.set_survey_context(false)
		check(map.telescope_button.is_visible_in_tree(), "%s: map controls restored after observation" % stage)
		var body_id: String = sim.world.system.bodies[0].id
		check(map.focus_object({"kind":"body","id":body_id}) and map.observation_reference() == {"kind":"body","id":body_id}, "%s: exact live body reference round-trips" % stage)
	sim.stop()
