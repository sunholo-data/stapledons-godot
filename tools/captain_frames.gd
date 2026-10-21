extends SceneTree
## R2-CAPTAIN-ANIMATION §D1, §D3, §D4 (AC4, AC5): the painted captain frames.
##
##   --ingest <raw dir> --guides <dir> [--art <res dir>]
##                        painted frames at the contract canvas (1024 x 1536, from the art thread)
##                        -> matte (alpha remapped: the generator's figure alpha sits at ~0.9-0.99),
##                        aligned to their pose guide (scale by figure height, the planted sole on the
##                        guide's), downscaled to cells (CELL_SCALE), trimmed to the alpha box, saved
##                        as lossless WebP in assets/characters/captain/anim/y0/; the "anim" section is
##                        written to ANIM_MANIFEST from <art>/clips.json (default art/captain-anim-v2;
##                        "keep" clips carry over). Each frame records its guide and planted foot.
##   (default: check)     every manifest frame against its own guide (cell size) and the stage-0 stills:
##                        pose (silhouette IoU and leg coverage), palette (k-means of the still, CIE76
##                        dE), figure height against the guide, cell geometry, disk and GPU budgets; and
##                        AC3: a planted foot slides <= STANCE_PX_MAX at 1440p between stance frames.
##   --selftest           the check must FAIL on three seeded defects: a recoloured frame (another
##                        identity's palette), a frame drawn for the wrong pose (the other facing's
##                        guide), a frame at the wrong scale.
## Prints "captain-frames: ok" or FAIL lines. Writes --json <file> with every number.
const DIR := "res://assets/characters/captain"
const CELL_SCALE := 0.1875
## The manifest the painted frames are written to and checked in: the pilot's own until Mark accepts it
## (then the "anim" section moves into manifest.json and the game shows it).
const ANIM_MANIFEST := "anim_pilot.json"
const CANVAS := Vector2i(1024, 1536)
const ANCHOR := Vector2(512, 1440)
## Pose (§D4), per painted facing [IoU, leg coverage], set from the measured numbers (design doc "Walk"):
##   back:    IoU >= 0.65 and legs >= 0.65. The walk's back frames score IoU 0.694-0.764 and legs
##            0.705-0.805 against their own guides, IoU 0.497-0.582 against the profile guides: the IoU
##            half separates the poses (the leg half alone does not: 0.608-0.828).
##   profile: IoU >= 0.50 and legs >= 0.60. Own IoU 0.534-0.732 and legs 0.688-0.873; against the back
##            guides IoU 0.500-0.563 and legs 0.271-0.487: the leg half separates the poses.
## Tighter than the jog's (back IoU 0.60, profile not gated): the walking coat hangs, so the silhouette
## follows the guide. The idle frames (first pilot) pass both.
const POSE_MIN := {"back": [0.65, 0.65], "profile": [0.50, 0.60]}
const POSE_MIN_OTHER := [0.55, 0.65] ## facings not painted yet (the first pilot's gate)
const HEIGHT_TOL := 0.12 ## the shipped figure's box height against its guide's: the facing shares one scale, so a
##   frame's box differs with its pose and the flying coat (jog v2: 0.902-1.052); 0.7x (the seeded defect) fails
const DE_MAX := 12.0
## AC3: a planted foot may slide at most this far on screen per stance step (2560 x 1440, the Bow view, where
## the 1.754 m captain is 161 px: CameraDirector.figure_px at the spawn).
const STANCE_PX_MAX := 2.0
## Ingest pins a planted frame by its planted sole along the travel axis, at most this far (canvas px).
const PIN_MAX := 64
const SCREEN_PX_PER_M := 161.144 / 1.754
const DISK_STAGE_MAX := 3 * 1024 * 1024
const GPU_STAGE_MAX := 32 * 1024 * 1024
const PALETTE_K := 6
const PALETTE_SHARE_MIN := 0.08 ## the still's colour clusters checked: each >= 8% of the figure (coat, trousers, yoke, boots)
## A cluster may shrink to this share of the still's (a walking back view hides more trouser under the
## hanging coat: walk_back_10 shows 10% where the still shows 21%); a missing colour still fails.
const PALETTE_SHARE_KEEP := 0.4
## The still each painted facing is compared with (the nearest stage-0 view).
const REF_STILL := {"back": "avatar_captain_y0_back.png", "back_34": "avatar_captain_y0_ne.png", "profile": "avatar_captain_y0_se.png", "front_34": "avatar_captain_y0_se.png", "front": "avatar_captain_y0_front.png"}

var report := {"frames": [], "failures": []}
var json_out := ""
var guides_dir := "" ## --guides: the full-size pose guides (pinned in <art>/guides.sha256)
var art_dir := "res://art/captain-anim-v2" ## --art: the clip plan, guides.json and the cell-size guides


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := "check"
	var raw := ""
	for i in args.size():
		match args[i]:
			"--ingest": mode = "ingest"; raw = args[i + 1]
			"--guides": guides_dir = args[i + 1]
			"--art": art_dir = args[i + 1]
			"--selftest": mode = "selftest"
			"--json": json_out = args[i + 1]
	if mode == "ingest":
		_ingest(raw)
	var ok := _check(mode == "selftest")
	if json_out != "":
		var f := FileAccess.open(json_out, FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "  "))
		f.close()
	if mode == "selftest":
		print("captain-frames: selftest ok" if ok else "captain-frames: FAIL selftest")
	else:
		print("captain-frames: ok" if ok else "captain-frames: FAIL")
	quit(0 if ok else 1)


## The clip plan: which painted file is each frame (<art>/clips.json).
func _plan() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(art_dir.path_join("clips.json")))


func _ingest(raw: String) -> void:
	var plan := _plan()
	var out_dir := DIR.path_join("anim/y0")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var gmeta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(art_dir.path_join("guides.json")))
	var planted := {}
	for row: Dictionary in gmeta.get("frames", []):
		planted[str(row.file).get_basename()] = row.get("planted", "")
	var old: Dictionary = {}
	if FileAccess.file_exists(DIR.path_join(ANIM_MANIFEST)):
		old = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join(ANIM_MANIFEST))).get("anim", {})
	var crops := {}
	var scales: Dictionary = old.get("ingest_scale", {}).duplicate()
	var pins := {}
	var pins_full := {}
	var heads := {}
	# One scale per painted facing (the median of the frames' height ratios): a frame's own box height
	# swings with the pose and the flying coat, the painted person's size should not.
	var per_frame := {}
	var by_facing := {}
	for src: String in plan.painted:
		var img0 := Image.load_from_file(raw.path_join(src + ".png"))
		img0.convert(Image.FORMAT_RGBA8)
		_matte(img0)
		var g0 := Image.load_from_file(guides_dir.path_join(src + ".png"))
		g0.convert(Image.FORMAT_RGBA8)
		per_frame[src] = float(_figure_rect(g0, 0.25).size.y) / float(_figure_rect(img0, 0.5).size.y)
		by_facing.get_or_add(src.split("_")[1], []).append(per_frame[src])
	var median := {}
	for f: String in by_facing:
		var l: Array = by_facing[f]
		l.sort()
		median[f] = l[l.size() / 2]
	for src: String in plan.painted:
		var img := Image.load_from_file(raw.path_join(src + ".png"))
		img.convert(Image.FORMAT_RGBA8)
		_matte(img)
		var guide := Image.load_from_file(guides_dir.path_join(src + ".png"))
		guide.convert(Image.FORMAT_RGBA8)
		var a := _align(img, guide, median[src.split("_")[1]])
		scales[src] = a.scale
		var cell: Image = a.image
		# Profile: the body's height on the canvas follows the guide's head (its bob), not the silhouette
		# fit, which the trailing coat can pull down; the planted sole then pins x below.
		if src.contains("_profile_"):
			var dy := _figure_rect(guide, 0.25).position.y - _figure_rect(cell, 0.5).position.y
			if dy != 0:
				var moved := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
				moved.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(0, dy))
				cell = moved
			heads[src] = dy
		# A planted frame is pinned by its planted sole (the guide's stance foot is on the deck at the
		# same place): the body may move a few px, the foot never slides (AC3).
		if str(planted.get(src, "")) in ["L", "R"]:
			var gs := _key_sole(guide, str(planted[src]))
			var full := Vector2i((gs - _sole_near(cell, 0.5, gs.x, 70)).round())
			# Pin only along the travel as the camera sees it (x in profile, y in the back view), capped:
			# the other axis keeps the body where the silhouette fit put it, so the body does not hop.
			var profile_like := src.contains("_profile_")
			var d := Vector2i(clampi(full.x, -PIN_MAX, PIN_MAX), 0) if profile_like else Vector2i(0, clampi(full.y, -PIN_MAX, PIN_MAX))
			pins_full[src] = [full.x, full.y]
			var pinned := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
			pinned.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), d)
			pins[src] = [d.x, d.y]
			cell = pinned
		cell.resize(int(CANVAS.x * CELL_SCALE), int(CANVAS.y * CELL_SCALE), Image.INTERPOLATE_LANCZOS)
		var box: Rect2i = cell.get_used_rect().grow(1).intersection(Rect2i(Vector2i.ZERO, cell.get_size()))
		var trimmed: Image = cell.get_region(box)
		trimmed.save_webp(ProjectSettings.globalize_path(out_dir.path_join(src + ".webp")), false)
		crops[src] = [box.position.x, box.position.y, box.size.x, box.size.y]
	# The anim section: painted clips from this plan; "keep" clips carried over from the manifest.
	var clips := {}
	var guide_rel := art_dir.trim_prefix("res://").path_join("guides")
	for clip: String in plan.clips:
		var c: Dictionary = plan.clips[clip].duplicate(true)
		if bool(c.get("keep", false)) and old.get("clips", {}).has(clip):
			var kept: Dictionary = old.clips[clip].duplicate(true)
			for facing: String in kept.stages["0"]:
				for e: Dictionary in kept.stages["0"][facing]:
					if not e.has("guide"):
						e["guide"] = "art/captain-anim-v1/guides/" + str(e.file).get_file().get_basename() + ".png"
			clips[clip] = kept
			continue
		var facings: Dictionary = c.get("frames", {})
		c.erase("frames")
		c.erase("keep")
		var st := {}
		for facing: String in facings:
			var list: Array = []
			for e: Array in facings[facing]:
				list.append({"file": "anim/y0/" + str(e[0]) + ".webp", "crop": crops[e[0]], "flip": bool(e[1]),
					"guide": guide_rel.path_join(str(e[0]) + ".png"), "planted": planted.get(str(e[0]), "")})
			st[facing] = list
		c["stages"] = {"0": st}
		clips[clip] = c
	var m := {"anim": {"about": "R2-CAPTAIN-ANIMATION painted frames (manifest v2): cells of the contract canvas at cell_scale, trimmed (crop = [x, y, w, h] in the cell canvas), per stage and painted facing; flip mirrors a frame; guide is the pose guide (cell size) each frame is checked against; planted is the guide's stance foot (L, R, flight). Made by tools/captain_frames.gd --ingest.", "cell_scale": CELL_SCALE, "clips": clips, "ingest_scale": scales, "ingest_pin_px": pins, "ingest_pin_wanted_px": pins_full, "ingest_head_dy_px": heads}}
	var f := FileAccess.open(DIR.path_join(ANIM_MANIFEST), FileAccess.WRITE)
	f.store_string(JSON.stringify(m, "  ") + "\n")
	f.close()
	print("ingest: %d frames -> %s" % [plan.painted.size(), out_dir])


## The generator's figure alpha sits at ~0.9-0.99 and its glow lives at alpha 0: remap 0.5..0.9 to 0..1.
static func _matte(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			c.a = clampf((c.a - 0.5) / 0.4, 0.0, 1.0)
			if c.a == 0.0:
				c = Color(0, 0, 0, 0)
			img.set_pixel(x, y, c)


## Align a painted frame to its guide: scale by the figure's height (alpha box), start from the boxes'
## centres and bottoms, and refine the shift to the best silhouette overlap (a search of +-192 px at
## 1/16 of the canvas, then +-16 px at 1/4). The painted coat flares where the guide's is a cone, so
## the boxes alone can sit off.
static func _align(img: Image, guide: Image, scale := 0.0) -> Dictionary:
	var pr := _figure_rect(img, 0.5)
	var gr := _figure_rect(guide, 0.25)
	var s := scale if scale > 0.0 else float(gr.size.y) / float(pr.size.y)
	var scaled := img.duplicate() as Image
	scaled.resize(int(round(img.get_width() * s)), int(round(img.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	var sr := _figure_rect(scaled, 0.5)
	var d := Vector2i(gr.get_center().x - sr.get_center().x, gr.end.y - sr.end.y) # box centres and bottoms
	for step in [[16, 12], [4, 4]]: # [mask scale k, search span in mask cells]
		var k: int = step[0]
		var gm := _mask(guide, 0.25, k)
		var best := -1.0
		var bd := d
		for dy in range(-step[1], step[1] + 1):
			for dx in range(-step[1], step[1] + 1):
				var cand := d + Vector2i(dx, dy) * k
				var iou := _iou_shift(_mask(scaled, 0.5, k, cand), gm)
				if iou > best:
					best = iou; bd = cand
		d = bd
	var outimg := Image.create(CANVAS.x, CANVAS.y, false, Image.FORMAT_RGBA8)
	outimg.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), d)
	return {"image": outimg, "scale": s, "shift": [d.x, d.y]}


## A coverage mask of img (shifted by d, canvas size) at 1/k: PackedByteArray of 0/1.
static func _mask(img: Image, thr: float, k: int, d := Vector2i.ZERO) -> PackedByteArray:
	var w := CANVAS.x / k
	var h := CANVAS.y / k
	var m := PackedByteArray()
	m.resize(w * h)
	for y in h:
		for x in w:
			var sx := x * k + k / 2 - d.x
			var sy := y * k + k / 2 - d.y
			if sx >= 0 and sy >= 0 and sx < img.get_width() and sy < img.get_height() and img.get_pixel(sx, sy).a > thr:
				m[y * w + x] = 1
	return m


static func _iou_shift(a: PackedByteArray, b: PackedByteArray) -> float:
	var i := 0
	var u := 0
	for n in a.size():
		i += a[n] & b[n]
		u += a[n] | b[n]
	return float(i) / maxf(1, u)


static func _figure_rect(img: Image, thr: float) -> Rect2i:
	var x0 := img.get_width(); var y0 := img.get_height(); var x1 := -1; var y1 := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > thr:
				x0 = mini(x0, x); y0 = mini(y0, y); x1 = maxi(x1, x); y1 = maxi(y1, y)
	return Rect2i(x0, y0, maxi(0, x1 - x0 + 1), maxi(0, y1 - y0 + 1))


## The planted sole: the centroid of the figure's lowest 3% of rows (x) and its bottom row (y).
static func _sole(img: Image, thr: float) -> Vector2:
	var r := _figure_rect(img, thr)
	var band := maxi(2, int(r.size.y * 0.03))
	var sx := 0.0; var n := 0
	for y in range(r.end.y - band, r.end.y):
		for x in range(r.position.x, r.end.x):
			if img.get_pixel(x, y).a > thr:
				sx += x; n += 1
	return Vector2(sx / maxf(1, n), r.end.y)


func _check(selftest: bool) -> bool:
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join(ANIM_MANIFEST)))
	var anim: Dictionary = m.get("anim", {})
	if anim.is_empty():
		_fail("manifest has no anim section")
		return false
	var s: float = anim.cell_scale
	var refs := {}
	var disk := 0
	var gpu := 0
	var seen := {}
	var by_facing := {}
	for clip: String in anim.clips:
		for stage: String in anim.clips[clip].stages:
			for facing: String in anim.clips[clip].stages[stage]:
				for e: Dictionary in anim.clips[clip].stages[stage][facing]:
					var file: String = e.file
					if seen.has(file):
						continue
					seen[file] = true
					var path := DIR.path_join(file)
					if not FileAccess.file_exists(path):
						_fail("%s: missing" % file)
						continue
					var img := Image.load_from_file(ProjectSettings.globalize_path(path))
					img.convert(Image.FORMAT_RGBA8)
					var crop: Array = e.crop
					if img.get_width() != int(crop[2]) or img.get_height() != int(crop[3]) or int(crop[0]) + int(crop[2]) > int(CANVAS.x * s) or int(crop[1]) + int(crop[3]) > int(CANVAS.y * s):
						_fail("%s: cell %dx%d does not match crop %s" % [file, img.get_width(), img.get_height(), crop])
					disk += FileAccess.get_file_as_bytes(path).size()
					gpu += int(img.get_width() * img.get_height() * 4 * 4.0 / 3.0)
					var cell := Image.create(int(CANVAS.x * s), int(CANVAS.y * s), false, Image.FORMAT_RGBA8)
					cell.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(int(crop[0]), int(crop[1])))
					var src: String = file.get_file().get_basename()
					var row := _frame_checks(src, facing, cell, refs, false, ("res://" + str(e.guide)) if e.has("guide") else "")
					by_facing.get_or_add(facing, []).append(row)
					report.frames.append(row)
	# AC3: planted feet, measured on the painted frames. In place, a planted foot must move back by
	# exactly one frame's spacing (cycle_m / frames) from one stance frame to the next; in game the
	# sprite advances by that spacing, so any difference is the foot sliding on the deck. Measured at
	# the bottom of the figure (the planted sole), in cell px (720 * cell_scale px/m; the back view's
	# depth is foreshortened by sin 29 deg), reported in screen px at 2560 x 1440 (the Bow view).
	var stance := []
	for clip: String in anim.clips:
		var c: Dictionary = anim.clips[clip]
		if str(c.get("kind", "")) != "gait":
			continue
		for facing: String in c.stages["0"]:
			var list: Array = c.stages["0"][facing]
			var n := list.size()
			var mpf: float = float(c.get("cycle_m", 0.0)) / n
			var ppm: float = 720.0 * s
			var pos := []
			for e: Dictionary in list:
				var side_e := str(e.get("planted", ""))
				if side_e in ["L", "R"]:
					var g := Image.load_from_file(ProjectSettings.globalize_path("res://" + str(e.guide)))
					g.convert(Image.FORMAT_RGBA8)
					var hint := _key_sole(g, side_e)
					pos.append(_sole_points(_cell_of_entry(e, s), 0.5, hint.x, 13))
				else:
					pos.append([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
			for i in n:
				var a: Dictionary = list[i]
				var b: Dictionary = list[(i + 1) % n]
				var side := str(a.get("planted", ""))
				if side not in ["L", "R"] or str(b.get("planted", "")) != side:
					continue
				# The planted foot rolls (heel strike, flat, heel off over the toe): whichever of its heel,
				# centre and toe stays put is the contact, so the smallest drift of the three counts.
				var drift := INF
				var moved := 0.0
				for k in 3:
					var d: Vector2 = pos[(i + 1) % n][k] - pos[i][k]
					var mv: float = (-d.x / ppm) if facing == "profile" else (d.y / (ppm * sin(deg_to_rad(29.0))))
					if absf(mv - mpf) < absf(drift):
						drift = mv - mpf
						moved = mv
				var px := absf(drift) * SCREEN_PX_PER_M
				var row := {"clip": clip, "facing": facing, "from": i, "to": (i + 1) % n, "side": side, "moved_m": snappedf(moved, 0.0001), "deck_m": snappedf(mpf, 0.0001), "drift_m": snappedf(drift, 0.0001), "drift_px_1440": snappedf(px, 0.01)}
				stance.append(row)
				# The check measures on cells: one cell px is the resolution (0.68 screen px across, 1.4 px in
				# depth for the back view), added to the 2 px allowance.
				var res_px: float = SCREEN_PX_PER_M / ppm / (1.0 if facing == "profile" else sin(deg_to_rad(29.0)))
				row["limit_px"] = snappedf(STANCE_PX_MAX + res_px, 0.01)
				if px > STANCE_PX_MAX + res_px:
					_fail("%s %s frames %d->%d (%s planted): the foot slides %.1f px at 1440p (> %.0f)" % [clip, facing, i, (i + 1) % n, side, px, STANCE_PX_MAX])
	report["stance"] = stance
	# How far the painter's framing drifted (ingest rescales it; reported, not gated).
	report["ingest_scale"] = anim.get("ingest_scale", {})
	report["disk_bytes"] = disk
	report["gpu_bytes_with_mips"] = gpu
	if disk > DISK_STAGE_MAX:
		_fail("disk %d B > %d B for the stage" % [disk, DISK_STAGE_MAX])
	if gpu > GPU_STAGE_MAX:
		_fail("GPU %d B > %d B for the stage" % [gpu, GPU_STAGE_MAX])
	var real_ok: bool = report.failures.is_empty()
	if not selftest:
		return real_ok
	# Seeded defects: each must fail.
	var first: Dictionary = report.frames[0]
	var cell0 := _cell_of(anim, first.src)
	var recol := cell0.duplicate() as Image
	for y in recol.get_height():
		for x in recol.get_width():
			var c := recol.get_pixel(x, y)
			if c.a > 0.0:
				recol.set_pixel(x, y, Color(c.g * 0.6, c.b * 0.9, c.r, c.a)) # a cool, other palette
	var r1 := _frame_checks(first.src, first.facing, recol, refs, true, first.guide)
	var other := "profile" if first.facing == "back" else "back"
	var wrong := _frame_checks(first.src, other, cell0, refs, true, _other_guide(first.guide, first.facing, other))
	report["selftest_wrong_pose_iou"] = wrong.get("iou", 0.0)
	# The pose control for every frame: its IoU against the other facing's guide of the same index.
	var cross := {}
	for row: Dictionary in report.frames:
		var o2 := "profile" if row.facing == "back" else "back"
		var c2 := _cell_of(anim, row.src)
		var cr := _frame_checks(row.src, o2, c2, refs, true, _other_guide(row.guide, row.facing, o2))
		cross[row.src] = {"iou": cr.get("iou", 0.0), "legs": cr.get("legs", 0.0)}
	report["cross_pose_iou"] = cross
	var small := cell0.duplicate() as Image
	small.resize(int(cell0.get_width() * 0.7), int(cell0.get_height() * 0.7), Image.INTERPOLATE_BILINEAR)
	var padded := Image.create(cell0.get_width(), cell0.get_height(), false, Image.FORMAT_RGBA8)
	padded.blit_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), Vector2i((cell0.get_width() - small.get_width()) / 2, cell0.get_height() - small.get_height()))
	var r3 := _frame_checks(first.src, first.facing, padded, refs, true, first.guide)
	report["selftest"] = {"recoloured_fails": not r1.ok, "wrong_pose_fails": not wrong.ok, "wrong_scale_fails": not r3.ok, "real_frames_pass": real_ok}
	print("selftest: recoloured %s, wrong pose %s, wrong scale %s" % ["fails" if not r1.ok else "PASSES", "fails" if not wrong.ok else "PASSES", "fails" if not r3.ok else "PASSES"])
	return real_ok and not r1.ok and not wrong.ok and not r3.ok


static func _other_guide(guide: String, facing: String, other: String) -> String:
	return guide.replace("_%s_" % facing, "_%s_" % other)


func _cell_of(anim: Dictionary, src: String) -> Image:
	for clip: String in anim.clips:
		for stage: String in anim.clips[clip].stages:
			for facing: String in anim.clips[clip].stages[stage]:
				for e: Dictionary in anim.clips[clip].stages[stage][facing]:
					if str(e.file).get_file().get_basename() == src:
						var img := Image.load_from_file(ProjectSettings.globalize_path(DIR.path_join(e.file)))
						img.convert(Image.FORMAT_RGBA8)
						var cell := Image.create(int(CANVAS.x * anim.cell_scale), int(CANVAS.y * anim.cell_scale), false, Image.FORMAT_RGBA8)
						cell.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(int(e.crop[0]), int(e.crop[1])))
						return cell
	return null


## IoU against the guide mask (cell size) and palette class means against the reference still.
func _frame_checks(src: String, facing: String, cell: Image, refs: Dictionary, quiet := false, gpath := "") -> Dictionary:
	if gpath == "":
		gpath = "res://art/captain-anim-v1/guides/" + src + ".png"
	var row := {"src": src, "facing": facing, "ok": true, "notes": [], "guide": gpath}
	if not FileAccess.file_exists(gpath):
		row.ok = false
		row.notes.append("no guide")
		if not quiet: _fail("%s: no guide %s" % [src, gpath])
		return row
	var g := Image.load_from_file(ProjectSettings.globalize_path(gpath))
	g.convert(Image.FORMAT_RGBA8)
	var inter := 0; var uni := 0
	var legs := 0; var legs_hit := 0
	for y in cell.get_height():
		for x in cell.get_width():
			var a := cell.get_pixel(x, y).a > 0.5
			var gp := g.get_pixel(x, y)
			var b := gp.a > 0.25
			inter += int(a and b); uni += int(a or b)
			if gp.a > 0.5 and absf(gp.r - gp.b) > 0.3: # a red (left) or blue (right) leg key
				legs += 1; legs_hit += int(a)
	row["iou"] = float(inter) / maxf(1, uni)
	row["legs"] = float(legs_hit) / maxf(1, legs)
	var pmin: Array = POSE_MIN.get(facing, POSE_MIN_OTHER)
	if row.iou < pmin[0]:
		row.ok = false
		row.notes.append("IoU %.3f < %.2f" % [row.iou, pmin[0]])
	if row.legs < pmin[1]:
		row.ok = false
		row.notes.append("legs %.3f < %.2f" % [row.legs, pmin[1]])
	var hr := float(_figure_rect(cell, 0.5).size.y) / maxf(1, _figure_rect(g, 0.25).size.y)
	row["height_ratio"] = hr
	if absf(hr - 1.0) > HEIGHT_TOL:
		row.ok = false
		row.notes.append("figure %.3fx the guide's height" % hr)
	var still: String = REF_STILL.get(facing, REF_STILL.back)
	if not refs.has(still):
		var ri := Image.load_from_file(ProjectSettings.globalize_path(DIR.path_join(still)))
		ri.convert(Image.FORMAT_RGBA8)
		ri.resize(int(ri.get_width() * CELL_SCALE), int(ri.get_height() * CELL_SCALE), Image.INTERPOLATE_LANCZOS)
		refs[still] = _palette(ri)
	var ref: Dictionary = refs[still]
	var mine := _assign(cell, ref.centroids)
	var de := {}
	for i in ref.centroids.size():
		if ref.share[i] < PALETTE_SHARE_MIN:
			continue
		var key := "c%d" % i
		if mine.n[i] < PALETTE_SHARE_KEEP * ref.share[i] * mine.total:
			row.ok = false
			row.notes.append("%s (%.0f%% of the still) is %.0f%% here" % [key, 100.0 * ref.share[i], 100.0 * mine.n[i] / maxf(1, mine.total)])
		de[key] = _de(mine.mean[i], ref.centroids[i]) if mine.n[i] > 0 else INF
		if de[key] > DE_MAX:
			row.ok = false
			row.notes.append("%s dE %.1f > %.0f" % [key, de[key], DE_MAX])
	row["de"] = de
	if not row.ok and not quiet:
		_fail("%s (%s): %s" % [src, facing, ", ".join(row.notes)])
	return row


static func _de(a: Vector3, b: Vector3) -> float:
	return a.distance_to(b)


static func _lab(c: Color) -> Vector3:
	var r := _lin(c.r); var g := _lin(c.g); var b := _lin(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
	var y := 0.2126 * r + 0.7152 * g + 0.0722 * b
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
	var fx := _f(x); var fy := _f(y); var fz := _f(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


static func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


static func _f(t: float) -> float:
	return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0


func _fail(msg: String) -> void:
	report.failures.append(msg)
	print("FAIL ", msg)


## The still's palette: k-means (k = PALETTE_K, deterministic: seeded from the luminance-sorted
## pixels) over its opaque pixels in Lab; the centroids and each one's share of the figure.
static func _palette(img: Image) -> Dictionary:
	var px: Array[Vector3] = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a >= 0.9:
				px.append(_lab(c))
	px.sort_custom(func(a, b): return a.x < b.x)
	var cents: Array[Vector3] = []
	for i in PALETTE_K:
		cents.append(px[int((i + 0.5) * px.size() / PALETTE_K)])
	for it in 12:
		var sum: Array[Vector3] = []
		var n: Array[int] = []
		for i in PALETTE_K:
			sum.append(Vector3.ZERO); n.append(0)
		for p in px:
			var j := _nearest(p, cents)
			sum[j] += p; n[j] += 1
		for i in PALETTE_K:
			if n[i] > 0:
				cents[i] = sum[i] / n[i]
	var share: Array[float] = []
	var counts := _assign_counts(px, cents)
	for i in PALETTE_K:
		share.append(float(counts[i]) / px.size())
	return {"centroids": cents, "share": share}


static func _assign_counts(px: Array[Vector3], cents: Array[Vector3]) -> Array[int]:
	var n: Array[int] = []
	for i in cents.size():
		n.append(0)
	for p in px:
		n[_nearest(p, cents)] += 1
	return n


static func _nearest(p: Vector3, cents: Array[Vector3]) -> int:
	var best := 0
	var bd := INF
	for i in cents.size():
		var d := p.distance_squared_to(cents[i])
		if d < bd:
			bd = d; best = i
	return best


## A frame's opaque pixels sorted to the still's centroids: counts and mean Lab per centroid.
static func _assign(img: Image, cents: Array) -> Dictionary:
	var c2: Array[Vector3] = []
	for c in cents:
		c2.append(c)
	var sum: Array[Vector3] = []
	var n: Array[int] = []
	for i in c2.size():
		sum.append(Vector3.ZERO); n.append(0)
	var total := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.9:
				continue
			var l := _lab(c)
			var j := _nearest(l, c2)
			sum[j] += l; n[j] += 1; total += 1
	var mean: Array[Vector3] = []
	for i in c2.size():
		mean.append(sum[i] / n[i] if n[i] > 0 else Vector3.ZERO)
	return {"mean": mean, "n": n, "total": total}


static func _cell_of_entry(e: Dictionary, s: float) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(DIR.path_join(e.file)))
	img.convert(Image.FORMAT_RGBA8)
	var cell := Image.create(int(CANVAS.x * s), int(CANVAS.y * s), false, Image.FORMAT_RGBA8)
	cell.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(int(e.crop[0]), int(e.crop[1])))
	if bool(e.get("flip", false)):
		cell.flip_x()
	return cell


## The guide's planted boot: the lowest pixels of that leg's colour key (red L, blue R); x centroid, bottom y.
static func _key_sole(guide: Image, side: String) -> Vector2:
	var bottom := -1
	for y in range(guide.get_height() - 1, -1, -1):
		for x in guide.get_width():
			if _is_key(guide.get_pixel(x, y), side):
				bottom = y
				break
		if bottom >= 0:
			break
	if bottom < 0:
		return Vector2(-1, -1)
	var band := maxi(2, int(guide.get_height() * 0.015))
	var sx := 0.0
	var n := 0
	for y in range(bottom - band, bottom + 1):
		for x in guide.get_width():
			if _is_key(guide.get_pixel(x, y), side):
				sx += x
				n += 1
	return Vector2(sx / maxf(1, n), bottom)


static func _is_key(c: Color, side: String) -> bool:
	return c.a > 0.5 and ((c.r - c.b > 0.3) if side == "L" else (c.b - c.r > 0.3))


## The painted planted sole: the lowest opaque pixels within a column window around the guide's boot
## (so the other, trailing boot is ignored); x centroid, bottom y.
static func _sole_near(img: Image, thr: float, x_hint: float, radius: int) -> Vector2:
	var x0 := maxi(0, int(x_hint) - radius)
	var x1 := mini(img.get_width(), int(x_hint) + radius + 1)
	var bottom := -1
	for y in range(img.get_height() - 1, -1, -1):
		for x in range(x0, x1):
			if img.get_pixel(x, y).a > thr:
				bottom = y
				break
		if bottom >= 0:
			break
	if bottom < 0:
		return Vector2(-1, -1)
	var band := maxi(2, int(img.get_height() * 0.015))
	var sx := 0.0
	var n := 0
	for y in range(bottom - band, bottom + 1):
		for x in range(x0, x1):
			if img.get_pixel(x, y).a > thr:
				sx += x
				n += 1
	return Vector2(sx / maxf(1, n), bottom)


## The planted boot's [heel side, centre, toe side] at the bottom of the figure near the guide's boot:
## the band's leftmost, centroid and rightmost points (the back view: the same band's centroid, thrice).
static func _sole_points(img: Image, thr: float, x_hint: float, radius: int) -> Array:
	var c := _sole_near(img, thr, x_hint, radius)
	if c.x < 0.0:
		return [c, c, c]
	var band := maxi(2, int(img.get_height() * 0.015))
	var x0 := INF
	var x1 := -INF
	for y in range(int(c.y) - band, int(c.y) + 1):
		for x in range(maxi(0, int(x_hint) - radius), mini(img.get_width(), int(x_hint) + radius + 1)):
			if img.get_pixel(x, y).a > thr:
				x0 = minf(x0, x)
				x1 = maxf(x1, x)
	return [Vector2(x0, c.y), c, Vector2(x1, c.y)]
