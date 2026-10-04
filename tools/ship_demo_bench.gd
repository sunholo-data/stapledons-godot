extends SceneTree
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate();root.add_child(demo);await process_frame
	var benchmark: RefCounted=load("res://demos/ship_demo_benchmark.gd").new()
	var report: Dictionary=await benchmark.run(demo)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/ship_demo"))
	var f:=FileAccess.open("res://renders/ship_demo/studio_benchmark.json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "))
	print("ship-demo-bench: OK (actual hardware in report; target laptop remains pending)");quit()
