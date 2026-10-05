extends SceneTree
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",label)
func _initialize()->void:run.call_deferred()
func run()->void:
	var sf:=Starfield.new();sf.set_custom_stars([]);sf.build();sf.point_overlay=true;root.add_child(sf)
	var sv:=SystemView.new();sv.setup(sf,false);root.add_child(sv)
	check("presentation cost and transition diagnostics exist",sv.has_method("presentation_stats"))
	check("native transition harness compiles",(load("res://tools/planet_transition_golden.gd") as GDScript).can_instantiate())
	check("CPU presentation benchmark compiles",(load("res://tools/planet_cpu_bench.gd") as GDScript).can_instantiate())
	if not sv.has_method("presentation_stats"):
		print("planet-presentation: %d checks %d failures"%[checks,failures]);quit(1);return
	var sim:=SimBridge.new();sim.want_minor=5;check("normal authoritative fixture",sim.start() and sim.new_game(42))
	if sim.world.is_empty():print(sim.last_error);quit(1);return
	var b:Dictionary={}
	for bb:Dictionary in sim.world.system.bodies:
		if bb.id=="moon":b=bb.duplicate(true)
	sv.lod_range=Vector2(1.5,3.5);sv.set_view(.001,600.)
	var previous:=0.;var max_step:=0.
	for j in 201:
		var diameter:=1.4+j*.011
		var dist:float=b.radius_km/sin(diameter*.001*.5)
		b.rel_km={"x":dist,"y":0.,"z":0.};b.sun_dir={"x":-1.,"y":0.,"z":0.};b.phase_deg=0.
		b.e_v_lux=Planets.disc_illuminance(127057.41052085394,b.p_v,b.radius_km,b.r_au,dist,0.,b.minnaert_k)
		sv.update({"bodies":[b]},1.)
		var weight:float=sv.lod_weights.moon
		check("nonnegative complementary emission weights %d"%j,weight>=0. and weight<=1. and absf(weight+(1.-weight)-1.)<1e-12)
		max_step=maxf(max_step,absf(weight-previous));previous=weight
		if sf.point_count>0:
			var point_flux:float=sf._point_custom[1]*sf._point_custom[3]/(Starfield.POINT_LY*Starfield.POINT_LY)
			check("weighted point buffer conserves authoritative flux %d"%j,absf(point_flux/b.e_v_lux-(1.-weight))<1e-6)
		if sv.discs.has("moon") and sv.discs.moon.visible:
			check("disc uniform receives complementary weight %d"%j,absf(sv.discs.moon.material_override.get_shader_parameter("exposure")-weight)<1e-6)
		check("physical opaque coverage independent of emission LOD %d"%j,sv.occludes_direction(PackedFloat64Array([0,0,-1])))
	check("continuous handoff has bounded adjacent weight change",max_step<.009)
	check("planet overlay separate from catalogue star material",sf.point_material!=null and sf.point_material.render_priority==127 and sf.material.render_priority==0)
	sf.set_velocity(Vector3.RIGHT,.5,1./sqrt(.75));sf.set_exposure(7.)
	check("overlay preserves authoritative optics uniforms",sf.point_material.get_shader_parameter("beta_mag")==.5 and sf.point_material.get_shader_parameter("gamma_f")==sf.material.get_shader_parameter("gamma_f") and sf.point_material.get_shader_parameter("exposure")==7.)
	var stats:=sv.presentation_stats();var system:={"bodies":[b]}
	for i in 100:sv.update(system,2.)
	var after:=sv.presentation_stats()
	check("unchanged metering avoids body preparation",after.preparations==stats.preparations and after.reuses-stats.reuses==100)
	sv.set_view(.002,600.);sv.update(system,2.)
	check("pixel calibration invalidates preparation",sv.presentation_stats().preparations==after.preparations+1)
	var before_velocity:int=sv.presentation_stats().preparations
	sv.set_velocity(Vector3.RIGHT,.5,1./sqrt(.75),.5);sv.update(system,2.)
	check("velocity invalidates preparation",sv.presentation_stats().preparations==before_velocity+1)
	sv.set_velocity(Vector3.RIGHT,0.,1.,1.);sv.set_view(.001,600.)
	var jupiter:Dictionary={}
	for body:Dictionary in sim.world.system.bodies:
		if body.id=="jupiter":jupiter=body.duplicate(true)
	jupiter.rel_km={"x":300000.,"y":0.,"z":0.};jupiter.sun_dir={"x":1.,"y":0.,"z":0.};jupiter.phase_deg=180.
	b.rel_km={"x":5000000.,"y":0.,"z":0.}
	sv.update({"bodies":[jupiter,b]},1.)
	check("farther unresolved moon stays behind opaque night globe",not sv.drawn_points.has("moon") and sf.point_count==0)
	b.rel_km={"x":200000.,"y":0.,"z":0.};b.radius_km=10.
	sv.update({"bodies":[jupiter,b]},1.)
	check("foreground unresolved moon remains visible",sv.drawn_points.has("moon") and sf.point_count==1)
	jupiter.kind="star";jupiter.id="foreground_sun";b.rel_km.x=5000000.
	sv.update({"bodies":[jupiter,b]},1.)
	check("foreground Sun masks farther unresolved moon",not sv.drawn_points.has("moon") and sf.point_count==0)
	var art:=SystemView.new();art.setup(null,true);art.preload_textures(["earth","jupiter","saturn"])
	check("bounded warmup prepares requested maps and CPU images",art.textures.size()==3 and art.meter_images.earth.size()==2 and art.preload_bytes<40*1024*1024)
	var initial_bytes:=art.preload_bytes;art.preload_textures(["earth"])
	check("warmup reuses maps without allocations",art.preload_bytes==initial_bytes)
	print("presentation stats ",sv.presentation_stats()," warmup ",art.presentation_stats())
	var sky:=InteriorSky.new();root.add_child(sky);sky.setup({"position_m":[8,4.8,83.7],"forward":[0,0,1],"up":[0,1,0]},78.,Vector2i(1280,720),{"stars":false,"background":false,"planet_textures":false})
	sky.apply(sim.world);var heading:=sky.heading_gal.duplicate();var world_heading:=sky.heading_world;var beta:=sky.beta
	sky.orient_basis(ShipFrame.ship_basis(PackedFloat64Array([0,1,0])))
	check("attitude override leaves authoritative observer motion unchanged",sky.heading_gal==heading and sky.heading_world==world_heading and sky.beta==beta)
	sim.stop();sky.queue_free();art.free();sv.queue_free();sf.queue_free();await process_frame
	print("planet-presentation: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
