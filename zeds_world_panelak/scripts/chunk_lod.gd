extends Node
## Vykresluje jen části domu kolem hráče. Dům je rozřezaný na pásy po 50 m,
## takže stačí držet ten, ve kterém hráč je, a sousední.

var dum: Node3D
var hrac: Node3D
var pasy := {}            # číslo pásu -> [MeshInstance3D]
var sklepy: Array[MeshInstance3D] = []
const DOSAH := 0          # jen pás, ve kterém hráč je

func _ready() -> void:
	await get_tree().process_frame
	if hrac == null:
		hrac = get_tree().get_first_node_in_group("hrac")
	if dum == null:
		return
	for n in dum.find_children("kus_*", "MeshInstance3D", true, false):
		var pas := n.name.get_slice("_", 1).to_int()
		if not pasy.has(pas):
			pasy[pas] = []
		pasy[pas].append(n)
	for n in dum.find_children("sklep_*", "MeshInstance3D", true, false):
		sklepy.append(n)

func _process(_d: float) -> void:
	if hrac == null:
		return
	var y := hrac.global_position.y
	var pas := int(max(y, 0.0) / 50.0)
	for p in pasy:
		var vid: bool = absi(p - pas) <= DOSAH
		for n in pasy[p]:
			if n.visible != vid:
				n.visible = vid
	var ve_sklepe := y < 1.0
	for n in sklepy:
		if n.visible != ve_sklepe:
			n.visible = ve_sklepe
