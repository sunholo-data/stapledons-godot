class_name CameraDirector
extends RefCounted
## R2-CAMERA (design_docs/planned/r2/camera-fixed-views.md) D0-D6: the one owner of every pose
## the player camera takes in the 3D ship. Views are data (data/camera/views.json, validated by
## validate()). ShipCamera stays the render boundary: the director only writes its transform and
## the demo calls _sync_observer(), so the sky is rendered through the same pose as the geometry.
##
##   levels    Z1 Close, Z2 Deck (default), Z3 Whole level: stepped, never continuous (the ruling)
##   sectors   8 x 45 deg around the spire axis (10 deg hysteresis) x 2 rings (the stations ring
##             inside ring_split_m, the rail ring outside; 1 m hysteresis): 16 cells, each with
##             its authored boom yaw (a view's turn_deg per ring)
##   envelope  every eye |eye| <= 95 m (inside the bubble wall); a view past it is clamped along
##             its boom and logged (the schema test fails such a view first)
##   console   focus frames the screen (ShipConsoles.focus_pose) and restore() returns to the
##             remembered level and sector
##   override  tools, captures, goldens and the developer free camera own the camera through
##             override() / release() (set_preset, look_direction, reference_view)
##   motion    "full" eases (smoothstep, no overshoot, <= 90 deg/s); "reduced" cuts with a
##             0.15 s fade and follows rigidly
##
## Time comes from advance(dt) only (the fake-clock seam, as ShipConsoles): no wall-clock reads.

const VIEWS_PATH := "res://data/camera/views.json"
const FOV_DEG := 78.0
const LEVELS := 3
const COOLDOWN_S := 0.3
const PAN_UNIT := 1.0
const PINCH_IN := 1.15
const PINCH_OUT := 0.87
const MAX_DEG_PER_S := 90.0
## Sector switches also keep the eye's acceleration under 36 m/s^2 (1 cm per frame^2 at 60 Hz,
## AC5): a long swing takes longer than the 0.8 s floor rather than lurching.
const MAX_ACCEL_MPS2 := 36.0
const FADE_S := 0.15
const FOLLOW_S := 0.25
const KINDS := ["level", "place", "situation", "console"]
const ANCHORS := ["captain", "point", "station"]
const MOTIONS := ["full", "reduced"]
## Named input actions (D5). Registered at runtime (ensure_actions), so a rebinding screen and a
## controller are mappings onto these names. physical keys, joypad buttons.
const ACTIONS := {
	"camera_level_in": {"keys": [KEY_EQUAL, KEY_KP_ADD], "joy": [JOY_BUTTON_RIGHT_SHOULDER]},
	"camera_level_out": {"keys": [KEY_MINUS, KEY_KP_SUBTRACT], "joy": [JOY_BUTTON_LEFT_SHOULDER]},
	"camera_level_1": {"keys": [KEY_1], "joy": []},
	"camera_level_2": {"keys": [KEY_2], "joy": []},
	"camera_level_3": {"keys": [KEY_3], "joy": []},
	"camera_default": {"keys": [KEY_R], "joy": [JOY_BUTTON_RIGHT_STICK]},
	"camera_sky_forward": {"keys": [KEY_7], "joy": [JOY_BUTTON_DPAD_UP]},
	"camera_sky_side": {"keys": [KEY_8], "joy": [JOY_BUTTON_DPAD_RIGHT]},
	"camera_sky_aft": {"keys": [KEY_9], "joy": [JOY_BUTTON_DPAD_DOWN]},
	"camera_free_toggle": {"keys": [KEY_F8], "joy": []},
}

var demo: Node = null
var data := {}
var views := {}
var errors := PackedStringArray()
var level := 2
var default_level := 2
var view_id := "z2"
var sector := -1
var area := "bridge"
var motion := "full"
var overridden := false
var console_pose := Transform3D()
var pose := Transform3D()
var has_pose := false
var fade := 0.0
var clamp_log: Array = []
var _blend := {} # {from: Transform3D, off: Vector3, dyaw, dpitch, t, dur, base, travel_cap, ready}
var _step_origin := Vector3.ZERO # the pose's last per-frame motion (a blend carries it on, so it never stalls)
var _step_yp := Vector2.ZERO
var _restoring := false
var _foot := Vector3.ZERO
var _foot_v := Vector3.ZERO
var _cooldown := 0.0
var _pan := 0.0
var _pinch := 1.0
## C2 situation views (sky forward / side / aft): the active one ("" = the level view), a view
## waiting for the captain's walk to its anchor, the interlude hold, and the HUD prompt a cue
## becomes under reduced motion (or off the bridge).
var situation := ""
var cue_prompt := ""
var hold := false
var _pending := ""
var _prompt_t := 0.0
var _sky_offset := {} # view id -> the yaw offset (deg, from outward) chosen when the view started
const PROMPT_S := 10.0


static func load_views(path := VIEWS_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _init(owner_demo: Node = null, path := VIEWS_PATH) -> void:
	demo = owner_demo
	data = load_views(path)
	errors = validate(data)
	for v: Dictionary in data.get("views", []):
		views[str(v.get("id", ""))] = v
	default_level = int(data.get("default_level", 2))
	level = default_level
	view_id = level_view(level, "bridge").get("id", "z2")


## The views.json schema (AC1's first half): kinds, anchors, numbers, one view per level, FOV 78.
static func validate(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if d.is_empty():
		return PackedStringArray(["views.json missing or not an object"])
	if not is_equal_approx(float(d.get("fov_deg", 0.0)), FOV_DEG):
		out.append("fov_deg must be %.0f (zoom is a dolly, never a lens)" % FOV_DEG)
	if float(d.get("envelope_m", 0.0)) <= 0.0 or float(d.get("envelope_m", 0.0)) > 95.0:
		out.append("envelope_m must be in (0, 95]")
	var s: Variant = d.get("sectors")
	if not s is Dictionary or int(s.get("count", 0)) != 8 or float(s.get("hysteresis_deg", -1.0)) < 0.0 or float(s.get("ring_split_m", 0.0)) <= 0.0 or float(s.get("ring_hysteresis_m", -1.0)) < 0.0:
		out.append("sectors must be {count: 8, hysteresis_deg >= 0, ring_split_m > 0, ring_hysteresis_m >= 0, switch_s}")
	var ids := {}
	var levels := {}
	for v: Variant in d.get("views", []):
		if not v is Dictionary:
			out.append("a view is not an object")
			continue
		var id := str(v.get("id", ""))
		if id.is_empty() or ids.has(id):
			out.append("view id missing or repeated: '%s'" % id)
		ids[id] = true
		if not str(v.get("kind", "")) in KINDS:
			out.append("%s: kind must be one of %s" % [id, KINDS])
		if not str(v.get("anchor", "")) in ANCHORS:
			out.append("%s: anchor must be one of %s" % [id, ANCHORS])
		var rule := str(v.get("yaw_rule", ""))
		if not (rule == "sector" or rule == "outward" or rule == "tangent" or rule.begins_with("fixed:") or rule.begins_with("toward:")):
			out.append("%s: yaw_rule must be sector, outward, fixed:<deg> or toward:<target>" % id)
		if v.get("kind") == "situation":
			for k in ["pitch_deg", "back_m", "rise_m", "height_m"]:
				if not v.has(k):
					out.append("%s: a sky view needs %s" % [id, k])
		if float(v.get("ease_s", -1.0)) < 0.0:
			out.append("%s: ease_s must be >= 0" % id)
		if v.has("fov_deg") and not is_equal_approx(float(v.fov_deg), FOV_DEG):
			out.append("%s: a view may not change the FOV" % id)
		if rule == "sector" and v.get("anchor") == "captain" and v.get("kind") == "level" and not (v.get("turn_deg") is Array and v.turn_deg.size() == 2):
			out.append("%s: a sector boom needs turn_deg [stations ring, rail ring]" % id)
		if v.get("kind") == "level":
			for k in ["pitch_deg", "distance_m", "height_m", "frame_deg"]:
				if not v.has(k):
					out.append("%s: a level view needs %s" % [id, k])
			if float(v.get("distance_m", 0.0)) <= 0.0:
				out.append("%s: distance_m must be > 0 (third person only)" % id)
		if v.get("anchor") == "point":
			for k in ["deck_y_m", "eye_radius_m", "eye_rise_m", "eye_angle_deg", "aim_radius_m", "track_deg"]:
				if not v.has(k):
					out.append("%s: a place view needs %s" % [id, k])
		var lv := int(v.get("level", 0))
		if lv > 0:
			var key := "%d:%s" % [lv, v.get("area", "any")]
			if levels.has(key):
				out.append("%s: level %d is already defined for area %s" % [id, lv, v.get("area", "any")])
			levels[key] = true
	for lv in range(1, LEVELS + 1):
		for a in ["bridge", "lower"]:
			if not levels.has("%d:any" % lv) and not levels.has("%d:%s" % [lv, a]):
				out.append("level %d has no view for area %s" % [lv, a])
	return out


## Registers the named actions (D5) once; tests and the demo call it.
static func ensure_actions() -> void:
	for action: String in ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k: int in ACTIONS[action].keys:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)
		for b: int in ACTIONS[action].joy:
			var j := InputEventJoypadButton.new()
			j.button_index = b
			InputMap.action_add_event(action, j)


## The view a level resolves to in an area ("bridge" or "lower"); an area's own view wins over "any".
func level_view(lv: int, where: String) -> Dictionary:
	var any := {}
	for v: Dictionary in views.values():
		if int(v.get("level", 0)) != lv:
			continue
		if str(v.get("area", "")) == where:
			return v
		if str(v.get("area", "")) == "any":
			any = v
	return any


# ------------------------------------------------------------------ geometry (pure)

## The cell (0..15: ring * 8 + sector) of a standing point. The sector is the plan angle (45 deg,
## kept until hysteresis_deg past its edges); the ring is the stations ring (r < ring_split_m) or
## the rail ring, kept until ring_hysteresis_m past the split.
func sector_for(foot: Vector3, current: int) -> int:
	var s: Dictionary = data.get("sectors", {})
	var n := int(s.get("count", 8))
	var width := 360.0 / n
	var hyst := float(s.get("hysteresis_deg", 10.0))
	var a := fposmod(rad_to_deg(atan2(foot.z, foot.x)), 360.0)
	var ang := int(floor(a / width)) % n
	if current >= 0 and current % n != ang:
		var centre := (current % n + 0.5) * width
		if absf(wrapf(a - centre, -180.0, 180.0)) <= width * 0.5 + hyst:
			ang = current % n
	var r := Vector2(foot.x, foot.z).length()
	var split := float(s.get("ring_split_m", 12.0))
	var ring := 0 if r < split else 1
	if current >= 0 and current / n != ring and absf(r - split) <= float(s.get("ring_hysteresis_m", 1.0)):
		ring = current / n
	return ring * n + ang


## The camera's look yaw for a cell and a view (radians, ShipCamera's convention: forward =
## (cos, ., sin)): the sector's centre angle plus the view's turn for the ring.
func sector_yaw(k: int, v: Dictionary = {}) -> float:
	return deg_to_rad(sector_centre_deg(k) + _ring_val(v, "turn_deg", k, 0.0))


## A view's yaw: the cell's (sector), a fixed world yaw (fixed:<deg>) or outward from the spire.
func yaw_for(v: Dictionary, foot: Vector3, k: int) -> float:
	var rule := str(v.get("yaw_rule", "sector"))
	if rule.begins_with("fixed:"):
		return deg_to_rad(float(rule.trim_prefix("fixed:")))
	if rule == "outward":
		return atan2(foot.z, foot.x)
	if rule == "tangent": # along the ring: the eye is never nearer the spire than the captain
		return atan2(foot.z, foot.x) + PI * 0.5
	return sector_yaw(k, v)


func sector_centre_deg(k: int) -> float:
	var n := int(data.get("sectors", {}).get("count", 8))
	return (k % n + 0.5) * 360.0 / n


func ring_of(k: int) -> int:
	return k / int(data.get("sectors", {}).get("count", 8))


## A per-ring view value ([stations ring, rail ring]) or a scalar for both.
func _ring_val(v: Dictionary, key: String, k: int, fallback: float) -> float:
	var cells: Variant = v.get("cells")
	if cells is Dictionary and cells.has(str(k)) and (cells[str(k)] as Dictionary).has(key):
		return float(cells[str(k)][key])
	var x: Variant = v.get(key, fallback)
	if x is Array:
		return float(x[clampi(ring_of(k), 0, x.size() - 1)])
	return float(x)


## The pose of a view for a captain standing at `foot` in sector `k`.
func resolve(v: Dictionary, foot: Vector3, k: int) -> Transform3D:
	match str(v.get("anchor", "")):
		"captain":
			if v.get("kind") == "situation":
				return _sky(v, foot, k)
			return _boom(v, foot, sector_yaw(k, v), k)
		"point":
			return _place(v, foot, k)
		"station":
			if v.has("offset_m"):
				var o: Array = v.offset_m
				var head := foot + Vector3.UP * float(v.get("height_m", 1.6))
				var eye := _envelope(foot + Vector3(o[0], o[1], o[2]), head, str(v.id))
				return Transform3D(Basis.looking_at(head - eye, _up_for(head - eye)), eye)
			return console_pose
	return pose


func head_of(v: Dictionary, foot: Vector3) -> Vector3:
	return foot + Vector3.UP * float(v.get("height_m", 1.6))


func _boom(v: Dictionary, foot: Vector3, yaw: float, k := -1) -> Transform3D:
	var p := deg_to_rad(_ring_val(v, "pitch_deg", k, float(v.get("pitch_deg", -35.0))))
	var dir := Vector3(cos(yaw) * cos(p), sin(p), sin(yaw) * cos(p))
	var head := head_of(v, foot)
	var eye := _envelope(head - dir * _ring_val(v, "distance_m", k, float(v.get("distance_m", 12.0))), head, str(v.id))
	var right := dir.cross(Vector3.UP).normalized()
	var look := dir.rotated(right, deg_to_rad(float(v.get("frame_deg", 0.0))))
	return Transform3D(Basis.looking_at(look, Vector3.UP), eye)


## C2 sky views: the eye back_m behind the captain (along the view's yaw) and rise_m above the
## deck, looking at a fixed pitch; the captain is a silhouette against the sky in the lower part
## of the frame. The sky is at infinity, so any eye on the bridge sees the same directions.
func _sky(v: Dictionary, foot: Vector3, k: int, offset: Variant = null) -> Transform3D:
	var yaw := yaw_for(v, foot, k)
	if offset == null:
		offset = _sky_offset.get(str(v.id))
	if offset != null:
		yaw = atan2(foot.z, foot.x) + deg_to_rad(float(offset))
	var f := Vector3(cos(yaw), 0.0, sin(yaw))
	var head := head_of(v, foot)
	var eye := _envelope(foot - f * float(v.back_m) + Vector3.UP * float(v.rise_m), head, str(v.id))
	return Transform3D(basis_of(yaw, deg_to_rad(float(v.pitch_deg))), eye)


## A view with yaw_candidates (Sky forward) picks, once, as it starts, the first yaw (relative to
## outward) whose eye sees the captain's whole figure and the forward pole clear; null when none
## does (the captain then walks to the view's anchor). Chosen once, never re-chosen per frame.
func choose_offset(v: Dictionary, foot: Vector3) -> Variant:
	for off: float in v.get("yaw_candidates_deg", []):
		var pose := _sky(v, foot, sector_for(foot, -1), off)
		if pose.origin.length() <= float(data.get("envelope_m", 95.0)) and view_clear(pose, foot, true):
			return off
	return null


## The captain's figure (0.15 to 1.6 m) seen from a pose, through the ship's collision and the
## lift's boxes; with `pole`, the forward pole straight overhead is clear too.
func view_clear(pose: Transform3D, foot: Vector3, pole := false) -> bool:
	if demo == null:
		return true
	var space: PhysicsDirectSpaceState3D = demo.camera.get_world_3d().direct_space_state
	var boxes := lift_boxes()
	var targets: Array = [foot + Vector3.UP * 0.15, foot + Vector3.UP * 0.9, foot + Vector3.UP * 1.6]
	for p: Vector3 in targets:
		var q := PhysicsRayQueryParameters3D.create(pose.origin, p + (pose.origin - p).normalized() * 0.25)
		q.hit_back_faces = true
		if not space.intersect_ray(q).is_empty():
			return false
		for b: AABB in boxes:
			if b.intersects_segment(pose.origin, p.lerp(pose.origin, 0.02)):
				return false
	if pole:
		var q2 := PhysicsRayQueryParameters3D.create(pose.origin, pose.origin + Vector3.UP * 40.0)
		q2.hit_back_faces = true
		if not space.intersect_ray(q2).is_empty():
			return false
		var sp := screen_point(pose, pose.origin + Vector3.UP * 1000.0, Vector2(1280, 720))
		if is_nan(sp.x) or not Rect2(Vector2(0, 40), Vector2(1280, 680)).has_point(sp):
			return false
	return true


## The lift's visible boxes (they have no collision), as global AABBs.
func lift_boxes() -> Array:
	var out := []
	if demo == null or demo.lift == null:
		return out
	var stack: Array = [demo.lift]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.is_visible_in_tree() and n.mesh != null:
			out.append((n as MeshInstance3D).global_transform * n.mesh.get_aabb())
		stack.append_array(n.get_children())
	return out


## The standing point a situation view needs (walk_to: a rail point at a fixed angle, or at the
## captain's own angle), or null when the view works from anywhere on the bridge.
func anchor_of(v: Dictionary, foot: Vector3) -> Variant:
	var w: Variant = v.get("walk_to")
	if not w is Dictionary or demo == null:
		return null
	if w.has("beyond_m") and Vector2(foot.x, foot.z).length() <= float(w.beyond_m):
		return null
	var ang: float = atan2(foot.z, foot.x) if str(w.get("angle_deg", "captain")) == "captain" else deg_to_rad(float(w.angle_deg))
	var r := float(w.radius_m)
	return demo.walk_bridge.closest_walkable(Vector3(r * cos(ang), 82.0, r * sin(ang)), 4.0)


func _place(v: Dictionary, foot: Vector3, k: int) -> Transform3D:
	var c := deg_to_rad(sector_centre_deg(k))
	var a := c + deg_to_rad(_ring_val(v, "eye_angle_deg", k, 0.0))
	var deck := float(v.deck_y_m)
	var er := _ring_val(v, "eye_radius_m", k, 15.0)
	var eye := Vector3(er * cos(a), deck + _ring_val(v, "eye_rise_m", k, 8.0), er * sin(a))
	var head := head_of(v, foot)
	eye = _envelope(eye, head, str(v.id))
	var ar := _ring_val(v, "aim_radius_m", k, 10.0)
	var aim := Vector3(ar * cos(c), deck + float(v.get("height_m", 1.6)), ar * sin(c))
	var nominal := (aim - eye).normalized()
	var want := (head - eye).normalized()
	var ang := nominal.angle_to(want)
	var track := deg_to_rad(float(v.track_deg))
	if ang > track:
		want = nominal.slerp(want, track / ang).normalized()
	return Transform3D(Basis.looking_at(want, Vector3.UP), eye)


static func _up_for(forward: Vector3) -> Vector3:
	return Vector3.FORWARD if absf(forward.normalized().dot(Vector3.UP)) > 0.99 else Vector3.UP


## Inside the wall, always (D8 rule 1): an eye past envelope_m moves along its boom toward the head.
func _envelope(eye: Vector3, head: Vector3, id: String) -> Vector3:
	var limit := float(data.get("envelope_m", 95.0))
	if eye.length() <= limit:
		return eye
	var d := eye - head
	# |head + s d| = limit, s in [0, 1]
	var a := d.dot(d)
	var b := 2.0 * head.dot(d)
	var c := head.dot(head) - limit * limit
	var disc := b * b - 4.0 * a * c
	var s := 0.0 if disc < 0.0 or a < 1e-12 else clampf((-b + sqrt(disc)) / (2.0 * a), 0.0, 1.0)
	if not id in clamp_log:
		clamp_log.append(id)
		push_warning("camera: view %s left the %.0f m envelope (|eye| %.1f m); clamped along its boom" % [id, limit, eye.length()])
	return head + d * s


## The captain's projected figure height in pixels (a full billboard of `height_m`, facing the
## camera) for a pose, FOV 78 deg (keep height) and a viewport `px_h` tall (AC4).
static func figure_px(cam: Transform3D, foot: Vector3, height_m: float, px_h: float) -> float:
	var up := cam.basis.y
	var a := _screen_y(cam, foot, px_h)
	var b := _screen_y(cam, foot + up * height_m, px_h)
	return absf(a - b)


## Screen y (pixels from the top) of a point, or NAN behind the camera.
static func _screen_y(cam: Transform3D, p: Vector3, px_h: float) -> float:
	var local := cam.affine_inverse() * p
	if local.z >= -1e-6:
		return NAN
	var f := tan(deg_to_rad(FOV_DEG) * 0.5)
	return px_h * 0.5 - (local.y / -local.z) / f * px_h * 0.5


## The screen position (pixels) of a point for a w x h viewport, or (NAN, NAN) behind.
static func screen_point(cam: Transform3D, p: Vector3, px: Vector2) -> Vector2:
	var local := cam.affine_inverse() * p
	if local.z >= -1e-6:
		return Vector2(NAN, NAN)
	var f := tan(deg_to_rad(FOV_DEG) * 0.5)
	var x := (local.x / -local.z) / f
	var y := (local.y / -local.z) / f
	return Vector2(px.x * 0.5 + x * px.y * 0.5, px.y * 0.5 - y * px.y * 0.5)


# ------------------------------------------------------------------ control

## Locked: lift travel, benchmark, console focus, an open panel (wheel belongs to the panel).
func locked() -> bool:
	if demo == null:
		return false
	if view_id == "console" or demo.camera_mode == "console":
		return true
	if demo.benchmark.running or (demo.lift != null and demo.lift.travelling()):
		return true
	return demo.pointer_required()


func set_level(lv: int) -> bool:
	if lv < 1 or lv > LEVELS or locked():
		return false
	var was_overridden := overridden
	release()
	var ended := end_situation()
	if lv == level and not was_overridden and not ended:
		return false
	level = lv
	_cooldown = COOLDOWN_S
	_start_blend(float(level_view(level, area).get("ease_s", 0.45)))
	return true


## One step in (toward Z1) or out (toward Z3); Z1 is the floor and Z3 the ceiling, no wrap.
func step_level(dir: int) -> bool:
	if hold:
		return false
	var lv := clampi(level + dir, 1, LEVELS)
	if lv == level and not overridden and situation.is_empty() and _pending.is_empty():
		return false
	return set_level(lv)


## R: the default view and level (D1).
func default_view() -> bool:
	if demo != null and (demo.benchmark.running or (demo.lift != null and demo.lift.travelling())):
		return false
	if hold:
		return false
	# Under way, the default view keeps the forward sky (the starbow) in frame (C2).
	if demo != null and demo.has_method("under_way") and demo.under_way() and demo.active_level == 0:
		release()
		level = default_level
		return sky("sky_forward")
	var changed := level != default_level or overridden or not situation.is_empty()
	release()
	situation = ""
	_pending = ""
	level = default_level
	if changed:
		_start_blend(float(level_view(level, area).get("ease_s", 0.45)))
	return true


## A wheel notch: one level, then COOLDOWN_S; repeats inside the cooldown are ignored and
## extend it (a wheel or an inertial swipe is one step). dir: -1 in (closer), +1 out.
func wheel(dir: int) -> bool:
	if _cooldown > 0.0:
		_cooldown = COOLDOWN_S
		return false
	return step_level(dir)


## A trackpad scroll: accumulate delta.y; one level per PAN_UNIT. Horizontal scroll is ignored.
## Scrolling down (delta.y > 0) comes closer, as the old dolly (-delta.y pulled back).
func pan(delta: Vector2) -> bool:
	if absf(delta.y) < 1e-9:
		return false
	if _cooldown > 0.0:
		_cooldown = COOLDOWN_S
		_pan = 0.0
		return false
	_pan += delta.y
	if absf(_pan) < PAN_UNIT:
		return false
	var dir := -1 if _pan > 0.0 else 1
	_pan = 0.0
	if not step_level(dir):
		_cooldown = COOLDOWN_S
		return false
	return true


## A pinch (magnify): one level per x1.15 (in) or x0.87 (out).
func pinch(factor: float) -> bool:
	if factor <= 0.0:
		return false
	if _cooldown > 0.0:
		_cooldown = COOLDOWN_S
		_pinch = 1.0
		return false
	_pinch *= factor
	var dir := 0
	if _pinch >= PINCH_IN:
		dir = -1
	elif _pinch <= PINCH_OUT:
		dir = 1
	if dir == 0:
		return false
	_pinch = 1.0
	if not step_level(dir):
		_cooldown = COOLDOWN_S
		return false
	return true


## C2: a sky view. A player key (7 / 8 / 9) or a cue (departure, a guided stop, braking, Sgr A*).
## A cue starts only with no panel open, not at a console and not in the lift; under reduced
## motion it is a HUD prompt instead. A view with an anchor walks the captain there first (the
## consoles' walk path, 3.5 m/s) and starts on arrival. `force`: the interlude hold.
func sky(id: String, cued := false, force := false) -> bool:
	var v: Dictionary = views.get(id, {})
	if v.is_empty() or demo == null or (cued and overridden):
		return false
	if demo.active_level != 0:
		if not cued:
			_prompt("Sky views are on the bridge")
		return false
	if demo.benchmark.running or (demo.lift != null and demo.lift.travelling()):
		return false
	if not force and not demo.consoles.focused.is_empty():
		return false
	if cued and not force and demo.panel_open():
		return false
	if cued and not force and motion == "reduced":
		_prompt(str(v.get("prompt", "Sky · 7")))
		return false
	release()
	var anchor: Variant = anchor_of(v, demo.avatar_pos)
	if v.has("yaw_candidates_deg"):
		var off: Variant = choose_offset(v, demo.avatar_pos)
		if off != null:
			anchor = null
			_sky_offset[id] = off
	if anchor is Vector3 and Vector2(demo.avatar_pos.x - anchor.x, demo.avatar_pos.z - anchor.z).length() > 0.75:
		if demo.consoles.walk_to_point(anchor, str(v.get("name", "rail"))):
			_pending = id
			cue_prompt = ""
			return true
		return false
	_enter(id, cued)
	return true


func _enter(id: String, cued: bool) -> void:
	_finish_restore() # a cue while stepping back from a console takes the camera from there
	situation = id
	_pending = ""
	cue_prompt = ""
	var v: Dictionary = views[id]
	_start_blend(float(v.get("cue_ease_s", 1.5) if cued else v.get("ease_s", 1.2)))


## Any level key, move key or R ends a sky view (back to the remembered level); not while the
## interlude holds it.
func end_situation() -> bool:
	if hold or (situation.is_empty() and _pending.is_empty()):
		return false
	situation = ""
	_pending = ""
	_start_blend(float(level_view(level, area).get("ease_s", 0.45)))
	return true


func _prompt(text: String) -> void:
	cue_prompt = text
	_prompt_t = PROMPT_S


## Console focus (D4): a framed screen; the level is remembered.
func focus_console(to: Transform3D) -> void:
	release()
	console_pose = to
	view_id = "console"
	_restoring = false
	_start_blend(float(views.get("console", {}).get("ease_s", 0.6)))


## Step back: to the remembered level and sector (not a stored tilt/yaw).
func restore() -> void:
	if view_id != "console":
		return
	view_id = level_view(level, area).get("id", "z2")
	_restoring = true
	_start_blend(float(views.get("console", {}).get("ease_s", 0.6)))


func blending() -> bool:
	return not _blend.is_empty()


## Tools, captures and the developer free camera take the camera; release() hands it back.
func override() -> void:
	overridden = true
	_blend = {}
	_restoring = false


func release() -> void:
	if not overridden:
		return
	overridden = false
	if demo != null:
		demo.camera.reference = false
		if demo.camera_mode != "console":
			demo.camera_mode = "player"
	has_pose = false # the first frame back is a cut, never a swing from a tool's pose


func set_motion(m: String) -> void:
	motion = m if m in MOTIONS else "full"


## The yaw WASD walks by: the view's (not the blend's) flat forward (D2 screen-relative).
func walk_yaw() -> float:
	if overridden and demo != null:
		var f: Vector3 = -demo.camera.global_transform.basis.z
		return atan2(f.z, f.x)
	var v: Dictionary = level_view(level, area) if situation.is_empty() else views.get(situation, {})
	if v.get("anchor") == "captain" or v.get("anchor") == "point":
		var f2: Vector3 = -resolve(v, _foot, maxi(sector, 0)).basis.z
		return atan2(f2.z, f2.x)
	var f3: Vector3 = -pose.basis.z
	return atan2(f3.z, f3.x)


func _start_blend(base: float) -> void:
	if motion == "reduced" or not has_pose:
		_blend = {}
		if has_pose:
			fade = 1.0
		_finish_restore()
		return
	_blend = {"from": pose, "t": 0.0, "dur": base, "base": base, "ready": false}


func _finish_restore() -> void:
	if _restoring:
		_restoring = false
		if demo != null:
			demo.camera_mode = "player"


# ------------------------------------------------------------------ the frame

func advance(dt: float) -> void:
	dt = maxf(dt, 0.0)
	_cooldown = maxf(0.0, _cooldown - dt)
	fade = maxf(0.0, fade - dt / FADE_S)
	_prompt_t = maxf(0.0, _prompt_t - dt)
	if _prompt_t <= 0.0:
		cue_prompt = ""
	if demo == null or overridden:
		return
	if not _pending.is_empty() and demo.consoles.walk_target.is_empty():
		var anchor: Variant = anchor_of(views[_pending], demo.avatar_pos)
		if anchor is Vector3 and Vector2(demo.avatar_pos.x - anchor.x, demo.avatar_pos.z - anchor.z).length() <= 0.75:
			if views[_pending].has("yaw_candidates_deg"):
				var off: Variant = choose_offset(views[_pending], demo.avatar_pos)
				_sky_offset[_pending] = off if off != null else 90.0
			_enter(_pending, true)
		else:
			_pending = ""
	var foot: Vector3 = demo.avatar_pos
	_follow(foot, dt)
	area = "lower" if demo.active_level == 1 else "bridge"
	var target: Transform3D
	var lifting: bool = demo.lift != null and demo.lift.travelling()
	if view_id == "console":
		target = console_pose
	elif lifting:
		target = resolve(views.get("lift", {}), foot, 0)
		if view_id != "lift":
			view_id = "lift"
			_start_blend(float(views.get("lift", {}).get("ease_s", 0.6)))
	else:
		if area != "bridge" and not hold:
			situation = ""
		var v: Dictionary = level_view(level, area) if situation.is_empty() else views[situation]
		if view_id == "lift":
			_start_blend(float(views.get("lift", {}).get("ease_s", 0.6)))
		view_id = str(v.get("id", ""))
		var k := sector_for(_foot, sector)
		if k != sector and sector >= 0 and has_pose:
			var s: Dictionary = data.get("sectors", {})
			_start_blend(float(s.get("switch_s", 0.8)))
			if not _blend.is_empty():
				_blend.travel_cap = true
		sector = k
		target = resolve(v, _foot, k)
	var before := pose
	pose = _blended(target, dt)
	if has_pose:
		_step_origin = pose.origin - before.origin
		var a := yaw_pitch(pose)
		var b := yaw_pitch(before)
		_step_yp = Vector2(wrapf(a.x - b.x, -PI, PI), a.y - b.y)
	else:
		_step_origin = Vector3.ZERO
		_step_yp = Vector2.ZERO
	has_pose = true
	_write()


func _follow(foot: Vector3, dt: float) -> void:
	if foot.distance_to(_foot) > 5.0 and has_pose:
		# A teleport (R, a tool, a test): cut, never a swing across the ship.
		has_pose = false
		sector = -1
		_blend = {}
	if motion == "reduced" or not has_pose or demo.lift.travelling():
		_foot = foot
		_foot_v = Vector3.ZERO
		return
	# Critically damped (FOLLOW_S): no overshoot, no bob.
	var omega := 2.0 / FOLLOW_S
	var x := omega * dt
	var e := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	var change := _foot - foot
	var temp := (_foot_v + omega * change) * dt
	_foot_v = (_foot_v - omega * temp) * e
	_foot = foot + (change + temp) * e


## The blend is an offset that decays to zero on top of the live target (position, and yaw and
## pitch: every player pose has zero roll, so the blend never rolls). The target keeps moving
## with the captain underneath, so starting a blend never stops the camera's motion.
func _blended(target: Transform3D, dt: float) -> Transform3D:
	if _blend.is_empty():
		return target
	var ty := yaw_pitch(target)
	if not _blend.ready:
		# Start from where the pose would have been this frame, had nothing changed: the blend then
		# carries the camera's motion on instead of stalling it for a frame (AC5).
		var from := Transform3D(Basis(), (_blend.from as Transform3D).origin + _step_origin)
		var fy := yaw_pitch(_blend.from) + _step_yp
		var dyaw := wrapf(fy.x - ty.x, -PI, PI)
		var dpitch := fy.y - ty.y
		# Smoothstep peaks at 1.5x the mean rate: keep the peak <= 90 deg/s.
		var dur := maxf(float(_blend.base), 1.5 * rad_to_deg(Vector2(dyaw, dpitch).length()) / MAX_DEG_PER_S)
		if _blend.get("travel_cap", false):
			dur = maxf(dur, sqrt(6.0 * from.origin.distance_to(target.origin) / MAX_ACCEL_MPS2))
		_blend.dur = dur
		_blend.off = from.origin - target.origin
		_blend.dyaw = dyaw
		_blend.dpitch = dpitch
		_blend.ready = true
	_blend.t = minf(1.0, float(_blend.t) + dt / maxf(float(_blend.dur), 1e-6))
	var t: float = _blend.t
	var k := 1.0 - t * t * (3.0 - 2.0 * t)
	var out := Transform3D(basis_of(ty.x + float(_blend.dyaw) * k, ty.y + float(_blend.dpitch) * k), target.origin + (_blend.off as Vector3) * k)
	if t >= 1.0:
		_blend = {}
		_finish_restore()
	return out


## (yaw, pitch) of a pose's look direction, radians, ShipCamera's yaw convention.
static func yaw_pitch(x: Transform3D) -> Vector2:
	var f := -x.basis.z.normalized()
	return Vector2(atan2(f.z, f.x), asin(clampf(f.y, -1.0, 1.0)))


## A zero-roll basis looking along (yaw, pitch).
static func basis_of(yaw: float, pitch: float) -> Basis:
	var f := Vector3(cos(yaw) * cos(pitch), sin(pitch), sin(yaw) * cos(pitch))
	return Basis.looking_at(f, _up_for(f))


func _write() -> void:
	var cam: Camera3D = demo.camera
	cam.global_transform = pose
	var f := -pose.basis.z
	cam.yaw = atan2(f.z, f.x)
	cam.tilt = rad_to_deg(asin(clampf(f.y, -1.0, 1.0)))
	var v: Dictionary = views.get(view_id, {})
	cam.pullback = float(v.get("distance_m", pose.origin.distance_to(head_of(v, demo.avatar_pos)))) if view_id != "console" else 0.0
	cam.external = false
