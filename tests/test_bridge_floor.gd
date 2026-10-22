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
		# R2-BRIDGE-STYLE S3: the deck top is painted (one atlas per quadrant); its family is the painted
		# colour's nearest original pigment, sampled at the hit.
		var fam:String=_family(a.material) if a.get('color')==null else _nearest(a.color,original)
		check('original floor material region retained at '+str(p)+' ('+fam+' '+str(a.get('color'))+' want '+_family(b.material)+')',not a.is_empty() and not b.is_empty() and fam==_family(b.material))
	if found!=null:
		for p in [Vector3(6.2,82,-6.2),Vector3(8,82,-8),Vector3(9.8,82,-9.8)]:
			check('render-only top leaves real shaft open '+str(p),_hit(found,Transform3D.IDENTITY,p,false).is_empty())
	# The floor restore left both walks untouched; R2-DECK-LAYOUT DL1 rebuilt the bridge walk on purpose,
	# so it is pinned by art/deck-layout-v2/asset-pins.json (the lower walk is still grounded v2's).
	var pins:Dictionary=JSON.parse_string(FileAccess.get_file_as_string('res://art/deck-layout-v2/asset-pins.json')).pins
	for pair in [['walk_bridge.glb',str(pins['assets/ship_demo/walk_bridge.glb'].sha256)],['walk_lower.glb','dc06abfcc0a3485db6eb443ae76b9d4beb12cdb658cbed877d5f15517e330213']]:
		check('walk matches its pin '+pair[0],FileAccess.get_sha256('res://assets/ship_demo/'+pair[0])==pair[1])
	actual.free();original.free();print('bridge-floor: %d passed, %d failures' % [passed,failures]);quit(1 if failures else 0)
func _find(n:Node,key:String)->Node:
	if n.name==key:return n
	for child in n.get_children():
		var r:=_find(child,key)
		if r!=null:return r
	return null
var _refs:={}
## The original pigments' mean colours (the gouache textures), by family.
func _nearest(c:Color,original:Node)->String:
	if _refs.is_empty():_collect_refs(original)
	var best:='';var bd:=INF
	var s:=maxf(1e-4,c.r+c.g+c.b)
	for f in _refs:
		var r:Color=_refs[f];var rs:=maxf(1e-4,r.r+r.g+r.b)
		var d:=Vector3(c.r/s-r.r/rs,c.g/s-r.g/rs,c.b/s-r.b/rs).length() # chroma only: the painted atlas is darker (contact shading, ink)
		if d<bd:bd=d;best=f
	return best
## The deck's original pigments (the DL1 master's packed gouache textures, mean sRGB, measured with
## Blender 2026-10-21): "ash floor" is the cream family's neutral (see _family).
func _collect_refs(_original:Node)->void:
	_refs={'cream':Color(.5321,.5271,.5321),'teal':Color(.7219,.8151,.8151),'coral':Color(.8321,.7083,.6652),'ochre':Color(.8266,.7675,.6181),'violet':Color(.6096,.5563,.6341)}
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
					if hit!=null and hit.y>=80. and (best.is_empty() or hit.y>best.y):
						best={'y':hit.y,'material':str(n.mesh.surface_get_material(s).resource_name),'node':str(n.name)}
						var mat:=n.mesh.surface_get_material(s) as BaseMaterial3D
						if mat!=null and str(mat.resource_name).contains('painted') and mat.albedo_texture!=null and arrays[Mesh.ARRAY_TEX_UV]!=null:
							var uvs:PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
							var w:=Geometry3D.get_triangle_barycentric_coords(hit,a,b,c)
							var uv:=uvs[indices[i]]*w.x+uvs[indices[i+1]]*w.y+uvs[indices[i+2]]*w.z
							var img:=mat.albedo_texture.get_image()
							if img.is_compressed():img.decompress()
							var px:=Vector2i(clampi(int(fposmod(uv.x,1.)*img.get_width()),0,img.get_width()-1),clampi(int(fposmod(uv.y,1.)*img.get_height()),0,img.get_height()-1))
							# a small neighbourhood (ink lines and grain are not the region's colour)
							var acc:=Color(0,0,0);var k:=0
							for dy in range(-6,7,3):
								for dx in range(-6,7,3):
									acc+=img.get_pixelv(Vector2i(clampi(px.x+dx,0,img.get_width()-1),clampi(px.y+dy,0,img.get_height()-1)));k+=1
							best['color']=Color(acc.r/k,acc.g/k,acc.b/k)
	for child in n.get_children():
		var value:=_hit(child,xf,p,walk_only)
		if not value.is_empty() and (best.is_empty() or value.y>best.y):best=value
	return best
