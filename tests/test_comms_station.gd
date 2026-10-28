extends SceneTree
## R3-EARTH-LINK EL3 (K1, design r3/earth-link.md): the comms station. make comms-station-test (in
## make ui).
##   console  the spare console reserved_2 is the Comms station (reserved_3 stays offline); it opens
##            from the deck, is in the Tab "Walk to" list and ShipControls.CONSOLE, and switches
##            between the Listen pane and the Exchange log
##   AC9      every Label on the panes is a ComposedBinding, every field it reads is earth.*, and the
##            display audit finds nothing unbound (make display-audit-comms replays a whole voyage)
##   rate     the Earth-rate phrase is chosen by D from data (data/ui/comms_copy.json rate_bands): at
##            the RS-26..RS-29 values (receding at the top speed and at 0.99c, rest, approaching)
##   reason   the out-of-beam reason, its due year and the silence date are the sim's fields
## Time is the fake clock (_process(dt)); no wall-clock reads.

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


func _run() -> void:
	test_rate_bands()
	test_reasons()
	await test_console()
	print("comms-station: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func new_demo() -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false, "live_start": true, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.escape_exits = false
	return demo


func step(demo: Node, seconds: float, dt := 0.05) -> void:
	var t := 0.0
	while t < seconds - 1e-9:
		demo._process(dt)
		t += dt


## The texts of a pane's lines for a view, through the same bindings the panel uses.
func texts(pane: String, view: Dictionary) -> Array:
	var out := []
	for parts: Array in CommsPanel.pane_lines(pane, view):
		var b := ComposedBinding.new().compose(parts)
		b.update_from(view)
		out.append(b.text)
		b.free()
	return out


## Every binding under `root` reads earth.* fields only, and nothing with a digit is unbound.
func earth_bound(root: Node) -> bool:
	var labels := root.find_children("*", "Label", true, false)
	if labels.is_empty() or not DisplayBinding.audit(root).is_empty():
		return false
	for l: Label in labels:
		if l is ComposedBinding:
			for p: Variant in (l as ComposedBinding).parts:
				if p is Array and not str(p[0]).begins_with("earth."):
					return false
	return true


func earth(over: Dictionary) -> Dictionary:
	var e := {"rate": 1.0, "rate_inverse": 1.0, "newest_light_t": 0.0, "newest_light_year": 0.0, "light_age_years": 0.0,
		"at_home": false, "in_beam": true, "sending": true, "last_beam_t": 0.0, "last_beam_year": 0.0, "out": null, "messages": []}
	e.merge(over, true)
	return {"earth": e}


func test_rate_bands() -> void:
	# RS-26..RS-29: D at 0.99c and 0.999999c astern (e^-phi) and ahead (e^phi); 1/D is the other.
	var rows := [
		[0.00070711, 1414.2, "Earth rate 0.0007071: one Earth day every 3.87 yr aboard"],
		[0.070888, 14.107, "Earth rate 0.07089: one Earth day every 14.1 days aboard"],
		[1.0, 1.0, "Earth rate 1.000: real time"],
		[14.107, 0.070888, "Earth rate 14.11: 14.1 days of Earth per ship-day"],
		[1414.2, 0.00070711, "Earth rate 1414: 3.87 yr of Earth per ship-day"],
	]
	for r: Array in rows:
		var got: String = texts("listen", earth({"rate": r[0], "rate_inverse": r[1]}))[1]
		check("rate phrase at D = %s: %s" % [r[0], got], got == r[2])
	var bands: Array = CommsPanel.copy().rate_bands
	check("the bands are data and cover every D >= 0", bands.size() >= 3 and [0.0, 0.5, 0.95, 0.9999999, 1.0, 1.0000001, 1.05, 1e9].all(func(d: float) -> bool: return not CommsPanel.rate_phrase(bands, d).is_empty()))
	check("a slightly slow Earth is not 'real time'", CommsPanel.rate_phrase(bands, 0.99) != CommsPanel.rate_phrase(bands, 1.0))


func test_reasons() -> void:
	var proxima := "Gaia DR3 5853498713190525696"
	var v := earth({"in_beam": false, "light_age_years": 4.2, "newest_light_year": 0.3, "last_beam_year": 2.9,
		"out": {"reason": "not_heard", "port_id": proxima, "due_t": 12.6, "due_year": 12.6, "due_in_years": 8.3}})
	var t := texts("listen", v)
	check("light line: Earth's clock in the newest light, its age (%s)" % t[0], t[0] == "Newest light: Earth at +109.6 days, 4.20 yr old")
	check("not heard: the port's name, the due time and how far off, from out.* (%s)" % t[2],
		t[2] == "Out of Earth's beam: the light reaching the ship left before Earth heard your plan for Proxima Centauri. Earth's beam reaches Proxima Centauri at Earth +12.60 yr, 8.30 yr from now.")
	check("silence: the last beamed light's Earth clock (%s)" % t[3], t[3] == "Silence: the last beamed light left Earth at +2.90 yr.")
	v.earth.out.due_year = 20.0
	check("the due time is the field's, not a sum", texts("listen", v)[2].contains(" at Earth +20.00 yr, "))
	v.earth.newest_light_year = -0.0000158
	check("light from before the Earth clock's zero reads with a minus (%s)" % texts("listen", v)[0], texts("listen", v)[0] == "Newest light: Earth at −8.3 min, 4.20 yr old")
	check("at home: the Solar System line, no light age", texts("listen", earth({"at_home": true}))[0] == "Inside the Solar System: Earth tracks the ship directly, its light minutes or hours old.")
	v.earth.out = {"reason": "off_line", "port_id": "", "due_t": 0.0, "due_year": 2400.0, "due_in_years": 0.0}
	check("off the beam line", texts("listen", v)[2] == "Out of Earth's beam: off the beam line. Earth aims only at plans it has heard.")
	v.earth.out = {"reason": "silent", "port_id": "", "due_t": 0.0, "due_year": 2400.0, "due_in_years": 0.0}
	check("Earth silent", texts("listen", v)[2] == "Out of Earth's beam: Earth is silent.")
	check("in beam: three lines, no silence line", texts("listen", earth({})).size() == 3 and texts("listen", earth({}))[2] == "In Earth's beam")
	check("no earth section (a black hole's session): no lines", CommsPanel.pane_lines("listen", {}).is_empty() and CommsPanel.pane_lines("log", {}).is_empty())
	check("the Exchange log before any commit", texts("log", earth({})) == ["Earth is transmitting. No plan has been sent home yet: every commit sends one."])
	var m := {"plan_id": 2.0, "port_id": "Sol", "sent_year": 44.9, "sent_tau": 6.3, "heard_year": 84.9, "reply_year": 84.9}
	check("an Exchange log row from messages.0 (%s)" % texts("log", earth({"messages": [m]})),
		texts("log", earth({"messages": [m]})) == ["Plan 2 to Sol: sent at Earth +44.90 yr (6.30 yr aboard). Earth hears it at +84.90 yr; its reply reaches Sol at +84.90 yr at the earliest."])


func test_console() -> void:
	var demo: Node = await new_demo()
	var c: ShipConsoles = demo.consoles
	check("the session asks for 2.16 and the world carries earth", demo.journey_sim.want_minor == SimBridge.EARTH_MINOR and demo.journey_sim.world.get("earth") is Dictionary)
	check("comms is an active station on console_decision_2; reserved_3 stays offline", c.stations.has("comms") and c.stations.comms.active and not c.stations.has("reserved_2") and not c.stations.reserved_3.active)
	check("Walk to lists the Comms station, and the controls list it", ShipHud.WALK_TO.any(func(p: Array) -> bool: return p[0] == "comms") and ShipControls.CONSOLE.any(func(r: Dictionary) -> bool: return r.station == "comms"))
	check("at Earth: at home and in beam", demo.journey_sim.world.earth.at_home == true and demo.journey_sim.world.earth.in_beam == true)
	step(demo, 0.05) # the idle screens refresh each frame (ShipConsoles.advance)
	check("its idle screen, bound (%s)" % c.screen_text("comms"), c.screen_text("comms") == "Comms\nEarth, close by" and (c.screens.comms.label as ComposedBinding).text == "Comms\nEarth, close by")
	check("use() refuses it out of reach", not c.use("comms", "open") and c.focused == "")
	c.go_to("comms")
	check("it opens from the deck", c.use("comms", "open") and c.focused == "comms" and c.panel.visible and c.comms_station != null and c.comms_station.get_parent() == c.panel_body)
	step(demo, 0.1)
	var st: CommsStation = c.comms_station
	check("visual first: the feed and the clocks show, the words wait behind Details", st.feed.is_visible_in_tree() and st.feed.picture.texture != null and st.clocks.is_visible_in_tree() and not st.words.is_visible_in_tree())
	check("at Earth the feed is live, in beam, no static", st.feed.signal_tag.text == "● live" and not st.feed.static_rect.visible and not st.feed.ring.visible)
	check("AC9 the feed and clocks: every label bound to earth.*", earth_bound(st))
	check("Listen opens the words layer", c.use("comms", "listen") and st.words.is_visible_in_tree())
	step(demo, 0.1)
	var p: CommsPanel = c.comms_panel
	check("Listen at Earth: home, rate, beam (%s)" % [p.lines.get_children().map(func(l: Label) -> String: return l.text)],
		p.pane == "listen" and p.lines.get_child_count() == 3 and (p.lines.get_child(0) as Label).text.begins_with("Inside the Solar System") and (p.lines.get_child(1) as Label).text == "Earth rate 1.000: real time" and (p.lines.get_child(2) as Label).text == "In Earth's beam")
	check("AC9 Listen: every label bound to earth.*", earth_bound(p))
	check("the Exchange log", c.use("comms", "log") and c.comms_panel.pane == "log")
	step(demo, 0.1)
	check("AC9 Exchange log: every label bound to earth.*", earth_bound(c.comms_panel) and c.comms_panel.lines.get_child_count() == 1)
	# A commit sends the plan home: the log gains a row from earth.messages.0.
	c.go_to("navigation")
	c.use("navigation", "open")
	c.use("navigation", "select", "Gaia DR3 4472832130942575872")
	demo.journey_tick()
	check("commit at the helm", c.use("navigation", "commit") and demo.journey_tick() and demo.live_journey)
	check("the sim sent the plan home", (demo.journey_sim.world.earth.messages as Array).size() == 1)
	c.go_to("comms")
	c.use("comms", "open")
	step(demo, 0.1)
	var row := c.comms_panel.lines.get_child(0) as ComposedBinding
	check("the pane chosen survives stepping back", c.comms_panel.pane == "log")
	check("the feed's week is earth.feed's (%s)" % c.comms_station.feed.shown_key, c.comms_station.feed.shown_key == EarthFeed.source_of(demo.journey_sim.world.earth.feed))
	check("one row, bound to earth.messages.0 (%s)" % row.text, c.comms_panel.lines.get_child_count() == 1 and row.parts.filter(func(x: Variant) -> bool: return x is Array).all(func(x: Array) -> bool: return str(x[0]).begins_with("earth.messages.0.")) and row.text.begins_with("Plan "))
	check("AC9 after the commit: every label bound to earth.*", earth_bound(c.comms_panel))
	c.use("comms", "listen")
	step(demo, 1.0)
	check("AC9 Listen under way: every label bound to earth.*", earth_bound(c.comms_panel))
	check("Esc steps back", c.escape() and c.focused == "" and not c.panel.visible)
	demo.queue_free()
	await process_frame
