extends SceneTree
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var host := Node.new();root.add_child(host)
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if not args.is_empty() else "capture"
	var result: int=await load("res://tools/constellation_golden.gd").new().run(host,mode)
	host.queue_free();await process_frame;quit(result)
