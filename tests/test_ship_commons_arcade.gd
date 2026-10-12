extends SceneTree
var faces:=PackedVector3Array()
func _initialize() -> void:
	var scene:=AreaBundle.load_glb("res://assets/ship_commons/commons_painted.glb")
	_scan(scene,Transform3D.IDENTITY)
	var clear:=not _hit(Vector3(26,58.7,-10),Vector3(26,58.7,-20))
	var terrace:=0
	for p in faces:
		var radius:=Vector2(p.x,p.z).length()
		if radius>=43. and radius<=55. and p.y>=61.14 and p.y<=61.4:terrace+=1
	var roof:=_hit(Vector3(49,58.725,-8),Vector3(49,65,-8))
	var arch:=not _hit(Vector3(38,58.7,-6.27),Vector3(55,58.7,-9.08))
	var ok:=clear and terrace>100 and roof and arch
	print("ship-commons-arcade: %s plaza=%s measured_terrace_vertices=%d roof=%s open_arch=%s" % ["OK" if ok else "FAIL",clear,terrace,roof,arch]);scene.free();quit(0 if ok else 1)
func _scan(n: Node,xf: Transform3D) -> void:
	if n is Node3D:xf=xf*n.transform
	if n is MeshInstance3D:
		for v in n.mesh.get_faces():faces.append(xf*v)
	for c in n.get_children():_scan(c,xf)
func _hit(a: Vector3,b: Vector3) -> bool:
	for i in range(0,faces.size(),3):
		if Geometry3D.segment_intersects_triangle(a,b,faces[i],faces[i+1],faces[i+2])!=null:return true
	return false
