extends Node3D
## Stav domu, šíření ohně a postupné hroucení.
## Dům se nerozpadne naráz: hoří, kus po kusu ztrácí oporu a padá,
## až se nakonec složí celý.

const PRAH_ODPOCTU := 55.0
const ZAKLADNI_CAS := 120.0
const MAX_PADAJICICH := 20          # kolik RigidBody3D smí běžet najednou
const PASU := 7                     # výškové pásy kus_00 .. kus_06
const SEGMENTU := 3

var dum: Node3D
var zvuk: Node
var hrac: CharacterBody3D
var zedove: Array[Node3D] = []

var kusy := {}        # "kus_BB_S" -> {uzly, vaha, stoji, hori, oslabeni, pas, seg}
var vaha_celkem := 0
var stav_procent := 100.0
var odpocet := -1.0
var zricen := false
var sesyp_bezi := false
var padajici: Array[RigidBody3D] = []
var zaluzie_stav := {}

signal zmena

func _ready() -> void:
	await get_tree().process_frame
	_rozdel_kusy()
	set_process(true)

func _rozdel_kusy() -> void:
	if dum == null:
		return
	for n in dum.find_children("kus_*", "MeshInstance3D", true, false):
		var klic: String = n.name.get_slice("__", 0)
		if not kusy.has(klic):
			var pas := klic.get_slice("_", 1).to_int()
			var seg := klic.get_slice("_", 2).to_int()
			var vaha := 3 if pas == 0 else (2 if pas == 1 else 1)
			kusy[klic] = {"uzly": [], "vaha": vaha, "stoji": true,
				"hori": 0.0, "oslabeni": 0.0, "pas": pas, "seg": seg}
			vaha_celkem += vaha
		kusy[klic]["uzly"].append(n)
	for n in dum.find_children("sklep_*", "MeshInstance3D", true, false):
		var klic2: String = n.name.get_slice("__", 0)
		if not kusy.has(klic2):
			kusy[klic2] = {"uzly": [], "vaha": 1, "stoji": true,
				"hori": 0.0, "oslabeni": 0.0, "pas": -1, "seg": 0}
			vaha_celkem += 1
		kusy[klic2]["uzly"].append(n)
	_prepocti()

func _prepocti() -> void:
	var stoji := 0
	for k in kusy:
		if kusy[k]["stoji"]:
			stoji += kusy[k]["vaha"]
	stav_procent = 100.0 * float(stoji) / maxf(1.0, float(vaha_celkem))
	if stav_procent < PRAH_ODPOCTU:
		var novy := ZAKLADNI_CAS * (stav_procent / PRAH_ODPOCTU)
		odpocet = novy if odpocet < 0.0 else minf(odpocet, novy)
	zmena.emit()

# ---------------------------------------------------------------- zásah
func stred_kusu(pas: int, seg: int) -> Vector3:
	return Vector3(-ZWConfig.HX + (seg + 0.5) * (ZWConfig.HX * 2.0 / SEGMENTU),
		pas * 50.0 + 25.0, 0.0)

func nahodny_cil_zasahu() -> Vector3:
	var stojici := []
	for k in kusy:
		if kusy[k]["stoji"] and kusy[k]["pas"] >= 0:
			stojici.append(k)
	if stojici.is_empty():
		return Vector3(0, 10, 0)
	var k2: String = stojici[randi() % stojici.size()]
	return stred_kusu(kusy[k2]["pas"], kusy[k2]["seg"])

func _klic(pas: int, seg: int) -> String:
	var k := "kus_%02d_%d" % [pas, seg]
	return k if kusy.has(k) else ""

func zasah_lodi(kde: Vector3) -> void:
	var pas := clampi(int(kde.y / 50.0), 0, PASU - 1)
	var seg := clampi(int((kde.x + ZWConfig.HX) / (ZWConfig.HX * 2.0 / SEGMENTU)), 0, SEGMENTU - 1)
	var klic := _klic(pas, seg)
	if klic == "":
		return
	zvuk.hraj_3d("zed_hod_lodi_02", self, 3.0, 900.0, 160.0)
	_zbor(klic)
	# v místě dopadu to chytne pořádně, okolní kusy jen olízne
	for s in [seg - 1, seg + 1]:
		var k2 := _klic(pas, s)
		if k2 != "":
			kusy[k2]["hori"] = maxf(kusy[k2]["hori"], 0.5)
	for p in [pas - 1, pas + 1]:
		var k3 := _klic(p, seg)
		if k3 != "":
			kusy[k3]["hori"] = maxf(kusy[k3]["hori"], 0.35)
	if hrac and hrac.global_position.distance_to(kde) < 30.0:
		hrac.zranit(40.0, true)
	_prepocti()

# ---------------------------------------------------------------- pád kusu
func _zbor(klic: String) -> void:
	if not kusy.has(klic) or not kusy[klic]["stoji"]:
		return
	kusy[klic]["stoji"] = false
	kusy[klic]["hori"] = 1.0
	var kde := stred_kusu(kusy[klic]["pas"], kusy[klic]["seg"])
	for n in kusy[klic]["uzly"]:
		_rozpadni(n)
	_naklonuj("trosky_%d" % (1 + randi() % 5), Vector3(kde.x, 0.5, randf_range(-8, 8)))
	_ohen_na(klic, 1.0)
	_naklonuj("kour_%d" % (2 + randi() % 3), kde + Vector3(0, 14, 0))

func _rozpadni(n: MeshInstance3D) -> void:
	## Z viditelného dílu uděláme padající těleso. Když už jich lítá moc,
	## díl jen zmizí — mobil by to jinak nedal.
	n.visible = false
	if padajici.size() >= MAX_PADAJICICH:
		return
	var aabb := n.get_aabb()
	if aabb.get_volume() < 0.5 or aabb.get_volume() > 40000.0:
		return
	var rb := RigidBody3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = n.mesh
	mi.position = -aabb.get_center()
	rb.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = aabb.size.clampf(0.4, 60.0)
	cs.shape = bs
	rb.add_child(cs)
	rb.mass = clampf(aabb.get_volume() * 0.4, 20.0, 4000.0)
	add_child(rb)
	rb.global_position = n.global_position + aabb.get_center()
	rb.angular_velocity = Vector3(randf_range(-0.6, 0.6), randf_range(-0.6, 0.6),
		randf_range(-0.6, 0.6))
	rb.linear_velocity = Vector3(randf_range(-4, 4), -2.0, randf_range(-4, 4))
	padajici.append(rb)
	# po dopadu kus za chvíli zmizí, ať se jich nehromadí tisíc
	get_tree().create_timer(randf_range(9.0, 16.0)).timeout.connect(
		func():
			padajici.erase(rb)
			if is_instance_valid(rb):
				rb.queue_free())

func _ohen_na(klic: String, sila: float) -> void:
	var kde := stred_kusu(kusy[klic]["pas"], kusy[klic]["seg"])
	var velikost := 2 if sila < 0.7 else (3 if sila < 0.95 else 4)
	_naklonuj("ohen_%d" % velikost, kde + Vector3(randf_range(-10, 10), 0, 0))

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
var _tik := 0.0

func _process(delta: float) -> void:
	_tik += delta
	if _tik > 0.5:
		_tik = 0.0
		_ohen_krok()
		_opora_krok()
	if odpocet > 0.0 and not zricen:
		odpocet -= delta
		if odpocet <= 0.0:
			_sesyp()
	zmena.emit()

func _ohen_krok() -> void:
	## Oheň sílí a přeskakuje na sousední kusy. Hořící kus postupně
	## ztrácí nosnost, až spadne sám od sebe.
	var nove := {}
	for k in kusy:
		var d: Dictionary = kusy[k]
		if d["hori"] <= 0.0:
			continue
		d["hori"] = minf(1.0, d["hori"] + 0.012)
		if d["stoji"]:
			d["oslabeni"] = minf(1.0, d["oslabeni"] + d["hori"] * 0.016)
		# oheň stoupá vzhůru rychleji než do stran
		if d["pas"] >= 0 and d["hori"] > 0.5:
			var nahoru := _klic(d["pas"] + 1, d["seg"])
			if nahoru != "" and randf() < 0.05:
				nove[nahoru] = maxf(nove.get(nahoru, 0.0), 0.3)
			for s in [d["seg"] - 1, d["seg"] + 1]:
				var k2 := _klic(d["pas"], s)
				if k2 != "" and randf() < 0.02:
					nove[k2] = maxf(nove.get(k2, 0.0), 0.25)
		if d["stoji"] and d["oslabeni"] >= 1.0:
			_zbor(k)
			_prepocti()
	for k in nove:
		if kusy[k]["hori"] <= 0.0:
			kusy[k]["hori"] = nove[k]
			_ohen_na(k, 0.4)
			zvuk.hraj_3d("predmet_ozije_02", self, -14.0, 400.0, 60.0)

func _opora_krok() -> void:
	## Co nemá pod sebou oporu, dřív nebo později spadne.
	for pas in range(1, PASU):
		for seg in SEGMENTU:
			var k := _klic(pas, seg)
			if k == "" or not kusy[k]["stoji"]:
				continue
			var pod := _klic(pas - 1, seg)
			if pod != "" and not kusy[pod]["stoji"]:
				kusy[k]["oslabeni"] = minf(1.0, kusy[k]["oslabeni"] + 0.09)
				if kusy[k]["oslabeni"] >= 1.0:
					_zbor(k)
					_prepocti()

func _sesyp() -> void:
	## Finální zřícení. Ne naráz — dům se skládá odspodu, pás po pásu.
	if sesyp_bezi:
		return
	sesyp_bezi = true
	zricen = true
	zvuk.hraj_2d("zed_hod_lodi", 2.0)
	for pas in PASU:
		for seg in SEGMENTU:
			var k := _klic(pas, seg)
			if k != "" and kusy[k]["stoji"]:
				_zbor(k)
				_prepocti()
			await get_tree().create_timer(0.22).timeout
	for i in ZWConfig.CELLARS:
		var ks := "sklep_%d" % (i + 1)
		if kusy.has(ks) and kusy[ks]["stoji"]:
			_zbor(ks)
		await get_tree().create_timer(0.4).timeout
	_prepocti()
	if hrac and hrac.global_position.length() < ZWConfig.HX + 25.0:
		hrac.zdravi = 0.0

# ---------------------------------------------------------------- žaluzie
func zaluzie_zatazene(patro: int) -> bool:
	return zaluzie_stav.get(patro, false)

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
