class_name ShipHud
extends Control
## R1-SHIP-UI (D-56) §A: the 3D ship's HUD, information only. It never sends a decision.
##
## - The status strip (top centre) is always shown: ship clock and home clock at the same
##   size (D-12), distance, where / phase, speed while moving (from the sim's
##   ship.one_minus_beta, never computed here) and the view tag. Every value is a
##   DisplayBinding on a field of the view the demo builds (the sim's world plus a "hud"
##   section of sim-derived lines); every caption is digit-free.
## - Contextual cards (right column): at most two expanded by priority, the rest collapsed to
##   a one-line chip, never dropped. They fade in over 0.4 s and out over 0.6 s, and never
##   cover the centre third of the screen. A card's lifetime hides the card only; no card
##   changes game state on a timer (NT2).
## - The prompt line (bottom centre), the onboarding hint, the dwell label and the Tab panel
##   (details, full transit rows, grouped controls, Walk to).
##
## Time comes from advance(dt) only (the fake-clock seam): no wall-clock reads, so two runs
## of a test give identical logs (AC13).

signal view_tag_pressed
signal walk_to_requested(station: String)
signal hint_dismissed

const CARD_W := 280.0
const MARGIN := 12.0
const FADE_IN_S := 0.4
const FADE_OUT_S := 0.6
const MAX_EXPANDED := 2
const CLOCK_SIZE := 17
## §A2 priority, high to low (the I card is ShipStarIdentification's own panel and the
## cruise interlude keeps its D-41 InterludeCard; both are listed so the order is complete).
const PRIORITY := ["identify", "medium_here", "arrival", "refusal", "gravity", "notice", "medium_notice", "transit", "tour", "interlude", "unlock"]
## The transit card's compact rows (M4.3a JourneyHud.ROWS by field); the full set is in Tab.
const TRANSIT_COMPACT := ["ship.phase", "consequence.gap_years", "consequence.distance_remaining", "consequence.earth_years_remaining", "consequence.load_suns", "ship.ism.glow_w_m2", "client.warp"]
const WALK_TO := [["navigation", "Navigation station"], ["voyage", "Voyage console"], ["archive", "Archive terminal"]]

var now_s := 0.0
var dev := false
var strip := PanelContainer.new()
var ship_cap := Label.new()
var home_cap := Label.new()
var ship_clock := DisplayBinding.new().bind("clock.tau", "dur_yr")
var home_clock := DisplayBinding.new().bind("clock.year", "dur_yr")
var distance := DisplayBinding.new().bind("hud.distance", "text")
var where := DisplayBinding.new().bind("hud.where", "text")
var speed := DisplayBinding.new().bind("hud.speed", "text")
var view_tag := Button.new()
var corner := HBoxContainer.new()
var help_button := Button.new()
var column := VBoxContainer.new()
var cards := {} # id -> {panel, title, body, priority, born, expires, leaving, left_at}
var card_values := {} # key -> text, shown through DisplayBindings on hud.cardtext.<key>
var prompt := Label.new()
var hint := PanelContainer.new()
var hint_label := Label.new()
var dwell := DisplayBinding.new().bind("hud.dwell", "text")
var dwell_value := ""
var tab_panel := PanelContainer.new()
var tab_box := VBoxContainer.new()
var details := RichTextLabel.new()
var transit_rows := VBoxContainer.new()
var ism_details := VBoxContainer.new()
var _medium_seen := ""
var help := RichTextLabel.new()
var walk_box := VBoxContainer.new()
var walk_buttons := {} # station -> Button
var display_box := VBoxContainer.new() # the demo's instant display controls
var dev_box := VBoxContainer.new() # developer launches only
var _bindings: Array = []
var _bindings_dirty := true
var _last_view: Dictionary = {}


func setup(developer: bool) -> void:
	dev = developer
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_strip()
	_build_column()
	_build_prompt()
	_build_tab()
	dwell.visible = false
	dwell.add_theme_font_size_override("font_size", 13)
	_shadow(dwell)
	add_child(dwell)
	resized.connect(_layout)
	_layout()


static func _panel_style(alpha := 0.78) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.04, 0.07, alpha)
	st.border_color = Color(0.45, 0.55, 0.75, 0.35)
	st.set_border_width_all(1)
	st.set_corner_radius_all(5)
	st.set_content_margin_all(8)
	return st


static func _shadow(l: Control) -> void:
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)


func _caption(l: Label, text: String) -> Label:
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color(0.62, 0.68, 0.8))
	return l


func _build_strip() -> void:
	strip.name = "StatusStrip"
	strip.add_theme_stylebox_override("panel", _panel_style(0.72))
	strip.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(strip)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 1)
	strip.add_child(rows)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_child(row)
	row.add_child(_caption(ship_cap, "Ship"))
	row.add_child(ship_clock)
	row.add_child(_caption(home_cap, "Earth"))
	row.add_child(home_clock)
	for c in [ship_clock, home_clock]:
		c.add_theme_font_size_override("font_size", CLOCK_SIZE)
		c.add_theme_color_override("font_color", Color(0.95, 0.96, 1.0))
	view_tag.name = "ViewTag"
	view_tag.flat = true
	view_tag.add_theme_font_size_override("font_size", 12)
	view_tag.tooltip_text = "V: Auto (bodies faded to fit) or Realistic (one exposure)"
	view_tag.focus_mode = Control.FOCUS_NONE
	view_tag.pressed.connect(func() -> void: view_tag_pressed.emit())
	speed.add_theme_font_size_override("font_size", 13)
	speed.add_theme_color_override("font_color", Color(0.86, 0.9, 0.98))
	row.add_child(speed)
	row.add_child(view_tag)
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 14)
	row2.alignment = BoxContainer.ALIGNMENT_CENTER
	rows.add_child(row2)
	for b: DisplayBinding in [where, distance]:
		b.add_theme_font_size_override("font_size", 13)
		b.add_theme_color_override("font_color", Color(0.86, 0.9, 0.98))
		row2.add_child(b)
	corner.position = Vector2(MARGIN, MARGIN)
	add_child(corner)
	help_button.text = "Tab · help"
	help_button.add_theme_font_size_override("font_size", 12)
	help_button.focus_mode = Control.FOCUS_NONE
	help_button.pressed.connect(toggle_tab)
	corner.add_child(help_button)


func _build_column() -> void:
	column.name = "Cards"
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)


func _build_prompt() -> void:
	prompt.name = "Prompt"
	prompt.add_theme_font_size_override("font_size", 15)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shadow(prompt)
	add_child(prompt)
	hint.add_theme_stylebox_override("panel", _panel_style(0.85))
	hint.visible = false
	add_child(hint)
	var row := HBoxContainer.new()
	hint.add_child(row)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size.x = 420
	hint_label.add_theme_font_size_override("font_size", 13)
	row.add_child(hint_label)
	var ok := Button.new()
	ok.text = "Got it"
	ok.pressed.connect(func() -> void: hint.visible = false; hint_dismissed.emit())
	row.add_child(ok)


func _build_tab() -> void:
	tab_panel.name = "TabPanel"
	tab_panel.visible = false
	tab_panel.add_theme_stylebox_override("panel", _panel_style(0.9))
	add_child(tab_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_panel.add_child(scroll)
	tab_box.add_theme_constant_override("separation", 6)
	tab_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(tab_box)
	tab_box.add_child(_caption(Label.new(), "Walk to (arrows and Enter)"))
	tab_box.add_child(walk_box)
	for pair in WALK_TO:
		var b := Button.new()
		b.text = pair[1]
		b.name = "WalkTo_" + pair[0]
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(func() -> void: walk_to_requested.emit(pair[0]))
		walk_box.add_child(b)
		walk_buttons[pair[0]] = b
	var keys: Array = walk_buttons.values()
	for i in keys.size():
		var b: Button = keys[i]
		b.focus_neighbor_top = b.get_path_to(keys[(i - 1 + keys.size()) % keys.size()])
		b.focus_neighbor_bottom = b.get_path_to(keys[(i + 1) % keys.size()])
	tab_box.add_child(_caption(Label.new(), "Display"))
	tab_box.add_child(display_box)
	tab_box.add_child(_caption(Label.new(), "Journey"))
	tab_box.add_child(transit_rows)
	for r in JourneyHud.ROWS:
		_binding_row(transit_rows, r[0], r[1], r[2])
	tab_box.add_child(ism_details)
	ism_details.add_child(_caption(Label.new(), "Medium here"))
	for r in [["Medium", "ship.ism.medium", "ism_medium"], ["Density", "ship.ism.n_h_cm3", "ism_density"], ["Mass-equivalent", "ship.ism.n_eff_m3", "sci m⁻³"], ["Visible flashes", "ship.ism.dust.visible_rate", "sci /ship-s"], ["Bright flashes", "ship.ism.dust.bright_rate", "sci /ship-s"], ["Grains swept", "ship.ism.dust.leg_grains", "sci (≥ 1 µm)"], ["Bright flashes this leg", "ship.ism.dust.leg_drawn", "%s"], ["Expected bright", "ship.ism.dust.leg_expected", "sci"], ["Largest grain", "ship.ism.dust.largest_um", "%.2f µm"], ["Largest impact", "ship.ism.dust.largest_j", "sci J"]]:
		_binding_row(ism_details, r[0], r[1], r[2])
	ism_details.add_child(_caption(Label.new(), "Planned route media"))
	var route := DisplayBinding.new().bind("hud.ism.route", "text")
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ism_details.add_child(route)
	ism_details.visible = false
	tab_box.add_child(_caption(Label.new(), "Details"))
	for rt: RichTextLabel in [details, help]:
		rt.fit_content = true
		rt.scroll_active = false
		rt.custom_minimum_size.x = 400
		rt.add_theme_font_size_override("normal_font_size", 12)
	tab_box.add_child(details)
	tab_box.add_child(_caption(Label.new(), "Controls"))
	help.text = ShipControls.help_text(dev)
	tab_box.add_child(help)
	dev_box.visible = dev
	tab_box.add_child(dev_box)


func _binding_row(parent: Container, caption: String, field: String, fmt: String) -> DisplayBinding:
	var line := HBoxContainer.new()
	parent.add_child(line)
	line.add_child(_caption(Label.new(), caption))
	var b := DisplayBinding.new().bind(field, fmt)
	b.add_theme_font_size_override("font_size", 13)
	line.add_child(b)
	_bindings_dirty = true
	return b


# ------------------------------------------------------------------ layout

func _layout() -> void:
	var w := size.x
	var h := size.y
	strip.reset_size()
	var sw := minf(strip.get_combined_minimum_size().x, w - 2.0 * (corner.get_combined_minimum_size().x + 2.0 * MARGIN))
	strip.size.x = sw
	strip.position = Vector2(maxf(0.0, (w - sw) * 0.5), 6.0)
	var cw := card_width()
	column.position = Vector2(w - cw - MARGIN, strip_bottom() + 8.0)
	column.size = Vector2(cw, 0.0)
	for id: String in cards:
		var c: Dictionary = cards[id]
		c.panel.custom_minimum_size.x = cw
		for b in c.body.find_children("*", "DisplayBinding", true, false):
			if (b as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
				(b as Label).custom_minimum_size.x = cw - 20.0
	prompt.size = Vector2(w, 24)
	prompt.position = Vector2(0, h - 48)
	hint.reset_size()
	hint.position = Vector2((w - hint.size.x) * 0.5, h - 64 - hint.size.y)
	tab_panel.position = Vector2(MARGIN, strip_bottom() + 8.0)
	tab_panel.size = Vector2(minf(440.0, w * 0.45), maxf(120.0, h - tab_panel.position.y - 60.0))


## A card is at most a third of the width less a gutter, so the column stays right of
## the centre third at any window size and UI scale.
func card_width() -> float:
	return minf(CARD_W, size.x / 3.0 - 2.0 * MARGIN)


func strip_bottom() -> float:
	return strip.position.y + strip.size.y


func toggle_tab() -> void:
	tab_panel.visible = not tab_panel.visible
	if tab_panel.visible:
		_layout()


# ------------------------------------------------------------------ cards

## Show (or refresh) a card; ttl > 0 hides it that many seconds later (display only).
## Returns its body for the caller to fill once.
func show_card(id: String, title: String, ttl := 0.0) -> VBoxContainer:
	if cards.has(id):
		var c: Dictionary = cards[id]
		if c.leaving:
			c.leaving = false
			c.born = now_s - FADE_IN_S * c.panel.modulate.a
		c.title.text = title
		c.expires = now_s + ttl if ttl > 0.0 else 0.0
		_order()
		return c.body
	var panel := PanelContainer.new()
	panel.name = "Card_" + id
	panel.add_theme_stylebox_override("panel", _panel_style(0.82))
	panel.custom_minimum_size.x = card_width()
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	box.add_child(t)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 2)
	box.add_child(body)
	column.add_child(panel)
	var pri := PRIORITY.find(id)
	cards[id] = {"panel": panel, "title": t, "body": body, "priority": pri if pri >= 0 else PRIORITY.size(), "born": now_s, "expires": now_s + ttl if ttl > 0.0 else 0.0, "leaving": false, "left_at": 0.0}
	_order()
	_bindings_dirty = true
	return body


func card_body(id: String) -> VBoxContainer:
	return cards[id].body if cards.has(id) else null


## A data line on a card: caption + a DisplayBinding on a view field.
func card_line(id: String, caption: String, field: String, fmt: String) -> DisplayBinding:
	return _binding_row(card_body(id), caption, field, fmt)


## A sim-derived text line (names may carry digits: TRAPPIST-1) shown through a binding on
## hud.cardtext.<key>; set_card_value() updates it.
func card_text(id: String, key: String, value: String) -> DisplayBinding:
	card_values[key] = value
	var b := DisplayBinding.new().bind("hud.cardtext." + key, "text")
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.x = card_width() - 20.0
	b.add_theme_font_size_override("font_size", 13)
	card_body(id).add_child(b)
	_bindings_dirty = true
	return b


func set_card_value(key: String, value: String) -> void:
	card_values[key] = value


func card_button(id: String, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 12)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(action)
	var body := card_body(id)
	var row: HFlowContainer = body.get_node_or_null("Buttons")
	if row == null:
		row = HFlowContainer.new()
		row.name = "Buttons"
		body.add_child(row)
	row.add_child(b)
	return b


## Start a card's fade-out; it is freed 0.6 s later.
func hide_card(id: String) -> void:
	if cards.has(id) and not cards[id].leaving:
		cards[id].leaving = true
		cards[id].left_at = now_s
		_order()


func has_card(id: String) -> bool:
	return cards.has(id) and not cards[id].leaving


## Cards by priority (leaving ones last); the first MAX_EXPANDED show their bodies.
func ordered() -> Array:
	var ids: Array = cards.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ca: Dictionary = cards[a]
		var cb: Dictionary = cards[b]
		if ca.leaving != cb.leaving:
			return cb.leaving
		return ca.priority < cb.priority if ca.priority != cb.priority else a < b)
	return ids


func expanded() -> Array:
	return ordered().filter(func(id: String) -> bool: return not cards[id].leaving and cards[id].body.visible)


func _order() -> void:
	var n := 0
	for id: String in ordered():
		var c: Dictionary = cards[id]
		column.move_child(c.panel, n)
		c.body.visible = not c.leaving and n < MAX_EXPANDED
		n += 1


## The fake-clock seam: every fade and card lifetime advances here, never on wall time.
func advance(dt: float) -> void:
	now_s += maxf(dt, 0.0)
	for id: String in cards.keys():
		var c: Dictionary = cards[id]
		if c.leaving:
			var a: float = 1.0 - (now_s - float(c.left_at)) / FADE_OUT_S
			if a <= 0.0:
				c.panel.queue_free()
				column.remove_child(c.panel)
				cards.erase(id)
				_bindings_dirty = true
				continue
			c.panel.modulate.a = minf(c.panel.modulate.a, a)
		else:
			c.panel.modulate.a = clampf((now_s - c.born) / FADE_IN_S, 0.0, 1.0)
			if c.expires > 0.0 and now_s >= c.expires:
				hide_card(id)
	_order()


# ------------------------------------------------------------------ data

## Show a view: the sim's world plus "hud" (where, distance, speed, home_caption, dwell)
## and "client" (warp) sections the demo builds from sim fields.
func update(view: Dictionary) -> void:
	_update_medium(view)
	var hud: Dictionary = view.get("hud", {})
	hud["cardtext"] = card_values
	hud["dwell"] = dwell_value
	view["hud"] = hud
	_last_view = view
	home_cap.text = str(hud.get("home_caption", "Earth"))
	if _bindings_dirty:
		_bindings = find_children("*", "DisplayBinding", true, false)
		_bindings_dirty = false
	for b: DisplayBinding in _bindings:
		if is_instance_valid(b):
			b.update_from(view)
	_place_dwell()
	speed.visible = not speed.text.is_empty()
	distance.visible = not distance.text.is_empty()
	_layout()


## New sessions are snapshots, not boundary events; never announce their initial medium.
func reset_medium(view: Dictionary) -> void:
	_medium_seen = str(GalaxyMap.field_value(view, "ship.ism.medium")) if IsmHud.supported(view) else ""
	hide_card("medium_notice")
	hide_card("medium_here")


func _update_medium(view: Dictionary) -> void:
	var supported := IsmHud.supported(view)
	ism_details.visible = supported
	if not supported:
		reset_medium(view)
	else:
		var ism: Dictionary = view.ship.ism
		var current := str(ism.medium)
		var hud: Dictionary = view.get("hud", {})
		hud["ism"] = {"impacts": IsmHud.impact_text(ism), "route": IsmHud.route_text(view.get("journey", {}).get("plan", {}).get("media", []))}
		view["hud"] = hud
		if not _medium_seen.is_empty() and current != _medium_seen:
			show_card("medium_notice", "Medium boundary", 8.0)
			if card_body("medium_notice").get_child_count() == 0: card_text("medium_notice", "medium_notice", "")
			set_card_value("medium_notice", "Leaving %s\nEntering %s · n_H %s" % [IsmHud.medium_name(_medium_seen), IsmHud.medium_name(current), IsmHud.density_text(float(ism.n_h_cm3))])
		_medium_seen = current
		if has_card("medium_here"): set_card_value("medium_here", medium_here_text(view))
	if not cards.has("transit"): return
	var body := card_body("transit")
	var rows: VBoxContainer = body.get_node_or_null("IsmTransit")
	if rows == null and supported:
		rows = VBoxContainer.new()
		rows.name = "IsmTransit"
		body.add_child(rows)
		body.move_child(rows, mini(5, body.get_child_count() - 1)) # after ISM load
		for r in [["Medium", "ship.ism.medium", "ism_medium"], ["Density", "ship.ism.n_h_cm3", "ism_density"], ["Dust impacts", "hud.ism.impacts", "text"]]:
			# Long medium names/density/impact descriptions wrap within the right column.
			rows.add_child(_caption(Label.new(), r[0]))
			var b := DisplayBinding.new().bind(r[1], r[2])
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size.x = card_width() - 20.0
			b.add_theme_font_size_override("font_size", 12)
			rows.add_child(b)
		_bindings_dirty = true
	if rows != null: rows.visible = supported


func show_medium_here(view: Dictionary) -> bool:
	if not IsmHud.supported(view): return false
	show_card("medium_here", "Medium here")
	if card_body("medium_here").get_child_count() == 0:
		card_text("medium_here", "medium_here", "")
	set_card_value("medium_here", medium_here_text(view))
	update(view)
	return true


static func medium_here_text(view: Dictionary) -> String:
	return "%s\nn_H %s\n%s" % [IsmHud.medium_name(str(view.ship.ism.medium)), IsmHud.density_text(float(view.ship.ism.n_h_cm3)), IsmHud.impact_text(view.ship.ism)]


func set_view_tag(text: String) -> void:
	view_tag.text = text


func set_prompt(text: String) -> void:
	prompt.text = text


func show_hint(text: String) -> void:
	hint_label.text = text
	hint.visible = true
	_layout()


## The dwell label beside a point (canvas coordinates); "" hides it.
func set_dwell(text: String, at: Vector2) -> void:
	dwell_value = text
	dwell.visible = not text.is_empty()
	_dwell_at = at
	_place_dwell()


var _dwell_at := Vector2.ZERO


## Beside its point, but never into the card column (placed after the binding has its text).
func _place_dwell() -> void:
	if not dwell.visible:
		return
	dwell.reset_size()
	var x := minf(_dwell_at.x + 14.0, column.position.x - MARGIN - dwell.get_combined_minimum_size().x)
	dwell.position = Vector2(maxf(MARGIN, x), _dwell_at.y - 8.0)


## Everything the HUD shows as text (tests): strip, cards, prompt, and Tab details when open.
func all_text() -> String:
	var parts := PackedStringArray([ship_cap.text, ship_clock.text, home_cap.text, home_clock.text, where.text, distance.text, speed.text, view_tag.text])
	for id: String in ordered():
		var c: Dictionary = cards[id]
		if c.leaving:
			continue
		parts.append(c.title.text)
		for b in c.body.find_children("*", "Label", true, false):
			parts.append((b as Label).text)
	parts.append(prompt.text)
	if tab_panel.visible:
		parts.append(details.get_parsed_text())
	return "\n".join(parts)


## Years as a readable duration: seconds through years (display only).
static func duration_text(years: float) -> String:
	var s := years * 31557600.0
	if s < 120.0: return "%.0f s" % s
	if s < 7200.0: return "%.1f min" % (s / 60.0)
	if s < 172800.0: return "%.1f h" % (s / 3600.0)
	if years < 2.0: return "%.1f days" % (s / 86400.0)
	return "%.2f yr" % years
