class_name ShipConsoles
extends Node
## R1-SHIP-UI (D-56, D-57) §B-§C: the bridge consoles decide. Every captain decision (plot,
## set speed, commit, cancel, approach, leave, the guided voyage, the Archive) is made at a
## console of ship.glb: walk there (WASD, click-to-walk, or Tab "Walk to"), E or click to
## use it, the camera dollies to a framed panel (D-57 Q4), Esc or E steps back.
##
## use(station, action, arg) is the single entry for the player's panels, the tests and the
## M4.5 bot. A decision action needs that station focused; focus needs the captain in reach
## (2.5 m). Irreversible actions confirm by a 1.5 s hold or by pressing twice (the
## accessibility setting, §C4); neither has a deadline.
##
## Time comes from advance(dt) only (the fake-clock seam): no wall-clock reads (AC13).

signal used(station: String, action: String)

const BlackHoleVisit := preload("res://demos/black_hole_visit.gd")

const REACH_M := 2.5
const FACING_DEG := 60.0
const DOLLY_S := 0.6
const WALK_SPEED_MPS := 3.5
const PATH_CEILING_M := 40.0
const HOLD_S := 1.5
const BRIDGE_SPAWN := Vector3(8, 82, -4.8)
## The stations, from ship.glb node names (§B, D-57 Q5). The navigation station is the arc
## of three consoles; "walk" names the mesh Walk-to aims for.
const STATIONS := {
	"navigation": {"name": "Navigation station", "meshes": ["console_navigation_0", "console_navigation_1", "console_navigation_2"], "walk": "console_navigation_1", "active": true},
	"voyage": {"name": "Voyage console", "meshes": ["console_decision_0"], "walk": "console_decision_0", "active": true},
	"archive": {"name": "Archive terminal", "meshes": ["archive_terminal"], "walk": "archive_terminal", "active": true},
	"reserved_1": {"name": "Crew console", "meshes": ["console_decision_1"], "walk": "console_decision_1", "active": false},
	"reserved_2": {"name": "Crew console", "meshes": ["console_decision_2"], "walk": "console_decision_2", "active": false},
	"reserved_3": {"name": "Crew console", "meshes": ["console_decision_3"], "walk": "console_decision_3", "active": false},
}
## Actions use() accepts per station (ShipControls.CONSOLE names each decision's action).
const ACTIONS := {
	"navigation": ["open", "select", "speed", "commit", "cancel", "home", "sgr_a", "approach", "leave"],
	"voyage": ["open", "begin"],
	"archive": ["open"],
}
const ITINERARY := "Earth → Sun → Jupiter → Callisto → Saturn → α Centauri → α Cen A → TRAPPIST-1 → Aldebaran"
const HINT := "Decisions are made at the bridge consoles: the Voyage console begins the guided voyage, the navigation station plots a course. Tab · Walk to."

var demo: Node
var now_s := 0.0
var stations := {} # id -> {id, name, active, meshes: [{name, node, origin, box, use}], use, path_len}
var mesh_station := {} # mesh name -> station id
var focused := ""
var focus_mesh := ""
var used_once := false
var confirm_mode := "hold"
var walking := PackedVector3Array()
var walk_target := ""
var _dolly := {} # {from_pos, from_basis, to_pos, to_basis, t, back}
var _eye := {} # the captain's camera before focus: tilt, yaw, pullback
var _confirm := {} # {id, action, held_s, holding, armed, button, label}
var _aimed := ""
var _glow: Array = [] # [MeshInstance3D, StandardMaterial3D]
var screens := {} # station -> {viewport, label, text}
var panel_layer := CanvasLayer.new()
var panel := PanelContainer.new()
var panel_title := Label.new()
var panel_body := VBoxContainer.new()
var step_back := Button.new()


func setup(owner_demo: Node) -> void:
	demo = owner_demo
	name = "ShipConsoles"
	for id: String in STATIONS:
		var spec: Dictionary = STATIONS[id]
		var st := {"id": id, "name": spec.name, "active": spec.active, "meshes": [], "use": Vector3.ZERO, "path_len": -1.0}
		for mesh_name: String in spec.meshes:
			var n := demo.geometry.find_child(mesh_name, true, false) as MeshInstance3D
			if n == null:
				continue
			var box: AABB = n.global_transform * n.mesh.get_aabb()
			var origin: Vector3 = n.global_transform.origin
			var use: Vector3 = demo.walk_bridge.closest_walkable(Vector3(origin.x, 82.0, origin.z), REACH_M)
			# Stand a step back from the console's edge (still in reach) so it is in view.
			var out := Vector3(use.x - origin.x, 0.0, use.z - origin.z)
			if out.length() > 1e-3:
				var back: Vector3 = demo.walk_bridge.closest_walkable(use + out.normalized() * 0.9, 0.4)
				if demo.walk_bridge.is_walkable(back) and footprint_distance(box, back) <= REACH_M - 0.5:
					use = back
			st.meshes.append({"name": mesh_name, "node": n, "origin": origin, "box": box, "use": use})
			mesh_station[mesh_name] = id
			if mesh_name == spec.walk:
				st.use = use
		stations[id] = st
	_build_panel()
	_build_screens()


## Walked path length from the bridge spawn to each station's use point (AC8; printed by
## the console test, 40 m ceiling).
func path_length(id: String) -> float:
	var p: PackedVector3Array = demo.walk_bridge.path(BRIDGE_SPAWN, stations[id].use)
	if p.is_empty():
		return -1.0
	var length := BRIDGE_SPAWN.distance_to(p[0])
	for i in range(1, p.size()):
		length += p[i - 1].distance_to(p[i])
	stations[id].path_len = length
	return length


## Plan-view distance from p to a console mesh's footprint.
static func footprint_distance(box: AABB, p: Vector3) -> float:
	var dx := maxf(0.0, maxf(box.position.x - p.x, p.x - box.end.x))
	var dz := maxf(0.0, maxf(box.position.z - p.z, p.z - box.end.z))
	return sqrt(dx * dx + dz * dz)


## The console in reach (2.5 m) and faced (within 60 deg of the view, plan view): {id, mesh, d}.
func in_reach(p: Vector3, forward: Vector3) -> Dictionary:
	var best := {}
	if demo.active_level != 0:
		return best
	var f := Vector2(forward.x, forward.z)
	for id: String in stations:
		for m: Dictionary in stations[id].meshes:
			var d := footprint_distance(m.box, p)
			if d > REACH_M:
				continue
			var c: Vector3 = m.box.get_center()
			var to := Vector2(c.x - p.x, c.z - p.z)
			if f.length() > 1e-6 and to.length() > 1e-6 and absf(rad_to_deg(f.angle_to(to))) > FACING_DEG:
				continue
			if best.is_empty() or d < best.d:
				best = {"id": id, "mesh": m.name, "d": d}
	return best


func captain_forward() -> Vector3:
	var yaw: float = demo.camera.yaw
	return Vector3(cos(yaw), 0.0, sin(yaw))


## What E uses now: the nearest interactable in reach and facing, the lift landing included
## (§F "E priority"; the prompt names it). {kind: "station"/"lift", id, d} or {}.
func e_target() -> Dictionary:
	if focused != "" or demo.lift == null or demo.lift.travelling():
		return {}
	var best := {}
	var st := in_reach(demo.avatar_pos, captain_forward())
	if not st.is_empty():
		best = {"kind": "station", "id": st.id, "d": st.d}
	var point: Vector3 = demo.lift.BOARD_POINT
	point.y = 82.0 if demo.active_level == 0 else 57.0
	var dl: float = demo.avatar_pos.distance_to(point)
	if dl <= 1.5 and (best.is_empty() or dl < best.d):
		best = {"kind": "lift", "id": "lift", "d": dl}
	return best


func press_e() -> bool:
	if focused != "":
		leave()
		return true
	var t := e_target()
	if t.is_empty():
		return false
	if t.kind == "lift":
		return demo.lift.board()
	return use(t.id, "open")


func prompt_text() -> String:
	if focused != "":
		return "%s · E or Esc steps back" % stations[focused].name
	if not walk_target.is_empty():
		return "Walking to the %s · WASD takes over" % stations[walk_target].name if stations.has(walk_target) else "Walking to the lift · WASD takes over"
	if demo.lift != null and demo.lift.travelling():
		return "Lift in motion"
	var t := e_target()
	if not t.is_empty():
		if t.kind == "lift":
			return "Lift · E " + ("to the lower deck" if demo.active_level == 0 else "to the bridge")
		var st: Dictionary = stations[t.id]
		return "%s · E use" % st.name if st.active else "%s · offline (reserved)" % st.name
	if demo.active_level == 1:
		return "Decisions are made on the bridge · take the lift (E at the landing)"
	if not _aimed.is_empty():
		return "%s · click to walk there" % stations[_aimed].name
	return ""


# ------------------------------------------------------------------ the single entry

## The single decision entry (player panels, tests, the M4.5 bot). Returns true when the
## action ran; a refusal says why on the HUD's refusal card.
func use(id: String, action: String, arg: Variant = null) -> bool:
	if not stations.has(id):
		return false
	var st: Dictionary = stations[id]
	if not st.active:
		demo.refuse("The %s is offline (reserved for the crew)." % st.name)
		return false
	if not ACTIONS[id].has(action):
		return false
	if action == "open":
		if focused == id:
			return true
		if demo.active_level != 0:
			demo.refuse("Decisions are made on the bridge: take the lift.")
			return false
		var reach := in_reach(demo.avatar_pos, captain_forward())
		var near := false
		for m: Dictionary in st.meshes:
			near = near or footprint_distance(m.box, demo.avatar_pos) <= REACH_M
		if not near:
			demo.refuse("Walk to the %s first (Tab · Walk to)." % st.name)
			return false
		focus(id, reach.get("mesh", "") if reach.get("id", "") == id else "")
		used.emit(id, action)
		return true
	if focused != id:
		demo.refuse("Use the %s first." % st.name)
		return false
	var ok := _act(id, action, arg)
	if ok:
		used.emit(id, action)
	_refresh_panel()
	return ok


func _act(id: String, action: String, arg: Variant) -> bool:
	match [id, action]:
		["voyage", "begin"]:
			return demo.start_solar_departure()
		["navigation", "sgr_a"]:
			var ok: bool = demo.start_black_hole()
			_refresh_panel()
			return ok
		["navigation", "approach"]:
			return demo.bh_next_stop()
		["navigation", "leave"]:
			if demo.black_hole == null:
				return false
			demo.leave_black_hole()
			return true
	var map: GalaxyMap = demo.journey_map
	if map == null or demo.black_hole != null:
		demo.refuse("Navigation is for flat space: leave Sgr A* first.")
		return false
	if map.guided_read_only:
		demo.refuse("The guided voyage owns the course; it plots and commits each leg itself.")
		return false
	match action:
		"select":
			if str(arg) == "Sol":
				map.plan_home()
				return true
			var i: int = map.index_of(str(arg))
			if i >= 0:
				return map.select(i)
			map.plan_body(str(arg))
			return true
		"speed":
			map.set_cruise_phi(float(arg))
			return true
		"home":
			map.plan_home()
			return true
		"cancel":
			map.press_cancel()
			return true
		"commit":
			# The completed confirm: the map's own commit dialog on the sim's current plan.
			if not map.open_commit_dialog():
				demo.refuse("Plot a course first: select a star, Sol or a body, then commit.")
				return false
			return map.hold_commit(GalaxyMap.HOLD_S)
	return false


# ------------------------------------------------------------------ focus and the dolly

## The camera's pose framing a console screen: in front of the mesh, on the captain's side,
## looking down onto its face.
func focus_pose(mesh_name: String) -> Transform3D:
	var m := _mesh(mesh_name)
	var c: Vector3 = m.box.get_center()
	var top := Vector3(c.x, m.box.end.y, c.z)
	var sid: String = mesh_station.get(mesh_name, "")
	if stations.has(sid) and stations[sid].has("screen") and STATIONS[sid].walk == mesh_name:
		top = stations[sid].screen # frame the station's screen
	var out := Vector3(m.use.x - c.x, 0.0, m.use.z - c.z)
	if out.length() < 1e-3:
		out = Vector3(demo.avatar_pos.x - c.x, 0.0, demo.avatar_pos.z - c.z)
	out = out.normalized()
	var eye := top + out * 1.25 + Vector3.UP * 0.55
	return Transform3D(Basis.looking_at(top - eye + Vector3.UP * -0.1, Vector3.UP), eye)


func _mesh(mesh_name: String) -> Dictionary:
	for id: String in stations:
		for m: Dictionary in stations[id].meshes:
			if m.name == mesh_name:
				return m
	return {}


func focus(id: String, mesh_name := "") -> void:
	cancel_walk()
	if mesh_name.is_empty():
		var best := INF
		for m: Dictionary in stations[id].meshes:
			var d := footprint_distance(m.box, demo.avatar_pos)
			if d < best:
				best = d
				mesh_name = m.name
	focused = id
	focus_mesh = mesh_name
	if not used_once:
		used_once = true
		set_glow(false)
		demo.ship_hud.hint.visible = false
	_eye = {"tilt": demo.camera.tilt, "yaw": demo.camera.yaw, "pullback": demo.camera.pullback}
	var to := focus_pose(mesh_name)
	_dolly = {"from": demo.camera.global_transform, "to": to, "t": 0.0, "back": false}
	demo.camera_mode = "console"
	demo.camera.pullback = 0.0
	_cancel_confirm()
	_open_panel(id)


## Step back: the camera dollies back to the captain's eye; the panel closes.
func leave() -> void:
	if focused.is_empty():
		return
	var id := focused
	focused = ""
	_cancel_confirm()
	_close_panel(id)
	var from: Transform3D = demo.camera.global_transform
	demo.camera.follow(demo.avatar_pos, _eye.get("tilt", -18.0), _eye.get("yaw", demo.camera.yaw), 0.0)
	var to: Transform3D = demo.camera.global_transform
	demo.camera.global_transform = from
	_dolly = {"from": from, "to": to, "t": 0.0, "back": true}


func dolly_active() -> bool:
	return not _dolly.is_empty()


# ------------------------------------------------------------------ walking

## Walk to a station's use point along WalkArea.path (3.5 m/s, the WASD speed). From the
## lower deck it walks to the lift landing and says decisions need the bridge.
func walk_to(id: String) -> bool:
	if not stations.has(id) or not focused.is_empty() or demo.lift.travelling():
		return false
	var target: Vector3
	if demo.active_level != 0:
		target = demo.lift.BOARD_POINT
		target.y = 57.0
		walk_target = "lift"
		demo.note("Decisions are made on the bridge: take the lift (E at the landing).")
	else:
		target = stations[id].use
		walk_target = id
	walking = demo.walk.path(demo.avatar_pos, target)
	if walking.is_empty():
		walk_target = ""
		demo.refuse("No walkable path to the %s from here." % stations[id].name)
		return false
	demo.camera_mode = "player"
	return true


func cancel_walk() -> void:
	walking = PackedVector3Array()
	walk_target = ""


func _advance_walk(dt: float) -> void:
	if walking.is_empty():
		return
	var budget := WALK_SPEED_MPS * dt
	while budget > 0.0 and not walking.is_empty():
		var next: Vector3 = walking[0]
		var flat := Vector3(next.x - demo.avatar_pos.x, 0.0, next.z - demo.avatar_pos.z)
		var d := flat.length()
		if d <= budget:
			demo.avatar_pos = Vector3(next.x, next.y, next.z)
			walking.remove_at(0)
			budget -= d
		else:
			var p: Vector3 = demo.avatar_pos + flat / d * budget
			demo.avatar_pos = Vector3(p.x, demo.walk.height_at(p.x, p.z) if not is_nan(demo.walk.height_at(p.x, p.z)) else demo.avatar_pos.y, p.z)
			demo.camera.yaw = atan2(flat.z, flat.x)
			budget = 0.0
	if walking.is_empty():
		var id := walk_target
		walk_target = ""
		if stations.has(id):
			face(id)


## Turn the captain to face a station's walk mesh.
func face(id: String) -> void:
	var m := _mesh(STATIONS[id].walk)
	if m.is_empty():
		return
	var c: Vector3 = m.box.get_center()
	demo.camera.yaw = atan2(c.z - demo.avatar_pos.z, c.x - demo.avatar_pos.x)
	demo.camera.tilt = -18.0
	demo.camera_mode = "player"


## Tests and tools: stand at a station's use point, facing it (no walking time).
func go_to(id: String) -> void:
	cancel_walk()
	demo.avatar_pos = stations[id].use
	face(id)
	demo.camera.follow(demo.avatar_pos, demo.camera.tilt, demo.camera.yaw, 0.0)


## The console a canvas point is on (camera ray against the console collision), or "".
func station_at(canvas_point: Vector2) -> String:
	var px: Vector2 = demo.get_viewport().get_stretch_transform() * canvas_point
	var cam: Camera3D = demo.camera
	var from := cam.project_ray_origin(px)
	var q := PhysicsRayQueryParameters3D.create(from, from + cam.project_ray_normal(px) * 80.0)
	var hit: Dictionary = cam.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty() or hit.collider == null:
		return ""
	var n: Node = hit.collider
	while n != null and not mesh_station.has(String(n.name)):
		n = n.get_parent()
	return mesh_station.get(String(n.name), "") if n != null else ""


## A click: use the console in reach, else walk to it.
func click(canvas_point: Vector2) -> bool:
	if not focused.is_empty() or demo.active_level != 0:
		return false
	var id := station_at(canvas_point)
	if id.is_empty():
		return false
	for m: Dictionary in stations[id].meshes:
		if footprint_distance(m.box, demo.avatar_pos) <= REACH_M:
			return use(id, "open")
	if not stations[id].active:
		demo.refuse("The %s is offline (reserved for the crew)." % stations[id].name)
		return true
	return walk_to(id)


func aim(canvas_point: Vector2) -> void:
	_aimed = "" if not focused.is_empty() or demo.active_level != 0 else station_at(canvas_point)
	if not _aimed.is_empty() and not stations[_aimed].active:
		_aimed = ""


# ------------------------------------------------------------------ confirm (§C4)

## A confirm button for an irreversible action. Hold mode: hold 1.5 s; releasing restarts
## with no penalty. Press-twice mode: the first press relabels it "Confirm: <label>", the
## second runs it; Esc backs out. No deadline in either mode (NT2, NT3).
func confirm_button(id: String, action: String, label: String) -> Button:
	var b := Button.new()
	b.text = label + (" (hold)" if confirm_mode == "hold" else "")
	b.name = "Confirm_" + action
	b.button_down.connect(func() -> void: confirm_press(id, action, label, b))
	b.button_up.connect(func() -> void: confirm_release())
	return b


func confirm_press(id: String, action: String, label := "", button: Button = null) -> bool:
	if confirm_mode == "twice":
		if _confirm.get("armed", false) and _confirm.action == action:
			_cancel_confirm()
			return use(id, action)
		_cancel_confirm()
		_confirm = {"id": id, "action": action, "armed": true, "holding": false, "held_s": 0.0, "button": button, "label": label}
		if button != null:
			button.text = "Confirm: " + label
		return false
	_confirm = {"id": id, "action": action, "armed": false, "holding": true, "held_s": 0.0, "button": button, "label": label}
	return false


func confirm_release() -> void:
	if confirm_mode == "hold" and not _confirm.is_empty():
		_confirm.holding = false
		_confirm.held_s = 0.0
		_set_confirm_progress(0.0)


func confirm_armed() -> bool:
	return _confirm.get("armed", false)


func confirm_held_s() -> float:
	return _confirm.get("held_s", 0.0)


func _cancel_confirm() -> void:
	if not _confirm.is_empty() and _confirm.get("button") != null and is_instance_valid(_confirm.button):
		(_confirm.button as Button).text = _confirm.label + (" (hold)" if confirm_mode == "hold" else "")
	_confirm = {}


func _set_confirm_progress(f: float) -> void:
	if not _confirm.is_empty() and _confirm.get("button") != null and is_instance_valid(_confirm.button):
		(_confirm.button as Button).text = _confirm.label + (" (hold %d%%)" % int(f * 100.0) if f > 0.0 else " (hold)")


func set_confirm_mode(mode: String) -> void:
	confirm_mode = mode if mode in ["hold", "twice"] else "hold"
	_cancel_confirm()
	if demo.journey_map != null:
		demo.journey_map.set_confirm_twice(confirm_mode == "twice")
	_refresh_panel()


## Esc while a press-twice confirm is armed backs out of it (and nothing else).
func escape() -> bool:
	if focused == "navigation" and demo.journey_map != null and demo.journey_map.armed:
		demo.journey_map.disarm()
		return true
	if confirm_armed():
		_cancel_confirm()
		return true
	if not focused.is_empty():
		leave()
		return true
	return false


# ------------------------------------------------------------------ the fake clock

func advance(dt: float) -> void:
	dt = maxf(dt, 0.0)
	now_s += dt
	if not _dolly.is_empty():
		_dolly.t = minf(1.0, _dolly.t + dt / DOLLY_S)
		var s: float = _dolly.t * _dolly.t * (3.0 - 2.0 * _dolly.t)
		var a: Transform3D = _dolly.from
		var b: Transform3D = _dolly.to
		demo.camera.global_transform = Transform3D(a.basis.slerp(b.basis, s), a.origin.lerp(b.origin, s))
		if _dolly.t >= 1.0:
			if _dolly.back:
				demo.camera_mode = "player"
			_dolly = {}
	_advance_walk(dt)
	if _confirm.get("holding", false):
		_confirm.held_s += dt
		_set_confirm_progress(minf(1.0, _confirm.held_s / HOLD_S))
		if _confirm.held_s >= HOLD_S:
			var c := _confirm
			_confirm = {}
			use(c.id, c.action)
	if not _glow.is_empty():
		var a := 0.18 + 0.14 * sin(now_s * TAU / 2.4)
		for g in _glow:
			(g[1] as StandardMaterial3D).albedo_color.a = a
	_refresh_screens()


# ------------------------------------------------------------------ onboarding glow

## The Voyage console and the navigation station glow softly until the first console use
## (a display cue, not a timer: it ends only on use).
func set_glow(on: bool) -> void:
	for g in _glow:
		(g[0] as MeshInstance3D).material_overlay = null
	_glow = []
	if not on:
		return
	for id in ["voyage", "navigation"]:
		for m: Dictionary in stations[id].meshes:
			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			mat.albedo_color = Color(0.35, 0.75, 1.0, 0.2)
			(m.node as MeshInstance3D).material_overlay = mat
			_glow.append([m.node, mat])


func glowing() -> bool:
	return not _glow.is_empty()


# ------------------------------------------------------------------ idle screens (display only)

func _build_screens() -> void:
	for id: String in stations:
		var st: Dictionary = stations[id]
		if st.meshes.is_empty():
			continue
		var m: Dictionary = _mesh(STATIONS[id].walk)
		var vp := SubViewport.new()
		vp.size = Vector2i(384, 128)
		vp.transparent_bg = false
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var bg := ColorRect.new()
		bg.color = Color(0.02, 0.05, 0.09) if st.active else Color(0.01, 0.01, 0.012)
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vp.add_child(bg)
		var l := Label.new()
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 26)
		l.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0) if st.active else Color(0.3, 0.32, 0.36))
		vp.add_child(l)
		add_child(vp)
		var quad := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.84, 0.28)
		quad.mesh = qm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_texture = vp.get_texture()
		quad.material_override = mat
		quad.name = "IdleScreen_" + id
		var c: Vector3 = m.box.get_center()
		var out := Vector3(m.use.x - c.x, 0.0, m.use.z - c.z)
		out = out.normalized() if out.length() > 1e-3 else Vector3(1, 0, 0)
		# On the console's face toward its use point, at about chest height.
		var half: float = absf(out.x) * m.box.size.x * 0.5 + absf(out.z) * m.box.size.z * 0.5
		# A rotated console's axis-aligned box overstates its depth: stay well in front of the
		# captain's use point.
		half = minf(half, Vector2(m.use.x - c.x, m.use.z - c.z).length() - 1.0)
		var pos: Vector3 = Vector3(c.x, m.box.position.y + minf(1.3, m.box.size.y * 0.75), c.z) + out * (half + 0.04)
		demo.geometry.add_child(quad)
		quad.global_transform = Transform3D(Basis.looking_at(-out, Vector3.UP), pos)
		screens[id] = {"viewport": vp, "label": l, "text": "", "quad": quad}
		st["screen"] = pos
	_refresh_screens()


func screen_text(id: String) -> String:
	if not stations[id].active:
		return "offline"
	match id:
		"navigation":
			if demo.black_hole != null:
				var nl: String = demo.black_hole.next_label()
				return "Sgr A*\n" + ("next: " + nl if not nl.is_empty() else "last stop reached")
			if demo.live_journey:
				return "→ " + demo.stop_name()
			if demo.solar_tour != null:
				return "Guided voyage holds the course"
			return "No course set" if demo.journey_map == null or demo.journey_map.journey_state() != "planned" else "Course plotted · commit here"
		"voyage":
			if demo.solar_tour != null:
				return "Guided voyage\n" + ("→ " + demo.solar_tour.leg_name() if demo.live_journey else "at " + demo.solar_tour.leg_name())
			return "Guided voyage ready"
		"archive":
			var u: Variant = GalaxyMap.field_value(demo.sky_world, "consequence.archive.unlocked") if demo.sky_world is Dictionary else null
			return "Archive\n%s entries open" % (str(u.size()) if u is Array else "no")
	return ""


func _refresh_screens() -> void:
	for id: String in screens:
		var t := screen_text(id)
		if t != screens[id].text:
			screens[id].text = t
			(screens[id].label as Label).text = t
			(screens[id].viewport as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE


# ------------------------------------------------------------------ the focused panel

func _build_panel() -> void:
	panel_layer.layer = 14
	add_child(panel_layer)
	panel.name = "ConsolePanel"
	panel.visible = false
	panel.add_theme_stylebox_override("panel", ShipHud._panel_style(0.94))
	panel_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	panel_title.add_theme_font_size_override("font_size", 18)
	panel_title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(panel_title)
	step_back.text = "Step back [Esc]"
	step_back.focus_mode = Control.FOCUS_NONE
	step_back.pressed.connect(leave)
	head.add_child(step_back)
	panel_body.add_theme_constant_override("separation", 6)
	panel_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(panel_body)


## The panel's rect: below the status strip, left of the card column, above the prompt.
## The navigation station's map takes the full width (the cards wait under it).
func panel_rect() -> Rect2:
	var hud: ShipHud = demo.ship_hud
	var top := hud.strip_bottom() + 8.0
	var right := hud.size.x - ShipHud.MARGIN if focused == "navigation" else hud.column.position.x - ShipHud.MARGIN
	return Rect2(Vector2(ShipHud.MARGIN, top), Vector2(maxf(240.0, right - ShipHud.MARGIN), maxf(160.0, hud.size.y - top - 64.0)))


func _open_panel(id: String) -> void:
	panel_title.text = stations[id].name
	panel.visible = true
	_refresh_panel()
	_layout_panel()
	_layout_panel.call_deferred() # wrapped labels know their height a frame later


## The helm and the Archive take the whole region; the Voyage console's panel is compact
## at the left, so its console stays in view beside it.
func _layout_panel() -> void:
	var r := panel_rect()
	panel.position = r.position
	if focused == "voyage":
		panel.custom_minimum_size = Vector2(minf(r.size.x * 0.42, 420.0), 0.0)
		panel.size = Vector2(panel.custom_minimum_size.x, panel.get_combined_minimum_size().y)
	else:
		panel.custom_minimum_size = r.size
		panel.size = r.size


func _close_panel(id: String) -> void:
	panel.visible = false
	for c in panel_body.get_children():
		panel_body.remove_child(c)
		c.queue_free()
	if id == "navigation":
		demo.close_navigation()
	if id == "archive" and demo.codex != null:
		demo.codex.close()
		(demo.codex.get_parent() as CanvasLayer).layer = 13


func _label(text: String, size := 14, color := Color(0.86, 0.9, 0.98)) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Rebuild the focused panel's body for the current state.
func _refresh_panel() -> void:
	if focused.is_empty() or not panel.visible:
		return
	for c in panel_body.get_children():
		panel_body.remove_child(c)
		c.queue_free()
	_cancel_confirm()
	match focused:
		"navigation":
			_navigation_panel()
		"voyage":
			_voyage_panel()
		"archive":
			_archive_panel()


func _navigation_panel() -> void:
	if demo.black_hole != null:
		demo.close_navigation()
		panel_body.add_child(_label("Sgr A* · the stop ladder", 15))
		var bh = demo.black_hole
		var stops: Array = BlackHoleVisit.STOPS
		for i in stops.size():
			var mark := "✓ " if i < bh.stops_taken else ("→ " if i == bh.stops_taken else "· ")
			panel_body.add_child(_label(mark + str(stops[i].label), 13, Color(0.7, 0.75, 0.85) if i < bh.stops_taken else Color(0.86, 0.9, 0.98)))
		var row := HFlowContainer.new()
		panel_body.add_child(row)
		var nl: String = bh.next_label()
		if not nl.is_empty() and not bh.approaching():
			row.add_child(confirm_button("navigation", "approach", nl))
		elif bh.approaching():
			panel_body.add_child(_label("Approach under way · K finishes it (pacing).", 13))
		row.add_child(confirm_button("navigation", "leave", "Leave Sgr A*"))
		return
	panel_body.add_child(_label("Plot on the map (a star, Sol, a body here), set the speed, then commit. M is the read-only chart.", 13, Color(0.7, 0.75, 0.85)))
	demo.open_navigation()


func _voyage_panel() -> void:
	panel_body.add_child(_label("The guided voyage (D-46, D-47, D-49)", 15))
	panel_body.add_child(_label(ITINERARY, 14))
	panel_body.add_child(_label("Each leg is flown in real time; at each stop the ship turns to show the body and holds for a dwell. Pause (P), Skip dwell (N) and Skip stage (K) only change how fast you watch.", 13, Color(0.7, 0.75, 0.85)))
	if demo.solar_tour != null:
		panel_body.add_child(_label("Under way: " + demo.tour_line(), 14))
		return
	panel_body.add_child(_label("A new voyage replaces the current navigation session. It cannot be undone.", 13, Color(0.95, 0.6, 0.4)))
	panel_body.add_child(confirm_button("voyage", "begin", "Begin guided voyage"))


func _archive_panel() -> void:
	demo._ensure_codex()
	var world: Dictionary = demo.sky_world if demo.sky_world is Dictionary else {}
	demo.codex.show_world(world)
	demo.codex.open()
	(demo.codex.get_parent() as CanvasLayer).layer = panel_layer.layer + 1 # over the console panel
	var r := panel_rect()
	var p: PanelContainer = demo.codex.panel
	p.custom_minimum_size = Vector2(r.size.x - 24.0, r.size.y - 92.0)
	p.position = r.position + Vector2(12.0, 84.0)
	p.size = p.custom_minimum_size
	var news := HBoxContainer.new()
	news.add_theme_constant_override("separation", 12)
	panel_body.add_child(news)
	var nl := _label("News and legacy log", 14)
	nl.autowrap_mode = TextServer.AUTOWRAP_OFF
	news.add_child(nl)
	for spec in [["legacy entries", "consequence.legacy.count", "%d"], ["latest news from", "consequence.news.star_id", "%s"]]:
		var cap := _label(spec[0], 12, Color(0.62, 0.68, 0.8))
		cap.autowrap_mode = TextServer.AUTOWRAP_OFF
		news.add_child(cap)
		var b := DisplayBinding.new().bind(spec[1], spec[2])
		b.update_from(world)
		news.add_child(b)
