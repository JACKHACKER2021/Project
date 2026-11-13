extends Node3D
## Zéd Zédovský — beznohá a bezruká entita, 300 m.
## Chodí tak, že se překlápí z hrany na hranu. Lodě hází telekinezí.
## Pozná se z dálky podle zvuku: sekačka + zemětřesení.

enum Stav { HLIDKA, PRICHAZI, KOUKA_DO_OKEN, ZLOST, HAZI, ODCHAZI }

const RYCHLOST := 11.0           # m/s — na 300 m bytost je to pomalá chůze
const KROK_PERIODA := 1.45       # sedí na animaci Walk i na zvuk kroku
const DOSAH_HLUKU := 900.0
const VZDALENOST_U_DOMU := 210.0

var model: Node3D
var zvuk: Node
var hrac: CharacterBody3D
var dum_stav: Node

var stav: Stav = Stav.HLIDKA
var anim: AnimationPlayer
var motor: AudioStreamPlayer3D
var cil := Vector3.ZERO
var _krok_cas := 0.0
var _cas_ve_stavu := 0.0
var _okno_y := 60.0
var podezreni := 0.0             # 0..1, jak moc tuší, že tam někdo je
var _varoval := false

func _ready() -> void:
	add_to_group("zedove")
	await get_tree().process_frame
	_najdi_animaci()
	motor = AudioStreamPlayer3D.new()
	motor.stream = zvuk.stream("zed_idle_motor")
	motor.volume_db = -4.0
	motor.max_distance = DOSAH_HLUKU
	motor.unit_size = 160.0
	motor.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(motor)
	motor.play()
	_novy_cil()

func _najdi_animaci() -> void:
	if model == null:
		return
	for n in model.find_children("*", "AnimationPlayer", true, false):
		anim = n
		break
	if anim:
		anim.play("Walk")
		anim.speed_scale = 1.0

# ---------------------------------------------------------------- mozek
func _novy_cil() -> void:
	var uhel := randf() * TAU
	var r := randf_range(260.0, 900.0)
	cil = Vector3(cos(uhel) * r, 0.0, sin(uhel) * r)

func _process(delta: float) -> void:
	_cas_ve_stavu += delta
	match stav:
		Stav.HLIDKA:
			_jdi_k(cil, delta)
			if global_position.distance_to(cil) < 20.0:
				if randf() < 0.5:
					_prepni(Stav.PRICHAZI)
					cil = Vector3(randf_range(-90, 90), 0, randf_range(-90, 90))
				else:
					_novy_cil()
		Stav.PRICHAZI:
			_jdi_k(cil, delta)
			if _u_domu():
				_prepni(Stav.KOUKA_DO_OKEN)
		Stav.KOUKA_DO_OKEN:
			_kouka(delta)
		Stav.ZLOST:
			if _cas_ve_stavu > 4.0:
				_prepni(Stav.HAZI)
		Stav.HAZI:
			if _cas_ve_stavu > 7.5:
				_prepni(Stav.ODCHAZI)
				_novy_cil()
		Stav.ODCHAZI:
			_jdi_k(cil, delta)
			if global_position.distance_to(cil) < 30.0:
				_prepni(Stav.HLIDKA)

func _prepni(s: Stav) -> void:
	stav = s
	_cas_ve_stavu = 0.0
	if anim == null:
		return
	match s:
		Stav.HLIDKA, Stav.PRICHAZI, Stav.ODCHAZI:
			anim.play("Walk")
		Stav.KOUKA_DO_OKEN:
			anim.play("PeekWindow")
			_okno_y = randf_range(20.0, 200.0)
			zvuk.hraj_3d("zed_hlas_sepot", self, -4.0, DOSAH_HLUKU, 140.0)
		Stav.ZLOST:
			anim.play("Idle")
			zvuk.hraj_3d("zed_hlas_zlost", self, 0.0, DOSAH_HLUKU, 180.0)
		Stav.HAZI:
			anim.play("ThrowShip")
			_hod_lodi()

func _u_domu() -> bool:
	return Vector2(global_position.x, global_position.z).length() < VZDALENOST_U_DOMU

func _jdi_k(kam: Vector3, delta: float) -> void:
	var smer := (kam - global_position)
	smer.y = 0.0
	if smer.length() < 0.5:
		return
	smer = smer.normalized()
	global_position += smer * RYCHLOST * delta
	var cil_uhel := atan2(smer.x, smer.z)
	rotation.y = lerp_angle(rotation.y, cil_uhel, delta * 0.8)
	_kroky(delta)

func _kroky(delta: float) -> void:
	_krok_cas -= delta
	if _krok_cas > 0.0:
		return
	_krok_cas = KROK_PERIODA
	# zblízka plné kroky, z dálky tlumené
	var d := global_position.distance_to(hrac.global_position) if hrac else 500.0
	var jmeno: String = zvuk.nahodny(zvuk.KROKY_ZED) if d < 300.0 \
		else zvuk.nahodny(["zed_step_far_01", "zed_step_far_02"])
	zvuk.hraj_3d(jmeno, self, 2.0, DOSAH_HLUKU, 150.0)
	if hrac and d < 260.0:
		hrac.shake = maxf(hrac.shake, clampf(1.6 - d / 180.0, 0.0, 1.0))

# ---------------------------------------------------------------- okna
func _kouka(delta: float) -> void:
	## Prohlíží si okna. Když za sklem někdo je a žaluzie nejsou zatažené,
	## uvidí ho. Hluk ho navede k patru.
	if hrac == null:
		return
	var h := hrac.global_position
	_okno_y = lerpf(_okno_y, h.y, delta * (0.25 + hrac.hluk * 0.9))

	var vidi := false
	if absf(_okno_y - h.y) < 6.0:
		var u_okna: bool = absf(h.z) > ZWConfig.COR_HZ + 1.0 and absf(h.z) < ZWConfig.HZ
		var zataz: bool = dum_stav.zaluzie_zatazene(ZWConfig.y_to_floor(h.y))
		vidi = u_okna and not zataz and hrac.baterka_sviti or (u_okna and not zataz and hrac.hluk > 0.5)
	if vidi:
		podezreni = minf(1.0, podezreni + delta * 1.4)
	else:
		podezreni = maxf(0.0, podezreni - delta * 0.35)
		if podezreni < 0.2:
			_varoval = false

	if podezreni >= 0.6 and not _varoval:
		# půl vteřiny předem je slyšet, že si tě všiml — dá se stihnout schovat
		_varoval = true
		zvuk.hraj_3d("zed_hlas_nasel_jsem_te_dal", self, -1.0, DOSAH_HLUKU, 160.0)
	if podezreni >= 1.0:
		zvuk.hraj_3d(zvuk.nahodny(["zed_hlas_nasel_jsem_te",
			"zed_hlas_nasel_jsem_te_02"]), self, 2.0, DOSAH_HLUKU, 190.0)
		var h2 := get_tree().get_first_node_in_group("hud")
		if h2:
			h2.titulek("NAŠEL JSEM TĚ", "Schovej se. Hned.", 4.0)
		_prepni(Stav.ZLOST)
	elif _cas_ve_stavu > 26.0:
		_prepni(Stav.ODCHAZI)
		_novy_cil()

# ---------------------------------------------------------------- telekineze
func _hod_lodi() -> void:
	## Nemá ruce. Loď zvedne telekinezí: nadnese se, roztočí a vystřelí.
	var lod: Node3D = dum_stav.vyrob_lod()
	if lod == null:
		return
	var start := global_position + Vector3(0, 220.0, 0) \
		+ (global_position.normalized() * -60.0)
	lod.global_position = start
	zvuk.hraj_3d("zed_hod_lodi", self, 2.0, DOSAH_HLUKU, 170.0)

	# fáze 1: telekineze — loď se třese a stoupá
	var tw := create_tween()
	tw.tween_property(lod, "global_position", start + Vector3(0, 40, 0), 1.5) \
		.set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(lod, "rotation:y", lod.rotation.y + TAU, 1.5)
	await tw.finished

	# fáze 2: vystřelí na dům
	var zasah: Vector3 = dum_stav.nahodny_cil_zasahu()
	var tw2 := create_tween()
	tw2.tween_property(lod, "global_position", zasah, 1.9).set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN)
	tw2.parallel().tween_property(lod, "rotation:z", lod.rotation.z + 1.2, 1.9)
	await tw2.finished
	dum_stav.zasah_lodi(zasah)
	lod.queue_free()
