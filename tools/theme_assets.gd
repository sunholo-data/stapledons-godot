extends SceneTree
## R2-BRIDGE-STYLE S4 (OQ4 resolved by Mark, D-100): the HUD's hand-drawn ink panel border, a 9-slice
## texture drawn from a seeded jitter so it is reproducible. 96x96 px, margins 24 px:
##   - a night fill (the panel colour comes from the theme's modulate; the texture is white-on-alpha
##     for the fill so one texture serves panels and cards);
##   - a 2 px ink outline whose edge wanders by up to 0.8 px, with corners drawn slightly irregular
##     (not a perfect radius): the comic panel's hand;
##   - a warm 1 px inner rule, 5 px inside, broken twice per side like a brush lifted.
## Channels: R = fill coverage, G = ink coverage, B = rule coverage, A = 1 where anything is drawn.
## The theme builder (ui/stapledon_theme.gd) composites these into the final colours at load, so the
## palette lives in one place. Writes ui/theme/ink_panel.png; its sha256 is pinned in ui/theme/pins.json.
## Usage: godot --headless --path . --script tools/theme_assets.gd
const SIZE := 96
const SEED := 20261020
const OUT := "res://ui/theme/ink_panel.png"


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# The outline: a rounded rectangle (radius ~7 px) inset 2 px, its distance wobbled per side.
	var wob := []
	for k in 16:
		wob.append(rng.randf_range(-0.8, 0.8))
	var gaps := []
	for k in 8:
		gaps.append(rng.randf_range(0.2, 0.8))
	for y in SIZE:
		for x in SIZE:
			var d := _sdf(Vector2(x + 0.5, y + 0.5), wob)
			var fill := clampf(-d + 0.5, 0.0, 1.0) # inside the outline's inner edge
			var ink := clampf(1.5 - absf(d), 0.0, 1.0) # a ~2 px band centred on d = 0, antialiased
			var rule := 0.0
			var dr := d + 5.0 # the rule 5 px inside
			if absf(dr) < 0.75 and not _in_gap(Vector2(x, y), gaps):
				rule = 1.0 - absf(dr) / 0.75
			var a := maxf(maxf(fill, ink), rule)
			img.set_pixel(x, y, Color(fill, ink, rule, a))
	img.save_png(ProjectSettings.globalize_path(OUT))
	print("theme-assets: wrote %s sha256 %s" % [OUT, FileAccess.get_sha256(OUT)])
	quit(0)


## Signed distance to the wobbled rounded rectangle (negative inside).
func _sdf(p: Vector2, wob: Array) -> float:
	var inset := 2.0
	var r := 7.0
	var c := Vector2(SIZE, SIZE) * 0.5
	var half := c - Vector2(inset, inset)
	# Which side's wobble (4 per side, smoothly interpolated along it).
	var q := (p - c).abs() - (half - Vector2(r, r))
	var d := minf(maxf(q.x, q.y), 0.0) + Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() - r
	var ang := fposmod(atan2(p.y - c.y, p.x - c.x) / TAU, 1.0) * 16.0
	var i := int(floor(ang))
	var t := ang - i
	var w: float = lerpf(wob[i % 16], wob[(i + 1) % 16], t * t * (3.0 - 2.0 * t))
	return d - w


func _in_gap(p: Vector2, gaps: Array) -> bool:
	# Two short breaks per side, at seeded fractions along it (the brush lifted).
	var s := float(SIZE)
	var along: float
	var side: int
	if p.y < 12.0: side = 0; along = p.x / s
	elif p.y > s - 12.0: side = 1; along = p.x / s
	elif p.x < 12.0: side = 2; along = p.y / s
	else: side = 3; along = p.y / s
	for k in 2:
		if absf(along - gaps[side * 2 + k]) < 0.025: return true
	return false
