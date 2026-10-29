extends SceneTree
## A nearby captain must not bias the new paired-baseline star centroid or create a false signal.
func _initialize() -> void:
	var helper = load("res://tools/m4_ship_golden.gd").new()
	helper.size = Vector2i(100, 100)
	var before := Image.create(100, 100, false, Image.FORMAT_RGB8)
	before.fill(Color.BLACK)
	before.set_pixel(50, 61, Color.WHITE) # captain hair within the 12px centroid window
	var after := before.duplicate() as Image
	after.set_pixel(50, 50, Color.WHITE)
	var measured: Array = helper._centroid(helper._star_difference(after, before, Vector2(50, 50)), Vector2(50, 50))
	var positive: bool = measured[0].distance_to(Vector2(50.5, 50.5)) < 0.001 and measured[2] > 0.0
	var absent: Array = helper._centroid(helper._star_difference(before, before, Vector2(50, 50)), Vector2(50, 50))
	var negative: bool = absent[2] == 0.0 and absent[0] == Vector2(-1, -1)
	print("%s differential centroid isolates added star from nearby captain" % ("ok" if positive else "FAIL"))
	print("%s unchanged captain cannot create a differential star signal" % ("ok" if negative else "FAIL"))
	var failures := int(not positive) + int(not negative)
	print("level-golden: %d passed, %d failures" % [2 - failures, failures])
	quit(1 if failures else 0)
