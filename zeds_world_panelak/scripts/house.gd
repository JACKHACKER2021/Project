extends Node3D
## Stav domu v procentech, destrukce po kusech, šíření ohně, odpočet do zřícení.

const MODEL := "res://assets/models/panelak_zed_destrukce_mobil.glb"
const PRAH_ODPOCTU := 55.0
const ZAKLADNI_CAS := 90.0

var dum: Node3D
var zvuk: Node
var hrac: CharacterBody3D
var zedove: Array[Node3D] = []

var kusy := {}                 # "kus_BB_S" -> {uzly:[], vaha:int, stoji:bool, hori:float}
var vaha_celkem := 0
var stav_procent := 100.0
var odpocet := -1.0            # -1 = ještě neběží
var zricen := false

var zaluzie_stav := {}         # patro -> bool (true = zatažené)
var _lod_scn: PackedScene

signal zmena

func _ready() -> void:
	await get_tree().process_frame
	_rozdel_kusy()
	_lod_scn = load(MODEL)
	set_process(true)

func _rozdel_kusy() -> void:
	if dum == null:
		return
	for n in dum.find_children("kus_*", "MeshInstance3D", true, false):
		var klic: String = n.name.get_slice("__", 0)
		if not kusy.has(klic):
			var pas := klic.get_slice("_", 1).to_int()
			var vaha := 3 if pas == 0 else (2 if pas == 1 else 1)
			kusy[klic] = {"uzly": [], "vaha": vaha, "stoji": true, "hori": 0.0}
			vaha_celkem += vaha
		kusy[klic]["uzly"].append(n)
	for n in dum.find_children("sklep_*", "MeshInstance3D", true, false):
		var klic2: String = n.name.get_slice("__", 0)
		if not kusy.has(klic2):
			kusy[klic2] = {"uzly": [], "vaha": 1, "stoji": true, "hori": 0.0}
			vaha_celkem += 1
		kusy[klic2]["uzly"].append(n)
	_prepocti()

func _prepocti() -> void:
	var stoji := 0
	for k in kusy:
		if kusy[k]["stoji"]:
			stoji += kusy[k]["vaha"]
	stav_procent = 100.0 * float(stoji) / maxf(1.0, float(vaha_celkem))
	if stav_procent < PRAH_ODPOCTU and odpocet < 0.0:
		odpocet = ZAKLADNI_CAS * (stav_procent / PRAH_ODPOCTU)
	elif odpocet > 0.0:
		# každý další zásah odpočet zkrátí
		odpocet = minf(odpocet, ZAKLADNI_CAS * (stav_procent / PRAH_ODPOCTU))
	zmena.emit()

# ---------------------------------------------------------------- zásah
func nahodny_cil_zasahu() -> Vector3:
	var stojici := []
	for k in kusy:
		if kusy[k]["stoji"] and k.begins_with("kus_"):
			stojici.append(k)
	if stojici.is_empty():
		return Vector3(0, 10, 0)
	var k2: String = stojici[randi() % stojici.size()]
	var pas := k2.get_slice("_", 1).to_int()
	var seg := k2.get_slice("_", 2).to_int()
	var y := pas * 50.0 + 25.0
	var x := -ZWConfig.HX + (seg + 0.5) * (ZWConfig.HX * 2.0 / 3.0)
	return Vector3(x, y, 0.0)

func zasah_lodi(kde: Vector3) -> void:
	var klic := _kus_na(kde)
	if klic == "":
		return
	_zbor(klic, kde)
	# okolní kusy chytnou
	for k in kusy:
		if kusy[k]["stoji"] and _sousedi(k, klic):
			kusy[k]["hori"] = maxf(kusy[k]["hori"], 0.4)
	_prepocti()

func _kus_na(p: Vector3) -> String:
	var pas := clampi(int(p.y / 50.0), 0, 6)
	var seg := clampi(int((p.x + ZWConfig.HX) / (ZWConfig.HX * 2.0 / 3.0)), 0, 2)
	var klic := "kus_%02d_%d" % [pas, seg]
	return klic if kusy.has(klic) else ""

func _sousedi(a: String, b: String) -> bool:
	if not a.begins_with("kus_") or not b.begins_with("kus_"):
		return false
	var pa := a.get_slice("_", 1).to_int()
	var sa := a.get_slice("_", 2).to_int()
	var pb := b.get_slice("_", 1).to_int()
	var sb := b.get_slice("_", 2).to_int()
	return absi(pa - pb) + absi(sa - sb) == 1

func _zbor(klic: String, kde: Vector3) -> void:
	if not kusy.has(klic) or not kusy[klic]["stoji"]:
		return
	kusy[klic]["stoji"] = false
	kusy[klic]["hori"] = 1.0
	for n in kusy[klic]["uzly"]:
		# padající kus: z MeshInstance uděláme RigidBody, ale jen pár najednou
		n.visible = false
	_naklonuj("trosky_%d" % (1 + randi() % 5), kde)
	_naklonuj("ohen_%d" % (2 + randi() % 3), kde)
	_naklonuj("kour_%d" % (2 + randi() % 3), kde + Vector3(0, 12, 0))
	zvuk.hraj_3d("zed_hod_lodi_02", self, 3.0, 900.0, 160.0)
	# kdo je blízko dopadu, schytá to
	if hrac and hrac.global_position.distance_to(kde) < 26.0:
		hrac.zranit(38.0, true)
	# když padne spodní pás, všechno nad ním se časem sesype
	if klic.begins_with("kus_00"):
		odpocet = minf(odpocet if odpocet > 0.0 else 999.0, 40.0)

func _naklonuj(jmeno: String, kde: Vector3) -> void:
	if dum == null:
		return
	for vzor in dum.find_children(jmeno + "*", "MeshInstance3D", true, false):
		var k: MeshInstance3D = vzor.duplicate()
		k.visible = true
		add_child(k)
		k.global_position = kde + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		k.rotation.y = randf() * TAU

# ---------------------------------------------------------------- čas
func _process(delta: float) -> void:
	# oheň ubírá dům sám od sebe
	var neco_hori := false
	for k in kusy:
		var h: float = kusy[k]["hori"]
		if h <= 0.0:
			continue
		neco_hori = true
		kusy[k]["hori"] = minf(1.0, h + delta * 0.02)
		if kusy[k]["stoji"] and kusy[k]["hori"] >= 1.0:
			_zbor(k, Vector3(0, k.get_slice("_", 1).to_int() * 50.0 + 25.0, 0))
			_prepocti()
			break
	if neco_hori and randf() < delta * 0.4:
		zvuk.hraj_2d("predmet_znicen_02", -16.0)

	if odpocet > 0.0:
		odpocet -= delta
		if odpocet <= 0.0 and not zricen:
			_zritit()
	zmena.emit()

func _zritit() -> void:
	zricen = true
	for k in kusy:
		kusy[k]["stoji"] = false
		for n in kusy[k]["uzly"]:
			n.visible = false
	zvuk.hraj_2d("zed_hod_lodi", 2.0)
	if hrac and hrac.global_position.length() < ZWConfig.HX + 20.0:
		hrac.zdravi = 0.0
	_prepocti()

# ---------------------------------------------------------------- žaluzie
func zaluzie_zatazene(patro: int) -> bool:
	return zaluzie_stav.get(patro, false)

func prepni_zaluzie(patro: int) -> bool:
	## Lamely v modelu jsou jeden mesh na celý dům; hratelné žaluzie
	## staví blinds_manager.gd. Tady se drží jen stav pro Zédův zrak.
	var novy := not zaluzie_zatazene(patro)
	zaluzie_stav[patro] = novy
	return novy

func vyrob_lod() -> Node3D:
	if dum == null:
		return null
	var vzor := dum.find_children("lod*", "MeshInstance3D", true, false)
	if vzor.is_empty():
		return null
	var l: Node3D = vzor[0].duplicate()
	l.visible = true
	add_child(l)
	return l
