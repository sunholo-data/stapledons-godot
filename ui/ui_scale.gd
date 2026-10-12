class_name UiScale
extends RefCounted
## HiDPI window setup and the runtime UI zoom (review-build polish after
## v0.3.1-m2-journey: "very small for my screen" on a Retina MacBook).
##
## project.godot stretches canvas items (aspect expand) from the 960x540 base,
## so the panel and HUD scale with the window while the 3D view renders at the
## window's full pixel size. On a HiDPI screen the window opens at
## base x DisplayServer.screen_get_scale() (fitted to the screen), so the UI
## comes up at the screen's scale. Cmd/Ctrl + / - / 0 then multiplies the
## window's content_scale_factor within [MIN, MAX].
##
## Captures and goldens (--capture, --map-capture, --golden) keep the old
## unstretched 1:1 window with factor 1.0, so their PNGs and pixel maths do
## not change.

const MIN := 0.75
const MAX := 3.0
const STEP := 0.25


## The factor after a UI-zoom key: + / = grows by STEP, - shrinks, 0 resets
## to 1.0; clamped to [MIN, MAX]. Any other key leaves it unchanged.
static func step(factor: float, keycode: Key) -> float:
	match keycode:
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			return clampf(factor + STEP, MIN, MAX)
		KEY_MINUS, KEY_KP_SUBTRACT:
			return clampf(factor - STEP, MIN, MAX)
		KEY_0, KEY_KP_0:
			return 1.0
	return factor


## A pressed Cmd/Ctrl + / = / - / 0 (keypad too).
static func is_zoom_event(event: InputEvent) -> bool:
	var k := event as InputEventKey
	if k == null or not k.pressed or not (k.is_command_or_control_pressed() or k.ctrl_pressed or k.meta_pressed):
		return false
	return k.keycode in [KEY_EQUAL, KEY_PLUS, KEY_KP_ADD, KEY_MINUS, KEY_KP_SUBTRACT, KEY_0, KEY_KP_0]


## Apply a UI-zoom key to the window; true if the event was a zoom key.
static func handle(win: Window, event: InputEvent) -> bool:
	if not is_zoom_event(event):
		return false
	win.content_scale_factor = step(win.content_scale_factor, (event as InputEventKey).keycode)
	return true


## The window size for a HiDPI screen: base x scale, shrunk (aspect kept) to
## 90% of the usable screen area.
static func fitted_size(base: Vector2i, scale: float, usable: Vector2i) -> Vector2i:
	var want := Vector2(base) * maxf(scale, 1.0)
	var fit := minf(1.0, minf(usable.x * 0.9 / want.x, usable.y * 0.9 / want.y))
	return Vector2i((want * fit).round())


## Startup: `fixed` (captures, goldens) pins the old 1:1 unstretched window;
## otherwise the window is grown to the screen's scale when it opened smaller.
static func configure(win: Window, fixed: bool) -> void:
	win.content_scale_factor = 1.0
	if fixed:
		win.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		return
	var screen := win.current_screen
	var scale := DisplayServer.screen_get_scale(screen)
	if scale <= 1.0 or win.mode != Window.MODE_WINDOWED:
		return
	var want := fitted_size(win.content_scale_size, scale, DisplayServer.screen_get_usable_rect(screen).size)
	if win.size.x < want.x and win.size.y < want.y:
		win.size = want
		win.move_to_center()
