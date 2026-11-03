extends SceneTree
## Hollow Hare – zničený Hollow Bunny, uvnitř uvězněný D. (selhání springlocků).
## Jen nástroj pro budoucí Remaster 3+4: vytvoří GLB a náhledy. Hru nemění.
const H := preload("res://scripts/hollow.gd")

func m(c: String, rough := 0.95, metal := 0.0) -> StandardMaterial3D:
	var x = StandardMaterial3D.new()
	x.albedo_color = Color(c)
	x.roughness = rough
	x.metallic = metal
	return x

func make_hare() -> Node3D:
	seed(1987)
	var g = H.make(false)
	g.name = "HollowHare"
	var fur = m("#8f7d34")
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
		nm.albedo_color = c.lerp(Color("#4a4418"), 0.62).darkened(0.18)
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
	# hlava: utržené ucho, propadlý čumák, lidské oči uvnitř důlků
	var earR: Node3D = head.get_node("ear_R")
	earR.get_node("tip").visible = false
	earR.rotation.z = 0.55
	var earL: Node3D = head.get_node("ear_L")
	earL.rotation = Vector3(-0.35, 0, 0.25)
	head.rotation = Vector3(0.28, 0.22, 0.2)
	for s in [-1, 1]:
		var eye = MeshInstance3D.new()
		var sp = SphereMesh.new()
		sp.radius = 0.04
		sp.height = 0.08
		eye.mesh = sp
		eye.material_override = m("#d8d0c0", 0.3)
		eye.position = Vector3(0.15 * s, 0.32, 0.29)
		head.add_child(eye)
		var iris = MeshInstance3D.new()
		var sp2 = SphereMesh.new()
		sp2.radius = 0.017
		sp2.height = 0.034
		iris.mesh = sp2
		var ir = m("#4a6a80", 0.2)
		ir.emission_enabled = true
		ir.emission = Color("#9fd0ff")
		ir.emission_energy_multiplier = 0.25
		iris.material_override = ir
		iris.position = Vector3(0.15 * s + 0.005 * s, 0.32, 0.325)
		head.add_child(iris)
	# díra ve tváři: pod látkou šedá kůže D.
	var face = MeshInstance3D.new()
	var bf = BoxMesh.new()
	bf.size = Vector3(0.18, 0.16, 0.03)
	face.mesh = bf
	face.material_override = rot
	face.position = Vector3(-0.2, 0.12, 0.3)
	head.add_child(face)
	var fs = MeshInstance3D.new()
	var bfs = BoxMesh.new()
	bfs.size = Vector3(0.12, 0.1, 0.035)
	fs.mesh = bfs
	fs.material_override = skin
	fs.position = Vector3(-0.2, 0.12, 0.302)
	head.add_child(fs)
	# skvrny, spáleniny, roztrhané švy
	for i in 26:
		var st = MeshInstance3D.new()
		var b3 = BoxMesh.new()
		b3.size = Vector3(randf_range(0.04, 0.12), randf_range(0.04, 0.12), 0.012)
		st.mesh = b3
		st.material_override = rot if i % 3 else fur_d
		var y = randf_range(0.15, 2.05)
		st.position = Vector3(randf_range(-0.33, 0.33), y, 0.26 if y < 1.62 else 0.31)
		g.add_child(st)
	# shrbený postoj
	chest.rotation.x = 0.16
	chest.rotation.z = -0.06
	return g

func _init() -> void:
	var root3 = Node3D.new()
	get_root().add_child(root3)
	var hare = make_hare()
	root3.add_child(hare)
	var doc = GLTFDocument.new()
	var st = GLTFState.new()
	doc.append_from_scene(hare, st)
	print("HARE ", doc.write_to_filesystem(st, "res://models/hollow_hare_D.glb"))
	# náhledy
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0a0606")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#404050")
	env.ambient_light_energy = 0.6
	var we = WorldEnvironment.new()
	we.environment = env
	root3.add_child(we)
	var key = SpotLight3D.new()
	key.light_energy = 6
	key.spot_range = 12
	key.spot_angle = 35
	key.shadow_enabled = true
	root3.add_child(key)
	key.look_at_from_position(Vector3(1.6, 3.6, 3.0), Vector3(0, 1.1, 0))
	var rim = OmniLight3D.new()
	rim.light_color = Color("#9fd0ff")
	rim.light_energy = 1.5
	rim.position = Vector3(-1.5, 2.2, -1.5)
	root3.add_child(rim)
	var floor_ = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(8, 8)
	floor_.mesh = pm
	floor_.material_override = m("#1a1416")
	root3.add_child(floor_)
	var cam = Camera3D.new()
	cam.fov = 40
	root3.add_child(cam)
	cam.current = true
	var views = [[0.0, 5.4, 1.3], [0.9, 5.4, 1.3], [PI, 5.4, 1.3], [-0.5, 1.6, 1.75]]
	for i in views.size():
		var v = views[i]
		var target = Vector3(0, 1.15, 0) if i < 3 else Vector3(0, 1.75, 0)
		cam.look_at_from_position(target + Vector3(sin(v[0]) * v[1], v[2] - target.y + 1.1, cos(v[0]) * v[1]), target)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		get_root().get_texture().get_image().save_png("user://hare_" + str(i) + ".png")
	quit()
