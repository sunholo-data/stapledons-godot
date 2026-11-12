extends SceneTree
## D-150: real system panels in the seated command shell, at three viewport sizes.
## --layout-only is headless geometry evidence, never a rendered visual verdict.
var out := "res://renders/captain_command"
var layout_only := false
var failures := 0
var cases := 0
var frames := 0
var rows := []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--layout-only": layout_only = true
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless" and not layout_only:
		print("FAIL rendered command capture needs a renderer; use --layout-only for geometry")
		quit(1); return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.gui_embed_subwindows = true
	var d: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	d.setup_options = {"stars": not layout_only, "background": not layout_only, "live_start": true, "sky_state": "rest", "seed": 1}
	d.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(d)
	await process_frame
	d.auto = false; d.journey_auto_tick = false; d.escape_exits = false
	if not d.ready_ok or d.journey_sim == null:
		print("FAIL command capture could not start the real ship simulation")
		d.queue_free(); await process_frame; quit(1); return
	d.avatar_pos = d.walk_bridge.closest_walkable(d.chair_seat() - d.chair_facing(), 3.)
	d.sit_chair()
	for k in 50: d._process(1. / 60.)
	for px in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(2560, 1440)]:
		root.size = px
		for k in 3: await process_frame
		d._resize()
		# UI coordinates follow the project's stretch viewport, not physical window pixels.
		# Forcing a 1280-wide HUD into the default 960-wide canvas silently crops the capture.
		var logical := Vector2(root.get_visible_rect().size)
		d.ship_hud.size = logical
		var command: CaptainCommand = d.consoles.command
		command.layout_for(logical, d.ship_hud.strip_bottom())
		for system: String in CaptainCommand.ORDER:
			command.select_system(system)
			if system == "crew" and d.consoles.crew_console != null:
				d.consoles.crew_console.open_call("pilot")
			if system == "archive":
				d.consoles.ask_field.text = "What is the bubble?"
				d.consoles.use("archive", "ask")
			for k in 180: d._process(1. / 60.)
			for k in 4: await process_frame
			d._process(0.)
			var bounds := Rect2(Vector2.ZERO, logical)
			var fits := bounds.encloses(command.frame.get_global_rect())
			var screen_bounds := Rect2(Vector2.ZERO, Vector2(command.screen_host.viewport.size))
			if d.consoles.panel.visible:
				fits = fits and screen_bounds.encloses(d.consoles.panel.get_global_rect())
				fits = fits and d.consoles.panel_body.size.x <= d.consoles.body_scroll.size.x + 1.
			if not fits:
				failures += 1
				print("FAIL command layout ", system, " at ", px, " panel ", d.consoles.panel.get_global_rect())
			cases += 1
			var name := "%dx%d_%s" % [px.x, px.y, system]
			var row := {"case": name, "fits": fits, "logical_size": [logical.x, logical.y], "shell": _rect(command.frame.get_global_rect()), "system": _rect(d.consoles.panel.get_global_rect()), "content": _rect(command.content_rect())}
			rows.append(row)
			if not layout_only:
				await RenderingServer.frame_post_draw
				var frame := root.get_texture().get_image()
				if frame != null: row["raster_size"] = [frame.get_width(), frame.get_height()]
				if frame == null or frame.is_empty() or frame.save_png(out.path_join(name + ".png")) != OK:
					failures += 1
				else: frames += 1
	var report := {"schema": "stapledons.captain-command-review/1", "layout_cases": cases, "frames": frames, "failures": failures, "visual_acceptance": "pending", "rows": rows}
	var f := FileAccess.open(out.path_join("layout.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ") + "\n")
	d.queue_free()
	await process_frame
	if layout_only: print("captain-command-layout: %d cases, %d failures" % [cases, failures])
	else: print("captain-command-capture: %d frames, %d failures" % [frames, failures])
	quit(1 if failures else 0)

static func _rect(r: Rect2) -> Array:
	return [r.position.x, r.position.y, r.size.x, r.size.y]
