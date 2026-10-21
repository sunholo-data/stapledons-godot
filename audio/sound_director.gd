class_name SoundDirector
extends Node
## R2-SOUND §D1 (design_docs/planned/r2/sound.md): plays the cue table's sounds for game events.
##
## It listens and never speaks: sim events arrive through on_sim_step (wired to SimBridge.stepped),
## interface signals through on_ui, the captain's walk through walked, game states through on_game.
## Nothing is sent to the sim (CLAUDE.md gate 4).
##
## The clocks (§D1): every cue is keyed and rate-limited in its trigger's own clock, never frames or
## wall time, so the cue log is byte-identical for the same input on any machine and frame rate:
##   sim cues      "t<tick>.<event index>", cooldown in sim ticks;
##   UI cues       "u<input sequence>", cooldown in inputs;
##   footsteps     "w<step index>", one step per whole STEP_MM of an integer millimetre accumulator;
##   game states   "g<game sequence>".
## Variant and pitch come from a hash of (cue id, the cue's fire count), not an RNG (§D1).

const LOG_MAX := 4096
## R2-SOUND rework (D-108): the spire's degradation layer follows the Archive's Memory Health.
## Memory Health is designed (stapledons-design features/next/archive-voice.md §5, archive-system.md:
## 0..100, hidden, deterministic in the sim) but the sim does not emit it yet (Archive phase 2). When
## it does, at this path, the director maps it to archive_degradation = 1 − health/100. Until then the
## parameter stays 0 (pristine) and the layer is silent: nothing here invents a value.
const ARCHIVE_HEALTH_PATH := "archive.memory_health"
const STEP_MM := 700
const PLAYERS_2D := 12

var cues := {} ## id -> row
var assets := {} ## id -> manifest row
var errors: Array[String] = []
var cue_log := PackedStringArray()
## Off in tests that only read the log; on in the game and in the loudness and review tools.
var audible := true

var _streams := {} ## asset id -> AudioStreamWAV
var _fires := {} ## cue id -> count
var _last := {} ## cue id -> the clock value of its last fire
var _input_seq := 0
var _game_seq := 0
var _walk_mm := 0
var _steps := 0
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _loops := {} ## cue id -> its own player
var _state := {} ## sim_state cue id -> last value seen
var params := {} ## parameter name -> 0..1 (archive_degradation)
var _param_seq := 0


## Loads and validates the tables; returns the errors (also kept in `errors`). With errors the
## director stays silent but keeps logging nothing, so a bad table is loud in tests, quiet in play.
func setup(cues_path := SoundData.CUES_PATH, assets_path := SoundData.ASSETS_PATH, root := "res://") -> Array[String]:
	errors.clear()
	var m := SoundData.load_assets(assets_path)
	errors.append_array(m.errors)
	errors.append_array(SoundData.check_rows(m))
	assets = m.assets
	var table: Variant = SoundData.read_json(cues_path)
	errors.append_array(SoundData.check_cues(table, assets, root))
	cues.clear()
	if errors.is_empty():
		for c: Dictionary in table.cues:
			cues[c.id] = c
	SoundMix.ensure_layout()
	return errors


## SimBridge.stepped: the accepted tick's events, in order.
func on_sim_step(tick: int, events: Array) -> void:
	for idx in events.size():
		var e: Variant = events[idx]
		if not e is Dictionary:
			continue
		for id: String in cues:
			var t: Dictionary = cues[id].trigger
			if t.kind == "sim_event" and t.k == e.get("k", "") and _matches(t.get("match", {}), e):
				if _cooled(id, tick):
					fire(id, "t%d.%d" % [tick, idx], tick)


## A sim state edge (§D1): the cue fires when the value at its path changes to its `equals` (or to
## anything, without `equals`). Paths are dotted into the mirrored world, e.g. "ship.ism.medium".
func on_sim_world(tick: int, world: Dictionary) -> void:
	var h: Variant = _at(world, ARCHIVE_HEALTH_PATH)
	if h is float or h is int:
		set_param("archive_degradation", 1.0 - clampf(float(h), 0.0, 100.0) / 100.0)
	for id: String in cues:
		var t: Dictionary = cues[id].trigger
		if t.kind != "sim_state":
			continue
		var v: Variant = _at(world, str(t.path))
		var had := _state.has(id)
		var before: Variant = _state.get(id)
		_state[id] = v
		if had and v != before and v != null and (not t.has("equals") or v == t.equals):
			fire(id, "t%d.s" % tick, tick)


## An interface signal by name (consoles, the map, the HUD): one input in the UI clock.
func on_ui(signal_name: String) -> void:
	_input_seq += 1
	for id: String in cues:
		var t: Dictionary = cues[id].trigger
		if t.kind == "ui_signal" and t.name == signal_name and _cooled(id, _input_seq):
			fire(id, "u%d" % _input_seq, _input_seq)


## A game state by name ("level_bridge" starts the bridge's loops, "level_none" stops them, ...).
func on_game(state_name: String) -> void:
	_game_seq += 1
	for id: String in cues:
		var t: Dictionary = cues[id].trigger
		if t.kind == "game" and t.name == state_name:
			fire(id, "g%d" % _game_seq, _game_seq)
		elif t.kind == "game" and t.get("stop_on", "") == state_name:
			stop(id)


## The captain walked this many metres this frame. Integer millimetres, so 6,990 mm gives 9 steps
## and 7,000 mm gives 10 whatever the frame split (§D1).
## A continuous parameter (0..1). Cues with a matching `param` follow it: their volume moves along
## the row's points (value -> dB offset, linear between points). Logged when it moves by 0.01 or more.
func set_param(param_name: String, value: float) -> void:
	var v := clampf(value, 0.0, 1.0)
	if absf(v - float(params.get(param_name, 0.0))) < 0.01 and params.has(param_name):
		return
	params[param_name] = v
	_param_seq += 1
	cue_log.append("p%d %s %.2f" % [_param_seq, param_name, v])
	for id: String in _loops:
		var c: Dictionary = cues.get(id, {})
		if c.get("param", {}).get("name", "") == param_name:
			(_loops[id] as AudioStreamPlayer).volume_db = float(c.get("volume_db", 0.0)) + param_offset(c)


## The dB offset a row's param curve gives at the parameter's current value (0 without a param).
func param_offset(c: Dictionary) -> float:
	var pc: Variant = c.get("param", null)
	if not pc is Dictionary:
		return 0.0
	return curve_db(pc.points, float(params.get(pc.name, 0.0)))


static func curve_db(points: Array, x: float) -> float:
	if points.is_empty():
		return 0.0
	if x <= float(points[0][0]):
		return float(points[0][1])
	for i in range(1, points.size()):
		var a: Array = points[i - 1]
		var b: Array = points[i]
		if x <= float(b[0]):
			return lerpf(float(a[1]), float(b[1]), (x - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-9))
	return float(points.back()[1])


func walked(metres: float) -> void:
	add_walk_mm(roundi(maxf(0.0, metres) * 1000.0))


func add_walk_mm(mm: int) -> void:
	_walk_mm += maxi(0, mm)
	while (_steps + 1) * STEP_MM <= _walk_mm:
		_steps += 1
		for id: String in cues:
			var t: Dictionary = cues[id].trigger
			if t.kind == "game" and t.name == "step":
				fire(id, "w%d" % _steps, _steps)


func steps() -> int:
	return _steps


## Fires one cue: picks its variant and pitch from (id, fire count), logs it, and plays it when audible.
func fire(id: String, key: String, clock: int) -> void:
	if not cues.has(id):
		return
	var c: Dictionary = cues[id]
	var n: int = _fires.get(id, 0)
	_fires[id] = n + 1
	_last[id] = clock
	var h := ("%s#%d" % [id, n]).hash() & 0x7fffffff
	var streams: Array = c.streams
	var variant := h % streams.size()
	var spread := int(c.get("pitch_cents_spread", 0))
	var cents := 0 if spread <= 0 else (h / 7) % (2 * spread + 1) - spread
	var vol := float(c.get("volume_db", 0.0)) + param_offset(c)
	cue_log.append("%s %s v%d %+dc %.1fdB" % [key, id, variant, cents, vol])
	if cue_log.size() > LOG_MAX:
		cue_log.remove_at(0)
	if audible:
		_play(c, str(streams[variant]), pow(2.0, cents / 1200.0), vol)


func stop(id: String) -> void:
	if _loops.has(id):
		(_loops[id] as AudioStreamPlayer).stop()


func log_text() -> String:
	return "\n".join(cue_log) + ("\n" if cue_log.size() > 0 else "")


## The loaded stream of an asset (cached), with its manifest loop points applied.
func stream(asset_id: String, root := "res://") -> AudioStreamWAV:
	if _streams.has(asset_id):
		return _streams[asset_id]
	var r: Dictionary = assets.get(asset_id, {})
	var s := AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes(source_path(str(r.get("path", "")), root)))
	if s != null and r.get("loop", null) is Dictionary:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = int(r.loop.begin)
		s.loop_end = int(r.loop.end)
	_streams[asset_id] = s
	return s


## assets/audio is .gdignore'd (the repo's convention: assets are read as files, not imported), so
## the export carries the WAVs staged as audio_bundle/<kind>/<file>.bin (make sound-stage).
static func source_path(rel: String, root := "res://") -> String:
	var p := root.path_join(rel)
	if FileAccess.file_exists(p) or not rel.begins_with("assets/audio/"):
		return p
	return "res://audio_bundle/" + rel.trim_prefix("assets/audio/") + ".bin"


func _play(c: Dictionary, asset_id: String, pitch: float, vol: float) -> void:
	var s := stream(asset_id)
	if s == null or not is_inside_tree():
		return
	var p: AudioStreamPlayer
	if c.get("loop", false):
		if not _loops.has(c.id):
			p = AudioStreamPlayer.new()
			p.name = "Loop_" + str(c.id)
			add_child(p)
			_loops[c.id] = p
		p = _loops[c.id]
		if p.playing:
			return
	else:
		while _pool.size() < PLAYERS_2D:
			var q := AudioStreamPlayer.new()
			add_child(q)
			_pool.append(q)
		p = _pool[_next]
		_next = (_next + 1) % PLAYERS_2D
	p.bus = StringName(c.bus)
	p.stream = s
	p.pitch_scale = pitch
	p.volume_db = vol
	p.play()


func _cooled(id: String, clock: int) -> bool:
	var cd := int(cues[id].get("cooldown", 0))
	return cd <= 0 or not _last.has(id) or clock - int(_last[id]) >= cd


static func _matches(want: Variant, e: Dictionary) -> bool:
	if not want is Dictionary:
		return true
	for k: String in want:
		if e.get(k) != want[k]:
			return false
	return true


static func _at(d: Dictionary, path: String) -> Variant:
	var v: Variant = d
	for part in path.split("."):
		if not v is Dictionary or not v.has(part):
			return null
		v = v[part]
	return v
