extends SceneTree
## Planet albedo texture normalisation (M5.2a, design m5-planets §M5.2): the
## texture sets pattern and colour, the data's p_V sets brightness.
##
##   godot --headless --path . --script tools/planet_textures.gd -- --write
##       writes data/planets/ALBEDO: per body, the texture's disc-integrated mean
##       linear luminance for that body's Minnaert k, rotationally averaged at an
##       equatorial view: mean = sum Y cos^(2k+1)(lat) / sum cos^(2k+1)(lat) over
##       the equirectangular texels (at opposition a surface element contributes
##       rho mu^(2k) dA, and the average of max(0, cos(lon - lon0))^(2k) over lon0
##       is the same for every longitude, leaving the latitude weight).
##   ... -- --check
##       the independent check: ray-samples the visible disc at opposition on a
##       256 x 256 grid at 12 sub-observer longitudes, weights each sample by its radiance mu^(2k-1), and
##       requires the disc-integrated albedo the renderer produces with the
##       table's mean, p_V x <Y>_disc / mean averaged over longitude, to equal
##       p_V within 1% for every texture. Skips (exit 0) without the textures.
## Body k and p_V come from the sim's recorded system section
## (tests/fixtures/system_sol.ndjson), never typed in here. Earth composites
## its cloud map over the day map as planets/planet.gdshader does:
## rgb = mix(day, white, cloud).

const DIR := "res://assets/planets"
const TABLE := "res://data/planets/ALBEDO"
const FIXTURE := "res://tests/fixtures/system_sol.ndjson"
const MAP := {"mercury": "2k_mercury.jpg", "venus": "2k_venus_atmosphere.jpg",
	"earth": "2k_earth_daymap.jpg+2k_earth_clouds.jpg", "moon": "2k_moon.jpg", "mars": "2k_mars.jpg",
	"jupiter": "2k_jupiter.jpg", "saturn": "2k_saturn.jpg", "uranus": "2k_uranus.jpg", "neptune": "2k_neptune.jpg"}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var bodies := _bodies()
	if bodies.is_empty():
		printerr("planet_textures: no system section in %s" % FIXTURE)
		quit(2)
		return
	var missing := false
	for f: String in MAP.values():
		for x in f.split("+"):
			missing = missing or not FileAccess.file_exists(DIR.path_join(x))
	if missing:
		print("planet-textures: textures not fetched (make planet-assets); check skipped")
		quit(0 if args.has("--check") else 1)
		return
	if args.has("--write"):
		quit(_write(bodies))
	elif args.has("--check"):
		quit(_check(bodies))
	else:
		printerr("usage: --write | --check")
		quit(2)


func _bodies() -> Dictionary:
	var out := {}
	for line in FileAccess.get_file_as_string(FIXTURE).split("\n"):
		var m = JSON.parse_string(line) if line.strip_edges() != "" else null
		if typeof(m) == TYPE_DICTIONARY and m.get("type") == "state" and m["changes"].has("system"):
			for b: Dictionary in m["changes"]["system"]["bodies"]:
				out[b["id"]] = b
			return out
	return out


## Linear luminance of every texel, row-major (w x h), with Earth's clouds composited.
static func luminance(files: String) -> Array:
	var parts := files.split("+")
	var base := Image.load_from_file(DIR.path_join(parts[0]))
	base.convert(Image.FORMAT_RGB8)
	var w := base.get_width()
	var h := base.get_height()
	var lut := PackedFloat64Array()
	for i in 256:
		lut.append(Color(i / 255.0, 0, 0).srgb_to_linear().r)
	var d := base.get_data()
	var cloud := PackedByteArray()
	if parts.size() > 1:
		var ci := Image.load_from_file(DIR.path_join(parts[1]))
		ci.convert(Image.FORMAT_RGB8)
		ci.resize(w, h, Image.INTERPOLATE_BILINEAR)
		cloud = ci.get_data()
	var y := PackedFloat64Array()
	y.resize(w * h)
	for i in w * h:
		var r := lut[d[3 * i]]
		var g := lut[d[3 * i + 1]]
		var bl := lut[d[3 * i + 2]]
		if not cloud.is_empty():
			var c := lut[cloud[3 * i]] # the cloud map's coverage, decoded as the shader samples it (source_color)
			r = r + (1.0 - r) * c
			g = g + (1.0 - g) * c
			bl = bl + (1.0 - bl) * c
		y[i] = 0.2126729 * r + 0.7151522 * g + 0.0721750 * bl
	return [y, w, h]


static func weighted_mean(lum: Array, k: float) -> float:
	var y: PackedFloat64Array = lum[0]
	var w: int = lum[1]
	var h: int = lum[2]
	var num := 0.0
	var den := 0.0
	for j in h:
		var lat := PI * (0.5 - (j + 0.5) / h)
		var wt := pow(cos(lat), 2.0 * k + 1.0)
		var row := 0.0
		for i in w:
			row += y[j * w + i]
		num += wt * row / w
		den += wt
	return num / den


func _write(bodies: Dictionary) -> int:
	var lines := PackedStringArray([
		"# Planet albedo texture means (M5.2a): tools/planet_textures.gd -- --write; checked by -- --check.",
		"# id file k mean: the texture's disc-integrated mean linear luminance (Rec. 709 Y of the sRGB-decoded",
		"# texels) for the body's Minnaert k, rotationally averaged at an equatorial view. planet.gdshader divides",
		"# the texel colour by mean, so the disc-integrated albedo is the sim's p_V. Textures: data/planets/SHA256SUMS."])
	for id: String in MAP:
		var k: float = bodies[id]["minnaert_k"]
		var mean := weighted_mean(luminance(MAP[id]), k)
		lines.append("%s %s %s %.9f" % [id, MAP[id], str(k), mean])
		print("  %-8s k %.3f  mean %.6f  (%s)" % [id, k, mean, MAP[id]])
	var f := FileAccess.open(TABLE, FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("planet-textures: wrote %s (%d bodies)" % [TABLE, MAP.size()])
	return 0


func _check(bodies: Dictionary) -> int:
	var table := SystemView.read_albedo_table(TABLE)
	var failures := 0
	for id: String in MAP:
		var b: Dictionary = bodies[id]
		var k: float = b["minnaert_k"]
		var p_v: float = b["p_v"]
		var row: Dictionary = table.get(id, {})
		if row.is_empty() or row["file"] != MAP[id] or not is_equal_approx(row["k"], k):
			print("FAIL  %-8s ALBEDO row missing or stale (file/k): %s" % [id, row])
			failures += 1
			continue
		var lum := luminance(MAP[id])
		var acc := 0.0
		for lon0 in 12:
			acc += _disc_mean(lum, k, TAU * lon0 / 12.0)
		var p: float = p_v * (acc / 12.0) / row["mean"]
		var ok := absf(p / p_v - 1.0) < 0.01
		if not ok:
			failures += 1
		print("%s  %-8s disc-integrated albedo %.4f, p_V %.4f (ratio %.4f, limit 1%%)" % ["ok  " if ok else "FAIL", id, p, p_v, p / p_v])
	print("planet-textures check: %d textures, %d failures" % [MAP.size(), failures])
	return 1 if failures > 0 else 0


## <Y> over the visible disc at opposition, as the disc integral weights it, sub-observer longitude lon0, equatorial view.
static func _disc_mean(lum: Array, k: float, lon0: float) -> float:
	var y: PackedFloat64Array = lum[0]
	var w: int = lum[1]
	var h: int = lum[2]
	var n := 256
	var num := 0.0
	var den := 0.0
	for j in n:
		for i in n:
			var x := -1.0 + (i + 0.5) * 2.0 / n
			var v := 1.0 - (j + 0.5) * 2.0 / n
			var r2 := x * x + v * v
			if r2 >= 1.0:
				continue
			var z := sqrt(1.0 - r2)
			var bx := z * cos(lon0) - x * sin(lon0)
			var by := z * sin(lon0) + x * cos(lon0)
			var u := 0.5 + atan2(by, bx) / TAU
			var t := 0.5 - asin(v) / PI
			var wt := pow(z, 2.0 * k - 1.0) # radiance mu^(2k-1) per unit projected area (the grid is in the projected disc)
			num += wt * y[clampi(int(t * h), 0, h - 1) * w + clampi(int(u * w), 0, w - 1)]
			den += wt
	return num / den
