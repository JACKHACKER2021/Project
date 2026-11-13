extends Node3D
## Kolize se nedělají z modelu (400k trojúhelníků by mobil nedal),
## ale počítají se z rozměrů — a jen pro podlaží kolem hráče.

var dum: Node3D
var hrac: Node3D
var aktivni := {}            # patro -> Node3D s kolizemi
const DOSAH := 1             # kolik podlaží nad a pod hráčem držet

func _ready() -> void:
	set_physics_process(true)
	await get_tree().process_frame
	hrac = get_tree().get_first_node_in_group("hrac")

func _physics_process(_d: float) -> void:
	if hrac == null:
		return
	var f := ZWConfig.y_to_floor(hrac.global_position.y)
	for p in range(f - DOSAH, f + DOSAH + 1):
		if not aktivni.has(p):
			aktivni[p] = _postav_patro(p)
	for p in aktivni.keys():
		if absi(p - f) > DOSAH + 1:
			aktivni[p].queue_free()
			aktivni.erase(p)

func _box(rodic: Node3D, stred: Vector3, velikost: Vector3) -> void:
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = velikost
	cs.shape = bs
	sb.add_child(cs)
	sb.position = stred
	rodic.add_child(sb)

func _postav_patro(f: int) -> Node3D:
	var n := Node3D.new()
	n.name = "Kolize_%d" % f
	add_child(n)
	if f < -ZWConfig.CELLARS or f >= ZWConfig.FLOORS:
		return n
	var y := ZWConfig.floor_y(f)

	# podlaha a strop
	_box(n, Vector3(0, y - 0.12, 0), Vector3(ZWConfig.HX * 2, 0.24, ZWConfig.HZ * 2))
	_box(n, Vector3(0, y + 2.95, 0), Vector3(ZWConfig.HX * 2, 0.2, ZWConfig.HZ * 2))
	# obvodové stěny
	for sz in [-1.0, 1.0]:
		_box(n, Vector3(0, y + 1.5, sz * (ZWConfig.HZ - 0.15)),
			Vector3(ZWConfig.HX * 2, 3.0, ZWConfig.WALL))
	for sx in [-1.0, 1.0]:
		_box(n, Vector3(sx * (ZWConfig.HX - 0.15), y + 1.5, 0),
			Vector3(ZWConfig.WALL, 3.0, ZWConfig.HZ * 2))

	_schodiste(n, y)

	if f < 0:
		_sklep(n, f, y)
		return n

	# stěny chodby s otvory ve dveřích bytů; na severu navíc vstup do jádra
	for sz in [-1.0, 1.0]:
		var z: float = sz * ZWConfig.COR_HZ
		var hrany: Array[float] = [-ZWConfig.HX]
		for i in ZWConfig.APT_COUNT:
			var x := ZWConfig.apt_x(i)
			if sz > 0.0 and x > ZWConfig.JADRO_X0 and x < ZWConfig.JADRO_X1:
				continue
			hrany.append(x - 0.6)
			hrany.append(x + 0.6)
		if sz > 0.0:
			hrany.append(ZWConfig.JADRO_X0)
			hrany.append(ZWConfig.JADRO_X1)
		hrany.append(ZWConfig.HX)
		hrany.sort()
		var i2 := 0
		while i2 < hrany.size() - 1:
			var a: float = hrany[i2]
			var b: float = hrany[i2 + 1]
			if b - a > 0.05:
				_box(n, Vector3((a + b) * 0.5, y + 1.5, z), Vector3(b - a, 3.0, 0.14))
			i2 += 2
	# příčky mezi byty (v jádru žádné)
	for sz in [-1.0, 1.0]:
		for i in ZWConfig.APT_COUNT:
			var px := ZWConfig.apt_x(i) + 4.3
			if sz > 0.0 and px > ZWConfig.JADRO_X0 - 4.3 and px < ZWConfig.JADRO_X1:
				continue
			_box(n, Vector3(px, y + 1.5, sz * (ZWConfig.HZ * 0.55)),
				Vector3(0.14, 3.0, ZWConfig.HZ * 0.9))
	# stěny jádra
	for xj in [ZWConfig.JADRO_X0, ZWConfig.JADRO_X1]:
		_box(n, Vector3(xj, y + 1.5, (ZWConfig.COR_HZ + ZWConfig.HZ) * 0.5),
			Vector3(0.18, 3.0, ZWConfig.HZ - ZWConfig.COR_HZ))
	_box(n, Vector3(ZWConfig.SH_X1 + 1.0, y + 1.5,
		(ZWConfig.SH_Z1 + ZWConfig.HZ) * 0.5),
		Vector3(0.18, 3.0, ZWConfig.HZ - ZWConfig.SH_Z1))
	# šachta výtahu — zadní a boční stěny; čelo řeší dveře výtahu
	var sx0 := ZWConfig.SH_X0 - 0.3
	var sx1 := ZWConfig.SH_X1 + 0.3
	_box(n, Vector3((sx0 + sx1) * 0.5, y + 1.5, ZWConfig.SH_Z1 + 0.2),
		Vector3(sx1 - sx0, 3.0, 0.2))
	for xx in [sx0, sx1]:
		_box(n, Vector3(xx, y + 1.5, (ZWConfig.SH_Z0 + ZWConfig.SH_Z1) * 0.5),
			Vector3(0.2, 3.0, ZWConfig.SH_Z1 - ZWConfig.SH_Z0))
	return n

func _schodiste(n: Node3D, y: float) -> void:
	## Schodiště je v modelu živé a rozsypané, ale chodit se po něm musí dát.
	## Kolize proto kopírují ramena, ne jednotlivé rozhozené stupně.
	var stup := 0.175
	var pod := 0.29
	var pocet := int(ZWConfig.FLOOR_H / stup)        # ~17 stupňů na podlaží
	var x := ZWConfig.ST_X0 + 0.6
	var z := ZWConfig.ST_Z0 + 1.3
	var smer := 1.0
	var i := 0
	while i < pocet:
		for k in 16:
			if i >= pocet:
				break
			_box(n, Vector3(x + smer * k * pod, y + i * stup + stup * 0.5, z),
				Vector3(pod, stup, 2.6))
			i += 1
		var yl := y + i * stup
		var xl := x + smer * 16.0 * pod
		_box(n, Vector3(xl + smer * 0.8, yl - 0.08, z), Vector3(1.8, 0.16, 5.6))
		x = xl + smer * 1.6
		z = ZWConfig.ST_Z0 + 1.3 if smer < 0.0 else ZWConfig.ST_Z1 - 2.0
		smer *= -1.0
		i += 2
	# zábradlí, ať se nedá spadnout do zrcadla schodiště
	_box(n, Vector3((ZWConfig.ST_X0 + ZWConfig.ST_X1) * 0.5, y + 1.6, ZWConfig.ST_Z1 + 0.1),
		Vector3(ZWConfig.ST_X1 - ZWConfig.ST_X0, 3.2, 0.2))

func _sklep(n: Node3D, f: int, y: float) -> void:
	## Sklep je bludiště — kolize se generují ze stejného semínka jako model,
	## takže sedí na drátěné kóje.
	var rng := RandomNumberGenerator.new()
	rng.seed = 500 + absi(f)
	var gx := 18
	var gz := 6
	var cw := (ZWConfig.HX * 2 - 2.0) / gx
	var cd := (ZWConfig.HZ * 2 - 2.0) / gz
	var x0 := -ZWConfig.HX + 1.0
	var z0 := -ZWConfig.HZ + 1.0
	for a in gx:
		for b in gz:
			var cx := x0 + (a + 0.5) * cw
			var cz := z0 + (b + 0.5) * cd
			if absf(cz) < 1.2:
				continue        # průchozí chodba ke schodišti a výtahu
			if a < gx - 1 and rng.randf() < 0.62:
				_box(n, Vector3(x0 + (a + 1) * cw, y + 1.4, cz), Vector3(0.2, 2.6, cd))
			if b < gz - 1 and rng.randf() < 0.62:
				_box(n, Vector3(cx, y + 1.4, z0 + (b + 1) * cd), Vector3(cw, 2.6, 0.2))
