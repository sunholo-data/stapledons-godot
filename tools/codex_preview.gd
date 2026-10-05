extends Node
## M4.7 review render of the codex panel over the REAL sim's minimum path (every unlock is the sim's).
##   AILANG_BIN=... godot --path . --write-movie /tmp/iter15_codex/frame.png --fixed-fps 10 \
##     --quit-after 30 --resolution 1280x720 res://tools/codex_preview.tscn -- [--select=archive.ism-glow] [--locked-only]
## The panel is on a plain dark ground; the toasts show for 4 s after the last unlock.

func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cx: Codex = load("res://ui/archive/codex.tscn").instantiate()
	add_child(cx)
	cx.load_lore()
	var sim := SimBridge.new()
	sim.want_minor = 2
	sim.archive_rows = LoreLoader.archive_rows(cx.entries)
	if not sim.start() or not sim.new_game(0, "sol", false, Transit.new_game_params()):
		push_error("sim: %s" % sim.last_error)
		get_tree().quit(2)
		return
	var h := TransitHarness.new()
	add_child(h)
	h.attach(sim)
	h.hud.visible = false # the harness HUD is not under review
	h.card.visible = false
	if args.has("locked-only"):
		cx.show_world(sim.world) # new_game state: nothing unlocked yet
	else:
		var res := h.run_session()
		print("preview: arrived=%s unlocked=%s" % [res["ok"], GalaxyMap.field_value(sim.world, "consequence.archive.unlocked")])
		# the toast stack shows what the last ticks unlocked: replay the world through the panel from empty
		cx.show_world({})
		var w := sim.world.duplicate(true)
		if args.has("open"): # a prefix of the sim's real unlock list, to show locked rows beside open ones
			w["consequence"]["archive"]["unlocked"] = w["consequence"]["archive"]["unlocked"].slice(0, int(args["open"]))
		cx.show_world(w)
	cx.open()
	if args.has("select"):
		cx.select(args["select"])
	h.hud.visible = false
	h.card.visible = false
	sim.stop()
