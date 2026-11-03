extends RefCounted
## Hollow Bunny – žlutý springlock animatronik (odstaven 1980 kvůli nestabilním zámkům), z kostiček jako Voxie Bear.
## make(false) = unwithered remodel, make(true) = ohořelý po požáru.

static func _m(c: Color, burnt := false, rough := 0.9) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = c.darkened(0.7).lerp(Color("#1a120e"), 0.25) if burnt else c
	m.roughness = rough
	return m

static func _b(p: Node3D, sz: Vector3, pos: Vector3, m: Material, nm := "") -> MeshInstance3D:
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

static func _j(p: Node3D, pos: Vector3, nm: String) -> Node3D:
	var n = Node3D.new()
	n.name = nm
	n.position = pos
	p.add_child(n)
	return n

static func make(burnt := false) -> Node3D:
	var g = Node3D.new()
	g.name = "HollowBunny"
	var fur = _m(Color("#e8c64a"), burnt)        # žlutá látka
	var fur_d = _m(Color("#c8a432"), burnt)      # stín/boky (jako tmavší strana Voxieho)
	var fur_l = _m(Color("#f6dc72"), burnt)      # světlá horní hrana
	var cream = _m(Color("#f2e6d0"), burnt)
	var pink = _m(Color("#f0a0b8"), burnt)
	var dark = _m(Color("#0a0608"), false, 1.0)
	var red = _m(Color("#c0202a"), burnt, 0.5)
	var white = _m(Color("#fffaf0"), burnt, 0.5)
	var zip = _m(Color("#9a9aa2"), burnt, 0.3)
	zip.metallic = 0.8
	# nohy (kostičky jako Voxie) + velká chodidla
	for s in [-1, 1]:
		var leg = _j(g, Vector3(0.17 * s, 0.82, 0), "leg_" + ("L" if s < 0 else "R"))
		_b(leg, Vector3(0.24, 0.44, 0.28), Vector3(0, -0.22, 0), fur)
		var leg2 = _j(leg, Vector3(0, -0.44, 0), "shin")
		_b(leg2, Vector3(0.22, 0.3, 0.26), Vector3(0, -0.15, 0), fur_d)
		_b(leg2, Vector3(0.3, 0.12, 0.46), Vector3(0, -0.32, 0.08), cream)
	# trup
	var chest = _j(g, Vector3(0, 0.84, 0), "chest")
	_b(chest, Vector3(0.74, 0.78, 0.5), Vector3(0, 0.39, 0), fur)
	_b(chest, Vector3(0.74, 0.08, 0.5), Vector3(0, 0.74, 0), fur_l)
	_b(chest, Vector3(0.06, 0.78, 0.5), Vector3(0.34, 0.39, 0), fur_d)
	_b(chest, Vector3(0.44, 0.5, 0.04), Vector3(0, 0.33, 0.26), cream)
	for y in [0.48, 0.3]:
		_b(chest, Vector3(0.06, 0.06, 0.03), Vector3(0, y, 0.29), dark)
	# motýlek (stejný jako Voxieho, jen rudý)
	_b(chest, Vector3(0.12, 0.1, 0.05), Vector3(-0.08, 0.7, 0.27), red)
	_b(chest, Vector3(0.12, 0.1, 0.05), Vector3(0.08, 0.7, 0.27), red)
	_b(chest, Vector3(0.05, 0.06, 0.06), Vector3(0, 0.7, 0.28), _m(Color("#801018"), burnt))
	# zip na zádech – je to kostým, do kterého se leze
	_b(chest, Vector3(0.05, 0.66, 0.03), Vector3(0, 0.38, -0.26), zip)
	_b(chest, Vector3(0.07, 0.08, 0.04), Vector3(0, 0.68, -0.27), zip)
	_b(chest, Vector3(0.16, 0.16, 0.12), Vector3(0, 0.08, -0.3), cream)    # ocásek
	# ruce visí bez síly (uvnitř není kostra)
	for s in [-1, 1]:
		var arm = _j(chest, Vector3(0.48 * s, 0.68, 0), "arm_" + ("L" if s < 0 else "R"))
		arm.rotation = Vector3(0.05, 0, 0.1 * s)
		_b(arm, Vector3(0.2, 0.38, 0.22), Vector3(0, -0.19, 0), fur)
		var arm2 = _j(arm, Vector3(0, -0.38, 0), "forearm")
		_b(arm2, Vector3(0.18, 0.32, 0.2), Vector3(0, -0.16, 0), fur_d)
		_b(arm2, Vector3(0.2, 0.14, 0.22), Vector3(0, -0.38, 0.01), cream)
	# hlava: kostka jako Voxie, místo medvědích uší vysoké králičí
	var head = _j(g, Vector3(0, 1.66, 0), "head")
	head.rotation = Vector3(0.1, 0, 0.05)
	_b(head, Vector3(0.66, 0.56, 0.6), Vector3(0, 0.28, 0), fur)
	_b(head, Vector3(0.66, 0.06, 0.6), Vector3(0, 0.53, 0), fur_l)
	_b(head, Vector3(0.06, 0.56, 0.6), Vector3(0.3, 0.28, 0), fur_d)
	# čumák + nos + zuby
	_b(head, Vector3(0.32, 0.18, 0.12), Vector3(0, 0.12, 0.33), cream)
	_b(head, Vector3(0.1, 0.07, 0.05), Vector3(0, 0.2, 0.4), pink)
	_b(head, Vector3(0.07, 0.09, 0.03), Vector3(-0.04, 0.0, 0.38), white)
	_b(head, Vector3(0.07, 0.09, 0.03), Vector3(0.04, 0.0, 0.38), white)
	# duté oči: černé čtvercové důlky s jedním bílým pixelem
	var pu = _m(Color.WHITE, false, 0.3)
	pu.emission_enabled = true
	pu.emission = Color.WHITE
	pu.emission_energy_multiplier = 0.8
	for s in [-1, 1]:
		_b(head, Vector3(0.15, 0.15, 0.04), Vector3(0.15 * s, 0.32, 0.3), dark)
		_b(head, Vector3(0.035, 0.035, 0.02), Vector3(0.15 * s + 0.02, 0.34, 0.325), pu)
		_b(head, Vector3(0.09, 0.05, 0.02), Vector3(0.23 * s, 0.16, 0.305), pink)
	# uši: kostičkové, pravé se v půlce láme dopředu
	for s in [-1, 1]:
		var ear = _j(head, Vector3(0.18 * s, 0.56, -0.04), "ear_" + ("L" if s < 0 else "R"))
		ear.rotation.z = -0.12 * s
		_b(ear, Vector3(0.16, 0.36, 0.1), Vector3(0, 0.18, 0), fur)
		_b(ear, Vector3(0.08, 0.3, 0.02), Vector3(0, 0.18, 0.055), pink)
		var tip = _j(ear, Vector3(0, 0.36, 0), "tip")
		if s > 0:
			tip.rotation.x = 1.0
		_b(tip, Vector3(0.16, 0.26, 0.1), Vector3(0, 0.13, 0), fur)
		_b(tip, Vector3(0.08, 0.2, 0.02), Vector3(0, 0.12, 0.055), pink)
	# pružinové zámky (springlocky) na kloubech a švech
	var lock = _m(Color("#7a7a82"), burnt, 0.35)
	lock.metallic = 0.85
	for y in [0.62, 0.42, 0.22]:
		for s in [-1, 1]:
			_b(chest, Vector3(0.05, 0.05, 0.05), Vector3(0.3 * s, y, 0.24), lock)
	for s in [-1, 1]:
		_b(g, Vector3(0.06, 0.06, 0.3), Vector3(0.17 * s, 0.6, 0.0), lock)
		_b(head, Vector3(0.05, 0.05, 0.3), Vector3(0.33 * s, 0.1, 0), lock)
	if burnt:
		for i in 16:
			_b(g, Vector3(randf_range(0.06, 0.14), randf_range(0.06, 0.14), 0.02), Vector3(randf_range(-0.3, 0.3), randf_range(0.6, 2.0), 0.27), dark)
	return g
