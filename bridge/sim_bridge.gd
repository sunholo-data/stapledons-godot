class_name SimBridge
extends RefCounted
## Runs the AILANG simulation as a child process and talks protocol v2 NDJSON
## over its stdin/stdout (design m2-journey-core §M2.1): `hello`, then
## `new_game`, then one `input` line in and one `state` line out per tick.
## The world state lives in AILANG; Godot sends intents and mirrors the state
## by applying each reply's change-set to `world`.

const SIM_FILE := "sim/ship.ail"
const PROTO_MAJOR := 2
## 2.1 (AI.3): the sim's `ai` section and AI events; AiRelay reads them (AI.7).
const PROTO_MINOR := 1
## 2.3 (M5.1b): the `system` section (the star, planets and moons as seen from
## the ship). Asked for by setting `want_minor = SYSTEM_MINOR` before hello().
const SYSTEM_MINOR := 3
## 2.4 (M5.5a): body targets. Plans to a planet or moon (body_plan()); a body
## plan's journey.plan carries target_kind, intercept and pass or hold
## (parse_plan_nav()). Asked for by setting `want_minor = NAV_MINOR`.
const NAV_MINOR := 4
## 2.5: exact recorded journey departure for map route framing.
const DEPARTURE_MINOR := 5
## 2.6 (M3.4b): the black-hole mode. new_game(seed, "sgr_a", diag, {"bh_mass_msun": m,
## "bh_r": r}) (both optional: Sgr A*, 10^6 r_s); the intents gr_approach(),
## {"k": "gr_hover"}, {"k": "gr_orbit"} and {"k": "gr_ring"} (the first ring star);
## the `gr` section (parse_gr(), kept in `gr`) and `archive` events. Asked for by
## setting `want_minor = GR_MINOR`.
const GR_MINOR := 6
## 2.7 (D-54/D-58): a star plan may carry its catalogue row {"star": {name, v, teff}}; the
## system section adds inferred finite stars and each Sol body's sync_orbit.
const STOPS_MINOR := 7
## Protocol 2.8 (R1-ISM-DUST): new games fly the measured interstellar medium (lism-1): ship.ism
## names the medium and carries the dust impacts; journey.plan the media crossed and the hold limit.
const ISM_MINOR := 8

var _pipe: FileAccess
var _stderr: FileAccess
var _record: FileAccess
var _pid := -1
var _game := false
## Mirrored world: `tick`, `status` and every section the sim has sent
## (`clock`, `ship`, `params`, ...). A change-set replaces whole sections and
## leaves the others alone.
var world: Dictionary = {}
## The last message read from the sim, as parsed, and its raw text.
var state: Dictionary = {}
var last_line := ""
## The sim's hello reply (proto, sim, relativity, rng).
var hello_reply: Dictionary = {}
## `refused` and `events` of the last accepted input.
var last_refused: Array = []
var last_events: Array = []
var last_error := ""
## The seed of the running world (set by a new_game the sim accepted); -1 before any.
var last_seed := -1
var child_pid := -1
var launch_override: Dictionary = {}
## When set before start(), every line written to the sim's stdin is also
## appended here byte for byte: an NDJSON input log that replays the session.
var record_path := ""
## Optional AiRelay (AI.7): unset, nothing changes. Set, its queued intents
## (`take_intents()`) ride on every send after the caller's, and it is shown
## every accepted tick's events (`on_events`). Intents of a line the sim does
## not accept are dropped; their requests expire in the sim (ai_ttl_ticks).
var ai_relay: Object = null
## The protocol minor hello() asks for (PROTO_MINOR unless a caller opts in, before
## start()): the interior (M4.2) asks for 2 (ship.ism, consequence), the system view
## SYSTEM_MINOR. Everything else keeps 2.1, so the recorded replay goldens are unchanged.
var want_minor := PROTO_MINOR
## The codex table `archive: [{id, unlock}]` new_game carries (protocol 2.2, M4.7: LoreLoader.archive_rows()).
## Empty = the field is left out, so every existing session and its replay log are unchanged.
var archive_rows: Array = []
## The last `system` section, as parsed by parse_system(); {} until one arrives.
var system: Dictionary = {}
## The body planner's fields of the current plan, as parsed by parse_plan_nav();
## {} for a star plan or no plan.
var plan_nav: Dictionary = {}
## The last `gr` section, as parsed by parse_gr(); {} outside a black-hole scenario.
var gr: Dictionary = {}
var _line_bytes := PackedByteArray()
## R1-SHIP-UI record seam (record only; nothing sent changes): with record_sent on, every
## send() appends {tick, source, intents} to sent_log. `source` says who originated the
## line: "player" (a captain's console choice), "tour" (the guided itinerary's own legs,
## SolarDeparture) or "tick" (no intents, or client observations such as gr_ring). A caller
## sets intent_source just before send(); it is one-shot. Unset, a line with intents is
## "player" and an empty one is "tick". tests/test_no_twitch.gd reads it (NT1).
var record_sent := false
var sent_log: Array = []
var intent_source := ""


static func find_ailang() -> String:
	var env := OS.get_environment("AILANG_BIN")
	if env != "":
		return env
	for dir in OS.get_environment("PATH").split(":"):
		var p := dir.path_join("ailang")
		if FileAccess.file_exists(p):
			return p
	return ""


## Launch the sim and complete the handshake. The sim prints nothing before
## its hello reply.
func start() -> bool:
	if _adopt_warm():
		return true
	var launch := launch_override if not launch_override.is_empty() else _launch_plan()
	if launch.is_empty():
		return false
	var started := Time.get_ticks_msec()
	# Through the descriptor scrub (as AiBridge): execute_with_pipe sets no
	# close-on-exec, so the sim would otherwise inherit every pipe Godot holds.
	var proc := OS.execute_with_pipe(AiBridge.scrub_shell(), AiBridge.scrubbed(launch), false)
	if proc.is_empty():
		push_error("failed to start %s" % launch["bin"])
		return false
	_pipe = proc["stdio"]
	_stderr = proc["stderr"]
	_pid = proc["pid"]
	child_pid = _pid
	if record_path != "":
		_record = FileAccess.open(record_path, FileAccess.WRITE)
		if _record == null:
			push_error("cannot record to %s" % record_path)
	return hello(started + bootstrap_budget_ms(OS.has_feature("template"), not launch_override.is_empty()))


## The loading jump (ui/loading_jump.gd) starts the sim a title route will ask for on a
## worker thread: warm() spawns it and completes the same hello handshake there; the
## main thread then offer_warm()s it, and the next default start() (no launch_override,
## no record_path, the same want_minor) takes it over instead of spawning. Unused, it is
## stopped by discard_warm(). Every other start() is unchanged.
static var _warm: SimBridge = null
var _warming := false


## Worker thread: a started bridge, or null (the reason is pushed as an error).
static func warm(minor: int) -> SimBridge:
	var b := SimBridge.new()
	b.want_minor = minor
	b._warming = true # never adopts (it must not read _warm off the main thread)
	return b if b.start() else null


## Main thread only.
static func offer_warm(b: SimBridge) -> void:
	discard_warm()
	_warm = b


static func discard_warm() -> void:
	if _warm != null:
		_warm.stop()
	_warm = null


static func has_warm() -> bool:
	return _warm != null


func _adopt_warm() -> bool:
	if _warming:
		return false
	var w := _warm
	if w == null or not launch_override.is_empty() or record_path != "" or w.want_minor != want_minor:
		return false
	_warm = null
	if w._pid < 0 or not OS.is_process_running(w._pid):
		w.stop()
		return false
	_pipe = w._pipe
	_stderr = w._stderr
	_pid = w._pid
	child_pid = w.child_pid
	hello_reply = w.hello_reply
	state = w.state
	last_line = w.last_line
	_line_bytes = w._line_bytes
	w._pid = -1 # the child is this bridge's now
	w._pipe = null
	w._stderr = null
	return true


## Normal source has no compiled cache on first launch. A measured cold compile
## exceeded 9 s; allow 30 s for normal source/exported bootstrap. Explicit fixture
## launches retain 5 s; new_game/input deadlines and child cleanup are unchanged.
static func bootstrap_budget_ms(exported: bool, overridden: bool) -> int:
	return 5000 if overridden else 30000


## Send `hello` and accept only an integer protocol major of 2.
func hello(deadline: int = Time.get_ticks_msec() + 5000) -> bool:
	if _pid < 0:
		return false
	_write(encode({"v": 2, "type": "hello", "want": {"major": PROTO_MAJOR, "minor": want_minor}}))
	if not _read_state(deadline, "startup_timeout"):
		return false
	var proto = state.get("proto")
	if state.get("type") != "hello" or typeof(proto) != TYPE_DICTIONARY \
			or not _is_count(proto.get("major")) or not _is_count(proto.get("minor")) or proto["major"] != PROTO_MAJOR:
		return _fail("bad_proto")
	hello_reply = state.duplicate(true)
	return true


## Start a world. Returns false (child kept, `last_error` = the sim's reason)
## if the sim refuses the request.
func new_game(seed: int, scenario: String = "sol", diag: bool = false, params: Dictionary = {}, ai_core: String = "") -> bool:
	if _pid < 0 or hello_reply.is_empty():
		last_error = "no_hello"
		return false
	var msg := {"v": 2, "type": "new_game", "seed": seed, "scenario": scenario, "diag": diag}
	if not params.is_empty():
		msg["params"] = params
	if ai_core != "":
		msg["ai_core"] = ai_core
	if not archive_rows.is_empty():
		msg["archive"] = archive_rows
	_write(encode(msg))
	if not _read_state(Time.get_ticks_msec() + 2000, "step_timeout"):
		return false
	if state.get("type") != "state":
		return _fail("bad_response")
	if state.get("status") != "ok":
		last_error = state.get("status", "bad_response")
		return false
	if state.get("full") != true or state.get("tick") != 0 or typeof(state.get("changes")) != TYPE_DICTIONARY:
		return _fail("bad_response")
	system = {}
	plan_nav = {}
	gr = {}
	if not _take_system(state["changes"]) or not _take_gr(state["changes"]):
		return _fail("bad_response")
	world = state["changes"].duplicate(true)
	world["tick"] = 0
	world["status"] = "ok"
	_game = true
	last_seed = seed
	return true


## One tick: `intents` (dictionaries tagged by "k") over `dtau` ship-years.
## True when the sim accepted the line and the tick advanced; refused intents
## are then in `last_refused`. A malformed line leaves `world` unchanged and
## returns false with the sim's reason in `last_error`; the child keeps
## running. Nothing is sent before new_game has been answered.
func send(intents: Array, dtau: float) -> bool:
	if _pid < 0:
		return false
	if not _game:
		last_error = "no_game"
		return false
	var tick := int(world["tick"]) + 1
	if ai_relay != null:
		intents = intents + ai_relay.take_intents()
	var source := intent_source if not intent_source.is_empty() else ("tick" if intents.is_empty() else "player")
	intent_source = ""
	if record_sent:
		sent_log.append({"tick": tick, "source": source, "intents": intents.duplicate(true)})
	_write(encode({"v": 2, "type": "input", "tick": tick, "dtau": dtau, "intents": intents}))
	if not _read_state(Time.get_ticks_msec() + 2000, "step_timeout"):
		return false
	if state.get("type") != "state" or typeof(state.get("changes")) != TYPE_DICTIONARY:
		return _fail("bad_response")
	if state.get("status") != "ok":
		last_error = state.get("status", "bad_response")
		return false
	if state.get("tick") != tick:
		return _fail("bad_response")
	var changes: Dictionary = state["changes"]
	if not _take_system(changes) or not _take_plan_nav(changes) or not _take_gr(changes):
		return _fail("bad_response")
	for section in changes:
		world[section] = changes[section].duplicate(true) if changes[section] is Dictionary else changes[section]
	world["tick"] = tick
	world["status"] = "ok"
	last_refused = state.get("refused", [])
	last_events = state.get("events", [])
	if ai_relay != null:
		ai_relay.on_events(last_events)
	return true


func stop() -> void:
	if _pid < 0:
		return
	_cleanup()


## JSON text for a request. Floats use Godot's shortest round-trip digits
## (`full_precision`), except -0.0, which Godot prints as "0.0" and std/json
## needs as "-0.0" (ailang#1460). Ints stay integers. Keys keep their order.
static func encode(v: Variant) -> String:
	match typeof(v):
		TYPE_DICTIONARY:
			var parts := PackedStringArray()
			for k in v:
				parts.append(JSON.stringify(str(k)) + ":" + encode(v[k]))
			return "{" + ",".join(parts) + "}"
		TYPE_ARRAY:
			var items := PackedStringArray()
			for x in v:
				items.append(encode(x))
			return "[" + ",".join(items) + "]"
		TYPE_FLOAT:
			return number(v)
		TYPE_INT:
			return str(v)
	return JSON.stringify(v)


static func number(x: float) -> String:
	if x == 0.0:
		var b := PackedByteArray()
		b.resize(8)
		b.encode_double(0, x)
		return "-0.0" if b[7] & 0x80 else "0.0"
	return JSON.stringify(x, "", true, true)


static func _is_count(v: Variant) -> bool:
	return (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floorf(v) and v >= 0.0) or (typeof(v) == TYPE_INT and v >= 0)


func _write(line: String) -> void:
	_pipe.store_line(line)
	_pipe.flush()
	if _record != null:
		_record.store_string(line + "\n")
		_record.flush()


static func _run_args(ailang: String, sim_dir: String) -> PackedStringArray:
	# --package-dir holds ailang.toml, so module paths resolve from any cwd.
	return PackedStringArray([ailang, "run", "--quiet", "--bytecode", "--package-dir", sim_dir,
		"--caps", "IO", "--entry", "main", sim_dir.path_join(SIM_FILE.get_file())])


## Editor / source checkout: ailang from AILANG_BIN or PATH, sim from the repo.
## Exported build: the bundled runtime (pinned ailang + package cache + sim),
## unpacked once per version into user://, run with its own HOME because
## ailang's package cache is fixed at $HOME/.ailang/cache/registry.
func _launch_plan() -> Dictionary:
	if not OS.has_feature("template"):
		var bin := find_ailang()
		if bin == "":
			push_error("ailang not found; set AILANG_BIN or add it to PATH")
			return {}
		var dev_args := _run_args(bin, ProjectSettings.globalize_path("res://" + SIM_FILE.get_base_dir()))
		return {"bin": dev_args[0], "args": dev_args.slice(1)}
	var root := _unpack_runtime()
	if root == "":
		return {}
	var args := PackedStringArray(["HOME=" + root.path_join("home")])
	args.append_array(_run_args(root.path_join("runtime/bin/ailang"), root.path_join("sim")))
	return {"bin": "/usr/bin/env", "args": args}


## Runtime cache identity includes simulation source and dependency pins. A new
## app revision must not execute a previous build's sim just because AILANG has
## the same version. Existing caches are retained for older builds.
static func runtime_fingerprint(version:String, inputs:Dictionary)->String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256)
	hash.update(version.to_utf8_buffer())
	var names:=inputs.keys();names.sort()
	for name in names:
		hash.update(str(name).to_utf8_buffer());hash.update(PackedByteArray([0]))
		hash.update(inputs[name]);hash.update(PackedByteArray([0]))
	return version+"-"+hash.finish().hex_encode()

## Stable relative paths include nested data modules imported by the sim.
static func runtime_inputs(directory:String, prefix:="")->Dictionary:
	var inputs:Dictionary={}
	var source:=DirAccess.open(directory)
	if source==null:return inputs
	for name in source.get_files():
		if name.ends_with(".ail") or name in ["ailang.toml","ailang.lock"]:
			inputs[prefix+name]=FileAccess.get_file_as_bytes(directory.path_join(name))
	for name in source.get_directories():
		if not name.begins_with("."):
			inputs.merge(runtime_inputs(directory.path_join(name),prefix+name+"/"))
	return inputs

static func _unpack_runtime() -> String:
	var version := FileAccess.get_file_as_string("res://runtime/VERSION").strip_edges()
	if version == "":
		push_error("exported build has no bundled runtime (res://runtime/VERSION missing)")
		return ""
	var inputs:=runtime_inputs("res://sim")
	if inputs.is_empty():return ""
	var root := ProjectSettings.globalize_path("user://runtime-%s" % runtime_fingerprint(version,inputs))
	var marker := root.path_join(".unpacked")
	if not FileAccess.file_exists(marker):
		for pair in [["res://runtime", root.path_join("runtime")], ["res://sim", root.path_join("sim")],
				["res://runtime/cache", root.path_join("home/.ailang/cache")]]:
			if not _copy_tree(pair[0], pair[1]):
				push_error("failed to unpack %s" % pair[0])
				return ""
		OS.execute("/bin/chmod", ["+x", root.path_join("runtime/bin/ailang")])
		FileAccess.open(marker, FileAccess.WRITE).store_string(version)
	return root


static func _copy_tree(src: String, dst: String) -> bool:
	DirAccess.make_dir_recursive_absolute(dst)
	var dir := DirAccess.open(src)
	if dir == null:
		return false
	for f in dir.get_files():
		var out := FileAccess.open(dst.path_join(f), FileAccess.WRITE)
		if out == null:
			return false
		out.store_buffer(FileAccess.get_file_as_bytes(src.path_join(f)))
	for d in dir.get_directories():
		if not _copy_tree(src.path_join(d), dst.path_join(d)):
			return false
	return true


func _read_state(deadline: int, timeout_code: String) -> bool:
	while Time.get_ticks_msec() < deadline:
		var end := _line_bytes.find(10)
		if end < 0:
			var chunk := _pipe.get_buffer(4096)
			if chunk.is_empty():
				if not OS.is_process_running(_pid):
					return _fail("child_eof")
				OS.delay_msec(2)
				continue
			_line_bytes.append_array(chunk)
			continue
		var line := _line_bytes.slice(0, end).get_string_from_utf8().strip_edges()
		_line_bytes = _line_bytes.slice(end + 1)
		if not line.begins_with("{"):
			continue
		var parsed = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			return _fail("bad_response")
		state = parsed
		last_line = line
		return true
	return _fail(timeout_code)

# ------------------------------------------------------------ 2.3 system (M5.1b)
# Parse-only: the sim computed every number; this checks the shape and keeps it.
# sun_dir is a unit vector for planets and moons and the zero vector for the
# star (kind "star"): never normalise a star's sun_dir.
const _BODY_STRINGS := ["id", "name", "kind", "host", "status", "ring_id", "source"]
const _BODY_NUMBERS := ["radius_km", "flattening", "w_deg", "r_au", "phase_deg", "e_v_lux", "p_v", "minnaert_k", "light_age_s"]
const _BODY_VECTORS := ["rel_km", "pole", "sun_dir"]

## A `system` section checked field by field: `{}` if anything is missing or mistyped.
static func parse_system(v: Variant) -> Dictionary:
	if typeof(v) != TYPE_DICTIONARY or typeof(v.get("jd")) != TYPE_FLOAT or v.get("frame") != "galactic" \
			or not v.get("ephemeris") in ["jpl-approx", "mean-orbit"] or typeof(v.get("bodies")) != TYPE_ARRAY:
		return {}
	for b in v["bodies"]:
		if typeof(b) != TYPE_DICTIONARY or typeof(b.get("visitable")) != TYPE_BOOL:
			return {}
		for k in _BODY_STRINGS:
			if typeof(b.get(k)) != TYPE_STRING:
				return {}
		for k in _BODY_NUMBERS:
			if typeof(b.get(k)) != TYPE_FLOAT:
				return {}
		for k in _BODY_VECTORS:
			var x = b.get(k)
			if typeof(x) != TYPE_DICTIONARY or typeof(x.get("x")) != TYPE_FLOAT or typeof(x.get("y")) != TYPE_FLOAT or typeof(x.get("z")) != TYPE_FLOAT:
				return {}
	return v.duplicate(true)

func _take_system(changes: Dictionary) -> bool:
	if not changes.has("system"):
		return true
	var parsed := parse_system(changes["system"])
	if parsed.is_empty():
		return false
	system = parsed
	return true

# ------------------------------------------------------------ 2.4 body plans (M5.5a)
## The plan intent's body form. The sim computes the target from the id (any
## pos is ignored). approach: {} (a stop at the default stand-off),
## {"mode": "stop", "standoff_km": km} or {"mode": "flyby", "b_km": km,
## "clock_deg": deg, "run_out_km": km} (run_out_km optional).
static func body_plan(id: String, cruise_phi: float, approach: Dictionary = {}) -> Dictionary:
	var m := {"k": "plan", "target": {"kind": "body", "id": id}, "cruise_phi": cruise_phi}
	if not approach.is_empty():
		m["approach"] = approach
	return m

static func _is_vec(x: Variant) -> bool:
	return typeof(x) == TYPE_DICTIONARY and typeof(x.get("x")) == TYPE_FLOAT and typeof(x.get("y")) == TYPE_FLOAT and typeof(x.get("z")) == TYPE_FLOAT

static func _floats(d: Variant, keys: Array) -> bool:
	if typeof(d) != TYPE_DICTIONARY:
		return false
	for k in keys:
		if typeof(d.get(k)) != TYPE_FLOAT:
			return false
	return true

## A journey.plan's body fields checked: {target_kind, intercept{t, pos}, pass{t,
## b_km, beta, d_at_pass} | hold{body, offset_km}}; {} for a star plan or a bad shape
## (`ok` false then).
static func parse_plan_nav(plan: Variant) -> Dictionary:
	if typeof(plan) != TYPE_DICTIONARY or not plan.has("target_kind"):
		return {}
	var it = plan.get("intercept")
	if plan["target_kind"] != "body" or not _floats(it, ["t"]) or not _is_vec(it.get("pos")):
		return {"ok": false}
	var nav := {"ok": true, "target_kind": "body", "intercept": it.duplicate(true)}
	if plan.has("pass"):
		if not _floats(plan["pass"], ["t", "b_km", "beta", "d_at_pass"]):
			return {"ok": false}
		nav["pass"] = plan["pass"].duplicate(true)
	elif plan.has("hold"):
		var h = plan["hold"]
		if not _floats(h, ["offset_km"]) or typeof(h.get("body")) != TYPE_STRING:
			return {"ok": false}
		nav["hold"] = h.duplicate(true)
	else:
		return {"ok": false}
	return nav

func _take_plan_nav(changes: Dictionary) -> bool:
	if not changes.has("journey"):
		return true
	var j = changes["journey"]
	var parsed := parse_plan_nav(j.get("plan") if typeof(j) == TYPE_DICTIONARY else null)
	if parsed.get("ok", true) == false:
		return false
	plan_nav = parsed
	return true

# ------------------------------------------------------------ 2.6 GR (M3.4b)
# Parse-only, like the system section: every number (clocks, blueshift, shadow,
# local beta/gamma/1-beta, tides, hover acceleration and power) is the sim's,
# computed from sunholo/relativity. The HUD formats these fields; it never derives them.
const _GR_NUMBERS := ["mass_msun", "rs_m", "r", "to_r", "phase", "static_clock", "ship_clock", "home_per_ship", "blueshift", "shadow",
	"beta_local", "gamma_local", "one_minus_beta_local", "hover_accel_g", "hover_power_w_per_kg", "hover_power_w", "tidal_radial_g", "tidal_transverse_g"]

## The approach intent: radially to `to_r` (r_s, [2, 10^6]) at local speed `beta_local` (0, 0.99].
static func gr_approach(to_r: float, beta_local: float) -> Dictionary:
	return {"k": "gr_approach", "to_r": to_r, "beta_local": beta_local}

## A `gr` section checked field by field: `{}` if anything is missing or mistyped.
static func parse_gr(v: Variant) -> Dictionary:
	if typeof(v) != TYPE_DICTIONARY or typeof(v.get("hole_id")) != TYPE_STRING or not v.get("mode") in ["hover", "orbit", "approach"] \
			or typeof(v.get("orbit_stable")) != TYPE_BOOL or not _floats(v, _GR_NUMBERS) or not _is_vec(v.get("dir_local")) or not _is_vec(v.get("hole_dir")):
		return {}
	return v.duplicate(true)

func _take_gr(changes: Dictionary) -> bool:
	if not changes.has("gr"):
		return true
	var parsed := parse_gr(changes["gr"])
	if parsed.is_empty():
		return false
	gr = parsed
	return true

func _fail(code: String) -> bool:
	last_error = code
	if not world.is_empty():
		world["status"] = code
	_cleanup()
	return false

func _cleanup() -> void:
	if _pid < 0:
		return
	if _pipe != null and _pipe.is_open():
		_write(encode({"v": 2, "type": "quit"}))
		_pipe.close()
	if _record != null:
		_record.close()
		_record = null
	var deadline := Time.get_ticks_msec() + 1000
	while OS.is_process_running(_pid) and Time.get_ticks_msec() < deadline:
		OS.delay_msec(5)
	if OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
	_game = false
