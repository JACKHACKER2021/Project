extends Control
## HUD NaV2 Remastered (Godot) – kreslení obrazovek a dotykové ovládání

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
var drag = null
var touches = {}
var dev_fps = 60
var dev_fpsT = 0.0
var dev_frames = 0
var NEWS_WIN = []

var EX = {"page": "chars", "idx": 0, "rot": 0.0, "scare": -1.0, "room": null, "vAnim": "Idle", "cAnim": "Idle", "at": 0.0}
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


# ====================================================================
#  NaV2: obrazovky a HUD
# ====================================================================
var joy = null
var mg_paper := false
var paper_n := 1
var MG = null
var inv_open := false
var inspect = null       # {"id":..., "rx":.., "ry":..}
var flash_id = -1

func btn(x: float, y: float, w: float, h: float, label: String, id: String, cb: Callable, on := true, size := 20.0, col := "#ff3b3b") -> void:
	var c = Color(col)
	rr(x, y, w, h, 10, (c if hover_btn == id else Color(0.47, 0.08, 0.08, 0.35)) if on else Color(1, 1, 1, 0.05), c if on else Color("#444444"), 2)
	while size > 9 and tw(label, size) > w - 14:
		size -= 1
	txt(label, x + w / 2, y + h / 2 + size * 0.36, size, "#ffffff" if on else "#666666", "center")
	if on:
		add_btn(x, y, w, h, id, cb)

func wrap_txt(s: String, x: float, y: float, max_w: float, size: float, col) -> float:
	var ls = wrapt(s, max_w, size)
	for i in ls.size():
		txt(ls[i], x, y + i * size * 1.4, size, col)
	return y + ls.size() * size * 1.4

func draw_logo(x: float, y: float, s: float, ring_ := true) -> void:
	var u = s / 16
	var R = func(a: float, b: float, w: float, h: float, col: String): rect(x + a * u, y + b * u, w * u, h * u, col)
	var cc = Vector2(x + s / 2, y + s / 2)
	for i in 4:
		draw_arc(cc, s * 0.47, 0, TAU, 96, C(Color(1, 0.12, 0.12, 0.16)), s * 0.045 + (4 - i) * 4, true)
	draw_arc(cc, s * 0.47, 0, TAU, 96, C("#ff2020"), s * 0.045, true)
	draw_arc(cc, s * 0.42, 0, TAU, 96, C("#5a0a0a"), s * 0.012, true)
	R.call(10.2, 2.4, 3.2, 3.2, "#2a1808"); R.call(11, 3.2, 1.6, 1.6, "#6a2a2a"); R.call(3.4, 3.6, 1.2, 1.4, "#7a7f88")
	R.call(3, 4.4, 10, 7.4, "#5a3818"); R.call(3, 4.4, 10, 1, "#6a4420"); R.call(12, 4.4, 1, 7.4, "#3a2410")
	for a in [[4, 5, 2], [9.5, 6, 2.5], [5.5, 8.5, 1.5], [10.5, 9.5, 1.5]]:
		R.call(a[0], a[1], a[2], 1, "#1a0e06")
	R.call(4.4, 6.6, 2.6, 2.6, "#111111"); R.call(5.3, 7.5, 0.9, 0.9, "#ff1a1a")
	R.call(9, 7.6, 2.6, 2.6, "#e8e8e0"); R.call(9.9, 8.6, 1.1, 1.2, "#111111"); R.call(10.1, 10.2, 0.4, 1.4, "#902020")
	R.call(5.6, 10, 4.8, 1.8, "#8a6a40"); R.call(7.1, 10.1, 1.8, 0.9, "#1a0e06")
	R.call(3.6, 11.8, 8.8, 3.6, "#100604")
	for i in 6:
		R.call(4 + i * 1.4, 11.8, 0.9, 1, "#d8d0b0")
		R.call(4.3 + i * 1.4, 14.4, 0.9, 1, "#d8d0b0")
	R.call(13.2, 6, 0.5, 4, "#c0201a"); R.call(13.6, 7, 0.4, 3.5, "#2050c0")

func map_x(x: float) -> float:
	return (x + 22) * 9
func map_y(z: float) -> float:
	return (z + 30) * 7.5

# ---------------------------------------------------------------- hlavní kreslení
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
			draw_logo(HW / 2 - 90, 190, 180)
			txt("Načítám trosky…", HW / 2, 440, 22, "#ff8080", "center")
		"menu": draw_menu(t)
		"extras": draw_extras(t)
		"devmenu": draw_dev_menu(t)
		"intro": draw_intro()
		"custom": draw_custom(t)
		"mini": draw_mini(t)
		"paper1": draw_paper1(t)
		"home": draw_home(t)
		"finale": draw_finale(t)
		"news": draw_news(t)
		"boot": draw_boot(t)
		"play":
			draw_play(t)
			draw_dev(t)
		"scare":
			if g.scene_t < 0.05:
				rect(0, 0, HW, HH, "#ffffff")
			noise(0.12 + randf() * 0.12 + maxf(0, g.scene_t - 1.35) * 1.6)
			if g.scene_t > 1.45:
				rect(0, 0, HW, HH, Color(0, 0, 0, clampf((g.scene_t - 1.7) * 2.5, 0, 0.7)))
		"dead": draw_end(false)
		"win": draw_end(true)

func clock_s() -> String:
	var h: int = game.hour()
	return ("0" if h == 0 else str(h)) + ":00"
func bat_bar(G) -> void:
	rr(24, 60, 180, 22, 6, "#111111")
	rect(27, 63, 174 * G.bat / 100.0, 16, "#ff4040" if G.bat < 25 else ("#ffb030" if G.bat < 50 else "#5dff8a"))
	txt("🔋 " + str(ceili(G.bat)) + " %", 212, 77, 16, "#cccccc")

func draw_play(t: float) -> void:
	var G = game.G
	if G.roam:
		draw_roam(t)
	else:
		draw_desk(t)
	draw_inventory(t)

func draw_desk(t: float) -> void:
	var G = game.G
	vignette(0.65)
	if G.monA > 0:
		save_()
		alpha = G.monA
		translate(0, (1 - G.monA) * HH)
		draw_computer(t)
		restore_()
	if G.monA < 0.5:
		txt(clock_s(), HW - 24, 54, 46, "#ffffff", "right")
		txt("Custom Night" if G.custom else "Noc " + str(G.night), 24, 42, 22, "#ff8b8b")
		bat_bar(G)
	if not G.out:
		btn(HW / 2 - 200, 654 if not G.mon else 664, 400, 50, "▼ ZAVŘÍT POČÍTAČ" if G.mon else "🖥 POČÍTAČ", "mon", game.toggle_mon, true, 20, "#5dff8a")
		if not G.mon:
			rr(HW - 170, 520, 140, 110, 16, Color(1, 0.94, 0.78, 0.85) if G.flash else Color(0.47, 0.08, 0.08, 0.35), "#fff3c4", 2)
			txt("🔦", HW - 100, 588, 40, "#ffffff", "center")
			txt("DRŽ", HW - 100, 618, 14, "#000000" if G.flash else "#cccccc", "center")
			add_btn(HW - 170, 520, 140, 110, "flash", func(): pass)
			txt("◀ táhni pro rozhlížení ▶", HW / 2, 636, 14, "#777777", "center")
			btn(24, 650, 250, 56, "🚶 ODEJÍT OD STOLU", "leave", game.leave_desk, true, 17, "#ffb030")
			task_line(24, 110)
	draw_speech(G.mon)
	if G.msgT > 0 and G.monA < 0.5:
		save_()
		alpha = minf(1, G.msgT)
		txt(G.msg, HW / 2, 110, 20, "#ffd0d0", "center")
		restore_()
	if G.out:
		rect(0, 0, HW, HH, Color(0, 0, 0, minf(0.92, G.outT * 0.2)))
		if G.outT > 8 and randf() < 0.5:
			rect(HW / 2 - 30, 330, 10, 10, "#ff2020")
	if G.staticT > 0.5 and not G.mon:
		noise(0.15)

func draw_speech(mon: bool) -> void:
	var sp = game.speech
	if sp == null or sp.t >= sp.dur:
		return
	var sy = 574.0 if mon else 140.0
	var ls = wrapt(sp.text, 728, 19)
	rr(HW / 2 - 380, sy, 760, 36 + ls.size() * 26, 10, Color(0.08, 0, 0, 0.8))
	txt(sp.get("who", "Vojtěch"), HW / 2 - 364, sy + 22, 15, "#ff5050")
	save_()
	translate(randf_range(-1, 1), randf_range(-1, 1))
	for i in ls.size():
		txt(ls[i], HW / 2, sy + 50 + i * 26, 19, "#ffd8d8", "center")
	restore_()

## počítač ve stylu Windows 98 (rok 2002, CRT monitor): okno VOXIE-CAM na modrozelené ploše
func bevel(x: float, y: float, w: float, h: float, sunk := false, face := "#c0c0c0") -> void:
	rect(x, y, w, h, face)
	var lt = "#808080" if sunk else "#ffffff"
	var dk = "#ffffff" if sunk else "#404040"
	rect(x, y, w, 2, lt)
	rect(x, y, 2, h, lt)
	rect(x, y + h - 2, w, 2, dk)
	rect(x + w - 2, y, 2, h, dk)
	rect(x + 2, y + h - 4, w - 4, 2, "#808080" if not sunk else face)
	rect(x + w - 4, y + 2, 2, h - 4, "#808080" if not sunk else face)
func w98_btn(x: float, y: float, w: float, h: float, label: String, id: String, cb: Callable, on := true, size := 15.0) -> void:
	var pressed = hover_btn == id
	bevel(x, y, w, h, pressed)
	while size > 9 and tw(label, size) > w - 12:
		size -= 1
	txt(label, x + w / 2 + (1 if pressed else 0), y + h / 2 + size * 0.36 + (1 if pressed else 0), size, "#000000" if on else "#808080", "center")
	if on:
		add_btn(x, y, w, h, id, cb)
func draw_computer(t: float) -> void:
	var G = game.G
	# rámeček CRT monitoru (béžový plast) a zaoblené zakřivené sklo
	rr(4, 4, HW - 8, HH - 8, 40, "#c8c0a8", "#8a8470", 6)
	var x0 = 44.0
	var y0 = 30.0
	var w = HW - 88
	var h = HH - 120
	rr(x0 - 6, y0 - 6, w + 12, h + 12, 26, "#151515")
	rect(x0, y0, w, h, "#008080")
	# ikony na ploše (klikací aplikace)
	var icons = [["cam", "📹", "VOXIE-CAM"], ["web", "🌐", "Internet"], ["tapes", "📼", "Nahrávky D."], ["fire", "🎞", "POZAR_CAM7.AVI"], ["bin", "🗑", "Koš"]]
	for i in icons.size():
		var ic = icons[i]
		var iy = y0 + 14 + i * 82
		if pc.app == ic[0]:
			rect(x0 + 6, iy, 72, 70, Color(0, 0, 0.5, 0.6))
		txt(ic[1], x0 + 42, iy + 38, 30, "#ffffff", "center")
		txt(ic[2], x0 + 42, iy + 62, 10, "#ffffff", "center")
		var app: String = ic[0]
		add_btn(x0 + 6, iy, 72, 70, "ic" + app, func():
			pc.app = app
			pc.art = null
			game.audio.sfx("click"))
	var wx = x0 + 90
	var wy = y0 + 14
	var ww = w - 110
	var wh = h - 64
	if pc.app == "cam":
		cam_window(G, wx, wy, ww, wh, t)
	else:
		app_window(G, wx, wy, ww, wh, t)
	# hlavní panel Windows
	bevel(x0, y0 + h - 34, w, 34)
	bevel(x0 + 4, y0 + h - 30, 86, 26)
	txt("⊞ Start", x0 + 47, y0 + h - 11, 15, "#000000", "center")
	bevel(x0 + 98, y0 + h - 30, 230, 26, true)
	txt({"cam": "📹 VOXIE-CAM v2.0", "web": "🌐 Internet Explorer", "tapes": "📼 Nahrávky D.", "fire": "🎞 Přehrávač médií", "bin": "🗑 Koš"}[pc.app], x0 + 110, y0 + h - 11, 13, "#000000")
	bevel(x0 + w - 120, y0 + h - 30, 116, 26, true)
	txt("🔋 " + clock_s(), x0 + w - 62, y0 + h - 11, 13, "#000000", "center")
	# zakřivení a prokládání CRT
	var yy = y0
	while yy < y0 + h:
		rect(x0, yy, w, 1, Color(0, 0, 0, 0.16))
		yy += 3
	vignette(0.35)

func cam_window(G, wx: float, wy: float, ww: float, wh: float, t: float) -> void:
	# okno aplikace
	bevel(wx, wy, ww, wh)
	for i in 40:
		var k = i / 40.0
		rect(wx + 4 + (ww - 8) * k, wy + 4, (ww - 8) / 40.0 + 1, 24, Color(0, 0, 0.5).lerp(Color(0.06, 0.52, 0.82), k))
	txt("📹 VOXIE-CAM v2.0 - [CAM " + G.cam + "]", wx + 12, wy + 22, 15, "#ffffff")
	for i in 3:
		bevel(wx + ww - 70 + i * 22, wy + 7, 20, 18)
		txt(["_", "□", "×"][i], wx + ww - 60 + i * 22, wy + 21, 13, "#000000", "center")
	txt("Soubor   Kamera   Zobrazit   Nápověda", wx + 10, wy + 46, 13, "#000000")
	var fx = wx + 12
	var fy = wy + 58
	var fw = ww - 470
	var fh = wh - 96
	bevel(fx - 3, fy - 3, fw + 6, fh + 6, true)
	rect(fx, fy, fw, fh, "#000000")
	if not game.online(G.cam):
		noise_rect(0.8, fx, fy, fw, fh)
		rect(fx, fy + fh / 2 - 30, fw, 60, Color(0, 0, 0, 0.7))
		txt("NO SIGNAL", fx + fw / 2, fy + fh / 2 + 12, 40, "#ff4040", "center")
	else:
		if G.monA >= 1:
			draw_texture_rect(game.feed_vp.get_texture(), Rect2(fx, fy, fw, fh), false, Color(0.8, 1.0, 0.85, alpha))
		noise_rect(0.06 + G.staticT, fx, fy, fw, fh)
	txt("CAM " + G.cam + " – " + game.CAMS[G.cam], fx + 10, fy + 24, 17, "#ffffff")
	txt("REC", fx + fw - 64, fy + 24, 15, "#ffffff")
	if sin(t * 4) > 0:
		circle(fx + fw - 76, fy + 18, 6, "#ff2020")
	txt("2002-07-%02d  %s" % [14 + G.night, clock_s()], fx + 10, fy + fh - 12, 14, "#ffffff")
	# panel s mapou
	var mx = fx + fw + 20
	var my = fy
	bevel(mx - 4, my - 4, 440, 290, true, "#ffffff")
	var sc = 1.0
	save_()
	translate(mx + 8, my + 8)
	scale_(sc, sc)
	for l in game.D.LINKS:
		var A = game.D.MAP[l[0]]
		var B = game.D.MAP[l[1]]
		line(A[0] + A[2] / 2, A[1] + A[3] / 2, B[0] + B[2] / 2, B[1] + B[3] / 2, Color(0.5, 0.5, 0.5, 0.6), 4)
	for id in game.D.MAP:
		var r = game.D.MAP[id]
		var sel = G.cam == id
		var on = game.online(id)
		rect(r[0], r[1], r[2], r[3], "#800000" if id == "TY" else ("#000080" if sel else ("#c0c0c0" if on else "#808080")))
		draw_rect(Rect2(r[0], r[1], r[2], r[3]), C("#000000"), false, 1)
		txt("TY" if id == "TY" else id, r[0] + r[2] / 2, r[1] + r[3] / 2 + 5, 13, "#ffffff" if (sel or id == "TY") else ("#000000" if on else "#404040"), "center")
		if game.CAMS.has(id):
			var cid: String = id
			add_btn(r[0], r[1], r[2], r[3], "c" + id, func():
				if game.G.cam != cid:
					game.G.cam = cid
					game.G.staticT = 0.3
					game.audio.sfx("cam")
					game.G.fix = null)
	restore_()
	var by = my + 300
	if game.online(G.cam):
		w98_btn(mx, by, 300, 34, "🔊 Přilákat zvukem (-4 %)", "lure", game.lure)
	else:
		txt("⚠ Signál vypadl… zkus jinou kameru", mx, by + 22, 15, "#800000")
	var on_l = G.online.duplicate()
	on_l.sort()
	txt("Signál: STABILNÍ" if G.stable else "Online: " + ", ".join(on_l), mx, by + 60, 13, "#000000")
	# stavový řádek
	bevel(wx + 6, wy + wh - 30, ww - 12, 24, true)
	txt("Baterie: " + str(ceili(G.bat)) + " %   |   " + ("Opravuji kameru…" if G.fix else "Připraveno"), wx + 14, wy + wh - 12, 13, "#000000")


# ---------------------------------------------------------------- další aplikace v počítači
var pc = {"app": "cam", "q": "", "art": null, "tape": -1, "tapeT": 0.0, "fireT": 0.0, "fireOn": false}
var tape_player = null
const TAPES_D := [
	["12. 5. 1997", "Páska jedna. Dvanáctého května devadesát sedm. Tady D., noční směna. Ve skladu je pod plachtou starý oblek. Říkají mu Glitch. Má pružinové zámky. Pan Vojtěch tvrdí, že je bezpečný."],
	["20. 5. 1997", "Páska dvě. Našel jsem v kanceláři složku. První Voxie. Deaktivován v roce osmdesát. Prý se v noci hýbal sám, i když byl vypnutý. Proto ho rozebrali. Hlava chybí dodnes."],
	["2. 6. 1997", "Páska tři. Hollow Bunny. Dutý králík. Kostým bez kostry, do kterého se leze. Žádná elektronika, jen látka a tma uvnitř. Pan Vojtěch ho chce na oslavu čtrnáctého června. Pro Emu."],
	["9. 6. 1997", "Páska čtyři. Springlocky cvakají, když je vlhko. Říkal jsem to panu Vojtěchovi. Nechce poslouchat. Chce na oslavě vystupovat sám, v obleku Voxieho."],
	["13. 6. 1997", "Páska pět. Třináctého června, večer před oslavou. Klíč od kanceláře mám já. Kdyby se něco stalo… nevím, jestli budu mít odvahu odemknout."],
]
const SEARCH := ["požár Voxie's", "náčelník Král žhář", "Vojtěch nezvěstný", "Ema 1997", "Voxie historie 1980", "Hollow Bunny"]
const ARTICLES := [
	{"q": [0, 1], "t": "Herna Voxie's lehla popelem", "d": "15. 7. 2023 · Večerní zpravodaj", "b": "Požár vypukl jen pár minut poté, co noční hlídač v 6:00 odešel z práce. Plameny se podle hasičů rozšířily ze skladu do herny a na pódium. Střecha nad hernou se propadla v 6:11. Uvnitř byly nalezeny obleky dvou maskotů. Majitel je nezvěstný od roku 1997."},
	{"q": [1, 0], "t": "Náčelník Král: Byl to úmysl. Hledáme žháře", "d": "17. 7. 2023 · Policie ČR", "b": "Policejní náčelník Král potvrdil, že požár herny Voxie's byl založen úmyslně. „Ve skladu jsme našli kanystr od benzínu a stopy hořlaviny po celé podlaze. Záznam z kamery 7 někdo smazal ještě před požárem,“ uvedl Král. Policie hledá nočního hlídače, který budovu opustil v 6:00."},
	{"q": [1], "t": "Král: Žhář se vrací na místo činu", "d": "21. 7. 2023 · Regionální zprávy", "b": "„Hlídač je pořád někde v okolí. Svědci ho viděli u vyhořelé herny v noci, s baterkou,“ řekl náčelník Král. Policie vypsala odměnu za informace. Bývalý noční hlídač z roku 1997, známý jen jako D., policii řekl, že nového hlídače „nikdy neviděl“."},
	{"q": [2, 0], "t": "1997: Majitel herny po oslavě zmizel", "d": "16. 6. 1997 · Archiv", "b": "Majitel Voxie's Fun Factory pan Vojtěch se nevrátil domů po narozeninové oslavě 14. června. Policie našla jen jeho auto na parkovišti. Herna byla uzavřena, animatronici zůstali uvnitř. Klíč od kanceláře se nenašel."},
	{"q": [3, 2], "t": "Pátrání po devítileté Emě ukončeno", "d": "30. 6. 1997 · Archiv", "b": "Policie ukončila pátrání po devítileté Emě, která se ztratila během oslavy v herně Voxie's. Svědci tvrdí, že ji naposledy viděli u animatronické králice Cocoy. Otec dívky, majitel herny, je rovněž nezvěstný."},
	{"q": [4, 5], "t": "Voxie's Fun Factory: historie (1980–2023)", "d": "Encyklopedie herních sálů", "b": "1980 – první Voxie, robotický medvěd, byl po stížnostech deaktivován (prý se v noci hýbal sám). 1993 – herna znovu otevřena, Voxie jako kostým s pružinovými zámky (springlock); prototyp s přezdívkou Glitch skončil ve skladu. 1997 – přibyla Cocoa a dutý kostým Hollow Bunny. 14. 6. 1997 – oslava, zmizení majitele. 2023 – požár."},
	{"q": [5, 4], "t": "Hollow Bunny: kostým, který nikdo nechtěl nosit", "d": "Fórum fanoušků · příspěvek uživatele ema_fan", "b": "Hollow Bunny byl dutý králičí kostým bez kostry. Měl se na oslavě v roce 1997 objevit poprvé. Na fotkách z té noci ale stojí v rohu herny sám – a nikdo si nepamatuje, kdo v něm byl."},
]
const FIRE_LOG := [[0.0, "6:00", "Hlídač odchází z budovy.", ""], [2.5, "6:02", "Sklad: zážeh. Kanystr od benzínu.", "4"], [5.0, "6:04", "Oheň se šíří do bludiště.", "3"], [7.5, "6:06", "Herna s automaty v plamenech.", "1B"], [10.0, "6:08", "Pódium hoří. Voxie stojí uprostřed.", "1A"], [12.0, "6:09", "Pizzerie a výdej lístků.", "2"], [14.0, "6:10", "Chodby a toalety.", "8"], [16.0, "6:11", "Propadá se strop nad hernou.", "5"], [18.0, "6:12", "Hasiči na místě. Kamera 7 vypadla.", "7"]]
const FIRE_ROOMS := {"4": 2.5, "9": 3.5, "3": 5.0, "1B": 7.5, "1A": 10.0, "2": 12.0, "6": 13.0, "8": 14.0, "5": 15.0, "TY": 16.5, "7": 18.0}

func win98_frame(x: float, y: float, w: float, h: float, title: String) -> void:
	bevel(x, y, w, h)
	for i in 40:
		var k = i / 40.0
		rect(x + 4 + (w - 8) * k, y + 4, (w - 8) / 40.0 + 1, 24, Color(0, 0, 0.5).lerp(Color(0.06, 0.52, 0.82), k))
	txt(title, x + 12, y + 22, 15, "#ffffff")
	for i in 3:
		bevel(x + w - 70 + i * 22, y + 7, 20, 18)
		txt(["_", "□", "×"][i], x + w - 60 + i * 22, y + 21, 13, "#000000", "center")
	add_btn(x + w - 26, y + 7, 20, 18, "wclose", func():
		pc.app = "cam"
		_stop_tape())

func app_window(G, wx: float, wy: float, ww: float, wh: float, t: float) -> void:
	match pc.app:
		"web": web_app(wx, wy, ww, wh)
		"tapes": tapes_app(wx, wy, ww, wh)
		"fire": fire_app(wx, wy, ww, wh)
		"bin": bin_app(wx, wy, ww, wh)

func web_app(x: float, y: float, w: float, h: float) -> void:
	win98_frame(x, y, w, h, "🌐 Internet Explorer – Hledat")
	txt("Soubor   Úpravy   Zobrazit   Oblíbené", x + 10, y + 46, 13, "#000000")
	bevel(x + 8, y + 54, w - 16, 26, true, "#ffffff")
	var url = "http://www.hledej.cz/" + ("clanek" if pc.art != null else "?q=" + pc.q.replace(" ", "+"))
	txt("Adresa: " + url, x + 14, y + 72, 13, "#000000")
	var cx = x + 10
	var cy = y + 88
	var cw = w - 20
	var ch = h - 100
	rect(cx, cy, cw, ch, "#ffffff")
	if pc.art != null:
		var A = ARTICLES[pc.art]
		w98_btn(cx + 10, cy + 10, 110, 28, "◀ Zpět", "wback", func(): pc.art = null)
		txt(A.t, cx + 20, cy + 76, 24, "#000080")
		txt(A.d, cx + 20, cy + 100, 13, "#666666")
		wrap_txt(A.b, cx + 20, cy + 134, cw - 40, 17, "#000000")
		return
	txt("hledej.cz", cx + cw / 2, cy + 50, 34, "#0000aa", "center")
	bevel(cx + cw / 2 - 240, cy + 66, 480, 30, true, "#ffffff")
	txt(pc.q if pc.q != "" else "Vyber hledaný výraz…", cx + cw / 2 - 230, cy + 87, 15, "#000000" if pc.q != "" else "#888888")
	for i in SEARCH.size():
		var qi = i
		w98_btn(cx + 20 + (i % 3) * ((cw - 40) / 3.0), cy + 106 + floor(i / 3.0) * 36, (cw - 40) / 3.0 - 8, 30, "🔎 " + SEARCH[i], "q" + str(i), func():
			pc.q = SEARCH[qi]
			game.audio.sfx("click"), true, 13)
	if pc.q == "":
		return
	var qi = SEARCH.find(pc.q)
	var yy = cy + 196
	txt("Výsledky hledání „" + pc.q + "“:", cx + 20, yy, 15, "#000000")
	yy += 14
	for i in ARTICLES.size():
		var A = ARTICLES[i]
		if not A.q.has(qi):
			continue
		var ai = i
		txt(A.t, cx + 24, yy + 22, 17, "#0000ee")
		draw_line(Vector2(cx + 24, yy + 25), Vector2(cx + 24 + tw(A.t, 17), yy + 25), C("#0000ee"), 1)
		txt(A.d, cx + 24, yy + 42, 12, "#008000")
		add_btn(cx + 20, yy + 4, cw - 40, 42, "art" + str(i), func():
			pc.art = ai
			game.audio.sfx("click"))
		yy += 52

func tapes_app(x: float, y: float, w: float, h: float) -> void:
	win98_frame(x, y, w, h, "📼 Nahrávky D. – diktafon (1997)")
	bevel(x + 8, y + 40, w - 16, h - 50, true, "#ffffff")
	txt("Nalezeno na disku: D_NAHRAVKY\\ (5 souborů)", x + 20, y + 66, 14, "#000000")
	for i in TAPES_D.size():
		var yy = y + 80 + i * 44
		var ti = i
		w98_btn(x + 20, yy, 44, 34, "■" if pc.tape == i else "▶", "tp" + str(i), func():
			if pc.tape == ti:
				_stop_tape()
			else:
				_play_tape(ti), true, 16)
		txt("PASKA_" + str(i + 1) + ".WAV   " + TAPES_D[i][0], x + 76, yy + 23, 15, "#000080" if pc.tape == i else "#000000")
	if pc.tape >= 0:
		var len_ = 11.5
		pc.tapeT += game.frame_dt
		var k = clampf(pc.tapeT / len_, 0, 1)
		bevel(x + 20, y + 310, w - 40, 22, true)
		rect(x + 24, y + 314, (w - 48) * k, 14, "#000080")
		wrap_txt("D.: „" + TAPES_D[pc.tape][1] + "“", x + 24, y + 360, w - 48, 16, "#000000")
		if k >= 1:
			pc.tape = -1

func _play_tape(i: int) -> void:
	_stop_tape()
	pc.tape = i
	pc.tapeT = 0.0
	tape_player = game.audio._play(load("res://voice/tape_d" + str(i) + ".wav"), 1.0, 0.0)
func _stop_tape() -> void:
	if tape_player and is_instance_valid(tape_player):
		tape_player.queue_free()
	tape_player = null
	pc.tape = -1

func fire_app(x: float, y: float, w: float, h: float) -> void:
	win98_frame(x, y, w, h, "🎞 Přehrávač médií – POZAR_CAM7.AVI")
	if pc.fireOn:
		pc.fireT = minf(20.0, pc.fireT + game.frame_dt)
		if pc.fireT >= 20.0:
			pc.fireOn = false
	var vx = x + 12
	var vy = y + 38
	var vw = w - 300
	var vh = h - 110
	rect(vx, vy, vw, vh, "#000000")
	# půdorys herny a šíření ohně
	var sc = minf(vw / 410.0, vh / 290.0)
	save_()
	translate(vx + (vw - 396 * sc) / 2, vy + 8)
	scale_(sc, sc)
	for id in game.D.MAP:
		var r = game.D.MAP[id]
		var ft = FIRE_ROOMS.get(id, 99.0)
		var burn = clampf((pc.fireT - ft) / 2.0, 0, 1)
		rect(r[0], r[1], r[2], r[3], Color(0.15, 0.15, 0.15).lerp(Color(0.9, 0.3 + randf() * 0.25, 0.05), burn * (0.75 + randf() * 0.25)))
		draw_rect(Rect2(r[0], r[1], r[2], r[3]), C("#555555"), false, 1)
		txt(id, r[0] + r[2] / 2, r[1] + r[3] / 2 + 5, 12, "#ffffff", "center")
		if burn > 0:
			for k in int(burn * 6):
				rect(r[0] + randf() * r[2], r[1] + randf() * r[3], 5, 5, ["#ffe46b", "#ff8a1a", "#c0200a"][randi() % 3])
	restore_()
	noise_rect(0.12, vx, vy, vw, vh)
	txt("CAM 7 · REC", vx + 10, vy + 20, 14, "#ffffff")
	var cur = FIRE_LOG[0]
	for e in FIRE_LOG:
		if pc.fireT >= e[0]:
			cur = e
	txt("6:" + "%02d" % int(pc.fireT * 0.6) + "  " + cur[2], vx + 10, vy + vh - 12, 15, "#ffe46b")
	# ovládání přehrávače
	bevel(vx, vy + vh + 8, vw, 22, true)
	rect(vx + 4, vy + vh + 12, (vw - 8) * pc.fireT / 20.0, 14, "#000080")
	w98_btn(vx, vy + vh + 36, 90, 30, "❚❚" if pc.fireOn else "▶", "fplay", func():
		if pc.fireT >= 20.0:
			pc.fireT = 0.0
		pc.fireOn = not pc.fireOn, true, 15)
	w98_btn(vx + 100, vy + vh + 36, 90, 30, "⏮", "frew", func(): pc.fireT = 0.0, true, 15)
	# protokol
	var lx = x + w - 280
	bevel(lx, vy, 268, vh + 66, true, "#ffffff")
	txt("Časová osa požáru:", lx + 10, vy + 22, 14, "#000000")
	for i in FIRE_LOG.size():
		var e = FIRE_LOG[i]
		var on = pc.fireT >= e[0]
		txt(e[1] + " " + e[2], lx + 10, vy + 46 + i * 34, 11, "#000000" if on else "#aaaaaa")
	txt("Policie ČR · náčelník Král: záznam zajištěn", lx + 10, vy + vh + 56, 10, "#800000")

func bin_app(x: float, y: float, w: float, h: float) -> void:
	win98_frame(x, y, w, h, "🗑 Koš")
	bevel(x + 8, y + 40, w - 16, h - 50, true, "#ffffff")
	var items = [["📄", "zaznam_cam7_14-07-2023.avi", "Nelze obnovit: soubor byl přepsán."], ["📄", "smena_d_1997.txt", "„Klíč od kanceláře vrátit majiteli.“ – nikdy neodesláno"], ["📄", "pojistka_herna.doc", "Pojistná smlouva na budovu. Navýšena týden před požárem. Podpis nečitelný."]]
	for i in items.size():
		txt(items[i][0], x + 30, y + 86 + i * 70, 26, "#000000")
		txt(items[i][1], x + 70, y + 76 + i * 70, 15, "#000080")
		txt(items[i][2], x + 70, y + 98 + i * 70, 13, "#444444")

func noise_rect(a: float, x: float, y: float, w: float, h: float) -> void:
	if a > 0:
		draw_texture_rect(noise_frames[randi() % 5], Rect2(x, y, w, h), false, Color(1, 1, 1, minf(1, a) * alpha))

func task_line(x: float, y: float) -> void:
	var G = game.G
	var st = game.cur_task()
	if st:
		txt("Úkol: " + st.name + " → " + game.CAMS.get(st.room, st.room), x, y, 16, "#ffe46b")
	elif game.tasks(G.night).size() and not G.custom:
		txt("✓ Úkol noci splněn", x, y, 16, "#5dff8a")

func draw_roam(t: float) -> void:
	var G = game.G
	vignette(0.75)
	if G.cut:
		draw_cut(t)
		return
	if G.egg and G.egg.sub != "":
		rr(HW / 2 - 380, 600, 760, 62, 10, Color(0, 0, 0, 0.75))
		txt(G.egg.sub, HW / 2, 638, 20, "#ffffff", "center")
	txt(clock_s(), HW - 24, 54, 46, "#ffffff", "right")
	txt("Noc " + str(G.night) + " · budova", 24, 42, 22, "#ff8b8b")
	bat_bar(G)
	rect(24, 88, 180, 6, "#222222")
	rect(24, 88, 180 * G.rp.st, 6, "#6bc8ff")
	var sc = 0.45
	var mx = 24.0
	var my = 104.0
	rect(mx - 4, my - 4, 396 * sc + 8, 270 * sc + 8, Color(0, 0, 0, 0.6))
	var st = game.cur_task()
	for id in game.D.MAP:
		var r = game.D.MAP[id]
		draw_rect(Rect2(mx + r[0] * sc, my + r[1] * sc, r[2] * sc, r[3] * sc), C("#ffe46b" if (st and st.room == id and sin(t * 6) > 0) else "#663333"), false, 1.5)
	var px = mx + map_x(G.rp.x) * sc
	var py = my + map_y(G.rp.z - game.RZ) * sc
	circle(px, py, 4, "#5dff8a")
	line(px, py, px - sin(G.rp.yaw) * 10, py - cos(G.rp.yaw) * 10, "#5dff8a", 1.5)
	task_line(24, my + 272 * sc + 24)
	if st and st.kind != "pick" and G.hold > 0:
		rr(HW / 2 - 160, 560, 320, 18, 6, "#111111")
		rect(HW / 2 - 157, 563, 314 * G.hold / st.t, 12, "#ffe46b")
	if G.vox.lit > 0:
		txt("Voxie couvá…", HW / 2, 540, 18, "#ffb0b0", "center")
	txt("🔦 baterka svítí", HW - 30, 620, 16, "#fff3c4", "right")
	btn(HW - 150, 400, 120, 90, "▲ SKOK", "jump", game.roam_jump, true, 18, "#6bc8ff")
	if G.hsReady:
		btn(HW / 2 - 150, 540, 300, 64, "🤝 PODAT RUKU", "hs", game.start_hs, true, 22, "#8fe0ff")
	elif G.get("giveReady", false):
		btn(HW / 2 - 170, 540, 340, 64, "📷 DÁT VOXIEMU FOTKY (" + str(G.photos) + ")", "give", game.give_photos, true, 20, "#ffe46b")
	if G.can and not G.egg:
		btn(HW - 280, 540, 256, 56, "🔥 POLÍT A PODPÁLIT", "burn", game.start_burn, true, 17, "#ff7020")
	if game.near_desk():
		btn(HW / 2 - 160, 640, 320, 56, "🪑 ZPĚT KE STOLU", "back", game.back_desk, true, 18, "#5dff8a")
	if joy:
		ring(joy.ox, joy.oy, 70, Color(1, 1, 1, 0.5), 3)
		circle(joy.ox + joy.dx * 70, joy.oy + joy.dy * 70, 26, Color(1, 1, 1, 0.5))
	else:
		txt("◀ vlevo: chůze (na doraz = běh) · vpravo: rozhlížení ▶", HW / 2, 700, 14, "#777777", "center")
	var sp = game.speech
	if sp and sp.t < sp.dur:
		rr(HW / 2 - 380, 140, 760, 86, 10, Color(0.08, 0, 0, 0.8))
		txt(sp.get("who", "Vojtěch"), HW / 2 - 364, 162, 15, "#ff5050")
		wrap_txt(sp.text, HW / 2 - 364, 188, 728, 17, "#ffd8d8")
	if G.msgT > 0:
		save_()
		alpha = minf(1, G.msgT)
		txt(G.msg, HW / 2, 110, 20, "#ffd0d0", "center")
		restore_()
	if G.out:
		rect(0, 0, HW, HH, Color(0, 0, 0, minf(0.92, G.outT * 0.2)))

# ---------------------------------------------------------------- INVENTÁŘ (nové)
const INV_INFO := {
	"can": ["🛢", "Kanystr s benzínem", "Plný. Zapalovač máš v kapse. V budově se dá všechno polít a podpálit."],
	"draw": ["🖍", "Dětská kresba", "Ohořelá kresba z bludiště. Medvěd a malá holka. Podepsáno: „TÁTA“. Dej ji Voxiemu při podání ruky."],
	"head": ["🐰", "Cocoina hlava", "Ohořelá hlava Cocoy. Z krku visí kabely. Uvnitř je škrábanec: EMA, 9 LET."],
	"photo0": ["📷", "Fotka: pódium 1996", "Pan Vojtěch s Emou na pódiu. Ještě bez obleku."],
	"photo1": ["📷", "Fotka: Emy narozeniny", "Ema s Cocoou na oslavě. Cocoa vypadá, jako by se usmívala."],
	"photo2": ["📷", "Fotka: rodina", "Rodinná fotka před hernou. Na zadní straně: „Táta, Ema a já.“"],
}
func draw_inventory(t: float) -> void:
	var G = game.G
	if G.cut or game.S != "play":
		return
	if not G.mon:
		btn(HW - 200, 96, 176, 48, "🎒 INVENTÁŘ (" + str(G.inv.size()) + ")", "inv", func():
			inv_open = not inv_open
			inspect = null
			game.audio.sfx("click"), true, 16, "#c0a0ff")
	if not inv_open:
		return
	if inspect != null:
		draw_inspect(t)
		return
	rr(HW / 2 - 360, 150, 720, 430, 14, Color(0.06, 0.02, 0.08, 0.92), "#c0a0ff", 2)
	txt("INVENTÁŘ", HW / 2, 192, 30, "#c0a0ff", "center")
	if G.inv.is_empty():
		txt("Zatím nic. Hledej po budově (kanystr, kresba, Cocoina hlava, fotky).", HW / 2, 360, 17, "#aaaaaa", "center")
	for i in G.inv.size():
		var id: String = G.inv[i]
		var info = INV_INFO.get(id, ["?", id, ""])
		var x = HW / 2 - 330 + (i % 3) * 222
		var y = 220 + floor(i / 3.0) * 160
		rr(x, y, 210, 146, 10, Color(0, 0, 0, 0.5), "#664488", 1)
		txt(info[0], x + 105, y + 52, 40, "#ffffff", "center")
		txt(info[1], x + 105, y + 86, 14, "#ffd8ff", "center")
		var iid = id
		btn(x + 30, y + 100, 150, 36, "🔍 PROHLÉDNOUT", "insp" + id, func():
			inspect = {"id": iid, "rx": 0.2, "ry": 0.0}
			game.audio.sfx("click"), true, 14, "#c0a0ff")
	btn(HW / 2 - 100, 530, 200, 40, "ZAVŘÍT", "invx", func(): inv_open = false, true, 16, "#c0a0ff")

## prohlídka předmětu: Cocoina hlava ve 3D (táhni prstem = otáčení)
func draw_inspect(t: float) -> void:
	var id: String = inspect.id
	var info = INV_INFO.get(id, ["?", id, ""])
	rect(0, 0, HW, HH, Color(0, 0, 0, 0.55))
	rr(HW - 470, 150, 440, 380, 14, Color(0.06, 0.02, 0.08, 0.92), "#c0a0ff", 2)
	txt(info[1], HW - 250, 196, 24, "#c0a0ff", "center")
	wrap_txt(info[2], HW - 450, 240, 400, 17, "#ffffff")
	if id.begins_with("photo"):
		var n: Node3D = game.photo_nodes[int(id.right(1))]
		draw_texture_rect(n.get_meta("tex"), Rect2(140, 140, 320, 400), false)
	elif id == "draw":
		draw_texture_rect(load("res://models/kresba.png"), Rect2(80, 200, 500, 330), false)
	else:
		txt("táhni prstem pro otáčení", 330, 600, 16, "#aaaaaa", "center")
	btn(HW - 350, 460, 200, 48, "← ZPĚT", "inspx", func(): inspect = null, true, 16, "#c0a0ff")

# ---------------------------------------------------------------- menu a obrazovky
func draw_menu(t: float) -> void:
	rect(0, 0, HW, HH, Color(0, 0, 0, 0.55))
	noise(0.08 + (0.2 if randf() < 0.05 else 0.0))
	vignette(0.9)
	draw_logo(60, 40, 150)
	for i in 6:
		txt("NIGHT AT", 230 + cos(i) * 2, 100 + sin(i) * 2, 40, Color(1, 0.12, 0.12, 0.12))
	txt("NIGHT AT", 230, 100, 40, "#ff8080")
	txt("VOXIE'S", 230, 178, 80, "#ff3030")
	txt("2", 610, 178, 80, "#ffffff")
	neon("REMASTERED", 760, 120, 30, "#ffb030", 16)
	txt("Zbylo jen to, co shořelo. A on.", 234, 208, 17, "#cccccc")
	var un: int = game.st_get("v2_night", 1)
	if game.menu_night > un:
		game.menu_night = un
	btn(60, 240, 400, 56, "▶ HRÁT NOC " + str(game.menu_night), "play", func(): game.start_night(game.menu_night), true, 22)
	for i in range(1, 8):
		var n = i
		btn(60 + (i - 1) * 57.5, 306, 51, 44, str(i) if i <= un else "🔒", "n" + str(i), func():
			game.menu_night = n
			game.audio.sfx("click"), i <= un, 18, "#ffe46b" if i == game.menu_night else "#ff3b3b")
	btn(60, 360, 195, 48, "★ EXTRAS", "ex", func():
		game.S = "extras"
		game.scene_t = 0.0
		EX.page = "chars"
		EX.scare = -1.0, true, 18)
	btn(265, 360, 195, 48, "🛠 DEV", "dev", func():
		game.S = "devmenu"
		game.scene_t = 0.0, true, 18)
	btn(470, 360, 230, 48, "⚙ CUSTOM NIGHT", "cust", func():
		game.S = "custom"
		game.scene_t = 0.0, true, 18, "#ffb030")
	var e: int = game.st_get("v2_end", 0)
	txt(("★ Dohráno · " + ("srdce zhaslo" if e == 5 else "herna žije")) if e else "★ Odemčeno nocí: " + str(un) + " / 7", 64, 436, 17, "#ffe46b")
	var lines = ["Žádné dveře ani proud. Jen počítač na baterii.", "🔦 Voxie v díře ve zdi: drž baterku, dokud necouvne.", "🖥 Kamery ukazují budovu, ale signál vypadává – kontroluj všechny.", "🔊 Zvukem ho odlákáš do vzdálenější místnosti.", "👁 Stínová Cocoa: osviť ji, jinak vysaje baterii.", "🚶 Odejdi od stolu (díra přes toalety). 🎒 Inventář, ▲ skok, 📷 fotky pro Voxieho."]
	for i in lines.size():
		txt(lines[i], 64, 476 + i * 28, 16, "#ffcfcf")
	txt("v2.0.0 · Godot", HW - 20, 700, 14, "#666666", "right")

func draw_intro() -> void:
	var G = game.G
	var st: float = game.scene_t
	rect(0, 0, HW, HH, "#000000")
	save_()
	alpha = clampf(minf(st, 3 - st) * 1.5, 0, 1)
	if G.night == 1:
		txt("O týden později.", HW / 2, 300, 34, "#ffffff", "center")
		txt("Herna Voxie's je vyhořelá. Policie hledá nočního hlídače.", HW / 2, 350, 20, "#cccccc", "center")
		txt("A ty ses vrátil. Protože tě někdo zavolal jménem.", HW / 2, 382, 20, "#ff8080", "center")
	else:
		var L = ["", "", "Pořád to tu jiskří.", "Kamery šeptají tvoje jméno.", "Někdo přepsal záznamy z té noci.", "Herna dýchá.", "Slyšíš kroky i ve dne.", "Poslední noc.", "Voxie " + str(game.CUST.v) + " · Cocoa " + str(game.CUST.c)]
		txt(L[G.night], HW / 2, 330, 30, "#ff8080", "center")
	alpha = clampf(minf(st - 3, 6 - st) * 1.5, 0, 1)
	txt("0:00", HW / 2, 330, 90, "#ffffff", "center")
	txt("Custom Night" if G.custom else "Noc " + str(G.night), HW / 2, 400, 40, "#ff8080", "center")
	restore_()
	noise(0.06)

## úvod 1. noci: hráč prochází zbořenou kanceláří a zapíná VOXIE-CAM
func draw_boot(t: float) -> void:
	var st: float = game.scene_t
	vignette(0.8)
	if st < 2:
		rect(0, 0, HW, HH, Color(0, 0, 0, 1 - st / 2))
	var cur = null
	for s in game.BOOT_SUB:
		if st >= s[0] and st < s[0] + 3.6:
			cur = s
	if cur:
		rr(HW / 2 - 380, 600, 760, 62, 10, Color(0, 0, 0, 0.72))
		txt("Ty", HW / 2 - 364, 620, 14, "#9fd0ff")
		txt(cur[1], HW / 2, 648, 20, "#ffffff", "center")
	if st > 19.2 and st < 21:
		noise(0.15)
	if st > 33:
		rect(0, 0, HW, HH, Color(0, 0, 0, clampf((st - 33) / 2, 0, 1)))
	btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "bskip", func(): game.scene_t = 35.0, true, 16)

func draw_end(win: bool) -> void:
	var G = game.G
	var st: float = game.scene_t
	rect(0, 0, HW, HH, "#000000")
	noise(0.05 if win else maxf(0.15, 0.8 - st))
	if win:
		neon("6:00", HW / 2, 300, 110, "#ffe46b", 20)
		if G.custom:
			txt("Custom Night přežita! Voxie " + str(game.CUST.v) + " · Cocoa " + str(game.CUST.c) + " · skóre " + str((game.CUST.v + game.CUST.c) * 10), HW / 2, 380, 24, "#ffffff", "center")
		else:
			txt("Srdce herny zhaslo. Bylo ticho." if G.heartOff else "Přežil jsi " + str(G.night) + ". noc ve zbytcích Voxie's.", HW / 2, 380, 24, "#ffffff", "center")
	else:
		txt("KONEC", HW / 2, 280, 80, "#ff3030", "center")
		txt("Zničený Voxie tě našel." if G.killer == "V" else "Stín tě pohltil.", HW / 2, 340, 24, "#ffffff", "center")
	if st > 1.5:
		if G.custom:
			if win:
				btn(HW / 2 - 200, 584, 400, 56, "▶ KONEC 2", "end2", func():
					game.news_end = 2
					game.st_set("v2_end", 2)
					game.S = "news"
					game.scene_t = 0.0, true, 20, "#ffb030")
			btn(HW / 2 - 200, 440, 400, 56, "↻ ZNOVU CUSTOM NIGHT", "again", game.start_custom)
		elif win:
			btn(HW / 2 - 200, 440, 400, 56, "▶ NOC " + str(G.night + 1) if G.night < 7 else "▶ POKRAČOVAT", "again", func():
				if game.G.night < 7:
					game.start_night(game.G.night + 1)
				else:
					game.start_finale())
		else:
			btn(HW / 2 - 200, 440, 400, 56, "ZNOVU NOC " + str(G.night), "again", func(): game.new_game())
		btn(HW / 2 - 200, 512, 400, 56, "MENU", "menu", game.to_menu)

func draw_custom(t: float) -> void:
	var CU: Dictionary = game.CUST
	rect(0, 0, HW, HH, Color(0, 0, 0, 0.72))
	vignette(0.8)
	neon("CUSTOM NIGHT", HW / 2, 110, 54, "#ffb030", 20)
	txt("Nastav, jak moc aktivní budou (0–20). Úkoly se neplní, jen přežij do 6:00.", HW / 2, 150, 17, "#dddddd", "center")
	var rows = [["v", "Zničený Voxie", "Leze do díry ve zdi. Drž na něj baterku. Zvukem ho odlákáš.", "#ff5050"], ["c", "Stínová Cocoa", "Zjeví se v kanceláři a vysává baterii. Posviť na ni.", "#c0a0ff"]]
	for i in 2:
		var k: String = rows[i][0]
		var y = 210.0 + i * 150
		rr(HW / 2 - 400, y, 800, 130, 12, Color(0.12, 0.03, 0.03, 0.8))
		txt(rows[i][1], HW / 2 - 380, y + 40, 26, rows[i][3])
		txt(rows[i][2], HW / 2 - 380, y + 74, 15, "#cccccc")
		btn(HW / 2 + 140, y + 34, 64, 56, "−", "cm" + k, func():
			CU[k] = maxi(0, CU[k] - 1)
			game.st_set("v2r_cust", CU), true, 28)
		txt(str(CU[k]), HW / 2 + 260, y + 76, 40, "#ffffff", "center")
		btn(HW / 2 + 316, y + 34, 64, 56, "+", "cp" + k, func():
			CU[k] = mini(20, CU[k] + 1)
			game.st_set("v2r_cust", CU), true, 28)
	for i in 3:
		var v = [0, 10, 20][i]
		btn(HW / 2 - 400 + i * 140, 530, 130, 48, str(v) + "/" + str(v), "cpr" + str(i), func():
			CU.v = v
			CU.c = v
			game.st_set("v2r_cust", CU), true, 18, "#ffb030")
	txt("Skóre " + str((CU.v + CU.c) * 10) + " · nejlepší " + str(game.st_get("v2r_cbest", 0)), HW / 2 + 400, 562, 18, "#ffe46b", "right")
	btn(HW / 2 - 400, 610, 520, 64, "▶ HRÁT CUSTOM NIGHT", "cgo", game.start_custom, true, 22, "#5dff8a")
	btn(HW / 2 + 140, 610, 260, 64, "← MENU", "cb", game.to_menu, true, 20)

# ---------------------------------------------------------------- DEV
func draw_dev(t: float) -> void:
	var DEV: Dictionary = game.DEV
	var G = game.G
	if not DEV.on:
		return
	btn(HW - 120, 150, 96, 34, "DEV ✕" if DEV.panel else "DEV", "devp", func(): DEV.panel = not DEV.panel, true, 16, "#5dff8a")
	if not DEV.panel:
		return
	var x = 20.0
	var y = 110.0
	rr(x, y, 390, 470, 10, Color(0, 0.04, 0.016, 0.88), "#5dff8a", 1)
	var v = G.vox
	txt("čas %.1f s (%d:00) · baterie %.1f %%" % [G.t, game.hour(), G.bat], x + 12, y + 22, 13, "#ffffff")
	txt("Voxie: " + str(game.ROUTE[v.i]) + " krok " + str(v.i) + " díra %.1f" % v.holeT, x + 12, y + 39, 13, "#9fffb8")
	txt("Cocoa: " + ("V KANCELÁŘI" if G.coc.on else "za %d s" % int(G.coc.t)), x + 12, y + 56, 13, "#9fffb8")
	var B = [
		["+1 HODINA", func(): game.G.t = minf(6 * game.HOUR - 1, game.G.t + game.HOUR)], ["SKOK NA 6:00", func(): game.G.t = 6 * game.HOUR - 0.1], ["BATERIE 100", func():
			game.G.bat = 100.0
			game.G.out = false],
		["GOD", func(): DEV.god = not DEV.god], ["ZMRAZIT AI", func(): DEV.freeze = not DEV.freeze], ["STABILNÍ SIGNÁL", func(): game.G.stable = not game.G.stable],
		["VOXIE → DÍRA", func(): game.vox_move(game.ROUTE.size() - 1)], ["VOXIE → PÓDIUM", func(): game.vox_move(0)], ["COCOA TEĎ", func(): game.G.coc.t = 0.0],
		["JUMPSCARE", func():
			var gd = DEV.god
			DEV.god = false
			game.jumpscare("V")
			DEV.god = gd], ["VYBÍT BATERII", func(): game.G.bat = 0.5], ["MENU", game.to_menu],
		["ÚKOL HOTOV", func():
			var st = game.cur_task()
			if st:
				game.task_done(st)], ["KE STOLU / ODEJÍT", func():
			if game.G.roam:
				game.back_desk()
			else:
				game.leave_desk()], ["NOC +1", func(): game.new_game(mini(7, game.G.night + 1))],
	]
	for i in B.size():
		btn(x + 10 + (i % 3) * 124, y + 90 + floor(i / 3.0) * 54, 118, 46, B[i][0], "dv" + str(i), B[i][1], true, 12, "#5dff8a")

func draw_dev_menu(t: float) -> void:
	var DEV: Dictionary = game.DEV
	rect(0, 0, HW, HH, Color(0, 0.03, 0.016, 0.9))
	var cx = HW / 2
	txt("🛠 DEV NÁSTROJE", cx, 110, 44, "#5dff8a", "center")
	txt("Night at Voxie's 2 v2.0.0 (Godot) · pro tvůrce a testování", cx, 142, 16, "#9fffb8", "center")
	btn(cx - 300, 190, 600, 54, "DEV PANEL VE HŘE: " + ("ZAP" if DEV.on else "VYP"), "dvon", func():
		DEV.on = not DEV.on
		game.st_set("v2_dev", DEV.on), true, 20, "#5dff8a")
	btn(cx - 300, 260, 600, 54, "▶ SPUSTIT NOC S DEV PANELEM", "dvgo", func():
		DEV.on = true
		DEV.panel = true
		game.new_game(game.menu_night), true, 20, "#5dff8a")
	btn(cx - 300, 330, 600, 54, "RESET POSTUPU", "dvr", func():
		for k in ["v2_won", "v2_night", "v2_end"]:
			game.store.erase(k)
		game.st_set("v2_dev", DEV.on), true, 20, "#5dff8a")
	btn(cx - 300, 400, 600, 54, "ODEMKNOUT VŠECHNY NOCI", "dvu", func(): game.st_set("v2_night", 7), true, 20, "#5dff8a")
	btn(cx - 300, 470, 600, 54, "▶ ÚVOD: ZAPNUTÍ VOXIE-CAM", "dvboot", func():
		game.new_game(1)
		game.start_boot(), true, 20, "#5dff8a")
	btn(cx - 150, 600, 300, 54, "← MENU", "dvb", game.to_menu, true, 20, "#5dff8a")

# ---------------------------------------------------------------- EXTRAS
func draw_extras(t: float) -> void:
	var tabs = [["chars", "POSTAVY"], ["map", "MAPA"]]
	if EX.page != "chars":
		rect(0, 0, HW, HH, Color(0.04, 0.008, 0.008, 0.92))
	txt("★ EXTRAS", 40, 60, 36, "#ff8080")
	for i in tabs.size():
		var id: String = tabs[i][0]
		btn(260 + i * 160, 26, 150, 44, tabs[i][1], "ext" + id, func():
			EX.page = id
			EX.scare = -1.0, true, 17)
		if EX.page == id:
			rect(260 + i * 160, 72, 150, 4, "#ff3030")
	btn(HW - 180, 26, 160, 44, "← MENU", "exb", game.to_menu, true, 17)
	if EX.page == "chars":
		var b = game.D.BIOS[EX.idx]
		var x = HW - 520
		rr(x, 110, 490, 470, 12, Color(0, 0, 0, 0.75))
		neon(b.name, x + 245, 160, 36, b.col, 16)
		txt(b.sub, x + 245, 190, 15, "#cccccc", "center")
		wrap_txt(b.text, x + 20, 230, 450, 17, "#ffffff")
		var anims = [["IDLE", "Idle"], ["POHYB", "Walk"], ["KULHÁNÍ", "Limp"]] if EX.idx == 0 else [["IDLE", "Idle"], ["POHYB", "Float"], ["ZMIZENÍ", "Vanish"]]
		txt("Animace:", x + 20, 432, 15, "#cccccc")
		for i in 3:
			var nm: String = anims[i][1]
			var cur: String = EX.vAnim if EX.idx == 0 else EX.cAnim
			btn(x + 20 + i * 156, 442, 146, 46, anims[i][0], "exa" + str(i), func():
				if EX.idx == 0:
					EX.vAnim = nm
				else:
					EX.cAnim = nm
				EX.at = 0.0
				EX.scare = -1.0, true, 16, "#ffb030" if cur == nm else "#ff3b3b")
		btn(x + 20, 500, 220, 56, "😱 JUMPSCARE" if EX.idx == 0 else "😱 LUNGE", "exj", func():
			EX.scare = 0.0
			game.scare_sound("V" if EX.idx == 0 else "C"), EX.scare < 0, 18)
		btn(x + 250, 500, 220, 56, "COCOA ▶" if EX.idx == 0 else "◀ VOXIE", "exn", func():
			EX.idx = 1 - EX.idx
			EX.scare = -1.0, true, 18)
		if EX.scare >= 0 and EX.scare < 0.05:
			rect(0, 0, HW, HH, "#ffffff")
	else:
		var sc = 1.5
		save_()
		translate(70, 110)
		scale_(sc, sc)
		for l in game.D.LINKS:
			var A = game.D.MAP[l[0]]
			var B2 = game.D.MAP[l[1]]
			line(A[0] + A[2] / 2, A[1] + A[3] / 2, B2[0] + B2[2] / 2, B2[1] + B2[3] / 2, Color(1, 0.31, 0.31, 0.25), 6)
		for id in game.D.MAP:
			var r = game.D.MAP[id]
			var sel = EX.room == id
			rect(r[0], r[1], r[2], r[3], "#7a1a1a" if sel else ("#3a1010" if id == "TY" else "#1a1414"))
			draw_rect(Rect2(r[0], r[1], r[2], r[3]), C("#ff6b6b" if sel else "#663333"), false, 2)
			txt(id, r[0] + r[2] / 2, r[1] + r[3] / 2 + 5, 13, "#ffffff", "center")
			var rid: String = id
			add_btn(r[0], r[1], r[2], r[3], "exr" + id, func(): EX.room = rid)
		restore_()
		var x = 740.0
		rr(x, 120, HW - x - 40, 420, 12, Color(0, 0, 0, 0.6))
		txt("Mapa vyhořelé herny", x + 20, 160, 24, "#ff8080")
		if EX.room != null:
			var rm: String = EX.room
			txt("Tvoje kancelář (zbořená)" if rm == "TY" else "CAM " + rm + " – " + game.CAMS.get(rm, rm), x + 20, 210, 19, "#ffb0b0")
			var info = "Jediný funkční počítač na baterii. Zbořená kancelář bez dveří: boční vchody zasypala suť, ven se dá jen dírou ve zdi přes toalety – a tudy chodí i Voxie." if rm == "TY" else ("Kamera po požáru funguje." if ["2", "5", "8"].has(rm) else "Kamera je spálená, dá se opravit přepojením kabelů.")
			if rm == "6":
				info = "Toalety. Prolomená zeď vede přímo do tvé kanceláře."
			wrap_txt(info, x + 20, 245, HW - x - 80, 17, "#ffffff")
		else:
			txt("Klepni na místnost.", x + 20, 210, 18, "#aaaaaa")
		txt("Voxie: Pódium → Herna → … → Toalety → díra", x + 20, 470, 14, "#ffb0b0")

# ---------------------------------------------------------------- minihry (před každou nocí)
const MSX := 960.0 / 44
const MSY := 480.0 / 36
func mpx(x: float) -> float:
	return (x + 22) * MSX
func mpy(z: float) -> float:
	return (z + 30) * MSY
func mini_pts(n: int) -> Array:
	var used = {}
	var out = []
	for p in game.D.MINIS[str(n)].pts:
		var id: String = game.D.MROOM.get(p[2], "1B")
		var r = game.RROOMS[id]
		used[id] = used.get(id, 0) + 1
		var k: int = used[id]
		out.append({"x": r.cx + (k - 2) * 1.6 * (1 if k > 1 else 0), "z": r.cz - game.RZ + (k - 1) * 0.9 - 0.4, "label": p[2], "text": p[3]})
	return out
func start_mini(n: int) -> void:
	var r7 = game.RROOMS["7"]
	var M = game.D.MINIS[str(n)]
	var fl = []
	if M.has("fire"):
		for i in int(round(14 * M.fire)) + 2:
			fl.append({"x": randf_range(-20, 20), "z": randf_range(-28, 4), "vx": randf_range(-1.5, 1.5), "vz": randf_range(-1.5, 1.5)})
	MG = {"n": n, "i": 0, "x": r7.cx, "z": r7.cz - game.RZ + 1, "msg": M.sub, "msgT": 3.0, "endT": -1.0, "walk": 0.0, "pts": mini_pts(n), "hurt": 0.0, "flames": fl}
	game.S = "mini"
	game.scene_t = 0.0
	game.audio.sfx("cam")
func mini_done() -> void:
	if MG.n == 1:
		game.start_home()
	else:
		game.new_game(MG.n)
func update_mini(dt: float) -> void:
	var M = game.D.MINIS[str(MG.n)]
	var RZ = game.RZ
	if MG.msgT > 0:
		MG.msgT -= dt
	if MG.hurt > 0:
		MG.hurt -= dt
	if MG.endT >= 0:
		MG.endT += dt
		if MG.endT > 4.5:
			mini_done()
		return
	var mx = joy.dx if joy else 0.0
	var my = joy.dy if joy else 0.0
	var k_ = game.keys
	if k_.get("a") or k_.get("left"):
		mx -= 1
	if k_.get("d") or k_.get("right"):
		mx += 1
	if k_.get("w") or k_.get("up"):
		my -= 1
	if k_.get("s") or k_.get("down"):
		my += 1
	var m = Vector2(mx, my).length()
	if m > 0.05:
		var k = 5 * dt * minf(1, m) / m
		var nx = MG.x + mx * k
		var nz = MG.z + my * k
		if game.walk_m(nx, MG.z + RZ):
			MG.x = nx
		if game.walk_m(MG.x, nz + RZ):
			MG.z = nz
		var w0 = MG.walk
		MG.walk += dt
		if floor(w0 * 4) != floor(MG.walk * 4):
			game.audio.sfx("step", 0.08)
	for f in MG.flames:
		f.x += f.vx * dt
		f.z += f.vz * dt
		if not game.walk_m(f.x, f.z + RZ):
			f.vx *= -1
			f.vz *= -1
			f.x += f.vx * dt * 2
			f.z += f.vz * dt * 2
		if MG.hurt <= 0 and Vector2(f.x - MG.x, f.z - MG.z).length() < 0.9:
			MG.hurt = 1.0
			game.audio.sfx("hurt")
			MG.msg = "Pálí to! Obejdi plameny."
			MG.msgT = 2.0
			MG.x += (MG.x - f.x) * 1.5
			MG.z += (MG.z - f.z) * 1.5
			if not game.walk_m(MG.x, MG.z + RZ):
				var r7 = game.RROOMS["7"]
				MG.x = r7.cx
				MG.z = r7.cz - RZ
	var p = MG.pts[MG.i] if MG.i < MG.pts.size() else null
	if p and Vector2(MG.x - p.x, MG.z - p.z).length() < 1.4:
		MG.msg = p.text
		MG.msgT = 5.0
		MG.i += 1
		game.audio.sfx("pick")
		if String(p.text).begins_with("Vojtěch"):
			game.audio.voice(String(p.text).replace("Vojtěch: ", ""), 0.5)
	if p == null and MG.msgT <= 2:
		MG.endT = 0.0
		game.scare_sound("V")
func px_man(x: float, y: float, shirt, hair, st := 0, s := 1.0) -> void:
	var R = func(a, b, w, h, c): rect(x + a * s, y + b * s, w * s, h * s, c)
	R.call(-5, -20, 10, 9, "#e0b090"); R.call(-5, -21, 10, 3, hair); R.call(-3, -17, 2, 2, "#111111"); R.call(1, -17, 2, 2, "#111111")
	R.call(-7, -11, 14, 12, shirt); R.call(-6, 1, 5, 8 + st * 2, "#141820"); R.call(1, 1, 5, 10 - st * 2, "#141820")
func px_vox(x: float, y: float) -> void:
	var R = func(a, b, w, h, c): rect(x + a, y + b, w, h, c)
	R.call(-12, -40, 7, 7, "#5a3716"); R.call(5, -40, 7, 7, "#5a3716"); R.call(-11, -35, 22, 18, "#8a5a2b"); R.call(-7, -30, 5, 5, "#f2f2ea"); R.call(3, -30, 5, 5, "#f2f2ea")
	R.call(-6, -22, 12, 4, "#2a1608"); R.call(-13, -17, 26, 22, "#8a5a2b"); R.call(-11, 5, 9, 12, "#6a4220"); R.call(2, 5, 9, 12, "#6a4220")
func px_coc(x: float, y: float, t: float) -> void:
	var R = func(a, b, w, h, c): rect(x + a, y + b, w, h, c)
	R.call(-8, -50, 5, 14, "#f0b0c8"); R.call(3, -50, 5, 14, "#f0b0c8"); R.call(-10, -37, 20, 16, "#f0b0c8"); R.call(-6, -32, 4, 4, "#3a1a2a"); R.call(2, -32, 4, 4, "#3a1a2a")
	R.call(-11, -21, 22, 22, "#e090b0"); R.call(-16 + sin(t * 6) * 3, -26, 5, 12, "#e090b0"); R.call(-9, 1, 7, 12, "#d080a0"); R.call(2, 1, 7, 12, "#d080a0")
func draw_mini(t: float) -> void:
	var M = game.D.MINIS[str(MG.n)]
	var RZ = game.RZ
	var ox = (HW - 960) / 2
	var oy = 120.0
	rect(0, 0, HW, HH, "#000000")
	txt("MINIHRA " + str(MG.n) + "/7 · " + M.title, HW / 2, 60, 30, "#ff5050", "center")
	txt(M.sub + " · herna Voxie's", HW / 2, 92, 16, "#aaaaaa", "center")
	save_()
	translate(ox, oy)
	rect(0, 0, 960, 480, "#0a0606")
	for id in game.RROOMS:
		var r = game.RROOMS[id]
		rect(mpx(r.x0) - 4, mpy(r.z0 - RZ) - 4, (r.x1 - r.x0) * MSX + 8, (r.z1 - r.z0) * MSY + 8, "#3a2430")
	var floor_ = func(x0, x1, z0, z1, alt):
		var x = floor(mpx(x0))
		while x < mpx(x1):
			var y = floor(mpy(z0))
			while y < mpy(z1):
				rect(x, y, minf(16, mpx(x1) - x), minf(16, mpy(z1) - y), alt[0] if (int(x / 16) + int(y / 16)) % 2 else alt[1])
				y += 16
			x += 16
	for id in game.RROOMS:
		var r = game.RROOMS[id]
		floor_.call(r.x0, r.x1, r.z0 - RZ, r.z1 - RZ, ["#3a1030", "#2a0a22"] if id == "1A" else (["#1e1a28", "#16121e"] if id == "TY" else ["#2a1c1c", "#201414"]))
	for d in game.DOORS + game.BZ:
		floor_.call(d.zone.x0, d.zone.x1, d.zone.z0 - RZ, d.zone.z1 - RZ, ["#2a1c1c", "#201414"])
	for f in MG.flames:
		for i in 6:
			rect(floor((mpx(f.x) + randf_range(-12, 12)) / 4) * 4, floor((mpy(f.z) + randf_range(-14, 6)) / 4) * 4, 8, 8, ["#ff3010", "#ff8020", "#ffd040"][randi() % 3])
	if M.get("fire", 0) >= 1:
		for i in 40:
			var fx = fmod(i * 157 + floor(t * 8) * 31, 960.0)
			var fy = 470 - fmod(i * 73 + t * 120, 200.0)
			rect(floor(fx / 8) * 8, floor(fy / 8) * 8, 8, 8, ["#ff3010", "#ff8020", "#ffd040"][randi() % 3])
	for i in MG.pts.size():
		var p = MG.pts[i]
		var done = i < MG.i
		var cur = i == MG.i
		var x = mpx(p.x)
		var y = mpy(p.z)
		if String(p.text).begins_with("Vojtěch"):
			px_man(x + 18, y, "#2a4a8a", "#5a3a20")
		if p.label == "COCOA" or (p.label == "PÓDIUM" and MG.n == 3):
			px_coc(x - 22, y, t)
		if p.label == "OBLEK" or p.label == "SRDCE":
			px_vox(x + 24, y)
		if p.label == "HASIČI":
			px_man(x - 20, y, "#8a1a10", "#222222")
			px_man(x + 20, y, "#8a1a10", "#222222")
		rect(x - 9, y - 9, 18, 18, "#333333" if done else (("#ffe46b" if sin(t * 6) > 0 else "#b08a20") if cur else "#5a3a3a"))
		txt(p.label, x, y - 14, 12, "#666666" if done else "#ffffff", "center")
	var px = floor(mpx(MG.x))
	var py = floor(mpy(MG.z))
	var a0 = alpha
	if MG.hurt > 0.5:
		alpha = 0.5
	px_man(px, py, "#20305a", "#3a2a1a", int(floor(MG.walk * 8)) % 2)
	alpha = a0
	var cp = MG.pts[MG.i] if MG.i < MG.pts.size() else null
	if cp:
		var a = atan2(mpy(cp.z) - py, mpx(cp.x) - px)
		draw_colored_polygon(PackedVector2Array([Vector2(px + cos(a) * 34, py + sin(a) * 34), Vector2(px + cos(a + 0.4) * 24, py + sin(a + 0.4) * 24), Vector2(px + cos(a - 0.4) * 24, py + sin(a - 0.4) * 24)]), C("#ffe46b"))
	draw_rect(Rect2(2, 2, 956, 476), C("#5a2020"), false, 4)
	restore_()
	if MG.hurt > 0.7:
		rect(0, 0, HW, HH, Color(1, 0.24, 0, 0.25))
	if MG.msgT > 0:
		save_()
		alpha = minf(1, MG.msgT)
		rr(HW / 2 - 400, 612, 800, 56, 10, Color(0.12, 0, 0, 0.85))
		txt(MG.msg, HW / 2, 648, 19, "#ffd8d8", "center")
		restore_()
	if MG.endT >= 0:
		if MG.endT < 1.2:
			rect(0, 0, HW, HH, "#ffffff" if MG.endT < 0.08 else Color(0.31, 0, 0, 0.8))
			var s2 = 22.0
			var cx = HW / 2 - 8 * s2
			var cy = 160.0
			for q in [[3, 3, 10, 9, "#3a2410"], [4, 5, 3, 3, "#000000"], [5, 6, 1, 1, "#ff1a1a"], [9, 5, 3, 3, "#e8e8e0"], [4, 12, 8, 3, "#100604"], [4, 12, 1, 1, "#dddddd"], [6, 12, 1, 1, "#dddddd"], [8, 12, 1, 1, "#dddddd"], [10, 12, 1, 1, "#dddddd"]]:
				rect(cx + q[0] * s2 + randf_range(-4, 4), cy + q[1] * s2 + randf_range(-4, 4), q[2] * s2, q[3] * s2, q[4])
			noise(0.3)
		else:
			rect(0, 0, HW, HH, "#000000")
			save_()
			alpha = clampf((MG.endT - 1.2) * 2, 0, 1)
			txt(M.end, HW / 2, 360, 24, "#ff8080", "center")
			restore_()
	else:
		btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "mskip", mini_done, true, 16)
		if joy:
			ring(joy.ox, joy.oy, 70, Color(1, 1, 1, 0.4), 3)
		else:
			txt("Táhni prstem / šipky – jdi za žlutou šipkou", HW / 2, 700, 14, "#888888", "center")

# ---------------------------------------------------------------- noviny, domov, finále, cutscény
func newspaper(x0: float, y0: float, w: float, h: float, t: float) -> void:
	var cx = HW / 2
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
	var P2 = 10.0
	rect(ix, iy, iw, ih, "#1a0e12")
	rect(ix + 40, iy + 110, 320, 160, "#2a2026")
	rect(ix + 40, iy + 100, 320, 12, "#3a2a30")
	for i in 14:
		rect(ix + 60 + (i % 7) * 42, iy + 130 + floor(i / 7.0) * 60, 26, 34, "#ffb030" if sin(t * 9 + i * 1.7) > 0.2 else "#ff6a1a")
	txt("VOXIE'S", ix + 200, iy + 96, 26, "#ff8bea", "center")
	for c in int(iw / P2):
		var hg = 6 + int(floor((sin(t * 6 + c * 0.9) + sin(t * 3.3 + c * 2.1) + 2) * 3.5))
		for r in hg:
			var yy = iy + 100 - r * P2
			if yy < iy:
				continue
			var fq = float(r) / hg
			rect(ix + c * P2, yy, P2, P2, "#ffe46b" if fq < 0.35 else ("#ff8a1a" if fq < 0.7 else "#c0200a"))
	draw_rect(Rect2(ix, iy, iw, ih), C("#111111"), false, 2)
	txt("Foto: hasiči na místě v 6:12", ix, iy + ih + 20, 13, "#444444")
	wrap_txt("Hasiči v troskách našli obleky dvou maskotů. Jeden z nich byl podle svědků ještě teplý. Pracovníci tvrdí, že slyšeli z trosek hrací skříňku. Policie hledá nočního hlídače, který podle záznamů opustil budovu v 6:00. Majitel herny je nezvěstný od roku 1997.", ix + iw + 30, iy + 14, w - iw - 90, 16, "#222222")
	rect(x0 + 20, y0 + h - 70, w - 40, 1, "#111111")
	txt("Týden poté ti zazvoní telefon…", cx, y0 + h - 30, 20, "#7a1010", "center")
func draw_paper1(t: float) -> void:
	rect(0, 0, HW, HH, "#0a0608")
	var k = game.ease_io(clampf(game.scene_t / 1.6, 0, 1))
	var cx = HW / 2
	save_()
	translate(cx, HH / 2)
	rotate_((1 - k) * -0.25 - 0.02)
	scale_(0.6 + 0.4 * k, 0.6 + 0.4 * k)
	translate(-cx, -HH / 2)
	newspaper(cx - 430, 30, 860, 660, t)
	restore_()
	noise(0.04)
	if game.scene_t > 2:
		btn(HW - 260, HH - 80, 236, 56, "POKRAČOVAT ▶", "pp", func(): game.start_night(paper_n), true, 18)

func draw_home(t: float) -> void:
	vignette(0.8)
	var s: float = game.scene_t
	if s < 2:
		rect(0, 0, HW, HH, Color(0, 0, 0, 1 - s / 2))
	if s < 1.5:
		txt("Týden po požáru. Tvůj byt.", HW / 2, 360, 26, "#ffffff", "center")
	if s > 1.5 and s < 20:
		rr(HW / 2 - 170, 40, 340, 70, 14, Color(0.04, 0.04, 0.08, 0.85))
		txt("📞 Příchozí hovor…" if s < 5.5 else "📞 Hovor " + str(int(s - 5.5)) + " s", HW / 2, 70, 20, "#9fd0ff", "center")
		txt("Neznámé číslo · herna Voxie's", HW / 2, 96, 14, "#aaaaaa", "center")
	var cur = null
	for c in game.D.CALL:
		if s >= c[0] and s < c[0] + 3.2:
			cur = c
	if cur and s < 20:
		rr(HW / 2 - 380, 600, 760, 60, 10, Color(0, 0, 0, 0.75))
		txt("Hlas v telefonu", HW / 2 - 364, 620, 14, "#9fd0ff")
		txt(cur[1], HW / 2, 648, 20, "#ffffff", "center")
	if s > 9.5 and s < 15.8 and game.home_reply == null:
		txt("Odpovědět:", HW / 2, 400, 16, "#9fd0ff", "center")
		for i in game.D.HC.size():
			var k: String = game.D.HC[i][0]
			btn(HW / 2 - 190, 420 + i * 58, 380, 48, game.D.HC[i][1], "hc" + k, func(): game.home_pick(k), true, 17, "#9fd0ff")
	if game.home_reply != null and s - game.home_reply.t < 3.6:
		rr(HW / 2 - 380, 530, 760, 54, 10, Color(0.04, 0.08, 0.16, 0.8))
		txt("Ty: " + game.home_reply.text, HW / 2, 565, 20, "#cfe8ff", "center")
	if s > 19.6 and s < 21.5:
		noise(0.25)
		txt("— hovor ukončen —", HW / 2, 360, 24, "#ff6060", "center")
	if s > 21.5 and s < 25:
		txt("Musím tam jet.", HW / 2, 640, 22, "#ffd0d0", "center")
	if s > 44:
		btn(HW / 2 - 200, 560, 400, 64, "🚗 JET DO PIZZERIE", "drive", func():
			game.home.visible = false
			game.audio.sfx("cam")
			game.new_game(1)
			game.start_boot(), true, 24)
	else:
		btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "hskip", func(): game.scene_t = 44.5, true, 16)

func draw_finale(t: float) -> void:
	vignette(0.75)
	var s: float = game.scene_t
	var heart = game.G != null and game.G.heartOff
	if s < 1.5:
		rect(0, 0, HW, HH, Color(0, 0, 0, 1 - s / 1.5))
	var cur = null
	for c in game.D.FIN_SUB:
		if s >= c[0] and s < c[0] + 3:
			cur = c
	if cur:
		rr(HW / 2 - 380, 600, 760, 62, 10, Color(0, 0, 0, 0.7))
		if cur[1] != "":
			txt(cur[1], HW / 2 - 364, 620, 14, "#d0a0ff")
		txt(cur[2], HW / 2, 648, 20, "#ffffff", "center")
	if not heart:
		var ca = null
		for c in game.D.FIN_A:
			if s >= c[0] and s < c[0] + 2.8:
				ca = c
		if ca:
			rr(HW / 2 - 380, 520, 760, 62, 10, Color(0.12, 0, 0, 0.7))
			if ca[1] != "":
				txt(ca[1], HW / 2 - 364, 540, 14, "#ff8080")
			txt(ca[2], HW / 2, 568, 20, "#ffffff", "center")
	if heart:
		if s > 48:
			rect(0, 0, HW, HH, Color(1, 1, 1, clampf((s - 48) / 3, 0, 1)))
	elif s > 51.5:
		rect(0, 0, HW, HH, Color(0, 0, 0, clampf((s - 51.5) / 1.3, 0, 1)))
		if s > 52.3:
			neon("HERNA ŽIJE", HW / 2, 360, 54, "#ff2020", 22)
	if not heart and s >= 48.8 and game.fin_pick == null:
		txt("Odpovědět Vojtěchovi:", HW / 2, 400, 16, "#ff8080", "center")
		for i in game.D.FIN_C.size():
			var k: String = game.D.FIN_C[i][0]
			btn(HW / 2 - 190, 420 + i * 58, 380, 48, game.D.FIN_C[i][1], "fc" + k, func(): game.fin_choose(k), true, 18, "#ff5050")
	if game.fin_pick != null and game.D.FIN_R.has(game.fin_pick) and s < 53:
		rr(HW / 2 - 380, 520, 760, 62, 10, Color(0.12, 0, 0, 0.75))
		txt("Vojtěch", HW / 2 - 364, 540, 14, "#ff8080")
		txt(game.D.FIN_R[game.fin_pick], HW / 2, 568, 20, "#ffffff", "center")
	btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "fskip", func():
		if game.fin_pick == null:
			game.fin_pick = "skip"
		game.scene_t = 53.0, true, 16)

func draw_cut(t: float) -> void:
	var c = game.G.cut
	var ct: float = c.t
	var SUB = game.cut_subs(c.k)
	vignette(0.7)
	var cur = null
	for s in SUB:
		if ct >= s[0] and ct < s[0] + 3:
			cur = s
	if cur:
		rr(HW / 2 - 380, 600, 760, 62, 10, Color(0, 0, 0, 0.72))
		if cur[1] != "":
			txt(cur[1], HW / 2 - 364, 620, 14, "#d0a0ff" if (cur[1] == "Cocoa" or cur[1] == "Ema") else "#ff8080")
		txt(cur[2], HW / 2, 648, 20, "#ffffff", "center")
	if c.k == "hs":
		if ct > 16:
			rect(0, 0, HW, HH, Color(1, 1, 1, clampf((ct - 16) / 2.5, 0, 1)))
	elif c.k == "fire":
		var a = 0.0
		if ct >= 9 and ct < 10.4:
			a = (ct - 9) / 1.4
		elif ct >= 10.4 and ct < 12:
			a = 1 - (ct - 10.4) / 1.6
		elif ct > 22.6:
			a = clampf((ct - 22.6) / 2, 0, 1)
		if a > 0:
			rect(0, 0, HW, HH, Color(0, 0, 0, a))
		if ct > 5 and ct < 9.6:
			rect(0, 0, HW, HH, Color(1, 0.31, 0, clampf((ct - 5) / 8, 0, 0.35)))
	if c.k != "photo":
		btn(HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "cskip", func(): game.end_cut(3 if c.k == "hs" else 4), true, 16)

func draw_news(t: float) -> void:
	var N = game.D.NEWS.get(str(game.news_end), game.D.NEWS["1"])
	rect(0, 0, HW, HH, "#0a0806")
	var x = HW / 2 - 420
	var y = 40.0
	rect(x, y, 840, 600, "#d8d0bc")
	txt("RANNÍ ZPRÁVY", x + 420, y + 56, 46, "#1a1410", "center")
	rect(x + 30, y + 72, 780, 3, "#1a1410")
	txt(N.h, x + 420, y + 124, 26 if N.h.length() > 36 else 30, "#000000", "center")
	txt(N.sub, x + 420, y + 156, 17, "#3a2a1a", "center")
	wrap_txt(N.b, x + 40, y + 200, 760, 17, "#1a1410")
	wrap_txt(N.t + (" Hlídač se prý druhý den vrátil." if (game.news_end == 1 and game.SV.fin == "back") else ""), x + 40, y + 430, 760, 17, N.tc)
	if game.scene_t > 3:
		neon(N.l, HW / 2, y + 540, 30, N.c, 14)
		btn(HW / 2 - 150, 652, 300, 54, "MENU", "nmenu", game.to_menu, true, 20)

# ---------------------------------------------------------------- VSTUP
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
	if b and b.id == "flash":
		if G and not G.out and not G.roam:
			G.flash = true
			flash_id = id
			game.audio.sfx("click")
		return
	if b:
		b.cb.call()
		return
	if inspect != null:
		drag = {"id": id, "x": p.x, "y": p.y, "insp": true}
		return
	if game.S == "intro":
		game.begin_play()
		return
	if game.S == "mini" or (game.S == "play" and G.roam and p.x < HW * 0.45):
		joy = {"id": id, "ox": p.x, "oy": p.y, "dx": 0.0, "dy": 0.0}
		return
	if game.S == "play" and G.roam:
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
	if drag and drag.id == id:
		if drag.get("insp"):
			game.egg_head.rotation.y += (p.x - drag.x) / HW * 6
			game.egg_head.rotation.x += (p.y - drag.y) / HH * 4
			drag.x = p.x
			drag.y = p.y
		elif drag.get("roam"):
			G.rp.yaw = drag.yaw - (p.x - drag.x) / HW * 4
			G.rp.pitch = clampf(drag.pitch - (p.y - drag.y) / HH * 2.5, -0.9, 0.7)
		elif G:
			G.look = clampf(drag.look - (p.x - drag.x) / HW * 2.6, -1.25, 1.25)
func _up(id: int) -> void:
	if joy and joy.id == id:
		joy = null
	if drag and drag.id == id:
		drag = null
	if flash_id == id and game.G:
		game.G.flash = false
		flash_id = -1
func _keyname(e: InputEventKey) -> String:
	match e.keycode:
		KEY_LEFT: return "left"
		KEY_RIGHT: return "right"
		KEY_UP: return "up"
		KEY_DOWN: return "down"
		KEY_SPACE: return " "
		KEY_SHIFT: return "shift"
		KEY_F1: return "f1"
		KEY_QUOTELEFT: return "`"
	return OS.get_keycode_string(e.keycode).to_lower()
func _key(e: InputEventKey) -> void:
	var k = _keyname(e)
	var G = game.G
	if not e.pressed:
		game.keys[k] = false
		if k == "f" and G:
			G.flash = false
		return
	if e.echo:
		return
	game.keys[k] = true
	if game.S != "play":
		return
	if k == "`" or k == "f1":
		game.DEV.panel = not game.DEV.panel
		return
	if k == "i":
		inv_open = not inv_open
		inspect = null
		return
	if G.roam:
		if k == " ":
			game.roam_jump()
		return
	if k == " " or k == "s":
		game.toggle_mon()
	if k == "f" and not G.out:
		G.flash = true
