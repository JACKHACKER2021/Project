extends Node3D
## Stav domu, šíření ohně a postupné hroucení.
## Dům se nerozpadne naráz: hoří, kus po kusu ztrácí oporu a padá,
## až se nakonec složí celý.

const PRAH_ODPOCTU := 55.0
const ZAKLADNI_CAS := 120.0
const MAX_PADAJICICH := 34          # kolik RigidBody3D smí běžet najednou
const KUSU_Z_DILU := 3              # na kolik kusů se rozletí jeden díl
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
	_prach(kde, 1.0)
	_prach(Vector3(kde.x, 2.0, 0.0), 1.4)        # prach se vyvalí i dole u paty
	_otres(kde, 1.0)
	_naklonuj("trosky_%d" % (1 + randi() % 5), Vector3(kde.x, 0.5, randf_range(-8, 8)))
	_naklonuj("trosky_%d" % (1 + randi() % 5), Vector3(kde.x * 0.4, 0.5, randf_range(-14, 14)))
	_ohen_na(klic, 1.0)
	_naklonuj("kour_%d" % (2 + randi() % 3), kde + Vector3(0, 14, 0))

func _rozpadni(n: MeshInstance3D) -> void:
	## Díl se neschová — roztrhne se na několik panelů, které padají dolů.
	n.visible = false
	var aabb := n.get_aabb()
	if aabb.get_volume() < 0.5:
		return
	var stred := n.global_position + aabb.get_center()
	for i in KUSU_Z_DILU:
		if padajici.size() >= MAX_PADAJICICH:
			return
		_panel(stred, aabb.size)

func _panel(kde: Vector3, vel: Vector3) -> void:
	## Jeden kus betonového panelu. Vlastní geometrie, ať to nejsou
	## celé patra lítající vzduchem.
	var rb := RigidBody3D.new()
	var s := Vector3(
		clampf(vel.x * randf_range(0.12, 0.3), 1.0, 9.0),
		clampf(vel.y * randf_range(0.08, 0.2), 0.6, 5.0),
		clampf(vel.z * randf_range(0.15, 0.4), 0.8, 7.0))
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = s
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.60, 0.56).lerp(Color(0.3, 0.28, 0.26), randf())
	m.roughness = 0.95
	mi.material_override = m
	rb.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = s
	cs.shape = bs
	rb.add_child(cs)
	rb.mass = clampf(s.x * s.y * s.z * 2.4, 40.0, 3000.0)
	add_child(rb)
	rb.global_position = kde + Vector3(randf_range(-12, 12), randf_range(-16, 16),
		randf_range(-8, 8))
	rb.angular_velocity = Vector3(randf_range(-1.4, 1.4), randf_range(-1.4, 1.4),
		randf_range(-1.4, 1.4))
	rb.linear_velocity = Vector3(randf_range(-9, 9), randf_range(-4, 1),
		randf_range(-9, 9))
	padajici.append(rb)
	get_tree().create_timer(randf_range(10.0, 18.0)).timeout.connect(
		func():
			padajici.erase(rb)
			if is_instance_valid(rb):
				rb.queue_free())

func _prach(kde: Vector3, sila: float) -> void:
	## Mrak prachu po zřícení. Zvedne se a rozplyne.
	for i in int(5 + 7 * sila):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var v := randf_range(6.0, 16.0) * sila
		bm.size = Vector3(v, v * 0.7, v)
		mi.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.74, 0.70, 0.64, 0.5)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = m
		add_child(mi)
		mi.global_position = kde + Vector3(randf_range(-14, 14), randf_range(-6, 6),
			randf_range(-10, 10))
		var tw := create_tween()
		tw.tween_property(mi, "global_position",
			mi.global_position + Vector3(randf_range(-18, 18), randf_range(8, 26),
			randf_range(-18, 18)), randf_range(3.5, 7.0))
		tw.parallel().tween_property(mi, "scale", Vector3.ONE * randf_range(2.0, 3.5),
			5.0)
		tw.parallel().tween_property(m, "albedo_color:a", 0.0, randf_range(4.0, 7.0))
		tw.tween_callback(mi.queue_free)

func _otres(kde: Vector3, sila: float) -> void:
	if hrac == null:
		return
	var d := hrac.global_position.distance_to(kde)
	hrac.shake = maxf(hrac.shake, clampf(sila * (1.0 - d / 320.0), 0.0, 1.0))

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
	# hořící kusy dostanou další plameny, jak oheň sílí
	for k in kusy:
		if kusy[k]["stoji"] and kusy[k]["hori"] > 0.3 and randf() < 0.08:
			_ohen_na(k, kusy[k]["hori"])

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
				zvuk.hraj_3d("zed_hod_lodi_02", self, -2.0, 900.0, 150.0)
			await get_tree().create_timer(0.18).timeout
		_prach(Vector3(0, pas * 50.0, 0), 1.8)
		_otres(Vector3(0, pas * 50.0, 0), 1.0)
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
