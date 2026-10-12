extends SceneTree
## Restored visible floor, independently sampled against original authoring regions.
var failures:=0
var passed:=0
func check(label:String,ok:bool)->void:
	print('  %s %s' % ['ok' if ok else 'FAIL',label]);passed+=int(ok);failures+=int(not ok)
func _initialize()->void:
	var actual:=AreaBundle.load_glb('res://assets/ship_demo/ship.glb')
	var original:=AreaBundle.load_glb('res://assets/areas/bridge/play_bridge.glb')
	var found:=_find(actual,'bridge_floor_top82')
	check('distinct render-only top exists',found!=null and not str(found.name).begins_with('WALK_'))
	for p in [Vector3(8,82,-4.8),Vector3(0,82,-10),Vector3(14,82,0),Vector3(18,82,9)]:
		var a:=_hit(actual,Transform3D.IDENTITY,p,false)
		var b:=_hit(original,Transform3D(Basis.IDENTITY,Vector3(0,82,0)),p,true)
		check('actual visible support82 at '+str(p),not a.is_empty() and absf(a.y-82.)<.001)
		check('original floor material region retained at '+str(p),not a.is_empty() and not b.is_empty() and _family(a.material)==_family(b.material))
	if found!=null:
		for p in [Vector3(6.2,82,-6.2),Vector3(8,82,-8),Vector3(9.8,82,-9.8)]:
			check('render-only top leaves real shaft open '+str(p),_hit(found,Transform3D.IDENTITY,p,false).is_empty())
	for pair in [['walk_bridge.glb','9775c88d9f4d7ba7cb041ceedc61b22d6fca631092a73d051b0efdbad58f319b'],['walk_lower.glb','dc06abfcc0a3485db6eb443ae76b9d4beb12cdb658cbed877d5f15517e330213']]:
		check('existing walk remains byte-identical '+pair[0],FileAccess.get_sha256('res://assets/ship_demo/'+pair[0])==pair[1])
	actual.free();original.free();print('bridge-floor: %d passed, %d failures' % [passed,failures]);quit(1 if failures else 0)
func _find(n:Node,key:String)->Node:
	if n.name==key:return n
	for child in n.get_children():
		var r:=_find(child,key)
		if r!=null:return r
	return null
func _family(value:String)->String:
	if value.contains('ash floor'):return 'cream'
	for f in ['cream','teal','coral','ochre','violet']:
		if value.contains('p_'+f):return f
	return value
func _hit(n:Node,xf:Transform3D,p:Vector3,walk_only:bool)->Dictionary:
	if n is Node3D:xf=xf*n.transform
	var best:Dictionary={}
	if n is MeshInstance3D and (not walk_only or str(n.name).begins_with('WALK_')):
		for s in n.mesh.get_surface_count():
			var arrays:Array=n.mesh.surface_get_arrays(s);var vertices:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			if indices.is_empty():
				for i in vertices.size():indices.append(i)
			for i in range(0,indices.size()-2,3):
				var a:=xf*vertices[indices[i]];var b:=xf*vertices[indices[i+1]];var c:=xf*vertices[indices[i+2]]
				for hit in [Geometry3D.ray_intersects_triangle(p+Vector3.UP*2,Vector3.DOWN,a,b,c),Geometry3D.ray_intersects_triangle(p+Vector3.UP*2,Vector3.DOWN,a,c,b)]:
					if hit!=null and hit.y>=80. and (best.is_empty() or hit.y>best.y):best={'y':hit.y,'material':str(n.mesh.surface_get_material(s).resource_name),'node':str(n.name)}
	for child in n.get_children():
		var value:=_hit(child,xf,p,walk_only)
		if not value.is_empty() and (best.is_empty() or value.y>best.y):best=value
	return best
