extends SceneTree
## D-38 evidence: the same actual Solar session views in the Realistic view
## (one manual exposure) and the Auto view (per-body fader, sky unchanged).
## Writes renders/ship_demo/auto_view/<stop>_<view>.png; open them to check.
const SolarDeparture=preload("res://demos/solar_departure.gd")
var sky:InteriorSky
var frame:=0
var out:="res://renders/ship_demo/auto_view"
var failures:=0
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(1280,720);DirAccess.make_dir_recursive_absolute(out)
 sky=InteriorSky.new();root.add_child(sky)
 sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},78.,root.size,{"stars":true,"background":true,"planet_textures":true})
 var rect:=TextureRect.new();rect.texture=sky.get_texture();rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(rect)
 var sim:=SimBridge.new();sim.want_minor=5
 if not sim.start() or not sim.new_game(424242,"solar_departure",false,SolarDeparture.guided_params()):print("exposure-auto-view: startup FAIL ",sim.last_error);quit(1);return
 sky.exposure.fixed=true;sky.exposure.fixed_ev=sky.exposure.ev_dark()-2.;sky.set_temporal_exposure(false)
 await capture(sim.world,"earth","earth")
 await sun_check(sim.world)
 var catalogue:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).get("stars",[])
 var destination:Dictionary={}
 for i in catalogue.size():
  if catalogue[i].id=="CNS5:3627":destination=catalogue[i].duplicate();destination.index=i
 var tour:=SolarDeparture.new()
 if not tour.attach(sim,catalogue):print("exposure-auto-view: attach FAIL");quit(1);return
 for i in 2:
  if not tour.advance():failures+=1;break
  var plan:Dictionary=sim.world.journey.plan
  if not sim.send([],plan.age_on_arrival-sim.world.params.start_age-sim.world.clock.tau+1e-14):failures+=1
 await capture(sim.world,"jupiter","jupiter")
 sim.stop();sky.queue_free();rect.queue_free();await process_frame
 print("exposure-auto-view: ",failures," failures");quit(1 if failures else 0)
func capture(world:Dictionary,label:String,target:String)->void:
 var axis:=Vector3.ZERO;var sun:=Vector3.ZERO
 for b:Dictionary in world.system.bodies:
  var w:=Planets.world_of(b.rel_km);var n:=Vector3(w[0],w[1],w[2]).normalized()
  if b.id==target:axis=n
  if b.id=="sun":sun=n
 # Body off-centre (20 degrees towards the anti-sun side) so the frame also holds open sky.
 var n:=(axis.rotated(axis.cross(sun).normalized(),deg_to_rad(-20.))).normalized()
 for auto:bool in [false,true]:
  sky.system_view.body_fader=auto
  sky.apply(world);sky.camera.look(atan2(-n.x,-n.z),asin(n.y),0.)
  for i in 90:
   if i%3==0:sky.apply(world);sky.camera.look(atan2(-n.x,-n.z),asin(n.y),0.)
   frame+=1;sky.finish_exposure_frame(1./60.,frame)
   await process_frame
  await RenderingServer.frame_post_draw
  var name:=label+("_auto" if auto else "_realistic")
  sky.get_texture().get_image().save_png(out.path_join(name+".png"))
  print("AUTO VIEW ",name," ev=",sky.exposure.ev," faded_stops=",sky.system_view.fader_stops(sky.exposure.k())," discs=",sky.system_view.drawn_discs)
## The Sun in Auto (2026-10-07, star colours): a warm white with its tint order kept,
## R >= G >= B, bright (R >= 190) and only gently tinted (R - B <= 40).
func sun_check(world:Dictionary)->void:
 var sun:=Vector3.ZERO
 for b:Dictionary in world.system.bodies:
  if b.id=="sun":var w:=Planets.world_of(b.rel_km);sun=Vector3(w[0],w[1],w[2]).normalized()
 sky.system_view.body_fader=true
 for i in 60:
  if i%3==0:sky.apply(world);sky.camera.look(atan2(-sun.x,-sun.z),asin(sun.y),0.)
  frame+=1;sky.finish_exposure_frame(1./60.,frame);await process_frame
 await RenderingServer.frame_post_draw
 var img:=sky.get_texture().get_image();img.save_png(out.path_join("sun_auto.png"))
 var p:=Vector2i(sky.camera.project(sun,Vector2(root.size)));var c:=img.get_pixel(p.x,p.y)
 var ok:=c.r8>=190 and c.r8>=c.g8 and c.g8>=c.b8 and c.r8-c.b8<=40
 print("AUTO VIEW sun_auto centre=",Vector3i(c.r8,c.g8,c.b8)," ok=",ok)
 if not ok:failures+=1
 await cool_star_check(world,sun,p)

## D-49: the Auto lift is wired and visible. The Sun's disc given TRAPPIST-1's 2,566 K:
## Auto shows a clearly redder centre than the same frame with the physical tint, the
## luminance-renormalised lift keeps brightness, and Realistic carries no lift at all.
func cool_star_check(world:Dictionary,sun:Vector3,p:Vector2i)->void:
 var w:=world.duplicate(true)
 for b:Dictionary in w.system.bodies:
  if b.id=="sun":b["teff_k"]=2566.
 var got:={}
 for mode in ["lifted","physical"]:
  sky.system_view.body_fader=true
  sky.system_view.star_saturation=sky.system_view.STAR_SATURATION if mode=="lifted" else 1.
  for i in 30:
   if i%3==0:sky.apply(w);sky.camera.look(atan2(-sun.x,-sun.z),asin(sun.y),0.)
   frame+=1;sky.finish_exposure_frame(1./60.,frame);await process_frame
  await RenderingServer.frame_post_draw
  var c:=sky.get_texture().get_image().get_pixel(p.x,p.y);got[mode]=c
 var lift:=float(sky.system_view.STAR_SATURATION)
 sky.system_view.star_saturation=lift
 sky.system_view.body_fader=false;sky.system_view.set_exposure(1.)
 var realistic:=float((sky.system_view.discs["sun"].material_override as ShaderMaterial).get_shader_parameter("star_saturation"))
 var a:Color=got.lifted;var b:Color=got.physical
 var spread_a:=a.r8-a.b8;var spread_b:=b.r8-b.b8
 var luma:=func(c:Color)->float:return .2126*c.r+.7152*c.g+.0722*c.b
 var ok:=lift>1. and is_equal_approx(realistic,1.) and a.r8>=a.g8 and a.g8>=a.b8 and spread_a>=spread_b+15 and absf(luma.call(a)-luma.call(b))<.12
 print("AUTO VIEW cool_star lifted=",Vector3i(a.r8,a.g8,a.b8)," physical=",Vector3i(b.r8,b.g8,b.b8)," realistic_saturation=",realistic," ok=",ok)
 if not ok:failures+=1
 sky.system_view.body_fader=true
