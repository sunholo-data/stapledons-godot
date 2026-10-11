extends SceneTree
## Renderer geometry only: independent sphere-area quadrature and enclosing-ball safety.
var failures := 0
var checks := 0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print(("ok " if ok else "FAIL ")+label)
func _init()->void:
	var dust:Script=load("res://interior/dust_flash.gd")
	check("surface footprint CPU geometry is available",dust.has_method("footprint_uv") and dust.has_method("surface_extent"))
	if failures>0:
		print("bubble-surface: %d checks %d failures"%[checks,failures]);quit(1);return
	var radius:=100.0;var spot:=0.5
	for n:Vector3 in [Vector3(0,0,1),Vector3(0.6,0,0.8),Vector3(0.96,0,0.28)]:
		var axis:Vector3=dust.call("surface_axis",n)
		var across:=n.cross(axis)
		check("incidence axis is tangent %s"%n,absf(n.dot(axis))<1e-6 and absf(axis.length()-1)<1e-6)
		var area:=0.0;var inside:=0;var escaped:=0
		# Lambert azimuthal equal-area coordinates: each cell is equal sphere area.
		var step:=6.4*spot/400.0
		for iy in 400:
			for ix in 400:
				var xy:=Vector2((ix+0.5)*step-3.2*spot,(iy+0.5)*step-3.2*spot)
				var rr:=xy.length_squared();var cosine:=1.0-rr/(2.0*radius*radius)
				var p:=radius*cosine*n+sqrt(1.0-rr/(4.0*radius*radius))*(xy.x*axis+xy.y*across)
				var uv:Vector2=dust.call("footprint_uv",p,n,radius,spot,true)
				if uv.length_squared()<=1.0:
					inside+=1;area+=step*step
					if (p-radius*n).length()>float(dust.call("surface_extent",spot)):escaped+=1
		check("equal spherical area %.3f m2 vs %.3f %s"%[area,PI*spot*spot,n],absf(area/(PI*spot*spot)-1.0)<0.005)
		check("all accepted rays inside conservative projection ball %s"%n,inside>100 and escaped==0)
		var uv0:Vector2=dust.call("footprint_uv",radius*n,n,radius,spot,true)
		check("impact origin remains inside footprint %s"%n,uv0.length()<1e-5)
	var n:=Vector3(0.96,0,0.28);var axis:Vector3=dust.call("surface_axis",n)
	var p:Vector3=(100.0*n+1.0*axis).normalized()*100.0
	var smeared:Vector2=dust.call("footprint_uv",p,n,100.0,0.5,true)
	var circle:Vector2=dust.call("footprint_uv",p,n,100.0,0.5,false)
	check("glancing surface mark extends along incidence beyond circle",smeared.length_squared()<1.0 and circle.length_squared()>1.0)
	var shader:=FileAccess.get_file_as_string("res://interior/dust_flash.gdshader")
	check("runtime shader exposes comparison and edge coverage",shader.contains("surface_marks") and shader.contains("fwidth"))
	var flashes:=PackedVector4Array();flashes.resize(64)
	flashes[0]=Vector4(n.x,n.y,n.z,1)
	var other:Vector3=(100.0*n+1.8*axis).normalized()
	flashes[63]=Vector4(other.x,other.y,other.z,1)
	var masks:Array=dust.call("overlap_masks",flashes,64,100.0,float(dust.call("surface_extent",0.5)))
	check("long footprint neighbour across bit63 retained",(masks[1][0] & (1<<31))!=0)
	print("bubble-surface: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
