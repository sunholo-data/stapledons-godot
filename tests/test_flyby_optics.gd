extends SceneTree
var failures := 0
var checks := 0
func check(name: String, ok: bool) -> void:
	checks+=1
	if not ok: failures+=1;print("FAIL ",name)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var mirror := Planets.new()
	check("audited float64 inverse-ray mirror exists",mirror.has_method("inverse_ray64"))
	if mirror.has_method("inverse_ray64"):
		for line in FileAccess.get_file_as_string("res://tests/fixtures/flyby_package.jsonl").split("\n",false):
			var row: Array = JSON.parse_string(line)
			var got: PackedFloat64Array = mirror.call("inverse_ray64",PackedFloat64Array([sin(row[1]),0,cos(row[1])]),PackedFloat64Array([0,0,1]),row[0],row[2],row[3])
			check("inverse ray matches package <1e-12",absf(got[0]-row[6])+absf(got[1]-row[7])+absf(got[2]-row[8])<1e-12)
			# Vector2 is float32; scalar-array implementation must retain float64.
			var exact: Array = mirror.call("apparent_disc64",cos(row[1]),deg_to_rad(5.),row[0],row[2])
			check("apparent centre/radius match actual package",absf(exact[0]-row[4])+absf(exact[1]-row[5])<1e-12)
			check("stable apparent Doppler matches package",absf(mirror.call("doppler_seen64",PackedFloat64Array([sin(row[1]),0,cos(row[1])]),PackedFloat64Array([0,0,1]),row[0],row[2],row[3])-row[9])<1e-12)
		for i in 1024:
			var z := -1.0+2.0*(i+.5)/1024.;var a := i*2.399963229728653
			var n := PackedFloat64Array([sqrt(1-z*z)*cos(a),sqrt(1-z*z)*sin(a),z]);var b:=.99;var g:=7.088812050083356
			var seen:PackedFloat64Array=mirror.call("inverse_ray64",n,PackedFloat64Array([0,0,-1]),b,g,.01)
			var back:PackedFloat64Array=mirror.call("inverse_ray64",seen,PackedFloat64Array([0,0,1]),b,g,.01)
			check("1024 deterministic direction roundtrip",absf(back[0]-n[0])+absf(back[1]-n[1])+absf(back[2]-n[2])<1e-11)
	print("flyby-optics: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
