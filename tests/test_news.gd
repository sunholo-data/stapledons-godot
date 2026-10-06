extends SceneTree
## M4.4 news from home, the AI path, the return trip and the legacy screen (design
## m4-first-journey.md "M4.4"; sprint M4.4_NEWS_LEGACY). Headless:
##   godot --headless --path . --script tests/test_news.gd      (make news-test)
## Part A (no sim): templates, the numeral lint, the reason -> phrase table, the three panel
## renderings, the display audit. Part B (the real sim): a scripted session that arrives at alpha
## Cen, takes AI text, flies home through the map's commit ritual, takes a digits fixture, and
## reaches the legacy screen and "Begin again".

const FIX := "res://tests/fixtures/news/"
const WATCHDOG_S := 280.0
const CANCEL := ["offline", "no_key", "text_only", "timeout", "service_down", "budget", "provider_error"]
const RECORD := ["ai_hash", "ai_length", "ai_numeral", "ai_markup", "ai_emotion", "ai_descriptor", "ai_kind"]

var failures := 0
var checks := 0
var templates: Dictionary = NewsCopy.load_json(NewsCopy.TEMPLATES)
var copy: Dictionary = NewsCopy.load_json(NewsCopy.COPY)


func ok(name: String, cond: bool) -> void:
	checks += 1
	if not cond: failures += 1
	print("  %s  %s" % ["ok  " if cond else "FAIL", name])


func world(src: String, reason: Variant = null, req: Variant = null, tier := 0, tid := 1, star := "alpha Cen") -> Dictionary:
	var n := {"tier": tier, "tier_name": "x", "template_id": tid, "star_id": star,
		"slots": {"elapsed_years": 0.04398, "news_epoch": 0.04398, "news_age_years": 4.35}, "body_source": src}
	if reason != null:
		n["fallback_reason"] = reason
	if req != null:
		n["ai_request_id"] = req
	return {"consequence": {"news": n, "news_epoch": 0.04398}}


# ------------------------------------------------------------------ part A

func test_templates() -> void:
	ok("the real copy lints clean (%s)" % str(NewsCopy.lint(templates, copy)), NewsCopy.lint(templates, copy).is_empty())
	var fx := NewsCopy.load_json(FIX + "paragraphs.json")
	var all_ok := true
	for t in fx["tiers"]:
		for j in 4:
			var id: int = int(t["tier"]) * NewsCopy.PER_TIER + j
			var got := NewsCopy.paragraph(templates, id, {"elapsed_years": t["elapsed_years"], "news_epoch": fx["news_epoch"], "news_age_years": fx["news_age_years"]})
			if got != t["paragraphs"][j] or got == "" or got.length() > NewsCopy.MAX_CHARS:
				all_ok = false
				print("    template %d: got '%s'" % [id, got])
	ok("all five tiers x four templates fill to the fixture paragraphs, each at most 280 characters", all_ok and fx["tiers"].size() == 5)
	ok("a filled paragraph has digits only where a slot was", NewsCopy.has_digit(NewsCopy.paragraph(templates, 0, {"elapsed_years": 0.04, "news_epoch": 0.0, "news_age_years": 4.35})) and not NewsCopy.has_digit(NewsCopy.without_slots(templates["tiers"][0]["templates"][0])))
	# positive controls: the lint catches a stray digit, a missing tier, an over-long text, a digit in copy
	var bad := NewsCopy.load_json(FIX + "stray_digit.json")
	var found := NewsCopy.lint(bad, copy)
	ok("positive control: a digit outside a slot fails the lint (%s)" % str(found), found.size() == 1 and found[0].contains("numeral outside a slot"))
	var t2: Dictionary = templates.duplicate(true)
	t2["tiers"][2]["templates"][1] = t2["tiers"][2]["templates"][1].replace("A parent", "A parent aged 80")
	ok("positive control: a numeral spliced into a real template fails", not NewsCopy.lint(t2, copy).is_empty())
	var t3: Dictionary = templates.duplicate(true)
	t3["tiers"].pop_back()
	ok("positive control: four tiers fail", not NewsCopy.lint(t3, copy).is_empty())
	var t4: Dictionary = templates.duplicate(true)
	t4["tiers"][0]["templates"][0] = "x".repeat(300)
	ok("positive control: a paragraph over 280 characters fails", NewsCopy.lint(t4, copy).any(func(s): return s.contains("cap")))
	var c2: Dictionary = copy.duplicate(true)
	c2["labels"]["ai_tag"] = "generated 1"
	ok("positive control: a digit in a fixed label fails", not NewsCopy.lint(templates, c2).is_empty())
	ok("a template slot with no sim number yields no paragraph (never a wrong one)", NewsCopy.fill("Home {elapsed_years}", {}) == "" and NewsCopy.paragraph(templates, 99, {}) == "")
	# the files agree with the sim's own constants
	var sim_src := FileAccess.get_file_as_string("res://sim/consequence.ail")
	ok("PER_TIER is the sim's templatesPerTier", sim_src.contains("templatesPerTier() -> int = %d" % NewsCopy.PER_TIER))
	var names: Array = []
	for m in RegEx.create_from_string('"([^"]*)"').search_all("\n".join(sim_src.substr(sim_src.find("tierName(i: int)"), 300).split("\n").slice(0, 2))):
		names.append(m.get_string(1))
	ok("tier names are the sim's tierName (%s)" % str(names), names == templates["tiers"].map(func(t): return t["name"]))
	ok("the sim's news cap is 280", FileAccess.get_file_as_string("res://sim/ai.ail").contains('maxCharsFor(purpose: string) -> int = if purpose == "archive" then 600 else 280') and NewsCopy.MAX_CHARS == 280)


func test_reasons() -> void:
	var src := FileAccess.get_file_as_string("res://sim/ai.ail")
	var line := RegEx.create_from_string('cancelReasons\\(\\) -> \\[string\\] = \\[([^\\]]*)\\]').search(src).get_string(1)
	var sim_cancel: Array = []
	for m in RegEx.create_from_string('"([a-z_]*)"').search_all(line):
		sim_cancel.append(m.get_string(1))
	ok("the cancel reasons the table covers are the sim's cancelReasons (%s)" % str(sim_cancel), sim_cancel == CANCEL)
	ok("each record refusal the table covers is a code the sim emits", RECORD.all(func(c): return src.contains('"%s"' % c)) and src.contains('reason: "expired"'))
	var every: Array = CANCEL + RECORD + ["expired"]
	var all_ok := true
	for code: String in every:
		var p := NewsCopy.reason_phrase(copy, code)
		if p == "" or NewsCopy.has_digit(p):
			all_ok = false
			print("    reason %s: '%s'" % [code, p])
	ok("every known reason code has a non-empty, digit-free phrase", all_ok)
	ok("the table has no phrase for a code the sim cannot emit", copy["reasons"].keys().all(func(k): return every.has(k)))
	ok("the spec's two examples read as written", NewsCopy.reason_phrase(copy, "ai_numeral") == "the generated text contained a numeral" and NewsCopy.reason_phrase(copy, "expired") == "no reply in time")
	ok("an UNKNOWN reason fails loudly: no phrase, never a blank", NewsCopy.reason_phrase(copy, "made_up_reason") == "")
	var p := NewsPanel.new()
	root.add_child(p)
	p.show_world(world("fallback", "made_up_reason", "1"))
	ok("the panel shows an unknown reason as unknown and records an error", p.reason.text.contains("unknown") and p.errors.size() >= 1 and p.diagnostics.size() == 1 and p.diagnostics[0].contains("unknown reason"))
	p.queue_free()


func panel_with(view: Dictionary, events: Array = []) -> NewsPanel:
	var p := NewsPanel.new()
	root.add_child(p)
	p.on_events(events)
	p.show_world(view)
	return p


func test_renderings() -> void:
	var fx := NewsCopy.load_json(FIX + "snapshots.json")
	var notice: String = copy["labels"]["fallback_notice"]
	ok("the fallback notice is the fixed copy", notice == "Live transmission unavailable: archived text shown")
	var tpl := panel_with(world("template"))
	var ai := panel_with(world("ai", null, "1"), [{"k": "ai_accepted", "kind": "text", "req": "1", "text": "The world turned on without you."}])
	var fb := panel_with(world("fallback", "ai_numeral", "1"))
	ok("template: snapshot, no tag, no notice, no reason", tpl.snapshot() == fx["template"] and tpl.tag.text == "" and tpl.notice.text == "" and tpl.reason.text == "")
	ok("ai: snapshot, the small generated tag, the accepted text, no notice", ai.snapshot() == fx["ai"] and ai.tag.text == "generated" and ai.notice.text == "")
	ok("fallback: snapshot, the notice, the reason in words, the template text, a diagnostics entry", fb.snapshot() == fx["fallback"] and fb.notice.text == notice and fb.reason.text.contains("the generated text contained a numeral") and fb.tag.text == "")
	print("    template:  %s" % JSON.stringify(tpl.snapshot()))
	print("    ai:        %s" % JSON.stringify(ai.snapshot()))
	print("    fallback:  %s" % JSON.stringify(fb.snapshot()))
	ok("the header is from the sim's fields: Earth-year +0.04, already 4.35 years old", tpl.snapshot()["header"] == "Latest news from Earth: Earth-year +0.04, already 4.35 years old.")
	for p: NewsPanel in [tpl, ai, fb]:
		ok("audit: every number on the panel is a binding (%d)" % DisplayBinding.audit(p).size(), DisplayBinding.audit(p).is_empty())
	var hand := Label.new()
	hand.text = "4.35 years"
	tpl.add_child(hand)
	ok("positive control: a hand-set number on the panel fails the audit", DisplayBinding.audit(tpl) == [hand])
	# the sim decides: `ai` with no accepted text is an error, not a quiet template; `template` ignores any text seen
	var noaccept := panel_with(world("ai", null, "7"))
	ok("body_source ai without accepted text is a loud error", not noaccept.errors.is_empty())
	var ignores := panel_with(world("template", null, null), [{"k": "ai_accepted", "kind": "text", "req": "1", "text": "Smuggled."}])
	ok("body_source template shows the template even if text was seen (Godot never decides)", ignores.snapshot() == fx["template"])
	# diagnostics: one entry per item, kept across items
	fb.show_world(world("fallback", "ai_numeral", "1"))
	ok("one diagnostics entry per fallback item", fb.diagnostics.size() == 1)
	fb.show_world(world("fallback", "expired", "2", 2, 9, "Sol"))
	ok("a second item adds a second entry, in words", fb.diagnostics.size() == 2 and fb.diagnostics[1].contains("no reply in time") and fb.diagnostics.all(func(d): return not NewsCopy.has_digit(d)))
	fb.reset()
	ok("reset forgets the diagnostics", fb.diagnostics.is_empty())
	var nonews := panel_with({})
	ok("no news yet: the panel says so and shows no header", not nonews.header.visible and nonews.no_news.visible)
	for p in [tpl, ai, fb, noaccept, ignores, nonews]:
		p.queue_free()


class FakeRelay extends AiRelay:
	var opened: Array = []

	func open(kind: String, purpose: String, entity_id: String, _fields: Dictionary = {}) -> bool:
		opened.append([kind, purpose, entity_id])
		return true


func test_request_policy() -> void:
	var r := FakeRelay.new()
	r.enabled = true
	r.mode = "stub"
	var p := panel_with(world("template"))
	ok("AI on with a key: one news request is asked for", p.request_ai(r, world("template")) and r.opened == [["text", "news", "newswire"]])
	ok("never twice for the same item", not p.request_ai(r, world("template")) and r.opened.size() == 1)
	var off := FakeRelay.new()
	off.enabled = true
	off.mode = "off"
	var p2 := panel_with(world("template"))
	ok("AI off (D-8): nothing is asked, the template stands", not p2.request_ai(off, world("template")) and off.opened.is_empty())
	var nokey := FakeRelay.new()
	nokey.enabled = true
	nokey.mode = "stub"
	nokey.keys = []
	ok("no key for text (D-8): nothing is asked", not panel_with(world("template")).request_ai(nokey, world("template")) and nokey.opened.is_empty())
	ok("an item that already has a request is not asked again", not panel_with(world("template")).request_ai(r, world("template", null, "1")))


func test_legacy_line() -> void:
	var l := LegacyScreen.new()
	root.add_child(l)
	# gap_years deliberately NOT t - tau (7.56): a client that subtracts shows 7.56 and fails
	var v := {"clock": {"tau": 1.24, "t": 8.8, "year": 8.8, "age": 31.24}, "consequence": {"gap_years": 7.56, "news": {"star_id": "Sol"},
		"legacy": {"count": 2, "appended": [{"tick": 1, "kind": "arrival", "star_id": "Sol", "tau": 1.24, "t": 8.8, "gap_years": 7.56}, {"tick": 1, "kind": "news", "star_id": "Sol", "tau": 1.24, "t": 8.8, "gap_years": 7.56}]}},
		"journey": {"state": "arrived"}}
	l.show_world(v)
	ok("the closing line is the sim's clock.tau and clock.t, formatted", l.closing.text == "You were away 1.24 years. Home is 8.80 years older.")
	ok("it appears only when home (arrived at Sol)", l.visible and not LegacyScreen.is_home({"journey": {"state": "arrived"}, "consequence": {"news": {"star_id": "alpha Cen"}}}) and not LegacyScreen.is_home({"journey": {"state": "committed"}, "consequence": {"news": {"star_id": "Sol"}}}))
	ok("the entries are the sim's, folded once (a repeat adds none)", l.entries.size() == 2 and l.rows.size() == 2)
	l.show_world(v)
	ok("a re-sent section adds nothing", l.entries.size() == 2)
	ok("audit: the legacy screen is all bindings", DisplayBinding.audit(l).is_empty())
	l.show_world(v, true)
	ok("held back while the news panel is open", not l.visible)
	var src := FileAccess.get_file_as_string("res://ui/legacy_screen.gd") + FileAccess.get_file_as_string("res://ui/composed_binding.gd") + FileAccess.get_file_as_string("res://ui/news_panel.gd")
	ok("AC3: no save or load path in the new screens", RegEx.create_from_string("(?i)save_game|load_game|ResourceSaver").search(src) == null)
	l.queue_free()


# ------------------------------------------------------------------ part B

## The harness, feeding the legacy screen after every tick the way the interior does.
class SampleHarness extends TransitHarness:
	var on_tick := Callable()

	func refresh() -> void:
		super.refresh()
		if on_tick.is_valid():
			on_tick.call()


func ai_news(sim: SimBridge, p: NewsPanel, body: String, lg: LegacyScreen = null) -> Dictionary:
	var open_ok := sim.send([{"k": "ai_open", "kind": "text", "purpose": "news", "entity_id": "newswire"}], 0.0)
	var req := ""
	for e in sim.last_events:
		if e.get("k") == "ai_request":
			req = e["req"]
	p.on_events(sim.last_events)
	var rec_ok := sim.send([{"k": "record", "source": "ai", "req": req, "kind": "text", "sha256": body.sha256_text(), "body": body}], 0.0)
	p.on_events(sim.last_events)
	p.show_world(sim.world)
	if lg != null:
		lg.show_world(sim.world)
	return {"ok": open_ok and rec_ok and req != "", "req": req}


func test_session() -> void:
	var sim := SimBridge.new()
	sim.want_minor = 2
	if not sim.start() or not sim.new_game(0, "sol", false, Transit.new_game_params()):
		ok("sim starts (%s)" % sim.last_error, false)
		return
	var h := SampleHarness.new()
	root.add_child(h)
	var panel := NewsPanel.new()
	root.add_child(panel)
	var legacy := LegacyScreen.new()
	root.add_child(legacy)
	legacy.attach(sim)
	h.on_tick = func() -> void: legacy.show_world(sim.world)
	h.attach(sim)
	var res := h.run_session()
	ok("the scripted flight arrived at alpha Cen", res["ok"] and sim.world["journey"]["state"] == "arrived")
	legacy.show_world(sim.world)
	panel.show_world(sim.world)
	var n: Dictionary = sim.world["consequence"]["news"]
	ok("the sim made a news item: tier 0, template, no request yet", n["tier"] == 0 and n["body_source"] == "template" and not n.has("ai_request_id") and not n.has("fallback_reason"))
	var tpl := panel.snapshot()
	print("    session template: %s" % JSON.stringify(tpl))
	var want := NewsCopy.paragraph(panel.templates, int(n["template_id"]), n["slots"])
	ok("template rendering: the sim's template id and slots, header from fields, no tag, no notice", tpl["body"] == want and want != "" and tpl["notice"] == "" and tpl["tag"] == "" and tpl["header"] == "Latest news from Earth: Earth-year +%.2f, already %.2f years old." % [n["slots"]["news_epoch"], n["slots"]["news_age_years"]])
	ok("not home yet: no legacy screen", not legacy.visible)
	# the AI path: an accepted record -> body_source ai
	var r := ai_news(sim, panel, "The world turned on without you.", legacy)
	var snap := panel.snapshot()
	print("    session ai: %s" % JSON.stringify(snap))
	ok("ai rendering: body_source ai, the accepted text and the generated tag, no notice", r["ok"] and sim.world["consequence"]["news"]["body_source"] == "ai" and snap["body"] == "The world turned on without you." and snap["tag"] == "generated" and snap["notice"] == "")
	ok("audit: the live panel is all bindings", DisplayBinding.audit(panel).is_empty())
	# the way home: the map opens with Sol highlighted; the commit ritual again
	var map := GalaxyMap.new()
	root.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	map.attach(sim)
	map.auto_tick = false
	map.plan_home()
	ok("return trip: Sol is highlighted and planned", map.home_highlight and map._pending.get("target", {}).get("id") == "Sol")
	map.tick()
	ok("the sim planned the voyage home", map.journey_state() == "planned" and sim.world["journey"]["plan"]["target"]["id"] == "Sol")
	var plan_id := int(sim.world["journey"]["plan_id"])
	ok("the commit dialog opens on the sim's plan", map.open_commit_dialog())
	ok("a short press commits nothing", not map.hold_commit(0.5) and map._queue.is_empty())
	map.release_commit()
	map.close_commit_dialog()
	sim.send([{"k": "commit", "plan_id": plan_id + 40}], 0.0)
	ok("the sim still enforces the rule: a commit naming another plan is refused stale_plan", sim.last_refused.size() == 1 and sim.last_refused[0]["reason"] == "stale_plan" and map.journey_state() == "planned")
	ok("the ritual again: dialog, full hold, the commit for the plan shown", map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S + 0.05) and map._queue.size() == 1 and map._queue[0]["plan_id"] == plan_id)
	map.tick()
	legacy.show_world(sim.world)
	ok("committed to the voyage home", map.journey_state() == "committed")
	var n2 := 0
	while map.journey_state() == "committed" and n2 < 9000:
		n2 += 1
		h.tick(TransitHarness.TICK_DT)
	ok("arrived at Sol after %d ticks" % n2, map.journey_state() == "arrived" and sim.world["consequence"]["news"]["star_id"] == "Sol")
	legacy.show_world(sim.world)
	panel.show_world(sim.world)
	var m: Dictionary = sim.world["consequence"]["news"]
	ok("home: a new news item, tier 2 (5-15 Earth years), template again", m["tier"] == 2 and m["body_source"] == "template" and panel.snapshot()["notice"] == "")
	# the digits fixture: the sim closes the request ai_fallback{ai_numeral}; the panel says so
	var d := ai_news(sim, panel, "It was the year 2041.", legacy)
	var fb := panel.snapshot()
	print("    session fallback: %s" % JSON.stringify(fb))
	var fn: Dictionary = sim.world["consequence"]["news"]
	ok("fallback rendering: ai_numeral, the notice, the reason in words, the template text, a diagnostics entry", d["ok"] and fn["body_source"] == "fallback" and fn["fallback_reason"] == "ai_numeral" and fb["notice"] == "Live transmission unavailable: archived text shown" and fb["reason"] == "Reason: the generated text contained a numeral" and fb["body"] != "" and fb["tag"] == "" and panel.diagnostics.size() == 1 and panel.errors.is_empty())
	# the legacy screen, from the sim's clocks
	legacy.show_world(sim.world)
	var tau: float = sim.world["clock"]["tau"]
	var t: float = sim.world["clock"]["t"]
	ok("the legacy screen shows when home", legacy.visible)
	ok("the closing line is the sim's two clocks (%s)" % legacy.closing.text, legacy.closing.text == "You were away %.2f years. Home is %.2f years older." % [tau, t])
	ok("it is not the gap: the sim's gap_years differs from the second number shown", absf(float(sim.world["consequence"]["gap_years"]) - t) > 1.0)
	var log_kinds: Array = legacy.entries.map(func(e): return e["kind"])
	ok("the legacy entries are the sim's append-only log: both legs (%s)" % str(log_kinds.slice(0, 3)), log_kinds.count("commit") == 2 and log_kinds.count("arrival") == 2 and log_kinds.count("news") == 2 and legacy.entries.size() == int(sim.world["consequence"]["legacy"]["count"]))
	ok("audit: the legacy screen is all bindings (live)", DisplayBinding.audit(legacy).is_empty())
	# Begin again: a new voyage on the same sim, a new seed, nothing carried over
	var old_seed := sim.last_seed
	legacy.next_seed = func() -> int: return 12345
	var began := legacy.begin_again(sim)
	panel.reset()
	panel.show_world(sim.world)
	ok("Begin again: a new_game with a new seed (%d -> %d)" % [old_seed, sim.last_seed], began and sim.last_seed == 12345 and sim.last_seed != old_seed and sim.last_error == "")
	ok("a new voyage: tick 0, nothing planned, no news, no legacy, closed screens", sim.world["tick"] == 0 and sim.world["journey"]["state"] == "idle" and not sim.world["consequence"].has("news") and legacy.entries.is_empty() and not legacy.visible and panel.diagnostics.is_empty())
	var again := legacy.begin_again(sim)
	ok("the next Begin again never repeats the seed", again and sim.last_seed != 12345)
	sim.stop()
	for x in [h, panel, legacy, map]:
		x.queue_free()


func _init() -> void:
	create_timer(WATCHDOG_S).timeout.connect(func() -> void:
		print("news: watchdog expired (a script error above?)")
		quit(2))
	test_templates()
	test_reasons()
	test_renderings()
	test_request_policy()
	test_legacy_line()
	test_session()
	ok("all checks ran", checks >= 70)
	print("news: %d passed, %d failures" % [checks - failures, failures])
	quit(1 if failures > 0 else 0)
