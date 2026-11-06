extends SceneTree
func _initialize() -> void:
	if not FileAccess.file_exists("res://demos/ship_demo_benchmark.gd"):
		print("ship-demo-benchmark: FAIL missing runnable measurement tool");quit(1);return
	var script: GDScript=load("res://demos/ship_demo_benchmark.gd")
	if script==null or not script.can_instantiate():
		print("ship-demo-benchmark: FAIL invalid script");quit(1);return
	var result: Dictionary=script.summarize([10.,12.,14.,16.,18.])
	var conds: Array=[result.p50_ms==14.,result.p95_ms==18.,result.samples==5]
	var passed: int=conds.count(true)
	var ok: bool=passed==conds.size()
	print("ship-demo-benchmark: %s (%d passed, %d failures)" % ["OK" if ok else "FAIL",passed,conds.size()-passed]);quit(0 if ok else 1)
