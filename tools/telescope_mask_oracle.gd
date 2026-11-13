extends RefCounted
## Reference-image oracle only. Same disc-mask method as star-surface goldens,
## with explicit black-rim and bounds guards against vacuous clipped-field proofs.
static func measure(image: Image, expected: Vector2) -> Dictionary:
	var peak := 0.0
	for y in image.get_height():
		for x in image.get_width(): peak = maxf(peak,image.get_pixel(x,y).srgb_to_linear().get_luminance())
	var mean := 0.0; var count := 0; var rim_peak := 0.0
	var mask_min := Vector2i(image.get_width(),image.get_height()); var mask_max := Vector2i(-1,-1)
	for y in image.get_height():
		for x in image.get_width():
			var light := image.get_pixel(x,y).srgb_to_linear().get_luminance()
			if x < 4 or y < 4 or x >= image.get_width()-4 or y >= image.get_height()-4: rim_peak = maxf(rim_peak,light)
			if light > 0.01 * peak:
				mean += light; count += 1
				mask_min = Vector2i(mini(mask_min.x,x),mini(mask_min.y,y)); mask_max = Vector2i(maxi(mask_max.x,x),maxi(mask_max.y,y))
	mean /= maxf(1.,count)
	var sum := Vector2.ZERO; var weight := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var light := image.get_pixel(x,y).srgb_to_linear().get_luminance()
			if light > 0.01 * peak:
				var coverage := minf(1., light / maxf(0.25 * mean,1e-12))
				sum += coverage * Vector2(x+.5,y+.5); weight += coverage
	var measured := sum / maxf(1e-12,weight)
	var unclipped := peak > 0.001 and count > 16 and count < image.get_width()*image.get_height()*0.8 and rim_peak < 0.01*peak and mask_min.x > 4 and mask_min.y > 4 and mask_max.x < image.get_width()-5 and mask_max.y < image.get_height()-5
	return {"geometry_valid":unclipped,"geometry_status":"unclipped measured disc" if unclipped else "invalid geometry: clipped or absent disc","centroid_error_px":measured.distance_to(expected) if unclipped and weight > 0. else null,"expected_px":[expected.x,expected.y],"measured_px":[measured.x,measured.y],"rim_peak":rim_peak,"lit_pixels":count,"mask_bounds":[mask_min.x,mask_min.y,mask_max.x,mask_max.y],"centroid_method":"coverage-weighted disc mask with black-rim/unclipped-mask guard; independent CPU Camera3D projection"}
static func passes(report: Dictionary, limit := 0.75) -> bool:
	return report.get("geometry_valid",false) and report.get("centroid_error_px") != null and float(report.centroid_error_px) <= limit
