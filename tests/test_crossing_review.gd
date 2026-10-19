extends SceneTree
## R2-INTERLUDE I3 (design interlude-card.md D2; AC9, AC10): the crossing review on the sim's own
## 2.10 frames (tests/fixtures/crossing_review/*.ndjson, recorded by tools/crossing_review_fixture.gd
## from the guided voyage). Headless, no sim:
##   which pages appear and in what order; empty pages omitted; the Hold page first while a hold
##   is open, and its Resume needs a confirming press (crew_resume); paging by Next/Back, the arrow
##   keys, Enter and the page dots; the only dismissal is the last page's Brake button;
##   portrait per moment follows the sim's emotion (fallback list), and mutating it changes the
##   face (AC10); crew text has no digits, fits 280 characters and has no scored words (AC9);
##   every Label showing a digit is a DisplayBinding / ComposedBinding over a sim field, and
##   mutating a field changes the page.
## Run:  make crossing-review-test

const FIX := "res://tests/fixtures/crossing_review/"
var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok: passes += 1
	else: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func rows(name: String) -> Array:
	var out: Array = []
	for line in FileAccess.get_file_as_string(FIX + name + ".ndjson").split("\n", false):
		out.append(JSON.parse_string(line))
	return out


## The view the demo hands the review: the sim's world plus the leg's name (hud_view's `review`).
func view_of(row: Dictionary) -> Dictionary:
	var v: Dictionary = row.world.duplicate(true)
	v["review"] = {"leg": row.leg, "target": row.target}
	return v


func texts(n: Node) -> Array:
	var out := []
	for c in n.find_children("*", "Label", true, false):
		if c.is_visible_in_tree(): out.append((c as Label).text)
	return out


## The face on the page being shown (every page is built; only the current one is visible).
func page_face(r: CrossingReview) -> TextureRect:
	var p: Node = r.find_child("Page_" + r.current(), true, false)
	return p.find_child("Face", true, false) if p != null else null


func buttons(n: Node) -> Dictionary:
	var out := {}
	for b in n.find_children("*", "Button", true, false):
		if b.is_visible_in_tree(): out[str(b.name)] = b
	return out


## Every page in turn: the audit (no unbound digit, every binding clean) and the crew text rules.
func audit_pages(r: CrossingReview, label: String) -> void:
	var bad := []
	var crew_bad := []
	var scored := []
	var words := RegEx.create_from_string("(?i)\\b(good|bad|score|scored|grade|rating|failed you)\\b")
	for i in r.page_ids().size():
		r.go(i)
		for b in DisplayBinding.audit(r):
			if b.is_visible_in_tree(): bad.append("%s: %s" % [r.current(), b.text])
		for l in r.find_children("*", "Label", true, false):
			if not l.is_visible_in_tree(): continue
			if words.search(l.text) != null: scored.append(l.text)
			if l.has_meta("crew_text") and (DisplayBinding._has_digit(l.text) or l.text.length() > 280): crew_bad.append(l.text)
			if l.has_meta("archive_text") and (DisplayBinding._has_digit(l.text) or l.text.length() > 600 + 20): crew_bad.append(l.text)
	check("%s: every label with a number is a clean binding, on every page %s" % [label, bad.slice(0, 3)], bad.is_empty())
	check("%s: crew text has no digits and fits 280 characters %s" % [label, crew_bad.slice(0, 2)], crew_bad.is_empty())
	check("%s: no scored words (good, bad, score) %s" % [label, scored.slice(0, 2)], scored.is_empty())


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var acen := rows("acen")
	var trap := rows("trappist")
	var nocrew := rows("nocrew")
	check("fixtures: Alpha Centauri has holds then its crossing; TRAPPIST-1 and Aldebaran crossed; a crossing with no crew",
		acen.size() >= 2 and acen[0].at == "hold" and acen.back().at == "crossed" and trap.filter(func(x): return x.at == "crossed").size() == 2 and nocrew.size() == 1 and nocrew[0].world.cruise.digest.crew == null)

	# I3 polish (A2): "You lived N days" and "Your crew lived N days" are one number (the crew's day clock).
	var days_bad := []
	for row in acen + trap:
		var dg: Variant = row.world.get("cruise", {}).get("digest")
		if dg is Dictionary and dg.crew is Dictionary and int(dg.time.ship_days) != int(dg.crew.counts.days):
			days_bad.append([row.at, dg.time.ship_days, dg.crew.counts.days])
	check("ship_days equals crew.counts.days in every recorded frame %s" % [days_bad], days_bad.is_empty())

	var r := CrossingReview.new()
	root.add_child(r)
	var crossed: Dictionary = acen.back()
	var v := view_of(crossed)
	var d: Dictionary = v.cruise.digest
	r.show_review(v, true)
	var moments: int = d.crew.moments.size()
	var want := ["crossing", "home", "aboard"]
	for i in moments: want.append("moment_%d" % i)
	if d.crew.movement.any(func(m): return float(m.moved) > 0.0): want.append("changed")
	want.append("medium")
	if not d.crew.waiting.is_empty(): want.append("waiting")
	check("pages in design order, empty ones omitted: %s" % [r.page_ids()], r.page_ids() == want and moments >= 3 and moments <= 7)
	check("no Hold page once the crossing is over and no hold is open", not r.page_ids().has("hold"))
	check("it opens on the first page", r.current() == "crossing")
	var t := texts(r)
	check("the crossing page: the leg, the speed and γ from the plan, the clocks from the digest (%s)" % [t],
		t.has("Alpha Centauri A") and t.any(func(s): return s.begins_with("0.999c · γ ")) and t.has("You lived %d days. %.2f years passed on Earth." % [int(d.time.ship_days), float(d.time.earth_years)]))
	audit_pages(r, "Alpha Centauri crossed")

	# Paging: Next/Back, the arrows, Enter, the dots; Brake only on the last page.
	r.go(0)
	var braked := [0]
	r.brake_pressed.connect(func() -> void: braked[0] += 1)
	r.key(KEY_RIGHT)
	check("→ turns to the next page", r.current() == "home")
	r.key(KEY_LEFT)
	r.key(KEY_LEFT)
	check("← turns back and stops at the first page", r.current() == "crossing")
	r.key(KEY_ENTER)
	check("Enter turns the page before the last", r.current() == "home" and braked[0] == 0)
	check("Brake is not offered before the last page", not buttons(r).has("Brake"))
	(r.find_child("Dot_%d" % (want.size() - 1), true, false) as Button).pressed.emit()
	check("a page dot goes to its page", r.current() == want.back())
	var bb := buttons(r)
	check("the last page brakes for the target (%s)" % [bb.keys()], bb.has("Brake") and (bb.Brake as Button).text == "Brake for Alpha Centauri A" and not bb.has("Next"))
	r.key(KEY_RIGHT)
	check("→ on the last page does not dismiss", braked[0] == 0 and r.current() == want.back())
	r.key(KEY_ENTER)
	check("Enter on the last page brakes", braked[0] == 1)
	(buttons(r).Brake as Button).pressed.emit()
	check("the Brake button brakes", braked[0] == 2)

	# Portraits: each moment's face is the sim's emotion through the fallback list (AC10).
	var faces_ok := true
	for i in moments:
		r.go(want.find("moment_%d" % i))
		var m: Dictionary = d.crew.moments[i]
		var face: TextureRect = page_face(r)
		faces_ok = faces_ok and face != null and face.texture != null and face.texture == CrewPage.face(str(m.actor), str(m.emotion)) and face.tooltip_text == str(m.emotion)
	check("each moment shows its speaker at the moment's emotion", faces_ok)
	var k := -1
	for i in moments:
		if str(d.crew.moments[i].actor) == "medic" and k < 0: k = i
	var v2 := v.duplicate(true)
	var before_face: Texture2D = CrewPage.face("medic", str(d.crew.moments[k].emotion))
	v2.cruise.digest.crew.moments[k].emotion = "happy" if str(d.crew.moments[k].emotion) != "happy" else "fearful"
	r.show_review(v2, true)
	r.go(want.find("moment_%d" % k))
	var face2: TextureRect = page_face(r)
	check("mutating a moment's emotion changes the face (%s -> %s)" % [d.crew.moments[k].emotion, v2.cruise.digest.crew.moments[k].emotion], face2.texture == CrewPage.face("medic", str(v2.cruise.digest.crew.moments[k].emotion)) and face2.texture != before_face)
	check("a role without the emotion shows its fallback face", CrewPage.face_path("engineer", "angry").ends_with("engineer_neutral.png"))
	# The aboard page: a face per member at their end-of-crossing emotion.
	r.go(want.find("aboard"))
	var row_ok := true
	for m: Dictionary in d.crew.movement:
		var f: TextureRect = r.find_child("Face_" + str(m.id), true, false)
		row_ok = row_ok and f != null and f.texture == CrewPage.face(str(m.id), str(m.emotion1))
	check("the aboard page shows every member at their end-of-crossing emotion", row_ok)

	# A field mutation changes the page (the clocks are bindings, not copies).
	var v3 := v.duplicate(true)
	v3.cruise.digest.time.ship_days = 71.0
	r.show_review(v3, true)
	r.go(0)
	check("mutating time.ship_days changes the crossing page", texts(r).any(func(s): return s.begins_with("You lived 71 days.")))
	check("the home page's tier line is the sim's, with its years bound (%s)" % [d.time.tier_line], (func() -> bool:
		r.go(r.page_ids().find("home"))
		return texts(r).has(str(d.time.tier_line) % int(d.time.years_at_home))).call())
	# The home pictures (ruling 2; R2-HOME-TIERS, D-86): sixteen tiers, each a pool of variants
	# tier<n>_v<k>.webp, every one 3:2 at 1536x1024, with variant 0 of every tier present.
	var sizes_ok := true
	var pool := 0
	for f: String in DirAccess.get_files_at(CrossingReview.HOME_DIR):
		if f.ends_with(".webp"):
			pool += 1
			var tx := CrossingReview.home_texture(CrossingReview.HOME_DIR.path_join(f))
			sizes_ok = sizes_ok and tx != null and tx.get_size() == Vector2(1536, 1024) and f.begins_with("tier") and f.contains("_v")
	for tier in CrossingReview.TIER_COUNT:
		sizes_ok = sizes_ok and CrossingReview.home_texture(CrossingReview.home_path(CrossingReview.HOME_DIR, tier, 0)) != null
	check("every tier's pool lands (%d pictures), 1536x1024 (3:2), as WebP with no PNG master in the tree (D-18)" % pool, sizes_ok and pool >= CrossingReview.TIER_COUNT
		and not DirAccess.get_files_at(CrossingReview.HOME_DIR).has("tier0_v0.png") and not FileAccess.file_exists("res://data/interlude/home/tier0.png"))
	var art: TextureRect = r.find_child("HomeImage", true, false)
	check("the Home page shows its tier's picture (the voyage's variant) as a cover over the whole panel", not r.home_art_missing() and r.home_art_shown() and art != null and art.is_visible_in_tree()
		and art.texture == CrossingReview.home_texture_for(CrossingReview.HOME_DIR, CrossingReview.picture_index(d.time), CrossingReview.picture_variant(d.time))
		and art.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED and art.offset_left == -CrossingReview.PAD and art.offset_right == CrossingReview.PAD)
	var col: Control = r.find_child("Page_home", true, false).find_child("HomeText", true, false)
	check("the home words sit in a column over the picture's left side, with a scrim", col != null and is_equal_approx(col.size_flags_stretch_ratio, CrossingReview.HOME_TEXT)
		and r.find_child("ScrimLeft", true, false) != null and (r.find_child("ScrimLeft", true, false) as Control).is_visible_in_tree())
	check("no stand-in caption, no placeholder", not texts(r).any(func(s): return s.contains("A picture of home is to come")) and r.find_child("HomePlaceholder", true, false) == null)
	r.go(0)
	check("the picture is the Home page's alone", not r.home_art_shown() and not art.is_visible_in_tree())
	# A missing tier picture: the words alone across the page, nothing broken.
	var rm := CrossingReview.new()
	rm.home_dir = "res://data/interlude/no_such_dir"
	root.add_child(rm)
	rm.show_review(v, true)
	rm.go(rm.page_ids().find("home"))
	var mcol: Control = rm.find_child("Page_home", true, false).find_child("HomeText", true, false)
	check("a missing tier picture falls back to the words alone", rm.home_art_missing() and not rm.home_art_shown() and texts(rm).has(str(d.time.tier_line) % int(d.time.years_at_home))
		and mcol.get_parent().get_child_count() == 1)
	audit_pages(rm, "missing home picture")
	rm.queue_free()
	test_home_tiers(r, v)

	# The Hold page: first while a hold is open; Resume needs a confirming press (crew_resume).
	var held: Dictionary = acen[0]
	var hv := view_of(held)
	var sent: Array = []
	r.intents.connect(func(list: Array) -> void: sent.append_array(list))
	r.show_review(hv, false)
	var h: Dictionary = held.world.crew.holds[0]
	check("a hold mid-crossing opens the review on the Hold page", r.page_ids()[0] == "hold" and r.current() == "hold")
	t = texts(r)
	check("the Hold page: who and the sim's hold words (%s)" % [h.line], t.has("%s %s" % [h.name, h.line]) and str(h.line) != "")
	var hf: TextureRect = page_face(r)
	check("the Hold page shows them strained (sad)", hf != null and hf.texture == CrewPage.face(str(h.actor), "sad"))
	check("so far: the crossing reviewable behind it (%s)" % [r.page_ids()], r.page_ids().has("crossing") and r.page_ids().has("aboard"))
	check("no Brake while the crossing is not over", (func() -> bool:
		for i in r.page_ids().size():
			r.go(i)
			if buttons(r).has("Brake"): return false
		return true).call())
	r.go(0)
	(buttons(r).Resume as Button).pressed.emit()
	check("one press on Resume queues nothing and arms the confirm", sent.is_empty() and (buttons(r).Resume as Button).text.begins_with("Confirm"))
	(buttons(r).Resume as Button).pressed.emit()
	check("the confirmed Resume is crew_resume for that hold", sent.size() == 1 and sent[0].k == "crew_resume" and JSON.parse_string(sent[0].line) == {"command": "resume", "hold": h.id})
	var crew_asked := [0]
	r.open_crew.connect(func() -> void: crew_asked[0] += 1)
	(buttons(r).CrewConsole as Button).pressed.emit()
	check("the Hold page offers the Crew console", crew_asked[0] == 1)
	audit_pages(r, "Alpha Centauri held")
	# Eval R2-INTERLUDE (3): a hold open with no digest yet (a session below the commit's first fold)
	# still shows the Hold page with its confirmed Resume; no number is left unbound.
	var nd := view_of(held)
	nd.cruise.erase("digest")
	var rn := CrossingReview.new()
	root.add_child(rn)
	var sent_nd: Array = []
	rn.intents.connect(func(list: Array) -> void: sent_nd.append_array(list))
	rn.show_review(nd, false)
	check("a hold without a digest still opens on the Hold page (%s)" % [rn.page_ids()], rn.page_ids() == ["hold"] and rn.current() == "hold" and buttons(rn).has("Resume"))
	(buttons(rn).Resume as Button).pressed.emit()
	(buttons(rn).Resume as Button).pressed.emit()
	check("its confirmed Resume is crew_resume for that hold", sent_nd.size() == 1 and sent_nd[0].k == "crew_resume")
	audit_pages(rn, "hold without a digest")
	rn.queue_free()
	# While crossing (no hold, not over): the progress view, nothing to dismiss.
	var mid := view_of(held)
	mid.crew.holds = []
	r.show_review(mid, false)
	check("between chunks the review is the progress view (%s)" % [r.page_ids()], r.page_ids() == ["crossing"] and texts(r).any(func(s): return s.begins_with("Crossing…")) and not buttons(r).has("Brake"))

	# Waiting for you: an open request in the digest is the last page, in words, with its face.
	var vw := v.duplicate(true)
	vw.cruise.digest.crew.waiting = [{"kind": "relief", "id": "relief-1", "actor": "medic", "name": "Samir Amari", "task": "t1-medic"}]
	r.show_review(vw, true)
	check("an open request adds Waiting for you as the last page", r.page_ids().back() == "waiting")
	r.go(r.page_ids().size() - 1)
	t = texts(r)
	check("the waiting page names who and what, and where to answer (%s)" % [t], t.has("Samir Amari asks to step back from their work.") and t.has("Answer them at the Crew console.") and r.find_child("Page_waiting", true, false).find_child("Face_medic", true, false) != null)

	# No crew: no crew pages.
	r.show_review(view_of(nocrew[0]), true)
	check("a crossing with no crew has no crew pages (%s)" % [r.page_ids()], not r.page_ids().any(func(p): return p in ["aboard", "changed", "waiting", "hold"] or p.begins_with("moment")) and r.page_ids().has("crossing") and r.page_ids().has("home"))
	audit_pages(r, "no crew")

	# TRAPPIST-1 then Aldebaran: the Earth years add up; the tier line moves with them.
	var tr: Array = trap.filter(func(x): return x.at == "crossed")
	r.show_review(view_of(tr[0]), true)
	r.go(0)
	check("the TRAPPIST-1 leg name is bound (it has a digit)", texts(r).has("TRAPPIST-1") and r.find_child("Leg", true, false) is DisplayBinding)
	audit_pages(r, "TRAPPIST-1")
	r.show_review(view_of(tr[1]), true)
	audit_pages(r, "Aldebaran")
	# Eval R2-INTERLUDE (1): two news ages, each unambiguous: news reaching the ship now, and the last
	# word received at its stop (written within days of departure: no "0.00 years").
	r.go(r.page_ids().find("home"))
	var ht := texts(r)
	var age_now := "News reaching the ship now left home %.1f years ago." % float(tr[1].world.cruise.digest.time.news_age_years)
	check("home: the news age now and the last word at its stop are told apart (%s)" % [ht], ht.has(age_now) and ht.has("The last word received, at your last stop:")
		and ht.any(func(s): return s.contains("within days of your departure")) and not ht.any(func(s): return s.contains("0.00 years")))
	var t0: Dictionary = tr[0].world.cruise.digest.time
	var t1: Dictionary = tr[1].world.cruise.digest.time
	check("Aldebaran's crossing is later at home than TRAPPIST-1's (%s, %s years)" % [t0.years_at_home, t1.years_at_home], float(t1.earth_year_total) > float(t0.earth_year_total) and int(t1.tier) >= int(t0.tier))
	test_narration(r, v)
	r.queue_free()
	await process_frame
	print("crossing-review: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func narration_label(r: CrossingReview, id: String) -> Label:
	r.go(r.page_ids().find(id))
	var p: Node = r.find_child("Page_" + id, true, false)
	return p.find_child("Narration", true, false) if p != null else null


## I4 (design D3, Rulings §6): the Archive's authored framing on pages 1 and 3, always; with live AI
## (and a key) one telling per crossing, asked with the digest as context, voiced once.
func test_narration(r: CrossingReview, v: Dictionary) -> void:
	var n: Dictionary = v.cruise.digest.narration
	r.narration = null
	r.show_review(v, true)
	var l1 := narration_label(r, "crossing")
	var l3 := narration_label(r, "aboard")
	check("I4 the crossing page carries the Archive's authored line (%s)" % n.key, l1 != null and l1.text == "The Archive: “%s”" % n.crossing)
	check("I4 the aboard page carries the Archive's authored line", l3 != null and l3.text == "The Archive: “%s”" % n.aboard)
	check("I4 the narration key and lines have no digits", not DisplayBinding._has_digit(str(n.key) + str(n.crossing) + str(n.aboard)))
	# When the Archive may be asked: live AI with a text route (the tests' stub counts), never off,
	# replay, without a key or without a relay (D-8).
	var live := AiRelay.new()
	live.enabled = true
	var off := AiRelay.new()
	off.enabled = true
	off.mode = "off"
	var replay := AiRelay.new()
	replay.enabled = true
	replay.mode = "replay"
	var keyless := AiRelay.new()
	keyless.enabled = true
	keyless.mode = "live"
	keyless.keys = []
	check("I4 the telling is asked only with live AI and a key", ArchiveNarration.can_open(live) and not ArchiveNarration.can_open(off) and not ArchiveNarration.can_open(replay)
		and not ArchiveNarration.can_open(keyless) and not ArchiveNarration.can_open(null))
	var quiet := ArchiveNarration.new()
	check("I4 live AI off: nothing is opened; the authored lines stand", not quiet.maybe_open(v, off, true) and off.queued() == 0 and quiet.crossing_text(v) == str(n.crossing))
	var later := AiRelay.new()
	later.enabled = true
	check("I4 live AI switched on while the review is open: the telling is still asked, once", quiet.maybe_open(v, later, true) and later.queued() == 1 and not quiet.maybe_open(v, later, true) and later.queued() == 1)
	var nr := ArchiveNarration.new()
	check("I4 nothing is asked before the crossing is over", not nr.maybe_open(v, live, false) and live.queued() == 0)
	check("I4 the crossing over: one telling is asked", nr.maybe_open(v, live, true) and live.queued() == 1 and nr.state == "waiting")
	check("I4 once per crossing", not nr.maybe_open(v, live, true) and live.queued() == 1)
	var o: Dictionary = live.take_intents()[0]
	var ctx: Dictionary = o.get("context", {})
	var typed := ctx.values().all(func(x): return x is String or (x is Array and (x as Array).all(func(y): return y is String)))
	check("I4 ai_open{text, purpose archive, entity archive} with the digest as context (%s)" % [ctx.keys()], o.k == "ai_open" and o.kind == "text" and o.purpose == "archive"
		and o.entity_id == "archive" and ctx.size() <= 8 and typed and ctx.get("narration") == n.key and ctx.get("question") == ArchiveNarration.QUESTION
		and ctx.has("crossing") and ctx.has("home") and ctx.has("canon") and (o.emotions as Array).all(func(e): return e in ["neutral", "happy", "sad", "angry", "fearful", "curious", "loving", "grieving"]))
	# The sim's events: the request, the accepted telling (recorded sim input), then its voice.
	var req_e := {"k": "ai_request", "req": "7", "kind": "text", "purpose": "archive", "context": ctx}
	var ask := ArchiveAsk.new()
	ask.state = "waiting"
	ask.on_events([req_e])
	check("I4 the Archive terminal's open question does not take the telling's request", ask.req == "")
	nr.on_events([req_e])
	check("I4 the telling's request id is noted", nr.req == "7")
	nr.on_events([{"k": "ai_accepted", "req": "7", "kind": "text", "text": "{curious} The crossing was long, Captain. {sad} Home has moved on without us."}])
	check("I4 the accepted telling, without its markers", nr.state == "told" and nr.telling == "The crossing was long, Captain. Home has moved on without us.")
	var vi: Array = live.take_intents()
	check("I4 the telling is voiced once: ai_open{voice} naming its line", vi.size() == 1 and vi[0].kind == "voice" and vi[0].purpose == "archive" and vi[0].entity_id == "archive" and vi[0].line_req == "7")
	r.narration = nr
	r.show_review(v, true)
	check("I4 page 1 shows the accepted telling", narration_label(r, "crossing").text == "The Archive: “The crossing was long, Captain. Home has moved on without us.”")
	check("I4 page 3 keeps the authored aboard line", narration_label(r, "aboard").text == "The Archive: “%s”" % n.aboard)
	audit_pages(r, "narrated")
	nr.on_events([{"k": "ai_request", "req": "8", "kind": "voice", "purpose": "archive", "line_req": "7"},
		{"k": "ai_accepted", "req": "8", "kind": "voice", "sha256": "ab".repeat(32), "descriptor": {}},
		{"k": "ai_accepted", "req": "7", "kind": "text", "text": "{neutral} Again."}])
	check("I4 the voice is noted; a repeat does not ask again", nr.voice_req == "8" and str(nr.voice.get("sha256")) == "ab".repeat(32) and live.queued() == 0 and nr.voiced == 1 and nr.telling.begins_with("The crossing was long"))
	check("I4 a voice not on disk plays nothing", nr.voice_path(AiCache.new()) == "")
	# A fallback (screened out, no key at the service, timeout): the authored line stands.
	var fb := ArchiveNarration.new()
	fb.maybe_open(v, live, true)
	live.take_intents()
	fb.on_events([{"k": "ai_request", "req": "9", "kind": "text", "purpose": "archive", "context": {"narration": n.key}}, {"k": "ai_fallback", "req": "9", "reason": "provider_error"}])
	check("I4 a fallback leaves the authored line", fb.state == "authored" and fb.crossing_text(v) == str(n.crossing) and live.queued() == 0)
	# The next crossing (a new commit: new begin clocks) is told afresh.
	var v2 := v.duplicate(true)
	v2.cruise.digest.time.tau0 = float(v.cruise.digest.time.tau0) + 1.0
	check("I4 the next crossing is asked again", nr.maybe_open(v2, live, true) and live.queued() == 1 and nr.crossing_text(v2) == str(n.crossing))
	live.take_intents()
	r.narration = null


## R2-HOME-TIERS (design home-tiers.md H2; AC8, AC10-AC12): the sixteen tiers and their variants.
func test_home_tiers(r: CrossingReview, v: Dictionary) -> void:
	var d: Dictionary = v.cruise.digest
	check("the recorded frames are 2.12: tier_count 16 and a variant beside the tier", int(d.time.get("tier_count", 0)) == CrossingReview.TIER_COUNT and d.time.has("variant"))
	# The choice of file.
	check("picture_index: the sim's tier at 16 tiers; an old 7-tier frame maps to its picture's place; clamped",
		CrossingReview.picture_index({"tier": 8.0, "tier_count": 16.0}) == 8 and CrossingReview.picture_index({"tier": 15.0, "tier_count": 16.0}) == 15
		and CrossingReview.picture_index({"tier": 5.0}) == 10 and CrossingReview.picture_index({"tier": 6.0}) == 13 and CrossingReview.picture_index({"tier": 1.0}) == 2
		and CrossingReview.picture_index({"tier": 40.0, "tier_count": 16.0}) == 15 and CrossingReview.picture_index({"tier": 9.0}) == 13 and CrossingReview.picture_index({}) == 0)
	check("picture_variant: the sim's variant at 16 tiers, 0 below 2.12", CrossingReview.picture_variant({"tier": 3.0, "tier_count": 16.0, "variant": 1.0}) == 1
		and CrossingReview.picture_variant({"tier": 3.0, "variant": 1.0}) == 0 and CrossingReview.picture_variant({"tier": 3.0, "tier_count": 16.0}) == 0)
	check("home_path names the variant's file", CrossingReview.home_path("res://x", 8, 1) == "res://x/tier8_v1.webp" and CrossingReview.home_path("res://x", 0) == "res://x/tier0_v0.webp")
	# The sim's 7 -> 16 map is the host's (sim/home_tiers.ail pictureOfSeven, the real AILANG).
	var out: Array = []
	var code := OS.execute(SimBridge.find_ailang(), PackedStringArray(["run", "--quiet", "--package-dir", ProjectSettings.globalize_path("res://sim"),
		"--entry", "pictureTable", "--args-json", "0", ProjectSettings.globalize_path("res://sim/home_tiers_test.ail")]), out, true)
	var sim_map := str(out[0] if out.size() > 0 else "").strip_edges()
	check("PICTURE_OF_SEVEN is the sim's pictureOfSeven (%s)" % sim_map, code == 0 and sim_map == ",".join(CrossingReview.PICTURE_OF_SEVEN.map(func(x): return str(x))))
	# An old 2.10 frame (kept as recorded) shows v0 of its picture's place in the sixteen.
	var legacy := rows("legacy_2_10_trappist").filter(func(x): return x.at == "crossed")
	var lt: Dictionary = legacy.back().world.cruise.digest.time
	r.show_review(view_of(legacy.back()), true)
	r.go(r.page_ids().find("home"))
	var art: TextureRect = r.find_child("HomeImage", true, false)
	check("a 2.10 frame (tier %d of seven) shows tier%d_v0.webp" % [int(lt.tier), CrossingReview.PICTURE_OF_SEVEN[int(lt.tier)]], not lt.has("tier_count")
		and art.texture == CrossingReview.home_texture(CrossingReview.home_path(CrossingReview.HOME_DIR, CrossingReview.PICTURE_OF_SEVEN[int(lt.tier)], 0)) and not r.home_art_missing())
	# A missing variant falls back to v0; a missing tier to the words alone.
	var tmp := "user://home_tiers_fallback"
	DirAccess.make_dir_recursive_absolute(tmp)
	for f: String in DirAccess.get_files_at(tmp): DirAccess.remove_absolute(tmp.path_join(f))
	DirAccess.copy_absolute(ProjectSettings.globalize_path(CrossingReview.home_path(CrossingReview.HOME_DIR, 8, 0)), ProjectSettings.globalize_path(tmp.path_join("tier8_v0.webp")))
	var rf := CrossingReview.new()
	rf.home_dir = tmp
	root.add_child(rf)
	var vf := v.duplicate(true)
	vf.cruise.digest.time.tier = 8.0
	vf.cruise.digest.time.variant = 1.0
	rf.show_review(vf, true)
	rf.go(rf.page_ids().find("home"))
	var fart: TextureRect = rf.find_child("HomeImage", true, false)
	check("a missing variant (tier8_v1) falls back to the tier's v0", not rf.home_art_missing() and rf.home_art_shown() and fart.texture == CrossingReview.home_texture(tmp.path_join("tier8_v0.webp")))
	vf.cruise.digest.time.tier = 9.0
	rf.show_review(vf, true)
	rf.go(rf.page_ids().find("home"))
	check("a missing tier (no tier9_v*) gives the words alone", rf.home_art_missing() and not rf.home_art_shown() and texts(rf).has(str(vf.cruise.digest.time.tier_line) % int(vf.cruise.digest.time.years_at_home)))
	rf.queue_free()
	# The guided voyage's end. Mark's playtest (2026-10-19) reported about 150 Earth years and the drowned town
	# (old tier 5, 130-1000 years). Recorded here (seed 42, an orders crew under critical_only) it is about
	# 120 Earth years: tier 7 of sixteen (90-130, the plain memorial), never the drowned town (tier 10).
	var tour := rows("tour").filter(func(x): return x.at == "crossed")
	var last: Dictionary = tour.back().world.cruise.digest.time if not tour.is_empty() else {}
	check("the tour's last crossing (%s Earth years) is tier 7 of sixteen, not the drowned town" % [last.get("earth_year_total")], tour.size() == 3 and int(last.get("tier", -1)) == 7
		and float(last.earth_year_total) >= 90.0 and float(last.earth_year_total) < 130.0 and CrossingReview.picture_index(last) != 10)
	r.show_review(view_of(tour.back()), true)
	r.go(r.page_ids().find("home"))
	check("the tour's end shows tier7_v%d" % int(last.get("variant", 0)), r.find_child("HomeImage", true, false).texture == CrossingReview.home_texture(CrossingReview.home_path(CrossingReview.HOME_DIR, 7, int(last.get("variant", 0)))))
	audit_pages(r, "tour end")
