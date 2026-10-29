extends RefCounted
## Review-only lived-in Commons kit. Production never calls this loader.
## Config: source_glb (res:// or config-relative GLB), bounds {min,max} in ship metres,
## placements [{name,prop,ship_m,yaw_deg,solid_meshes:[exact source mesh names]}].
## An empty solid_meshes list is deliberate decoration; substantial props name structural meshes.
## Optional plants: {name,kind,height,tint?,root:[ship metres]} OR {placement,anchor:FOLIAGE_*}.
## Optional practicals: {name,ship_m,range_m,energy,tint?}; at most eight, range<=8m, energy<=2.
## Returns {ok,node,placements,colliders,plants,plant_shadows,practicals,errors}. Any error leaves
## demo.geometry untouched. This installs art and physical props only: no WALK/camera/sim changes.
const MAX_ROWS:=128
const KINDS:=["frond","shrub","grown_planter"]

static func install(demo:Node,config_path:String)->Dictionary:
 var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(config_path)) if FileAccess.file_exists(config_path) else null
 var result:={"ok":false,"node":null,"placements":{},"colliders":[],"plants":[],"plant_shadows":[],"practicals":[],"errors":validate(parsed)}
 if not result.errors.is_empty():return result
 var host:Variant=demo.get("geometry") if demo!=null else null
 if not host is Node3D:result.errors.append("demo.geometry must be Node3D");return result
 var config:Dictionary=parsed
 var path:String=config.source_glb
 if not path.begins_with("res://"):path=config_path.get_base_dir().path_join(path).simplify_path()
 if not FileAccess.file_exists(path):result.errors.append("missing source_glb: "+path);return result
 var catalog:=AreaBundle.load_glb(path)
 if catalog==null:result.errors.append("source_glb did not load");return result
 var pilot:=Node3D.new();pilot.name="CommonsArtPilot"
 var bounds:=_bounds(config.bounds)
 for placement:Dictionary in config.placements:
  var matches:=_named(catalog,placement.prop)
  if matches.size()!=1 or not matches[0] is Node3D:
   result.errors.append("%s: source prop must name one subtree"%placement.name);continue
  var source:Node3D=matches[0]
  var meshes:=StapledonStyle.meshes(source)
  if meshes.is_empty() or not _safe_tree(source):result.errors.append("%s: unsafe or empty source subtree"%placement.name);continue
  var wrapper:=Node3D.new();wrapper.name=placement.name
  wrapper.transform=Transform3D(Basis(Vector3.UP,deg_to_rad(float(placement.yaw_deg))),ShipFrame.gltf_from_structure(placement.ship_m))
  var prop:=source.duplicate() as Node3D;wrapper.add_child(prop);pilot.add_child(wrapper)
  var box:=_mesh_bounds(prop)
  if not bounds.encloses(wrapper.transform*box):
   result.errors.append("%s: complete prop bounds leave pilot bounds"%placement.name);continue
  var solids:Array=[]
  for solid_name:String in placement.solid_meshes:
   var selected:=_named(prop,solid_name)
   if selected.size()!=1 or not selected[0] is MeshInstance3D:
    result.errors.append("%s: missing or ambiguous solid mesh %s"%[placement.name,solid_name]);continue
   var mesh:MeshInstance3D=selected[0]
   if not _opaque(mesh):result.errors.append("%s: solid mesh %s must be opaque geometry"%[placement.name,solid_name]);continue
   solids.append(mesh)
  # GLB material overrides must go through the same shared toon conversion as surface materials.
  for mesh:MeshInstance3D in StapledonStyle.meshes(prop):
   if mesh.material_override!=null:
    var material:Material=mesh.material_override
    if not StapledonStyle.excluded(mesh,material):mesh.material_override=StapledonStyle.toon_material(material)
  StapledonStyle.apply([prop])
  for mesh:MeshInstance3D in solids:
   var body:=StaticBody3D.new();body.name="PilotSolid_"+str(mesh.name);body.collision_layer=1;body.collision_mask=1
   var collider:=CollisionShape3D.new();var shape:=ConcavePolygonShape3D.new();var faces:=mesh.mesh.get_faces();var transform:=_relative(prop,mesh)
   for i in faces.size():faces[i]=transform*faces[i]
   shape.set_faces(faces);shape.backface_collision=true;collider.shape=shape;body.add_child(collider);prop.add_child(body);result.colliders.append(body)
  result.placements[placement.name]=wrapper
 for plant:Dictionary in config.get("plants",[]):
  var at:Vector3
  if plant.has("root"):at=ShipFrame.gltf_from_structure(plant.root)
  else:
   var wrapper:Node3D=result.placements.get(plant.placement)
   var anchors:=_named(wrapper,plant.anchor) if wrapper!=null else []
   if anchors.size()!=1:result.errors.append("%s: missing placement/foliage anchor"%plant.name);continue
   at=wrapper.transform*_relative(wrapper,anchors[0]).origin
  var h:=float(plant.height)*ShipDressing.CARD_MARGIN
  var box:=AABB(at+Vector3(-h*.5,-h*.03,-h*.5),Vector3(h,h,h))
  if not bounds.encloses(box):result.errors.append("%s: plant crown leaves pilot bounds"%plant.name);continue
  var texture:=StapledonStyle.card_texture(plant.kind)
  if texture==null:result.errors.append("%s: missing painted foliage"%plant.name);continue
  var builder:=ShipDressing.new()
  var card:=builder._card(plant.name,texture,h);var shadow:=builder._card(plant.name+"_shadow",texture,h);builder.free()
  var tint:=_tint(plant.get("tint",[1,1,1]))
  var facing:=Basis(Vector3.UP,deg_to_rad(float(plant.get("yaw_deg",0))))
  card.transform=Transform3D(facing,at);shadow.transform=Transform3D(facing.rotated(Vector3.UP,PI*.5),at)
  (card.material_override as ShaderMaterial).set_shader_parameter("albedo",tint)
  card.set_instance_shader_parameter("cloud_center",at+Vector3.UP*h*.55);card.set_instance_shader_parameter("cloud_radii",Vector3.ONE*h*.5)
  card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  shadow.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
  (shadow.material_override as ShaderMaterial).set_shader_parameter("clamp_deg",0.)
  pilot.add_child(card);pilot.add_child(shadow);result.plants.append(card);result.plant_shadows.append(shadow)
 for spec:Dictionary in config.get("practicals",[]):
  var at:=ShipFrame.gltf_from_structure(spec.ship_m)
  if not bounds.has_point(at):result.errors.append("%s: practical leaves pilot bounds"%spec.name);continue
  var lamp:=OmniLight3D.new();lamp.name=spec.name;lamp.position=at;lamp.omni_range=float(spec.range_m);lamp.light_energy=float(spec.energy)
  lamp.light_color=_tint(spec.get("tint",[1,.8,.58]));lamp.shadow_enabled=false;pilot.add_child(lamp);result.practicals.append(lamp)
 catalog.free()
 if not result.errors.is_empty():
  pilot.free();result.placements={};result.colliders=[];result.plants=[];result.plant_shadows=[];result.practicals=[];return result
 host.add_child(pilot);result.node=pilot;result.ok=true;return result

static func validate(value:Variant)->PackedStringArray:
 var errors:=PackedStringArray()
 if not value is Dictionary:return PackedStringArray(["pilot config must be an object"])
 if not value.get("source_glb") is String or not str(value.source_glb).ends_with(".glb") or str(value.source_glb).contains("..") or (str(value.source_glb).contains("://") and not str(value.source_glb).begins_with("res://")):
  errors.append("source_glb must be a local GLB path")
 var b:Variant=value.get("bounds")
 if not b is Dictionary or not _vec(b.get("min")) or not _vec(b.get("max")):
  errors.append("bounds must contain finite min/max ship metre triples")
 else:
  for i in 3:
   if float(b.min[i])>=float(b.max[i]) or absf(float(b.min[i]))>1000 or absf(float(b.max[i]))>1000:errors.append("bounds must be ordered and bounded ship metres");break
 var names:Array=[]
 for section:String in ["placements","plants","practicals"]:
  var rows:Variant=value.get(section,[])
  if not rows is Array or rows.size()>MAX_ROWS or (section=="practicals" and rows.size()>8):errors.append(section+" must be a bounded list");continue
  if section=="placements" and rows.is_empty():errors.append("placements must not be empty")
  for row:Variant in rows:
   if not row is Dictionary:errors.append(section+" entries must be objects");continue
   if not _id(row.get("name")) or names.has(row.get("name")):errors.append(section+" names must be unique simple identifiers")
   names.append(row.get("name"))
   if section=="placements":
    if not _id(row.get("prop")) or not _vec(row.get("ship_m")) or not _num(row.get("yaw_deg")):errors.append("placement requires prop, finite ship_m and yaw_deg")
    var solids:Variant=row.get("solid_meshes")
    if not solids is Array:errors.append("placement requires deliberate solid_meshes list")
    else:
     var used:Array=[]
     for solid:Variant in solids:
      if not _id(solid) or used.has(solid):errors.append("solid_meshes must be unique exact mesh names")
      used.append(solid)
   elif section=="plants":
    if not row.get("kind") in KINDS or not _num(row.get("height")) or float(row.get("height",0))<.2 or float(row.get("height",0))>6:errors.append("plant requires known kind and height .2..6 metres")
    if row.has("root"):
     if not _vec(row.root) or row.has("placement") or row.has("anchor"):errors.append("plant root must be finite ship metres, separate from an anchor")
    elif not _id(row.get("placement")) or not _id(row.get("anchor")) or not str(row.get("anchor","")).begins_with("FOLIAGE_"):errors.append("plant requires root or a placement/FOLIAGE_ anchor")
    if row.has("yaw_deg") and not _num(row.yaw_deg):errors.append("plant yaw_deg must be finite")
   else:
    if not _vec(row.get("ship_m")) or not _num(row.get("range_m")) or not _num(row.get("energy")):errors.append("practical requires finite ship_m/range_m/energy")
    elif float(row.range_m)<=0 or float(row.range_m)>8 or float(row.energy)<0 or float(row.energy)>2:errors.append("practical range<=8m and energy<=2 required")
   if row.has("tint") and (not _vec(row.tint) or (row.tint as Array).any(func(c:Variant)->bool:return float(c)<0 or float(c)>1)):errors.append("tint must be an RGB triple in 0..1")
 return errors

static func _num(value:Variant)->bool:return (value is int or value is float) and is_finite(float(value))
static func _vec(value:Variant)->bool:return value is Array and value.size()==3 and value.all(func(c:Variant)->bool:return _num(c))
static func _id(value:Variant)->bool:
 if not value is String or value.is_empty():return false
 for c:String in value:
  if not c in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_":return false
 return true
static func _tint(value:Array)->Color:return Color(float(value[0]),float(value[1]),float(value[2]))
static func _named(root:Node,name:String)->Array:
 var out:Array=[];var stack:Array=[root]
 while not stack.is_empty():
  var node:Node=stack.pop_back();stack.append_array(node.get_children())
  if str(node.name)==name:out.append(node)
 return out
static func _relative(root:Node3D,node:Node)->Transform3D:
 var transform:=Transform3D.IDENTITY;var at:Node=node
 while at!=root:
  if at is Node3D:transform=(at as Node3D).transform*transform
  at=at.get_parent()
 return transform
static func _mesh_bounds(prop:Node3D)->AABB:
 var first:=true;var box:=AABB()
 for mesh:MeshInstance3D in StapledonStyle.meshes(prop):
  var next:=prop.transform*_relative(prop,mesh)*mesh.get_aabb()
  box=next if first else box.merge(next);first=false
 return box
static func _bounds(spec:Dictionary)->AABB:
 var box:=AABB(ShipFrame.gltf_from_structure(spec.min),Vector3.ZERO)
 for x in 2:
  for y in 2:
   for z in 2:box=box.expand(ShipFrame.gltf_from_structure([spec.max[0] if x else spec.min[0],spec.max[1] if y else spec.min[1],spec.max[2] if z else spec.min[2]]))
 return box
static func _opaque(mesh:MeshInstance3D)->bool:
 for i in mesh.mesh.get_surface_count():
  var material:=StapledonStyle._surface(mesh,i)
  if StapledonStyle.excluded(mesh,material) or StapledonStyle.is_card(material):return false
 return true
static func _safe_tree(prop:Node3D)->bool:
 var stack:Array=[prop]
 while not stack.is_empty():
  var node:Node=stack.pop_back();stack.append_array(node.get_children())
  if node.get_script()!=null or node is CollisionObject3D or node is Light3D or node is Camera3D or node is AnimationPlayer:return false
  if node is Node3D:
   var transform:Transform3D=node.transform
   if not transform.origin.is_finite() or not transform.basis.is_finite() or absf(transform.basis.determinant())<1e-9:return false
  if node is MeshInstance3D and node.mesh!=null:
   var box:AABB=node.mesh.get_aabb()
   if not box.position.is_finite() or not box.size.is_finite():return false
   var faces:PackedVector3Array=node.mesh.get_faces()
   if faces.is_empty() or faces.size()>300000:return false
   for vertex:Vector3 in faces:
    if not vertex.is_finite():return false
 return true
