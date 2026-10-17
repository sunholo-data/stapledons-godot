extends SceneTree
## R2-CREW C6 review frames: the Crew console's page (crew-work W1) in the console panel style, from the
## crew section recorded from the real sim (tests/crew/console_state.json), at 1280x1400: the whole
## scroll content (the console scrolls it at 1280x720).
##   crew_page.png         the page as a captain first sees it (medic asking for relief)
##   crew_page_armed.png   after one press on "Grant relief" (the confirm state)
##   crew_page_ai.png      after the AI words for both lines are accepted
##   crew_page_hold.png    a crew hold: auto-run stopped for the medic's breakdown (C8)
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
	DisplayServer.window_set_size(Vector2i(1280, 1400))
	root.size = Vector2i(1280, 1400)
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.05)
	bg.size = Vector2(1280, 1400)
	root.add_child(bg)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ShipHud._panel_style(0.94))
	panel.position = Vector2(24, 64)
	panel.custom_minimum_size = Vector2(680, 0)
	root.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var title := Label.new()
	title.text = "Crew console · the crew and their work"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	box.add_child(title)
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
	var held: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/crew/console_state.json"))
	held["auto"] = "critical_only"
	held["holds"] = [{"id": "h12-breakdown-medic", "rule": "breakdown", "actor": "medic", "name": "Ligaya Reyes", "task": "", "tick": 12, "detail": "stress 85", "line": "is close to breaking down."}]
	page.show_crew(held)
	await _shot("crew_page_hold.png")
	print("crew-console-capture: 4 frames in renders/crew_console")
	quit(0)
