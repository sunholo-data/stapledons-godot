class_name LevelMetrics
extends RefCounted
## R2-LEVELS S2 (design_docs/planned/r2/levels.md §B3, §B5, AC5; ledger D-103): the level evaluator's
## measurements, generalised from the bridge's DeckBowMetrics to any level's stages and surfaces.
## Headless: rays against the demo's colliders plus any greybox pieces, through the stage views'
## poses, over each surface's samples.
##
## Poses (§B3): a walk view puts the eye `back_m` behind the captain along its fixed yaw and `rise_m`
## above the captain's own floor, so the slide follows the floor height and never turns. Under an
## overhang (a collider within `probe_m` above the captain's head) the CEILING CLAMP takes over: a
## lower, closer pose with the same yaw. An `enclosed` view (crawlspaces) never clamps. pose() is the
## rule the game camera adopts in LP1b; the camera's test checks it against this one.
##
## Two readings of each ray are kept:
##   first-hit   the first collider on the ray (greybox pieces are "GB_<role>_<name>"): head_gb counts
##               greybox hits only, which is the R2-LEVELS mock's reading (its positive control)
##   after fades the gate: CameraDirector.clear_after_fades (the occluder fade list applies)
## Surface samplers: {"grid": [x0, x1, y0, y1], "step": m} (ship frame; a rectangle at z_m, for decks
## whose walk is not authored yet), {"walk": "bridge"} (the shipped bridge walk), or by default the
## greybox walk over the stage bounds at `grid_m`.

const CLAMP := LevelCamera.CLAMP
const HEAD_M := 1.6
const CAPTAIN_M := 1.754
const BODY_OFF_DEG := 30.0
const PX := Vector2(1280, 720)
const DEFAULTS := {
	"grid_m": 0.5, "head_share_max": 0.02, "pole_share_max": 0.02, "band_tol_deg": 0.5, "near_bow_max": 0.05,
	"near_astern_max": 0.10, "body_both_share_max": 0.02, "find_hops_max": 4, "find_route_m_max": 80.0, "heights_min": 2,
}

var demo: Node
var level: Dictionary
var walk: WalkArea
var cam: Camera3D


func _init(owner_demo: Node, level_doc: Dictionary, greybox_walk: WalkArea = null) -> void:
	demo = owner_demo
	level = level_doc
	walk = greybox_walk


static func pose(v: Dictionary, captain: Vector3, clamp := false) -> Transform3D:
	return LevelCamera.pose(v, captain, clamp)


func hit(a: Vector3, b: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(a, b)
	q.hit_back_faces = true
	return demo.camera.get_world_3d().direct_space_state.intersect_ray(q)


static func gltf(s: Array) -> Vector3:
	return ShipFrame.gltf_from_structure(s)


func view_of(stage: Dictionary, id: String) -> Dictionary:
	for v: Dictionary in stage.views:
		if v.id == id:
			return v
	return {}


## Captain positions (glTF) on one surface.
func samples(stage: Dictionary, surf: Dictionary, grid_m: float) -> Array:
	var out := []
	var z := float(surf.z_m)
	if surf.has("grid"):
		var g: Array = surf.grid
		var st := float(surf.get("step", grid_m))
		var x := float(g[0])
		while x <= float(g[1]) + 1e-6:
			var y := float(g[2])
			while y <= float(g[3]) + 1e-6:
				out.append(gltf([x, y, z]))
				y += st
			x += st
		return out
	var w: WalkArea = demo.walk_bridge if str(surf.get("walk", "")) == "bridge" else walk
	if w == null:
		return out
	var b: Array = surf.get("bounds_ship_m",stage.bounds_ship_m)
	var xx := float(b[0])
	while xx <= float(b[1]) + 1e-6:
		var yy := float(b[2])
		while yy <= float(b[3]) + 1e-6:
			var p := gltf([xx, yy, z])
			var h := w.height_at_near(p.x, p.z, z)
			if not is_nan(h) and w.is_walkable_near(Vector3(p.x, h, p.z)):
				out.append(Vector3(p.x, h, p.z))
			yy += grid_m
		xx += grid_m
	return out


func _probe_cam() -> Camera3D:
	if cam == null:
		cam = Camera3D.new()
		cam.fov = demo.camera.fov
		cam.current = false
		demo.camera.get_parent().add_child(cam)
	return cam


func captain_px(t: Transform3D, c: Vector3) -> float:
	var k := _probe_cam()
	k.global_transform = t
	return absf(k.unproject_position(c).y - k.unproject_position(c + Vector3(0, CAPTAIN_M, 0)).y)


static func is_gb(h: Dictionary) -> bool:
	return not h.is_empty() and String(h.collider.name).begins_with("GB_")


## One surface through one view: head (after fades, and greybox first-hit), pole, clamp, body, px.
func surface_metrics(stage: Dictionary, surf: Dictionary, grid_m: float) -> Dictionary:
	var vid := str(surf.get("view", stage.default_view))
	var v := view_of(stage, vid)
	var enclosed := str(v.get("kind", "walk")) == "enclosed"
	var probe := float((v.get("ceiling_clamp", CLAMP) as Dictionary).get("probe_m", 8.0))
	var dir: CameraDirector = demo.director
	var pts := samples(stage, surf, grid_m)
	var r := {"surface": surf.id, "view": vid, "samples": pts.size(), "head": 0, "head_gb": 0, "under": 0,
		"head_gb_clamped": 0, "pole": 0, "pole_first_hit": 0, "body_both": 0, "px": [1e9, 0.0], "by": {}}
	for c: Vector3 in pts:
		var t := pose(v, c)
		var head := c + Vector3(0, HEAD_M, 0)
		var h := hit(t.origin, head + (t.origin - head).normalized() * 0.4)
		if is_gb(h):
			r.head_gb += 1
		var up := hit(head, head + Vector3(0, probe, 0))
		var tg := pose(v, c, true) if not enclosed and not up.is_empty() else t
		if not up.is_empty() and not enclosed:
			r.under += 1
		if not enclosed and is_gb(up):
			var tc := pose(v, c, true)
			if is_gb(hit(tc.origin, head + (tc.origin - head).normalized() * 0.4)):
				r.head_gb_clamped += 1
		elif is_gb(h):
			r.head_gb_clamped += 1
		var clear: Dictionary = dir.clear_after_fades(t, c) if tg == t else dir.clear_after_fades(tg, c)
		if not clear.captain:
			r.head += 1
			var hb := hit(tg.origin, head + (tg.origin - head).normalized() * 0.25)
			var nm := String(hb.collider.name) if not hb.is_empty() else "?"
			r.by[nm] = int(r.by.get(nm, 0)) + 1
		var p := hit(t.origin, t.origin + Vector3(0, 0, -400))
		if not p.is_empty():
			r.pole_first_hit += 1
		if not clear.pole_ray:
			r.pole += 1
			var pb := hit(tg.origin, tg.origin + ShipCamera.BOW * 120.0)
			var pn := "pole:" + (String(pb.collider.name) if not pb.is_empty() else "?")
			r.by[pn] = int(r.by.get(pn, 0)) + 1
		var nb := 0
		for sgn: float in [-1.0, 1.0]:
			var bd := ShipCamera.BOW.rotated(Vector3.UP, -sgn * deg_to_rad(BODY_OFF_DEG))
			if not hit(tg.origin, tg.origin + bd * 120.0).is_empty():
				nb += 1
		if nb == 2:
			r.body_both += 1
		var px := captain_px(tg, c)
		r.px[0] = minf(r.px[0], px)
		r.px[1] = maxf(r.px[1], px)
	r.px = [snappedf(r.px[0], 0.1), snappedf(r.px[1], 0.1)] if pts.size() > 0 else [0.0, 0.0]
	r["captain_px_band"] = v.get("captain_px", [45, 82])
	return r


## The roof edge's elevation seen from a pose, along the bow: the first elevation (0.05 deg steps)
## whose ray meets geometry above the eye, against the slab model atan((roof_z - eye_z) / D).
func band_top(t: Transform3D) -> Dictionary:
	var roof: Dictionary = level.get("roof", {})
	if not roof.get("z_m") is float and not roof.get("z_m") is int:
		return {}
	var eye := t.origin
	var measured := NAN
	var e := 0.0
	while e <= 80.0:
		var d := Vector3(0.0, sin(deg_to_rad(e)), -cos(deg_to_rad(e)))
		var h := hit(eye, eye + d * 400.0)
		if not h.is_empty() and float(h.position.y) > eye.y + 0.01:
			measured = e
			break
		e += 0.05
	var s := ShipFrame.structure_from_gltf(eye)
	var r := float(roof.radius_m)
	var model := NAN
	if absf(float(s[0])) < r:
		var dist := sqrt(r * r - float(s[0]) * float(s[0])) - float(s[1])
		if dist > 0.0:
			model = rad_to_deg(atan((float(roof.z_m) - eye.y) / dist))
	return {"measured_deg": snappedf(measured, 0.05), "model_deg": snappedf(model, 0.01)}


## Share of a 32 x 18 grid of frame rays that meet geometry nearer than the captain (less 0.5 m),
## floors excluded (an upward-facing hit is ground the captain walks on, as DeckBowMetrics.near
## excludes the deck).
func near_field(t: Transform3D, c: Vector3) -> float:
	var k := _probe_cam()
	k.global_transform = t
	var dc := t.origin.distance_to(c + Vector3(0, 0.9, 0)) - 0.5
	var near := 0
	var n := 0
	for i in 32:
		for j in 18:
			var sp := Vector2((i + 0.5) / 32.0 * PX.x, (j + 0.5) / 18.0 * PX.y)
			var dirv := k.project_ray_normal(sp)
			var h := hit(t.origin, t.origin + dirv * dc)
			n += 1
			if not h.is_empty() and (h.normal as Vector3).y < 0.7:
				near += 1
	return float(near) / n


## Surfaces joined by routes and stage exits; hops and metres from the spawn to each surface and find.
func graph() -> Dictionary:
	var pos := {}
	var stage_first := {}
	for s: Dictionary in level.stages:
		for f: Dictionary in s.surfaces:
			var key := "%s/%s" % [s.id, f.id]
			pos[key] = gltf(f.get("at", [float(s.spawn[0]), float(s.spawn[1]), float(f.z_m)]))
			if not stage_first.has(s.id):
				stage_first[s.id] = key
	var edges := []
	for rt: Dictionary in level.get("routes", []):
		var a := str(rt.from)
		var b := str(rt.to)
		if a == "lift" or b == "lift":
			continue
		var extra := 0.0
		if rt.has("from_at") and rt.has("to_at"):
			extra = gltf(rt.from_at).distance_to(gltf(rt.to_at))
		edges.append([a, b, extra])
	for s: Dictionary in level.stages:
		for x: Dictionary in s.get("exits", []):
			if stage_first.has(str(x.to)):
				edges.append([stage_first[s.id], stage_first[str(x.to)], 0.0])
	var start: String = stage_first[str(level.stages[0].id)]
	var dist := {start: 0.0}
	var hops := {start: 0}
	var frontier := [start]
	while not frontier.is_empty():
		var u: String = frontier.pop_front()
		for e: Array in edges:
			var w: String = e[1] if e[0] == u else (e[0] if e[1] == u else "")
			if w == "" or dist.has(w) or not pos.has(w):
				continue
			dist[w] = dist[u] + (pos[u] as Vector3).distance_to(pos[w]) + float(e[2])
			hops[w] = hops[u] + 1
			frontier.append(w)
	var unreached := []
	var heights := []
	for k: String in pos:
		if not dist.has(k):
			unreached.append(k)
		var hz := snappedf((pos[k] as Vector3).y, 1.0)
		if not heights.has(hz):
			heights.append(hz)
	heights.sort()
	var finds := {}
	for f: Dictionary in level.get("finds", []):
		var key: String = ("%s/%s" % [f.stage, f.get("surface", "")]) if f.has("surface") else str(stage_first.get(str(f.stage), ""))
		finds[f.id] = {"on": key, "reachable": dist.has(key), "hops": hops.get(key, -1), "route_m": snappedf(dist.get(key, -1.0), 0.1)}
	return {"surfaces": pos.size(), "heights": heights, "unreached": unreached, "hops": hops, "finds": finds, "start": start}


## Each find from its stage's default view at the stage spawn: in frame and nothing else in the way.
func find_sight() -> Dictionary:
	var out := {}
	var k := _probe_cam()
	for f: Dictionary in level.get("finds", []):
		var st: Dictionary = {}
		for s: Dictionary in level.stages:
			if s.id == f.stage:
				st = s
		var t := pose(view_of(st, str(st.default_view)), gltf(st.spawn))
		k.global_transform = t
		var p := gltf(f.at)
		var sp := k.unproject_position(p)
		var inside := not k.is_position_behind(p) and sp.x >= 0 and sp.x <= PX.x and sp.y >= 0 and sp.y <= PX.y
		var h := hit(t.origin, p)
		var unblocked: bool = h.is_empty() or String(h.collider.name) == "GB_find_" + str(f.id) or (h.position as Vector3).distance_to(p) < 0.8
		out[f.id] = {"in_frame": inside, "unblocked": unblocked, "cue": str(f.get("cue", "")), "seen": inside and unblocked}
	return out


func measure(grid_override := 0.0) -> Dictionary:
	var grid := grid_override if grid_override > 0.0 else float(level.get("grid_m", DEFAULTS.grid_m))
	var stages := {}
	for s: Dictionary in level.stages:
		var surfs := []
		for f: Dictionary in s.surfaces:
			surfs.append(surface_metrics(s, f, grid))
			if level.get("evaluate_all_views",false):
				for v: Dictionary in s.views:
					if str(v.id)==str(f.get("view",s.default_view)):continue
					var other:=f.duplicate(true);other.view=v.id
					var row:=surface_metrics(s,other,grid);row.surface=str(f.id)+"@"+str(v.id)
					surfs.append(row)
		var dv := view_of(s, str(s.default_view))
		var sp := gltf(s.spawn)
		var t := pose(dv, sp)
		var st := {"surfaces": surfs, "intricate": bool(s.get("intricate", false)), "journey": bool(s.get("journey", false))}
		if str(dv.get("kind", "walk")) == "walk":
			st["near_bow"] = snappedf(near_field(t, sp), 0.001)
			var va := view_of(s, "astern")
			if not va.is_empty():
				st["near_astern"] = snappedf(near_field(pose(va, sp), sp), 0.001)
			var bt := band_top(t)
			if not bt.is_empty():
				st["band_top"] = bt
		var hs := []
		for f: Dictionary in s.surfaces:
			var hz := snappedf(float(f.z_m), 1.0)
			if not hs.has(hz):
				hs.append(hz)
		st["heights"] = hs.size()
		stages[s.id] = st
	return {"level": level.id, "version": level.get("version", 1), "grid_m": grid, "stages": stages, "routes": graph(), "finds": find_sight()}


## The §B5 failures as {id, detail}, against thresholds (DEFAULTS overridden per level).
static func failures(m: Dictionary, th: Dictionary) -> Array:
	var t := DEFAULTS.duplicate()
	t.merge(th, true)
	var out := []
	if not (m.routes.unreached as Array).is_empty():
		out.append({"id": "unreached", "detail": "surfaces not reachable from %s: %s" % [m.routes.start, m.routes.unreached]})
	for sid: String in m.stages:
		var st: Dictionary = m.stages[sid]
		if st.intricate and int(st.heights) < int(t.heights_min):
			out.append({"id": "heights", "detail": "%s: %d walkable heights (want >= %d)" % [sid, st.heights, t.heights_min]})
		for r: Dictionary in st.surfaces:
			if int(r.samples) == 0:
				out.append({"id": "samples", "detail": "%s/%s: no samples" % [sid, r.surface]})
				continue
			var hs := float(r.head) / float(r.samples)
			if hs > float(t.head_share_max):
				out.append({"id": "head", "detail": "%s/%s: captain's head hidden at %d of %d samples (%.1f%%, max %.1f%%) %s" % [sid, r.surface, r.head, r.samples, 100.0 * hs, 100.0 * float(t.head_share_max), r.by]})
			if st.journey:
				var ps := float(r.pole) / float(r.samples)
				if ps > float(t.pole_share_max):
					out.append({"id": "pole-ray", "detail": "%s/%s: forward pole hidden at %d of %d samples (%.1f%%)" % [sid, r.surface, r.pole, r.samples, 100.0 * ps]})
			var band: Array = r.captain_px_band
			if float(r.px[0]) < float(band[0]) - 0.5 or float(r.px[1]) > float(band[1]) + 0.5:
				out.append({"id": "captain-px", "detail": "%s/%s: captain %s px, band %s" % [sid, r.surface, r.px, band]})
			if st.journey and float(r.body_both) / float(r.samples) > float(t.body_both_share_max):
				out.append({"id": "body-both", "detail": "%s/%s: stop body hidden on both sides at %d of %d" % [sid, r.surface, r.body_both, r.samples]})
		if st.has("near_bow") and float(st.near_bow) > float(t.near_bow_max):
			out.append({"id": "near-field", "detail": "%s: Bow near-field %.3f (max %.2f)" % [sid, st.near_bow, t.near_bow_max]})
		if st.has("near_astern") and float(st.near_astern) > float(t.near_astern_max):
			out.append({"id": "near-field", "detail": "%s: Astern near-field %.3f (max %.2f)" % [sid, st.near_astern, t.near_astern_max]})
		if st.has("band_top"):
			var b: Dictionary = st.band_top
			if is_nan(float(b.measured_deg)) != is_nan(float(b.model_deg)) or (not is_nan(float(b.model_deg)) and absf(float(b.measured_deg) - float(b.model_deg)) > float(t.band_tol_deg)):
				out.append({"id": "band-top", "detail": "%s: roof edge %s deg measured vs %s deg slab model (tol %.1f)" % [sid, b.measured_deg, b.model_deg, t.band_tol_deg]})
	for fid: String in m.finds:
		var f: Dictionary = m.finds[fid]
		if not f.seen and str(f.cue).is_empty():
			out.append({"id": "find-sight", "detail": "%s: not in sight from its stage's first view (in frame %s, unblocked %s) and no cue" % [fid, f.in_frame, f.unblocked]})
	for fid: String in m.routes.finds:
		var fr: Dictionary = m.routes.finds[fid]
		if not fr.reachable or int(fr.hops) > int(t.find_hops_max) or float(fr.route_m) > float(t.find_route_m_max):
			out.append({"id": "find-route", "detail": "%s: hops %d, %.1f m (max %d, %.0f m)" % [fid, fr.hops, fr.route_m, t.find_hops_max, t.find_route_m_max]})
	return out
