extends RefCounted
## Voxie z 1. dílu: kostičkový medvěd poskládaný z kvádrů (stejné rozměry jako ve webové verzi).

static func _mat(c: Color, tex: Texture2D = null) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	if tex:
		m.albedo_texture = tex
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return m

static func _box(w: float, h: float, d: float, m: Material, x: float, y: float, z: float, p: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, h, d)
	mi.mesh = bm
	mi.material_override = m
	mi.position = Vector3(x, y, z)
	p.add_child(mi)
	return mi

static func _node(n: String, p: Node3D, x: float, y: float, z: float) -> Node3D:
	var g := Node3D.new()
	g.name = n
	g.position = Vector3(x, y, z)
	p.add_child(g)
	return g

static func _disc(r: float, m: Material, x: float, y: float, z: float, p: Node3D) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.03
	mi.mesh = cm
	mi.material_override = m
	mi.position = Vector3(x, y, z)
	mi.rotation.x = PI / 2
	p.add_child(mi)

static func build() -> Node3D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color("#8a5a2b"))
	for i in 32:
		for j in [0, 1, 30, 31]:
			img.set_pixel(i, j, Color(0.36, 0.23, 0.11))
			img.set_pixel(j, i, Color(0.36, 0.23, 0.11))
	var fur := _mat(Color.WHITE, ImageTexture.create_from_image(img))
	var dark := _mat(Color("#5a3716"))
	var belly := _mat(Color("#d6a064"))
	var g := Node3D.new()
	g.name = "Voxie"
	var rig := {}
	var hips := _node("hips", g, 0, 0.8, 0)
	rig.hips = hips
	for s in [-1, 1]:
		var k := "R" if s < 0 else "L"
		var l1 := _node("leg" + k + "1", hips, s * 0.2, 0, 0)
		_box(0.26, 0.45, 0.3, fur, 0, -0.22, 0, l1)
		var l2 := _node("leg" + k + "2", l1, 0, -0.45, 0)
		_box(0.24, 0.32, 0.28, fur, 0, -0.16, 0, l2)
		_box(0.3, 0.1, 0.4, dark, 0, -0.3, 0.05, l2)
		rig["leg" + k + "1"] = l1
	var chest := _node("chest", hips, 0, 0.05, 0)
	rig.chest = chest
	_box(0.8, 0.72, 0.55, fur, 0, 0.36, 0, chest)
	_box(0.52, 0.5, 0.02, belly, 0, 0.32, 0.28, chest)
	var bow := _mat(Color("#ff2bd6"))
	_box(0.18, 0.14, 0.06, bow, -0.11, 0.68, 0.29, chest)
	_box(0.18, 0.14, 0.06, bow, 0.11, 0.68, 0.29, chest)
	for s in [-1, 1]:
		var k := "R" if s < 0 else "L"
		var a1 := _node("arm" + k + "1", chest, s * 0.52, 0.64, 0)
		_box(0.22, 0.4, 0.24, fur, 0, -0.2, 0, a1)
		var a2 := _node("arm" + k + "2", a1, 0, -0.4, 0)
		_box(0.2, 0.34, 0.22, fur, 0, -0.17, 0, a2)
		_box(0.22, 0.1, 0.24, dark, 0, -0.34, 0, a2)
		rig["arm" + k + "1"] = a1
	var head := _node("head", chest, 0, 0.74, 0)
	rig.head = head
	_box(0.82, 0.64, 0.7, fur, 0, 0.32, 0, head)
	_box(0.38, 0.2, 0.2, belly, 0, 0.17, 0.38, head)
	_box(0.14, 0.09, 0.06, _mat(Color("#2a1608")), 0, 0.24, 0.48, head)
	var white := _mat(Color("#f2f2ea"))
	var pupil := StandardMaterial3D.new()
	pupil.albedo_color = Color(0.07, 0.07, 0.07)
	pupil.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for s in [-1, 1]:
		var e := _node("ear", head, s * 0.3, 0.64, 0)
		_box(0.22, 0.2, 0.14, fur, 0, 0.1, 0, e)
		_box(0.12, 0.1, 0.02, _mat(Color("#e88aa0")), 0, 0.1, 0.08, e)
		_disc(0.095, white, s * 0.19, 0.44, 0.355, head)
		_disc(0.045, pupil, s * 0.19, 0.43, 0.372, head)
	# rudé oči, které se rozsvítí, když je software poškozený nebo útočí
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1, 0.05, 0.05)
	red.emission_enabled = true
	red.emission = Color(1, 0, 0)
	red.emission_energy_multiplier = 4.0
	red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var eyes := Node3D.new()
	eyes.name = "RedEyes"
	head.add_child(eyes)
	for s in [-1, 1]:
		_disc(0.03, red, s * 0.19, 0.43, 0.39, eyes)
	eyes.visible = false
	g.set_meta("rig", rig)
	return g
