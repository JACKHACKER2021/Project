extends Node3D
## Výtah Transporta TOV 250 — převzatý z projektu godot_vytah.
## Jezdí přes všech 99 podlaží i do sklepa. A je zlobivý: má vlastní vůli.

const RYCHLOST := 1.6            # m/s, stará kladka
const PRODLEVA_DVERI := 1.6

var dum: Node3D
var hrac: CharacterBody3D
var zvuk: Node

var kabina: AnimatableBody3D
var kabina_mesh: Node3D
var patro := 12
var cil := 12
var jede := false
var dvere_otevrene := false
var motor: AudioStreamPlayer3D

# --- zlobivost
var naladovost := 0.35           # pravděpodobnost, že si udělá, co chce
var _ignoruje := 0               # kolikrát za sebou nepřijel
var _stoji_mezi_patry := false

signal stav(text: String)

func _ready() -> void:
	await get_tree().process_frame
	_najdi_kabinu()
	set_physics_process(true)

func _najdi_kabinu() -> void:
	if dum == null:
		return
	var uzly := dum.find_children("vytah_kabina*", "MeshInstance3D", true, false)
	if uzly.is_empty():
		return
	kabina = AnimatableBody3D.new()
	kabina.name = "Kabina"
	add_child(kabina)
	# geometrii kabiny přesuneme pod AnimatableBody, ať se s ní hýbe
	kabina_mesh = Node3D.new()
	kabina.add_child(kabina_mesh)
	for u in uzly:
		var kopie: Node = u.duplicate()
		kabina_mesh.add_child(kopie)
		u.visible = false
	# podlaha a stěny kabiny
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(ZWConfig.SH_X1 - ZWConfig.SH_X0 - 0.5, 0.2,
		ZWConfig.SH_Z1 - ZWConfig.SH_Z0 - 0.5)
	cs.shape = bs
	cs.position = Vector3((ZWConfig.SH_X0 + ZWConfig.SH_X1) * 0.5, 0.1,
		(ZWConfig.SH_Z0 + ZWConfig.SH_Z1) * 0.5)
	kabina.add_child(cs)
	kabina.position.y = ZWConfig.floor_y(patro)
	kabina_mesh.position.y = -ZWConfig.floor_y(patro) - 0.5

	motor = AudioStreamPlayer3D.new()
	motor.stream = zvuk.stream("zed_idle_motor")
	motor.volume_db = -14.0
	motor.max_distance = 80.0
	kabina.add_child(motor)

func v_kabine() -> bool:
	if kabina == null or hrac == null:
		return false
	var p := hrac.global_position
	return p.x > ZWConfig.SH_X0 and p.x < ZWConfig.SH_X1 \
		and p.z > ZWConfig.SH_Z0 and p.z < ZWConfig.SH_Z1 \
		and absf(p.y - kabina.position.y) < 2.4

# ---------------------------------------------------------------- ovládání
func privolat(z_patra: int) -> void:
	if jede:
		stav.emit("Výtah někde jede. Je ho slyšet šachtou.")
		return
	# tady se projeví povaha: někdy prostě nepřijede
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
	if kabina == null:
		return
	var skutecne := p
	if randf() < naladovost * 0.8:
		# jede si, kam chce — a ve sklepě táhne dolů
		if randf() < 0.45:
			skutecne = -ZWConfig.CELLARS
			stav.emit("Výtah tě veze dolů. Nemačkal jsi to.")
		else:
			skutecne = clampi(p + (randi() % 9) - 4, -ZWConfig.CELLARS, ZWConfig.FLOORS - 1)
			stav.emit("Rozsvítilo se jiné číslo, než jsi zmáčkl.")
	_jed(skutecne)

func _jed(p: int) -> void:
	cil = clampi(p, -ZWConfig.CELLARS, ZWConfig.FLOORS - 1)
	jede = true
	dvere_otevrene = false
	_stoji_mezi_patry = false
	if motor:
		motor.play()

# ---------------------------------------------------------------- pohyb
func _physics_process(delta: float) -> void:
	if kabina == null or not jede:
		return
	var ty := ZWConfig.floor_y(cil)
	kabina.position.y = move_toward(kabina.position.y, ty, RYCHLOST * delta)
	kabina_mesh.position.y = -kabina.position.y - 0.5

	# hráč v kabině se veze i se třesem
	if v_kabine():
		hrac.global_position.y = kabina.position.y + 0.15
		hrac.shake = 1.0

	# zlobivost za jízdy: občas se zastaví mezi patry
	if not _stoji_mezi_patry and randf() < 0.0012 and absf(kabina.position.y - ty) > 6.0:
		_stoji_mezi_patry = true
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
		dvere_otevrene = true
		stav.emit("%d. patro. Mříž zaskřípala." % patro)

func pouzij(_kdo: Node) -> void:
	if v_kabine():
		zvol_patro(ZWConfig.y_to_floor(hrac.global_position.y) + 1)
	else:
		privolat(ZWConfig.y_to_floor(hrac.global_position.y))

# ---------------------------------------------------------------- tlačítka
var _tlacitka := {}

func _process(_d: float) -> void:
	## Přivolávací tlačítko se staví jen u podlaží, kde hráč zrovna je.
	if hrac == null:
		return
	var f := ZWConfig.y_to_floor(hrac.global_position.y)
	for p in [f - 1, f, f + 1]:
		if not _tlacitka.has(p) and p >= -ZWConfig.CELLARS and p < ZWConfig.FLOORS:
			_tlacitka[p] = _postav_tlacitko(p)
	for p in _tlacitka.keys():
		if absi(p - f) > 2:
			_tlacitka[p].queue_free()
			_tlacitka.erase(p)
	# panel v kabině postavíme jednou
	if kabina and not kabina.has_meta("panel"):
		kabina.set_meta("panel", true)
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.3, 1.3, 0.3)
		cs.shape = bs
		sb.add_child(cs)
		sb.position = Vector3(ZWConfig.SH_X1 - 0.45, 1.3,
			(ZWConfig.SH_Z0 + ZWConfig.SH_Z1) * 0.5 - 1.6)
		sb.set_script(preload("res://scripts/elevator_button.gd"))
		sb.vytah = self
		sb.uvnitr = true
		kabina.add_child(sb)

func _postav_tlacitko(p: int) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(0.35, 0.5, 0.25)
	cs.shape = bs
	sb.add_child(cs)
	sb.position = Vector3(2.9, ZWConfig.floor_y(p) + 1.25, ZWConfig.SH_Z0 - 0.25)
	sb.set_script(preload("res://scripts/elevator_button.gd"))
	sb.vytah = self
	sb.patro = p
	sb.uvnitr = false
	n.add_child(sb)
	return n
