extends SceneTree
## Native current-game recovery evidence: real Sol startup and an actual
## committed voyage state; manual fixed exposure, unchanged SR and catalogue.
var failed:=false
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(1280,800)
 var demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"live_start":true,"sky_state":"rest"};root.add_child(demo)
 await process_frame
 if not demo.ready_ok or demo.journey_sim==null:print("exposure-sky-recovery: startup FAIL");quit(1);return
 var samples:int=demo.sky.meter_sample_count
 var locked_ev:float=demo.sky.exposure.ev
 for i in 60:
  if i%3==0:demo.journey_tick()
  await process_frame
  if not demo.auto or not demo.sky.exposure.fixed or demo.sky.exposure.ev!=locked_ev:failed=true
 if demo.sky.meter_sample_count!=samples:failed=true
 print("NATIVE DEFAULT auto=true frames=60 fixedEV=",locked_ev," automatic_meter_samples=",demo.sky.meter_sample_count-samples)
 demo.auto=false;demo.set_process(false);demo.close_navigation()
 var records:=[];var output:="res://renders/ship_demo/exposure_recovery"
 DirAccess.make_dir_recursive_absolute(output)
 for phase:String in ["rest","cruise"]:
  if phase=="cruise":
   demo.journey_map.preselect(demo.journey_map.index_of("CNS5:3627"));demo.journey_map.tick()
   demo.journey_map.open_commit_dialog();demo.journey_map.hold_commit(GalaxyMap.HOLD_S);demo.journey_map.tick()
   var plan:Dictionary=demo.journey_sim.world.journey.plan
   var burn:float=plan.boost_minutes/(365.25*24.*60.)
   if not demo.journey_sim.send([],burn*1.1):failed=true
   demo._apply_journey_world()
   if demo.journey_sim.world.ship.phase!="cruising":failed=true
  for view:String in ["forward","side","back"]:
   var tilt:=89.5 if view=="forward" else (-89.5 if view=="back" else 0.)
   demo.camera.follow(demo.avatar_pos,tilt,0.,0.);demo._sync_observer()
   demo.sky.set_temporal_exposure(false)
   for i in 120:
    if i%3==0:demo.sky.apply(demo.sky_world);demo._sync_observer()
    demo.sky.finish_exposure_frame(1./60.)
    await process_frame
   demo._process(0.) # Refresh the HUD from the same authoritative captured state.
   await process_frame
   await RenderingServer.frame_post_draw
   var name:=phase+"_"+view
   demo.sky.get_texture().get_image().save_png(output.path_join(name+".png"))
   root.get_texture().get_image().save_png(output.path_join(name+"_ship.png"))
   var sky=demo.sky
   var record={"name":name,"beta":sky.beta,"phase":demo.sky_world.ship.phase,"ev":sky.exposure.ev,"base_ev":sky.exposure.mode_ev(sky._meter_samples[0],sky._meter_samples[1])+sky.exposure.bias,"automatic_exposure":false,"manual_reference_ev":sky.exposure.fixed_ev,"meter":Array(sky._meter_samples),"camera":Array(PackedFloat32Array([sky.camera.view_dir().x,sky.camera.view_dir().y,sky.camera.view_dir().z])),"catalogue_count":sky.starfield.count,"source":"actual normal Sol and committed voyage; manual fixed dark-reference4x aid"}
   print("RECOVERY ",record);records.append(record)
   if phase=="rest" and sky.exposure.ev>0.:failed=true
 var file:=FileAccess.open(output.path_join("metrics.json"),FileAccess.WRITE);file.store_string(JSON.stringify(records,"  "));file.close()
 demo.queue_free();await process_frame
 print("exposure-sky-recovery: ","FAIL" if failed else "OK");quit(1 if failed else 0)
