extends Control
## HUD Remasteru – port 2D kreslení (drawHUD, menu, kamery, minihry, extras, DEV) a dotykového ovládání.

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
var EX = {"song": 0, "page": "chars", "idx": 0, "rot": 0.0, "scare": -1.0, "room": null}
var M = null
var news_secret = false
var tint_k = 0.0
var drag = null
var touches = {}
var dev_fps = 60
var dev_fpsT = 0.0
var dev_frames = 0
var NEWS_WIN = []

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
	# deterministické okna hořící budovy (NEWS_R se seedem 614)
	var sd = 614
	for i in 14:
		sd = (sd * 16807) % 2147483647
		NEWS_WIN.append(sd / 2147483647.0)

# ====================================================================
#  KRESLICÍ POMŮCKY (rect/rr/txt/neon/wrap/noise/scanlines/vignette)
# ====================================================================
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

func big_btn(x: float, y: float, w: float, h: float, label: String, id: String, cb: Callable, enabled := true, size := 22.0) -> void:
	var hov = hover_btn == id and enabled
	var fill: Color = (Color("#ff2bd6") if hov else Color(1, 0.17, 0.84, 0.2)) if enabled else Color(1, 1, 1, 0.05)
	rr(x, y, w, h, 12, fill, Color("#ff2bd6") if enabled else Color("#444444"), 2)
	while size > 9 and tw(label, size) > w - 16:
		size -= 1
	txt(label, x + w / 2, y + h / 2 + size * 0.36, size, "#ffffff" if enabled else "#666666", "center")
	if enabled:
		add_btn(x, y, w, h, id, cb)

func round_btn(x: float, y: float, r: float, on: bool, on_col: String, off_col: String, label: String, id: String, cb: Callable) -> void:
	circle(x, y, r + 6, Color(0.04, 0.024, 0.063, 0.75))
	if on:
		var c = Color(on_col)
		for i in 4:
			circle(x, y, r + 10 - i * 2, Color(c.r, c.g, c.b, 0.1))
	circle(x, y, r, on_col if on else off_col)
	txt(label, x, y + r + 22, 15, "#e8e0f0", "center")
	add_btn(x - r - 12, y - r - 12, r * 2 + 24, r * 2 + 40, id, cb)

func draw_logo(x: float, y: float, s: float, ring_ := true) -> void:
	var u = s / 16
	var R = func(a: float, b: float, w: float, h: float, col: String): rect(x + a * u, y + b * u, w * u, h * u, col)
	if ring_:
		var cc = Vector2(x + s / 2, y + s / 2)
		for i in 4:
			draw_arc(cc, s * 0.47, 0, TAU, 96, C(Color(1, 0.17, 0.84, 0.18)), s * 0.045 + (4 - i) * 4, true)
		draw_arc(cc, s * 0.47, 0, TAU, 96, C("#ff2bd6"), s * 0.045, true)
		draw_arc(cc, s * 0.42, 0, TAU, 96, C("#7ff4ff"), s * 0.015, true)
	R.call(2.6, 2.4, 3.2, 3.2, "#5a3716"); R.call(10.2, 2.4, 3.2, 3.2, "#5a3716"); R.call(3.4, 3.2, 1.6, 1.6, "#e88aa0"); R.call(11, 3.2, 1.6, 1.6, "#e88aa0")
	R.call(3, 4.4, 10, 8.6, "#8a5a2b"); R.call(3, 4.4, 10, 1, "#a8703a"); R.call(12, 4.4, 1, 8.6, "#6a4220")
	R.call(4.4, 6.6, 2.6, 2.6, "#f2f2ea"); R.call(9, 6.6, 2.6, 2.6, "#f2f2ea"); R.call(5.4, 7.4, 1.2, 1.4, "#111111"); R.call(10, 7.4, 1.2, 1.4, "#111111")
	R.call(5.6, 9.6, 4.8, 2.8, "#d6a064"); R.call(7.1, 9.8, 1.8, 1.1, "#2a1608"); R.call(6.4, 11.6, 3.2, 0.5, "#5a3716")
	R.call(4.8, 13.2, 2.8, 1.8, "#ff2bd6"); R.call(8.4, 13.2, 2.8, 1.8, "#ff2bd6"); R.call(7.4, 13.5, 1.2, 1.2, "#b0108f")

# ====================================================================
#  HLAVNÍ KRESLENÍ
# ====================================================================
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
	var sc: String = g.scene_
	if sc in ["dayend", "loading", "intro", "dead", "win", "ending", "mini", "secret", "news"]:
		rect(0, 0, HW, HH, "#000000")
	if sc == "loading":
		draw_logo(HW / 2 - 90, 180, 180)
		txt("Načítám herna Voxie's…", HW / 2, 430, 22, "#ff8bea", "center")
	elif sc == "menu":
		draw_menu(t)
	elif sc == "intro":
		draw_intro()
	elif sc == "play":
		var G = g.G
		if G.camA > 0 and G.camA < 1:
			var y = HH * (1 - G.camA)
			rr(60, y + 20, HW - 120, HH, 24, "#1b1b1f")
			rect(90, y + 50, HW - 180, HH, "#000000")
			txt("VOXIE-CAM", HW / 2, y + 90, 22, "#5dff8a", "center")
		if g.roam.on:
			draw_roam_hud(t)
		else:
			draw_hud(t)
		pizza_hud(t)
		draw_dev(t)
	elif sc == "mini":
		draw_mini(t)
	elif sc == "scare" and g.scare_kind == "dark":
		noise(0.2 + randf() * 0.2)
		if g.scare_t > 1.0:
			rect(0, 0, HW, HH, Color(0, 0.35, 0.08, 0.55) if int(floor(g.scare_t * 14)) % 2 else Color(0, 0, 0, 0.95))
	elif sc == "scare":
		if g.scare_t < 0.05:
			rect(0, 0, HW, HH, "#ffffff")
		noise(0.12 + randf() * 0.15)
		if g.scare_t > 1.0:
			rect(0, 0, HW, HH, Color(1, 0, 0, 0.75) if int(floor(g.scare_t * 20)) % 2 else Color(0, 0, 0, 0.9))
	elif sc == "news":
		draw_news(t)
	elif sc == "custom":
		draw_custom(t)
	elif sc == "extras":
		draw_extras(t)
	elif sc == "devmenu":
		draw_dev_menu(t)
	elif sc == "secret":
		draw_secret()
	elif sc == "dayend":
		draw_dayend()
	elif sc == "dead":
		draw_dead()
	elif sc == "win":
		draw_win()
	elif sc == "ending":
		draw_ending()

func clock_str(h: int) -> String:
	if game.G.get("day"):
		return str(9 + int(game.G.t / 60.0)) + ":" + ("%02d" % (int(game.G.t) % 60))
	if game.G.night == 4:
		return str(12 if h == 0 else h) + " AM"
	return ("0" if h == 0 else str(h)) + ":00"

func night_name() -> String:
	if game.G.get("day"):
		return "Den " + str(game.G.day)
	return "Vlastní noc" if game.G.night == 8 else "Noc " + str(game.G.night)

func draw_map() -> void:
	var G = game.G
	var sc = 1.1
	var mx = HW - 440 * sc + 10
	var my = 360.0
	save_()
	translate(mx, my)
	scale_(sc, sc)
	rr(-10, -10, 410, 295, 10, Color(0, 0, 0, 0.6))
	for l in game.T.LINKS:
		var A: Array = game.T.MAP[l[0]]
		var B: Array = game.T.MAP[l[1]]
		line(A[0] + A[2] / 2, A[1] + A[3] / 2, B[0] + B[2] / 2, B[1] + B[3] / 2, Color(1, 1, 1, 0.25), 6)
	for id in game.T.MAP:
		var r: Array = game.T.MAP[id]
		var sel: bool = G.cam == id
		rect(r[0], r[1], r[2], r[3], "#3a2650" if id == "TY" else ("#222222" if id == "X" else ("#1f8a3a" if sel else "#2a2a34")))
		draw_rect(Rect2(r[0], r[1], r[2], r[3]), C("#7cff6b" if sel else "#888888"), false, 2)
		txt("TY" if id == "TY" else ("🔒" if id == "X" else "CAM " + id), r[0] + r[2] / 2, r[1] + r[3] / 2 + 6, 14, "#ffffff" if sel else "#cccccc", "center")
		if game.CAMS.has(id):
			var cid: String = id
			add_btn(r[0], r[1], r[2], r[3], "cam" + id, func(): game.select_cam(cid))
	restore_()

func draw_speech() -> void:
	var sp = game.speech
	var G = game.G
	if not sp or sp.t > sp.dur:
		return
	if sp.who != "phone" and not sp.heard:
		return
	var phone: bool = sp.who == "phone"
	var name: String = "☎ Bývalý hlídač" if phone else sp.who
	var bw = minf(720, HW - 560)
	var bx = (24.0 if (G and G.cams) else HW / 2 - bw / 2) if phone else HW / 2 - bw / 2
	var ls = wrapt(sp.text, bw - 30, 20)
	var bh = ls.size() * 26 + 44.0
	var by: float
	if phone and not (G and game.roam.on):
		by = (640 - bh) if (G and G.cams) else (642 - bh)
	else:
		by = 96.0 if (G and G.task and G.task.step < 5) else 92.0
	save_()
	alpha = minf(1, (sp.dur - sp.t) * 3)
	var col: Color = sp.col
	rr(bx, by, bw, bh, 10, Color(0, 0, 0, 0.75), Color(col.r, col.g, col.b, 0.53), 2)
	txt(name, bx + 16, by + 26, 17, col)
	for i in ls.size():
		txt(ls[i], bx + bw / 2, by + 52 + i * 26, 20, "#ffffff", "center")
	restore_()

func draw_hud(t: float) -> void:
	var G = game.G
	var h: int = game.hour_of()
	if G.cams and G.camA >= 1:
		scanlines()
		noise(0.05 + G.camStatic * 0.5 + (0.15 if randf() < 0.015 else 0.0))
		if G.camStatic > 0.9:
			rect(0, 0, HW, HH, Color(0, 0, 0, 0.5))
		vignette(0.6)
		for c in [[20, 20, 1, 1], [HW - 20, 20, -1, 1], [20, HH - 20, 1, -1], [HW - 20, HH - 20, -1, -1]]:
			draw_polyline(PackedVector2Array([Vector2(c[0], c[1] + 40 * c[3]), Vector2(c[0], c[1]), Vector2(c[0] + 40 * c[2], c[1])]), C(Color(1, 1, 1, 0.5)), 3)
		if sin(t * 4) > 0:
			circle(46, 213, 9, "#ff2020")
		txt("REC", 64, 220, 20, "#ffffff")
		txt("CAM " + G.cam, 30, 150, 34, "#ffffff")
		txt(game.CAMS[G.cam].name, 30, 180, 22, "#ccffee")
		draw_map()
	elif not G.out:
		vignette(0.55)
		if G.flick > 0:
			rect(0, 0, HW, HH, Color(0, 0, 0, minf(1, G.flick * 2.5)))
		round_btn(70, 300, 30, G.doorL, "#ff3b3b", "#4a1414", "DVEŘE", "doorL", func(): game.toggle_door("L"))
		round_btn(70, 410, 30, G.light == "L", "#fff3c4", "#3a3a3a", "SVĚTLO", "lightL", func(): game.set_light("L"))
		round_btn(HW - 70, 300, 30, G.doorR, "#ff3b3b", "#4a1414", "DVEŘE", "doorR", func(): game.toggle_door("R"))
		round_btn(HW - 70, 410, 30, G.light == "R", "#fff3c4", "#3a3a3a", "SVĚTLO", "lightR", func(): game.set_light("R"))
		for ar in [[130.0, 1.0, "lookL"], [HW - 176, -1.0, "lookR"]]:
			var dir: float = ar[1]
			rr(ar[0], 300, 46, 120, 10, Color(0.5, 0.96, 1, 0.3 if hover_btn == ar[2] else 0.1))
			txt("◀" if dir < 0 else "▶", ar[0] + 23, 370, 26, "#bbffff", "center")
			add_btn(ar[0], 300, 46, 120, ar[2], func(): game.look_target = clampf((game.look_target if game.look_target != null else game.G.look) + dir * 0.95, -1.15, 1.15))
	else:
		rect(0, 0, HW, HH, Color(0, 0, 0, 0.15))
	txt(night_name(), 24, 42, 26, "#ffffff")
	txt(clock_str(h), HW - 24, 54, 46, "#ffffff", "right")
	if not G.out:
		txt("Proud: " + str(maxi(0, ceili(G.power))) + " %", 24, 662, 24, "#ff6b6b" if G.power < 20 else "#ffffff")
		txt("Spotřeba:", 24, 694, 20, "#cccccc")
		var u: int = game.usage()
		var cols = ["#4cff6b", "#4cff6b", "#ffe46b", "#ff9b3b", "#ff3b3b"]
		for i in 5:
			rect(140 + i * 26, 676, 20, 22, cols[i] if i < u else "#2a2a2a")
		var bx = HW / 2 - 240
		rr(bx, 664, 480, 46, 10, Color(0.5, 0.96, 1, 0.35 if hover_btn == "cams" else 0.15), "#7ff4ff", 2)
		txt("▼  ZAVŘÍT KAMERY  ▼" if G.cams else "▲  KAMERY  ▲", HW / 2, 695, 22, "#e8fdff", "center")
		add_btn(bx, 656, 480, 64, "cams", game.toggle_cams)
	if not G.cams and not G.out:
		big_btn(24, 590, 250, 44, "🚶 ODEJÍT OD STOLU", "roam", game.toggle_roam, true, 18)
	draw_task()
	draw_dialog()
	if G.sysMsg > 0:
		rr(HW / 2 - 230, 600, 460, 46, 10, Color(0.47, 0, 0, 0.8))
		txt("⚠ SIGNÁL KAMER ZTRACEN", HW / 2, 631, 22, "#ffffff", "center")
	if G.call.on:
		big_btn(24, 60, 170, 40, "ZAVĚSIT ✆", "hang", game.hang_up, true, 20)
		if G.call.ring > 0:
			txt("☎ Volá: Bývalý hlídač...", 210, 88, 20, "#ffe46b")
	draw_speech()

func draw_roam_hud(t: float) -> void:
	var G = game.G
	var roam: Dictionary = game.roam
	vignette(0.7)
	var jx = 150.0
	var jy = 560.0
	circle(jx, jy, 90, Color(1, 1, 1, 0.08))
	ring(jx, jy, 90, Color(0.5, 0.96, 1, 0.5), 3)
	var kx: float = jx + (roam.joy.dx * 70 if roam.joy else 0.0)
	var ky: float = jy + (roam.joy.dy * 70 if roam.joy else 0.0)
	circle(kx, ky, 38, Color(0.5, 0.96, 1, 0.35))
	rr(24, 96, 220, 14, 6, Color(0, 0, 0, 0.6))
	rect(26, 98, 216 * roam.stamina, 10, "#ff5050" if roam.tired else ("#ffb030" if roam.stamina < 0.3 else "#5dff8a"))
	txt("Zadýchaný…" if roam.tired else "Stamina", 250, 108, 14, "#cccccc")
	var sprint_on: bool = roam.sprint and not roam.tired
	rr(HW - 230, 380, 95, 70, 12, "#ff2bd6" if sprint_on else Color(1, 0.17, 0.84, 0.2), "#ff2bd6", 2)
	txt("🏃", HW - 182, 425, 30, "#ffffff", "center")
	add_btn(HW - 230, 380, 95, 70, "sprint", func(): pass)
	big_btn(HW - 125, 380, 95, 70, "▲", "jump", game.roam_jump, true, 34)
	big_btn(HW - 230, 520, 200, 50, "🔦 BATERKA: ZAP" if roam.flash else "🔦 BATERKA: VYP", "flash", func():
		if not game.G.out:
			game.roam.flash = not game.roam.flash
			game.audio.sfx("click"), not G.out, 18)
	if game.near_desk() and not G.get("day"):
		big_btn(HW - 230, 590, 200, 50, "🪑 KE STOLU", "desk", game.toggle_roam, true, 18)
	if game.can_hit():
		big_btn(HW / 2 - 210, 500, 420, 64, "🪓 ÚDER (" + str(G.hits) + "/3)", "hit", game.hit_voxie, true, 24)
	var it = game.near_inter()
	if it:
		big_btn(HW / 2 - 210, 580, 420, 56, it.label, "inter", game.interact, true, 19)
	elif game.can_talk():
		big_btn(HW / 2 - 210, 580, 420, 56, "💬 MLUVIT S COCOU", "talk", game.open_dialog, true, 19)
	txt(night_name(), 24, 42, 26, "#ffffff")
	txt(clock_str(game.hour_of()), HW - 24, 54, 46, "#ffffff", "right")
	if not G.out and not G.get("day"):
		txt("Proud: " + str(maxi(0, ceili(G.power))) + " %", 24, 80, 22, "#ff6b6b" if G.power < 20 else "#ffffff")
	var rid = game.room_at(roam.pos.x, roam.pos.z)
	txt("Kancelář" if rid == "OFF" else (game.CAMS[rid].name if rid != null and game.CAMS.has(rid) else ""), HW / 2, 40, 22, "#ccffee", "center")
	draw_task()
	draw_speech()
	draw_dialog()
	if roam.msgT > 0:
		save_()
		alpha = minf(1, roam.msgT)
		var ls = wrapt(roam.msg, 640, 20)
		rr(HW / 2 - 340, 480 - ls.size() * 26, 680, ls.size() * 26 + 20, 10, Color(0, 0, 0, 0.7))
		for i in ls.size():
			txt(ls[i], HW / 2, 503 - ls.size() * 26 + i * 26, 20, "#ffe46b", "center")
		restore_()

var bar_y = 52.0
func bar(label: String, k, col: String) -> void:
	rr(HW / 2 - 260, bar_y, 520, 34, 8, Color(0.16, 0.04, 0.12, 0.78))
	if k != null:
		rect(HW / 2 - 256, bar_y + 28, 512 * clampf(k, 0, 1), 4, col)
	txt(label, HW / 2, bar_y + 23, 17, col, "center")
	bar_y += 40

func rep_clock(h: int) -> String:
	return str(12 if h == 0 else h) + " AM"

func draw_task() -> void:
	var G = game.G
	if G.get("day"):
		bar_y = 52.0
		if G.work and String(G.work.id).begins_with("d_"):
			var Wd: Dictionary = game.WORK[G.work.id]
			bar("🔧 " + Wd.label + ": " + str(int(G.work.prog / Wd.need * 100)) + " %", G.work.prog / Wd.need, "#7ff4ff")
		else:
			var tt: String = game.day.task_text()
			if tt != "":
				bar(tt, null, "#ffd28a")
		return
	if G.rep:
		rep_hud()
	bar_y = 52.0
	if G.rep:
		rep_bars()
	var W: Dictionary = game.WORK if not game.WORK.is_empty() else game.T.WORK
	if G.coc.broken and not G.rep:
		var on: bool = G.work != null and G.work.id == "repair"
		bar("🔧 Oprava Cocoy: " + str(int(G.work.prog / W.repair.need * 100)) + " % (zůstaň u ní)" if on else "🔧 Úkol: oprav Cocou ve skladu (CAM 4) – Voxie je dnes vypnutý", G.work.prog / W.repair.need if on else null, "#9fe8ff")
	if G.sys and G.sys.broken:
		var on: bool = G.work != null and G.work.id == "server"
		bar("🖥 Restart serveru: " + str(int(G.work.prog / W.server.need * 100)) + " %" if on else "⚠ KAMERY OFFLINE – restartuj server ve vchodu (CAM 7)", G.work.prog / W.server.need if on else null, "#ff6b6b")
	if false:
		bar("🪓 Ve skladu (CAM 4) je sekera… nebo jen vydrž do 6:00", null, "#ffb0b0")
	if G.axe:
		bar("🪓 Sekera: " + str(G.hits) + "/3 zásahů", G.hits / 3.0, "#ff6b6b")
	var Tk = G.task
	if not Tk or Tk.step >= 5:
		return
	var msg: String = ["Úkol: jdi do Pizzerie (CAM 2) a přijmi objednávku", "Úkol: vlož pizzu do pece v Pizzerii", "Peče se: " + str(ceili(20 - Tk.bake)) + " s", "Úkol: vezmi hotovou pizzu z pece", "Úkol: odnes pizzu ke stolu v kanceláři"][Tk.step]
	bar("🍕 " + msg, null, "#ffd28a")

func rep_bars() -> void:
	var G = game.G
	var R = G.rep
	if not R or R.done:
		return
	var h: int = game.hour_of()
	if G.work and String(G.work.id).begins_with("rep_"):
		var Wd: Dictionary = game.WORK[G.work.id]
		bar("🔧 " + Wd.label + ": " + str(int(G.work.prog / Wd.need * 100)) + " % (zůstaň u místa)", G.work.prog / Wd.need, "#7ff4ff")
		return
	var obj: String = ["🔎 Zkontroluj Cocu ve skladu (CAM 4)", "🔌 Odpoj napájení a otevři hrudní panel", "📦 Najdi polovodič VX84 (TO-247) v bednách", "🔩 Zamontuj polovodič do Cocoy", "📟 Kalibruj napětí", "⚡ Restartuj Cocu"][R.st]
	var mh: int = game.T.REP_MINH[R.st]
	if h < mh:
		bar("⏳ Počkej do " + rep_clock(mh) + " – " + ("díl musí vychladnout" if R.st == 3 else "systém se ustaluje"), fmod(G.t, game.HOUR) / game.HOUR, "#ffd28a")
	else:
		bar(obj + (" · " + str(R.searched.size()) + "/3" if R.st == 2 else ""), null, "#7ff4ff")

func rep_hud() -> void:
	var R = game.G.rep
	rr(24, 116, 150, 74, 10, Color(0, 0, 0, 0.6), "#7ff4ff" if R.chip else "#444444", 2)
	txt("INVENTÁŘ", 99, 136, 14, "#aaaaaa", "center")
	if R.chip:
		rect(70, 146, 36, 30, "#222222")
		rect(70, 146, 36, 8, "#99aaaa")
		for i in 3:
			rect(75 + i * 11, 176, 4, 10, "#d8c27a")
		txt("VX84", 126, 166, 14, "#7ff4ff")
	else:
		txt("prázdné", 99, 168, 15, "#666666", "center")
	if R.pick:
		game.roam.msgT = 0.0
		rect(0, 0, HW, HH, Color(0, 0, 0, 0.72))
		txt("VYBER SPRÁVNÝ POLOVODIČ", HW / 2, 214, 32, "#7ff4ff", "center")
		txt("Na desce svítilo: VX84 · TO-247. Špatný díl způsobí zkrat.", HW / 2, 250, 18, "#ffc9a0", "center")
		for i in R.parts.size():
			var p: Dictionary = R.parts[i]
			big_btn(HW / 2 - 230, 280 + i * 84, 460, 72, p.name + " · " + p.sub, "part" + p.id, func(): game.rep_pick(p), not R.bad.has(p.id), 20)

func pizza_hud(t: float) -> void:
	var G = game.G
	if not G:
		return
	if G.pzMsgT > 0:
		rr(HW / 2 - 330, 90, 660, 44, 10, Color(0, 0, 0, 0.75))
		txt(G.pzMsg, HW / 2, 120, 20, "#ffc9a0", "center")
	if not G.pz or G.pz.ph != "pizza" or G.out or G.cams:
		return
	var cam: Camera3D = game.roam_cam if game.roam.on else game.office_cam
	var wp: Vector3 = game.coco_pizza.global_position
	if not cam.is_position_behind(wp):
		var s: Vector2 = cam.unproject_position(wp) / HK
		if s.x > 0 and s.x < HW and s.y > 0 and s.y < HH:
			txt("▼", s.x, s.y - 60 + sin(t * 6) * 8, 30, "#ffe46b", "center")
			add_btn(s.x - 80, s.y - 90, 160, 160, "pizza", game.take_pizza)
	big_btn(HW / 2 - 130, 600, 260, 52, "🍕 VZÍT PIZZU", "pizzaB", game.take_pizza, true, 20)

func draw_dialog() -> void:
	var G = game.G
	if not G or not G.dialog:
		return
	var n: Dictionary = game.T.DIALOG[G.dialog]
	var bw = minf(860, HW - 120)
	var bx = HW / 2 - bw / 2
	var ls = wrapt(n.t, bw - 40, 21)
	var bh = ls.size() * 28 + 70 + n.o.size() * 58.0
	var by = HH / 2 - bh / 2 - 20
	rr(bx, by, bw, bh, 14, Color(0.08, 0.03, 0.06, 0.9), "#ffc9a0", 2)
	txt("💬 Cocoa", bx + 20, by + 32, 19, "#ffc9a0")
	for i in ls.size():
		txt(ls[i], bx + bw / 2, by + 66 + i * 28, 21, "#ffffff", "center")
	for i in n.o.size():
		var nx = n.o[i][1]
		big_btn(bx + 30, by + 80 + ls.size() * 28 + i * 58, bw - 60, 48, str(i + 1) + ") " + n.o[i][0], "dlg" + str(i), func(): game.choose(nx), true, 19)

# ---------- menu a obrazovky ----------
func draw_menu(t: float) -> void:
	scanlines()
	noise(0.12 + (0.3 if randf() < 0.05 else 0.0))
	vignette(0.85)
	for i in 32:
		rect(i * 20, 0, 20, HH, Color(0, 0, 0, 0.88 * (1 - i / 32.0)))
	draw_logo(50, 28, 150)
	neon("NIGHT AT", 220, 92, 40, "#7ff4ff", 14, "left")
	neon("VOXIE'S", 220, 168, 80, "#ff2bd6", 26, "left")
	txt("Voxie's Fun Factory · zavřeno od 14. 6. 1997", 222, 200, 16, "#cccccc")
	var pulse = 0.75 + 0.25 * sin(t * 2.4)
	save_()
	translate(590, 96)
	rotate_(-0.07)
	rr(-8, -34, 250, 62, 10, Color(0.08, 0.03, 0.13, 0.82))
	rr(-8, -34, 250, 62, 10, null, Color(1, 0.89, 0.42, pulse), 2)
	neon("★ REMASTERED", 117, -6, 30, "#ffe46b", 12, "center")
	txt("vylepšená verze", 117, 18, 15, "#ffd9f6", "center")
	restore_()
	var pr: int = game.progress
	big_btn(60, 228, 420, 50, "NOVÁ HRA", "new", func(): game.start_night(1))
	big_btn(60, 288, 420, 50, "POKRAČOVAT · NOC " + str(pr), "cont", func(): game.start_night(game.progress), pr > 1)
	txt("Výběr noci:", 64, 364, 17, "#aaaaaa")
	for n in range(1, 8):
		var nn = n
		big_btn(60 + (n - 1) * 60, 372, 52, 44, str(n) if n <= pr else "🔒", "n" + str(n), func(): game.start_night(nn), n <= pr)
	txt("Animatronici: Voxie + Cocoa", 64, 440, 16, "#ffb3f0")
	var n7: bool = game.st_get("voxies_n7", false)
	big_btn(500, 228, 160, 50, "★ EXTRAS", "extras", func():
		game.scene_ = "extras"
		game.scene_t = 0.0
		EX.page = "chars"
		EX.scare = -1.0, true, 18)
	big_btn(500, 288, 160, 50, "🛠 DEV", "devm", func():
		game.scene_ = "devmenu"
		game.scene_t = 0.0, true, 18)
	big_btn(60, 506, 420, 44, "⚙ VLASTNÍ NOC" if n7 else "🔒 Vlastní noc (po 7. noci)", "custom", func():
		game.scene_ = "custom"
		game.scene_t = 0.0, n7, 18)
	if game.beaten:
		txt("★ Přežil jsi 5 nocí" + (" · noci 6–7 odemčeny" if pr >= 7 else ""), 64, 560, 18, "#ffe46b")
	if game.st_get("voxies_secret", false):
		txt("🪓 Tajný konec: Osvobození", 64, 584, 18, "#ff6b6b")
	txt("v2.7.0 Remastered · Godot", HW - 20, 700, 14, "#888888", "right")
	txt("Táhni prstem = rozhlížení · Joystick = chůze mimo stůl · Q/E světla, A/D dveře, mezerník kamery, F baterka", 64, 700, 13, "#777777")

func draw_intro() -> void:
	var G = game.G
	save_()
	alpha = clampf(minf(game.scene_t, 3 - game.scene_t) * 1.5, 0, 1)
	txt("0:00", HW / 2, 330, 90, "#ffffff", "center")
	txt(night_name(), HW / 2, 400, 40, "#ff8bea", "center")
	restore_()
	noise(0.05)

func draw_dead() -> void:
	var G = game.G
	noise(maxf(0.15, 0.9 - game.scene_t))
	if game.scene_t < 1:
		return
	txt("KONEC HRY", HW / 2, 250, 72, "#ff3b3b", "center")
	var kd: Dictionary = game._ai_def(game.killer.id if game.killer else "V")
	txt("Došel proud… a Voxie si tě našel." if G.out else kd.ch.name + " tě " + ("našla" if kd.f else "našel") + ".", HW / 2, 310, 26, "#ffffff", "center")
	if G.tip == null:
		G.tip = game.pick(game.T.TIPS)
	var ls = wrapt("Tip: " + G.tip, 800, 18)
	for i in ls.size():
		txt(ls[i], HW / 2, 360 + i * 24, 18, "#aaaaaa", "center")
	big_btn(HW / 2 - 200, 440, 400, 56, "ZKUSIT ZNOVU", "retry", func(): game.new_game(game.G.night))
	big_btn(HW / 2 - 200, 512, 400, 56, "MENU", "menu", game.to_menu)

func draw_win() -> void:
	var G = game.G
	var roll = clampf((game.scene_t - 0.6) / 0.8, 0, 1)
	# výřez: čísla mimo okno zakryjeme
	txt("5:00", HW / 2, 310 - roll * 140, 100, "#ffffff", "center")
	txt("6:00", HW / 2, 450 - roll * 140, 100, "#ffffff", "center")
	rect(0, 0, HW, 200, "#000000")
	rect(0, 340, HW, HH - 340, "#000000")
	if game.scene_t > 2:
		txt("Vlastní noc přežita! (" + str(game.CUSTOM.v) + "/" + str(game.CUSTOM.c) + ")" if G.night == 8 else "Noc " + str(G.night) + " přežita!", HW / 2, 400, 34, "#ffe46b", "center")
		if G.night == 8:
			big_btn(HW / 2 - 200, 460, 400, 56, "ZNOVU", "again", func(): game.new_game(8))
		elif G.night == 5 or G.night == 7:
			big_btn(HW / 2 - 200, 460, 400, 56, "POKRAČOVAT", "end", func():
				game.scene_ = "ending"
				game.scene_t = 0.0)
		else:
			big_btn(HW / 2 - 200, 460, 400, 56, "DALŠÍ NOC", "next", func(): game.start_night(game.G.night + 1))
		big_btn(HW / 2 - 200, 532, 400, 56, "MENU", "menu", game.to_menu)

func draw_secret() -> void:
	rect(0, 0, HW, HH, "#050206")
	noise(0.06)
	var S: Array = game.T.SECRET
	for i in S.size():
		if game.scene_t > 1 + i * 3:
			var last = i == S.size() - 1
			var ws = wrapt(S[i], 900, 40 if last else 24)
			for k in ws.size():
				if last:
					neon(ws[k], HW / 2, 230 + i * 80 + k * 30, 40, "#ff2bd6", 20)
				else:
					txt(ws[k], HW / 2, 190 + i * 80 + k * 30, 24, "#ffffff", "center")
	if randf() < 0.03:
		rect(0, 0, HW, HH, Color(1, 0.78, 0.47, 0.06))
	if game.scene_t > 1 + S.size() * 3:
		big_btn(HW / 2 - 200, 600, 400, 56, "POKRAČOVAT", "news", func(): game.go_news(true))

func draw_news(t: float) -> void:
	rect(0, 0, HW, HH, "#0a0608")
	var k: float = game.ease_io(clampf(game.scene_t / 1.6, 0, 1))
	var cx = HW / 2
	save_()
	translate(cx, HH / 2)
	rotate_((1 - k) * -0.25 - 0.02)
	scale_(0.6 + 0.4 * k, 0.6 + 0.4 * k)
	translate(-cx, -HH / 2)
	var x0 = cx - 430
	var y0 = 30.0
	var w = 860.0
	var h = 660.0
	rect(x0 + 8, y0 + 10, w, h, Color(0, 0, 0, 0.5))
	rect(x0, y0, w, h, "#e6dfcb")
	txt("VEČERNÍ ZPRAVODAJ", cx, y0 + 58, 46, "#111111", "center")
	rect(x0 + 20, y0 + 72, w - 40, 3, "#111111")
	txt("Sobota 15. července 2023 · Cena 25 Kč", cx, y0 + 94, 15, "#333333", "center")
	rect(x0 + 20, y0 + 102, w - 40, 1, "#111111")
	txt("HERNA VOXIE'S LEHLA POPELEM", cx, y0 + 152, 40, "#111111", "center")
	txt("Požár vypukl jen pár minut poté, co noční hlídač v 6:00 odešel z práce", cx, y0 + 182, 17, "#333333", "center")
	var ix = x0 + 30
	var iy = y0 + 200
	var iw = 400.0
	var ih = 270.0
	var P = 10.0
	rect(ix, iy, iw, ih, "#1a0e12")
	rect(ix + 40, iy + 110, 320, 160, "#2a2026")
	rect(ix + 40, iy + 100, 320, 12, "#3a2a30")
	for i in NEWS_WIN.size():
		rect(ix + 60 + (i % 7) * 42, iy + 130 + floor(i / 7.0) * 60, 26, 34, "#ffb030" if sin(t * 9 + i * 1.7) > 0.2 else "#ff6a1a")
	txt("VOXIE'S", ix + 200, iy + 96, 26, "#ff8bea", "center")
	for c in int(iw / P):
		var hgt = 6 + int(floor((sin(t * 6 + c * 0.9) + sin(t * 3.3 + c * 2.1) + 2) * 3.5))
		for r in hgt:
			var yy = iy + 100 - r * P
			if yy < iy:
				continue
			var f = float(r) / hgt
			rect(ix + c * P, yy, P, P, "#ffe46b" if f < 0.35 else ("#ff8a1a" if f < 0.7 else "#c0200a"))
	for i in 18:
		var sx = ix + fposmod(i * 53 + t * 20, iw)
		var sy = iy + fposmod(fposmod(i * 37 - t * 40, 120) + 120, 120)
		rect(sx, sy, 6, 6, Color(0.35, 0.31, 0.35, 0.6))
	draw_rect(Rect2(ix, iy, iw, ih), C("#111111"), false, 2)
	txt("Foto: hasiči na místě v 6:12", ix, iy + ih + 20, 13, "#444444")
	var col: String = "Hasiči v troskách našli rozbitý oblek maskota Voxieho. Podle nich byl prázdný. Vedle něj seděla nepoškozená figurína králíka. U obleku ležela zrezivělá jmenovka s nápisem „Vojtěch – majitel“. Případ z roku 1997 bude znovu otevřen. Noční hlídač je nezvěstný." if news_secret else "Hasiči v troskách našli obleky dvou maskotů. Jeden z nich byl podle svědků ještě teplý. Pracovníci tvrdí, že slyšeli z trosek hrací skříňku. Policie hledá nočního hlídače, který podle záznamů opustil budovu v 6:00. Majitel herny je nezvěstný od roku 1997."
	var ls = wrapt(col, w - iw - 90, 16)
	for i in ls.size():
		txt(ls[i], ix + iw + 30, iy + 14 + i * 22, 16, "#222222")
	rect(x0 + 20, y0 + h - 70, w - 40, 1, "#111111")
	txt("ZE ŽIVOTA · 6   ·   SPORT · 12   ·   POČASÍ: jasno, 28 °C", cx, y0 + h - 44, 14, "#444444", "center")
	restore_()
	noise(0.05)
	vignette(0.75)
	if game.scene_t > 4:
		save_()
		alpha = clampf((game.scene_t - 4) / 1.5, 0, 1)
		neon("KONEC…?", cx, HH - 40, 34, "#ff2bd6", 18)
		restore_()
	if game.scene_t > 6:
		big_btn(HW - 230, HH - 76, 200, 50, "MENU", "menu", game.to_menu, true, 18)

func draw_custom(t: float) -> void:
	var CU: Dictionary = game.CUSTOM
	rect(0, 0, HW, HH, Color(0.03, 0.016, 0.055, 0.88))
	scanlines()
	var cx = HW / 2
	neon("VLASTNÍ NOC", cx, 90, 52, "#ff2bd6", 20)
	var set_c = func(k: String, v):
		CU[k] = v
		game.st_set("voxies_custom", CU)
		game.audio.sfx("click")
	for L in [["🐻 Voxie – aktivita", "v", 140.0, "#ff8bea"], ["🐰 Cocoa – aktivita", "c", 230.0, "#ffc9a0"]]:
		var k: String = L[1]
		var y: float = L[2]
		txt(L[0], cx - 300, y + 34, 26, L[3])
		big_btn(cx + 40, y, 60, 50, "−", k + "-", func(): set_c.call(k, clampi(CU[k] - 1, 0, 20)), true, 30)
		txt(str(CU[k]), cx + 150, y + 38, 40, "#ffffff", "center")
		big_btn(cx + 200, y, 60, 50, "+", k + "+", func(): set_c.call(k, clampi(CU[k] + 1, 0, 20)), true, 30)
		rr(cx - 300, y + 58, 560, 8, 4, "#222222")
		rect(cx - 300, y + 58, 560 * CU[k] / 20.0, 8, L[3])
	for T2 in [["Cocoa je pasivní (jen pomáhá, nikdy nezaútočí)", "cocPassive", 330.0], ["Voxie chodí i pravou chodbou (obě dveře)", "voxBoth", 392.0], ["Voxie je poškozený (rozběhne se, když ho sleduješ)", "damaged", 454.0]]:
		var k: String = T2[1]
		var on: bool = CU[k]
		big_btn(cx - 300, T2[2], 560, 50, ("☑ " if on else "☐ ") + T2[0], "t" + k, func(): set_c.call(k, not on), true, 19)
	var diff: int = int(CU.v) + (0 if CU.cocPassive else int(CU.c)) + (5 if CU.voxBoth else 0) + (5 if CU.damaged else 0)
	var dn = "pohoda" if diff < 10 else ("normální" if diff < 20 else ("těžká" if diff < 30 else ("noční můra" if diff < 40 else "20/20 MODE")))
	txt("Obtížnost: " + dn, cx, 540, 22, "#ff3b3b" if diff >= 40 else "#ffe46b", "center")
	big_btn(cx - 300, 570, 270, 56, "← ZPĚT", "back", func():
		game.scene_ = "menu"
		game.scene_t = 0.0, true, 20)
	big_btn(cx + 30, 570, 270, 56, "▶ START", "startc", func(): game.new_game(8), true, 22)

func draw_ending() -> void:
	var G = game.G
	rect(0, 0, HW, HH, "#0a0612")
	var cx = HW / 2
	rect(cx - 250, 90, 500, 380, "#e8e2cc")
	txt("VOXIE'S FUN FACTORY", cx, 140, 26, "#3b1d6e", "center")
	txt("Výplatní páska – noční hlídač", cx, 172, 18, "#333333", "center")
	rect(cx - 220, 190, 440, 2, "#999999")
	var rows = [["Odpracováno", ("7" if G.night == 7 else "5") + " nocí"], ["Hodinová mzda", "4,00 $"], ["Příplatek za noc", "0,10 $"], ["Celkem", "120,50 $"]]
	for i in rows.size():
		txt(rows[i][0], cx - 210, 230 + i * 36, 20, "#222222")
		txt(rows[i][1], cx + 210, 230 + i * 36, 20, "#222222", "right")
	if game.scene_t > 2:
		txt("Normální konec. Voxie zůstal uvnitř. Zkus to příště se sekerou…" if G.night == 7 else "Normální konec. Ale kdo je vlastně uvnitř kostýmu? (Odemčena noc 6)", cx, 520, 22, "#ff8bea", "center")
	if game.scene_t > 3:
		big_btn(cx - 200, 570, 400, 56, "POKRAČOVAT" if G.night == 7 else "MENU", "menu", func():
			if game.G.night == 7:
				game.go_news(false)
			else:
				game.to_menu())

# ---------- DEV ----------
func dev_act(f: Callable, msg: String) -> Callable:
	return func():
		f.call()
		game.audio.sfx("click")
		game.DEV.msg = msg
		game.DEV.msgT = 1.5

func draw_dev(t: float) -> void:
	var DEV: Dictionary = game.DEV
	var G = game.G
	dev_frames += 1
	dev_fpsT += game.frame_dt
	if dev_fpsT > 0.5:
		dev_fps = int(round(dev_frames / dev_fpsT))
		dev_frames = 0
		dev_fpsT = 0.0
	if not DEV.on:
		return
	big_btn(HW - 120, 66, 96, 34, "DEV ✕" if DEV.panel else "DEV", "devp", func(): DEV.panel = not DEV.panel, true, 16)
	txt(str(dev_fps) + " FPS", HW - 128, 90, 14, "#ff6b6b" if dev_fps < 25 else "#5dff8a", "right")
	if not DEV.panel:
		return
	var x = 20.0
	var y = 110.0
	var w = 380.0
	rr(x, y, w, 520, 10, Color(0, 0.04, 0.016, 0.86), "#5dff8a", 1)
	var L = func(s: String, i: int, c := "#9fffb8"): txt(s, x + 12, y + 22 + i * 17, 13, c)
	var roam: Dictionary = game.roam
	L.call("DEV · noc " + str(G.night) + " · čas " + "%.1f" % G.t + " s (" + str(game.hour_of()) + ":00) · proud " + "%.1f" % G.power + " %", 0, "#ffffff")
	L.call("scéna " + game.scene_ + " · kamery " + (G.cam if G.cams else "-") + " · spotřeba " + str(game.usage()) + " · roam " + ("%.1f,%.1f" % [roam.pos.x, roam.pos.z] if roam.on else "ne"), 1)
	var ais: Array = game.ai_list()
	for i in ais.size():
		var a: Dictionary = ais[i]
		L.call(game._ai_def(a.id).ch.name + ": " + a.pos + " lvl " + str(game.lvl(a)) + " t " + "%.1f" % a.timer + " lit " + "%.1f" % a.lit + (" ÚTOK" if a.attack else "") + (" HONÍ" if a.chase else "") + (" ROZBITÁ" if a.broken else "") + (" OFF" if a.off else ""), 2 + i, "#ff6b6b" if a.attack else "#9fffb8")
	L.call("god " + str(DEV.god) + " · freeze " + str(DEV.freeze) + " · noclip " + str(DEV.noclip), 4, "#ffe46b")
	var B = [
		["+1 HODINA", func(): game.G.t = minf(6 * game.HOUR - 1, game.G.t + game.HOUR)], ["SKOK NA 6:00", func(): game.G.t = 6 * game.HOUR - 0.1], ["PROUD 100 %", func(): game.G.power = 100.0],
		["GOD " + ("ZAP" if DEV.god else "VYP"), func(): DEV.god = not DEV.god], ["ZMRAZIT AI " + ("ZAP" if DEV.freeze else "VYP"), func(): DEV.freeze = not DEV.freeze], ["NOCLIP " + ("ZAP" if DEV.noclip else "VYP"), func(): DEV.noclip = not DEV.noclip],
		["DEBUG MAPA " + ("ZAP" if DEV.map else "VYP"), func(): DEV.map = not DEV.map], ["KAMERY OFFLINE", func():
			if game.G.sys == null:
				game.G.sys = {"broken": false, "next": 99.0}
			game.G.sys.broken = true], ["VOXIE → DVEŘE", func(): game.move_to(game.G.vox, "DOOR")],
		["COCOA → DVEŘE", func():
			if not game.G.coc.off:
				game.G.coc.broken = false
				game.move_to(game.G.coc, "cDOOR")], ["VOXIE → PÓDIUM", func(): game.move_to(game.G.vox, "1A")], ["JUMPSCARE", func():
			var gd: bool = DEV.god
			DEV.god = false
			game.jumpscare(game.G.vox)
			DEV.god = gd],
		["VÝPADEK PROUDU", game.power_out], ["MENU", game.to_menu],
	]
	for i in B.size():
		big_btn(x + 10 + (i % 3) * 122, y + 100 + floor(i / 3.0) * 52, 116, 44, B[i][0], "dv" + str(i), dev_act(B[i][1], B[i][0]), true, 12)
	if DEV.msgT > 0:
		DEV.msgT -= game.frame_dt
		txt("✓ " + DEV.msg, x + 12, y + 505, 14, "#5dff8a")
	if DEV.map:
		draw_debug_map(HW - 330, 120, 300)

func draw_debug_map(mx: float, my: float, mw: float) -> void:
	var X0 = -23.0
	var X1 = 23.0
	var Z0 = -31.0
	var Z1 = 7.0
	var k = mw / (X1 - X0)
	var mh = (Z1 - Z0) * k
	var P = func(x: float, z: float) -> Vector2: return Vector2(mx + (x - X0) * k, my + (z - Z0) * k)
	rr(mx - 8, my - 8, mw + 16, mh + 16, 8, Color(0, 0, 0, 0.8))
	for id in game.ROOMS:
		var r: Dictionary = game.ROOMS[id]
		var a: Vector2 = P.call(r.x0, r.z0)
		draw_rect(Rect2(a.x, a.y, (r.x1 - r.x0) * k, (r.z1 - r.z0) * k), C("#3a6a4a"), false, 1)
		txt(id, a.x + 3, a.y + 11, 10, "#5a8a6a")
	for g in game.GAPS:
		var a: Vector2 = P.call(g.r[0], g.r[1])
		rect(a.x, a.y, (g.r[2] - g.r[0]) * k, (g.r[3] - g.r[1]) * k, Color(1, 0.24, 0.24, 0.7) if (g.door != null and game.door_of(g.door)) else Color(0.36, 1, 0.54, 0.35))
	for id in game.CAMS:
		var a: Vector2 = P.call(game.CAMS[id].pos[0], game.CAMS[id].pos[2])
		rect(a.x - 2, a.y - 2, 4, 4, "#7ff4ff")
	for a in game.ai_list():
		if a.off:
			continue
		var ch = game._ai_def(a.id).ch
		var col = "#ff8bea" if a.id == "V" else "#ffc9a0"
		if a.path:
			var pts = PackedVector2Array()
			for v in a.path.pts:
				pts.append(P.call(v.x, v.z))
			if pts.size() > 1:
				draw_polyline(pts, C(col), 1)
		var p: Vector2 = P.call(ch.root.position.x, ch.root.position.z)
		circle(p.x, p.y, 5, col)
	var me: Vector3 = game.roam.pos if game.roam.on else game.OFFICE_EYE
	var yaw: float = game.roam.yaw if game.roam.on else game.G.look
	var p: Vector2 = P.call(me.x, me.z)
	circle(p.x, p.y, 5, "#ffffff")
	line(p.x, p.y, p.x - sin(yaw) * 14, p.y - cos(yaw) * 14, "#ffffff", 1)
	txt("■ Voxie  ■ Cocoa  ● ty  ▪ kamera", mx, my + mh + 22, 12, "#9fffb8")

func draw_dev_menu(t: float) -> void:
	var DEV: Dictionary = game.DEV
	rect(0, 0, HW, HH, Color(0, 0.03, 0.016, 0.9))
	scanlines()
	var cx = HW / 2
	txt("🛠 DEV NÁSTROJE", cx, 80, 44, "#5dff8a", "center")
	txt("Night at Voxie's v2.7.0 Remastered · pro tvůrce a testování", cx, 110, 16, "#9fffb8", "center")
	big_btn(cx - 420, 140, 400, 50, "DEV PANEL VE HŘE: " + ("ZAP" if DEV.on else "VYP"), "dvon", func():
		DEV.on = not DEV.on
		game.st_set("voxies_dev", DEV.on), true, 18)
	big_btn(cx + 20, 140, 400, 50, "ODEMKNOUT VŠE", "dvun", dev_act(func():
		game.progress = 7
		game.st_set("voxies_night", 7)
		game.st_set("voxies_n7", true)
		game.st_set("voxies_secret", true)
		game.st_set("voxies_fire", true)
		game.beaten = true
		game.st_set("voxies_beaten", true), "odemčeno"), true, 18)
	txt("Spustit noc:", cx - 420, 230, 18, "#9fffb8")
	for n in range(1, 9):
		var nn = n
		big_btn(cx - 420 + (n - 1) * 104, 242, 96, 46, "VLASTNÍ" if n == 8 else "NOC " + str(n), "dvn" + str(n), func():
			DEV.on = true
			game.new_game(nn), true, 16)
	txt("Minihry:", cx - 420, 330, 18, "#9fffb8")
	var ms = [2, 3, 4, 5]
	for i in 4:
		var n: int = ms[i]
		big_btn(cx - 420 + i * 210, 342, 200, 46, String(game.T.MINIS[str(n)].title).replace("ARCHIV 1997 · ", ""), "dvm" + str(n), func():
			start_mini(n)
			M.extras = true, true, 15)
	txt("Konce a scény:", cx - 420, 430, 18, "#9fffb8")
	big_btn(cx - 420, 442, 270, 46, "TAJNÝ KONEC", "dvs", func():
		game.scene_ = "secret"
		game.scene_t = 0.0, true, 16)
	big_btn(cx - 140, 442, 270, 46, "NOVINY (POŽÁR)", "dvnw", func(): game.go_news(false), true, 16)
	big_btn(cx + 140, 442, 280, 46, "RESET POSTUPU", "dvr", dev_act(func():
		for k in ["voxies_night", "voxies_n7", "voxies_secret", "voxies_fire", "voxies_beaten", "voxies_promise", "voxies_custom", "voxies_ema"]:
			game.store.erase(k)
		game.st_set("voxies_dev", DEV.on)
		game.progress = 1
		game.beaten = false, "resetováno"), true, 16)
	for n in range(1, 8):
		var dn = n
		big_btn(cx - 420 + (n - 1) * 120, 494, 112, 40, "DEN " + str(n), "dvd" + str(n), func():
			DEV.on = true
			game.day.start_day(dn), true, 15)
	txt("Ve hře: tlačítko DEV vpravo nahoře nebo klávesa ` / F1", cx, 556, 16, "#9fffb8", "center")
	if DEV.msgT > 0:
		DEV.msgT -= game.frame_dt
		txt("✓ " + DEV.msg, cx, 580, 18, "#5dff8a", "center")
	big_btn(cx - 150, 610, 300, 52, "← MENU", "dvb", func():
		game.scene_ = "menu"
		game.scene_t = 0.0, true, 20)

# ---------- EXTRAS ----------
func draw_extras(t: float) -> void:
	var tabs = [["chars", "POSTAVY"], ["map", "MAPA"], ["mini", "MINIHRY"], ["ends", "KONCE"], ["song", "PÍSNIČKA"]]
	if EX.page != "chars":
		rect(0, 0, HW, HH, Color(0.03, 0.016, 0.055, 0.9))
		scanlines()
	neon("★ EXTRAS", 40, 60, 38, "#ffe46b", 16, "left")
	for i in tabs.size():
		var id: String = tabs[i][0]
		big_btn(270 + i * 160, 26, 150, 44, tabs[i][1], "ext" + id, func():
			EX.page = id
			EX.scare = -1.0, true, 17)
		if EX.page == id:
			rect(270 + i * 160, 72, 150, 4, "#ffe46b")
	big_btn(HW - 180, 26, 160, 44, "← MENU", "exb", func():
		game.scene_ = "menu"
		game.scene_t = 0.0
		game.menu_spots(), true, 17)
	if EX.page == "chars":
		var b: Dictionary = game.T.BIOS[EX.idx]
		var x = HW - 520
		rr(x, 110, 490, 470, 12, Color(0, 0, 0, 0.72))
		neon(b.name, x + 245, 160, 40, b.col, 16)
		txt(b.sub, x + 245, 190, 15, "#cccccc", "center")
		var ls = wrapt(b.text, 450, 17)
		for i in ls.size():
			txt(ls[i], x + 20, 230 + i * 24, 17, "#ffffff")
		if EX.idx == 0:
			big_btn(x + 20, 436, 450, 52, "🔌 JUMPSCARE PŘI 0 % PROUDU", "exj0", func():
				EX.scare = 0.0
				game.scare_kind = "dark"
				game.audio.start_music_box(14.0)
				game.say_later(1.0, game.audio.stop_music_box)
				game.say_later(1.0, func(): game.audio.scare("V")), EX.scare < 0, 17)
		big_btn(x + 20, 500, 220, 56, "😱 JUMPSCARE", "exj", func():
			game.scare_kind = "classic"
			EX.scare = 0.0
			var who = "V" if EX.idx == 0 else "C"
			game.audio.scare(who)
			game.audio.voice(("Vex|" if who == "V" else "Cex|") + game.pick(game._ai_def(who).lines.scare), 0.8, 0.0, false), EX.scare < 0, 18)
		big_btn(x + 250, 500, 220, 56, "COCOA ▶" if EX.idx == 0 else "◀ VOXIE", "exn", func():
			EX.idx = 1 - EX.idx
			EX.scare = -1.0, true, 18)
		if game.scare_kind == "dark" and EX.scare >= 0:
			if EX.scare > 1.0:
				rect(0, 0, HW, HH, Color(0, 0.35, 0.08, 0.5) if int(floor(EX.scare * 14)) % 2 else Color(0, 0, 0, 0.9))
			noise(0.15)
		elif EX.scare >= 0 and EX.scare < 0.05:
			rect(0, 0, HW, HH, "#ffffff")
	elif EX.page == "map":
		var sc = 1.55
		var mx = 70.0
		var my = 110.0
		save_()
		translate(mx, my)
		scale_(sc, sc)
		for l in game.T.LINKS:
			var A: Array = game.T.MAP[l[0]]
			var B2: Array = game.T.MAP[l[1]]
			line(A[0] + A[2] / 2, A[1] + A[3] / 2, B2[0] + B2[2] / 2, B2[1] + B2[3] / 2, Color(1, 1, 1, 0.25), 6)
		for id in game.T.MAP:
			var r: Array = game.T.MAP[id]
			var sel: bool = EX.room == id
			rect(r[0], r[1], r[2], r[3], "#7a2a6a" if sel else ("#3a2650" if id == "TY" else "#2a2a34"))
			draw_rect(Rect2(r[0], r[1], r[2], r[3]), C("#ff8bea" if sel else "#888888"), false, 2)
			txt("TY" if id == "TY" else ("🔒" if id == "X" else id), r[0] + r[2] / 2, r[1] + r[3] / 2 + 5, 13, "#ffffff", "center")
			var rid: String = id
			add_btn(r[0], r[1], r[2], r[3], "exr" + id, func(): EX.room = rid)
		restore_()
		var x = 760.0
		rr(x, 120, HW - x - 40, 420, 12, Color(0, 0, 0, 0.6))
		txt("Mapa Voxie's Fun Factory", x + 20, 160, 24, "#ffe46b")
		if EX.room != null:
			var rm: String = EX.room
			txt("CAM " + rm + " – " + game.CAMS[rm].name if game.CAMS.has(rm) else ("Zamčená místnost" if rm == "X" else "Kancelář"), x + 20, 210, 20, "#ff8bea")
			var info: String = game.T.ROOM_INFO.get(rm, "")
			if rm == "X":
				info = "Kancelář pana Vojtěcha: psací stůl, židle, knihovna, trezor a kartotéky. Zamčeno od roku 1997."
			if rm == "2":
				info += " Nová pec s lopatou, objednávkový lístek a stoly s pizzou."
			if rm == "7":
				info += " Nová fialová pokladna."
			var ls = wrapt(info, HW - x - 80, 18)
			for i in ls.size():
				txt(ls[i], x + 20, 245 + i * 26, 18, "#ffffff")
		else:
			txt("Klepni na místnost.", x + 20, 210, 18, "#aaaaaa")
		txt("Voxie: Pódium → Herna → Pizzerie/Toalety → Levá chodba", x + 20, 440, 15, "#ffb3f0")
		txt("Cocoa: Bludiště → Sklad/Herna → Pravá chodba", x + 20, 466, 15, "#ffd2b0")
	elif EX.page == "mini":
		var ms = [2, 3, 4, 5]
		for i in 4:
			var n: int = ms[i]
			var y = 130.0 + i * 110
			var D: Dictionary = game.T.MINIS[str(n)]
			rr(120, y, HW - 240, 96, 12, Color(0, 0, 0, 0.55))
			txt(D.title, 150, y + 38, 24, "#7ff4ff")
			var ls = wrapt(D.intro, HW - 600, 15)
			for k in mini(2, ls.size()):
				txt(ls[k], 150, y + 64 + k * 20, 15, "#cccccc")
			big_btn(HW - 330, y + 22, 180, 52, "▶ HRÁT", "exm" + str(n), func():
				start_mini(n)
				M.extras = true, true, 18)
	elif EX.page == "song":
		draw_song(t)
	elif EX.page == "ends":
		var sec: bool = game.st_get("voxies_secret", false)
		var fire: bool = game.st_get("voxies_fire", false)
		var cards = [
			[140.0, "Normální konec – výplata", "Přežij 5 nocí. Výplatní páska nočního hlídače.", game.beaten, func():
				if game.G == null:
					game.G = {"night": 5}
				game.scene_ = "ending"
				game.scene_t = 0.0],
			[280.0, "Tajný konec – Osvobození", "Tři rány sekerou v noci 7. Pan Vojtěch je volný.", sec, func():
				game.scene_ = "secret"
				game.scene_t = 0.0],
			[420.0, "Požár – Večerní zpravodaj", "Po 7. noci herna Voxie's lehla popelem…", fire, func(): game.go_news(false)],
		]
		for cd in cards:
			var y: float = cd[0]
			rr(160, y, HW - 320, 120, 12, Color(0, 0, 0, 0.55))
			txt(cd[1] if cd[3] else "🔒 ???", 190, y + 44, 26, "#ffe46b" if cd[3] else "#666666")
			txt(cd[2] if cd[3] else "Zatím nezjištěno.", 190, y + 80, 16, "#cccccc")
			if cd[3]:
				big_btn(HW - 380, y + 34, 180, 52, "▶ ZOBRAZIT", "exe" + str(int(y)), cd[4], true, 17)

# ====================================================================
#  MINIHRY „ARCHIV 1997"
# ====================================================================
func start_mini(n: int) -> void:
	game.audio.stop_menu_song()
	var D: Dictionary = game.T.MINIS[str(n)]
	M = {"hero": D.hero, "shake": 0.0, "blood": 0.0, "drips": [], "n": n, "def": D, "x": 120.0, "i": 0, "msg": D.intro, "msgT": 5.0, "phase": "play", "endT": 0.0, "dir": 0, "walk": 0.0, "hold": null, "keys": {}, "extras": false, "sl": null}
	game.scene_ = "mini"
	game.scene_t = 0.0
	game.audio.start_chip()

func _mini_dir() -> int:
	var d: int = M.hold.dir if M.hold else 0
	if M.keys.get("left") or M.keys.get("a"):
		d = -1
	if M.keys.get("right") or M.keys.get("d"):
		d = 1
	return d

func sl_update(dt: float) -> void:
	if M.sl == null:
		M.sl = {"ph": "walk", "t": 0.0, "dark": 0.0, "maxX": M.x, "turned": false, "gx": 0.0}
	var S: Dictionary = M.sl
	S.t += dt
	if S.ph == "walk":
		var d = _mini_dir()
		M.dir = d
		M.x = clampf(M.x + d * 240 * dt, 60, M.def.len - 200)
		if d != 0:
			M.walk += dt * 10
		S.maxX = maxf(S.maxX, M.x)
		S.dark = clampf(((S.maxX - 120) / (M.def.len - 320) - 0.2) / 0.55, 0, 1)
		if S.dark >= 1:
			S.ph = "eyes"
			S.t = 0.0
			S.gx = M.x + 90
			M.dir = 0
			game.audio.stop_chip()
			game.audio.sfx("sl_drone")
	elif S.ph == "eyes":
		if S.t > 1.4:
			S.ph = "turn"
			S.t = 0.0
			S.turned = true
	elif S.ph == "turn":
		if S.t > 0.9:
			S.ph = "glitch"
			S.t = 0.0
			game.audio.sfx("sl_glitch")
	elif S.ph == "glitch":
		if S.t > 1.1:
			S.ph = "black"
			S.t = 0.0
	elif S.ph == "black":
		if S.t > 1.2:
			M.phase = "end"
			M.endT = 10.0

func mini_update(dt: float) -> void:
	if not M:
		return
	M.msgT -= dt
	if M.phase == "play" and M.def.get("sl", false):
		sl_update(dt)
		return
	if M.phase == "play":
		var d = _mini_dir()
		M.dir = d
		M.x = clampf(M.x + d * 240 * dt, 60, M.def.len - 60)
		if d != 0:
			M.walk += dt * 10
		var g = M.def.goals[M.i] if M.i < M.def.goals.size() else null
		if g and absf(M.x - g.x) < 46:
			M.msg = g.text
			M.msgT = 4.5
			M.i += 1
			if g.has("become"):
				M.hero = g.become
				game.audio.sfx("clank")
				game.audio.sfx("clank")
			if g.has("shake"):
				M.shake = g.shake
				if M.def.bg == "backstage":
					M.blood = minf(1, M.blood + g.shake * 0.5)
				for k in 3:
					game.say_later(k * 0.22, func(): game.audio.sfx("clank", randf_range(-0.5, 0.5)))
				game.audio.sfx("mini_shake")
			else:
				game.audio.sfx("mini_goal")
		M.shake = maxf(0, M.shake - dt * 0.6)
		if not g and M.msgT < 0:
			M.phase = "end"
			M.endT = 0.0
			game.audio.stop_chip()
			game.audio.sfx("powerdown")
	else:
		M.endT += dt

func sprite(kind: String, x: float, y: float, c, t: float, f := 1.0) -> void:
	var P = 6.0 * f
	var R = func(a: float, b: float, w: float, h: float, col): px(x + a * P, y + b * P, w * P, h * P, col)
	var st = 1 if sin(t) > 0 else 0
	match kind:
		"voxie":
			R.call(-4, -24, 3, 3, "#5a3716"); R.call(1, -24, 3, 3, "#5a3716"); R.call(-4, -22, 8, 7, "#8a5a2b"); R.call(-3, -20, 2, 2, "#ffffff"); R.call(1, -20, 2, 2, "#ffffff"); R.call(-1, -17, 2, 1, "#2a1608"); R.call(-4, -15, 8, 8, "#8a5a2b"); R.call(-2, -14, 4, 1, "#ff2bd6"); R.call(-2, -12, 4, 4, "#d6a064")
			R.call(-3, -7, 2, 7 - st, "#8a5a2b"); R.call(1, -7, 2, 6 + st, "#8a5a2b")
		"bunny":
			R.call(-3, -30, 2, 8, "#7a4a2a"); R.call(1, -30, 2, 8, "#7a4a2a"); R.call(-4, -22, 8, 7, "#9a6238"); R.call(-3, -20, 2, 2, "#111111"); R.call(1, -20, 2, 2, "#111111"); R.call(-1, -17, 2, 1, "#5a2a1a"); R.call(-3, -15, 6, 1, "#ffffff"); R.call(-3, -14, 6, 7, "#9a6238")
			R.call(-3, -7, 2, 7 - st, "#9a6238"); R.call(1, -7, 2, 6 + st, "#9a6238")
		"guard":
			R.call(-3, -23, 6, 2, "#1a2a5a"); R.call(-3, -21, 6, 5, "#e0b090"); R.call(-2, -19, 1, 1, "#111111"); R.call(1, -19, 1, 1, "#111111"); R.call(-4, -16, 8, 9, "#2a3a7a"); R.call(-1, -15, 2, 1, "#ffe46b")
			R.call(-3, -7, 2, 7 - st, "#1a1a2a"); R.call(1, -7, 2, 6 + st, "#1a1a2a")
			draw_colored_polygon(PackedVector2Array([Vector2(x + 4 * P, y - 13 * P), Vector2(x + 60 * P, y - 30 * P), Vector2(x + 60 * P, y + 2 * P)]), C(Color(1, 0.95, 0.77, 0.18)))
		"man":
			R.call(-3, -25, 6, 2, "#3a2412"); R.call(-3, -23, 6, 6, "#e0b090"); R.call(-2, -21, 1, 1, "#111111"); R.call(1, -21, 1, 1, "#111111"); R.call(-3, -21, 6, 1, Color(0, 0, 0, 0.4)); R.call(-1, -18, 2, 1, "#a05040"); R.call(-4, -17, 8, 10, "#2a7a4a"); R.call(-1, -16, 2, 1, "#ffe46b")
			R.call(-3, -7, 2, 7 - st, "#2a2a3a"); R.call(1, -7, 2, 6 + st, "#2a2a3a")
		"suit":
			R.call(-6, -2, 12, 2, "#333333"); R.call(-1, -6, 2, 4, "#555555"); R.call(-4, -24, 3, 3, "#4a2e12"); R.call(1, -24, 3, 3, "#4a2e12"); R.call(-4, -22, 8, 7, "#6a4420"); R.call(-3, -20, 2, 2, "#111111"); R.call(1, -20, 2, 2, "#111111"); R.call(-4, -15, 8, 9, "#6a4420"); R.call(-2, -14, 4, 1, "#a01a8a")
			for i in 4:
				R.call(-3 + i * 2, -12 + (i % 2) * 3, 1, 1, "#c0c0c0")
		"leak":
			R.call(-8, -70, 16, 2, "#33333d")
			var kk = fmod(t * 2, 1.0)
			R.call(0, -68 + kk * 60, 1, 2, "#7ab8ff"); R.call(-3, -1, 6, 1, "#3a5a8a")
		"kid":
			R.call(-2, -15, 4, 2, c); R.call(-1, -17, 2, 2, "#ffe46b"); R.call(-2, -13, 4, 4, "#e8b890"); R.call(-1, -12, 1, 1, "#111111"); R.call(1, -12, 1, 1, "#111111"); R.call(-2, -9, 4, 5, c); R.call(-2, -4, 1, 4, "#333333"); R.call(1, -4, 1, 4, "#333333")
		"cake":
			R.call(-4, -8, 8, 1, "#dddddd"); R.call(-3, -12, 6, 4, "#ff8bea"); R.call(-3, -12, 6, 1, "#ffffff")
			for i in 3:
				R.call(-2 + i * 2, -14, 1, 2, "#ffffff")
				if sin(t * 3 + i) > -0.5:
					R.call(-2 + i * 2, -15, 1, 1, "#ffb000")
			R.call(-1, -8, 2, 8, "#6a4a2a")
		"cab":
			R.call(-4, -26, 8, 26, "#1d1a2a"); R.call(-3, -24, 6, 4, hsl(fmod(t * 60, 360), 0.8, 0.55)); R.call(-3, -19, 6, 1, "#ff3b3b")
		"tube":
			draw_arc(Vector2(x, y - 14 * P), 10 * P, 0, TAU, 48, C("#3bb2ff"), 3 * P)
			R.call(-1, -16, 1, 1, "#ffffff"); R.call(1, -16, 1, 1, "#ffffff")
		"shadow":
			var a0 = alpha
			alpha *= 0.85
			R.call(-5, -26, 3, 3, "#111111"); R.call(2, -26, 3, 3, "#111111"); R.call(-5, -24, 10, 24, "#0a0a0a")
			alpha = a0
		"door":
			R.call(-5, -30, 10, 30, "#3a2a1a"); R.call(-4, -34, 8, 3, "#1a6a2a"); R.call(3, -16, 1, 2, "#ffe46b")
		"paper":
			R.call(-12, -10, 24, 2, "#ffd000"); R.call(-4, -6, 8, 6, "#dddddd")
		"ticket":
			R.call(-5, -32, 10, 32, "#1a3a6a"); R.call(-6, -34, 12, 2, "#111111"); R.call(-3, -26, 6, 3, "#000000"); R.call(-2, -25, 4, 1, "#ff3b3b"); R.call(-1, -18, 2, 4, "#ffb3d0")
		"lock":
			R.call(-5, -30, 10, 30, "#2a2a2a"); R.call(-1, -16, 2, 3, "#ffe46b"); R.call(-4, -34, 8, 3, "#660000")

func sl_draw(cx: float, ground: float, t: float) -> void:
	var S = M.sl
	if S == null:
		return
	var P = 6.0
	var gx: float = (M.x + 90 if S.ph == "walk" else S.gx) - cx
	save_()
	if not S.turned:
		translate(gx, 0)
		scale_(0.62, 1)
		translate(-gx, 0)
	tint_k = S.dark
	sprite("guard", gx, ground, null, M.walk if S.ph == "walk" else 0.0, 1)
	tint_k = 0.0
	if S.dark >= 1:
		for o in [-2, 1]:
			for i in 3:
				rect(gx + o * P - i * 2, ground - 19 * P - i * 2, P + i * 4, P + i * 4, Color(1, 0, 0, 0.2))
			px(gx + o * P, ground - 19 * P, P, P, "#ff0000")
	restore_()
	if S.ph == "glitch":
		for i in 7:
			rect(0, randf() * HH, HW, 4 + randf() * 30, Color(1, 0, 0, 0.4) if randf() < 0.5 else Color(0, 0, 0, 0.7))
		noise(0.4)

func draw_mini(t: float) -> void:
	var D: Dictionary = M.def
	var ground = 560.0
	var cx = clampf(M.x - HW / 2, 0, D.len - HW)
	rect(0, 0, HW, HH, "#07040c")
	save_()
	if M.shake > 0:
		translate(randf_range(-12, 12) * M.shake, randf_range(-8, 8) * M.shake)
	var x = -fmod(cx * 0.5, 160.0)
	while x < HW:
		if D.bg == "party":
			px(x + 40, 140, 70, 90, "#2a1640")
			px(x + 50, 150, 50, 60, ["#ff2bd6", "#7ff4ff", "#ffe46b"][posmod(int(floor((x + cx * 0.5) / 160)), 3)])
		if D.bg == "arcade":
			px(x + 30, 260, 60, 180, "#120f20")
			px(x + 38, 275, 44, 30, hsl(fmod(x + t * 40, 360), 0.7, 0.45 if sin(t * 2 + x) > 0 else 0.25))
		if D.bg == "backstage":
			px(x + 10, 90, 150, 10, "#2a2a33"); px(x + 70, 100, 10, 140, "#22222a"); px(x + 30, 400, 60, 60, "#3a2a1a"); px(x + 36, 406, 48, 4, "#5a4a2a")
		if D.bg == "hall":
			px(x + 60, 120, 20, 8, "#333333" if sin(t * 9 + x) > 0.7 else "#fff3c4")
			px(x + 20, 230, 50, 70, "#3b1d6e")
		x += 160
	px(0, ground, HW, HH - ground, "#3a1a2a" if D.bg == "party" else "#151020")
	x = -fmod(cx, 48.0)
	while x < HW:
		px(x, ground, 24, 8, "#2a2040")
		x += 48
	for i in D.goals.size():
		var g: Dictionary = D.goals[i]
		var sx: float = g.x - cx
		if sx > -100 and sx < HW + 100:
			sprite(g.kind, sx, ground, g.get("c", "#ffffff"), t, 1)
			if i == M.i:
				txt("▼", sx, ground - (200 if g.kind == "bunny" else 230), 22, "#ffe46b", "center")
	sprite(M.hero, M.x - cx, ground, null, M.walk, 1)
	if D.get("sl", false):
		sl_draw(cx, ground, t)
	if M.blood > 0 and M.hero == "voxie":
		var hx: float = M.x - cx
		var P = 6.0
		var seams = [[-4, -15], [3, -15], [-4, -9], [3, -9], [-1, -16], [0, -22]]
		for i in mini(seams.size(), ceili(M.blood * seams.size())):
			var ln = 1 + int(floor(fmod(t * 3 + i * 0.7, 1.0) * 4 * M.blood))
			px(hx + seams[i][0] * P, ground + seams[i][1] * P, P, P * ln, "#9a0010")
			px(hx + seams[i][0] * P, ground + seams[i][1] * P, P, P, "#d01020")
		if randf() < M.blood * 0.25:
			M.drips.append({"x": M.x + randf_range(-20, 20), "y": ground - 60, "v": 0.0})
	for d in M.drips:
		d.v += 0.4
		d.y = minf(ground, d.y + d.v)
		px(d.x - cx, d.y, 6, 6, "#a00012")
	if M.drips.size() > 140:
		M.drips = M.drips.slice(20)
	restore_()
	if M.shake > 0.8 and randf() < 0.3:
		rect(0, 0, HW, HH, Color(0.47, 0, 0, 0.25))
	scanlines()
	noise(0.05)
	vignette(0.8)
	txt(D.title, HW / 2, 50, 26, "#7ff4ff", "center")
	if D.get("sl", false) and M.sl and M.sl.ph == "black":
		rect(0, 0, HW, HH, "#000000")
	elif M.phase == "play":
		if M.msgT > 0:
			var ls = wrapt(M.msg, 760, 21)
			rr(HW / 2 - 400, 80, 800, ls.size() * 28 + 22, 10, Color(0, 0, 0, 0.75))
			for i in ls.size():
				txt(ls[i], HW / 2, 108 + i * 28, 21, "#ffffff", "center")
		txt("◀ drž vlevo · drž vpravo ▶", HW / 2, 690, 16, "#888888", "center")
		big_btn(HW - 210, 20, 190, 40, "PŘESKOČIT ▶▶", "skip", func():
			M.phase = "end"
			M.endT = 10.0
			game.audio.stop_chip(), true, 16)
	else:
		rect(0, 0, HW, HH, Color(0, 0, 0, minf(0.85, M.endT * 0.5)))
		if D.bg == "backstage":
			var xx = 0
			while xx < HW:
				var h = maxf(0, (M.endT * 60 - (xx * 37 % 90)) * (0.4 + (xx * 13 % 7) / 7.0))
				px(xx, 0, 12, minf(HH * 0.55, h), "#6a000c")
				px(xx, minf(HH * 0.55, h), 12, 6, "#a00012")
				xx += 12
		if randf() < 0.1:
			noise(0.3)
		for i in D.end.size():
			if M.endT > 1 + i * 2.6:
				var ws = wrapt(D.end[i], 900, 24)
				for k in ws.size():
					txt(ws[k], HW / 2, 250 + i * 90 + k * 30, 24, "#ff8bea" if i == D.end.size() - 1 else "#ffffff", "center")
		if M.endT > 1 + D.end.size() * 2.6:
			big_btn(HW / 2 - 200, 560, 400, 56, "ZPĚT DO EXTRAS" if M.extras else "ZAČÍT NOC " + str(M.n), "go", func():
				var n: int = M.n
				var ex: bool = M.extras
				M = null
				game.audio.stop_chip()
				if ex:
					game.scene_ = "extras"
					game.scene_t = 0.0
					game.audio.start_menu_song()
				else:
					game.new_game(n))

# ====================================================================
#  VSTUP
# ====================================================================
func _hit(p: Vector2):
	for i in range(buttons.size() - 1, -1, -1):
		var b: Dictionary = buttons[i]
		if p.x >= b.x and p.x <= b.x + b.w and p.y >= b.y and p.y <= b.y + b.h:
			return b
	return null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if game.scene_ != "menu":
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
		var p: Vector2 = e.position / HK
		var b = _hit(p)
		hover_btn = b.id if b else null
		var G = game.G
		if drag == null and G and game.scene_ == "play" and not G.cams and not game.roam.on and not b and e.button_mask == 0:
			var edge = HW * 0.12
			G.lookV = 1.6 * (1 - p.x / edge) if p.x < edge else (-1.6 * (1 - (HW - p.x) / edge) if p.x > HW - edge else 0.0)
	elif e is InputEventKey:
		_key(e)

func _down(id: int, p: Vector2) -> void:
	var roam: Dictionary = game.roam
	var G = game.G
	if game.scene_ == "menu":
		game.audio.start_menu_song()
	var b = _hit(p)
	if b and b.id == "sprint":
		roam.sprint = true
		roam["sprintId"] = id
		return
	if b:
		b.cb.call()
		return
	if game.scene_ == "intro":
		game.scene_ = "play"
		game.scene_t = 0.0
		game.audio.start_ambient()
		return
	if game.scene_ == "mini" and M:
		M.hold = {"id": id, "dir": -1 if p.x < HW / 2 else 1}
		return
	if game.scene_ == "play" and roam.on:
		if p.x < HW * 0.4 and p.y > HH * 0.35 and not roam.joy:
			roam.joy = {"id": id, "x": 150.0, "y": 560.0, "dx": 0.0, "dy": 0.0}
		else:
			roam.look = {"id": id, "x": p.x, "y": p.y, "yaw": roam.yaw, "pitch": roam.pitch}
		return
	if game.scene_ == "play" and not G.cams:
		drag = {"x": p.x, "look": G.look, "id": id}
		game.look_target = null

func _move(id: int, p: Vector2) -> void:
	var roam: Dictionary = game.roam
	var G = game.G
	if drag and drag.id == id and G:
		G.look = clampf(drag.look + (p.x - drag.x) / HW * 2.4, -1.15, 1.15)
	if roam.joy and roam.joy.id == id:
		var dx: float = (p.x - roam.joy.x) / 70
		var dy: float = (p.y - roam.joy.y) / 70
		var l = Vector2(dx, dy).length()
		if l > 1:
			dx /= l
			dy /= l
		roam.joy.dx = dx
		roam.joy.dy = dy
	if roam.look and roam.look.id == id:
		roam.yaw = roam.look.yaw - (p.x - roam.look.x) / HW * 3.2
		roam.pitch = clampf(roam.look.pitch - (p.y - roam.look.y) / HH * 2, -1, 1)
	if M and M.hold and M.hold.id == id:
		M.hold.dir = -1 if p.x < HW / 2 else 1

func _up(id: int) -> void:
	var roam: Dictionary = game.roam
	if roam.get("sprintId") == id:
		roam.sprint = false
		roam.sprintId = null
	if drag and drag.id == id:
		drag = null
	if roam.joy and roam.joy.id == id:
		roam.joy = null
	if roam.look and roam.look.id == id:
		roam.look = null
	if M and M.hold and M.hold.id == id:
		M.hold = null

func _keyname(e: InputEventKey) -> String:
	match e.keycode:
		KEY_LEFT: return "left"
		KEY_RIGHT: return "right"
		KEY_UP: return "up"
		KEY_DOWN: return "down"
		KEY_SPACE: return " "
		KEY_SHIFT: return "shift"
		KEY_ENTER: return "enter"
		KEY_F1: return "f1"
		KEY_QUOTELEFT: return "`"
		KEY_ESCAPE: return "escape"
	return OS.get_keycode_string(e.keycode).to_lower()

func _key(e: InputEventKey) -> void:
	var k = _keyname(e)
	var roam: Dictionary = game.roam
	var G = game.G
	if not e.pressed:
		roam.keys[k] = false
		if M:
			M.keys[k] = false
		if G and (k == "left" or k == "right"):
			G.lookV = 0.0
		return
	if e.echo:
		return
	if game.scene_ == "mini" and M:
		M.keys[k] = true
		return
	if game.scene_ != "play":
		return
	if k == "`" or k == "f1":
		game.DEV.panel = not game.DEV.panel
		return
	if G.dialog:
		var n: Dictionary = game.T.DIALOG[G.dialog]
		var i = int(k) - 1 if k.is_valid_int() else -1
		if i >= 0 and i < n.o.size():
			game.choose(n.o[i][1])
		return
	if roam.on:
		roam.keys[k] = true
		if k == "f":
			roam.flash = not roam.flash and not G.out
		if k == " ":
			if game.can_hit():
				game.hit_voxie()
			else:
				game.roam_jump()
		if k == "e":
			game.interact()
		if k == "r" or k == "enter":
			game.toggle_roam()
		return
	if k == "r":
		game.toggle_roam()
		return
	if k == "a":
		game.toggle_door("L")
	elif k == "d":
		game.toggle_door("R")
	elif k == "q" and not G.cams:
		game.set_light("L")
	elif k == "e" and not G.cams:
		game.set_light("R")
	elif k == " " or k == "s":
		game.toggle_cams()
	elif k == "left":
		G.lookV = 1.6
	elif k == "right":
		G.lookV = -1.6
	elif G.cams:
		var mp = {"1": "1A", "2": "1B", "3": "2", "4": "3", "5": "4", "6": "5", "7": "6", "8": "7", "9": "8", "0": "9"}
		if mp.has(k):
			game.select_cam(mp[k])

# ---------- odměna: písnička od fanouška ----------
var song_parts = []
func draw_song(t: float) -> void:
	if not game.st_get("voxies_secret", false) and not game.st_get("voxies_n7", false):
		rr(160, 200, HW - 320, 220, 12, Color(0, 0, 0, 0.6))
		txt("🔒 PÍSNIČKA ZAMČENA", HW / 2, 280, 32, "#666666", "center")
		txt("Odemkne se po přežití 7. noci.", HW / 2, 330, 18, "#aaaaaa", "center")
		return
	if song_parts.is_empty():
		for blk in FileAccess.get_file_as_string("res://data/song.txt").strip_edges().split("\n\n"):
			song_parts.append(blk.split("\n"))
	var n = song_parts.size()
	EX.song = clampi(EX.song, 0, n - 1)
	var cx = HW / 2
	neon("PĚT NOCÍ U VOXIEHO", cx, 140, 40, "#ff2bd6", 18)
	txt("písnička od fanouška · odměna za 7. noc", cx, 170, 15, "#ffd9f6", "center")
	var part: Array = song_parts[EX.song]
	rr(cx - 400, 190, 800, 420, 14, Color(0.04, 0.02, 0.07, 0.8), "#ff2bd6", 2)
	txt(part[0], cx, 228, 20, "#ffe46b", "center")
	for i in range(1, part.size()):
		var col = "#ffffff" if not part[i].begins_with("(") else "#ff8bea"
		txt(part[i], cx, 228 + i * 34 + 6 * sin(t * 2 + i) * 0.0, 21, col, "center")
	for i in 5:
		var c = hsl(fmod(t * 60 + i * 72, 360), 0.9, 0.6)
		circle(cx - 360 + i * 180, 600 + sin(t * 4 + i) * 6, 5, c)
	big_btn(cx - 400, 630, 180, 50, "◀ ZPĚT", "sgp", func(): EX.song -= 1, EX.song > 0, 18)
	txt(str(EX.song + 1) + " / " + str(n), cx, 662, 20, "#cccccc", "center")
	big_btn(cx + 220, 630, 180, 50, "DÁL ▶", "sgn", func(): EX.song += 1, EX.song < n - 1, 18)

func draw_dayend() -> void:
	var n: int = game.G.day if game.G else 1
	neon("KONEC DENNÍ SMĚNY", HW / 2, 240, 52, "#ffe46b", 18)
	txt("Den " + str(n) + " hotový. Herna se zavírá… a začíná noc.", HW / 2, 300, 22, "#ffffff", "center")
	if game.scene_t > 1.2:
		big_btn(HW / 2 - 220, 380, 440, 60, "🌙 NASTOUPIT NA NOC " + str(n), "dayn", func(): game.day.after_day(n), true, 22)
		big_btn(HW / 2 - 220, 460, 440, 52, "MENU", "menu", game.to_menu, true, 20)
	noise(0.05)
