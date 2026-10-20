class_name DeckBowMetrics
extends RefCounted
## R2-DECK-LAYOUT §D4 (design_docs/planned/r2/deck-layout.md, ledger D-95): the bow evaluator's
## measurements, shared by tools/deck_layout_eval.gd (the gate), tests/test_deck_layout_eval.gd and
## tools/deck_bow_probe.gd (the plan's evidence and review captures). Headless: rays against the
## demo's colliders (the lift's boxes as AABBs), through the real Bow and Astern walk poses
## (CameraDirector.walk_pose, occluders_for, clear_after_fades), over every bridge walk sample.
##
## With a layout applied in-engine (DeckLayout.apply, search only) the stations' use points are
## the layout's use_m, else ShipConsoles' closest-walkable rule on the moved mesh; on a shipped
## export (no layout) they are the game's own (demo.consoles), and the console zoom is the game's
## focus_pose. Failure names are the §D4 IDs.

const PX := Vector2(1280, 720)
const FAMILIES := ["spire", "lift", "shrine", "archive_terminal", "frond"]
const BODY_OFF_DEG := 30.0
const CAPTAIN_M := 1.754 # the captain sprite's real height (F1, D-94)
const ZOOM_STATIONS := ["navigation", "voyage", "crew"]

var demo: Node
var dl: DeckLayout


func _init(owner_demo: Node, layout: DeckLayout) -> void:
	demo = owner_demo
	dl = layout


static func family(demo_node: Node, n: Node) -> String:
	var s := String(n.name).to_lower()
	var p := n.get_parent()
	while p != null and p != demo_node:
		if p == demo_node.lift:
			return "lift"
		p = p.get_parent()
	for f: String in FAMILIES:
		if s.contains(f):
			return f
	return s


func view(id: String) -> Dictionary:
	for v: Dictionary in demo.director.data.levels.bridge.views:
		if v.id == id:
			return v
	return {}


## A station's use point (glTF): see the header.
func use_point(sid: String) -> Variant:
	var mesh_name: String = ShipConsoles.STATIONS[sid].walk
	var n := demo.geometry.find_child(mesh_name, true, false) as MeshInstance3D
	if n == null or not n.visible:
		return null
	if shipped() and demo.consoles != null and demo.consoles.stations.has(sid):
		return demo.consoles.stations[sid].use
	var spec: Variant = dl.layout.get("bridge", {}).get("props", {}).get(mesh_name, {}).get("use_m")
	if spec is Array:
		return demo.walk_bridge.closest_walkable(Vector3(float(spec[0]), 82.0, -float(spec[1])), 1.5)
	var o: Vector3 = n.global_transform.origin
	var use: Vector3 = demo.walk_bridge.closest_walkable(Vector3(o.x, 82.0, o.z), ShipConsoles.REACH_M)
	var d := Vector3(use.x - o.x, 0.0, use.z - o.z)
	if d.length() > 1e-3:
		var back: Vector3 = demo.walk_bridge.closest_walkable(use + d.normalized() * 0.9, 0.4)
		if demo.walk_bridge.is_walkable(back):
			use = back
	return use


## True when no prop is moved in-engine: the deck is measured as the GLB ships it.
func shipped() -> bool:
	return (dl.layout.get("bridge", {}).get("props", {}) as Dictionary).is_empty()


func hit(a: Vector3, b: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b)
	q.hit_back_faces = true
	return demo.camera.get_world_3d().direct_space_state.intersect_ray(q)


## Is a stop body 30 deg off the bow (port, starboard) clear of ship geometry from this pose?
func body_clear(pose: Transform3D) -> Array:
	var out := []
	for sgn: float in [-1.0, 1.0]:
		var bd := ShipCamera.BOW.rotated(Vector3.UP, -sgn * deg_to_rad(BODY_OFF_DEG))
		out.append(hit(pose.origin, pose.origin + bd * 120.0).is_empty())
	return out


func metrics() -> Dictionary:
	var dir: CameraDirector = demo.director
	var pts := dl.samples("bridge")
	var m := {"samples": pts.size()}
	for vid: String in ["bow", "astern"]:
		var v := view(vid)
		var fade := 0
		var fam := {}
		var blocked := {"pole_ray": 0, "captain": 0, "eye_free": 0}
		var body := {"port": 0, "starboard": 0}
		var body_by := {}
		var body_both := 0
		var cap_by := {}
		var frond_by := {}
		for p: Vector3 in pts:
			var pose := dir.walk_pose(v, p)
			var occ: Array = dir.occluders_for(pose, p)
			if not occ.is_empty():
				fade += 1
				var seen := {}
				for n: Node in occ:
					seen[family(demo, n)] = true
					if family(demo, n) == "frond":
						frond_by[str(n.name)] = int(frond_by.get(str(n.name), 0)) + 1
				for k: String in seen:
					fam[k] = int(fam.get(k, 0)) + 1
			var c: Dictionary = dir.clear_after_fades(pose, p)
			for k: String in blocked:
				if vid == "astern" and k == "pole_ray":
					continue
				if not c[k]:
					blocked[k] += 1
			if not c.captain:
				var hd := p + Vector3.UP * 1.6
				var ch := hit(pose.origin, hd + (pose.origin - hd).normalized() * 0.25)
				var cn := DeckLayout.collider_name(ch) if not ch.is_empty() else "?"
				cap_by[cn] = int(cap_by.get(cn, 0)) + 1
			if vid == "bow":
				var nb := 0
				for side: String in body:
					var s := -1.0 if side == "port" else 1.0
					var bd := ShipCamera.BOW.rotated(Vector3.UP, -s * deg_to_rad(BODY_OFF_DEG))
					var bh := hit(pose.origin, pose.origin + bd * 120.0)
					if not bh.is_empty():
						body[side] += 1
						nb += 1
						var bn := DeckLayout.collider_name(bh)
						body_by[bn] = int(body_by.get(bn, 0)) + 1
				if nb == 2:
					body_both += 1
		m[vid] = {"fade": fade, "families": fam, "blocked": blocked, "frond_by": frond_by, "captain_by": cap_by}
		if vid == "bow":
			m[vid]["body_blocked"] = body
			m[vid]["body_by"] = body_by
			m[vid]["body_both"] = body_both
	# The spawn: open walk straight ahead, the first thing hit, near field in both views, the head.
	var sp := dl.spawn()
	var run := 0.0
	while run < 25.0 and demo.walk_bridge.is_walkable(sp + ShipCamera.BOW * (run + 0.25)):
		run += 0.25
	var h := hit(sp + Vector3.UP * 1.0, sp + Vector3.UP * 1.0 + ShipCamera.BOW * 25.0)
	var bow_sp := dir.walk_pose(view("bow"), sp)
	var ast_sp := dir.walk_pose(view("astern"), sp)
	m["spawn"] = {"at_gltf": [sp.x, sp.z], "open_ahead_m": run,
		"first_hit": (DeckLayout.collider_name(h) if not h.is_empty() else "none"),
		"first_hit_m": ((h.position - (sp + Vector3.UP)).length() if not h.is_empty() else -1.0),
		"near_bow": near(bow_sp, sp), "near_astern": near(ast_sp, sp),
		"head_clear_bow": dir.clear_after_fades(bow_sp, sp).captain, "head_clear_astern": dir.clear_after_fades(ast_sp, sp).captain,
		"captain_px": snappedf(CameraDirector.figure_px(bow_sp, sp, CAPTAIN_M, PX.y), 0.1),
		"body_clear_port_stbd": body_clear(bow_sp)}
	var st := {}
	for id: String in ShipConsoles.STATIONS:
		var spec: Dictionary = ShipConsoles.STATIONS[id]
		if not spec.active:
			continue
		var u: Variant = use_point(id)
		if not u is Vector3:
			continue
		var pose := dir.walk_pose(view("bow"), u)
		var n := demo.geometry.find_child(spec.walk, true, false) as MeshInstance3D
		var box: AABB = n.global_transform * n.mesh.get_aabb()
		var sc := CameraDirector.screen_point(pose, box.get_center(), PX)
		var c: Dictionary = dir.clear_after_fades(pose, u)
		st[id] = {"body_clear_port_stbd": body_clear(pose), "use_gltf": [snappedf(u.x, 0.01), snappedf(u.z, 0.01)], "station_px": [snappedf(sc.x, 1), snappedf(sc.y, 1)],
			"in_frame": (not is_nan(sc.x)) and Rect2(Vector2.ZERO, PX).has_point(sc),
			"faces_bow": box.get_center().z < u.z, "clear": c.captain and c.pole_ray and c.eye_free,
			"fades": dir.occluders_for(pose, u).map(func(x: Node) -> String: return family(demo, x))}
		if id in ZOOM_STATIONS:
			var zp := zoom_pose(id, u, box)
			var pole := CameraDirector.screen_point(zp, zp.origin + CameraDirector.pole_dir() * 1000.0, PX)
			st[id]["zoom_pole_px"] = [snappedf(pole.x, 1), snappedf(pole.y, 1)]
			st[id]["zoom_pole_in_frame"] = (not is_nan(pole.x)) and Rect2(Vector2.ZERO, PX).has_point(pole)
	m["stations"] = st
	return m


## The console zoom: the game's focus_pose on a shipped export; with an in-engine layout, the same
## rule (the eye 1.25 m out on the operator's side, 0.55 m above the console top) from the moved
## mesh and its use point.
func zoom_pose(sid: String, use: Vector3, box: AABB) -> Transform3D:
	if shipped() and demo.consoles != null:
		return demo.consoles.focus_pose(ShipConsoles.STATIONS[sid].walk)
	var c := box.get_center()
	var top := Vector3(c.x, box.end.y, c.z)
	var o := Vector3(use.x - c.x, 0.0, use.z - c.z).normalized()
	var eye := top + o * 1.25 + Vector3.UP * 0.55
	return Transform3D(Basis.looking_at(top - eye + Vector3.UP * -0.1, Vector3.UP), eye)


## Share of a 64x36 grid of frame rays that hit geometry nearer than the captain (deck and floor
## excluded), by node (>= 1 % of the frame), and the lift's own share.
func near(pose: Transform3D, foot: Vector3) -> Dictionary:
	var d := pose.origin.distance_to(foot + Vector3.UP * 0.9) - 0.5
	var fam := {}
	var total := 0
	var lift_n := 0
	var lift: Array = demo.director.lift_boxes() # the lift's boxes have no colliders
	for j in 36:
		for i in 64:
			var r := DeckLayout.frame_dir(pose, (i + 0.5) / 64.0, (j + 0.5) / 36.0)
			var in_lift := false
			for b: AABB in lift:
				if b.intersects_segment(pose.origin, pose.origin + r * d):
					in_lift = true
			if in_lift:
				total += 1
				lift_n += 1
				continue
			var hh := hit(pose.origin, pose.origin + r * d)
			if hh.is_empty():
				continue
			var name := DeckLayout.collider_name(hh)
			if name.to_lower().contains("deck") or name.to_lower().contains("floor"):
				continue
			total += 1
			fam[name] = int(fam.get(name, 0)) + 1
	var top := {}
	for k: String in fam:
		if fam[k] >= 23: # 1 % of the frame
			top[k] = snappedf(fam[k] / 2304.0, 0.001)
	return {"share": snappedf(total / 2304.0, 0.001), "lift": snappedf(lift_n / 2304.0, 0.001), "by_node": top}


## The §D4 thresholds a report fails (empty when it passes), each line led by its metric ID.
static func failures(m: Dictionary, t: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var bow: Dictionary = m.bow
	var ast: Dictionary = m.astern
	var sp: Dictionary = m.spawn
	var st: Dictionary = m.stations
	var station_meshes := []
	for id: String in ShipConsoles.STATIONS:
		station_meshes.append_array(ShipConsoles.STATIONS[id].meshes)
	if int(bow.blocked.pole_ray) > int(t.pole_ray_max):
		out.append("pole-ray: the Bow pole ray is blocked after fades at %d samples (max %d)" % [bow.blocked.pole_ray, t.pole_ray_max])
	var head_st := st.keys().filter(func(k: String) -> bool: return not st[k].clear)
	if int(bow.blocked.captain) > int(t.head_bow_max) or not sp.head_clear_bow or not head_st.is_empty():
		out.append("head-bow: the captain's head is blocked after fades at %d Bow samples (max %d); spawn clear %s; stations not clear %s" % [bow.blocked.captain, t.head_bow_max, sp.head_clear_bow, head_st])
	if int(ast.blocked.captain) > int(t.head_astern_max) or not sp.head_clear_astern:
		out.append("head-astern: the captain's head is blocked after fades at %d Astern samples (max %d); spawn clear %s" % [ast.blocked.captain, t.head_astern_max, sp.head_clear_astern])
	if int(bow.fade) > int(t.fade_max):
		out.append("fade-count: %d Bow samples need a fade (max %d)" % [bow.fade, t.fade_max])
	if int(bow.body_both) > int(t.body_both_max):
		out.append("body-both: the stop body is blocked on both sides at %d samples (max %d)" % [bow.body_both, t.body_both_max])
	var body_ok := 1 if not (sp.body_clear_port_stbd as Array).has(false) else 0
	for id: String in st:
		if not (st[id].body_clear_port_stbd as Array).has(false):
			body_ok += 1
	if body_ok < 1 + st.size() or st.size() < int(t.active_stations):
		out.append("station-body: the stop body is clear on both sides at %d of %d (the spawn and %d stations)" % [body_ok, 1 + int(t.active_stations), st.size()])
	if float(sp.open_ahead_m) < float(t.spawn_open_min_m) or not str(sp.first_hit) in station_meshes:
		out.append("spawn-open: %.2f m open ahead of the spawn (min %.1f), then %s (must be a station)" % [sp.open_ahead_m, t.spawn_open_min_m, sp.first_hit])
	if float(sp.near_bow.share) > float(t.near_bow_max) or float(sp.near_astern.share) > float(t.near_astern_max) or float(sp.near_astern.lift) > 0.0:
		out.append("near-field: spawn near field Bow %.3f (max %.2f), Astern %.3f (max %.2f), lift in Astern %.3f (must be 0)" % [sp.near_bow.share, t.near_bow_max, sp.near_astern.share, t.near_astern_max, sp.near_astern.lift])
	var faces := st.keys().filter(func(k: String) -> bool: return st[k].faces_bow)
	if faces.size() < int(t.active_stations):
		out.append("faces-bow: %d of %d active stations face the bow (%s)" % [faces.size(), t.active_stations, faces])
	var clear := st.keys().filter(func(k: String) -> bool: return st[k].clear and st[k].in_frame and (st[k].fades as Array).is_empty())
	if clear.size() < int(t.active_stations):
		out.append("station-clear: %d of %d active stations clear in the Bow view with no fades at the use point (%s)" % [clear.size(), t.active_stations, clear])
	var zoom := st.keys().filter(func(k: String) -> bool: return st[k].get("zoom_pole_in_frame", false))
	if zoom.size() < ZOOM_STATIONS.size():
		out.append("zoom-pole: the forward pole is in frame in %d of %d console zooms (%s)" % [zoom.size(), ZOOM_STATIONS.size(), zoom])
	var cpx := float(sp.captain_px)
	if cpx < float(t.captain_px[0]) or cpx > float(t.captain_px[1]):
		out.append("captain-px: the captain is %.1f px tall in the Bow view at 720p (band %s)" % [cpx, t.captain_px])
	return out


## One line per §D4 metric (the gate's log and the report).
static func summary(m: Dictionary) -> PackedStringArray:
	var st: Dictionary = m.stations
	var out := PackedStringArray()
	out.append("samples %d" % m.samples)
	out.append("bow: fade %d %s blocked %s body %s both %d" % [m.bow.fade, m.bow.families, m.bow.blocked, m.bow.body_blocked, m.bow.body_both])
	out.append("astern: fade %d blocked %s" % [m.astern.fade, m.astern.blocked])
	out.append("spawn %s open %.2f m then %s; near Bow %.3f Astern %.3f (lift %.3f); captain %.1f px; body %s" % [m.spawn.at_gltf, m.spawn.open_ahead_m, m.spawn.first_hit, m.spawn.near_bow.share, m.spawn.near_astern.share, m.spawn.near_astern.lift, m.spawn.captain_px, m.spawn.body_clear_port_stbd])
	for id: String in st:
		out.append("station %s use %s faces_bow %s clear %s fades %s body %s zoom_pole %s" % [id, st[id].use_gltf, st[id].faces_bow, st[id].clear, st[id].fades, st[id].body_clear_port_stbd, st[id].get("zoom_pole_in_frame", "-")])
	return out
