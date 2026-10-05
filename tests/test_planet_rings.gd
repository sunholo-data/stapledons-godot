extends SceneTree
var failures:=0
var checks:=0
func check(name:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1;print("FAIL ",name)
func _initialize()->void:run.call_deferred()
func run()->void:
	var mirror:=Planets.new();check("ring mirror exists",mirror.has_method("ring_lit_radiance"))
	if mirror.has_method("ring_lit_radiance"):
		for line in FileAccess.get_file_as_string("res://tests/fixtures/rings_package.jsonl").split("\n",false):
			var r:Array=JSON.parse_string(line)
			for pair in [["ring_lit_radiance",3],["ring_unlit_radiance",4]]:
				var value:float=mirror.call(pair[0],.5,1.,r[0],r[1],r[2],1000.)
				check("actual celestial package ring radiance",absf(value-r[pair[1]])<1e-12*maxf(1.,r[pair[1]]))
			check("actual celestial ring transmission",absf(mirror.call("ring_transmission",r[0],r[2])-r[5])<1e-12)
	print("planet-rings: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
