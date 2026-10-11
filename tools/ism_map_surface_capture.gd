extends SceneTree
## Actual Navigation station; density shading toggles send no simulation intent.
var demo:Node
var failures:=0
func _initialize()->void:run.call_deferred()
func settle()->void:
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
func run()->void:
	root.size=Vector2i(1440,900);root.title="Local gas: instrument density surfaces"
	DirAccess.make_dir_recursive_absolute("res://renders/bubble_surface")
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"live_start":true,"sky_state":"rest","auto_view":true,"size":root.size}
	root.add_child(demo);await settle();demo.journey_auto_tick=false
	demo.consoles.go_to("navigation");demo.consoles.use("navigation","open");await settle()
	var map:GalaxyMap=demo.journey_map;map.frame_local_ism();await settle()
	var before:int=demo.journey_sim.world.tick
	for on:bool in [false,true]:
		map.ism_shading.button_pressed=on;await settle()
		root.get_texture().get_image().save_png("res://renders/bubble_surface/map_"+("density" if on else "boundaries")+".png")
	if demo.journey_sim.world.tick!=before:failures+=1
	var f:=FileAccess.open("res://renders/bubble_surface/map_capture.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"label":"False-colour gas-density instrument view; same source boundaries/adopted approximate depths, not naked-eye gas.","tick_before":before,"tick_after":demo.journey_sim.world.tick,"source_sha256":FileAccess.get_sha256(IsmLayer.PATH),"counts":map.ism_layer.last_drawn,"guides":map.ism_layer.show_depth_guides,"failures":failures},"  "))
	print("map-surface-capture: %d failures, %d media"%[failures,map.ism_layer.last_drawn.size()])
	demo.queue_free();await process_frame;quit(1 if failures else 0)
