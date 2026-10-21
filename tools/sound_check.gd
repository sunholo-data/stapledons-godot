extends SceneTree
## R2-SOUND AC6 (design_docs/planned/r2/sound.md §D2, §D9): make sound-check.
##   - every cue's level at default settings, from its own samples × its volume_db (the buses add no
##     gain at default: the compressors are idle without a voice and the reverb is dry), against its
##     band (RMS over the active span, samples above −60 dBFS; a loop's RMS over exactly one loop)
##     and the peak ceiling;
##   - laptop speakers: the hum and the boost keep at least −6 dB of their RMS through a 150 Hz
##     one-pole high-pass;
##   - through the real mixer (the headless Dummy driver mixes): one cue's captured level matches
##     its computed level within 1.5 dB; a voice ducks the Ship bus by at least 6 dB; every cue at
##     once stays at or below −1 dBFS before the Master limiter, and the limiter is there;
##   - negative control: the same check on a cue 30 dB too hot fails.
## Writes the measurements as JSON (--out=<file>) for the review page.
## Run: godot --headless --path . --script tools/sound_check.gd [-- --out=<file>]
var failed := 0
var passed := 0
var d: SoundDirector
var table: Dictionary
var measures := {}


func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", message])


func _initialize() -> void:
	_run.call_deferred()


static func db(x: float) -> float:
	return -120.0 if x <= 0.000001 else 20.0 * log(x) / log(10.0)


## Samples of an asset's source WAV as floats in [-1, 1] (the source file, not the imported stream,
## which Godot compresses with QOA).
func samples(asset_id: String) -> PackedFloat32Array:
	var b := FileAccess.get_file_as_bytes("res://" + str(d.assets[asset_id].path))
	var h := SoundData.wav_info(b)
	var out := PackedFloat32Array()
	out.resize(h.frames)
	for i in h.frames:
		out[i] = b.decode_s16(h.data_offset + i * 2) / 32768.0
	return out


## {peak_dbfs, rms_dbfs, seconds} of samples × gain; RMS over samples above −60 dBFS.
static func level(x: PackedFloat32Array, gain_db: float) -> Dictionary:
	var g := db_to_linear(gain_db)
	var peak := 0.0
	var sq := 0.0
	var m := 0
	for v in x:
		var a := absf(v * g)
		peak = maxf(peak, a)
		if a > 0.001:
			sq += a * a
			m += 1
	return {"peak_dbfs": snappedf(db(peak), 0.01), "rms_dbfs": snappedf(db(sqrt(sq / maxf(1, m))), 0.01), "seconds": snappedf(x.size() / 48000.0, 0.001)}


## The RMS kept through a one-pole 150 Hz high-pass, in dB relative to the whole.
static func highpass_keep_db(x: PackedFloat32Array) -> float:
	var a := 1.0 - exp(-TAU * 150.0 / 48000.0)
	var lp := 0.0
	var all := 0.0
	var hi := 0.0
	for v in x:
		lp += a * (v - lp)
		all += v * v
		hi += (v - lp) * (v - lp)
	return db(sqrt(hi / maxf(all, 1e-12)))


## The loudest dB a param loop reaches (its curve's highest point); 0 for an ordinary cue.
static func max_param_db(c: Dictionary) -> float:
	var pc: Variant = c.get("param", null)
	if not pc is Dictionary:
		return 0.0
	var m := -80.0
	for p: Array in pc.points:
		m = maxf(m, float(p[1]))
	return m


## RMS through four one-pole 120 Hz low-passes, in dB relative to the whole (the felt band).
static func lowband_db(x: PackedFloat32Array) -> float:
	var a := 1.0 - exp(-TAU * 120.0 / 48000.0)
	var y := [0.0, 0.0, 0.0, 0.0]
	var all := 0.0
	var lo := 0.0
	for v in x:
		var u := v
		for k in 4:
			y[k] = y[k] + a * (u - y[k])
			u = y[k]
		all += v * v
		lo += u * u
	return db(sqrt(lo / maxf(all, 1e-12)))


## The band and peak errors of one cue's level (empty = within).
func band_errors(c: Dictionary, lv: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	var band: Array = c.get("band", table.bands.get(c.bus, [-120, 0]))
	if lv.rms_dbfs < float(band[0]) or lv.rms_dbfs > float(band[1]):
		bad.append("%s: RMS %.1f dBFS is outside its band %s" % [c.id, lv.rms_dbfs, band])
	if lv.peak_dbfs > float(table.peak_max_dbfs):
		bad.append("%s: peak %.1f dBFS is over %.1f" % [c.id, lv.peak_dbfs, table.peak_max_dbfs])
	return bad


func capture_for(cap: AudioEffectCapture, seconds: float) -> PackedVector2Array:
	cap.clear_buffer()
	var out := PackedVector2Array()
	var t := 0.0
	while t < seconds:
		await process_frame
		t += 1.0 / 60.0
		var n := cap.get_frames_available()
		if n > 0:
			out.append_array(cap.get_buffer(n))
	return out


static func stereo_level(buf: PackedVector2Array) -> Dictionary:
	var peak := 0.0
	var sq := 0.0
	for f in buf:
		peak = maxf(peak, maxf(absf(f.x), absf(f.y)))
		sq += f.x * f.x
	return {"peak_dbfs": db(peak), "rms_dbfs": db(sqrt(sq / maxf(1, buf.size())))}


func _run() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	table = SoundData.read_json(SoundData.CUES_PATH)
	d = SoundDirector.new()
	var errs := d.setup()
	check(errs.is_empty(), "the shipped cue table and manifest validate (%s)" % "; ".join(errs))
	if not errs.is_empty():
		_finish(args)
		return
	root.add_child(d)
	var cam := Camera3D.new() # 3D audio needs a current camera (design §Evidence)
	root.add_child(cam)

	# Offline levels against the bands.
	for id: String in d.cues:
		var c: Dictionary = d.cues[id]
		var x := samples(str(c.streams[0]))
		var lv := level(x, float(c.volume_db) + max_param_db(c)) # a param loop at its loudest (fully degraded)
		measures[id] = lv
		var bad := band_errors(c, lv)
		check(bad.is_empty(), "AC6: %s on %s: RMS %.1f dBFS, peak %.1f dBFS (%s)" % [id, c.bus, lv.rms_dbfs, lv.peak_dbfs, "; ".join(bad) if not bad.is_empty() else "in band"])
	for id: String in ["spire_hum", "drive_boost"]:
		var keep := highpass_keep_db(samples(id))
		measures[id]["highpass150_keep_db"] = snappedf(keep, 0.01)
		check(keep >= -6.0, "AC6 laptop speakers: %s keeps %.1f dB of its RMS above 150 Hz (>= -6)" % [id, keep])

	# The teacup rule (§D3.2): the drive is never felt. Energy under about 200 Hz (a 4-pole 120 Hz
	# low-pass) stays at least 20 dB below the whole.
	for id: String in ["drive_boost", "drive_silent", "drive_brake"]:
		var low := lowband_db(samples(id))
		measures[id]["below_200hz_db"] = snappedf(low, 0.01)
		check(low <= -20.0, "AC6 teacup rule: %s keeps %.1f dB below 200 Hz (<= -20)" % [id, low])
	var thud := PackedFloat32Array()
	thud.resize(48000)
	for i in 48000:
		thud[i] = 0.5 * sin(TAU * 60.0 * i / 48000.0) + 0.2 * sin(TAU * 300.0 * i / 48000.0)
	check(lowband_db(thud) > -20.0, "AC6 teacup negative control: a 60 Hz rumble fails the guard")

	# Negative control: 30 dB too hot fails both the band and the peak.
	var hot: Dictionary = d.cues["ui_click"].duplicate(true)
	hot.volume_db = float(hot.volume_db) + 30.0
	check(band_errors(hot, level(samples("ui_click"), hot.volume_db)).size() == 2, "AC6 negative control: a cue 30 dB too hot fails its band and the peak ceiling")

	# Through the mixer: a pre-limiter capture at the head of Master.
	var cap := AudioEffectCapture.new()
	cap.buffer_length = 2.0
	AudioServer.add_bus_effect(0, cap, 0)
	var lim_ok := SoundMix.is_layout_ok().is_empty()
	check(lim_ok, "AC6: the layout has the Master limiter at -1 dB and Voice ducking on Ship, UI and Music")
	await process_frame
	d.on_game("level_bridge")
	await capture_for(cap, 0.4)
	var bed := stereo_level(await capture_for(cap, 1.0))
	var room := level(samples("room_bridge").slice(0, 48000), float(d.cues["room_bridge"].volume_db))
	var hum := level(samples("spire_hum").slice(0, 48000), float(d.cues["spire_hum"].volume_db))
	var want: float = db(sqrt(pow(db_to_linear(room.rms_dbfs), 2) + pow(db_to_linear(hum.rms_dbfs), 2)))
	check(absf(bed.rms_dbfs - want) < 1.5, "mixer routing: the bridge bed captures at %.1f dBFS, computed %.1f (within 1.5 dB)" % [bed.rms_dbfs, want])
	var ship_cap := AudioEffectCapture.new()
	ship_cap.buffer_length = 2.0
	var ship := AudioServer.get_bus_index("Ship")
	AudioServer.add_bus_effect(ship, ship_cap) # last, after the ducking compressor
	await capture_for(ship_cap, 0.3)
	var before := stereo_level(await capture_for(ship_cap, 0.8))
	var voice := AudioStreamPlayer.new()
	voice.bus = &"Voice"
	voice.stream = _voice_proxy()
	root.add_child(voice)
	voice.play()
	await capture_for(ship_cap, 0.3)
	var during := stereo_level(await capture_for(ship_cap, 0.8))
	var duck: float = before.rms_dbfs - during.rms_dbfs
	measures["_ducking_db"] = snappedf(duck, 0.1)
	check(duck >= 6.0, "AC6: a voice at about -18 dBFS ducks the Ship bus by %.1f dB (>= 6)" % duck)
	voice.stop()
	d.on_game("level_none")
	await capture_for(cap, 0.5)

	# Every cue at once, with the Archive fully degraded (the drift layers at their loudest): the mix
	# fits under -1 dBFS before the limiter.
	d.set_param("archive_degradation", 1.0)
	for id: String in d.cues:
		d.fire(id, "all", 0)
	var all := stereo_level(await capture_for(cap, 1.5))
	measures["_all_at_once_prelimiter_peak_dbfs"] = snappedf(all.peak_dbfs, 0.01)
	check(all.peak_dbfs <= -1.0, "AC6: every cue at once peaks at %.1f dBFS before the Master limiter (<= -1)" % all.peak_dbfs)
	d.on_game("level_none")
	_finish(args)


## A voice stand-in for the ducking check: a 200 Hz-based buzz at about -18 dBFS RMS, 2 s.
func _voice_proxy() -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 48000
	var n := 96000
	var b := PackedByteArray()
	b.resize(n * 2)
	for i in n:
		var t := i / 48000.0
		var v := 0.12 * (sin(TAU * 200.0 * t) + 0.5 * sin(TAU * 400.0 * t) + 0.3 * sin(TAU * 600.0 * t))
		b.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	s.data = b
	return s


func _finish(args: Dictionary) -> void:
	if args.has("out"):
		DirAccess.make_dir_recursive_absolute(str(args.out).get_base_dir())
		var f := FileAccess.open(args.out, FileAccess.WRITE)
		f.store_string(JSON.stringify(measures, " ", false) + "\n")
		f.close()
	print("sound-check: %d passed, %d failures" % [passed, failed])
	quit(1 if failed > 0 else 0)
