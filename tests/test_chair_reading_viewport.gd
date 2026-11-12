extends SceneTree
## Actual reading panels must scroll inside the short chair screen, not force it taller.
const HELPER := "res://ui/chair_reading_viewport.gd"
var passes := 0
var failures := 0

func check(label: String, yes: bool) -> void:
	if yes:passes += 1
	else:failures += 1
	print(("ok " if yes else "FAIL ") + label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	check("chair reading viewport implementation exists", ResourceLoader.exists(HELPER))
	if not ResourceLoader.exists(HELPER):
		finish()
		return
	root.size = Vector2i(960, 540)
	var helper = load(HELPER)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var room := Rect2(24, 349, 912, 131)
	var news := NewsPanel.new()
	layer.add_child(news)
	await process_frame
	news.show_world({"consequence": {"news": {"tier": 0, "tier_name": "x", "template_id": 1, "star_id": "alpha Cen", "slots": {"elapsed_years": 0.04398, "news_epoch": 0.04398, "news_age_years": 4.35}, "body_source": "fallback", "fallback_reason": "ai_numeral"}}})
	news.open()
	var news_connections := news.visibility_changed.get_connections().size()
	helper.fit(news, room)
	await settle()
	var scroll := news.get_parent() as ScrollContainer
	check("real NewsPanel stays intact inside a bounded scroll", scroll != null and news.is_visible_in_tree())
	if scroll != null:
		check("news viewport fits the chair and window at 960x540", room.encloses(scroll.get_global_rect()) and Rect2(0, 0, 960, 540).encloses(scroll.get_global_rect()))
		check("news overflow is clipped and scrollable", scroll.clip_contents and scroll.get_v_scroll_bar().max_value > scroll.get_v_scroll_bar().page)
		scroll.scroll_vertical = 10000
		await settle()
		check("news content can scroll to its bottom", scroll.scroll_vertical > 0 and news.global_position.y < room.position.y)
	news.close()
	await process_frame
	check("hidden news leaves no visible input-blocking wrapper", not scroll.is_visible_in_tree())
	helper.restore(news)
	await settle()
	check("physical Archive restores NewsPanel's original parent", news.get_parent() == layer)
	check("restore disconnects the wrapper visibility callback", news.visibility_changed.get_connections().size() == news_connections)
	var answer := PanelContainer.new()
	answer.name = "ArchiveAnswer"
	layer.add_child(answer)
	var body := VBoxContainer.new()
	answer.add_child(body)
	for text in ["The Archive", "You asked: Why are the clocks different?", "The ship clock records the proper time aboard. The received signal from Earth also reflects how long its light has travelled. ".repeat(24)]:
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(label)
	var answer_connections := answer.visibility_changed.get_connections().size()
	helper.fit(answer, room)
	await settle()
	var answer_scroll := answer.get_parent() as ScrollContainer
	var wrapped_connections := answer.visibility_changed.get_connections().size()
	check("long Archive answer fits the same short viewport", room.encloses(answer_scroll.get_global_rect()))
	check("long answer has usable vertical overflow", answer_scroll.get_v_scroll_bar().max_value > answer_scroll.get_v_scroll_bar().page)
	for k in 4:
		helper.restore(answer)
		helper.fit(answer, room)
		await settle()
	check("repeated chair/physical visits do not accumulate wrapper callbacks", answer.visibility_changed.get_connections().size() == wrapped_connections)
	(body.get_child(2) as Label).text = "Quiet."
	await settle()
	check("short reading content fills the viewport so nested codex text does not collapse", answer.size.y >= room.size.y)
	helper.restore(answer)
	await settle()
	check("answer restore removes wrapper callbacks", answer.visibility_changed.get_connections().size() == answer_connections)
	check("all temporary wrappers disappear on restore", layer.get_child_count() == 2 and answer.get_parent() == layer)
	layer.queue_free()
	await process_frame
	finish()

func settle() -> void:
	for k in 8:await process_frame

func finish() -> void:
	print("chair-reading-viewport: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)
