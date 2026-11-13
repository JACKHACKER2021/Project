extends Node3D
## Výtah Transporta TOV 250 — převzatý z projektu godot_vytah a zasazený
## do šachty paneláku. Šachetní dveře na pantu, shrnovací mříž, panel
## s čísly pater a STOP. A má vlastní vůli.

const RYCHLOST := 1.6
const SIRKA := 1.44          # kabina je malá, šachta kolem je velká klec
const DVERE_SIR := 0.82

var dum: Node3D
var hrac: CharacterBody3D
var zvuk: Node

var kabina: AnimatableBody3D
var mriz_uzel: Node3D
var mriz_tvar: CollisionShape3D
var mriz_otevrena := false
var motor: AudioStreamPlayer3D

var patro := 12
var cil := 12
var jede := false
var stoji_mezi := false
var dvere := {}              # patro -> {pivot, otevreno}
var ukazatele := {}          # patro -> Label3D
var naladovost := 0.33
var _ignoruje := 0

signal stav(text: String)

var SX := 0.0
var SZ := 0.0

func _ready() -> void:
	SX = (ZWConfig.SH_X0 + ZWConfig.SH_X1) * 0.5
	SZ = (ZWConfig.SH_Z0 + ZWConfig.SH_Z1) * 0.5
	await get_tree().process_frame
	_schovej_puvodni_kabinu()
	_postav_kabinu()
	set_process(true)
	set_physics_process(true)

# ---------------------------------------------------------------- stavba
func _mat(c: Color, svitici := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.75
	if svitici:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.4
	return m

func _dil(rodic: Node3D, vel: Vector3, pos: Vector3, m: Material, kolize: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = vel
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	rodic.add_child(mi)
	if kolize:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = vel
		cs.shape = bs
		cs.position = pos
		rodic.add_child(cs)
	return mi

func _popis(t: String, pos: Vector3, px: float, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.pixel_size = px
	l.modulate = c
	l.position = pos
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.double_sided = true
	return l

func _tlacitko(rodic: Node3D, pos: Vector3, popisek: String, akce: Array,
		rot: float, c := Color(0.15, 0.15, 0.15)) -> void:
	var sb := StaticBody3D.new()
	sb.position = pos
	sb.rotation.y = rot
	rodic.add_child(sb)
	_dil(sb, Vector3(0.1, 0.1, 0.03), Vector3.ZERO, _mat(c), true)
	var l := _popis(popisek, Vector3(0, 0, 0.02), 0.0032, Color(0.95, 0.95, 0.9))
	sb.add_child(l)
	sb.set_script(preload("res://scripts/vytah_prvek.gd"))
	sb.vytah = self
	sb.akce = akce

func _schovej_puvodni_kabinu() -> void:
	if dum == null:
		return
	for u in dum.find_children("vytah_kabina*", "MeshInstance3D", true, false):
		u.visible = false

func _postav_kabinu() -> void:
	kabina = AnimatableBody3D.new()
	kabina.sync_to_physics = true
	add_child(kabina)
	var mDrevo := _mat(Color(0.52, 0.34, 0.18))
	var mRam := _mat(Color(0.62, 0.33, 0.14))
	var mSit := _mat(Color(0.52, 0.29, 0.14))
	var h := SIRKA / 2.0
	_dil(kabina, Vector3(SIRKA, 0.1, SIRKA), Vector3(0, 0.05, 0), mDrevo, true)
	_dil(kabina, Vector3(0.04, 2.3, SIRKA), Vector3(-h, 1.25, 0), mRam, true)
	_dil(kabina, Vector3(0.04, 2.3, SIRKA), Vector3(h, 1.25, 0), mRam, true)
	_dil(kabina, Vector3(SIRKA, 2.3, 0.04), Vector3(0, 1.25, -h), mDrevo, true)
	_dil(kabina, Vector3(SIRKA, 0.05, SIRKA), Vector3(0, 2.42, 0), mRam, true)
	# lana nahoru
	for dx in [-0.08, 0.08]:
		_dil(kabina, Vector3(0.03, 40.0, 0.03), Vector3(dx, 22.45, 0),
			_mat(Color(0.2, 0.2, 0.2)), false)
	# shrnovací mříž
	mriz_uzel = Node3D.new()
	kabina.add_child(mriz_uzel)
	for i in 9:
		_dil(mriz_uzel, Vector3(0.035, 2.2, 0.035),
			Vector3(-h + 0.08 + i * 0.16, 1.2, h - 0.08), mSit, false)
	for j in 7:
		_dil(mriz_uzel, Vector3(SIRKA - 0.1, 0.03, 0.03),
			Vector3(0, 0.2 + j * 0.34, h - 0.08), mSit, false)
	var mcs := CollisionShape3D.new()
	var mbs := BoxShape3D.new()
	mbs.size = Vector3(SIRKA - 0.08, 2.2, 0.06)
	mcs.shape = mbs
	mcs.position = Vector3(0, 1.2, h - 0.08)
	kabina.add_child(mcs)
	mriz_tvar = mcs
	# mříž jako cíl pro ruku
	var ma := StaticBody3D.new()
	ma.position = Vector3(0, 1.2, h - 0.2)
	kabina.add_child(ma)
	_dil(ma, Vector3(SIRKA - 0.2, 1.4, 0.06), Vector3.ZERO, _mat(Color(0, 0, 0, 0)), true)
	ma.get_child(0).visible = false
	ma.set_script(preload("res://scripts/vytah_prvek.gd"))
	ma.vytah = self
	ma.akce = ["mriz"]
	# ovládací panel
	_dil(kabina, Vector3(0.02, 0.9, 0.22), Vector3(h - 0.03, 1.3, 0.3),
		_mat(Color(0.55, 0.53, 0.48)), false)
	for i in 6:
		var p := patro - 2 + i
		_tlacitko(kabina, Vector3(h - 0.045, 1.05 + i * 0.15, 0.3), str(p),
			["jed", p], -PI / 2)
	_tlacitko(kabina, Vector3(h - 0.045, 1.95, 0.3), "STOP", ["stop"], -PI / 2,
		Color(0.8, 0.1, 0.1))
	# žárovka
	var zar := OmniLight3D.new()
	zar.position = Vector3(0, 2.25, 0)
	zar.light_color = Color(1, 0.8, 0.5)
	zar.omni_range = 3.0
	zar.light_energy = 1.2
	kabina.add_child(zar)
	_dil(kabina, Vector3(0.08, 0.08, 0.08), Vector3(0, 2.36, 0),
		_mat(Color(1, 0.9, 0.6), true), false)

	motor = AudioStreamPlayer3D.new()
	motor.stream = zvuk.stream("zed_idle_motor")
	motor.volume_db = -12.0
	motor.unit_size = 6.0
	motor.max_distance = 90.0
	motor.position.y = 2.6
	kabina.add_child(motor)

	kabina.position = Vector3(SX, ZWConfig.floor_y(patro), SZ)

func _postav_patro(f: int) -> Node3D:
	## Šachetní dveře, ukazatel a přivolávač pro jedno podlaží.
	var n := Node3D.new()
	add_child(n)
	var y := ZWConfig.floor_y(f)
	var zc := ZWConfig.SH_Z0 - 0.1
	var mSit := _mat(Color(0.52, 0.29, 0.14))
	var mRam := _mat(Color(0.62, 0.33, 0.14))

	var pivot := Node3D.new()
	pivot.position = Vector3(SX - DVERE_SIR / 2.0, y, zc)
	n.add_child(pivot)
	var d := StaticBody3D.new()
	pivot.add_child(d)
	var p2 := DVERE_SIR / 2.0
	_dil(d, Vector3(DVERE_SIR - 0.02, 2.08, 0.03), Vector3(p2, 1.04, 0), mSit, true)
	_dil(d, Vector3(DVERE_SIR, 0.06, 0.05), Vector3(p2, 0.03, 0), mRam, false)
	_dil(d, Vector3(DVERE_SIR, 0.06, 0.05), Vector3(p2, 2.05, 0), mRam, false)
	_dil(d, Vector3(DVERE_SIR, 0.05, 0.05), Vector3(p2, 1.0, 0), mRam, false)
	_dil(d, Vector3(0.05, 2.1, 0.05), Vector3(0.025, 1.04, 0), mRam, false)
	_dil(d, Vector3(0.05, 2.1, 0.05), Vector3(DVERE_SIR - 0.025, 1.04, 0), mRam, false)
	_dil(d, Vector3(0.3, 0.1, 0.01), Vector3(p2 - 0.1, 1.12, -0.03),
		_mat(Color(0.95, 0.95, 0.9)), false)
	d.add_child(_popis("POZOR VÝTAH!\nNosnost 250 kg",
		Vector3(p2 - 0.1, 1.12, -0.045), 0.0012, Color(0.1, 0.1, 0.1)))
	_dil(d, Vector3(0.12, 0.03, 0.05), Vector3(DVERE_SIR - 0.1, 1.0, -0.05),
		_mat(Color(0.1, 0.1, 0.1)), false)
	d.add_child(_popis(str(f), Vector3(p2 + 0.22, 1.12, -0.045), 0.004,
		Color(0.1, 0.1, 0.1)))
	d.set_script(preload("res://scripts/vytah_prvek.gd"))
	d.vytah = self
	d.akce = ["dvere", f]
	dvere[f] = {"pivot": pivot, "otevreno": false}

	# ukazatel patra a přivolávač vedle dveří
	var ind := _popis(str(patro), Vector3(SX + 0.62, y + 1.52, zc - 0.03), 0.004,
		Color(1, 0.1, 0.1))
	n.add_child(ind)
	ukazatele[f] = ind
	n.add_child(_popis("NÁVOD\nk obsluze\nvýtahu",
		Vector3(SX + 0.62, y + 1.85, zc - 0.03), 0.0009, Color(0.1, 0.1, 0.1)))
	_tlacitko(n, Vector3(SX + 0.62, y + 1.3, zc - 0.04), "VOLAT", ["volat", f], PI)
	n.add_child(_popis(str(f), Vector3(SX - 1.6, y + 2.5, zc - 0.03), 0.01,
		Color(0.2, 0.2, 0.2)))
	return n

# ---------------------------------------------------------------- obsluha
func akce(a: Array) -> void:
	match a[0]:
		"dvere":
			var f: int = a[1]
			if not dvere.has(f):
				return
			if not at_floor(f) and not dvere[f]["otevreno"]:
				stav.emit("Dveře nejdou otevřít. Kabina tu není.")
				zvuk.hraj_3d("sekera_zasah_03", kabina, -12.0, 40.0)
				return
			var o: bool = not dvere[f]["otevreno"]
			dvere[f]["otevreno"] = o
			var tw := create_tween()
			tw.tween_property(dvere[f]["pivot"], "rotation:y", -1.5 if o else 0.0, 0.7)
			zvuk.hraj_3d("predmet_ozije_02", kabina, -10.0, 60.0)
			stav.emit("Těžké dveře s drátěným sklem zaskřípaly.")
		"mriz":
			mriz_otevrena = not mriz_otevrena
			mriz_tvar.disabled = mriz_otevrena
			var tw2 := create_tween()
			tw2.tween_property(mriz_uzel, "scale:x", 0.12 if mriz_otevrena else 1.0, 0.5)
			tw2.parallel().tween_property(mriz_uzel, "position:x",
				-SIRKA * 0.42 if mriz_otevrena else 0.0, 0.5)
			zvuk.hraj_3d("sekera_zasah_01", kabina, -8.0, 50.0)
			stav.emit("Mříž se shrnula." if mriz_otevrena else "Mříž je zavřená.")
		"volat":
			privolat(a[1])
		"jed":
			zvol_patro(a[1])
		"stop":
			if jede:
				jede = false
				stoji_mezi = true
				if motor:
					motor.stop()
				stav.emit("STOP. Kabina stojí mezi patry.")

func at_floor(f: int) -> bool:
	return kabina != null and absf(kabina.position.y - ZWConfig.floor_y(f)) < 0.2

func v_kabine() -> bool:
	if kabina == null or hrac == null:
		return false
	var p := hrac.global_position - kabina.global_position
	return absf(p.x) < SIRKA * 0.6 and absf(p.z) < SIRKA * 0.6 and p.y > -0.5 and p.y < 2.4

func privolat(z_patra: int) -> void:
	if jede:
		stav.emit("Výtah někde jede. Je ho slyšet šachtou.")
		return
	if randf() < naladovost:
		_ignoruje += 1
		if _ignoruje >= 3:
			_ignoruje = 0
			stav.emit("Výtah se konečně rozjel. Nějak neochotně.")
			_jed(z_patra)
		else:
			zvuk.hraj_3d("predmet_ozije_02", kabina, -10.0, 90.0)
			stav.emit("Zmáčkl jsi VOLAT. Nic. Šachtou je slyšet, jak stojí.")
		return
	_ignoruje = 0
	_jed(z_patra)

func zvol_patro(p: int) -> void:
	if not mriz_otevrena:
		pass
	var skutecne := p
	if randf() < naladovost * 0.8:
		if randf() < 0.45:
			skutecne = -ZWConfig.CELLARS
			stav.emit("Výtah tě veze dolů. Nemačkal jsi to.")
		else:
			skutecne = clampi(p + (randi() % 9) - 4, -ZWConfig.CELLARS, ZWConfig.FLOORS - 1)
			stav.emit("Rozsvítilo se jiné číslo, než jsi zmáčkl.")
	_jed(skutecne)

func _jed(p: int) -> void:
	# s otevřenými dveřmi nebo mříží se nerozjede
	for f in dvere:
		if dvere[f]["otevreno"]:
			stav.emit("Nejdřív zavři šachetní dveře.")
			return
	cil = clampi(p, -ZWConfig.CELLARS, ZWConfig.FLOORS - 1)
	jede = true
	stoji_mezi = false
	if motor:
		motor.play()

# ---------------------------------------------------------------- běh
var _patra_uzly := {}

func _process(_d: float) -> void:
	if hrac == null:
		return
	var f := ZWConfig.y_to_floor(hrac.global_position.y)
	for p in [f - 1, f, f + 1]:
		if not _patra_uzly.has(p) and p >= -ZWConfig.CELLARS and p < ZWConfig.FLOORS:
			_patra_uzly[p] = _postav_patro(p)
	for p in _patra_uzly.keys():
		if absi(p - f) > 2:
			_patra_uzly[p].queue_free()
			_patra_uzly.erase(p)
			dvere.erase(p)
			ukazatele.erase(p)
	var akt := str(ZWConfig.y_to_floor(kabina.position.y)) if kabina else "?"
	for p in ukazatele:
		ukazatele[p].text = akt

func _physics_process(delta: float) -> void:
	if kabina == null or not jede:
		return
	var ty := ZWConfig.floor_y(cil)
	kabina.position.y = move_toward(kabina.position.y, ty, RYCHLOST * delta)
	if v_kabine():
		hrac.global_position.y = kabina.position.y + 0.2
		hrac.shake = 0.6
	if not stoji_mezi and randf() < 0.0012 and absf(kabina.position.y - ty) > 6.0:
		stoji_mezi = true
		jede = false
		if motor:
			motor.stop()
		zvuk.hraj_3d("predmet_znicen_01", kabina, -6.0, 90.0)
		stav.emit("Kabina stojí mezi patry. Je ticho.")
		await get_tree().create_timer(randf_range(3.0, 9.0)).timeout
		jede = true
		if motor:
			motor.play()
		stav.emit("Zaskřípalo to a výtah se zase rozjel.")
		return
	if is_equal_approx(kabina.position.y, ty):
		jede = false
		patro = cil
		if motor:
			motor.stop()
		zvuk.hraj_3d("sekera_zasah_02", kabina, -10.0, 70.0)
		stav.emit("%d. patro. Prudké zabrzdění." % patro)

func pouzij(_kdo: Node) -> void:
	privolat(ZWConfig.y_to_floor(hrac.global_position.y))
