extends Node3D
## Zářivky na chodbě podlaží, kde hráč je. Po výpadku proudu zhasnou
## (world.gd je schová) a zbyde jen baterka.

var hrac: CharacterBody3D
var aktivni := {}

func _ready() -> void:
	await get_tree().process_frame
	if hrac == null:
		hrac = get_tree().get_first_node_in_group("hrac")

func _process(_d: float) -> void:
	if hrac == null:
		return
	var f := ZWConfig.y_to_floor(hrac.global_position.y)
	# jen podlaží, kde hráč je — víc světel mobil neutáhne
	for p in [f]:
		if not aktivni.has(p):
			aktivni[p] = _postav(p)
	for p in aktivni.keys():
		if absi(p - f) > 0:
			aktivni[p].queue_free()
			aktivni.erase(p)

func _postav(f: int) -> Node3D:
	var n := Node3D.new()
	n.add_to_group("svetla_domu")
	add_child(n)
	var y := ZWConfig.floor_y(f)
	for k in 5:
		var l := OmniLight3D.new()
		l.position = Vector3(-30.0 + k * 15.0, y + 2.7, 0.0)
		l.light_color = Color(1.0, 0.92, 0.74)
		l.light_energy = 2.6
		l.omni_range = 13.0
		l.shadow_enabled = false
		n.add_child(l)
	# jedno světlo i v bytě, kde hráč začíná
	var b := OmniLight3D.new()
	b.position = Vector3(ZWConfig.apt_x(3), y + 2.6, -7.0)
	b.light_color = Color(1.0, 0.90, 0.72)
	b.light_energy = 3.0
	b.omni_range = 9.0
	b.shadow_enabled = false
	n.add_child(b)
	return n
