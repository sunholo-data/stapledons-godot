extends SceneTree
## External-script harness when a template permits path overrides. Official
## release templates use the explicit --telescope-app-probe production CLI route.
const Probe = preload("res://ui/telescope_app_probe.gd")
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var failures: int = await Probe.new().run(self,OS.get_cmdline_user_args())
	quit(1 if failures else 0)
