extends SceneTree
## R2-LEVELS design mocks (design_docs/planned/r2/levels.md §L1, §L9; Mark D-100 "more intricate level
## design"): a role-coloured GREYBOX of an intricate Commons and a re-imagined bridge sketch, laid over
## the real ship and seen through the fixed views with the live sky, plus the evaluator-style numbers
## (traversal graph, head and pole rays per surface sample, captain size per height, discoveries in
## frame). Review only: the greybox is primitives built here, nothing is exported or shipped.
## Colours: sand = walkable surfaces, teal = structure, orange = routes (stairs, ladders, hatches),
## magenta = things to find, violet = foreground layer, grey = background landmarks.
## Writes renders/levels/intricate/*.png, contact_sheet.png and metrics.json. GPU window, 1280x720.
## Usage: godot --path . --script tools/levels_intricate_mock.gd -- [--out=res://renders/levels/intricate]
var demo: Node
var out := "res://renders/levels/intricate"
var px := Vector2i(1280, 720)
var rows := []
var box_root: Node3D
var mats := {}
const BOW := {"yaw": 270.0, "pitch": -8.0, "back": 9.0, "rise": 5.5}
const CRAWL := {"yaw": 270.0, "pitch": -4.0, "back": 6.0, "rise": 1.9}
const SURF := "surface"
## The ceiling clamp (design §L1.3): under an overhang the slide lowers and closes in, never turns.
const CLAMP := {"yaw": 270.0, "pitch": -4.0, "back": 6.0, "rise": 2.2}

## Commons greybox (glTF metres: x, y up, z = -ship_y; the bow is -z). [kind, centre, size, name]
const COMMONS := [
	# mezzanine terrace on the starboard side, 4 m up, with posts and a rail
	[SURF, Vector3(34, 61.0, -8), Vector3(8, 0.4, 16), "mezzanine"],
	["structure", Vector3(30.3, 59.0, -15.5), Vector3(0.4, 4, 0.4), "post"],
	["structure", Vector3(30.3, 59.0, -0.5), Vector3(0.4, 4, 0.4), "post"],
	["structure", Vector3(30.3, 61.8, -8), Vector3(0.12, 0.9, 16), "mezz_rail"],
	["route", Vector3(27, 59.0, 1.2), Vector3(6, 0.3, 1.6), "stairs_mezz"], # drawn as a ramp block (greybox)
	# alcove stalls along the port side, open toward the court
	["structure", Vector3(15.5, 60.2, -12), Vector3(3, 0.25, 3), "stall_roof"],
	["structure", Vector3(15.5, 60.2, -7.5), Vector3(3, 0.25, 3), "stall_roof"],
	["structure", Vector3(15.5, 60.2, -3), Vector3(3, 0.25, 3), "stall_roof"],
	["structure", Vector3(14.1, 58.6, -7.5), Vector3(0.2, 3.2, 12), "stall_back"],
	# a catwalk across the frame 9 m up, from the lift gantry to the mezzanine ladder and a bow balcony
	[SURF, Vector3(24, 66.0, -12), Vector3(32, 0.25, 1.4), "catwalk"],
	["structure", Vector3(24, 66.6, -12.65), Vector3(32, 0.08, 0.06), "catwalk_rail"],
	["structure", Vector3(24, 66.6, -11.35), Vector3(32, 0.08, 0.06), "catwalk_rail"],
	["route", Vector3(37.5, 63.5, -12.9), Vector3(0.6, 5.0, 0.15), "ladder_catwalk"],
	[SURF, Vector3(42, 66.0, -14), Vector3(4, 0.25, 4), "balcony"],
	["structure", Vector3(42, 66.6, -16.0), Vector3(4, 1.0, 0.08), "balcony_rail"],
	["structure", Vector3(8.5, 61.5, -12), Vector3(1.2, 9, 1.2), "gantry_strut"],
	# a hatch to the service gallery hung under the Commons slab (in the Homes tier's ceiling)
	["route", Vector3(20, 57.03, -6), Vector3(1.2, 0.06, 1.2), "hatch"],
	[SURF, Vector3(26, 52.6, -3), Vector3(16, 0.3, 14), "service_gallery"],
	["structure", Vector3(26, 54.2, -9.5), Vector3(16, 0.5, 0.5), "pipe"],
	["structure", Vector3(26, 55.0, 3.5), Vector3(16, 0.7, 0.7), "pipe"],
	["structure", Vector3(19, 54.3, -3), Vector3(0.3, 3.4, 0.3), "hanger"],
	["structure", Vector3(33, 54.3, -3), Vector3(0.3, 3.4, 0.3), "hanger"],
	# things to find
	["find", Vector3(16.5, 58.5, -9), Vector3(0.15, 1.2, 1.6), "notice_board"],
	["find", Vector3(43, 67.0, -15), Vector3(0.4, 1.4, 0.4), "telescope"],
	["find", Vector3(35, 61.7, -13), Vector3(1.6, 0.9, 0.6), "mezz_bench"],
	["find", Vector3(30, 53.5, -8), Vector3(0.8, 1.6, 0.8), "service_panel"],
	# foreground layer between the camera and the court (above head height)
	["fore", Vector3(25, 64.6, 0), Vector3(14, 0.35, 0.35), "banner_beam"],
	["fore", Vector3(19.5, 57.7, 2.5), Vector3(1.6, 1.4, 1.6), "planter"],
	["fore", Vector3(30.5, 57.7, 2.5), Vector3(1.6, 1.4, 1.6), "planter"],
	# background landmarks on the far floor
	["back", Vector3(13, 66, -57), Vector3(6, 18, 6), "civic_tower"],
	["back", Vector3(35, 61, -40), Vector3(30, 0.4, 6), "market_canopy"],
	["back", Vector3(35, 59, -42.8), Vector3(30, 4, 0.3), "market_back"],
]

## Bridge sketch over today's bridge (deck +82, radius 22, the spire on the axis, the helm at the bow rail).
const BRIDGE := [
	[SURF, Vector3(0, 85.0, 11), Vector3(20, 0.35, 6), "stern_gallery"],
	["structure", Vector3(-9.5, 83.5, 8.2), Vector3(0.35, 3, 0.35), "post"],
	["structure", Vector3(9.5, 83.5, 8.2), Vector3(0.35, 3, 0.35), "post"],
	["structure", Vector3(0, 85.7, 8.1), Vector3(20, 0.9, 0.1), "gallery_rail"],
	["route", Vector3(11.5, 83.6, 5.5), Vector3(1.6, 0.3, 5.5), "stairs_gallery"],
	[SURF, Vector3(0, 88.0, -3.6), Vector3(8, 0.25, 1.0), "mast_ring_bow"],
	[SURF, Vector3(0, 88.0, 3.6), Vector3(8, 0.25, 1.0), "mast_ring_stern"],
	[SURF, Vector3(-3.6, 88.0, 0), Vector3(1.0, 0.25, 6.2), "mast_ring_port"],
	[SURF, Vector3(3.6, 88.0, 0), Vector3(1.0, 0.25, 6.2), "mast_ring_stbd"],
	["route", Vector3(4.6, 85.0, 1.5), Vector3(0.6, 6.0, 0.15), "ladder_mast"],
	["find", Vector3(0, 88.8, -4.0), Vector3(1.2, 1.2, 0.5), "mast_scope"],
	["fore", Vector3(0, 89.6, -6), Vector3(18, 0.3, 0.3), "lamp_beam"],
]


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
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": px, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("levels-intricate: FAIL demo did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	box_root = Node3D.new()
	demo.geometry.add_child(box_root)
	_build(COMMONS)
	_build(BRIDGE)
	for k in 4:
		await physics_frame
	var metrics := {"commons": _measure_commons(), "bridge": _measure_bridge()}
	for sky: String in ["rest", "cruise"]:
		demo.set_sky_state(sky)
		await _shot("commons_floor_%s" % sky, Vector3(25, 57, -5), BOW)
		await _shot("commons_mezzanine_%s" % sky, Vector3(34, 61.2, -6), BOW)
		await _shot("commons_catwalk_%s" % sky, Vector3(26, 66.1, -12), BOW)
		await _shot("commons_balcony_%s" % sky, Vector3(42, 66.1, -13.5), BOW)
		await _shot("commons_service_%s" % sky, Vector3(26, 52.75, -1), CRAWL)
		await _shot("bridge_sketch_%s" % sky, demo.bridge_spawn(), BOW)
		await _shot("bridge_gallery_%s" % sky, Vector3(3, 85.2, 11), BOW)
		await _shot("bridge_mast_%s" % sky, Vector3(0, 88.1, 3.6), BOW)
	await _diagnostic("commons_diagnostic", Vector3(62, 78, 22), Vector3(25, 58, -8))
	await _diagnostic("bridge_diagnostic", Vector3(24, 96, 26), Vector3(0, 84, 0))
	_sheet()
	var f := FileAccess.open(out + "/metrics.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-LEVELS intricate greybox mocks: evaluator-style numbers (design §L9)", "metrics": metrics, "frames": rows}, "  "))
	print("levels-intricate: %d frames" % rows.size())
	print(JSON.stringify(metrics))
	quit(0)


func _mat(kind: String) -> StandardMaterial3D:
	if mats.has(kind):
		return mats[kind]
	var c: Color = {SURF: Color(0.86, 0.72, 0.5), "structure": Color(0.15, 0.45, 0.47), "route": Color(0.93, 0.5, 0.15),
		"find": Color(0.85, 0.2, 0.65), "fore": Color(0.25, 0.18, 0.35), "back": Color(0.45, 0.45, 0.5)}[kind]
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	mats[kind] = m
	return m


func _build(list: Array) -> void:
	for e: Array in list:
		var body := StaticBody3D.new()
		body.name = "GB_%s_%s" % [e[0], e[3]]
		body.position = e[1]
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = e[2]
		mi.mesh = bm
		mi.material_override = _mat(e[0])
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = e[2]
		cs.shape = sh
		body.add_child(cs)
		box_root.add_child(body)


## A walk pose: the eye `back` m behind the captain toward the stern and `rise` m above the captain's
## own floor; the slide follows the floor height, so climbing raises the camera without turning it.
func _pose(captain: Vector3, v: Dictionary) -> Transform3D:
	var y := deg_to_rad(float(v.yaw))
	var p := deg_to_rad(float(v.pitch))
	var ground := Vector3(cos(y), 0.0, sin(y))
	var eye := captain - ground * float(v.back) + Vector3(0.0, float(v.rise), 0.0)
	var dir := ground * cos(p) + Vector3(0.0, sin(p), 0.0)
	return Transform3D(Basis.looking_at(dir, Vector3.UP), eye)


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	return demo.camera.get_world_3d().direct_space_state.intersect_ray(q)


## Evaluator-style sample over one surface: head ray and pole ray from the view's eye, captain size.
func _surface(name: String, x0: float, x1: float, z0: float, z1: float, y: float, v: Dictionary, cam: Camera3D) -> Dictionary:
	var n := 0
	var head_blocked := 0
	var pole_blocked := 0
	var px_min := 1e9
	var px_max := 0.0
	var by := {}
	var under := 0
	var head_clamped := 0
	var x := x0
	while x <= x1 + 1e-3:
		var z := z0
		while z <= z1 + 1e-3:
			var c := Vector3(x, y, z)
			var t := _pose(c, v)
			var head := c + Vector3(0, 1.6, 0)
			var hit := _ray(t.origin, head + (t.origin - head).normalized() * 0.4)
			if not hit.is_empty() and String(hit.collider.name).begins_with("GB_"):
				head_blocked += 1
				var hk := "head:" + String(hit.collider.name).trim_prefix("GB_")
				by[hk] = int(by.get(hk, 0)) + 1
			var up := _ray(head, head + Vector3(0, 8, 0))
			if v == BOW and not up.is_empty() and String(up.collider.name).begins_with("GB_"):
				under += 1
				var tc := _pose(c, CLAMP)
				var hc := _ray(tc.origin, head + (tc.origin - head).normalized() * 0.4)
				if not hc.is_empty() and String(hc.collider.name).begins_with("GB_"):
					head_clamped += 1
			elif not hit.is_empty() and String(hit.collider.name).begins_with("GB_"):
				head_clamped += 1
			var pole := _ray(t.origin, t.origin + Vector3(0, 0, -400))
			if not pole.is_empty():
				pole_blocked += 1
				var pk := "pole:" + String(pole.collider.name).trim_prefix("GB_")
				by[pk] = int(by.get(pk, 0)) + 1
			cam.global_transform = t
			var a := cam.unproject_position(c)
			var b := cam.unproject_position(c + Vector3(0, 1.754, 0))
			var h := absf(a.y - b.y)
			px_min = minf(px_min, h)
			px_max = maxf(px_max, h)
			n += 1
			z += 1.0
		x += 1.0
	return {"surface": name, "samples": n, "head_blocked": head_blocked, "pole_blocked": pole_blocked, "captain_px": [snappedf(px_min, 0.1), snappedf(px_max, 0.1)], "blocked_by": by, "under_overhang": under, "head_blocked_with_clamp": head_clamped}


func _probe_cam() -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = demo.camera.fov
	cam.current = false
	demo.camera.get_parent().add_child(cam)
	return cam


## Route graph: surfaces joined by connectors; hops and metres from the spawn to every surface and find.
func _graph(nodes: Dictionary, edges: Array, finds: Dictionary, spawn: String) -> Dictionary:
	var dist := {spawn: 0.0}
	var hops := {spawn: 0}
	var frontier := [spawn]
	while not frontier.is_empty():
		var u: String = frontier.pop_front()
		for e: Array in edges:
			var w: String = e[1] if e[0] == u else (e[0] if e[1] == u else "")
			if w == "" or dist.has(w):
				continue
			dist[w] = dist[u] + (nodes[u] as Vector3).distance_to(nodes[w]) + float(e[2])
			hops[w] = hops[u] + 1
			frontier.append(w)
	var find_out := {}
	for f: String in finds:
		var s: String = finds[f]
		find_out[f] = {"on": s, "reachable": dist.has(s), "hops": hops.get(s, -1), "route_m": snappedf(dist.get(s, -1.0), 0.1)}
	var unreached := []
	for k: String in nodes:
		if not dist.has(k):
			unreached.append(k)
	return {"surfaces": nodes.size(), "heights": _heights(nodes), "unreached": unreached, "hops": hops, "finds": find_out}


func _heights(nodes: Dictionary) -> Array:
	var hs := []
	for k: String in nodes:
		var y := snappedf((nodes[k] as Vector3).y, 0.5)
		if not hs.has(y):
			hs.append(y)
	hs.sort()
	return hs


## Things to find visible from the floor view at the court centre (in frame and not hidden by greybox).
func _finds_in_frame(captain: Vector3, cam: Camera3D, names: Array) -> Dictionary:
	cam.global_transform = _pose(captain, BOW)
	var outd := {}
	for e: Array in COMMONS + BRIDGE:
		if not names.has(e[3]):
			continue
		var p: Vector3 = e[1]
		var s := cam.unproject_position(p)
		var inside := not cam.is_position_behind(p) and s.x >= 0 and s.x <= px.x and s.y >= 0 and s.y <= px.y
		var hit := _ray(cam.global_position, p)
		var clear: bool = hit.is_empty() or String(hit.collider.name) == "GB_find_" + e[3]
		outd[e[3]] = {"in_frame": inside, "unblocked": clear}
	return outd


func _measure_commons() -> Dictionary:
	var cam := _probe_cam()
	var surfaces := [
		_surface("floor", 14, 36, -20, 6, 57.0, BOW, cam),
		_surface("mezzanine", 31, 37, -15, -1, 61.2, BOW, cam),
		_surface("catwalk", 9, 39, -12, -12, 66.1, BOW, cam),
		_surface("balcony", 41, 43, -15, -13, 66.1, BOW, cam),
		_surface("service_gallery", 19, 33, -9, 3, 52.75, CRAWL, cam),
	]
	var nodes := {"landing": Vector3(8, 57, -4.8), "floor": Vector3(25, 57, -5), "mezzanine": Vector3(34, 61.2, -8),
		"catwalk": Vector3(24, 66.1, -12), "balcony": Vector3(42, 66.1, -14), "service_gallery": Vector3(26, 52.75, -3),
		"lift_gantry": Vector3(8.5, 66.1, -12)}
	var edges := [["landing", "floor", 0.0], ["floor", "mezzanine", 2.0], ["mezzanine", "catwalk", 5.0], ["catwalk", "balcony", 0.0],
		["floor", "service_gallery", 4.3], ["catwalk", "lift_gantry", 0.0]]
	var finds := {"notice_board": "floor", "mezz_bench": "mezzanine", "telescope": "balcony", "service_panel": "service_gallery"}
	var g := _graph(nodes, edges, finds, "landing")
	var seen := _finds_in_frame(Vector3(25, 57, -5), cam, ["notice_board", "mezz_bench", "telescope", "service_panel", "hatch", "ladder_catwalk", "stairs_mezz"])
	cam.queue_free()
	return {"surfaces": surfaces, "routes": g, "from_floor_view": seen}


func _measure_bridge() -> Dictionary:
	var cam := _probe_cam()
	var sp: Vector3 = demo.bridge_spawn()
	var surfaces := [
		_surface("stern_gallery", -9, 9, 9, 13, 85.2, BOW, cam),
		_surface("mast_ring_stern", -3, 3, 3.6, 3.6, 88.1, BOW, cam),
	]
	var nodes := {"deck": sp, "stern_gallery": Vector3(0, 85.2, 11), "mast_ring": Vector3(0, 88.1, 3.6)}
	var edges := [["deck", "stern_gallery", 1.0], ["deck", "mast_ring", 6.0]]
	var g := _graph(nodes, edges, {"mast_scope": "mast_ring"}, "deck")
	var seen := _finds_in_frame(sp, cam, ["mast_scope", "ladder_mast", "stairs_gallery"])
	cam.queue_free()
	return {"surfaces": surfaces, "routes": g, "from_spawn_view": seen}


func _place(captain: Vector3) -> void:
	demo.consoles.cancel_walk()
	demo.director.override()
	demo.avatar_pos = captain
	demo.captain_yaw = -PI * 0.5
	demo.camera_mode = "review"
	for k in 20:
		demo._process(1.0 / 60.0)
	demo.avatar_pos = captain
	demo.avatar.visible = true


func _shot(name: String, captain: Vector3, v: Dictionary) -> void:
	_place(captain)
	demo.camera.global_transform = _pose(captain, v)
	demo._sync_observer()
	await _save(name, {"captain": [captain.x, captain.y, captain.z], "view": v})


func _diagnostic(name: String, eye: Vector3, aim: Vector3) -> void:
	_place(Vector3(25, 57, -5))
	demo.set_sky_state("rest")
	demo.camera.global_transform = Transform3D(Basis.looking_at(aim - eye, Vector3.UP), eye)
	demo._sync_observer()
	await _save(name, {"diagnostic": true, "eye": [eye.x, eye.y, eye.z]})


func _save(name: String, pose: Dictionary) -> void:
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	pose["name"] = name
	pose["sky"] = demo.sky_state
	rows.append(pose)
	print("shot %s" % name)


func _sheet() -> void:
	var names := ["commons_floor_cruise", "commons_mezzanine_cruise", "commons_catwalk_cruise", "commons_balcony_cruise",
		"commons_service_rest", "commons_floor_rest", "commons_diagnostic", "bridge_diagnostic",
		"bridge_sketch_cruise", "bridge_gallery_cruise", "bridge_mast_cruise", "bridge_sketch_rest"]
	var w := 480
	var h := 270
	var g := 16
	var cols := 4
	var img := Image.create(cols * (w + g) + g, 3 * (h + g) + g, false, Image.FORMAT_RGB8)
	img.fill(Color(0.06, 0.06, 0.08))
	for i in names.size():
		var path := ProjectSettings.globalize_path("%s/%s.png" % [out, names[i]])
		if not FileAccess.file_exists(path):
			continue
		var f := Image.load_from_file(path)
		f.convert(Image.FORMAT_RGB8)
		f.resize(w, h, Image.INTERPOLATE_LANCZOS)
		img.blit_rect(f, Rect2i(0, 0, w, h), Vector2i(g + (i % cols) * (w + g), g + (i / cols) * (h + g)))
	img.save_png("%s/contact_sheet.png" % out)
