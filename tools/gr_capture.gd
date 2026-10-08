extends SceneTree
## make capture-bh-sky (M3.5a/b of R1-M3-BLACK-HOLES): the lensed sky as the player sees it,
## through InteriorSky (the unified 3D ship's sky, D-52), sky-only, to renders/bh_sky/*.png.
## A person opens them (the sprint JSON notes record who and when).
##   grid_r{10,5,3}_toward_hover   the debug grid: the shadow, the photon ring, warped lines
##   grid_r5_toward_orbit          the same in orbit at r = 5 (beta_local 0.354, aberrated)
##   mw_off_toward                 the Milky Way and the large-tier catalogue, no hole (reference)
##   mw_r{10,5,3}_toward_hover     ... lensed: hole toward Sgr A* as seen from Sol (design OQ5:
##                                 the background is the sky seen from Sol, not the
##                                 Galactic-Centre sky), stars with both images
##   mw_r5_{side,away}_hover       90 deg off and astern of the hole
##   ring_r{10,100,1000}           a bright star exactly behind the hole: the Einstein ring
##                                 (ring-star path), on a black sky
##   secondary_r10                 a star 20 deg off the hole at r = 10: both images
## Exposure: the player's auto exposure, 2 EV brighter (legibility of the dim Milky Way in review).
## The gr states come from the CPU reference (GrLens.reference_state), not the sim: M3.6 drives
## the same InteriorSky.set_gr from the sim's protocol-2.6 gr section.

const SIZE := Vector2i(1280, 720)
const OUT := "res://renders/bh_sky"
const HOLE_GAL := [1.0, 0.0, 0.0] # galactic centre

var sky: InteriorSky
var h := Vector3(0.0, 0.0, -1.0)
var failures := 0
var shots := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = SIZE
	DirAccess.make_dir_recursive_absolute(OUT)
	if not Schwarzschild.load_tables():
		print("capture-bh-sky: FAIL %s" % Schwarzschild.load_error)
		quit(1)
		return
	var w := SkyFrame.to_world64(HOLE_GAL)
	h = Vector3(w[0], w[1], w[2])
	sky = InteriorSky.new()
	root.add_child(sky)
	sky.setup({"forward": [0.0, 0.0, 1.0], "up": [0.0, 1.0, 0.0], "position_m": [0.0, 0.0, 0.0]}, 90.0, SIZE,
		{"tier": "large", "planet_textures": false, "planet_preload": false, "planet_smooth_lod": false})
	var shown := TextureRect.new()
	shown.texture = sky.get_texture()
	root.add_child(shown)
	sky.env.glow_enabled = false
	sky.exposure.bias = -2.0 # 2 EV brighter than the player's auto exposure, so the dim Milky Way reads in a review
	sky.starfield.set_ship_position(0.0, 0.0, 0.0)
	var t0 := Time.get_ticks_msec()
	# the debug grid
	sky.background.set_grid(true)
	for r in [10.0, 5.0, 3.0]:
		await _shot("grid_r%d_toward_hover" % int(r), r, 0.0, 0.0, 0.0)
	await _shot("grid_r5_toward_orbit", 5.0, 0.35355339059327373, -0.25, 0.0)
	# the Milky Way and the catalogue
	sky.background.set_grid(false)
	await _shot("mw_off_toward", 0.0, 0.0, 0.0, 0.0)
	for r in [10.0, 5.0, 3.0]:
		await _shot("mw_r%d_toward_hover" % int(r), r, 0.0, 0.0, 0.0)
	await _shot("mw_r5_side_hover", 5.0, 0.0, -PI * 0.5, 0.0)
	await _shot("mw_r5_away_hover", 5.0, 0.0, PI, 0.0)
	# synthetic stars on a black sky: the ring-star path and the two images
	sky.background.set_exposure(0.0)
	var keep_tiers := sky.starfield.tiers.duplicate()
	for r in [10.0, 100.0, 1000.0]:
		sky.starfield.set_custom_stars([{"pos": h * 1000.0, "t": 9000.0, "flux": 2e-5}])
		await _shot("ring_r%d" % int(r), r, 0.0, 0.0, 0.0, 60.0 if r < 1000.0 else 12.0)
	var src := (h * cos(deg_to_rad(20.0)) + Vector3.RIGHT * sin(deg_to_rad(20.0))).normalized()
	sky.starfield.set_custom_stars([{"pos": src * 1000.0, "t": 9000.0, "flux": 2e-5}])
	await _shot("secondary_r10", 10.0, 0.0, 0.0, 0.0, 100.0)
	print("capture-bh-sky: tiers %s, %d renders in %.1f s to %s" % [keep_tiers, shots, (Time.get_ticks_msec() - t0) / 1000.0, ProjectSettings.globalize_path(OUT)])
	print("capture-bh-sky: %s" % ("OK" if failures == 0 else "FAIL"))
	quit(1 if failures > 0 else 0)


## r = 0: GR off. yaw/pitch turn the camera from the hole direction (world -Z).
func _shot(name: String, r: float, b_local: float, yaw: float, pitch: float, fov := 90.0) -> void:
	sky.camera.fov = fov
	sky.view_fov = fov
	sky.configure_pixel()
	sky.background.material.set_shader_parameter("screen_px_rad", deg_to_rad(fov) / SIZE.y)
	sky.camera.look(yaw, pitch, 0.0)
	sky.eye_meter = SkyMeter.new() # the custom-star renders change the field under the meter's cache
	if r > 0.0:
		# in orbit the motion is tangential (world +X, to starboard)
		sky.set_gr(GrLens.reference_state(r, PackedFloat64Array(HOLE_GAL), b_local, PackedFloat64Array([0.0, -1.0, 0.0])))
		sky.gr_lens.refresh_now()
	else:
		sky.set_gr({})
	sky.update_exposure()
	if sky.gr_lens.active:
		sky.gr_lens.set_exposure(sky.exposure.star_scale(), sky.exposure.psf_sigma_rad())
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := sky.get_texture().get_image()
	var path := "%s/%s.png" % [OUT, name]
	if img == null or img.save_png(path) != OK:
		failures += 1
		print("capture-bh-sky: FAIL %s" % path)
		return
	shots += 1
	print("capture-bh-sky: %s  (%s)" % [path, sky.gr_lens.debug_line()])
