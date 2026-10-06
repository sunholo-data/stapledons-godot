extends SceneTree
## make splash: compose the boot splash (ui/splash/splash.png, set as
## application/boot_splash/image) in the style of the website hero: the
## destarred Milky Way, the wordmark, the tagline and "built in AILANG".
## Offline art step, not part of make test. Needs a GPU window (text is drawn
## by the renderer) and the gitignored panorama in data/raw (make sky-inputs).
##   godot --path . --script tools/splash_compose.gd [-- --out PATH]

const SIZE := Vector2i(1920, 1080)
const PANORAMA := "res://data/raw/background/noirlab_10k_destarred.png"
## The crop of the 10000 x 5000 equirectangular panorama: centred on the
## galactic centre (l = 0 at x = 5000, b = 0 at y = 2500), 4000 px wide
## (144 deg of longitude), shifted up so the band sits under the wordmark.
const CROP := Rect2i(3000, 1250, 4000, 2250)
const OUT := "res://ui/splash/splash.png"
const BOLD := "res://ui/splash/Montserrat-Bold.ttf"
const LOGO := "res://ui/splash/ailang-logo.png"
const WORDMARK_PX := 200

## The hero shade from website/src/pages/index.module.css (.heroShade).
const SHADE := """
shader_type canvas_item;
void fragment() {
	vec2 p = (UV - vec2(0.5, 0.55)) * vec2(1.0, 16.0 / 9.0);
	float r = length(p) / 0.9;
	float radial = mix(0.15, 0.55, smoothstep(0.0, 0.6, r)) + 0.30 * smoothstep(0.6, 1.0, r);
	float top = 0.55 * (1.0 - smoothstep(0.0, 0.30, UV.y));
	float bottom = smoothstep(0.70, 1.0, UV.y);
	float a = 1.0 - (1.0 - radial) * (1.0 - top) * (1.0 - bottom);
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
"""

## .wordmarkBig: linear-gradient(180deg, #ffffff 0%, #dbe6ff 55%, #9fb6ff 100%).
const WORDMARK := """
shader_type canvas_item;
uniform float height = 1.0;
varying float y;
void vertex() { y = VERTEX.y / height; }
void fragment() {
	vec3 a = vec3(1.0);
	vec3 b = vec3(0.859, 0.902, 1.0);
	vec3 c = vec3(0.624, 0.714, 1.0);
	float t = clamp(y, 0.0, 1.0);
	COLOR.rgb = t < 0.55 ? mix(a, b, t / 0.55) : mix(b, c, (t - 0.55) / 0.45);
}
"""

## text-shadow: 0 0 40px rgba(120, 160, 255, 0.35), from a blurred mask.
const GLOW := """
shader_type canvas_item;
render_mode blend_add;
void fragment() {
	float m = texture(TEXTURE, UV).r;
	COLOR = vec4(vec3(0.47, 0.63, 1.0) * m * 0.55, 1.0);
}
"""


func _init() -> void:
	_compose.call_deferred()


func _compose() -> void:
	var args := OS.get_cmdline_user_args()
	var out := OUT
	var i := args.find("--out")
	if i >= 0 and i + 1 < args.size():
		out = args[i + 1]

	var pano := Image.load_from_file(ProjectSettings.globalize_path(PANORAMA))
	if pano == null or pano.get_size() != Vector2i(10000, 5000):
		printerr("splash: need the 10000x5000 destarred panorama at ", PANORAMA, " (make sky-inputs)")
		quit(1)
		return
	var bg := pano.get_region(CROP)
	bg.resize(SIZE.x, SIZE.y, Image.INTERPOLATE_LANCZOS)

	RenderingServer.set_default_clear_color(Color.BLACK)
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)

	var sky := TextureRect.new()
	sky.texture = ImageTexture.create_from_image(bg)
	sky.size = SIZE
	vp.add_child(sky)

	var shade := ColorRect.new()
	shade.size = SIZE
	shade.material = _material(SHADE)
	vp.add_child(shade)

	var glow := TextureRect.new()
	glow.size = SIZE
	glow.material = _material(GLOW)
	vp.add_child(glow)

	var bold := FontFile.new()
	bold.load_dynamic_font(ProjectSettings.globalize_path(BOLD))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size = SIZE
	col.add_theme_constant_override("separation", 0)
	vp.add_child(col)

	var rest: Array[CanvasItem] = []
	rest.append(_line(col, "A HARD-SF GAME IN GODOT 4 AND AILANG", _spaced(bold, 22, 0.22), 22, Color(1, 1, 1, 0.65)))
	_gap(col, 34)
	rest.append(_line(col, "STAPLEDON'S", _spaced(bold, 50, 0.42), 50, Color(1, 1, 1, 0.85)))
	_gap(col, 4)
	var mark := _line(col, "VOYAGE", _spaced(bold, WORDMARK_PX, 0.08, 0.6), WORDMARK_PX, Color.WHITE)
	_gap(col, 28)
	rest.append(_line(col, "Travel as fast as you like. Live with the consequences.", bold, 38, Color("#ffb199")))
	_gap(col, 70)
	rest.append(_built_with(col, bold))
	rest.append(_credit(vp, bold))

	# Labels shape their text once they are in the tree; size the line holders after that.
	await process_frame
	for l: Label in col.find_children("*", "Label", true, false):
		var h := l.get_minimum_size().y
		l.size = Vector2(SIZE.x, h)
		(l.get_parent() as Control).custom_minimum_size = Vector2(SIZE.x, h)

	# Pass 1: the wordmark alone, white on black, blurred into the glow mask.
	for n: CanvasItem in rest + [sky, shade, glow] as Array[CanvasItem]:
		n.modulate.a = 0.0
	var mask := await _grab(vp)
	for n: CanvasItem in rest + [sky, shade, glow] as Array[CanvasItem]:
		n.modulate.a = 1.0
	glow.texture = ImageTexture.create_from_image(_blur(mask, 40))

	# Pass 2: everything, with the gradient fill on the wordmark.
	var m := _material(WORDMARK)
	m.set_shader_parameter("height", mark.size.y)
	mark.material = m
	var img := await _grab(vp)
	img.convert(Image.FORMAT_RGB8)
	var err := img.save_png(out)
	if err != OK:
		printerr("splash: could not write ", out, ": ", error_string(err))
		quit(1)
		return
	print("splash: wrote ", out, " ", img.get_size())
	quit(0)


func _grab(vp: SubViewport) -> Image:
	for f in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	return vp.get_texture().get_image()


## Separable box blur, three passes (close to a Gaussian of sigma ~ radius / 2).
func _blur(src: Image, radius: int) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	# Blur at quarter size: the glow is soft, so nothing is lost.
	var s := 4
	var img := src.duplicate() as Image
	img.resize(w / s, h / s, Image.INTERPOLATE_BILINEAR)
	var sw := img.get_width()
	var sh := img.get_height()
	var r := maxi(1, radius / s / 2)
	var buf := PackedFloat32Array()
	buf.resize(sw * sh)
	for y in sh:
		for x in sw:
			buf[y * sw + x] = img.get_pixel(x, y).r
	for p in 3:
		buf = _box(buf, sw, sh, r, 1, sw) # rows
		buf = _box(buf, sh, sw, r, sw, 1) # columns
	var outi := Image.create(sw, sh, false, Image.FORMAT_RGB8)
	for y in sh:
		for x in sw:
			var v := buf[y * sw + x]
			outi.set_pixel(x, y, Color(v, v, v))
	outi.resize(w, h, Image.INTERPOLATE_CUBIC)
	return outi


## One box pass along lines of length n (stride step), lines spaced by line_stride.
func _box(a: PackedFloat32Array, n: int, lines: int, r: int, step: int, line_stride: int) -> PackedFloat32Array:
	var o := PackedFloat32Array()
	o.resize(a.size())
	var norm := 1.0 / (2 * r + 1)
	for l in lines:
		var base := l * line_stride
		var acc := 0.0
		for k in range(-r, r + 1):
			acc += a[base + clampi(k, 0, n - 1) * step]
		for i in n:
			o[base + i * step] = acc * norm
			acc += a[base + clampi(i + r + 1, 0, n - 1) * step] - a[base + clampi(i - r, 0, n - 1) * step]
	return o


func _material(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## CSS letter-spacing in em, as a FontVariation (plus optional extra weight).
func _spaced(font: Font, px: int, em: float, embolden := 0.0) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = font
	v.spacing_glyph = roundi(px * em)
	v.variation_embolden = embolden
	return v


## A centred line. Letter spacing trails the last glyph, so the label is shifted
## right by half of it (the site's padding-left balance).
func _line(parent: Control, text: String, font: Font, px: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_outline_size", 6)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 2)
	var holder := Control.new()
	holder.add_child(l)
	if font is FontVariation:
		l.position.x = (font as FontVariation).spacing_glyph * 0.5
	parent.add_child(holder)
	return l


func _gap(parent: Control, px: int) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	parent.add_child(c)


## The site's "built with" line: logo + "Simulation built in AILANG".
func _built_with(parent: Control, font: Font) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var logo := TextureRect.new()
	logo.texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(LOGO)))
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = Vector2(64, 64)
	row.add_child(logo)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.autowrap_mode = TextServer.AUTOWRAP_OFF
	text.scroll_active = false
	text.add_theme_font_override("normal_font", font)
	text.add_theme_font_override("bold_font", font)
	text.add_theme_font_size_override("normal_font_size", 30)
	text.add_theme_font_size_override("bold_font_size", 30)
	text.add_theme_color_override("default_color", Color(1, 1, 1, 0.8))
	text.text = "Simulation built in [b][color=#ffffff]AILANG[/color][/b]"
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)
	return row


## CC BY 4.0 attribution for the panorama (website/docs/credits.md).
func _credit(parent: Node, font: Font) -> Label:
	var credit := Label.new()
	credit.text = "Milky Way: E. Slawik / NOIRLab / NSF / AURA (CC BY 4.0)"
	credit.add_theme_font_override("font", font)
	credit.add_theme_font_size_override("font_size", 15)
	credit.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	credit.position = Vector2(SIZE.x - 560, SIZE.y - 40)
	credit.size = Vector2(530, 24)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	parent.add_child(credit)
	return credit
