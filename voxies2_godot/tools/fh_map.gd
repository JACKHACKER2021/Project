extends SceneTree
## FRIGHTS & HIDES – mapa pro budoucí hru (Remaster 3+4).
## Strašidelná atrakce z věcí po vyhořelé herně Voxie's: automaty a stoly vytažené z budovy 2,
## Cocoina hlava ve vitríně, ohořelá kresba v rámu, vzadu zákulisí připravené pro Hollow Hare.
## Výstup: models/frights_hides_map.glb, data/frights_hides_map.json a náhledy.

const H := 3.2
var root3: Node3D
var map: Node3D
var info := {"rooms": {}, "cams": {}, "spawns": {}, "vents": []}
var mats := {}

func mat(c: String, rough := 0.9, metal := 0.0, unshaded := false) -> StandardMaterial3D:
	var k = c + str(rough) + str(metal) + str(unshaded)
	if mats.has(k):
		return mats[k]
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = rough
	m.metallic = metal
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mats[k] = m
	return m

func box(p: Node3D, sz: Vector3, pos: Vector3, m: Material, nm := "") -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.position = pos
	mi.material_override = m
	if nm != "":
		mi.name = nm
	p.add_child(mi)
	return mi

func label(p: Node3D, text: String, pos: Vector3, col: String, size := 48, rot_y := 0.0) -> void:
	var l = Label3D.new()
	l.text = text
	l.font_size = size
	l.modulate = Color(col)
	l.position = pos
	l.rotation.y = rot_y
	p.add_child(l)

func omni(p: Node3D, pos: Vector3, c: String, e: float, r: float) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.light_color = Color(c)
	l.light_energy = e
	l.omni_range = r
	l.position = pos
	p.add_child(l)
	return l

## místnost: podlaha, strop a zdi s otvory. doors = {"n": [[a,b]], "s":..., "w":..., "e":...}
func room(id: String, name: String, x0: float, z0: float, x1: float, z1: float, wall: String, floor_a: String, floor_b: String, doors := {}, h := H) -> Node3D:
	var r = Node3D.new()
	r.name = "Room_" + id
	map.add_child(r)
	info.rooms[id] = {"name": name, "x0": x0, "z0": z0, "x1": x1, "z1": z1, "h": h, "doors": doors}
	# šachovnicová podlaha
	var ts = 1.0
	var x = x0
	while x < x1 - 0.001:
		var z = z0
		while z < z1 - 0.001:
			var a = (int(floor(x / ts)) + int(floor(z / ts))) % 2 == 0
			box(r, Vector3(minf(ts, x1 - x), 0.05, minf(ts, z1 - z)), Vector3(x + minf(ts, x1 - x) / 2, -0.025, z + minf(ts, z1 - z) / 2), mat(floor_a if a else floor_b))
			z += ts
		x += ts
	box(r, Vector3(x1 - x0, 0.1, z1 - z0), Vector3((x0 + x1) / 2, h + 0.05, (z0 + z1) / 2), mat("#141214"))
	var wm = mat(wall)
	var trim = mat("#1a1018")
	for side in ["n", "s", "w", "e"]:
		var ns = side == "n" or side == "s"
		var a0 = x0 if ns else z0
		var a1 = x1 if ns else z1
		var fixed = z0 if side == "n" else (z1 if side == "s" else (x0 if side == "w" else x1))
		var gaps = doors.get(side, [])
		gaps.sort_custom(func(p, q): return p[0] < q[0])
		var cur = a0
		var segs = []
		for g in gaps:
			segs.append([cur, g[0]])
			# překlad nad dveřmi
			var mid = (g[0] + g[1]) / 2.0
			var w = g[1] - g[0]
			if ns:
				box(r, Vector3(w, h - 2.3, 0.2), Vector3(mid, 2.3 + (h - 2.3) / 2, fixed), wm)
			else:
				box(r, Vector3(0.2, h - 2.3, w), Vector3(fixed, 2.3 + (h - 2.3) / 2, mid), wm)
			cur = g[1]
		segs.append([cur, a1])
		for sg in segs:
			var L = sg[1] - sg[0]
			if L <= 0.01:
				continue
			var mid = (sg[0] + sg[1]) / 2.0
			if ns:
				box(r, Vector3(L, h, 0.2), Vector3(mid, h / 2, fixed), wm)
				box(r, Vector3(L, 0.12, 0.24), Vector3(mid, 0.06, fixed), trim)
			else:
				box(r, Vector3(0.2, h, L), Vector3(fixed, h / 2, mid), wm)
				box(r, Vector3(0.24, 0.12, L), Vector3(fixed, 0.06, mid), trim)
	return r

func cam_point(id: String, name: String, pos: Vector3, look: Vector3) -> void:
	info.cams[id] = {"name": name, "pos": [pos.x, pos.y, pos.z], "look": [look.x, look.y, look.z]}
	var c = Node3D.new()
	c.name = "CAM_" + id
	c.position = pos
	map.add_child(c)
	box(c, Vector3(0.22, 0.14, 0.3), Vector3.ZERO, mat("#2a2a30", 0.5, 0.6))
	box(c, Vector3(0.05, 0.05, 0.02), Vector3(0.06, 0.04, -0.16), mat("#ff2020", 0.5, 0.0, true))

# ---------------------------------------------------------------- assety z budovy 2
func extract_from_building() -> Dictionary:
	var b = load("res://models/broken_map.glb").instantiate()
	root3.add_child(b)
	var out = {"cabinets": [], "tables": [], "curtain": []}
	# automaty z herny (1B): celé skupiny dílů s výškou automatu
	var taken = []
	for n in b.find_children("*", "Node3D", true, false):
		if n is MeshInstance3D:
			continue
		var skip = false
		for t in taken:
			if t.is_ancestor_of(n):
				skip = true
				break
		if skip:
			continue
		var ms = n.find_children("*", "MeshInstance3D", true, false)
		if ms.size() < 3 or ms.size() > 60:
			continue
		var a = AABB()
		var first = true
		for mi in ms:
			var aa = mi.global_transform * mi.get_aabb()
			a = aa if first else a.merge(aa)
			first = false
		var c = a.get_center()
		if c.x > -10 and c.x < 10 and c.z > -222 and c.z < -212 and a.size.y > 1.3 and a.size.y < 2.6 and maxf(a.size.x, a.size.z) < 1.8:
			taken.append(n)
			out.cabinets.append([n, a])
	# stoly z pizzerie (2): deska 1.6 × 1.6 + noha + kloboučky kolem
	var tops = []
	var all_m = b.find_children("*", "MeshInstance3D", true, false)
	for mi in all_m:
		var a = mi.global_transform * mi.get_aabb()
		var c = a.get_center()
		if c.x > -22 and c.x < -10 and c.z > -222 and c.z < -210 and absf(a.size.x - 1.6) < 0.2 and absf(a.size.z - 1.6) < 0.2 and a.size.y < 0.2:
			tops.append(c)
	for tc in tops:
		var group = []
		for mi in all_m:
			var a = mi.global_transform * mi.get_aabb()
			var c = a.get_center()
			if Vector2(c.x - tc.x, c.z - tc.z).length() < 1.1 and c.y < 1.4 and a.size.y < 1.0 and maxf(a.size.x, a.size.z) < 1.8:
				group.append(mi)
		out.tables.append([tc, group])
	out.building = b
	return out

func place_copy(nodes: Array, src_center: Vector3, dst: Vector3, yaw := 0.0, parent: Node3D = null) -> Node3D:
	var holder = Node3D.new()
	(parent if parent else map).add_child(holder)
	holder.position = dst
	holder.rotation.y = yaw
	for n in nodes:
		var d = n.duplicate()
		holder.add_child(d)
		if d is Node3D:
			var gt: Transform3D = n.global_transform
			d.transform = Transform3D(gt.basis, gt.origin - src_center)
	return holder

# ---------------------------------------------------------------- stavba mapy
func build() -> void:
	map = Node3D.new()
	map.name = "FrightsAndHides"
	root3.add_child(map)
	var wall_d = "#2a2230"
	# kancelář hlídače (jih), okno do hlavní chodby, dveře vlevo, větrací šachta vpravo
	var off = room("OFF", "Kancelář", -3, 6, 3, 10, "#2a2632", "#1a1620", "#262030", {"n": [], "w": [[7.0, 8.6]]})
	box(off, Vector3(3.0, 1.2, 0.22), Vector3(0, 0.6, 6), mat("#2a2632"))
	box(off, Vector3(3.0, 0.9, 0.22), Vector3(0, 2.75, 6), mat("#2a2632"))
	for x in [-1.5, 1.5]:
		pass
	var glass = StandardMaterial3D.new()
	glass.albedo_color = Color(0.6, 0.75, 0.8, 0.18)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	box(off, Vector3(3.0, 1.1, 0.04), Vector3(0, 1.75, 6.02), glass, "OfficeWindow")
	# vnitřek kanceláře: stůl, monitor, panel, plakáty, ventilátor
	box(off, Vector3(2.6, 0.08, 0.9), Vector3(0, 0.78, 7.1), mat("#3a2a1e"))
	for x in [-1.2, 1.2]:
		box(off, Vector3(0.08, 0.74, 0.8), Vector3(x, 0.39, 7.1), mat("#2a1e14"))
	box(off, Vector3(0.66, 0.5, 0.5), Vector3(0.2, 1.08, 7.2), mat("#d8d0b8", 0.6), "Monitor")
	box(off, Vector3(0.52, 0.38, 0.02), Vector3(0.2, 1.1, 6.94), mat("#0a2a12", 0.3, 0.0, true), "MonitorScreen")
	box(off, Vector3(0.5, 0.3, 0.06), Vector3(-0.9, 0.95, 6.95), mat("#2a2a30", 0.5, 0.5), "ControlPanel")
	for i in 3:
		box(off, Vector3(0.08, 0.08, 0.03), Vector3(-1.05 + i * 0.15, 0.98, 6.91), mat(["#ff3030", "#30ff60", "#3080ff"][i], 0.5, 0.0, true))
	box(off, Vector3(0.7, 0.9, 0.03), Vector3(-2.0, 1.7, 9.88), mat("#3a1030"))
	label(off, "VOXIE'S\nBAV SE!", Vector3(-2.0, 1.7, 9.85), "#ffb030", 28, PI)
	box(off, Vector3(0.6, 0.8, 0.03), Vector3(2.98, 1.6, 8.6), mat("#202a3a"))
	label(off, "FRIGHTS\n& HIDES", Vector3(2.95, 1.6, 8.6), "#ff5050", 26, -PI / 2)
	box(off, Vector3(0.9, 0.9, 0.2), Vector3(2.9, 0.6, 7.6), mat("#3a3a40", 0.4, 0.7), "VentOffice")
	for i in 5:
		box(off, Vector3(0.05, 0.75, 0.22), Vector3(2.9, 0.6, 7.25 + i * 0.17), mat("#1a1a1e", 0.4, 0.7))
	omni(off, Vector3(0, 2.9, 8.0), "#ffe0b0", 1.2, 6)
	info.spawns["player"] = [0, 1.35, 8.4]
	# hlavní chodba s exponáty
	var hall = room("HALL", "Hlavní chodba", -3, -8, 3, 6, wall_d, "#2a1c1c", "#1a1212", {"s": [], "n": [[-1, 1]], "w": [[3.0, 4.6], [-3.6, -2.0]], "e": [[-5.0, -3.0], [2.0, 4.0]]})
	for z in [-6.0, -2.0, 2.0]:
		box(hall, Vector3(0.6, 0.1, 0.25), Vector3(0, 3.1, z), mat("#fff0c8", 0.5, 0.0, true))
	omni(hall, Vector3(0, 2.8, -4.0), "#ffd8a0", 0.8, 7)
	omni(hall, Vector3(0, 2.8, 3.0), "#ff9070", 0.6, 6)
	for z in [-5.0, 0.0, 4.0]:
		box(hall, Vector3(0.05, 0.9, 0.7), Vector3(-2.88, 1.6, z), mat(["#3b1d6e", "#14313d", "#4a1438"][int(z + 5) % 3]))
	# zbytky Voxieho – jen výstavní kus na pódiu za provazy
	var vx = Node3D.new()
	vx.name = "VoxieRemainsExhibit"
	vx.position = Vector3(0, 0, -6.0)
	hall.add_child(vx)
	box(vx, Vector3(2.6, 0.3, 1.8), Vector3(0, 0.15, 0), mat("#2a1410"))
	box(vx, Vector3(2.7, 0.04, 1.9), Vector3(0, 0.31, 0), mat("#4a2418", 0.7))
	var vm_ = load("res://models/znicen_voxie.glb").instantiate()
	vm_.scale = Vector3.ONE * 0.85
	vm_.position = Vector3(0, 0.32, 0)
	vx.add_child(vm_)
	for ap in vm_.find_children("*", "AnimationPlayer", true, false):
		ap.queue_free()
	for s in [-1, 1]:
		box(vx, Vector3(0.08, 0.9, 0.08), Vector3(1.0 * s, 0.45, 1.3), mat("#c0a040", 0.3, 0.8))
	box(vx, Vector3(2.0, 0.05, 0.05), Vector3(0, 0.75, 1.3), mat("#8a1020"))
	box(vx, Vector3(0.7, 0.4, 0.05), Vector3(0, 0.55, 1.45), mat("#d8c890", 0.4, 0.6))
	label(vx, "VOXIE BEAR\nco zbylo po požáru", Vector3(0, 0.55, 1.48), "#1a1410", 16)
	var sp3 = SpotLight3D.new()
	sp3.light_color = Color("#ffd8b0")
	sp3.light_energy = 5
	sp3.spot_range = 6
	sp3.spot_angle = 28
	vx.add_child(sp3)
	sp3.look_at_from_position(Vector3(0, 3.0, -4.2), Vector3(0, 1.0, -6.0))
	# západní koridor (k recepci a herně)
	room("WC", "Západní koridor", -6, -8, -3, 10, wall_d, "#201818", "#181212", {"e": [[3.0, 4.6], [-3.6, -2.0], [7.0, 8.6]], "w": [[-3.0, -1.0], [5.0, 7.0]]})
	# recepce / vchod s pokladnou
	var lob = room("LOBBY", "Vchod a pokladna", -14, 2, -6, 10, "#2a2a3a", "#1c1c28", "#24243a", {"e": [[5.0, 7.0]], "s": [[-11.0, -9.0]], "n": [[-11.0, -9.0]]})
	var booth = Node3D.new()
	booth.position = Vector3(-12.2, 0, 6.0)
	lob.add_child(booth)
	box(booth, Vector3(1.6, 1.1, 1.2), Vector3(0, 0.55, 0), mat("#5a2a6a"))
	box(booth, Vector3(1.7, 0.08, 1.3), Vector3(0, 1.12, 0), mat("#3a1a4a"))
	box(booth, Vector3(1.6, 0.6, 0.06), Vector3(0, 2.1, 0), mat("#2a0f3a"))
	label(booth, "VSTUPENKY", Vector3(0, 2.1, 0.05), "#ffe46b", 34)
	label(lob, "FRIGHTS & HIDES", Vector3(-10.0, 2.6, 9.8), "#ff4040", 64, PI)
	omni(lob, Vector3(-10, 2.8, 6), "#c0c8ff", 0.9, 9)
	box(lob, Vector3(1.4, 0.35, 0.1), Vector3(-10, 2.6, 2.12), mat("#0a3a12"))
	label(lob, "VÝCHOD", Vector3(-10, 2.6, 2.2), "#5dff8a", 28)
	# herna – exponát: ohořelé automaty z budovy 2
	var herna = room("ARC", "Expozice: herna", -14, -8, -6, 2, "#141c34", "#0c1020", "#1c2440", {"e": [[-3.0, -1.0]], "s": [[-11.0, -9.0]]})
	label(herna, "EXPOZICE: HERNA 1997", Vector3(-10, 2.7, -7.85), "#ffe46b", 40)
	omni(herna, Vector3(-10, 2.8, -3), "#8090ff", 0.8, 9)
	# pizzerie – exponát: stoly z budovy 2
	var piz = room("PIZ", "Expozice: pizzerie", 3, -8, 11, 0, "#3a1a10", "#2a0f0a", "#cfc6b4", {"w": [[-5.0, -3.0]]})
	label(piz, "EXPOZICE: PIZZERIE", Vector3(7, 2.7, -7.85), "#ffb030", 40)
	omni(piz, Vector3(7, 2.8, -4), "#ffb070", 0.9, 9)
	# Cocoina hlava ve vitríně
	var coc = room("COC", "Expozice: Cocoa", 3, 0, 11, 6, "#2a1a30", "#1a1020", "#2a1a30", {"w": [[2.0, 4.0]]})
	label(coc, "COCOA (1997)\n„Usměvavá králičí holka z reklam“", Vector3(7, 2.55, 0.15), "#ffc9a0", 28)
	var ped = Node3D.new()
	ped.name = "CocoaHeadExhibit"
	ped.position = Vector3(8.0, 0, 3.0)
	coc.add_child(ped)
	box(ped, Vector3(0.8, 1.0, 0.8), Vector3(0, 0.5, 0), mat("#1a1a1e", 0.4, 0.3))
	box(ped, Vector3(0.9, 0.06, 0.9), Vector3(0, 1.03, 0), mat("#c0a040", 0.3, 0.8))
	var head = load("res://models/cocoa_torn_head.glb").instantiate()
	head.scale = Vector3.ONE * (0.42 / 2.66)
	head.position = Vector3(0, 1.08, 0)
	head.rotation.y = -PI / 2 - 0.4
	ped.add_child(head)
	var gm = StandardMaterial3D.new()
	gm.albedo_color = Color(0.75, 0.85, 0.9, 0.14)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.03
	gm.metallic = 0.2
	box(ped, Vector3(0.82, 0.7, 0.82), Vector3(0, 1.41, 0), gm, "GlassCase")
	box(ped, Vector3(0.6, 0.12, 0.02), Vector3(0, 0.6, 0.41), mat("#d8c890", 0.4, 0.6))
	label(ped, "HLAVA COCOY · nalezena v bludišti", Vector3(0, 0.6, 0.43), "#1a1410", 14)
	var sp = SpotLight3D.new()
	sp.light_color = Color("#ffe8d0")
	sp.light_energy = 5
	sp.spot_range = 5
	sp.spot_angle = 20
	sp.shadow_enabled = true
	ped.add_child(sp)
	sp.look_at_from_position(Vector3(8.0, 3.0, 3.6), Vector3(8.0, 1.2, 3.0))
	omni(coc, Vector3(5, 2.8, 3), "#a070ff", 0.5, 6)
	# archiv: ohořelá kresba v rámu + fotky
	var arch = room("ARCH", "Archiv", -3, -14, 3, -8, "#2a2420", "#1a1612", "#2a2420", {"s": [[-1, 1]], "n": [[-0.8, 0.8]]})
	label(arch, "ARCHIV · CO ZBYLO Z VOXIE'S", Vector3(0, 2.75, -13.85), "#ffd28a", 34)
	var fr = Node3D.new()
	fr.name = "DrawingFrame"
	fr.position = Vector3(0, 1.6, -13.86)
	arch.add_child(fr)
	box(fr, Vector3(1.24, 0.92, 0.06), Vector3.ZERO, mat("#5a3a18", 0.6, 0.2))
	var pic = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(1.1, 1.1 * 626.0 / 952.0)
	pic.mesh = q
	var pm = StandardMaterial3D.new()
	pm.albedo_texture = load("res://models/kresba.png")
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	pic.material_override = pm
	pic.position = Vector3(0, 0, 0.04)
	fr.add_child(pic)
	label(arch, "Kresba z bludiště: „TÁTA“", Vector3(0, 1.0, -13.8), "#d8c8a0", 18)
	for i in 4:
		var x = [-2.0, -1.2, 1.2, 2.0][i]
		box(arch, Vector3(0.36, 0.46, 0.03), Vector3(x, 1.7 + (i % 2) * 0.2, -13.88), mat(["#d8d0c0", "#c8c0b0"][i % 2]))
		box(arch, Vector3(0.3, 0.32, 0.01), Vector3(x, 1.72 + (i % 2) * 0.2, -13.86), mat(["#4a2050", "#6a3a2a", "#2a3a5a", "#3a2a24"][i]))
	var sp2 = SpotLight3D.new()
	sp2.light_color = Color("#ffe0b8")
	sp2.light_energy = 4
	sp2.spot_range = 5
	sp2.spot_angle = 30
	arch.add_child(sp2)
	sp2.look_at_from_position(Vector3(0, 2.9, -12.2), Vector3(0, 1.6, -13.8))
	# zákulisí vzadu: místo pro Hollow Hare (zatím prázdné)
	var back = room("BACK", "Zákulisí", -3, -22, 3, -14, "#1a1614", "#121010", "#1a1614", {"s": [[-0.8, 0.8]], "e": [[-19.0, -18.0]]})
	box(back, Vector3(1.2, 0.02, 1.2), Vector3(0, 0.01, -20.0), mat("#2a0606"), "HareSpot")
	label(back, "?", Vector3(0, 2.4, -21.85), "#5dff8a", 120)
	for i in 6:
		box(back, Vector3(randf_range(0.5, 1.0), randf_range(0.4, 0.9), randf_range(0.5, 0.9)), Vector3(randf_range(-2.4, -1.2), 0.35, randf_range(-21.2, -15)), mat("#5a4430"))
	box(back, Vector3(2.4, 2.2, 0.1), Vector3(2.0, 1.1, -21.6), mat("#4a1030"))
	omni(back, Vector3(0, 2.6, -20), "#40ff80", 0.25, 5)
	info.spawns["hollow_hare"] = [0, 0, -20.0]
	# větrací šachty (zákulisí → východ → kancelář)
	var vent = Node3D.new()
	vent.name = "Vents"
	map.add_child(vent)
	var vm = mat("#3a3a40", 0.45, 0.7)
	var segs = [[Vector3(3.0, 0.5, -18.5), Vector3(12.5, 0.5, -18.5)], [Vector3(12.5, 0.5, -18.5), Vector3(12.5, 0.5, 7.6)], [Vector3(12.5, 0.5, 7.6), Vector3(3.0, 0.5, 7.6)]]
	for sgm in segs:
		var a: Vector3 = sgm[0]
		var b: Vector3 = sgm[1]
		var mid = (a + b) / 2
		var d = b - a
		var sz = Vector3(absf(d.x) + 1.0, 1.0, absf(d.z) + 1.0)
		box(vent, Vector3(sz.x, 0.06, sz.z), mid + Vector3(0, 0.5, 0), vm)
		box(vent, Vector3(sz.x, 0.06, sz.z), mid - Vector3(0, 0.5, 0), vm)
		if absf(d.x) > absf(d.z):
			box(vent, Vector3(sz.x, 1.0, 0.06), mid + Vector3(0, 0, 0.5), vm)
			box(vent, Vector3(sz.x, 1.0, 0.06), mid - Vector3(0, 0, 0.5), vm)
		else:
			box(vent, Vector3(0.06, 1.0, sz.z), mid + Vector3(0.5, 0, 0), vm)
			box(vent, Vector3(0.06, 1.0, sz.z), mid - Vector3(0.5, 0, 0), vm)
		info.vents.append([[a.x, a.y, a.z], [b.x, b.y, b.z]])
	# kamery pro budoucí hru
	cam_point("01", "Vchod a pokladna", Vector3(-6.5, 2.9, 9.5), Vector3(-11, 0.8, 4))
	cam_point("02", "Expozice: herna", Vector3(-6.5, 2.9, 1.5), Vector3(-11, 0.8, -5))
	cam_point("03", "Západní koridor", Vector3(-4.5, 2.9, -7.5), Vector3(-4.5, 0.8, 6))
	cam_point("04", "Hlavní chodba", Vector3(2.5, 2.9, -7.5), Vector3(-1, 0.8, 4))
	cam_point("05", "Expozice: pizzerie", Vector3(10.5, 2.9, -0.5), Vector3(5, 0.8, -6))
	cam_point("06", "Expozice: Cocoa", Vector3(10.5, 2.9, 5.5), Vector3(7.5, 1.0, 2.5))
	cam_point("07", "Archiv", Vector3(2.5, 2.9, -8.5), Vector3(-1, 1.2, -13.5))
	cam_point("08", "Zákulisí", Vector3(2.5, 2.9, -14.5), Vector3(0, 0.6, -20.5))
	cam_point("09", "Větrací šachta", Vector3(12.5, 0.8, -2.0), Vector3(12.5, 0.4, 6.0))

func place_assets() -> void:
	var ex = extract_from_building()
	# automaty → herna (max 6)
	var i = 0
	for e in ex.cabinets:
		if i >= 6:
			break
		var a: AABB = e[1]
		var src = Vector3(a.get_center().x, a.position.y, a.get_center().z)
		var dst = Vector3(-13.0 + (i % 3) * 1.4 if i < 3 else -8.0, 0.0, -6.8 if i < 3 else -6.5 + (i - 3) * 2.2)
		var h = place_copy([e[0]], src, dst, 0.0 if i < 3 else -PI / 2, map.get_node("Room_ARC"))
		h.name = "Cabinet_" + str(i)
		i += 1
	# stoly → pizzerie (max 4)
	var j = 0
	for e in ex.tables:
		if j >= 4:
			break
		var tc: Vector3 = e[0]
		var src = Vector3(tc.x, 0, tc.z)
		var dst = Vector3(5.2 + (j % 2) * 3.4, 0, -5.6 + int(j / 2) * 3.2)
		var h = place_copy(e[1], src, dst, randf_range(-0.2, 0.2), map.get_node("Room_PIZ"))
		h.name = "Table_" + str(j)
		j += 1
	info["assets"] = {"cabinets": i, "tables": j}
	ex.building.queue_free()

func _init() -> void:
	seed(2041)
	root3 = Node3D.new()
	get_root().add_child(root3)
	build()
	await process_frame
	place_assets()
	await process_frame
	var doc = GLTFDocument.new()
	var st = GLTFState.new()
	doc.append_from_scene(map, st)
	print("FHMAP ", doc.write_to_filesystem(st, "res://models/frights_hides_map.glb"), " ", info.assets)
	var f = FileAccess.open("res://data/frights_hides_map.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "\t"))
	f.close()
	# náhledy
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#050304")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#605870")
	env.ambient_light_energy = 0.55
	env.glow_enabled = true
	var we = WorldEnvironment.new()
	we.environment = env
	root3.add_child(we)
	var cam = Camera3D.new()
	cam.far = 120
	root3.add_child(cam)
	cam.current = true
	var shots = [["top", Vector3(-1.5, 46, -6), Vector3(-1.5, 0, -6.01)], ["voxie", Vector3(1.2, 1.7, -2.5), Vector3(0, 1.1, -6)], ["cocoa", Vector3(5.2, 1.6, 4.6), Vector3(8, 1.2, 3)], ["archiv", Vector3(0, 1.6, -9.0), Vector3(0, 1.5, -14)], ["herna", Vector3(-7.0, 1.7, 1.2), Vector3(-12, 0.8, -5)], ["pizzerie", Vector3(10, 1.8, -0.6), Vector3(5, 0.6, -6)], ["lobby", Vector3(-7, 1.7, 3), Vector3(-13, 1.0, 8)], ["back", Vector3(0, 1.7, -14.6), Vector3(0, 0.6, -21)]]
	for s in shots:
		if s[0] == "top":
			# ze shora bez stropů
			for r in map.get_children():
				for c in r.get_children():
					if c is MeshInstance3D and c.position.y > H - 0.1 and (c.mesh as BoxMesh).size.y < 0.2:
						c.visible = false
			env.ambient_light_energy = 2.2
		else:
			for r in map.get_children():
				for c in r.get_children():
					if c is MeshInstance3D:
						c.visible = true
			env.ambient_light_energy = 0.55
		cam.fov = 50 if s[0] == "top" else 70
		cam.look_at_from_position(s[1], s[2])
		for k in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("user://fh_" + s[0] + ".png")
	quit()
