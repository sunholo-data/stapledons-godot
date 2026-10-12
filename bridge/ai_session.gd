class_name AiSession
extends Node
## The game's AI wiring (AI.9): settings, AiBridge, AiCache, AiRelay and the
## indicator, made from the command line and `user://` settings. main.gd adds
## one and passes `ai_core()` to new_game, then `attach(sim)`.
## Live AI is on only when the player ticked it with a key present and this is
## not an automation run; otherwise the relay is "off" (cache hits from the
## core set, everything else falls back) and no service is started.
## Automation runs (captures, goldens) get no indicator.
## `--ai-hello=FILE` (export smoke): starts the stub service, writes its hello
## (or {"error": ...}) to FILE and quits.

const CORE_INDEX := "res://data/ai/core/index.ndjson"
const HELLO_MS := 60000

var settings := AiSettings.new()
var bridge := AiBridge.new()
var cache := AiCache.new()
var relay: AiRelay
var indicator: AiIndicator
var _hello_out := ""
var _hello_deadline := 0
var _dirty := false


## `dir` holds the settings and saved keys (tests use a scratch directory).
func _init(args: Dictionary = {}, dir: String = "user://") -> void:
	name = "AiSession"
	settings.dir = dir
	settings.apply_args(args)
	settings.load_settings()
	settings.forget_session_keys() # a crash may have left the last session's (AI.9 hardening)
	relay = AiRelay.new(bridge, cache)
	settings.apply(bridge, relay)
	_hello_out = args.get("ai-hello", "")
	add_child(bridge)
	if settings.automation and _hello_out == "":
		return # captures and goldens: no indicator in their frames
	indicator = load("res://ui/ai_indicator.tscn").instantiate()
	indicator.session = self
	add_child(indicator)


## sha256 of the core index (design (a4)): the `ai_core` value for new_game.
static func ai_core() -> String:
	var b := FileAccess.get_file_as_bytes(CORE_INDEX)
	if b.is_empty():
		return ""
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	h.update(b)
	return h.finish().hex_encode()


## Hook the relay into the sim (an older sim stays on templates). Always true:
## AI is never a reason for the game to fail.
func attach(sim: SimBridge) -> bool:
	relay.attach(sim)
	if _hello_out != "":
		_start_hello()
	return true


## Settings changed (the panel): reconfigure; the service restarts with the
## new configuration once it is idle.
func settings_changed() -> void:
	settings.save_settings()
	settings.apply(bridge, relay)
	_dirty = true


func _process(_delta: float) -> void:
	if _dirty and bridge.pending() == 0:
		_dirty = false
		bridge.shutdown()
	if _hello_out != "" and _hello_deadline > 0:
		_poll_hello()


func _exit_tree() -> void:
	settings.forget_session_keys()


func _start_hello() -> void:
	bridge.live = false
	_hello_deadline = Time.get_ticks_msec() + HELLO_MS
	bridge.request({"req": "smoke", "kind": "text", "purpose": "probe"})


func _poll_hello() -> void:
	var done := not bridge.hello_reply.is_empty()
	if not done and Time.get_ticks_msec() < _hello_deadline and not bridge.service_down:
		return
	var out := bridge.hello_reply if done else {"error": bridge.last_error, "stderr": bridge.stderr_tail.right(400)}
	var f := FileAccess.open(_hello_out, FileAccess.WRITE)
	if f != null:
		f.store_string(SimBridge.encode(out) + "\n")
	_hello_deadline = 0
	get_tree().quit(0 if done else 2)
