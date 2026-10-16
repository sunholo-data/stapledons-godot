extends SceneTree
## R2-CREW C6 (AC10): the Voyage console's Crew page (ui/crew_page.gd) bound to a crew section
## recorded from the real sim (tests/crew/console_state.json: seed 1, orders, the medic asking for
## relief, the analyst carrying on). It shows the crew and its actions emit the right crew intents;
## decisions need a confirming press (no twitch); the intents it builds are accepted by the real sim.
## Run:  make crew-console-test

var failures := 0

func check(label: String, ok: bool) -> void:
	if not ok: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])

func texts(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is Label: out.append((c as Label).text)
		if c is Button: out.append((c as Button).text)
		out.append_array(texts(c))
	return out

func line_of(intent: Dictionary) -> Dictionary:
	return JSON.parse_string(intent["line"])

func _initialize() -> void:
	var section: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/crew/console_state.json"))
	var page := CrewPage.new()
	root.add_child(page)

	page.show_crew({})
	check("no crew: the page says so", texts(page) == ["No crew aboard yet."])

	page.show_crew(section)
	var all := texts(page)
	check("five crew rows", page.get_children().filter(func(c): return c.name.begins_with("Member_")).size() == 5)
	check("generated name with the role (D-74): Ligaya Reyes · The Medic", all.has("Ligaya Reyes · The Medic"))
	check("captaincy shown, the switch offers consent", all.has("Captaincy: orders") and all.has("Switch to consent"))
	var medic := page.get_node("Member_medic")
	check("stress, fatigue and trust bars for the medic", medic.find_child("Bar_stress", true, false) != null and medic.find_child("Bar_fatigue", true, false) != null and medic.find_child("Bar_trust", true, false) != null)
	# Portraits (trial): every member has a face; the medic asked for relief, so the medic's face
	# is the strained one (sad -> grieving); the call panel shows the last speaker, the analyst.
	var faces := ["medic", "engineer", "analyst", "pilot", "counselor"].filter(func(id): var t = page.find_child("Portrait_" + id, true, false); return t is TextureRect and t.texture != null)
	check("every crew row has a portrait", faces.size() == 5)
	check("the medic asked for relief: her sad face", page.emotion_of("medic") == "sad" and page.portrait_path("medic", "sad").ends_with("medic_sad.png") and page.find_child("Portrait_medic", true, false).texture == page.portrait("medic", "sad"))
	check("the medic has all eight emotions; a decline shows anger, a concern fear", ["neutral", "happy", "sad", "angry", "fearful", "curious", "loving", "grieving"].all(func(e): return page.portrait_path("medic", e).ends_with("medic_%s.png" % e)) and CrewPage.LABEL_EMOTION["decline"] == "angry" and CrewPage.LABEL_EMOTION["concern"] == "fearful")
	check("an angry face falls back to neutral for a role without it", page.portrait_path("engineer", "angry").ends_with("engineer_neutral.png"))
	check("a role without the emotion falls back to its neutral face", page.portrait_path("analyst", "sad").ends_with("analyst_neutral.png"))
	var call := page.get_node_or_null("Call")
	check("the call panel shows the last speaker, larger, with their words", call != null and texts(call).has("Santiago Navarro · The Analyst") and call.find_child("CallPortrait", true, false).texture != null)
	var trust: ProgressBar = medic.find_child("Bar_trust", true, false).get_child(1)
	check("trust bar reads the sim's trust (50)", trust.value == 50.0 and not trust.show_percentage)
	check("the medic's latest line is the relief template until the AI words arrive", page.latest_line("medic") == "I need to step back from this for a while.")
	page.set_ai_text("1", "I'm running on empty, Captain. I need a few days.")
	check("accepted AI words replace the template", page.latest_line("medic") == "I'm running on empty, Captain. I need a few days." and page.latest_line("analyst") == "I can keep going for now.")
	page.on_events([{"k": "ai_accepted", "req": "2", "kind": "text", "text": "Still fine here."}, {"k": "ai_accepted", "req": "99", "kind": "text", "text": "Archive words."}])
	check("ai_accepted events for crew lines are taken; others ignored", page.latest_line("analyst") == "Still fine here." and not page.ai_text.has("99"))
	check("the relief request has Grant and Deny", page.find_child("Grant_relief-c1", true, false) != null and page.find_child("Deny_relief-c1", true, false) != null)
	check("working crew show their work in words, idle crew can be offered work", texts(medic).any(func(t): return t.begins_with("Working on Record the household messages: day ")) and page.get_node("Member_engineer").find_child("Offer_engineer", true, false) != null)
	# crew-work W1: the work card says what is offered, why, how long, what it needs and costs.
	var eng := texts(page.get_node("Member_engineer"))
	check("an idle member's card names the work and its terms", eng.has("Seal the drive for the first leg") and eng.any(func(t): return t.contains("Takes three days. Needs one archive compute slot, free mass (used up).") and t.contains("Readies them")))
	check("the ship's resources show free of total", (page.get_node("Resources") as Label).text.begins_with("Ship: ") and (page.get_node("Resources") as Label).text.contains("free of"))
	page._last_actor = "pilot"
	page.on_refused([{"i": 0, "reason": "crew:blocked:insufficient_resource:compute"}])
	check("a blocked start says why, in words, on that member", texts(page.get_node("Member_pilot")).any(func(t): return t.begins_with("Couldn't start: not enough archive compute slots free.")))
	check("no numbers on the page but the names (D-21: numbers come from sim fields)", texts(page).all(func(t): return not RegEx.create_from_string("[0-9]").search(t)))

	var got := []
	page.intents.connect(func(l): got.append(l))
	var offer := page.press("offer:engineer")
	check("offer work is one press: offer + ask for the engineer", offer.size() == 2 and offer[0]["k"] == "crew_offer" and offer[1]["k"] == "crew_ask"
		and line_of(offer[0])["worker"] == "engineer" and line_of(offer[0])["recipe"] == "work_engineer" and line_of(offer[1])["task"] == line_of(offer[0])["id"])
	var first := page.press("relief:relief-c1:true")
	check("granting relief needs a second press", first.is_empty() and (page.find_child("Grant_relief-c1", true, false) as Button).text == "Confirm: Grant relief")
	var grant := page.press("relief:relief-c1:true")
	check("the confirmed grant is resolve_relief release true", grant.size() == 1 and grant[0]["k"] == "crew_relief" and line_of(grant[0]) == {"command": "resolve_relief", "id": "relief-c1", "release": true})
	page.press("policy:consent")
	page.press("relief:relief-c1:false")
	check("a different action disarms the first (no stray confirm)", page.armed == "relief:relief-c1:false")
	page.press("policy:consent")
	var pol := page.press("policy:consent")
	check("switching to consent is a confirmed crew_policy", pol.size() == 1 and pol[0]["k"] == "crew_policy" and line_of(pol[0]) == {"command": "policy", "policy": "consent"})
	var offered := section.duplicate(true)
	offered["members"][1]["work"] = {"task": "t9", "recipe": "work_engineer", "status": "offered"}
	page.show_crew(offered)
	page.press("start:t9")
	var st := page.press("start:t9")
	check("starting offered work is a confirmed crew_start", st.size() == 1 and line_of(st[0]) == {"command": "start_task", "task": "t9"})
	check("every emitted list reached the intents signal", got.size() == 4)

	# The real sim accepts what the page builds (same seed and orders as the recording).
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.CREW_MINOR
	var ok := sim.start() and sim.new_game(1, "free_nav", false, {}, "", "orders")
	page.show_crew(sim.crew)
	ok = ok and sim.send(page.press("offer:pilot"), 0.0)
	check("the sim accepts the page's offer and ask", ok and sim.last_refused.is_empty() and sim.crew["lines"].size() == 1 and sim.crew["lines"][0]["actor"] == "pilot")
	# The console's path: the page's intents queue on the bridge and ride the next tick (SimBridge.queue).
	page.show_crew(sim.crew)
	page.intents.connect(sim.queue)
	page.press("offer:counselor")
	check("queued intents wait for the next tick", sim.queued.size() == 2)
	ok = sim.send([], 0.0)
	check("the next tick carries them and clears the queue", ok and sim.queued.is_empty() and sim.last_refused.is_empty() and sim.crew["lines"].size() == 2 and sim.crew["lines"][1]["actor"] == "counselor")
	# crew-work W1: the ship has two Archive compute slots; a third compute user is blocked, and the
	# real sim says why (crew:blocked:insufficient_resource:compute), which the page words on the pilot.
	page.intents.disconnect(sim.queue)
	page.show_crew(sim.crew)
	ok = sim.send(page.offer_intents("engineer") + page.offer_intents("analyst"), 0.0)
	var task_of := func(id: String) -> String:
		for m in sim.crew["members"]:
			if m["id"] == id and m.get("work") is Dictionary: return str(m["work"]["task"])
		return ""
	for id in ["engineer", "analyst"]:
		ok = ok and sim.send([SimBridge.crew_intent("crew_start", {"command": "start_task", "task": task_of.call(id)})], 0.0) and sim.last_refused.is_empty()
	check("two compute users start", ok and sim.crew["members"].filter(func(m): return m.get("work") is Dictionary and m["work"]["status"] == "working").size() == 2)
	page.show_crew(sim.crew)
	page.press("start:" + task_of.call("pilot"))
	var third := page.press("start:" + task_of.call("pilot"))
	ok = sim.send(third, 0.0)
	check("the third is blocked, and the sim says why", ok and sim.last_refused.size() == 1 and str(sim.last_refused[0].get("reason", "")) == "crew:blocked:insufficient_resource:compute")
	page.on_refused(sim.last_refused)
	check("the page says so on the pilot, naming who holds the slots", texts(page.get_node("Member_pilot")).any(func(t): return t.begins_with("Couldn't start: not enough archive compute slots free.") and t.contains(" are using them.")))
	page.show_crew(sim.crew)
	check("working crew show day one of their work", texts(page.get_node("Member_engineer")).any(func(t): return t.begins_with("Working on Seal the drive for the first leg: day one of three.")))
	sim.stop()

	# crew_core 0.4.1: a concern the captain can answer sits on the member's card, with one confirmed
	# button per approach; the reply is crew_reply (captain_reply) and the real sim accepts it.
	var cs := SimBridge.new()
	cs.want_minor = SimBridge.CREW_MINOR
	ok = cs.start() and cs.new_game(1, "free_nav", false, {}, "", "consent")
	var cp := CrewPage.new()
	root.add_child(cp)
	cp.show_crew(cs.crew)
	var offers: Array = []
	for id in ["medic", "engineer", "analyst", "pilot", "counselor"]:
		offers.append_array(cp.offer_intents(id))
	ok = ok and cs.send(offers, 0.0)
	cp.show_crew(cs.crew)
	var concern: Dictionary = {}
	for q in cs.crew.get("concerns", []):
		if q["actor"] == "pilot": concern = q
	check("the pilot's concern is open, with reply options", ok and not concern.is_empty() and concern["options"].size() >= 3)
	var pilot_texts := texts(cp.get_node("Member_pilot"))
	check("the card names the concern and offers each approach", pilot_texts.any(func(t): return t.begins_with("Anh Rahman raised a concern:") or t.contains(" raised a concern: ")) and cp.find_children("Reply_%s_*" % concern.get("issue", "x"), "Button", true, false).size() == concern.get("options", []).size())
	var action := "reply:%s:%s" % [concern.get("issue", ""), str(concern.get("options", [{}])[0].get("approach", ""))]
	check("a reply needs a second press", cp.press(action).is_empty())
	var reply := cp.press(action)
	check("the confirmed reply is one crew_reply (captain_reply) at the crew's tick and revision", reply.size() == 1 and reply[0]["k"] == "crew_reply" and line_of(reply[0])["command"] == "captain_reply" and line_of(reply[0])["issue"] == concern.get("issue") and int(line_of(reply[0])["revision"]) == int(cs.crew["revision"]))
	ok = cs.send(reply, 0.0)
	check("the sim accepts the reply", ok and cs.last_refused.is_empty())
	cs.stop()
	print("crew-console: %d failures" % failures)
	quit(1 if failures else 0)
