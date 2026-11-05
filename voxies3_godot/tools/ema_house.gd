extends SceneTree
## NaV4 Nightmare – mapa domu: pokojíček malé Emy (1997), chodby, koupelna, ložnice rodičů.
## Ema stojí uprostřed pokoje s baterkou: vlevo a vpravo dveře do chodeb, před ní skříň, za ní postel.
## Výstup: models/ema_house.glb, data/ema_house.json, náhledy user://eh_*.png

const H := 2.6
var root3: Node3D
var house: Node3D
var mats := {}
var info := {"rooms": {}, "spots": {}, "player": [0, 1.05, 0.2]}

func mat(c: String, rough := 0.85, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var k = c + str(rough) + str(metal) + str(emit)
	if mats.has(k):
		return mats[k]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = rough
	m.metallic = metal
	if emit > 0:
		m.emission_enabled = true
		m.emission = Color(c)
		m.emission_energy_multiplier = emit
	mats[k] = m
	return m
func tex(img: Image, sc := 1.0, rough := 0.85) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * sc
	m.roughness = rough
	return m
func box(p: Node3D, sz: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.position = pos
	mi.rotation = rot
	mi.material_override = m
	p.add_child(mi)
	return mi
func cyl(p: Node3D, r: float, h: float, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var c = CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.position = pos
	mi.rotation = rot
	mi.material_override = m
	p.add_child(mi)
	return mi
func label(p: Node3D, t: String, pos: Vector3, col: String, size := 32, rot_y := 0.0) -> void:
	var l = Label3D.new()
	l.text = t
	l.font_size = size
	l.modulate = Color(col)
	l.position = pos
	l.rotation.y = rot_y
	l.pixel_size = 0.004
	p.add_child(l)

# ------------------------------------------------------------------ textury
func img_wallpaper(base: String, dot: String, stars: bool) -> Image:
	var im = Image.create(128, 128, false, Image.FORMAT_RGB8)
	var b = Color(base)
	for y in 128:
		for x in 128:
			var c = b.darkened(randf() * 0.05)
			if (x % 32) < 2:
				c = b.darkened(0.12)
			im.set_pixel(x, y, c)
	if stars:
		for i in 18:
			var cx = randi() % 120 + 4
			var cy = randi() % 120 + 4
			for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				im.set_pixel(clampi(cx + d.x, 0, 127), clampi(cy + d.y, 0, 127), Color(dot))
	return im
func img_planks() -> Image:
	var im = Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var row = int(y / 32)
			var off = (row * 97) % 256
			var c = Color("#6a4628").lerp(Color("#4a2e18"), (sin((x + off) * 0.07 + row) * 0.5 + 0.5) * 0.4 + randf() * 0.08)
			if y % 32 < 1 or (x + off) % 128 < 1:
				c = Color("#2a180c")
			im.set_pixel(x, y, c)
	return im
func img_tiles(a: String, b: String) -> Image:
	var im = Image.create(64, 64, false, Image.FORMAT_RGB8)
	for y in 64:
		for x in 64:
			var c = Color(a) if ((x / 16) + (y / 16)) % 2 == 0 else Color(b)
			if x % 16 == 0 or y % 16 == 0:
				c = Color("#8a8a8a")
			im.set_pixel(x, y, c.darkened(randf() * 0.04))
	return im
func img_rug() -> Image:
	var im = Image.create(128, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 128:
			var d = Vector2(x - 64, y - 64).length()
			var c = Color("#6a2a5a") if int(d / 10) % 2 == 0 else Color("#e8a8c8")
			if d > 60:
				c = Color("#3a1030")
			im.set_pixel(x, y, c.darkened(randf() * 0.06))
	return im

# ------------------------------------------------------------------ místnost
func room(id: String, nm: String, x0: float, z0: float, x1: float, z1: float, wall: Material, floor_m: Material, doors := {}) -> Node3D:
	var r = Node3D.new()
	r.name = "Room_" + id
	house.add_child(r)
	info.rooms[id] = {"name": nm, "x0": x0, "z0": z0, "x1": x1, "z1": z1}
	box(r, Vector3(x1 - x0, 0.06, z1 - z0), Vector3((x0 + x1) / 2, -0.03, (z0 + z1) / 2), floor_m)
	box(r, Vector3(x1 - x0, 0.06, z1 - z0), Vector3((x0 + x1) / 2, H + 0.03, (z0 + z1) / 2), mat("#d8d0c4", 0.95))
	var trim = mat("#e8e0d0", 0.7)
	for side in ["n", "s", "w", "e"]:
		var ns = side == "n" or side == "s"
		var a0 = x0 if ns else z0
		var a1 = x1 if ns else z1
		var f = z0 if side == "n" else (z1 if side == "s" else (x0 if side == "w" else x1))
		var gaps = doors.get(side, [])
		var cur = a0
		var segs = []
		for g in gaps:
			segs.append([cur, g[0]])
			var mid = (g[0] + g[1]) / 2.0
			var w = g[1] - g[0]
			var dh = g[2] if g.size() > 2 else 2.05
			if ns:
				box(r, Vector3(w, H - dh, 0.14), Vector3(mid, dh + (H - dh) / 2, f), wall)
				if dh < 1.5:
					box(r, Vector3(w, dh - 0.9, 0.14), Vector3(mid, 0.45, f), wall)
			else:
				box(r, Vector3(0.14, H - dh, w), Vector3(f, dh + (H - dh) / 2, mid), wall)
			# zárubeň
			for e in [g[0], g[1]]:
				if ns:
					box(r, Vector3(0.06, dh, 0.18), Vector3(e, dh / 2, f), trim)
				else:
					box(r, Vector3(0.18, dh, 0.06), Vector3(f, dh / 2, e), trim)
			cur = g[1]
		segs.append([cur, a1])
		for sg in segs:
			var L = sg[1] - sg[0]
			if L <= 0.01:
				continue
			var mid = (sg[0] + sg[1]) / 2.0
			if ns:
				box(r, Vector3(L, H, 0.14), Vector3(mid, H / 2, f), wall)
				box(r, Vector3(L, 0.1, 0.17), Vector3(mid, 0.05, f), trim)
			else:
				box(r, Vector3(0.14, H, L), Vector3(f, H / 2, mid), wall)
				box(r, Vector3(0.17, 0.1, L), Vector3(f, 0.05, mid), trim)
	return r

func door_leaf(p: Node3D, hinge: Vector3, w: float, open_ang: float, axis_x: bool, nm := "") -> void:
	var d = Node3D.new()
	if nm != "":
		d.name = nm
	d.position = hinge
	d.rotation.y = open_ang
	p.add_child(d)
	var dm = mat("#e8dcc8", 0.6)
	if axis_x:
		box(d, Vector3(w, 2.0, 0.04), Vector3(w / 2, 1.0, 0), dm)
		box(d, Vector3(0.1, 0.03, 0.06), Vector3(w - 0.1, 1.0, 0.04), mat("#c8a448", 0.3, 0.8))
	else:
		box(d, Vector3(0.04, 2.0, w), Vector3(0, 1.0, w / 2), dm)
		box(d, Vector3(0.06, 0.03, 0.1), Vector3(0.04, 1.0, w - 0.1), mat("#c8a448", 0.3, 0.8))

# ------------------------------------------------------------------ stavba
func build() -> void:
	house = Node3D.new()
	house.name = "EmaHouse"
	root3.add_child(house)
	var planks = tex(img_planks(), 0.5, 0.6)
	var wp_ema = tex(img_wallpaper("#c8a8d8", "#fff4b0", true), 0.6)
	var wp_hall = tex(img_wallpaper("#b8b098", "#000000", false), 0.6)
	var tiles = tex(img_tiles("#e8e8f0", "#a8c8d8"), 1.0, 0.3)
	# --- pokojíček Emy: x -2.2..2.2, z -2.2..2.2
	var er = room("EMA", "Pokojíček Emy", -2.2, -2.2, 2.2, 2.2, wp_ema, planks, {"w": [[-0.5, 0.5]], "e": [[-0.5, 0.5]], "n": [[-0.6, 0.6]]})
	# dveře do chodeb – vlevo a vpravo. Zavřené: otevřít je umí jen animatronici (Door_L / Door_R, pant u z = -0.5)
	door_leaf(er, Vector3(-2.2, 0, -0.5), 1.0, 0.0, false, "Door_L")
	door_leaf(er, Vector3(2.2, 0, -0.5), 1.0, 0.0, false, "Door_R")
	# skříň v severní stěně: dvoukřídlá, pootevřená, uvnitř tma
	var cl = Node3D.new()
	cl.name = "Closet"
	cl.position = Vector3(0, 0, -2.2)
	er.add_child(cl)
	box(cl, Vector3(1.4, 2.2, 0.7), Vector3(0, 1.1, -0.36), mat("#3a2414", 0.8))
	box(cl, Vector3(1.2, 2.0, 0.6), Vector3(0, 1.0, -0.4), mat("#050304", 1.0))
	var cd = mat("#8a5a34", 0.7)
	var l = Node3D.new()
	l.name = "Closet_L"
	l.position = Vector3(-0.6, 0, 0.02)
	l.rotation.y = 0.0
	cl.add_child(l)
	box(l, Vector3(0.6, 2.0, 0.04), Vector3(0.3, 1.0, 0), cd)
	var rr = Node3D.new()
	rr.name = "Closet_R"
	rr.position = Vector3(0.6, 0, 0.02)
	rr.rotation.y = 0.0
	cl.add_child(rr)
	box(rr, Vector3(0.6, 2.0, 0.04), Vector3(-0.3, 1.0, 0), cd)
	for s in [-1, 1]:
		box(cl, Vector3(0.04, 0.12, 0.04), Vector3(0.06 * s, 1.0, 0.06), mat("#c8a448", 0.3, 0.8))
	# postel za zády (jih): dětská postel s dekou Cocoy
	var bed = Node3D.new()
	bed.name = "Bed"
	bed.position = Vector3(0, 0, 1.25)
	er.add_child(bed)
	box(bed, Vector3(1.0, 0.3, 1.9), Vector3(0, 0.25, 0), mat("#8a5a34"))
	box(bed, Vector3(1.04, 0.8, 0.08), Vector3(0, 0.45, 0.95), mat("#7a4a28"))
	box(bed, Vector3(0.96, 0.14, 1.8), Vector3(0, 0.47, 0), mat("#f4ece0"))
	box(bed, Vector3(0.98, 0.08, 1.2), Vector3(0, 0.56, -0.25), mat("#e88ab8", 0.95))
	for i in 5:
		box(bed, Vector3(0.12, 0.085, 0.12), Vector3(-0.35 + i * 0.17, 0.565, -0.2 + (i % 2) * 0.3), mat("#6a3a1c"))
	box(bed, Vector3(0.6, 0.12, 0.3), Vector3(0, 0.6, 0.7), mat("#ffffff"))
	# plyšová Cocoa na posteli a plyšový Voxie na zemi
	var cp = Node3D.new()
	cp.position = Vector3(-0.25, 0.6, 1.95)
	er.add_child(cp)
	box(cp, Vector3(0.16, 0.18, 0.12), Vector3(0, 0.09, 0), mat("#7a4a2a"))
	box(cp, Vector3(0.16, 0.15, 0.14), Vector3(0, 0.26, 0), mat("#7a4a2a"))
	for s in [-1, 1]:
		box(cp, Vector3(0.04, 0.2, 0.03), Vector3(0.05 * s, 0.42, -0.02), mat("#7a4a2a"))
		box(cp, Vector3(0.04, 0.04, 0.01), Vector3(0.04 * s, 0.28, 0.075), mat("#111111"))
	box(cp, Vector3(0.1, 0.04, 0.02), Vector3(0, 0.2, 0.07), mat("#ffffff"))
	var vp = Node3D.new()
	vp.position = Vector3(1.55, 0, 0.9)
	vp.rotation.y = -0.9
	er.add_child(vp)
	box(vp, Vector3(0.22, 0.24, 0.16), Vector3(0, 0.12, 0), mat("#6a4020"))
	box(vp, Vector3(0.22, 0.2, 0.2), Vector3(0, 0.34, 0), mat("#6a4020"))
	for s in [-1, 1]:
		box(vp, Vector3(0.07, 0.07, 0.04), Vector3(0.09 * s, 0.46, 0), mat("#6a4020"))
		box(vp, Vector3(0.04, 0.04, 0.01), Vector3(0.05 * s, 0.37, 0.105), mat("#111111"))
	box(vp, Vector3(0.08, 0.04, 0.02), Vector3(0, 0.25, 0.09), mat("#c02060"))
	# stolek s kresbami, lampička, budík
	var desk = Node3D.new()
	desk.position = Vector3(-1.65, 0, 1.2)
	er.add_child(desk)
	box(desk, Vector3(0.8, 0.05, 0.6), Vector3(0, 0.62, 0), mat("#d8c8a8"))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(desk, Vector3(0.04, 0.6, 0.04), Vector3(0.36 * sx, 0.3, 0.26 * sz), mat("#c8b898"))
	box(desk, Vector3(0.21, 0.004, 0.29), Vector3(-0.15, 0.648, 0.05), mat("#f8f4e8"), Vector3(0, 0.3, 0))
	box(desk, Vector3(0.21, 0.004, 0.29), Vector3(0.15, 0.648, -0.05), mat("#f8f4e8"), Vector3(0, -0.4, 0))
	for i in 5:
		box(desk, Vector3(0.012, 0.012, 0.1), Vector3(0.05 + i * 0.03, 0.655, 0.2), mat(["#d02020", "#2060d0", "#20a040", "#e0c020", "#8a4a20"][i]))
	cyl(desk, 0.06, 0.03, Vector3(0.28, 0.66, -0.18), mat("#e8a0c0"))
	cyl(desk, 0.012, 0.25, Vector3(0.28, 0.79, -0.18), mat("#e8a0c0"))
	box(desk, Vector3(0.16, 0.1, 0.16), Vector3(0.28, 0.94, -0.18), mat("#fff0f8", 0.6))
	box(desk, Vector3(0.1, 0.08, 0.05), Vector3(-0.28, 0.69, -0.2), mat("#c02020"))
	label(desk, "00:00", Vector3(-0.28, 0.69, -0.17), "#ff3030", 22)
	# hračky: truhla, kostky, kresby na zdi
	var tb = Node3D.new()
	tb.position = Vector3(1.6, 0, -1.4)
	er.add_child(tb)
	box(tb, Vector3(0.7, 0.45, 0.45), Vector3(0, 0.225, 0), mat("#c84040"))
	box(tb, Vector3(0.72, 0.06, 0.47), Vector3(0, 0.46, -0.08), mat("#a03030"), Vector3(-0.5, 0, 0))
	for i in 6:
		box(er, Vector3(0.12, 0.12, 0.12), Vector3(randf_range(-1.0, 1.2), 0.06, randf_range(-1.2, 0.6)), mat(["#d02020", "#2060d0", "#20a040", "#e0c020"][i % 4]), Vector3(0, randf() * 3, 0))
	var kres = load("res://models/kresba.png") if ResourceLoader.exists("res://models/kresba.png") else null
	for i in 3:
		var pic = MeshInstance3D.new()
		var q = QuadMesh.new()
		q.size = Vector2(0.42, 0.3)
		pic.mesh = q
		var pm = StandardMaterial3D.new()
		if kres and i == 0:
			pm.albedo_texture = kres
		else:
			pm.albedo_color = Color(["#f8f4e8", "#fff0d8", "#f0f8e8"][i])
		pic.material_override = pm
		pic.position = Vector3(-2.12, 1.4 + (i % 2) * 0.35, -1.2 + i * 0.5)
		pic.rotation = Vector3(0, PI / 2, randf_range(-0.1, 0.1))
		er.add_child(pic)
	# koberec
	box(er, Vector3(1.8, 0.01, 1.4), Vector3(0, 0.005, -0.2), tex(img_rug(), 0.55, 0.95))
	# okno (východ, roh) s měsícem a závěsy
	var win = Node3D.new()
	win.position = Vector3(2.12, 0, 1.4)
	er.add_child(win)
	box(win, Vector3(0.06, 1.0, 0.8), Vector3(0, 1.45, 0), mat("#0a1830", 0.1, 0.0, 0.4))
	box(win, Vector3(0.08, 0.05, 0.86), Vector3(0, 1.45, 0), mat("#e8e0d0"))
	box(win, Vector3(0.08, 1.06, 0.05), Vector3(0, 1.45, 0), mat("#e8e0d0"))
	for s in [-1, 1]:
		box(win, Vector3(0.05, 1.4, 0.3), Vector3(-0.06, 1.35, 0.5 * s), mat("#8a5aa8", 0.95))
	# strop: lampa (zhasnutá), noční světýlko v zásuvce
	cyl(er, 0.25, 0.12, Vector3(0, H - 0.08, 0), mat("#f0e8d8", 0.6))
	box(er, Vector3(0.08, 0.08, 0.03), Vector3(-1.0, 0.3, -2.13), mat("#ffd080", 0.5, 0.0, 2.0))
	label(er, "EMA", Vector3(0, 2.3, -2.12), "#e88ab8", 60)
	# --- chodby
	var hw = room("HALL_W", "Levá chodba", -6.2, -0.9, -2.2, 0.9, wp_hall, planks, {"e": [[-0.5, 0.5]], "w": [[-0.5, 0.5]], "n": [[-5.0, -4.0]]})
	var he = room("HALL_E", "Pravá chodba", 2.2, -0.9, 6.2, 0.9, wp_hall, planks, {"w": [[-0.5, 0.5]], "e": [[-0.5, 0.5]], "n": [[4.0, 5.0]]})
	for hr in [[hw, -4.2], [he, 4.2]]:
		box(hr[0], Vector3(3.6, 0.012, 0.8), Vector3(hr[1], 0.006, 0), mat("#6a1a20", 0.95))
		for i in 3:
			var fx = hr[1] - 1.2 + i * 1.2
			box(hr[0], Vector3(0.3, 0.38, 0.03), Vector3(fx, 1.5, 0.86), mat("#5a3a1c"))
			box(hr[0], Vector3(0.24, 0.32, 0.01), Vector3(fx, 1.5, 0.845), mat(["#2a3a5a", "#5a2a3a", "#3a4a2a"][i]))
		cyl(hr[0], 0.12, 0.08, Vector3(hr[1], H - 0.05, 0), mat("#f0e8d8", 0.6))
	# schody dolů z levé chodby
	var st = Node3D.new()
	st.position = Vector3(-4.5, 0, -1.0)
	hw.add_child(st)
	box(st, Vector3(1.0, 0.04, 0.8), Vector3(0, -0.02, -0.4), mat("#050304"))
	for i in 5:
		box(st, Vector3(1.0, 0.04, 0.26), Vector3(0, -0.22 - i * 0.2, -0.2 - i * 0.26), mat("#4a2e18"))
	box(st, Vector3(0.05, 0.9, 0.05), Vector3(0.55, 0.45, 0), mat("#4a2e18"))
	box(st, Vector3(0.05, 0.05, 1.4), Vector3(0.55, 0.9, -0.6), mat("#4a2e18"))
	# --- koupelna (konec levé chodby)
	var bath = room("BATH", "Koupelna", -8.6, -1.4, -6.2, 1.4, tex(img_tiles("#e8e8f0", "#c8d8e8"), 1.2, 0.3), tiles, {"e": [[-0.5, 0.5]]})
	box(bath, Vector3(0.7, 0.55, 1.6), Vector3(-8.2, 0.28, -0.4), mat("#f4f4f8", 0.2))
	box(bath, Vector3(0.6, 0.1, 1.5), Vector3(-8.2, 0.5, -0.4), mat("#a8c0d0", 0.1))
	box(bath, Vector3(0.5, 0.15, 0.4), Vector3(-7.0, 0.8, 1.15), mat("#f4f4f8", 0.2))
	box(bath, Vector3(0.5, 0.6, 0.03), Vector3(-7.0, 1.5, 1.33), mat("#a8b8c8", 0.05, 0.8))
	door_leaf(bath, Vector3(-6.2, 0, -0.5), 1.0, 1.3, false)
	# --- ložnice rodičů (konec pravé chodby)
	var par = room("PARENTS", "Ložnice rodičů", 6.2, -2.0, 9.6, 2.0, tex(img_wallpaper("#a8b8a0", "#000000", false), 0.6), planks, {"w": [[-0.5, 0.5]]})
	box(par, Vector3(1.6, 0.35, 2.0), Vector3(8.6, 0.28, 0.2), mat("#5a3a20"))
	box(par, Vector3(1.55, 0.15, 1.9), Vector3(8.6, 0.52, 0.2), mat("#d8d0c0"))
	box(par, Vector3(1.6, 0.9, 0.08), Vector3(8.6, 0.6, -0.8), mat("#4a2e18"))
	box(par, Vector3(0.5, 0.6, 0.4), Vector3(7.4, 0.3, -1.6), mat("#5a3a20"))
	box(par, Vector3(0.3, 0.4, 0.03), Vector3(9.52, 1.5, 0.2), mat("#ffd080"), Vector3(0, -PI / 2, 0))
	label(par, "VOXIE'S\\nFUN FACTORY", Vector3(9.5, 1.55, 1.2), "#ff4040", 20, -PI / 2)
	door_leaf(par, Vector3(6.2, 0, -0.5), 1.0, -1.3, false)
	# --- dveře na konci chodeb do dalších místností (zavřené)
	box(hw, Vector3(1.0, 2.0, 0.04), Vector3(-4.5, 1.0, -0.88), mat("#e8dcc8", 0.6))
	box(he, Vector3(1.0, 2.0, 0.04), Vector3(4.5, 1.0, -0.88), mat("#e8dcc8", 0.6))
	info["mechanic"] = "Dveře Door_L, Door_R a skříň Closet_L/Closet_R otevírají jen animatronici. Ema je musí do 6:00 kontrolovat baterkou; světla se Nightmare Voxie i Nightmare Hollow Bunny bojí."
	info["doors"] = {"Door_L": {"hinge": [-2.2, 0, -0.5], "open_y": 1.3}, "Door_R": {"hinge": [2.2, 0, -0.5], "open_y": -1.3}, "Closet_L": {"open_y": -1.0}, "Closet_R": {"open_y": 1.0}}
	info.spots = {"door_left": [-2.2, 0, 0], "door_right": [2.2, 0, 0], "closet": [0, 0, -2.2], "bed": [0, 0, 1.6], "hall_left_end": [-6.0, 0, 0], "hall_right_end": [6.0, 0, 0]}

func _init() -> void:
	seed(1997)
	root3 = Node3D.new()
	get_root().add_child(root3)
	build()
	await process_frame
	var doc = GLTFDocument.new()
	var st = GLTFState.new()
	doc.append_from_scene(house, st)
	print("EH ", doc.write_to_filesystem(st, "res://models/ema_house.glb"))
	var f = FileAccess.open("res://data/ema_house.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "\t"))
	f.close()
	# náhledy: noc, měsíční světlo z okna, baterka v ruce Emy
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#020104")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#2a2850")
	env.ambient_light_energy = 0.35
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color("#05040a")
	env.fog_density = 0.08
	var we = WorldEnvironment.new()
	we.environment = env
	root3.add_child(we)
	var moon = OmniLight3D.new()
	moon.light_color = Color("#8aa8ff")
	moon.light_energy = 0.8
	moon.omni_range = 4
	moon.position = Vector3(1.6, 1.6, 1.4)
	root3.add_child(moon)
	var night = OmniLight3D.new()
	night.light_color = Color("#ffc070")
	night.light_energy = 0.3
	night.omni_range = 1.8
	night.position = Vector3(-1.0, 0.4, -1.9)
	root3.add_child(night)
	var cam = Camera3D.new()
	cam.fov = 70
	cam.near = 0.05
	root3.add_child(cam)
	cam.current = true
	var torch = SpotLight3D.new()
	torch.light_color = Color("#fff4d8")
	torch.light_energy = 0
	torch.spot_range = 10
	torch.spot_angle = 28
	torch.shadow_enabled = true
	cam.add_child(torch)
	torch.position = Vector3(0.15, -0.15, 0)
	var eye = Vector3(0, 1.05, 0.2)
	var shots = [["open", eye, Vector3(-4.0, 1.0, 0.0), true], ["closet", eye, Vector3(0, 1.0, -2.2), true], ["left", eye, Vector3(-4.0, 1.0, 0.0), true], ["right", eye, Vector3(4.0, 1.0, 0.1), true], ["bed", eye, Vector3(0, 0.6, 1.6), true], ["dark", eye, Vector3(0, 1.0, -2.2), false], ["hall", Vector3(-2.6, 1.05, 0.1), Vector3(-8, 0.8, 0), true], ["parents", Vector3(5.6, 1.1, 0.4), Vector3(8.6, 0.6, 0.0), true], ["top", Vector3(0, 16, 0.01), Vector3(0, 0, 0), false]]
	for s in shots:
		var dl: Node3D = house.find_child("Door_L", true, false)
		dl.rotation.y = 1.3 if s[0] == "open" else 0.0
		cam.fov = 40 if s[0] == "top" else 70
		cam.look_at_from_position(s[1], s[2])
		torch.light_energy = 6.0 if s[3] else 0.0
		if s[0] == "top":
			env.ambient_light_energy = 2.0
			for r in house.get_children():
				for c in r.get_children():
					if c is MeshInstance3D and c.position.y > H - 0.2:
						c.visible = false
		for i in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("user://eh_" + s[0] + ".png")
	quit()
