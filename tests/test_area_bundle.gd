extends SceneTree
## M4.0 area bundles: the loader (interior/area_bundle.gd) and `make validate-areas`
## (tools/validate_area.gd) on the blockout fixture, plus positive controls: every check must
## FAIL on a bundle broken in its way. Run:
##   godot --headless --path . --script tests/test_area_bundle.gd
## Exits non-zero on any failure.

const Validate := preload("res://tools/validate_area.gd")
const FIXTURE := "res://tests/fixtures/areas/bridge_blockout"
const TMP := "res://.godot/tmp/test_area_bundle" # gitignored, inside the checkout

var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


## A fresh copy of the fixture under user://, for breaking.
func copy_fixture(case: String) -> String:
	var dst := TMP.path_join(case)
	DirAccess.make_dir_recursive_absolute(dst)
	for f in DirAccess.get_files_at(FIXTURE):
		DirAccess.copy_absolute(FIXTURE.path_join(f), dst.path_join(f))
	return dst


func read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func write_json(path: String, d: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))
	f.close()


## the named check's result in a validator run ({} if it did not run)
func result(checks: Array[Dictionary], prefix: String) -> Dictionary:
	for c in checks:
		if c["name"].begins_with(prefix):
			return c
	return {}


func all_pass(checks: Array[Dictionary]) -> bool:
	for c in checks:
		if not c["ok"]:
			print("        %s: %s" % [c["name"], c["detail"]])
			return false
	return not checks.is_empty()


func test_loader() -> void:
	print("Area bundle loader (brief §9, V17)")
	var b := AreaBundle.load_dir(FIXTURE)
	check("fixture loads", b.ok(), "; ".join(b.errors))
	check("fixture is area bridge", b.ok() and b.area() == "bridge")
	check("placeholder: true surfaces the HUD tag", b.hud_tag() == "placeholder art", b.hud_tag())
	check("layer paths follow the brief names", b.ok() and b.path("panorama").ends_with("pano_bridge.png")
		and b.path("play").ends_with("play_bridge.glb") and b.path("foreground").ends_with("fg_bridge.png"))
	check("camera loaded (78 deg vertical fov)", b.camera.get("fov_vertical_deg") == 78.0)
	var play := b.instantiate_play()
	check("play GLB instantiates at runtime (no import step)", play != null)
	if play != null:
		play.free()

	# unknown keys are kept and ignored; placeholder defaults to false
	var d := copy_fixture("unknown_keys")
	var m := read_json(d.path_join("manifest.json"))
	m.erase("placeholder")
	m["palette_note"] = "cream deck"
	m["future_brief_field"] = {"levels": [1, 2, 3]}
	write_json(d.path_join("manifest.json"), m)
	b = AreaBundle.load_dir(d)
	check("unknown keys do not break the loader", b.ok(), "; ".join(b.errors))
	check("unknown keys are kept in manifest", b.manifest.get("future_brief_field", {}).get("levels") == [1.0, 2.0, 3.0])
	check("placeholder defaults to false (no HUD tag)", not b.placeholder and b.hud_tag() == "")

	# a missing layer is refused, naming the layer
	for layer in [["foreground", "fg_bridge.png"], ["panorama", "pano_bridge.png"], ["play", "play_bridge.glb"]]:
		d = copy_fixture("missing_" + layer[0])
		DirAccess.remove_absolute(d.path_join(layer[1]))
		b = AreaBundle.load_dir(d)
		check("missing %s layer is refused" % layer[0], not b.ok() and "; ".join(b.errors).contains("missing layer " + layer[0]), "; ".join(b.errors))
	d = copy_fixture("missing_camera")
	DirAccess.remove_absolute(d.path_join("cam_bridge.json"))
	check("missing camera JSON is refused", not AreaBundle.load_dir(d).ok())

	d = copy_fixture("panorama_mismatch")
	var cm := read_json(d.path_join("cam_bridge.json"))
	cm["panorama"] = "stapledon_pano_bridge.png"
	write_json(d.path_join("cam_bridge.json"), cm)
	b = AreaBundle.load_dir(d)
	check("camera.panorama != layers.panorama.file is refused", not b.ok() and "; ".join(b.errors).contains("camera.panorama"), "; ".join(b.errors))

	# every V17 field is required
	for path in [["area"], ["camera"], ["focus_m"], ["sky_visible"], ["layers", "panorama", "parallax"],
			["layers", "play", "iso_pitch_deg"], ["layers", "play", "iso_yaw_deg"], ["layers", "play", "iso_size_m"],
			["layers", "foreground", "file"], ["layers", "foreground"]]:
		m = read_json(FIXTURE.path_join("manifest.json"))
		var node: Dictionary = m
		for i in path.size() - 1:
			node = node[path[i]]
		node.erase(path[-1])
		check("manifest without %s is refused" % ".".join(path), not AreaBundle.check_manifest(m).is_empty())
	m = read_json(FIXTURE.path_join("manifest.json"))
	m["layers"]["panorama"]["file"] = "panorama.png"
	check("non-brief file name is refused", not AreaBundle.check_manifest(m).is_empty())
	m = read_json(FIXTURE.path_join("manifest.json"))
	m["focus_m"] = [1.0, 2.0]
	check("focus_m of 2 numbers is refused", not AreaBundle.check_manifest(m).is_empty())
	m = read_json(FIXTURE.path_join("manifest.json"))
	m["placeholder"] = "yes"
	check("non-bool placeholder is refused", not AreaBundle.check_manifest(m).is_empty())

	# camera schema (brief §5.2)
	var cam := read_json(FIXTURE.path_join("cam_bridge.json"))
	check("fixture camera schema is clean", AreaBundle.check_camera(cam).is_empty(), "; ".join(AreaBundle.check_camera(cam)))
	var bad := cam.duplicate(true)
	bad["forward"] = [0.0, 0.0, 2.0]
	check("non-unit camera forward is refused", not AreaBundle.check_camera(bad).is_empty())
	bad = cam.duplicate(true)
	bad["up"] = bad["forward"]
	check("camera up not orthogonal to forward is refused", not AreaBundle.check_camera(bad).is_empty())
	bad = cam.duplicate(true)
	bad.erase("fov_vertical_deg")
	check("camera without fov_vertical_deg is refused", not AreaBundle.check_camera(bad).is_empty())
	bad = cam.duplicate(true)
	bad["frame"] = "blender: Z up"
	check("camera in another frame is refused (frame contract)", not AreaBundle.check_camera(bad).is_empty())
	bad = cam.duplicate(true)
	bad["resolution"] = [1920.5, 1080]
	check("non-integer resolution is refused", not AreaBundle.check_camera(bad).is_empty())

	# projection: the centre ray projects to the frame centre and unproject inverts project
	var o: Array = cam["position_m"]
	var f: Array = cam["forward"]
	var c := AreaBundle.project(cam, [o[0] + 50.0 * f[0], o[1] + 50.0 * f[1], o[2] + 50.0 * f[2]])
	check("forward ray lands on the frame centre", absf(c[0] - 960.0) < 1e-6 and absf(c[1] - 540.0) < 1e-6, str(c))
	var r := AreaBundle.unproject(cam, 123.25, 987.5)
	var q := AreaBundle.project(cam, [o[0] + 30.0 * r[0], o[1] + 30.0 * r[1], o[2] + 30.0 * r[2]])
	check("project(unproject(px)) = px to 1e-6 px", absf(q[0] - 123.25) < 1e-6 and absf(q[1] - 987.5) < 1e-6, str(q))
	# the bridge needle tip [0, 0, 98] at 4K lands where the Blender bundle's own check put it
	var cam4k := cam.duplicate(true)
	cam4k["resolution"] = [3840, 2160]
	var n := AreaBundle.project(cam4k, [0.0, 0.0, 98.0])
	check("needle tip at 4K = (1920, 1437.42) (Blender validation.json, independent)", absf(n[0] - 1920.0) < 0.01 and absf(n[1] - 1437.4249) < 0.01, str(n))


func test_validator() -> void:
	print("validate-areas (tools/validate_area.gd)")
	var checks := Validate.validate(FIXTURE)
	check("fixture passes every check (%d)" % checks.size(), all_pass(checks))
	check("fixture run covers alpha, round trip and GLB", not result(checks, "alpha: panorama").is_empty()
		and not result(checks, "round trip: anchor").is_empty() and not result(checks, "glb: Y up").is_empty())
	checks = Validate.validate("res://assets/areas/bridge")
	check("assets/areas/bridge (current bundle) passes", all_pass(checks))

	# alpha positive controls on small synthetic plates
	var img := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	img.fill_rect(Rect2i(0, 40, 64, 24), Color(1, 1, 1, 1)) # architecture along the bottom
	check("synthetic plate with clean space passes", Validate.check_alpha(img, "t", true, false)["ok"], Validate.check_alpha(img, "t", true, false)["detail"])
	var star := img.duplicate() as Image
	star.set_pixel(20, 10, Color(1, 1, 1, 1))
	check("a painted star (isolated speck) fails", not Validate.check_alpha(star, "t", true, false)["ok"])
	var haze := img.duplicate() as Image
	haze.fill_rect(Rect2i(10, 5, 20, 10), Color(0.3, 0.2, 0.5, 3.0 / 255.0))
	check("faint painted haze (alpha 3/255) fails", not Validate.check_alpha(haze, "t", true, false)["ok"])
	var opaque := img.duplicate() as Image
	opaque.fill(Color(0, 0, 0.02, 1))
	check("an opaque plate (space painted over) fails", not Validate.check_alpha(opaque, "t", true, false)["ok"])
	var rgb := Image.create_empty(64, 64, false, Image.FORMAT_RGB8)
	check("a plate without an alpha channel fails", not Validate.check_alpha(rgb, "t", true, false)["ok"])
	var edge := img.duplicate() as Image
	for x in 64:
		edge.set_pixel(x, 39, Color(1, 1, 1, 8.0 / 255.0)) # anti-aliased edge next to solid
	check("a faint anti-aliased edge beside solid pixels passes", Validate.check_alpha(edge, "t", true, false)["ok"])
	var fg := img.duplicate() as Image
	fg.fill_rect(Rect2i(28, 28, 4, 4), Color(1, 1, 1, 1))
	check("a foreground with art across the centre fails", not Validate.check_alpha(fg, "t", true, true)["ok"])

	var fgwide := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	fgwide.fill(Color(0.2, 0.1, 0.3, 1)) # silhouettes everywhere but the centre box
	fgwide.fill_rect(Rect2i(16, 12, 32, 40), Color(0, 0, 0, 0))
	var fw := Validate.check_alpha(fgwide, "t", true, true)
	check("a foreground covering most of the frame (centre clear) fails", not fw["ok"] and fw["detail"].contains("foreground covers"), fw["detail"])

	# overscan (m4-2-requirements §4): the foreground rules apply to the centre VIEW region
	var os_plate := Image.create_empty(128, 64, false, Image.FORMAT_RGBA8)
	os_plate.fill(Color(0, 0, 0, 0))
	var view := Rect2i(40, 16, 48, 32) # its centre box: x 54-73, y 24-40
	os_plate.fill_rect(Rect2i(40, 30, 10, 4), Color(1, 1, 1, 1)) # in the full-plate centre box, outside the view's
	var ov := Validate.check_alpha(os_plate, "t", true, true, view)
	check("overscanned fg: art in the margin-shifted full-plate centre passes (view centre clear)", ov["ok"], ov["detail"])
	check("same plate measured as a whole fails (control for the view region)", not Validate.check_alpha(os_plate, "t", true, true)["ok"])
	var os_bad := os_plate.duplicate() as Image
	os_bad.fill_rect(Rect2i(60, 30, 4, 4), Color(1, 1, 1, 1))
	check("overscanned fg: art in the view's centre box fails", not Validate.check_alpha(os_bad, "t", true, true, view)["ok"])
	var os_margin := Image.create_empty(128, 64, false, Image.FORMAT_RGBA8)
	os_margin.fill(Color(0.2, 0.1, 0.3, 1)) # opaque margin all round: 81% of the plate
	os_margin.fill_rect(view, Color(0, 0, 0, 0))
	os_margin.fill_rect(Rect2i(40, 44, 48, 4), Color(0.2, 0.1, 0.3, 1)) # a bottom band inside the view
	var om := Validate.check_alpha(os_margin, "t", true, true, view)
	check("overscanned fg: mostly-clear is measured on the view (opaque margins allowed)", om["ok"], om["detail"])

	# whole-bundle positive controls: a broken alpha and broken camera JSON must fail
	var d := copy_fixture("broken_alpha")
	var pano := Image.load_from_file(d.path_join("pano_bridge.png"))
	pano.set_pixel(300, 100, Color(1, 1, 1, 1))
	pano.save_png(d.path_join("pano_bridge.png"))
	checks = Validate.validate(d)
	check("bundle with a painted star in the panorama fails alpha", not result(checks, "alpha: panorama").get("ok", true), str(result(checks, "alpha: panorama")))

	d = copy_fixture("broken_cam_json")
	var f := FileAccess.open(d.path_join("cam_bridge.json"), FileAccess.WRITE)
	f.store_string("{\"shot\": \"bridge\", \"forward\": [0, 0, 1")
	f.close()
	checks = Validate.validate(d)
	check("bundle with truncated camera JSON fails schema", not result(checks, "schema").get("ok", true))

	d = copy_fixture("moved_camera")
	var cam := read_json(d.path_join("cam_bridge.json"))
	cam["position_m"] = [16.0, -8.0, 80.0] # 3.7 m low: the needle no longer lands on itself
	write_json(d.path_join("cam_bridge.json"), cam)
	checks = Validate.validate(d)
	check("camera moved 3.7 m: needle image check fails", not result(checks, "round trip: needle visible").get("ok", true), str(result(checks, "round trip: needle visible")))

	# the needle tolerance is one-sided: the solid top may sit up to 2.5 px ABOVE the projected tip
	# (the ink outline) and at most 0.5 px below it. Shift the camera along its up vector so the
	# projected tip moves by a chosen number of pixels (fixture: solid top 1.71 px above the tip).
	for shift in [[-4.5, false], [4.5, false], [-2.5, false], [0.5, true]]:
		d = copy_fixture("needle_shift_%s" % shift[0])
		var moved := shifted_camera(read_json(FIXTURE.path_join("cam_bridge.json")), shift[0])
		write_json(d.path_join("cam_bridge.json"), moved[0])
		var nr := result(Validate.validate(d), "round trip: needle visible")
		check("camera shift moves the tip %+.1f px (got %+.3f): needle check %s" % [shift[0], moved[1], "passes" if shift[1] else "fails"],
			absf(moved[1] - shift[0]) < 0.05 and nr.get("ok", not shift[1]) == shift[1], str(nr))

	d = copy_fixture("wrong_declared_pixel")
	var m := read_json(d.path_join("manifest.json"))
	m["validation"]["needle_tip_pixel"] = [960.0, 721.0]
	write_json(d.path_join("manifest.json"), m)
	checks = Validate.validate(d)
	check("declared needle pixel 2.3 px off fails the round trip", not result(checks, "round trip: declared").get("ok", true), str(result(checks, "round trip: declared")))

	d = copy_fixture("off_resolution")
	cam = read_json(d.path_join("cam_bridge.json"))
	cam["resolution"] = [3840, 2160]
	write_json(d.path_join("cam_bridge.json"), cam)
	checks = Validate.validate(d)
	check("panorama size != camera resolution fails", not result(checks, "resolution: panorama").get("ok", true))

	# overscan bundles: pano = camera resolution (the camera spans the whole plate, widened fov);
	# each plate = view + 2 x its overscan_px, view = camera resolution - 2 x panorama overscan
	d = overscanned_fixture("overscan_ok", Vector2i(16, 8), Vector2i(64, 32), true)
	checks = Validate.validate(d)
	check("overscanned bundle (pano [16, 8], fg [64, 32]) passes every check", all_pass(checks))
	check("overscanned fg size is view + 2 x overscan (2048x1144)", result(checks, "resolution: foreground").get("ok", false), str(result(checks, "resolution: foreground")))
	d = overscanned_fixture("overscan_fg_unpadded", Vector2i(16, 8), Vector2i(64, 32), false)
	checks = Validate.validate(d)
	check("fg declaring overscan_px but not padded fails resolution", not result(checks, "resolution: foreground").get("ok", true), str(result(checks, "resolution: foreground")))
	d = copy_fixture("overscan_bad_type")
	m = read_json(d.path_join("manifest.json"))
	m["layers"]["foreground"]["overscan_px"] = [64, -2]
	write_json(d.path_join("manifest.json"), m)
	check("negative overscan_px is refused", not AreaBundle.load_dir(d).ok())

	# GLB positive controls: a Z-up export, centimetres, no SPAWN_/INTERACT_
	d = copy_fixture("z_up_glb")
	write_glb(d.path_join("play_bridge.glb"), Vector3(PI / 2.0, 0, 0), 1.0, true)
	checks = Validate.validate(d)
	check("Z-up GLB (walk surface vertical) fails Y up", not result(checks, "glb: Y up").get("ok", true), str(result(checks, "glb: Y up")))
	d = copy_fixture("cm_glb")
	write_glb(d.path_join("play_bridge.glb"), Vector3.ZERO, 100.0, true)
	checks = Validate.validate(d)
	check("centimetre GLB fails metres", not result(checks, "glb: metres").get("ok", true) or not result(checks, "glb: walk area").get("ok", true))
	d = copy_fixture("huge_glb")
	write_glb(d.path_join("play_bridge.glb"), Vector3.ZERO, 1.0, true, 5000.0)
	checks = Validate.validate(d)
	check("a 5 km mesh outside the walk area fails metres on its own", not result(checks, "glb: metres").get("ok", true)
		and result(checks, "glb: walk area").get("ok", false), str(result(checks, "glb: metres")))
	d = copy_fixture("bare_glb")
	write_glb(d.path_join("play_bridge.glb"), Vector3.ZERO, 1.0, false)
	checks = Validate.validate(d)
	check("GLB without SPAWN_ fails", not result(checks, "glb: SPAWN_").get("ok", true))
	check("GLB without INTERACT_ fails", not result(checks, "glb: INTERACT_").get("ok", true))
	check("same GLB still has its WALK_ mesh", result(checks, "glb: WALK_").get("ok", false))
	d = copy_fixture("manifest_names")
	m = read_json(d.path_join("manifest.json"))
	m["interactables"] = ["captain_chair", "helm_that_is_not_there"]
	write_json(d.path_join("manifest.json"), m)
	checks = Validate.validate(d)
	check("manifest interactable missing from the GLB fails", not result(checks, "glb: manifest").get("ok", true), str(result(checks, "glb: manifest")))


## A fixture copy with overscanned plates: the panorama padded by `pano_os` per side with the
## camera's resolution and vertical fov widened to match (m4-2-requirements §4), and the
## foreground padded by `fg_os` (or left unpadded when `pad_fg` is false). Padding is alpha 0.
func overscanned_fixture(case: String, pano_os: Vector2i, fg_os: Vector2i, pad_fg: bool) -> String:
	var d := copy_fixture(case)
	var pano := Image.load_from_file(d.path_join("pano_bridge.png"))
	pano.convert(Image.FORMAT_RGBA8)
	var big := Image.create_empty(pano.get_width() + 2 * pano_os.x, pano.get_height() + 2 * pano_os.y, false, Image.FORMAT_RGBA8)
	big.blit_rect(pano, Rect2i(Vector2i.ZERO, pano.get_size()), pano_os)
	big.save_png(d.path_join("pano_bridge.png"))
	if pad_fg:
		var fg := Image.load_from_file(d.path_join("fg_bridge.png"))
		fg.convert(Image.FORMAT_RGBA8)
		var fbig := Image.create_empty(fg.get_width() + 2 * fg_os.x, fg.get_height() + 2 * fg_os.y, false, Image.FORMAT_RGBA8)
		fbig.blit_rect(fg, Rect2i(Vector2i.ZERO, fg.get_size()), fg_os)
		fbig.save_png(d.path_join("fg_bridge.png"))
	var cam := read_json(d.path_join("cam_bridge.json"))
	var h0 := float(cam["resolution"][1])
	cam["resolution"] = [big.get_width(), big.get_height()]
	cam["fov_vertical_deg"] = rad_to_deg(2.0 * atan(tan(deg_to_rad(float(cam["fov_vertical_deg"])) / 2.0) * big.get_height() / h0))
	write_json(d.path_join("cam_bridge.json"), cam)
	var m := read_json(d.path_join("manifest.json"))
	m["layers"]["panorama"]["overscan_px"] = [pano_os.x, pano_os.y]
	m["layers"]["foreground"]["overscan_px"] = [fg_os.x, fg_os.y]
	write_json(d.path_join("manifest.json"), m)
	return d


## The fixture camera moved along its up vector so the needle tip [0, 0, 98] projects `dpx`
## pixels lower (positive) or higher (negative): [camera, actual shift in px].
func shifted_camera(cam: Dictionary, dpx: float) -> Array:
	var tip := [0.0, 0.0, 98.0]
	var y0 := AreaBundle.project(cam, tip)[1]
	var moved := cam.duplicate(true)
	var step := 0.0
	for it in 3: # Newton on the camera offset (the map is nearly linear)
		var probe := cam.duplicate(true)
		var u: Array = cam["up"]
		var o: Array = cam["position_m"]
		var eps := 1e-3
		probe["position_m"] = [o[0] + (step + eps) * u[0], o[1] + (step + eps) * u[1], o[2] + (step + eps) * u[2]]
		moved["position_m"] = [o[0] + step * u[0], o[1] + step * u[1], o[2] + step * u[2]]
		var ym := AreaBundle.project(moved, tip)[1]
		var slope := (AreaBundle.project(probe, tip)[1] - ym) / eps
		step += (y0 + dpx - ym) / slope
	var o2: Array = cam["position_m"]
	var u2: Array = cam["up"]
	moved["position_m"] = [o2[0] + step * u2[0], o2[1] + step * u2[1], o2[2] + step * u2[2]]
	return [moved, AreaBundle.project(moved, tip)[1] - y0]


## a minimal play GLB: a 20 m walk disc (rotated / scaled), optionally a spawn and an interactable
func write_glb(path: String, rot: Vector3, scale: float, markers: bool, extra_box := 0.0) -> void:
	var root_node := Node3D.new()
	root_node.name = "play_bridge"
	var walk := Node3D.new()
	walk.name = "WALK_bridge"
	walk.rotation = rot
	walk.scale = Vector3.ONE * scale
	var disc := MeshInstance3D.new()
	disc.name = "WALK_disc"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 10.0
	cyl.bottom_radius = 10.0
	cyl.height = 0.02
	disc.mesh = cyl
	walk.add_child(disc)
	root_node.add_child(walk)
	if markers:
		var s := Node3D.new()
		s.name = "SPAWN_captain_0"
		root_node.add_child(s)
		var i := MeshInstance3D.new()
		i.name = "INTERACT_chair"
		i.mesh = BoxMesh.new()
		root_node.add_child(i)
	if extra_box > 0.0:
		var big := MeshInstance3D.new()
		big.name = "hull"
		var bm := BoxMesh.new()
		bm.size = Vector3.ONE * extra_box
		big.mesh = bm
		root_node.add_child(big)
	for c in root_node.get_children():
		c.owner = root_node
		for g in c.get_children():
			g.owner = root_node
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_scene(root_node, st)
	doc.write_to_filesystem(st, ProjectSettings.globalize_path(path))
	root_node.free()


## Bridge v2 play plate (m4-2-requirements §9.7): a small synthetic plate on the blockout
## fixture passes; each plate check fails on a plate broken its way.
func plate_fixture(case: String, opts := {}) -> String:
	var d := copy_fixture(case)
	var w: int = opts.get("w", 404)
	var h: int = opts.get("h", 220)
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.55, 0.5, 1.0))
	img.fill_rect(Rect2i(0, 0, 60, 40), Color(0, 0, 0, 0)) # a corner of space (alpha rule: some exactly 0)
	if opts.get("hole", false): # the plate's centre painted out: GLB surfaces would sample space
		img.fill_rect(Rect2i(w / 4, h / 2, w / 2, h / 2), Color(0, 0, 0, 0))
	if opts.get("opaque", false):
		img.fill(Color(0.6, 0.55, 0.5, 1.0))
	img.save_png(d.path_join("plate_bridge.png"))
	var m := read_json(d.path_join("manifest.json"))
	m["layers"]["play"]["plate"] = {"file": "plate_bridge.png", "projection": "isocam",
		"resolution": opts.get("declared", [w, h]), "size_m": opts.get("size_m", 22.0)}
	if opts.has("drop"):
		m["layers"]["play"]["plate"].erase(opts["drop"])
	write_json(d.path_join("manifest.json"), m)
	return d


func test_plate() -> void:
	var good := Validate.validate(plate_fixture("plate_ok"))
	check("synthetic v2 plate on the blockout passes every check", all_pass(good))
	check("the plate checks ran (4 of them)", result(good, "plate: every GLB triangle") != {} and result(good, "plate: covers") != {}
		and result(good, "plate: plate_bridge.png") != {} and result(good, "alpha: play plate") != {})
	var b := AreaBundle.load_dir(plate_fixture("plate_schema", {"drop": "size_m"}))
	check("a plate without size_m is refused by the loader", not b.ok() and "; ".join(b.errors).contains("size_m"), "; ".join(b.errors))
	var c := Validate.validate(plate_fixture("plate_res", {"declared": [808, 440]}))
	check("a plate whose size is not the declared resolution fails", not result(c, "plate: plate_bridge.png").get("ok", true))
	c = Validate.validate(plate_fixture("plate_opaque", {"opaque": true}))
	check("an opaque plate (space painted over) fails the alpha rules", not result(c, "alpha: play plate").get("ok", true))
	c = Validate.validate(plate_fixture("plate_short", {"size_m": 15.0, "w": 276, "h": 150}))
	check("a plate smaller than the iso view fails the pan-range check", not result(c, "plate: covers").get("ok", true), str(result(c, "plate: covers")))
	c = Validate.validate(plate_fixture("plate_hole", {"hole": true}))
	check("a plate with its centre painted out fails the GLB coverage check", not result(c, "plate: every GLB triangle").get("ok", true), str(result(c, "plate: every GLB triangle")))
	var it := Interior.plate_camera_of({"pitch_deg": -14.0, "yaw_deg": 45.0, "focus_m": [-8.0, 1.0, 9.0], "v_offset_m": 6.08, "size_m": 16.0})
	var uv := Interior.plate_uv(Vector3(-8.0, 1.0, 9.0) + it["up"] * 6.08, it, 22.0, 40.4444 / 22.0)
	check("plate_uv: the pan-0 view centre is the plate centre", uv.distance_to(Vector2(0.5, 0.5)) < 1e-6, str(uv))
	var up := Interior.plate_glow_factor(Vector3.UP, it)
	var side := Interior.plate_glow_factor(Vector3(1, 0, 0), it)
	check("glow factor: an up-facing surface gets the forward glow, a side-facing one none", up > 1.0 and absf(side) < 1e-9, "up %f side %f" % [up, side])


func _init() -> void:
	test_loader()
	test_validator()
	test_plate()
	print("\n%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
