extends SceneTree
## Normal cold compilation gets headroom; explicit fixture sessions and requests stay bounded.
var failures:=0
var checks:=0
func _initialize()->void:run.call_deferred()
func check(label:String,ok:bool)->void:
	checks+=1;print("ok " if ok else "FAIL ",label)
	if not ok:failures+=1
func fake(mode:String)->SimBridge:
	var s:=SimBridge.new()
	s.launch_override={"bin":"python3","args":PackedStringArray([ProjectSettings.globalize_path("res://tests/fixtures/fake_sim.py"),mode])}
	return s
func gone(pid:int)->bool:return OS.execute("/bin/kill",["-0",str(pid)],[])!=0
func run()->void:
	var policy:=SimBridge.new()
	check("explicit normal-vs-fixture bootstrap policy",policy.has_method("bootstrap_budget_ms"))
	if not policy.has_method("bootstrap_budget_ms"):
		print("sim-bootstrap: %d checks %d failures"%[checks,failures]);quit(1);return
	check("exported bundled bootstrap bounded to30s",policy.call("bootstrap_budget_ms",true,false)==30000)
	check("normal source bootstrap has30s cold-compile headroom",policy.call("bootstrap_budget_ms",false,false)==30000)
	check("exported launch override remains5s",policy.call("bootstrap_budget_ms",true,true)==5000)
	check("editor launch override remains5s",policy.call("bootstrap_budget_ms",false,true)==5000)
	var silent:=fake("silent_start");var t:=Time.get_ticks_msec();var started:=silent.start();var elapsed:=Time.get_ticks_msec()-t
	check("silent overridden bootstrap still5s and finite",not started and silent.last_error=="startup_timeout" and elapsed>=4900 and elapsed<6500)
	check("bootstrap timeout cleans child and invents no state",gone(silent.child_pid) and silent.world.is_empty())
	var step:=fake("silent_step");check("fake request session ready",step.start() and step.new_game(1))
	var before:=step.world.duplicate(true);t=Time.get_ticks_msec();var accepted:=step.send([],0.01);elapsed=Time.get_ticks_msec()-t
	check("request deadline remains2s",not accepted and step.last_error=="step_timeout" and elapsed>=1900 and elapsed<3500)
	var after:=step.world.duplicate(true);before.erase("status");after.erase("status")
	check("request timeout preserves physical world and cleans child",before==after and gone(step.child_pid))
	print("sim-bootstrap: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
