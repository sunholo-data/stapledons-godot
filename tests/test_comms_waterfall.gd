extends SceneTree
## R3-COMMS-V2 CV3 (design r3/comms-station-v2.md §D6, AC7): the waterfall of the signal from home.
## make comms-waterfall-test (headless: the Dummy driver mixes, and the analyser reads before the fader).
##   carrier  the Carrier tap's measured peak sits at the True carrier, 400 x D, within 1 % (AC7), at
##            D = 0.05 (20 Hz, the floor of hearing), 0.070888, 1 and 14.107 (RS-26, rest, RS-29), over
##            20 measurements each; the test computes 400 x D as its oracle, the waterfall never does
##   estimator hann_peak recovers a synthetic Hann-windowed tone's frequency to 0.2 % of a bin
##   trace    each trace point is that frame's measurement: a column with no measurement has no point
##            (fed 400, 400, 400, then 0, the newest column is empty)
##   hearing  at D = 60 and 1414.2 (RS-30) True is above hearing: the taps are stopped and the arrow
##            reads above; at D = 0.03 (12 Hz) and 0.01, below (RS-46: 20 Hz, Mark 2026-11-03)
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


## A Hann window's response to a tone `x` bins from a bin (its main lobe), the oracle for hann_peak.
func hann_mag(x: float) -> float:
	if absf(x) < 1e-9:
		return 0.5
	if absf(absf(x) - 1.0) < 1e-9:
		return 0.25
	return absf(sin(PI * x) / (PI * x) * 0.5 / (1.0 - x * x))


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
	for d: float in [0.05, 0.070888, 1.0, 14.107]:
		await settle(w, view_at(d), false, 1.4)
		var want := CommsWaterfall.carrier_hz() * d # the test's oracle
		var worst := 0.0
		var n := 0
		var t0 := Time.get_ticks_msec()
		while n < 20 and Time.get_ticks_msec() - t0 < 8000:
			await process_frame
			var got := w.measure_peak()
			if got > 0.0: # between Earth's pips there is no measurement
				worst = maxf(worst, absf(got / want - 1.0))
				n += 1
		check("carrier: D %s, %d measurements within %.3f %% of the True carrier %.3f Hz (AC7: 1 %%; bin %.2f Hz)" % [d, n, worst * 100.0, want, CommsWaterfall.bin_hz()], n == 20 and worst <= 0.01)
	var est := 0.0
	for frac: float in [0.0, 0.13, 0.27, 0.5, 0.71, 0.93]:
		var k := 7
		var tone := k + frac
		var mags := []
		for j in [k - 1, k, k + 1]:
			mags.append(hann_mag(tone - j))
		est = maxf(est, absf(CommsWaterfall.hann_peak(k, mags[0], mags[1], mags[2]) / CommsWaterfall.bin_hz() - tone))
	check("estimator: hann_peak recovers synthetic Hann tones to %.4f bins (want <= 0.002)" % est, est <= 0.002)
	var tr := CommsWaterfall.new()
	for hz: float in [400.0, 400.0, 400.0, 0.0]:
		tr.push_trace(hz)
	check("trace: a column with no measurement has no point (newest %s after 400, 400, 400, 0)" % tr._trace[tr._cols - 1], tr._trace[tr._cols - 1] == 0.0 and tr._trace[tr._cols - 2] == 400.0)
	tr.free()
	for d: float in [60.0, 1414.2]:
		await settle(w, view_at(d), false, 0.3)
		check("hearing: D %s is above hearing, the taps silent" % d, w.hearing == "above" and w.measure_peak() == 0.0 and not w._carrier.playing)
	for d: float in [0.03, 0.01]:
		await settle(w, view_at(d), false, 0.3)
		check("hearing: D %s (%.0f Hz) is below hearing, the taps silent" % [d, 400.0 * d], w.hearing == "below" and not w._carrier.playing)
	await settle(w, view_at(0.05), false, 0.3)
	check("hearing: D 0.05 (20 Hz, RS-46) is the floor, still heard", w.hearing == "" and w._carrier.playing)
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
