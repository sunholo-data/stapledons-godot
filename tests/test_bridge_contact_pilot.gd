extends SceneTree
## Independent held-palm landmarks against additive Blender geometry; no GPU needed.
var failed := 0
var passed := 0
const ART := "res://art/view-finish-v1/"
# Annotated palm centres on CA2's full 192x288 cell (not cropped texture pixels).
# The front and back paintings intentionally remain unchanged.
const PALMS := {"front":[Vector2(34,132),Vector2(154,132)],"back":[Vector2(38,126),Vector2(149,126)]}
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+"bridge-contact-pilot.json"))
	var shipped: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ship_demo/manifest.json"))
	check("proposal GLB matches its content pin",FileAccess.get_sha256(ART+"bridge_contact_pilot.glb")==data.asset_sha256)
	var model := AreaBundle.load_glb(ART+"bridge_contact_pilot.glb")
	check("Blender pilot imports",model!=null)
	if model==null: quit(1);return
	root.add_child(model)
	var triangles := 0
	for station: String in ["voyage","crew"]:
		check(station+" authored use point unchanged",shipped.stations[station].use_m==data.station_use_ship_m[station])
		var use: Vector3 = ShipConsoles.authored_use(shipped,station)
		for side in [-1,1]:
			var pad := model.find_child("VF_%s_contact_pad_%s" % [station,side],true,false) as MeshInstance3D
			check("named contact pad exists",pad!=null)
			if pad==null:continue
			var box: AABB = pad.global_transform*pad.mesh.get_aabb()
			for facing: String in PALMS:
				var px: Vector2 = PALMS[facing][0 if side<0 else 1]
				var palm := use+Vector3((px.x-96.)/135.,(270.-px.y)/135.,0.)
				check("%s %s palm supported within 6cm" % [station,facing],supported(box,palm))
				check("raised palm negative control fails",not supported(box,palm+Vector3.UP*.3))
	for child in model.get_children():
		if child is MeshInstance3D:
			triangles += child.mesh.get_faces().size()/3
			for surface in child.mesh.get_surface_count():
				var mat: Material = child.mesh.surface_get_material(surface)
				check("opaque surface without painted emission",mat is StandardMaterial3D and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not mat.emission_enabled)
	check("bounded mesh budget",triangles>0 and triangles<5000)
	model.free()
	print("bridge-contact-pilot: %d passed, %d failures" % [passed,failed])
	quit(1 if failed else 0)
func supported(box: AABB,palm: Vector3) -> bool:
	return absf(box.end.y-palm.y)<=.06 and palm.x>=box.position.x-.01 and palm.x<=box.end.x+.01 and palm.z>=box.position.z-.01 and palm.z<=box.end.z+.01
func check(label: String,ok: bool) -> void:
	if ok:passed+=1
	else:failed+=1
	print("%s %s" % ["ok" if ok else "FAIL",label])
