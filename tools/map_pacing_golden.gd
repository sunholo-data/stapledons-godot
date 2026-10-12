extends SceneTree
## Records ordinary (non-guided) map pacing dtau values as a byte-exact golden.
## Run once before changing ui/journey_pacing.gd: godot --headless --path . --script tools/map_pacing_golden.gd -- --write
## tests/test_tour_pacing.gd replays the same scenario and compares every value.
const OUT:="res://tests/fixtures/map_pacing_golden.json"
static func scenario_values()->Array:
	var pacing=load('res://ui/journey_pacing.gd').new()
	var burn:=0.001
	var world:={'journey':{'state':'committed','plan_id':1,'plan':{'boost_minutes':burn*pacing.MINUTES_PER_YEAR,'ship_years':3.*burn,'age_on_arrival':31.+3.*burn}},'clock':{'tau':31.},'params':{'start_age':31.},'ship':{'phase':'boosting'}}
	var out:=[pacing.step(world,true,0.,20.)]
	world.clock.tau+=out[0]
	for tick in 200:
		var elapsed:float=world.clock.tau-31.
		if elapsed>=3.*burn:break
		world.ship.phase='boosting' if elapsed<burn else ('cruising' if elapsed<2.*burn else 'braking')
		var dt:float=pacing.step(world,false,0.,20.)
		out.append(dt);world.clock.tau+=dt
	world.journey.state='arrived'
	out.append(pacing.step(world,false,0.05,20.))
	return out
func _initialize()->void:
	var values:=scenario_values()
	if "--write" in OS.get_cmdline_user_args():
		var f:=FileAccess.open(OUT,FileAccess.WRITE);f.store_string(JSON.stringify(values.map(func(v):return var_to_str(v))));f.close()
		print("map-pacing-golden: wrote %d values"%values.size())
	quit(0)
