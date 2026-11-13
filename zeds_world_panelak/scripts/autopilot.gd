extends Node
## Automatický průchod hrou: projde byt, chodbu, výtah, schody, sklep,
## zkusí žaluzie, sekeru a nechá na barák spadnout loď.
## Každý snímek se ukládá, aby z toho šlo udělat video.

var svet: Node3D
var hrac: CharacterBody3D
var hud: CanvasLayer
var vytah: Node
var dum_stav: Node

var t := 0.0
var krok := 0
var nahravat := true
var n := 0
var cil: Vector3
var _ceka := 0.0
var _zprava := ""

const SLOZKA := "res://cap"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SLOZKA)
	await get_tree().process_frame
	hrac = get_tree().get_first_node_in_group("hrac")
	hud = get_tree().get_first_node_in_group("hud")

func _popis(s: String) -> void:
	if _zprava == s:
		return
	_zprava = s
	if hud:
		hud.titulek("", s, 6.0)
	print("[TEST %5.1f s] %s" % [t, s])

func _jdi(c: Vector3, delta: float, rychlost := 2.4) -> bool:
	## Posune hráče k cíli pomocí fyziky, takže to rovnou testuje kolize.
	var d: Vector3 = c - hrac.global_position
	d.y = 0.0
	if d.length() < 0.6:
		hrac.velocity.x = 0.0
		hrac.velocity.z = 0.0
		return true
	var smer := d.normalized()
	hrac.velocity.x = smer.x * rychlost
	hrac.velocity.z = smer.z * rychlost
	if not hrac.is_on_floor():
		hrac.velocity.y -= 9.8 * delta
	else:
		hrac.velocity.y = 0.0
	hrac.move_and_slide()
	# otoč se po směru chůze
	var cilu := atan2(-smer.x, -smer.z)
	hrac.rotation.y = lerp_angle(hrac.rotation.y, cilu, delta * 3.0)
	return false

func _kouknij_na(c: Vector3, delta: float) -> void:
	var d: Vector3 = c - hrac.hlava.global_position
	hrac.rotation.y = lerp_angle(hrac.rotation.y, atan2(-d.x, -d.z), delta * 3.0)
	var vodor := Vector2(d.x, d.z).length()
	hrac.hlava.rotation.x = lerp_angle(hrac.hlava.rotation.x, atan2(d.y, vodor),
		delta * 3.0)

func _process(delta: float) -> void:
	if hrac == null:
		return
	t += delta
	_scenar(delta)
	if nahravat:
		_snimek()

func _snimek() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_jpg("%s/f%05d.jpg" % [SLOZKA, n], 0.86)
	n += 1
	if t > 74.0:
		print("[TEST] hotovo, snimku: ", n)
		get_tree().quit()

func _scenar(delta: float) -> void:
	var y := hrac.global_position.y
	match krok:
		0:
			_popis("TEST 1/10 — probuzení v bytě, rozhlédnutí")
			_kouknij_na(Vector3(-6.2, y + 1.4, -11.5), delta)
			if t > 5.0:
				krok = 1
		1:
			_popis("TEST 2/10 — chůze bytem ke dveřím")
			if _jdi(Vector3(-6.2, y, -3.6), delta) or t > 16.0:
				krok = 2
		2:
			_popis("TEST 3/10 — ruka: otevřít dveře bytu")
			_kouknij_na(Vector3(-6.2, y + 1.1, -2.3), delta)
			_ceka += delta
			if _ceka > 1.4:
				hrac.pouzij_ruku()
				_popis("Dveře: " + (hrac.cil_popis if hrac.cil_popis != "" else "nic pod rukou"))
				_ceka = 0.0
				krok = 3
		3:
			if _jdi(Vector3(-6.2, y, 0.0), delta) or t > 26.0:
				krok = 4
		4:
			_popis("TEST 4/10 — chodba, navigace k výtahu")
			if _jdi(Vector3(0.0, y, 0.0), delta) or t > 34.0:
				krok = 5
		5:
			_popis("TEST 5/10 — přivolat výtah")
			_kouknij_na(Vector3(2.9, y + 1.2, 2.4), delta)
			_ceka += delta
			if _ceka > 1.5:
				hrac.pouzij_ruku()
				_ceka = 0.0
				krok = 6
		6:
			_popis("TEST 6/10 — šachetní dveře a kabina")
			if _jdi(Vector3(0.0, y, 1.6), delta) or t > 46.0:
				_kouknij_na(Vector3(0.0, y + 1.2, 3.2), delta)
				_ceka += delta
				if _ceka > 1.2:
					hrac.pouzij_ruku()
					_ceka = 0.0
					krok = 7
		7:
			_popis("TEST 7/10 — zpět na chodbu a ke schodišti")
			if _jdi(Vector3(9.5, y, 1.2), delta) or t > 58.0:
				krok = 8
		8:
			_popis("TEST 8/10 — žaluzie v bytě")
			if _jdi(Vector3(2.4, y, -8.0), delta) or t > 68.0:
				_kouknij_na(Vector3(2.4, y + 1.5, -11.6), delta)
				_ceka += delta
				if _ceka > 1.5:
					hrac.pouzij_ruku()
					_ceka = 0.0
					krok = 9
		9:
			_popis("TEST 9/10 — sekera")
			hrac.seknout()
			_ceka += delta
			if _ceka > 2.5:
				_ceka = 0.0
				krok = 10
		10:
			_popis("TEST 10/10 — Zéd hodil loď, barák se bortí")
			_kouknij_na(Vector3(0.0, y + 6.0, -11.0), delta)
			if dum_stav:
				dum_stav.zasah_lodi(Vector3(hrac.global_position.x, y + 8.0, -6.0))
				dum_stav.zasah_lodi(Vector3(hrac.global_position.x + 20.0, y + 30.0, 0.0))
			krok = 11
		11:
			_kouknij_na(Vector3(0.0, y + 4.0, -11.0), delta)
			if t > 70.0:
				_popis("Stav domu: %d %%" % int(dum_stav.stav_procent) if dum_stav else "")
