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
	check("the ring fills by out.progress, its label bound (%s)" % f.ring.label.text, f.ring.visible and is_equal_approx(f.ring.fill, 0.36) and f.ring.label.text == "8.30 yr until Earth's voice")
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
	st.queue_free()
	await test_live(root)
	root.queue_free()
	await process_frame
	print("earth-feed: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


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
