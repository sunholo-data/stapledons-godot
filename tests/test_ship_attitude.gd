extends SceneTree
var failed:=0
func check(ok:bool,label:String)->void:
	print(('ok ' if ok else 'FAIL ')+label)
	if not ok:failed+=1
func _initialize()->void:
	var attitude=load('res://demos/ship_attitude.gd').new()
	var first:=ShipFrame.ship_basis(PackedFloat64Array([0.,0.,-1.]))
	attitude.reset(first)
	var body:=PackedFloat64Array([1.,0.,0.])
	var side:PackedFloat64Array=attitude.side_basis(body)
	var local:=ShipFrame.to_ship(side,body)
	check(absf(local[2]-sin(deg_to_rad(15.)))<1e-10 and absf(local[1])<1e-10 and local[0]>0.,'body fifteen degrees above ship horizon')
	attitude.turn_to(side,3.)
	check(attitude.current==first,'starting turn does not jump')
	var max_step:=0.
	for frame in 180:
		var old:PackedFloat64Array=attitude.current.duplicate()
		attitude.advance(1./60.)
		for i in 9:max_step=maxf(max_step,absf(attitude.current[i]-old[i]))
		check(absf(ShipFrame.det(attitude.current)-1.)<1e-10,'orthonormal attitude') if frame==90 else null
	check(max_step<.06,'bounded per-frame attitude transition')
	check(attitude.current==side and not attitude.turning(),'exact endpoint in three seconds')
	var reversed:=ShipFrame.ship_basis(PackedFloat64Array([0.,0.,1.]))
	attitude.turn_to(reversed,3.);attitude.advance(30.)
	check(attitude.current==reversed and not attitude.turning(),'long frame reaches finite exact endpoint')
	print('ship-attitude: %d failures'%failed);quit(1 if failed else 0)
