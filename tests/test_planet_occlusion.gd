extends SceneTree
var failures:=0
var checks:=0
func check(name:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",name)
func _initialize()->void:run.call_deferred()
func run()->void:
	var sim:=SimBridge.new();sim.want_minor=5
	check("normal system authority",sim.start() and sim.new_game(31))
	var sf:=Starfield.new();sf.set_custom_stars([]);sf.build();root.add_child(sf)
	var sv:=SystemView.new();sv.setup(sf,false);sv.relativistic_enabled=true;sv.set_view(.002,720.);root.add_child(sv)
	var body:Dictionary={}
	for b:Dictionary in sim.world.system.bodies:
		if b.id=="earth":body=b.duplicate(true)
	body.rel_km={"x":50000.0,"y":0.0,"z":0.0};body.sun_dir={"x":1.0,"y":0.0,"z":0.0}
	sv.update({"bodies":[body]},1.)
	check("unlit globe still masks a catalogue star",sv.occludes_direction(PackedFloat64Array([0,0,-1])))
	check("clear sky remains selectable",not sv.occludes_direction(PackedFloat64Array([1,0,0])))
	check("outside body limb remains selectable",not sv.occludes_direction(PackedFloat64Array([.2,0,-sqrt(.96)])))
	sv.set_velocity(Vector3(1,0,0),.9,2.294157338705618,.1);sv.update({"bodies":[body]},1.)
	var seen:=Planets.inverse_ray64(PackedFloat64Array([0,0,-1]),PackedFloat64Array([-1,0,0]),.9,2.294157338705618,.1)
	check("moving body masks its aberrated direction",sv.occludes_direction(seen))
	check("moving body does not mask old rest direction",not sv.occludes_direction(PackedFloat64Array([0,0,-1])))
	check("hidden resolved bodies do not mask sky",_hidden(sv,seen))
	sv.set_velocity(Vector3(0,0,-1),0.,1.,1.)
	var saturn:Dictionary={};var ring:Dictionary={}
	for b:Dictionary in sim.world.system.bodies:
		if b.id=="saturn":saturn=b.duplicate(true)
	for rr:Dictionary in sim.world.system.rings:
		if rr.host=="saturn":ring=rr
	var pole:=SkyFrame.to_galactic64([0,.8,.6]);saturn.pole={"x":pole[0],"y":pole[1],"z":pole[2]};saturn.rel_km={"x":1500000.0,"y":0.0,"z":0.0}
	sv.update({"bodies":[saturn],"rings":[ring]},1.)
	var n:=Vector3(100000.,0.,-1500000.).normalized();var ray:=PackedFloat64Array([n.x,n.y,n.z])
	var transmission:=sv.directional_transmission(ray)
	check("thin ring transmits fraction rather than opaque wall",transmission>0.0 and transmission<1.0 and not sv.occludes_direction(ray))
	var grazing:=Vector3(110000.,0.,-1500000.).normalized()
	var gp:=SkyFrame.to_galactic64([0,sqrt(1.0-.15*.15),.15]);saturn.pole={"x":gp[0],"y":gp[1],"z":gp[2]}
	sv.update({"bodies":[saturn],"rings":[ring]},1.)
	var finite_trans:=sv.directional_transmission(PackedFloat64Array([grazing.x,grazing.y,grazing.z]))
	check("grazing optical transmission stays finite and positive",finite_trans>0.0 and finite_trans<3e-8)
	check("grazing ring matches renderer-effective opacity",sv.occludes_direction(PackedFloat64Array([grazing.x,grazing.y,grazing.z])))
	check("ring gap leaves exact full transmission",sv.directional_transmission(PackedFloat64Array([1,0,0]))==1.0)
	sv.update({},1.);check("cleared snapshot never masks stale bodies",not sv.occludes_direction(seen))
	sim.stop();sv.queue_free();sf.queue_free();await process_frame
	print("planet-occlusion: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
func _hidden(sv:SystemView,ray:PackedFloat64Array)->bool:
	sv.visible=false;var value:=not sv.occludes_direction(ray);sv.visible=true;return value
