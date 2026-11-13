extends Node3D
## Staví otevíratelné dveře bytů pro podlaží kolem hráče.
## V modelu jsou jen zárubně — křídla patří hře, aby šla otevřít.

const JMENA := ["Svoboda", "Novák", "Dvořák", "Černý", "Procházka", "Kučera",
	"Veselý", "Horák", "Němec", "Marek", "Pospíšil", "Hájek", "Jelínek",
	"Král", "Růžička", "Beneš", "Fiala", "Sedláček", "Doležal", "Zeman"]

var zvuk: Node
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
	for p in [f - 1, f, f + 1]:
		if not aktivni.has(p) and p >= 0 and p < ZWConfig.FLOORS:
			aktivni[p] = _postav(p)
	for p in aktivni.keys():
		if absi(p - f) > 2:
			aktivni[p].queue_free()
			aktivni.erase(p)

func _postav(f: int) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	var y := ZWConfig.floor_y(f)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7000 + f
	var i := 0
	for sz in [-1.0, 1.0]:
		for k in ZWConfig.APT_COUNT:
			var ax := ZWConfig.apt_x(k)
			if sz > 0.0 and ax > ZWConfig.JADRO_X0 and ax < ZWConfig.JADRO_X1:
				continue              # tady je výtah a schodiště
			var d: Node3D = preload("res://scripts/dvere.gd").new()
			d.zvuk = zvuk
			n.add_child(d)
			var cis := f * 16 + i + 1
			d.postav(Vector3(ZWConfig.apt_x(k), y, sz * (ZWConfig.COR_HZ + 0.06)),
				sz, JMENA[rng.randi() % JMENA.size()], cis)
			# pár bytů je zamčených — ty se dají otevřít sekerou
			d.zamceno = rng.randf() < 0.35
			i += 1
	return n
