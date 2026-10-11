extends SceneTree
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1;if not ok:failures+=1
	print(("ok " if ok else "FAIL ")+label)
func _init()->void:
	var layer:=IsmLayer.new();layer.load_model()
	check("instrument surface geometry exists",layer.has_method("lic_surface") and layer.has_method("cloud_surface"))
	if failures:print("ism-surfaces: %d checks %d failures"%[checks,failures]);quit(1);return
	var tris:Array=layer.call("lic_surface");var lic:Dictionary=layer.model.lic;var centre:=Vector3(lic.centre_ly[0],lic.centre_ly[1],lic.centre_ly[2]);var exact:=true
	for tri:PackedVector3Array in tris:
		for point:Vector3 in tri:
			var d:=point-centre
			exact=exact and absf(d.length()-IsmLayer.surface_radius(lic.coeffs_ly,d))<1e-5
	check("LIC fill vertices follow adopted harmonic surface",exact and tris.size()>100)
	for cl:Dictionary in layer.model.clouds:
		var faces:Array=layer.call("cloud_surface",cl);var ok:bool=faces.size()==cl.outline.size()
		for tri:PackedVector3Array in faces:
			for p:Vector3 in tri:ok=ok and absf(p.length()-float(cl.r_out_ly))<1e-5 and p.length()>0
		check("%s fill follows source triangles at approximate far depth, without origin fans"%cl.name,ok)
	check("legend explicitly describes instrument colours",layer.legend().contains("False-colour") and layer.legend().contains("not naked-eye"))
	check("map shading defaults on with construction guides off",bool(layer.get("show_surfaces")) and not layer.show_depth_guides)
	print("ism-surfaces: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
