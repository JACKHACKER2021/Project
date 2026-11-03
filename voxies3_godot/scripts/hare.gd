extends RefCounted
## Hollow Hare – zničený Hollow Bunny s uvězněným D. (stejný model jako hollow_hare_D.glb), za běhu kvůli kloubům.
const H := preload("res://scripts/hollow.gd")

static func m(c: String, rough := 0.95, metal := 0.0) -> StandardMaterial3D:
	var x = StandardMaterial3D.new()
	x.albedo_color = Color(c)
	x.roughness = rough
	x.metallic = metal
	return x

static func box(p: Node3D, sz: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	p.add_child(mi)
	return mi
static func cyl(p: Node3D, r: float, h: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var c = CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	mi.mesh = c
	mi.position = pos
	mi.material_override = mat
	p.add_child(mi)
	return mi

static func make_hare() -> Node3D:
	seed(1987)
	var g = H.make(false)
	g.name = "HollowHare"
	var fur = m("#6a7030")
	var fur_d = m("#6a5a22")
	var rot = m("#2a2214")
	var shirt = m("#77777d")          # šedé tričko D.
	var skin = m("#7a6a58", 1.0)      # vysušená kůže
	var metal = m("#6a6a70", 0.4, 0.85)
	var rust = m("#5a3a20", 0.8, 0.4)
	# přebarvit látku: vybledlá, špinavá žlutá
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		var mm: StandardMaterial3D = mi.material_override
		var c = mm.albedo_color
		var nm = mm.duplicate()
		nm.albedo_color = c.lerp(Color("#4a5a20"), 0.7).darkened(0.15)
		mi.material_override = nm
	var chest: Node3D = g.get_node("chest")
	var head: Node3D = g.get_node("head")
	# vyrvané díry v látce: pod nimi šedé tričko D. a kovová kostra
	for h in [[Vector3(-0.2, 0.5, 0.26), Vector3(0.2, 0.22, 0.03)], [Vector3(0.18, 0.2, 0.26), Vector3(0.18, 0.2, 0.03)], [Vector3(0.38, 0.4, 0.0), Vector3(0.03, 0.24, 0.26)]]:
		var hole = MeshInstance3D.new()
		var b = BoxMesh.new()
		b.size = h[1]
		hole.mesh = b
		hole.material_override = rot
		hole.position = h[0]
		chest.add_child(hole)
		var sh = MeshInstance3D.new()
		var b2 = BoxMesh.new()
		b2.size = h[1] * Vector3(0.7, 0.7, 1.15)
		sh.mesh = b2
		sh.material_override = shirt
		sh.position = h[0] + Vector3(0, 0, 0.004)
		chest.add_child(sh)
	# kostra a springlocky trčí z boku a ramen
	for i in 5:
		var bar = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.012
		cy.bottom_radius = 0.012
		cy.height = randf_range(0.18, 0.34)
		bar.mesh = cy
		bar.material_override = metal if i % 2 else rust
		bar.position = Vector3(randf_range(-0.34, 0.34), randf_range(0.1, 0.7), randf_range(0.2, 0.28))
		bar.rotation = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1.4, 1.4))
		chest.add_child(bar)
	for i in 4:
		var spring = MeshInstance3D.new()
		var t = TorusMesh.new()
		t.inner_radius = 0.018
		t.outer_radius = 0.03
		spring.mesh = t
		spring.material_override = metal
		spring.position = Vector3([-0.37, 0.37][i % 2], 0.62 - (i / 2) * 0.3, 0.1)
		spring.rotation.z = PI / 2
		chest.add_child(spring)
	# kabely z hrudi
	for i in 6:
		var w = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = 0.008
		cy.bottom_radius = 0.008
		cy.height = randf_range(0.2, 0.45)
		w.mesh = cy
		w.material_override = m(["#a01010", "#1a3a90", "#c0a020", "#111111"][i % 4], 0.4)
		w.position = Vector3(randf_range(-0.25, 0.1), randf_range(0.0, 0.35), 0.29)
		w.rotation = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.6, 0.6))
		chest.add_child(w)
	# levá ruka: látka utržená, vidět šedý rukáv a vysušená ruka D.
	var arm: Node3D = chest.get_node("arm_L")
	arm.rotation = Vector3(0.35, 0, -0.32)
	var fore: Node3D = arm.get_node("forearm")
	for c in fore.get_children():
		c.visible = false
	var sl = MeshInstance3D.new()
	var bs = BoxMesh.new()
	bs.size = Vector3(0.13, 0.3, 0.14)
	sl.mesh = bs
	sl.material_override = shirt
	sl.position = Vector3(0, -0.15, 0)
	fore.add_child(sl)
	var hd = MeshInstance3D.new()
	var bh = BoxMesh.new()
	bh.size = Vector3(0.1, 0.16, 0.08)
	hd.mesh = bh
	hd.material_override = skin
	hd.position = Vector3(0, -0.36, 0.02)
	fore.add_child(hd)
	var blood = m("#4a0606", 0.6)
	var blood2 = m("#2a0303", 0.5)
	var bone = m("#b8b0a0", 0.7)
	var glow = m("#20ff60", 0.2)
	glow.emission_enabled = true
	glow.emission = Color("#30ff70")
	glow.emission_energy_multiplier = 2.5
	# hlava nakloněná, rozpadlá
	head.rotation = Vector3(0.28, 0.22, 0.2)
	# pravé ucho chybí – z hlavy trčí kabely a kovový pahýl
	head.get_node("ear_R").visible = false
	box(head, Vector3(0.08, 0.06, 0.08), Vector3(0.18, 0.58, -0.04), metal)
	for i in 5:
		var w = cyl(head, 0.01, randf_range(0.2, 0.42), Vector3(0.18 + randf_range(-0.04, 0.04), 0.66, -0.04), m(["#a01010", "#1a3a90", "#c0a020", "#111111", "#a01010"][i], 0.4))
		w.rotation = Vector3(randf_range(-0.7, 0.7), 0, randf_range(-1.0, 0.2))
		w.position.y += 0.1
	var earL: Node3D = head.get_node("ear_L")
	earL.rotation = Vector3(-0.35, 0, 0.45)
	# původní čumák a zuby pryč: tlama ve dvou částech
	for c in head.get_children():
		if c is MeshInstance3D and c.position.z > 0.32 and c.position.y < 0.25:
			c.visible = false
	box(head, Vector3(0.4, 0.1, 0.16), Vector3(0, 0.17, 0.33), m("#8a7a50"))          # horní čelist
	box(head, Vector3(0.1, 0.06, 0.04), Vector3(0, 0.21, 0.42), m("#6a4a40"))          # nos
	for i in 6:
		box(head, Vector3(0.04, 0.05, 0.03), Vector3(-0.15 + i * 0.06, 0.1, 0.39), bone)
	var jaw = Node3D.new()
	jaw.name = "jaw"
	jaw.position = Vector3(0, 0.08, 0.26)
	jaw.rotation.x = 0.6
	head.add_child(jaw)
	box(jaw, Vector3(0.38, 0.08, 0.2), Vector3(0, -0.04, 0.09), m("#7a6a40"))
	for i in 5:
		box(jaw, Vector3(0.04, 0.05, 0.03), Vector3(-0.12 + i * 0.06, 0.02, 0.17), bone)
	box(jaw, Vector3(0.2, 0.02, 0.1), Vector3(0.05, -0.085, 0.1), blood)
	# uvnitř tlamy: dutina a zbytek hlavy D. (kůže, zuby, oko)
	box(head, Vector3(0.34, 0.2, 0.06), Vector3(0, 0.02, 0.27), m("#0a0505"))
	box(head, Vector3(0.24, 0.14, 0.04), Vector3(0, 0.03, 0.3), skin)
	box(head, Vector3(0.16, 0.03, 0.02), Vector3(0, -0.02, 0.322), bone)
	box(head, Vector3(0.04, 0.04, 0.02), Vector3(-0.06, 0.07, 0.322), m("#1a1010"))
	box(head, Vector3(0.05, 0.03, 0.02), Vector3(0.05, 0.075, 0.322), blood2)
	# oči: zelené, svítí z hlubokých důlků
	for sx in [-1, 1]:
		box(head, Vector3(0.15, 0.15, 0.04), Vector3(0.15 * sx, 0.33, 0.3), m("#050303"))
		box(head, Vector3(0.05, 0.05, 0.03), Vector3(0.15 * sx, 0.33, 0.32), glow)
		var eg = OmniLight3D.new()
		eg.light_color = Color("#30ff70")
		eg.light_energy = 0.12
		eg.omni_range = 0.5
		eg.position = Vector3(0.15 * sx, 0.33, 0.4)
		head.add_child(eg)
	# nohy: z části holý endoskelet
	for nm in ["leg_L", "leg_R"]:
		var leg: Node3D = g.get_node(nm)
		var shin: Node3D = leg.get_node("shin")
		var lower = nm == "leg_L"
		var tgt: Node3D = shin if lower else leg
		var fur_box: MeshInstance3D = tgt.get_child(0)
		fur_box.visible = false
		var y0 = 0.0
		var hh = 0.3 if lower else 0.44
		for dx in [-0.05, 0.05]:
			cyl(tgt, 0.022, hh, Vector3(dx, -hh / 2, 0), metal if dx < 0 else rust)
		for k in 3:
			var sp = MeshInstance3D.new()
			var t = TorusMesh.new()
			t.inner_radius = 0.02
			t.outer_radius = 0.045
			sp.mesh = t
			sp.material_override = metal
			sp.position = Vector3(0, -0.06 - k * hh / 3.2, 0)
			tgt.add_child(sp)
		var kn = MeshInstance3D.new()
		var ks = SphereMesh.new()
		ks.radius = 0.06
		ks.height = 0.12
		kn.mesh = ks
		kn.material_override = rust
		kn.position = Vector3(0, -hh, 0)
		tgt.add_child(kn)
		# cáry látky visí kolem kostry
		box(tgt, Vector3(0.24, 0.1, 0.26), Vector3(0, -0.04, 0), fur)
		box(tgt, Vector3(0.1, 0.12, 0.03), Vector3(0.06, -hh * 0.6, 0.12), blood2)
	# krev: stékající pruhy a skvrny
	for i in 22:
		var y = randf_range(0.2, 1.95)
		var st = box(g, Vector3(randf_range(0.03, 0.09), randf_range(0.06, 0.26), 0.012), Vector3(randf_range(-0.32, 0.32), y, 0.262 if y < 1.62 else 0.312), blood if i % 2 else blood2)
		st.rotation.z = randf_range(-0.15, 0.15)
	for c in [Vector3(0.12, 0.55, 0.27), Vector3(-0.2, 0.3, 0.27), Vector3(0.0, 0.05, 0.27)]:
		box(chest, Vector3(0.12, 0.2, 0.014), c, blood)
	# další díry v látce (rozpad)
	for i in 8:
		var y = randf_range(0.4, 1.5)
		box(g, Vector3(randf_range(0.06, 0.12), randf_range(0.06, 0.12), 0.014), Vector3(randf_range(-0.3, 0.3), y, -0.262), m("#0a0505"))
	# shrbený postoj
	chest.rotation.x = 0.16
	chest.rotation.z = -0.06
	return g

