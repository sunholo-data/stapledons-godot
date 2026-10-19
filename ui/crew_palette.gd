class_name CrewPalette
extends RefCounted
## R2-CREW-CONSOLE-V2 V2 (design crew-console-v2.md §V2, AC6): one palette for the crew's work
## states. Colour is never the only carrier: every state has a colour token, an icon and a word
## (the chip), and the token encodes whose move it is, not virtue (Pillar 2: refused is a fact).
## The hues are the Okabe-Ito set plus tints; `CrewPalette.check()` proves the contrast and the
## colour-blind separation (Machado 2009 at severity 1.0, CIEDE2000) the tests assert.
## Pure: no nodes, no state. The sim names the state (protocol 2.11 crew.members[].work_state);
## the only client state is `sending` (intents queued, the ship has not ticked yet).

const PANEL := Color("#0b0f17")   ## ShipHud._panel_style(0.94) over the dark sky
const TEXT := Color("#dbe6fa")
const DIM := Color("#9eabc8")
const TITLE := Color("#f2d180")
const ON_CHIP := Color("#0b0f17") ## chip words on a filled chip
const ROW := Color("#111827")     ## a roster row and the decision panel
const CALL_BG := Color("#070a11") ## the call window's screen
const EDGE := Color("#26324a")

## token -> {color, icon, edge}. Edges: solid, dashed (sending: nothing has happened yet), striped
## (held: auto-run is waiting), outline (refused: a fact, drawn hollow so it never reads as alarm).
const TOKENS := {
	"st-free": {"color": Color("#8c9bb5"), "icon": "plus", "edge": "outline"},
	"st-sending": {"color": Color("#6fa8dc"), "icon": "arrow", "edge": "dashed"},
	"st-asked": {"color": Color("#3d8fd1"), "icon": "clock", "edge": "solid"},
	"st-needs": {"color": Color("#e69f00"), "icon": "alert", "edge": "solid"},
	"st-agreed": {"color": Color("#7fdcb0"), "icon": "check", "edge": "solid"},
	"st-working": {"color": Color("#009e73"), "icon": "play", "edge": "solid"},
	"st-resting": {"color": Color("#cc79a7"), "icon": "moon", "edge": "solid"},
	"st-refused": {"color": Color("#e8742a"), "icon": "cross", "edge": "outline"},
	"st-done": {"color": Color("#9a8fc0"), "icon": "double_check", "edge": "solid"},
	"st-held": {"color": Color("#f0e442"), "icon": "pause", "edge": "striped"},
}

## The sim's work_state (and the client's sending) -> token and the chip's word. "Needs you" words
## carry the reason (OQ9: a decline is open to talk).
const STATES := {
	"free": {"token": "st-free", "word": "Can offer"},
	"sending": {"token": "st-sending", "word": "Sent, waiting for the ship"},
	"asked": {"token": "st-asked", "word": "Asked, waiting for their answer"},
	"offered": {"token": "st-asked", "word": "Offered, waiting on them"},
	"concern": {"token": "st-needs", "word": "Needs you: a concern"},
	"declined": {"token": "st-needs", "word": "Needs you: declined, open to talk"},
	"deferred": {"token": "st-needs", "word": "Needs you: they asked for time"},
	"relief_asked": {"token": "st-needs", "word": "Needs you: asks to step back"},
	"stand_down_asked": {"token": "st-needs", "word": "Needs you: asks to stand down"},
	"agreed": {"token": "st-agreed", "word": "Agreed, ready to start"},
	"working": {"token": "st-working", "word": "Working"},
	"resting": {"token": "st-resting", "word": "Resting"},
	"stopped": {"token": "st-refused", "word": "Refused"},
	"done": {"token": "st-done", "word": "Done"},
	"held": {"token": "st-held", "word": "Auto-run held"},
}

## The legend row: one chip per token, its short word (the same everywhere).
const LEGEND := [["st-free", "Can offer"], ["st-sending", "Sent"], ["st-asked", "Waiting on them"], ["st-needs", "Needs you"],
	["st-agreed", "Agreed"], ["st-working", "Working"], ["st-resting", "Resting"], ["st-refused", "Refused"], ["st-done", "Done"], ["st-held", "Held"]]

## Board order: whose move it is first (needs you, then agreed), then the rest in crew order.
const SORT := {"held": 0, "concern": 0, "declined": 0, "deferred": 0, "relief_asked": 0, "stand_down_asked": 0, "agreed": 1}

## Token pairs a captain watches one member move between (the work flow, plus the needs-you and
## held states that interrupt it). Each must stay apart for colour-blind captains: CIEDE2000 >= 12
## under simulated deutan, protan and tritan vision, or a different icon and edge style.
const NEIGHBOURS := [
	["st-free", "st-sending"], ["st-sending", "st-asked"], ["st-asked", "st-needs"], ["st-asked", "st-agreed"],
	["st-needs", "st-agreed"], ["st-agreed", "st-working"], ["st-working", "st-resting"], ["st-working", "st-done"],
	["st-working", "st-refused"], ["st-needs", "st-refused"], ["st-needs", "st-held"], ["st-working", "st-held"],
	["st-done", "st-free"], ["st-refused", "st-free"], ["st-asked", "st-free"], ["st-needs", "st-free"],
]


static func token_of(state: String) -> String:
	return str(STATES.get(state, STATES["free"])["token"])


static func color_of(state: String) -> Color:
	return TOKENS[token_of(state)]["color"]


static func word_of(state: String) -> String:
	return str(STATES.get(state, STATES["free"])["word"])


static func icon_of(state: String) -> String:
	return str(TOKENS[token_of(state)]["icon"])


static func edge_of(state: String) -> String:
	return str(TOKENS[token_of(state)]["edge"])


# ------------------------------------------------------------------ the checks (AC6)

## WCAG relative luminance of an sRGB colour.
static func luminance(c: Color) -> float:
	var l := c.srgb_to_linear()
	return 0.2126 * l.r + 0.7152 * l.g + 0.0722 * l.b


static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Machado, Oliveira & Fernandes (2009) at severity 1.0, applied to linear RGB.
const MACHADO := {
	"protan": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
	"deutan": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
	"tritan": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}


static func simulate(c: Color, kind: String) -> Color:
	var l := c.srgb_to_linear()
	var m: Array = MACHADO[kind]
	var v := [l.r, l.g, l.b]
	var o := []
	for row in m:
		o.append(clampf(row[0] * v[0] + row[1] * v[1] + row[2] * v[2], 0.0, 1.0))
	return Color(o[0], o[1], o[2]).linear_to_srgb()


## CIE Lab (D65) of an sRGB colour.
static func lab(c: Color) -> Vector3:
	var l := c.srgb_to_linear()
	var x := (0.4124564 * l.r + 0.3575761 * l.g + 0.1804375 * l.b) / 0.95047
	var y := (0.2126729 * l.r + 0.7151522 * l.g + 0.0721750 * l.b)
	var z := (0.0193339 * l.r + 0.1191920 * l.g + 0.9503041 * l.b) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))


## CIEDE2000 (Sharma, Wu & Dalal 2005), kL = kC = kH = 1.
static func delta_e2000(c1: Color, c2: Color) -> float:
	return delta_e2000_lab(lab(c1), lab(c2))


static func delta_e2000_lab(a: Vector3, b: Vector3) -> float:
	var c1s := sqrt(a.y * a.y + a.z * a.z)
	var c2s := sqrt(b.y * b.y + b.z * b.z)
	var cm := (c1s + c2s) / 2.0
	var g := 0.5 * (1.0 - sqrt(pow(cm, 7) / (pow(cm, 7) + pow(25.0, 7))))
	var a1 := (1.0 + g) * a.y
	var a2 := (1.0 + g) * b.y
	var cp1 := sqrt(a1 * a1 + a.z * a.z)
	var cp2 := sqrt(a2 * a2 + b.z * b.z)
	var hp1 := 0.0 if (a1 == 0.0 and a.z == 0.0) else fposmod(rad_to_deg(atan2(a.z, a1)), 360.0)
	var hp2 := 0.0 if (a2 == 0.0 and b.z == 0.0) else fposmod(rad_to_deg(atan2(b.z, a2)), 360.0)
	var dl := b.x - a.x
	var dc := cp2 - cp1
	var dh := 0.0
	if cp1 * cp2 != 0.0:
		dh = hp2 - hp1
		if dh > 180.0: dh -= 360.0
		elif dh < -180.0: dh += 360.0
	var dH := 2.0 * sqrt(cp1 * cp2) * sin(deg_to_rad(dh / 2.0))
	var lm := (a.x + b.x) / 2.0
	var cpm := (cp1 + cp2) / 2.0
	var hm := hp1 + hp2
	if cp1 * cp2 != 0.0:
		if absf(hp1 - hp2) <= 180.0: hm = (hp1 + hp2) / 2.0
		elif hp1 + hp2 < 360.0: hm = (hp1 + hp2 + 360.0) / 2.0
		else: hm = (hp1 + hp2 - 360.0) / 2.0
	var t := 1.0 - 0.17 * cos(deg_to_rad(hm - 30.0)) + 0.24 * cos(deg_to_rad(2.0 * hm)) + 0.32 * cos(deg_to_rad(3.0 * hm + 6.0)) - 0.20 * cos(deg_to_rad(4.0 * hm - 63.0))
	var dtheta := 30.0 * exp(-pow((hm - 275.0) / 25.0, 2))
	var rc := 2.0 * sqrt(pow(cpm, 7) / (pow(cpm, 7) + pow(25.0, 7)))
	var sl := 1.0 + (0.015 * pow(lm - 50.0, 2)) / sqrt(20.0 + pow(lm - 50.0, 2))
	var sc := 1.0 + 0.045 * cpm
	var sh := 1.0 + 0.015 * cpm * t
	var rt := -sin(deg_to_rad(2.0 * dtheta)) * rc
	return sqrt(pow(dl / sl, 2) + pow(dc / sc, 2) + pow(dH / sh, 2) + rt * (dc / sc) * (dH / sh))


## Every check AC6 asks for, as {ok, lines}: one line per measurement, so the test prints them.
static func check() -> Dictionary:
	var lines: Array = []
	var ok := true
	for t: String in TOKENS:
		var col: Color = TOKENS[t]["color"]
		var on_panel := contrast(col, PANEL)
		var chip_text := contrast(ON_CHIP, col) if TOKENS[t]["edge"] in ["solid", "striped"] else contrast(col, PANEL)
		var good := on_panel >= 3.0 and chip_text >= 4.5
		ok = ok and good
		lines.append("%s %s on panel %.2f:1, chip words %.2f:1" % ["ok" if good else "FAIL", t, on_panel, chip_text])
	for pair: Array in NEIGHBOURS:
		var a: Dictionary = TOKENS[pair[0]]
		var b: Dictionary = TOKENS[pair[1]]
		var worst := INF
		for kind: String in ["none", "deutan", "protan", "tritan"]:
			var ca: Color = a["color"] if kind == "none" else simulate(a["color"], kind)
			var cb: Color = b["color"] if kind == "none" else simulate(b["color"], kind)
			worst = minf(worst, delta_e2000(ca, cb))
		var shapes: bool = a["icon"] != b["icon"] and a["edge"] != b["edge"]
		var good: bool = worst >= 12.0 or shapes
		ok = ok and good
		lines.append("%s %s / %s worst dE2000 %.1f%s" % ["ok" if good else "FAIL", pair[0], pair[1], worst, " (icon and edge differ)" if worst < 12.0 and shapes else ""])
	return {"ok": ok, "lines": lines}
