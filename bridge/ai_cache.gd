class_name AiCache
extends RefCounted
## Reads the AI asset layers and resolves a cache key to an asset (design
## ai-service-foundation (a4)). Every layer has the same layout:
##   <layer>/index.ndjson         append-only, one line per asset
##   <layer>/blobs/ab/<sha256>.<ext>
## Layers: core (`res://ai_core/`, bundled, AI.8) then the player library
## (`user://ai_cache/`, written only by the AI service). For a key, core
## wins; within the library the newest line wins. Text resolves from core
## only (a library line is never replayed as a new line), and a library voice
## line counts only when it carries `duration_ms` and `segments_ms` (the
## service's index lines do not yet; such lines are a miss).
## `age_stage` resolves to the greatest stage <= the years asked for.

const EMOTIONS := ["neutral", "happy", "sad", "angry", "fearful", "curious", "loving", "grieving"]

var core_dir := "res://ai_core"
var library_dir := "user://ai_cache"

## canonical key without the stage -> [{stage, entry, layer}] in file order
var _core: Dictionary = {}
var _lib: Dictionary = {}
var _lib_bytes := -1


func load_layers() -> void:
	_core = _read_index(core_dir, "core")
	_lib = _read_index(library_dir, "library")
	_lib_bytes = _index_size(library_dir)


## Re-read the library if its index grew (the service appends before it prints a result).
func refresh() -> void:
	if _index_size(library_dir) != _lib_bytes:
		_lib = _read_index(library_dir, "library")
		_lib_bytes = _index_size(library_dir)


## kind/entity_id/emotion/variant (the stage is resolved separately).
static func stem(k: Dictionary) -> String:
	return "%s/%s/%s/%s" % [k.get("kind"), k.get("entity_id"), k.get("emotion"), k.get("variant")]


## The index entry for `key` with the greatest age_stage <= `years`, core
## first, or {} on a miss. The entry has the index line's fields plus `_dir`.
func lookup(key: Dictionary, years: int) -> Dictionary:
	var hit := _best(_core.get(stem(key), []), years)
	if not hit.is_empty() or key.get("kind") == "text":
		return hit
	var lib := _best(_lib.get(stem(key), []), years)
	if key.get("kind") == "voice" and not (lib.has("duration_ms") and lib.has("segments_ms")):
		return {}
	return lib


func blob_path(e: Dictionary) -> String:
	var sha: String = e.get("sha256", "")
	return str(e["_dir"]).path_join("blobs/%s/%s.%s" % [sha.substr(0, 2), sha, e.get("ext", "")])


func has_blob(sha: String) -> bool:
	for layer in [_core, _lib]:
		for entries in layer.values():
			for x in entries:
				if x["entry"].get("sha256") == sha and FileAccess.file_exists(blob_path(x["entry"])):
					return true
	return false


## The record body for a media hit: the descriptor the sim validates, keyed by
## the request's key (a voice key keeps the line-derived variant).
func descriptor(e: Dictionary, req_key: Dictionary) -> Dictionary:
	var k := req_key.duplicate()
	if req_key.get("kind") == "voice":
		k["variant"] = e["key"]["variant"]
	var d := {"key": k, "mime": e["mime"], "bytes": e["bytes"]}
	for f in ["width", "height", "duration_ms", "segments_ms"]:
		if e.has(f):
			d[f] = e[f]
	return d


## Which portrait to show for an emotion: the chain mirrors sim/markers.ail
## fallbackChain (tests compare the two): the emotion, its neighbour, neutral.
static func fallback_chain(e: String) -> Array:
	match e:
		"happy": return ["happy", "loving", "neutral"]
		"loving": return ["loving", "happy", "neutral"]
		"sad": return ["sad", "grieving", "neutral"]
		"grieving": return ["grieving", "sad", "neutral"]
	if e == "neutral" or not e in EMOTIONS:
		return ["neutral"]
	return [e, "neutral"]


## The portrait entry to display for (entity, emotion) at `years`, walking the
## fallback chain; {} if the person has none.
func portrait_for(entity: String, emotion: String, years: int) -> Dictionary:
	for e in fallback_chain(emotion):
		var hit := lookup({"kind": "portrait", "entity_id": entity, "emotion": e, "variant": "0"}, years)
		if not hit.is_empty():
			return hit
	return {}


## A voice line's key variant (ai/voice.ail voiceVariant): what is said and by whom.
static func voice_variant(voice: String, segments: Array) -> String:
	var marked := PackedStringArray()
	for s in segments:
		marked.append("{%s}%s" % [s["emotion"], s["text"]])
	return (voice + "\n" + " ".join(marked)).sha256_text().substr(0, 16)


## Whole-number floats as ints, recursively: Godot's JSON parses every number
## as a float, and keys, seeds and descriptors carry integers.
static func ints(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			return int(v) if is_finite(v) and v == floorf(v) and absf(v) <= 9007199254740991.0 else v
		TYPE_DICTIONARY:
			var d := {}
			for k in v:
				d[k] = ints(v[k])
			return d
		TYPE_ARRAY:
			var a := []
			for x in v:
				a.append(ints(x))
			return a
	return v


static func _best(entries: Array, years: int) -> Dictionary:
	var best := {}
	var stage := -1
	for x in entries: # file order: a later line of the same stage replaces an earlier one
		if x["stage"] <= years and x["stage"] >= stage:
			stage = x["stage"]
			best = x["entry"]
	return best


static func _index_size(dir: String) -> int:
	var f := FileAccess.open(dir.path_join("index.ndjson"), FileAccess.READ)
	return -1 if f == null else f.get_length()


static func _read_index(dir: String, layer: String) -> Dictionary:
	var out := {}
	var f := FileAccess.open(dir.path_join("index.ndjson"), FileAccess.READ)
	if f == null:
		return out
	for line in f.get_as_text().split("\n", false):
		var e = JSON.parse_string(line) if line.begins_with("{") else null
		if not (e is Dictionary) or not (e.get("key") is Dictionary) or typeof(e.get("sha256")) != TYPE_STRING:
			continue
		e = ints(e)
		e["_dir"] = dir
		e["_layer"] = layer
		var k: Dictionary = e["key"]
		if typeof(k.get("age_stage")) != TYPE_INT:
			continue
		var s := stem(k)
		if not out.has(s):
			out[s] = []
		out[s].append({"stage": k["age_stage"], "entry": e})
	return out
