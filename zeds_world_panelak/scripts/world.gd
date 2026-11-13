extends Node3D
## Zed's World: Panelák — staví svět, drží stav hry.
## 5. 1. 2072, den Zédovy apokalypsy.

const MODEL_DUM := "res://assets/models/panelak_zed_destrukce_mobil.glb"
const MODEL_ZED := "res://assets/models/zed_zedovsky_rig.glb"
const MODEL_PROPS := "res://assets/models/props_zed.glb"

var dum: Node3D
var hrac: CharacterBody3D
var hud: CanvasLayer
var vytah: Node
var dum_stav: Node
var pocasi: Node
var zedove: Array[Node3D] = []

var cas_hry := 0.0
var intro_bezi := true
var svetla_jdou := true          # na začátku jdou, pak vypadnou

@onready var zvuk := preload("res://scripts/audio.gd").new()

func _ready() -> void:
	add_child(zvuk)
	_postav_dum()
	_postav_pocasi()
	_postav_hrace()
	_postav_vytah()
	_postav_stav_domu()
	_postav_hud()
	_spawn_zedy(3)
	_postav_predmety()
	_postav_zaluzie()
	_postav_lampy()
	_postav_svetla_domu()
	_postav_dvere()
	if "demolice" in OS.get_cmdline_user_args():
		var a2 := preload("res://scripts/autopilot2.gd").new()
		add_child(a2)
		a2.dum_stav = dum_stav
	if "autopilot" in OS.get_cmdline_user_args():
		_autopilot()
	else:
		_intro()

# ---------------------------------------------------------------- dům
func _postav_dum() -> void:
	dum = (load(MODEL_DUM) as PackedScene).instantiate()
	dum.name = "Panelak"
	add_child(dum)
	# trosky, oheň, kouř a loď se v klidu schovají — klonují se až při zásahu
	for jmeno in ["trosky", "ohen", "kour", "lod"]:
		for n in dum.find_children(jmeno + "*", "MeshInstance3D", true, false):
			n.visible = false
	# každé podlaží do vlastního uzlu, ať se dá vypínat (kvůli výkonu na mobilu)
	var kolize := preload("res://scripts/colliders.gd").new()
	add_child(kolize)
	kolize.dum = dum
	# vykreslovat jen pásy domu kolem hráče, jinak to telefon neutáhne
	var lod := preload("res://scripts/chunk_lod.gd").new()
	add_child(lod)
	lod.dum = dum

func _postav_pocasi() -> void:
	pocasi = preload("res://scripts/weather.gd").new()
	add_child(pocasi)

func _postav_hrace() -> void:
	hrac = preload("res://scripts/player.gd").new()
	add_child(hrac)
	# začínáme ve svém bytě ve 12. podlaží
	hrac.position = Vector3(ZWConfig.apt_x(3), ZWConfig.floor_y(12) + 1.0, -7.0)
	hrac.zvuk = zvuk

func _postav_vytah() -> void:
	vytah = preload("res://scripts/vytah_transporta.gd").new()
	add_child(vytah)
	vytah.dum = dum
	vytah.hrac = hrac
	vytah.zvuk = zvuk
	vytah.stav.connect(_hlaska)

func _postav_stav_domu() -> void:
	dum_stav = preload("res://scripts/house.gd").new()
	add_child(dum_stav)
	dum_stav.dum = dum
	dum_stav.zvuk = zvuk
	dum_stav.hrac = hrac

func _postav_hud() -> void:
	hud = preload("res://scripts/hud.gd").new()
	add_child(hud)
	hud.hrac = hrac
	hud.dum_stav = dum_stav

func _spawn_zedy(pocet: int) -> void:
	var scn := load(MODEL_ZED) as PackedScene
	for i in pocet:
		var z := preload("res://scripts/zed.gd").new()
		add_child(z)
		z.model = scn.instantiate()
		z.add_child(z.model)
		z.zvuk = zvuk
		z.hrac = hrac
		z.dum_stav = dum_stav
		var uhel := TAU * float(i) / float(pocet) + 0.4
		z.position = Vector3(cos(uhel) * 900.0, 0.0, sin(uhel) * 900.0)
		zedove.append(z)
	dum_stav.zedove = zedove

func _postav_predmety() -> void:
	var p := preload("res://scripts/props.gd").new()
	add_child(p)
	p.zvuk = zvuk
	p.hrac = hrac

func _postav_zaluzie() -> void:
	## Hratelná žaluzie se staví jen pro podlaží kolem hráče — na mobilu
	## by 99 pater × 28 oken nemělo smysl.
	var z := preload("res://scripts/blinds_manager.gd").new()
	add_child(z)
	z.dum_stav = dum_stav
	z.zvuk = zvuk
	z.hrac = hrac

func _postav_lampy() -> void:
	## Pravidlo pouliční lampy (kánon, fáze 14–15): venku chrání jedině
	## kužel světla. V domě proud padá, ale venkovní síť zatím drží.
	var l := preload("res://scripts/lamps.gd").new()
	add_child(l)
	l.hrac = hrac

func _postav_svetla_domu() -> void:
	## Zářivky na chodbě. Svítí jen do výpadku proudu.
	var sv := preload("res://scripts/house_lights.gd").new()
	add_child(sv)
	sv.hrac = hrac

func _postav_dvere() -> void:
	## Dveře bytů se dají otevřít; část jich je zamčená a jdou na sekeru.
	var d := preload("res://scripts/dvere_manager.gd").new()
	add_child(d)
	d.zvuk = zvuk
	d.hrac = hrac

func _autopilot() -> void:
	## Automatický průchod pro nahrání testovacího videa.
	svetla_jdou = false
	hrac.baterka_povolena = true
	hrac.muze_hybat = false
	var a := preload("res://scripts/autopilot.gd").new()
	add_child(a)
	a.svet = self
	a.vytah = vytah
	a.dum_stav = dum_stav
	await get_tree().create_timer(8.0).timeout
	_zhasni_svetla()
	hrac.prepni_baterku()

func _hlaska(text: String) -> void:
	if hud:
		hud.titulek("", text, 4.0)

# ---------------------------------------------------------------- intro
## MladoboleslavRadio, 5. 1. 2072 — čtyři dny po Zédově příletu.
## Pan Rozhlasník je mrtvý od prvního ledna, vysílá někdo jiný.
## Kánon: Edice 2.5 + chronologie apokalypsy, fáze 1–4.
const RADIO := [
	"MladoboleslavRadio vysílá. Pátý leden, sedm hodin ráno.",
	"Pan Rozhlasník je čtvrtý den po smrti. Mluví k vám náhradní směna.",
	"Prezident Monderez nasadil těžkou techniku. Technika se obrátila proti posádkám.",
	"Nevycházejte. Opakuji, nevycházejte. Kov venku není kov.",
	"Kdo slyšel to slovo, ať nevzpomíná, jak znělo.",
]

func _intro() -> void:
	hrac.muze_hybat = false
	hud.titulek("5. 1. 2072", "Mladá Boleslav. Probudil ses doma. Venku je něco divně slyšet.")
	zvuk.hraj_2d("intro_probuzeni")
	await get_tree().create_timer(3.0).timeout
	for veta in RADIO:
		hud.titulek("", "RÁDIO: " + veta, 2.6)
		await get_tree().create_timer(2.6).timeout
	hrac.muze_hybat = true
	hud.titulek("", "Okno zarachotilo. Sousedi už utíkají.")
	await get_tree().create_timer(6.0).timeout
	hud.titulek("", "RÁDIO: …je u čtvrtého bloku. Zatáhněte žalu—", 3.0)
	await get_tree().create_timer(3.0).timeout
	_zhasni_svetla()
	intro_bezi = false

func _zhasni_svetla() -> void:
	## Proud padá. Od téhle chvíle má hráč jen baterku.
	svetla_jdou = false
	for n in dum.find_children("*zlut_svetlo*", "MeshInstance3D", true, false):
		n.visible = false
	for l in get_tree().get_nodes_in_group("svetla_domu"):
		l.visible = false
	hrac.baterka_povolena = true
	hud.titulek("", "Proud je pryč. Monderez vypnul síť. Máš jen baterku.")
	zvuk.hraj_2d("predmet_znicen_01", -8.0)

func _process(delta: float) -> void:
	cas_hry += delta
