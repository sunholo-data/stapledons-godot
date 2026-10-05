extends Control
const Info = preload("res://ui/star_info.gd")
const StarProjection = preload("res://sky/star_projection.gd")
const Occlusion = preload("res://ui/star_occlusion.gd")
signal open_map(id: String)
var info := Info.new()
var occlusion := Occlusion.new()
var demo: Node
var held := false
var suppressed := false
var candidates: Array = []
var eligible: Array = []
var selected_id := ""
var card := PanelContainer.new()
var content := VBoxContainer.new()
var hovered: Array = []
var _field_count := -1
var _identity_revision := -1
var _sample_cache := {}
var _cache_signature: Array = []
func setup(host: Node) -> void:
	demo = host
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.load_files()
	occlusion.build(demo.geometry)
	add_child(card)
	var margin := MarginContainer.new();card.add_child(margin);margin.add_child(content)
	for side in ["left","top","right","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.hide()
	demo.get_window().focus_exited.connect(func():set_held(false))
func set_held(value: bool) -> void:
	held = value and not suppressed
	if not held:candidates.clear(); hovered.clear()
	queue_redraw()
func reindex() -> void:
	eligible.clear()
	var field: Starfield = demo.sky.starfield
	var counts := {}
	for id in field.ids:
		if not id.is_empty():counts[id] = counts.get(id,0)+1
	for i in field.count:
		if i < field.ids.size() and counts.get(field.ids[i],0) == 1 and info.records.has(field.ids[i]):eligible.append(i)
	_field_count = field.count
	_identity_revision = field.identity_revision
func update_candidates() -> void:
	candidates.clear()
	if suppressed or not held:return
	var sky: InteriorSky = demo.sky
	var field := sky.starfield
	if field.identity_revision != _identity_revision:reindex()
	if not demo.sky_only:occlusion.refresh(demo.camera)
	var px := Vector2(demo.geometry_view.size)
	var ctx := StarProjection.context(field)
	# Camera pan changes projection/occlusion, not the apparent physics ray.
	# Invalidate on actual uploaded observer/photometry or identity changes.
	var signature: Array = [field.identity_revision,field.replacement_revision,field.rebases,field.origin,ctx.ship,ctx.b,ctx.g,ctx.bh,ctx.om,ctx.exposure,ctx.floor_flux,ctx.floor_peak,ctx.min_r2,ctx.cull_peak]
	if signature != _cache_signature:
		_sample_cache.clear();_cache_signature = signature
	var view := sky.camera.global_basis.transposed()
	var focal := .5*px.y/tan(deg_to_rad(sky.camera.fov)*.5)
	var canvas_to_pixel := get_viewport().get_stretch_transform()*get_global_transform_with_canvas()
	for k in eligible:
		if not _sample_cache.has(k):_sample_cache[k] = StarProjection.direction(field,k,ctx)
		var sample: Dictionary = _sample_cache[k]
		if sample.is_empty():continue
		var local: Vector3 = view*sample.direction
		if local.z >= 0.:continue
		var point := Vector2(px.x*.5-focal*local.x/local.z,px.y*.5+focal*local.y/local.z)
		if not Rect2(Vector2.ZERO,px).has_point(point):continue
		if not sample.has("visible"):sample.visible = StarProjection.visible(field,k,sample,ctx)
		if not sample.visible:continue
		# The astronomical renderer has opaque foreground surfaces too.
		# Ship BVH alone cannot hide a background star behind a planet or Sun.
		var observed:Vector3=sample.direction
		var replacement:Dictionary=sample.get("replacement",{})
		if sky.system_view!=null and sky.system_view.visible and sky.system_view.occludes_direction(PackedFloat64Array([observed.x,observed.y,observed.z]),replacement.get("body_id",""),replacement.get("distance",INF)):continue
		var ray: Vector3 = demo.camera.project_ray_normal(point)
		if not demo.sky_only and occlusion.blocked(demo.camera.global_position,ray):continue
		candidates.append({id=field.ids[k],point=canvas_to_pixel.affine_inverse()*point,pixel=point,index=k})
	queue_redraw()
func _process(_delta: float) -> void:
	if demo == null:return
	suppressed = demo.benchmark.running or (demo.navigation_window != null and demo.navigation_window.visible) or demo.controls.visible
	if suppressed:set_held(false)
	if held:
		update_candidates()
		hovered = at_point(get_local_mouse_position())
		queue_redraw()
func at_point(point: Vector2) -> Array:
	return candidates.filter(func(candidate):return candidate.point.distance_to(point) <= 12.)
func inspect(id: String) -> bool:
	if not info.records.has(id):return false
	selected_id = id
	_clear_card()
	var facts := Label.new(); facts.text = info.text(id)
	facts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; facts.custom_minimum_size.x = 310
	content.add_child(facts)
	var row := HBoxContainer.new();content.add_child(row)
	var map := Button.new();map.text = "Open in map";map.pressed.connect(func():open_map.emit(id));row.add_child(map)
	var close := Button.new();close.text = "Close";close.pressed.connect(close_card);row.add_child(close)
	_show_card()
	return true
func _clear_card() -> void:
	for child in content.get_children():content.remove_child(child);child.queue_free()
func _show_card() -> void:
	card.position = Vector2(maxf(12.,size.x-350.),maxf(160.,size.y-235.));card.size = Vector2(330,0);card.show()
func close_card() -> void:
	selected_id = "";card.hide()
func click_at(point: Vector2) -> bool:
	if not held or suppressed:return false
	var hits := at_point(point)
	if hits.size() == 1:return inspect(hits[0].id)
	if hits.size() > 1:
		selected_id = ""
		_clear_card()
		var title := Label.new();title.text = "Overlapping sources — choose exact ID";content.add_child(title)
		var scroll := ScrollContainer.new();scroll.custom_minimum_size = Vector2(310,130);scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
		var list := VBoxContainer.new();list.size_flags_horizontal = Control.SIZE_EXPAND_FILL;scroll.add_child(list)
		for hit in hits:
			var button := Button.new();button.text = "%s · %s" % [info.display_name(hit.id),hit.id]
			button.tooltip_text = button.text;button.clip_text = true;button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.pressed.connect(inspect.bind(hit.id));list.add_child(button)
		var close := Button.new();close.text = "Close";close.pressed.connect(close_card);content.add_child(close)
		_show_card()
	return true # I-click never propagates to walking, even on empty sky
func handle_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.physical_keycode == KEY_I:
		set_held(event.pressed);return true
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE and card.visible:
		close_card();return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.alt_pressed:
		if card.visible and card.get_global_rect().has_point(event.position):return false
		return click_at(event.position)
	return false
func _input(event: InputEvent) -> void:
	if handle_input(event):get_viewport().set_input_as_handled()
func _draw() -> void:
	if not held or suppressed:return
	var cells := {}
	for candidate in candidates:
		var cell := Vector2i(candidate.point/10.)
		if cells.has(cell):continue
		cells[cell] = true
		draw_arc(candidate.point,5.,0.,TAU,16,Color(.55,.85,.9,.85),1.2,true)
	if not hovered.is_empty():
		var title := info.display_name(hovered[0].id) if hovered.size() == 1 else "%d overlapping known sources" % hovered.size()
		draw_string(ThemeDB.fallback_font,Vector2(clampf(get_local_mouse_position().x+15,10,size.x-260),clampf(get_local_mouse_position().y-12,20,size.y-20)),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
