extends SceneTree
var passed := 0
var failed := 0
func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1; push_error(message)
func _initialize() -> void: _run.call_deferred()
func fixture() -> Dictionary:
	return {version=1,figures=[{id="test",name="Test",endpoints=[{id="a",catalogue_id="a"},{id="b",catalogue_id="b"}],segments=[["a","b"]]}]}
func _run() -> void:
	var script = load("res://ui/constellation_overlay.gd")
	check(script != null,"constellation overlay exists")
	if script == null: finish(); return
	var guide = script.new()
	check(guide.load_manifest(),"shipped manifest validates")
	check(guide.figures.size()==4,"four approved starter figures")
	var field := Starfield.new()
	check(field.load_tiers(Starfield.default_tier()),"normal sky stack loads")
	field.build()
	guide.resolve(field)
	check(guide.missing_count==0 and guide.indices.size()==23,"all 23 source identities resolve uniquely")
	field.set_custom_stars([{id="a",pos=Vector3(-10,0,-100),t=5700.,flux=.001},{id="b",pos=Vector3(10,0,-100),t=5700.,flux=.001}])
	field.set_ship_position(0,0,0);field.set_velocity(Vector3.FORWARD,0,1);field.set_exposure(5.)
	check(guide.set_manifest(fixture()),"small manifest")
	var camera := Camera3D.new();root.add_child(camera);camera.fov=78
	guide.refresh(field,camera,Vector2(960,540))
	check(guide.segments.size()==1 and guide.endpoints.size()==2,"both visible endpoints connect")
	var rest: Vector2=guide.endpoints.get("a",Vector2.ZERO)
	field.set_velocity(Vector3.FORWARD,.9,Relativity.gamma_of_rapidity(Relativity.rapidity_of_beta(.9)))
	guide.refresh(field,camera,Vector2(960,540))
	check(guide.endpoints.a.distance_to(Vector2(480,270))<rest.distance_to(Vector2(480,270)),"aberration contracts the pattern toward travel")
	field.set_ship_position(5,0,0);guide.refresh(field,camera,Vector2(960,540))
	check(guide.endpoints.a!=rest,"travel changes the observed pattern")
	guide.refresh(field,camera,Vector2(960,540),null,true)
	check(guide.segments.is_empty() and guide.endpoints.is_empty(),"GR suppresses the guide")
	field.set_custom_stars([{id="a",pos=Vector3(0,0,100),t=5700.,flux=.001},{id="b",pos=Vector3(0,0,-100),t=5700.,flux=.001}])
	field.set_ship_position(0,0,0);field.set_velocity(Vector3.FORWARD,0,1)
	guide.refresh(field,camera,Vector2(960,540))
	check(guide.segments.is_empty(),"behind-camera source cannot mirror a line into view")
	field.set_custom_stars([{id="a",pos=Vector3(0,0,-100),t=5700.,flux=.001}])
	guide.refresh(field,camera,Vector2(960,540))
	check(guide.missing_count==1 and guide.segments.is_empty(),"missing star suppresses incident segment")
	field.append_stars([{id="a",pos=Vector3(1,0,-100),t=5700.,flux=.001}])
	guide.refresh(field,camera,Vector2(960,540))
	check(not guide.indices.has("a"),"duplicate physical identity is ambiguous")
	var bad := fixture();bad.figures[0].segments=[["a","missing"]]
	check(not guide.set_manifest(bad) and guide.figures.is_empty(),"unknown segment endpoint rejected")
	bad=fixture();bad.figures.append(bad.figures[0].duplicate(true))
	check(not guide.set_manifest(bad),"duplicate figure IDs rejected")
	bad=fixture();bad.figures[0].segments=[["a","a"]]
	check(not guide.set_manifest(bad),"self-loop rejected")
	guide.set_manifest(fixture())
	field.set_custom_stars([{id="a",pos=Vector3(-300,0,-100),t=5700.,flux=.001},{id="b",pos=Vector3(300,0,-100),t=5700.,flux=.001}])
	guide.refresh(field,camera,Vector2(960,540))
	check(guide.segments.size()==1 and absf(guide.segments[0].a.x)<.001 and absf(guide.segments[0].b.x-960.)<.001,"off-screen front endpoints clip at viewport edges")
	camera.fov=40;guide.refresh(field,camera,Vector2(1920,1080))
	check(guide.segments.size()==1 and absf(guide.segments[0].b.x-1920.)<.001,"zoom and viewport resize refresh clipping")
	field.set_exposure(0.);guide.refresh(field,camera,Vector2(960,540))
	check(guide.segments.is_empty(),"invisible endpoints yield no guide")
	field.set_exposure(5.)
	field.set_custom_stars([{id="a",pos=Vector3(-10,0,-100),t=5700.,flux=.001},{id="b",pos=Vector3(10,0,-100),t=5700.,flux=.001}])
	field.set_catalogue_replacements(["a"]);guide.refresh(field,camera,Vector2(960,540))
	check(guide.segments.is_empty(),"hidden replacement copy cannot carry a connector")
	field.set_catalogue_replacements([])
	field.catalogue_replacement_sources["a"]={dir=Vector3.FORWARD,t=5700.,lux=.001}
	guide.refresh(field,camera,Vector2(960,540))
	check(guide.segments.is_empty(),"finite replacement suppresses incident guide")
	field.catalogue_replacement_sources.clear()
	var sv := SystemView.new();root.add_child(sv)
	sv.relativistic_enabled=false
	sv.rendered_bodies=[{id="test-body",radius_km=100.,rel_km={x=0.,y=0.,z=1000.}}]
	guide.refresh(field,camera,Vector2(960,540),sv)
	check(guide.segments.is_empty(),"opaque globe across connector masks the whole segment")
	sv.hide();guide.refresh(field,camera,Vector2(960,540),sv)
	check(guide.segments.size()==1,"hidden body does not mask guide")
	sv.queue_free()
	field.set_custom_stars([{id="a",pos=Vector3(.02,0,-.01),t=5700.,flux=.001},{id="b",pos=Vector3(.03,0,-.01),t=5700.,flux=.001}])
	field.set_rebase_mode(Starfield.Rebase.CPU);field.set_ship_position(.0099,0,0)
	guide.refresh(field,camera,Vector2(960,540))
	var revision := field.identity_revision;var rebases := field.rebases
	var scans: int=guide.identity_scans;var before: Vector2=guide.endpoints.a
	field.set_ship_position(.0101,0,0);guide.refresh(field,camera,Vector2(960,540))
	check(field.identity_revision==revision and guide.identity_scans==scans and field.rebases>rebases,"warm rebase updates without rescanning identities")
	# Use the fixture viewport rather than the root window for the reference pinhole.
	var want := Vector2(480,270)+Vector2((.02-.0101)/.01,0)*(.5*540/tan(deg_to_rad(camera.fov)*.5))
	check(guide.endpoints.a.distance_to(want)<.01 and guide.endpoints.a.distance_to(before)>.01,"warm field endpoints follow travel across rebase boundary")
	for speed in [.999999, .999999999999]:
		field.set_velocity(Vector3.FORWARD,speed,Relativity.gamma_of_rapidity(Relativity.rapidity_of_beta(speed)))
		guide.refresh(field,camera,Vector2(960,540))
		var finite := true
		for sample in guide._samples.values():finite=finite and (sample.is_empty() or sample.direction.is_finite())
		check(finite,"uploaded near-c projection stays finite")
	await integrated()
	field.free();guide.free();camera.queue_free()
	finish()
func integrated() -> void:
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={stars=false,background=false,sky_state="rest"}
	root.add_child(demo);await process_frame
	demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
	var identify: Control=demo.star_identification
	var overlay: Control=identify.constellations
	check(overlay!=null and overlay.get_parent().layer==-30,"guide layer is between sky and geometry")
	var before: Dictionary=demo.sky_world.duplicate(true)
	identify.probe(Vector2(100,100))
	check(not overlay.visible and not identify.held,"dwell probe never activates guides")
	var key := InputEventKey.new();key.physical_keycode=KEY_I;key.pressed=true
	identify.handle_input(key)
	check(overlay.visible and identify.held,"I activates integrated guide")
	key.pressed=false;identify.handle_input(key)
	check(not overlay.visible and overlay.segments.is_empty(),"release clears guides immediately")
	identify.set_held(true);demo.get_window().focus_exited.emit()
	check(not overlay.visible,"focus loss clears guides")
	identify.suppressed=true;identify.set_held(true)
	check(not overlay.visible and not identify.held,"modal suppression refuses guide")
	identify.suppressed=false
	var edit := LineEdit.new();root.add_child(edit);edit.grab_focus();key.pressed=true
	check(not identify.handle_input(key) and not overlay.visible,"typing I does not activate guides")
	edit.release_focus();edit.queue_free()
	check(before==demo.sky_world and demo.journey_map==null,"guides do not alter world, create sim or commit")
	demo.queue_free();await process_frame
func finish() -> void:
	print("constellations: %d passed, %d failures" % [passed,failed]);quit(1 if failed else 0)
