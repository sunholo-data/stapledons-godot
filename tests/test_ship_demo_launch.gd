extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var main: Node=load("res://main.gd").new()
	main.sim.world={"ship":{"journey_sentinel":"preserve"}}
	var expected: Dictionary=main.sim.world.duplicate(true)
	var pid: int=main._open_ship_demo_review(true)
	var deadline:=Time.get_ticks_msec()+15000
	while pid>0 and OS.is_process_running(pid) and Time.get_ticks_msec()<deadline:
		await create_timer(.1).timeout
	var ok: bool=pid>0 and not OS.is_process_running(pid) and main.sim.world==expected and is_instance_valid(main)
	if pid>0 and OS.is_process_running(pid):OS.kill(pid)
	main.free()
	print("ship-demo-launch: %s" % ("OK" if ok else "FAIL"));quit(0 if ok else 1)
