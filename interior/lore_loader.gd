class_name LoreLoader
extends RefCounted
## M4.7 the Archive's lore (design m4-first-journey.md "M4.7"): reads the vendored design-repo
## entries under res://data/lore/archive/ (make lore-import), refuses any file whose sha256 differs
## from data/lore/manifest.json, and renders a Markdown subset to BBCode for a RichTextLabel.
## The numbers in the entries are vouched for by `make lore-check`; this class never edits them.
## The game never reads the design repo at run time.

const DIR := "res://data/lore"
## The README's hint vocabulary (also sim/consequence.ail knownHints). Words only: the codex shows
## no numeral that is not lore.
const HINT_TEXT := {
	"always": "Open from the start",
	"first_commit": "Opens when you commit to a journey",
	"first_boost": "Opens when the first boost begins",
	"cruise_above_0.9c": "Opens when you cruise at close to the speed of light",
	"cruise_above_gamma_275": "Opens when you cruise at an extreme Lorentz factor",
	"first_black_hole": "Opens when you arrive near a black hole",
}


## {"entries": [{id, title, unlock, checks, body, file, sha256}], "errors": [String]}. Entries are in
## the README's table order (the order the sim fires simultaneous unlocks), then any others by name.
static func load_entries(dir: String = DIR) -> Dictionary:
	var out := {"entries": [], "errors": []}
	var manifest := _manifest(dir)
	if manifest.is_empty():
		out["errors"].append("%s/manifest.json is missing or unreadable" % dir)
		return out
	var files: Array = []
	for f in DirAccess.get_files_at(dir + "/archive"):
		if f.ends_with(".md") and f != "README.md":
			files.append(f)
	files.sort()
	var order := _readme_order(dir)
	files.sort_custom(func(a: String, b: String) -> bool:
		var ia: int = order.find("archive." + a.trim_suffix(".md"))
		var ib: int = order.find("archive." + b.trim_suffix(".md"))
		if ia == -1: ia = 1000
		if ib == -1: ib = 1000
		return ia < ib if ia != ib else a < b)
	for f in files:
		var rel: String = "archive/" + f
		var bytes := FileAccess.get_file_as_bytes("%s/%s" % [dir, rel])
		var sha := _sha256(bytes)
		if manifest.get(rel, "") != sha:
			out["errors"].append("%s does not match the manifest (sha256 %s)" % [rel, sha])
			continue
		var e := parse_entry(bytes.get_string_from_utf8())
		if e.is_empty():
			out["errors"].append("%s has no valid front matter" % rel)
			continue
		e["file"] = rel
		e["sha256"] = sha
		out["entries"].append(e)
	return out


## {id, title, unlock, checks, body} from an entry's text, or {} when the front matter is invalid.
static func parse_entry(text: String) -> Dictionary:
	var lines := text.split("\n")
	if lines.size() < 3 or lines[0].strip_edges() != "---":
		return {}
	var close := -1
	for i in range(1, lines.size()):
		if lines[i].strip_edges() == "---":
			close = i
			break
	if close < 0:
		return {}
	var fm := {}
	for i in range(1, close):
		var colon := lines[i].find(":")
		if colon > 0:
			var v := lines[i].substr(colon + 1)
			var hash := v.find(" #")
			fm[lines[i].substr(0, colon).strip_edges()] = (v.substr(0, hash) if hash >= 0 else v).strip_edges()
	for k in ["id", "title", "unlock", "checks"]:
		if not fm.has(k) or fm[k] == "":
			return {}
	var checks_text: String = fm["checks"].trim_prefix("[").trim_suffix("]")
	var checks: Array = []
	for c in checks_text.split(","):
		if c.strip_edges() != "":
			checks.append(c.strip_edges())
	return {"id": fm["id"], "title": fm["title"], "unlock": fm["unlock"], "checks": checks, "body": "\n".join(lines.slice(close + 1))}


static func archive_rows(entries: Array) -> Array:
	return entries.map(func(e: Dictionary) -> Dictionary: return {"id": e["id"], "unlock": e["unlock"]})


## sha256 (hex) of an entry's body as imported, for LoreBinding.
static func body_sha(entry_id: String, dir: String = DIR) -> String:
	for e: Dictionary in load_entries(dir)["entries"]:
		if e["id"] == entry_id:
			return sha256_text(e["body"])
	return ""


static func sha256_text(s: String) -> String:
	return _sha256(s.to_utf8_buffer())


static func _sha256(bytes: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(bytes)
	return ctx.finish().hex_encode()


static func _manifest(dir: String) -> Dictionary:
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir + "/manifest.json"))
	var out := {}
	if j is Dictionary and j.get("files") is Array:
		for f in j["files"]:
			out[f["path"]] = f["sha256"]
	return out


## The README's entries table lists ids in the order the design repo wants them.
static func _readme_order(dir: String) -> Array:
	var ids: Array = []
	var rx := RegEx.create_from_string("\\|\\s*`(archive\\.[a-z0-9-]+)`")
	for m in rx.search_all(FileAccess.get_file_as_string(dir + "/archive/README.md")):
		ids.append(m.get_string(1))
	return ids


# ---------------------------------------------------------------- Markdown subset -> BBCode
## Headings, paragraphs, emphasis and strong, bullet lists and pipe tables. Soft line breaks inside a
## paragraph are spaces. `[` and `]` in the text are escaped so prose can never open a BBCode tag.
static func to_bbcode(md: String) -> String:
	var blocks: Array = []
	var para: Array = []
	var table: Array = []
	var flush := func() -> void:
		if not para.is_empty():
			blocks.append(_inline(" ".join(para)))
			para.clear()
		if not table.is_empty():
			blocks.append(_table(table))
			table.clear()
	for raw in md.split("\n"):
		var line: String = raw.strip_edges(false, true)
		var t := line.strip_edges()
		if t == "":
			flush.call()
		elif t.begins_with("|"):
			if not para.is_empty():
				flush.call()
			table.append(t)
		elif t.begins_with("#"):
			flush.call()
			blocks.append("[font_size=22][b]%s[/b][/font_size]" % _inline(t.lstrip("#").strip_edges()))
		elif t.begins_with("- ") or t.begins_with("* "):
			flush.call()
			blocks.append("• " + _inline(t.substr(2)))
		else:
			if not table.is_empty():
				flush.call()
			para.append(t)
	flush.call()
	return "\n\n".join(blocks)


static func _inline(s: String) -> String:
	s = s.replace("[", "\u0001").replace("]", "\u0002") # placeholders, so the escapes below are not re-escaped
	s = RegEx.create_from_string("\\*\\*(?=\\S)(.+?)(?<=\\S)\\*\\*").sub(s, "[b]$1[/b]", true)
	s = RegEx.create_from_string("(?<![\\w*])\\*(?=[^\\s*])(.+?)(?<=[^\\s*])\\*(?![\\w*])").sub(s, "[i]$1[/i]", true)
	s = RegEx.create_from_string("(?<![\\w_])_(?=\\S)(.+?)(?<=\\S)_(?![\\w_])").sub(s, "[i]$1[/i]", true)
	return s.replace("\u0001", "[lb]").replace("\u0002", "[rb]")


static func _table(rows: Array) -> String:
	var cells: Array = []
	for r: String in rows:
		var parts: Array = Array(r.trim_prefix("|").trim_suffix("|").split("|"))
		var is_sep: bool = parts.all(func(p: String) -> bool: return p.strip_edges().replace("-", "").replace(":", "") == "")
		if not is_sep:
			cells.append(parts.map(func(p: String) -> String: return p.strip_edges()))
	if cells.is_empty():
		return ""
	var cols: int = cells[0].size()
	var out := "[table=%d]" % cols
	for row: Array in cells:
		for i in cols:
			out += "[cell]%s[/cell]" % _inline(row[i] if i < row.size() else "")
	return out + "[/table]"
