extends Node
## Druhá část testu: pohled zvenku na dům, Zéd hodí loď a barák se bortí.

var hrac: CharacterBody3D
var hud: CanvasLayer
var dum_stav: Node
var kam: Camera3D
var t := 0.0
var n := 0
var faze := 0
const SLOZKA := "res://cap2"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SLOZKA)
	await get_tree().process_frame
	hrac = get_tree().get_first_node_in_group("hrac")
	hud = get_tree().get_first_node_in_group("hud")
	# kamera ven, ať je vidět celý dům
	kam = Camera3D.new()
	kam.fov = 55.0
	kam.far = 2000.0
	add_child(kam)
	kam.make_current()
	kam.global_position = Vector3(150, 80, -230)
	kam.look_at(Vector3(0, 90, 0))
	hrac.muze_hybat = false
	if hud:
		hud.titulek("TEST — DEMOLICE", "Zéd hází lodě, barák se bortí", 8.0)

func _process(d: float) -> void:
	t += d
	# pomalý nálet kamery
	var f := clampf(t / 26.0, 0.0, 1.0)
	kam.global_position = Vector3(lerp(150.0, 95.0, f), lerp(80.0, 46.0, f),
		lerp(-230.0, -150.0, f))
	kam.look_at(Vector3(0, lerp(120.0, 60.0, f), 0))
	if faze == 0 and t > 3.0:
		faze = 1
		_zasah(Vector3(-20, 170, 0))
	elif faze == 1 and t > 7.0:
		faze = 2
		_zasah(Vector3(10, 120, 0))
		_zasah(Vector3(25, 70, 0))
	elif faze == 2 and t > 12.0:
		faze = 3
		_zasah(Vector3(-25, 25, 0))
		_zasah(Vector3(0, 25, 0))
		if hud:
			hud.titulek("", "Spodní pás dostal zásah — dům se složí", 6.0)
	elif faze == 3 and t > 17.0:
		faze = 4
		if dum_stav:
			dum_stav.odpocet = 1.0
	_snimek()

func _zasah(kde: Vector3) -> void:
	if dum_stav:
		dum_stav.zasah_lodi(kde)
		print("[TEST2 %.1f s] zásah %s, stav domu %d %%" % [t, str(kde),
			int(dum_stav.stav_procent)])

func _snimek() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_jpg("%s/f%05d.jpg" % [SLOZKA, n], 0.86)
	n += 1
	if t > 34.0:
		print("[TEST2] hotovo ", n)
		get_tree().quit()
