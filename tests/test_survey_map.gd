extends SceneTree
const Layer = preload("res://ui/survey_map_layer.gd")
const Index = preload("res://ui/observation_index.gd")
class FakeMap:
	extends Node3D
	var camera := Camera3D.new()
	var intents := 0
	func select(_id):intents += 1
	func preselect(_id):intents += 1
	func plan(_id):intents += 1
var passed := 0
var failures := 0
var received: Array = []
var chosen_fields: Array = []
func check(ok: bool, detail: String) -> void:
	if ok:passed += 1
	else:failures += 1;print("FAIL survey-map: "+detail)
func _initialize() -> void:
	var index := Index.new()
	check(index.load_files(),"actual source index available")
	var map := FakeMap.new()
	root.add_child(map)
	map.add_child(map.camera)
	var layer := Layer.new()
	map.add_child(layer)
	layer.setup(map,index)
	check(layer.last_error.is_empty(),"real package footprint loaded")
	check(layer.fields.size()==1 and layer.fields.has("abell3128-vis"),"only registered actual plate gets footprint")
	check(layer.source_ids.size()==40,"all exact measured source identities retained")
	check(not layer.fields.has("m81-outreach") and not layer.fields.has("ngc1291-outreach"),"outreach images have no invented registration")
	check(Layer.direction_world({x=1.,y=0.,z=0.}).is_equal_approx(Vector3(0,0,-8)),"galactic centre direction uses shared orientation")
	check(Layer.direction_world({x=0.,y=1.,z=0.}).is_equal_approx(Vector3(-8,0,0)),"longitude grows left without mirrored frame")
	check(Layer.direction_world({x=0.,y=0.,z=1.}).is_equal_approx(Vector3(0,8,0)),"north galactic pole points up")
	check(Layer.FRAME_LABEL.contains("Directions from Sol") and Layer.FRAME_LABEL.contains("depth not shown"),"direction-only frame labelled")
	var initial_transform := map.camera.transform
	layer.activate(true)
	layer.layout_for(Vector2(1440,900))
	check(layer.visible and layer.size==Vector2(1010,900),"overlay excludes existing side panel")
	check(map.camera.transform == initial_transform,"activation never changes local camera")
	layer.object_selected.connect(func(ref):received.append(ref))
	layer.field_selected.connect(func(id):chosen_fields.append(id))
	check(layer.choose_field("abell3128-vis") and chosen_fields==["abell3128-vis"] and received.is_empty(),"field browsing does not invent a source selection")
	var sid := "DR1_R2:dr1.mer_catalogue_wide_survey:102017310:-524917322525922548"
	check(layer.choose_object(sid) and received==[{kind="survey",id=sid}],"explicit source selection emits exact typed reference")
	check(not layer.choose_object("-524917322525922548") and not layer.choose_object("Euclid -524917322525922548"),"raw ID or label cannot substitute for composite identity")
	check(layer.selected_id==sid and layer.source_choice.get_item_metadata(layer.source_choice.selected)==sid,"selected source remains exact in selector and marker state")
	check(map.intents==0,"survey choices never enter travel intent methods")
	layer.activate(false)
	check(not layer.visible and not layer.active and map.camera.transform==initial_transform,"deactivation leaves camera and destinations alone")
	if not FileAccess.file_exists(Layer.FOOTPRINTS):
		print("survey-map: %d passed, %d failures" % [passed,failures])
		map.queue_free()
		quit(1)
		return
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Layer.FOOTPRINTS))
	# Frozen scalar-TAN + published Hipparcos matrix references (not package output).
	# tools/observation_projection_oracle.py now recomputes centre/physical edges
	# from pinned FITS bytes with scalar TAN and the defining Galactic angles.
	# This frozen-table check uses 1e-12; the independent oracle permits 2e-10
	# for the production matrix's documented 10-decimal rounding.
	var expected_centre := [-0.0568021542852528,-0.6250654098573947,-0.7785028893216913]
	var expected_corners := [[-0.056734031568549725,-0.625253894475796,-0.7783564845998978],[-0.05656390550680765,-0.625020673858644,-0.7785561520256306],[-0.056870273471548695,-0.624876886820687,-0.7786492460192814],[-0.057040399967063865,-0.6251101074271415,-0.7784495785713368]]
	var real_field: Dictionary = raw.fields[0]
	var axes := ["x","y","z"]
	var centre_ok := true
	var corners_ok := true
	for i in 3:
		centre_ok = centre_ok and absf(real_field.centre_galactic[axes[i]]-expected_centre[i]) < 1e-12
		for k in 4:corners_ok = corners_ok and absf(real_field.corners_galactic[k][axes[i]]-expected_corners[k][i]) < 1e-12
	check(centre_ok,"real WCS image centre matches independent oracle")
	check(corners_ok,"four FITS physical edges match independent oracle, not pixel centres")
	var bad := raw.duplicate(true)
	bad.pack_id="wrong"
	check(not layer.set_footprints(bad) and layer.fields.is_empty() and layer.source_ids.is_empty(),"wrong pack clears old survey view")
	check(layer.set_footprints(raw),"valid data reloads")
	bad=raw.duplicate(true);bad.fields[0].plate_id="m81-outreach"
	check(not layer.set_footprints(bad),"unregistered plate cannot receive copied coordinates")
	bad=raw.duplicate(true);bad.fields[0].centre_galactic.x=NAN
	check(not layer.set_footprints(bad),"nonfinite directions rejected")
	bad=raw.duplicate(true);bad.fields.append(bad.fields[0].duplicate(true))
	check(not layer.set_footprints(bad),"duplicate field identities rejected")
	check(layer.set_footprints(raw),"restore real source data")
	await process_frame
	map.camera.look_at(Layer.direction_world(layer.fields["abell3128-vis"].centre_galactic),Vector3.UP)
	layer.activate(true)
	await process_frame
	await process_frame
	check(not map.camera.is_position_behind(Layer.direction_world(layer.fields["abell3128-vis"].centre_galactic)),"visible real field exercises draw callback without renderer errors")
	map.queue_free()
	print("survey-map: %d passed, %d failures" % [passed,failures])
	quit(1 if failures else 0)
