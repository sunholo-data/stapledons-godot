extends SceneTree
const StarProjection = preload("res://sky/star_projection.gd")
var failures:=0
var samples:=[]
func _initialize()->void:run.call_deferred()
func run()->void:
 root.size=Vector2i(800,600);root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
 var vp:=SubViewport.new();vp.size=root.size;vp.own_world_3d=true;vp.use_hdr_2d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(vp)
 var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color.BLACK;env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 var we:=WorldEnvironment.new();we.environment=env;vp.add_child(we)
 var cam:=FreeLookCamera.new();cam.fov=35.;cam.current=true;vp.add_child(cam)
 var sf:=Starfield.new();sf.set_custom_stars([]);sf.point_overlay=true;sf.build();vp.add_child(sf)
 var sv:=SystemView.new();sv.setup(sf,false);sv.relativistic_enabled=true;vp.add_child(sv)
 var pxrad:=2.*tan(deg_to_rad(17.5))/600.;sv.set_view(pxrad,600.)
 var fixtures:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/alpha_centauri_physical.json"))
 DirAccess.make_dir_recursive_absolute("res://renders/alpha_centauri")
 var worst:=0.
 for fixture in ["sol","arrival_1000au","diagnostic_3ra"]:
  for beta in [0.,.9]:
   for source in fixtures[fixture].bodies:
    if fixture=="diagnostic_3ra" and source.id=="acen-b":continue
    var heading:=Vector3.RIGHT;var gamma:=1./sqrt(1.-beta*beta)
    sv.set_velocity(heading,beta,gamma,1./(gamma*gamma*(1.+beta)));sf.set_velocity(heading,beta,gamma)
    var w:=Planets.world_of(source.rel_km);var n:=Vector3(w[0],w[1],w[2]).normalized();var seen:=Relativity.aberrate(n,heading,beta)
    sf.set_custom_stars([{id=source.catalogue_id,pos=[1.,0.,0.],t=5550.,flux=.02}])
    cam.look(atan2(-seen.x,-seen.z),asin(seen.y),0.)
    var k:float=.1*pxrad*pxrad/(source.e_v_lux*SkyMeter.seen_point(1.,source.teff_k,n,heading,beta))
    if fixture=="diagnostic_3ra":k=.12/(source.e_v_lux/(PI*pow(source.radius_km/Planets.length64(w),2.)))
    sv.update({bodies=[source]},k);sf.set_exposure(k/(TAU*.9*.9*pxrad*pxrad));sf.set_psf(.9);sf.set_floor(Vector2.ZERO)
    for f in 3:await process_frame
    await RenderingServer.frame_post_draw
    var img:=vp.get_texture().get_image();var error:=0.;var gpu:=0.;var cpu:=0.;var centre:=Vector2.ZERO;var total_weight:=0.
    if fixture=="diagnostic_3ra":
     for yy in 8:
      for xx in 8:
       var ray:=cam.project_ray_normal(Vector2(400.5+(xx+.5)/8.-.5,300.5+(yy+.5)/8.-.5))
       var c:=sv.ray_colour(PackedFloat64Array([ray.x,ray.y,ray.z]));cpu+=.2126729*c.x+.7151522*c.y+.0721750*c.z
     cpu=cpu/64.*k;var colour:=img.get_pixel(400,300);gpu=.2126729*colour.r+.7151522*colour.g+.0721750*colour.b
     error=absf(gpu/cpu-1.)
    else:
     for yy in range(286,314):
      for xx in range(386,414):
       var c:=img.get_pixel(xx,yy);gpu+=(.2126729*c.r+.7151522*c.g+.0721750*c.b)*pxrad*pxrad
       var weight:float=.2126729*c.r+.7151522*c.g+.0721750*c.b;centre+=Vector2(xx+.5,yy+.5)*weight;total_weight+=weight
     cpu=source.e_v_lux*k*SkyMeter.seen_point(1.,source.teff_k,n,heading,beta);error=absf(gpu/cpu-1.)
    worst=maxf(worst,error)
    if error>.03:failures+=1
    var pixel_error:=0.
    if total_weight>0.:
     var sample:=StarProjection.sample(sf,0);var projected:=cam.unproject_position(sample.direction*1000.)
     pixel_error=(centre/total_weight).distance_to(projected)
     if pixel_error>.75:failures+=1
    samples.append({fixture=fixture,id=source.id,beta=beta,radius_km=source.radius_km,teff_k=source.teff_k,distance_km=Planets.length64(w),physical_diameter_arcsec=rad_to_deg(2.*Planets.angular_radius(source.radius_km,Planets.length64(w)))*3600.,gpu=gpu,cpu=cpu,relative_error=error,inspection_pixel_error=pixel_error})
    img.convert(Image.FORMAT_RGB8);img.linear_to_srgb();img.save_png("res://renders/alpha_centauri/%s_%s_b%.1f.png"%[fixture,source.id,beta])
 var out:=FileAccess.open("res://renders/alpha_centauri/audit.json",FileAccess.WRITE);out.store_string(JSON.stringify({samples=samples,worst_relative_error=worst,note="Pinned AILANG producer fixture: measured A/B radii, Hipparcos V-band flux, package Kepler and retarded local positions. Sol/1000AU are unresolved point flux; 3RA is explicitly a diagnostic observer, not a guided navigation endpoint. Actual HDR GPU vs CPU shared physical rays; no enlarged star radii."},"  "));out.close()
 print("alpha-centauri-golden: %d cases, %d failures; worst %.6f"%[samples.size(),failures,worst])
 sv.queue_free();sf.queue_free();cam.queue_free();await process_frame;quit(1 if failures else 0)
