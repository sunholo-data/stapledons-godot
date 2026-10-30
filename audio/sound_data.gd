class_name SoundData
extends RefCounted
## R2-SOUND §D1, §D7, §D8: the cue table (data/audio/cues.json) and the asset manifest
## (data/audio/assets.json and its parts), loaded and validated. Every check returns readable
## error lines; an empty list means valid. `make sound-test` and `make sound-assets-check` print them.

const CUES_SCHEMA := "stapledons.audio.cues/1"
const ASSETS_SCHEMA := "stapledons.audio.assets/1"
const PART_SCHEMA := "stapledons.audio.asset-part/1"
const CUES_PATH := "res://data/audio/cues.json"
const ASSETS_PATH := "res://data/audio/assets.json"
## Buses a cue may play on (Ship and Master are mixing buses, never a cue's own).
const CUE_BUSES := ["Voice", "Ambience", "Effects", "Instruments", "Receiver", "UI", "Music"]
const TRIGGER_KINDS := ["sim_event", "sim_state", "ui_signal", "game"]
## Continuous parameters a looping cue may follow (SoundDirector.set_param).
const PARAMS := ["archive_degradation"]
## §D7, Pillar 2 (The Game Doesn't Judge): no cue may be named or described as a verdict.
const FORBIDDEN_WORDS := ["success", "successful", "fail", "failed", "failure", "win", "won", "lose", "reward", "penalty", "fanfare", "victory"]
## §D8 and D-101: generated sound is reserved, off until a later ruling sets allow_generated.
const SOURCE_KINDS := {"synth": ["synth-own"], "library": ["CC0-1.0"], "generated": ["generated-licensed"]}
const PROVENANCE := {
	"synth": ["generator", "generator_sha256", "recipe"],
	"library": ["url", "author", "retrieved", "download_sha256"],
	"generated": ["tool", "model", "prompt_sha256", "date", "terms_url"],
}


static func read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())


## The manifest's asset rows from every part, keyed by id, plus the top-level fields.
## {allow_generated, budget_bytes, assets: {id: row}, errors: [...]}.
static func load_assets(path := ASSETS_PATH) -> Dictionary:
	var out := {"allow_generated": false, "budget_bytes": 0, "assets": {}, "errors": []}
	var top: Variant = read_json(path)
	if not top is Dictionary or top.get("schema", "") != ASSETS_SCHEMA:
		out.errors.append("%s: not a %s manifest" % [path, ASSETS_SCHEMA])
		return out
	out.allow_generated = top.get("allow_generated", false) == true
	out.budget_bytes = int(top.get("budget_bytes", 0))
	for part: Variant in top.get("parts", []):
		var pp := path.get_base_dir().path_join(str(part))
		var p: Variant = read_json(pp)
		if not p is Dictionary or p.get("schema", "") != PART_SCHEMA or not p.get("assets", null) is Array:
			out.errors.append("%s: not a %s part" % [pp, PART_SCHEMA])
			continue
		for row: Variant in p.assets:
			if not row is Dictionary or str(row.get("id", "")).is_empty():
				out.errors.append("%s: a row without an id" % pp)
			elif out.assets.has(row.id):
				out.errors.append("asset %s is listed twice" % row.id)
			else:
				out.assets[row.id] = row
	return out


## Licence and provenance rules (no file access): every row has a known source_kind, a licence that
## kind allows, the kind's provenance fields, and `generated` only when allow_generated is true.
static func check_rows(m: Dictionary) -> Array[String]:
	var bad: Array[String] = []
	for id: String in m.assets:
		var r: Dictionary = m.assets[id]
		var kind := str(r.get("source_kind", ""))
		if not SOURCE_KINDS.has(kind):
			bad.append("%s: unknown source_kind '%s'" % [id, kind])
			continue
		if kind == "generated" and not m.allow_generated:
			bad.append("%s: generated sound is not allowed yet (allow_generated is false; D-101)" % id)
		if not str(r.get("licence", "")) in SOURCE_KINDS[kind]:
			bad.append("%s: licence '%s' is not allowed for %s (allowed: %s)" % [id, r.get("licence", ""), kind, ", ".join(SOURCE_KINDS[kind])])
		var prov: Variant = r.get("provenance", null)
		for field: String in PROVENANCE[kind]:
			if not prov is Dictionary or str(prov.get(field, "")).is_empty():
				bad.append("%s: provenance.%s is missing" % [id, field])
		if not str(r.get("path", "")).begins_with("assets/audio/%s/" % kind):
			bad.append("%s: path %s is not under assets/audio/%s/" % [id, r.get("path", ""), kind])
	return bad


## The files themselves: present, bytes and sha256 as listed, 48 kHz 16-bit PCM WAV with the
## listed channels and frames, loop points inside the data, and the git budget.
static func check_files(m: Dictionary, root := "res://") -> Array[String]:
	var bad: Array[String] = []
	var total := 0
	for id: String in m.assets:
		var r: Dictionary = m.assets[id]
		var p := root.path_join(str(r.get("path", "")))
		if not FileAccess.file_exists(p):
			bad.append("%s: %s is missing" % [id, p])
			continue
		var bytes := FileAccess.get_file_as_bytes(p)
		total += bytes.size()
		if bytes.size() != int(r.get("bytes", -1)):
			bad.append("%s: %d bytes, manifest says %s" % [id, bytes.size(), r.get("bytes", "?")])
		if FileAccess.get_sha256(p) != str(r.get("sha256", "")):
			bad.append("%s: sha256 differs from the manifest" % id)
		var h := wav_info(bytes)
		if h.is_empty():
			bad.append("%s: not a PCM WAV" % id)
			continue
		if h.rate != 48000 or h.bits != 16:
			bad.append("%s: %d Hz %d-bit, want 48000 Hz 16-bit" % [id, h.rate, h.bits])
		if h.channels != int(r.get("channels", -1)) or h.frames != int(r.get("frames", -1)):
			bad.append("%s: %d ch %d frames, manifest says %s ch %s frames" % [id, h.channels, h.frames, r.get("channels", "?"), r.get("frames", "?")])
		var lp: Variant = r.get("loop", null)
		if lp is Dictionary and not (int(lp.get("begin", -1)) >= 0 and int(lp.get("end", -1)) <= h.frames and int(lp.begin) < int(lp.end)):
			bad.append("%s: loop %s is outside 0..%d" % [id, lp, h.frames])
	if m.budget_bytes > 0 and total > m.budget_bytes:
		bad.append("audio in git is %d bytes, over the %d budget" % [total, m.budget_bytes])
	return bad


## {rate, channels, bits, frames, data_offset} of a canonical PCM WAV, or {} when it is not one.
static func wav_info(b: PackedByteArray) -> Dictionary:
	if b.size() < 44 or b.slice(0, 4).get_string_from_ascii() != "RIFF" or b.slice(8, 12).get_string_from_ascii() != "WAVE":
		return {}
	var i := 12
	var fmt := {}
	while i + 8 <= b.size():
		var tag := b.slice(i, i + 4).get_string_from_ascii()
		var n := b.decode_u32(i + 4)
		if tag == "fmt ":
			if b.decode_u16(i + 8) != 1:
				return {}
			fmt = {"channels": b.decode_u16(i + 10), "rate": b.decode_u32(i + 12), "bits": b.decode_u16(i + 22)}
		elif tag == "data" and not fmt.is_empty():
			fmt["frames"] = n / (fmt.channels * fmt.bits / 8)
			fmt["data_offset"] = i + 8
			return fmt
		i += 8 + n + (n & 1)
	return {}


## The cue table against the manifest: schema, unique ids, known trigger kinds with their fields,
## streams that exist, a cue bus, the visual counterpart rule and the forbidden words.
## check_refs: the visual-counterpart rule reads the game's source files, so it is an authoring check
## (tests, tools); an exported build has no .gd text to read and skips it (SoundDirector.setup).
static func check_cues(table: Variant, assets: Dictionary, root := "res://", check_refs := true) -> Array[String]:
	var bad: Array[String] = []
	if not table is Dictionary or table.get("schema", "") != CUES_SCHEMA or not table.get("cues", null) is Array:
		return ["cue table: not a %s table" % CUES_SCHEMA]
	var seen := {}
	for c: Variant in table.cues:
		if not c is Dictionary or str(c.get("id", "")).is_empty():
			bad.append("a cue without an id")
			continue
		var id := str(c.id)
		if seen.has(id):
			bad.append("%s: listed twice" % id)
		seen[id] = true
		var t: Variant = c.get("trigger", null)
		var kind := str(t.get("kind", "")) if t is Dictionary else ""
		if not kind in TRIGGER_KINDS:
			bad.append("%s: unknown trigger kind '%s'" % [id, kind])
		elif kind == "sim_event" and str(t.get("k", "")).is_empty():
			bad.append("%s: a sim_event trigger needs k" % id)
		elif kind == "sim_state" and str(t.get("path", "")).is_empty():
			bad.append("%s: a sim_state trigger needs path" % id)
		elif kind in ["ui_signal", "game"] and str(t.get("name", "")).is_empty():
			bad.append("%s: a %s trigger needs name" % [id, kind])
		var streams: Variant = c.get("streams", [])
		if not streams is Array or streams.is_empty():
			bad.append("%s: no streams" % id)
		else:
			for s: Variant in streams:
				if not assets.has(str(s)):
					bad.append("%s: stream %s is not in the asset manifest" % [id, s])
		if not str(c.get("bus", "")) in CUE_BUSES:
			bad.append("%s: bus '%s' is not a cue bus (%s)" % [id, c.get("bus", ""), ", ".join(CUE_BUSES)])
		var pc: Variant = c.get("param", null)
		if pc != null:
			var pts: Variant = pc.get("points", null) if pc is Dictionary else null
			var ok: bool = pc is Dictionary and str(pc.get("name", "")) in PARAMS and pts is Array and pts.size() >= 2
			if ok:
				for i in pts.size():
					ok = ok and pts[i] is Array and pts[i].size() == 2 and (i == 0 or float(pts[i][0]) > float(pts[i - 1][0]))
			if not ok:
				bad.append("%s: param needs a known name (%s) and two or more [value, dB] points in rising order" % [id, ", ".join(PARAMS)])
			elif not c.get("loop", false):
				bad.append("%s: only a loop can follow a param" % id)
		var vis := str(c.get("visual", ""))
		if kind in ["sim_event", "sim_state"] and check_refs:
			var ref := vis.split("::")
			if ref.size() != 2 or not FileAccess.file_exists(root.path_join(ref[0])) or not FileAccess.get_file_as_string(root.path_join(ref[0])).contains(ref[1]):
				bad.append("%s: an informative cue needs a visual counterpart 'file::text' that exists in the code (got '%s')" % [id, vis])
		elif vis.is_empty():
			bad.append("%s: visual is empty (name a counterpart or say 'ambient: why')" % id)
		var words := (id + " " + str(c.get("about", ""))).to_lower()
		for w: String in FORBIDDEN_WORDS:
			if RegEx.create_from_string("\\b%s\\b" % w).search(words) != null:
				bad.append("%s: '%s' judges the player (Pillar 2)" % [id, w])
	return bad


## A canonical 16-bit PCM WAV (tests and the review renderer; the game's own files come from the
## AILANG synthesis tool).
static func wav_bytes(pcm: PackedByteArray, rate: int, channels: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(44)
	b.encode_u32(0, 0x46464952) # RIFF
	b.encode_u32(4, 36 + pcm.size())
	b.encode_u32(8, 0x45564157) # WAVE
	b.encode_u32(12, 0x20746d66) # fmt
	b.encode_u32(16, 16)
	b.encode_u16(20, 1)
	b.encode_u16(22, channels)
	b.encode_u32(24, rate)
	b.encode_u32(28, rate * channels * 2)
	b.encode_u16(32, channels * 2)
	b.encode_u16(34, 16)
	b.encode_u32(36, 0x61746164) # data
	b.encode_u32(40, pcm.size())
	b.append_array(pcm)
	return b
