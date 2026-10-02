class_name StarCatalogue
extends RefCounted
## Binary catalogue tier loader (M1.2c; M1.3 renders from it).
## A tier is data/starmap/stars_<tier>.bin, 24-byte little-endian F32 records
##   x, y, z (ly, galactic), teff (K), v (mag), flags
## written by sim/tools/catalogue_main.ail, plus the stars_<tier>.json sidecar. from_files() refuses
## (returns null, reason in last_error) unless the sidecar's format_version, record_bytes,
## fields and count match and sha256(bin) equals sidecar sha256.bin. The writer cannot swap
## both files in one rename, so a sha mismatch can also mean "a commit is in flight": retry,
## never use the bytes.
##
## flags bits (sim/tools/catalogue.ail convert): 1 white dwarf, 2 missing Gaia photometry
## (then teff = 0 and v = 99), 4 white dwarf with blackbody photometry, 8 photometry from Hipparcos
## (M1.2d: V verbatim, teff from B-V; the bright tier and CNS5 rows Gaia could not measure), 16 colour
## outside the model's invertible range. Only FLAG_SETS occur; catalogue_stats.gd fails on any other value,
## which guards catalogue.ail's whiteDwarf/missingRow (they test whole flag values).

const FORMAT_VERSION := 1
const RECORD_BYTES := 24
const FLOATS := 6
const FIELDS := ["x", "y", "z", "teff", "v", "flags"]
const FLAG_WD := 1
const FLAG_MISSING_PHOT := 2
const FLAG_WD_BLACKBODY := 4
const FLAG_HIP := 8
const FLAG_OUT_OF_RANGE := 16
## Every flags value convert() can produce: 0, 16 (main sequence), 2 (missing), 3 (missing WD),
## 5, 21 (WD with photometry); and sim/tools/bright.ail: 8, 24 (Hipparcos V and B-V).
const FLAG_SETS := [0, 2, 3, 5, 8, 16, 21, 24]

static var last_error := ""

var sidecar: Dictionary
var count := 0
## count * 6 floats, record i at [6 i, 6 i + 6)
var data: PackedFloat32Array


static func little_endian_host() -> bool:
	return PackedFloat32Array([1.0]).to_byte_array() == PackedByteArray([0, 0, 0x80, 0x3f])


static func _refuse(msg: String) -> StarCatalogue:
	last_error = msg
	return null


## bin_path and json_path: res:// or absolute paths. null on any refusal (see last_error).
static func from_files(bin_path: String, json_path: String) -> StarCatalogue:
	last_error = ""
	if not little_endian_host():
		return _refuse("host is not little-endian; the tier bytes are F32 LE")
	var text := FileAccess.get_file_as_string(json_path)
	if text == "":
		return _refuse("cannot read sidecar %s" % json_path)
	var meta: Variant = JSON.parse_string(text)
	if typeof(meta) != TYPE_DICTIONARY:
		return _refuse("sidecar %s is not a JSON object" % json_path)
	var m: Dictionary = meta
	if int(m.get("format_version", -1)) != FORMAT_VERSION:
		return _refuse("format_version %s, want %d" % [m.get("format_version"), FORMAT_VERSION])
	if int(m.get("record_bytes", -1)) != RECORD_BYTES:
		return _refuse("record_bytes %s, want %d" % [m.get("record_bytes"), RECORD_BYTES])
	if m.get("fields") != FIELDS:
		return _refuse("fields %s, want %s" % [m.get("fields"), FIELDS])
	var n := int(m.get("count", -1))
	if n < 0:
		return _refuse("sidecar has no count")
	var want_sha := str(m.get("sha256", {}).get("bin", "")) if typeof(m.get("sha256")) == TYPE_DICTIONARY else ""
	if want_sha.length() != 64:
		return _refuse("sidecar has no sha256.bin")
	var bytes := FileAccess.get_file_as_bytes(bin_path)
	if bytes.size() == 0 and n > 0:
		return _refuse("cannot read %s" % bin_path)
	if bytes.size() != n * RECORD_BYTES:
		return _refuse("%s is %d B, sidecar count %d needs %d B" % [bin_path, bytes.size(), n, n * RECORD_BYTES])
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	if bytes.size() > 0:  # HashingContext refuses an empty update
		ctx.update(bytes)
	var got_sha := ctx.finish().hex_encode()
	if got_sha != want_sha:
		return _refuse("sha256(bin) %s != sidecar %s (stale pair or a commit in flight: retry)" % [got_sha, want_sha])
	var c := StarCatalogue.new()
	c.sidecar = m
	c.count = n
	c.data = bytes.to_float32_array()
	return c


## Tier by name from a directory (default res://data/starmap).
static func load_tier(tier: String, dir := "res://data/starmap") -> StarCatalogue:
	return from_files("%s/stars_%s.bin" % [dir, tier], "%s/stars_%s.json" % [dir, tier])


## F32 position; M1.3 rebases in float64 before it subtracts the ship position.
func position(i: int) -> Vector3:
	return Vector3(data[6 * i], data[6 * i + 1], data[6 * i + 2])


func teff(i: int) -> float:
	return data[6 * i + 3]


func vmag(i: int) -> float:
	return data[6 * i + 4]


func flags(i: int) -> int:
	return int(data[6 * i + 5])


func missing_photometry(i: int) -> bool:
	return flags(i) & FLAG_MISSING_PHOT != 0


func white_dwarf(i: int) -> bool:
	return flags(i) & FLAG_WD != 0


func hip_photometry(i: int) -> bool:
	return flags(i) & FLAG_HIP != 0
