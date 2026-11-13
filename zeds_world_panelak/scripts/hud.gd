extends CanvasLayer
## Dotykové ovládání pro Android + ukazatele.
## Vlevo páčka, vpravo rozhled tahem, tlačítko s rukou a sekera.

var hrac: CharacterBody3D
var dum_stav: Node

var packa_zaklad: Control
var packa_palec: Control
var tl_ruka: Button
var tl_sekera: Button
var tl_baterka: Button
var pruh_stamina: ProgressBar
var pruh_zdravi: ProgressBar
var popis_dum: Label
var popis_cas: Label
var titulky: Label
var nadpis: Label

var _packa_id := -1
var _packa_stred := Vector2.ZERO
var _look_id := -1
var _look_min := Vector2.ZERO
var _titulek_cas := 0.0

const PACKA_R := 110.0

func _ready() -> void:
	layer = 10
	add_to_group("hud")
	_postav()
	if dum_stav:
		dum_stav.zmena.connect(_obnov)
	if hrac:
		hrac.zmena_stavu.connect(_obnov)

func _kruh(barva: Color, r: float) -> Control:
	var c := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = barva
	st.corner_radius_top_left = int(r)
	st.corner_radius_top_right = int(r)
	st.corner_radius_bottom_left = int(r)
	st.corner_radius_bottom_right = int(r)
	c.add_theme_stylebox_override("panel", st)
	c.size = Vector2(r * 2, r * 2)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

func _postav() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- virtuální páčka vlevo dole
	packa_zaklad = _kruh(Color(1, 1, 1, 0.10), PACKA_R)
	packa_zaklad.position = Vector2(70, -260)
	packa_zaklad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, true)
	root.add_child(packa_zaklad)
	packa_palec = _kruh(Color(1, 1, 1, 0.26), 46)
	packa_palec.position = packa_zaklad.position + Vector2(PACKA_R - 46, PACKA_R - 46)
	root.add_child(packa_palec)

	# --- tlačítko s rukou
	tl_ruka = Button.new()
	tl_ruka.text = "RUKA"
	tl_ruka.add_theme_font_size_override("font_size", 30)
	tl_ruka.custom_minimum_size = Vector2(150, 150)
	tl_ruka.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	tl_ruka.position = Vector2(-190, -200)
	tl_ruka.pressed.connect(_na_ruku)
	root.add_child(tl_ruka)

	# --- sekera
	tl_sekera = Button.new()
	tl_sekera.text = "SEKERA"
	tl_sekera.add_theme_font_size_override("font_size", 22)
	tl_sekera.custom_minimum_size = Vector2(110, 110)
	tl_sekera.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	tl_sekera.position = Vector2(-340, -170)
	tl_sekera.pressed.connect(_na_sekeru)
	root.add_child(tl_sekera)

	# --- baterka
	tl_baterka = Button.new()
	tl_baterka.text = "SVĚTLO"
	tl_baterka.add_theme_font_size_override("font_size", 20)
	tl_baterka.custom_minimum_size = Vector2(96, 96)
	tl_baterka.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
	tl_baterka.position = Vector2(-190, -330)
	tl_baterka.pressed.connect(_na_baterku)
	root.add_child(tl_baterka)

	# --- ukazatele
	pruh_zdravi = ProgressBar.new()
	pruh_zdravi.custom_minimum_size = Vector2(260, 18)
	pruh_zdravi.position = Vector2(24, 24)
	pruh_zdravi.show_percentage = false
	root.add_child(pruh_zdravi)

	pruh_stamina = ProgressBar.new()
	pruh_stamina.custom_minimum_size = Vector2(260, 12)
	pruh_stamina.position = Vector2(24, 50)
	pruh_stamina.show_percentage = false
	root.add_child(pruh_stamina)

	popis_dum = Label.new()
	popis_dum.position = Vector2(-330, 24)
	popis_dum.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	popis_dum.add_theme_font_size_override("font_size", 22)
	root.add_child(popis_dum)

	popis_cas = Label.new()
	popis_cas.position = Vector2(-330, 54)
	popis_cas.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	popis_cas.add_theme_font_size_override("font_size", 28)
	popis_cas.add_theme_color_override("font_color", Color(1, 0.45, 0.4))
	root.add_child(popis_cas)

	nadpis = Label.new()
	nadpis.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
	nadpis.position = Vector2(-200, 90)
	nadpis.custom_minimum_size = Vector2(400, 40)
	nadpis.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nadpis.add_theme_font_size_override("font_size", 40)
	root.add_child(nadpis)

	titulky = Label.new()
	titulky.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, true)
	titulky.position = Vector2(-420, -110)
	titulky.custom_minimum_size = Vector2(840, 60)
	titulky.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulky.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	titulky.add_theme_font_size_override("font_size", 24)
	root.add_child(titulky)

func _na_ruku() -> void:
	if hrac:
		hrac.pouzij_ruku()

func _na_sekeru() -> void:
	if hrac:
		hrac.seknout()

func _na_baterku() -> void:
	if hrac:
		hrac.prepni_baterku()

# ---------------------------------------------------------------- dotyk
func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			if e.position.x < get_viewport().get_visible_rect().size.x * 0.45:
				_packa_id = e.index
				_packa_stred = e.position
			else:
				_look_id = e.index
				_look_min = e.position
		else:
			if e.index == _packa_id:
				_packa_id = -1
				if hrac:
					hrac.nastav_pohyb(Vector2.ZERO)
				packa_palec.position = packa_zaklad.position + Vector2(PACKA_R - 46, PACKA_R - 46)
			elif e.index == _look_id:
				_look_id = -1
	elif e is InputEventScreenDrag:
		if e.index == _packa_id and hrac:
			var d: Vector2 = (e.position - _packa_stred) / PACKA_R
			d = d.limit_length(1.0)
			hrac.nastav_pohyb(Vector2(d.x, -d.y))
			packa_palec.position = packa_zaklad.position \
				+ Vector2(PACKA_R - 46, PACKA_R - 46) + d * (PACKA_R - 46)
		elif e.index == _look_id and hrac:
			hrac.nastav_look(e.relative)

# ---------------------------------------------------------------- výpis
func _obnov() -> void:
	if hrac:
		pruh_zdravi.value = hrac.zdravi
		pruh_stamina.value = hrac.stamina
	if dum_stav:
		popis_dum.text = "Dům: %d %%" % int(round(dum_stav.stav_procent))
		if dum_stav.odpocet > 0.0:
			var m := int(dum_stav.odpocet) / 60
			var s := int(dum_stav.odpocet) % 60
			popis_cas.text = "Zřícení za %d:%02d" % [m, s]
		elif dum_stav.zricen:
			popis_cas.text = "Dům je pryč"
		else:
			popis_cas.text = ""

func _process(delta: float) -> void:
	if _titulek_cas > 0.0:
		_titulek_cas -= delta
		if _titulek_cas <= 0.0:
			titulky.text = ""
			nadpis.text = ""
	_obnov()

func titulek(h: String, text: String, doba := 6.0) -> void:
	nadpis.text = h
	titulky.text = text
	_titulek_cas = doba
