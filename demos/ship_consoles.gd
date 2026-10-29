class_name ShipConsoles
extends Node
## R1-SHIP-UI (D-56, D-57) §B-§C: the bridge consoles decide. Every captain decision (plot,
## set speed, commit, cancel, approach, leave, the guided voyage, the Archive) is made at a
## console of ship.glb: walk there (WASD, click-to-walk, or Tab "Walk to"), E or click to
## use it, the camera eases to a framed panel (D-57 Q4; R2-CAMERA D4: through the CameraDirector, which
## remembers the zoom level), Esc or E steps back to that level.
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
const DOLLY_S := 0.6 # the director's "console" view ease (data/camera/views.json)
## D-115 (Mark, 2026-10-21): the captain walks calmly. 1.3 m/s is an unhurried adult walk; the painted
## walk cycle (art/captain-anim-v3) is drawn for it. No positional ease: the start and stop clips carry it.
const WALK_SPEED_MPS := 1.3
const PATH_CEILING_M := 40.0
const HOLD_S := 1.5
const CHAIR_REACH_M := 2.6 ## the chair's E reach from its seat point: the walk keeps 0.5 m clear of the chair, so the nearest
## walkable point is 1.9-2.2 m from the seat (measured round it, CA2)
## The stations, from ship.glb node names (§B, D-57 Q5). The navigation station is the arc
## of three consoles; "walk" names the mesh Walk-to aims for.
const STATIONS := {
	"navigation": {"name": "Navigation station", "meshes": ["console_navigation_0", "console_navigation_1", "console_navigation_2"], "walk": "console_navigation_1", "active": true},
	"voyage": {"name": "Voyage console", "meshes": ["console_decision_0"], "walk": "console_decision_0", "active": true},
	"archive": {"name": "Archive terminal", "meshes": ["archive_terminal"], "walk": "archive_terminal", "active": true},
	"crew": {"name": "Crew console", "meshes": ["console_decision_1"], "walk": "console_decision_1", "active": true}, # crew-work W1 (Mark 2026-10-14)
	"reserved_2": {"name": "Crew console", "meshes": ["console_decision_2"], "walk": "console_decision_2", "active": false},
	"reserved_3": {"name": "Crew console", "meshes": ["console_decision_3"], "walk": "console_decision_3", "active": false},
}
## Actions use() accepts per station (ShipControls.CONSOLE names each decision's action).
const ACTIONS := {
	"navigation": ["open", "select", "speed", "commit", "cancel", "home", "sgr_a", "approach", "leave"],
	"voyage": ["open", "begin"],
	"crew": ["open"],
	"archive": ["open", "news", "log", "ask", "codex"], # D-66 H2 + D-68: news from home and this voyage's log; starting over is the title screen's New game, never a console. R1-ARCHIVE-VOICE: ask the Archive; codex returns to the entries
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
var _open_on_arrival := "" # D-132: finish the short real approach before reaching onto a low desk
var _confirm := {} # {id, action, held_s, holding, armed, button, label}
var _aimed := ""
var _glow: Array = [] # [MeshInstance3D, StandardMaterial3D]
var screens := {} # station -> {viewport, label, text}
var panel_layer := CanvasLayer.new()
# D-66 H2: the news from home and the legacy log, read at the Archive terminal (M4.4's panels).
var news_panel: NewsPanel
var legacy_screen: LegacyScreen
var _reading_layer: CanvasLayer
## R1-ARCHIVE-VOICE: the question in flight and its answer; the field and the answer panel.
var archive_ask := ArchiveAsk.new()
var ask_field: LineEdit
var ask_button: Button
var answer_panel: PanelContainer
var answer_question: Label
var answer_text: Label
var panel := PanelContainer.new()
var panel_title := Label.new()
var panel_body := VBoxContainer.new()
## R2-CREW C6, R2-CREW-CONSOLE-V2 V3: the Crew console (only while a crew is aboard, protocol 2.11):
## the roster board and the two-panel call (ui/crew_console.gd). It persists across refreshes, so a
## pending confirm and an open call survive them.
var crew_console: CrewConsole
var crew_summary: Label ## the Voyage console's one-line crew summary (crew-work W1)
var _crew_sim: SimBridge
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
			var authored: Variant = authored_use(demo.manifest, id) if mesh_name == spec.walk else null
			if authored is Vector3:
				# R2-DECK-LAYOUT §D2: the operator point authored in Blender (INTERACT_<id>_use), so
				# "faces the bow" is a property of the asset.
				use = demo.walk_bridge.closest_walkable(authored, 1.0)
			else:
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


## A station's authored operator point (glTF), from the manifest's stations.<id>.use_m (ship
## metres; R2-DECK-LAYOUT §D2), else null (the closest-walkable rule).
static func authored_use(manifest: Dictionary, id: String) -> Variant:
	var u: Variant = manifest.get("stations", {}).get(id, {}).get("use_m")
	if u is Array and (u as Array).size() == 2:
		return Vector3(float(u[0]), 82.0, -float(u[1]))
	return null


## Walked path length from the bridge spawn to each station's use point (AC8; printed by
## the console test, 40 m ceiling).
func path_length(id: String) -> float:
	var spawn: Vector3 = demo.bridge_spawn()
	var p: PackedVector3Array = demo.walk_bridge.path(spawn, stations[id].use)
	if p.is_empty():
		return -1.0
	var length := spawn.distance_to(p[0])
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


## The captain's facing (R2-CAMERA: separate from the camera's yaw, which the director owns).
func captain_forward() -> Vector3:
	var yaw: float = demo.captain_yaw
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
	# CA2 (OQ9): the captain's chair, from its walkable side (the bridge only).
	if demo.active_level == 0 and demo.has_method("chair_seat"):
		var seat: Variant = demo.chair_seat()
		if seat is Vector3:
			var dc: float = Vector2(demo.avatar_pos.x - seat.x, demo.avatar_pos.z - seat.z).length()
			if dc <= CHAIR_REACH_M and (best.is_empty() or dc < best.d):
				best = {"kind": "chair", "id": "chair", "d": dc}
	return best


func press_e() -> bool:
	if focused != "":
		leave()
		return true
	if demo.has_method("seated") and demo.seated():
		return demo.stand_chair()
	var t := e_target()
	if t.is_empty():
		return false
	if t.kind == "lift":
		return demo.lift.board()
	if t.kind == "chair":
		return demo.sit_chair()
	return use(t.id, "open")


func prompt_text() -> String:
	if focused != "":
		return "%s · E or Esc steps back" % stations[focused].name
	if demo.has_method("seated") and demo.seated():
		return "Captain's chair · E or a move key stands"
	if not walk_target.is_empty():
		if walk_target.begins_with("point:"):
			return "Walking to the %s · WASD takes over" % walk_target.trim_prefix("point:")
		return "Walking to the %s · WASD takes over" % stations[walk_target].name if stations.has(walk_target) else "Walking to the lift · WASD takes over"
	if demo.lift != null and demo.lift.travelling():
		return "Lift in motion"
	var t := e_target()
	if not t.is_empty():
		if t.kind == "lift":
			return "Lift · E " + ("to the lower deck" if demo.active_level == 0 else "to the bridge")
		if t.kind == "chair":
			return "Captain's chair · E sit"
		var st: Dictionary = stations[t.id]
		return "%s · E use" % st.name if st.active else "%s · offline (reserved)" % st.name
	if demo.active_level == 1:
		return ""
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
		if not focused.is_empty(): # another station's panel closes first (the bot can switch)
			var was := focused
			focused = ""
			_cancel_confirm()
			_close_panel(was)
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
		# E/click may be in reach while still away from the working edge. Walk the physical
		# captain into place before playing a contact pose or opening the console panel.
		if id in ["voyage", "crew"] and demo.avatar_pos.distance_to(st.use) > 0.025:
			if not walk_to(id):
				return false
			_open_on_arrival = id
			return true
		if id in ["voyage", "crew"]:
			face(id)
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
		["archive", "news"]:
			var w: Dictionary = demo.sky_world if demo.sky_world is Dictionary else {}
			if not NewsPanel.new().has_news(w):
				demo.refuse("No news from home has reached the ship yet.")
				return false
			_reading().show_world(w); news_panel.open(); legacy_screen.visible = false; answer_panel.visible = false
			if demo.journey_sim != null and demo.journey_sim.ai_relay is AiRelay:
				news_panel.request_ai(demo.journey_sim.ai_relay, w)
			return true
		["archive", "ask"]:
			var q: String = ask_field.text if ask_field != null else ""
			var relay: AiRelay = demo.ai_session.relay if demo.get("ai_session") != null else null
			var w: Dictionary = demo.sky_world if demo.sky_world is Dictionary else {}
			var where: String = "" if demo.live_journey or demo.journey_sim == null else demo.stop_name()
			if archive_ask.state == "waiting":
				demo.refuse("The Archive is still answering.")
				return false
			if not archive_ask.ask(q, relay, w, where):
				demo.refuse("Ask the Archive a question first.")
				return false
			if archive_ask.state == "offline":
				# Out of world, in the HUD's own voice (D-56): the in-world line stays on the terminal.
				demo.note("Live AI is off: switch it on in the AI indicator, with a key, to hear the Archive answer.")
			follow(demo.journey_sim)
			_reading(); news_panel.close(); legacy_screen.visible = false
			_show_answer()
			return true
		["archive", "log"]:
			_reading(); news_panel.close(); answer_panel.visible = false
			legacy_screen.show_world(demo.sky_world if demo.sky_world is Dictionary else {})
			legacy_screen.visible = true
			_fit_archive() # show_world re-centres the log; it belongs over the codex like the others
			return true
		["archive", "codex"]:
			# Back to the entries from news, the log or an answer (the answer stays for later).
			if news_panel != null:
				news_panel.close(); legacy_screen.visible = false; answer_panel.visible = false
			return true
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
	# The sim answers attempts against a committed course, without advancing the journey.
	if map.journey_state() == "committed" and action in ["select", "cancel", "commit"]:
		if action == "select" and map.index_of(str(arg)) < 0: return false
		var intent: Dictionary = map.plan_intent(map.index_of(str(arg))) if action == "select" else {"k": action}
		if action == "commit": intent["plan_id"] = int(demo.journey_sim.world.journey.plan_id)
		var ok: bool = demo.journey_sim.send([intent], 0.0)
		if ok: demo._apply_journey_world()
		return ok
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
	demo.director.focus_console(focus_pose(mesh_name))
	demo.camera_mode = "console"
	_cancel_confirm()
	_open_panel(id)


## Step back: the camera eases back to the remembered level and sector view; the panel closes.
func leave() -> void:
	if focused.is_empty():
		return
	var id := focused
	focused = ""
	_cancel_confirm()
	if id == "crew" and crew_console != null: # stepping back ends a call and disarms (V3)
		crew_console.armed = ""
		crew_console.call_id = ""
	_close_panel(id)
	demo.director.restore()


func dolly_active() -> bool:
	return demo.director.blending()


# ------------------------------------------------------------------ walking

## Walk to a station's use point along WalkArea.path (WALK_SPEED_MPS, the WASD speed). From the
## lower deck it walks to the lift landing and says decisions need the bridge.
func walk_to(id: String) -> bool:
	if not stations.has(id) or not focused.is_empty() or demo.lift.travelling():
		return false
	cancel_walk()
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


## R2-CAMERA C2: walk to a point on the bridge (a sky view's anchor), same path and speed; WASD
## takes over. The walk target reads "point:<label>".
func walk_to_point(target: Vector3, label: String) -> bool:
	if not focused.is_empty() or demo.lift.travelling() or demo.active_level != 0:
		return false
	cancel_walk()
	walking = demo.walk.path(demo.avatar_pos, target)
	if walking.is_empty():
		return false
	walk_target = "point:" + label
	demo.camera_mode = "player"
	return true


func cancel_walk() -> void:
	walking = PackedVector3Array()
	walk_target = ""
	_open_on_arrival = ""


func _advance_walk(dt: float) -> void:
	if walking.is_empty():
		return
	var budget := WALK_SPEED_MPS * dt
	while budget > 0.0 and not walking.is_empty():
		var next: Vector3 = walking[0]
		var flat := Vector3(next.x - demo.avatar_pos.x, 0.0, next.z - demo.avatar_pos.z)
		var d := flat.length()
		var at_endpoint := d <= budget
		var p: Vector3 = next if at_endpoint else demo.avatar_pos + flat / d * budget
		# Execute on the surface reachable from this segment's current floor. A terrace
		# overhead is never an auto-walk destination merely because it is the highest hit.
		var floor_y: float = demo.walk.height_at_near(p.x, p.z, demo.avatar_pos.y)
		if is_nan(floor_y) or (at_endpoint and absf(floor_y - next.y) > WalkArea.STEP_M):
			cancel_walk()
			return
		demo.avatar_pos = Vector3(p.x, floor_y, p.z)
		if at_endpoint:
			walking.remove_at(0)
			budget -= d
		else:
			demo.captain_yaw = atan2(flat.z, flat.x)
			budget = 0.0
	if walking.is_empty():
		var id := walk_target
		var open_after_walk := _open_on_arrival == id and not id.is_empty()
		walk_target = ""
		_open_on_arrival = ""
		if stations.has(id):
			face(id)
			if open_after_walk:
				use(id, "open")


## Turn the captain to face a station's walk mesh.
func face(id: String) -> void:
	var m := _mesh(STATIONS[id].walk)
	if m.is_empty():
		return
	var c: Vector3 = m.box.get_center()
	demo.captain_yaw = atan2(c.z - demo.avatar_pos.z, c.x - demo.avatar_pos.x)
	demo.camera.yaw = demo.captain_yaw # the developer free camera / tools' eye faces it too
	demo.camera.tilt = -18.0
	demo.camera_mode = "player"


## Tests and tools: stand at a station's use point, facing it (no walking time).
func go_to(id: String) -> void:
	cancel_walk()
	demo.avatar_pos = stations[id].use
	face(id)
	if demo.director.overridden:
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
	if archive_ask.check_timeout():
		_show_answer()
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
		var l := ComposedBinding.new() if id in ["archive", "crew"] else Label.new()
		l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_size_override("font_size", 26)
		l.theme = StapledonTheme.theme() # the screen's own viewport: the theme set on the label (R2-BRIDGE-STYLE ST4)
		l.theme_type_variation = "HUDAccent" if st.active else "HUDDisabled"
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
		# The screen belongs to its authored housing; a closer working point must not bury it.
		var screen: Variant = demo.manifest.get("stations",{}).get(id,{}).get("screen_ship_m")
		if screen is Array and screen.size()==3 and screen.all(func(value: Variant)->bool:return (value is float or value is int) and is_finite(float(value))):
			pos = ShipFrame.gltf_from_structure(screen)
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
		"crew":
			var sim = demo.get("journey_sim") if demo != null else null
			var c: Dictionary = (sim as SimBridge).crew if sim is SimBridge else {}
			if c.is_empty():
				return "Crew console\nno crew aboard yet"
			if not c.get("holds", []).is_empty():
				return "Crew console\nneeds you"
			return "Crew console\n%s working" % DisplayBinding.format_field(crew_screen_view(), "client.crew.working", "%d")
		"archive":
			var view := archive_screen_view()
			return "Archive\n%s entries open" % DisplayBinding.format_field(view, "client.archive.unlocked_count", archive_count_format(view))
	return ""


func archive_screen_view() -> Dictionary:
	var unlocked: Variant = GalaxyMap.field_value(demo.sky_world, "consequence.archive.unlocked") if demo.sky_world is Dictionary else null
	return {"client": {"archive": {"unlocked_count": unlocked.size() if unlocked is Array else "no", "empty": ""}}}


## The Crew console screen's count, as a bound field (the display audit traces it to the crew).
func crew_screen_view() -> Dictionary:
	var sim = demo.get("journey_sim") if demo != null else null
	var c: Dictionary = (sim as SimBridge).crew if sim is SimBridge else {}
	var working: int = c.get("members", []).filter(func(m): return m.get("work") is Dictionary and str(m["work"].get("status", "")) == "working").size()
	return {"client": {"crew": {"working": working, "status": "no crew aboard yet" if c.is_empty() else ("needs you" if not c.get("holds", []).is_empty() else ""), "empty": ""}}}


func archive_count_format(view: Dictionary) -> String:
	# JSON replay reads integer counts as floats; %d preserves the original size() text.
	return "%s" if view.client.archive.unlocked_count is String else "%d"


func _refresh_screens() -> void:
	for id: String in screens:
		var t := screen_text(id)
		if id == "archive":
			var binding := screens[id].label as ComposedBinding
			var view := archive_screen_view()
			binding.record_context = true
			binding.compose(["Archive\n", ["client.archive.unlocked_count", archive_count_format(view)], " entries open"] if stations[id].active else ["offline", ["client.archive.empty", "text"]])
			binding.update_from(view)
		if id == "crew":
			var binding := screens[id].label as ComposedBinding
			var view := crew_screen_view()
			binding.record_context = true
			var words: String = view.client.crew.status
			binding.compose(["offline", ["client.crew.empty", "text"]] if not stations[id].active else (["Crew console\n", ["client.crew.status", "%s"]] if not words.is_empty() else ["Crew console\n", ["client.crew.working", "%d"], " working"]))
			binding.update_from(view)
		if t != screens[id].text:
			screens[id].text = t
			if id not in ["archive", "crew"]: (screens[id].label as Label).text = t
			(screens[id].viewport as SubViewport).render_target_update_mode = SubViewport.UPDATE_ONCE


# ------------------------------------------------------------------ the focused panel

func _build_panel() -> void:
	panel_layer.layer = 14
	add_child(panel_layer)
	panel.name = "ConsolePanel"
	panel.visible = false
	panel.theme = StapledonTheme.theme()
	panel.theme_type_variation = "HUDSheet"
	panel_layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	panel_title.add_theme_font_size_override("font_size", 18)
	panel_title.theme_type_variation = "HUDCardTitle"
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
	if focused == "crew":
		return crew_panel_rect(hud.size, hud.strip_bottom())
	var top := hud.strip_bottom() + 8.0
	var right := hud.size.x - ShipHud.MARGIN if focused == "navigation" else hud.column.position.x - ShipHud.MARGIN
	return Rect2(Vector2(ShipHud.MARGIN, top), Vector2(maxf(240.0, right - ShipHud.MARGIN), maxf(160.0, hud.size.y - top - 64.0)))


## R2-CREW-CONSOLE-V2 V3: the Crew console takes the whole width under the HUD strip, as the helm
## does, and the height down to the prompt line (the board and the two-panel call both need it).
const CREW_BOTTOM := 24.0
static func crew_panel_rect(view: Vector2, strip_bottom: float) -> Rect2:
	var top := strip_bottom + 8.0
	return Rect2(Vector2(ShipHud.MARGIN, top), Vector2(maxf(240.0, view.x - 2.0 * ShipHud.MARGIN), maxf(160.0, view.y - top - CREW_BOTTOM)))


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
	elif focused == "crew":
		panel.custom_minimum_size = r.size
		panel.size = r.size
	else:
		panel.custom_minimum_size = r.size
		panel.size = r.size
	if focused == "archive":
		_fit_archive()


## The codex and the reading panels fill the Archive terminal below its two rows, laid out with
## the terminal (again a frame later, when the HUD strip above has its final height).
func _fit_archive() -> void:
	if demo.codex != null and demo.codex.panel != null:
		_fit_reading(demo.codex.panel)
	if news_panel != null:
		for c: Control in [news_panel, legacy_screen, answer_panel]:
			_fit_reading(c)


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
	if id == "archive" and news_panel != null:
		news_panel.close(); legacy_screen.visible = false; answer_panel.visible = false


## The news and legacy panels over the Archive terminal's panel (made once; M4.4's ui, unchanged).
func _reading() -> NewsPanel:
	if news_panel == null:
		_reading_layer = CanvasLayer.new(); _reading_layer.layer = panel_layer.layer + 2; add_child(_reading_layer)
		news_panel = NewsPanel.new(); _reading_layer.add_child(news_panel); news_panel.visible = false
		legacy_screen = LegacyScreen.new(); _reading_layer.add_child(legacy_screen)
		legacy_screen.build()
		legacy_screen.visible = false
		answer_panel = PanelContainer.new(); answer_panel.name = "ArchiveAnswer"; answer_panel.visible = false
		answer_panel.theme = StapledonTheme.theme(); answer_panel.theme_type_variation = "HUDSheet"
		var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 10); answer_panel.add_child(box)
		var head := _label("The Archive", 20); box.add_child(head)
		answer_question = _label("", 14, "HUDHint"); box.add_child(answer_question)
		answer_text = _label("", 17); box.add_child(answer_text)
		_reading_layer.add_child(answer_panel)
		_fit_archive()
	return news_panel


## Below the terminal's two rows (news and log; the reading buttons and Ask), over the codex.
const READING_TOP := 140.0


func _fit_reading(c: Control) -> void:
	var r := Rect2(panel.position, panel.size) if panel.visible and panel.size.y > 0.0 else panel_rect()
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.grow_horizontal = Control.GROW_DIRECTION_END # the log grows both ways from its centre otherwise
	c.grow_vertical = Control.GROW_DIRECTION_END
	c.custom_minimum_size = Vector2(r.size.x - 24.0, r.size.y - READING_TOP - 12.0)
	if c is LegacyScreen and (c as LegacyScreen).scroll != null: # its list scrolls inside the room left
		(c as LegacyScreen).scroll.custom_minimum_size = Vector2(c.custom_minimum_size.x - 32.0, maxf(48.0, c.custom_minimum_size.y - 110.0))
	c.size = c.custom_minimum_size
	c.position = r.position + Vector2(12.0, READING_TOP)


## The ship's journey session (each new one): its steps feed the Voyage log and the open question.
func follow(sim: SimBridge) -> void:
	if sim != null and not sim.stepped.is_connected(_on_sim_stepped):
		sim.stepped.connect(_on_sim_stepped)
		_reading()
		legacy_screen.fold(sim.world) # the new game's own entries came before any step


## The sim stepped: fold this voyage's new log entries (D-68; the log section carries only the
## entries since the last step); the open question (R1-ARCHIVE-VOICE) may have its answer now.
func _on_sim_stepped(events: Array) -> void:
	var sim: SimBridge = demo.journey_sim
	if sim != null:
		if not sim.last_refused.is_empty() and str(sim.last_refused[0].reason) == "committed":
			demo.refuse(GalaxyMap.refusal_text(str(sim.last_refused[0].reason)))
		_reading()
		legacy_screen.fold(sim.world)
		news_panel.on_events(events)
	var before := archive_ask.state
	archive_ask.on_events(events, sim.last_refused if sim != null else [], sim.relay_intents if sim != null else [], sim.relay_from if sim != null else 0)
	if archive_ask.state != before:
		_show_answer()


func _show_answer() -> void:
	if answer_panel == null:
		return
	answer_question.text = "You asked: " + archive_ask.question
	answer_text.text = archive_ask.answer
	answer_panel.visible = focused == "archive" and not archive_ask.question.is_empty()
	if is_instance_valid(ask_button):
		ask_button.disabled = archive_ask.state == "waiting"


## A console label; `kind` is its meaning (a StapledonTheme label variation), never a colour (ST4).
func _label(text: String, size := 14, kind := "HUDLabel") -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.theme_type_variation = kind
	return l


## Rebuild the focused panel's body for the current state.
func _refresh_panel() -> void:
	if focused.is_empty() or not panel.visible:
		return
	for c in panel_body.get_children():
		panel_body.remove_child(c)
		if c != crew_console: # the Crew console persists, so a pending confirm and an open call survive a refresh
			c.queue_free()
	_cancel_confirm()
	match focused:
		"navigation":
			_navigation_panel()
		"voyage":
			_voyage_panel()
		"crew":
			_crew_panel()
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
			panel_body.add_child(_label(mark + str(stops[i].label), 13, "HUDHint" if i < bh.stops_taken else "HUDLabel"))
		var row := HFlowContainer.new()
		panel_body.add_child(row)
		var nl: String = bh.next_label()
		if not nl.is_empty() and not bh.approaching():
			row.add_child(confirm_button("navigation", "approach", nl))
		elif bh.approaching():
			panel_body.add_child(_label("Approach under way · K finishes it (pacing).", 13))
		row.add_child(confirm_button("navigation", "leave", "Leave Sgr A*"))
		return
	panel_title.text = "Navigation station · plot, set speed, commit"
	demo.open_navigation()


func _voyage_panel() -> void:
	panel_body.add_child(_label("The guided voyage (D-46, D-47, D-49)", 15))
	panel_body.add_child(_label(ITINERARY, 14))
	panel_body.add_child(_label("Each leg is flown in real time; at each stop the ship turns to show the body and holds for a dwell. Pause (P), Skip dwell (N) and Skip stage (K) only change how fast you watch.", 13, "HUDHint"))
	if demo.solar_tour != null:
		panel_body.add_child(_label("Under way: " + demo.tour_line(), 14))
	else:
		panel_body.add_child(_label("The guided voyage replaces the current course. It cannot be undone.", 13, "HUDWarn"))
		panel_body.add_child(confirm_button("voyage", "begin", "Begin guided voyage"))
	# crew-work W1: the crew live at the Crew console; here, one line and any moment that needs you.
	var sim = demo.get("journey_sim") if demo != null else null
	if sim is SimBridge and not (sim as SimBridge).crew.is_empty():
		crew_summary = _label(crew_summary_text((sim as SimBridge).crew), 13, "HUDHint")
		crew_summary.name = "CrewSummary"
		panel_body.add_child(crew_summary)


## The crew in one line for the Voyage console: how many aboard and working, auto-run, and who
## needs the captain (at the Crew console).
static func crew_summary_text(c: Dictionary) -> String:
	var members: Array = c.get("members", [])
	var working := members.filter(func(m): return m.get("work") is Dictionary and str(m["work"].get("status", "")) == "working").size()
	var auto := str(CrewPage.PRESETS.get(str(c.get("auto", "off")), c.get("auto", "off")))
	var line := "Crew: %d aboard, %d working · auto-run %s · the Crew console has the rest." % [members.size(), working, auto.to_lower()]
	var holds: Array = c.get("holds", [])
	if not holds.is_empty():
		var h: Dictionary = holds[0]
		var who := str(h.get("name", h.get("actor", "The crew")))
		line = "Needs you at the Crew console: %s\n%s" % [CrewPage.hold_text(who, h), line] # the sim's hold words (2.10 holds[].line)
	return line


func _crew_panel() -> void:
	panel_title.text = CrewConsole.TITLE_BOARD
	var sim = demo.get("journey_sim") if demo != null else null
	if not (sim is SimBridge) or (sim as SimBridge).crew.is_empty():
		panel_body.add_child(_label("No crew aboard yet: they join when a voyage begins.", 14))
		return
	_crew_section()


## The crew aboard the journey sim, if any: the board and the call. The console's intents ride the
## sim's next tick (SimBridge.queue); each tick refreshes it, and the tick that carried them answers
## them (the `sending` lock lifts, a refusal says why).
func _crew_section() -> void:
	var sim = demo.get("journey_sim") if demo != null else null
	if not (sim is SimBridge) or (sim as SimBridge).crew.is_empty():
		return
	if crew_console == null:
		crew_console = CrewConsole.new()
		crew_console.size_flags_vertical = Control.SIZE_EXPAND_FILL
		crew_console.title_changed.connect(func(t: String) -> void:
			if focused == "crew": panel_title.text = t)
	if _crew_sim != sim:
		if _crew_sim != null and _crew_sim.stepped.is_connected(_on_crew_step):
			_crew_sim.stepped.disconnect(_on_crew_step)
		for c in crew_console.intents.get_connections():
			crew_console.intents.disconnect(c["callable"])
		_crew_sim = sim
		_crew_sim.stepped.connect(_on_crew_step)
		crew_console.intents.connect(_crew_sim.queue)
	crew_console.show_crew(_crew_sim.crew)
	panel_title.text = crew_console.title()
	panel_body.add_child(crew_console)


func _on_crew_step(events: Array) -> void:
	if crew_console == null or _crew_sim == null:
		return
	crew_console.on_events(events)
	if not _crew_sim.last_queued.is_empty(): # only a tick that carried the console's intents answers them
		crew_console.on_refused(_crew_sim.queued_refused(), _crew_sim.last_queued)
	if focused == "crew" and crew_console.get_parent() == panel_body:
		crew_console.show_crew(_crew_sim.crew)
	if focused == "voyage" and is_instance_valid(crew_summary):
		crew_summary.text = crew_summary_text(_crew_sim.crew)


func _archive_panel() -> void:
	follow(demo.journey_sim)
	demo._ensure_codex()
	var world: Dictionary = demo.sky_world if demo.sky_world is Dictionary else {}
	demo.codex.show_world(world)
	demo.codex.open()
	(demo.codex.get_parent() as CanvasLayer).layer = panel_layer.layer + 1 # over the console panel
	_fit_reading(demo.codex.panel) # below the reading row, so Ask stays reachable
	var news := HBoxContainer.new()
	news.add_theme_constant_override("separation", 12)
	panel_body.add_child(news)
	var nl := _label("News and voyage log", 14)
	nl.autowrap_mode = TextServer.AUTOWRAP_OFF
	news.add_child(nl)
	for spec in [["log entries", "consequence.legacy.count", "%d"], ["latest news from", "consequence.news.star_id", "%s"]]:
		var cap := _label(spec[0], 12, "HUDCaption")
		cap.autowrap_mode = TextServer.AUTOWRAP_OFF
		news.add_child(cap)
		var b := DisplayBinding.new().bind(spec[1], spec[2])
		b.update_from(world)
		news.add_child(b)
	var reading := HBoxContainer.new()
	reading.add_theme_constant_override("separation", 10)
	panel_body.add_child(reading)
	var read_news := Button.new(); read_news.text = "Read news from home"; read_news.name = "ReadNews"
	read_news.disabled = not NewsPanel.new().has_news(world)
	read_news.pressed.connect(func() -> void: use("archive", "news"))
	reading.add_child(read_news)
	var read_log := Button.new(); read_log.text = "Voyage log"; read_log.name = "VoyageLog"
	read_log.pressed.connect(func() -> void: use("archive", "log"))
	reading.add_child(read_log)
	var codex_b := Button.new(); codex_b.text = "Codex"; codex_b.name = "ArchiveCodex"
	codex_b.pressed.connect(func() -> void: use("archive", "codex"))
	reading.add_child(codex_b)
	# R1-ARCHIVE-VOICE: ask the Archive (Enter or the button).
	ask_field = LineEdit.new(); ask_field.name = "ArchiveQuestion"; ask_field.placeholder_text = "Ask the Archive..."
	ask_field.max_length = ArchiveAsk.MAX_QUESTION; ask_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ask_field.custom_minimum_size = Vector2(260, 0)
	ask_field.text_submitted.connect(func(_t: String) -> void: use("archive", "ask"))
	reading.add_child(ask_field)
	var ask_b := Button.new(); ask_b.text = "Ask"; ask_b.name = "AskArchive"
	ask_b.pressed.connect(func() -> void: use("archive", "ask"))
	reading.add_child(ask_b)
	ask_button = ask_b
	ask_b.disabled = archive_ask.state == "waiting"
	# Back at the terminal: the last question and its answer (it may have arrived while away).
	if not archive_ask.question.is_empty():
		_reading()
		_show_answer.call_deferred()
