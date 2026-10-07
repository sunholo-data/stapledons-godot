extends SceneTree
## Large tier L4 evidence (design_docs/planned/r1/starmap-large-tier-and-reach.md): the same
## views drawn with the medium stack (50,000 nearest GCNS stars) and the large stack (all
## 331,311), to be opened side by side:
##   rest       at Sol, at rest, looking toward the galactic centre (no change expected: the
##              added stars are below the naked-eye limit);
##   g707       at Sol, gamma 707 toward the galactic centre, looking forward through a 1 deg (Godot's minimum)
##              field (aberration folds the whole forward hemisphere into 1/gamma = 0.08 deg; more
##              stars expected in the starbow: forward boosting lifts the faint M dwarfs);
##   g707stars  the same with the CMB and panorama off: at gamma 707 the boosted CMB (~3,850 K)
##              fills the forward cone and the meter exposes for it, hiding the stars;
##   ly50       50 ly from Sol toward l 0, b +30, at rest, looking back at Sol (nearby faint
##              stars shifted by parallax).
## Fixed EV for rest and ly50 (the dark-adapted EV - 2, as the tour captures), eye metering for
## g707. metrics.json records each view's stack, star count and mean frame luminance.
##   godot --path . --script tools/starmap_sky_capture.gd -- [--out=DIR]   (GPU window; needs stars_large.bin)
var out := "res://renders/starmap_sky"
var sky: InteriorSky
var frame := 0
var records := []

func _initialize() -> void: run.call_deferred()

func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = Vector2i(1280, 720)
	sky = InteriorSky.new(); root.add_child(sky)
	sky.setup({"position_m": [0, 0, 0], "forward": [0, 0, 1], "up": [0, 1, 0]}, 78., root.size, {"stars": true, "background": true, "tier": "medium"})
	var rect := TextureRect.new(); rect.texture = sky.get_texture()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(rect)
	sky.set_temporal_exposure(false)
	var gc := {"x": 1.0, "y": 0.0, "z": 0.0} # galactic centre
	var b := deg_to_rad(30.0)
	var away := {"x": cos(b), "y": 0.0, "z": sin(b)}
	for tier in ["medium", "large"]:
		if not sky.starfield.load_tiers(tier):
			print("starmap-sky: %s FAIL %s" % [tier, sky.starfield.last_error]); quit(1); return
		sky.starfield._fill()
		await shot(tier, "rest", {"x": 0.0, "y": 0.0, "z": 0.0}, gc, 1.0, gc, true)
		await shot(tier, "g707", {"x": 0.0, "y": 0.0, "z": 0.0}, gc, 707.0, gc, false)
		await shot(tier, "g707stars", {"x": 0.0, "y": 0.0, "z": 0.0}, gc, 707.0, gc, false, false)
		await shot(tier, "ly50", {"x": 50.0 * away.x, "y": 0.0, "z": 50.0 * away.z}, away, 1.0, {"x": -away.x, "y": 0.0, "z": -away.z}, true)
	var f := FileAccess.open(out.path_join("metrics.json"), FileAccess.WRITE); f.store_string(JSON.stringify(records, "  ")); f.close()
	print("starmap-sky-capture: %d views" % records.size()); quit(0)

func zoom(fov: float) -> void:
	sky.view_fov = fov; sky.camera.fov = fov; sky.configure_pixel()

## bg false: the CMB/panorama off (env colour background, the meter sees the dark sky), so the
## boosted stars are not hidden under the boosted CMB.
func shot(tier: String, view: String, pos: Dictionary, heading: Dictionary, gamma: float, look: Dictionary, fixed: bool, bg := true) -> void:
	zoom(1.0 if gamma > 100.0 else 78.0)
	var had_bg := sky.has_background
	var mode := sky.env.background_mode
	if not bg:
		sky.has_background = false; sky.env.background_mode = Environment.BG_COLOR
	var beta := sqrt(1.0 - 1.0 / (gamma * gamma))
	sky.exposure.fixed = fixed
	if fixed: sky.exposure.fixed_ev = sky.exposure.ev_dark() - 2.
	sky.apply({"ship": {"heading": heading, "beta": beta, "gamma": gamma, "one_minus_beta": 1.0 / (gamma * gamma * (1.0 + beta)), "pos": pos}, "params": {}})
	var w := SkyFrame.to_world64(PackedFloat64Array([look.x, look.y, look.z]))
	var n := Vector3(w[0], w[1], w[2]).normalized()
	for i in 12:
		sky.camera.look(atan2(-n.x, -n.z), asin(clampf(n.y, -1., 1.)), 0.)
		frame += 1; sky.finish_exposure_frame(1. / 60., frame)
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var name := "%s_%s" % [view, tier]
	img.save_png(out.path_join(name + ".png"))
	var lum := 0.0
	var lit := 0
	for y in range(0, img.get_height(), 2):
		for x in range(0, img.get_width(), 2):
			var l := img.get_pixel(x, y).get_luminance()
			lum += l
			if l > 0.25: lit += 1
	var px := (img.get_height() / 2) * (img.get_width() / 2)
	records.append({"name": name, "tier": tier, "stars": sky.starfield.count, "mean_luminance": lum / px, "pixels_over_0.25": lit, "gamma": gamma})
	sky.has_background = had_bg; sky.env.background_mode = mode
	print("SKY %s: %d stars in the stack, mean luminance %.4f, %d sampled pixels > 0.25" % [name, sky.starfield.count, lum / px, lit])
