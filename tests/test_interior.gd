extends SceneTree
## M4.2 the iso interior (design m4-first-journey.md "M4.2"): the five-layer composite, one
## tonemap, the forward-glow CPU mirror, walking on WALK_, the captain avatar, the bundle's
## optional typed fields, clamped plate parallax and the export staging. Headless:
##   godot --headless --path . --script tests/test_interior.gd      (make interior-test)
## The GPU halves (G-M4-1..4) are in tools/interior_golden.gd (make golden).

const FIXTURE := "res://tests/fixtures/areas/bridge_blockout"
const BRIDGE := "res://assets/areas/bridge"
const CAPTAIN := "res://assets/characters/captain"
const TMP := "res://.godot/tmp/test_interior"
## tools/glow_probe (sunholo/relativity 0.7.0 glowEmittanceAt, n 0.1 cm^-3, eps 1e-9,
## f_in 0.5), VM = interpreter. [cos theta, emittance W/m^2] at 0, 45, 80, 90, 120 deg.
## Written in e-notation: Godot 4.7 parses long plain decimals inexactly (0.000...0589 -> 0.0).
const PROBE := {
	"b099": {"pole": 9.628776871706524e-05, "mean": 2.407194217926631e-05, "rows": [
		[1.0, 9.628776871706524e-05], [0.7071067811865476, 6.808573420515876e-05],
		[0.17364817766693041, 1.672019556933325e-05],
		[6.123233995736757e-17, 5.895925387819721e-21],
		[-0.4999999999999998, 0.0]]},
	"cap": {"pole": 1.1250843031053142, "mean": 0.28127107577632854, "rows": [
		[1.0, 1.1250843031053142], [0.7071067811865476, 0.7955547401323088],
		[0.17364817766693041, 0.19536883895590618],
		[6.123233995736757e-17, 6.889154452844258e-17],
		[-0.4999999999999998, 0.0]]},
}
const PROBE_LM_PER_W := 182.5654375783963

var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


func rel(a: float, b: float) -> float:
	return absf(a - b) / maxf(absf(b), 1e-300)


func write_json(path: String, d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))
	f.close()


func copy_dir(src: String, dst: String, suffix := "") -> void:
	DirAccess.make_dir_recursive_absolute(dst)
	for f in DirAccess.get_files_at(src):
		DirAccess.copy_absolute(src.path_join(f), dst.path_join(f + suffix))


func test_glow_mirror() -> void:
	print("Forward glow: CPU mirror of glowEmittanceAt (package 0.7.0 probe), within 1e-12 relative")
	for speed: String in PROBE:
		var p: Dictionary = PROBE[speed]
		for row: Array in p["rows"]:
			var got := ForwardGlow.profile(p["pole"], row[0])
			var ok := absf(got - row[1]) <= 1e-12 * absf(row[1]) if row[1] != 0.0 else got == 0.0
			check("%s glow_profile(pole, %.6f) = %s (package %s)" % [speed, row[0], str(got), str(row[1])], ok)
		check("%s pole = 4 x glowInwardFlux (package mean %s)" % [speed, str(p["mean"])], rel(p["pole"], 4.0 * p["mean"]) < 1e-12)
	check("profile is 0 at rest (pole 0)", ForwardGlow.profile(0.0, 1.0) == 0.0)
	check("profile clamps a rounded-past-1 cosine to the pole", ForwardGlow.profile(2.0, 1.0000000000000002) == 2.0)
	check("profile propagates NaN (package parity, ailang#1419)", is_nan(ForwardGlow.profile(1.0, NAN)))
	check("Lambertian: radiance = emittance / pi", ForwardGlow.radiance(PI) == 1.0)
	check("efficacy equals the probe's equal-energy 380-780 nm value", ForwardGlow.LM_PER_W == PROBE_LM_PER_W)
	var w := ForwardGlow.WHITE_RGB
	check("glow colour has unit luminance (illuminant E in linear sRGB)", absf(0.2126729 * w.x + 0.7151522 * w.y + 0.0721750 * w.z - 1.0) < 1e-6)
	# the wall point the panorama camera's rays reach (the camera is not at the bubble centre)
	var c := PackedFloat64Array([0.0, 0.0, 0.0])
	check("wall_cos from the centre = the ray's own z", absf(ForwardGlow.wall_cos(c, PackedFloat64Array([0.6, 0.0, 0.8]), 100.0) - 0.8) < 1e-15)
	var cam := PackedFloat64Array([16.0, -8.0, 83.7])
	var up := ForwardGlow.wall_cos(cam, PackedFloat64Array([0.0, 0.0, 1.0]), 100.0)
	check("wall_cos straight up from the bridge camera: sqrt(R^2 - x^2 - y^2) / R", absf(up - sqrt(10000.0 - 256.0 - 64.0) / 100.0) < 1e-15, str(up))
	var side := ForwardGlow.wall_cos(cam, PackedFloat64Array([1.0, 0.0, 0.0]), 100.0)
	check("wall_cos sideways from the bridge camera keeps the camera's height", absf(side - 0.837) < 1e-15, str(side))
	check("wall_cos is NaN outside the bubble", is_nan(ForwardGlow.wall_cos(PackedFloat64Array([0, 0, 120]), PackedFloat64Array([0, 0, 1]), 100.0)))
	check("pole_of reads ship.ism.glow_pole_w_m2", ForwardGlow.pole_of({"ship": {"ism": {"glow_pole_w_m2": 9.6e-5}}}) == 9.6e-5)
	check("pole_of: no field -> -1 (glow off; never derived from glow_w_m2)", ForwardGlow.pole_of({"ship": {"ism": {"glow_w_m2": 2.4e-5}}}) == -1.0)


func test_bundle_fields() -> void:
	print("AreaBundle: optional typed play_origin_ship_m and layers.play.plate (bridge v2 hook)")
	var b := AreaBundle.load_dir(BRIDGE)
	check("bridge v1 loads", b.ok(), str(b.errors))
	check("play_origin_ship_m read typed [0, 0, 82]", b.play_origin_ship_m() == PackedFloat64Array([0.0, 0.0, 82.0]))
	check("glTF -> ship frame: glTF +Y up is ship +Z, origin added", b.glb_to_ship(Vector3(1.0, 2.0, 3.0)) == PackedFloat64Array([1.0, -3.0, 84.0]))
	var f := AreaBundle.load_dir(FIXTURE)
	check("fixture has no play_origin_ship_m: defaults to the bubble centre, no error", f.ok() and f.play_origin_ship_m() == PackedFloat64Array([0.0, 0.0, 0.0]))
	check("no layers.play.plate in v1: has_play_plate() false", not b.has_play_plate())
	var m: Dictionary = b.manifest.duplicate(true)
	m["play_origin_ship_m"] = [0.0, 82.0]
	check("control: play_origin_ship_m with 2 numbers is refused", not AreaBundle.check_manifest(m).is_empty())
	m["play_origin_ship_m"] = "0 0 82"
	check("control: play_origin_ship_m as a string is refused", not AreaBundle.check_manifest(m).is_empty())
	m = b.manifest.duplicate(true)
	m["layers"]["play"]["plate"] = {"file": "plate_bridge.png"}
	check("layers.play.plate {file} accepted", AreaBundle.check_manifest(m).is_empty(), str(AreaBundle.check_manifest(m)))
	m["layers"]["play"]["plate"] = {"file": 3}
	check("control: layers.play.plate.file must be a string", not AreaBundle.check_manifest(m).is_empty())
	m = b.manifest.duplicate(true)
	m["layers"]["play"]["camera"] = 7
	check("control: layers.play.camera must be a string", not AreaBundle.check_manifest(m).is_empty())
	check("bridge pan_range_m read typed [6, 3]", b.pan_range_m() == Vector2(6.0, 3.0))
	var m2: Dictionary = b.manifest.duplicate(true)
	m2.erase("pan_range_m")
	var b2 := AreaBundle.new()
	b2.manifest = m2
	b2.camera = b.camera
	var derived := b2.pan_range_m()
	check("without pan_range_m the overscan sets it: fg 1296 px / (1.6 x 135 px/m) = 6 m, 656 / 216 = 3.04 m", absf(derived.x - 6.0) < 1e-5 and absf(derived.y - 656.0 / 216.0) < 1e-5, str(derived))
	check("no overscan (blockout): no pan limit", f.pan_range_m() == Vector2.INF)
	m2["pan_range_m"] = [6, -1]
	check("control: a negative pan_range_m is refused", not AreaBundle.check_manifest(m2).is_empty())
	check("bridge iso camera JSON read (orthographic, size 16, v_offset 6.08)", b.iso_camera().get("projection") == "orthographic" and b.iso_camera().get("v_offset_m") == 6.08)
	check("fixture iso camera falls back to the manifest angles", f.iso_camera().get("pitch_deg") == -14.0 and f.iso_camera().get("yaw_deg") == 45.0 and f.iso_camera().get("size_m") == 16.0)


func test_staging() -> void:
	print("Export staging: a bundle staged as <file>.bin (assets/areas is .gdignore'd) loads the same")
	var dst := TMP.path_join("staged/bridge")
	copy_dir(FIXTURE, dst, ".bin")
	var b := AreaBundle.load_dir(dst)
	check("staged bundle loads from .bin files", b.ok(), str(b.errors))
	var img := b.load_image("panorama")
	var want := Image.load_from_file(FIXTURE.path_join("pano_bridge.png"))
	check("staged panorama decodes to the source pixels", img != null and img.get_size() == want.get_size() and img.get_data() == want.get_data())
	var glb := b.instantiate_play()
	check("staged GLB loads", glb != null)
	if glb != null:
		glb.free()
	check("resolve_dir finds the source checkout's bundle first", AreaBundle.resolve_dir("bridge") == BRIDGE)
	check("resolve_dir falls back to the export staging dir", AreaBundle.resolve_dir("nowhere") == "res://areas_bundle/nowhere")


func test_parallax() -> void:
	print("Plate parallax: pan factor x pixels per metre, clamped at the overscan")
	var ppm := 1080.0 / 16.0
	var s := 1080.0 / 2160.0 # screen px per plate px
	var pano_os := Vector2(128, 64)
	var fg_os := Vector2(1296, 656)
	var p := Interior.plate_shift(Vector2(2.0, 1.0), 0.15, ppm, pano_os, s)
	check("pano shift at pan (2, 1) m = -p x 0.15 x ppm (x), +q x 0.15 x ppm (y)", p.distance_to(Vector2(-2.0 * 0.15 * ppm, 1.0 * 0.15 * ppm)) < 1e-9, str(p))
	var edge := Interior.plate_shift(Vector2(6.0, 3.0), 1.6, ppm, fg_os, s)
	check("fg at the [6, 3] m range edge stays inside its overscan", absf(edge.x) <= fg_os.x * s + 1e-9 and absf(edge.y) <= fg_os.y * s + 1e-9, str(edge))
	var far := Interior.plate_shift(Vector2(10.0, -7.0), 1.6, ppm, fg_os, s)
	check("fg beyond the range is clamped at the overscan (no plate edge on screen)", far == Vector2(-fg_os.x * s, -fg_os.y * s), str(far))
	var farp := Interior.plate_shift(Vector2(-10.0, 7.0), 0.15, ppm, pano_os, s)
	check("pano beyond the range is clamped at its overscan", farp == Vector2(pano_os.x * s, pano_os.y * s), str(farp))
	check("no overscan (blockout): plates stay put", Interior.plate_shift(Vector2(3.0, 1.0), 0.15, ppm, Vector2.ZERO, s) == Vector2.ZERO)


func test_composite() -> void:
	print("Composite: layer order, pan factors, one tonemap, placeholder tag (fixture and bridge v1)")
	for dir in [FIXTURE, BRIDGE]:
		var it := Interior.new()
		var ok := it.setup(AreaBundle.load_dir(dir), {"background": false, "stars": false, "size": Vector2i(960, 540)})
		root.add_child(it)
		check("%s: interior builds" % dir.get_file(), ok, it.last_error)
		var layers := it.layer_nodes()
		var order := []
		for name in Interior.LAYERS:
			order.append(layers[name].layer if layers.has(name) else 999)
		var sorted := order.duplicate()
		sorted.sort()
		check("%s: canvas order sky < panorama < play < foreground < hud" % dir.get_file(), order == sorted and not 999 in order, str(order))
		check("%s: pan factors 0 / 0.15 / 1 / 1.6" % dir.get_file(),
			[it.pan_factor("sky"), it.pan_factor("panorama"), it.pan_factor("play"), it.pan_factor("foreground")] == [0.0, 0.15, 1.0, 1.6])
		check("%s: no WorldEnvironment outside the sky/play SubViewports (the parent never tonemaps)" % dir.get_file(), it.environments_outside_subviewports().is_empty())
		check("%s: sky SubViewport tonemaps once with AgX" % dir.get_file(), it.sky.env.tonemap_mode == Environment.TONE_MAPPER_AGX)
		check("%s: sky texture shown raw (no material, white modulate)" % dir.get_file(), it.sky_rect.material == null and it.sky_rect.modulate == Color.WHITE and it.sky_rect.self_modulate == Color.WHITE)
		check("%s: sky mirrored back to the camera JSON's handedness (galactic_to_world has det -1)" % dir.get_file(), it.sky_rect.flip_h == Interior.SKY_FLIP_H
			and is_equal_approx(Basis(Starfield.galactic_to_world(Vector3(1, 0, 0)), Starfield.galactic_to_world(Vector3(0, 1, 0)), Starfield.galactic_to_world(Vector3(0, 0, 1))).determinant(), -1.0 if Interior.SKY_FLIP_H else 1.0))
		check("%s: the play layer renders over a transparent background (the sky shows through)" % dir.get_file(), it.play_view.transparent_bg and it.play_env.background_mode == Environment.BG_CLEAR_COLOR)
		var tag := it.bundle.placeholder
		check("%s: placeholder tag %s" % [dir.get_file(), "shown" if tag else "hidden"], it.tag_label.visible == tag and (it.tag_label.text == AreaBundle.HUD_TAG or not tag))
		it.set_pan(Vector2(20.0, 0.0))
		check("%s: sky layer never pans" % dir.get_file(), it.sky_rect.position == Vector2.ZERO)
		it.queue_free()
	await process_frame


func test_walk() -> void:
	print("Walking: the avatar stays on WALK_ (fixture and bridge v1)")
	for dir in [FIXTURE, BRIDGE]:
		var b := AreaBundle.load_dir(dir)
		var scene := b.instantiate_play()
		var w := WalkArea.from_scene(scene, 0.35)
		check("%s: walk triangles found" % dir.get_file(), w.triangle_count() > 0, str(w.triangle_count()))
		check("%s: at least one spawn" % dir.get_file(), not w.spawns.is_empty())
		var sp: Vector3 = w.spawn_point()
		check("%s: the spawn is walkable" % dir.get_file(), w.is_walkable(sp), str(sp))
		check("%s: 60 m off the deck is not walkable" % dir.get_file(), not w.is_walkable(Vector3(60.0, 0.0, 60.0)))
		var p := sp
		var off := 0
		for i in 400: # walk straight out for 80 m: the avatar must stop at the edge
			p = w.step(p, Vector3(0.2, 0.0, 0.07))
			if not w.is_walkable(p):
				off += 1
		check("%s: walking into the rim stops on the deck (400 steps, 0 off)" % dir.get_file(), off == 0 and w.is_walkable(p), "%d off, end %s" % [off, p])
		check("%s: the avatar stands on the walk surface height" % dir.get_file(), absf(p.y - w.height_at(p.x, p.z)) < 1e-6)
		check("%s: interactables found" % dir.get_file(), not w.interactables.is_empty())
		scene.free()
	var bridge := AreaBundle.load_dir(BRIDGE).instantiate_play()
	var wb := WalkArea.from_scene(bridge, 0.35)
	var nav: AABB = wb.interactables.get("console_navigation_0", AABB())
	check("bridge: the navigation console's footprint is not walkable (obstacle)", nav.size != Vector3.ZERO and not wb.is_walkable(nav.get_center()))
	check("bridge: a point beside the nav console is in reach", wb.nearest_interactable(wb.closest_walkable(nav.get_center()), 1.5) != "")
	var route := wb.path(wb.spawn_point(), nav.get_center())
	var on := true
	for q in route:
		on = on and wb.is_walkable(q)
	check("bridge: a walkable route from the spawn to the nav console (%d points)" % route.size(), route.size() > 1 and on and wb.nearest_interactable(route[route.size() - 1], 1.5).begins_with("console_navigation"))
	bridge.free()
	# the avatar's walk never talks to the sim: the walk/avatar scripts hold no sim reference
	for f in ["res://interior/walk.gd", "res://interior/captain_avatar.gd"]:
		var src := FileAccess.get_file_as_string(f)
		check("%s has no sim / SimBridge reference" % f.get_file(), not src.contains("SimBridge") and not src.contains(".send("))


func test_avatar() -> void:
	print("Captain avatar: life stage from years since departure, facing from movement, feet at the anchor, 720 px/m")
	check("stage 0 at 0 yr", CaptainAvatar.stage_for(0.0, [0, 20, 40, 60]) == 0)
	check("stage 0 at 19.99 yr", CaptainAvatar.stage_for(19.99, [0, 20, 40, 60]) == 0)
	check("stage 20 at 20 yr", CaptainAvatar.stage_for(20.0, [0, 20, 40, 60]) == 20)
	check("stage 40 at 45 yr", CaptainAvatar.stage_for(45.0, [0, 20, 40, 60]) == 40)
	check("stage 60 at 100 yr", CaptainAvatar.stage_for(100.0, [0, 20, 40, 60]) == 60)
	check("negative years clamp to the first stage", CaptainAvatar.stage_for(-1.0, [0, 20, 40, 60]) == 0)
	var a := CaptainAvatar.new()
	check("manifest loads (8 sprites)", a.load_dir(CAPTAIN), a.last_error)
	check("pixel size = 1/720 m (manifest px_per_m; Godot stores it as float32)", absf(a.pixel_size * 720.0 - 1.0) < 1e-7)
	check("starts facing front", a.facing == "front")
	a.set_motion(Vector2(0.0, -1.0))
	check("moving up the screen faces back", a.facing == "back")
	a.set_motion(Vector2(1.0, 0.0))
	check("moving sideways keeps the facing", a.facing == "back")
	a.set_motion(Vector2(0.3, 0.8))
	check("moving down the screen faces front", a.facing == "front")
	a.set_motion(Vector2.ZERO)
	check("standing still keeps the facing", a.facing == "front")
	a.set_years(41.5)
	check("41.5 ship-yr shows the y40 front sprite", a.stage == 40 and a.texture == a.textures["y40_front"])
	var foot := a.anchor_local()
	check("foot anchor (512, 1440) px sits at the node origin", foot.length() < 1e-6, str(foot))
	a.free()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(TMP)
	test_glow_mirror()
	test_bundle_fields()
	test_staging()
	test_parallax()
	await test_composite()
	test_walk()
	test_avatar()
	print("interior: %d passed, %d failures" % [passes, failures])
	quit(1 if failures > 0 else 0)


func _init() -> void:
	_run.call_deferred()
