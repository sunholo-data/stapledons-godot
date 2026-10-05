extends SceneTree
const Info = preload("res://ui/star_info.gd")
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok:passed += 1
	else:failed += 1; push_error(message)
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var c := StarCatalogue.new(); c.count = 3
	check(c.load_identity(["a", "missing", "b"]), "exact ordered identity")
	check(not c.load_identity(["a", "a", "b"]) and c.ids.is_empty(), "duplicate identity refused")
	check(not c.load_identity(["a"]), "stale count refused")
	c.load_identity(["a", "missing", "b"])
	c.data = PackedFloat32Array([1,0,0,5000,0,0, 2,0,0,0,99,2, 3,0,0,6000,1,8])
	var stars := Starfield.new(); stars.append_catalogue(c)
	check(stars.ids == ["a", "b"], "identity survives missing-photometry filtering")
	stars.clear(); stars.append_catalogue(c,8)
	check(stars.ids == ["b"], "identity survives HIP stacking filter")
	stars.free()
	var info := Info.new(); info.set_records([{id="b"}, {id="a",teff=5000.,vmag=2.,dist_ly=3.}])
	check(info.text("a").contains("3.000 ly") and info.text("b").contains("unavailable"), "factual fields and absent labels")
	info.set_records([{id="a"},{id="a"}]); check(not info.records.has("a"), "duplicate metadata is not eligible")
	info.load_files()
	var field := Starfield.new(); check(field.load_tiers("medium"), "real active stack loads")
	check(field.ids.size() == field.count, "real IDs match every rendered row")
	check(field.ids.has("CNS5:3627"), "actual alpha Cen A identity")
	var sirius := ""
	for id in info.names:
		if info.names[id] == "Sirius A":sirius = id
	check(not sirius.is_empty() and field.ids.has(sirius), "actual Sirius identity")
	field.free()
	var bytes := c.data.to_byte_array()
	var ctx := HashingContext.new();ctx.start(HashingContext.HASH_SHA256);ctx.update(bytes)
	var metadata := {format_version=1,record_bytes=24,fields=StarCatalogue.FIELDS,count=3,sha256={bin=ctx.finish().hex_encode()},ids=["a","missing","b"]}
	var file := FileAccess.open("user://identify-test.bin",FileAccess.WRITE);file.store_buffer(bytes);file.close()
	file = FileAccess.open("user://identify-test.json",FileAccess.WRITE);file.store_string(JSON.stringify(metadata));file.close()
	check(StarCatalogue.from_files("user://identify-test.bin","user://identify-test.json") != null,"hash-pinned identity fixture")
	metadata.sha256.bin = "0".repeat(64)
	file = FileAccess.open("user://identify-test.json",FileAccess.WRITE);file.store_string(JSON.stringify(metadata));file.close()
	check(StarCatalogue.from_files("user://identify-test.bin","user://identify-test.json") == null,"stale binary hash refused")
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {stars=false,background=false,sky_state="rest"}
	root.add_child(demo);await process_frame
	demo.auto=false;demo.set_process(false)
	var identify: Control = demo.star_identification
	check(demo.ready_ok and identify != null,"actual demo installs shared component")
	demo.camera.follow(Vector3(8,82,-4.8),20.,.4,0.);demo._sync_observer()
	var world: Dictionary = demo.sky_world.duplicate(true)
	var n: Vector3 = demo.camera.to_sky_direction(-demo.camera.basis.z,demo.camera.heading)
	demo.sky.starfield.set_custom_stars([{id="a",pos=n*100.,t=5700.,flux=1.}])
	demo.sky.starfield.set_ship_position(0.,0.,0.);demo.sky.starfield.set_velocity(Vector3.UP,0.,1.)
	demo.sky.starfield.set_exposure(5.)
	identify.info.set_records([{id="a",dist_ly=100.,teff=5700.,vmag=0.},{id="b"}])
	demo.sky_only=true
	var key := InputEventKey.new();key.physical_keycode=KEY_I;key.pressed=true
	check(identify.handle_input(key) and identify.held,"hold I is consumed")
	identify.update_candidates()
	check(identify.candidates.size()==1,"actual shader-eligible source projects")
	var point: Vector2=identify.candidates[0].point if not identify.candidates.is_empty() else Vector2.ZERO
	var click := InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=point
	check(identify.handle_input(click) and identify.selected_id=="a" and identify.card.visible,"native left click opens exact ID card")
	key.pressed=false;identify.handle_input(key)
	check(not identify.held and identify.card.visible and identify.candidates.is_empty(),"release hides rings, preserves card")
	check(demo.sky_world==world and demo.journey_map==null,"inspection does not plan, tick or create simulation")
	var escape := InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.pressed=true
	check(identify.handle_input(escape) and not identify.card.visible,"Escape closes card first")
	identify.set_held(true);demo.get_window().focus_exited.emit();check(not identify.held,"focus loss clears held state")
	identify.suppressed=true;identify.set_held(true);check(not identify.held,"modal/benchmark suppression refuses hold")
	identify.suppressed=false;identify.set_held(true)
	click.alt_pressed=true;check(not identify.handle_input(click),"Option click remains look");click.alt_pressed=false
	var planet_sim:=SimBridge.new();planet_sim.want_minor=5
	check(planet_sim.start() and planet_sim.new_game(17),"actual body fields available for foreground test")
	var earth:Dictionary={}
	for body:Dictionary in planet_sim.world.system.bodies:
		if body.id=="earth":earth=body.duplicate(true)
	var rel:Vector3=SkyFrame.to_galactic(n*50000.)
	earth.rel_km={"x":rel.x,"y":rel.y,"z":rel.z}
	demo.sky.system_view.set_velocity(Vector3.UP,0.,1.,1.)
	demo.sky.system_view.update({"bodies":[earth]},demo.sky.exposure.k())
	identify.update_candidates()
	check(identify.candidates.is_empty(),"opaque astronomical globe masks I rings and clicks")
	rel=SkyFrame.to_galactic(n*50000.+demo.sky.camera.screen_right()*15000.)
	earth.rel_km={"x":rel.x,"y":rel.y,"z":rel.z}
	demo.sky.system_view.update({"bodies":[earth]},demo.sky.exposure.k());identify.update_candidates()
	check(identify.candidates.size()==1,"clear sky beside planet retains known star")
	demo.sky.system_view.update({},demo.sky.exposure.k());planet_sim.stop()
	var blocker := MeshInstance3D.new();var box := BoxMesh.new();box.size=Vector3(2,2,.2);blocker.mesh=box
	demo.geometry.add_child(blocker);blocker.position=demo.camera.position-demo.camera.basis.z*10.;blocker.basis=demo.camera.basis
	for child in demo.geometry.get_children():
		if child is Node3D and child != blocker:child.visible=false
	identify.occlusion.build(demo.geometry);demo.sky_only=false;identify.update_candidates()
	check(identify.candidates.is_empty(),"opaque visual without collider blocks apparent star")
	blocker.position+=demo.camera.basis.x*10.;identify.update_candidates()
	check(identify.candidates.size()==1,"moving mesh transform is refreshed")
	blocker.position-=demo.camera.basis.x*10.;blocker.visible=false;identify.update_candidates()
	check(identify.candidates.size()==1,"hidden visual does not occlude")
	blocker.visible=true
	var opaque_shader := Shader.new();opaque_shader.code="shader_type spatial; void fragment(){ ALBEDO=vec3(0.0); ALPHA=1.0; }"
	var opaque_material := ShaderMaterial.new();opaque_material.shader=opaque_shader;blocker.material_override=opaque_material
	identify.occlusion.build(demo.geometry);identify.update_candidates()
	check(identify.candidates.is_empty(),"opaque ALPHA=1 custom shader without collider blocks")
	blocker.visible=false
	var second := {id="b",pos=n*100.,t=5700.,flux=1.}
	demo.sky.starfield.append_stars([second]);identify.update_candidates()
	check(identify.candidates.size()==2 and identify.click_at(point) and identify.content.get_child(0).text.contains("Overlapping"),"unresolved blend offers individual exact IDs")
	check(identify.inspect("b") and identify.selected_id=="b","either blended ID can be inspected")
	demo.sky.starfield.append_stars([{id="a",pos=n*100.,t=5700.,flux=1.}]);identify.update_candidates()
	check(identify.candidates.size()==1 and identify.candidates[0].id=="b","duplicate IDs across stacked stars fail closed")
	demo.sky.starfield.set_custom_stars([{id="c",pos=n*100.,t=5700.,flux=1.},{id="b",pos=n*100.,t=5700.,flux=1.}]);identify.update_candidates()
	check(identify.candidates.size()==1 and identify.candidates[0].id=="b","same-count catalogue replacement invalidates identity cache")
	demo.sky.starfield.set_custom_stars([{id="b",pos=-n*100.,t=5700.,flux=1.}]);identify.update_candidates()
	check(identify.candidates.is_empty(),"behind-camera source excluded")
	demo.sky.starfield.set_custom_stars([{id="b",pos=n*100.,t=5700.,flux=1e-10}]);identify.update_candidates()
	check(identify.candidates.is_empty(),"renderer peak culling excludes invisible source")
	demo.sky.starfield.set_floor(Vector2(1e-12,.02));identify.update_candidates()
	check(identify.candidates.size()==1,"renderer magnitude floor restores eligibility exactly")
	demo.sky.starfield.set_floor(Vector2.ZERO)
	demo.sky.starfield.set_custom_stars([{id="b",pos=n*100.,t=5700.,flux=1.}]);identify.update_candidates()
	var original: Vector2=identify.candidates[0].pixel
	demo.sky.starfield.set_velocity(demo.sky.camera.screen_right(),.3,Relativity.gamma_of(.3));identify.update_candidates()
	check(identify.candidates.size()==1 and identify.candidates[0].pixel.distance_to(original)>1.,"apparent cache invalidates on uploaded live boost")
	demo.sky.starfield.set_velocity(Vector3.UP,0.,1.);demo.sky.starfield.set_ship_position(.5,0,0);identify.update_candidates()
	check(identify.candidates.size()==1 and identify.candidates[0].pixel.distance_to(original)>.1,"apparent cache invalidates on uploaded ship offset")
	demo.sky.starfield.set_ship_position(0,0,0)
	var sprite := Sprite3D.new();var image := Image.create(32,32,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
	for y in range(8,24):
		for x in range(8,24):image.set_pixel(x,y,Color.WHITE)
	sprite.texture=ImageTexture.create_from_image(image);sprite.pixel_size=.1;sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
	demo.geometry.add_child(sprite);sprite.position=demo.camera.position-demo.camera.basis.z*10.
	identify.occlusion.build(demo.geometry);identify.update_candidates()
	check(identify.candidates.is_empty(),"opaque billboard sprite pixels block identification")
	sprite.position+=demo.camera.basis.x*1.2;identify.update_candidates()
	check(identify.candidates.size()==1,"transparent billboard padding keeps star visible")
	sprite.queue_free();await process_frame;identify.update_candidates()
	check(identify.candidates.size()==1,"freed sprite references are ignored")
	identify.info.records.erase("b");identify.reindex();identify.update_candidates();check(identify.candidates.is_empty(),"absent metadata fails closed")
	demo.queue_free();await process_frame
	print("ship-star-identification: %d passed, %d failures" % [passed, failed]); quit(1 if failed else 0)
