extends SceneTree
var failures:=0
func check(label:String,ok:bool)->void:
	print("%s %s"%["ok" if ok else "FAIL",label]);if not ok:failures+=1
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var sim:=SimBridge.new();sim.want_minor=2
	if not sim.start() or not sim.new_game(424242,"sol",false):check("normal startup (%s)" %sim.last_error,false);quit(1);return
	var map:=GalaxyMap.new();root.add_child(map);map.auto_tick=false;map.live_pacing=true
	map.load_catalogue("res://data/starmap/stars.json");map.attach(sim)
	var prior_distance:=-1.
	for target in ["CNS5:3627","HIP 71681"]:
		map.preselect(map.index_of(target))
		map.tick();check("selected target planned",map.journey_state()=="planned" and sim.world.journey.plan.target.id==target)
		var start_tau:float=sim.world.clock.tau;var start_year:float=sim.world.clock.year
		var plan:Dictionary=sim.world.journey.plan.duplicate(true)
		if prior_distance>=0.:check("new target changes journey plan",plan.distance!=prior_distance and start_tau>0.)
		prior_distance=plan.distance
		map.open_commit_dialog();map.hold_commit(GalaxyMap.HOLD_S);map.tick()
		check("commit retains boost samples",sim.world.ship.phase=="boosting" and sim.world.ship.beta>0.)
		map.press_cancel();map.tick();check("committed cancel refused",map.journey_state()=="committed" and not sim.last_refused.is_empty())
		var counts:={"boosting":0,"cruising":0,"braking":0};var previous:float=sim.world.ship.beta
		var heading:Dictionary=sim.world.ship.heading.duplicate()
		var monotonic:=true
		var ticks:=0
		for i in 1500:
			ticks+=1
			var before_phase:String=sim.world.ship.phase
			map.tick()
			var phase:String=sim.world.ship.phase;var beta:float=sim.world.ship.beta
			if counts.has(phase):counts[phase]+=1
			if phase==before_phase and phase=="boosting":monotonic=monotonic and beta>=previous
			if phase==before_phase and phase=="braking":monotonic=monotonic and beta<=previous
			monotonic=monotonic and sim.world.ship.heading==heading
			previous=beta
			if map.journey_state()=="arrived":break
		check("three phases take approximately 60 real seconds",ticks>=1190 and ticks<=1210)
		check("multiple continuous phase states",counts.boosting>100 and counts.braking>100 and counts.cruising>100 and monotonic)
		check("rest arrival",map.journey_state()=="arrived" and sim.world.ship.beta==0.)
		check("both clocks match plan",absf(sim.world.clock.tau-start_tau-plan.ship_years)<1e-9 and absf(sim.world.clock.year-start_year-plan.earth_years)<1e-9)
		check("arrival point matches target",sim.world.ship.pos==plan.target.pos)
	sim.stop();quit(1 if failures else 0)
