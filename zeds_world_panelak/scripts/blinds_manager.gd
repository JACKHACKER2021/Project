extends Node3D
## Drží žaluzie jen pro podlaží, kde hráč právě je.

var dum_stav: Node
var zvuk: Node
var hrac: CharacterBody3D
var aktivni := {}

func _process(_d: float) -> void:
	if hrac == null:
		return
	var f := ZWConfig.y_to_floor(hrac.global_position.y)
	for p in [f - 1, f, f + 1]:
		if p >= 0 and p < ZWConfig.FLOORS and not aktivni.has(p):
			aktivni[p] = _postav_patro(p)
	for p in aktivni.keys():
		if absi(p - f) > 2:
			aktivni[p].queue_free()
			aktivni.erase(p)

func _postav_patro(f: int) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	var y := ZWConfig.floor_y(f)
	# okna po obou dlouhých stranách, rozteč 5.1 m jako v modelu
	for sz in [-1.0, 1.0]:
		for k in 14:
			var x: float = -ZWConfig.HX + 3.6 + k * 5.1
			var z: float = sz * (ZWConfig.HZ - 0.25)
			var b: Node3D = preload("res://scripts/blinds.gd").new()
			b.dum_stav = dum_stav
			b.zvuk = zvuk
			b.patro = f
			n.add_child(b)
			b.postav(Vector3(x, y + 1.5, z), 3.0, 1.7)
	return n
