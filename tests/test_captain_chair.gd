extends SceneTree
## R2-CAPTAIN-ANIMATION CA2 (OQ9): the captain's chair and the look-up cues in the real ship demo, headless.
##   make captain-chair-test
## E in reach of the seat sits the captain (on the seat, facing the bow: sit, then seated); a move key or E
## stands first and only then walks, back at the walkable point beside the chair. The lower deck has no
## chair. The ship arriving at a stop, or the starbow forming (beta past 0.9), raises one look-up cue.
const DT := 1.0 / 60.0
var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("ok   ", name)
	else:
		failures += 1
		print("FAIL ", name, (": " + detail) if detail != "" else "")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	var seat: Variant = demo.chair_seat()
	check("the ship manifest places the chair (layout A)", seat is Vector3, str(seat))
	if not seat is Vector3:
		_done(demo)
		return
	# Far from the chair: no chair target.
	demo.avatar_pos = demo.bridge_spawn() + Vector3(6, 0, 0)
	check("out of reach, E does not target the chair", demo.consoles.e_target().get("kind", "") != "chair", str(demo.consoles.e_target()))
	# Beside the chair: E sits.
	var beside: Vector3 = demo.walk_bridge.closest_walkable(seat + Vector3(0, 0, 0.8), 3.0) # the stern side, ~2 m from the seat
	demo.avatar_pos = beside
	demo._process(DT)
	check("in reach, E targets the chair and the prompt says so", demo.consoles.e_target().get("kind", "") == "chair" and demo.consoles.prompt_text().contains("chair"), "%s %s" % [demo.consoles.e_target(), demo.consoles.prompt_text()])
	check("E sits", demo.use_nearest() and demo.seated())
	var clips: Array = []
	for k in 50:
		demo._process(DT)
		clips.append(demo.captain_anim.clip)
	check("on the seat, facing the bow (the back in the Bow view)", demo.avatar_pos.distance_to(seat) < 1e-3 and demo.captain_anim.facing_for_test() == "back", "%s %s" % [demo.avatar_pos, demo.captain_anim.facing_for_test()])
	check("sit, then seated", clips[0] == "sit" and clips[49] == "seated", str(clips))
	# A move key stands first; the captain does not move while standing.
	var on_seat: Vector3 = demo.avatar_pos
	demo.walk_motion(Vector2(0, 1), DT)
	demo._process(DT)
	check("a move key stands the captain (no walking yet)", demo.captain_anim.clip == "stand" and demo.avatar_pos.distance_to(on_seat) < 1e-3, demo.captain_anim.clip)
	for k in 40:
		demo.walk_motion(Vector2(0, 1), DT)
		demo._process(DT)
	check("stood up: back beside the chair, free to walk", not demo.seated() and demo.walk_bridge.is_walkable(demo.avatar_pos), "%s seated %s" % [demo.avatar_pos, demo.seated()])
	# E stands too.
	demo.avatar_pos = beside
	demo._process(DT)
	demo.use_nearest()
	for k in 50:
		demo._process(DT)
	var stood: bool = demo.use_nearest()
	demo._process(DT)
	check("E while seated stands", stood and demo.captain_anim.chair in ["stand", ""], demo.captain_anim.chair)
	for k in 40:
		demo._process(DT)
	check("free after standing", not demo.seated())
	# Look-up cues.
	demo._was_under_way = true
	check("arriving at a stop raises one look-up cue", demo._look_up_cue() == "look_up" and demo._look_up_cue() == "")
	demo._was_starbow = false
	var beta: float = demo.sky.beta
	demo.sky.beta = 0.95
	check("the starbow forming raises one look-up cue", demo._look_up_cue() == "look_up" and demo._look_up_cue() == "")
	demo.sky.beta = beta
	_done(demo)


func _done(demo: Node) -> void:
	print("captain-chair: %d passed, %d failures" % [passes, failures])
	demo.queue_free()
	await process_frame
	quit(1 if failures else 0)
