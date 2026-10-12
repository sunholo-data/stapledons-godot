extends SceneTree
func _initialize() -> void:
	var path := "res://assets/ship_demo/manifest.json"
	if not FileAccess.file_exists(path):
		print("ship-demo-assets: FAIL missing measured asset manifest")
		quit(1)
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var failures := 0
	var heights := [82,57,32,7,-18,-43,-68]
	for i in heights.size():
		if float(data["deck_heights_ship_m"][i]) != heights[i]: failures += 1
	if not data.get("lift_route", {}).get("clear", false): failures += 1
	for filename in data.get("assets", {}).values():
		if not FileAccess.file_exists("res://assets/ship_demo/" + filename): failures += 1
	print("ship-demo-assets: %s" % ("OK" if failures == 0 else "FAIL"))
	quit(failures)
