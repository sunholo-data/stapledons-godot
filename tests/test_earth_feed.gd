extends SceneTree
## R3-EARTH-LINK EL3b.3 (design r3/earth-link.md EL3b): Earth's feed at the comms station.
## make earth-feed-test (in make ui). The feed shows the sim's earth.feed and never chooses:
##   picture  the week's event picture (pick among the library's variants), the procedural sky for
##            the sky kind or a week with no picture yet, and nothing changes between sim frames
##   beam     out of beam: the frame of the last beamed light (earth.last_feed) under static, the
##            ring filled by earth.out.progress, the caption "the last week that got through"
##   band     chosen by earth.rate: ghosts of the weeks that flicked past only in fast and torrent
##   bound    every number on it is a binding (tags, the ring, the clocks' rate)
##   live     EL3b.6: a painted-live week asks the AI relay once (a few per visit, with the week's
##            event, scene and era, nothing from the ship) and shows the painting once it is in the
##            player's library; painted frames join the event's pictures (the library grows)
##   sound    EL3b.7: the bed (category, sky, babble, static) and its pitch by band, the hold, the accents
## Time is the fake clock (advance(dt)); no wall-clock reads.

var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func feed(frame: int, kind: String, id: String, words: String, pick := 0) -> Dictionary:
	return {"frame": frame, "kind": kind, "event": {"id": id, "category": "town", "words": words}, "pick": pick,
		"context": {"era_tier": 0, "era_word": "launch", "years": 0.3, "influences": []}}


func view(over: Dictionary) -> Dictionary:
	var e := {"rate": 1.0, "rate_inverse": 1.0, "newest_light_t": 0.3, "newest_light_year": 0.3, "light_age_years": 4.2, "at_home": false,
		"in_beam": true, "sending": true, "last_beam_t": 0.3, "last_beam_year": 0.3, "out": null,
		"feed": feed(15, "library", "town-market", "market day", 3), "last_feed": feed(15, "library", "town-market", "market day", 3)}
	e.merge(over, true)
	return {"earth": e, "clock": {"tau": 0.1, "year": 4.5}}


func _run() -> void:
	# A fixture library, so the test does not depend on which pictures are shipped yet.
	EarthFeed._library = {"town-market": ["res://data/feed/pictures/town-market_v0.webp", "res://data/feed/pictures/town-market_v1.webp"]}
	check("a library week picks among the event's variants by the sim's pick", EarthFeed.source_of(feed(15, "library", "town-market", "market day", 3)) == "library:res://data/feed/pictures/town-market_v1.webp")
	check("a painted-live week shows the library until it is painted (EL3b.6)", EarthFeed.source_of(feed(15, "live", "town-market", "market day", 4)) == "library:res://data/feed/pictures/town-market_v0.webp")
	check("the sky kind is the sky over home, the same for a week", EarthFeed.source_of(feed(22, "sky", "town-market", "market day")) == "sky:22")
	check("a week with no picture yet shows the sky, never nothing", EarthFeed.source_of(feed(23, "library", "world-election", "election day")) == "sky:23")

	var root := Control.new()
	root.size = Vector2(640, 360)
	get_root().add_child(root)
	var f := EarthFeed.new()
	f.size = Vector2(640, 360)
	root.add_child(f)
	await process_frame
	var v := view({})
	f.refresh(v)
	check("in beam: the week's picture, no static, no ring", f.shown_key == EarthFeed.source_of(v.earth.feed) and f.picture.texture != null and not f.static_rect.visible and not f.ring.visible)
	check("the caption is the week's event (%s)" % f.caption.text, f.caption.text == "market day")
	check("the corner clock is bound (%s)" % f.clock_tag.text, f.clock_tag.text == "Earth +109.6 days · 4.20 yr old")
	var key := f.shown_key
	f.advance(10.0)
	check("nothing changes between sim frames: no timer of its own", f.shown_key == key)
	var cv := view({"feed": feed(16, "card", "town-market", "market day", 4)})
	f.refresh(cv)
	check("a news card week shows its words large", f.caption.text == "market day" and f.caption.get_theme_font_size("font_size") == 20)
	var sv := view({"feed": feed(17, "sky", "town-market", "market day")})
	f.refresh(sv)
	check("a sky week says so (%s)" % f.caption.text, f.caption.text == "the sky over home" and f.shown_key == "sky:17")

	# bands: ghosts of the flicked-past weeks only when D is fast; the tint warm or cool
	f.refresh(view({"rate": 14.107, "feed": feed(40, "library", "town-market", "market day", 5)}))
	f.refresh(view({"rate": 14.107, "feed": feed(41, "sky", "town-market", "market day")}))
	check("fast: ghosts of the weeks that flicked past", f.ghosts[0].visible and f.tint.visible and f.tint.color.b > f.tint.color.r)
	f.refresh(view({"rate": 0.070888, "feed": feed(42, "library", "town-market", "market day", 6)}))
	check("slow: no ghosts, a warm wash", not f.ghosts[0].visible and f.tint.visible and f.tint.color.r > f.tint.color.b)
	f.refresh(view({"rate": 1.0}))
	check("real time: no tint, no ghosts", not f.tint.visible and not f.ghosts[0].visible)

	# out of beam
	var out := view({"in_beam": false, "last_feed": feed(2, "library", "town-market", "market day", 3), "feed": feed(400, "library", "town-market", "market day", 7),
		"out": {"reason": "not_heard", "port_id": "CNS5:1676", "due_t": 17.29, "due_year": 17.29, "due_in_years": 8.3, "progress": 0.36}})
	f.refresh(out)
	f.advance(0.2)
	check("out of beam: the last beamed week under static", f.static_rect.visible and f.static_rect.texture != null and f.shown_key == EarthFeed.source_of(out.earth.last_feed))
	check("the ring fills by out.progress, its label bound (%s)" % f.ring.label.text, f.ring.visible and is_equal_approx(f.ring.fill, 0.36) and f.ring.label.text == "8.30 yr\nuntil Earth's voice")
	check("the caption: the last week that got through (%s)" % f.caption.text, f.caption.text == "market day · the last week that got through")
	check("no signal (%s)" % f.signal_tag.text, f.signal_tag.text == "no signal" and not f.clock_tag.visible)
	check("every number on the feed is a binding", DisplayBinding.audit(f).is_empty())

	# the clocks: hands straight from the sim's clocks; the rate bound
	var c := EarthClocks.new()
	root.add_child(c)
	c.refresh(view({"rate": 1414.2, "newest_light_t": 2.5}))
	check("the clocks: Earth's hand from the newest light, the ship's from clock.tau", is_equal_approx(c.earth_dial.turns, 2.5) and is_equal_approx(c.ship_dial.turns, 0.1))
	check("the torrent whirls Earth's hand (%s)" % c.rate.text, c.earth_dial.whirl and c.rate.text == "×1414" and DisplayBinding.audit(c).is_empty())
	# EL3b.4: the crew around the console at their home feelings
	var st := CommsStation.new()
	root.add_child(st)
	st.refresh(view({"crew": [{"id": "medic", "name": "Asha Rao", "feeling": "grieving"}, {"id": "pilot", "name": "Tomas Vidal", "feeling": "loving"}]}))
	var b0 := st.crew.get_child(0)
	check("each member's face at their feeling, the feeling and the name bound (%s, %s)" % [(b0.get_node("Feeling") as Label).text, (b0.get_node("Who") as Label).text],
		st.crew.visible and st.crew.get_child_count() == 2 and (b0.get_node("Face") as TextureRect).texture == CrewPage.face("medic", "grieving") and (b0.get_node("Feeling") as Label).text == "grieving" and (b0.get_node("Who") as Label).text == "Asha Rao")
	check("the pilot's warm face (loving)", (st.crew.get_child(1).get_node("Feeling") as Label).text == "warm" and (st.crew.get_child(1).get_node("Face") as TextureRect).texture == CrewPage.face("pilot", "loving") and CrewPage.face_path("pilot", "loving").ends_with("pilot_loving.png"))
	st.refresh(view({}))
	check("no crew aboard: no faces", not st.crew.visible)
	test_strip(st)
	st.queue_free()
	test_home_sound(root)
	await test_live(root)
	root.queue_free()
	await process_frame
	print("earth-feed: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


## EL3b.7: sound from home. The bed is the week's category (the sky's for the sky kind, babble in the
## torrent, static out of beam); a new week's bed waits for hold_s of the station's clock, a change of
## beam does not. AR8b (standing order 2026-10-30): the rates are the Earth rate D exactly at RS-26..RS-30;
## Receiver (the default) plays at D within 1/16x..16x and corrects the frequency by 1/speed; True plays
## speed and pitch x D and is silent outside hearing; accents come every every_s / D.
func test_home_sound(root: Control) -> void:
	var f := EarthFeed.new()
	root.add_child(f)
	var s: Dictionary = EarthFeed.copy().sound
	var week := func(frame: int, kind: String, cat: String) -> Dictionary:
		var w := feed(frame, kind, "x", "x")
		w.event.category = cat
		return w
	f.refresh(view({"feed": week.call(1, "library", "family")}))
	check("in beam at rest: the week's category bed at real time, uncorrected (%s)" % [f.home_sound], f.home_sound.cue == "home_family" and is_equal_approx(f.home_sound.rate, 1.0) and is_equal_approx(f.home_sound.correct, 1.0) and f.home_sound.accent == "home_family_tune" and f.receiver)
	# Receiver: [D, speed] at RS-28, RS-26, rest, RS-29, RS-30
	var rx := {7.0711e-4: 0.0625, 0.070888: 0.070888, 1.0: 1.0, 14.107: 14.107, 1414.2: 16.0}
	var ok := true
	for d: float in rx:
		f.refresh(view({"rate": d, "feed": week.call(1, "library", "family")}))
		ok = ok and is_equal_approx(f.home_sound.rate, rx[d]) and is_equal_approx(f.home_sound.correct, 1.0 / rx[d]) and not f.home_sound.silent
	check("Receiver: speed D exactly within 1/16x..16x (the receiver's real-time range), the frequency corrected by 1/speed", ok)
	f.set_receiver(false)
	ok = true
	for d: float in [0.070888, 1.0, 14.107]:
		f.refresh(view({"rate": d, "feed": week.call(1, "library", "family")}))
		ok = ok and is_equal_approx(f.home_sound.rate, d) and is_equal_approx(f.home_sound.correct, 1.0) and not f.home_sound.silent
	check("True: speed and pitch x D exactly (RS-26, rest, RS-29), uncorrected", ok)
	f.refresh(view({"rate": 7.0711e-4, "feed": week.call(1, "library", "family")}))
	var below: bool = f.home_sound.silent and f.home_sound.hearing == "below" and f.sound_button.text.contains("below hearing")
	f.refresh(view({"rate": 1414.2, "feed": week.call(1, "library", "family")}))
	check("True at the top speed: below hearing astern (RS-28), above it ahead (RS-30), and the station says so (%s)" % f.sound_button.text, below and f.home_sound.silent and f.home_sound.hearing == "above" and f.sound_button.text.contains("true sound") and DisplayBinding.audit(f).is_empty())
	f.set_receiver(true)
	check("back to Receiver: heard, corrected (%s)" % f.sound_button.text, not f.home_sound.silent and is_equal_approx(f.home_sound.rate, 16.0) and f.sound_button.text.contains("receiver"))
	f.sound_button.pressed.emit()
	check("the station's button switches the setting", not f.receiver)
	f.set_receiver(true)
	check("the torrent plays the babble once the hold is up, not yet (%s)" % f.home_sound.cue, f.home_sound.cue == "home_family")
	f.advance(float(s.hold_s))
	f.refresh(view({"rate": 1414.2, "feed": week.call(2, "library", "family")}))
	check("the torrent's bed is the babble (%s)" % f.home_sound.cue, f.home_sound.cue == "home_babble" and f.home_sound.accent == "")
	f.refresh(view({"rate": 1.0, "feed": week.call(3, "library", "town")}))
	check("a new week's bed waits for the hold (%s)" % f.home_sound.cue, f.home_sound.cue == "home_babble")
	f.advance(float(s.hold_s) - 0.5)
	f.refresh(view({"rate": 1.0, "feed": week.call(3, "library", "town")}))
	check("still held just before hold_s", f.home_sound.cue == "home_babble")
	f.advance(0.5)
	f.refresh(view({"rate": 1.0, "feed": week.call(3, "library", "town")}))
	check("after hold_s the town's bed and bells", f.home_sound.cue == "home_town" and f.home_sound.accent == "home_town_bells")
	f.refresh(view({"in_beam": false, "last_feed": week.call(3, "library", "town")}))
	check("out of beam: the static at once, the receiver's own hiss with no Doppler (%s)" % [f.home_sound], f.home_sound.cue == "home_static" and is_equal_approx(f.home_sound.rate, 1.0) and is_equal_approx(f.home_sound.correct, 1.0))
	f.refresh(view({"feed": week.call(4, "sky", "town")}))
	check("back in beam at once; the sky kind plays the sky's bed (%s)" % f.home_sound.cue, f.home_sound.cue == "home_sky")
	# accents: the first after first_s / D, then every every_s / D (home's own time at RS-26)
	f.advance(float(s.hold_s))
	f.refresh(view({"rate": 0.070888, "feed": week.call(5, "library", "town")}))
	var seq := int(f.home_sound.accent_seq)
	var first := float(s.first_s) / 0.070888
	var every := float(s.accents.home_town.every_s) / 0.070888
	f.advance(first - 0.05)
	var early := int(f.home_sound.accent_seq) == seq
	f.advance(0.1)
	var one := int(f.home_sound.accent_seq) == seq + 1
	f.advance(every - 0.1)
	var held := int(f.home_sound.accent_seq) == seq + 1
	f.advance(0.1)
	check("slowed home: the first bell after first_s / D = %.1f s, the next every_s / D = %.1f s later" % [first, every], early and one and held and int(f.home_sound.accent_seq) == seq + 2)
	f.refresh({"clock": {"tau": 0.1}})
	check("no Earth section: nothing plays", f.home_sound.cue == "")
	f.queue_free()


## EL3b.5: the exchange as light. A plan from home (heard at once, Earth's reply ahead of the ship),
## then a re-plan 4.37 ly out to a port 20 ly from home: its light home, Earth's reply out, the wait
## at the port; the ship is in flight (now 12), so the second leg's end is still to come.
func test_strip(st: CommsStation) -> void:
	var ms := [
		{"plan_id": 1, "port_id": "A", "from_ly": 0.00001, "port_ly": 4.37, "sent_t": 0.0, "heard_t": 0.0, "reply_t": 4.37, "arrive_t": 4.4},
		{"plan_id": 2, "port_id": "B", "from_ly": 4.37, "port_ly": 20.0, "sent_t": 5.0, "heard_t": 9.37, "reply_t": 29.37, "arrive_t": 25.0}]
	var v := view({"messages": ms, "newest_light_t": 2.0, "light_age_years": 10.0})
	v.clock["t"] = 12.0
	st.refresh(v)
	var s := st.strip
	var kinds := {}
	for el: Dictionary in s.elements: kinds[el.kind] = int(kinds.get(el.kind, 0)) + 1
	check("the station shows the strip under the feed", s.visible and s.get_parent() == st and s.get_index() == 1)
	check("both legs (the one in flight through the ship now), the stop between them, one plan's light home (the first was heard at once), two replies, one wait, the newest light (%s)" % [kinds],
		kinds == {"ship": 4, "plan": 1, "reply": 2, "wait": 1, "light": 1})
	var fields := [0.00001, 4.37, 20.0, 0.0, 9.37, 29.37, 4.4, 5.0, 25.0, 12.0, 10.0, 2.0]
	var bound := true
	for el: Dictionary in s.elements:
		for p: Vector2 in [el.a, el.b]:
			bound = bound and fields.any(func(x: float) -> bool: return is_equal_approx(p.x, x)) and fields.any(func(y: float) -> bool: return is_equal_approx(p.y, y))
	check("every endpoint is a sim field (sent, from, heard, reply, port, arrive, clock.t, the newest light)", bound)
	var wait: Dictionary = s.elements.filter(func(el: Dictionary) -> bool: return el.kind == "wait")[0]
	check("the wait: at the port from arrival until Earth's reply", is_equal_approx(wait.a.x, 25.0) and is_equal_approx(wait.b.x, 29.37) and is_equal_approx(wait.a.y, 20.0))
	check("the strip spans the first plan to the last reply, home to the farthest port", is_equal_approx(s.span.position.x, 0.0) and is_equal_approx(s.span.end.x, 29.37) and is_equal_approx(s.span.size.y, 20.0))
	s.size = Vector2(600, 116)
	var px := s.at(s.now)
	check("the ship now sits inside the strip (%s)" % px, px.x > 0.0 and px.x < 600.0 and px.y > 0.0 and px.y < 116.0)
	check("a picture: no words or numbers on it", s.get_child_count() == 0 and DisplayBinding.audit(s).is_empty())
	ms.append({"plan_id": 3, "from_ly": 20.0, "port_ly": 30.0, "sent_t": 26.0, "heard_t": 46.0, "reply_t": 76.0, "arrive_t": 40.0})
	ms.append({"plan_id": 4, "from_ly": 30.0, "port_ly": 31.0, "sent_t": 41.0, "heard_t": 71.0, "reply_t": 102.0, "arrive_t": 42.0})
	st.refresh(v)
	check("only the newest %d plans" % EarthStrip.SHOWN, s.elements.filter(func(el: Dictionary) -> bool: return el.kind == "reply").size() == EarthStrip.SHOWN)
	st.refresh(view({"messages": []}))
	check("no plans sent yet: no strip", not s.visible)


func test_live(root: Control) -> void:
	var dir := "user://earth_feed_test_cache"
	DirAccess.make_dir_recursive_absolute(dir)
	var cache := AiCache.new()
	cache.core_dir = "res://no_such_core"
	cache.library_dir = dir
	var relay := AiRelay.new(null, cache)
	relay.enabled = true
	relay.mode = "stub"
	relay.keys = ["gemini"]
	var g := EarthFeed.new()
	g.size = Vector2(640, 360)
	g.relay = relay
	root.add_child(g)
	g.begin_visit()
	g.refresh(view({"feed": feed(500, "live", "town-market", "market day", 1)}))
	var it := relay.take_intents()
	var o: Dictionary = it[0] if it.size() == 1 else {}
	var ctx: Dictionary = o.get("context", {})
	check("a live week asks once: kind and purpose feed, the event as entity (%s)" % [o], it.size() == 1 and o.get("k") == "ai_open" and o.get("kind") == "feed" and o.get("purpose") == "feed" and o.get("entity_id") == "town_market" and o.get("age_stage") == 0)
	check("its context: the week, the event, its scene, the era; nothing from the ship", ctx.get("week") == "500" and ctx.get("event") == "town-market" and str(ctx.get("scene", "")).begins_with("Scene, market day") and ctx.get("era") == "launch" and not ctx.has("port_id") and not ctx.has("crew"))
	check("until it is painted, the library shows", g.shown_key.begins_with("library:"))
	g.refresh(view({"feed": feed(500, "live", "town-market", "market day", 1)}))
	check("the same week is not asked twice", relay.take_intents().is_empty())
	for w in [501, 502, 503]:
		g.refresh(view({"feed": feed(w, "live", "town-market", "market day", 1)}))
	check("a few per visit: two more, not three", relay.take_intents().size() == 2)
	g.begin_visit()
	g.refresh(view({"feed": feed(504, "live", "town-market", "market day", 1)}))
	check("a new visit paints a few more weeks", relay.take_intents().size() == 1)
	g.refresh(view({"feed": feed(505, "library", "town-market", "market day", 1)}))
	check("a library week asks for nothing", relay.take_intents().is_empty())
	# The painting arrives in the player's library (the AI service writes blob, then index line).
	var img := Image.create(16, 9, false, Image.FORMAT_RGB8)
	img.fill(Color(0.8, 0.3, 0.2))
	var png := img.save_png_to_buffer()
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(png)
	var sha := hc.finish().hex_encode()
	DirAccess.make_dir_recursive_absolute(dir.path_join("blobs/" + sha.substr(0, 2)))
	var blob := FileAccess.open(dir.path_join("blobs/%s/%s.png" % [sha.substr(0, 2), sha]), FileAccess.WRITE)
	blob.store_buffer(png)
	blob.close()
	var idx := FileAccess.open(dir.path_join("index.ndjson"), FileAccess.WRITE)
	idx.store_line(JSON.stringify({"key": {"kind": "feed", "entity_id": "town_market", "emotion": "-", "age_stage": 0, "variant": "500"}, "sha256": sha, "ext": "png", "mime": "image/png"}))
	idx.close()
	cache.load_layers()
	g.refresh(view({"feed": feed(500, "live", "town-market", "market day", 1)}))
	check("once painted, the live week shows its painting (%s)" % g.shown_key, g.shown_key.begins_with("live:") and g.picture.texture != null and g.picture.texture.get_size() == Vector2(16, 9))
	check("painted frames join the event's pictures: the library grows", g.pictures_of("town-market").size() == 3 and str(g.pictures_of("town-market")[2]).begins_with("painted:"))
	relay.mode = "off"
	g.begin_visit()
	g.refresh(view({"feed": feed(600, "live", "town-market", "market day", 1)}))
	check("AI off: no request, the library shows", relay.take_intents().is_empty() and not g.shown_key.begins_with("live:"))
	for f: String in [dir.path_join("index.ndjson"), dir.path_join("blobs/%s/%s.png" % [sha.substr(0, 2), sha])]:
		DirAccess.remove_absolute(f)
	DirAccess.remove_absolute(dir.path_join("blobs/" + sha.substr(0, 2)))
	DirAccess.remove_absolute(dir.path_join("blobs"))
	DirAccess.remove_absolute(dir)
	g.queue_free()
	await process_frame
