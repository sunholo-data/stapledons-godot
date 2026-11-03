extends SceneTree
## R3-COMMS-V2 CV4 (design r3/comms-station-v2.md §D2, AC9): the consoles under the screens, walked on the
## shipped bridge with the game's own router (WalkArea.path). make comms-walk-test.
##   use      every active station's operator point (ShipConsoles, the manifest's use_m) is walkable and
##            reachable from the spawn and from the captain's chair
##   comms    the walk from the chair to the comms station is at most 9.0 m (today's 17.1 m)
##   rim      the walk along the bow rail from the port quarter to the starboard quarter stays open
##            (at most 42 m on the router, against a 52 m arc): the desks under the screens do not wall it off
##   screens  the comms, Voyage and crew idle screens stand at the manifest's screen_ship_m (the housings)

const COMMS_MAX_M := 9.0
const RIM_MAX_M := 42.0
var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func plen(a: Vector3, p: PackedVector3Array) -> float:
	if p.is_empty():
		return -1.0
	var s := a.distance_to(p[0])
	for i in range(1, p.size()):
		s += p[i - 1].distance_to(p[i])
	return s


func _run() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	check("the ship demo builds", demo.ready_ok)
	if not demo.ready_ok:
		print("comms-walk: %d passed, %d failures" % [passes, failures])
		quit(1)
		return
	var w: WalkArea = demo.walk_bridge
	var spawn: Vector3 = demo.bridge_spawn()
	var seat: Array = demo.manifest.captain_chair.position_m
	var chair := w.closest_walkable(Vector3(float(seat[0]), 82.0, -float(seat[1]) + 2.0), 2.0) # stern of the chair, where the captain sits down
	var c: ShipConsoles = demo.consoles
	for id: String in c.stations:
		if not c.stations[id].active:
			continue
		var u: Vector3 = c.stations[id].use
		var from_spawn := plen(spawn, w.path(spawn, u))
		var from_chair := plen(chair, w.path(chair, u))
		check("use: %s at (%.2f, %.2f) walkable, reachable (spawn %.1f m, chair %.1f m)" % [id, u.x, -u.z, from_spawn, from_chair], w.is_walkable(u) and from_spawn > 0.0 and from_chair > 0.0)
		if id == "comms":
			check("comms: chair to comms %.1f m walked (at most %.1f m; it was 17.1 m)" % [from_chair, COMMS_MAX_M], from_chair > 0.0 and from_chair <= COMMS_MAX_M)
	var rim := func(b: float) -> Vector3: return w.closest_walkable(Vector3(19.9 * sin(deg_to_rad(b)), 82.0, -19.9 * cos(deg_to_rad(b))), 1.5)
	var a: Vector3 = rim.call(-75.0)
	var z: Vector3 = rim.call(75.0)
	var rl := plen(a, w.path(a, z))
	check("rim: port quarter to starboard quarter along the rail %.1f m (at most %.0f m)" % [rl, RIM_MAX_M], rl > 0.0 and rl <= RIM_MAX_M)
	for id: String in ["comms", "voyage", "crew"]:
		var s: Variant = demo.manifest.stations.get(id, {}).get("screen_ship_m")
		var want := ShipFrame.gltf_from_structure(s) if s is Array else Vector3.INF
		var got: Vector3 = c.screens[id].quad.global_position if c.screens.has(id) else Vector3.ZERO
		check("screens: %s idle screen at its housing (%s)" % [id, got], got.is_equal_approx(want))
	demo.queue_free()
	await process_frame
	print("comms-walk: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)
