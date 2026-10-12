extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	print(('ok ' if ok else 'FAIL ')+label)
	if not ok:failures+=1
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var avatar:=CaptainAvatar.new();root.add_child(avatar)
	check(avatar.load_dir('res://assets/characters/captain'),'painted avatar loads')
	var shadow:=avatar.install_grounded_shadow()
	check(avatar.anchor_local().length()<1e-6,'painted foot remains anchored at player position')
	check(avatar.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,'camera-facing billboard does not cast a detached plane shadow')
	check(shadow.get_child_count()==4 and avatar.install_grounded_shadow()==shadow,'one stable human shadow volume')
	var ground_count:=0
	for part:MeshInstance3D in shadow.get_children():
		var bottom:float=part.position.y+part.get_aabb().position.y
		if absf(bottom)<1e-6:ground_count+=1
		check(bottom>=-1e-6 and part.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,'shadow geometry stays above floor and invisible to camera')
	check(ground_count==2,'both legs meet actual floor')
	var occlusion=load('res://ui/star_occlusion.gd').new();occlusion.build(avatar)
	check(occlusion.meshes.is_empty(),'invisible shadow volumes do not block star inspection')
	avatar.queue_free();await process_frame
	print('shadow-contacts: %d failures'%failures);quit(1 if failures else 0)
