extends Control
## HUD NaV3 – Frights & Hides (Godot): stejný kreslicí systém jako NaV2, Windows XP místo Win98

var game
const HH := 720.0
var HW = 1280.0
var HK = 1.0
var font: Font
var buttons = []
var hover_btn = null
var alpha = 1.0
var xf = Transform2D.IDENTITY
var xf_stack = []
var noise_frames = []
var scan_tex: ImageTexture
var vig_tex: GradientTexture2D
var tint_k = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = game.make_font()
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for f in 5:
		var img = Image.create(320, 180, false, Image.FORMAT_RGBA8)
		for y in 180:
			for x in 320:
				var v = randf()
				img.set_pixel(x, y, Color(v, v, v, 1))
		noise_frames.append(ImageTexture.create_from_image(img))
	var s = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	s.fill(Color(0, 0, 0, 0))
	for x in 4:
		s.set_pixel(x, 0, Color(0, 0, 0, 0.35))
		s.set_pixel(x, 2, Color(0, 0, 0, 0.35))
	scan_tex = ImageTexture.create_from_image(s)
	vig_tex = GradientTexture2D.new()
	vig_tex.fill = GradientTexture2D.FILL_RADIAL
	vig_tex.fill_from = Vector2(0.5, 0.5)
	vig_tex.fill_to = Vector2(1.15, 0.5)
	vig_tex.width = 256
	vig_tex.height = 256
	var g = Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_offset(0, 200.0 / (1280 * 0.65))
	g.set_color(1, Color(0, 0, 0, 1))
	vig_tex.gradient = g

func _apply() -> void:
	draw_set_transform_matrix(Transform2D().scaled(Vector2(HK, HK)) * xf)
func save_() -> void:
	xf_stack.append([xf, alpha])
func restore_() -> void:
	var s = xf_stack.pop_back()
	xf = s[0]
	alpha = s[1]
	_apply()
func translate(x: float, y: float) -> void:
	xf = xf * Transform2D(0, Vector2(x, y))
	_apply()
func scale_(sx: float, sy: float) -> void:
	xf = xf * Transform2D().scaled(Vector2(sx, sy))
	_apply()
func rotate_(a: float) -> void:
	xf = xf * Transform2D(a, Vector2.ZERO)
	_apply()

func C(c) -> Color:
	var col: Color = c if c is Color else Color(c)
	if tint_k > 0:
		col = Color(col.r * (1 - tint_k), col.g * (1 - tint_k), col.b * (1 - tint_k), col.a)
	col.a *= alpha
	return col

func rect(x: float, y: float, w: float, h: float, c) -> void:
	draw_rect(Rect2(x, y, w, h), C(c))
func px(x: float, y: float, w: float, h: float, c) -> void:
	draw_rect(Rect2(round(x), round(y), w, h), C(c))

func rr(x: float, y: float, w: float, h: float, r: float, fill, stroke = null, lw := 2.0) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = C(fill) if fill != null else Color(0, 0, 0, 0)
	sb.set_corner_radius_all(int(r))
	sb.anti_aliasing = true
	if stroke != null:
		sb.border_color = C(stroke)
		sb.set_border_width_all(int(lw))
		sb.draw_center = fill != null
	draw_style_box(sb, Rect2(x, y, w, h))

func tw(s: String, size: float) -> float:
	return font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size)).x

func txt(s: String, x: float, y: float, size: float, col, align := "left") -> void:
	var w = tw(s, size)
	var xx = x
	if align == "center":
		xx = x - w / 2
	elif align == "right":
		xx = x - w
	draw_string(font, Vector2(xx, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size), C(col))

func neon(s: String, x: float, y: float, size: float, col, blur := 18.0, align := "center") -> void:
	var c: Color = Color(col) if col is String else col
	var glow = Color(c.r, c.g, c.b, 0.16)
	var r = blur / 5.0
	for i in 10:
		var a = i * TAU / 10
		txt(s, x + cos(a) * r, y + sin(a) * r, size, glow, align)
	txt(s, x, y, size, c, align)
	txt(s, x, y, size, "#ffffff", align)
	var a0 = alpha
	alpha *= 0.55
	txt(s, x, y, size, c, align)
	alpha = a0

func wrapt(s: String, max_w: float, size: float) -> Array:
	var lines = []
	var line = ""
	for w in s.split(" "):
		var t: String = line + " " + w if line != "" else w
		if tw(t, size) > max_w and line != "":
			lines.append(line)
			line = w
		else:
			line = t
	if line != "":
		lines.append(line)
	return lines

func circle(x: float, y: float, r: float, c) -> void:
	draw_circle(Vector2(x, y), r, C(c))
func ring(x: float, y: float, r: float, c, lw: float) -> void:
	draw_arc(Vector2(x, y), r, 0, TAU, 64, C(c), lw, true)
func line(x0: float, y0: float, x1: float, y1: float, c, lw: float) -> void:
	draw_line(Vector2(x0, y0), Vector2(x1, y1), C(c), lw, true)

func noise(a: float) -> void:
	if a <= 0:
		return
	draw_texture_rect(noise_frames[randi() % 5], Rect2(0, 0, HW, HH), false, Color(1, 1, 1, minf(1, a) * alpha))
func scanlines() -> void:
	draw_texture_rect(scan_tex, Rect2(0, 0, HW, HH), true, Color(1, 1, 1, alpha))
func vignette(a: float) -> void:
	draw_texture_rect(vig_tex, Rect2(0, 0, HW, HH), false, Color(1, 1, 1, a * alpha))

static func hsl(h: float, s: float, l: float) -> Color:
	h = fposmod(h, 360.0) / 360.0
	var q = l * (1 + s) if l < 0.5 else l + s - l * s
	var p = 2 * l - q
	var f = func(t: float) -> float:
		t = fposmod(t, 1.0)
		if t < 1.0 / 6: return p + (q - p) * 6 * t
		if t < 0.5: return q
		if t < 2.0 / 3: return p + (q - p) * (2.0 / 3 - t) * 6
		return p
	return Color(f.call(h + 1.0 / 3), f.call(h), f.call(h - 1.0 / 3))

func add_btn(x: float, y: float, w: float, h: float, id: String, cb: Callable) -> void:
	var p = xf * Vector2(x, y)
	var q = xf * Vector2(x + w, y + h)
	buttons.append({"x": p.x, "y": p.y, "w": q.x - p.x, "h": q.y - p.y, "id": id, "cb": cb})



# ====================================================================
#  NaV3: obrazovky, Windows XP a ovládání
# ====================================================================
var joy = null
var drag = null
var touches = {}
var flash_id = -1

func btn(x: float, y: float, w: float, h: float, label: String, id: String, cb: Callable, on := true, size := 20.0, col := "#5dff8a") -> void:
	var c = Color(col)
	rr(x, y, w, h, 10, (c.darkened(0.3) if hover_btn == id else Color(c.r * 0.3, c.g * 0.3, c.b * 0.3, 0.45)) if on else Color(1, 1, 1, 0.05), c if on else Color("#444444"), 2)
	while size > 9 and tw(label, size) > w - 14:
		size -= 1
	txt(label, x + w / 2, y + h / 2 + size * 0.36, size, "#ffffff" if on else "#666666", "center")
	if on:
		add_btn(x, y, w, h, id, cb)

func wrap_txt(s: String, x: float, y: float, max_w: float, size: float, col, lh := 1.4) -> float:
	var ls = wrapt(s, max_w, size)
	for i in ls.size():
		txt(ls[i], x, y + i * size * lh, size, col)
	return y + ls.size() * size * lh

## logo: zelené oči Hollow Hare v černém kruhu
func draw_logo(x: float, y: float, s: float) -> void:
	var c = Vector2(x + s / 2, y + s / 2)
	for i in 4:
		draw_arc(c, s * 0.47, 0, TAU, 96, C(Color(0.3, 1, 0.4, 0.14)), s * 0.045 + (4 - i) * 4, true)
	draw_arc(c, s * 0.47, 0, TAU, 96, C("#40ff60"), s * 0.045, true)
	var u = s / 16
	rect(x + 3.5 * u, y + 5 * u, 9 * u, 8 * u, "#5a6020")
	rect(x + 4 * u, y + 1 * u, 2 * u, 4.5 * u, "#5a6020")
	rect(x + 10.5 * u, y + 2.5 * u, 1.2 * u, 2.5 * u, "#2a2a2a")
	rect(x + 4.6 * u, y + 7 * u, 2.2 * u, 2.2 * u, "#050505")
	rect(x + 9.2 * u, y + 7 * u, 2.2 * u, 2.2 * u, "#050505")
	rect(x + 5.3 * u, y + 7.7 * u, 0.8 * u, 0.8 * u, "#60ff70")
	rect(x + 9.9 * u, y + 7.7 * u, 0.8 * u, 0.8 * u, "#60ff70")
	rect(x + 5 * u, y + 10.5 * u, 6 * u, 1.4 * u, "#1a0505")
	for i in 5:
		rect(x + (5.3 + i * 1.15) * u, y + 10.5 * u, 0.6 * u, 0.6 * u, "#d8d0b0")
	rect(x + 9 * u, y + 11 * u, 1.2 * u, 2 * u, "#8a1010")

func _draw() -> void:
	var vs = get_viewport_rect().size
	HW = maxf(960.0, HH * vs.x / vs.y)
	HK = minf(vs.y / HH, vs.x / HW)
	buttons = []
	xf = Transform2D.IDENTITY
	xf_stack = []
	alpha = 1.0
	_apply()
	var g = game
	var t: float = g.t_now
	match g.S:
		"loading":
			rect(0, 0, HW, HH, "#000000")
		"menu": draw_menu(t)
		"tour": draw_tour(t)
		"extras": draw_extras(t)
		"custom": draw_custom(t)
		"end7": draw_end7(t)
		"devmenu": draw_devmenu(t)
		"arrive": draw_arrive(t)
		"intro": draw_intro()
		"play": draw_play(t)
		"scare": draw_scare(t)
		"collapse": draw_collapse(t)
		"dead": draw_end("dead")
		"win": draw_end("win")
		"fired": draw_end("fired")

# ---------------------------------------------------------------- menu
func draw_menu(t: float) -> void:
	rect(0, 0, HW, HH, Color(0, 0.05, 0.01, 0.55))
	rect(0, 0, HW, HH, Color(0.1, 0.5, 0.15, 0.06))
	noise(0.07 + (0.2 if randf() < 0.04 else 0.0))
	vignette(0.9)
	# profilovka: živý portrét Hollow Hare v zeleném kruhu
	var pc = Vector2(135, 115)
	for i in 5:
		draw_arc(pc, 80, 0, TAU, 96, C(Color(0.3, 1, 0.4, 0.12)), 6 + (5 - i) * 4, true)
	circle(pc.x, pc.y, 76, "#061006")
	draw_texture_rect(game.portrait_vp.get_texture(), Rect2(pc.x - 76, pc.y - 76, 152, 152), false, C(Color(1, 1, 1, 0.75 + 0.25 * absf(sin(t * 2.0)) if randf() > 0.03 else 0.2)))
	draw_arc(pc, 76, 0, TAU, 96, C("#40ff60"), 5, true)
	txt("HOLLOW HARE", pc.x, pc.y + 104, 13, "#7dff8a", "center")
	txt("NIGHT AT", 230, 100, 40, "#9fffb0")
	txt("VOXIE'S", 230, 178, 80, "#40ff60")
	txt("3", 610, 178, 80, "#ffffff")
	neon("FRIGHTS & HIDES", 830, 120, 30, "#ff4040", 16)
	txt("Atrakce z popela. A v zákulisí stojí on.", 234, 208, 17, "#cccccc")
	var un: int = game.st_get("v3_night", 1)
	game.menu_night = mini(game.menu_night, un)
	btn(60, 240, 400, 56, "▶ HRÁT NOC " + str(game.menu_night), "play", func(): game.start_night(game.menu_night), true, 22)
	for i in range(1, 8):
		var n = i
		btn(60 + (i - 1) * 57.5, 306, 51, 44, str(i) if i <= un else "🔒", "n" + str(i), func():
			game.menu_night = n
			game.audio.sfx("click"), i <= un, 18, "#ffe46b" if i == game.menu_night else "#5dff8a")
	btn(60, 360, 195, 48, "★ EXTRAS", "ex", game.start_extras, true, 18)
	btn(265, 360, 195, 48, "🛠 DEV", "dev", func():
		game.S = "devmenu"
		game.scene_t = 0.0, true, 18, "#ffb030")
	btn(470, 360, 230, 48, "⚙ CUSTOM NIGHT", "cust", game.start_custom, game.st_get("v3_end", false) or game.st_get("v3_night", 1) >= 7, 18, "#ffb030")
	if game.st_get("v3_end", false):
		txt("★ Frights & Hides lehlo popelem.", 720, 390, 17, "#ffe46b")
	var lines = ["🖥 Windows XP: piš hlášení. 🚶 Ve 3., 4. a 6. noci musíš vstát a splnit úkol v budově.",
		"📹 Kamery F&H: sleduj, kudy chodí Hollow Hare. 🔊 Dětským smíchem ho odlákáš.",
		"🚪 Dveře a 🌀 šachta berou ⚡ energii. Tři bouchnutí zajíce = -5 %. Bez proudu jsi bez ochrany.",
		"🧠 Sanity: pohled na zajíce tě ničí. Točí se hlava, je ti zle… až zkolabuješ.",
		"☕ Káva z kávovaru a 💊 prášky vrátí příčetnost. Psaní hlášení tě uklidňuje."]
	for i in lines.size():
		txt(lines[i], 64, 450 + i * 30, 16, "#cfeed4")
	txt("v0.2.0 · Godot", HW - 20, 700, 14, "#666666", "right")

# ---------------------------------------------------------------- titulky
func subs() -> void:
	var l = game.line
	if l == null:
		return
	var who = {"V": ["Broken Voxie (Vojtěch)", "#9fd0ff"], "S": ["???", "#ffffff"], "P": ["Ty", "#bbbbbb"], "O": ["Pan Kroupa", "#ffb060"], "H": ["???", "#7dff8a"], "X": ["", "#ffffff"]}[l.who]
	var ls = wrapt(l.t, 760, 21)
	var h = 30 + ls.size() * 28
	var base = HH - (175 if game.S == "play" and not game.G.mon else 40)
	rr(HW / 2 - 400, base - h, 800, h, 10, Color(0.0, 0.06, 0.02, 0.78), Color(0.25, 0.8, 0.35, 0.5), 1)
	if who[0] != "":
		txt(who[0], HW / 2 - 384, base - h + 20, 14, who[1])
	for i in ls.size():
		var off = Vector2(randf_range(-2, 2), randf_range(-2, 2)) if l.who == "H" else Vector2.ZERO
		txt(ls[i], HW / 2 + off.x, base - h + 46 + i * 28 + off.y, 21, "#ffffff" if l.who != "H" else "#b8ffc0", "center")

func draw_tour(t: float) -> void:
	vignette(0.75)
	var st = game.L.tour[game.tour_i]
	var names = {"LOBBY": "Vchod a pokladna", "ARC": "Expozice: herna", "HALL": "Hlavní chodba", "COC": "Expozice: Cocoa", "PIZ": "Expozice: pizzerie", "ARCH": "Archiv", "BACK": "Zákulisí", "OFF": "Kancelář hlídače"}
	txt("NOC 1 · PROHLÍDKA", 24, 40, 18, "#9fffb0")
	txt(names[st.at], 24, 66, 26, "#ffffff")
	if game.G.tour_cut < 0.6:
		rect(0, 0, HW, HH, Color(0, 0, 0, 1 - game.G.tour_cut / 0.6))
	subs()
	btn(HW - 220, 24, 196, 44, "DALŠÍ ▶", "tskip", func(): game._tour_next(), true, 16)

func draw_arrive(t: float) -> void:
	var st: float = game.scene_t
	vignette(0.8)
	rect(0, 0, HW, HH, Color(0.05, 0.3, 0.1, 0.05))
	if st < 1.5:
		rect(0, 0, HW, HH, Color(0, 0, 0, 1 - st / 1.5))
	if st > 0.8 and st < 5.5:
		save_()
		alpha = clampf(minf(st - 0.8, 5.5 - st), 0, 1)
		txt("ŘÍJEN 2004", 40, 70, 20, "#9fffb0")
		txt("Parkoviště u atrakce Frights & Hides, 23:48", 40, 100, 18, "#cccccc")
		restore_()
	if st > 13.0:
		rect(0, 0, HW, HH, Color(0, 0, 0, clampf(st - 13.0, 0, 1)))
	subs()
	btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "askip", func(): game.scene_t = maxf(game.scene_t, 13.9), true, 16)

func draw_intro() -> void:
	var G = game.G
	var st: float = game.scene_t
	rect(0, 0, HW, HH, "#000000")
	save_()
	alpha = clampf(minf(st, 3.2 - st) * 1.5, 0, 1)
	var T = {6: ["Zítra přijede muzeum.", "Projdi všechny exponáty."], 7: ["Poslední noc.", "Ve skladu stojí kanystr benzínu."], 8: ["Custom Night", "Zajíc %d · Shadow Voxie %d · Shadow D. %d · Broken Voxie %d" % [game.CUST.hare, game.CUST.sv, game.CUST.sd, game.CUST.vx]], 1: ["Frights & Hides.", "Atrakce z věcí, které přežily požár herny Voxie's."], 2: ["Zajíc stál ráno jinde.", "Pan Kroupa tvrdí, že to jsou efekty."], 3: ["Ze zákulisí je slyšet cvakání.", "Muzeum chce zajíce koupit."], 4: ["Brigádník omdlel u zákulisí.", "Slyšel, jak zajíc mluví."], 5: ["Zajíc má zase jinak hlavu.", "Uvnitř obleku je někdo. Víš kdo."]}[G.night]
	txt(T[0], HW / 2, 310, 32, "#9fffb0", "center")
	txt(T[1], HW / 2, 356, 20, "#cccccc", "center")
	alpha = clampf(minf(st - 3.2, 6.4 - st) * 1.5, 0, 1)
	txt("0:00", HW / 2, 330, 90, "#ffffff", "center")
	txt("Custom Night" if G.night == 8 else "Noc " + str(G.night), HW / 2, 400, 40, "#7dff8a", "center")
	restore_()
	noise(0.06)
	if st > 6.4:
		game.begin_play()

# ---------------------------------------------------------------- v kanceláři
func clock_s() -> String:
	var h: int = game.hour()
	return ("12" if h == 0 else str(h)) + ":00 AM"

func sanity_bar(x: float, y: float) -> void:
	var G = game.G
	var s: float = G.san
	var wob = sin(game.t_now * 7) * (100 - s) * 0.03
	rr(x, y + wob, 230, 26, 6, "#111111")
	var col = "#5dff8a" if s > 60 else ("#ffd040" if s > 30 else "#ff4040")
	rect(x + 3, y + 3 + wob, 224 * s / 100.0, 20, col)
	txt("🧠 SANITY " + str(ceili(s)) + " %", x + 240, y + 19 + wob, 16, col)
	if G.heat > 0.05:
		txt("🌡 Vedro " + str(int(G.heat * 100)) + " %", x, y + 50, 15, "#ffb060")

func draw_play(t: float) -> void:
	var G = game.G
	var s: float = G.nausea
	rect(0, 0, HW, HH, Color(0.1, 0.45, 0.15, 0.05))
	vignette(0.6 + s * 0.4)
	if G.monA > 0:
		save_()
		alpha = G.monA
		draw_xp(t)
		restore_()
	if G.roam:
		draw_roam(t)
	elif G.monA < 0.5:
		txt(clock_s(), HW - 24, 54, 42, "#ffffff", "right")
		txt("Noc " + str(G.night), HW - 24, 82, 20, "#7dff8a", "right")
		sanity_bar(24, 24)
		power_bar(24, 66)
		if G.night < 7:
			txt("📄 Hlášení: " + str(int(100.0 * G.typed / game.REPORTS[G.night].length())) + " %", 24, 124, 16, "#ffffff" if not game.report_done() else "#5dff8a")
		var tl = game.sys.task_label()
		if tl != "":
			txt(tl + ("  ✔" if game.sys.task_done() and G.task.kind != "fire" else ""), 24, 150, 16, "#ffe46b" if not game.sys.task_done() else "#5dff8a")
		if G.vox.beat:
			txt("⚠ Z hlavní chodby jsou slyšet rány! VOXIE " + str(ceili(G.vox.hp)) + " %", HW / 2, 140, 20, "#ff5050" if sin(t * 8) > 0 else "#ffb0b0", "center")
		if G.blackout:
			txt("⚡ VÝPADEK PROUDU", HW / 2, 200, 30, "#ff4040", "center")
		btn(HW - 210, 100, 126, 40, "🚶 VSTÁT", "stand", game.sys.stand_up, not G.kroupa and not G.blackout, 15, "#9fd0ff")
		# ovládání dveří a šachty
		var by = HH - 92
		btn(24, by, 150, 64, ("🚪 OTEVŘÍT" if G.door else "🚪 ZAVŘÍT"), "door", func():
			G.door = not G.door
			game.audio.sfx("clunk", 0.8, -0.8), true, 17, "#ff6060" if G.door else "#5dff8a")
		btn(182, by, 80, 64, "💡", "dl", func():
			G.dl = not G.dl
			if G.dl:
				G.lookT = game.LOOK_DOOR
			game.audio.sfx("click"), true, 24, "#ffe46b" if G.dl else "#5dff8a")
		btn(HW - 174, by, 150, 64, ("🌀 OTEVŘÍT" if G.vent else "🌀 ZAVŘÍT"), "vent", func():
			G.vent = not G.vent
			game.audio.sfx("clunk", 0.7, 0.8), true, 17, "#ff6060" if G.vent else "#5dff8a")
		btn(HW - 262, by, 80, 64, "💡", "vl", func():
			G.vl = not G.vl
			if G.vl:
				G.lookT = game.LOOK_VENT
			game.audio.sfx("click"), true, 24, "#ffe46b" if G.vl else "#5dff8a")
		btn(HW / 2 - 130, by, 260, 64, "🖥 POČÍTAČ", "pc", game.toggle_mon, not G.kroupa and not G.blackout, 20)
		btn(HW / 2 - 130, by - 58, 126, 48, "💊 PRÁŠKY " + str(G.pills), "pill", game.take_pill, G.pills > 0 and G.pillT <= 0, 15, "#b0d0ff")
		var ctext = "☕ VAŘÍ SE…" if G.brew > 0 else ("☕ KÁVA" if G.coffeeCd <= 0 else "☕ " + str(ceili(G.coffeeCd)) + " s")
		btn(HW / 2 + 4, by - 58, 126, 48, ctext, "coffee", game.make_coffee, G.brew <= 0 and G.coffeeCd <= 0, 15, "#ffb060")
		if not has_touch():
			txt("A/D nebo ←/→ rozhlížení · MEZERNÍK počítač · Q dveře · E šachta", HW / 2, by - 72, 13, "#777777", "center")
	# zvracení / pád: obraz bliká zeleně
	if s > 0.6:
		rect(0, 0, HW, HH, Color(0.2, 0.35, 0.05, (s - 0.6) * 0.25 * (0.5 + 0.5 * sin(t * 2.3))))
	if G.hall > 0 and randf() < 0.5:
		noise(0.15)
	if G.blackout:
		rect(0, 0, HW, HH, Color(0, 0, 0, 0.55))
	if G.fire:
		rect(0, 0, HW, HH, Color(0.6, 0.15, 0.0, 0.12 + 0.05 * sin(t * 13)))
	if G.scareFace and not G.roam:
		draw_shadow_face(G.scareFace)
	if not G.roam:
		subs()
	draw_dev_panel()

func power_bar(x: float, y: float) -> void:
	var G = game.G
	var p: float = G.pow
	var col = "#ffe46b" if p > 30 else "#ff6040"
	if G.powFlash > 0 and sin(game.t_now * 30) > 0:
		col = "#ffffff"
	rr(x, y, 230, 22, 6, "#111111")
	rect(x + 3, y + 3, 224 * p / 100.0, 16, col)
	txt("⚡ ENERGIE " + str(ceili(p)) + " %", x + 240, y + 17, 15, col)
	if G.bangs > 0:
		txt("🚪 bouchnutí: " + str(G.bangs) + " (každé 3. = -5 %)", x, y + 108, 13, "#aaaaaa")

func draw_roam(t: float) -> void:
	var G = game.G
	txt(clock_s(), HW - 24, 54, 36, "#ffffff", "right")
	sanity_bar(24, 24)
	var tl = game.sys.task_label()
	if tl != "":
		txt(tl, 24, 90, 18, "#ffe46b" if not game.sys.task_done() else "#5dff8a")
	var jx = 150.0
	var jy = HH - 150.0
	ring(jx, jy, 80, Color(1, 1, 1, 0.25), 3)
	if joy:
		circle(jx + joy.dx * 60, jy + joy.dy * 60, 30, Color(0.4, 1, 0.5, 0.35))
	else:
		circle(jx, jy, 30, Color(1, 1, 1, 0.12))
	var al = game.sys.act_label()
	if al != "":
		btn(HW - 330, HH - 190, 300, 64, al, "act", game.sys.act, true, 18, "#ffe46b")
	if game.sys.near_chair():
		btn(HW - 330, HH - 110, 300, 60, "🪑 SEDNOUT KE STOLU", "sit", game.sys.sit_down, true, 17)
	if G.scareFace:
		draw_shadow_face(G.scareFace)
	subs()

## stín se zjeví přes celou obrazovku
func draw_shadow_face(f) -> void:
	var a = clampf(f.t / 0.9, 0, 1)
	rect(0, 0, HW, HH, Color(0, 0, 0, 0.85 * a))
	var cx = HW / 2 + randf_range(-6, 6)
	var cy = HH / 2 + randf_range(-6, 6)
	var s = 300.0
	rect(cx - s / 2, cy - s / 2, s, s * 0.9, Color(0.02, 0.01, 0.03, a))
	if f.who == "vox":
		rect(cx - s / 2 - 10, cy - s / 2 - 70, 110, 90, Color(0.02, 0.01, 0.03, a))
		rect(cx + s / 2 - 100, cy - s / 2 - 70, 110, 90, Color(0.02, 0.01, 0.03, a))
	for k in [-1, 1]:
		rect(cx + k * 70 - 14, cy - 40, 28, 28, Color(1, 1, 1, a))
	rect(cx - 80, cy + 60, 160, 16, Color(1, 1, 1, a * 0.6))
	noise(0.3 * a)

# ---------------------------------------------------------------- Windows XP
func xp_title(x: float, y: float, w: float, title: String, icon: String) -> void:
	rr(x, y, w, 30, 8, "#0a52dd")
	for i in 10:
		rect(x + 2, y + 2 + i * 2.6, w - 4, 2.6, Color("#3a8cf7").lerp(Color("#0a3fc4"), i / 10.0))
	rect(x, y + 22, w, 8, "#0a3fc4")
	txt(icon + " " + title, x + 10, y + 21, 15, "#ffffff")
	for i in 2:
		rr(x + w - 84 + i * 26, y + 4, 22, 22, 3, "#2a6cf0", "#ffffff", 1)
		txt(["_", "□"][i], x + w - 73 + i * 26, y + 20, 13, "#ffffff", "center")
	rr(x + w - 30, y + 4, 24, 22, 3, "#e0502a", "#ffffff", 1)
	txt("✕", x + w - 18, y + 20, 13, "#ffffff", "center")
	add_btn(x + w - 30, y + 4, 24, 22, "xclose", func():
		game.G.app = "desk"
		game.audio.sfx("click"))
func xp_window(x: float, y: float, w: float, h: float, title: String, icon: String) -> void:
	rr(x - 3, y, w + 6, h + 3, 8, "#0a3fc4")
	rect(x, y + 30, w, h - 30, "#ece9d8")
	xp_title(x - 3, y, w + 6, title, icon)
func xp_btn(x: float, y: float, w: float, h: float, label: String, id: String, cb: Callable, on := true, size := 14.0) -> void:
	rr(x, y, w, h, 4, "#f4f3ee" if hover_btn != id else "#fff8d8", "#003c74" if on else "#a0a0a0", 1)
	while size > 9 and tw(label, size) > w - 10:
		size -= 1
	txt(label, x + w / 2, y + h / 2 + size * 0.36, size, "#000000" if on else "#a0a0a0", "center")
	if on:
		add_btn(x, y, w, h, id, cb)

func draw_xp(t: float) -> void:
	var G = game.G
	# rámeček LCD monitoru
	rr(4, 4, HW - 8, HH - 8, 18, "#1c1c20", "#3a3a40", 4)
	var x0 = 30.0
	var y0 = 24.0
	var w = HW - 60
	var h = HH - 70
	# tapeta (zelený kopec, modré nebe)
	for i in 24:
		rect(x0, y0 + i * h / 40.0, w, h / 40.0 + 1, Color("#2f6fd8").lerp(Color("#a8d4f6"), i / 24.0))
	var pts = PackedVector2Array()
	for i in 41:
		var xx = x0 + w * i / 40.0
		pts.append(Vector2(xx, y0 + h * 0.58 + sin(i / 40.0 * PI * 0.9 + 0.35) * -h * 0.12))
	pts.append(Vector2(x0 + w, y0 + h))
	pts.append(Vector2(x0, y0 + h))
	draw_colored_polygon(pts, C("#4f9e26"))
	for i in 6:
		rect(x0, y0 + h * 0.82 + i * h * 0.03, w, h * 0.03 + 1, Color("#4f9e26").darkened(0.06 * i))
	# ikony na ploše
	var icons = [["cam", "📹", "F&H Kamery"], ["word", "📄", "Hlášení.doc"], ["mail", "📧", "Outlook Express"], ["bin", "🗑", "Koš"]]
	for i in icons.size():
		var ic = icons[i]
		var iy = y0 + 16 + i * 92
		if G.app == ic[0]:
			rr(x0 + 8, iy, 86, 82, 4, Color(0.2, 0.4, 0.9, 0.45))
		txt(ic[1], x0 + 51, iy + 42, 34, "#ffffff", "center")
		txt(ic[2], x0 + 52, iy + 72, 11, "#000000", "center")
		txt(ic[2], x0 + 51, iy + 71, 11, "#ffffff", "center")
		var app: String = ic[0]
		add_btn(x0 + 8, iy, 86, 82, "ic" + app, func():
			G.app = app
			game.audio.sfx("click"))
	var wx = x0 + 110
	var wy = y0 + 12
	var ww = w - 130
	var wh = h - 58
	match G.app:
		"cam": cam_app(wx, wy, ww, wh, t)
		"word": word_app(wx, wy, ww, wh, t)
		"mail": mail_app(wx, wy, ww, wh)
		"bin":
			xp_window(wx + 200, wy + 100, 460, 220, "Koš", "🗑")
			txt("hollow_bunny_1980_servis.txt", wx + 230, wy + 170, 15, "#000000")
			wrap_txt("„Zámky č. 3 a 7 povolují při vlhkosti. Do obleku NIKDO nesmí lézt. Vyřazeno.“ – V.", wx + 230, wy + 200, 400, 14, "#333333")
	# hlavní panel XP
	rect(x0, y0 + h - 34, w, 34, "#245edb")
	for i in 6:
		rect(x0, y0 + h - 34 + i * 2, w, 2, Color("#3c81f3").lerp(Color("#245edb"), i / 6.0))
	rr(x0, y0 + h - 34, 104, 34, 12, "#3c9a3c")
	rect(x0, y0 + h - 34, 20, 34, "#3c9a3c")
	txt("⊞ start", x0 + 52, y0 + h - 10, 18, "#ffffff", "center")
	if G.app != "desk":
		rr(x0 + 116, y0 + h - 30, 220, 26, 4, "#1e4ab8", "#5a8cf0", 1)
		txt({"cam": "📹 F&H Kamery", "word": "📄 Hlášení.doc - Microsoft Word", "mail": "📧 Outlook Express", "bin": "🗑 Koš"}[G.app], x0 + 126, y0 + h - 12, 12, "#ffffff")
	rect(x0 + w - 150, y0 + h - 34, 150, 34, "#0f8ae6")
	txt("🔊 " + clock_s(), x0 + w - 75, y0 + h - 11, 14, "#ffffff", "center")
	# odejít od počítače
	btn(HW / 2 - 110, HH - 46, 220, 40, "▼ ODEJÍT OD PC", "pcoff", game.toggle_mon, true, 15, "#9fd0ff")
	var yy = y0
	while yy < y0 + h:
		rect(x0, yy, w, 1, Color(0, 0, 0, 0.05))
		yy += 3

func cam_app(wx: float, wy: float, ww: float, wh: float, t: float) -> void:
	var G = game.G
	xp_window(wx, wy, ww, wh, "F&H Kamery – CAM " + G.cam + " " + game.MAP.cams[G.cam].name, "📹")
	var fx = wx + 10
	var fy = wy + 40
	var fw = ww - 380
	var fh = wh - 50
	rect(fx - 2, fy - 2, fw + 4, fh + 4, "#7a7a7a")
	rect(fx, fy, fw, fh, "#000000")
	if G.monA >= 1:
		draw_texture_rect(game.feed_vp.get_texture(), Rect2(fx, fy, fw, fh), false, Color(0.85, 1.0, 0.85, alpha))
	noise_rect(0.07 + G.staticT * 3 + (G.hall * 0.6), fx, fy, fw, fh)
	# halucinace: na kameře se na okamžik objeví zelené oči
	if G.hall > 0.2:
		for s in [-1, 1]:
			rect(fx + fw / 2 + s * 30 - 8, fy + fh * 0.4, 16, 16, "#60ff70")
	txt("CAM " + G.cam, fx + 12, fy + 26, 20, "#ffffff")
	txt(game.MAP.cams[G.cam].name, fx + 12, fy + 48, 15, "#dddddd")
	if sin(t * 4) > 0:
		circle(fx + fw - 70, fy + 20, 6, "#ff2020")
	txt("REC", fx + fw - 56, fy + 26, 15, "#ffffff")
	txt("2004-10-%02d  %s" % [11 + G.night, clock_s()], fx + 12, fy + fh - 12, 14, "#ffffff")
	# mapa
	var mx = fx + fw + 14
	var my = fy
	rect(mx, my, 344, 330, "#ffffff")
	draw_rect(Rect2(mx, my, 344, 330), C("#7a96df"), false, 1)
	var sc = 9.4
	var ox = mx + 172 - 0.5 * sc
	var oy = my + 330 - 10.8 * sc
	for id in game.MAP.rooms:
		var r = game.MAP.rooms[id]
		var rx = ox + r.x0 * sc
		var ry = oy + r.z0 * sc
		var rw = (r.x1 - r.x0) * sc
		var rh = (r.z1 - r.z0) * sc
		rect(rx, ry, rw, rh, "#d8e4f8" if id != "OFF" else "#ffd0d0")
		draw_rect(Rect2(rx, ry, rw, rh), C("#5a6a8a"), false, 1)
	# šachta
	line(ox + 3 * sc, oy - 18.5 * sc, ox + 12.5 * sc, oy - 18.5 * sc, "#a0a0a0", 5)
	line(ox + 12.5 * sc, oy - 18.5 * sc, ox + 12.5 * sc, oy + 7.6 * sc, "#a0a0a0", 5)
	line(ox + 12.5 * sc, oy + 7.6 * sc, ox + 3 * sc, oy + 7.6 * sc, "#a0a0a0", 5)
	txt("TY", ox, oy + 8.4 * sc, 12, "#a00000", "center")
	for cid in game.MAP.cams:
		var c = game.MAP.cams[cid]
		var px_ = ox + c.pos[0] * sc
		var py_ = oy + c.pos[2] * sc
		var sel = cid == G.cam
		rr(px_ - 15, py_ - 11, 30, 22, 4, "#0a52dd" if sel else "#f4f3ee", "#003c74", 1)
		txt(cid, px_, py_ + 5, 12, "#ffffff" if sel else "#000000", "center")
		var id2: String = cid
		add_btn(px_ - 16, py_ - 12, 32, 24, "c" + cid, func():
			if G.cam != id2:
				G.cam = id2
				G.staticT = 0.25
				game.audio.sfx("cam", 0.5))
	var gy = my + 338
	var ids = game.MAP.cams.keys()
	ids.sort()
	for i in ids.size():
		var cid2: String = ids[i]
		var bx = mx + (i % 5) * 69
		var byy = gy + int(i / 5) * 40
		rr(bx, byy, 64, 34, 4, "#0a52dd" if cid2 == G.cam else "#f4f3ee", "#003c74", 1)
		txt("CAM " + cid2, bx + 32, byy + 22, 12, "#ffffff" if cid2 == G.cam else "#000000", "center")
		add_btn(bx, byy, 64, 34, "cb" + cid2, func():
			if G.cam != cid2:
				G.cam = cid2
				G.staticT = 0.25
				game.audio.sfx("cam", 0.5))
	var by = gy + 86
	xp_btn(mx, by, 344, 34, "🔊 Pustit dětský smích" + ("" if G.lureCd <= 0 else " (" + str(ceili(G.lureCd)) + " s)"), "lure", game.lure, G.lureCd <= 0 and G.cam != "09")
	txt("Smích přiláká zajíce do místnosti na kameře.", mx, by + 52, 12, "#333333")
	if game.hare_on_cam():
		txt("⚠ Dívá se do kamery. Nedívej se dlouho!", mx, by + 74, 14, "#c00000")
	if G.vox.beat and G.cam == "04":
		txt("⚠ Mlátí do Voxieho! Odlákej ho smíchem jinam.", mx, by + 94, 13, "#c00000")

func word_app(wx: float, wy: float, ww: float, wh: float, t: float) -> void:
	var G = game.G
	xp_window(wx, wy, ww, wh, "Hlášení.doc - Microsoft Word", "📄")
	txt("Soubor  Úpravy  Zobrazit  Vložit  Formát  Nástroje  Tabulka  Okno  Nápověda", wx + 10, wy + 50, 13, "#000000")
	rect(wx, wy + 58, ww, 30, "#e3e0d0")
	txt("Times New Roman ▾   12 ▾   B  I  U   ≡  ≡  ≡", wx + 12, wy + 79, 13, "#000000")
	rect(wx + 6, wy + 92, ww - 12, wh - 128, "#8a8a8a")
	var px_ = wx + 60
	var pw = ww - 120
	rect(px_, wy + 100, pw, wh - 142, "#ffffff")
	var full: String = game.REPORTS[G.night]
	var shown = full.substr(0, G.typed)
	var cur = "|" if fmod(t, 1.0) < 0.5 else " "
	var ey = wrap_txt(shown + cur, px_ + 40, wy + 140, pw - 80, 17, "#000000", 1.5)
	add_btn(px_, wy + 100, pw, wh - 142, "page", func(): game.type_chars(4))
	rect(wx, wy + wh - 30, ww, 30, "#e3e0d0")
	var pr = float(G.typed) / full.length()
	txt("Str. 1/1    Slov: " + str(shown.split(" ", false).size()) + "    " + ("✔ Hlášení hotové – ulož a přežij do 6:00" if pr >= 1 else "Ťukej do stránky nebo piš na klávesnici"), wx + 12, wy + wh - 10, 13, "#000000" if pr < 1 else "#007a00")
	rect(wx + ww - 210, wy + wh - 22, 200, 14, "#ffffff")
	rect(wx + ww - 208, wy + wh - 20, 196 * pr, 10, "#37b24d")

func mail_app(wx: float, wy: float, ww: float, wh: float) -> void:
	var G = game.G
	xp_window(wx, wy, ww, wh, "Doručená pošta - Outlook Express", "📧")
	var ms = []
	for n in range(1, G.night + 1):
		for m in game.MAILS[n]:
			ms.append(m)
	ms.reverse()
	rect(wx + 6, wy + 40, 300, wh - 46, "#ffffff")
	for i in ms.size():
		var m = ms[i]
		var y = wy + 44 + i * 52
		if i == G.mail:
			rect(wx + 8, y, 296, 50, "#316ac5")
		var cl = "#ffffff" if i == G.mail else "#000000"
		txt(("✉ " if not G.mailsRead.has(m[1]) else "  ") + m[0], wx + 16, y + 20, 13, cl)
		txt(m[1], wx + 16, y + 40, 12, cl)
		var k = i
		add_btn(wx + 8, y, 296, 50, "m" + str(i), func():
			G.mail = k
			game.audio.sfx("click"))
	var sel = ms[clampi(G.mail, 0, ms.size() - 1)]
	G.mailsRead[sel[1]] = true
	rect(wx + 314, wy + 40, ww - 320, wh - 46, "#ffffff")
	txt("Od: " + sel[0], wx + 330, wy + 66, 14, "#000000")
	txt("Předmět: " + sel[1], wx + 330, wy + 88, 14, "#000000")
	rect(wx + 330, wy + 98, ww - 352, 1, "#a0a0a0")
	wrap_txt(sel[2], wx + 330, wy + 126, ww - 360, 16, "#111111" if sel[0] != "neznámý" and sel[0] != "D." else "#7a0000", 1.5)

func noise_rect(a: float, x: float, y: float, w: float, h: float) -> void:
	if a <= 0:
		return
	draw_texture_rect(noise_frames[randi() % 5], Rect2(x, y, w, h), false, Color(1, 1, 1, minf(1, a) * alpha))

# ---------------------------------------------------------------- extras a dev
func draw_extras(t: float) -> void:
	vignette(0.8)
	rect(0, 0, 520, HH, Color(0, 0.05, 0.02, 0.8))
	txt("★ EXTRAS", 40, 64, 34, "#7dff8a")
	var E = game.EXTRAS[game.ex_i]
	txt(E[0], 40, 130, 30, "#ffffff")
	txt(E[1], 40, 160, 16, "#9fffb0")
	wrap_txt(E[2], 40, 210, 440, 17, "#dddddd", 1.5)
	for i in game.EXTRAS.size():
		var k = i
		btn(40 + (i % 4) * 112, 540 + int(i / 4) * 52, 106, 46, ["HARE", "KROUPA", "BROKEN V.", "SHADOW V.", "SHADOW D.", "SHOŘELÝ", "COCOA"][i], "e" + str(i), func():
			game.ex_i = k
			game.audio.sfx("click"), true, 15, "#ffe46b" if i == game.ex_i else "#5dff8a")
	btn(40, 652, 200, 48, "◀ MENU", "back", game.to_menu, true, 16)

func dev_toggle(x: float, y: float, label: String, key: String) -> void:
	var on: bool = game.DEV[key]
	btn(x, y, 360, 50, ("☑ " if on else "☐ ") + label, "d" + key, func():
		game.DEV[key] = not game.DEV[key]
		game.audio.sfx("click"), true, 17, "#ffb030" if on else "#5dff8a")

func draw_devmenu(t: float) -> void:
	rect(0, 0, HW, HH, Color(0, 0.03, 0.01, 0.9))
	txt("🛠 DEV", 60, 80, 40, "#ffb030")
	dev_toggle(60, 120, "Nesmrtelnost (sanity se neztrácí)", "god")
	dev_toggle(60, 180, "Zmrazit Hollow Hare", "freeze")
	dev_toggle(60, 240, "Zobrazit FPS a pozici zajíce", "fps")
	btn(60, 300, 360, 50, "🔓 Odemknout všech 5 nocí", "unl", func():
		game.st_set("v3_night", 5)
		game.audio.sfx("task"), true, 17)
	txt("Ve hře: tlačítko 🛠 vpravo nahoře otevře rychlý panel.", 60, 400, 16, "#cccccc")
	btn(60, 630, 200, 48, "◀ MENU", "back", game.to_menu, true, 16)

func draw_dev_panel() -> void:
	var G = game.G
	var D = game.DEV
	btn(HW - 74, 100, 50, 40, "🛠", "dpan", func(): D.panel = not D.panel, true, 18, "#ffb030")
	if D.fps:
		txt("FPS " + str(Engine.get_frames_per_second()) + " · zajíc: " + G.hare.node + " → " + G.hare.goal + " · čeká " + str(snappedf(G.hare.wait, 0.1)), HW - 90, 128, 13, "#ffb030", "right")
	if not D.panel:
		return
	rr(HW - 330, 150, 306, 300, 10, Color(0, 0, 0, 0.85), "#ffb030", 2)
	var y = 162
	for a in [["⏩ +1 hodina", func(): G.t = minf(G.t + game.HOUR, game.HOUR * 6 - 1)], ["📄 Dopsat hlášení", func(): G.typed = game.REPORTS[G.night].length()], ["🧠 Sanity 100 %", func(): G.san = 100.0], ["🧠 Sanity 10 %", func(): G.san = 10.0], ["🐰 Zajíc ke dveřím", func(): game.hare_go("DOOR")], ["💀 Jumpscare", game.jumpscare]]:
		btn(HW - 318, y, 282, 40, a[0], "dp" + str(y), a[1], true, 15, "#ffb030")
		y += 46

# ---------------------------------------------------------------- smrt a konce
func draw_scare(t: float) -> void:
	var st: float = game.scene_t
	if st < 0.06:
		rect(0, 0, HW, HH, "#ffffff")
	noise(0.1 + randf() * 0.1)
	if game.G.hurtT > 0:
		rect(0, 0, HW, HH, Color(0.7, 0, 0, game.G.hurtT * 1.6))
	# krev a praskliny po každém úderu
	var hits: int = game.G.get("hits", 0)
	seed(77)
	for i in hits * 3:
		var x = randf() * HW
		var y = randf() * HH
		circle(x, y, 20 + randf() * 60, Color(0.4, 0, 0, 0.55))
	seed(int(game.t_now * 1000))
	if st > 5.2:
		rect(0, 0, HW, HH, Color(0, 0, 0, clampf((st - 5.2) / 1.2, 0, 1)))

func draw_collapse(t: float) -> void:
	var st: float = game.scene_t
	rect(0, 0, HW, HH, Color(0.15, 0.25, 0.0, 0.25 + 0.1 * sin(t * 3)))
	vignette(1.0)
	if st > 1.6:
		rect(0, 0, HW, HH, Color(0, 0, 0, clampf((st - 1.6) / 2.2, 0, 1)))
	if st > 4.6:
		game.S = "dead"
		game.scene_t = 0.0

func draw_custom(t: float) -> void:
	rect(0, 0, HW, HH, Color(0, 0.04, 0.01, 0.88))
	txt("⚙ CUSTOM NIGHT", 60, 80, 40, "#ffb030")
	var rows = [["hare", "Hollow Hare"], ["sv", "Shadow Voxie"], ["sd", "Shadow D."], ["vx", "Broken Voxie (duše Vojtěcha)"]]
	for i in rows.size():
		var k: String = rows[i][0]
		var y = 140 + i * 80
		txt(rows[i][1], 60, y + 34, 22, "#ffffff")
		btn(480, y, 60, 50, "−", "m" + k, func():
			game.CUST[k] = maxi(0, game.CUST[k] - 1)
			game.audio.sfx("click"), true, 24)
		txt(str(game.CUST[k]), 590, y + 36, 30, "#7dff8a", "center")
		btn(640, y, 60, 50, "+", "p" + k, func():
			game.CUST[k] = mini(20, game.CUST[k] + 1)
			game.audio.sfx("click"), true, 24)
	btn(60, 480, 320, 60, "▶ SPUSTIT", "cgo", func(): game.start_night(8), true, 22)
	btn(60, 630, 200, 48, "◀ MENU", "back", game.to_menu, true, 16)

func draw_end7(t: float) -> void:
	var st0: float = game.scene_t
	vignette(0.8)
	rect(0, 0, HW, HH, Color(0.5, 0.12, 0.0, 0.08 + 0.04 * sin(t * 11)))
	if st0 < 1.5:
		rect(0, 0, HW, HH, Color(0, 0, 0, 1 - st0 / 1.5))
	for f in [8.6, 17.6]:
		if absf(st0 - f - 0.4) < 0.4:
			rect(0, 0, HW, HH, Color(0, 0, 0, 1 - absf(st0 - f - 0.4) / 0.4))
	if st0 < 18.0:
		subs()
		btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "e7skip", func(): game.scene_t = 41.5, true, 16)
		return
	var st = st0 - 18.0
	var L = [[2.0, "6:00 AM. Frights & Hides hoří."], [6.0, "Strop se propadl. Zbyly jen sutiny."], [10.0, "V popelu našli hasiči ohořelou kostru springlocku. A uvnitř… člověka."], [15.0, "Pan Kroupa tvrdil, že to byly jen efekty."], [19.0, "D. konečně odpočívá."]]
	var y = 120.0
	for l in L:
		if st > l[0]:
			save_()
			alpha = clampf(st - l[0], 0, 1)
			txt(l[1], HW / 2, y, 24, "#ffd0a0", "center")
			restore_()
		y += 46
	if st > 23:
		neon("KONEC", HW / 2, 480, 70, "#ff5020", 20)
		btn(HW / 2 - 160, 560, 320, 56, "MENU", "menu", game.to_menu, true, 20)
	else:
		btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "e7skip", func(): game.scene_t = 41.5, true, 16)

func draw_end(kind: String) -> void:
	var G = game.G
	rect(0, 0, HW, HH, "#000000")
	noise(0.05)
	if kind == "win":
		txt("6:00 AM", HW / 2, 280, 96, "#ffffff", "center")
		txt(("Přežil jsi noc " + str(G.night) + ". Hlášení odesláno panu Kroupovi.") if G.night < 8 else "Přežil jsi.", HW / 2, 340, 22, "#7dff8a", "center")
		if G.night >= 8:
			txt("Custom Night dokončena.", HW / 2, 390, 20, "#ffe46b", "center")
			btn(HW / 2 - 160, 460, 320, 56, "MENU", "menu", game.to_menu, true, 20)
		else:
			btn(HW / 2 - 160, 440, 320, 56, "▶ NOC " + str(G.night + 1), "next", func(): game.start_night(G.night + 1), true, 22)
			btn(HW / 2 - 160, 508, 320, 48, "MENU", "menu", game.to_menu, true, 18)
	else:
		var T = {"dead": ["KONEC", {"hare": "Hollow Hare tě srazil na zem a umlátil.", "sanity": "Zkolaboval jsi. Mysl to nevydržela.", "voxie": "Hollow Hare roztloukl Broken Voxieho na kusy. Duše pana Vojtěcha zmizela… a pak přišel pro tebe."}.get(G.dead_by, "Konec.")], "fired": ["6:00 AM", "Nesplnil jsi práci (hlášení nebo úkol). Pan Kroupa: „Bez toho žádná výplata. Jste propuštěn.“"]}[kind]
		txt(T[0], HW / 2, 290, 90, "#ff3030" if kind == "dead" else "#ffb060", "center")
		wrap_txt(T[1], HW / 2 - 380, 350, 760, 21, "#dddddd")
		btn(HW / 2 - 160, 450, 320, 56, "↻ ZKUSIT ZNOVU", "retry", func(): game.start_night(G.night), true, 20)
		btn(HW / 2 - 160, 518, 320, 48, "MENU", "menu", game.to_menu, true, 18)

# ---------------------------------------------------------------- vstup
func has_touch() -> bool:
	return DisplayServer.is_touchscreen_available()
func _hit(p: Vector2):
	for i in range(buttons.size() - 1, -1, -1):
		var b: Dictionary = buttons[i]
		if p.x >= b.x and p.x <= b.x + b.w and p.y >= b.y and p.y <= b.y + b.h:
			return b
	return null
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and game.S != "menu":
		game.to_menu()
func _input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var p: Vector2 = e.position / HK
		if e.pressed:
			_down(e.index, p)
		else:
			_up(e.index)
	elif e is InputEventScreenDrag:
		_move(e.index, e.position / HK)
	elif e is InputEventMouseMotion:
		var b = _hit(e.position / HK)
		hover_btn = b.id if b else null
	elif e is InputEventKey:
		_key(e)
func _down(id: int, p: Vector2) -> void:
	var G = game.G
	if game.S == "menu":
		game.audio.start_menu_song()
	var b = _hit(p)
	if b:
		b.cb.call()
		return
	if game.S == "intro" and game.scene_t > 1.0:
		game.scene_t = maxf(game.scene_t, 6.4)
		return
	if game.S == "play" and G.roam:
		if p.x < HW * 0.45:
			joy = {"id": id, "ox": p.x, "oy": p.y, "dx": 0.0, "dy": 0.0}
		else:
			drag = {"id": id, "x": p.x, "y": p.y, "yaw": G.rp.yaw, "pitch": G.rp.pitch, "roam": true}
		return
	if game.S == "play" and not G.mon:
		drag = {"id": id, "x": p.x, "look": G.look}
func _move(id: int, p: Vector2) -> void:
	var G = game.G
	if joy and joy.id == id:
		var dx = (p.x - joy.ox) / 70
		var dy = (p.y - joy.oy) / 70
		var m = Vector2(dx, dy).length()
		if m > 1:
			dx /= m
			dy /= m
		joy.dx = dx
		joy.dy = dy
		return
	if drag and drag.id == id and G and drag.get("roam"):
		G.rp.yaw = drag.yaw - (p.x - drag.x) / HW * 4
		G.rp.pitch = clampf(drag.pitch - (p.y - drag.y) / HH * 2.5, -0.9, 0.7)
		return
	if drag and drag.id == id and G:
		G.lookT = 0.0
		G.look = clampf(drag.look - (p.x - drag.x) / HW * 2.8, game.LOOK_VENT, game.LOOK_DOOR)
func _up(id: int) -> void:
	if joy and joy.id == id:
		joy = null
	if drag and drag.id == id:
		drag = null
func _key(e: InputEventKey) -> void:
	var k = OS.get_keycode_string(e.keycode).to_lower()
	match e.keycode:
		KEY_LEFT: k = "left"
		KEY_RIGHT: k = "right"
		KEY_SPACE: k = " "
	if not e.pressed:
		game.keys[k] = false
		return
	if e.echo:
		return
	game.keys[k] = true
	var G = game.G
	if game.S != "play":
		return
	# při otevřeném Wordu každá klávesa píše hlášení
	if G.roam:
		if k == "f":
			game.sys.act()
		return
	if G.mon and G.app == "word" and k != " ":
		game.type_chars(2)
		return
	if k == " " and not G.blackout:
		game.toggle_mon()
	elif k == "q":
		G.door = not G.door
		game.audio.sfx("clunk", 0.8, -0.8)
	elif k == "e":
		G.vent = not G.vent
		game.audio.sfx("clunk", 0.7, 0.8)
