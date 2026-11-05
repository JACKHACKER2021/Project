extends RefCounted
## NaV4 – 2D pixelové minihry (vzpomínky Emy a pana Vojtěcha). Kreslí se přes HUD na mřížce 320×180.
## show     – noc 1: Ema s tátou v herně, Voxie a Hollow Bunny hrají představení
## hide     – noc 2: schovávaná s Hollow Bunnym
## pit      – noc 3: po zavíračce ji Hollow Bunny vede k míčkovému bazénku… a zhasne světlo
## shutdown – noc 5: rok 1980, pan Vojtěch dává Hollow Bunnyho odstavit, D. přihlíží

var game
var kind := ""
var t := 0.0
var ph := 0            # fáze scény
var pt := 0.0          # čas ve fázi
var px := 30.0         # hráč (Ema nebo táta)
var hold := 0          # -1 vlevo, 1 vpravo
var face := 1
var walkT := 0.0
var bub := []          # [kdo, text, x, zbývá]
var spot := -1         # schovávaná: vybraný úkryt
var bx := 0.0          # Hollow Bunny
var dark := 0.0
var scare := 0.0
var done := false
var from_extras := false
var sw_on := true      # odstavení: vypínač
var sign_on := false

const HIDE := [["za stolem", 62], ["za automatem", 132], ["v míčkovém bazénku", 192], ["za oponou", 262]]

func start(k: String, extras := false) -> void:
	kind = k
	from_extras = extras
	t = 0.0
	ph = 0
	pt = 0.0
	hold = 0
	bub = []
	spot = -1
	dark = 0.0
	scare = 0.0
	done = false
	sw_on = true
	sign_on = false
	match k:
		"show":
			px = 34.0
			say("f", "Emo, pojď, představení začíná!", 18)
		"hide":
			px = 160.0
			bx = 236.0
			say("b", "Raz, dva, tři, jdu hledat!", 236)
		"pit":
			px = 26.0
			bx = 70.0
			dark = 0.55
			say("b", "Pojď, Emo. Ukážu ti něco v míčkovém bazénku.", 70)
		"shutdown":
			px = 30.0
			say("f", "Rozhodl jsem se. Hollow Bunny bude odstaven.", 30)

func say(who: String, text: String, x: float) -> void:
	var d = game.audio.voice(text, 0.85) if game.audio.AUD.voice.has(text) else clampf(text.length() * 0.06, 2.0, 5.0)
	bub = [[who, text, x, maxf(2.4, d + 0.8)]]

func goal_text() -> String:
	match kind:
		"show":
			return ["Jdi k pódiu ▶", "Dívej se na představení…", "Vrať se k tátovi ◀", ""][mini(ph, 3)]
		"hide":
			return "Schovej se! (✋ v úkrytu)" if ph == 0 else ("Ticho… hledá tě." if ph == 1 else "")
		"pit":
			return "Jdi za Hollow Bunnym ▶" if ph == 0 else ""
		"shutdown":
			return ["Jdi k Hollow Bunnymu ▶", "", "Vypni napájení u rozvaděče ▶ (✋)", "Pověs ceduli ◀ (✋)", ""][mini(ph, 4)]
	return ""

func near(x: float, r := 14.0) -> bool:
	return absf(px - x) < r

func act() -> void:
	match kind:
		"hide":
			if ph == 0:
				for i in HIDE.size():
					if near(HIDE[i][1]):
						spot = i
						ph = 1
						pt = 0.0
						game.audio.sfx("click", 0.4)
						return
		"shutdown":
			if ph == 2 and near(282):
				sw_on = false
				ph = 3
				pt = 0.0
				game.audio.sfx("powerdown", 0.7)
			elif ph == 3 and near(196, 20):
				sign_on = true
				ph = 4
				pt = 0.0
				game.audio.sfx("clunk", 0.6)

func tick(dt: float) -> void:
	t += dt
	pt += dt
	for b in bub:
		b[3] -= dt
	bub = bub.filter(func(b): return b[3] > 0)
	var k = game.keys
	var mv = hold
	if k.get("a") or k.get("left"):
		mv = -1
	if k.get("d") or k.get("right"):
		mv = 1
	var can_move = not (kind == "hide" and ph >= 1) and not (kind == "pit" and ph >= 1) and not (kind == "show" and ph == 1) and not (kind == "shutdown" and ph in [1, 4])
	if mv != 0 and can_move:
		face = mv
		px = clampf(px + mv * 42.0 * dt, 8, 312)
		var w0 = walkT
		walkT += dt * 8
		if floor(w0 / PI) != floor(walkT / PI):
			game.audio.sfx("step", 0.08)
	scare = maxf(0, scare - dt)
	match kind:
		"show": _show(dt)
		"hide": _hide(dt)
		"pit": _pit(dt)
		"shutdown": _shutdown(dt)

func _show(dt: float) -> void:
	match ph:
		0:
			if px > 176:
				ph = 1
				pt = 0.0
				say("v", "Vítejte v herně u Voxieho!", 236)
		1:
			if pt > 3.0 and pt - dt <= 3.0:
				say("b", "Ahoj, děti! Já jsem Hollow Bunny!", 280)
			if pt > 6.5 and pt - dt <= 6.5:
				game.audio.sfx("servo", 0.5)
			if pt > 8.5:
				ph = 2
				pt = 0.0
				say("f", "Emo, jdeme domů.", 18)
		2:
			if px < 30:
				ph = 3
				pt = 0.0
		3:
			if pt > 1.5:
				done = true

func _hide(dt: float) -> void:
	match ph:
		1:
			# Hollow Bunny prochází hernou a hledá; vždycky najde
			var target = HIDE[spot][1]
			var route = [236.0, 40.0, 300.0, target]
			var seg = mini(int(pt / 2.2), 3)
			var to = route[seg]
			bx = move_toward(bx, to, 55 * dt)
			if fmod(pt, 0.5) < dt:
				game.audio.sfx("step", 0.15)
			if seg == 3 and absf(bx - target) < 1 and pt > 7.5:
				ph = 2
				pt = 0.0
				scare = 0.9
				game.audio.sfx("scare_c", 1.0)
		2:
			if pt > 1.2 and pt - dt <= 1.2:
				say("b", "Tak jaká byla hra?", bx)
			if pt > 4.2:
				done = true

func _pit(dt: float) -> void:
	match ph:
		0:
			# Hollow Bunny jde napřed k bazénku a mává
			var gx = clampf(px + 46, 70, 214)
			bx = move_toward(bx, gx, 40 * dt)
			if px > 206:
				ph = 1
				pt = 0.0
				game.audio.sfx("whoosh", 0.4)
		1:
			# Ema skočí do míčků, Bunny se nad ní skloní
			px = move_toward(px, 236, 30 * dt)
			bx = move_toward(bx, 222, 20 * dt)
			if pt > 2.2:
				ph = 2
				pt = 0.0
		2:
			# zhasne světlo
			dark = minf(1.0, dark + dt * (0.6 if pt < 0.9 else 3.0))
			if pt > 0.9 and pt - dt <= 0.9:
				game.audio.sfx("powerdown", 0.9)
			if pt > 1.4 and pt - dt <= 1.4:
				game.audio.sfx("clunk", 0.6)
			if pt > 4.5:
				done = true

func _shutdown(dt: float) -> void:
	match ph:
		0:
			if px > 168:
				ph = 1
				pt = 0.0
				say("g", "Pane Vojtěchu, to nemůžete!", 110)
		1:
			if pt > 2.6 and pt - dt <= 2.6:
				say("f", "Zámky povolují. Nikdo už si ho neoblékne.", px)
			if pt > 5.8:
				ph = 2
				pt = 0.0
		4:
			if pt > 1.2 and pt - dt <= 1.2:
				game.audio.sfx("servo", 0.4)
			if pt > 4.0:
				done = true

# ================================================================== kreslení
var h
var S := 4.0
var OX := 0.0
func P(x: float, y: float, w: float, hh: float, c) -> void:
	h.rect(OX + floor(x) * S, floor(y) * S, w * S, hh * S, c)

func draw(hud) -> void:
	h = hud
	S = hud.HH / 180.0
	OX = (hud.HW - 320 * S) / 2.0
	hud.rect(0, 0, hud.HW, hud.HH, "#000000")
	match kind:
		"show", "hide": _bg_herna(true)
		"pit": _bg_herna(false)
		"shutdown": _bg_workshop()
	match kind:
		"show":
			var dance = ph == 1
			_voxie(236, dance)
			_bunny(280, dance, ph >= 1 and pt > 6.0)
			_father(18 if ph != 3 else 26)
			_ema(px)
		"hide":
			if ph == 0 or spot != 2:
				pass
			_bunny(bx, false, ph == 2)
			if ph == 0:
				_ema(px)
			elif ph == 2:
				_ema(HIDE[spot][1])
			_hide_covers()
		"pit":
			_bunny(bx, false, true)
			if ph == 0:
				_ema(px)
			else:
				_ema(px, true)
			_pit_front()
		"shutdown":
			_bunny(196, false, sw_on, true)
			_guard(110)
			_father(px)
			if sign_on:
				P(184, 112, 26, 10, "#e8e0d0")
				P(185, 113, 24, 8, "#c02020")
	# tma (zavírací doba / zhasnutí)
	if dark > 0:
		hud.rect(0, 0, hud.HW, hud.HH, Color(0, 0, 0, dark * 0.95))
	# lekačka: obří pixelová tvář Hollow Bunnyho
	if scare > 0:
		_scare_face()
	# bubliny
	for b in bub:
		_bubble(b)
	# úkol a ovládání
	var g = goal_text()
	if g != "":
		hud.rr(hud.HW / 2 - 260, 16, 520, 38, 8, Color(0, 0, 0, 0.6), "#d088ff", 1)
		hud.txt(g, hud.HW / 2, 42, 18, "#ffffff", "center")
	var title = {"show": "1997 · Představení", "hide": "1997 · Schovávaná", "pit": "1997 · Po zavíračce", "shutdown": "1980 · Odstavení"}[kind]
	hud.txt(title, 20, 30, 15, "#e0b0ff")
	_controls()

func _controls() -> void:
	var by = h.HH - 104
	for b in [["◀", "ml", 24], ["▶", "mr", 160]]:
		h.rr(b[2], by, 120, 80, 12, Color(0.2, 0.1, 0.3, 0.55), "#d088ff", 2)
		h.txt(b[0], b[2] + 60, by + 52, 34, "#ffffff", "center")
		h.add_btn(b[2], by, 120, 80, b[1], func(): pass)
	h.btn(h.HW - 170, by, 146, 80, "✋", "ma", act, true, 30)
	h.btn(h.HW - 170, 20, 150, 40, "PŘESKOČIT ▶", "mskip", func(): done = true, true, 14)

func _bubble(b) -> void:
	var nm = {"f": "Táta", "b": "Hollow Bunny", "v": "Voxie", "g": "D."}.get(b[0], "")
	var x = OX + clampf(b[2], 50, 270) * S
	var w = clampf(h.tw(b[1], 16) + 30, 160, 560)
	x = clampf(x - w / 2, 10, h.HW - w - 10)
	h.rr(x, 64, w, 58, 10, Color(1, 1, 1, 0.92), "#000000", 2)
	h.txt(nm, x + 12, 82, 13, "#7a3aa0")
	h.txt(b[1], x + w / 2, 108, 16, "#000000", "center")

# ---------- pozadí
func _bg_herna(lit: bool) -> void:
	var wall = "#3a1a4a" if lit else "#160a1c"
	P(0, 0, 320, 150, wall)
	for i in 16:
		P(i * 20, 20, 10, 130, "#42205a" if lit else "#1a0c22")
	P(0, 92, 320, 4, "#ffd040" if lit else "#3a3010")
	for i in 32:
		P(i * 10, 93, 5, 2, "#e04060" if lit else "#401020")
	# balónky
	for i in 6:
		var bxx = 20 + i * 52
		var bc = ["#e04040", "#40a0e0", "#e0c040", "#40c060", "#c040e0", "#e08040"][i]
		P(bxx, 30 + (i % 2) * 8 + sin(t * 1.5 + i) * 2, 7, 9, bc if lit else "#201820")
		P(bxx + 3, 39 + (i % 2) * 8, 1, 12, "#d0d0d0" if lit else "#202020")
	# podlaha – šachovnice
	for y in 3:
		for x in 32:
			P(x * 10, 150 + y * 10, 10, 10, ("#e8e0d0" if (x + y) % 2 == 0 else "#202020") if lit else ("#2a2828" if (x + y) % 2 == 0 else "#0a0a0a"))
	# pódium s oponou
	P(206, 124, 114, 26, "#6a3a1c" if lit else "#1c100a")
	P(206, 124, 114, 3, "#8a5a2c" if lit else "#24140c")
	P(200, 36, 10, 114, "#a01828" if lit else "#300810")
	P(312, 36, 8, 114, "#a01828" if lit else "#300810")
	P(200, 30, 120, 8, "#c02030" if lit else "#380a12")
	label_px(236, 22, "VOXIE'S", "#ffe46b" if lit else "#3a3010")
	# stoly s kloboučky
	for tx in [52, 76]:
		P(tx - 10, 132, 22, 3, "#e8e0d0" if lit else "#202020")
		P(tx, 135, 2, 15, "#888888" if lit else "#202020")
		P(tx - 3, 126, 5, 6, "#e040a0" if lit else "#200a18")
	# automat
	P(124, 106, 16, 44, "#2a2a6a" if lit else "#0c0c1c")
	P(127, 110, 10, 10, "#40ff80" if lit else "#0a200a")
	P(127, 124, 10, 3, "#ff4040" if lit else "#200808")
	# míčkový bazének
	P(176, 134, 34, 16, "#4060c0" if lit else "#101830")
	for i in 22:
		P(178 + (i * 7) % 30, 132 + (i * 3) % 8, 3, 3, ["#e04040", "#40a0e0", "#e0c040", "#40c060"][i % 4] if lit else "#181818")
	if not lit:
		# nouzové světlo nad bazénkem
		P(186, 0, 14, 4, "#ffe0a0")

func _bg_workshop() -> void:
	P(0, 0, 320, 150, "#2a2a30")
	for i in 8:
		P(i * 40, 0, 2, 150, "#222228")
	P(0, 150, 320, 30, "#1a1a1c")
	for i in 16:
		P(i * 20, 150, 10, 1, "#303034")
	# pracovní stůl s nářadím
	P(14, 118, 70, 4, "#6a4a2a")
	P(18, 122, 3, 28, "#4a3218")
	P(78, 122, 3, 28, "#4a3218")
	P(24, 110, 10, 8, "#c0c0c0")
	P(40, 112, 18, 6, "#a02020")
	# stojan s Hollow Bunnym
	P(178, 146, 36, 4, "#505058")
	# rozvaděč s vypínačem
	P(274, 96, 18, 26, "#6a6a70")
	P(276, 98, 14, 22, "#3a3a40")
	P(281, 103 if sw_on else 111, 4, 8, "#e02020" if sw_on else "#808080")
	P(279, 100, 8, 2, "#40ff40" if sw_on else "#202020")
	label_px(30, 40, "VOXIEWORKS 1980", "#c0c0c0")
	# lampa
	P(150, 0, 2, 16, "#101010")
	P(140, 16, 22, 5, "#c0c0c0")

func label_px(x: float, y: float, s: String, c) -> void:
	h.txt(s, OX + x * S, y * S + 10, 6 * S, c, "center")

# ---------- postavy (x = střed u nohou, zem y = 150)
func _ema(x: float, inpit := false) -> void:
	var w = sin(walkT) * 1.2 if hold != 0 or game.keys.get("a") or game.keys.get("d") else 0.0
	var y0 = 150 if not inpit else 146
	if not inpit:
		P(x - 3, y0 - 1, 2, 1, "#4a2a2a")
		P(x + 1, y0 - 1, 2, 1, "#4a2a2a")
		P(x - 2, y0 - 6 + w, 1, 5, "#f0c8a0")
		P(x + 1, y0 - 6 - w, 1, 5, "#f0c8a0")
	P(x - 3, y0 - 16, 6, 4, "#e870a8")
	P(x - 4, y0 - 12, 8, 6, "#e870a8")
	P(x - 5, y0 - 15, 1, 5, "#f0c8a0")
	P(x + 4, y0 - 15, 1, 5, "#f0c8a0")
	P(x - 3, y0 - 23, 6, 7, "#f0c8a0")
	P(x - 4, y0 - 24, 8, 3, "#6a3a1a")
	P(x - 4, y0 - 22, 1, 5, "#6a3a1a")
	P(x + 3, y0 - 22, 1, 5, "#6a3a1a")
	P(x - 6, y0 - 22, 2, 3, "#6a3a1a")
	P(x + 4, y0 - 22, 2, 3, "#6a3a1a")
	P(x - 6, y0 - 23, 2, 1, "#ff70b0")
	P(x + 4, y0 - 23, 2, 1, "#ff70b0")
	P(x - 2 + (1 if face > 0 else 0), y0 - 20, 1, 1, "#000000")
	P(x + 1 + (1 if face > 0 else 0), y0 - 20, 1, 1, "#000000")

func _father(x: float) -> void:
	P(x - 4, 149, 3, 1, "#202020")
	P(x + 1, 149, 3, 1, "#202020")
	P(x - 3, 136, 3, 13, "#2a3050")
	P(x, 136, 3, 13, "#2a3050")
	P(x - 5, 120, 10, 16, "#3a5aa0")
	P(x - 7, 121, 2, 13, "#3a5aa0")
	P(x + 5, 121, 2, 13, "#3a5aa0")
	P(x - 7, 134, 2, 2, "#f0c8a0")
	P(x + 5, 134, 2, 2, "#f0c8a0")
	P(x - 3, 111, 7, 9, "#f0c8a0")
	P(x - 3, 109, 7, 3, "#4a3020")
	P(x - 2, 117, 5, 1, "#4a3020")
	P(x - 1, 114, 1, 1, "#000000")
	P(x + 2, 114, 1, 1, "#000000")

func _guard(x: float) -> void:
	P(x - 3, 136, 3, 14, "#2a2a30")
	P(x, 136, 3, 14, "#2a2a30")
	P(x - 5, 120, 10, 16, "#77777d")
	P(x - 7, 121, 2, 12, "#77777d")
	P(x + 5, 121, 2, 12, "#77777d")
	P(x - 3, 111, 7, 9, "#e0b890")
	P(x - 4, 108, 9, 3, "#1a2a5a")
	P(x - 4, 110, 11, 1, "#1a2a5a")
	P(x - 1, 114, 1, 1, "#000000")
	P(x + 2, 114, 1, 1, "#000000")
	P(x - 1, 117, 4, 1, "#7a4a3a")

func _voxie(x: float, dance: bool) -> void:
	var b = absf(sin(t * 4)) * 2 if dance else 0.0
	var br = "#8a5a2a"
	P(x - 5, 136, 4, 14 - b, br)
	P(x + 1, 136, 4, 14 - b, br)
	P(x - 7, 116 - b, 14, 20, br)
	P(x - 4, 120 - b, 8, 12, "#c8a070")
	var a1 = sin(t * 4) * 6 if dance else 0.0
	P(x - 10, 118 - b - maxf(0, a1), 3, 12, br)
	P(x + 7, 118 - b - maxf(0, -a1), 3, 12, br)
	P(x - 7, 102 - b, 14, 14, br)
	P(x - 8, 99 - b, 4, 4, br)
	P(x + 4, 99 - b, 4, 4, br)
	P(x - 4, 94 - b, 8, 6, "#151015")
	P(x - 6, 99 - b, 12, 1, "#151015")
	P(x - 5, 105 - b, 4, 4, "#ffffff")
	P(x + 1, 105 - b, 4, 4, "#ffffff")
	P(x - 4, 106 - b, 2, 2, "#1a1a6a")
	P(x + 2, 106 - b, 2, 2, "#1a1a6a")
	P(x - 3, 110 - b, 6, 4, "#c8a070")
	P(x - 1, 110 - b, 2, 1, "#202020")
	P(x - 3, 116 - b, 6, 3, "#c02040")

func _bunny(x: float, dance: bool, stare: bool, off := false) -> void:
	var b = absf(sin(t * 4 + 1)) * 2 if dance else 0.0
	var ye = "#e8c64a"
	var yd = "#c8a432"
	P(x - 5, 134, 4, 16 - b, ye)
	P(x + 1, 134, 4, 16 - b, ye)
	P(x - 6, 116 - b, 12, 18, ye)
	P(x - 4, 120 - b, 8, 10, "#f2e6d0")
	P(x - 8, 117 - b, 2, 14, yd)
	P(x + 6, 117 - b, 2, 14 - (6 if dance and sin(t * 4) > 0 else 0), yd)
	P(x - 6, 102 - b, 12, 14, ye)
	P(x - 5, 84 - b, 3, 18, ye)
	P(x + 2, 86 - b, 3, 8, ye)
	P(x + 5, 86 - b, 6, 3, ye)
	P(x - 4, 86 - b, 1, 14, "#f0a0b8")
	# oči: černé důlky s bílou tečkou; při zírání se otočí na Emu, odstavený zhasne
	P(x - 5, 106 - b, 4, 4, "#0a0608")
	P(x + 1, 106 - b, 4, 4, "#0a0608")
	if not off or sw_on:
		var dx = -1 if stare and px < x else (1 if stare else 0)
		P(x - 4 + dx + 1, 107 - b, 1, 1, "#ffffff")
		P(x + 2 + dx + 1, 107 - b, 1, 1, "#ffffff")
	P(x - 2, 111 - b, 4, 2, "#f2e6d0")
	P(x - 1, 113 - b, 1, 2, "#ffffff")
	P(x + 1, 113 - b, 1, 2, "#ffffff")
	P(x - 2, 116 - b, 2, 2, "#c0202a")
	P(x + 1, 116 - b, 2, 2, "#c0202a")

func _hide_covers() -> void:
	# přední části úkrytů (Ema je za nimi)
	if ph >= 1 and spot >= 0:
		var x = HIDE[spot][1]
		match spot:
			0:
				P(x - 12, 132, 24, 18, "#c8c0b0")
				P(x - 12, 132, 24, 2, "#e8e0d0")
			1:
				P(x - 8, 106, 16, 44, "#2a2a6a")
				P(x - 5, 110, 10, 10, "#40ff80")
			2:
				P(176, 132, 34, 18, "#4060c0")
				for i in 26:
					P(177 + (i * 7) % 31, 128 + (i * 5) % 9, 3, 3, ["#e04040", "#40a0e0", "#e0c040", "#40c060"][i % 4])
			3:
				P(x - 6, 36, 14, 114, "#a01828")

func _pit_front() -> void:
	P(176, 138, 34, 12, "#101830")
	for i in 16:
		P(178 + (i * 7) % 30, 134 + (i * 3) % 6, 3, 3, "#181818")

func _scare_face() -> void:
	var a = clampf(scare / 0.9, 0, 1)
	var cx = h.HW / 2 + randf_range(-8, 8)
	var cy = h.HH / 2 + randf_range(-8, 8)
	var u = 34.0
	h.rect(0, 0, h.HW, h.HH, Color(0, 0, 0, 0.6 * a))
	h.rect(cx - 6 * u, cy - 5 * u, 12 * u, 11 * u, Color("#e8c64a"))
	h.rect(cx - 5 * u, cy - 3 * u, 4 * u, 4 * u, Color("#0a0608"))
	h.rect(cx + 1 * u, cy - 3 * u, 4 * u, 4 * u, Color("#0a0608"))
	h.rect(cx - 3.5 * u, cy - 2 * u, u, u, Color("#ffffff"))
	h.rect(cx + 2.5 * u, cy - 2 * u, u, u, Color("#ffffff"))
	h.rect(cx - 3 * u, cy + 2 * u, 6 * u, 2 * u, Color("#2a0a0a"))
	for i in 6:
		h.rect(cx - 3 * u + i * u, cy + 2 * u, 0.7 * u, 0.9 * u, Color("#f0f0e0"))
	h.noise(0.25 * a)
