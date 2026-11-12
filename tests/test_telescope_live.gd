extends SceneTree
const Telescope = preload("res://ui/telescope_view.gd")
var passed := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok ", label)
	else: failed += 1; printerr("FAIL ", label)
func _init() -> void:
	var view := Telescope.new()
	var sv := SystemView.new()
	var small := MeshInstance3D.new()
	var large := MeshInstance3D.new()
	sv.discs = {"small": small, "large": large}
	view.sv = sv
	var world := {"system": {"bodies": [
		{"id": "small", "kind": "star", "radius_km": 100.0, "rel_km": {"x": 10000.0, "y": 0.0, "z": 0.0}},
		{"id": "large", "kind": "star", "radius_km": 200.0, "rel_km": {"x": 10000.0, "y": 0.0, "z": 0.0}}
	]}}
	check(view.pick_star(world) == "large", "legacy fallback selects largest visible star")
	check(view.has_method("set_target"), "live renderer accepts explicit object target")
	if view.has_method("set_target"):
		view.set_target("small")
		check(view.pick_star(world) == "small", "explicit small star honoured over larger neighbour")
		small.hide()
		check(view.pick_star(world).is_empty(), "hidden explicit target never changes to another star")
		view.set_target("absent")
		check(view.pick_star(world).is_empty(), "missing explicit target never falls back")
		view.set_target("")
		check(view.pick_star(world) == "large", "clearing requested target restores legacy fallback")
		view.set_active(false)
		check(view._vp.render_target_update_mode == SubViewport.UPDATE_DISABLED, "closed live view does not render")
	view.free(); small.free(); large.free(); sv.free()
	print("telescope-live-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
