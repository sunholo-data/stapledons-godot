extends SceneTree
## R3-COMMS-V2 GPU golden G-CV (definition of done gate 2; make comms-golden, part of make golden; needs a
## GPU window). The comms station's two physics visuals, drawn by the GPU, against CPU values:
##   G-CV-1 the waterfall at D = 0.070888 (outbound at 0.99c, RS-42) and 14.107 (homebound, RS-43), from
##          the live Carrier tap (the real audio driver):
##            trace    the measured carrier's trace: each rendered point's row within 0.5 px of the CPU row
##                     of its own measurement, and every measurement within 1 % of 400 x D (the oracle)
##            line     the Receiver's line within 0.5 px of the CPU row of 400 Hz
##            tick     the bracket's foot (the teal tick) within 0.5 px of the same row
##            tip      the bracket's arrow tip within 1.0 px of the CPU row of the measured carrier
##   G-CV-2 the frame diagram for an outbound week and a homebound week of the real sim at 2.18 (seed 7:
##          out to Alpha Cen A, home along Earth's beam):
##            sent     the send dot's centroid within 0.5 px of the CPU light-cone event, t = arrived.t -
##                     arrived.ly (float64 from the record's arrival), on Earth's line
##            arrived  the arrival dot's centroid within 0.5 px of (arrived.t, arrived.ly)
##            then     the ship-when-sent ring's centroid within 0.5 px of ship_at_sent
##            light    the rendered ray at 45 degrees (|slope| within 0.01 of 1 on equal axes) and through
##                     the CPU send event (0.5 px)
## Each element is drawn alone (the views' `layers`), so a centroid is that element's. The row maps (the
## log axis, the diagram's box) are the views' presentation; the physics (400 x D, the light cone) is
## computed here, independently. 16 cases, plus the line that the voyage ran (17 lines).

const ALPHA := {"index": 2, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}
const SOL := {"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}
const PHI := 2.6466524123622457
const WF := Vector2i(920, 400)
const STRIP := Vector2i(1000, 132)
var failures := 0
var passes := 0
var vp: SubViewport


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	SoundMix.ensure_layout()
	vp = SubViewport.new()
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	await waterfall_cases()
	await frame_cases()
	print("comms-golden: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func grab() -> Image:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	return vp.get_texture().get_image()


## The lit weight of a pixel over the dark ground (its luminance above `ground`).
static func lit(img: Image, x: int, y: int, ground: float) -> float:
	return maxf(img.get_pixel(x, y).get_luminance() - ground, 0.0)


## The weighted centroid row of column x within rows [y0, y1); -1 when nothing is lit.
static func col_centroid(img: Image, x: int, y0: int, y1: int, ground: float) -> float:
	var s := 0.0
	var w := 0.0
	for y in range(maxi(y0, 0), mini(y1, img.get_height())):
		var l := lit(img, x, y, ground)
		if l > 0.02:
			s += (y + 0.5) * l
			w += l
	return s / w if w > 0.0 else -1.0


# ----------------------------------------------------------------------------------- G-CV-1 waterfall
func waterfall_cases() -> void:
	vp.size = WF
	var w := CommsWaterfall.new()
	w.bold = true
	w.position = Vector2.ZERO
	w.size = Vector2(WF)
	vp.add_child(w)
	await process_frame
	for d: float in [0.070888, 14.107]:
		var view := {"earth": {"rate": d, "in_beam": true}}
		w.layers = CommsWaterfall.L_PICTURE | CommsWaterfall.L_TRACE
		w.set_process(true)
		w.refresh(view, true, "")
		var t1 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t1 < 1500: # the analyser's buffer forgets the previous case
			await process_frame
		w._trace.fill(0.0) # this case's measurements only
		# let the trace fill: at 0.07 Earth's keyed pips come every 14 s, so wait for a run of measurements
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 60000:
			await process_frame
			if _run_len(w) >= 16:
				break
		w.set_process(false) # freeze the trace for the reads
		var want := 400.0 * d # the oracle
		var z := 2.6
		var r := Rect2(Vector2(26.0 * z, 4.0), Vector2(WF) - Vector2(30.0 * z, 8.0))
		# trace alone
		w.layers = CommsWaterfall.L_TRACE
		w.queue_redraw()
		var img := await grab()
		var ground := img.get_pixel(2, 2).get_luminance() + 0.02
		var worst := 0.0
		var phys := 0.0
		var n := 0
		for i in range(w._cols - 2, 0, -1):
			if w._trace[i] <= 0.0 or w._trace[i - 1] <= 0.0 or w._trace[i + 1] <= 0.0:
				continue
			var x := r.position.x + (i + 0.5) / w._cols * r.size.x
			if x > r.end.x - 40.0: # clear of the bracket's column
				continue
			var cy := yrow(w._trace[i], r)
			var got := col_centroid(img, int(x), int(cy) - 14, int(cy) + 15, ground)
			worst = maxf(worst, absf(got - cy) if got >= 0.0 else INF)
			phys = maxf(phys, absf(w._trace[i] / want - 1.0))
			n += 1
		check("G-CV-1 trace D %s: %d points, rendered rows within %.3f px of their measurements (0.5), measured within %.4f %% of 400 x D = %.3f Hz (1 %%)" % [d, n, worst, phys * 100.0, want], n >= 8 and worst <= 0.5 and phys <= 0.01)
		var peak := _last_peak(w)
		w.peak_hz = peak
		var yr := yrow(400.0, r)
		# the Receiver's line alone
		w.layers = CommsWaterfall.L_LINE
		w.queue_redraw()
		img = await grab()
		var acc := 0.0
		var m := 0
		for x in range(int(r.position.x) + 20, int(r.end.x) - 60, 7):
			var c := col_centroid(img, x, int(yr) - 10, int(yr) + 11, ground)
			if c >= 0.0:
				acc += c
				m += 1
		var line_y := acc / maxf(m, 1)
		check("G-CV-1 line D %s: the Receiver's 400 Hz line at row %.3f, CPU %.3f (d = %.3f px, 0.5)" % [d, line_y, yr, absf(line_y - yr)], m > 20 and absf(line_y - yr) <= 0.5)
		# the bracket alone
		w.layers = CommsWaterfall.L_BRACKET
		w.queue_redraw()
		img = await grab()
		var bx := r.end.x - 10.0 * z
		acc = 0.0
		m = 0
		for x in range(int(bx - 12.0), int(bx - 4.5)):
			var c := col_centroid(img, x, int(yr) - 8, int(yr) + 9, ground)
			if c >= 0.0:
				acc += c
				m += 1
		var tick_y := acc / maxf(m, 1)
		check("G-CV-1 tick D %s: the bracket's foot at row %.3f, CPU %.3f (d = %.3f px, 0.5)" % [d, tick_y, yr, absf(tick_y - yr)], m >= 4 and absf(tick_y - yr) <= 0.5)
		var yt := yrow(peak, r)
		var up := yt < yr
		var tip := -1.0
		var mx := 0.0
		for y in img.get_height():
			mx = maxf(mx, lit(img, int(bx), y, ground))
		var rows := range(img.get_height()) if up else range(img.get_height() - 1, -1, -1)
		for y: int in rows:
			if lit(img, int(bx), y, ground) >= 0.5 * mx:
				tip = y + (0.0 if up else 1.0)
				break
		check("G-CV-1 tip D %s: the arrow's tip at row %.1f, CPU row of the measured %.3f Hz %.3f (d = %.3f px, 1.0)" % [d, tip, peak, yt, absf(tip - yt)], peak > 0.0 and absf(tip - yt) <= 1.0)
	w.free()


static func yrow(f: float, r: Rect2) -> float:
	return r.end.y - log(f / CommsWaterfall.F0) / log(CommsWaterfall.F1 / CommsWaterfall.F0) * r.size.y


## The longest run of measured columns among the newest 120.
static func _run_len(w: CommsWaterfall) -> int:
	var best := 0
	var cur := 0
	for i in range(w._cols - 200, w._cols - 12):
		cur = cur + 1 if w._trace[i] > 0.0 else 0
		best = maxi(best, cur)
	return best


static func _last_peak(w: CommsWaterfall) -> float:
	for i in range(w._cols - 1, -1, -1):
		if w._trace[i] > 0.0:
			return w._trace[i]
	return 0.0


# ----------------------------------------------------------------------------------- G-CV-2 frame diagram
func frame_cases() -> void:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.EARTH_LOG_MINOR
	var ok := sim.start() and sim.new_game(7, "free_nav", false, {}, "", "") and fly(sim, ALPHA)
	var n := 0
	while ok and n < 400 and str(sim.world.get("journey", {}).get("state", "")) != "arrived":
		ok = sim.send([], 0.004)
		n += 1
	ok = ok and fly(sim, SOL)
	for i in 120:
		ok = ok and sim.send([], 0.004)
	var view := sim.world.duplicate(true)
	sim.stop()
	var recs: Array = view.get("earth_log", {}).get("records", [])
	check("G-CV-2 the real voyage ran (%d records)" % recs.size(), ok and recs.size() > 10)
	if not ok:
		return
	var homeward := -1
	for i in range(recs.size() - 1, -1, -1):
		if recs[i].beamed == true and recs[i].get("ship_at_sent") is Dictionary:
			homeward = i
			break
	vp.size = STRIP
	var s := EarthStrip.new()
	s.position = Vector2.ZERO
	s.size = Vector2(STRIP)
	vp.add_child(s)
	await process_frame
	for c: Array in [["outbound", 1], ["homebound", homeward]]:
		var k: int = c[1]
		s.refresh(view)
		s.set_frame(k)
		s.size = Vector2(STRIP)
		var r: Dictionary = recs[k]
		var arr: Dictionary = r.arrived
		var box := s._frame_box()
		var sent_t := float(arr.t) - float(arr.ly) # the light cone, here in float64
		var want_sent := s.eq(box, Vector2(sent_t, 0.0))
		var want_hit := s.eq(box, Vector2(float(arr.t), float(arr.ly)))
		var then: Dictionary = r.ship_at_sent if r.get("ship_at_sent") is Dictionary else {}
		var want_then := s.eq(box, Vector2(float(then.get("t", 0.0)), float(then.get("ly", 0.0))))
		s.layers = EarthStrip.L_EVENTS | EarthStrip.L_BACK
		s._place_tags()
		s.queue_redraw()
		var img := await grab()
		var got_sent := blob(img, want_sent, 9, StapledonTheme.OCHRE_LIGHT)
		var got_hit := blob(img, want_hit, 10, StapledonTheme.TEAL_LIGHT)
		check("G-CV-2 sent %s (record %d): GPU (%.2f, %.2f), CPU light cone (%.2f, %.2f), d = %.3f px (record sent.t - CPU %s yr)" % [c[0], k, got_sent.x, got_sent.y, want_sent.x, want_sent.y, got_sent.distance_to(want_sent), String.num_scientific(float(r.sent.t) - sent_t)], got_sent.distance_to(want_sent) <= 0.5)
		check("G-CV-2 arrived %s: GPU (%.2f, %.2f), CPU (%.2f, %.2f), d = %.3f px" % [c[0], got_hit.x, got_hit.y, want_hit.x, want_hit.y, got_hit.distance_to(want_hit)], got_hit.distance_to(want_hit) <= 0.5)
		s.layers = EarthStrip.L_THEN | EarthStrip.L_BACK
		s.queue_redraw()
		img = await grab()
		var got_then := blob(img, want_then, 10, StapledonTheme.TEAL_LIGHT)
		check("G-CV-2 then %s: GPU (%.2f, %.2f), CPU (%.2f, %.2f), d = %.3f px" % [c[0], got_then.x, got_then.y, want_then.x, want_then.y, got_then.distance_to(want_then)], not then.is_empty() and got_then.distance_to(want_then) <= 0.5)
		s.layers = EarthStrip.L_RAY | EarthStrip.L_BACK
		s.queue_redraw()
		img = await grab()
		var ground := img.get_pixel(2, 2).get_luminance() + 0.02
		var xs := PackedFloat64Array()
		var ys := PackedFloat64Array()
		var a := minf(want_sent.x, want_hit.x)
		var b := maxf(want_sent.x, want_hit.x)
		for x in range(int(a + 0.2 * (b - a)), int(b - 0.2 * (b - a))):
			var t := (x + 0.5 - want_sent.x) / (want_hit.x - want_sent.x)
			var yc := lerpf(want_sent.y, want_hit.y, t)
			var cy := col_centroid(img, x, int(yc) - 5, int(yc) + 6, ground)
			if cy >= 0.0:
				xs.append(x + 0.5)
				ys.append(cy)
		var fit := line_fit(xs, ys)
		var off := absf(fit.slope * want_sent.x + fit.icept - want_sent.y) / sqrt(1.0 + fit.slope * fit.slope)
		check("G-CV-2 light %s: rendered slope %.4f (|slope| 1 within 0.01: 45 degrees on equal axes), through the CPU send event (%.3f px) over %d columns" % [c[0], fit.slope, off, xs.size()], xs.size() >= 10 and absf(absf(fit.slope) - 1.0) <= 0.01 and off <= 0.5)
	s.free()


func fly(sim: SimBridge, target: Dictionary) -> bool:
	if not sim.send([{"k": "plan", "target": target, "cruise_phi": PHI}], 0.0):
		return false
	return sim.send([{"k": "commit", "plan_id": int(sim.world.get("journey", {}).get("plan_id", 0))}], 0.0)


## The centroid of pixels close to colour `col` within `rad` px of `near` (a dot drawn alone).
static func blob(img: Image, near: Vector2, rad: int, col: Color) -> Vector2:
	var s := Vector2.ZERO
	var w := 0.0
	for y in range(int(near.y) - rad, int(near.y) + rad + 1):
		for x in range(int(near.x) - rad, int(near.x) + rad + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var p := img.get_pixel(x, y)
			var cov := clampf(1.0 - Vector3(p.r - col.r, p.g - col.g, p.b - col.b).length() / 0.6, 0.0, 1.0)
			if cov > 0.05:
				s += Vector2(x + 0.5, y + 0.5) * cov
				w += cov
	return s / w if w > 0.0 else Vector2(-1e4, -1e4)


static func line_fit(xs: PackedFloat64Array, ys: PackedFloat64Array) -> Dictionary:
	var n := float(xs.size())
	if n < 2.0:
		return {"slope": 0.0, "icept": 0.0}
	var sx := 0.0
	var sy := 0.0
	var sxx := 0.0
	var sxy := 0.0
	for i in xs.size():
		sx += xs[i]
		sy += ys[i]
		sxx += xs[i] * xs[i]
		sxy += xs[i] * ys[i]
	var slope := (n * sxy - sx * sy) / (n * sxx - sx * sx)
	return {"slope": slope, "icept": (sy - slope * sx) / n}
