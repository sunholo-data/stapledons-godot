extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	print(('ok ' if ok else 'FAIL ')+label)
	if not ok:failures+=1
func _initialize()->void:
	var pacing=load('res://ui/journey_pacing.gd').new()
	pacing.guided_approach=true
	var burn:=0.001
	var world:={'journey':{'state':'committed','plan_id':1,'plan':{'boost_minutes':burn*pacing.MINUTES_PER_YEAR,'ship_years':3.*burn,'age_on_arrival':31.+3.*burn}},'clock':{'tau':31.},'params':{'start_age':31.},'ship':{'phase':'boosting'}}
	var first_step:float=pacing.step(world,true,0.,20.)
	check(absf(first_step-1./(20.*pacing.SECONDS_PER_YEAR))<1e-18,'guided departure begins at one physical second per wall second')
	world.clock.tau+=first_step
	var counts:={'boosting':1,'cruising':0,'braking':0}
	var near_ticks:=0
	var max_dt:=0.
	var ramp_monotonic:=true
	var previous_ramp_step:=first_step
	var ramp_end_step:=0.
	for tick in 4000:
		var elapsed:float=world.clock.tau-31.
		if elapsed>=3.*burn:break
		world.ship.phase='boosting' if elapsed<burn else ('cruising' if elapsed<2.*burn else 'braking')
		counts[world.ship.phase]+=1
		if elapsed>2.9*burn:near_ticks+=1
		var dt:float=pacing.step(world,false,0.,20.)
		if world.ship.phase=='boosting' and counts.boosting<=61:
			ramp_monotonic=ramp_monotonic and dt>=previous_ramp_step and dt>0. and is_finite(dt)
			previous_ramp_step=dt
			if counts.boosting==61:ramp_end_step=dt
		if tick==0:check(dt>0. and is_finite(dt),'positive finite elapsed step')
		if world.ship.phase=='braking':max_dt=maxf(max_dt,dt)
		world.clock.tau+=dt
	check(world.clock.tau>=31.+3.*burn,'exact endpoint reached without clock reversal')
	print('guided phase ticks ',counts)
	check(abs(counts.boosting-630)<=3 and abs(counts.cruising-400)<=2 and abs(counts.braking-1800)<=3,'three-second eased boost adds only 1.5 seconds; cruise20s and braking90s unchanged')
	check(ramp_monotonic and absf(ramp_end_step-burn/600.)<1e-15,'positive monotonic compression reaches nominal guided rate after three seconds')
	check(near_ticks>=560,'last tenth of physical braking lasts at least 28 wall seconds')
	check(max_dt<burn/800.,'braking starts with bounded steps')
	var standard=load('res://ui/journey_pacing.gd').new()
	world.clock.tau=31.;world.ship.phase='boosting'
	check(absf(standard.step(world,true,0.,20.)-burn/400.)<1e-15,'ordinary navigation retains existing pacing')
	print('tour-pacing: %d failures'%failures);quit(1 if failures else 0)
