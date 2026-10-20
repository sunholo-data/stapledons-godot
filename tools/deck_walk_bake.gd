extends SceneTree
## R2-DECK-LAYOUT DL1 (design_docs/planned/r2/deck-layout.md §D2, ledger D-95): bakes the bridge walk
## for a layout, so the walk the evaluator measured in-engine is the walk that ships. Loads the pinned
## grounded-bridge-v2 deck (build/ship-baseline, make ship-baseline), applies the layout with
## DeckLayout.apply (the shipped walk clipped out of each moved group's old and new footprints and
## re-rastered at 0.125 m; elsewhere untouched) and writes the result as a glTF binary holding one
## mesh, WALK_bridge, in the play frame (glTF metres, Y up). The Blender generator
## (~/dev/blender/scripts/stapledon_deck_layout_v2.py) puts it into the master and exports it.
## Usage: godot --headless --path . --script tools/deck_walk_bake.gd -- --layout <json> --out <glb>
const BASELINE := "res://build/ship-baseline"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var lp := args[args.find("--layout") + 1] if args.has("--layout") else ""
	var out := args[args.find("--out") + 1] if args.has("--out") else ""
	if lp == "" or out == "":
		print("deck-walk-bake: FAIL usage --layout <json> --out <glb>")
		quit(2)
		return
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": Vector2i(1280, 720), "sky_state": "rest", "asset_dir": BASELINE}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok or FileAccess.get_sha256(BASELINE + "/walk_bridge.glb") != "9775c88d9f4d7ba7cb041ceedc61b22d6fca631092a73d051b0efdbad58f319b":
		print("deck-walk-bake: FAIL the pinned baseline did not load (make ship-baseline)")
		quit(1)
		return
	var dl := DeckLayout.new(demo)
	var errs := dl.apply(DeckLayout.load_layout(lp), DeckLayout.load_layout(DeckLayoutEval.BASE))
	if not errs.is_empty():
		print("deck-walk-bake: FAIL %s" % errs)
		quit(1)
		return
	var w: WalkArea = demo.walk_bridge
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in w.triangle_count():
		var a := w._tris[3 * t]
		var b := w._tris[3 * t + 1]
		var c := w._tris[3 * t + 2]
		if (b - a).cross(c - a).y < 0.0: # face up
			var x := b
			b = c
			c = x
		for p: Vector3 in [a, b, c]:
			st.set_normal(Vector3.UP)
			st.add_vertex(p)
	var mi := MeshInstance3D.new()
	mi.name = "WALK_bridge"
	mi.mesh = st.commit()
	var scene := Node3D.new()
	scene.name = "walk_bridge"
	scene.add_child(mi)
	mi.owner = scene
	var doc := GLTFDocument.new()
	var gs := GLTFState.new()
	if doc.append_from_scene(scene, gs) != OK or doc.write_to_filesystem(gs, out) != OK:
		print("deck-walk-bake: FAIL writing %s" % out)
		quit(1)
		return
	print("deck-walk-bake: %d triangles -> %s" % [w.triangle_count(), out])
	scene.free()
	quit(0)
