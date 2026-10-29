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
# Context-only client paths with no frame source. target_name is a star name from names.json,
# never a numeral; make ui (map_text_identity.json) pins its text.
const CONTEXT_ONLY := ["client.map.target_name"]
# Context-only client paths whose producer value is looked up from the frame or the catalogue.
const CONTEXT_SOURCED := ["client.map.target_id", "client.map.distance_ly", "client.map.count", "client.map.radius_pc", "client.map.rate", "client.map.hold_s", "client.archive.unlocked_count", "client.crew.working", "client.crew.status", "client.map.empty", "client.archive.empty", "client.crew.empty", "client.comms.empty"]
# R2-CREW-CONSOLE-V2 V7: the Crew console's own call state (who is on the call, what is on its
# way, the inline Ask or Order, refusal words, the captain's words, accepted AI words) is client
# state with no frame source: context-only, under these prefixes.
const CONTEXT_ONLY_PREFIX := ["client.crew.call", "client.crew.sending.", "client.crew.how.", "client.crew.notice.", "client.crew.said.", "client.crew.ai_text."]
var crew_seen := {}
var comms_seen := {} # R3-EARTH-LINK EL3: listen:in, listen:<reason>, log, and the panes' bindings
var stars_header: Dictionary = {}
var stars: Array = []
var review_seen := {}
var review_listed := {}


func normalized(text_value: String) -> String:
	return digits.sub(text_value, "N", true)


func normalized_node(node: String) -> String:
	# Creation-order suffixes are unstable; named segments and class names are exact.
	var segments := node.split("/")
	for i in segments.size():
		segments[i] = generated_segment.sub(segments[i], "@$1")
	return "/".join(segments)


func ruling_valid(entry: Dictionary) -> bool:
	if not entry.has("accepted_by"): return true
	if not entry.accepted_by is String: return false
	var cards := "/root/ShipGeometryDemo/@CanvasLayer/@Control/Cards/"
	match entry.accepted_by:
		"D-77":
			return entry.kind == "transit-ISM" and entry.node == cards + "Card_transit" and entry.text == "missing ship.ism.glow_w_mN" and entry.get("folding_card") == cards + "Card_medium_notice" and entry.get("accompanying_card") == cards + "Card_notice"
		"D-78":
			return entry.kind == "unbound" and entry.node == "/root/ShipGeometryDemo/@Window/GalaxyMap/@CanvasLayer/@PanelContainer/@VBoxContainer/MapDetails/@VBoxContainer/@GridContainer/@Label" and entry.text in ["Cruise N - beta", "N - beta", "  its N - beta", "Grains swept (>= N um)"]
	return false


func ac4_verdict() -> String:
	var accepted_count := 0
	for finding_entry: Dictionary in known_entries:
		if finding_entry.has("accepted_by"): accepted_count += 1
	if known_entries.is_empty(): return "ac4: MET"
	if accepted_count == known_entries.size():
		return "ac4: MET (%d accepted by D-77/D-78)" % accepted_count
	return "ac4: OPEN (%d unaccepted known, %d accepted by D-77/D-78)" % [known_entries.size() - accepted_count, accepted_count]


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
		if not ruling_valid(entry):
			check(false, "known-ruling invalid acceptance"); continue
		var key := JSON.stringify([entry.kind, entry.node, entry.text])
		check(not keys.has(key), "known-file duplicate entry " + key)
		keys[key] = true
		known_entries.append(entry)


func load_stars(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	var document: Variant = JSON.parse_string(f.get_as_text()) if f != null else null
	if not document is Dictionary or not document.get("stars") is Array:
		check(false, "stars-file invalid " + path); return
	stars = document.stars
	stars_header = {"count": document.get("count"), "radius_pc": document.get("radius_pc")}


func context_leaves(node: Dictionary, prefix: String, out: Array) -> void:
	for k: String in node:
		var p: String = k if prefix.is_empty() else prefix + "." + k
		if node[k] is Dictionary: context_leaves(node[k], p, out)
		else: out.append(p)


func parts_read(b: Dictionary, field: String) -> bool:
	for part: Variant in b.get("parts", []):
		if part is Array and part[0] == field: return true
	return false


## The catalogue entry a frame's target resolves to, as galaxy_map.gd _refresh_view resolves it.
func catalogue_star(view: Dictionary) -> Variant:
	var target: Variant = GalaxyMap.field_value(view, "journey.plan.target")
	if not target is Dictionary: return null
	var i := int(target.get("index", -1))
	if i < 0 or i >= stars.size() or stars[i].get("id") != target.get("id") or not stars[i].has("dist_ly"): return null
	return stars[i]


func working_crew(view: Dictionary) -> int:
	var members: Variant = GalaxyMap.field_value(view, "crew.members")
	if not members is Array: return 0
	var n := 0
	for m: Variant in members:
		if m is Dictionary and m.get("work") is Dictionary and str(m.get("work").get("status", "")) == "working": n += 1
	return n


## The producer's value for a context-sourced path: lookups that mirror galaxy_map.gd and
## ship_consoles.gd, never a computation. Null means the path must be absent or mismatch.
func expected_source(p: String, view: Dictionary) -> Variant:
	var target: Variant = GalaxyMap.field_value(view, "journey.plan.target")
	var unlocked: Variant = GalaxyMap.field_value(view, "consequence.archive.unlocked")
	var crew: Variant = GalaxyMap.field_value(view, "crew")
	var star: Variant = catalogue_star(view)
	match p:
		"client.map.target_id": return target.get("id") if target is Dictionary else null
		"client.map.distance_ly": return float(star.get("dist_ly")) if star != null else null
		"client.map.count": return stars_header.get("count")
		"client.map.radius_pc": return stars_header.get("radius_pc")
		"client.map.rate": return GalaxyMap.field_value(view, "client.warp")
		"client.map.hold_s": return GalaxyMap.HOLD_S
		"client.archive.unlocked_count": return unlocked.size() if unlocked is Array else "no"
		"client.crew.working": return working_crew(view)
		"client.crew.status":
			if not crew is Dictionary or crew.is_empty(): return "no crew aboard yet"
			return "needs you" if not crew.get("holds", []).is_empty() else ""
		"client.map.empty", "client.archive.empty", "client.crew.empty", "client.comms.empty": return ""
	return null


## Cross-check a binding's recorded context with the frame view it was drawn from. Exact equality.
func check_context(node: String, b: Dictionary, view: Dictionary) -> void:
	var paths: Array = []
	context_leaves(b.context, "", paths)
	for p: String in paths:
		var recorded: Variant = GalaxyMap.field_value(b.context, p)
		var frame: Variant = GalaxyMap.field_value(view, p)
		if frame != null: check(recorded == frame, "context-drift %s %s" % [node, p])
		elif not p.begins_with("client."): check(false, "context-drift %s %s" % [node, p])
		elif p in CONTEXT_SOURCED: check(recorded == expected_source(p, view), "context-source %s %s" % [node, p])
		else: check(p in CONTEXT_ONLY or CONTEXT_ONLY_PREFIX.any(func(x: String) -> bool: return p.begins_with(x)), "context-unknown %s %s" % [node, p])
	if parts_read(b, "client.map.target_id"):
		# A catalogue target carries its distance, and only it does; Sol carries none.
		var expected := catalogue_star(view) != null
		var carried := GalaxyMap.field_value(b.context, "client.map.distance_ly") != null
		check(carried == expected and parts_read(b, "client.map.distance_ly") == expected, "context-presence %s client.map.distance_ly" % node)


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
		if b.has("context"):
			check(b.context is Dictionary, "invalid binding context")
			local_view = b.context if b.context is Dictionary else {}
			if b.context is Dictionary: check_context(str(b.get("node", b.get("field", ""))), b, view)
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
		# R3-EARTH-LINK EL3 (AC9), EL3b: every number on the comms station is an earth.* field.
		if str(b.get("node", "")).contains("/CommsStation/"):
			for part: Variant in b.get("parts", [[b.get("field", "")]]):
				if part is Array: check(str(part[0]).begins_with("earth."), "comms-field %s %s" % [b.get("node", ""), part[0]])
	for l: Dictionary in row.get("labels", []):
		var label := Label.new(); label.text = l.get("text", ""); label.set_meta("node", l.get("node", "")); root_node.add_child(label)
		# R2-CREW-CONSOLE-V2 V7: every Label on the Crew console is a binding, digits or not.
		check(not str(l.get("node", "")).contains("/CrewConsole/"), "crew-unbound %s %s" % [l.get("node", ""), JSON.stringify(l.get("text", ""))])
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
	# R2-INTERLUDE I3: which crossing-review pages this run showed (the interlude route checks all).
	var rv: Dictionary = row.get("review", {}) if row.get("review") is Dictionary else {}
	if not rv.is_empty():
		review_seen[str(rv.get("page", ""))] = true
		for p: Variant in rv.get("pages", []):
			if str(p) != "hold": review_listed[str(p)] = true
	var cr: Dictionary = row.get("crew", {}) if row.get("crew") is Dictionary else {}
	if not cr.is_empty():
		crew_seen["board" if str(cr.get("call", "")) == "" else "call:" + str(cr.get("state", ""))] = true
		crew_seen["bindings"] = int(crew_seen.get("bindings", 0)) + row.get("bindings", []).filter(func(b: Dictionary) -> bool: return str(b.get("node", "")).contains("/CrewConsole/")).size()
	var cm: Dictionary = row.get("comms", {}) if row.get("comms") is Dictionary else {}
	if not cm.is_empty():
		var key := "log" if str(cm.get("pane", "")) == "log" else ("listen:in" if cm.get("in_beam") == true else "listen:" + str(cm.get("reason", "")))
		comms_seen[key] = true
		if key == "log" and int(cm.get("lines", 0)) >= 2: comms_seen["log:rows"] = true
		comms_seen["bindings"] = int(comms_seen.get("bindings", 0)) + row.get("bindings", []).filter(func(b: Dictionary) -> bool: return str(b.get("node", "")).contains("/CommsStation/")).size()
		if bool(cm.get("feed", false)): comms_seen["feed"] = true
		if int(cm.get("faces", 0)) > 0: comms_seen["faces"] = true
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
	load_stars("res://data/starmap/stars.json")
	var f := FileAccess.open(args[0], FileAccess.READ)
	if f == null: print("FAIL missing samples"); quit(1); return
	state_file = FileAccess.open(args[0].get_base_dir().path_join("states.ndjson"), FileAccess.READ)
	while not f.eof_reached():
		var line := f.get_line()
		if line.is_empty(): continue
		var row: Variant = JSON.parse_string(line)
		if row is Dictionary: audit(row)
		else: check(false, "invalid sample")
	var route := args[1] if args.size() > 1 else "scene"
	if route == "interlude":
		# R2-INTERLUDE I3 (AC8): the guided crossing's playthrough (tests/playthrough_interlude.json).
		# Every sampled frame is audited as above against the same known file (a new finding fails);
		# this route has no map, news or codex screens, so their known entries are not expected here.
		check(state_file != null, "missing state stream")
		check(count >= 50, "fewer than 50 samples")
		check(phases.has("cruising"), "missing phase cruising")
		for p: String in review_listed: check(review_seen.has(p), "review page never sampled: " + p)
		check(review_listed.size() >= 3 and review_seen.has("hold"), "review pages and the Hold page sampled %s" % [review_seen.keys()])
		print("display-audit interlude: review pages sampled %d of %d %s" % [review_seen.size(), review_listed.size() + 1, review_seen.keys()])
		known_hits.clear()
		for i in known_entries.size(): known_hits[i] = 0
	elif route == "crew":
		# R2-CREW-CONSOLE-V2 V7 (AC14): the Crew console's playthrough (tests/playthrough_crew.json):
		# the board, a call in each state the crew reached, every frame audited as above.
		check(state_file != null, "missing state stream")
		check(crew_seen.has("board"), "crew board never sampled")
		var calls: Array = crew_seen.keys().filter(func(k: String) -> bool: return k.begins_with("call:"))
		check(calls.size() >= 3, "crew calls sampled in fewer than three states %s" % [calls])
		check(int(crew_seen.get("bindings", 0)) > 0, "no Crew console bindings sampled")
		print("display-audit crew: %s, %d console bindings" % [crew_seen.keys().filter(func(k): return k != "bindings"), int(crew_seen.get("bindings", 0))])
		known_hits.clear()
		for i in known_entries.size(): known_hits[i] = 0
	elif route == "comms":
		# R3-EARTH-LINK EL3 (AC9): the comms playthrough (tests/playthrough_comms.json): the Listen
		# pane in beam and out of it (the sim's reason), the Exchange log with two plans sent home.
		check(state_file != null, "missing state stream")
		for k in ["listen:in", "listen:not_heard", "log", "log:rows", "feed", "faces"]: check(comms_seen.has(k), "comms never sampled: " + k)
		check(int(comms_seen.get("bindings", 0)) > 0, "no comms bindings sampled")
		print("display-audit comms: %s, %d pane bindings" % [comms_seen.keys().filter(func(k): return k != "bindings"), int(comms_seen.get("bindings", 0))])
		known_hits.clear()
		for i in known_entries.size(): known_hits[i] = 0
	elif route != "control":
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
	print(ac4_verdict())
	var known_count := int(known_kinds.get("unbound", 0)) + int(known_kinds.get("transit-ISM", 0))
	print("display-audit: samples=%d checks=%d mismatches=%d missing=%d new=%d known=%d stale=%d failures=%d" % [count, checks, mismatches, missing, new_findings, known_count, stale_entries, failures])
	quit(1 if failures else 0)
