extends SceneTree
## R3-COMMS-V2 CV3 (design r3/comms-station-v2.md §D6, AC7): the waterfall of the signal from home.
## make comms-waterfall-test (headless: the Dummy driver mixes, and the analyser reads before the fader).
##   carrier  the Carrier tap's measured peak sits at the True carrier, 400 x D, within 1 % or one
##            analyser bin (mix rate / FFT size), whichever is larger, at D = 0.070888, 1 and 14.107
##            (RS-26, rest, RS-29); the test computes 400 x D as its oracle, the waterfall never does
##   hearing  at D = 60 and 1414.2 (RS-30) True is above hearing: the taps are stopped and the arrow
##            reads above; at D = 0.01, below
##   line     the Receiver's line is the data constant (waterfall.carrier_hz) in both settings
##   silent   the taps are analysis buses at −80 dB, never heard; no beam, no tap
##   guard    ui/comms_waterfall.gd never multiplies a rate into a frequency

var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func view_at(d: float, beam := true) -> Dictionary:
	return {"earth": {"rate": d, "in_beam": beam}}


func settle(w: CommsWaterfall, v: Dictionary, rx: bool, seconds: float) -> void:
	w.refresh(v, rx, "")
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(seconds * 1000.0):
		await process_frame


func _run() -> void:
	SoundMix.ensure_layout()
	var w := CommsWaterfall.new()
	w.size = Vector2(480, 140)
	root.add_child(w)
	await process_frame
	var bin := AudioServer.get_mix_rate() / 4096.0
	for d: float in [0.070888, 1.0, 14.107]:
		await settle(w, view_at(d), false, 1.4)
		var want := CommsWaterfall.carrier_hz() * d # the test's oracle
		var got := w.measure_peak()
		var tol := maxf(want * 0.01, bin)
		check("carrier: D %s measured %.2f Hz, True carrier %.2f Hz (tolerance %.2f)" % [d, got, want, tol], absf(got - want) <= tol)
	for d: float in [60.0, 1414.2]:
		await settle(w, view_at(d), false, 0.3)
		check("hearing: D %s is above hearing, the taps silent" % d, w.hearing == "above" and w.measure_peak() == 0.0 and not w._carrier.playing)
	await settle(w, view_at(0.01), false, 0.3)
	check("hearing: D 0.01 is below hearing", w.hearing == "below" and not w._carrier.playing)
	await settle(w, view_at(14.107), true, 0.2)
	check("line: the Receiver's line is waterfall.carrier_hz (%s Hz) in Receiver" % CommsWaterfall.carrier_hz(), w.receiver and CommsWaterfall.carrier_hz() == 400.0)
	check("line: x D is a binding on earth.rate", w.rate_tag != null and w.rate_tag.field == "earth.rate" and DisplayBinding.audit(w).is_empty())
	await settle(w, view_at(1.0, false), true, 0.2)
	check("silent: no beam, no tap", not w._carrier.playing and not w._beacon.playing)
	for b: String in ["Antenna", "Carrier"]:
		var i := AudioServer.get_bus_index(b)
		check("silent: %s is an analysis tap at %.0f dB (never above −60)" % [b, AudioServer.get_bus_volume_db(i)], i >= 0 and AudioServer.get_bus_volume_db(i) <= -60.0)
	check("silent: the bus layout matches SoundMix.BUSES", SoundMix.is_layout_ok().is_empty())
	var src := FileAccess.get_file_as_string("res://ui/comms_waterfall.gd")
	var re := RegEx.create_from_string("(rate|\\bd\\b)\\s*\\*\\s*carrier_hz|carrier_hz\\(\\)\\s*\\*\\s*(rate|\\bd\\b)")
	check("guard: no rate x frequency in the waterfall", re.search(src) == null)
	print("comms-waterfall: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)
