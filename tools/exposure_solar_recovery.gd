extends SceneTree
## One actual Solar session: no position/radius/flux edits or new_game between
## Earth, approach, dwell and departure. Native manual fixed exposure evidence.
const SolarDeparture=preload("res://demos/solar_departure.gd")
var sky:InteriorSky
var frame:=0
var records:=[]
var out:="res://renders/ship_demo/exposure_recovery"
var failures:=0
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(800,600);DirAccess.make_dir_recursive_absolute(out)
 sky=InteriorSky.new();root.add_child(sky)
 sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},78.,root.size,{"stars":true,"background":true,"planet_textures":true})
 var rect:=TextureRect.new();rect.texture=sky.get_texture();rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(rect)
 var sim:=SimBridge.new();sim.want_minor=5
 if not sim.start() or not sim.new_game(424242,"solar_departure",false,SolarDeparture.guided_params()):print("exposure-solar-recovery: startupFAIL ",sim.last_error);quit(1);return
 sky.exposure.bias=-2.;sky.exposure.fixed=true;sky.exposure.fixed_ev=sky.exposure.ev_dark()-2.;sky.set_temporal_exposure(false)
 await capture(sim.world,"earth_start","earth")
 var catalogue:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).get("stars",[])
 # Destination is needed only by the controller's eventual outbound leg.
 var destination:Dictionary={"id":"CNS5:3627","index":0,"x":0.,"y":0.,"z":0.}
 for i in catalogue.size():
  if catalogue[i].id=="CNS5:3627":destination=catalogue[i].duplicate();destination.index=i
 var tour:=SolarDeparture.new()
 if not tour.attach(sim,catalogue):print("exposure-solar-recovery: attachFAIL");quit(1);return
 for i in 2:
  if not tour.advance():failures+=1;break
  var plan:Dictionary=sim.world.journey.plan
  var remaining:float=plan.age_on_arrival-sim.world.params.start_age-sim.world.clock.tau
  if i==1:
   if not sim.send([],remaining*.999):failures+=1
   await capture(sim.world,"jupiter_approach","jupiter")
   remaining=plan.age_on_arrival-sim.world.params.start_age-sim.world.clock.tau
  if not sim.send([],remaining+1e-14):failures+=1
  if i==1:
   await capture(sim.world,"jupiter_stop","jupiter")
   var before:Dictionary=sim.world.ship.pos.duplicate()
   if not sim.send([],12./31557600.):failures+=1
   await capture(sim.world,"jupiter_dwell","jupiter")
   if sim.world.ship.pos!=before:failures+=1
   if not tour.advance():failures+=1
   await capture(sim.world,"jupiter_leave","jupiter")
 var file:=FileAccess.open(out.path_join("solar_metrics.json"),FileAccess.WRITE);file.store_string(JSON.stringify(records,"  "));file.close()
 sim.stop();sky.queue_free();rect.queue_free();await process_frame
 print("exposure-solar-recovery: ",failures," failures");quit(1 if failures else 0)
func capture(world:Dictionary,label:String,target:String)->void:
 var axis:=Vector3.ZERO;var sun:=Vector3.ZERO
 for b:Dictionary in world.system.bodies:
  var w:=Planets.world_of(b.rel_km);var n:=Vector3(w[0],w[1],w[2]).normalized()
  if b.id==target:axis=n
  if b.id=="sun":sun=n
 var away:=axis.cross(sun).normalized()
 for look:String in ["body","away","dim"]:
  # Package body directions, converted through the actual inverse-aberration
  # convention; camera viewing direction alone is presentation state.
  var n:Vector3=away if look=="away" else axis
  sky.exposure.fixed_ev=sky.exposure.ev_dark()+(24. if target=="earth" else 16.) if look=="dim" else sky.exposure.ev_dark()-2.
  sky.apply(world)
  if sky.beta>0.:
   var apparent:=Planets.inverse_ray64(PackedFloat64Array([n.x,n.y,n.z]),PackedFloat64Array([-sky.heading_world.x,-sky.heading_world.y,-sky.heading_world.z]),sky.beta,sky.system_view.velocity_gamma,sky.system_view.velocity_omb)
   n=Vector3(apparent[0],apparent[1],apparent[2])
  sky.camera.look(atan2(-n.x,-n.z),asin(n.y),0.)
  for i in 120:
   if i%3==0:sky.apply(world);sky.camera.look(atan2(-n.x,-n.z),asin(n.y),0.)
   frame+=1;sky.finish_exposure_frame(1./60.,frame)
   await process_frame
  await RenderingServer.frame_post_draw
  sky.get_texture().get_image().save_png(out.path_join(label+"_"+look+".png"))
  var record={"name":label+"_"+look,"phase":world.ship.phase,"beta":world.ship.beta,"tau":world.clock.tau,"position":world.ship.pos,"ev":sky.exposure.ev,"base_ev":sky.exposure.mode_ev(sky._meter_samples[0],sky._meter_samples[1])+sky.exposure.bias,"automatic_exposure":false,"manual_reference_ev":sky.exposure.fixed_ev,"meter":Array(sky._meter_samples),"source":"one actual Solar session; unchanged state repeated20Hz; manual fixed exposure; default4x or explicit dim setting"}
  print("SOLAR RECOVERY ",record);records.append(record)
  if look=="away" and sky.exposure.ev>0. and sky.beta<.001:failures+=1
