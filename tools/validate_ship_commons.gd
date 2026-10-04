extends SceneTree
var failures:=0
var triangles:=0
var maximum:=0.
var minimum_y:=INF
var maximum_y:=-INF
var materials:={}
var faces:=PackedVector3Array()
func check(name: String, ok: bool) -> void:
	print("  %s %s" % ["ok" if ok else "FAIL",name]);if not ok:failures+=1
func _initialize() -> void:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ship_commons/manifest.json"))
	var scene:=AreaBundle.load_glb("res://assets/ship_commons/"+manifest.assets.get("painted",manifest.assets.blockout))
	if scene==null:check("real exported geometry",false);quit(1);return
	if OS.get_cmdline_user_args().has("bad-envelope"):scene.position.x+=100.
	_scan(scene,Transform3D.IDENTITY)
	check("actual new vertices inside95m envelope",maximum<=95.001)
	check("actual Commons finished floor",absf(minimum_y-57.)<.001)
	check("actual pavilion top65.42m",absf(maximum_y-65.42)<.002)
	check("actual triangles under30000",triangles<=30000 and triangles==int(manifest.triangle_count))
	check("actual material count at most4",materials.size()<=4)
	for p in [Vector3(26,58.7,-10),Vector3(21,58.7,-10),Vector3(31,58.7,-10)]:
		check("roof blocks upward ray "+str(p),_hit(p,p+Vector3.UP*20))
	check("opaque back wall",_hit(Vector3(26,58.7,-10),Vector3(26,58.7,-20)))
	check("opaque side wall",_hit(Vector3(26,58.7,-10),Vector3(40,58.7,-10)))
	check("door clear at human eye",not _hit(Vector3(26,58.7,-2),Vector3(26,58.7,-8)))
	check("door clear for capsule width",not _hit(Vector3(25.65,58.7,-2),Vector3(25.65,58.7,-8)) and not _hit(Vector3(26.35,58.7,-2),Vector3(26.35,58.7,-8)))
	check("4m landing guard opening",not _hit(Vector3(12,58,-4.8),Vector3(16,58,-4.8)))
	if manifest.get("revision",1)>=2:
		check("opaque terrace canopy",_hit(Vector3(18.75,58.7,3),Vector3(18.75,63,3)))
		check("canopy standing head clearance",not _hit(Vector3(18.75,58.7,3),Vector3(18.75,59.05,3)))
	for x in [6.2,8.,9.8]:
		for z in [-6.2,-8.,-9.8]:check("new mesh leaves lift shaft clear",not _hit(Vector3(x,83.4,z),Vector3(x,55.5,z)))
	scene.free();print("validate-ship-commons: %s" % ("OK" if failures==0 else "FAIL"));quit(1 if failures else 0)
func _scan(n: Node, transform: Transform3D) -> void:
	if n is Node3D:transform=transform*n.transform
	if n is MeshInstance3D and n.mesh!=null:
		var vertices: PackedVector3Array=n.mesh.get_faces();triangles+=vertices.size()/3
		for v in vertices:
			var point:=transform*v;faces.append(point);maximum=maxf(maximum,point.length());minimum_y=minf(minimum_y,point.y);maximum_y=maxf(maximum_y,point.y)
		for surface in n.mesh.get_surface_count():
			var material: Material=n.mesh.surface_get_material(surface)
			if material!=null:
				materials[material.get_instance_id()]=true
				check("opaque material",material is StandardMaterial3D and material.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED)
	for child in n.get_children():_scan(child,transform)
func _hit(a: Vector3,b: Vector3) -> bool:
	for i in range(0,faces.size(),3):
		if Geometry3D.segment_intersects_triangle(a,b,faces[i],faces[i+1],faces[i+2])!=null:return true
	return false
