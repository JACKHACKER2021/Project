extends SceneTree
## NaV4 Nightmare – mapa domu: pokojíček malé Emy (1997), chodby, koupelna, ložnice rodičů.
## Ema stojí uprostřed pokoje s baterkou: vlevo a vpravo dveře do chodeb, před ní skříň, za ní postel.
## Výstup: models/ema_house.glb, data/ema_house.json, náhledy user://eh_*.png

const H := 2.6
var root3: Node3D
var house: Node3D
var mats := {}
var storm_sky_mat: StandardMaterial3D
var storm_bolt: Node3D
var lightning: OmniLight3D
func _storm_tex() -> ImageTexture:
	var n = FastNoiseLite.new()
	n.seed = 77
	n.frequency = 0.02
	n.fractal_octaves = 5
	var im = Image.create(256, 128, false, Image.FORMAT_RGB8)
	for y in 128:
		for x in 256:
			var v = n.get_noise_2d(x, y * 1.6) * 0.5 + 0.5
			var c = Color("#0a0c16").lerp(Color("#4a5070"), clampf(v * v * 1.6, 0, 1))
			c = c.lerp(Color("#05060a"), clampf((y - 70) / 58.0, 0, 1))
			im.set_pixel(x, y, c)
	return ImageTexture.create_from_image(im)
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
				if g.size() > 3:
					box(r, Vector3(0.14, g[3], w), Vector3(f, g[3] / 2, mid), wall)
			# zárubeň (jen u dveří)
			for e in ([] if g.size() > 3 else [g[0], g[1]]):
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
	var er = room("EMA", "Pokojíček Emy", -2.2, -2.2, 2.2, 2.2, wp_ema, planks, {"w": [[-0.5, 0.5]], "e": [[-0.5, 0.5], [0.95, 1.85, 1.95, 0.95]], "n": [[-0.6, 0.6]]})
	# dveře do chodeb – vlevo a vpravo. Zavřené: otevřít je umí jen animatronici (Door_L / Door_R, pant u z = -0.5)
	door_leaf(er, Vector3(-2.2, 0, -0.5), 1.0, 0.0, false, "Door_L")
	door_leaf(er, Vector3(2.2, 0, -0.5), 1.0, 0.0, false, "Door_R")
	# ---------- skříň v severní stěně: masivní dřevěná, rámové výplně, lišta, mosazné úchytky
	var cl = Node3D.new()
	cl.name = "Closet"
	cl.position = Vector3(0, 0, -2.2)
	er.add_child(cl)
	var wood = mat("#7a4a26", 0.7)
	var wood_d = mat("#5a3418", 0.75)
	var brass = mat("#c8a448", 0.3, 0.85)
	box(cl, Vector3(1.5, 2.25, 0.72), Vector3(0, 1.125, -0.36), wood_d)
	box(cl, Vector3(1.62, 0.12, 0.8), Vector3(0, 2.29, -0.34), wood)
	box(cl, Vector3(1.56, 0.08, 0.78), Vector3(0, 2.2, -0.34), wood_d)
	box(cl, Vector3(1.56, 0.1, 0.76), Vector3(0, 0.05, -0.34), wood_d)
	box(cl, Vector3(1.24, 2.0, 0.6), Vector3(0, 1.08, -0.4), mat("#030202", 1.0))
	for s in [-1, 1]:
		box(cl, Vector3(0.1, 2.1, 0.06), Vector3(0.69 * s, 1.1, 0.01), wood)
	var cdoor = func(nm: String, hx: float, dir: float) -> void:
		var d = Node3D.new()
		d.name = nm
		d.position = Vector3(hx, 0, 0.03)
		cl.add_child(d)
		var cx = 0.31 * dir
		box(d, Vector3(0.62, 2.04, 0.04), Vector3(cx, 1.1, 0), wood)
		box(d, Vector3(0.46, 0.8, 0.02), Vector3(cx, 1.58, 0.025), wood_d)
		box(d, Vector3(0.46, 0.7, 0.02), Vector3(cx, 0.6, 0.025), wood_d)
		box(d, Vector3(0.4, 0.74, 0.012), Vector3(cx, 1.58, 0.037), wood)
		box(d, Vector3(0.4, 0.64, 0.012), Vector3(cx, 0.6, 0.037), wood)
		box(d, Vector3(0.03, 0.14, 0.04), Vector3(0.56 * dir, 1.1, 0.05), brass)
		for y in [0.3, 1.9]:
			box(d, Vector3(0.02, 0.1, 0.03), Vector3(0.01 * dir, y, 0.0), brass)
	cdoor.call("Closet_L", -0.62, 1.0)
	cdoor.call("Closet_R", 0.62, -1.0)
	box(cl, Vector3(0.05, 0.05, 0.02), Vector3(0, 1.1, 0.08), brass)
	# ---------- postel za zády: dřevěná s čely, sloupky, matrace, peřina s Cocoou, polštář s volánem
	var bed = Node3D.new()
	bed.name = "Bed"
	bed.position = Vector3(0, 0, 1.25)
	er.add_child(bed)
	var bw = mat("#a06a3a", 0.6)
	box(bed, Vector3(1.0, 0.16, 1.9), Vector3(0, 0.3, 0), bw)
	for sx in [-1, 1]:
		box(bed, Vector3(0.05, 0.14, 1.9), Vector3(0.5 * sx, 0.3, 0), wood_d)
		for sz in [-1, 1]:
			box(bed, Vector3(0.08, 0.95 if sz > 0 else 0.6, 0.08), Vector3(0.5 * sx, (0.95 if sz > 0 else 0.6) / 2, 0.95 * sz), bw)
			cyl(bed, 0.05, 0.05, Vector3(0.5 * sx, (0.95 if sz > 0 else 0.6) + 0.025, 0.95 * sz), brass)
	box(bed, Vector3(0.94, 0.6, 0.04), Vector3(0, 0.6, 0.95), bw)
	for i in 5:
		box(bed, Vector3(0.04, 0.42, 0.05), Vector3(-0.36 + i * 0.18, 0.62, 0.95), wood_d)
	box(bed, Vector3(0.94, 0.3, 0.04), Vector3(0, 0.42, -0.95), bw)
	box(bed, Vector3(0.92, 0.16, 1.84), Vector3(0, 0.46, 0), mat("#f6f0e6", 0.95))
	# peřina: zvlněná, odhrnutá (Ema z ní právě vstala)
	var duv = mat("#e88ab8", 0.95)
	for i in 6:
		box(bed, Vector3(0.98, 0.07 + (i % 2) * 0.03, 0.2), Vector3(0, 0.57 + (i % 2) * 0.015, -0.85 + i * 0.2), duv, Vector3(randf_range(-0.05, 0.05), 0, 0))
	box(bed, Vector3(0.98, 0.12, 0.25), Vector3(0.0, 0.6, 0.38), duv, Vector3(0.4, 0, 0))
	box(bed, Vector3(0.98, 0.03, 0.08), Vector3(0, 0.62, 0.48), mat("#ffffff"))
	for i in 6:
		box(bed, Vector3(0.1, 0.075, 0.1), Vector3(-0.36 + (i % 3) * 0.36, 0.6, -0.7 + int(i / 3) * 0.45), mat("#6a3a1c"))
		box(bed, Vector3(0.03, 0.08, 0.03), Vector3(-0.39 + (i % 3) * 0.36, 0.63, -0.72 + int(i / 3) * 0.45), mat("#6a3a1c"))
	box(bed, Vector3(0.64, 0.14, 0.34), Vector3(0, 0.6, 0.7), mat("#ffffff", 0.95))
	box(bed, Vector3(0.7, 0.04, 0.4), Vector3(0, 0.55, 0.7), mat("#f8d8e8", 0.95))
	# plyšová Cocoa (na polštáři)
	var cp = Node3D.new()
	cp.name = "CocoaPlush"
	cp.position = Vector3(-0.22, 0.67, 1.92)
	cp.rotation = Vector3(-0.3, PI, 0.15)
	er.add_child(cp)
	var choc = mat("#7a4a2a", 0.95)
	box(cp, Vector3(0.16, 0.18, 0.12), Vector3(0, 0.09, 0), choc)
	box(cp, Vector3(0.1, 0.1, 0.02), Vector3(0, 0.1, 0.06), mat("#c89a70"))
	box(cp, Vector3(0.17, 0.16, 0.15), Vector3(0, 0.26, 0), choc)
	box(cp, Vector3(0.18, 0.04, 0.16), Vector3(0, 0.35, 0), mat("#f4ece0"))
	for s in [-1, 1]:
		box(cp, Vector3(0.045, 0.22, 0.03), Vector3(0.05 * s, 0.44, -0.02), choc, Vector3(0, 0, 0.15 * s))
		box(cp, Vector3(0.05, 0.05, 0.01), Vector3(0.042 * s, 0.28, 0.08), mat("#111111"))
		box(cp, Vector3(0.015, 0.015, 0.005), Vector3(0.048 * s, 0.29, 0.087), mat("#ffffff"))
		box(cp, Vector3(0.05, 0.1, 0.05), Vector3(0.1 * s, 0.1, 0.0), choc, Vector3(0, 0, 0.5 * s))
	box(cp, Vector3(0.03, 0.02, 0.02), Vector3(0, 0.24, 0.08), mat("#3a1a0a"))
	# plyšový Voxie (na zemi)
	var vp = Node3D.new()
	vp.name = "VoxiePlush"
	vp.position = Vector3(1.5, 0, 0.9)
	vp.rotation.y = -0.9
	er.add_child(vp)
	var vb = mat("#6a4020", 0.95)
	box(vp, Vector3(0.22, 0.24, 0.16), Vector3(0, 0.12, 0), vb)
	box(vp, Vector3(0.14, 0.14, 0.02), Vector3(0, 0.12, 0.085), mat("#a87848"))
	box(vp, Vector3(0.24, 0.21, 0.2), Vector3(0, 0.345, 0), vb)
	box(vp, Vector3(0.12, 0.07, 0.04), Vector3(0, 0.3, 0.11), mat("#a87848"))
	box(vp, Vector3(0.04, 0.03, 0.02), Vector3(0, 0.325, 0.13), mat("#111111"))
	for s in [-1, 1]:
		box(vp, Vector3(0.08, 0.08, 0.05), Vector3(0.1 * s, 0.47, 0), vb)
		box(vp, Vector3(0.04, 0.04, 0.01), Vector3(0.1 * s, 0.47, 0.03), mat("#a87848"))
		box(vp, Vector3(0.045, 0.045, 0.01), Vector3(0.055 * s, 0.38, 0.105), mat("#111111"))
		box(vp, Vector3(0.06, 0.14, 0.06), Vector3(0.14 * s, 0.14, 0.0), vb, Vector3(0, 0, 0.4 * s))
		box(vp, Vector3(0.07, 0.06, 0.1), Vector3(0.07 * s, 0.03, 0.06), vb)
	box(vp, Vector3(0.1, 0.045, 0.02), Vector3(0, 0.25, 0.09), mat("#c02060"))
	# ---------- psací stolek se šuplíky, židlička, kresby, pastelky v hrnku, lampička, budík
	var desk = Node3D.new()
	desk.name = "Desk"
	desk.position = Vector3(-1.75, 0, 1.15)
	desk.rotation.y = PI / 2
	er.add_child(desk)
	var dw = mat("#e8d8b8", 0.6)
	box(desk, Vector3(0.9, 0.05, 0.55), Vector3(0, 0.64, 0), dw)
	box(desk, Vector3(0.32, 0.6, 0.52), Vector3(0.27, 0.31, 0), dw)
	for i in 3:
		box(desk, Vector3(0.28, 0.17, 0.02), Vector3(0.27, 0.12 + i * 0.19, 0.27), mat("#f0e4cc"))
		box(desk, Vector3(0.08, 0.025, 0.03), Vector3(0.27, 0.15 + i * 0.19, 0.285), brass)
	for sz in [-1, 1]:
		box(desk, Vector3(0.04, 0.62, 0.04), Vector3(-0.42, 0.31, 0.24 * sz), dw)
	box(desk, Vector3(0.21, 0.004, 0.29), Vector3(-0.15, 0.668, 0.05), mat("#f8f4e8"), Vector3(0, 0.3, 0))
	box(desk, Vector3(0.21, 0.004, 0.29), Vector3(0.12, 0.67, -0.05), mat("#f8f4e8"), Vector3(0, -0.4, 0))
	for i in 4:
		box(desk, Vector3(0.04, 0.003, 0.02), Vector3(-0.2 + i * 0.03, 0.672, 0.05 + i * 0.02), mat(["#d02020", "#2060d0", "#20a040", "#e0c020"][i]))
	cyl(desk, 0.04, 0.09, Vector3(0.35, 0.71, -0.18), mat("#4080c0", 0.4))
	for i in 5:
		box(desk, Vector3(0.012, 0.14, 0.012), Vector3(0.33 + (i % 3) * 0.02, 0.77, -0.19 + int(i / 3) * 0.02), mat(["#d02020", "#2060d0", "#20a040", "#e0c020", "#8a4a20"][i]), Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2)))
	cyl(desk, 0.07, 0.03, Vector3(-0.32, 0.68, -0.18), mat("#e8a0c0"))
	cyl(desk, 0.012, 0.28, Vector3(-0.32, 0.82, -0.18), mat("#e8a0c0"))
	var shade = MeshInstance3D.new()
	var sh = CylinderMesh.new()
	sh.top_radius = 0.06
	sh.bottom_radius = 0.11
	sh.height = 0.12
	shade.mesh = sh
	shade.material_override = mat("#fff0f8", 0.6)
	shade.position = Vector3(-0.32, 0.99, -0.18)
	desk.add_child(shade)
	box(desk, Vector3(0.12, 0.09, 0.06), Vector3(0.05, 0.71, -0.2), mat("#c02020", 0.4))
	for s in [-1, 1]:
		cyl(desk, 0.025, 0.02, Vector3(0.05 + 0.04 * s, 0.77, -0.2), mat("#e0e0e0", 0.3, 0.8))
	label(desk, "00:00", Vector3(0.05, 0.71, -0.165), "#ff3030", 22)
	var ch = Node3D.new()
	ch.position = Vector3(-0.05, 0, 0.45)
	ch.rotation.y = 0.3
	desk.add_child(ch)
	box(ch, Vector3(0.36, 0.04, 0.34), Vector3(0, 0.38, 0), mat("#e88ab8", 0.6))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			box(ch, Vector3(0.03, 0.38, 0.03), Vector3(0.15 * sx, 0.19, 0.14 * sz), mat("#e8e0d0"))
	box(ch, Vector3(0.36, 0.3, 0.03), Vector3(0, 0.6, 0.16), mat("#e88ab8", 0.6))
	# ---------- truhla s hračkami (víko pootevřené, vykukují hračky)
	var tb = Node3D.new()
	tb.name = "ToyChest"
	tb.position = Vector3(1.6, 0, -1.45)
	er.add_child(tb)
	box(tb, Vector3(0.72, 0.45, 0.46), Vector3(0, 0.225, 0), mat("#c84040", 0.7))
	for x in [-0.3, 0, 0.3]:
		box(tb, Vector3(0.04, 0.45, 0.47), Vector3(x, 0.225, 0), mat("#a03030", 0.7))
	box(tb, Vector3(0.74, 0.05, 0.47), Vector3(0, 0.03, 0), mat("#802020", 0.7))
	box(tb, Vector3(0.64, 0.12, 0.38), Vector3(0, 0.4, 0), mat("#100606", 1.0))
	box(tb, Vector3(0.1, 0.18, 0.1), Vector3(-0.18, 0.5, 0.05), mat("#2060d0"), Vector3(0.3, 0, 0.2))
	cyl(tb, 0.07, 0.08, Vector3(0.15, 0.5, -0.05), mat("#e0c020"), Vector3(0.6, 0, 0))
	box(tb, Vector3(0.04, 0.25, 0.04), Vector3(0.0, 0.55, 0.0), mat("#20a040"), Vector3(0, 0, 0.5))
	var lid = Node3D.new()
	lid.position = Vector3(0, 0.45, -0.23)
	lid.rotation.x = -1.1
	tb.add_child(lid)
	box(lid, Vector3(0.74, 0.06, 0.47), Vector3(0, 0, 0.235), mat("#a03030", 0.7))
	box(lid, Vector3(0.3, 0.08, 0.02), Vector3(0, 0.0, 0.47), mat("#ffe46b"))
	for i in 6:
		box(er, Vector3(0.12, 0.12, 0.12), Vector3(randf_range(-1.0, 1.2), 0.06, randf_range(-1.2, 0.6)), mat(["#d02020", "#2060d0", "#20a040", "#e0c020"][i % 4]), Vector3(0, randf() * 3, 0))
	# ---------- police s knížkami nad truhlou
	var shelf = Node3D.new()
	shelf.position = Vector3(2.08, 1.5, -1.3)
	er.add_child(shelf)
	box(shelf, Vector3(0.24, 0.03, 0.9), Vector3(0, 0, 0), wood)
	for s in [-1, 1]:
		box(shelf, Vector3(0.03, 0.12, 0.03), Vector3(0.08, -0.07, 0.4 * s), brass)
	var bz = -0.38
	for i in 10:
		var bwid = randf_range(0.03, 0.06)
		var bh = randf_range(0.16, 0.24)
		box(shelf, Vector3(0.16, bh, bwid), Vector3(-0.02, 0.015 + bh / 2, bz), mat(["#c03030", "#3060b0", "#e0c040", "#40a060", "#a050a0", "#f08030"][i % 6], 0.8))
		bz += bwid + 0.008
	box(shelf, Vector3(0.12, 0.18, 0.1), Vector3(-0.02, 0.105, 0.34), mat("#7a4a2a", 0.95))
	# ---------- noční stolek u postele se sklenicí vody
	var ns = Node3D.new()
	ns.position = Vector3(0.85, 0, 1.95)
	er.add_child(ns)
	box(ns, Vector3(0.4, 0.5, 0.36), Vector3(0, 0.25, 0), wood)
	box(ns, Vector3(0.32, 0.16, 0.02), Vector3(0, 0.33, -0.19), wood_d)
	box(ns, Vector3(0.06, 0.02, 0.03), Vector3(0, 0.33, -0.2), brass)
	var gl = StandardMaterial3D.new()
	gl.albedo_color = Color(0.8, 0.9, 1.0, 0.35)
	gl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gl.roughness = 0.05
	cyl(ns, 0.035, 0.11, Vector3(-0.08, 0.56, 0.0), gl)
	# kresby na zdi
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
		pic.position = Vector3(-2.12, 1.45 + (i % 2) * 0.35, -1.25 + i * 0.5)
		pic.rotation = Vector3(0, PI / 2, randf_range(-0.1, 0.1))
		er.add_child(pic)
		box(er, Vector3(0.01, 0.03, 0.03), Vector3(-2.125, 1.45 + (i % 2) * 0.35 + 0.13, -1.25 + i * 0.5), mat("#e02020"))
	# koberec
	box(er, Vector3(1.8, 0.01, 1.4), Vector3(0, 0.005, -0.2), tex(img_rug(), 0.55, 0.95))
	# ---------- okno s bouřkou (skutečný otvor ve zdi)
	var win = Node3D.new()
	win.name = "Window"
	win.position = Vector3(2.2, 0, 1.4)
	er.add_child(win)
	var frame = mat("#f0ece4", 0.5)
	box(win, Vector3(0.18, 0.06, 0.96), Vector3(-0.02, 0.95, 0), frame)
	box(win, Vector3(0.26, 0.04, 1.0), Vector3(-0.1, 0.92, 0), frame)
	box(win, Vector3(0.18, 0.06, 0.96), Vector3(0, 1.95, 0), frame)
	for s in [-1, 1]:
		box(win, Vector3(0.18, 1.06, 0.06), Vector3(0, 1.45, 0.45 * s), frame)
	box(win, Vector3(0.06, 1.0, 0.05), Vector3(0, 1.45, 0), frame)
	box(win, Vector3(0.06, 0.05, 0.9), Vector3(0, 1.45, 0), frame)
	var glass = StandardMaterial3D.new()
	glass.albedo_color = Color(0.5, 0.6, 0.75, 0.16)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.02
	glass.metallic = 0.3
	box(win, Vector3(0.01, 1.0, 0.9), Vector3(0.0, 1.45, 0), glass)
	# kapky na skle
	var drop = StandardMaterial3D.new()
	drop.albedo_color = Color(0.85, 0.9, 1.0, 0.45)
	drop.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop.roughness = 0.0
	for i in 40:
		box(win, Vector3(0.004, randf_range(0.015, 0.06), 0.012), Vector3(-0.008, randf_range(1.0, 1.9), randf_range(-0.42, 0.42)), drop)
	# závěsy s řasením, garnýž
	cyl(win, 0.015, 1.5, Vector3(-0.12, 2.1, 0), brass, Vector3(PI / 2, 0, 0))
	for s in [-1, 1]:
		for k in 4:
			box(win, Vector3(0.05, 1.5, 0.08), Vector3(-0.12 + (k % 2) * 0.03, 1.33, s * (0.5 + k * 0.07)), mat("#8a5aa8" if k % 2 == 0 else "#7a4a98", 0.95))
	# radiátor pod oknem
	for i in 8:
		box(win, Vector3(0.08, 0.5, 0.05), Vector3(-0.12, 0.55, -0.35 + i * 0.1), mat("#e8e8e8", 0.5, 0.3))
	box(win, Vector3(0.06, 0.04, 0.8), Vector3(-0.12, 0.3, 0), mat("#d8d8d8", 0.5, 0.3))
	# venku: zahrada, plot, strom, sousední dům, bouřková obloha, blesk
	var out = Node3D.new()
	out.name = "Storm"
	out.position = Vector3(2.2, 0, 1.4)
	er.add_child(out)
	var sky = MeshInstance3D.new()
	sky.name = "StormSky"
	var sq = QuadMesh.new()
	sq.size = Vector2(16, 8)
	sky.mesh = sq
	var sm = StandardMaterial3D.new()
	sm.albedo_texture = _storm_tex()
	sm.emission_enabled = true
	sm.emission_texture = sm.albedo_texture
	sm.emission_energy_multiplier = 0.35
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky.material_override = sm
	sky.position = Vector3(9.0, 3.0, 0)
	sky.rotation.y = -PI / 2
	out.add_child(sky)
	storm_sky_mat = sm
	box(out, Vector3(9, 0.05, 12), Vector3(4.5, -0.6, 0), mat("#0a1408", 1.0))
	for i in 14:
		box(out, Vector3(0.06, 0.9, 0.1), Vector3(3.6, -0.15, -3.5 + i * 0.5), mat("#1a1410"))
	box(out, Vector3(0.04, 0.06, 7.0), Vector3(3.6, 0.15, 0), mat("#1a1410"))
	box(out, Vector3(0.04, 0.06, 7.0), Vector3(3.6, -0.3, 0), mat("#1a1410"))
	# strom: kmen a holé větve (silueta)
	var tree = Node3D.new()
	tree.position = Vector3(2.6, -0.6, -1.4)
	out.add_child(tree)
	var bark = mat("#0a0806", 1.0)
	box(tree, Vector3(0.3, 4.5, 0.3), Vector3(0, 2.25, 0), bark)
	for i in 9:
		var y = 1.6 + i * 0.35
		box(tree, Vector3(0.08, 1.4 - i * 0.08, 0.08), Vector3(0, y, 0), bark, Vector3(randf_range(-0.9, 0.9), 0, randf_range(0.6, 1.2) * (1 if i % 2 else -1)))
	# sousední dům se svítícím oknem
	box(out, Vector3(3.0, 3.2, 4.0), Vector3(7.6, 0.9, 2.5), mat("#0c0a10", 1.0))
	box(out, Vector3(3.2, 0.8, 4.4), Vector3(7.6, 2.8, 2.5), mat("#08060a", 1.0), Vector3(PI / 4, 0, 0))
	box(out, Vector3(0.05, 0.5, 0.4), Vector3(6.08, 1.0, 1.6), mat("#ffc060", 0.5, 0.0, 2.5))
	# déšť: šikmé provazce kapek (ve hře se pohybují)
	var rain = Node3D.new()
	rain.name = "Rain"
	out.add_child(rain)
	var rm = StandardMaterial3D.new()
	rm.albedo_color = Color(0.7, 0.8, 1.0, 0.35)
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 220:
		box(rain, Vector3(0.006, randf_range(0.25, 0.5), 0.006), Vector3(randf_range(0.3, 6.0), randf_range(-0.4, 3.5), randf_range(-3.0, 3.0)), rm, Vector3(0.25, 0, 0))
	# blesk: klikatý, svítivý (ve hře jen na zlomek vteřiny)
	var bolt = Node3D.new()
	bolt.name = "LightningBolt"
	bolt.position = Vector3(6.4, 4.6, -0.5)
	out.add_child(bolt)
	var bm = mat("#e8f0ff", 0.0, 0.0, 6.0)
	var p = Vector3.ZERO
	for i in 9:
		var q2 = p + Vector3(randf_range(-0.25, 0.25), -0.75, randf_range(-0.5, 0.5))
		var seg = box(bolt, Vector3(0.05, p.distance_to(q2), 0.05), (p + q2) / 2, bm)
		seg.look_at_from_position((p + q2) / 2 + bolt.position + out.position + er.position, q2 + bolt.position + out.position + er.position, Vector3.FORWARD)
		seg.rotate_object_local(Vector3.RIGHT, PI / 2)
		if i == 4:
			var br = q2 + Vector3(0, -0.6, 0.6)
			var s2 = box(bolt, Vector3(0.03, q2.distance_to(br), 0.03), (q2 + br) / 2, bm)
			s2.rotation.x = 0.8
		p = q2
	lightning = OmniLight3D.new()
	lightning.name = "LightningLight"
	lightning.light_color = Color("#c8d8ff")
	lightning.light_energy = 0.0
	lightning.omni_range = 16
	lightning.position = Vector3(1.6, 2.4, 0)
	out.add_child(lightning)
	storm_bolt = bolt
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
	info["storm"] = {"sky": "StormSky", "bolt": "LightningBolt", "light": "LightningLight", "rain": "Rain", "note": "Ema se často budila při bouřce: blesk na zlomek vteřiny ozáří pokoj, pak hrom."}
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
	var shots = [["window", Vector3(0.2, 1.1, 1.0), Vector3(3.0, 1.7, 1.3), false], ["flash", Vector3(0.2, 1.1, 1.0), Vector3(3.0, 1.7, 1.3), false], ["bedd", Vector3(-0.2, 1.3, -0.3), Vector3(0.0, 0.5, 1.6), true], ["deskd", Vector3(-0.5, 1.3, 0.4), Vector3(-1.8, 0.7, 1.15), true], ["open", eye, Vector3(-4.0, 1.0, 0.0), true], ["closet", eye, Vector3(0, 1.0, -2.2), true], ["left", eye, Vector3(-4.0, 1.0, 0.0), true], ["right", eye, Vector3(4.0, 1.0, 0.1), true], ["bed", eye, Vector3(0, 0.6, 1.6), true], ["dark", eye, Vector3(0, 1.0, -2.2), false], ["hall", Vector3(-2.6, 1.05, 0.1), Vector3(-8, 0.8, 0), true], ["parents", Vector3(5.6, 1.1, 0.4), Vector3(8.6, 0.6, 0.0), true], ["top", Vector3(0, 16, 0.01), Vector3(0, 0, 0), false]]
	for s in shots:
		var fl = s[0] == "flash"
		lightning.light_energy = 5.0 if fl else 0.0
		storm_bolt.visible = fl
		storm_sky_mat.emission_energy_multiplier = 3.5 if fl else 0.35
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
