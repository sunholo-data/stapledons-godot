extends SceneTree
## M4.0: builds play_bridge.glb for the blockout TEST FIXTURE (tests/fixtures/areas/bridge_blockout/)
## from the spike's bridge slice, adding the brief §6/§9 collections the spike never had:
##   WALK_bridge     a flat walk disc (r 20 m, top at deck level y = 0)
##   SPAWN_captain_0, SPAWN_arrival_0
##   INTERACT_bridge two stand-ins named like bridge v1's (captain_chair, console_navigation_0)
## Not shipping art: it exists so the loader, validator, walking and the bot have a bundle.
## Reproduce (spike commit 4eda978, origin/spike/iso-bridge):
##   git show origin/spike/iso-bridge:spike/v2/bridge_slice.glb > .godot/tmp/bridge_slice.glb
##   godot --headless --path . --script tools/build_blockout_fixture.gd -- \
##       .godot/tmp/bridge_slice.glb tests/fixtures/areas/bridge_blockout/play_bridge.glb


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() != 2:
		printerr("usage: build_blockout_fixture.gd -- SPIKE_SLICE.glb OUT.glb"); quit(2); return
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(a[0], st) != OK:
		printerr("cannot read %s" % a[0]); quit(2); return
	var scene := doc.generate_scene(st)
	scene.name = "play_bridge"
	var walk := Node3D.new()
	walk.name = "WALK_bridge"
	var disc := MeshInstance3D.new()
	disc.name = "WALK_disc"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 20.0
	cyl.bottom_radius = 20.0
	cyl.height = 0.02
	cyl.radial_segments = 64
	cyl.rings = 1
	disc.mesh = cyl
	disc.position = Vector3(0, -0.01, 0)
	walk.add_child(disc)
	scene.add_child(walk)
	for s in [["SPAWN_captain_0", Vector3(0, 0, 3.5)], ["SPAWN_arrival_0", Vector3(8, 0, -8)]]:
		var m := Node3D.new()
		m.name = s[0]
		m.position = s[1]
		scene.add_child(m)
	var inter := Node3D.new()
	inter.name = "INTERACT_bridge"
	for s in [["captain_chair", Vector3(0, 0.9, 4.5)], ["console_navigation_0", Vector3(0, 0.8, -11)]]:
		var m := MeshInstance3D.new()
		m.name = s[0]
		var box := BoxMesh.new()
		box.size = Vector3(1.6, 1.6, 1.6)
		m.mesh = box
		m.position = s[1]
		inter.add_child(m)
	scene.add_child(inter)
	for c in scene.get_children():
		_own(c, scene)
	var out := GLTFDocument.new()
	var ost := GLTFState.new()
	if out.append_from_scene(scene, ost) != OK or out.write_to_filesystem(ost, a[1]) != OK:
		printerr("cannot write %s" % a[1]); quit(1); return
	print("wrote %s" % a[1])
	scene.free()
	quit(0)


func _own(n: Node, owner_node: Node) -> void:
	n.owner = owner_node
	for c in n.get_children():
		_own(c, owner_node)
