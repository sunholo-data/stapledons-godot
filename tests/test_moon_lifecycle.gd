extends SceneTree
var checks:=0
var failures:=0
var samples:=[]
# Guided phases take 30s boost + optional 20s cruise + 90s braking.
# Bound each physical leg at 200 wall seconds (including numeric step margin).
const MAX_LEG_WALL_SECONDS := 200.0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",label)
func _initialize()->void:run.call_deferred()
func sample(sv:SystemView,world:Dictionary,host:String)->Dictionary:
	var ship:Dictionary=world.ship;var hg:=SkyFrame.to_world64([ship.heading.x,ship.heading.y,ship.heading.z])
	sv.set_velocity(Vector3(hg[0],hg[1],hg[2]),ship.beta,ship.gamma,ship.one_minus_beta);sv.update(world.system,1.)
	var rows:={};var host_body:Dictionary={}
	for body:Dictionary in world.system.bodies:
		if body.id==host:host_body=body
	var host_w:=Planets.world_of(host_body.rel_km);var host_dist:=Planets.length64(host_w);var host_alpha:=Planets.angular_radius(host_body.radius_km,host_dist)
	for body:Dictionary in world.system.bodies:
		if body.kind!="moon" or body.host!=host:continue
		var w:=Planets.world_of(body.rel_km);var distance:=Planets.length64(w);var n:=[w[0]/distance,w[1]/distance,w[2]/distance]
		var dot_:float=(w[0]*host_w[0]+w[1]*host_w[1]+w[2]*host_w[2])/(distance*host_dist)
		var off_limb:=acos(clampf(dot_,-1.,1.))>host_alpha+Planets.angular_radius(body.radius_km,distance)
		var transmission:=sv._point_transmission({"id":body.id,"distance":distance,"dir":n})
		var represented:=sv.drawn_points.has(body.id) or sv.drawn_discs.has(body.id)
		rows[body.id]={"present":true,"represented":represented,"transmission":transmission,"off_limb":off_limb,"foreground":distance<host_dist-host_body.radius_km,"diameter_px":sv._diameter_seen(w,body.radius_km,distance),"flux_lux":body.e_v_lux,"weight":sv.lod_weights.get(body.id,0.)}
	samples.append({"host":host,"phase":ship.phase,"beta":ship.beta,"tau":world.clock.tau,"moons":rows})
	return rows
func run()->void:
	var sim:=SimBridge.new();sim.want_minor=5
	if not sim.start() or not sim.new_game(42,"solar_departure",false,{"standoff_au":1000.,"boost_g":1.,"m_eff_kg":10.,"cap_one_minus_beta":.01}):print(sim.last_error);quit(1);return
	var sf:=Starfield.new();sf.set_custom_stars([]);sf.point_overlay=true;sf.build();root.add_child(sf)
	var sv:=SystemView.new();sv.setup(sf,false);sv.relativistic_enabled=true;sv.lod_range=Vector2(1.5,3.5);sv.set_view(2.*tan(deg_to_rad(39.))/720.,720.);root.add_child(sv)
	var controller=load("res://demos/solar_departure.gd").new();var catalogue:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"));var outbound:Dictionary={}
	for i in catalogue.stars.size():
		if catalogue.stars[i].id=="CNS5:3627":outbound=catalogue.stars[i].duplicate();outbound.index=i
	check("normal itinerary attaches",controller.attach(sim,outbound))
	for destination in ["sun","jupiter","callisto","saturn"]:
		check(destination+" physical leg commits",controller.advance())
		var previous:Dictionary={}
		for tick in int(MAX_LEG_WALL_SECONDS * controller.TICK_HZ):
			if sim.world.journey.state=="arrived":break
			previous=sim.world.duplicate(true)
			if not controller.step():check("physical tick",false);break
		check(destination+" endpoint reached",sim.world.journey.state=="arrived")
		if destination not in ["jupiter","saturn"]:continue
		var before:=sample(sv,previous,destination);var arrived:=sample(sv,sim.world,destination)
		check(destination+" moon authority survives braking to arrival",before.keys()==arrived.keys() and before.size()>=4)
		var retained:=0
		for id:String in arrived:
			if arrived[id].transmission>0. and (arrived[id].off_limb or arrived[id].foreground):
				retained+=1;check(destination+" visible off-limb/foreground moon retains representation "+id,arrived[id].represented and before[id].represented)
		check(destination+" has meaningful physically unocculted moon samples",retained>0)
		for i in 20:check(destination+" stationary epoch advances",controller.step())
		var settled:=sample(sv,sim.world,destination)
		check(destination+" moon array remains stable after endpoint",arrived.keys()==settled.keys())
		for id:String in settled:
			if settled[id].transmission>0. and (settled[id].off_limb or settled[id].foreground):check(destination+" stationary visible moon persists "+id,settled[id].represented)
	DirAccess.make_dir_recursive_absolute("res://renders/m5/transitions")
	var out:=FileAccess.open("res://renders/m5/transitions/moon-lifecycle.json",FileAccess.WRITE);out.store_string(JSON.stringify(samples,"  "))
	sim.stop();sv.queue_free();sf.queue_free();await process_frame
	print("moon-lifecycle: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
