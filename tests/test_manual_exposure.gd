extends SceneTree
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
 checks+=1
 if not ok:failures+=1;print("FAIL ",label)
func _initialize()->void:run.call_deferred()
func run()->void:
 var demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"live_start":true,"sky_state":"rest","stars":false,"background":false,"planet_textures":false,"planet_preload":false}
 root.add_child(demo);await process_frame
 check("actual current demo starts",demo.ready_ok and demo.journey_sim!=null)
 if not demo.ready_ok or demo.journey_sim==null:quit(1);return
 var sky:InteriorSky=demo.sky
 var expected:=sky.exposure.ev_dark()-2.
 check("default is manual dark reference plus approved4x",sky.exposure.fixed and not sky.temporal_exposure and absf(sky.exposure.ev-expected)<1e-12)
 check("HUD states manual exposure",demo.brightness_label().contains("Manual sky exposure EV") and not demo.brightness_label().contains("anticipation"))
 var live_samples:=sky.meter_sample_count
 var live_start:float=demo.journey_sim.world.clock.tau
 for i in 30:
  if i%3==0:demo.journey_tick()
  demo.camera.tilt=float(i)*5.-70.;demo.camera.yaw=i*.1
  await process_frame
  check("actual auto=true processing retains manualEV "+str(i),demo.auto and sky.exposure.fixed and not sky.temporal_exposure and sky.exposure.ev==expected)
 check("live pipeline advanced authoritative world",demo.journey_sim.world.clock.tau>live_start)
 check("live pipeline never invokes automatic meter",sky.meter_sample_count==live_samples)
 demo.auto=false;demo.set_process(false)
 var count:=sky.meter_sample_count
 var preparations:=sky.system_view.preparation_count
 for i in 120:
  if i%3==0:sky.apply(demo.sky_world)
  demo.camera.follow(demo.avatar_pos,sin(i*.1)*85.,i*.03,0.);demo._sync_observer();sky.finish_exposure_frame(1./60.,1000+i)
  check("actual Sol camera/world changes preserve EV "+str(i),sky.exposure.ev==expected)
 check("manual display never samples automatic meter",sky.meter_sample_count==count)
 check("unchanged physical body buffers are cached",sky.system_view.preparation_count-preparations<=1)
 check("actual Solar startup",demo.start_solar_departure())
 expected=sky.exposure.ev_dark()-2.
 var source:Dictionary=demo.journey_sim.world.duplicate(true)
 for i in 60:
  sky.apply(source);demo.camera.follow(demo.avatar_pos,float(i)*3.-89.,i*.1,0.);demo._sync_observer();sky.finish_exposure_frame(1./60.,2000+i)
  check("nearEarth view never changes manualEV "+str(i),sky.exposure.ev==expected)
 check("planet pipeline retained",not sky.system_view.rendered_bodies.is_empty() and sky.system_view.drawn_discs.has("earth"))
 check("rendering does not change authoritative source",demo.journey_sim.world==source)
 var event:InputEventKey
 # D-38 Realistic/Auto view: the body fader is display-only and never touches the sky exposure.
 var sv:SystemView=sky.system_view
 var k:=sky.exposure.k()
 check("Realistic view is the default",not sv.body_fader and demo.brightness_label().begins_with("REALISTIC view"))
 for id:String in sv.drawn_discs:check("Realistic disc keeps one exposure "+id,sv.fader_gain(id,k)==1.0)
 var star_scale:float=sky.exposure.star_scale()
 demo.set_auto_view(true);sky.apply(source);demo._sync_observer();sky.finish_exposure_frame(.05,4000)
 check("Auto keeps manual sky EV",sky.exposure.ev==expected and sky.exposure.fixed and sky.exposure.star_scale()==star_scale)
 var earth_gain:=sv.fader_gain("earth",k)
 check("Auto dims sunlit Earth by > 10 stops",earth_gain>0.0 and earth_gain<pow(2.,-10.))
 check("Auto lands Earth's peak at the fader target",absf(sv._fader_peak["earth"]*k*earth_gain-SystemView.FADER_TARGET)<1e-9)
 var earth_param:float=(sv.discs["earth"].material_override as ShaderMaterial).get_shader_parameter("exposure")
 check("Auto Earth disc uniform carries the gain",absf(earth_param-k*sv.lod_weights["earth"]*earth_gain)<=1e-12*k)
 for id:String in sv.drawn_discs+sv.drawn_points:check("fader never brightens "+id,sv.fader_gain(id,k)<=1.0)
 check("Auto HUD labels the composite",demo.brightness_label().begins_with("AUTO view") and demo.brightness_label().contains("composite"))
 event=InputEventKey.new();event.physical_keycode=KEY_V;event.pressed=true
 demo._unhandled_input(event);sky.finish_exposure_frame(.05,4001)
 check("V returns to Realistic",not sv.body_fader and sv.fader_gain("earth",k)==1.0)
 earth_param=(sv.discs["earth"].material_override as ShaderMaterial).get_shader_parameter("exposure")
 check("Realistic Earth disc back at physical exposure",absf(earth_param-k*sv.lod_weights["earth"])<=1e-12*k)
 for stops:int in demo.BRIGHTNESS_STOPS:
  check("manual preset accepted "+str(stops),demo.set_brightness_trial(stops))
  var ev:float=sky.exposure.ev_dark()-stops
  check("manualEV follows user preset "+str(stops),sky.exposure.ev==ev and sky.exposure.fixed_ev==ev)
  for i in 3:sky.apply(source);demo._sync_observer();sky.finish_exposure_frame(.05,3000+stops*10+i)
  check("bright bodies cannot override dim preset "+str(stops),sky.exposure.ev==ev)
  check("preset only changes shared presentationK "+str(stops),sky.starfield.material.get_shader_parameter("exposure")==sky.exposure.star_scale())
 check("negative stops label dimming accurately",demo.set_brightness_trial(-16) and demo.brightness_label().contains("16 stops dimmer"))
 demo.set_brightness_trial(2)
 event=InputEventKey.new();event.physical_keycode=KEY_J;event.pressed=true
 demo._unhandled_input(event)
 check("J selects explicit next preset",demo.brightness_stops==4 and sky.exposure.fixed_ev==sky.exposure.ev_dark()-4.)
 check("legacy invalid preset remains rejected",not demo.set_brightness_trial(7))
 demo.queue_free();await process_frame
 print("manual-exposure: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
