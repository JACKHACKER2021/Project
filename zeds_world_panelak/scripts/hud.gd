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
var napoveda: Label
var smery: Label
var patro_popis: Label

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

	napoveda = Label.new()
	napoveda.set_anchors_preset(Control.PRESET_CENTER_BOTTOM, true)
	napoveda.position = Vector2(-300, -176)
	napoveda.custom_minimum_size = Vector2(600, 34)
	napoveda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	napoveda.add_theme_font_size_override("font_size", 26)
	napoveda.add_theme_color_override("font_outline_color", Color.BLACK)
	napoveda.add_theme_constant_override("outline_size", 6)
	root.add_child(napoveda)

	smery = Label.new()
	smery.set_anchors_preset(Control.PRESET_CENTER_TOP, true)
	smery.position = Vector2(-320, 16)
	smery.custom_minimum_size = Vector2(640, 32)
	smery.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	smery.add_theme_font_size_override("font_size", 24)
	smery.add_theme_color_override("font_outline_color", Color.BLACK)
	smery.add_theme_constant_override("outline_size", 5)
	root.add_child(smery)

	patro_popis = Label.new()
	patro_popis.position = Vector2(24, 76)
	patro_popis.add_theme_font_size_override("font_size", 26)
	patro_popis.add_theme_color_override("font_outline_color", Color.BLACK)
	patro_popis.add_theme_constant_override("outline_size", 5)
	root.add_child(patro_popis)

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
func _sipka(cil: Vector3) -> String:
	## Šipka ukazující, kam se otočit. Bez minimapy, jen podle pohledu.
	var smer: Vector3 = cil - hrac.global_position
	var vpred: Vector3 = -hrac.hlava.global_transform.basis.z
	var uhel := atan2(smer.x, smer.z) - atan2(vpred.x, vpred.z)
	uhel = wrapf(uhel, -PI, PI)
	if absf(uhel) < 0.5:
		return "^"
	elif absf(uhel) > 2.6:
		return "v"
	return "<" if uhel > 0.0 else ">"

func _obnov() -> void:
	if hrac:
		pruh_zdravi.value = hrac.zdravi
		pruh_stamina.value = hrac.stamina
		# co je pod rukou
		napoveda.text = ("[ RUKA ]  " + hrac.cil_popis) if hrac.cil_popis != "" else ""
		tl_ruka.disabled = hrac.cil_popis == ""
		tl_ruka.modulate = Color(1, 1, 1, 1.0 if hrac.cil_popis != "" else 0.45)
		# kde je výtah a kde schodiště
		var y := hrac.global_position.y
		var v := Vector3((ZWConfig.SH_X0 + ZWConfig.SH_X1) * 0.5, y,
			ZWConfig.SH_Z0 - 1.0)
		var sch := Vector3((ZWConfig.ST_X0 + ZWConfig.ST_X1) * 0.5, y,
			ZWConfig.ST_Z0 - 1.0)
		smery.text = "VÝTAH %s %d m     SCHODIŠTĚ %s %d m" % [
			_sipka(v), int(hrac.global_position.distance_to(v)),
			_sipka(sch), int(hrac.global_position.distance_to(sch))]
		var f := ZWConfig.y_to_floor(y)
		patro_popis.text = ("%d. podlaží" % f) if f >= 0 else ("sklep %d" % -f)
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
