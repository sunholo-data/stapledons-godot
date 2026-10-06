extends SceneTree
## M4.7 the Archive codex (design m4-first-journey.md "M4.7"): the lore loader and its manifest
## check, the Markdown subset, the codex panel (locked entries greyed, unlock toasts), LoreBinding,
## and the real sim's minimum path against tests/expected_unlocks.json. Headless:
##   godot --headless --path . --script tests/test_codex.gd      (make codex-test)
## Unlocks come only from the sim's consequence.archive.unlocked; the panel has no way to unlock.

const EXPECTED := "res://tests/expected_unlocks.json"
const TMP := "res://.godot/tmp/test_codex"
const HINTS := ["always", "first_commit", "first_boost", "cruise_above_0.9c", "cruise_above_gamma_275", "first_black_hole"]
const WATCHDOG_S := 120.0

var failures := 0
var checks := 0


func ok(name: String, cond: bool) -> void:
	checks += 1
	if not cond: failures += 1
	print("  %s  %s" % ["ok  " if cond else "FAIL", name])


## The harness, sampled after every tick (TransitHarness.refresh runs once per tick).
class Sampler extends TransitHarness:
	var on_tick := Callable()

	func refresh() -> void:
		super.refresh()
		if on_tick.is_valid():
			on_tick.call()


func world_with(unlocked: Array) -> Dictionary:
	return {"consequence": {"archive": {"unlocked": unlocked}}}


func test_loader() -> Array:
	var r := LoreLoader.load_entries()
	var es: Array = r["entries"]
	ok("the vendored lore loads with no manifest errors (%s)" % str(r["errors"]), r["errors"].is_empty())
	ok("ten entries, in the README's order: bubble, one-g, nothing-crosses first", es.size() == 10 and es[0]["id"] == "archive.bubble" and es[1]["id"] == "archive.one-g" and es[2]["id"] == "archive.nothing-crosses" and es[9]["id"] == "archive.shadow-ring")
	ok("every entry has id, title, a known unlock hint, checks and a body", es.all(func(e): return e["id"].begins_with("archive.") and e["title"] != "" and HINTS.has(e["unlock"]) and e["checks"].size() > 0 and e["body"].length() > 200))
	ok("archive_rows are {id, unlock} in the same order, for new_game", LoreLoader.archive_rows(es) == es.map(func(e): return {"id": e["id"], "unlock": e["unlock"]}) and LoreLoader.archive_rows(es).size() == 10)
	ok("a front-matter comment is not part of the value", es[0]["unlock"] == "always")
	# positive control: one byte changed in a vendored file -> that entry is refused, with a message
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TMP + "/archive"))
	for f in DirAccess.get_files_at("res://data/lore/archive"):
		DirAccess.copy_absolute(ProjectSettings.globalize_path("res://data/lore/archive/" + f), ProjectSettings.globalize_path(TMP + "/archive/" + f))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://data/lore/manifest.json"), ProjectSettings.globalize_path(TMP + "/manifest.json"))
	var f := FileAccess.open(TMP + "/archive/one-g.md", FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("x")
	f.close()
	var bad := LoreLoader.load_entries(TMP)
	ok("a tampered file is refused and reported, the others still load", bad["entries"].size() == 9 and bad["errors"].size() == 1 and str(bad["errors"][0]).contains("one-g"))
	return es


func test_markdown() -> void:
	var md := "# Head\n\nA *slanted* and **bold** word, A* stays, a [bracket].\n\n- one\n- two\n\n| a | b |\n|---|---|\n| 1 | 2 |\n"
	var b := LoreLoader.to_bbcode(md)
	ok("headings become bold sized text", b.contains("[b]Head[/b]"))
	ok("emphasis and strong map to [i] and [b]; a lone asterisk after a letter is plain", b.contains("[i]slanted[/i]") and b.contains("[b]bold[/b]") and b.contains("A* stays"))
	ok("a literal bracket cannot open a BBCode tag", b.contains("[lb]bracket[rb]") and not b.contains("[bracket]"))
	ok("lists become bullets", b.contains("• one") and b.contains("• two"))
	ok("tables become [table] with one cell per column and no separator row", b.contains("[table=2]") and b.contains("[cell]1[/cell]") and not b.contains("---"))
	var rt := RichTextLabel.new()
	rt.bbcode_enabled = true
	rt.text = b
	ok("the BBCode parses to the visible text (no stray tags)", rt.get_parsed_text().contains("A slanted and bold word") and not rt.get_parsed_text().contains("[b]"))
	rt.free()
	var real: Array = LoreLoader.load_entries()["entries"]
	ok("every real body renders with no leftover markup tags and keeps its words", real.all(func(e):
		var r := RichTextLabel.new()
		r.bbcode_enabled = true
		r.text = LoreLoader.to_bbcode(e["body"])
		var good: bool = r.get_parsed_text().replace("\n", " ").contains(e["body"].strip_edges().split("\n")[0].substr(0, 20))
		r.free()
		return good))


func test_binding(es: Array) -> void:
	var e: Dictionary = es[3]
	var binding := LoreBinding.new()
	binding.entry_id = e["id"]
	ok("LoreBinding: the shown body hash-equals the imported entry", binding.check(e["body"]))
	ok("LoreBinding: one changed character fails (positive control)", not binding.check(e["body"].substr(0, 10) + "X" + e["body"].substr(11)))
	ok("LoreBinding: a trailing space fails", not binding.check(e["body"] + " "))
	ok("LoreBinding: an unknown entry never binds", not LoreBinding.new().check("anything"))


func test_panel(es: Array) -> void:
	var cx: Codex = load("res://ui/archive/codex.tscn").instantiate()
	root.add_child(cx)
	ok("the codex loads the lore", cx.load_lore() and cx.entries.size() == 10)
	cx.show_world(world_with([]))
	cx.open()
	var rows := cx.entry_rows()
	ok("nothing unlocked: ten rows, all disabled and greyed", rows.size() == 10 and rows.values().all(func(b): return b.disabled and b.modulate.a < 0.6))
	ok("nothing unlocked: no toast", cx.toast_log.is_empty())
	ok("a locked entry shows its title and no body", rows["archive.bubble"].text == es[0]["title"] and cx.shown_body_source() == "")
	cx.show_world(world_with(["archive.bubble", "archive.one-g", "archive.nothing-crosses"]))
	rows = cx.entry_rows()
	ok("three unlocked: those rows enabled at full strength, the other seven still greyed", ["archive.bubble", "archive.one-g", "archive.nothing-crosses"].all(func(i): return not rows[i].disabled and rows[i].modulate.a == 1.0) and rows.values().filter(func(b): return b.disabled).size() == 7)
	ok("one toast per new unlock, in order", cx.toast_log == ["archive.bubble", "archive.one-g", "archive.nothing-crosses"])
	cx.show_world(world_with(["archive.bubble", "archive.one-g", "archive.nothing-crosses"]))
	ok("the same world again: no new toast", cx.toast_log.size() == 3)
	ok("an unlocked entry opens by its row", cx.select("archive.one-g") and cx.selected == "archive.one-g")
	ok("the shown source is the entry body, hash-equal through LoreBinding", cx.shown_body_source() == es[1]["body"] and cx.binding_ok())
	ok("a locked entry cannot be selected", not cx.select("archive.tides") and cx.selected == "archive.one-g")
	var label := cx.body_label()
	ok("the RichTextLabel shows the entry (title and first sentence)", label.get_parsed_text().contains(es[1]["title"]) and label.get_parsed_text().contains("Your feet press on the deck"))
	cx.show_world(world_with(["archive.bubble"]))
	ok("the sim is the only source: if it reports fewer unlocks the panel shows fewer", cx.entry_rows().values().filter(func(b): return not b.disabled).size() == 1)
	var names: Array = cx.get_method_list().map(func(m): return m["name"])
	ok("the panel has no way to unlock an entry (no unlock/set_unlocked method; unlocked is read by show_world)", names.filter(func(n): return n.contains("unlock") and n != "show_world").is_empty())
	cx.show_world({})
	ok("a world without the archive section locks everything", cx.entry_rows().values().all(func(b): return b.disabled))
	var open_n := func() -> int: return cx.entry_rows().values().filter(func(b): return not b.disabled).size()
	cx.show_world({"free_unlocks": ["archive.bubble"]})
	ok("a non-canonical key alone (free_unlocks) unlocks nothing", open_n.call() == 0)
	cx.show_world({"archive": {"unlocked": ["archive.bubble"]}, "consequence": {"unlocked": ["archive.bubble"]}})
	ok("the canonical list at the wrong path unlocks nothing", open_n.call() == 0)
	cx.show_world({"free_unlocks": ["archive.bubble", "archive.one-g"], "consequence": {"archive": {"unlocked": ["archive.nothing-crosses"]}}})
	ok("with both, only consequence.archive.unlocked counts", open_n.call() == 1 and not cx.entry_rows()["archive.nothing-crosses"].disabled and cx.entry_rows()["archive.bubble"].disabled)
	cx.close()
	ok("closed: the panel is hidden", not cx.panel.visible)
	cx.queue_free()


func test_minimum_path() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(EXPECTED))
	var sim := SimBridge.new()
	sim.want_minor = 2
	sim.archive_rows = LoreLoader.archive_rows(LoreLoader.load_entries()["entries"])
	if not sim.start() or not sim.new_game(0, "sol", false, Transit.new_game_params()):
		ok("sim starts with the codex table (%s)" % sim.last_error, false)
		return
	var h := Sampler.new()
	root.add_child(h)
	h.attach(sim)
	var seen: Array = [] # [id, phase at the tick it appeared, journey state]
	var known := {}
	var g := {"gamma": 0.0} # lambdas capture numbers by value
	var res := {}
	# run_session ticks the scripted flight; sample after every tick by wrapping sim.send
	var cx: Codex = load("res://ui/archive/codex.tscn").instantiate()
	root.add_child(cx)
	cx.load_lore()
	h.on_tick = (func() -> void:
		var u: Variant = GalaxyMap.field_value(sim.world, "consequence.archive.unlocked")
		cx.show_world(sim.world)
		if u is Array:
			for id in u:
				if not known.has(id):
					known[id] = true
					seen.append([id, sim.world["ship"]["phase"], GalaxyMap.field_value(sim.world, "journey.state")])
		if sim.world["ship"]["phase"] == "cruising" and g["gamma"] == 0.0:
			g["gamma"] = sim.world["ship"]["gamma"])
	var gamma: float = 0.0
	res = h.run_session()
	gamma = g["gamma"]
	ok("the scripted minimum path ran to arrival", res["ok"] and sim.world["journey"]["state"] == "arrived")
	var ids: Array = seen.map(func(s): return s[0])
	var want: Array = expected["unlocks"].map(func(u): return u["id"])
	ok("the sim unlocked exactly the seven expected entries, in order (%s)" % str(ids), ids == want)
	var hints_ok := true
	var rows: Array = sim.archive_rows
	for u in expected["unlocks"]:
		hints_ok = hints_ok and rows.any(func(r): return r["id"] == u["id"] and r["unlock"] == u["hint"])
	ok("each expected entry sits on its hint in the table the sim was given", hints_ok)
	ok("cmb-forward does not unlock at gamma %.4f (< 275), nor do tides or the shadow ring" % gamma, expected["not_unlocked"].all(func(i): return not known.has(i)) and gamma > 7.0 and gamma < 7.1)
	var by := {}
	for s in seen:
		by[s[0]] = s
	ok("the three always entries open before any commit", ["archive.bubble", "archive.one-g", "archive.nothing-crosses"].all(func(i): return by[i][2] != "committed"))
	ok("two-clocks opens at the commit and photon-drive at the boost", by["archive.two-clocks"][2] == "committed" and by["archive.photon-drive"][1] == "boosting")
	ok("ism-glow and starbow open when the ship reaches cruise above 0.9c", by["archive.ism-glow"][1] == "cruising" and by["archive.starbow"][1] == "cruising")
	ok("the codex shows exactly the unlocked entries after arrival", cx.entry_rows().values().filter(func(b): return not b.disabled).size() == 7 and cx.toast_log == want)
	ok("the sim answers the new_game with the codex table (protocol 2.2, no refusal)", sim.last_error == "")
	sim.stop()
	cx.queue_free()


func _init() -> void:
	create_timer(WATCHDOG_S).timeout.connect(func() -> void:
		print("codex: watchdog expired (a script error above?)")
		quit(2))
	var es := test_loader()
	test_markdown()
	test_binding(es)
	test_panel(es)
	test_minimum_path()
	ok("all checks ran", checks >= 38)
	print("codex: %d passed, %d failures" % [checks - failures, failures])
	quit(1 if failures > 0 else 0)
