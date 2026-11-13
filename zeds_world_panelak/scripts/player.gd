extends CharacterBody3D
## Hráč: stamina, kulhání, zranění, baterka, sekera, ruka na interakci.

const CHUZE := 2.6
const BEH := 4.6
const KULHA_RYCHLOST := 1.5
const MYS_CITLIVOST := 0.0032
const DOSAH_RUKY := 2.6

var zvuk: Node
var hlava: Node3D
var kamera: Camera3D
var baterka: SpotLight3D
var sekera_model: Node3D

var zdravi := 100.0
var stamina := 100.0
var kulha := false
var muze_hybat := true
var baterka_povolena := false
var baterka_sviti := false
var hluk := 0.0                  # 0..1, kolik ho je právě slyšet
var shake := 0.0

var _krok_cas := 0.0
var _look := Vector2.ZERO        # z dotykového ovládání
var _pohyb := Vector2.ZERO       # z virtuální páčky
var _sek_cooldown := 0.0
var cil_interakce: Node = null
var cil_popis := ""

signal zmena_stavu

func _ready() -> void:
	add_to_group("hrac")
	var kap := CapsuleShape3D.new()
	kap.radius = 0.32
	kap.height = 1.75
	var cs := CollisionShape3D.new()
	cs.shape = kap
	cs.position.y = 0.88
	add_child(cs)

	hlava = Node3D.new()
	hlava.position.y = 1.62
	add_child(hlava)
	kamera = Camera3D.new()
	kamera.fov = 74.0
	kamera.far = 1200.0
	kamera.near = 0.05
	hlava.add_child(kamera)

	baterka = SpotLight3D.new()
	baterka.light_energy = 3.2
	baterka.light_color = Color(1.0, 0.94, 0.80)
	baterka.spot_range = 26.0
	baterka.spot_angle = 26.0
	baterka.spot_attenuation = 1.4
	baterka.shadow_enabled = false       # kvůli výkonu na mobilu
	baterka.visible = false
	kamera.add_child(baterka)

	var props := load("res://assets/models/props_zed.glb") as PackedScene
	if props:
		var inst := props.instantiate()
		for n in inst.find_children("sekera*", "", true, false):
			sekera_model = n.duplicate()
			break
		inst.queue_free()
	if sekera_model:
		# sekera v ruce: malá a vpravo dole, ať nezakrývá výhled
		sekera_model.position = Vector3(0.30, -0.46, -0.52)
		sekera_model.rotation_degrees = Vector3(-24, 152, 16)
		sekera_model.scale = Vector3.ONE * 0.42
		kamera.add_child(sekera_model)

# ---------------------------------------------------------------- vstup
func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_otoc(-e.relative.x * MYS_CITLIVOST, -e.relative.y * MYS_CITLIVOST)
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_L:
			prepni_baterku()
		elif e.keycode == KEY_E:
			pouzij_ruku()
		elif e.keycode == KEY_F:
			seknout()
		elif e.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _otoc(dx: float, dy: float) -> void:
	rotate_y(dx)
	hlava.rotate_x(dy)
	hlava.rotation.x = clampf(hlava.rotation.x, -1.4, 1.4)

func nastav_look(d: Vector2) -> void:
	_look = d

func nastav_pohyb(d: Vector2) -> void:
	_pohyb = d

# ---------------------------------------------------------------- běh hry
func _physics_process(delta: float) -> void:
	_sek_cooldown = maxf(0.0, _sek_cooldown - delta)
	if _look.length() > 0.001:
		_otoc(-_look.x * 0.004, -_look.y * 0.004)
		_look = Vector2.ZERO

	if not is_on_floor():
		velocity.y -= 9.8 * delta
	else:
		velocity.y = 0.0

	var smer := Vector2.ZERO
	if muze_hybat:
		smer.x = Input.get_axis("move_left", "move_right") + _pohyb.x
		smer.y = Input.get_axis("move_forward", "move_back") - _pohyb.y
		smer = smer.limit_length(1.0)

	var chce_bezet := Input.is_action_pressed("run") and not kulha and stamina > 2.0
	var rychlost := CHUZE
	if kulha:
		rychlost = KULHA_RYCHLOST
	elif chce_bezet and smer.length() > 0.1:
		rychlost = BEH

	var zaklad := (transform.basis * Vector3(smer.x, 0, smer.y)).normalized()
	velocity.x = zaklad.x * rychlost
	velocity.z = zaklad.z * rychlost

	# stamina
	if rychlost == BEH and smer.length() > 0.1:
		stamina = maxf(0.0, stamina - 18.0 * delta)
	else:
		var doplnuje := 9.0 if smer.length() < 0.1 else 3.5
		stamina = minf(100.0, stamina + doplnuje * delta)

	# hluk — podle rychlosti; Zéd podle něj hledá
	var cil_hluk := 0.0
	if smer.length() > 0.1:
		cil_hluk = 0.35 if rychlost == CHUZE else 1.0
		if kulha:
			cil_hluk = 0.5
	hluk = lerpf(hluk, cil_hluk, delta * 3.0)

	if shake > 0.0:
		hlava.position.y = 1.62 + sin(Time.get_ticks_msec() * 0.05) * 0.02 * shake
		shake = maxf(0.0, shake - delta * 0.5)

	move_and_slide()
	_kroky(delta, smer.length() > 0.1, rychlost)
	_zamer()
	zmena_stavu.emit()

func _zamer() -> void:
	## Co je právě pod rukou. HUD to vypisuje, ať hráč neťuká naslepo.
	cil_interakce = null
	cil_popis = ""
	var h := _raycast_pred_sebou(DOSAH_RUKY)
	if h.is_empty():
		return
	var c = h.collider
	while c != null:
		if c.has_method("pouzij"):
			cil_interakce = c
			cil_popis = c.popis() if c.has_method("popis") else "Použít"
			return
		c = c.get_parent()

func _kroky(delta: float, jde: bool, rychlost: float) -> void:
	if not jde or not is_on_floor():
		return
	_krok_cas -= delta * (rychlost / CHUZE)
	if _krok_cas > 0.0:
		return
	_krok_cas = 0.62 if not kulha else 0.95
	var sada: Array = zvuk.KROKY_HRAC
	if kulha:
		sada = zvuk.KROKY_KULHA
	elif global_position.y < 0.0:
		sada = zvuk.KROKY_SUT
	zvuk.hraj_3d(zvuk.nahodny(sada), self, -6.0 if rychlost == CHUZE else -1.0, 30.0)

# ---------------------------------------------------------------- akce
func prepni_baterku() -> void:
	if not baterka_povolena:
		return
	baterka_sviti = not baterka_sviti
	baterka.visible = baterka_sviti

func _raycast_pred_sebou(dosah: float) -> Dictionary:
	var od := kamera.global_position
	var kam := od - kamera.global_transform.basis.z * dosah
	var par := PhysicsRayQueryParameters3D.create(od, kam)
	par.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(par)

func pouzij_ruku() -> void:
	## Tlačítko s rukou: dveře, výtah, žaluzie, předměty.
	var h := _raycast_pred_sebou(DOSAH_RUKY)
	if h.is_empty():
		return
	var c = h.collider
	while c != null:
		if c.has_method("pouzij"):
			c.pouzij(self)
			return
		c = c.get_parent()

func seknout() -> void:
	if _sek_cooldown > 0.0 or stamina < 8.0:
		return
	_sek_cooldown = 0.75
	stamina = maxf(0.0, stamina - 8.0)
	hluk = 1.0
	if sekera_model:
		var tw := create_tween()
		tw.tween_property(sekera_model, "rotation_degrees:x", -72.0, 0.08)
		tw.tween_property(sekera_model, "rotation_degrees:x", -24.0, 0.3)
	zvuk.hraj_3d(zvuk.nahodny(zvuk.SEKERA), self, -3.0, 40.0)
	var h := _raycast_pred_sebou(2.2)
	if not h.is_empty():
		var c = h.collider
		while c != null:
			if c.has_method("zasah_sekerou"):
				c.zasah_sekerou(34.0)
				return
			c = c.get_parent()

func zranit(kolik: float, zpusobi_kulhani := false) -> void:
	zdravi = maxf(0.0, zdravi - kolik)
	zvuk.hraj_3d("hrac_bolest_01" if kolik < 25.0 else "hrac_bolest_02", self, -2.0, 20.0)
	if zpusobi_kulhani or kolik >= 25.0:
		kulha = true
	zmena_stavu.emit()

func osetrit() -> void:
	kulha = false
	zdravi = minf(100.0, zdravi + 25.0)
	zmena_stavu.emit()
