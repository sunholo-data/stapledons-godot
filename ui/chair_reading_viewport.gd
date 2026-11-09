class_name ChairReadingViewport
extends RefCounted
## Rehost existing Archive panels without copying their state or signal connections.
## The chair's short reading room clips/scrolls; physical consoles recover the original parent.
const WRAPPER := "chair_reading_wrapper"
const PARENT := "chair_reading_parent"
const INDEX := "chair_reading_index"
const CALLBACK := "chair_reading_callback"
const FLAGS := "chair_reading_flags"

static func fit(reader: Control, room: Rect2) -> void:
	var scroll := reader.get_meta(WRAPPER) as ScrollContainer if reader.has_meta(WRAPPER) else null
	if not is_instance_valid(scroll):
		var original := reader.get_parent()
		if original == null:return
		var index := reader.get_index()
		scroll = ScrollContainer.new()
		scroll.name = str(reader.name) + "ChairScroll"
		scroll.theme = reader.theme
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroll.clip_contents = true
		original.add_child(scroll)
		original.move_child(scroll, index)
		reader.reparent(scroll, false)
		reader.set_meta(WRAPPER, scroll)
		reader.set_meta(PARENT, original)
		reader.set_meta(INDEX, index)
		reader.set_meta(FLAGS, Vector2i(reader.size_flags_horizontal, reader.size_flags_vertical))
		var follow := func() -> void:
			if is_instance_valid(scroll):scroll.visible = reader.visible
		reader.visibility_changed.connect(follow)
		reader.set_meta(CALLBACK, follow)
	scroll.set_anchors_preset(Control.PRESET_TOP_LEFT)
	scroll.custom_minimum_size = Vector2.ZERO
	scroll.position = room.position
	scroll.size = room.size
	scroll.visible = reader.visible
	reader.set_anchors_preset(Control.PRESET_TOP_LEFT)
	reader.grow_horizontal = Control.GROW_DIRECTION_END
	reader.grow_vertical = Control.GROW_DIRECTION_END
	reader.position = Vector2.ZERO
	reader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reader.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bar := scroll.get_v_scroll_bar().get_combined_minimum_size().x
	# Reserve the scrollbar even before the first Container sort, so wrapped text never
	# forces a disabled horizontal scrollbar or a one-frame overflow outside the chair.
	reader.custom_minimum_size = Vector2(maxf(1.0, room.size.x - bar), 0.0)
	reader.size = Vector2(reader.custom_minimum_size.x, 0.0)

static func restore(reader: Control) -> void:
	var scroll := reader.get_meta(WRAPPER) as ScrollContainer if reader.has_meta(WRAPPER) else null
	if not is_instance_valid(scroll):return
	var original: Node = reader.get_meta(PARENT, null)
	if not is_instance_valid(original):return
	var follow: Callable = reader.get_meta(CALLBACK)
	if reader.visibility_changed.is_connected(follow):reader.visibility_changed.disconnect(follow)
	reader.reparent(original, false)
	original.move_child(reader, mini(int(reader.get_meta(INDEX, 0)), original.get_child_count() - 1))
	var flags: Vector2i = reader.get_meta(FLAGS)
	reader.size_flags_horizontal = flags.x
	reader.size_flags_vertical = flags.y
	for key in [WRAPPER, PARENT, INDEX, CALLBACK, FLAGS]:reader.remove_meta(key)
	scroll.queue_free()
