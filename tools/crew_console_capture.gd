extends SceneTree
## R2-CREW C6 review frames: the Voyage console's Crew page in the console panel style, from the
## crew section recorded from the real sim (tests/crew/console_state.json), at 1280x720.
##   crew_page.png         the page as a captain first sees it (medic asking for relief)
##   crew_page_armed.png   after one press on "Grant relief" (the confirm state)
##   crew_page_ai.png      after the AI words for both lines are accepted
## Run:  make crew-console-capture  (needs a GPU window; open every frame)

const OUT := "res://renders/crew_console"

func _initialize() -> void:
	_run.call_deferred()

func _shot(name: String) -> void:
	for i in 3:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT.path_join(name)))
	print("frame %s %dx%d" % [name, img.get_width(), img.get_height()])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.size = Vector2i(1280, 720)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.05)
	bg.size = Vector2(1280, 720)
	root.add_child(bg)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ShipHud._panel_style(0.94))
	panel.position = Vector2(24, 64)
	panel.custom_minimum_size = Vector2(420, 0)
	root.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Voyage console"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	box.add_child(title)
	var crew := Label.new()
	crew.text = "Crew"
	crew.add_theme_font_size_override("font_size", 15)
	box.add_child(crew)
	var page := CrewPage.new()
	box.add_child(page)
	page.show_crew(JSON.parse_string(FileAccess.get_file_as_string("res://tests/crew/console_state.json")))
	await _shot("crew_page.png")
	page.press("relief:relief-c1:true")
	await _shot("crew_page_armed.png")
	page.press("relief:relief-c1:false")
	page.armed = ""
	page.set_ai_text("1", "I'm running on empty, Captain. I need a few days off the rota.")
	page.set_ai_text("2", "Still steady here. The signal work can wait for no one.")
	await _shot("crew_page_ai.png")
	print("crew-console-capture: 3 frames in renders/crew_console")
	quit(0)
