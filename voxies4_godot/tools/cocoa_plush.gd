extends SceneTree
## Z dodaného GLB (plyšáci) vezme jen plyšovou Cocou, Bassieho odstraní a uloží models/cocoa_plush.glb
func _init() -> void:
	var src = load("res://models/plush_src.glb").instantiate()
	get_root().add_child(src)
	var keep = src.find_child("CocoaPlush", true, false)
	for n in src.find_children("*", "Node3D", true, false):
		if n.name.begins_with("BassiePlush"):
			n.get_parent().remove_child(n)
			n.free()
	var root = Node3D.new()
	root.name = "CocoaPlush"
	get_root().add_child(root)
	keep.get_parent().remove_child(keep)
	root.add_child(keep)
	keep.position = Vector3(0, 3.31, 0)   # spodek plyšáka na y = 0
	var doc = GLTFDocument.new()
	var st = GLTFState.new()
	doc.append_from_scene(root, st)
	print("PLUSH ", doc.write_to_filesystem(st, "res://models/cocoa_plush.glb"))
	quit()
