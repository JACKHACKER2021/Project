extends Control
## HUD NaV4 Nightmare (Godot): stejný kreslicí systém jako NaV2 a NaV3

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
#  NaV4 Nightmare: obrazovky a ovládání
# ====================================================================
var drag = null
var light_id = -1

func btn(x: float, y: float, w: float, h: float, label: String, id: String, cb: Callable, on := true, size := 20.0, col := "#d088ff") -> void:
	var c = Color(col)
	rr(x, y, w, h, 12, (c.darkened(0.35) if hover_btn == id else Color(c.r * 0.25, c.g * 0.2, c.b * 0.3, 0.5)) if on else Color(1, 1, 1, 0.05), c if on else Color("#444444"), 2)
	while size > 9 and tw(label, size) > w - 14:
		size -= 1
	txt(label, x + w / 2, y + h / 2 + size * 0.36, size, "#ffffff" if on else "#666666", "center")
	if on:
		add_btn(x, y, w, h, id, cb)

func _draw() -> void:
	var vs = get_viewport_rect().size
	HW = maxf(960.0, HH * vs.x / vs.y)
	HK = minf(vs.y / HH, vs.x / HW)
	buttons = []
	xf = Transform2D.IDENTITY
	xf_stack = []
	alpha = 1.0
	_apply()
	var t: float = game.t_now
	match game.S:
		"loading": rect(0, 0, HW, HH, "#000000")
		"menu": draw_menu(t)
		"intro": draw_intro()
		"play": draw_play(t)
		"scare": draw_scare(t)
		"dead", "win": draw_end(game.S)

func draw_menu(t: float) -> void:
	rect(0, 0, HW, HH, Color(0.03, 0.0, 0.06, 0.55))
	noise(0.06 + (0.25 if randf() < 0.03 else 0.0))
	vignette(0.95)
	txt("NIGHT AT", 60, 110, 40, "#e0b0ff")
	neon("VOXIE'S 4", 60, 196, 84, "#c040ff", 18, "left")
	neon("NIGHTMARE", 64, 250, 34, "#ff3060", 14, "left")
	txt("PREVIEW 0.2.1", 420, 250, 18, "#ffe46b")
	if game.st_get("v4_end", false):
		txt("★ Všech 7 nocí přežito.", 64, 462, 16, "#ffe46b")
	txt("Ema, jaro 1997. Bouřka. A něco v domě, co umí otevírat dveře.", 64, 290, 17, "#cccccc")
	var un: int = game.st_get("v4_night", 1)
	game.menu_night = mini(game.menu_night, un)
	btn(60, 320, 400, 60, "▶ HRÁT NOC " + str(game.menu_night), "play", func(): game.start_night(game.menu_night), true, 22)
	for i in range(1, 8):
		var n = i
		btn(60 + (i - 1) * 57.5, 392, 51, 46, (str(i) if i <= un else "🔒"), "n" + str(i), func():
			game.menu_night = n
			game.audio.sfx("click"), i <= un, 18, "#ffe46b" if i == game.menu_night else "#d088ff")
	var lines = ["🚪 Dveře vlevo, vpravo a skříň umí otevřít jen noční můry. Ty je otevřít nemůžeš.",
		"👂 Poslouchej kroky na chodbě a vrzání. Když se dveře začnou otevírat, otoč se tam.",
		"🔦 Drž baterku na tom, kdo stojí ve dveřích, dokud necouvne a dveře se nezabouchnou.",
		"🔋 Baterka se vybíjí. Když ji necháš zhasnutou, nabije se.",
		"⛈ Venku je bouřka. Blesk na chvilku rozsvítí pokoj. Přežij do 6:00."]
	for i in lines.size():
		txt(lines[i], 64, 480 + i * 30, 16, "#e8d8f8")
	txt("Nightmare Voxie · Nightmare Hollow Bunny", HW - 24, 680, 14, "#a080c0", "right")
	txt("v0.2.1 preview · Godot", HW - 24, 704, 13, "#666666", "right")

func draw_intro() -> void:
	var st: float = game.scene_t
	rect(0, 0, HW, HH, "#000000")
	save_()
	alpha = clampf(minf(st, 3.0 - st) * 1.6, 0, 1)
	var T = ["", "Duben 1997. Ema se zase budí uprostřed noci.", "Druhá noc. Bouřka nepřestává.", "Třetí noc. Táta pořád není doma.", "Čtvrtá noc. Plyšová Cocoa leží jinak, než jsem ji nechala.", "Pátá noc. Ve skříni je cítit stará látka a olej.", "Šestá noc. Hollow Bunny mi dnes v herně zase zamával.", "Květen 1997. Zítra jdu s tátou do herny."]
	txt(T[game.G.night], HW / 2, 330, 24, "#e0b0ff", "center")
	alpha = clampf(minf(st - 3.0, 6.0 - st) * 1.6, 0, 1)
	txt("0:00", HW / 2, 330, 90, "#ffffff", "center")
	txt("Noc " + str(game.G.night), HW / 2, 400, 40, "#d088ff", "center")
	restore_()
	noise(0.06)

func clock_s() -> String:
	var h: int = game.hour()
	return ("12" if h == 0 else str(h)) + " AM"

func draw_play(t: float) -> void:
	var G = game.G
	vignette(0.75 + G.fear * 0.4)
	if G.flash > 0:
		rect(0, 0, HW, HH, Color(0.75, 0.82, 1.0, 0.12 if fmod(G.flash, 0.12) > 0.05 else 0.0))
	txt(clock_s(), HW - 24, 56, 44, "#ffffff", "right")
	txt("Noc " + str(G.night), HW - 24, 84, 18, "#d088ff", "right")
	# baterka
	rr(24, 24, 220, 24, 6, "#111111")
	var bc = "#ff4040" if G.batLock else ("#ffe46b" if G.bat > 30 else "#ff9040")
	rect(27, 27, 214 * G.bat / 100.0, 18, bc)
	txt("🔦 " + str(ceili(G.bat)) + " %" + ("  (nabíjí se…)" if G.batLock else ""), 254, 42, 16, bc)
	var names = {"left": "LEVÉ DVEŘE", "closet": "SKŘÍŇ", "right": "PRAVÉ DVEŘE", "back": "POSTEL"}
	txt(names[G.view], HW / 2, 46, 22, "#ffffff", "center")
	# ovládání: otáčení a baterka (podržet)
	var by = HH - 110
	btn(24, by, 120, 86, "◀", "tl", func(): game.turn(-1), true, 34)
	btn(HW - 144, by, 120, 86, "▶", "tr", func(): game.turn(1), true, 34)
	var lit_on = G.light and not G.batLock
	rr(HW / 2 - 130, by, 260, 86, 14, Color(1, 0.9, 0.5, 0.35) if lit_on else Color(0.15, 0.1, 0.2, 0.55), "#ffe46b", 3)
	txt("🔦 DRŽ = SVĚTLO", HW / 2, by + 52, 20, "#ffffff", "center")
	add_btn(HW / 2 - 130, by, 260, 86, "light", func(): pass)
	if not has_touch():
		txt("A/D nebo ←/→ otočit · MEZERNÍK nebo F držet baterku", HW / 2, by - 14, 13, "#777777", "center")
	subs()

func subs() -> void:
	var l = game.line
	if l == null:
		return
	var h = 58
	rr(HW / 2 - 360, HH - 190, 720, h, 10, Color(0.05, 0.0, 0.08, 0.75), Color(0.8, 0.5, 1.0, 0.5), 1)
	txt("Ema", HW / 2 - 344, HH - 172, 14, "#ffb0d8")
	txt(l.t, HW / 2, HH - 148, 20, "#ffffff", "center")

func draw_scare(t: float) -> void:
	if game.scene_t < 0.08:
		rect(0, 0, HW, HH, "#ffffff")
	noise(0.12 + randf() * 0.12)
	if game.scene_t > 1.6:
		rect(0, 0, HW, HH, Color(0, 0, 0, clampf((game.scene_t - 1.6) / 0.8, 0, 1)))

func draw_end(kind: String) -> void:
	var G = game.G
	rect(0, 0, HW, HH, "#000000")
	noise(0.05)
	if kind == "win":
		txt("6:00 AM", HW / 2, 270, 96, "#ffffff", "center")
		txt("Zazvonil budík. Ema se probudila ve své posteli.", HW / 2, 330, 22, "#ffb0d8", "center")
		txt("„Už je ráno. Byl to jen sen.“", HW / 2, 366, 20, "#cccccc", "center")
		if G.night < 7:
			btn(HW / 2 - 160, 430, 320, 56, "▶ NOC " + str(G.night + 1), "next", func(): game.start_night(G.night + 1), true, 22)
		else:
			txt("Druhý den Ema v herně zmizela. Policie ji hledala celé jaro.", HW / 2, 404, 18, "#ff8ab8", "center")
			txt("Konec preview. Co se s Emou stalo, se dozvíš v minihrách.", HW / 2, 432, 16, "#ffe46b", "center")
		btn(HW / 2 - 160, 500, 320, 48, "MENU", "menu", game.to_menu, true, 18)
	else:
		txt("PROBUDILA SES S KŘIKEM", HW / 2, 280, 54, "#ff3060", "center")
		txt(("Nightmare Voxie otevřel dveře." if G.dead_by == "vox" else "Nightmare Hollow Bunny vylezl ze skříně."), HW / 2, 340, 22, "#dddddd", "center")
		btn(HW / 2 - 160, 420, 320, 56, "↻ ZKUSIT ZNOVU", "retry", func(): game.start_night(G.night), true, 20)
		btn(HW / 2 - 160, 488, 320, 48, "MENU", "menu", game.to_menu, true, 18)

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
	if game.S == "menu":
		game.audio.start_menu_song()
	var b = _hit(p)
	if b and b.id == "light":
		game.G.light = true
		light_id = id
		game.audio.sfx("click", 0.4)
		return
	if b:
		b.cb.call()
		return
	if game.S == "intro" and game.scene_t > 1.0:
		game.scene_t = maxf(game.scene_t, 6.0)
		return
	if game.S == "play":
		drag = {"id": id, "x": p.x}
func _move(id: int, p: Vector2) -> void:
	if drag and drag.id == id and game.S == "play":
		var dx = p.x - drag.x
		if absf(dx) > 110:
			game.turn(-1 if dx > 0 else 1)
			drag.x = p.x
func _up(id: int) -> void:
	if drag and drag.id == id:
		drag = null
	if light_id == id and game.G:
		game.G.light = false
		light_id = -1
func _key(e: InputEventKey) -> void:
	var k = OS.get_keycode_string(e.keycode).to_lower()
	match e.keycode:
		KEY_LEFT: k = "a"
		KEY_RIGHT: k = "d"
		KEY_SPACE: k = "f"
	if game.S != "play":
		return
	if k == "f":
		game.G.light = e.pressed
		return
	if not e.pressed or e.echo:
		return
	if k == "a":
		game.turn(-1)
	elif k == "d":
		game.turn(1)
