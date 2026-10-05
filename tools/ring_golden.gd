extends SceneTree
## M5.2b controlled Saturn optics against celestial package mirrors.
const E1:=127057.41052085394
var camera:=FreeLookCamera.new()
var sf:=Starfield.new()
var sv:=SystemView.new()
var failures:=0
func _initialize()->void:run.call_deferred()
func check(name:String,ok:bool,detail:="")->void:
	print("ok " if ok else "FAIL ",name," ",detail)
	if not ok:failures+=1
func run()->void:
	root.size=Vector2i(800,600)
	var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color.BLACK;env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	var we:=WorldEnvironment.new();we.environment=env;root.add_child(we)
	camera.fov=25.;camera.current=true;root.add_child(camera)
	sf.set_custom_stars([]);sf.build();root.add_child(sf)
	sv.setup(sf,false);sv.set_view(2*tan(deg_to_rad(12.5))/600.,600.);root.add_child(sv)
	var sim:=SimBridge.new();sim.want_minor=5
	if not sim.start() or not sim.new_game(19):push_error(sim.last_error);quit(1);return
	var sys:Dictionary=sim.world.system.duplicate(true);var body:Dictionary={};var ring:Dictionary={}
	for b:Dictionary in sys.bodies:
		if b.id=="saturn":body=b.duplicate(true)
	for rr:Dictionary in sys.rings:
		if rr.host=="saturn":ring=rr
	check("actual minor5 Saturn ring bands",ring.get("bands",[]).size()==11)
	var d:=1500000.;var r:float=body.radius_km
	body.rel_km={"x":d,"y":0.0,"z":0.0}
	var pole_gal:=SkyFrame.to_galactic64([0,.8,.6]);body.pole={"x":pole_gal[0],"y":pole_gal[1],"z":pole_gal[2]}
	var f:=300./tan(deg_to_rad(12.5));var radius:=10*r/d;var centre:=Vector3(0,0,-10);var pole:=Vector3(0,.8,.6)
	var lux:=Planets.star_illuminance_at(E1,body.r_au);var rho:=Planets.rho_from_geometric_albedo(body.p_v,body.minnaert_k)
	var exposure:=1.4/(rho*lux/PI)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/m5/rings"))
	for side in [1.,-1.]:
		var sun:=Vector3(.8,0,.6*side);var sg:=SkyFrame.to_galactic64([sun.x,sun.y,sun.z]);body.sun_dir={"x":sg[0],"y":sg[1],"z":sg[2]};body.phase_deg=rad_to_deg(acos(sun.z))
		body.e_v_lux=Planets.disc_illuminance(E1,body.p_v,r,body.r_au,d,deg_to_rad(body.phase_deg),body.minnaert_k)
		sv.update({"bodies":[body],"rings":[ring]},exposure)
		print("e1 ratio",sv.e1_au/E1," k",body.minnaert_k," pole",(sv.discs.saturn.material_override as ShaderMaterial).get_shader_parameter("body_basis").z)
		for j in 5:await process_frame
		await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image();var tested:=0;var max_error:=0.;var shadow_samples:=0;var transmitted_samples:=0
		for y in range(180,420,3):
			for x in range(180,620,3):
				var ray:=Vector3((x+.5-400)/f,-(y+.5-300)/f,-1).normalized()
				var along:=ray.dot(centre);var perpendicular:=centre-along*ray;var h2:=radius*radius-perpendicular.length_squared()
				if absf(h2)<radius*radius*.06:continue # resolved sample, away from supersample limb
				var gd:=1e30;var color:=Vector3.ZERO;var globe:=false
				if along>0 and h2>=0:
					gd=along-sqrt(h2);var n:Vector3=(ray*gd-centre)/radius;var ci:=n.dot(sun);var ce:=n.dot(-ray)
					if ci>0:
						var p:=PackedFloat64Array([n.x*r,n.y*r,n.z*r])
						var sh:=Planets.ring_plane_hit(p,PackedFloat64Array([sun.x,sun.y,sun.z]),PackedFloat64Array([pole.x,pole.y,pole.z]))
						var near_shadow_edge:=false
						if sh.hits:
							for edge:Dictionary in ring.bands:
								if minf(absf(sh.radius-edge.r_in_km),absf(sh.radius-edge.r_out_km))<5000.:near_shadow_edge=true
						if near_shadow_edge:continue
						var shadow:=Planets.ring_shadow_transmission(ring.bands,p,PackedFloat64Array([sun.x,sun.y,sun.z]),PackedFloat64Array([pole.x,pole.y,pole.z]))
						color=Blackbody.rgb_unit_luminance(5772.)*Planets.minnaert_radiance(rho,body.minnaert_k,lux,ci,ce)*shadow*exposure
						if shadow<.99:transmitted_samples+=1
					globe=true
				var rh:=Planets.ring_plane_hit(PackedFloat64Array([-centre.x,-centre.y,-centre.z]),PackedFloat64Array([ray.x,ray.y,ray.z]),PackedFloat64Array([pole.x,pole.y,pole.z]))
				if rh.hits and rh.distance<gd:
					var band:=Planets.ring_band(ring.bands,rh.radius*r/radius)
					if band.tau<=0.:continue
					var pos:Vector3=ray*rh.distance-centre
					var band_r:=pos.length()*r/radius
					if minf(band_r-band.r_in_km,band.r_out_km-band_r)<3000.:continue # band edge antialiasing
					var perpendicular_sun:=pos-pos.dot(sun)*sun;var sphere_shadow:=pos.dot(sun)<0 and perpendicular_sun.length_squared()<radius*radius
					if absf(perpendicular_sun.length()-radius)<radius*.06:continue
					var mu:=absf(ray.dot(pole));var mu0:=absf(sun.dot(pole));var lit:=(-ray).dot(pole)*sun.dot(pole)>0
					var l:=0. if sphere_shadow else (Planets.ring_lit_radiance(band.w0,1.,band.tau,mu0,mu,lux) if lit else Planets.ring_unlit_radiance(band.w0,1.,band.tau,mu0,mu,lux))
					color=Vector3(ring.tint.r,ring.tint.g,ring.tint.b)*l*exposure+Planets.ring_transmission(band.tau,mu)*color
					if sphere_shadow:shadow_samples+=1
				elif not globe:continue
				if color.length()<.06 or maxf(color.x,maxf(color.y,color.z))>.9:continue
				color=Vector3.ZERO
				for jy in 3:
					for ix in 3:
						var sx:=x+(ix+.5)/3.;var sy:=y+(jy+.5)/3.
						var nr:=Vector3((sx-400)/f,-(sy-300)/f,-1).normalized()
						color+=sv.ray_colour(PackedFloat64Array([nr.x,nr.y,nr.z]))*exposure/9.
				var got:=img.get_pixel(x,y).srgb_to_linear();var value:=Vector3(got.r,got.g,got.b)
				var error:=value.distance_to(color)/color.length();if error>max_error:
					print("worst side",side," xy",x,",",y," got",value," want",color," error",error," globe",globe)
				max_error=maxf(max_error,error);tested+=1
		check("ring/globe radiance and transmission side%.0f"%side,tested>200 and max_error<.02,"%d samples maxerr%.4f"%[tested,max_error])
		check("globe-on-ring shadow samples side%.0f"%side,shadow_samples>5,str(shadow_samples))
		check("ring-on-globe shadow samples side%.0f"%side,transmitted_samples>5,str(transmitted_samples))
		var edge:=_shadow_edges(img,centre,radius,pole,sun,f,ring,r,exposure)
		check("analytic globe shadow edge side%.0f"%side,edge.x>=8 and edge.y<.75,"%d edges max %.4fpx"%[int(edge.x),edge.y])
		var ring_edge:=_ring_shadow_edges(img,centre,radius,pole,sun,f,ring,r,exposure)
		check("analytic ring shadow edge side%.0f"%side,ring_edge.x>=8 and ring_edge.y<.75,"%d edges max %.4fpx"%[int(ring_edge.x),ring_edge.y])
		img.save_png("res://renders/m5/rings/saturn_side%.0f.png"%side)
	sim.stop();sv.queue_free();sf.queue_free();camera.queue_free();await process_frame
	print("ring-golden: %d failures"%failures);quit(1 if failures else 0)

func _shadow_point(psi:float,radius:float,pole:Vector3,sun:Vector3)->Vector3:
	var u:=Vector3.RIGHT*cos(psi)+pole.cross(Vector3.RIGHT)*sin(psi)
	return u*radius/sqrt(1.-pow(u.dot(sun),2.))

func _project(p:Vector3,f:float)->Vector2:
	return Vector2(400.+f*p.x/-p.z,300.-f*p.y/-p.z)

func _pixel_linear(img:Image,p:Vector2)->float:
	var q:=p-Vector2(.5,.5);var ix:=int(floor(q.x));var iy:=int(floor(q.y))
	var a:=img.get_pixel(ix,iy).srgb_to_linear().r;var b:=img.get_pixel(ix+1,iy).srgb_to_linear().r
	var c:=img.get_pixel(ix,iy+1).srgb_to_linear().r;var d:=img.get_pixel(ix+1,iy+1).srgb_to_linear().r
	return lerpf(lerpf(a,b,q.x-ix),lerpf(c,d,q.x-ix),q.y-iy)

func _shadow_edges(img:Image,centre:Vector3,radius:float,pole:Vector3,sun:Vector3,f:float,ring:Dictionary,r:float,k:float)->Vector2:
	var count:=0;var error:=0.
	for j in 7200:
		var psi:=TAU*j/7200.;var p:=_shadow_point(psi,radius,pole,sun)
		if p.dot(sun)>=0.:continue
		var band:=Planets.ring_band(ring.bands,p.length()*r/radius)
		if band.tau<=0. or minf(p.length()*r/radius-band.r_in_km,band.r_out_km-p.length()*r/radius)<5000.:continue
		var screen:=_project(centre+p,f)
		var tangent:=(_project(centre+_shadow_point(psi+.001,radius,pole,sun),f)-_project(centre+_shadow_point(psi-.001,radius,pole,sun),f)).normalized()
		var normal:=Vector2(-tangent.y,tangent.x);var ends:=[]
		for side in [-1.,1.]:
			var q:Vector2=screen+normal*3.*side;var nr:=Vector3((q.x-400.)/f,-(q.y-300.)/f,-1.).normalized()
			ends.append(sv.ray_colour(PackedFloat64Array([nr.x,nr.y,nr.z])).x*k)
		if maxf(ends[0],ends[1])>.9 or maxf(ends[0],ends[1])<.04 or minf(ends[0],ends[1])>maxf(ends[0],ends[1])*.02:continue
		# Reject a nearby globe limb or radial band transition: the isolated
		# illuminated side must retain its ring radiance up to this shadow edge.
		var lit_sign:float=-1. if ends[0]>ends[1] else 1.
		var qlit:=screen+normal*.8*lit_sign
		var nr_lit:=Vector3((qlit.x-400.)/f,-(qlit.y-300.)/f,-1.).normalized()
		var lit_value:=sv.ray_colour(PackedFloat64Array([nr_lit.x,nr_lit.y,nr_lit.z])).x*k
		if absf(lit_value/maxf(ends[0],ends[1])-1.)>.05:continue
		var threshold:float=maxf(ends[0],ends[1])*.5;var best:=100.
		var previous:=_pixel_linear(img,screen-normal*2.)-threshold
		for step in range(1,65):
			var offset:float=-2.+step/16.;var value:=_pixel_linear(img,screen+normal*offset)-threshold
			if previous*value<=0.:
				var crossing:=offset-1./16.+absf(previous)/(absf(previous)+absf(value))/16.
				best=minf(best,absf(crossing))
			previous=value
		if best<100.:
			if best>.75:print("edge mismatch psi",psi," screen",screen," ends",ends," offset",best)
			count+=1;error=maxf(error,best)
	return Vector2(count,error)

func _ring_shadow_edges(img:Image,centre:Vector3,radius:float,pole:Vector3,sun:Vector3,f:float,ring:Dictionary,r:float,k:float)->Vector2:
	var count:=0;var error:=0.
	# Project the producer's actual band boundaries along the Sun ray onto
	# the illuminated sphere. This is the analytic ring-shadow contour.
	for band:Dictionary in ring.bands:
		var rr:float=band.r_out_km*radius/r
		for j in 1440:
			var psi:=TAU*j/1440.;var q:=rr*(Vector3.RIGHT*cos(psi)+pole.cross(Vector3.RIGHT)*sin(psi))
			var along:=q.dot(sun);var delta:=radius*radius-q.length_squared()+along*along
			if delta<=0. or along<=0.:continue
			var p:=q-(along-sqrt(delta))*sun
			if p.z<=radius*.2:continue
			var screen:=_project(centre+p,f)
			# Screen gradient of radius where the sunlight ray crosses ring plane.
			var grad:=Vector2.ZERO
			for axis in 2:
				var delta_px:=Vector2.RIGHT if axis==0 else Vector2.DOWN;var radii:=[]
				for sign_ in [-1.,1.]:
					var sp:Vector2=screen+delta_px*.1*sign_;var ray:=Vector3((sp.x-400.)/f,-(sp.y-300.)/f,-1.).normalized()
					var projection:=ray.dot(centre);var disc:=radius*radius-(centre-projection*ray).length_squared()
					if disc<=0.:radii.append(0.);continue
					var surface:=ray*(projection-sqrt(disc))-centre
					var hit:=Planets.ring_plane_hit(PackedFloat64Array([surface.x,surface.y,surface.z]),PackedFloat64Array([sun.x,sun.y,sun.z]),PackedFloat64Array([pole.x,pole.y,pole.z]))
					radii.append(hit.radius if hit.hits else 0.)
				grad[axis]=(radii[1]-radii[0])/.2
			if grad.length()<1e-6:continue
			var normal:=grad.normalized();var ends:=[]
			for sign_ in [-1.,1.]:
				var sp:Vector2=screen+normal*1.5*sign_;var ray:=Vector3((sp.x-400.)/f,-(sp.y-300.)/f,-1.).normalized()
				ends.append(sv.ray_colour(PackedFloat64Array([ray.x,ray.y,ray.z])).x*k)
			var bright:float=maxf(ends[0],ends[1]);var dark:float=minf(ends[0],ends[1])
			if bright>.9 or bright<.08 or dark>bright*.25:continue
			var isolated:=true
			for side_index in 2:
				var sign_:float=-1. if side_index==0 else 1.
				var sp:Vector2=screen+normal*.3*sign_;var ray:=Vector3((sp.x-400.)/f,-(sp.y-300.)/f,-1.).normalized()
				var local:=sv.ray_colour(PackedFloat64Array([ray.x,ray.y,ray.z])).x*k
				if absf(local-ends[side_index])>bright*.04:isolated=false
			if not isolated:continue
			var threshold:float=(bright+dark)*.5;var previous:=_pixel_linear(img,screen-normal*1.5)-threshold;var best:=100.
			for step in range(1,49):
				var offset:float=-1.5+step/16.;var value:=_pixel_linear(img,screen+normal*offset)-threshold
				if previous*value<=0.:best=minf(best,absf(offset-1./16.+absf(previous)/(absf(previous)+absf(value))/16.))
				previous=value
			if best<100.:count+=1;error=maxf(error,best)
	return Vector2(count,error)
