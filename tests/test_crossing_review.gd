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
	check("the home image is a placeholder until the per-tier art lands (flagged)", r.home_placeholder() == (not FileAccess.file_exists("res://data/interlude/home/tier%d.png" % int(d.time.tier))))

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
	var t0: Dictionary = tr[0].world.cruise.digest.time
	var t1: Dictionary = tr[1].world.cruise.digest.time
	check("Aldebaran's crossing is later at home than TRAPPIST-1's (%s, %s years)" % [t0.years_at_home, t1.years_at_home], float(t1.earth_year_total) > float(t0.earth_year_total) and int(t1.tier) >= int(t0.tier))
	r.queue_free()
	await process_frame
	print("crossing-review: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)
