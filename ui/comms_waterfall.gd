class_name CommsWaterfall
extends Control
## R3-COMMS-V2 CV3 (design r3/comms-station-v2.md §D6): the signal from home as a scrolling waterfall.
## Time runs right to left (the newest column at the right edge), frequency up on a log axis over
## human hearing (20 Hz to 20 kHz). Standing order 2026-10-30: the picture is always True, whatever
## the station's setting: it is measured from the silent Antenna tap (SoundMix), which carries the
## True signal from home: the week's bed and Earth's carrier at speed and pitch x D, exactly the True
## plan EarthFeed.receiver_plan(D, false) gives. Over it:
##   - the Receiver's line at the carrier's rest frequency (data/ui/comms_feed.json waterfall.carrier_hz),
##     solid in the Receiver setting (what is heard), dashed in True (where a receiver would put it);
##   - a bracket from the measured True carrier (the Carrier tap's peak, interpolated across bins) to the
##     line, with x earth.rate (a binding): the gap is the Doppler shift;
##   - outside hearing (the plan's `hearing`, receiver.audible) True plays nothing: the band goes dark
##     and an arrow at the edge says "above hearing" / "below hearing".
## Nothing here multiplies a rate into a frequency (make comms-waterfall-test guards it). `bold` is the
## bridge monitor's face: bigger type and lines, fewer words (design §D3). The taps play only while
## the waterfall is visible and Earth's beam is in, and never reach the ear (−80 dB).

const F0 := 20.0
const F1 := 20000.0
const BANDS := 96
const BEACON := "home_beacon"
## The carrier tap's floor for a measured peak (linear magnitude; a keyed pip reads about 0.1, the gaps
## between pips read under 1e-4).
const PEAK_FLOOR := 1e-3

var bold := false
var receiver := true
var in_beam := false
var rate := 1.0
var hearing := "" ## the True plan's: "", "above" or "below"
var peak_hz := 0.0 ## the Carrier tap's measured peak (0 when nothing is there)
## CV5 legibility (Mark's mid-point note): the measured carrier's own trace, one point per column, drawn
## bright over the True picture so a carrier near the floor of hearing (28 Hz at x 0.07) still reads from
## across the bridge. It is the measurement itself, not a model: no point where the tap is silent.
var _trace := PackedFloat32Array()
var view: Dictionary = {}
var rate_tag: ComposedBinding = null
var _img: Image
var _tex: ImageTexture
var _cols := 240
## The taps' players are shared by every waterfall (the station's and the bridge monitor's), so two
## views of the signal never play it twice: whichever refreshes sets the same True plan.
static var _bed: AudioStreamPlayer = null
static var _beacon: AudioStreamPlayer = null
static var _carrier: AudioStreamPlayer = null
static var _bed_cue := ""
var _ramp: Gradient


func _init() -> void:
	name = "CommsWaterfall"
	clip_contents = true
	custom_minimum_size = Vector2(0, 120)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ramp = Gradient.new() # the sound agent's review look: deep violet, red, cream (magma-like)
	_ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.55, 0.8, 1.0])
	_ramp.colors = PackedColorArray([Color("#05030c"), Color("#2b1270"), Color("#b33a5b"), Color("#f08a5d"), Color("#fcf2c2")])
	_trace.resize(_cols)
	_trace.fill(0.0)
	_img = Image.create(_cols, BANDS, false, Image.FORMAT_RGB8)
	_img.fill(_ramp.sample(0.0))
	_tex = ImageTexture.create_from_image(_img)


func _ready() -> void:
	SoundMix.ensure_layout()
	_players()


## The shared tap players, made once under the tree's root (they outlive any one waterfall).
static func _players() -> void:
	if _bed != null and is_instance_valid(_bed):
		return
	var tree := Engine.get_main_loop() as SceneTree
	_bed = AudioStreamPlayer.new()
	_beacon = AudioStreamPlayer.new()
	_carrier = AudioStreamPlayer.new()
	_bed.name = "TapBed"
	_beacon.name = "TapBeacon"
	_carrier.name = "TapCarrier"
	_bed.bus = "Antenna"
	_beacon.bus = "Antenna"
	_carrier.bus = "Carrier"
	_bed_cue = ""
	for p: AudioStreamPlayer in [_bed, _beacon, _carrier]:
		tree.root.add_child.call_deferred(p)


static func carrier_hz() -> float:
	return float(EarthFeed.copy().get("waterfall", {}).get("carrier_hz", 400.0))


static var _assets := {}


## A sound by its asset id, loaded as the sound director loads it (assets/audio is .gdignore'd: the WAV
## file in the editor and tests, the QOA bundle in the export), its loop points from the manifest.
static func stream_of(id: String) -> AudioStream:
	if _assets.is_empty():
		_assets = SoundData.load_assets().get("assets", {})
	var r: Dictionary = _assets.get(id, {})
	var rel := str(r.get("path", ""))
	if rel.is_empty():
		return null
	var s: AudioStreamWAV = null
	if FileAccess.file_exists("res://" + rel):
		s = AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes("res://" + rel))
	elif ResourceLoader.exists(SoundDirector.bundle_path(rel)):
		s = ResourceLoader.load(SoundDirector.bundle_path(rel))
	if s != null:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD # the taps loop the week's sound and the carrier
		if r.get("loop", null) is Dictionary:
			s.loop_begin = int(r.loop.begin)
			s.loop_end = int(r.loop.end)
		else:
			s.loop_begin = 0
			s.loop_end = int(s.get_length() * s.mix_rate)
	return s


## The frame's world and the station's setting: Earth's rate and beam (sim fields), the week's bed.
func refresh(v: Dictionary, rx: bool, bed_cue := "") -> void:
	view = v
	receiver = rx
	var e: Variant = v.get("earth")
	in_beam = e is Dictionary and e.get("in_beam") == true
	rate = float(e.get("rate", 1.0)) if e is Dictionary else 1.0
	var plan := EarthFeed.receiver_plan(rate, false) # the True plan: speed and pitch x D, or silence
	hearing = str(plan.get("hearing", ""))
	_follow(plan, bed_cue)
	if rate_tag == null:
		rate_tag = ComposedBinding.new()
		rate_tag.theme = StapledonTheme.theme()
		rate_tag.theme_type_variation = "HUDCaption"
		rate_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rate_tag)
	rate_tag.add_theme_font_size_override("font_size", 30 if bold else 12)
	rate_tag.compose(["×", ["earth.rate", "sci"]])
	rate_tag.update_from(v)
	queue_redraw()


## The taps follow the True plan: playing at speed and pitch x D in beam and on screen, else stopped.
func _follow(plan: Dictionary, bed_cue: String) -> void:
	_players()
	var on := in_beam and is_visible_in_tree() and hearing.is_empty()
	if not on:
		for p: AudioStreamPlayer in [_bed, _beacon, _carrier]:
			p.stop()
		return
	var d := float(plan.get("rate", 1.0))
	if _beacon.stream == null:
		_beacon.stream = stream_of(BEACON)
		_carrier.stream = _beacon.stream
	if bed_cue != _bed_cue:
		_bed_cue = bed_cue
		_bed.stream = stream_of(bed_cue) if not bed_cue.is_empty() else null
		_bed.stop()
	for p: AudioStreamPlayer in [_bed, _beacon, _carrier]:
		if p.stream == null or not p.is_inside_tree():
			continue
		p.pitch_scale = d
		if not p.playing:
			p.play()


## The measured True carrier: the Carrier tap's strongest band, refined by a parabola over its
## neighbours (a measurement technique; 0 when the tap is silent).
func measure_peak() -> float:
	var inst := SoundMix.tap("Carrier")
	if inst == null or _carrier == null or not _carrier.playing:
		return 0.0
	var best := -1
	var mags := PackedFloat32Array()
	var steps := 600
	for k in steps:
		var f := F0 * pow(F1 / F0, float(k) / steps)
		var g := F0 * pow(F1 / F0, float(k + 1) / steps)
		mags.append(inst.get_magnitude_for_frequency_range(f, g).length())
		if best < 0 or mags[k] > mags[best]:
			best = k
	if best < 0 or mags[best] < PEAK_FLOOR: # between Earth's pips the keyed carrier is silent: no point
		return 0.0
	var off := 0.0
	if best > 0 and best < steps - 1:
		var a := mags[best - 1]
		var b := mags[best]
		var c := mags[best + 1]
		var den := a - 2.0 * b + c
		off = 0.5 * (a - c) / den if absf(den) > 1e-12 else 0.0
	return F0 * pow(F1 / F0, (float(best) + 0.5 + clampf(off, -0.5, 0.5)) / steps)


## The trace's point: the median of the last five measured peaks (a receiver's tracking filter; it drops
## the keying clicks' leakage, never invents a point: no carrier in the last five, no point).
var _recent := PackedFloat32Array()
func _median_peak() -> float:
	_recent.append(peak_hz)
	if _recent.size() > 5:
		_recent.remove_at(0)
	var on := Array(_recent).filter(func(h: float) -> bool: return h > 0.0)
	if on.size() < 3:
		return 0.0
	on.sort()
	return on[on.size() / 2]


## One column per frame from the Antenna tap.
func _process(_dt: float) -> void:
	if not is_visible_in_tree():
		return
	var inst := SoundMix.tap("Antenna")
	_img.blit_rect(_img, Rect2i(1, 0, _cols - 1, BANDS), Vector2i(0, 0))
	for b in BANDS:
		var f := F0 * pow(F1 / F0, float(b) / BANDS)
		var g := F0 * pow(F1 / F0, float(b + 1) / BANDS)
		var m := inst.get_magnitude_for_frequency_range(f, g).length() if inst != null and in_beam else 0.0
		var db := linear_to_db(maxf(m, 1e-7))
		_img.set_pixel(_cols - 1, BANDS - 1 - b, _ramp.sample(clampf((db + 80.0) / 70.0, 0.0, 1.0)))
	_tex.update(_img)
	peak_hz = measure_peak()
	for i in range(_cols - 1):
		_trace[i] = _trace[i + 1]
	_trace[_cols - 1] = _median_peak() if in_beam else 0.0
	queue_redraw()


func yf(f: float, r: Rect2) -> float:
	return r.end.y - log(f / F0) / log(F1 / F0) * r.size.y


func _draw() -> void:
	var z := 2.6 if bold else 1.0
	var r := Rect2(Vector2(26.0 * z, 4.0), size - Vector2(30.0 * z, 8.0))
	draw_rect(Rect2(Vector2.ZERO, size), StapledonTheme.INK)
	draw_texture_rect(_tex, r, false)
	draw_rect(r, Color(StapledonTheme.VIOLET, 0.9), false, 1.0)
	var font := get_theme_default_font()
	for g: Array in [[100.0, "100"], [1000.0, "1k"], [10000.0, "10k"]]: # axis constants (Hz)
		var y := yf(g[0], r)
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(StapledonTheme.CREAM, 0.12), 1.0)
		draw_string(font, Vector2(2, y + 4.0 * z), g[1], HORIZONTAL_ALIGNMENT_LEFT, int(24 * z), int(9 * z), Color(StapledonTheme.CREAM, 0.45))
	var w: Dictionary = EarthFeed.copy().words
	if not bold:
		var tag := ("♪ " + str(w.receiver if receiver else w.true_sound)) if in_beam else str(w.no_signal)
		draw_string(font, r.position + Vector2(6, 14), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(StapledonTheme.CREAM, 0.85))
	if rate_tag != null:
		rate_tag.visible = in_beam
	if not in_beam:
		return
	# the measured carrier's trace (bright cream, a halo under it), right to left with the picture
	var seg := PackedVector2Array()
	for i in _cols:
		var hz := _trace[i]
		if hz > 0.0:
			seg.append(Vector2(r.position.x + (i + 0.5) / _cols * r.size.x, yf(clampf(hz, F0, F1), r)))
		elif seg.size() > 1:
			draw_polyline(seg, Color(StapledonTheme.CORAL, 0.45), 6.0 * z, true)
			draw_polyline(seg, StapledonTheme.CREAM, 2.0 * z, true)
			seg = PackedVector2Array()
		else:
			seg = PackedVector2Array()
	if seg.size() > 1:
		draw_polyline(seg, Color(StapledonTheme.CORAL, 0.45), 6.0 * z, true)
		draw_polyline(seg, StapledonTheme.CREAM, 2.0 * z, true)
	var yr := yf(carrier_hz(), r)
	var teal := StapledonTheme.TEAL_LIGHT
	if receiver:
		draw_line(Vector2(r.position.x, yr), Vector2(r.end.x, yr), Color(teal, 0.9), 1.5 * z)
	else:
		draw_dashed_line(Vector2(r.position.x, yr), Vector2(r.end.x, yr), Color(teal, 0.7), 1.0 * z, 5.0 * z)
	var x := r.end.x - 10.0 * z
	var coral := StapledonTheme.CORAL
	var yt := yr
	var edge := ""
	if hearing == "above":
		yt = r.position.y + 2.0
		edge = str(w.above_hearing).trim_prefix(" · ")
	elif hearing == "below":
		yt = r.end.y - 2.0
		edge = str(w.below_hearing).trim_prefix(" · ")
	elif peak_hz > 0.0:
		yt = yf(clampf(peak_hz, F0, F1), r)
	if absf(yt - yr) > 3.0:
		draw_line(Vector2(x, yt), Vector2(x, yr), Color(coral, 0.9), 2.0 * z)
		draw_line(Vector2(x - 5.0 * z, yr), Vector2(x + 5.0 * z, yr), Color(teal, 0.95), 2.0 * z)
		var up := yt < yr
		var tip := Vector2(x, yt)
		draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(-5, 7 if up else -7) * z, tip + Vector2(5, 7 if up else -7) * z]), coral)
	if rate_tag != null:
		rate_tag.size = rate_tag.get_minimum_size()
		rate_tag.position = Vector2(x - rate_tag.size.x - 8.0 * z, (yt + yr) * 0.5 - rate_tag.size.y * 0.5)
	if not edge.is_empty():
		draw_string(font, Vector2(r.end.x - 150.0 * z, yt + (12.0 * z if hearing == "above" else -4.0 * z)), edge, HORIZONTAL_ALIGNMENT_RIGHT, int(136 * z), int(10 * z), Color(coral, 0.95))
