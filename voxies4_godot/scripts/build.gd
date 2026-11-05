extends Node
## Po 7. noci: hrajeme za D. v dílně herny Voxie's (mapa z NaV1, rok 1997).
## Před panem Vojtěchem skládáme Cocou: kovová kostra, nohy, tělo, hlava. Pak Vojtěch odejde…
## a uvnitř Cocoy se probudí Ema.

var game
var root: Node3D
var cocoa: Node3D
var cocoa_parts := []      # MeshInstance3D seřazené odspodu
var skel: Node3D           # kovová kostra
var dman: Dictionary       # D.
var voj: Dictionary        # pan Vojtěch
var carry: MeshInstance3D  # díl v rukou D.
var bench := []            # díly na ponku
var lamp: OmniLight3D
var eye_l: OmniLight3D

const STAND := Vector3(19.0, 0, -7.0)
const BENCH_X := 11.6
const LINE_Z := -5.2
var dx := 13.0
var step := 0              # kolik dílů je nasazených (0..4)
var holding := false
var ph := 0                # 0 skládání, 1 Vojtěch odchází, 2 Ema se probouzí, 3 konec
var pt := 0.0
var hold := 0
var walkT := 0.0
var done := false
var from_extras := false
const NAMES := ["kovová kostra", "nohy", "tělo a ruce", "hlava"]

static func raw_tex(path: String) -> ImageTexture:
	var img = Image.new()
	if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return null
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
## čistý materiál z původní textury (bez VRAM komprese a vertex barev – jinak vypadá „zmuchlaně“)
static func clean_mat(n: Node3D, path: String) -> void:
	var t = raw_tex(path)
	if t == null:
		return
	var m = StandardMaterial3D.new()
	m.albedo_texture = t
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.9
	m.vertex_color_use_as_albedo = false
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = m

## dodaný model je v T-póze: ruce spustit podél těla
static func pose_cocoa(c: Node3D) -> void:
	for s in c.find_children("*", "Skeleton3D", true, false):
		for nm in [["Bone.009_r", 1.25], ["Bone.009_l", -1.25]]:
			var b = s.find_bone(nm[0])
			if b < 0:
				continue
			var gr = s.get_bone_global_rest(b)
			var pg = s.get_bone_global_rest(s.get_bone_parent(b))
			var ng = Basis(Vector3(0, 0, 1), nm[1]) * gr.basis
			var lb = pg.basis.inverse() * ng
			s.set_bone_pose_rotation(b, lb.get_rotation_quaternion())

func _mat(c: String, rough := 0.8, metal := 0.0, emit := 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = rough
	m.metallic = metal
	if emit > 0:
		m.emission_enabled = true
		m.emission = Color(c)
		m.emission_energy_multiplier = emit
	return m
func _box(p: Node3D, sz: Vector3, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.position = pos
	mi.rotation = rot
	mi.material_override = m
	p.add_child(mi)
	return mi

func start(extras := false) -> void:
	from_extras = extras
	done = false
	step = 0
	holding = false
	ph = 0
	pt = 0.0
	dx = 13.0
	if root:
		root.queue_free()
	root = Node3D.new()
	game.add_child(root)
	var w = load("res://models/remaster_world.glb").instantiate()
	root.add_child(w)
	for l in w.find_children("*", "Light3D", true, false):
		l.queue_free()
	lamp = OmniLight3D.new()
	lamp.light_color = Color("#ffd8a0")
	lamp.light_energy = 4.0
	lamp.omni_range = 9
	lamp.position = Vector3(16, 2.8, -6)
	root.add_child(lamp)
	var fill = OmniLight3D.new()
	fill.light_color = Color("#8090c0")
	fill.light_energy = 1.4
	fill.omni_range = 12
	fill.position = Vector3(13, 2.6, -3)
	root.add_child(fill)
	# stojan
	_box(root, Vector3(1.2, 0.12, 1.2), STAND + Vector3(0, 0.06, 0), _mat("#3a3a40", 0.5, 0.6))
	_box(root, Vector3(0.08, 2.2, 0.08), STAND + Vector3(0, 1.1, -0.45), _mat("#3a3a40", 0.5, 0.6))
	# ponk s díly
	_box(root, Vector3(1.0, 0.08, 2.4), Vector3(BENCH_X - 0.3, 0.85, -6.0), _mat("#6a4a2a"))
	for z in [-7.0, -5.0]:
		_box(root, Vector3(0.08, 0.85, 0.08), Vector3(BENCH_X - 0.3, 0.42, z), _mat("#4a3218"))
	bench = []
	var cols = ["#8a8a92", "#7a4a2a", "#7a4a2a", "#7a4a2a"]
	for i in 4:
		var b = _box(root, Vector3(0.4, 0.25 + i * 0.05, 0.4), Vector3(BENCH_X - 0.3, 1.0 + i * 0.02, -7.0 + i * 0.6), _mat(cols[i], 0.6, 0.8 if i == 0 else 0.0))
		bench.append(b)
	# Cocoa (dodaný model) s čistou texturou; zpočátku schovaná
	cocoa = load("res://models/cocoa_dw.glb").instantiate()
	root.add_child(cocoa)
	cocoa.scale = Vector3.ONE * 0.3
	cocoa.position = STAND + Vector3(0, 0.95, 0)
	cocoa.rotation.y = 0.0
	pose_cocoa(cocoa)
	cocoa_parts = cocoa.find_children("*", "MeshInstance3D", true, false)
	cocoa_parts.sort_custom(func(a, b): return a.get_aabb().get_center().y < b.get_aabb().get_center().y)
	for mi in cocoa_parts:
		mi.visible = false
	# kovová kostra (endoskeleton) – „metalness“
	skel = Node3D.new()
	skel.position = STAND
	skel.visible = false
	root.add_child(skel)
	var mt = _mat("#9a9aa4", 0.25, 0.95)
	_box(skel, Vector3(0.06, 0.8, 0.06), Vector3(0, 1.1, 0), mt)
	_box(skel, Vector3(0.5, 0.05, 0.05), Vector3(0, 1.45, 0), mt)
	_box(skel, Vector3(0.36, 0.05, 0.05), Vector3(0, 0.75, 0), mt)
	for s in [-1, 1]:
		_box(skel, Vector3(0.05, 0.7, 0.05), Vector3(0.14 * s, 0.4, 0), mt)
		_box(skel, Vector3(0.04, 0.5, 0.04), Vector3(0.25 * s, 1.2, 0), mt, Vector3(0, 0, 0.2 * s))
		_box(skel, Vector3(0.05, 0.05, 0.05), Vector3(0.07 * s, 1.72, 0.12), _mat("#40ff70", 0.3, 0.0, 3.0))
	_box(skel, Vector3(0.22, 0.2, 0.2), Vector3(0, 1.7, 0), mt)
	for i in 4:
		_box(skel, Vector3(0.02, 0.18, 0.02), Vector3(-0.06 + i * 0.04, 1.3, 0.04), _mat(["#a01010", "#1a3a90", "#c0a020", "#111111"][i], 0.4))
	eye_l = OmniLight3D.new()
	eye_l.light_color = Color("#60ff70")
	eye_l.light_energy = 0
	eye_l.omni_range = 2.5
	eye_l.position = STAND + Vector3(0, 1.6, 0.7)
	root.add_child(eye_l)
	# D. a pan Vojtěch
	var P = preload("res://scripts/people.gd")
	dman = P.person("D.", Color("#77777d"), Color("#2a2a30"), Color("#e0b890"), Color("#2a2420"), 1.82, false)
	root.add_child(dman.root)
	voj = P.person("Vojtěch", Color("#3a5aa0"), Color("#2a3050"), Color("#f0c8a0"), Color("#4a3020"), 1.8, false)
	root.add_child(voj.root)
	voj.root.position = Vector3(20.6, 0, -3.6)
	voj.root.rotation.y = atan2(STAND.x - 20.6, STAND.z + 203.6)
	carry = null
	game.Q.clear()
	game.line = null
	game.say("G", "Bude to nejlepší maskotka, pane Vojtěchu.")

func goal() -> String:
	if ph > 0:
		return ""
	if step >= 4:
		return ""
	return ("Přines na stojan: " + NAMES[step] + " ▶ (✋)") if holding else ("Vezmi z ponku: " + NAMES[step] + " ◀ (✋)")

func act() -> void:
	if ph != 0:
		return
	if not holding and dx < BENCH_X + 1.3 and step < 4:
		holding = true
		bench[step].visible = false
		carry = bench[step].duplicate()
		carry.visible = true
		dman.root.add_child(carry)
		carry.position = Vector3(0, 1.1, 0.35)
		game.audio.sfx("pick", 0.6)
	elif holding and dx > STAND.x - 1.6:
		holding = false
		carry.queue_free()
		carry = null
		if step == 0:
			skel.visible = true
		else:
			for i in range(0, cocoa_parts.size()):
				if i * 3 / cocoa_parts.size() == step - 1:
					cocoa_parts[i].visible = true
		step += 1
		game.audio.sfx("clunk", 0.7)
		game.audio.sfx("servo", 0.4)
		if step == 2:
			game.say("F", "Tak tohle bude Cocoa?")
		if step == 4:
			for mi in cocoa_parts:
				mi.visible = true
			game.say("F", "Ema by ji milovala. Kdyby tu byla.")
			ph = 1
			pt = 0.0

func tick(dt: float) -> void:
	pt += dt
	game.tick_lines(dt)
	var mv = hold
	var k = game.keys
	if k.get("a") or k.get("left"):
		mv = -1
	if k.get("d") or k.get("right"):
		mv = 1
	var moving = false
	if ph == 0 and mv != 0:
		dx = clampf(dx + mv * 2.2 * dt, BENCH_X + 0.6, STAND.x - 0.9)
		moving = true
	dman.root.position = Vector3(dx, 0, LINE_Z)
	dman.root.rotation.y = lerp_angle(dman.root.rotation.y, (PI / 2 if mv >= 0 else -PI / 2) if moving else atan2(STAND.x - dx, STAND.z - LINE_Z), dt * 8)
	var P = preload("res://scripts/people.gd")
	P.animate(dman, game.t_now, dt, moving, game.talking("G"), "grab" if holding else "")
	P.animate(voj, game.t_now, dt, ph == 1 and pt > 3.0, game.talking("F"))
	lamp.light_energy = 4.0 + sin(game.t_now * 17) * 0.15
	var cam: Camera3D = game.cam
	match ph:
		0:
			cam.position = Vector3(dx - 0.6, 2.3, -2.7)
			cam.look_at(Vector3((dx + STAND.x) / 2, 1.1, -6.6))
		1:
			# pan Vojtěch odchází, D. zůstane sám s Cocoou
			cam.position = Vector3(15.5, 1.9, -2.7)
			cam.look_at(STAND + Vector3(0, 1.4, 0))
			if pt > 3.0:
				voj.root.position = voj.root.position.move_toward(Vector3(23.5, 0, -3.0), dt * 1.2)
				voj.root.rotation.y = PI / 2
			if pt > 6.0 and pt - dt <= 6.0:
				voj.root.visible = false
				game.audio.sfx("doorcreak", 0.6, 0.8)
				game.say("G", "Tak. Teď už tu budeš navždy.")
			if pt > 9.0:
				ph = 2
				pt = 0.0
				lamp.light_energy = 0.4
				game.audio.sfx("powerdown", 0.6)
		2:
			# Ema se probouzí uvnitř Cocoy
			lamp.light_energy = 0.25 + (0.6 if randf() < 0.05 else 0.0)
			cam.position = STAND + Vector3(0.25 + sin(pt * 0.4) * 0.05, 1.7, 1.5)
			cam.look_at(STAND + Vector3(0, 1.45, 0))
			eye_l.light_energy = clampf(pt / 2.0, 0, 1) * (0.35 + 0.1 * sin(game.t_now * 7))
			if pt > 1.5 and pt - dt <= 1.5:
				game.audio.sfx("whisper", 0.7)
				game.say("E", "Tati? Kde to jsem?")
				game.say("E", "Je tu tma. Nemůžu se hýbat.")
			cocoa.rotation.y = (sin(game.t_now * 19) * 0.03 if pt > 2.0 else 0.0)
			if pt > 9.5:
				ph = 3
				pt = 0.0
		3:
			if pt > 4.5:
				done = true

func finish() -> void:
	if root:
		root.queue_free()
		root = null
