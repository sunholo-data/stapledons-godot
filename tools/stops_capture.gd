extends SceneTree
## D-54 relative-size stops, rendered (design_docs/planned/r1/relative-size-stops.md):
## free navigation through the real sim to a red dwarf (TRAPPIST-1), a giant (Aldebaran),
## a Sun-like star (alpha Cen A), an uncited star (Barnard's Star, still 1,000 AU), home
## (Earth), then the Moon, Jupiter, Callisto and Saturn from the map's in-system list.
## Each stop: the forward view and the sky alone -> renders/stops/<n>_<stop>[_sky].png,
## plus the map with the in-system list at Sol. Needs a GPU window. Open the PNGs.
var demo: Node
const OUT := "res://renders/stops"
var log_rows: Array = []
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size = Vector2i(1280, 720)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate(); root.add_child(demo); demo.auto = false
	await process_frame
	if not demo.ready_ok: quit(1); return
	demo.journey_auto_tick = false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	demo.open_navigation(); await process_frame
	var n := 0
	for stop in [["trappist1", "Gaia DR3 2635476908753563008"], ["aldebaran", "CNS5:1142"], ["acen_a", "CNS5:3627"], ["barnard", "Gaia DR3 4472832130942575872"], ["earth", "Sol"]]:
		n += 1
		if stop[1] == "Sol": demo.journey_map.plan_home()
		else: demo.journey_map.preselect(demo.journey_map.index_of(stop[1]))
		if not await leg(): quit(1); return
		await shots("%d_%s" % [n, stop[0]])
		if stop[0] == "earth": await map_shot("%d_map_in_system" % n)
	for body in ["moon", "saturn", "callisto", "jupiter"]:
		n += 1
		demo.journey_map.plan_body(body)
		if not await leg(): quit(1); return
		await shots("%d_%s" % [n, body])
	var f := FileAccess.open(OUT + "/stops.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(log_rows, "  ") + "\n")
	print("stops-capture: OK %d stops" % log_rows.size()); quit()
func leg() -> bool:
	var map = demo.journey_map
	demo.journey_tick()
	if not (map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey):
		printerr("stops-capture: commit failed: ", map.status_text()); return false
	for i in 5000:
		if not demo.journey_tick() or not demo.live_journey: break
	await process_frame
	return map.journey_state() == "arrived"
func shots(name: String) -> void:
	var plan: Dictionary = demo.sky_world.journey.plan
	var hold: String = str(plan.get("hold", {}).get("body", "")) if plan.get("hold") is Dictionary else ""
	var row := {"name": name, "hud": demo.distances_text(demo.sky_world, null, demo.star_identification.info.names, demo.leg_from)}
	for b: Dictionary in demo.sky_world.get("system", {}).get("bodies", []):
		if b.id == hold:
			var d := Planets.length64(Planets.world_of(b.rel_km))
			row.merge({"body": b.id, "radius_km": b.radius_km, "distance_km": d, "apparent_deg": rad_to_deg(2.0 * Planets.angular_radius(b.radius_km, d)), "source": b.get("source", "")})
	log_rows.append(row); print("stop ", JSON.stringify(row))
	demo.look_direction("forward")
	await shot(name)
	demo.toggle_sky_only(); await shot(name + "_sky")
	# AUTO view (D-38): the body-aware exposure, so a bright disc shows its surface.
	demo.set_auto_view(true); await shot(name + "_sky_auto"); demo.set_auto_view(false)
	demo.toggle_sky_only()
func shot(name: String) -> void:
	for i in 8: await process_frame
	demo.sky.update_exposure()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
func map_shot(name: String) -> void:
	var w: Window = demo.navigation_window
	w.popup_centered(); demo.journey_map.refresh()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	w.get_texture().get_image().save_png(OUT + "/" + name + ".png")
	demo.close_navigation()
