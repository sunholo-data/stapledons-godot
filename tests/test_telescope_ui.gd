extends SceneTree
const TelescopePanel = preload("res://ui/observation_panel.gd")
const Index = preload("res://ui/observation_index.gd")
var passed := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok ", label)
	else: failed += 1; printerr("FAIL ", label)
func _init() -> void: call_deferred("run")
func run() -> void:
	var index := Index.new()
	check(index.load_files(), "real source index and plate manifest load")
	var panel := TelescopePanel.new()
	root.add_child(panel)
	panel.size = Vector2(900, 480)
	panel.configure(index)
	var id: String = index.objects.keys()[0]
	check(panel.open_reference({"kind": "survey", "id": id}), "survey source opens telescope")
	check(panel.reference.get("id") == id, "panel retains exact identity")
	check(panel.plate.get("id") == "abell3128-vis", "exact association opens registered field")
	check(panel.heading.text.contains("Survey archive"), "archive viewpoint clearly labelled")
	check(panel.has_method("zoom_at"), "archive pan/zoom controls exist")
	if panel.has_method("zoom_at"):
		await process_frame
		var at: Vector2 = panel.image_area.size * 0.5
		var before: Vector2 = panel.source_point(at)
		panel.zoom_at(1.5, at)
		check(panel.source_point(at).distance_to(before) < 0.001, "cursor-anchored zoom preserves source pixel")
		panel.select_plate("m81-outreach")
		check(panel.reference.is_empty(), "browsing another plate clears unrelated source identity")
		check(panel.point_candidates(Vector2.ZERO).is_empty(), "unregistered image cannot identify objects")
		var sources_toggle: CheckButton = panel.find_child("SourcesToggle", true, false)
		sources_toggle.button_pressed = true
		check(panel.detail.text.contains("CC BY-SA 3.0 IGO") and panel.detail.text.contains(str(panel.plate.source_url)), "field Sources control reveals actual licence and image URL")
		sources_toggle.button_pressed = false
		panel.select_plate("abell3128-vis")
		var source_before: String = panel.source_line.text
		var pins: Dictionary = panel.tile_index.duplicate(true)
		for beta in [0., .5, .9, .99, .999]:
			panel.update_world({"ship":{"beta":beta,"pos":{"x":1e9,"y":2e9,"z":3e9}},"gr":{"active":true}})
			check(panel.tile_index == pins and panel.source_line.text == source_before, "archive pins/date invariant at beta %s and GR" % beta)
		panel.set_mode("live")
		await process_frame
		check(panel.image_area.get_global_rect().grow(1.).encloses(panel.live_view.get_global_rect()), "live telescope fits inside available image area")
		panel.set_mode("archive")
		check(panel.source_line.text == source_before, "returning to archive restores dated Earth observation label")
		var at_point: Vector2 = panel._origin() + preload("res://physics/observation_projection.gd").display_point(panel.plate, index.object(id)) * panel._scale()
		check(panel.point_candidates(at_point).any(func(row): return row.id == id), "registered picking reaches exact catalogue source")
		# FITS pixel centres become integer zero-based indices, while a rendered
		# texture's first pixel occupies [0,1] and is centred at 0.5.
		panel.zoom = 64.
		var pixel_centre := preload("res://physics/observation_projection.gd").display_point(panel.plate, index.object(id)) + Vector2(.5,.5)
		var canvas_centre := panel.image_area.size * .5
		panel.pan = canvas_centre - pixel_centre * panel._scale() - (panel.image_area.size - panel._source_size() * panel._scale()) * .5
		check(panel.point_candidates(canvas_centre).any(func(row): return row.id == id), "high zoom picks the rendered source pixel centre, not its corner")
		panel.zoom = 1.; panel.pan = Vector2.ZERO; panel._update_tiles()
		# Dispatch through the actual viewport/GUI rather than calling the handler.
		panel.image_area.grab_focus()
		await process_frame
		var camera_zoom: float = panel.zoom
		var plus := InputEventKey.new(); plus.keycode = KEY_PLUS; plus.pressed = true
		root.push_input(plus)
		await process_frame
		check(panel.zoom > camera_zoom, "real focused key dispatch zooms archive")
		camera_zoom = panel.zoom
		var pinch := InputEventMagnifyGesture.new(); pinch.factor = 1.1
		pinch.position = panel.image_area.get_global_rect().get_center()
		root.push_input(pinch, true)
		await process_frame
		check(panel.zoom > camera_zoom, "real GUI pinch dispatch zooms archive")
		var pan_before: Vector2 = panel.pan
		var scroll := InputEventPanGesture.new(); scroll.delta = Vector2(1.,2.); scroll.position = pinch.position
		root.push_input(scroll, true)
		await process_frame
		check(panel.pan != pan_before, "real GUI trackpad dispatch pans archive")
		var next_index := Index.new()
		next_index.load_files(); next_index.version = "different-pack"
		panel.configure(next_index)
		check(panel.session_pack_id == index.version and panel.index.pin() == index.pin(), "observation pack stays pinned for this session")
		check(panel.archive_mismatch and panel.configure(index), "pinned source can recover without adopting the offered replacement")
		var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Index.OBJECTS_PATH))
		var changed: Dictionary = index.manifest.duplicate(true)
		changed.plates[0].credit = "Labelled changed-credit fixture"
		var same_id := Index.new(); same_id.set_data(raw,changed)
		check(not panel.configure(same_id) and panel.archive_mismatch, "same pack ID cannot conceal changed content hashes")
		panel.open_reference({"kind":"survey","id":id})
		check(not panel.cache.active and panel.state_line.text.contains("Archive unavailable"), "mismatched content exposes an unavailable archive")
		panel.configure(index)
		panel.select_plate("m81-outreach"); panel.select_object(id)
		check(panel.plate.id == "abell3128-vis", "selecting exact source restores its associated image")
		panel.show_details = true; panel.show_sources = true; panel._refresh_details()
		await process_frame
		panel.detail.get_v_scroll_bar().value = panel.detail.get_v_scroll_bar().max_value
		panel.select_object(str(index.objects.keys()[1]))
		await process_frame
		check(panel.detail.get_v_scroll_bar().value <= 0.1, "opening another source starts at its primary facts")
		panel.cache.close(); panel.cache.activate(index.version + ":failure-fixture")
		for level: Dictionary in panel.tile_index.levels:
			for tile: Dictionary in level.tiles: tile.path = "user://labelled-missing-image-fixture.png"
		panel._update_tiles(); panel._process(0.)
		check(panel.state_line.text.contains("unavailable") and panel.state_line.text.contains("missing"), "missing tile data has a visible unavailable state")
		check(panel.open_reference({"kind":"body","id":"labelled-missing-body"}), "missing explicit body opens an unavailable card")
		check(panel.detail.text.contains("Information unavailable") and panel.detail.text.contains("labelled-missing-body") and panel.map_button.disabled, "unavailable identity is retained without a map fallback")
		panel.close_panel()
		check(not panel.visible and not panel.cache.active, "closed panel stops tile decode lifecycle")
	panel.queue_free()
	await process_frame
	print("telescope-ui-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
