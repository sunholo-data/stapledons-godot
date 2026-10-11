extends SceneTree
## Native reference capture through the production SystemView/albedo shader.
## Recorded sim bodies, staged at six radii at opposition. This is a labelled
## photographer comparison, not a recorded journey or a different physics model.
const OUT := "res://renders/moons"
const E1 := 127057.41052085394
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 root.size = Vector2i(960, 720)
 var viewport := SubViewport.new()
 viewport.size = root.size
 viewport.own_world_3d = true
 viewport.use_hdr_2d = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color.BLACK
 env.tonemap_mode = Environment.TONE_MAPPER_AGX
 env.glow_enabled = false
 var we := WorldEnvironment.new()
 we.environment = env
 viewport.add_child(we)
 var camera := FreeLookCamera.new()
 camera.current = true
 camera.fov = 35.0
 viewport.add_child(camera)
 var sf := Starfield.new()
 sf.set_custom_stars([])
 sf.build()
 viewport.add_child(sf)
 var sv := SystemView.new()
 sv.setup(sf, true)
 sv.set_view(2.0 * tan(deg_to_rad(17.5)) / 720.0, 720.0)
 viewport.add_child(sv)
 var bodies := {}
 for line in FileAccess.get_file_as_string("res://tests/fixtures/system_sol.ndjson").split("\n"):
  var record = JSON.parse_string(line)
  if record is Dictionary and record.get("changes", {}).has("system"):
   for b: Dictionary in SimBridge.parse_system(record.changes.system).bodies:
    bodies[b.id] = b
   break
 DirAccess.make_dir_recursive_absolute(OUT)
 var report := []
 var tiles := []
 var failures := 0
 for id: String in SystemView.read_texture_declarations():
  if not id in ["callisto", "io", "europa", "ganymede", "mimas", "enceladus", "tethys", "dione", "rhea", "triton"]:
   continue
  var b: Dictionary = bodies[id].duplicate(true)
  var d: float = 6.0 * b.radius_km
  b.rel_km = {"x":d, "y":0.0, "z":0.0}
  b.sun_dir = {"x":-1.0, "y":0.0, "z":0.0}
  b.pole = {"x":0.0, "y":0.0, "z":1.0}
  b.w_deg = 0.0
  b.phase_deg = 0.0
  b.e_v_lux = Planets.disc_illuminance(E1, b.p_v, b.radius_km, b.r_au, d, 0.0, b.minnaert_k)
  var peak := Planets.rho_from_geometric_albedo(b.p_v, b.minnaert_k) * Planets.star_illuminance_at(E1, b.r_au) / PI
  var exposure := 0.18 / peak
  var uniform: Image
  if id == "callisto":
   sv.use_textures = false
   sv.update({"bodies":[b]}, exposure)
   uniform = await grab(viewport)
   uniform.save_png(OUT.path_join("callisto_uniform.png"))
   tiles.append(uniform)
  sv.use_textures = true
  sv.update({"bodies":[b]}, exposure)
  var img := await grab(viewport)
  img.save_png(OUT.path_join(id + "_textured.png"))
  tiles.append(img)
  var textured: bool = sv.discs[id].material_override.get_shader_parameter("textured")
  var changed := 0
  if uniform != null:
   for y in 720:
    for x in 960:
     if absf(img.get_pixel(x,y).get_luminance() - uniform.get_pixel(x,y).get_luminance()) > 0.01:
      changed += 1
  if not textured or (id == "callisto" and changed < 1000):
   failures += 1
  report.append({"id":id, "textured":textured, "callisto_changed_pixels":changed, "radius_km":b.radius_km, "p_v":b.p_v, "staged_distance_radii":6, "fixed_linear_centre_uniform":0.18, "source":sv.albedo_table[id].file})
  print("moon-capture: ", id, " textured=", textured, " changed=", changed)
 var sheet := Image.create(960, 540 * 3, false, Image.FORMAT_RGB8)
 sheet.fill(Color.BLACK)
 for i in tiles.size():
  var thumb: Image = tiles[i].duplicate()
  thumb.resize(320, 240, Image.INTERPOLATE_LANCZOS)
  thumb.convert(Image.FORMAT_RGB8)
  sheet.blit_rect(thumb, Rect2i(0,0,320,240), Vector2i((i % 3) * 320, (i / 3) * 270))
 sheet.save_png(OUT.path_join("moon_sheet.png"))
 var file := FileAccess.open(OUT.path_join("capture.json"), FileAccess.WRITE)
 file.store_string(JSON.stringify({"staging":"six radii, opposition, fixed photographer exposure; no journey", "cases":report, "stats":sv.presentation_stats(), "failures":failures}, "  ") + "\n")
 viewport.queue_free()
 await process_frame
 print("moon-capture: %d maps, %d failures" % [report.size(), failures])
 quit(1 if failures else 0)
func grab(viewport: SubViewport) -> Image:
 for i in 4:
  await process_frame
 await RenderingServer.frame_post_draw
 return viewport.get_texture().get_image()
