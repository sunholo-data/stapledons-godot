extends SceneTree
## AC11 auditor (tools/bright_star_audit.gd, M1.2d) on synthetic renders. Run:
##   godot --headless --path . --script tests/test_bright_audit.gd
## Stars are painted as Gaussian splats at sub-pixel positions the auditor does not see; it must
## recover them to well under a pixel, apply the 1 px hit radius, the 95% rule, the [min, max]
## count window and the by-id de-duplication across frames, and the CLI must refuse a directory
## without frames. Exits non-zero on any failure.

const Audit := preload("res://tools/bright_star_audit.gd")
const DIR := "user://test_bright_audit"

var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


## black frame with a Gaussian splat (sigma 0.8 px, peak `amp`) per centre
func render(w: int, h: int, centres: Array) -> Image:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBF)
	for y in h:
		for x in w:
			var l := 0.0
			for c: Vector2 in centres:
				var d := Vector2(x + 0.5, y + 0.5) - c
				l += exp(-d.length_squared() / (2.0 * 0.8 * 0.8))
			img.set_pixel(x, y, Color(l, l, l))
	return img


func grid(n: int, w: int) -> Array:
	var out := []
	for i in n:
		out.append(Vector2(6.3 + 9.0 * (i % (w / 9 - 1)), 6.7 + 9.0 * (i / (w / 9 - 1))))
	return out


func stars(centres: Array, v: float, prefix := "HIP ") -> Array:
	var out := []
	for i in centres.size():
		out.append({"id": "%s%d" % [prefix, i], "x": centres[i].x, "y": centres[i].y, "v": v})
	return out


func _init() -> void:
	# detection recovers sub-pixel centres
	var cs := [Vector2(10.3, 12.8), Vector2(30.75, 5.4), Vector2(50.5, 50.5)]
	var found := Audit.detect(render(64, 64, cs))
	var worst := 0.0
	for c: Vector2 in cs:
		var best := INF
		for f in found:
			best = minf(best, f.distance_to(c))
		worst = maxf(worst, best)
	check("detects every splat once", found.size() == 3, str(found))
	check("centroid within 0.15 px of the painted centre", worst < 0.15, "worst %.3f px" % worst)
	check("a black frame has no detections", Audit.detect(render(16, 16, [])).is_empty())

	# 20 V < 2.5 stars: 19 rendered = 95% passes, 18 = 90% fails; a 1.5 px offset is a miss
	var c20 := grid(20, 64)
	var pred := stars(c20, 1.0)
	var r := Audit.audit([{"image": render(64, 64, c20.slice(0, 19)), "stars": pred}], 19, 20)
	check("19/20 bright stars (95%) passes", r["pass"] and r["bright"] == 20 and r["bright_hit"] == 19, str(r))
	r = Audit.audit([{"image": render(64, 64, c20.slice(0, 18)), "stars": pred}], 18, 20)
	check("18/20 bright stars (90%) fails", not r["pass"] and r["bright_hit"] == 18, str(r))
	var shifted := []
	for c: Vector2 in c20:
		shifted.append(c + Vector2(1.5, 0.0))
	r = Audit.audit([{"image": render(64, 64, shifted), "stars": pred}], 0, 100)
	check("a 1.5 px offset is not a hit", r["bright_hit"] == 0 and not r["pass"], str(r))
	var near := []
	for c: Vector2 in c20:
		near.append(c + Vector2(0.6, 0.5))
	r = Audit.audit([{"image": render(64, 64, near), "stars": pred}], 0, 100)
	check("a 0.78 px offset is a hit", r["bright_hit"] == 20 and r["pass"], str(r))

	# the V < 6.5 count window, and one star seen in two frames counts once
	var faint := stars(c20, 5.0, "F")
	var both := pred + faint
	var img := render(64, 64, c20)
	r = Audit.audit([{"image": img, "stars": both}], 40, 40)
	check("rendered V < 6.5 counts bright + faint (40)", r["rendered_v65"] == 40 and r["pass"], str(r))
	r = Audit.audit([{"image": img, "stars": both}, {"image": img, "stars": both}], 40, 40)
	check("a star in two frames counts once", r["rendered_v65"] == 40 and r["bright"] == 20, str(r))
	r = Audit.audit([{"image": img, "stars": both}], 41, 100)
	check("below the count window fails", not r["pass"], str(r))
	r = Audit.audit([{"image": img, "stars": both}], 0, 39)
	check("above the count window fails", not r["pass"], str(r))
	r = Audit.audit([{"image": img, "stars": stars(c20, 7.0)}], 0, 100)
	check("no V < 2.5 star predicted is a fail, not a vacuous pass", not r["pass"] and r["bright"] == 0, str(r))
	r = Audit.audit([{"image": img, "stars": [{"id": "edge", "x": 0.4, "y": 30.0, "v": 0.0}] + pred}], 0, 100)
	check("a star outside the detectable interior is skipped", r["bright"] == 20 and r["pass"], str(r))
	check("AC11 defaults", Audit.COUNT_MIN == 5000 and Audit.COUNT_MAX == 9100 and Audit.MIN_FRACTION == 0.95
		and Audit.BRIGHT_V == 2.5 and Audit.COUNT_V == 6.5 and Audit.HIT_PX == 1.0)

	# the CLI: a directory without frame pairs is refused (exit 2); with a pair it exits by verdict
	DirAccess.make_dir_recursive_absolute(DIR)
	for old in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute("%s/%s" % [DIR, old])
	var out := []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tools/bright_star_audit.gd", "--", ProjectSettings.globalize_path(DIR)], out, true)
	check("CLI refuses a directory with no frames (exit 2)", code == 2, str(out))
	img.save_png("%s/f0.png" % DIR)
	var f := FileAccess.open("%s/f0.audit.json" % DIR, FileAccess.WRITE)
	f.store_string(JSON.stringify({"stars": both})); f.close()
	code = OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tools/bright_star_audit.gd", "--", ProjectSettings.globalize_path(DIR)], out, true)
	check("CLI on 40 rendered stars fails the 5,000 floor (exit 1) and prints the numbers",
		code == 1 and str(out).contains("20/20") and str(out).contains("rendered V < 6.5: 40"), str(out))
	print("test_bright_audit: %d passed, %d failed" % [passes, failures])
	quit(0 if failures == 0 else 1)
