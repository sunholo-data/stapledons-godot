extends SceneTree
## M5.3 standalone GPU vs pinned package limb and CPU photopic LUT.
var failures:=0
var sv:=SystemView.new()
var camera:=FreeLookCamera.new()
var sf:=Starfield.new()
func _initialize()->void:run.call_deferred()
func check(name:String,ok:bool,detail:String="")->void:
	print("ok " if ok else "FAIL ",name," ",detail)
	if not ok:failures+=1
func run()->void:
	root.size=Vector2i(800,600)
	var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color.BLACK;env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	var we:=WorldEnvironment.new();we.environment=env;root.add_child(we)
	camera.fov=35.;root.add_child(camera);camera.current=true
	sf.set_custom_stars([]);sf.build();root.add_child(sf)
	sv.setup(sf,false);sv.relativistic_enabled=true;sv.set_view(2*tan(deg_to_rad(17.5))/600.,600.);root.add_child(sv)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/m5/flyby"))
	for line in FileAccess.get_file_as_string("res://tests/fixtures/flyby_package.jsonl").split("\n",false):
		var r:Array=JSON.parse_string(line);var beta:float=r[0];var theta:float=r[1];var gamma:float=r[2];var omb:float=r[3]
		var centre:float=r[4];var radius:float=r[5]
		var b:Dictionary=load("res://tools/m5_golden.gd").body("uniform",71492.,71492./sin(deg_to_rad(5)),.538,1.)
		var gal:=SkyFrame.to_galactic64([sin(theta),0,-cos(theta)]);var dist:float=71492./sin(deg_to_rad(5))
		b.rel_km={"x":gal[0]*dist,"y":gal[1]*dist,"z":gal[2]*dist};b.kind="star"
		sv.set_velocity(Vector3(0,0,-1),beta,gamma,omb);sv.update({"bodies":[b]},1.)
		var mat:ShaderMaterial=sv.discs.uniform.material_override
		var dc:=Planets.doppler_seen64(PackedFloat64Array([sin(centre),0,-cos(centre)]),PackedFloat64Array([0,0,-1]),beta,gamma,omb)
		var base:=.2/pow(10.,Blackbody.lut_log10_y(5772.*dc)-Blackbody.lut_log10_y(5772.))
		mat.set_shader_parameter("limb_u",0.);mat.set_shader_parameter("star_mean",base);mat.set_shader_parameter("exposure",1.)
		camera.look(-centre,0.,0.)
		for j in 5:await process_frame
		await RenderingServer.frame_post_draw
		var img:=root.get_texture().get_image()
		var f:=300./tan(deg_to_rad(17.5));var expected:=f*tan(radius)
		var edge_errors:=PackedFloat64Array();var left:=800;var right:=-1;var top:=600;var bottom:=-1
		for y in 600:
			var first:=-1;var last:=-1
			for x in 800:
				var col:=img.get_pixel(x,y)
				if col.r+col.g+col.b>0.00001:
					left=mini(left,x);right=maxi(right,x);top=mini(top,y);bottom=maxi(bottom,y)
					if first<0:first=x
					last=x
			if first>=0:
				for xx in [first,last]:edge_errors.append(Vector2(xx+.5-400,y+.5-300).length())
		check("package apparent limb beta%.2f theta%.0f"%[beta,rad_to_deg(theta)],right>=left and absf((right-left)/2.-expected)<.75 and absf((bottom-top)/2.-expected)<.75,"expected%.3f actual%.3f/%.3f"%[expected,(right-left)/2.,(bottom-top)/2.])
		if beta==.9 and is_equal_approx(theta,PI/2):
			var mean:=0.;for v in edge_errors:mean+=v
			mean/=edge_errors.size();var variance:=0.;for v in edge_errors:variance+=(v-mean)*(v-mean)
			check("conformal limb circle RMS",sqrt(variance/edge_errors.size())<.5,"RMS%.4f px"%sqrt(variance/edge_errors.size()))
		check("apparent centre beta%.2f theta%.0f"%[beta,rad_to_deg(theta)],right>=left and absf((left+right+1)/2.-400)<.75 and absf((top+bottom+1)/2.-300)<.75)
		for offset in [-.6,0.,.6]:
			var x:=int(400+offset*expected);var u:float=(x+.5-400)/f;var n:=PackedFloat64Array([sin(centre)+u*cos(centre),0.,-cos(centre)+u*sin(centre)]);var len:=Planets.length64(n);for k in 3:n[k]/=len
			var d:=Planets.doppler_seen64(n,PackedFloat64Array([0,0,-1]),beta,gamma,omb)
			var want:=Blackbody.rgb_unit_luminance(5772.)*base
			if beta>0:
				var rest:=Blackbody.lut_rgb(5772.);var seen:=Blackbody.lut_rgb(5772.*d);want=want*seen/rest*pow(10.,Blackbody.lut_log10_y(5772.*d)-Blackbody.lut_log10_y(5772.))
			var got:=img.get_pixel(x,300).srgb_to_linear();var gv:=Vector3(got.r,got.g,got.b)
			check("spatial Doppler radiance",gv.distance_to(want)/maxf(want.length(),1e-12)<.01,"beta%.2f D%.5f ratioerr%.4f"%[beta,d,gv.distance_to(want)/maxf(want.length(),1e-12)])
		img.save_png("res://renders/m5/flyby/uniform_b%.2f_t%.0f.png"%[beta,rad_to_deg(theta)])
	sv.queue_free();sf.queue_free();camera.queue_free();await process_frame
	print("flyby-golden: %d failures"%failures);quit(1 if failures else 0)
