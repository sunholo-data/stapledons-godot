extends SceneTree
## SPIKE (stylised plants, D-103 follow-up; design_docs/planned/r2/stylised-plants-spike.md).
## Review tool only: nothing here ships. Renders one plant bed (a frond, a shrub, a small tree,
## vines on a rail and a "grown" planter) beside the captain through the player's Bow view, in
## four treatments, and swaps the bridge's rim fronds for each treatment's frond:
##   A  today's Blender plants: the rim-frond mesh (the only plant in the ship today) at every slot
##   B  painted cards: alpha-cut gouache sprites (Codex Sol image_gen, renders/plants_spike/cards)
##      on view-locked cards, lit through a rounded "sphere" normal with three toon bands
##   C  stylised 3D: sinuous swept tubes, lathed planters, arching ribbon leaves and ellipsoid leaf
##      clouds, three toon bands and an inverted-hull violet ink line; painted leaf-clump cards on
##      the canopy (the hybrid)
##   D  procedural leaf clouds: C's stems and planters, canopies and shrubs as hundreds of small
##      generated leaf quads with cloud-centred normals (painterly volume, no image generation)
## Each in deep space (the spire is the key), near the Sun (the star is the key) and at 0.99c.
## Writes renders/plants_spike/out/<V>_<state>.png, <V>_<state>_port3x.png, _stbd3x.png,
## contact_sheet.png and spike.json (GPU ms of the 3D viewport, primitives, determinism).
## Usage: godot --path . --script tools/plants_spike_capture.gd
var demo: Node
var out := "res://renders/plants_spike/out"
var cards_dir := "res://renders/plants_spike/cards"
var px := Vector2i(1280, 720)
var bed := Node3D.new()
var rows := []
var toon_shader: Shader
var ink_shader: Shader
var cards := {}
var leaf_tex: ImageTexture
const INK := Color(0.24, 0.13, 0.33)
const CREAM := Color(0.86, 0.80, 0.66)
const TEAL := Color(0.30, 0.55, 0.55)
const LEAF := Color(0.42, 0.55, 0.28)
const LEAF2 := Color(0.62, 0.66, 0.30)
const CORAL := Color(0.93, 0.50, 0.42)
const BARK := Color(0.62, 0.52, 0.40)
## Slots on the bridge deck (glTF, floor y = 82; the captain spawns at (0, 82, -13), the camera
## sits at (0, 87.5, -4) looking at the bow, -z). Port bed left of the captain, starboard right.
const SLOTS := {
	"tree": Vector3(-7.6, 82.0, -19.0),
	"frond": Vector3(-4.6, 82.0, -14.6),
	"shrub": Vector3(-7.4, 82.0, -13.2),
	"grown": Vector3(4.8, 82.0, -14.4),
	"vines": Vector3(7.6, 82.0, -17.0),
}
const HEIGHT := {"tree": 3.8, "frond": 1.7, "shrub": 1.1, "grown": 1.9, "vines": 2.2}
const FROND_BASE_LOCAL := Vector3(20.68, 0.0, 0.0) # the rim frond mesh's root in its node frame


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": px, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("plants-spike: FAIL demo did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	_shaders()
	_load_cards()
	leaf_tex = _leaf_texture()
	demo.geometry.add_child(bed)
	var rest: Dictionary = _with_sun(demo.sky_states.rest)
	demo.sky_states["star"] = rest
	demo.sky_states["deep"] = _pushed(rest, 2.5e8)
	var rim := _rim_fronds()
	RenderingServer.viewport_set_measure_render_time(demo.geometry_view.get_viewport_rid(), true)
	for v: String in ["0", "A", "B", "C", "D"]:
		_build(v, rim)
		for st: String in ["deep", "star", "cruise"]:
			if v == "0" and st != "deep":
				continue
			demo.set_sky_state(st)
			await _bow("%s_%s" % [v, st], v, st)
		# determinism + cost, deep space
		demo.set_sky_state("deep")
		await _measure(v)
	_sheet()
	var f := FileAccess.open(out + "/spike.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "stylised plants spike: Bow view captures, 3D viewport GPU ms, determinism", "rows": rows}, "  "))
	print("plants-spike: %d rows" % rows.size())
	quit(0)


# ------------------------------------------------------------------ scene plumbing (from deck_dl2_capture)
static func _with_sun(world: Dictionary) -> Dictionary:
	var w := world.duplicate(true)
	var lines := FileAccess.get_file_as_string("res://tests/fixtures/system_sol.ndjson").strip_edges().split("\n")
	var sys: Dictionary = SimBridge.parse_system(JSON.parse_string(lines[1]).changes.system)
	var earth := {}
	for b: Dictionary in sys.bodies:
		if b.id == "earth":
			earth = b.rel_km.duplicate()
	var keep := []
	for b: Dictionary in sys.bodies:
		if b.id == "earth":
			continue
		b.rel_km = {"x": b.rel_km.x - earth.x, "y": b.rel_km.y - earth.y, "z": b.rel_km.z - earth.z}
		if b.id == "sun":
			var d := sqrt(b.rel_km.x * b.rel_km.x + b.rel_km.y * b.rel_km.y + b.rel_km.z * b.rel_km.z)
			b.e_v_lux = 1.27e5 * pow(SystemView.AU_KM / d, 2.0)
		keep.append(b)
	sys.bodies = keep
	w.system = sys
	return w


static func _pushed(world: Dictionary, s: float) -> Dictionary:
	var w := world.duplicate(true)
	for b: Dictionary in w.system.bodies:
		var r: Dictionary = b.rel_km
		b.rel_km = {"x": r.x * s, "y": r.y * s, "z": r.z * s}
		if b.has("e_v_lux"):
			b.e_v_lux = float(b.e_v_lux) / (s * s)
	return w


func _settle(frames := 240) -> void:
	for k in frames:
		demo._process(1.0 / 60.0)


func _grab() -> Image:
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _bow(name: String, v: String, st: String) -> void:
	demo.consoles.cancel_walk()
	demo.director.release()
	demo.camera_mode = "player"
	demo.director.walk("bow")
	demo.avatar_pos = demo.bridge_spawn()
	_settle()
	var img: Image = await _grab()
	img.save_png("%s/%s.png" % [out, name])
	for side: String in ["port", "stbd"]:
		var r := _crop_rect(side)
		var c := img.get_region(r)
		c.resize(r.size.x * 3, r.size.y * 3, Image.INTERPOLATE_NEAREST)
		c.save_png("%s/%s_%s3x.png" % [out, name, side])
	var rig: Dictionary = demo.lighting
	rows.append({"shot": name, "variant": v, "state": st, "star": demo.star_light.target.get("name", ""),
		"star_energy": demo.star_light.light.light_energy, "spire_energy": rig.spire.light_energy, "key_energy": rig.key.light_energy})
	print("shot %s star %.2f spire %.2f key %.2f" % [name, demo.star_light.light.light_energy, rig.spire.light_energy, rig.key.light_energy])


## The bed's screen box at game size, as a 1/3-frame window (shown 3x, nearest: real game pixels).
func _crop_rect(side: String) -> Rect2i:
	var cam: Camera3D = demo.camera
	var pts := []
	for k: String in SLOTS:
		var p: Vector3 = SLOTS[k]
		if (side == "port") == (p.x < 0.0):
			pts.append(cam.unproject_position(p + Vector3(0, HEIGHT[k] * 0.5, 0)))
	var c := Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	c /= max(1, pts.size())
	var w := px.x / 3
	var h := px.y / 3
	var x := clampi(int(c.x) - w / 2, 0, px.x - w)
	var y := clampi(int(c.y) - h / 2, 0, px.y - h)
	return Rect2i(x, y, w, h)


func _measure(v: String) -> void:
	_settle(30)
	var ms := 0.0
	var prims := 0
	var n := 120
	await RenderingServer.frame_post_draw
	var t0 := Time.get_ticks_usec()
	for k in n:
		await RenderingServer.frame_post_draw
		prims = RenderingServer.viewport_get_render_info(demo.geometry_view.get_viewport_rid(), RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE, RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
	ms = (Time.get_ticks_usec() - t0) / 1000.0
	var bed_tris := 0
	for m in bed.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.visible and mi.mesh != null:
			for s in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
				bed_tris += idx.size() / 3 if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	rows.append({"variant": v, "frame_ms_mean_vsync_off": ms / n, "visible_primitives_3d": prims, "plant_triangles": bed_tris})
	print("measure %s frame %.2f ms prims %d plant tris %d" % [v, ms / n, prims, bed_tris])


func _sheet() -> void:
	var w := 480
	var h := 270
	var g := 16
	var lab := 70
	var states := ["deep", "star", "cruise"]
	var vs := ["A", "B", "C", "D"]
	var img := Image.create(lab + 3 * (w + g) + g, 4 * (h + g) + g, false, Image.FORMAT_RGB8)
	img.fill(Color(0.06, 0.06, 0.08))
	for r in vs.size():
		# a row marker: r+1 ticks (A=1 ... D=4), since the sheet has no font
		for t in r + 1:
			img.fill_rect(Rect2i(16 + t * 12, g + r * (h + g) + h / 2 - 10, 8, 20), Color(0.9, 0.8, 0.5))
		for c in states.size():
			var path := ProjectSettings.globalize_path("%s/%s_%s.png" % [out, vs[r], states[c]])
			if not FileAccess.file_exists(path):
				continue
			var f := Image.load_from_file(path)
			f.convert(Image.FORMAT_RGB8)
			f.resize(w, h, Image.INTERPOLATE_LANCZOS)
			img.blit_rect(f, Rect2i(0, 0, w, h), Vector2i(lab + g + c * (w + g), g + r * (h + g)))
	img.save_png("%s/contact_sheet.png" % out)


# ------------------------------------------------------------------ materials
func _shaders() -> void:
	toon_shader = Shader.new()
	toon_shader.code = """
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform bool use_tex = false;
uniform bool use_vcol = false;
uniform float scissor = 0.5;
uniform float sphere_mix = 0.0;
instance uniform vec3 cloud_center = vec3(0.0);
instance uniform vec3 cloud_radii = vec3(1.0);
uniform float card_bias = 0.0;
uniform float wind_amp = 0.0;
uniform float wind_time = 0.7;
uniform float wind_height = 1.0;
uniform vec4 ink : source_color = vec4(0.24, 0.13, 0.33, 1.0);
uniform float band_gain = 1.0;
uniform vec4 uv_rect = vec4(0.0, 0.0, 1.0, 1.0);
varying vec3 world_pos;
void vertex() {
	float h = clamp(VERTEX.y / wind_height, 0.0, 1.0);
	VERTEX.x += sin(wind_time * 1.3 + MODEL_MATRIX[3].x * 0.7 + MODEL_MATRIX[3].z * 0.4) * wind_amp * h * h;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec4 c = albedo;
	if (use_vcol) { c.rgb *= COLOR.rgb; }
	if (use_tex) {
		vec4 t = texture(tex, uv_rect.xy + UV * uv_rect.zw);
		if (t.a < scissor) { discard; }
		float edge = smoothstep(scissor, 0.97, t.a);
		c.rgb *= mix(ink.rgb / max(albedo.rgb, vec3(0.01)), t.rgb, edge);
	}
	ALBEDO = c.rgb;
	if (sphere_mix > 0.0) {
		vec3 d = (world_pos - cloud_center) / cloud_radii;
		vec3 cam_back = INV_VIEW_MATRIX[2].xyz;
		vec3 nw = normalize(normalize(d + vec3(1e-4)) + cam_back * card_bias);
		vec3 nv = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);
		vec3 base = FRONT_FACING ? NORMAL : -NORMAL;
		NORMAL = normalize(mix(base, nv, sphere_mix));
	} else if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
}
void light() {
	float ndl = dot(NORMAL, LIGHT);
	float b = ndl > 0.45 ? 1.0 : (ndl > 0.0 ? 0.55 : 0.2);
	DIFFUSE_LIGHT += b * ATTENUATION * LIGHT_COLOR * band_gain / PI;
}
"""
	ink_shader = Shader.new()
	ink_shader.code = """
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;
uniform vec4 ink : source_color = vec4(0.24, 0.13, 0.33, 1.0);
uniform float grow = 0.03;
void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	VERTEX += NORMAL * grow / max(s, 1e-3);
}
void fragment() { ALBEDO = ink.rgb; }
"""


func _toon(col: Color, inked := true, extra := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = toon_shader
	m.set_shader_parameter("albedo", col)
	for k: String in extra:
		if k != "ink_grow":
			m.set_shader_parameter(k, extra[k])
	if inked:
		var o := ShaderMaterial.new()
		o.shader = ink_shader
		o.set_shader_parameter("ink", INK)
		o.set_shader_parameter("grow", extra.get("ink_grow", 0.045))
		m.next_pass = o
	return m


func _load_cards() -> void:
	for k: String in ["frond", "shrub", "tree", "vines", "grown_planter"]:
		var p := ProjectSettings.globalize_path("%s/%s.png" % [cards_dir, k])
		var img := Image.load_from_file(p)
		img.generate_mipmaps()
		cards[k] = ImageTexture.create_from_image(img)


## D: a generated leaf-cluster sprite (five leaves, ink rim), 128 px, deterministic.
func _leaf_texture() -> ImageTexture:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var leaves := [[64.0, 70.0, 0.0], [44.0, 58.0, -0.7], [84.0, 58.0, 0.7], [52.0, 86.0, -0.35], [78.0, 88.0, 0.4]]
	for y in n:
		for x in n:
			var best := 9.0
			var shade := 0.0
			for lf: Array in leaves:
				var dx := x - float(lf[0])
				var dy := y - float(lf[1])
				var a: float = lf[2]
				var u := dx * cos(a) + dy * sin(a)
				var v := -dx * sin(a) + dy * cos(a)
				var r := sqrt(pow(u / 13.0, 2) + pow(v / 26.0, 2))
				if r < best:
					best = r
					shade = clampf(0.75 + 0.25 * (-v / 26.0) - 0.15 * absf(u) / 13.0, 0.4, 1.0)
			if best < 1.0:
				var col := Color(shade, shade, shade, 1.0)
				if best > 0.9:
					col = INK # the ink rim
				img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ geometry helpers
static func _bez(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, n := 24) -> PackedVector3Array:
	var pts := PackedVector3Array()
	for i in n + 1:
		var t := float(i) / n
		var u := 1.0 - t
		pts.append(u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3)
	return pts


## A swept tube along `pts` (parallel-transport frames, smooth normals), radius r0 -> r1.
static func _tube(pts: PackedVector3Array, r0: float, r1: float, sides := 14) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var rings := []
	var t_prev := (pts[1] - pts[0]).normalized()
	var nrm := t_prev.cross(Vector3.UP if absf(t_prev.y) < 0.9 else Vector3.RIGHT).normalized()
	for i in n:
		var t := ((pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)])).normalized()
		var ax := t_prev.cross(t)
		if ax.length() > 1e-6:
			nrm = nrm.rotated(ax.normalized(), t_prev.angle_to(t))
		t_prev = t
		var bin := t.cross(nrm).normalized()
		var r := lerpf(r0, r1, float(i) / (n - 1))
		var ring := []
		for s in sides:
			var a := TAU * s / sides
			var d := nrm * cos(a) + bin * sin(a)
			ring.append([pts[i] + d * r, d])
		rings.append(ring)
	for i in n - 1:
		for s in sides:
			var s2 := (s + 1) % sides
			for q: Array in [rings[i][s], rings[i + 1][s], rings[i + 1][s2], rings[i][s], rings[i + 1][s2], rings[i][s2]]:
				st.set_normal(q[1])
				st.add_vertex(q[0])
	return st.commit()


## A leaf ribbon along `pts`, width w(t) = w * sin(pi t)^0.6 (pointed ends), folded along its
## midrib for volume; `side_hint` is the width direction (kept perpendicular to the tangent).
static func _ribbon(pts: PackedVector3Array, w: float, side_hint: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := pts.size()
	var L := []
	var C := []
	var R := []
	for i in n:
		var t := ((pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)])).normalized()
		var side := (side_hint - t * side_hint.dot(t)).normalized()
		var up := side.cross(t).normalized()
		var f := float(i) / (n - 1)
		var ww := w * pow(maxf(sin(PI * f), 0.0), 0.6) * 0.5
		L.append(pts[i] - side * ww)
		R.append(pts[i] + side * ww)
		C.append(pts[i] + up * ww * 0.35)
	for i in n - 1:
		for tri: Array in [[L[i], C[i], C[i + 1]], [L[i], C[i + 1], L[i + 1]], [C[i], R[i], R[i + 1]], [C[i], R[i + 1], C[i + 1]]]:
			for p: Vector3 in tri:
				st.add_vertex(p)
	st.index()
	st.generate_normals()
	return st.commit()


## A lathed (turned) surface from a (radius, height) profile, smooth.
static func _lathe(profile: Array, sides := 28) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in profile.size() - 1:
		for s in sides:
			var a0 := TAU * s / sides
			var a1 := TAU * ((s + 1) % sides) / sides
			var p := []
			for pr: Vector2 in [profile[i], profile[i + 1]]:
				p.append([Vector3(pr.x * cos(a0), pr.y, pr.x * sin(a0)), Vector3(pr.x * cos(a1), pr.y, pr.x * sin(a1))])
			for v: Vector3 in [p[0][0], p[1][0], p[1][1], p[0][0], p[1][1], p[0][1]]:
				st.add_vertex(v)
	st.index()
	st.generate_normals()
	return st.commit()


func _mi(mesh: Mesh, mat: Material, xf := Transform3D.IDENTITY, parent: Node3D = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.transform = xf
	(parent if parent != null else bed).add_child(m)
	return m


func _blob(center: Vector3, radii: Vector3, mat: Material, parent: Node3D) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = 0.5
	s.height = 1.0
	s.radial_segments = 32
	s.rings = 16
	var m := _mi(s, mat, Transform3D(Basis.from_scale(radii * 2.0), center), parent)
	m.set_instance_shader_parameter("cloud_center", parent.global_transform * center if parent.is_inside_tree() else center)
	m.set_instance_shader_parameter("cloud_radii", radii)
	return m


# ------------------------------------------------------------------ the four treatments
func _rim_fronds() -> Array:
	var out_list := []
	for n in demo.geometry.find_children("rim_frond_*", "MeshInstance3D", true, false):
		if not String(n.name).ends_with("_col"):
			out_list.append(n)
	return out_list


func _clear() -> void:
	for c in bed.get_children():
		bed.remove_child(c)
		c.queue_free()


func _build(v: String, rim: Array) -> void:
	_clear()
	for f: MeshInstance3D in rim:
		f.visible = v == "A"
	if v == "0":
		for f: MeshInstance3D in rim:
			f.visible = true
		return
	for k: String in SLOTS:
		var root3 := Node3D.new()
		bed.add_child(root3)
		root3.global_position = SLOTS[k]
		match v:
			"A": _a_plant(k, root3, rim[0])
			"B": _b_plant(k, root3)
			"C": _c_plant(k, root3, false)
			"D": _c_plant(k, root3, true)
	if v != "A":
		# the bridge's rim fronds, replaced by this treatment's frond (3.2 m) at each frond root
		for f: MeshInstance3D in rim:
			var r3 := Node3D.new()
			bed.add_child(r3)
			r3.global_position = f.global_transform * FROND_BASE_LOCAL
			r3.scale = Vector3.ONE * (3.2 / HEIGHT.frond)
			match v:
				"B": _b_plant("frond", r3)
				"C": _c_plant("frond", r3, false)
				"D": _c_plant("frond", r3, true)


## A: the rim-frond mesh (5.2 m tall in its node frame) scaled to each slot's height.
func _a_plant(k: String, at: Node3D, frond: MeshInstance3D) -> void:
	var m := frond.duplicate() as MeshInstance3D
	for c in m.get_children():
		m.remove_child(c)
		c.free()
	var s: float = HEIGHT[k] / 5.26
	m.transform = Transform3D(Basis.from_scale(Vector3.ONE * s), Vector3.ZERO) * Transform3D(Basis.IDENTITY, -FROND_BASE_LOCAL)
	m.visible = true
	at.add_child(m)


## B: one painted card (two for the bigger plants, the second behind for parallax), view-locked:
## the Bow view's yaw is fixed, so the card faces +z (the camera looks at -z) and never turns.
func _b_plant(k: String, at: Node3D) -> void:
	var tex_name: String = {"tree": "tree", "frond": "frond", "shrub": "shrub", "grown": "grown_planter", "vines": "vines"}[k]
	var h: float = HEIGHT[k] * 1.12 # the painting has a margin
	var layers: Array = [[Vector3.ZERO, false, 1.0]]
	if k in ["tree", "shrub", "frond"]:
		layers.append([Vector3(0.35, 0.05, -0.45), true, 0.82])
	for L: Array in layers:
		var q := QuadMesh.new()
		q.size = Vector2(h, h)
		q.center_offset = Vector3(0, h * 0.5 - h * 0.03, 0)
		var mat := _toon(Color(L[2], L[2], L[2]), false, {"tex": cards[tex_name], "use_tex": true, "scissor": 0.55,
			"sphere_mix": 0.75, "card_bias": 0.9, "wind_amp": 0.04, "wind_height": h})
		var m := _mi(q, mat, Transform3D(Basis.from_scale(Vector3(-1 if L[1] else 1, 1, 1)), L[0]), at)
		m.set_instance_shader_parameter("cloud_center", at.global_position + Vector3(0, h * 0.55, 0) * at.scale)
		m.set_instance_shader_parameter("cloud_radii", Vector3(h * 0.5, h * 0.5, h * 0.5) * at.scale)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## C (procedural=false) and D (procedural=true): sinuous stylised 3D. D swaps the leaf masses for
## generated leaf-quad clouds.
func _c_plant(k: String, at: Node3D, procedural: bool) -> void:
	var leaf := _toon(LEAF, true, {"ink_grow": 0.035})
	var leaf2 := _toon(LEAF2, true, {"ink_grow": 0.035})
	var cream := _toon(CREAM, true)
	var teal := _toon(TEAL, true)
	var coral := _toon(CORAL, true, {"ink_grow": 0.015})
	var bark := _toon(BARK, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(k) # deterministic per plant kind
	match k:
		"frond":
			_mi(_lathe([Vector2(0.0, 0.0), Vector2(0.42, 0.02), Vector2(0.5, 0.18), Vector2(0.44, 0.34), Vector2(0.36, 0.36), Vector2(0.0, 0.33)]), cream, Transform3D.IDENTITY, at)
			for i in 9:
				var a := TAU * i / 9.0 + rng.randf_range(-0.2, 0.2)
				var dir := Vector3(cos(a), 0, sin(a))
				var reach := rng.randf_range(0.9, 1.3)
				var top := rng.randf_range(1.2, 1.7)
				var pts := _bez(Vector3(0, 0.3, 0), Vector3(0, top, 0) + dir * 0.1, dir * reach * 0.8 + Vector3(0, top, 0), dir * reach + Vector3(0, top * 0.45, 0))
				_mi(_ribbon(pts, 0.26, Vector3.UP.cross(dir).normalized() if dir.length() > 0 else Vector3.RIGHT), leaf if i % 2 == 0 else leaf2, Transform3D.IDENTITY, at)
		"shrub":
			var masses := [[Vector3(0, 0.5, 0), Vector3(0.6, 0.45, 0.55)], [Vector3(-0.4, 0.4, 0.1), Vector3(0.42, 0.36, 0.42)],
				[Vector3(0.42, 0.42, 0.05), Vector3(0.44, 0.38, 0.42)], [Vector3(0.05, 0.85, -0.05), Vector3(0.42, 0.3, 0.4)]]
			_leaf_masses(masses, at, procedural, leaf, leaf2, rng)
			for i in 12:
				var p := Vector3(rng.randf_range(-0.7, 0.7), rng.randf_range(0.35, 1.05), rng.randf_range(0.2, 0.55))
				_blob(p, Vector3.ONE * 0.07, coral, at)
		"tree":
			_mi(_lathe([Vector2(0.0, 0.0), Vector2(0.62, 0.03), Vector2(0.72, 0.28), Vector2(0.66, 0.5), Vector2(0.55, 0.52), Vector2(0.0, 0.48)]), cream, Transform3D.IDENTITY, at)
			var trunk := _bez(Vector3(0, 0.4, 0), Vector3(0.6, 1.2, 0.1), Vector3(-0.6, 1.9, 0), Vector3(0.1, 2.7, 0))
			_mi(_tube(trunk, 0.18, 0.08), bark, Transform3D.IDENTITY, at)
			for b: Array in [[Vector3(-0.2, 1.9, 0), Vector3(-1.2, 2.4, 0.2)], [Vector3(0.0, 2.3, 0), Vector3(1.1, 2.9, 0.1)], [Vector3(0.1, 2.6, 0), Vector3(-0.5, 3.3, 0)]]:
				var bp := _bez(b[0], b[0] + Vector3(0, 0.3, 0), b[1] - Vector3(0, 0.2, 0), b[1])
				_mi(_tube(bp, 0.07, 0.03), bark, Transform3D.IDENTITY, at)
			var canopy := [[Vector3(-1.2, 2.55, 0.1), Vector3(0.8, 0.32, 0.6)], [Vector3(1.1, 3.0, 0.05), Vector3(0.85, 0.34, 0.6)],
				[Vector3(-0.4, 3.45, 0), Vector3(0.9, 0.36, 0.65)], [Vector3(0.2, 3.0, -0.2), Vector3(0.7, 0.3, 0.5)]]
			_leaf_masses(canopy, at, procedural, leaf, leaf2, rng)
			if not procedural:
				# the hybrid: painted leaf-clump cards (crops of the painted tree's leaf clouds) over the
				# canopy masses' fronts, so the 3D form carries painted leaves
				var rects := [Vector4(0.03, 0.21, 0.45, 0.2), Vector4(0.51, 0.32, 0.47, 0.23), Vector4(0.18, 0.0, 0.62, 0.2), Vector4(0.12, 0.45, 0.35, 0.16)]
				var ci := 0
				for cpos: Array in canopy:
					var rad: Vector3 = cpos[1]
					var q := QuadMesh.new()
					q.size = Vector2(rad.x * 2.4, rad.y * 2.6)
					var mat := _toon(Color(1, 1, 1), false, {"tex": cards.tree, "use_tex": true, "scissor": 0.55, "sphere_mix": 0.6, "card_bias": 0.9, "uv_rect": rects[ci % rects.size()]})
					ci += 1
					var m := _mi(q, mat, Transform3D(Basis.IDENTITY, cpos[0] + Vector3(0, 0.05, rad.z * 0.7)), at)
					m.set_instance_shader_parameter("cloud_center", at.global_position + cpos[0])
					m.set_instance_shader_parameter("cloud_radii", cpos[1])
		"vines":
			var rail := _bez(Vector3(-1.2, 0, 0), Vector3(-1.2, 2.6, 0), Vector3(1.2, 2.6, 0), Vector3(1.2, 0, 0), 32)
			_mi(_tube(rail, 0.06, 0.06), cream, Transform3D.IDENTITY, at)
			for i in 7:
				var x := -0.8 + i * 0.27
				var top := Vector3(x, 1.95 + 0.25 * cos(x * 1.2), 0.0)
				var sway := rng.randf_range(-0.25, 0.25)
				var strand := _bez(top, top + Vector3(sway, -0.5, 0.05), top + Vector3(-sway, -1.0, 0.1), top + Vector3(sway * 0.5, -rng.randf_range(1.1, 1.6), 0.12))
				_mi(_tube(strand, 0.018, 0.01, 6), leaf, Transform3D.IDENTITY, at)
				for j in 6:
					var p: Vector3 = strand[int(j * 4) % strand.size()]
					if procedural:
						_leaf_cloud(p, Vector3(0.14, 0.12, 0.1), 6, at, rng)
					else:
						_blob(p + Vector3(0.05 * (1 if j % 2 == 0 else -1), 0, 0.02), Vector3(0.09, 0.05, 0.07), leaf2 if j % 2 == 0 else leaf, at)
				if i % 2 == 0:
					_blob(strand[strand.size() - 1], Vector3.ONE * 0.06, coral, at)
		"grown":
			# grown technology: the planter's three ribs rise, twist round each other and open as the plant
			_mi(_lathe([Vector2(0.0, 0.0), Vector2(0.34, 0.02), Vector2(0.46, 0.2), Vector2(0.4, 0.42), Vector2(0.22, 0.6), Vector2(0.12, 0.7), Vector2(0.0, 0.7)]), cream, Transform3D.IDENTITY, at)
			for i in 3:
				var pts := PackedVector3Array()
				for s in 33:
					var t := float(s) / 32.0
					var a := TAU * i / 3.0 + t * 2.4
					var r := 0.12 * (1.0 - t) + 0.05 + 0.22 * t * t
					pts.append(Vector3(r * cos(a), 0.55 + t * 1.15, r * sin(a)))
				_mi(_tube(pts, 0.06, 0.035), teal if i == 0 else cream, Transform3D.IDENTITY, at)
				var tip := pts[pts.size() - 1]
				var out_dir := Vector3(tip.x, 0, tip.z).normalized()
				for j in 2:
					var d2 := out_dir.rotated(Vector3.UP, (j - 0.5) * 0.9)
					var lp := _bez(tip, tip + Vector3(0, 0.3, 0) + d2 * 0.1, tip + d2 * 0.55 + Vector3(0, 0.25, 0), tip + d2 * 0.75 - Vector3(0, 0.15, 0), 16)
					_mi(_ribbon(lp, 0.2, Vector3.UP.cross(d2).normalized()), leaf, Transform3D.IDENTITY, at)
				_blob(tip + Vector3(0, 0.12, 0), Vector3(0.11, 0.09, 0.11), coral, at)


func _leaf_masses(masses: Array, at: Node3D, procedural: bool, leaf: Material, leaf2: Material, rng: RandomNumberGenerator) -> void:
	var i := 0
	for m: Array in masses:
		if procedural:
			_leaf_cloud(m[0], m[1], int(260.0 * (m[1] as Vector3).x * (m[1] as Vector3).y * 2.0) + 40, at, rng)
		else:
			_blob(m[0], m[1], leaf if i % 2 == 0 else leaf2, at)
		i += 1


## D: a leaf cloud of `count` generated leaf quads inside the ellipsoid, view-locked (facing +z,
## random roll), shaded by the cloud-centred normal. One ArrayMesh per cloud.
func _leaf_cloud(center: Vector3, radii: Vector3, count: int, at: Node3D, rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var size := clampf(radii.x * 0.75, 0.18, 0.5)
	for i in count:
		var p := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1))
		if p.length() > 1.0:
			p = p.normalized() * rng.randf_range(0.6, 1.0)
		p = center + p * radii
		var roll := rng.randf_range(-PI, PI)
		var ax := Vector3(cos(roll), sin(roll), 0) * size * 0.5
		var ay := Vector3(-sin(roll), cos(roll), 0) * size * 0.5
		var tint := rng.randf_range(0.75, 1.15)
		var col := LEAF.lerp(LEAF2, rng.randf()) * tint
		col.a = 1.0
		var corners := [p - ax - ay, p + ax - ay, p + ax + ay, p - ax + ay]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.set_uv(uvs[idx])
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(corners[idx])
	var mat := _toon(Color(1, 1, 1), false, {"tex": leaf_tex, "use_tex": true, "use_vcol": true, "scissor": 0.5, "sphere_mix": 0.85, "card_bias": 0.35})
	var m := _mi(st.commit(), mat, Transform3D.IDENTITY, at)
	m.set_instance_shader_parameter("cloud_center", at.global_position + center * at.scale)
	m.set_instance_shader_parameter("cloud_radii", radii * at.scale)
