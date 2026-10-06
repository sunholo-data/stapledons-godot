extends SceneTree
## Real-time guided pacing and the cruise-interlude cut (D-39/D-40/D-41, RT3).
var failures:=0
func check(ok:bool,label:String)->void:
	print(('ok ' if ok else 'FAIL ')+label)
	if not ok:failures+=1

const SPY:=31557600.0
const TICK:=1./(20.*SPY) # one wall second at 20 Hz, in years

func leg(burn_s:float,cruise_s:float)->Dictionary:
	var burn:=burn_s/SPY;var total:=(2.*burn_s+cruise_s)/SPY
	return {'journey':{'state':'committed','plan_id':7,'plan':{'boost_minutes':burn_s/60.,'ship_years':total,'age_on_arrival':31.+total}},'clock':{'tau':31.},'params':{'start_age':31.},'ship':{'phase':'boosting'},'_burn':burn,'_total':total}

func phase_of(w:Dictionary)->String:
	var e:float=w.clock.tau-31.
	return 'boosting' if e<w._burn else ('cruising' if e<w._total-w._burn else 'braking')

## Runs one guided leg; when an interlude is due the host consumes the exact remaining cruise.
func fly(pacing,w:Dictionary,hold_seen:Array)->Dictionary:
	var r:={'over':0,'short':0,'ticks':0,'interludes':0,'boundary_error':-1.}
	w.clock.tau+=pacing.step(w,true,0.,20.)
	for i in 400000:
		if w.clock.tau-31.>=w._total:break
		w.ship.phase=phase_of(w)
		if pacing.interlude_due(w):
			r.interludes+=1
			hold_seen.append(pacing.cruise_elapsed_s(w))
			var jump:float=pacing.cruise_remaining(w)
			w.clock.tau+=jump
			r.boundary_error=absf((w.clock.tau-31.)-(w._total-w._burn))
			w.ship.phase=phase_of(w)
			continue
		var dt:float=pacing.step(w,false,0.,20.)
		r.ticks+=1
		# Real time, exactly: every guided tick is one wall second of ship time (no clamping, no compression).
		if dt>TICK:r.over+=1
		elif dt<TICK:r.short+=1
		w.clock.tau+=dt
	return r

func _initialize()->void:
	var P=load('res://ui/journey_pacing.gd')
	# 1. Short cruise (Solar System leg): real time throughout, never cut.
	var short=P.new();short.guided_approach=true
	var a:=leg(27.,300.)
	var seen:=[]
	var ra:=fly(short,a,seen)
	check(ra.over==0 and ra.short==0,'every guided tick is exactly one wall second of ship time (%d over, %d short)'%[ra.over,ra.short])
	check(ra.interludes==0,'a cruise of 300 s (under 600 s) plays in real time, no cut')
	check(abs(ra.ticks-(2*27+300)*20)<=4,'real time: 354 ship seconds take ~7080 ticks (%d)'%ra.ticks)
	check(a.clock.tau-31.>=a._total,'short leg reaches its endpoint')
	# 2. Long cruise (interstellar): real-time boost, 10 s hold, one exact cut, real-time braking.
	var long=P.new();long.guided_approach=true
	var b:=leg(38.7,6102926.)
	seen=[]
	var rb:=fly(long,b,seen)
	check(rb.interludes==1,'a cruise over 600 s gets exactly one interlude')
	check(seen.size()==1 and absf(seen[0]-long.CRUISE_HOLD_S)<=0.051,'the cut comes after 10 s of real-time cruise (%s)'%str(seen))
	check(rb.boundary_error>=0. and rb.boundary_error<=1e-12*b._total,'after the interlude the clock sits on the braking boundary (error '+str(rb.boundary_error)+' yr)')
	check(rb.over==0 and rb.short==0,'boost, hold and braking: every tick exactly one wall second (%d over, %d short)'%[rb.over,rb.short])
	check(abs(rb.ticks-int((2*38.7+10.)*20))<=4,'ticks = boost + hold + brake at 20 Hz (%d)'%rb.ticks)
	check(long.CUT_THRESHOLD_S==600. and long.CRUISE_HOLD_S==10.,'design defaults: threshold 600 s, hold 10 s')
	# 3. Boundary: a cruise of exactly 600 s is not cut; 601 s is.
	var edge=P.new();edge.guided_approach=true;var e:=leg(10.,600.);seen=[]
	check(fly(edge,e,seen).interludes==0,'600 s cruise is not cut (threshold is strictly greater)')
	var over=P.new();over.guided_approach=true;var o:=leg(10.,601.);seen=[]
	check(fly(over,o,seen).interludes==1,'601 s cruise is cut')
	# 4. Ordinary map pacing is byte-identical to before RT3.
	var golden:Array=JSON.parse_string(FileAccess.get_file_as_string('res://tests/fixtures/map_pacing_golden.json'))
	var now:Array=load('res://tools/map_pacing_golden.gd').scenario_values()
	var same:=golden.size()==now.size()
	for i in mini(golden.size(),now.size()):same=same and str_to_var(golden[i])==now[i]
	check(same,'ordinary map pacing matches the recorded golden (%d values)'%golden.size())
	check(not long.interlude_due({'journey':{'state':'arrived'}}),'no interlude outside a committed journey')
	var plain=P.new();var c:=leg(38.7,6102926.);c.ship.phase='cruising';c.clock.tau=31.+c._burn+20./SPY
	plain.step(c,true,0.,20.)
	check(not plain.interlude_due(c),'ordinary (non-guided) map journeys never cut')
	print('tour-pacing: %d failures'%failures);quit(1 if failures else 0)
