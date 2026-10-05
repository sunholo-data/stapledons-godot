extends SceneTree
var failures:=0
var checks:=0
func check(name:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",name)
func _initialize()->void:run.call_deferred()
func run()->void:
	var exposure:=Exposure.new();check("approved highlight meter exists",exposure.has_method("highlight_ev"))
	if exposure.has_method("highlight_ev"):
		var sky:=InteriorSky.new();root.add_child(sky)
		sky.setup({"position_m":[8,4.8,83.7],"forward":[0,0,1],"up":[0,1,0]},78.,Vector2i(1280,720),{"stars":false,"background":false,"planet_textures":false})
		var sim:=SimBridge.new();sim.want_minor=5;check("normal real session",sim.start() and sim.new_game(11))
		sky.apply(sim.world);var baseline:=sky.exposure.ev
		check("dark/Sun-centre sparse planets keep baseline",absf(baseline-sky.exposure.ev_dark())<1e-10)
		var source:=sim.world.duplicate(true)
		for id in ["earth","saturn"]:
			var b:Dictionary={}
			for bb:Dictionary in source.system.bodies:
				if bb.id==id:b=bb.duplicate(true)
			b.rel_km={"x":50000.0 if id=="earth" else 500000.0,"y":0.0,"z":0.0};b.sun_dir={"x":-1.0,"y":0.0,"z":0.0};b.phase_deg=0.0
			b.e_v_lux=Planets.disc_illuminance(127057.41052085394,b.p_v,b.radius_km,b.r_au,b.rel_km.x,0.,b.minnaert_k)
			var world:=source.duplicate(true);world.system.bodies=[b]
			sky.apply(world);sky.camera.look(0.,0.,0.);sky.update_exposure()
			var p99:float=sky.system_view.call("highlight_luminance",sky.camera,Vector2(sky.size))
			check(id+" physical radiance reaches eye/highlight meter",p99>1.0 and sky.exposure.ev>baseline+10.)
			check(id+" shared scene-linear highlight target",p99*sky.exposure.k()<=1.01)
			sky.exposure.bias=-2.;sky.update_exposure()
			check(id+" approved 4x bias retains automatic highlight protection",p99*sky.exposure.k()<=1.01)
			check(id+" biased camera mode also protects resolved disc",_camera_mode(sky,p99))
			sky.exposure.bias=0.
			check(id+" camera mode protects resolved disc",_camera_mode(sky,p99))
			sky.exposure.fixed=true;sky.exposure.fixed_ev=baseline;sky.update_exposure()
			check(id+" explicit fixed EV remains fixed",sky.exposure.ev==baseline)
			sky.exposure.bias=-2.;sky.update_exposure()
			check(id+" biased fixed EV remains explicitly locked",sky.exposure.ev==baseline)
			sky.exposure.bias=0.
			sky.exposure.fixed=false;sky.exposure.mode=Exposure.Mode.EYE
			sky.camera.look(PI,0.,0.);sky.update_exposure()
			check(id+" looking away restores dark-adapted exposure",absf(sky.exposure.ev-baseline)<1e-10)
		var solar:Dictionary={}
		for bb:Dictionary in source.system.bodies:
			if bb.kind=="star":solar=bb.duplicate(true)
		solar.rel_km={"x":149597870.7,"y":0.,"z":0.};solar.e_v_lux=127057.41052085394
		var sun_world:=source.duplicate(true);sun_world.system.bodies=[solar]
		sky.apply(sun_world);sky.camera.look(0.,0.,0.);sky.update_exposure()
		check("compact Sun flux is integrated despite sparse disc samples",sky.system_view.compact_meter_sources().size()==1 and sky.exposure.ev>baseline+15.)
		sky.camera.look(PI,0.,0.);sky.update_exposure()
		check("compact Sun outside view leaves dark sky unchanged",absf(sky.exposure.ev-baseline)<1e-10)
		sky.exposure.bias=-2.;sky.update_exposure()
		check("clear dark sky retains approved 4x brightness",absf(sky.exposure.ev-(baseline-2.))<1e-10)
		check("metering leaves authoritative sim world unchanged",sim.world==source)
		sim.stop();sky.queue_free();await process_frame
	print("planet-meter: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
func _camera_mode(sky:InteriorSky,p99:float)->bool:
	sky.exposure.mode=Exposure.Mode.CAMERA;sky.update_exposure();return p99*sky.exposure.k()<=1.01
