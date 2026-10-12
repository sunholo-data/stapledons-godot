extends SceneTree
var failures:=0
func check(name:String,ok:bool)->void:
	print("ok " if ok else "FAIL ",name)
	if not ok:failures+=1
func _initialize()->void:run.call_deferred()
func run()->void:
	for minor in [3,4,5]:
		var sim:=SimBridge.new();sim.want_minor=minor
		check("minor%d actual normal handshake"%minor,sim.start() and sim.new_game(23))
		var rings:Array=sim.world.get("system",{}).get("rings",[])
		if minor<5:check("legacy minor%d has no ring fields"%minor,rings.is_empty())
		else:
			check("minor5 provides four authoritative ring systems",rings.size()==4)
			var saturn:Dictionary={}
			for ring:Dictionary in rings:
				if ring.host=="saturn":saturn=ring
			check("Saturn bands match source data",saturn.get("bands",[]).size()==11 and saturn.bands[0].r_in_km==66900.0 and saturn.bands[4].tau==3.6 and saturn.bands[10].r_out_km==140612.0)
			check("ring assumptions and citations travel with data",saturn.get("tint_cite","")=="tint-design" and saturn.get("tau_cite","")=="pds-rings" and saturn.get("tint",{}).get("r",0)==.83)
			check("live tick retains authoritative ring table",sim.send([],0.000001) and sim.world.system.get("rings",[])==rings)
		sim.stop()
	print("ring-protocol: %d failures"%failures);quit(1 if failures else 0)
