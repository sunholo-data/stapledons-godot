class_name TitleScreen
extends Control
## The launch menu (design_docs/planned/r1/title-screen.md; charter queue row 5b).
## Shown on a plain launch only (main.gd launch_route() == "title"); every
## command-line mode, capture, golden and smoke bypasses it.
##
## Behind it: the real sky (InteriorSky: the NOIRLab panorama and the catalogue
## stars, at rest, looking at the galactic centre with the NGP up) under one
## fixed physical exposure. No new art.
##
## It only chooses: `chosen(route)` with route in ROUTES; main.gd starts the mode.
## Settings and Credits are panels of this screen. Esc closes a panel.

signal chosen(route: String)

const TITLE := "STAPLEDON'S VOYAGE"
const TAGLINE := "Travel as fast as you like. Live with the consequences." # stapledons-design README
const FONT := "res://ui/splash/Montserrat-Bold.ttf" # SIL OFL 1.1, licence alongside
const BUILD_FILE := "res://runtime/build_version.txt" # make export-macos writes it (git describe)
## [route, button text, what it does]. "settings" / "credits" open panels; the rest go to main.gd.
const ENTRIES := [
	["ship", "Board the ship", "The painted 3D ship at rest in the Solar System. Walk the decks, open navigation (M) and fly anywhere."],
	["guided", "Guided voyage", "Board and start the guided tour: Earth, the outer planets, alpha Centauri, TRAPPIST-1, Aldebaran, in real time."],
	["map", "Galaxy map", "The 3D map of the nearby catalogued stars; plan and commit a journey."],
	["settings", "Settings", "Ship view (Realistic / Auto) and text-only AI."],
	["credits", "Credits", "Data, imagery, papers and software behind the game."],
	["quit", "Quit", "Close the game."],
]
const SCROLL_KEYS := {KEY_DOWN: 40, KEY_UP: -40, KEY_PAGEDOWN: 300, KEY_PAGEUP: -300}
const ROUTES := ["ship", "guided", "map", "quit"]
## Fixed title exposure: 4 stops over the dark-sky reference (a display aid the ship also offers, J).
const SKY_STOPS := 4.0
## Look 20 degrees left of the galactic centre (yaw positive = left), so the bulge sits right of the menu.
const BASE_YAW := 0.35
const CITATION_FILES := ["res://sim/data/sol.ail", "res://sim/data/acen.ail", "res://sim/data/trappist1.ail", "res://sim/data/stars.ail"]

var options := {}
var settings := GameSettings.new()
var sky: InteriorSky = null
var sky_rect := TextureRect.new()
var buttons := {}
var hint := Label.new()
var version_label := Label.new()
var menu := VBoxContainer.new()
var col := VBoxContainer.new() # title, tagline, menu, hint
var settings_panel := PanelContainer.new()
var credits_panel := PanelContainer.new()
var view_option := OptionButton.new()
var text_only_box := CheckBox.new()
var settings_status := Label.new()
var credits_body := Label.new()
var credits_scroll := ScrollContainer.new()
var _drift := 0.0


## opts: sky (bool, default true), settings_dir (String, default user://).
func _init(opts := {}) -> void:
	options = opts
	set_anchors_preset(Control.PRESET_FULL_RECT)
	settings.dir = opts.get("settings_dir", "user://")
	settings.load_settings()


func _ready() -> void:
	if options.get("sky", true):
		_build_sky()
	var shade := TextureRect.new() # left-to-right darkening so the type reads over the Milky Way
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.78))
	g.set_color(1, Color(0, 0, 0, 0.0))
	g.add_point(0.45, Color(0, 0, 0, 0.55))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_to = Vector2(1, 0)
	shade.texture = gt
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_build_menu()
	_build_settings()
	_build_credits()
	_build_footer()
	buttons["ship"].grab_focus.call_deferred()
	print("title-screen: OK %d buttons, sky %s, build %s" % [buttons.size(), "on" if sky != null else "off", build_label()])


## The bundled build id, or a plain source-checkout label.
static func build_label() -> String:
	var f := FileAccess.open(BUILD_FILE, FileAccess.READ)
	if f == null:
		return "source checkout"
	var s := f.get_as_text().strip_edges()
	return s if s != "" else "source checkout"


func _build_sky() -> void:
	var px := Vector2i(get_viewport().get_visible_rect().size)
	if px.x < 64 or px.y < 64:
		px = Vector2i(1280, 720)
	sky = InteriorSky.new()
	sky.setup({"position_m": [0, 0, 0], "forward": [1, 0, 0], "up": [0, 0, 1]}, 62.0, get_window().size, {"planet_preload": false, "planet_textures": false})
	add_child(sky)
	sky.starfield.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	sky.camera.look(BASE_YAW, 0.0, 0.0) # galactic centre right of the menu, NGP up (SkyFrame, D-28)
	sky.set_temporal_exposure(false)
	sky.exposure.bias = -SKY_STOPS
	sky.exposure.fixed = true
	sky.exposure.fixed_ev = sky.exposure.ev_dark() - SKY_STOPS
	sky.update_exposure()
	sky_rect.texture = sky.get_texture()
	sky_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sky_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky_rect)
	get_viewport().size_changed.connect(func() -> void:
		if sky != null: sky.resize(get_window().size))


## A slow pan along the Milky Way (0.6 degrees a second); `pan` false holds it (captures).
func _process(delta: float) -> void:
	if sky == null or not options.get("pan", true):
		return
	_drift += delta * deg_to_rad(0.6)
	sky.camera.look(BASE_YAW + _drift, 0.0, 0.0)


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


func _panel_style(alpha := 0.86) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.05, 0.08, alpha)
	s.border_color = Color(0.55, 0.65, 0.85, 0.35)
	s.set_border_width_all(1)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(18)
	return s


func _build_menu() -> void:
	col.position = Vector2(64, 48)
	col.add_theme_constant_override("separation", 6)
	add_child(col)
	var title := _label(TITLE, 36, Color(0.93, 0.95, 1.0))
	var font := FontFile.new() # read as data (the .ttf is not an imported resource; export_presets include_filter ships it)
	if font.load_dynamic_font(FONT) == OK:
		var spaced := FontVariation.new()
		spaced.base_font = font
		spaced.spacing_glyph = 3
		title.add_theme_font_override("font", spaced)
	col.add_child(title)
	col.add_child(_label(TAGLINE, 15, Color(0.78, 0.83, 0.92)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	col.add_child(gap)
	menu.add_theme_constant_override("separation", 6)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(menu)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.08, 0.13, 0.55)
	normal.set_corner_radius_all(4)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hot := normal.duplicate() as StyleBoxFlat
	hot.bg_color = Color(0.22, 0.32, 0.55, 0.85)
	hot.border_color = Color(0.7, 0.8, 1.0, 0.9)
	hot.border_width_left = 3
	for e in ENTRIES:
		var b := Button.new()
		b.text = e[1]
		b.tooltip_text = e[2]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(260, 0)
		b.focus_mode = Control.FOCUS_ALL
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_stylebox_override("normal", normal)
		b.add_theme_stylebox_override("hover", hot)
		b.add_theme_stylebox_override("focus", hot)
		b.add_theme_stylebox_override("pressed", hot)
		b.add_theme_color_override("font_color", Color(0.86, 0.9, 0.98))
		b.add_theme_color_override("font_focus_color", Color.WHITE)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.pressed.connect(press.bind(e[0]))
		b.focus_entered.connect(func() -> void: hint.text = e[2])
		b.mouse_entered.connect(func() -> void: b.grab_focus())
		menu.add_child(b)
		buttons[e[0]] = b
	# Up / Down wrap round the list.
	var keys := buttons.keys()
	for i in keys.size():
		var b: Button = buttons[keys[i]]
		b.focus_neighbor_top = buttons[keys[(i - 1 + keys.size()) % keys.size()]].get_path()
		b.focus_neighbor_bottom = buttons[keys[(i + 1) % keys.size()]].get_path()
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 10)
	col.add_child(gap2)
	hint.custom_minimum_size = Vector2(380, 0)
	hint.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	hint.text = ENTRIES[0][2]
	col.add_child(hint)


## A button's action: a route goes to main.gd; settings and credits open their panels.
func press(route: String) -> void:
	match route:
		"settings":
			open_panel(settings_panel)
		"credits":
			open_panel(credits_panel)
		_:
			chosen.emit(route)


func open_panel(p: Control) -> void:
	settings_panel.visible = p == settings_panel
	credits_panel.visible = p == credits_panel
	menu.visible = false
	hint.visible = false
	col.visible = p != credits_panel # the full-screen credits replace the title
	var first: Control = view_option if p == settings_panel else p.find_child("Back", true, false)
	if first != null:
		first.grab_focus.call_deferred()


func close_panels() -> void:
	var was := "settings" if settings_panel.visible else ("credits" if credits_panel.visible else "")
	settings_panel.visible = false
	credits_panel.visible = false
	menu.visible = true
	hint.visible = true
	col.visible = true
	if was != "":
		buttons[was].grab_focus.call_deferred()


func panel_open() -> bool:
	return settings_panel.visible or credits_panel.visible


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed:
		return
	if not k.echo and k.keycode == KEY_ESCAPE and panel_open():
		close_panels()
		get_viewport().set_input_as_handled()
	elif credits_panel.visible and k.keycode in SCROLL_KEYS: # keyboard scrolling of the credits
		credits_scroll.scroll_vertical += SCROLL_KEYS[k.keycode]
		get_viewport().set_input_as_handled()


func _back_button() -> Button:
	var back := Button.new()
	back.name = "Back"
	back.text = "Back  [Esc]"
	back.add_theme_font_size_override("font_size", 15)
	back.pressed.connect(close_panels)
	return back


func _build_settings() -> void:
	settings_panel.add_theme_stylebox_override("panel", _panel_style())
	settings_panel.position = Vector2(64, 150)
	settings_panel.custom_minimum_size = Vector2(470, 0)
	settings_panel.visible = false
	add_child(settings_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	settings_panel.add_child(box)
	box.add_child(_label("Settings", 22, Color.WHITE))
	var row := HBoxContainer.new()
	row.add_child(_label("Ship view", 15, Color(0.86, 0.9, 0.98)))
	view_option.add_item("Realistic (one exposure)", 0)
	view_option.add_item("Auto (bodies faded to fit)", 1)
	view_option.select(1 if settings.auto_view else 0)
	view_option.item_selected.connect(func(i: int) -> void: set_auto_view(i == 1))
	view_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(view_option)
	box.add_child(row)
	var note := _label("Realistic: one physical exposure for sky and planets; sunlit planets clip so the stars show. Auto: the same sky, each planet faded on its own so planets and stars show together (V switches aboard).", 12, Color(0.7, 0.75, 0.85))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(430, 0)
	box.add_child(note)
	text_only_box.text = "Text-only AI (no voices or new portraits)"
	text_only_box.button_pressed = settings.text_only
	text_only_box.toggled.connect(set_text_only)
	box.add_child(text_only_box)
	var ai_note := _label("Live AI is off unless you add your own key (the AI button, top right of the galaxy map). Text-only applies there too.", 12, Color(0.7, 0.75, 0.85))
	ai_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_note.custom_minimum_size = Vector2(430, 0)
	box.add_child(ai_note)
	settings_status.add_theme_font_size_override("font_size", 12)
	settings_status.add_theme_color_override("font_color", Color(0.6, 0.85, 0.65))
	box.add_child(settings_status)
	box.add_child(_back_button())


func set_auto_view(on: bool) -> void:
	settings.auto_view = on
	_save()


func set_text_only(on: bool) -> void:
	settings.text_only = on
	_save()


func _save() -> void:
	var ok := settings.save_settings()
	settings_status.text = ("Saved: view %s, text-only %s" % [settings.view_label(), "on" if settings.text_only else "off"]) if ok else "Could not save settings"
	settings_status.add_theme_color_override("font_color", Color(0.6, 0.85, 0.65) if ok else Color(1.0, 0.55, 0.45))


## Every reference the simulation's data cites: the ("key", "reference") rows of the
## *itations() lists in sim/data/*.ail, without the rows that mark an assumption.
static func cited_papers() -> Array:
	var out := []
	var rx := RegEx.new()
	rx.compile("^\\s*\\(\"[^\"]+\",\\s*\"(.*)\"\\),?\\s*$")
	for path in CITATION_FILES:
		var inside := false
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if line.contains("itations() -> [(string, string)] = ["):
				inside = true
				continue
			if inside and line.strip_edges().begins_with("]"):
				inside = false
			if not inside:
				continue
			var m := rx.search(line)
			if m == null:
				continue
			var ref := m.get_string(1)
			if ref.begins_with("assumed") or ref.begins_with("the navigation catalogue") or ref in out:
				continue
			out.append(ref)
	return out


static func credits_text() -> String:
	var lines := PackedStringArray([
		"Made by Sunholo. Code: Apache License 2.0. AI-generated art (the captain, the bridge and concept art): no copyright claimed.",
		"",
		"IMAGERY",
		"Milky Way panorama: NOIRLab noirlab2430b (E. Slawik / NOIRLab / NSF / AURA), CC BY 4.0; used with the catalogue stars removed and a fitted colour-temperature model.",
		Credits.PLANET_LINE + "; based on NASA imagery, brightness rescaled to each body's measured albedo.",
		"",
		"STARS",
		"CNS5, the fifth Catalogue of Nearby Stars (Golovin et al. 2023), via CDS VizieR.",
		"Gaia: GCNS, the Gaia Catalogue of Nearby Stars (Gaia Collaboration, Smart et al. 2021), Gaia EDR3/DR3. This work uses data from the European Space Agency (ESA) mission Gaia, processed by the Gaia Data Processing and Analysis Consortium (DPAC).",
		"Hipparcos (ESA 1997; van Leeuwen 2007 new reduction) for the bright stars.",
		"NASA Exoplanet Archive (table ps) for the alpha Centauri and TRAPPIST-1 planets.",
		"",
		"PAPERS AND TABLES THE SIMULATION CITES",
	])
	for ref in cited_papers():
		lines.append("· " + ref)
	lines.append_array(PackedStringArray([
		"",
		"SOFTWARE",
		"Godot Engine 4 (MIT licence) · AILANG and the sunholo/relativity and sunholo/celestial packages (Sunholo).",
		"Montserrat Bold (SIL Open Font License 1.1) on the title and the boot splash.",
		"",
		"CC BY 4.0: https://creativecommons.org/licenses/by/4.0/",
	]))
	return "\n".join(lines)


func _build_credits() -> void:
	credits_panel.add_theme_stylebox_override("panel", _panel_style(0.9))
	credits_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credits_panel.offset_left = 48
	credits_panel.offset_top = 36
	credits_panel.offset_right = -48
	credits_panel.offset_bottom = -44
	credits_panel.visible = false
	add_child(credits_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	credits_panel.add_child(box)
	var head := HBoxContainer.new()
	var t := _label("Credits", 22, Color.WHITE)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	head.add_child(_back_button())
	box.add_child(head)
	var scroll := credits_scroll
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	credits_body.text = credits_text()
	credits_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	credits_body.add_theme_font_size_override("font_size", 12)
	credits_body.add_theme_color_override("font_color", Color(0.84, 0.87, 0.94))
	scroll.add_child(credits_body)


func _build_footer() -> void:
	version_label.text = "dev build · %s" % build_label()
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 0.85))
	version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 14)
	version_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(version_label)
	var credit := Label.new() # CC BY 4.0 attribution where the panorama is shown
	credit.text = "Sky: NOIRLab / E. Slawik, CC BY 4.0 · stars: CNS5, Gaia, Hipparcos"
	credit.add_theme_font_size_override("font_size", 11)
	credit.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 0.75))
	credit.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 14)
	credit.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	credit.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(credit)
