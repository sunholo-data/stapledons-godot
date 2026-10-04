extends SceneTree
func _initialize() -> void:
	if not FileAccess.file_exists("res://demos/ship_demo_benchmark.gd"):
		print("ship-demo-benchmark: FAIL missing runnable measurement tool");quit(1);return
	var script: GDScript=load("res://demos/ship_demo_benchmark.gd")
	if script==null or not script.can_instantiate():
		print("ship-demo-benchmark: FAIL invalid script");quit(1);return
	var result: Dictionary=script.summarize([10.,12.,14.,16.,18.])
	var ok: bool=result.p50_ms==14. and result.p95_ms==18. and result.samples==5
	print("ship-demo-benchmark: %s" % ("OK" if ok else "FAIL"));quit(0 if ok else 1)
