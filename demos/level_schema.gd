class_name LevelSchema
extends RefCounted
## R2-LEVELS §A4 (design_docs/planned/r2/levels.md, ledger D-103): the level manifest and layout
## schema, stapledons.level/1. One document describes a level: its stages (bounded walkable areas
## with surfaces at several heights), each stage's fixed views (they slide, never turn: no yaw rule),
## routes between surfaces and stages, finds, set pieces, lights, layers (layers.foliage[] is the plants
## cards, D-106), the lift stop and crew anchors. A layout (art/levels/<id>/layout.json) is the same
## document with greybox `pieces`; the manifest a build writes drops nothing but adds layout_sha256.
## Coordinates are the ship (structure) frame: x, y = the bow, z = up; metres.
## validate() returns human-readable errors; empty means valid.

const SCHEMA := "stapledons.level/1"
const VIEW_KINDS := ["walk", "enclosed"]
const ROUTE_KINDS := ["stairs", "ramp", "ladder", "hatch", "exit", "gantry", "lift"]
const WHEN := ["stop", "eclipse", "arrival", "cruise", "rest"]
const PIECE_ROLES := ["surface", "structure", "route", "find", "fore", "back", "roof"]
const PIECE_SHAPES := ["box", "arc", "ramp"]
## D-106: everything that grows is a painted foliage card from the foliage library; layer is the
## parallax layer it stands in.
const FOLIAGE_LAYERS := ["fore", "stage", "far"]
const PX_MIN := 30.0
const PX_MAX := 90.0


static func validate(m: Variant) -> Array[String]:
	var e: Array[String] = []
	if not m is Dictionary:
		e.append("manifest is not an object")
		return e
	var d: Dictionary = m
	if str(d.get("schema", "")) != SCHEMA:
		e.append("schema is %s, want %s" % [d.get("schema", "missing"), SCHEMA])
	if not d.get("id") is String or str(d.id).is_empty():
		e.append("id missing")
	if not (d.get("version") is float or d.get("version") is int) or int(d.version) < 1:
		e.append("version must be a positive number")
	if not _num(d.get("deck_z_m")):
		e.append("deck_z_m missing")
	var camera: Variant=d.get("camera",{})
	if not camera is Dictionary:
		e.append("camera must be an object")
	else:
		if camera.has("occluders") and (not camera.occluders is Array or not camera.occluders.all(func(x: Variant)->bool:return x is String and not x.is_empty())):
			e.append("camera.occluders must be non-empty node names")
		if camera.has("dressing") and not camera.dressing is Dictionary:e.append("camera.dressing must be an object")
	var stages: Variant = d.get("stages")
	var ids := {}
	var surfaces := {}
	if not stages is Array or (stages as Array).is_empty():
		e.append("stages must be a non-empty list")
		stages = []
	for s: Variant in stages:
		if not s is Dictionary or not s.get("id") is String:
			e.append("a stage without an id")
			continue
		var sid: String = s.id
		if ids.has(sid):
			e.append("stage %s listed twice" % sid)
		ids[sid] = true
		var b: Variant = s.get("bounds_ship_m")
		if not b is Array or (b as Array).size() != 4 or not (float(b[0]) < float(b[1]) and float(b[2]) < float(b[3])):
			e.append("stage %s: bounds_ship_m must be [x0, x1, y0, y1] with x0 < x1, y0 < y1" % sid)
		var surf: Variant = s.get("surfaces")
		if not surf is Array or (surf as Array).is_empty():
			e.append("stage %s: surfaces must be a non-empty list" % sid)
		else:
			for f: Variant in surf:
				if not f is Dictionary or not f.get("id") is String or not _num(f.get("z_m")):
					e.append("stage %s: a surface needs an id and z_m" % sid)
				else:
					surfaces["%s/%s" % [sid, f.id]] = true
		if not _vec(s.get("spawn"), 3):
			e.append("stage %s: spawn must be [x, y, z]" % sid)
		var views: Variant = s.get("views")
		var vids := {}
		if not views is Array or (views as Array).is_empty():
			e.append("stage %s: views must be a non-empty list" % sid)
			views = []
		for v: Variant in views:
			if not v is Dictionary or not v.get("id") is String:
				e.append("stage %s: a view without an id" % sid)
				continue
			vids[v.id] = true
			if v.has("yaw_rule"):
				e.append("stage %s view %s turns (yaw_rule %s): stage views slide and never turn (D-91)" % [sid, v.id, v.yaw_rule])
			if not str(v.get("kind", "")) in VIEW_KINDS:
				e.append("stage %s view %s: kind must be one of %s" % [sid, v.id, VIEW_KINDS])
			for k: String in ["yaw_deg", "pitch_deg", "back_m", "rise_m"]:
				if not _num(v.get(k)):
					e.append("stage %s view %s: %s missing" % [sid, v.id, k])
			if v.has("lateral_m") and (not _num(v.lateral_m) or not is_finite(float(v.lateral_m))):
				e.append("stage %s view %s: lateral_m must be finite" % [sid,v.id])
			if _num(v.get("back_m")) and float(v.back_m)<=0.:e.append("stage %s: back_m must be positive" % sid)
			if _num(v.get("rise_m")) and float(v.rise_m)<.3:e.append("stage %s: rise_m must keep the eye above its floor" % sid)
			if v.has("ceiling_clamp"):
				var clamp: Variant=v.ceiling_clamp
				if not clamp is Dictionary:e.append("stage %s: ceiling_clamp must be an object" % sid)
				else:
					for field: String in ["pitch_deg","back_m","rise_m","probe_m"]:
						if not _num(clamp.get(field)):e.append("stage %s: ceiling_clamp.%s must be finite" % [sid,field])
					if _num(clamp.get("back_m")) and float(clamp.back_m)<=0.:e.append("ceiling_clamp.back_m must be positive")
					if _num(clamp.get("rise_m")) and float(clamp.rise_m)<.3:e.append("ceiling_clamp.rise_m must be above the floor")
					if _num(clamp.get("probe_m")) and float(clamp.probe_m)<=0.:e.append("ceiling_clamp.probe_m must be positive")
			for timing: String in ["ease_s","cue_ease_s"]:
				if v.has(timing) and (not _num(v[timing]) or float(v[timing])<0.):e.append("stage %s: %s must be finite and non-negative" % [sid,timing])
			var px: Variant = v.get("captain_px")
			if not _vec(px, 2) or float(px[0]) < PX_MIN or float(px[1]) > PX_MAX or float(px[0]) >= float(px[1]):
				e.append("stage %s view %s: captain_px must be [lo, hi] within %d-%d px" % [sid, v.id, PX_MIN, PX_MAX])
		if not vids.has(str(s.get("default_view", ""))):
			e.append("stage %s: default_view %s is not one of its views" % [sid, s.get("default_view", "missing")])
	for s: Variant in stages:
		if not s is Dictionary:
			continue
		for x: Variant in s.get("exits", []):
			if not x is Dictionary or not (ids.has(str(x.get("to", ""))) or str(x.get("to", "")) == "lift"):
				e.append("stage %s: an exit to an unknown stage (%s)" % [s.get("id", "?"), x.get("to", "missing") if x is Dictionary else x])
	var routes: Variant = d.get("routes", [])
	if not routes is Array:
		e.append("routes must be a list")
		routes = []
	for r: Variant in routes:
		if not r is Dictionary:
			e.append("a route that is not an object")
			continue
		var rid := str(r.get("id", "?"))
		if not str(r.get("kind", "")) in ROUTE_KINDS:
			e.append("route %s: kind must be one of %s" % [rid, ROUTE_KINDS])
		for end: String in ["from", "to"]:
			var at := str(r.get(end, ""))
			if at.is_empty():
				e.append("route %s: missing its %s end" % [rid, end])
			elif not (surfaces.has(at) or at == "lift" or ids.has(at)):
				e.append("route %s: %s end %s is not a stage surface" % [rid, end, at])
			if str(r.get("kind", "")) in ["ladder", "hatch"] and not _vec(r.get(end + "_at"), 3):
				e.append("route %s: a %s needs %s_at [x, y, z]" % [rid, r.kind, end])
	for f: Variant in d.get("finds", []):
		if not f is Dictionary or not ids.has(str(f.get("stage", ""))) or not _vec(f.get("at"), 3):
			e.append("find %s: needs a known stage and at [x, y, z]" % [f.get("id", "?") if f is Dictionary else f])
	for p: Variant in d.get("set_pieces", []):
		if not p is Dictionary or not str(p.get("when", "")) in WHEN:
			e.append("set piece %s: when must be one of %s" % [p.get("id", "?") if p is Dictionary else p, WHEN])
	var layers: Variant = d.get("layers", {})
	if not layers is Dictionary:
		e.append("layers must be an object")
	elif layers.has("foliage"):
		if not layers.foliage is Array:
			e.append("layers.foliage must be a list (painted foliage cards; D-103, D-106)")
		else:
			for c: Variant in layers.foliage:
				if not c is Dictionary or not c.get("card") is String or not _vec(c.get("at"), 3) or not _num(c.get("scale")) or float(c.get("scale", 0)) <= 0.0 \
						or not str(c.get("layer", "")) in FOLIAGE_LAYERS or not _num(c.get("sway")) or float(c.get("sway", -1)) < 0.0:
					e.append("layers.foliage: each card needs card (a library id), at [x, y, z], scale > 0, layer in %s and sway >= 0 (D-106): %s" % [FOLIAGE_LAYERS, c])
	for pc: Variant in d.get("pieces", []):
		if not pc is Dictionary or not str(pc.get("role", "")) in PIECE_ROLES or not str(pc.get("shape", "")) in PIECE_SHAPES:
			e.append("piece %s: role in %s, shape in %s" % [pc.get("name", "?") if pc is Dictionary else pc, PIECE_ROLES, PIECE_SHAPES])
	return e


static func _num(v: Variant) -> bool:
	return (v is float or v is int) and is_finite(float(v))


static func _vec(v: Variant, n: int) -> bool:
	if not v is Array or (v as Array).size() != n:
		return false
	for x: Variant in v:
		if not _num(x):
			return false
	return true
