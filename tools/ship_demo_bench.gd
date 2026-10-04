extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var baseline:=OS.get_cmdline_user_args().has("baseline")
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate();demo.setup_options={"commons":not baseline};root.add_child(demo);await process_frame
	var benchmark: RefCounted=load("res://demos/ship_demo_benchmark.gd").new()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/ship_demo"))
	var path:="res://renders/ship_demo/studio_benchmark_%s.json" % ("baseline" if baseline else "commons")
	await benchmark.run(demo,300,120,path)
	print("ship-demo-bench: OK (actual hardware in report; target laptop remains pending)");quit()
