class_name ObservationTileCache
extends RefCounted
## Host presentation cache only. Requests queue I/O; pump decodes a bounded number
## of visible pinned tiles. No network, physics, render loop or hidden thread.
## Resident byte counts cover cache-owned RGBA8 images/textures (no runtime mips).
## Callers must not retain returned entries across close/pack activation.
const CPU_LIMIT := 64 * 1024 * 1024
const GPU_LIMIT := 128 * 1024 * 1024
const MAX_COMPRESSED_BYTES := 8 * 1024 * 1024

var decodes := 0
var cpu_bytes := 0
var gpu_bytes := 0
var revision := 0
var last_error := ""
var pack_version := ""
var active := false
var cpu_limit: int
var gpu_limit: int
var _entries := {}
var _visible := {}
var _queue: Array[Dictionary] = []
var _queued := {}
var _states := {}
var _stamp := 0

func _init(max_cpu := CPU_LIMIT, max_gpu := GPU_LIMIT) -> void:
	cpu_limit = clampi(max_cpu, 0, CPU_LIMIT)
	gpu_limit = clampi(max_gpu, 0, GPU_LIMIT)

func activate(version: String) -> void:
	if active and version == pack_version: return
	close()
	pack_version = version
	active = not version.is_empty()
	last_error = "" if active else "missing_pack_version"

func set_visible(keys: Array) -> void:
	_visible.clear()
	if not active: return
	for key: Variant in keys:
		if key is String and not key.is_empty(): _visible[key] = true
	var keep: Array[Dictionary] = []
	_queued.clear()
	for job in _queue:
		if job.revision == revision and _visible.has(job.meta.key):
			keep.append(job)
			_queued[job.meta.key] = true
		else:
			_states[job.meta.key] = "not_visible"
	_queue = keep

static func _integer(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value))

static func _valid(meta: Dictionary) -> bool:
	for key in ["key", "path", "sha256"]:
		if not meta.get(key) is String or meta[key].is_empty(): return false
	if meta.sha256.length() != 64: return false
	for c in meta.sha256:
		if not c in "0123456789abcdef": return false
	for key in ["width", "height"]:
		if not _integer(meta.get(key)) or meta[key] < 3 or meta[key] > 514: return false
	return true

func request_tile(meta: Dictionary, version := "") -> Dictionary:
	last_error = ""
	var key := str(meta.get("key", ""))
	if not active:
		last_error = "closed"
		return {}
	if not version.is_empty() and version != pack_version:
		last_error = "pack_mismatch"
		return {}
	if not _valid(meta):
		_states[key] = "invalid"
		return {}
	if not _visible.has(key):
		_states[key] = "not_visible"
		return {}
	var needed := int(meta.width) * int(meta.height) * 4
	if needed > cpu_limit or needed > gpu_limit:
		_states[key] = "over_budget"
		return {}
	if _entries.has(key):
		var old: Dictionary = _entries[key].meta
		if old.sha256 != meta.sha256 or old.width != meta.width or old.height != meta.height:
			last_error = "identity_changed"
			return {}
		return get_tile(key)
	if not _queued.has(key):
		_queue.append({"meta": meta.duplicate(true), "revision": revision})
		_queued[key] = true
		_states[key] = "queued"
	return {}

func state(key: String) -> String:
	if _entries.has(key): return "ready"
	return _states.get(key, "unrequested")

func get_tile(key: String) -> Dictionary:
	if not active or not _entries.has(key): return {}
	_stamp += 1
	_entries[key].stamp = _stamp
	return _entries[key]

static func _png_dimension(bytes: PackedByteArray, at: int) -> int:
	return (int(bytes[at]) << 24) | (int(bytes[at + 1]) << 16) | (int(bytes[at + 2]) << 8) | int(bytes[at + 3])

func _load(meta: Dictionary) -> Dictionary:
	var file := FileAccess.open(meta.path, FileAccess.READ)
	if file == null: return {"error": "missing"}
	if file.get_length() > MAX_COMPRESSED_BYTES: return {"error": "invalid"}
	var bytes := file.get_buffer(file.get_length())
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	if hash.finish().hex_encode() != meta.sha256: return {"error": "corrupt"}
	if bytes.size() < 26 or bytes.slice(0, 8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]):
		return {"error": "corrupt"}
	if bytes.slice(12, 16).get_string_from_ascii() != "IHDR" or _png_dimension(bytes, 16) != int(meta.width) or _png_dimension(bytes, 20) != int(meta.height):
		return {"error": "invalid"}
	if bytes[24] != 8 or not bytes[25] in [0, 2, 4, 6]: return {"error": "invalid"}
	var image := Image.new()
	decodes += 1
	if image.load_png_from_buffer(bytes) != OK: return {"error": "corrupt"}
	image.convert(Image.FORMAT_RGBA8)
	return {"image": image, "bytes": image.get_data().size()}

func _evict_for(needed: int) -> void:
	while not _entries.is_empty() and (cpu_bytes + needed > cpu_limit or gpu_bytes + needed > gpu_limit):
		var victim := ""
		var oldest := 9223372036854775807
		for key: String in _entries:
			if _entries[key].stamp < oldest:
				oldest = _entries[key].stamp
				victim = key
		cpu_bytes -= int(_entries[victim].cpu_bytes)
		gpu_bytes -= int(_entries[victim].gpu_bytes)
		_entries.erase(victim)
		_states[victim] = "evicted"

func pump(max_jobs := 1) -> void:
	if not active: return
	for _job in clampi(max_jobs, 0, 8):
		if _queue.is_empty(): return
		var job: Dictionary = _queue.pop_front()
		var meta: Dictionary = job.meta
		_queued.erase(meta.key)
		if job.revision != revision or not _visible.has(meta.key): continue
		_evict_for(int(meta.width) * int(meta.height) * 4)
		var decoded := _load(meta)
		if decoded.has("error"):
			_states[meta.key] = decoded.error
			continue
		var needed: int = decoded.bytes
		_evict_for(needed)
		if needed > cpu_limit or needed > gpu_limit:
			_states[meta.key] = "over_budget"
			continue
		var texture := ImageTexture.create_from_image(decoded.image)
		_stamp += 1
		_entries[meta.key] = {"image": decoded.image, "texture": texture, "meta": meta,
			"cpu_bytes": needed, "gpu_bytes": needed, "stamp": _stamp}
		cpu_bytes += needed
		gpu_bytes += needed
		_states[meta.key] = "ready"

func close() -> void:
	active = false
	revision += 1
	_queue.clear()
	_queued.clear()
	_visible.clear()
	_entries.clear()
	_states.clear()
	cpu_bytes = 0
	gpu_bytes = 0
