extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(800,600)
 var sim:=SimBridge.new();sim.want_minor=5
 if not sim.start() or not sim.new_game(424242,"sol",false):quit(1);return
 var map:=GalaxyMap.new();root.add_child(map);map.auto_tick=false;map.load_catalogue("res://data/starmap/stars.json");map.attach(sim)
 map.preselect(map.index_of("CNS5:3627"));map.tick();map.open_commit_dialog();map.hold_commit(GalaxyMap.HOLD_S);map.tick()
 var remaining:float=sim.world.journey.plan.age_on_arrival-sim.world.params.start_age-sim.world.clock.tau
 if not sim.send([],remaining+1e-14):quit(1);return
 print("ALPHA OUTER phase=",sim.world.ship.phase," pos=",sim.world.ship.pos)
 if not sim.send([SimBridge.body_plan("acen-a",.002,{"mode":"stop","standoff_km":149597870.7})],0.) or not sim.last_refused.is_empty():print("ALPHA PLAN FAIL ",sim.last_error,sim.last_refused);quit(1);return
 if not sim.send([{"k":"commit","plan_id":sim.world.journey.plan_id}],0.):quit(1);return
 remaining=sim.world.journey.plan.age_on_arrival-sim.world.params.start_age-sim.world.clock.tau
 if not sim.send([],remaining+1e-14):quit(1);return
 var sky:=InteriorSky.new();root.add_child(sky)
 sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},78.,root.size,{"stars":true,"background":true,"planet_textures":true})
 var rect:=TextureRect.new();rect.texture=sky.get_texture();rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(rect)
 sky.exposure.bias=-2.;sky.exposure.fixed=true;sky.exposure.fixed_ev=sky.exposure.ev_dark()-2.;sky.set_temporal_exposure(false);sky.apply(sim.world)
 var a:Dictionary={}
 for b:Dictionary in sky.system_view.rendered_bodies:
  if b.id=="acen-a":a=b
 if a.is_empty():print("ALPHA BODY FAIL");quit(1);return
 var axis:Vector3=a._place[0];var yaw:=atan2(-axis.x,-axis.z);var pitch:=asin(axis.y)
 var out:="res://renders/ship_demo/exposure_recovery";DirAccess.make_dir_recursive_absolute(out)
 var records:=[]
 for angle:float in [0.,5.,20.,90.]:
  sky.camera.look(yaw+deg_to_rad(angle),pitch,0.)
  for i in 120:
   if i%3==0:sky.apply(sim.world);sky.camera.look(yaw+deg_to_rad(angle),pitch,0.)
   sky.finish_exposure_frame(1./60.);await process_frame
  await RenderingServer.frame_post_draw
  var name:="alpha_1au_pan_%d"%int(angle)
  var image:=sky.get_texture().get_image();image.save_png(out.path_join(name+".png"))
  var pixel:=Vector2i(sky.camera.project(axis,Vector2(root.size)))
  var peak:=0.
  if angle<=20.:
   for y in range(maxi(0,pixel.y-5),mini(image.get_height(),pixel.y+6)):
    for x in range(maxi(0,pixel.x-5),mini(image.get_width(),pixel.x+6)):
     var c:=image.get_pixel(x,y);peak=maxf(peak,maxf(c.r,maxf(c.g,c.b)))
   if peak<.5:failures+=1
  var record={"name":name,"phase":sim.world.ship.phase,"distance_km":a._place[3],"radius_km":a.radius_km,"lux":a.e_v_lux,"lod":sky.system_view.lod_weights[a.id],"drawn":sky.system_view.drawn_discs.has(a.id),"ev":sky.exposure.ev,"automatic_exposure":false,"manual_reference_ev":sky.exposure.fixed_ev,"peak_visible_pixel":peak,"source":"actual Sol->1000AU catalogue arrival->moving A1AU body intercept; no fixture geometry edits"}
  print("ALPHA RECOVERY ",record);records.append(record)
 var file:=FileAccess.open(out.path_join("alpha_metrics.json"),FileAccess.WRITE);file.store_string(JSON.stringify(records,"  "));file.close()
 sim.stop();map.queue_free();sky.queue_free();rect.queue_free();await process_frame
 print("exposure-alpha-recovery: ",failures," failures");quit(1 if failures else 0)
