extends SceneTree
## R3-REASONS RT5a (design r3/reasons-to-travel.md): the reason card for each candidate of the example
## fixture (tests/fixtures/finder/candidates.json: invented data, not sim output), in True and
## Processed, for review. Nothing here ships.
## Usage: godot --path . --resolution 1280x720 --script tools/reason_card_capture.gd -- [--out=res://renders/reason_card]
var out := "res://renders/reason_card"
var px := Vector2i(1280, 720)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	var back := ColorRect.new()
	back.color = Color("#05070c")
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(back)
	var card := ReasonCard.new()
	card.position = Vector2(60, 60)
	card.size = Vector2(px.x - 120, px.y - 120)
	root.add_child(card)
	var view: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/finder/candidates.json"))
	var frames := 0
	for i in view.finder.candidates.size():
		for mode: String in ["true", "processed"]:
			card.refresh(view, i)
			card.set_processed(mode == "processed")
			for _k in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			var path := "%s/%s_%s.png" % [out, str(view.finder.candidates[i].id), mode]
			if img.save_png(ProjectSettings.globalize_path(path)) == OK:
				frames += 1
	print("reason-card-capture: %d frames" % frames)
	quit(0 if frames == view.finder.candidates.size() * 2 else 1)
