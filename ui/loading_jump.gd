class_name LoadingJump
extends CanvasLayer
## The lightspeed loading view (design_docs/planned/r1/lightspeed-loading.md).
##
## A title-screen route (Board the ship, Guided voyage, Galaxy map) runs behind
## this layer. The title's own sky (InteriorSky: the real starfield, panorama,
## aberration, Doppler colour and the starbow) is taken over and accelerated
## along the galactic centre with rapidity phi = p * atanh(BETA_MAX), where p is
## the REAL load progress; beta, gamma and 1 - beta come from the sunholo/relativity
## mirror (Relativity.beta_of_rapidity & co.). The speed is illustrative (no ship
## accelerates like this); the optics are the game's renderer, unchanged.
##
## Progress. A route's work is three phases, weighted by their measured time
## (tools/loading_profile.gd, Mac Studio M2 Ultra, 2026-10-08, see STAGES):
##   prefetch  worker threads, in parallel, while the animation runs: the map's
##             star colours (Blackbody integrals), the simulation (spawn + hello),
##             and, on the main thread one a frame, the captain's sprite textures. Each result is handed to the
##             main thread and the unchanged route code takes it instead of
##             loading it again (Blackbody.seed_cache, SimBridge.offer_warm,
##             CaptainAvatar.offer_texture). The title's sky also lends the ship's sky
##             its decoded panorama and its loaded star tiers (SkyBackground and
##             Starfield share a live identical load).
##   build     the route itself (main.gd), on the main thread: it blocks, so the
##             animation holds on its last frame for that long.
##   frames    the destination's first frames (shader compiles), drawn under this layer.
## `progress` is that real fraction and reaches 1.0 only once the destination is
## built and has drawn; `shown` (what the overlay and the optics use) follows it
## monotonically, never ahead of it, and reaches 1.0 only after it.
##
## At 100% (only) the white-out runs: the forward point blooms to fill the screen,
## then fades to the destination. The bloom is a TRANSITION EFFECT, not physics:
## the real sky at 0.99999c is a tiny blue-white point about 1/gamma rad across
## with darkness around it, and stays that way.

signal finished(route: String)

const BETA_MAX := 0.99999
const ROUTES := ["ship", "guided", "map"]
const FONT := "res://ui/splash/Montserrat-Bold.ttf"
const HEADING := Vector3(0, 0, -1) # toward the galactic centre (main.gd HEADING), the title camera's yaw 0
## Phases per route: [id, overlay label, kind, measured ms]. "thread" stages run in
## parallel during the prefetch (worker threads; "crew" is main-thread work, one sprite
## a frame), so that phase weighs as its longest stage; "build" and "frames" follow.
## Measured on the Mac Studio (M2 Ultra) at 1280x720 with tools/loading_profile.gd,
## 2026-10-08, with this prefetch in place (route runs, LOADING_ROUTE=...); re-measure
## when a route's loading changes. Before this view the routes took, press to ready,
## ship 7.9 s, guided 7.3 s, map 3.0 s, as one frozen frame each.
const STAGES := {
	"ship": [["colours", "Star colours for the navigation map", "thread", 160.0], ["sim", "Starting the simulation", "thread", 540.0],
		["crew", "The captain", "thread", 440.0],
		["build", "Assembling the ship", "build", 1360.0], ["frames", "First light aboard", "frames", 130.0]],
	"guided": [["colours", "Star colours for the navigation map", "thread", 175.0], ["sim", "Starting the simulation", "thread", 540.0],
		["crew", "The captain", "thread", 460.0],
		["build", "Assembling the ship and the tour", "build", 1330.0], ["frames", "First light aboard", "frames", 110.0]],
	"map": [["colours", "Star colours for the galaxy map", "thread", 140.0], ["sim", "Starting the simulation", "thread", 545.0],
		["build", "Building the galaxy map", "build", 40.0], ["frames", "First light", "frames", 80.0]],
}
const CREW_DIR := "res://assets/characters/captain" # demos/ship_geometry_demo.gd avatar.load_dir
const TITLES := {"ship": "Board the ship", "guided": "Guided voyage", "map": "Galaxy map"}
const FRAMES_AT_DESTINATION := 3
## shown chases progress at most this fast (fraction per second), so a blocking
## build's jump in progress becomes a short visible acceleration instead of a cut.
const CATCH_UP_RATE := 1.6
const TURN_UNTIL := 0.25 # the camera turns to face the direction of travel over the first quarter
const WHITE_IN_S := 0.45 # 100%: the forward point blooms to full white (transition effect)
const WHITE_HOLD_S := 0.12
const WHITE_OUT_S := 0.7 # then fades to the destination

var route := ""
var sky: InteriorSky = null
var progress := 0.0 # real, monotone; 1.0 exactly when the destination is ready
var shown := 0.0 # displayed, monotone, <= progress
var stage_label := ""
var arrived := false # the destination is built and has drawn FRAMES_AT_DESTINATION frames
var done := false
var frame_ms: Array[float] = [] # every frame's wall time from start() to the end of the white-out
var stage_ms := {} # measured wall time per stage id this run
var build_blocked_ms := 0.0
var started_usec := 0
var ready_ms := -1.0
var warm_pid := -1 # the prefetched simulation's child (tests: the route must run on it)
var enabled_prefetch := true # tests: false runs the stages without the worker-thread prefetch

var _build: Callable
var _tasks := {} # stage id -> WorkerThreadPool task id
var _results := {} # stage id -> worker result (written by the worker, read after completion)
var _thread_done := {}
var _groups := {} # stage ids run as group tasks
var _crew: Array[String] = [] # captain sprites still to build (main thread, one a frame)
var _phase := "idle" # prefetch, build, frames, catchup (ready; shown still rising), white, finished
var _phase_t0 := 0
var _frames_seen := 0
var _white_t := 0.0
var _last_usec := 0
var _turn_from := 0.0
var _pitch_from := 0.0
var _preview := false
var _optics_warm := false

var _sky_rect := TextureRect.new()
var _shade := TextureRect.new()
var _box := VBoxContainer.new()
var _kicker := Label.new()
var _beta_label := Label.new()
var _gamma_label := Label.new()
var _range_label := Label.new()
var _bar_back := ColorRect.new()
var _bar := ColorRect.new()
var _pct := Label.new()
var _stage := Label.new()
var _note := Label.new()
var _bloom := TextureRect.new()
var _white := ColorRect.new()


static func phi_max() -> float:
	return Relativity.rapidity_of_beta(BETA_MAX)


## The jump's speed at displayed progress p: [beta, gamma, 1 - beta], all from the mirror.
static func speed_at(p: float) -> Array:
	var phi := clampf(p, 0.0, 1.0) * phi_max()
	return [Relativity.beta_of_rapidity(phi), Relativity.gamma_of_rapidity(phi), Relativity.one_minus_beta_of_rapidity(phi)]


## "0.9955" style: the leading nines plus two digits, at most BETA_MAX's five places.
static func beta_text(b: float, omb: float) -> String:
	if omb >= 0.01:
		return "%.3f" % b
	var digits := clampi(int(floor(-log(omb) / log(10.0))) + 2, 3, 5)
	return ("%." + str(digits) + "f") % b


## 1 - beta for the overlay: "0.0446", then "1.0 × 10⁻⁵" style (GDScript has no %e).
static func omb_text(omb: float) -> String:
	if omb >= 0.001:
		return "%.4f" % omb
	var e := int(floor(log(omb) / log(10.0)))
	var m := omb / pow(10.0, e)
	if m >= 9.95:
		m /= 10.0
		e += 1
	var sup := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"}
	var ex := ""
	for ch in str(e):
		ex += sup[ch]
	return "%.1f × 10%s" % [m, ex]


func _init() -> void:
	layer = 100 # above the ship (<= 12) and main.gd's layers
	name = "LoadingJump"


## Take the title's sky (null: black behind the overlay) and start route `r`;
## `build` runs the route itself (main.gd) and may be a coroutine.
func start(r: String, title_sky: InteriorSky, build: Callable) -> void:
	route = r
	_build = build
	sky = title_sky
	_build_ui()
	if sky != null:
		sky.reparent(self)
		_sky_rect.texture = sky.get_texture()
		_turn_from = sky.camera.yaw
		_pitch_from = sky.camera.pitch
	started_usec = Time.get_ticks_usec()
	_last_usec = started_usec
	_phase_t0 = started_usec
	_phase = "prefetch"
	_warm_optics() # ~45 ms: the CMB lookup the moving sky needs, once per process
	Blackbody.wavelength_table() # built here, read by the colour workers
	for s in STAGES[route]:
		if s[2] == "thread":
			_start_task(s[0])
	_apply(0.0)


## Captures and previews: no route, the overlay and optics at displayed progress p
## (p > 1 runs the white-out at t = p - 1 seconds).
func preview(title_sky: InteriorSky, r: String, p: float) -> void:
	if route == "":
		route = r
		sky = title_sky
		_preview = true
		_build_ui()
		if sky != null:
			sky.reparent(self)
			_sky_rect.texture = sky.get_texture()
			_turn_from = sky.camera.yaw
			_pitch_from = sky.camera.pitch
		stage_label = STAGES[r][0][1]
		_warm_optics()
	shown = minf(p, 1.0)
	progress = shown
	if p >= 1.0:
		stage_label = "Arrived"
		_white_t = p - 1.0
		_apply_white(_white_t)
	else:
		var st: Array = STAGES[r]
		stage_label = st[clampi(int(p * st.size()), 0, st.size() - 1)][1]
	_apply(shown)


# ------------------------------------------------------------------ prefetch

func _start_task(id: String) -> void:
	if not enabled_prefetch:
		_thread_done[id] = true
		return
	var holder := {} # this task's own result dictionary: workers never share a container
	_results[id] = holder
	match id:
		"colours":
			var temps := catalogue_temperatures()
			var n := clampi(OS.get_processor_count() - 2, 2, 8)
			var chunks: Array = []
			for i in n:
				chunks.append({"temps": temps.slice(i * temps.size() / n, (i + 1) * temps.size() / n), "rows": {}})
			holder["chunks"] = chunks
			_tasks[id] = WorkerThreadPool.add_group_task(_work_xyz.bind(chunks), n, -1, false, "loading-jump " + id)
			_groups[id] = true
		"sim":
			_tasks[id] = WorkerThreadPool.add_task(_work_sim.bind(holder), false, "loading-jump sim")
		"crew": # main thread, one sprite a frame (they are GPU textures): see _poll_prefetch
			_crew = CaptainAvatar.sprite_paths(CREW_DIR)
		_:
			_thread_done[id] = true


## Every distinct point temperature of the navigation catalogue: GalaxyMap.load_catalogue
## asks Blackbody.xyz for each (~2.4 s of integrals on the main thread otherwise).
static func catalogue_temperatures(path := "res://data/starmap/stars.json") -> PackedFloat64Array:
	var seen := {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary and data.get("stars") is Array:
		for st: Dictionary in data["stars"]:
			seen[GalaxyMap.point_teff(st)] = true
	return PackedFloat64Array(seen.keys())


## Worker (one chunk of a group): Blackbody integrals into the chunk's own dictionary.
func _work_xyz(i: int, chunks: Array) -> void:
	var c: Dictionary = chunks[i]
	var rows: Dictionary = c["rows"]
	for t: float in c["temps"]:
		if t > 0.0:
			rows[t] = Blackbody.xyz_uncached(t)


## Worker: the simulation every title route starts (protocol 2.7), spawned and greeted.
func _work_sim(holder: Dictionary) -> void:
	holder["value"] = SimBridge.warm(SimBridge.STOPS_MINOR) # the ship's navigation session minor (D-58)


## Main thread: the CMB lookup (CmbGlow.lut) before the sky moves.
func _warm_optics() -> void:
	var t0 := Time.get_ticks_usec()
	CmbGlow.lut()
	_optics_warm = true
	stage_ms["optics"] = (Time.get_ticks_usec() - t0) / 1000.0


## Main thread: hand every finished worker result over; true when all are in.
func _poll_prefetch() -> bool:
	var all := true
	for s in STAGES[route]:
		if s[2] != "thread" or _thread_done.has(s[0]):
			continue
		var id: String = s[0]
		var finished_now := false
		if id == "crew":
			if not _crew.is_empty():
				CaptainAvatar.offer_texture(_crew.pop_front())
			finished_now = _crew.is_empty()
		elif _groups.has(id):
			if WorkerThreadPool.is_group_task_completed(_tasks[id]):
				WorkerThreadPool.wait_for_group_task_completion(_tasks[id])
				finished_now = true
		elif WorkerThreadPool.is_task_completed(_tasks[id]):
			WorkerThreadPool.wait_for_task_completion(_tasks[id])
			finished_now = true
		if finished_now:
			_hand_over(id)
		if finished_now:
			_thread_done[id] = true
			stage_ms[id] = (Time.get_ticks_usec() - started_usec) / 1000.0
		else:
			all = false
	return all


func _hand_over(id: String) -> void:
	var holder: Dictionary = _results.get(id, {})
	var r: Variant = holder.get("value")
	match id:
		"colours":
			for c: Dictionary in holder.get("chunks", []):
				Blackbody.seed_cache(c["rows"])
		"sim":
			if r != null:
				warm_pid = r.child_pid
				SimBridge.offer_warm(r)


# ------------------------------------------------------------------ progress

func _weights() -> Dictionary:
	var w := {"prefetch": 0.0, "build": 0.0, "frames": 0.0}
	for s in STAGES[route]:
		var k: String = "prefetch" if s[2] == "thread" else s[2]
		w[k] = maxf(w[k], s[3]) if k == "prefetch" else w[k] + s[3]
	return w


## The real fraction: finished phases and stages count exactly; a running prefetch
## stage is estimated as elapsed / its measured time (at most 95%) until it finishes.
func _real_progress() -> float:
	var w := _weights()
	var total: float = w["prefetch"] + w["build"] + w["frames"]
	var now_ms := (Time.get_ticks_usec() - _phase_t0) / 1000.0
	var p := 0.0
	match _phase:
		"prefetch":
			var sum := 0.0
			var got := 0.0
			for s in STAGES[route]:
				if s[2] != "thread":
					continue
				sum += s[3]
				got += s[3] if _thread_done.has(s[0]) else s[3] * minf(0.95, now_ms / s[3])
			p = w["prefetch"] * (got / sum if sum > 0.0 else 1.0)
		"build":
			p = w["prefetch"]
		"frames":
			p = w["prefetch"] + w["build"] + w["frames"] * minf(0.95, float(_frames_seen) / FRAMES_AT_DESTINATION)
		_:
			p = total
	return clampf(p / total, 0.0, 1.0) if not arrived else 1.0


func _stage_text() -> String:
	for s in STAGES[route]:
		if _phase == "prefetch" and s[2] == "thread" and not _thread_done.has(s[0]):
			return s[1]
		if _phase == s[2] and s[2] != "thread":
			return s[1]
	return "Arrived" if arrived else STAGES[route][-1][1]


func _process(_delta: float) -> void:
	if _preview or _phase == "idle" or _phase == "finished":
		return
	var now := Time.get_ticks_usec()
	frame_ms.append((now - _last_usec) / 1000.0)
	_last_usec = now
	var dt := minf(frame_ms[-1] / 1000.0, 0.1)
	match _phase:
		"prefetch":
			if _poll_prefetch():
				stage_ms["prefetch"] = (now - _phase_t0) / 1000.0
				_phase = "build"
				_phase_t0 = now
				stage_label = _stage_text()
				_apply(shown)
				_run_build.call_deferred() # after this frame is drawn, so the overlay names the build
		"frames":
			_frames_seen += 1
			if _frames_seen >= FRAMES_AT_DESTINATION:
				stage_ms["frames"] = (now - _phase_t0) / 1000.0
				arrived = true
				ready_ms = (now - started_usec) / 1000.0
				_phase = "catchup"
		"white":
			_white_t += dt
			_apply_white(_white_t)
			if _white_t >= WHITE_IN_S + WHITE_HOLD_S + WHITE_OUT_S:
				_finish()
				return
	progress = maxf(progress, _real_progress())
	shown = minf(progress, shown + CATCH_UP_RATE * dt)
	if arrived and progress >= 1.0 and shown >= 1.0 and _phase == "catchup":
		shown = 1.0
		_phase = "white"
		_white_t = 0.0
	stage_label = _stage_text()
	_apply(shown)


func _run_build() -> void:
	var t0 := Time.get_ticks_usec()
	await _build.call()
	build_blocked_ms = (Time.get_ticks_usec() - t0) / 1000.0
	stage_ms["build"] = build_blocked_ms
	CaptainAvatar.clear_offered() # sprites a route did not take
	SimBridge.discard_warm()
	_phase = "frames"
	_phase_t0 = Time.get_ticks_usec()
	_last_usec = _phase_t0 # the blocked build is reported on its own, not as a frame


func _finish() -> void:
	_phase = "finished"
	done = true
	var f := frame_ms.duplicate()
	f.sort()
	var n := f.size()
	print("loading-jump: %s ready after %.0f ms (build blocked %.0f ms); %d frames: median %.1f ms, p95 %.1f ms, max %.1f ms; stages %s" % [
		route, ready_ms, build_blocked_ms, n, f[n / 2] if n > 0 else 0.0, f[int(n * 0.95)] if n > 0 else 0.0, f[-1] if n > 0 else 0.0,
		JSON.stringify(stage_ms)])
	finished.emit(route)
	queue_free()


# ------------------------------------------------------------------ drawing

func _apply(p: float) -> void:
	var v := speed_at(p)
	var b: float = v[0]
	var g: float = v[1]
	var omb: float = v[2]
	if sky != null:
		var turn := smoothstep(0.0, TURN_UNTIL, p)
		var yaw_to := roundf(_turn_from / TAU) * TAU # yaw 0 (mod a turn): the velocity at the centre
		sky.camera.look(lerpf(_turn_from, yaw_to, turn), lerpf(_pitch_from, 0.0, turn), 0.0)
		sky.beta = b
		sky.gamma = g
		sky.starfield.set_velocity(HEADING, b, g)
		if sky.has_background:
			sky.background.set_velocity(HEADING, b, g)
	_beta_label.text = "β %sc" % beta_text(b, omb)
	_gamma_label.text = "γ %s   ·   1 − β %s" % [("%.1f" % g) if g < 1000.0 else ("%.0f" % g), omb_text(omb)]
	var pct := int(floor(p * 100.0 + 1e-9))
	_pct.text = "%d%%" % pct
	_bar.size.x = _bar_back.size.x * clampf(p, 0.0, 1.0)
	_stage.text = stage_label


## The white-out (transition effect, not physics): t seconds after 100%.
func _apply_white(t: float) -> void:
	var vp := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1280, 720)
	var centre := vp * 0.5
	var grow := clampf(t / WHITE_IN_S, 0.0, 1.0)
	var r := lerpf(18.0, vp.length() * 1.3, grow * grow * grow)
	_bloom.visible = true
	_bloom.size = Vector2(2.0 * r, 2.0 * r)
	_bloom.position = centre - Vector2(r, r)
	_white.visible = true
	var full := clampf((t - 0.55 * WHITE_IN_S) / (0.45 * WHITE_IN_S), 0.0, 1.0)
	var out := clampf((t - WHITE_IN_S - WHITE_HOLD_S) / WHITE_OUT_S, 0.0, 1.0)
	_white.color = Color(0.94, 0.97, 1.0, full * (1.0 - out))
	_bloom.modulate.a = 1.0 - out
	var behind := t < WHITE_IN_S + WHITE_HOLD_S # the jump stays behind the white until it fades to the destination
	_sky_rect.visible = behind
	_shade.visible = behind
	if _black_bg != null:
		_black_bg.visible = behind
	_box.modulate.a = clampf(1.0 - grow * 1.5, 0.0, 1.0)


func _label(l: Label, size: int, color: Color, font: Font = null) -> Label:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	if font != null:
		l.add_theme_font_override("font", font)
	return l


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP # the destination gets no input until it shows
	add_child(root)
	var black := ColorRect.new()
	black.color = Color.BLACK
	black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(black)
	_sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sky_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_sky_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_sky_rect)
	# bottom shade so the type reads over the sky (as the title's left shade)
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.72))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.45)
	gt.fill_to = Vector2(0, 1)
	_shade.texture = gt
	_shade.stretch_mode = TextureRect.STRETCH_SCALE
	_shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_shade)
	var font: Font = null
	var ff := FontFile.new()
	if ff.load_dynamic_font(FONT) == OK:
		var spaced := FontVariation.new()
		spaced.base_font = ff
		spaced.spacing_glyph = 2
		font = spaced
	_box.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_box.offset_left = 64
	_box.offset_right = -64
	_box.offset_top = -196
	_box.offset_bottom = -40
	_box.add_theme_constant_override("separation", 4)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_box)
	_label(_kicker, 13, Color(0.7, 0.78, 0.92))
	_kicker.text = "LOADING  ·  %s" % TITLES.get(route, route).to_upper()
	_box.add_child(_kicker)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_box.add_child(row)
	_label(_beta_label, 40, Color(0.95, 0.97, 1.0), font)
	row.add_child(_beta_label)
	var gcol := VBoxContainer.new()
	gcol.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(gcol)
	_label(_gamma_label, 15, Color(0.82, 0.87, 0.96))
	gcol.add_child(_gamma_label)
	_label(_range_label, 12, Color(0.6, 0.67, 0.8))
	_range_label.text = "β 0.000c → %sc" % beta_text(BETA_MAX, Relativity.one_minus_beta_of_rapidity(phi_max()))
	gcol.add_child(_range_label)
	var bar_row := HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", 14)
	_box.add_child(bar_row)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(0, 3)
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_row.add_child(holder)
	_bar_back.color = Color(0.55, 0.65, 0.85, 0.25)
	_bar_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(_bar_back)
	_bar.color = Color(0.86, 0.92, 1.0, 0.95)
	_bar.position = Vector2.ZERO
	_bar.size = Vector2(0, 3)
	holder.add_child(_bar)
	holder.resized.connect(func() -> void: _bar.size = Vector2(_bar_back.size.x * clampf(shown, 0.0, 1.0), 3))
	_label(_pct, 16, Color(0.95, 0.97, 1.0), font)
	_pct.custom_minimum_size = Vector2(56, 0)
	_pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	bar_row.add_child(_pct)
	_label(_stage, 13, Color(0.78, 0.83, 0.92))
	_box.add_child(_stage)
	_label(_note, 11, Color(0.58, 0.64, 0.76))
	_note.text = "Loading view: the speed is illustrative; the optics are the game's own renderer (aberration, Doppler colour, the starbow)."
	_box.add_child(_note)
	# the white-out (transition effect): a radial bloom from the forward point, then full white
	var rg := Gradient.new()
	rg.set_color(0, Color(1, 1, 1, 1))
	rg.set_color(1, Color(0.75, 0.86, 1.0, 0.0))
	rg.add_point(0.35, Color(0.92, 0.96, 1.0, 0.95))
	var rt := GradientTexture2D.new()
	rt.gradient = rg
	rt.fill = GradientTexture2D.FILL_RADIAL
	rt.fill_from = Vector2(0.5, 0.5)
	rt.fill_to = Vector2(1.0, 0.5)
	rt.width = 256
	rt.height = 256
	_bloom.texture = rt
	_bloom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bloom.stretch_mode = TextureRect.STRETCH_SCALE
	_bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bloom.visible = false
	root.add_child(_bloom)
	_white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_white.color = Color(1, 1, 1, 0)
	_white.visible = false
	root.add_child(_white)
	_black_bg = black


var _black_bg: ColorRect


## Freed early (quit during the prefetch): reap the workers, stop an unused warm sim.
func _exit_tree() -> void:
	for id in _tasks:
		if _groups.has(id):
			WorkerThreadPool.wait_for_group_task_completion(_tasks[id])
		elif not _thread_done.has(id):
			WorkerThreadPool.wait_for_task_completion(_tasks[id])
	_tasks.clear()
	if not done:
		var holder: Dictionary = _results.get("sim", {})
		if holder.get("value") != null and not _thread_done.has("sim"):
			holder["value"].stop()
		SimBridge.discard_warm()
		CaptainAvatar.clear_offered()
