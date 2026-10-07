extends SceneTree
## Star truth AC5 (design_docs/planned/r1/starmap-single-truth.md): an ordinary map
## journey from Sol to a destination stops 1,000 AU short of its stars.json
## position. Renders the arrival view toward the destination with the sky stack
## of this branch ("after") and, when given, the stack of another checkout's
## committed tiers ("before"), and records where the rendered star actually is.
##   godot --path . --script tools/starmap_arrival_capture.gd -- [--before=DIR] [--out=DIR]   (GPU window)
## DIR holds stars_{medium,quick,bright}.{bin,json} and stars.json (e.g. git show origin/main:...).
const DESTINATIONS := [
	["Gaia DR3 2635476908753563008", "trappist1"],
	["Gaia DR3 816649002967779584", "10uma_gj332"],
	["Gaia DR3 2940211607277084672", "gj10940"],
	["Gaia DR3 6187779556809793024", "gj11892"]]
const AU_PER_LY := 63241.077
var out := "res://renders/starmap_arrival"
var before := ""
var sky: InteriorSky
var frame := 0
var records := []
var failures := 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--before="): before = a.trim_prefix("--before=")
		if a.begins_with("--out="): out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = Vector2i(1280, 720)
	sky = InteriorSky.new(); root.add_child(sky)
	sky.setup({"position_m": [0, 0, 0], "forward": [0, 0, 1], "up": [0, 1, 0]}, 60., root.size, {"stars": true, "background": true, "tier": "medium"})
	var rect := TextureRect.new(); rect.texture = sky.get_texture()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(rect)
	sky.exposure.fixed = true; sky.exposure.fixed_ev = sky.exposure.ev_dark() - 2.; sky.set_temporal_exposure(false)
	var nav: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).stars
	var stacks := [["after", "res://data/starmap"]]
	if before != "": stacks.push_front(["before", before])
	for st in stacks:
		if not sky.starfield.load_tiers("medium", st[1]):
			print("starmap-arrival: %s stack FAIL %s" % [st[0], sky.starfield.last_error]); quit(1); return
		sky.starfield._fill()
		for d in DESTINATIONS:
			var row := {}
			for s: Dictionary in nav:
				if s.id == d[0]: row = s
			if row.is_empty(): print("missing ", d[0]); failures += 1; continue
			await shot(st[0], d[1], row)
	var f := FileAccess.open(out.path_join("metrics.json"), FileAccess.WRITE); f.store_string(JSON.stringify(records, "  ")); f.close()
	print("starmap-arrival-capture: %d failures" % failures); quit(1 if failures else 0)

## The ship at the stand-off on the Sol -> star line, at rest, looking at the navigation position.
func shot(stack: String, slug: String, row: Dictionary) -> void:
	var p := PackedFloat64Array([row.x, row.y, row.z])
	var r := sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2])
	var k := 1.0 - (Transit.STANDOFF_AU / AU_PER_LY) / r
	var ship := {"x": p[0] * k, "y": p[1] * k, "z": p[2] * k}
	var unit := {"x": p[0] / r, "y": p[1] / r, "z": p[2] / r}
	sky.apply({"ship": {"heading": unit, "beta": 0.0, "gamma": 1.0, "pos": ship}, "params": {}})
	var w := SkyFrame.to_world64(PackedFloat64Array([p[0] - ship.x, p[1] - ship.y, p[2] - ship.z]))
	var n := Vector3(w[0], w[1], w[2]).normalized()
	for i in 6:
		sky.camera.look(atan2(-n.x, -n.z), asin(clampf(n.y, -1., 1.)), 0.)
		frame += 1; sky.finish_exposure_frame(1. / 60., frame)
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var name := "%s_%s" % [slug, stack]
	img.save_png(out.path_join(name + ".png"))
	# where the stack draws this identity, relative to the ship
	var sf := sky.starfield
	var drawn := -1.0
	var ahead := -1.0
	for alias: String in Starfield.aliases_of(str(row.id)):
		var j := sf.index_of(alias)
		if j < 0: continue
		var q := SkyFrame.to_galactic64(PackedFloat64Array([sf.pos[3 * j], sf.pos[3 * j + 1], sf.pos[3 * j + 2]]))
		var dx: float = q[0] - ship.x
		var dy: float = q[1] - ship.y
		var dz: float = q[2] - ship.z
		drawn = sqrt(dx * dx + dy * dy + dz * dz) * AU_PER_LY
		ahead = rad_to_deg(acos(clampf((dx * unit.x + dy * unit.y + dz * unit.z) / (drawn / AU_PER_LY), -1., 1.)))
	var c := Vector2i(root.size / 2)
	var peak := 0.0
	for y in range(c.y - 4, c.y + 5):
		for x in range(c.x - 4, c.x + 5):
			peak = maxf(peak, img.get_pixel(x, y).get_luminance())
	records.append({"name": name, "id": row.id, "stack": stack, "nav_dist_ly": r, "drawn_from_ship_au": drawn, "off_axis_deg": ahead, "centre_peak": peak})
	print("ARRIVAL %s: drawn %.0f AU from the ship (navigation 1000), %.3f deg off the view axis, centre peak %.3f" % [name, drawn, ahead, peak])
