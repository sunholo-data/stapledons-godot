extends SceneTree
## R2-INTERLUDE I3 (AC11): the crossing review's frames from the live demo and the real sim (2.10),
## over the live cruise sky, at 1280x720 and 2560x1440:
##   acen_<page>          the Alpha Centauri leg (an orders crew under critical_only): the Hold page
##                        the crossing stops on, then every page of the finished crossing
##   nocrew_<page>        the same leg with no crew aboard (no crew pages)
##   trappist_<page>      TRAPPIST-1 (the crossing, home and aboard pages), then on to
##   aldebaran_<page>     Aldebaran (Earth years add up across legs: a later home tier)
## make crossing-review-capture -> renders/crossing_review/<frame>_<w>x<h>.png. A person opens
## every frame. The home image per tier is attended art (Rulings §2): until data/interlude/home/
## tier<n>.png exists the cruise sky with the tier line stands in, and each such frame is flagged
## (PLACEHOLDER). Layout checks per frame: the panel inside the window, every label inside the
## panel (nothing cut off at the sides), the page buttons below the page.

const OUT := "res://renders/crossing_review"
const ReviewDrive := preload("res://tests/review_drive.gd")
var sizes: Array = [Vector2i(1280, 720), Vector2i(2560, 1440)]
var demo: Node
var written := 0
var failed := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("sizes="):
			sizes = []
			for s in a.trim_prefix("sizes=").split(","):
				var p := s.split("x")
				sizes.append(Vector2i(int(p[0]), int(p[1])))
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for sz: Vector2i in sizes:
		await scenario(sz, "acen", "orders", 4, 1, [])
		await scenario(sz, "nocrew", "", 4, 1, [])
		await scenario(sz, "trappist", "orders", 5, 2, ["crossing", "home", "aboard"])
	print("crossing-review-capture: %s (%d frames)" % ["FAIL" if failed else "OK", written])
	quit(1 if failed else 0)


func fail(why: String) -> void:
	failed = true
	print("FAIL " + why)


func settle(frames := 8) -> void:
	for i in frames:
		demo._process(0.05)
		await process_frame
	await RenderingServer.frame_post_draw


## One shot of the review's current page, with the layout checks.
func shot(name: String, sz: Vector2i) -> void:
	await settle()
	var r: CrossingReview = demo.crossing_review
	var panel := r.get_global_rect()
	var win := Rect2(Vector2.ZERO, r.get_viewport_rect().size)
	if not win.encloses(panel): fail("%s: the review %s leaves the window %s" % [name, panel, win])
	var scroll: ScrollContainer = r.find_children("*", "ScrollContainer", true, false)[0]
	for l in r.find_children("*", "Label", true, false):
		if not l.is_visible_in_tree(): continue
		var g: Rect2 = l.get_global_rect()
		if g.position.x < panel.position.x - 0.5 or g.end.x > panel.end.x + 0.5: fail("%s: label cut off at the side: %s" % [name, l.text])
	var nav: Control = r.find_child("Nav", true, false)
	if nav.get_global_rect().position.y < scroll.get_global_rect().end.y - 0.5: fail("%s: the page buttons overlap the page" % name)
	var content_h: float = scroll.get_child(0).get_combined_minimum_size().y
	var img := root.get_texture().get_image()
	var path := "%s/%s_%dx%d.png" % [OUT, name, sz.x, sz.y]
	img.save_png(path)
	written += 1
	print("frame %s %dx%d page=%s scrolls=%s" % [name, img.get_width(), img.get_height(), r.current(), content_h > scroll.size.y + 0.5])
	if r.current() == "home" and r.home_placeholder():
		print("PLACEHOLDER %s: no data/interlude/home/tier%d.png yet; the cruise sky with the tier line stands in (Rulings §2, attended art)" % [name, int(GalaxyMap.field_value(demo.sky_world, "cruise.digest.time.tier"))])


## Fly `legs` legs from itinerary index `first`, shooting the Hold page (first leg) and the pages.
func scenario(sz: Vector2i, slug: String, crew: String, first: int, legs: int, only: Array) -> void:
	root.size = sz
	get_root().get_window().size = sz
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"live_start": true, "sky_state": "rest", "size": sz, "crew": crew}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not demo.ready_ok or not ReviewDrive.begin(demo, first):
		fail("%s: the guided voyage did not begin" % slug)
		demo.queue_free(); await process_frame; return
	demo.set_preset("bridge")
	var r: CrossingReview = demo.crossing_review
	var names := ["", "", "", "", "acen", "trappist", "aldebaran"]
	for leg in legs:
		var tag: String = slug if leg == 0 and slug == "nocrew" else str(names[first + leg])
		var held_shot := false
		var state := ""
		for tries in 20:
			state = ReviewDrive.reach(demo, true)
			if state != "held": break
			if not held_shot:
				demo.look_direction("forward")
				await settle(40) # the turn to the sky ahead
				await shot(tag + "_hold", sz)
				held_shot = true
			ReviewDrive.frame(demo, true) # the review's confirmed Resume
		if state != "crossed":
			fail("%s: the crossing did not reach its review (%s, %s)" % [tag, state, demo.solar_tour.failed])
			break
		demo.look_direction("forward")
		for i in r.page_ids().size():
			var id: String = r.page_ids()[i]
			var kind := id.get_slice("_", 0) if id.begins_with("moment") else id
			if not only.is_empty() and not only.has(kind): continue
			r.go(i)
			await shot("%s_%s" % [tag, id], sz)
		r.go(r.page_ids().size() - 1)
		r.key(KEY_ENTER) # Brake
		if leg + 1 < legs:
			for i in 8000:
				if demo.solar_tour.leg_index == first + leg + 1 and demo.live_journey: break
				if ReviewDrive.frame(demo, true) == "failed": break
	demo.queue_free()
	await process_frame
