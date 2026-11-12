extends SceneTree
## Focused R3 telescope evidence. CPU bench is separate from renderer acceptance.
const TelescopePanel = preload("res://ui/observation_panel.gd")
const Index = preload("res://ui/observation_index.gd")
var mode := "bench"
var out := "res://renders/telescope"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		elif arg in ["bench", "capture", "golden"]: mode = arg
	_run.call_deferred()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	if mode == "bench":
		var report := await exercise(self)
		_write(out + "/bench.json", report)
		print("telescope-bench: %d samples, %d failures" % [report.samples.size(), report.failures])
		quit(1 if report.failures else 0)
	else:
		if DisplayServer.get_name() == "headless":
			printerr("FAIL telescope rendered evidence requires an available GPU")
			quit(1); return
		await _capture()
static func _write(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "  ") + "\n")
static func _percentile(values: Array, p: float) -> float:
	if values.is_empty(): return 0.0
	var sorted := values.duplicate(); sorted.sort()
	return float(sorted[clampi(int(ceil(sorted.size() * p)) - 1, 0, sorted.size() - 1)])
static func _baseline() -> void: pass
static func exercise(tree: SceneTree) -> Dictionary:
	var report := {"schema":"stapledons.telescope-bench/1", "failures":0, "samples":[], "decodes":0, "peak_cpu_bytes":0, "peak_gpu_bytes":0, "max_decodes_per_pump":0, "closed_decodes":0, "closed_bytes":0, "missing_unavailable":false, "host":OS.get_model_name(), "processor":OS.get_processor_name(), "engine":Engine.get_version_info().string, "renderer":DisplayServer.get_name(), "gpu_bytes_kind":"RGBA8 texture payload estimate; driver overhead excluded", "timing_kind":"individual CPU calls; no GPU/draw time; baseline=empty function, open=warm pan update+one cache pump, closed=panel process+cache pump", "render_acceptance":"pending GPU capture and dev-build review"}
	var revision: Array = []
	if OS.execute("git",["rev-parse","HEAD"],revision) == 0: report.build_revision = "".join(revision).strip_edges()
	report.host_load_note = OS.get_environment("TELESCOPE_HOST_LOAD_NOTE")
	var index := Index.new()
	if not index.load_files(): report.failures += 1; return report
	var start := Time.get_ticks_usec()
	var panel := TelescopePanel.new(); panel.set_process(false)
	tree.root.add_child(panel); panel.size = Vector2(1280, 720); panel.configure(index)
	panel.open_reference({})
	await tree.process_frame
	report.cold_panel_setup_ms = (Time.get_ticks_usec() - start) / 1000.0
	panel.set_process(false)
	var warm: Array = []; var baseline: Array = []; var closed: Array = []; var cold: Array = []
	for sample in 1024:
		var t := Time.get_ticks_usec(); _baseline()
		baseline.append((Time.get_ticks_usec() - t) / 1000.0)
	for plate_id: String in index.plates:
		panel.select_plate(plate_id)
		for step in 8:
			var at: Vector2 = panel.image_area.size * Vector2(0.47, 0.53)
			var before: Vector2 = panel.source_point(at)
			var target: float = [0.25, 1., 2., 4., 8., 16., 64., 1.][step]
			panel.zoom_at(target / panel.zoom, at)
			if panel.source_point(at).distance_to(before) > 0.01: report.failures += 1
			panel.pan += Vector2(13 * (step % 3 - 1), 7 * (step % 2))
			panel._update_tiles()
			var decode_start := Time.get_ticks_usec()
			for job in 128:
				var was: int = panel.cache.decodes
				panel.cache.pump(1)
				report.max_decodes_per_pump = maxi(report.max_decodes_per_pump, panel.cache.decodes - was)
				if was == panel.cache.decodes: break
			cold.append((Time.get_ticks_usec() - decode_start) / 1000.0)
			for repeat in 32:
				var warm_start := Time.get_ticks_usec()
				panel.pan += Vector2(0.05, 0.0); panel._update_tiles(); panel.cache.pump(1)
				warm.append((Time.get_ticks_usec() - warm_start) / 1000.0)
			report.peak_cpu_bytes = maxi(report.peak_cpu_bytes, panel.cache.cpu_bytes)
			report.peak_gpu_bytes = maxi(report.peak_gpu_bytes, panel.cache.gpu_bytes)
			report.samples.append({"plate":plate_id,"zoom":panel.zoom,"cpu_bytes":panel.cache.cpu_bytes,"gpu_bytes":panel.cache.gpu_bytes,"decodes":panel.cache.decodes,"visible_tiles":panel._requested().size()})
			if panel.cache.cpu_bytes > 64 * 1024 * 1024 or panel.cache.gpu_bytes > 128 * 1024 * 1024: report.failures += 1
		report.decodes += panel.cache.decodes
	report.total_session_ms = (Time.get_ticks_usec() - start) / 1000.0
	report.cold_first_visible_load_ms = cold[0] if not cold.is_empty() else 0.0
	panel.close_panel()
	var decoded: int = panel.cache.decodes
	for sample in 1024:
		var t := Time.get_ticks_usec()
		panel._process(0.0); panel.cache.pump(1)
		closed.append((Time.get_ticks_usec() - t) / 1000.0)
	report.closed_decodes = panel.cache.decodes - decoded
	report.closed_bytes = panel.cache.cpu_bytes + panel.cache.gpu_bytes
	report.closed_live_render_disabled = panel.live_view._vp.render_target_update_mode == SubViewport.UPDATE_DISABLED
	report.baseline_p95_ms = _percentile(baseline, 0.95)
	report.open_warm_p95_ms = _percentile(warm, 0.95)
	report.closed_p95_ms = _percentile(closed, 0.95)
	report.added_warm_p95_ms = maxf(0.0, report.open_warm_p95_ms - report.baseline_p95_ms)
	report.cold_load_p95_ms = _percentile(cold, 0.95)
	if report.added_warm_p95_ms > 2.0 or report.closed_decodes != 0 or report.closed_bytes != 0 or not report.closed_live_render_disabled: report.failures += 1
	panel.open_reference({}); panel.tile_index = {}; panel._update_tiles()
	report.missing_unavailable = panel.state_line.text.contains("Source file missing") and panel._requested().is_empty()
	if not report.missing_unavailable: report.failures += 1
	panel.close_panel(); panel.queue_free(); await tree.process_frame
	return report

# Actual ship/map/popup/chair contexts. No synthetic full-screen UI replacement.
func _capture() -> void:
	root.gui_embed_subwindows = true
	var frames := 0; var failures := 0; var rows: Array = []; var sheet_images: Array[Image] = []
	var view := SubViewport.new(); view.size = Vector2i(1280,720); view.gui_embed_subwindows = true; view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; root.add_child(view)
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars":true,"background":true,"live_start":true,"sky_state":"rest","seed":1,"size":Vector2i(1280,720)}
	view.add_child(demo); await process_frame
	demo.auto = false; demo.journey_auto_tick = false; demo.escape_exits = false
	if not demo.ready_ok or demo.journey_map == null:
		printerr("FAIL telescope capture could not start real ship"); quit(1); return
	print("telescope-evidence: real ship ready; preparing Aldebaran arrival")
	# Use the real free-navigation arrival; do not substitute a surface fixture.
	demo.open_navigation()
	var arrival_map = demo.journey_map
	arrival_map.preselect(arrival_map.index_of("CNS5:1142"))
	var arrived: bool = demo.journey_tick() and arrival_map.open_commit_dialog() and arrival_map.hold_commit(arrival_map.HOLD_S) and demo.journey_tick()
	if arrived:
		for tick in 6000:
			if tick % 500 == 0: print("telescope-evidence: arrival tick ",tick)
			if tick % 50 == 0: await process_frame
			if not demo.journey_tick() or not demo.live_journey: break
		arrived = arrival_map.journey_state() == "arrived"
	if not arrived:
		printerr("FAIL telescope capture could not reach Aldebaran"); demo.queue_free(); view.queue_free(); quit(1); return
	var live_ref := {}
	for body: Dictionary in demo.sky_world.get("system",{}).get("bodies",[]):
		if body.get("kind") == "star" and (body.get("catalogue_id") == "CNS5:1142" or body.get("id") == "aldebaran"):
			if not live_ref.is_empty():
				printerr("FAIL telescope capture Aldebaran identity is ambiguous"); quit(1); return
			live_ref = {"kind":"body","id":body.id}
	if live_ref.is_empty():
		printerr("FAIL telescope capture exact Aldebaran body unavailable"); demo.queue_free(); view.queue_free(); quit(1); return
	print("telescope-evidence: arrived at Aldebaran")
	for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(2560,1440)]:
		view.size = size; demo.setup_options.size = size
		for frame in 3: await process_frame
		demo._resize(); demo.geometry_view.size = size; demo._sync_observer(); demo.open_navigation()
		var map = demo.journey_map; var panel = map.observation_panel
		print("telescope-evidence: capture size ",size)
		for case_name in ["m81_wide","m81_detail","registered_sources","resolution_limit","missing_archive","sources_credits","survey_direction"]:
			map.open_observation({})
			panel.select_plate("m81-outreach" if not case_name in ["registered_sources","survey_direction"] else "abell3128-vis")
			if case_name == "m81_detail": panel.zoom_at(8., panel.image_area.size * .5)
			if case_name == "resolution_limit": panel.zoom_at(64., panel.image_area.size * .5)
			if case_name in ["registered_sources","sources_credits"]:
				panel.select_object(map.observation_index.objects.keys()[0]); panel.show_details = true; panel.show_sources = true; panel._refresh_details()
			if case_name == "missing_archive": panel.tile_index = {}; panel._update_tiles()
			if case_name == "survey_direction": panel.close_panel(); map.set_survey_context(true); map._overlay.queue_redraw()
			else: map.set_survey_context(false)
			for frame in 64: await process_frame
			await RenderingServer.frame_post_draw
			var image := view.get_texture().get_image()
			var name := "%dx%d_%s" % [size.x,size.y,case_name]
			var fits: bool = not panel.visible or _panel_fits(panel)
			if not fits or image.save_png(out + "/" + name + ".png") != OK: failures += 1
			else: frames += 1
			rows.append({"case":name,"fits":fits,"raster":[image.get_width(),image.get_height()]})
			image.resize(320,180); sheet_images.append(image)
		panel.close_panel(); map.focus_object({"kind":"catalogue","id":"CNS5:1142"},true)
		map.open_observation({"kind":"catalogue","id":"CNS5:1142"},"live")
		if not panel.visible or panel.reference != {"kind":"catalogue","id":"CNS5:1142"}: failures += 1
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		var navigation_card := view.get_texture().get_image()
		rows.append({"case":"navigation_inspection","size":[size.x,size.y],"fits":_panel_fits(panel),"reference":panel.reference,"facts_available":not panel.detail.text.is_empty()})
		if not _panel_fits(panel): failures += 1
		if navigation_card.save_png(out + "/%dx%d_navigation_inspection.png" % [size.x,size.y]) != OK: failures += 1
		else: frames += 1
		navigation_card.resize(320,180); sheet_images.append(navigation_card)
		# I-card comes from the same real identification controller used by the player.
		panel.close_panel(); demo.close_navigation()
		if not demo.star_identification.inspect("CNS5:1142"): failures += 1
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		var card := view.get_texture().get_image()
		if card.save_png(out + "/%dx%d_inspection_popup.png" % [size.x,size.y]) != OK: failures += 1
		else: frames += 1
		card.resize(320,180); sheet_images.append(card)
		# Actual live selected star, both magnification levels, through the shared panel.
		demo.star_identification.card.hide(); demo.open_telescope_reference(live_ref)
		panel.set_mode("live")
		for level in [1,2]:
			panel.live_view.level = level; panel.live_view.refresh(demo.sky_world)
			for frame in 8: await process_frame
			await RenderingServer.frame_post_draw
			var live_image := view.get_texture().get_image()
			if live_image.save_png(out + "/%dx%d_live_aldebaran_%d.png" % [size.x,size.y,level]) != OK: failures += 1
			else: frames += 1
			live_image.resize(320,180); sheet_images.append(live_image)
			if level == 1:
				var evidence := _live_golden(panel.live_view, demo.sky.system_view)
				rows.append(evidence)
				if not evidence.uniforms_equal or evidence.centroid_error_px > 0.75: failures += 1
		# The existing captain-command host owns the same map/panel on its physical screen.
		panel.close_panel(); demo.close_navigation()
		demo.avatar_pos = demo.walk_bridge.closest_walkable(demo.chair_seat() - demo.chair_facing(), 3.)
		demo.sit_chair()
		for frame in 50: demo._process(1./60.)
		demo.consoles.command.select_system("navigation")
		demo.journey_map.open_observation({}); panel.select_plate("m81-outreach")
		for frame in 64: await process_frame
		await RenderingServer.frame_post_draw
		var chair := view.get_texture().get_image()
		if chair.save_png(out + "/%dx%d_chair_navigation.png" % [size.x,size.y]) != OK: failures += 1
		else: frames += 1
		chair.resize(320,180); sheet_images.append(chair)
		panel.close_panel(); map.focus_object({"kind":"catalogue","id":"CNS5:1142"},true)
		map.open_observation({"kind":"catalogue","id":"CNS5:1142"},"live")
		if not panel.visible or panel.reference != {"kind":"catalogue","id":"CNS5:1142"}: failures += 1
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		var chair_card := view.get_texture().get_image()
		rows.append({"case":"chair_inspection","size":[size.x,size.y],"fits":_panel_fits(panel),"reference":panel.reference,"facts_available":not panel.detail.text.is_empty()})
		if not _panel_fits(panel): failures += 1
		if chair_card.save_png(out + "/%dx%d_chair_inspection.png" % [size.x,size.y]) != OK: failures += 1
		else: frames += 1
		chair_card.resize(320,180); sheet_images.append(chair_card)
		demo.stand_chair()
	# Archive independence golden: exact same viewport bytes for SR/GR snapshot changes.
	var panel = demo.journey_map.observation_panel
	demo.open_navigation(); demo.journey_map.open_observation({}); panel.select_plate("m81-outreach")
	for frame in 64: await process_frame
	await RenderingServer.frame_post_draw
	var archive_view: Viewport = panel.get_viewport()
	var reference := archive_view.get_texture().get_image().get_data()
	for beta in [0.,0.5,0.9,0.99,0.999]:
		var snapshot: Dictionary = demo.sky_world.duplicate(true); snapshot["ship"]["beta"] = beta; snapshot["gr"] = {"active":true,"g":0.2}
		panel.update_world(snapshot, demo.sky.system_view)
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		# Only compare archive pixels: cockpit clocks keep advancing outside the panel.
		var image := archive_view.get_texture().get_image()
		var area := Rect2i(panel.image_area.get_global_rect())
		var before := Image.create_from_data(image.get_width(),image.get_height(),false,image.get_format(),reference).get_region(area)
		var same := before.get_data() == image.get_region(area).get_data()
		rows.append({"case":"archive_sr_gr_invariance","beta":beta,"equal":same})
		if not same: failures += 1
	if not sheet_images.is_empty():
		var sheet := Image.create(3*320, int(ceil(sheet_images.size()/3.))*180,false,Image.FORMAT_RGB8)
		for i in sheet_images.size(): sheet.blit_rect(sheet_images[i],Rect2i(0,0,320,180),Vector2i((i%3)*320,(i/3)*180))
		sheet.save_png(out + "/contact_sheet.png")
	_write(out + "/" + mode + ".json", {"frames":frames,"failures":failures,"rows":rows,"visual_acceptance":"pending; open every frame"})
	demo.queue_free(); view.queue_free(); await process_frame
	print("telescope-%s: %d frames, %d failures" % [mode,frames,failures])
	quit(1 if failures else 0)

static func _panel_fits(panel: Control) -> bool:
	var bounds := Rect2(Vector2.ZERO,panel.get_viewport().get_visible_rect().size)
	var rect := panel.get_global_rect()
	if not bounds.grow(1.).encloses(rect): return false
	for control: Control in [panel.heading,panel.source_line,panel.state_line,panel.image_area,panel.field_picker,panel.live_button,panel.archive_button]:
		if control.is_visible_in_tree() and not rect.grow(1.).encloses(control.get_global_rect()): return false
	return panel.image_area.size.x > 0. and panel.image_area.size.y > 0.

# GPU geometry is measured independently from shader coordinates via Camera3D.
# Compare copied physical uniforms; the documented optical/gate overrides differ.
static func _live_golden(live: TelescopeView, sv: SystemView) -> Dictionary:
	if live.star_id.is_empty() or not sv.discs.has(live.star_id):
		return {"case":"live_physical_uniforms_and_cpu_centroid","uniforms_equal":false,"centroid_error_px":1e9,"error":"explicit live target unavailable"}
	var source: ShaderMaterial = sv.discs[live.star_id].material_override
	var optical := ["radius","bounded_draw","beta_mag","ss","px_per_radius","surf_on","cells_across","sigma_t","facula_sigma_t","salt0","salt1","spot_count","spots","spot_temps","fade_w","body_basis","bb_lut","lut_log_tmin","lut_log_tmax","surf_norm"]
	var equal := true; var checked := 0
	for uniform: Dictionary in source.shader.get_shader_uniform_list():
		if uniform.name in optical: continue
		checked += 1
		if live._mat.get_shader_parameter(uniform.name) != source.get_shader_parameter(uniform.name): equal = false
	var image := live._vp.get_texture().get_image()
	var expected := live._cam.unproject_position(source.get_shader_parameter("centre_w"))
	var peak := 0.0
	for y in image.get_height():
		for x in image.get_width(): peak = maxf(peak,image.get_pixel(x,y).srgb_to_linear().get_luminance())
	var mean := 0.0; var count := 0
	for y in image.get_height():
		for x in image.get_width():
			var light := image.get_pixel(x,y).srgb_to_linear().get_luminance()
			if light > 0.01 * peak: mean += light; count += 1
	mean /= maxf(1.,count)
	var sum := Vector2.ZERO; var weight := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var light := image.get_pixel(x,y).srgb_to_linear().get_luminance()
			if light > 0.01 * peak:
				var coverage := minf(1., light / maxf(0.25 * mean,1e-12))
				sum += coverage * Vector2(x+.5,y+.5); weight += coverage
	var measured := sum / maxf(1e-12,weight)
	return {"case":"live_physical_uniforms_and_cpu_centroid","star":live.star_id,"uniforms_checked":checked,"uniforms_equal":equal and checked > 0,"centroid_error_px":measured.distance_to(expected) if weight > 0. else 1e9,"expected_px":[expected.x,expected.y],"measured_px":[measured.x,measured.y],"centroid_method":"coverage-weighted disc mask (existing star-surface golden method); independent CPU Camera3D projection"}
