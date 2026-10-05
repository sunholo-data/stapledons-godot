extends RefCounted
## Physicsless BVHs of visible opaque surfaces. Geometry lacking collision
## still occludes; current node transforms/LOD visibility are read every update.
var meshes: Array = []
var active: Array = []
var sprites: Array = []
var active_sprites: Array = []
var images := {}
func build(root: Node) -> void:
	meshes.clear()
	sprites.clear()
	_collect(root)
func _collect(node: Node) -> void:
	if node is Sprite3D:sprites.append(node)
	if node is MeshInstance3D and node.mesh != null and node.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		var faces := PackedVector3Array()
		for s in node.mesh.get_surface_count():
			if node.mesh is ImmediateMesh:continue # diagnostic line guides
			if node.mesh is ArrayMesh and node.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:continue
			var material: Material = node.get_active_material(s)
			# Alpha-cutout sprites and unknown custom shaders aren't solid masks.
			if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:continue
			# Only explicitly tagged cutout shaders may omit their rectangle;
			# unknown/opaque custom surfaces conservatively block identification.
			if material is ShaderMaterial and material.get_meta("identification_cutout",false):continue
			var arrays: Array = node.mesh.surface_get_arrays(s)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices = arrays[Mesh.ARRAY_INDEX]
			if indices != null and indices.size() > 0:
				for i in indices:faces.append(vertices[i])
			else:faces.append_array(vertices)
		if not faces.is_empty():
			var tree := TriangleMesh.new()
			if tree.create_from_faces(faces):meshes.append({node=node, tree=tree, bounds=node.mesh.get_aabb()})
	for child in node.get_children():_collect(child)
func refresh(camera: Camera3D) -> void:
	active.clear()
	active_sprites.clear()
	for mesh in meshes:
		if not is_instance_valid(mesh.node):continue
		var node: MeshInstance3D = mesh.node
		if is_instance_valid(node) and node.is_visible_in_tree() and node.layers & camera.cull_mask:
			active.append({tree=mesh.tree,bounds=mesh.bounds,inverse=node.global_transform.affine_inverse()})
	for reference in sprites:
		if not is_instance_valid(reference):continue
		var sprite: Sprite3D = reference
		if not sprite.is_visible_in_tree() or sprite.texture==null or not sprite.layers & camera.cull_mask:continue
		var texture := sprite.texture
		var key := texture.get_rid()
		if not images.has(key):
			var image := texture.get_image()
			if image==null:continue
			if image.is_compressed():image.decompress()
			image.convert(Image.FORMAT_RGBA8)
			var bytes := image.get_data();var levels := []
			for level in image.get_mipmap_count()+1:
				var width:=maxi(1,image.get_width()>>level);var height:=maxi(1,image.get_height()>>level)
				var start:=image.get_mipmap_offset(level)
				levels.append(Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,bytes.slice(start,start+width*height*4)))
			images[key]=levels
		var transform := sprite.global_transform
		if sprite.billboard==BaseMaterial3D.BILLBOARD_ENABLED:
			transform.basis = camera.global_basis.scaled(sprite.global_basis.get_scale())
		var lod := 0.
		if sprite.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC]:
			var depth:=absf(camera.global_basis.z.dot(sprite.global_position-camera.global_position))
			var focal:=.5*camera.get_viewport().get_visible_rect().size.y/tan(deg_to_rad(camera.fov)*.5)
			var scale:=minf(sprite.global_basis.get_scale().x,sprite.global_basis.get_scale().y)
			lod=clampf(log(maxf(depth/(focal*sprite.pixel_size*scale),1.))/log(2.),0.,images[key].size()-1.)
		active_sprites.append({node=sprite,levels=images[key],lod=lod,inverse=transform.affine_inverse()})
func blocked(eye: Vector3, direction: Vector3) -> bool:
	for sprite in active_sprites:
		if sprite_blocked(sprite,eye,direction):return true
	for mesh in active:
		var inverse: Transform3D = mesh.inverse
		var local_eye := inverse*eye
		var local_dir := inverse.basis*direction
		if mesh.bounds.intersects_ray(local_eye,local_dir) == null:continue
		if not mesh.tree.intersect_ray(local_eye,local_dir).is_empty():return true
	return false
static func sprite_blocked(entry: Dictionary, eye: Vector3, direction: Vector3) -> bool:
	var sprite: Sprite3D = entry.node
	var local: Vector3 = entry.inverse*eye
	var ray: Vector3 = entry.inverse.basis*direction
	# Current captain is a full billboard with Z normal; regular axis sprites
	# use their configured normal. All sampling is in the same metre plane.
	var axis: int = sprite.axis
	if absf(ray[axis])<1e-8:return false
	var distance := -local[axis]/ray[axis]
	if distance<=0.:return false
	var hit := local+ray*distance
	var coordinates := Vector2(hit.x,hit.y) if axis==2 else Vector2(hit.z,hit.y) if axis==0 else Vector2(hit.x,hit.z)
	var rectangle := sprite.get_item_rect()
	var pixel := coordinates/sprite.pixel_size
	if not rectangle.has_point(pixel):return false
	if not sprite.transparent:return true
	var uv := (pixel-rectangle.position)/rectangle.size
	uv.y=1.-uv.y
	if sprite.flip_h:uv.x=1.-uv.x
	if sprite.flip_v:uv.y=1.-uv.y
	var region := sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO,sprite.texture.get_size())
	var frame_size := region.size/Vector2(sprite.hframes,sprite.vframes)
	var coordinate := (region.position+frame_size*(Vector2(sprite.frame_coords)+uv))/sprite.texture.get_size()
	var level := int(floor(entry.lod));var next := mini(level+1,entry.levels.size()-1)
	var alpha := lerpf(sample_alpha(entry.levels[level],coordinate),sample_alpha(entry.levels[next],coordinate),entry.lod-level)*sprite.modulate.a
	var threshold := sprite.alpha_scissor_threshold if sprite.alpha_cut==SpriteBase3D.ALPHA_CUT_DISCARD else .99
	return alpha>=threshold
static func sample_alpha(image: Image, uv: Vector2) -> float:
	var point:=uv*Vector2(image.get_size())-Vector2(.5,.5)
	var x:=clampi(int(floor(point.x)),0,image.get_width()-1);var y:=clampi(int(floor(point.y)),0,image.get_height()-1)
	var x1:=mini(x+1,image.get_width()-1);var y1:=mini(y+1,image.get_height()-1)
	return lerpf(lerpf(image.get_pixel(x,y).a,image.get_pixel(x1,y).a,clampf(point.x-x,0,1)),lerpf(image.get_pixel(x,y1).a,image.get_pixel(x1,y1).a,clampf(point.x-x,0,1)),clampf(point.y-y,0,1))
