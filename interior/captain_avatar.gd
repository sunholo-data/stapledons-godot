class_name CaptainAvatar
extends Sprite3D
## M4.2 the captain on the bridge: a flat billboard sprite in the iso play layer (ai-showcase
## §4: a static avatar; walk cycles come later). Data: assets/characters/captain/manifest.json
## (avatar_spec: 1024 x 1536 canvas, foot anchor (512, 1440) px, 720 px/m, drawn for the
## -14 deg iso pitch) and one sprite per life stage and facing.
##
##   life stage : the latest age_stage <= years since departure (ship proper time, clock.tau:
##                the captain ages on the ship's clock), clamped to the first stage
##   facing     : from the movement on screen: moving up the screen shows the back, down the
##                front; sideways or standing keeps the last facing
##   scale      : pixel_size = 1 / px_per_m, and a full billboard faces the orthographic iso
##                camera, so 720 px of sprite are 1 m in the view
##   anchor     : the foot anchor pixel sits at the node origin (the walk position)
## Presentation only: the avatar never goes to the sim.

var textures := {} # "y<stage>_<facing>" -> Texture2D
var stages: Array[int] = []
var stage := 0
var facing := "front"
var anchor_px := Vector2(512, 1440)
var canvas_px := Vector2(1024, 1536)
var last_error := ""


## The latest stage <= years (the first stage for years below it).
static func stage_for(years: float, list: Array) -> int:
	var best: int = list[0]
	for s: int in list:
		if float(s) <= years and s > best:
			best = s
	return best


func load_dir(dir: String) -> bool:
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("manifest.json")))
	if not m is Dictionary or not m.get("avatar_spec") is Dictionary or not m.get("files") is Array:
		last_error = "captain manifest missing or malformed: %s" % dir
		return false
	var spec: Dictionary = m["avatar_spec"]
	canvas_px = Vector2(spec["canvas_px"][0], spec["canvas_px"][1])
	anchor_px = Vector2(spec["foot_anchor_px"][0], spec["foot_anchor_px"][1])
	pixel_size = 1.0 / float(spec["px_per_m"])
	for f: Dictionary in m["files"]:
		if f.get("kind") != "avatar":
			continue
		var tex := _texture(dir.path_join(f["file"]))
		if tex == null:
			last_error = "captain sprite missing: %s" % f["file"]
			return false
		textures["y%d_%s" % [int(f["age_stage"]), f["facing"]]] = tex
		if not int(f["age_stage"]) in stages:
			stages.append(int(f["age_stage"]))
	stages.sort()
	if stages.is_empty():
		last_error = "captain manifest lists no avatar sprites"
		return false
	centered = false
	offset = Vector2(-anchor_px.x, anchor_px.y - canvas_px.y) # Sprite3D local y is up: rect bottom at offset.y
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	shaded = false
	alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	stage = stages[0]
	_show()
	return true


## Ship years since departure -> life stage.
func set_years(years: float) -> void:
	var s := stage_for(years, stages)
	if s != stage:
		stage = s
		_show()


## Movement on screen this frame (x right, y down): sets the facing.
func set_motion(screen_dir: Vector2) -> void:
	var f := facing
	if screen_dir.y < -1e-6:
		f = "back"
	elif screen_dir.y > 1e-6:
		f = "front"
	if f != facing:
		facing = f
		_show()


## Where the foot anchor pixel lands in the node's local frame (metres); zero by construction.
func anchor_local() -> Vector3:
	var r := get_item_rect() # local pixels, y up, rect bottom-left = offset
	return Vector3(r.position.x + anchor_px.x, r.position.y + canvas_px.y - anchor_px.y, 0.0) * pixel_size


func _show() -> void:
	var key := "y%d_%s" % [stage, facing]
	if textures.has(key):
		texture = textures[key]


## The sprite as a mipmapped texture: imported (editor and export) or the raw PNG.
static func _texture(path: String) -> Texture2D:
	if _offered.has(path): # made moments ago by the loading jump (ui/loading_jump.gd), one a frame
		var t: Texture2D = _offered[path]
		_offered.erase(path)
		return t
	return make_texture(path)


## Textures make_texture() built ahead of a load_dir, taken once each; main thread only.
static var _offered := {}


static func offer_texture(path: String) -> void:
	var t := make_texture(path)
	if t != null:
		_offered[path] = t


static func clear_offered() -> void:
	_offered.clear()


## The sprite files load_dir(dir) reads, in its order.
static func sprite_paths(dir: String) -> Array[String]:
	var out: Array[String] = []
	var m: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("manifest.json")))
	if m is Dictionary and m.get("files") is Array:
		for f: Variant in m["files"]:
			if f is Dictionary and f.get("kind") == "avatar":
				out.append(dir.path_join(str(f.get("file", ""))))
	return out


static func make_texture(path: String) -> Texture2D:
	var img: Image = null
	if ResourceLoader.exists(path):
		var t := load(path) as Texture2D
		img = t.get_image() if t != null else null
	elif FileAccess.file_exists(path):
		img = Image.load_from_file(path)
	if img == null or img.is_empty():
		return null
	if img.is_compressed():
		img.decompress()
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

## Current 3D ship: the painted billboard has no physical thickness. A small
## stationary 3D volume casts a grounded shadow; it never draws or masks stars.
func install_grounded_shadow()->Node3D:
	var existing:=get_node_or_null("GroundedShadow")
	if existing!=null:return existing
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var root:=Node3D.new();root.name="GroundedShadow";add_child(root)
	for side in [-1.,1.]:
		var leg:=CapsuleMesh.new();leg.radius=.085;leg.height=.8
		_shadow_part(root,leg,Vector3(side*.12,.4,0.))
	var body:=CapsuleMesh.new();body.radius=.23;body.height=.8
	_shadow_part(root,body,Vector3(0.,1.05,0.))
	var head:=SphereMesh.new();head.radius=.12;head.height=.24
	_shadow_part(root,head,Vector3(0.,1.62,0.))
	return root
static func _shadow_part(parent:Node3D,mesh:Mesh,position:Vector3)->void:
	var part:=MeshInstance3D.new();part.mesh=mesh;part.position=position
	part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	parent.add_child(part)
