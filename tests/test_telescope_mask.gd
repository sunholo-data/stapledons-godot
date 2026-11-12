extends SceneTree
## Explicit synthetic pixel fixtures, independent of any rendered star/shader.
const Oracle = preload("res://tools/telescope_mask_oracle.gd")
var passed := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok ",label)
	else: failures += 1; printerr("FAIL ",label)
func disc(centre: Vector2, radius: float) -> Image:
	var image := Image.create(64,64,false,Image.FORMAT_RGBA8); image.fill(Color.BLACK)
	for y in 64:
		for x in 64:
			if Vector2(x+.5,y+.5).distance_to(centre) < radius: image.set_pixel(x,y,Color.WHITE)
	return image
func _initialize() -> void:
	var expected := Vector2(32,32)
	var blank := Image.create(64,64,false,Image.FORMAT_RGBA8); blank.fill(Color.BLACK)
	var empty := Oracle.measure(blank,expected)
	check(not empty.geometry_valid and not Oracle.passes(empty), "blank labelled fixture cannot supply geometry proof")
	var filled := Image.create(64,64,false,Image.FORMAT_RGBA8); filled.fill(Color.WHITE)
	var rectangle := Oracle.measure(filled,expected)
	check(not rectangle.geometry_valid and not Oracle.passes(rectangle), "all-lit rectangle with centred centroid must fail")
	check(rectangle.get("centroid_error_px") == null, "invalid filled field has no valid centroid-error claim")
	var clipped := Oracle.measure(disc(Vector2(8,32),18),expected)
	check(not clipped.geometry_valid and not Oracle.passes(clipped), "edge-clipped labelled fixture must fail")
	var offset := Oracle.measure(disc(Vector2(45,32),10),expected)
	check(offset.geometry_valid and not Oracle.passes(offset) and offset.centroid_error_px > 12., "unclipped but offset disc fails independent expected position")
	var good := Oracle.measure(disc(expected,16),expected)
	check(good.geometry_valid and Oracle.passes(good) and good.centroid_error_px < 0.001, "centred unclipped labelled disc passes")
	var dirty_rim := disc(expected,16); dirty_rim.set_pixel(0,1,Color.WHITE)
	var rim := Oracle.measure(dirty_rim,expected)
	check(not rim.geometry_valid and not Oracle.passes(rim), "bright rim contamination fails even with centred interior")
	check(not Oracle.passes({"geometry_valid":true,"centroid_error_px":null}), "missing error cannot accidentally pass")
	print("telescope-mask-test: %d passed, %d failures" % [passed,failures])
	quit(1 if failures else 0)
