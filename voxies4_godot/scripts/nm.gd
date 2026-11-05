extends RefCounted
## Nightmare Voxie a Nightmare Hollow Bunny (stejné jako tools/nightmares.gd v NaV3), za běhu kvůli kloubům.
const H := preload("res://scripts/hollow.gd")

static func m(c: String, rough := 0.9, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var x = StandardMaterial3D.new()
	x.albedo_color = Color(c)
	x.roughness = rough
	x.metallic = metal
	if emit > 0:
		x.emission_enabled = true
		x.emission = Color(c)
		x.emission_energy_multiplier = emit
	return x
static func box(p: Node3D, sz: Vector3, pos: Vector3, mat: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	p.add_child(mi)
	return mi

## společné „noční můrové“ úpravy: zubaté čelisti, drápy, trhliny, ostny
static func nightmarify(g: Node3D, fur: String, fur_d: String, eye: String, bear: bool) -> void:
	var dark = m("#050304", 1.0)
	var tooth = m("#e8e0c8", 0.5)
	var gum = m("#4a0a10", 0.7)
	var claw = m("#d8d0b8", 0.4, 0.2)
	var metal = m("#3a3a40", 0.4, 0.8)
	var rip = m("#140a08", 1.0)
	# přebarvit
	for mi in g.find_children("*", "MeshInstance3D", true, false):
		var mm: StandardMaterial3D = mi.material_override
		var nm = mm.duplicate()
		var c = mm.albedo_color
		if c.v > 0.85 and c.s < 0.2:
			nm.albedo_color = Color("#a89a80")
		elif mm.emission_enabled:
			pass
		else:
			nm.albedo_color = c.lerp(Color(fur), 0.75).darkened(0.1)
		mi.material_override = nm
	var head: Node3D = g.get_node("head")
	var chest: Node3D = g.get_node("chest")
	g.scale = Vector3.ONE * 1.18
	head.scale = Vector3(1.12, 1.08, 1.12)
	head.rotation = Vector3(-0.15, 0.1, 0.0)
	chest.rotation.x = 0.18
	# ohromná zubatá tlama: horní řada a sklopená čelist se dvěma řadami zubů
	box(head, Vector3(0.6, 0.2, 0.14), Vector3(0, 0.1, 0.32), gum)
	for i in 9:
		box(head, Vector3(0.045, 0.1 + (i % 2) * 0.05, 0.04), Vector3(-0.24 + i * 0.06, 0.02, 0.4), tooth, Vector3(0, 0, randf_range(-0.2, 0.2)))
	var jaw = Node3D.new()
	jaw.name = "jaw"
	jaw.position = Vector3(0, 0.0, 0.18)
	jaw.rotation.x = 0.55
	head.add_child(jaw)
	box(jaw, Vector3(0.58, 0.1, 0.34), Vector3(0, -0.06, 0.1), m(fur_d))
	box(jaw, Vector3(0.5, 0.04, 0.28), Vector3(0, -0.005, 0.1), gum)
	for i in 8:
		box(jaw, Vector3(0.045, 0.11, 0.04), Vector3(-0.21 + i * 0.06, 0.05, 0.25), tooth, Vector3(0, 0, randf_range(-0.25, 0.25)))
	# oči: černé důlky, svítivé zorničky
	for s in [-1, 1]:
		box(head, Vector3(0.17, 0.14, 0.06), Vector3(0.15 * s, 0.34, 0.31), dark)
		box(head, Vector3(0.05, 0.05, 0.03), Vector3(0.15 * s, 0.34, 0.345), m(eye, 0.3, 0.0, 4.0))
	# trhliny v látce a vyčnívající dráty
	for i in 14:
		var p = Vector3(randf_range(-0.32, 0.32), randf_range(0.05, 0.75), 0.26)
		box(chest, Vector3(randf_range(0.05, 0.14), randf_range(0.04, 0.12), 0.02), p, rip)
	for i in 6:
		box(chest, Vector3(0.012, randf_range(0.12, 0.3), 0.012), Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.3), 0.27), m(["#a01010", "#1a3a90", "#c0a020", "#111111"][i % 4], 0.4), Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)))
	# druhá tlama na břiše (noční můra)
	box(chest, Vector3(0.3, 0.14, 0.03), Vector3(0, 0.22, 0.27), gum)
	for i in 6:
		box(chest, Vector3(0.035, 0.06, 0.03), Vector3(-0.12 + i * 0.048, 0.28, 0.285), tooth)
		box(chest, Vector3(0.035, 0.06, 0.03), Vector3(-0.12 + i * 0.048, 0.16, 0.285), tooth)
	# ostny na zádech
	for i in 5:
		box(chest, Vector3(0.06, 0.12, 0.06), Vector3(0, 0.15 + i * 0.13, -0.28), metal, Vector3(-0.6, 0, 0))
	# dlouhé drápy
	for nm in ["arm_L", "arm_R"]:
		var arm: Node3D = chest.get_node(nm)
		arm.rotation = Vector3(-0.35, 0, (0.25 if nm == "arm_L" else -0.25) * -1)
		var fore: Node3D = arm.get_node("forearm")
		fore.rotation.x = -0.6
		for f in 4:
			box(fore, Vector3(0.025, 0.2, 0.025), Vector3(-0.07 + f * 0.047, -0.52, 0.05), claw, Vector3(0.35, 0, 0))
	for nm in ["leg_L", "leg_R"]:
		var shin: Node3D = g.get_node(nm).get_node("shin")
		for f in 3:
			box(shin, Vector3(0.03, 0.04, 0.12), Vector3(-0.08 + f * 0.08, -0.36, 0.34), claw)
	if bear:
		# medvědí uši místo králičích, roztrhané
		for e in ["ear_L", "ear_R"]:
			head.get_node(e).visible = false
		for s in [-1, 1]:
			box(head, Vector3(0.2, 0.18, 0.12), Vector3(0.25 * s, 0.62, -0.02), m(fur))
			box(head, Vector3(0.1, 0.09, 0.02), Vector3(0.25 * s, 0.62, 0.05), m(fur_d))
			box(head, Vector3(0.05, 0.06, 0.03), Vector3(0.3 * s, 0.7, 0.04), rip)
		# klobouček a motýlek (zničené)
		box(head, Vector3(0.24, 0.05, 0.24), Vector3(0, 0.6, 0), m("#120c18"))
		box(head, Vector3(0.16, 0.16, 0.16), Vector3(0, 0.7, 0), m("#120c18"), Vector3(0, 0, 0.15))
	else:
		# roztřepené dlouhé uši, jedno zlomené
		head.get_node("ear_R").get_node("tip").rotation.x = 1.6
		head.get_node("ear_L").rotation.z = 0.35
		for i in 4:
			box(head.get_node("ear_L"), Vector3(0.04, 0.06, 0.11), Vector3(randf_range(-0.06, 0.06), randf_range(0.05, 0.45), 0), rip)

static func make_voxie() -> Node3D:
	seed(404)
	var g = H.make(false)
	g.name = "NightmareVoxie"
	nightmarify(g, "#5a3418", "#3a2010", "#ff2020", true)
	return g
static func make_bunny() -> Node3D:
	seed(505)
	var g = H.make(false)
	g.name = "NightmareHollowBunny"
	nightmarify(g, "#b8a030", "#6a5a18", "#60ff70", false)
	return g

