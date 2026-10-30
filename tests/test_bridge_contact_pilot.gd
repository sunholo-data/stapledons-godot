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
	var v2 := "--v2" in OS.get_cmdline_user_args()
	var metadata := "bridge-contact-pilot-v2.json" if v2 else "bridge-contact-pilot.json"
	var asset := "bridge_contact_pilot_v2.glb" if v2 else "bridge_contact_pilot.glb"
	if not FileAccess.file_exists(ART+metadata):
		check("versioned proposal exists",false)
		quit(1);return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+metadata))
	if v2:
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ART+"bridge-contact-pilot.json"))
		check("v2 preserves exact v1 palm targets",data.pad_centres_ship_m==original.pad_centres_ship_m and data.pad_radii_m==original.pad_radii_m)
	var shipped: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ship_demo/manifest.json"))
	check("proposal GLB matches its content pin",FileAccess.get_sha256(ART+asset)==data.asset_sha256)
	var model := AreaBundle.load_glb(ART+asset)
	check("Blender pilot imports",model!=null)
	if model==null: quit(1);return
	root.add_child(model)
	var triangles := 0
	var materials := {}
	for station: String in ["voyage","crew"]:
		check(station+" authored use point unchanged",shipped.stations[station].use_m==data.station_use_ship_m[station])
		if v2:
			for side in [-1,1]:
				var leaf := model.find_child("VF_%s_contact_leaf_%s" % [station,side],true,false) as MeshInstance3D
				check("v2 solid grown leaf exists",leaf!=null)
				if leaf!=null:
					var bounds: AABB = leaf.global_transform*leaf.mesh.get_aabb()
					check("v2 broad low-profile leaf replaces thin loop",bounds.size.x>=.35 and bounds.size.y<.30)
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
				materials[mat.get_instance_id()]=true
				check("opaque surface without painted emission",mat is StandardMaterial3D and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not mat.emission_enabled)
	check("bounded mesh budget",triangles>0 and triangles<5000)
	if v2:
		var props := AreaBundle.load_glb("res://assets/ship_demo/bridge_props.glb")
		var base_triangles := count_triangles(props)
		var budgets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/deck-layout-v2/budgets.json"))
		var cap := int(budgets.glb["assets/ship_demo/bridge_props.glb"].max_triangles)
		check("v2 additions fit 2000-triangle allocation",triangles<=2000)
		check("v2 uses two palette materials",materials.size()==2)
		check("combined bridge hero and proposal fit existing cap",base_triangles+triangles<=cap)
		var previous := AreaBundle.load_glb(ART+"bridge_contact_pilot.glb")
		check("prior v1 exceeds combined budget and is rejected",base_triangles+count_triangles(previous)>cap)
		previous.free()
		print("bridge-contact-v2 budget: base %d + proposal %d = %d / cap %d" % [base_triangles,triangles,base_triangles+triangles,cap])
		props.free()
	model.free()
	print("bridge-contact-pilot: %d passed, %d failures" % [passed,failed])
	quit(1 if failed else 0)
func supported(box: AABB,palm: Vector3) -> bool:
	return absf(box.end.y-palm.y)<=.06 and palm.x>=box.position.x-.01 and palm.x<=box.end.x+.01 and palm.z>=box.position.z-.01 and palm.z<=box.end.z+.01
func check(label: String,ok: bool) -> void:
	if ok:passed+=1
	else:failed+=1
	print("%s %s" % ["ok" if ok else "FAIL",label])

func count_triangles(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:count=node.mesh.get_faces().size()/3
	for child in node.get_children():count+=count_triangles(child)
	return count
