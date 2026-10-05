extends SceneTree
## Record actual AILANG states for repeatable, frozen SR review. No local kinematics.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var sim:=SimBridge.new();sim.want_minor=2
	if not sim.start() or not sim.new_game(424242,"sol",false,{"standoff_au":1000.}):
		push_error(sim.last_error);quit(1);return
	var stars:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))["stars"]
	var target:Dictionary={}
	for i in stars.size():
		if stars[i].id=="CNS5:3627":target={"index":i,"id":stars[i].id,"pos":{"x":stars[i].x,"y":stars[i].y,"z":stars[i].z}}
	if target.is_empty():sim.stop();quit(1);return
	var phi:float=sim.world.params.cruise_phi_default
	if not sim.send([{"k":"plan","target":target,"cruise_phi":phi}],0.) or not sim.send([{"k":"commit","plan_id":sim.world.journey.plan_id}],0.):
		sim.stop();quit(1);return
	var rest:Dictionary=sim.world.duplicate(true)
	var ready:=false
	for i in 1000:
		if not sim.send([],.01):break
		if sim.world.ship.phase=="cruising" and sim.world.ship.flown>sim.world.journey.plan.distance*.5:
			ready=true;break
	if not ready:sim.stop();quit(1);return
	var record:={"source":"AILANG simulation; frozen review states, not the active voyage","ailang":"v0.52.0","relativity":"0.8.0","seed":424242,"target":target,"step_ship_years":.01,"states":{"rest":rest,"cruise":sim.world.duplicate(true)}}
	var file:=FileAccess.open("res://assets/ship_demo/sky_review.json",FileAccess.WRITE)
	file.store_string(SimBridge.encode(record)+"\n");file.close();sim.stop()
	print("ship-demo-sky-states: OK");quit()
