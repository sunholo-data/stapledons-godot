extends SceneTree
var failures:=0
func check(name: String, ok: bool) -> void:
	print("  %s %s" % ["ok" if ok else "FAIL",name]);if not ok:failures+=1
func _initialize() -> void:
	var d: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ship_commons/manifest.json"))
	if not d.assets.has("painted") or not d.assets.has("coarse"):
		check("paint and coarse derivative exist",false);quit(1);return
	var detail:=AreaBundle.load_glb("res://assets/ship_commons/"+d.assets.painted)
	var coarse:=AreaBundle.load_glb("res://assets/ship_commons/"+d.assets.coarse)
	var detailed_triangles:={};var coarse_triangles:={}
	_scan(detail,Transform3D.IDENTITY,detailed_triangles);_scan(coarse,Transform3D.IDENTITY,coarse_triangles)
	var preserved:=true
	for key in coarse_triangles:if not detailed_triangles.has(key):preserved=false
	check("coarse triangles exact subset of detailed opaque geometry",preserved)
	check("coarse retains nonempty major silhouette",coarse_triangles.size()>2000 and coarse_triangles.size()<detailed_triangles.size())
	var kit:={"visual":detail,"coarse":coarse}
	load("res://demos/ship_commons.gd").update_detail(kit,Vector3(26,58.7,-10))
	check("near interior uses detailed kit",detail.visible and not coarse.visible)
	load("res://demos/ship_commons.gd").update_detail(kit,Vector3(250,100,250))
	check("far review uses coarse kit",not detail.visible and coarse.visible)
	detail.free();coarse.free()
	print("ship-commons-assets: %s" % ("OK" if failures==0 else "FAIL"));quit(1 if failures else 0)
func _scan(n: Node, xf: Transform3D, tris: Dictionary) -> void:
	if n is Node3D:xf=xf*n.transform
	if n is MeshInstance3D and n.mesh!=null:
		var faces: PackedVector3Array=n.mesh.get_faces()
		for i in range(0,faces.size(),3):
			var keys:=[]
			for j in 3:
				var p:=xf*faces[i+j];keys.append("%.3f,%.3f,%.3f" % [p.x,p.y,p.z])
			keys.sort();tris[str(keys)]=true
		for s in n.mesh.get_surface_count():
			var arrays: Array=n.mesh.surface_get_arrays(s)
			check("all vertices have UVs",arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size())
			var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			var safe:=true
			for p in uv:
				if not p.is_finite() or fmod(p.x,.5)<.009 or fmod(p.x,.5)>.491 or fmod(p.y,.5)<.009 or fmod(p.y,.5)>.491:safe=false
			check("UVs avoid atlas quadrant boundaries",safe)
			var mat: StandardMaterial3D=n.mesh.surface_get_material(s)
			check("embedded opaque paint material",mat!=null and mat.albedo_texture!=null and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED)
			if mat!=null and mat.albedo_texture!=null:check("texture within2K",mat.albedo_texture.get_width()<=2048 and mat.albedo_texture.get_height()<=2048)
	for c in n.get_children():_scan(c,xf,tris)
