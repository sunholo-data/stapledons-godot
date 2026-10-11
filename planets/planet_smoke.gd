extends RefCounted
## Exported-build check: every declared map loads from the bundle, and real
## Jupiter and Callisto shader discs are textured. Cold exported execution must
## fail for an omitted declaration/ALBEDO row/image; expectations are data-driven.
func run(main: Node, out_png: String) -> int:
 var sv: SystemView = main.system_view
 var declared := SystemView.read_texture_declarations()
 var required_ok := not declared.is_empty() and declared.size() == sv.albedo_table.size()
 var loaded := 0
 for id: String in declared:
  required_ok = required_ok and sv.albedo_table.has(id) and sv.albedo_table.get(id, {}).get("file", "") == declared[id]
  loaded += 1 if not sv._textures(id).is_empty() else 0
 var source := "assets/planets" if FileAccess.file_exists(SystemView.TEX_DIR.path_join("2k_jupiter.jpg")) else "res://planet_bundle"
 print("planet-smoke: %d/%d textured bodies (%s)" % [loaded, declared.size(), source])
 var ok := required_ok and loaded == declared.size()
 for target: Array in [["jupiter", "Jupiter", 71492.0, 0.538, 5.2], ["callisto", "Callisto", 2410.3, 0.19, 5.2]]:
  var id: String = target[0]
  var radius: float = target[2]
  var p_v: float = target[3]
  var au: float = target[4]
  var d := radius * 8.0
  var lux := Planets.disc_illuminance(127057.41052085394, p_v, radius, au, d, 0.0, 1.0)
  var b := {"id":id, "name":target[1], "kind":"planet" if id == "jupiter" else "moon", "host":"" if id == "jupiter" else "jupiter", "status":"confirmed",
   "rel_km":{"x":d,"y":0.0,"z":0.0}, "radius_km":radius, "flattening":0.0,
   "pole":{"x":0.0,"y":0.0,"z":1.0}, "w_deg":0.0, "sun_dir":{"x":-1.0,"y":0.0,"z":0.0},
   "r_au":au, "phase_deg":0.0, "e_v_lux":lux, "p_v":p_v, "minnaert_k":1.0, "ring_id":"",
   "light_age_s":0.0, "visitable":true, "source":"smoke"}
  main.camera.look(0.0,0.0,0.0)
  sv.set_view(main.exposure.pixel_rad, main.get_viewport().get_texture().get_size().y)
  var peak := Planets.rho_from_geometric_albedo(p_v, 1.0) * Planets.star_illuminance_at(127057.41052085394, au) / PI
  sv.update({"jd":2460251.5,"ephemeris":"jpl-approx","frame":"galactic","bodies":[b]}, 0.25 / peak)
  var textured: bool = sv.discs[id].material_override.get_shader_parameter("textured")
  ok = ok and textured
  print("planet-smoke: %s disc %s" % [target[1], "textured" if textured else "UNTEXTURED"])
  if out_png != "":
   var path := out_png if id == "jupiter" else out_png.get_basename() + "_callisto.png"
   var img: Image = await main._grab()
   img.save_png(path)
   print("planet-smoke: wrote %s" % path)
 return 0 if ok else 1
