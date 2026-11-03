extends SceneTree
## R3-TRUE-PROCESSED-b review frames: Earth's feed with the Processed Doppler indicator, its edge gradient, at
## the Earth rates RS-26 (0.070888, 0.99c away), rest (1), RS-29 (14.107, 0.99c home) and the top speed
## either way (RS-28 7.0711e-4, RS-30 1414.2), each in Receiver (Processed: the indicator, labelled) and
## True (no indicator). The picture is the same library week in every frame (it is never tinted).
## Writes renders/doppler_indicator/<name>_<setting>.png. Run: make capture-doppler-indicator (GPU window).
const OUT := "res://renders/doppler_indicator"
const CASES := [["rs28_d0.00071", 7.0711e-4], ["rs26_d0.071", 0.070888], ["rest_d1", 1.0], ["rs29_d14.1", 14.107], ["rs30_d1414", 1414.2]]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(640, 360)
	var bg := ColorRect.new()
	bg.color = StapledonTheme.INK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var f := EarthFeed.new()
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(f)
	var frames := 0
	for c: Array in CASES:
		for on: bool in [true, false]:
			f.set_receiver(on)
			var record := {"frame": 40, "kind": "library", "event": {"id": "home-blossom", "category": "home", "words": "spring blossom"}, "pick": 0}
			f.refresh({"earth": {"rate": float(c[1]), "in_beam": true, "at_home": false, "newest_light_year": 2034.5, "light_age_years": 4.25, "feed": record}})
			for i in 6: await process_frame
			await RenderingServer.frame_post_draw
			var name := "%s_%s" % [c[0], "processed" if on else "true"]
			root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
			var ind := EarthFeed.doppler_indicator(float(c[1]))
			print("doppler-indicator-capture: %s D %s line %.1f nm shown %.0f nm strength %.3f tag '%s'" % [name, c[1], ind.lambda_nm, ind.shown_nm, ind.strength, f.doppler_tag.text if f.doppler_tag.visible else "-"])
			frames += 1
	print("doppler-indicator-capture: %d frames OK" % frames)
	quit(0)
