extends RefCounted
## Explicit CLI-only functional probe of the exported application. No rendering
## or photometry claim: headless checks packaged resources and runtime lifecycle.
const Cache = preload("res://ui/observation_tiles.gd")
const Bridge = preload("res://bridge/sim_bridge.gd")
var passed := 0
var failures := 0
var evidence := {"schema":"stapledons.telescope-full-app/1","network":"required launcher applies sandbox-exec deny network*; not inferred from GDScript","gpu_rendering":"not tested; headless dummy renderer"}
func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok app telescope: ",label)
	else: failures += 1; printerr("FAIL app telescope: ",label)
func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}
func _files(path: String) -> Array[String]:
	var out: Array[String] = []
	for file in DirAccess.get_files_at(path): out.append(path.path_join(file))
	for child in DirAccess.get_directories_at(path): out.append_array(_files(path.path_join(child)))
	return out
func _finish(report: String) -> int:
	evidence["passed"] = passed; evidence["failures"] = failures
	if not report.is_empty():
		var file := FileAccess.open(report,FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(evidence,"  ") + "\n")
		else: check(false,"write probe evidence report")
	print("telescope-app-probe: %d passed, %d failures" % [passed,failures])
	return failures
func run(tree: SceneTree, args: PackedStringArray) -> int:
	var expected := ""; var home := ""; var report := ""
	for arg in args:
		if arg.begins_with("--expected="): expected = arg.trim_prefix("--expected=")
		elif arg.begins_with("--fresh-home="): home = arg.trim_prefix("--fresh-home=")
		elif arg.begins_with("--report="): report = arg.trim_prefix("--report=")
	check(OS.has_feature("template"),"running actual export template")
	check(DisplayServer.get_name() == "headless","dummy renderer; no GPU render claim")
	check(OS.get_environment("PATH") == "/usr/bin:/bin" and OS.get_environment("AILANG_BIN").is_empty(),"no ambient AILANG executable override")
	check(not home.is_empty() and OS.get_environment("HOME") == home and OS.get_user_data_dir().begins_with(home + "/"),"fresh isolated HOME and user data")
	var commit := FileAccess.get_file_as_string("res://runtime/build_commit.txt").strip_edges()
	check(expected.length() == 40 and commit == expected,"exact packaged build commit")
	evidence["build_commit"] = commit; evidence["expected_commit"] = expected
	evidence["executable"] = OS.get_executable_path(); evidence["home"] = OS.get_environment("HOME"); evidence["user_data"] = OS.get_user_data_dir()
	check(not DirAccess.dir_exists_absolute("res://data/raw/observations/"),"raw observation source directory excluded")
	check(ResourceLoader.exists("res://demos/ship_geometry_demo.tscn") and ResourceLoader.exists("res://ui/observation_panel.gd"),"real packaged ship scene and shared telescope resources")
	if failures: return _finish(report)
	var runtime: String = Bridge._unpack_runtime()
	check(runtime.begins_with(OS.get_user_data_dir() + "/runtime-"),"runtime extracted from pack under fresh user data")
	check(FileAccess.file_exists(runtime + "/.unpacked") and FileAccess.get_sha256(runtime + "/runtime/bin/ailang") == FileAccess.get_sha256("res://runtime/bin/ailang"),"extracted AILANG binary matches packaged bytes")
	check(DirAccess.dir_exists_absolute(runtime + "/home/.ailang/cache/registry/sunholo"),"bundled package cache extracted without network")
	evidence["runtime_root"] = runtime
	var manifest := _json("res://observation_bundle/manifest.json.bin")
	var files := _files("res://observation_bundle"); var footprint := 0
	for path in files:
		var file := FileAccess.open(path,FileAccess.READ)
		if file != null: footprint += file.get_length()
	check(not manifest.is_empty() and footprint > 0 and footprint <= 100*1024*1024,"bundled observation footprint within 100 MiB")
	var tile_count := 0
	for plate: Dictionary in manifest.get("plates",[]):
		var meta: Dictionary = plate.get("tiles",{}); var raw := str(meta.get("path","")); var bundled: String = Cache.available_path(raw)
		check(not FileAccess.file_exists(raw) and bundled.begins_with("res://observation_bundle/") and bundled.ends_with(".bin") and FileAccess.get_sha256(bundled) == str(meta.get("sha256","")),"packaged pinned index " + str(plate.get("id","")))
		for level: Dictionary in _json(bundled).get("levels",[]):
			for tile: Dictionary in level.get("tiles",[]):
				var path: String = Cache.available_path(tile.path)
				if FileAccess.file_exists(tile.path) or not path.begins_with("res://observation_bundle/") or FileAccess.get_sha256(path) != tile.sha256:
					check(false,"packaged pinned tile " + str(tile.key))
				tile_count += 1
	check(tile_count > 0,"all packaged tile hashes verified")
	evidence["bundle_bytes"] = footprint; evidence["bundle_files"] = files.size(); evidence["tiles_verified"] = tile_count
	var credits := FileAccess.get_file_as_string("res://data/observations/euclid_dr1/credits.md")
	check(credits.contains("ESA") and credits.contains("Euclid"),"packaged observation credits available")
	if failures: return _finish(report)
	# Headless templates default to a 64² window. Use an ordinary player-sized
	# viewport so the unchanged production LOD can resolve the actual Sun.
	evidence["initial_window_size"] = [tree.root.size.x,tree.root.size.y]
	tree.root.size = Vector2i(1280,720)
	var scene: PackedScene = load("res://demos/ship_geometry_demo.tscn")
	var demo = scene.instantiate()
	demo.setup_options = {"stars":false,"background":false,"live_start":true,"sky_state":"rest","seed":1,"ai":false,"crew":"","size":Vector2i(1280,720)}
	tree.root.add_child(demo); await tree.process_frame
	demo.auto = false; demo.journey_auto_tick = false
	check(demo.ready_ok and demo.journey_sim != null and not demo.journey_sim.world.is_empty(),"actual packaged AILANG simulation starts and supplies Sol world")
	if demo.journey_sim == null:
		demo.queue_free(); await tree.process_frame; return _finish(report)
	check(demo.journey_sim.child_pid > 0 and demo.journey_sim.launch_override.is_empty() and not demo.journey_sim.hello_reply.is_empty(),"actual bundled child handshake without fixture override")
	var launch: Dictionary = demo.journey_sim._launch_plan()
	var launch_args: PackedStringArray = launch.get("args",PackedStringArray())
	evidence["launch"] = {"bin":launch.get("bin"),"args":Array(launch_args),"expected_binary":runtime + "/runtime/bin/ailang","expected_home_assignment":"HOME=" + runtime + "/home"}
	check(launch.get("bin") == "/usr/bin/env" and launch_args.has(runtime + "/runtime/bin/ailang") and launch_args.has("HOME=" + runtime + "/home"),"actual sim launch uses extracted bundled binary and cache HOME")
	demo.open_navigation()
	var map = demo.journey_map; var panel = map.observation_panel
	var pin: Dictionary = map.observation_index.pin()
	check(not pin.is_empty() and pin.get("manifest_sha256") == FileAccess.get_sha256("res://observation_bundle/manifest.json.bin"),"production index manifest pin equals verified packaged metadata")
	check(pin.get("objects_sha256") == FileAccess.get_sha256("res://observation_bundle/objects.json.bin"),"production index object pin equals verified packaged metadata")
	check(demo.journey_sim.get_meta("observation_pack",{}) == pin,"actual host simulation carries the production observation pin")
	evidence["observation_pin"] = pin
	check(map.open_observation({},"archive"),"Navigation telescope opens")
	panel.select_plate("abell3128-vis"); panel.set_process(false)
	await tree.process_frame
	panel.set_process(false); panel._update_tiles()
	check(panel.plate.get("id") == "abell3128-vis" and panel.plate.get("registered",false) and not panel.tile_index.is_empty(),"real registered VIS plate loads from packaged index")
	var requested: Array = panel._requested()
	for job in requested.size()+1: panel.cache.pump(1)
	var verified := 0
	for meta: Dictionary in requested:
		var entry: Dictionary = panel.cache.get_tile(meta.key)
		if entry.is_empty(): check(false,"visible packaged tile decoded " + str(meta.key)); continue
		var image := Image.new(); var bytes := FileAccess.get_file_as_bytes(Cache.available_path(meta.path))
		check(image.load_png_from_buffer(bytes) == OK and entry.texture is Texture2D and entry.texture.get_width() == int(meta.width),"headless tile ImageTexture created with expected dimensions")
		check(entry.image.get_data() == image.get_data() and FileAccess.get_sha256(Cache.available_path(meta.path)) == meta.sha256,"pumped texture source pixels match exact packaged PNG pin")
		verified += 1
	check(verified > 0,"Navigation renders-ready tile payload exercised (no GPU readback claim)")
	evidence["visible_tiles_decoded"] = verified
	panel.close_panel()
	check(not panel.cache.active and panel.cache.cpu_bytes == 0 and panel.cache.gpu_bytes == 0,"archive close releases cached image/texture payload")
	check(map.open_observation({"kind":"body","id":"sun"},"live"),"shared Navigation panel opens exact live Sun")
	var live_refreshed: bool = panel.live_view.refresh(demo.sky_world)
	var source_sun: MeshInstance3D = demo.sky.system_view.discs.get("sun")
	evidence["live_state"] = {"requested_id":panel.live_view.requested_star_id,"selected_id":panel.live_view.star_id,"refreshed":live_refreshed,"telescope_disc_visible":panel.live_view._disc.visible,"source_sun_present":source_sun != null,"source_sun_visible":source_sun.visible if source_sun != null else false,"source_material_present":source_sun.material_override != null if source_sun != null else false,"source_disc_ids":demo.sky.system_view.discs.keys(),"window_size":[tree.root.size.x,tree.root.size.y],"geometry_size":[demo.geometry_view.size.x,demo.geometry_view.size.y],"sky_size":[demo.sky.size.x,demo.sky.size.y],"source_pixel_rad":demo.sky.system_view.px_rad}
	check(live_refreshed and panel.live_view.requested_star_id == "sun" and panel.live_view.star_id == "sun" and panel.live_view._disc.visible,"real finite-star material honours exact Sun target")
	panel.close_panel()
	check(panel.live_view._vp.render_target_update_mode == SubViewport.UPDATE_DISABLED and not panel.visible,"closing live panel disables render updates")
	demo.journey_sim.stop(); demo.queue_free(); await tree.process_frame
	return _finish(report)
