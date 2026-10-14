extends SceneTree
## Streaming audit: reconstruct bindings from their contracts, never from shown text.
var failures := 0
var count := 0
var checks := 0
var lore_checks := 0
var phases := {}
var news_checks := 0
var settled_news := 0
var mode := ""
var world := {}
var state_file: FileAccess
var fallback := false
var mismatches := 0
var unbound := 0
var missing := 0
var accepted := {}
var kinds := {}
var ai_failures := 0
var known_entries: Array = []
var known_hits := {}
var known_kinds := {}
var new_findings := 0
var stale_entries := 0
var digits := RegEx.create_from_string("[0-9]+(?:\\.[0-9]+)?")
var generated_segment := RegEx.create_from_string("^@([^/@]+)@[0-9]+$")


func normalized(text_value: String) -> String:
	return digits.sub(text_value, "N", true)


func normalized_node(node: String) -> String:
	# Creation-order suffixes are unstable; named segments and class names are exact.
	var segments := node.split("/")
	for i in segments.size():
		segments[i] = generated_segment.sub(segments[i], "@$1")
	return "/".join(segments)


func load_known(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		check(false, "known-file missing " + path); return
	var document: Variant = JSON.parse_string(f.get_as_text())
	if not document is Dictionary or not document.get("findings") is Array:
		check(false, "known-file invalid findings"); return
	var keys := {}
	for entry: Variant in document.findings:
		if not entry is Dictionary:
			check(false, "known-file invalid entry"); continue
		var valid := true
		for field in ["kind", "node", "text", "why", "row"]:
			if not entry.get(field) is String or str(entry.get(field, "")).is_empty(): valid = false
		if not entry.get("observed_samples") is float and not entry.get("observed_samples") is int: valid = false
		elif float(entry.observed_samples) <= 0 or float(entry.observed_samples) != floor(float(entry.observed_samples)): valid = false
		if entry.get("kind") not in ["unbound", "transit-ISM"] or entry.get("row") != "M4.5bR3-follow-up": valid = false
		if entry.get("kind") == "transit-ISM":
			for field in ["folding_card", "accompanying_card"]:
				if not entry.get(field) is String or str(entry.get(field, "")).is_empty(): valid = false
		if not valid:
			check(false, "known-file invalid entry fields"); continue
		entry.node = normalized_node(entry.node)
		entry.text = normalized(entry.text)
		if entry.kind == "transit-ISM":
			entry.folding_card = normalized_node(entry.folding_card)
			entry.accompanying_card = normalized_node(entry.accompanying_card)
		var key := JSON.stringify([entry.kind, entry.node, entry.text])
		check(not keys.has(key), "known-file duplicate entry " + key)
		keys[key] = true
		known_entries.append(entry)


func recorded_card(row: Dictionary, pattern: String, expanded: bool) -> bool:
	for card: Dictionary in row.get("cards", []):
		if normalized_node(str(card.get("node", ""))) == pattern and card.get("visible") == true and card.get("expanded") == expanded and card.get("leaving") == false:
			return true
	return false


func finding(kind: String, node: String, text_value: String, row: Dictionary) -> void:
	checks += 1
	var node_key := normalized_node(node)
	for i in known_entries.size():
		var entry: Dictionary = known_entries[i]
		if kind != entry.kind or node_key != entry.node or normalized(text_value) != entry.text: continue
		if kind == "transit-ISM" and (not recorded_card(row, entry.node, false) or not recorded_card(row, entry.folding_card, true) or not recorded_card(row, entry.accompanying_card, true)): continue
		known_hits[i] = int(known_hits.get(i, 0)) + 1
		known_kinds[kind] = int(known_kinds.get(kind, 0)) + 1
		return
	new_findings += 1
	check(false, "NEW %s node=%s text=%s" % [kind, node, JSON.stringify(text_value)])


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		var kind := why.get_slice(" ", 0)
		if kind in ["AI", "news", "template", "fallback"]: ai_failures += 1
		kinds[kind] = int(kinds.get(kind, 0)) + 1
		if kinds[kind] <= 4: print("FAIL " + why)


func advance_state(tick: int) -> void:
	while int(world.get("tick", -1)) < tick and not state_file.eof_reached():
		var line := state_file.get_line()
		if line.is_empty(): continue
		var row: Variant = JSON.parse_string(line)
		check(row is Dictionary, "invalid state evidence")
		if row is Dictionary and row.get("type") == "state":
			world.merge(row.changes, true)
			world["tick"] = row.tick
			for e: Dictionary in row.get("events", []):
				if e.get("k") == "ai_fallback" and e.get("reason") == "ai_numeral": fallback = true
				if e.get("k") == "ai_accepted" and e.get("kind") == "text": accepted[str(e.req)] = e.text
	check(int(world.get("tick", -1)) == tick, "missing frame state")


func audit(row: Dictionary) -> void:
	count += 1
	var view: Dictionary = row.get("view", {})
	var transit: bool = GalaxyMap.field_value(view, "journey.state") == "committed"
	var phase := str(GalaxyMap.field_value(view, "ship.phase"))
	phases[phase] = true
	if state_file != null:
		advance_state(int(view.get("tick", -1)))
		for section in ["ship", "clock", "journey", "consequence"]:
			check(view.get(section) == world.get(section), "frame state differs: " + section)
	var root_node := Node.new()
	var fields := {}
	for b: Dictionary in row.get("bindings", []):
		var binding: DisplayBinding
		var local_view := view.duplicate(false)
		if b.has("entry"): local_view["entry"] = b.entry
		if b.has("parts"):
			binding = ComposedBinding.new().compose(b.parts)
			for part in b.parts:
				if part is Array: check(GalaxyMap.field_value(local_view, part[0]) != null, "missing field " + part[0])
		elif b.has("map"):
			binding = NewsPanel.CopyBinding.new(); binding.map = b.map
		elif b.has("template"):
			binding = NewsPanel.TemplateText.new()
			binding.templates = NewsCopy.load_json(NewsCopy.TEMPLATES)
			binding.no_age_text = NewsCopy.load_json(NewsCopy.COPY).labels.body_no_age
			binding.no_age = NewsCopy.is_no_age(view.consequence.news.slots)
		else: binding = DisplayBinding.new()
		binding.bind(b.get("field", ""), b.get("fmt", "%s"))
		var present := not binding.field.is_empty() and GalaxyMap.field_value(local_view, binding.field) != null
		if not present: missing += 1
		check(present, "missing field " + binding.field)
		binding.update_from(local_view)
		if binding.text != b.get("text"): mismatches += 1
		check(binding.text == b.get("text"), "stale " + b.get("node", binding.field))
		binding.text = b.get("text", "")
		binding.set_meta("node", b.get("node", binding.field))
		root_node.add_child(binding)
		fields[binding.field] = true
	for l: Dictionary in row.get("labels", []):
		var label := Label.new(); label.text = l.get("text", ""); label.set_meta("node", l.get("node", "")); root_node.add_child(label)
	for bad in DisplayBinding.audit(root_node):
		if bad is DisplayBinding:
			check(false, "binding contract " + str(bad.get_meta("node")))
		else:
			unbound += 1
			finding("unbound", str(bad.get_meta("node")), bad.text, row)
	root_node.free()
	if transit:
		for f in ["clock.tau", "clock.year"]: check(fields.has(f), "transit missing " + f)
		if not fields.has("ship.ism.glow_w_m2"):
			var transit_node := ""
			for card: Dictionary in row.get("cards", []):
				if str(card.get("node", "")).ends_with("/Card_transit"): transit_node = card.node
			finding("transit-ISM", transit_node, "missing ship.ism.glow_w_m2", row)
	var lore: Dictionary = row.get("lore", {})
	if not lore.is_empty():
		var binding := LoreBinding.new(); binding.entry_id = lore.get("id", "")
		check(binding.check(lore.get("body", "")), "codex hash " + binding.entry_id)
		check(lore.get("rendered") == "[font_size=22][b]%s[/b][/font_size]\n\n%s" % [LoreLoader._inline(lore.title), LoreLoader.to_bbcode(lore.body)], "codex rendered body")
		lore_checks += 1
	var news: Dictionary = row.get("news", {})
	if not news.is_empty():
		news_checks += 1
		mode = row.get("ai_mode", "")
		var source: Variant = GalaxyMap.field_value(view, "consequence.news.body_source")
		var want: String = {"none": "template", "stub": "ai", "digits": "fallback"}.get(mode, "")
		# The template remains visible while the optional service is answering.
		check(source == want or (mode in ["stub", "digits"] and source == "template"), "AI body_source " + mode)
		if source == want: settled_news += 1
		check(not news.body.is_empty(), "AI body missing")
		if source == "ai":
			check(news.tag == "generated" and news.notice == "", "AI generated tag")
			check(news.body == accepted.get(str(view.consequence.news.ai_request_id)), "AI accepted body")
		elif source == "template": check(news.notice == "" and news.tag == "", "template notice")
		elif source == "fallback":
			check(not news.notice.is_empty() and news.reason.contains(NewsCopy.load_json(NewsCopy.COPY).reasons.ai_numeral), "fallback phrase")
			check(fallback and "ai_numeral" in " ".join(news.diagnostics), "fallback session event and notice code")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty(): print("FAIL missing samples"); quit(1); return
	load_known(args[2] if args.size() > 2 else "res://tests/fixtures/display_audit/known_findings.json")
	var f := FileAccess.open(args[0], FileAccess.READ)
	if f == null: print("FAIL missing samples"); quit(1); return
	state_file = FileAccess.open(args[0].get_base_dir().path_join("states.ndjson"), FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line()
		if line.is_empty(): continue
		var row: Variant = JSON.parse_string(line)
		if row is Dictionary: audit(row)
		else: check(false, "invalid sample")
	if args.size() < 2 or args[1] != "control":
		check(state_file != null, "missing state stream")
		check(count >= 500, "fewer than 500 samples")
		for p in ["at_rest", "boosting", "cruising", "braking"]: check(phases.has(p), "missing phase " + p)
		check(lore_checks > 0 and news_checks > 0, "missing lore/news samples")
		check(settled_news > 0, "AI mode never rendered")
		var events := FileAccess.open(args[0].get_base_dir().path_join("events.ndjson"), FileAccess.READ)
		var reads := 0
		if events != null:
			while not events.eof_reached():
				var line := events.get_line()
				if line.is_empty(): continue
				var e: Variant = JSON.parse_string(line)
				if e is Dictionary and e.get("type") == "read" and e.get("what") == "news":
					reads += 1
					check(e.get("body_source") == {"none": "template", "stub": "ai", "digits": "fallback"}.get(mode), "news read before mode resolved")
		check(reads > 0, "missing news read evidence")
	if not mode.is_empty():
		print("ai-mode: %s news_samples=%d settled=%d fallback=%s result=%s" % [mode, news_checks, settled_news, str(fallback), "PASS" if ai_failures == 0 and settled_news > 0 else "FAIL"])
	for i in known_entries.size():
		if not known_hits.has(i):
			stale_entries += 1
			check(false, "stale-known " + JSON.stringify(known_entries[i]))
	for kind: String in known_kinds: print("display-audit known: %s %d" % [kind, known_kinds[kind]])
	print("ac4: MET" if known_entries.is_empty() else "ac4: OPEN (%d known unbound, %d known transit-ISM)" % [known_kinds.get("unbound", 0), known_kinds.get("transit-ISM", 0)])
	var known_count := int(known_kinds.get("unbound", 0)) + int(known_kinds.get("transit-ISM", 0))
	print("display-audit: samples=%d checks=%d mismatches=%d missing=%d new=%d known=%d stale=%d failures=%d" % [count, checks, mismatches, missing, new_findings, known_count, stale_entries, failures])
	quit(1 if failures else 0)
