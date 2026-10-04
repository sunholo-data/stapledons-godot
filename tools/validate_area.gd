extends SceneTree
## M4.0 `make validate-areas` (AC13, AC14 validation half): checks an area bundle (brief §9) the
## way the game will read it. Godot headless (image and GLB I/O are Godot's job, CLAUDE.md
## "Python"):
##   godot --headless --path . --script tools/validate_area.gd -- BUNDLE_DIR [BUNDLE_DIR ...]
## Prints one PASS/FAIL line per check and exits 1 if any check fails (2 on usage errors).
##
## Checks:
##   schema       manifest.json field for field (V17) + cam_<area>.json (brief §5.2), every layer
##                file present (AreaBundle.load_dir; a refused bundle stops here)
##   resolution   each plate = view + 2 x its layers.<layer>.overscan_px (default 0), where
##                view = camera.resolution - 2 x panorama overscan (m4-2-requirements §4: the
##                camera spans the whole panorama plate); without overscan, = camera.resolution
##   alpha        "never paint space" (brief §5.1): the plates carry alpha; with sky_visible the
##                panorama has exactly-0 alpha where space shows (>= MIN_SPACE_FRACTION of it);
##                no SPECK (an alpha > 0 blob of <= 3x3 px with nothing around it: a painted
##                star) and no HAZE (0 < alpha <= HAZE_MAX with no solid pixel within 2 px:
##                painted nebula/glow, as opposed to an anti-aliased edge). The validator has no
##                render mask, so these are the image-only signatures of painted space.
##                fg: also mostly clear and clear across the centre (brief §5.4), both measured
##                on the pan-0 view region of an overscanned plate.
##   round trip   the anchor (manifest validation.needle_tip_ship_m, default the brief's spire
##                needle tip [0, 0, 98]) projected through the camera and unprojected back lands
##                within 1 px; a declared validation.needle_tip_pixel agrees within 1 px; and the
##                needle is visible in the panorama at that pixel: its topmost solid row lies in
##                [tip - NEEDLE_INK_ABOVE_PX, tip + NEEDLE_BELOW_PX]. One-sided, because the toon
##                ink outline always puts the solid top ABOVE the geometric tip (measured 1.4 px
##                on bridge v1 at 4K, 1.7 px on the blockout), never below it.
##   glb          loads; metres (overall extent and walk extent in range); Y up (walk surfaces
##                face +/-Y); WALK_ meshes, SPAWN_ points and INTERACT_ objects present; any
##                manifest `walk` / `spawns` / `interactables` lists (Blender extras) name real
##                nodes.
##   plate        bridge v2, when layers.play.plate is declared (m4-2-requirements §9.7): the
##                declared resolution, the alpha rules above, the pan range covered, and every
##                GLB triangle that projects into the plate lands on its coverage (<= 2 px).

const NEEDLE_TIP_SHIP_M := [0.0, 0.0, 98.0]
const ROUND_TRIP_PX := 1.0
const NEEDLE_INK_ABOVE_PX := 2.5 # solid top may sit this far above the projected tip (ink outline)
const NEEDLE_BELOW_PX := 0.5 # ... and at most this far below it
const NEEDLE_SEARCH_PX := 24
const MIN_SPACE_FRACTION := 0.01
const FG_MIN_CLEAR_FRACTION := 0.5
const HAZE_MAX := 16 # alpha byte: <= 6% opacity
const SOLID := 128 # alpha byte: a "solid" pixel for the haze and needle rules
const METRES_EXTENT := [1.0, 2000.0]
const WALK_EXTENT := [2.0, 500.0]
const Y_UP_FRACTION := 0.5
const PLATE_EDGE_PX := 2 # bridge v2: a GLB point may sit this far from plate coverage (anti-aliased silhouettes)
const PLATE_COVER_TOL := 0.001 # fraction of in-plate GLB triangles allowed off the plate's coverage


static func validate(dir: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var b := AreaBundle.load_dir(dir)
	_add(out, "schema: manifest + camera (V17), layer files present", b.ok(),
		"area %s, placeholder %s" % [b.area(), b.placeholder] if b.ok() else "; ".join(b.errors))
	if not b.ok():
		return out
	var pano := b.load_image("panorama")
	var fg := b.load_image("foreground")
	var view := b.view_size()
	for pair in [["panorama", pano], ["foreground", fg]]:
		var img: Image = pair[1]
		var want := b.plate_size(pair[0])
		var os := b.overscan(pair[0])
		_add(out, "resolution: %s = %dx%d (view %dx%d + 2 x overscan [%d, %d])" % [pair[0], want.x, want.y, view.x, view.y, os.x, os.y],
			img != null and img.get_size() == want and view.x > 0 and view.y > 0,
			"unreadable" if img == null else "got %dx%d" % [img.get_width(), img.get_height()])
	if pano != null:
		out.append(check_alpha(pano, "panorama", b.manifest["sky_visible"], false))
	if fg != null:
		out.append(check_alpha(fg, "foreground", true, true, b.view_rect("foreground") if fg.get_size() == b.plate_size("foreground") else Rect2i()))
	out.append_array(check_round_trip(b, pano))
	out.append_array(check_glb(b.path("play"), b.manifest))
	if b.has_play_plate():
		out.append_array(check_plate(b))
	return out


## The alpha rules on one plate. `space` = the plate must show space somewhere (exactly-0
## alpha); `fg` adds the foreground rules (mostly clear, clear across the centre).
static func check_alpha(src: Image, label: String, space: bool, fg: bool, view := Rect2i()) -> Dictionary:
	var name := "alpha: %s, exactly 0 where space shows (no painted space)" % label
	if not _has_alpha_format(src.get_format()):
		return _check(name, false, "no alpha channel (format %d)" % src.get_format())
	var img := src.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var d := img.get_data()
	var zero := 0
	for i in range(3, d.size(), 4):
		if d[i] == 0:
			zero += 1
	var frac := float(zero) / float(w * h)
	var specks := 0
	var haze := 0
	var first := ""
	for y in range(2, h - 2):
		var row := y * w
		for x in range(2, w - 2):
			var a := d[(row + x) * 4 + 3]
			if a == 0:
				continue
			if _ring_clear(d, w, x, y):
				specks += 1
				if first.is_empty(): first = "speck at (%d, %d) alpha %d" % [x, y, a]
			elif a <= HAZE_MAX and not _solid_near(d, w, x, y):
				haze += 1
				if first.is_empty(): first = "haze at (%d, %d) alpha %d" % [x, y, a]
	var ok := specks == 0 and haze == 0
	var why := []
	if space and frac < MIN_SPACE_FRACTION:
		ok = false
		why.append("only %.4f of pixels have alpha exactly 0 (need >= %.2f: space is painted over)" % [frac, MIN_SPACE_FRACTION])
	if fg:
		# measured on the pan-0 view region; an overscan margin follows the edge-and-bottom rule
		var v := view if view.has_area() else Rect2i(0, 0, w, h)
		var vclear := 1.0 - float(_count_nonzero(d, w, v.position.x, v.position.y, v.end.x, v.end.y)) / float(v.get_area())
		if vclear < FG_MIN_CLEAR_FRACTION:
			ok = false
			why.append("foreground covers %.3f of the view (need <= %.2f)" % [1.0 - vclear, 1.0 - FG_MIN_CLEAR_FRACTION])
		var centre := _count_nonzero(d, w, v.position.x + int(v.size.x * 0.3), v.position.y + int(v.size.y * 0.25),
			v.position.x + int(v.size.x * 0.7), v.position.y + int(v.size.y * 0.75))
		if centre > 0:
			ok = false
			why.append("%d px with alpha > 0 in the view's centre box (x 30-70%%, y 25-75%%)" % centre)
	var detail := "alpha-0 fraction %.4f, specks %d, haze %d%s%s" % [frac, specks, haze,
		"" if first.is_empty() else " (first: %s)" % first, "" if why.is_empty() else "; " + "; ".join(why)]
	return _check(name, ok, detail)


## The camera round trip (brief §9 "Checks before hand-off").
static func check_round_trip(b: AreaBundle, pano: Image) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var cam := b.camera
	var v: Dictionary = b.manifest.get("validation", {}) if b.manifest.get("validation") is Dictionary else {}
	var anchor: Array = v["needle_tip_ship_m"] if AreaBundle._vec3(v.get("needle_tip_ship_m")) else NEEDLE_TIP_SHIP_M
	var p := AreaBundle.project(cam, anchor)
	var w := float(cam["resolution"][0])
	var h := float(cam["resolution"][1])
	var inside := p[2] > 0.0 and p[0] >= 0.0 and p[0] < w and p[1] >= 0.0 and p[1] < h
	# unproject the pixel, put the point back on the ray at the anchor's depth, project again
	var ray := AreaBundle.unproject(cam, p[0], p[1])
	var o: Array = cam["position_m"]
	var dist: float = sqrt(pow(anchor[0] - o[0], 2) + pow(anchor[1] - o[1], 2) + pow(anchor[2] - o[2], 2))
	var q := AreaBundle.project(cam, [o[0] + ray[0] * dist, o[1] + ray[1] * dist, o[2] + ray[2] * dist])
	var err := Vector2(q[0] - p[0], q[1] - p[1]).length()
	var cos_miss: float = (ray[0] * (anchor[0] - o[0]) + ray[1] * (anchor[1] - o[1]) + ray[2] * (anchor[2] - o[2])) / dist
	var miss_px := tan(acos(clampf(cos_miss, -1.0, 1.0))) * (h / 2.0) / tan(deg_to_rad(float(cam["fov_vertical_deg"])) / 2.0)
	_add(out, "round trip: anchor %s -> pixel -> ray -> pixel within %.0f px" % [str(anchor), ROUND_TRIP_PX],
		inside and err <= ROUND_TRIP_PX and miss_px <= ROUND_TRIP_PX,
		"pixel (%.3f, %.3f), re-projection %.6f px, ray miss %.6f px%s" % [p[0], p[1], err, miss_px, "" if inside else ", OUTSIDE the frame"])
	if v.get("needle_tip_pixel") is Array and v["needle_tip_pixel"].size() == 2:
		var dp := Vector2(v["needle_tip_pixel"][0] - p[0], v["needle_tip_pixel"][1] - p[1]).length()
		_add(out, "round trip: declared validation.needle_tip_pixel agrees within %.0f px" % ROUND_TRIP_PX, dp <= ROUND_TRIP_PX,
			"declared %s, camera gives (%.3f, %.3f): %.4f px" % [str(v["needle_tip_pixel"]), p[0], p[1], dp])
	if pano != null and inside:
		var t := needle_top(pano, p[0], p[1])
		var off := float(t.x) - p[1] # < 0: solid top above the tip
		var ok := t.x >= 0 and off >= -NEEDLE_INK_ABOVE_PX and off <= NEEDLE_BELOW_PX
		_add(out, "round trip: needle visible in the panorama at the projected pixel (solid top in [tip - %.1f, tip + %.1f] px)" % [NEEDLE_INK_ABOVE_PX, NEEDLE_BELOW_PX], ok,
			"no solid pixel within %d px" % NEEDLE_SEARCH_PX if t.x < 0 else
			"projected y %.3f, topmost solid row %d (%.3f px %s the tip), topmost alpha>0 row %d" % [p[1], t.x, absf(off), "above" if off < 0.0 else "below", t.y])
	return out


## Topmost solid (alpha >= SOLID) and topmost alpha > 0 rows in the 5 columns around px, searched
## within NEEDLE_SEARCH_PX of py; (-1, -1) if nothing solid is there.
static func needle_top(src: Image, px: float, py: float) -> Vector2i:
	var img := src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	var cx := int(floor(px))
	var y0 := maxi(0, int(floor(py)) - NEEDLE_SEARCH_PX)
	var y1 := mini(img.get_height() - 1, int(floor(py)) + NEEDLE_SEARCH_PX)
	var solid := -1
	var any := -1
	for y in range(y0, y1 + 1):
		for x in range(maxi(0, cx - 2), mini(img.get_width(), cx + 3)):
			var a := img.get_pixel(x, y).a8
			if a > 0 and any < 0: any = y
			if a >= SOLID and solid < 0: solid = y
		if solid >= 0:
			break
	return Vector2i(solid, any)


static func check_glb(file: String, manifest: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var scene := AreaBundle.load_glb(file)
	_add(out, "glb: %s loads" % file.get_file(), scene != null, "GLTFDocument read it" if scene != null else "GLTFDocument could not read it")
	if scene == null:
		return out
	var info := {"aabb": AABB(), "has_aabb": false, "walk": [], "spawn": [], "interact": [], "walk_groups": [], "faces_y": 0.0, "faces_all": 0.0, "walk_aabb": AABB(), "has_walk": false}
	_scan(scene, Transform3D.IDENTITY, info, "")
	var ext: float = info["aabb"].size[info["aabb"].size.max_axis_index()]
	_add(out, "glb: metres (overall extent in [%s, %s] m)" % METRES_EXTENT, info["has_aabb"] and ext >= METRES_EXTENT[0] and ext <= METRES_EXTENT[1],
		"overall AABB %s, extent %.3f m" % [info["aabb"], ext])
	var wa: AABB = info["walk_aabb"]
	var wext := maxf(wa.size.x, wa.size.z)
	_add(out, "glb: walk area extent in [%s, %s] m" % WALK_EXTENT, info["has_walk"] and wext >= WALK_EXTENT[0] and wext <= WALK_EXTENT[1],
		"walk AABB %s" % wa)
	var yfrac: float = info["faces_y"] / info["faces_all"] if info["faces_all"] > 0.0 else 0.0
	_add(out, "glb: Y up (>= %.0f%% of walk surface area faces +/-Y)" % (Y_UP_FRACTION * 100.0), yfrac >= Y_UP_FRACTION,
		"%.4f of walk triangle area has |n.Y| > 0.9" % yfrac)
	_add(out, "glb: WALK_ meshes present", info["walk"].size() > 0, "%d walk meshes under %s" % [info["walk"].size(), str(info["walk_groups"])])
	_add(out, "glb: SPAWN_ points present", info["spawn"].size() > 0, "%d: %s" % [info["spawn"].size(), _short(info["spawn"])])
	_add(out, "glb: INTERACT_ objects present", info["interact"].size() > 0, "%d: %s" % [info["interact"].size(), _short(info["interact"])])
	var missing := []
	if manifest.get("walk") is String and not (manifest["walk"] in info["walk_groups"] or manifest["walk"] in info["walk"]):
		missing.append("walk " + manifest["walk"])
	for pair in [["spawns", "spawn"], ["interactables", "interact"]]:
		if manifest.get(pair[0]) is Array:
			for n in manifest[pair[0]]:
				if not (n in info[pair[1]]):
					missing.append("%s %s" % [pair[0], n])
	if manifest.has("walk") or manifest.has("spawns") or manifest.has("interactables"):
		_add(out, "glb: manifest walk/spawns/interactables lists name real GLB nodes", missing.is_empty(),
			"all listed names found" if missing.is_empty() else "not in the GLB: " + ", ".join(missing))
	scene.free()
	return out


## Bridge v2 play plate (m4-2-requirements §9.7): declared resolution, the alpha rules, the
## pan range it covers, and coverage: every GLB triangle that projects into the plate (through
## the pan-0 iso camera, Interior.plate_uv) lands on plate coverage (alpha > 0 within
## PLATE_EDGE_PX), so no visible surface would sample space.
static func check_plate(b: AreaBundle) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var pl := b.play_plate()
	var img := AreaBundle.load_png(b.play_plate_path())
	var want := Vector2i(int(pl["resolution"][0]), int(pl["resolution"][1]))
	_add(out, "plate: %s = declared %dx%d" % [b.play_plate_path().get_file(), want.x, want.y], img != null and img.get_size() == want,
		"unreadable" if img == null else "got %dx%d" % [img.get_width(), img.get_height()])
	if img == null or img.get_size() != want:
		return out
	out.append(check_alpha(img, "play plate", true, false))
	var iso := b.iso_camera()
	var size_m := float(pl["size_m"])
	var aspect := float(img.get_width()) / float(img.get_height())
	var view := Vector2(b.view_size())
	var view_m := Vector2(float(iso["size_m"]) * view.x / view.y, float(iso["size_m"]))
	var need := b.pan_range_m()
	if not need.is_finite():
		need = Vector2.ZERO
	var has := (Vector2(size_m * aspect, size_m) - view_m) * 0.5
	_add(out, "plate: covers the pan range (+/- [%.2f, %.2f] m about the pan-0 view)" % [need.x, need.y], has.x >= need.x - 0.01 and has.y >= need.y - 0.01,
		"plate %.3f x %.3f m, view %.3f x %.3f m: covers +/- [%.3f, %.3f] m" % [size_m * aspect, size_m, view_m.x, view_m.y, has.x, has.y])
	var scene := AreaBundle.load_glb(b.path("play"))
	if scene == null:
		_add(out, "plate: coverage of the GLB", false, "GLB did not load")
		return out
	var cam := Interior.plate_camera_of(iso)
	var tally := {"in": 0, "bad": 0, "first": ""}
	_plate_cover(scene, Transform3D.IDENTITY, img, cam, size_m, aspect, tally)
	scene.free()
	var frac := float(tally["bad"]) / maxf(float(tally["in"]), 1.0)
	_add(out, "plate: every GLB triangle in the plate lands on its coverage (alpha > 0 within %d px)" % PLATE_EDGE_PX, tally["in"] > 0 and frac <= PLATE_COVER_TOL,
		"%d triangles in the plate, %d on alpha 0 (%.4f %%, limit %.2f %%)%s" % [tally["in"], tally["bad"], frac * 100.0, PLATE_COVER_TOL * 100.0, (", first " + tally["first"]) if tally["first"] != "" else ""])
	return out


static func _plate_cover(n: Node, parent: Transform3D, img: Image, cam: Dictionary, size_m: float, aspect: float, tally: Dictionary) -> void:
	var xf := parent
	if n is Node3D:
		xf = parent * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var faces := (n as MeshInstance3D).mesh.get_faces()
		var w := img.get_width()
		var h := img.get_height()
		for i in range(0, faces.size(), 3):
			var c := (xf * faces[i] + xf * faces[i + 1] + xf * faces[i + 2]) / 3.0
			var uv := Interior.plate_uv(c, cam, size_m, aspect)
			var px := int(uv.x * w)
			var py := int(uv.y * h)
			if px < 0 or py < 0 or px >= w or py >= h:
				continue
			tally["in"] += 1
			var covered := false
			for dy in range(-PLATE_EDGE_PX, PLATE_EDGE_PX + 1):
				for dx in range(-PLATE_EDGE_PX, PLATE_EDGE_PX + 1):
					var x := clampi(px + dx, 0, w - 1)
					var y := clampi(py + dy, 0, h - 1)
					if img.get_pixel(x, y).a8 > 0:
						covered = true
						break
				if covered:
					break
			if not covered:
				tally["bad"] += 1
				if tally["first"] == "":
					tally["first"] = "%s at plate (%d, %d)" % [n.name, px, py]
	for ch in n.get_children():
		_plate_cover(ch, xf, img, cam, size_m, aspect, tally)


static func _scan(n: Node, parent: Transform3D, info: Dictionary, group: String) -> void:
	var xf := parent
	if n is Node3D:
		xf = parent * (n as Node3D).transform
	var nm := String(n.name)
	var in_group := group
	for prefix in ["WALK_", "SPAWN_", "INTERACT_"]:
		if nm.begins_with(prefix):
			in_group = prefix
	if nm.begins_with("WALK_") and n.get_child_count() > 0:
		info["walk_groups"].append(nm)
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mi := n as MeshInstance3D
		var box := xf * mi.mesh.get_aabb()
		info["aabb"] = box if not info["has_aabb"] else info["aabb"].merge(box)
		info["has_aabb"] = true
		if in_group == "WALK_":
			info["walk"].append(nm)
			info["walk_aabb"] = box if not info["has_walk"] else info["walk_aabb"].merge(box)
			info["has_walk"] = true
			var faces := mi.mesh.get_faces()
			for i in range(0, faces.size(), 3):
				var c := (xf * faces[i + 1] - xf * faces[i]).cross(xf * faces[i + 2] - xf * faces[i])
				var area := c.length()
				if area <= 0.0:
					continue
				info["faces_all"] += area
				if absf(c.y) / area > 0.9:
					info["faces_y"] += area
	# a point is a childless SPAWN_/INTERACT_ node or a direct child of such a group node
	var leaf := n.get_child_count() == 0
	if nm.begins_with("SPAWN_") and leaf or group == "SPAWN_" and n.get_parent() != null and String(n.get_parent().name).begins_with("SPAWN_"):
		info["spawn"].append(nm)
	if nm.begins_with("INTERACT_") and leaf or group == "INTERACT_" and n.get_parent() != null and String(n.get_parent().name).begins_with("INTERACT_"):
		info["interact"].append(nm)
	for c in n.get_children():
		_scan(c, xf, info, in_group)


static func _ring_clear(d: PackedByteArray, w: int, x: int, y: int) -> bool:
	for k in range(-2, 3):
		if d[((y - 2) * w + x + k) * 4 + 3] != 0 or d[((y + 2) * w + x + k) * 4 + 3] != 0:
			return false
	for k in range(-1, 2):
		if d[((y + k) * w + x - 2) * 4 + 3] != 0 or d[((y + k) * w + x + 2) * 4 + 3] != 0:
			return false
	return true


static func _solid_near(d: PackedByteArray, w: int, x: int, y: int) -> bool:
	for j in range(-2, 3):
		var row := (y + j) * w
		for k in range(-2, 3):
			if d[(row + x + k) * 4 + 3] >= SOLID:
				return true
	return false


static func _count_nonzero(d: PackedByteArray, w: int, x0: int, y0: int, x1: int, y1: int) -> int:
	var n := 0
	for y in range(y0, y1):
		for x in range(x0, x1):
			if d[(y * w + x) * 4 + 3] != 0:
				n += 1
	return n


static func _has_alpha_format(f: int) -> bool:
	return f in [Image.FORMAT_LA8, Image.FORMAT_RGBA8, Image.FORMAT_RGBA4444, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH]


static func _short(names: Array) -> String:
	return ", ".join(names.slice(0, 6)) + (", ..." if names.size() > 6 else "")


static func _check(name: String, ok: bool, detail: String) -> Dictionary:
	return {"name": name, "ok": ok, "detail": detail}


static func _add(out: Array[Dictionary], name: String, ok: bool, detail: String) -> void:
	out.append(_check(name, ok, detail))


func _init() -> void:
	var dirs := OS.get_cmdline_user_args()
	if dirs.is_empty():
		printerr("usage: validate_area.gd -- BUNDLE_DIR [BUNDLE_DIR ...]"); quit(2); return
	var failed := 0
	for dir in dirs:
		var checks := validate(dir)
		var bad := 0
		print("validate-areas %s" % dir)
		for c in checks:
			print("  %s  %s: %s" % ["PASS" if c["ok"] else "FAIL", c["name"], c["detail"]])
			if not c["ok"]:
				bad += 1
		print("  %d passed, %d failed\n" % [checks.size() - bad, bad])
		failed += bad
	quit(1 if failed > 0 else 0)
