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
	check(map.has_method("set_survey_context"), "survey sky context is explicit")
	if map.has_method("set_survey_context"):
		var camera_before := [map.pivot, map.yaw, map.pitch, map.dist]
		map.set_survey_context(true)
		check(map.survey_layer.active and not map._points.visible, "survey context hides local distance point cloud")
		check(map._pending == pending and map._queue == queue, "changing display context preserves navigation intents")
		var enter := InputEventKey.new()
		enter.keycode = KEY_ENTER; enter.pressed = true
		map._input(enter)
		check(not map.dialog.visible, "survey inspection cannot open route commit ritual")
		map.set_survey_context(false)
		check([map.pivot, map.yaw, map.pitch, map.dist] == camera_before, "leaving survey context restores local camera")
		check(map._points.visible and not map.survey_layer.active, "local points and context restored")
	await real_journey(map)
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
	map.select(map.index_of("CNS5:3627"))
	check(map.tick() and map.journey_state() == "planned", "actual journey planned before observing")
	for stage in ["planned", "committed"]:
		if stage == "committed":
			check(map.open_commit_dialog() and map.hold_commit(1.5) and map.tick(), "actual journey committed before observing")
		var target: Dictionary = sim.world.journey.plan.target.duplicate(true)
		var clock: float = sim.world.clock.tau
		sim.sent_log.clear()
		var local_star: Dictionary = map.catalogue[2].duplicate(true)
		var ref := {"kind": "catalogue", "id": str(local_star.id)}
		check(map.open_observation(ref), "%s: exact catalogue opens shared panel" % stage)
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
	sim.stop()
