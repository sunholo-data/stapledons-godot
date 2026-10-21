extends RefCounted
## ui-theme-check negative control (R2-BRIDGE-STYLE AC6): a hard-coded panel style outside the theme.
static func panel() -> StyleBox:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.04, 0.07, 0.8)
	return st
