class_name AiSettings
extends RefCounted
## Live AI settings (design ai-service-foundation (a5), AI.9): off by default;
## the player's own keys, either or both; one player-set ceiling over both
## providers; text-only always available. Never logs a key.
##
## - Opt-in needs at least one key AND the tick. Automation runs (captures,
##   goldens, bench, the export smoke) never go live, whatever is saved.
## - Each key: its env var first (GOOGLE_API_KEY, OPENROUTER_API_KEY), else
##   `<dir>/ai_key_gemini` / `<dir>/ai_key_openrouter`, mode 0600. The service
##   gets key FILES only (AiBridge.live_plan): an env key is copied to a
##   0600 session file, removed by `forget_session_keys()`.
## - `<dir>/ai_settings.cfg` holds the tick, the ceiling and text-only, never
##   a key.

const PROVIDERS := ["gemini", "openrouter"]
const KEY_ENV := {"gemini": "GOOGLE_API_KEY", "openrouter": "OPENROUTER_API_KEY"}
const LABEL := {"gemini": "Google AI (Gemini)", "openrouter": "OpenRouter"}
const CEILING_DEFAULT := 0.5
## Bounds per plan Q2 (D-20): US$0.05 to US$20 a session, over both providers.
const CEILING_MIN := 0.05
const CEILING_MAX := 20.0
const WARNING := "Live AI sends prompts to Google and/or OpenRouter and is billed to YOUR key, up to the session ceiling. A key saved here is stored unencrypted in a file only your user account can read (mode 0600)."
## Flags of automation runs: they never go live.
const AUTOMATION_FLAGS := ["capture", "map-capture", "golden", "bench", "ai-hello", "movie"]
## Per-kind estimate assumptions (display only): text in/out tokens, voice in/out tokens.
const TEXT_TOKENS := [600, 172]
const VOICE_TOKENS := [60, 300]

var dir := "user://"
var routing_path := "res://data/ai/routing.json"
var prices_path := "res://data/ai/prices.json"
var opt_in := false
var ceiling_usd := CEILING_DEFAULT
var text_only := false
var text_only_flag := false
var automation := false


func cfg_path() -> String:
	return dir.path_join("ai_settings.cfg")


func key_path(p: String) -> String:
	return dir.path_join("ai_key_" + p)


func session_key_path(p: String) -> String:
	return dir.path_join(".ai_key_session_" + p)


## `--text-only` forces text-only; automation flags force live off.
func apply_args(args: Dictionary) -> void:
	text_only_flag = args.has("text-only")
	automation = AUTOMATION_FLAGS.any(func(f): return args.has(f))


func load_settings() -> void:
	var cf := ConfigFile.new()
	if cf.load(cfg_path()) != OK:
		return
	opt_in = cf.get_value("ai", "opt_in", false) is bool and cf.get_value("ai", "opt_in", false)
	var c = cf.get_value("ai", "ceiling_usd", CEILING_DEFAULT)
	set_ceiling(float(c) if (c is float or c is int) else CEILING_DEFAULT)
	text_only = cf.get_value("ai", "text_only", false) is bool and cf.get_value("ai", "text_only", false)


func save_settings() -> bool:
	var cf := ConfigFile.new()
	cf.set_value("ai", "opt_in", opt_in)
	cf.set_value("ai", "ceiling_usd", ceiling_usd)
	cf.set_value("ai", "text_only", text_only)
	return cf.save(cfg_path()) == OK


func set_ceiling(v: float) -> void:
	ceiling_usd = CEILING_DEFAULT if is_nan(v) else clampf(snappedf(v, 0.01), CEILING_MIN, CEILING_MAX)


## "env", "file" or "" (none).
func key_source(p: String) -> String:
	if OS.get_environment(KEY_ENV[p]).strip_edges() != "":
		return "env"
	if FileAccess.file_exists(key_path(p)) and FileAccess.get_file_as_string(key_path(p)).strip_edges() != "":
		return "file"
	return ""


func keys_present() -> Array:
	return PROVIDERS.filter(func(p): return key_source(p) != "")


## Save a pasted key with mode 0600 (the file is made empty, chmod-ed, then
## written, so the key is never in a world-readable file). "" removes it.
func save_key(p: String, text: String) -> bool:
	var path := ProjectSettings.globalize_path(key_path(p))
	return _write_private(path, text.strip_edges())


static func _write_private(path: String, text: String) -> bool:
	if text == "":
		return not FileAccess.file_exists(path) or DirAccess.remove_absolute(path) == OK
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.close()
	if OS.execute("/bin/chmod", PackedStringArray(["600", path])) != 0:
		DirAccess.remove_absolute(path)
		return false
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	return true


## {provider: key file path} for every key present; an env key goes to a
## 0600 session file so it reaches the service as a path, like a saved key.
func key_files() -> Dictionary:
	var out := {}
	for p in PROVIDERS:
		match key_source(p):
			"file":
				out[p] = ProjectSettings.globalize_path(key_path(p))
			"env":
				var s := ProjectSettings.globalize_path(session_key_path(p))
				if _write_private(s, OS.get_environment(KEY_ENV[p]).strip_edges()):
					out[p] = s
	return out


func forget_session_keys() -> void:
	for p in PROVIDERS:
		_write_private(ProjectSettings.globalize_path(session_key_path(p)), "")


func live_on() -> bool:
	return opt_in and not automation and not keys_present().is_empty()


func effective_text_only() -> bool:
	return text_only or text_only_flag


func routes() -> Dictionary:
	var r = JSON.parse_string(FileAccess.get_file_as_string(routing_path))
	return r["routes"] if r is Dictionary and r.get("routes") is Dictionary else {}


## The kinds a key for `p` can serve, from the routing table (OpenRouter: text).
func kinds_for(p: String) -> Array:
	var out := []
	var rt := routes()
	for kind in rt:
		if AiRelay.route_in(rt, kind, [p], false) == p:
			out.append(kind)
	return out


## The kinds that go live with the keys present; the rest stay on the core set.
func live_kinds() -> Array:
	var rt := routes()
	var have := keys_present()
	return rt.keys().filter(func(k): return AiRelay.route_in(rt, k, have, effective_text_only()) != "")


## About what one text line, voice line and portrait costs on the route the
## keys present pick (or the first route): US$ per kind.
func estimates() -> Dictionary:
	var pr = JSON.parse_string(FileAccess.get_file_as_string(prices_path))
	var prices: Dictionary = pr["prices"] if pr is Dictionary and pr.get("prices") is Dictionary else {}
	var rt := routes()
	var have := keys_present()
	var out := {}
	for kind in ["text", "voice", "portrait"]:
		var p := AiRelay.route_in(rt, kind, have, false)
		var hop: Dictionary = {}
		for h in rt.get(kind, []):
			if hop.is_empty() or h.get("provider") == p:
				hop = h
		var m: Dictionary = prices.get(hop.get("provider", ""), {}).get(hop.get("model", ""), {})
		var t: Array = TEXT_TOKENS if kind == "text" else VOICE_TOKENS
		out[kind] = float(m.get("per_call", 0.0)) + (t[0] * float(m.get("in_per_mtok", 0.0)) + t[1] * float(m.get("out_per_mtok", 0.0))) / 1.0e6
	return out


## Configure the bridge and the relay. The tick is the player's attended
## consent, so it is what lets AI_LIVE=1 reach the service (live_allowed);
## automation never sets it (live_on() is false there).
func apply(bridge: AiBridge, relay: AiRelay) -> void:
	var on := live_on()
	bridge.live = on
	bridge.key_files = key_files() if on else {}
	bridge.live_allowed = on
	bridge.ceiling_usd = ceiling_usd
	bridge.text_only = effective_text_only()
	relay.mode = "live" if on else "off"
	relay.keys = keys_present() if on else []
	relay.text_only = effective_text_only()
