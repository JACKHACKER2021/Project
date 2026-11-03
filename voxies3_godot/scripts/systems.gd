extends Node
## NaV3 – systémy noci: chůze po budově, úkoly (krabice, vytírání, exponáty, kanystr),
## energie, stíny (Shadow Voxie, Shadow D.), duše Vojtěcha v Broken Voxiem a požár 7. noci.

var game
var shadow_vox: Node3D
var shadow_d: Node3D
var flash: SpotLight3D
var task_nodes := []
var fire_root: Node3D
var fire_lights := []
var debris := []
var vox_node: Node3D
var vox_base := Vector3.ZERO
var hare_fire: CPUParticles3D
var canister: Node3D

const CHECKS := [["Broken Voxie", Vector3(0, 0, -4.2)], ["Hlava Cocoy", Vector3(6.9, 0, 3.6)], ["Kresba", Vector3(0, 0, -12.9)], ["Automaty", Vector3(-10, 0, -5.4)], ["Stoly z pizzerie", Vector3(6.2, 0, -3.6)], ["Hollow Hare", Vector3(0, 0, -16.0)]]
const BOXES := [Vector3(-1.5, 0, -17), Vector3(1.4, 0, -16.4), Vector3(-2.2, 0, -20.6), Vector3(2.1, 0, -20.9)]
const STACK := Vector3(-2.2, 0, -15.0)
const MUD := [Vector3(0.4, 0, -1), Vector3(-4.5, 0, 4), Vector3(-10, 0, 5), Vector3(-10.5, 0, -3.5), Vector3(6, 0, -3), Vector3(0.5, 0, -10.5)]
const BLOCKS := [[-1.35, 6.55, 1.35, 7.7], [-1.45, -7.0, 1.45, -5.0], [7.5, 2.5, 8.5, 3.5], [-13.1, 5.3, -11.3, 6.7]]

func _mat(c, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	return game._mat(c, rough, metal)
func _box(p: Node3D, sz: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	return game._box(p, sz, pos, m)

func build() -> void:
	# Shadow Voxie: opravený klasický Voxie, celý černý – duše, která není Vojtěch
	shadow_vox = preload("res://scripts/hollow.gd").make(false)
	shadow_vox.name = "ShadowVoxie"
	_shadowify(shadow_vox)
	var head: Node3D = shadow_vox.get_node("head")
	for e in ["ear_L", "ear_R"]:
		head.get_node(e).visible = false
	for s in [-1, 1]:
		_box(head, Vector3(0.2, 0.18, 0.12), Vector3(0.24 * s, 0.6, -0.02), _mat("#050407", 1.0))
		_box(head, Vector3(0.1, 0.09, 0.02), Vector3(0.24 * s, 0.6, 0.05), _mat("#0c0a10", 1.0))
	_box(shadow_vox.get_node("chest"), Vector3(0.16, 0.12, 0.2), Vector3(0, 0.88, 0.0), _mat("#050407", 1.0))
	game.add_child(shadow_vox)
	shadow_vox.visible = false
	# Shadow D.: černá postava s bílýma očima
	var N = preload("res://scripts/people.gd").person("D.", Color("#050407"), Color("#050407"), Color("#050407"), Color("#050407"), 1.82, false)
	shadow_d = N.root
	shadow_d.name = "ShadowD"
	_shadowify(shadow_d)
	var hd: Node3D = N.parts.head
	for s in [-1, 1]:
		var ey = _box(hd, Vector3(0.05, 0.05, 0.02), Vector3(0.08 * s, 0.24, 0.17), _glow("#ffffff", 3.0))
	game.add_child(shadow_d)
	shadow_d.visible = false
	# baterka při chůzi
	flash = SpotLight3D.new()
	flash.light_color = Color("#fff4d8")
	flash.light_energy = 0
	flash.spot_range = 14
	flash.spot_angle = 28
	flash.shadow_enabled = false
	game.cam.add_child(flash)
	vox_node = game.world.find_child("znicen_voxie", true, false)
	if vox_node:
		vox_base = vox_node.rotation
	# hořící zajíc
	hare_fire = _fire(Vector3(0.7, 1.4, 0.5), 70)
	hare_fire.position = Vector3(0, 1.3, 0)
	game.hare.add_child(hare_fire)
	hare_fire.emitting = false
	fire_root = Node3D.new()
	game.add_child(fire_root)

func _glow(c: String, e: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.emission_enabled = true
	m.emission = Color(c)
	m.emission_energy_multiplier = e
	return m
func _shadowify(n: Node3D) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m = mi.material_override
		if m is StandardMaterial3D and m.emission_enabled:
			mi.material_override = _glow("#ffffff", 3.0)
		else:
			var b = StandardMaterial3D.new()
			b.albedo_color = Color("#050407")
			b.roughness = 1.0
			b.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			b.albedo_color.a = 0.92
			mi.material_override = b

func _fire(ext: Vector3, n := 60) -> CPUParticles3D:
	var p = CPUParticles3D.new()
	p.amount = n
	p.lifetime = 1.1
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3.UP
	p.spread = 15
	p.gravity = Vector3(0, 2.5, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.3
	p.scale_amount_min = 0.25
	p.scale_amount_max = 0.6
	var q = QuadMesh.new()
	q.size = Vector2(0.5, 0.5)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _flame_tex()
	q.material = m
	p.mesh = q
	var g = Gradient.new()
	g.set_color(0, Color(1, 0.85, 0.4, 1))
	g.add_point(0.4, Color(1, 0.4, 0.05, 0.9))
	g.set_color(g.get_point_count() - 1, Color(0.2, 0.05, 0.02, 0))
	p.color_ramp = g
	return p
var _ftex: Texture2D
func _flame_tex() -> Texture2D:
	if _ftex:
		return _ftex
	var t = GradientTexture2D.new()
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	t.gradient = g
	_ftex = t
	return t

# ------------------------------------------------------------------ noc: příprava
func setup(n: int) -> void:
	for t in task_nodes:
		t.queue_free()
	task_nodes = []
	for d in debris:
		d.queue_free()
	debris = []
	for c in fire_root.get_children():
		c.queue_free()
	fire_lights = []
	hare_fire.emitting = false
	if canister:
		canister.queue_free()
		canister = null
	shadow_vox.visible = false
	shadow_d.visible = false
	var G = game.G
	G.task = {"kind": "", "items": [], "done": 0, "need": 0}
	match n:
		3:
			G.task.kind = "boxes"
			for p in BOXES:
				var b = Node3D.new()
				b.position = p
				game.add_child(b)
				var sz = Vector3(randf_range(0.5, 0.7), randf_range(0.4, 0.55), randf_range(0.5, 0.65))
				_box(b, sz, Vector3(0, sz.y / 2, 0), _mat("#8a6a40", 0.95))
				_box(b, Vector3(sz.x + 0.01, 0.04, 0.08), Vector3(0, sz.y - 0.01, 0), _mat("#c8b088", 0.9))
				b.rotation.y = randf() * 3
				task_nodes.append(b)
				G.task.items.append({"pos": p, "done": false, "node": b, "h": sz.y})
			G.task.need = BOXES.size()
		4:
			G.task.kind = "mop"
			for p in MUD:
				var m = MeshInstance3D.new()
				var c = CylinderMesh.new()
				c.top_radius = randf_range(0.5, 0.8)
				c.bottom_radius = c.top_radius
				c.height = 0.01
				m.mesh = c
				var mm = StandardMaterial3D.new()
				mm.albedo_color = Color("#2a1a0e")
				mm.roughness = 0.15
				mm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.material_override = mm
				m.position = p + Vector3(0, 0.012, 0)
				m.scale = Vector3(1, 1, randf_range(0.6, 1.0))
				game.add_child(m)
				task_nodes.append(m)
				G.task.items.append({"pos": p, "done": false, "node": m, "k": 1.0})
			G.task.need = MUD.size()
		6:
			G.task.kind = "check"
			for c in CHECKS:
				G.task.items.append({"pos": c[1], "done": false, "name": c[0]})
			G.task.need = CHECKS.size()
		7:
			G.task.kind = "fire"
			G.task.need = 2

func task_label() -> String:
	var T = game.G.task
	match T.kind:
		"boxes": return "📦 Poskládej krabice v zákulisí (%d/%d)" % [T.done, T.need]
		"mop": return "🧹 Vytři bláto z podlahy (%d/%d)" % [T.done, T.need]
		"check": return "🔍 Zkontroluj exponáty (%d/%d)" % [T.done, T.need]
		"fire":
			if game.G.t < game.HOUR * 4:
				return "⏳ Ve 4:00 to skončí."
			if T.done == 0:
				return "⛽ Vezmi kanystr benzínu v zákulisí"
			if T.done == 1:
				return "🔥 Polij exponáty u Broken Voxieho a zapal to"
			return "🔥 Přežij do 6:00"
	return ""
func task_done() -> bool:
	var T = game.G.task
	return T.kind == "" or T.done >= T.need

# ------------------------------------------------------------------ chůze
func walkable(x: float, z: float) -> bool:
	var G = game.G
	for b in BLOCKS:
		if x > b[0] and x < b[2] and z > b[1] and z < b[3]:
			return false
	var m = 0.25
	for id in game.MAP.rooms:
		var r = game.MAP.rooms[id]
		if x > r.x0 + m and x < r.x1 - m and z > r.z0 + m and z < r.z1 - m:
			return true
	for id in game.MAP.rooms:
		var r = game.MAP.rooms[id]
		for side in r.doors:
			var f = r.z0 if side == "n" else (r.z1 if side == "s" else (r.x0 if side == "w" else r.x1))
			for g in r.doors[side]:
				if id == "OFF" and side == "w" and G.door:
					continue
				if side == "n" or side == "s":
					if absf(z - f) < 0.5 and x > g[0] + 0.25 and x < g[1] - 0.25:
						return true
				elif absf(x - f) < 0.5 and z > g[0] + 0.25 and z < g[1] - 0.25:
					if id == "WC" and side == "e" and g[0] > 6.0 and G.door:
						continue
					return true
	return false

func stand_up() -> void:
	var G = game.G
	if G.door:
		game.say("P", "Nejdřív musím otevřít dveře.")
		return
	G.roam = true
	G.mon = false
	G.rp = {"x": 0.0, "z": 9.2, "yaw": PI / 2 + 0.2, "pitch": 0.0, "bob": 0.0}
	game.audio.sfx("step", 0.4)
func sit_down() -> void:
	game.G.roam = false
	game.G.look = 0.0
	game.audio.sfx("step", 0.3)
func near_chair() -> bool:
	var p = game.G.rp
	return Vector2(p.x, p.z).distance_to(Vector2(0, 8.8)) < 1.4

func roam_tick(dt: float) -> void:
	var G = game.G
	var p = G.rp
	var mx = 0.0
	var mz = 0.0
	var joy = game.hud.joy
	if joy:
		mx = joy.dx
		mz = joy.dy
	var k = game.keys
	if k.get("w") or k.get("up"):
		mz -= 1
	if k.get("s") or k.get("down"):
		mz += 1
	if k.get("a"):
		mx -= 1
	if k.get("d"):
		mx += 1
	if k.get("left"):
		p.yaw += dt * 2
	if k.get("right"):
		p.yaw -= dt * 2
	var m = Vector2(mx, mz).length()
	if m > 0.05:
		var sp = 2.4 * dt * minf(1, m) / m * (0.7 if G.get("fire", false) else 1.0) * (0.75 + 0.25 * G.san / 100.0)
		var sn = sin(p.yaw)
		var cs = cos(p.yaw)
		var dx = (mx * cs + mz * sn) * sp
		var dz = (-mx * sn + mz * cs) * sp
		if walkable(p.x + dx, p.z):
			p.x += dx
		if walkable(p.x, p.z + dz):
			p.z += dz
		var pb = p.bob
		p.bob += dt * 8
		if floor(pb / PI) != floor(p.bob / PI):
			game.audio.sfx("step", 0.12)
	flash.light_energy = 3.0
	# zajíc tě chytil
	var hp = game.hare.position
	if Vector2(hp.x, hp.z).distance_to(Vector2(p.x, p.z)) < 1.25 and absf(hp.y) < 0.5 and not game.G.hare.get("dead", false) and not game.DEV.god:
		game.jumpscare()

func roam_cam(dt: float) -> void:
	var p = game.G.rp
	var s: float = game.G.nausea
	game.cam.position = Vector3(p.x, 1.6 + sin(p.bob * 2) * 0.03, p.z)
	game.cam.rotation = Vector3(p.pitch + sin(game.t_now * 0.6) * 0.03 * s, p.yaw, sin(game.t_now * 0.7) * 0.08 * s * s)

## co je v dosahu k akci
func target():
	var G = game.G
	var p = Vector3(G.rp.x, 0, G.rp.z)
	var T = G.task
	match T.kind:
		"boxes", "mop", "check":
			for it in T.items:
				if not it.done and p.distance_to(it.pos) < 1.5:
					return it
		"fire":
			if G.t >= game.HOUR * 4:
				if T.done == 0 and canister and p.distance_to(canister.position) < 1.5:
					return {"fire": 0}
				if T.done == 1 and p.distance_to(Vector3(0, 0, -3.6)) < 1.6:
					return {"fire": 1}
	return null
func act_label() -> String:
	var t = target()
	if t == null:
		return ""
	if t.has("fire"):
		return "⛽ VZÍT KANYSTR" if t.fire == 0 else "🔥 POLÍT A ZAPÁLIT"
	match game.G.task.kind:
		"boxes": return "📦 ODNÉST KRABICI"
		"mop": return "🧹 VYTŘÍT"
		"check": return "🔍 ZKONTROLOVAT"
	return ""
func act() -> void:
	var G = game.G
	var t = target()
	if t == null:
		return
	var T = G.task
	if t.has("fire"):
		if t.fire == 0:
			canister.visible = false
			T.done = 1
			game.audio.sfx("pick", 0.8)
			game.say("P", "Mám ho.")
		else:
			T.done = 2
			start_fire()
		return
	t.done = true
	T.done += 1
	match T.kind:
		"boxes":
			var h = 0.0
			for it in T.items:
				if it.done and it != t:
					h += it.h
			var tw = game.create_tween()
			tw.tween_property(t.node, "position", STACK + Vector3(randf_range(-0.05, 0.05), h, randf_range(-0.05, 0.05)), 0.5)
			game.audio.sfx("clunk", 0.4)
		"mop":
			var tw = game.create_tween()
			tw.tween_property(t.node, "scale", Vector3(0.01, 1, 0.01), 1.2)
			game.audio.sfx("drain", 0.4)
		"check":
			game.audio.sfx("task", 0.5)
			if t.name == "Hollow Hare":
				game.say("P", "Zajíc. Zase se dívá jinam.")
	if T.done >= T.need:
		game.audio.sfx("fixed", 0.8)

# ------------------------------------------------------------------ energie
func power_tick(dt: float) -> void:
	var G = game.G
	if G.blackout:
		G.blackT += dt
		return
	var d = 0.05
	if G.door:
		d += 0.22
	if G.vent:
		d += 0.18
	if G.dl and not G.door:
		d += 0.12
	if G.vl and not G.vent:
		d += 0.1
	if G.mon:
		d += 0.06
	if G.get("fire", false):
		d *= 1.6
	G.pow = maxf(0, G.pow - d * dt)
	if G.pow <= 0:
		blackout()
func on_bang() -> void:
	var G = game.G
	G.bangs += 1
	if G.bangs % 3 == 0:
		G.pow = maxf(0, G.pow - 5.0)
		G.powFlash = 1.2
		game.audio.sfx("powerdown", 0.35)
func blackout() -> void:
	var G = game.G
	G.blackout = true
	G.blackT = 0.0
	G.door = false
	G.vent = false
	G.dl = false
	G.vl = false
	G.mon = false
	game.desk_lamp.visible = false
	game.screen_mat.emission_energy_multiplier = 0.0
	game.audio.sfx("powerdown", 1.0)
	if G.hare.node != "DOOR":
		game.hare_go("DOOR")

# ------------------------------------------------------------------ stíny
func shadows_tick(dt: float) -> void:
	var G = game.G
	var n: int = G.night
	var lv_v = game.CUST.sv if n == 8 else (0 if n < 3 else 4 + n * 2)
	var lv_d = game.CUST.sd if n == 8 else (0 if n < 5 else 3 + n * 2)
	for sh in G.shadows:
		sh.t -= dt
		var node: Node3D = shadow_vox if sh.who == "vox" else shadow_d
		var seen = false
		if sh.where == "office":
			seen = not G.mon and not G.roam and absf(G.look - sh.ang) < 0.45
		elif sh.where == "cam":
			seen = G.mon and G.app == "cam" and G.cam == sh.cam and G.staticT <= 0
		if seen:
			sh.seen += dt
			if sh.seen > 1.5:
				G.scareFace = {"who": sh.who, "t": 0.9}
				G.san = maxf(0, G.san - 25)
				game.audio.sfx("scare_v", 0.9)
				if sh.who == "vox":
					game.say("S", "Já nejsem Vojtěch.")
				sh.t = 0.0
		if sh.t <= 0:
			node.visible = false
	G.shadows = G.shadows.filter(func(s): return s.t > 0)
	for who in ["vox", "d"]:
		var lv = lv_v if who == "vox" else lv_d
		if lv <= 0 or G.kroupa or G.get("fire", false):
			continue
		var key = "sh_" + who
		G[key] = G.get(key, randf_range(30, 50)) - dt * (0.4 + lv / 10.0)
		if G[key] <= 0:
			G[key] = randf_range(45, 80)
			var busy = false
			for s in G.shadows:
				busy = busy or s.who == who
			if busy:
				continue
			var node: Node3D = shadow_vox if who == "vox" else shadow_d
			node.visible = true
			if randf() < 0.5 and not G.roam:
				var a = 0.55 if who == "d" else -0.6
				var pos = game.EYE + Vector3(-sin(a) * 2.6, -1.3, -cos(a) * 2.6)
				pos.z = clampf(pos.z, 6.45, 9.6)
				node.position = pos
				node.rotation.y = atan2(game.EYE.x - pos.x, game.EYE.z - pos.z)
				G.shadows.append({"who": who, "where": "office", "ang": a, "t": 7.0, "seen": 0.0})
			else:
				var cid = game.pick(["01", "02", "03", "05", "06", "07"])
				var c = game.MAP.cams[cid]
				var cp = Vector3(c.pos[0], 0, c.pos[2])
				var lk = Vector3(c.look[0], 0, c.look[2])
				var pos = cp.lerp(lk, 0.45)
				node.position = pos
				node.rotation.y = atan2(cp.x - pos.x, cp.z - pos.z)
				G.shadows.append({"who": who, "where": "cam", "cam": cid, "t": 9.0, "seen": 0.0})
			game.audio.sfx("whisper", 0.35, randf_range(-1, 1))
	if G.scareFace:
		G.scareFace.t -= dt
		if G.scareFace.t <= 0:
			G.scareFace = null

# ------------------------------------------------------------------ Broken Voxie a duše Vojtěcha (jen 7. noc)
func vox_tick(dt: float) -> void:
	var G = game.G
	var V = G.vox
	var lv = game.CUST.vx if G.night == 8 else (8 if G.night == 7 else 0)
	if lv <= 0 or G.get("fire", false) or G.kroupa:
		return
	V.callT -= dt * (0.5 + lv / 10.0)
	if V.callT <= 0 and not V.called:
		V.callT = randf_range(45, 75)
		V.called = true
		V.twitch = 1.6
		game.say("V", game.pick(game.L.voxie))
		game.audio.sfx("servo", 0.5, -0.1)
		var H = G.hare
		if H.node not in ["DOOR", "VENTDOOR"]:
			game.hare_go("VOXIE")
	if V.twitch > 0 and vox_node:
		V.twitch -= dt
		vox_node.rotation = vox_base + Vector3(randf_range(-0.06, 0.06), randf_range(-0.15, 0.15), randf_range(-0.06, 0.06))
		if V.twitch <= 0:
			vox_node.rotation = vox_base
	var H = G.hare
	if H.node == "VOXIE" and H.path.is_empty() and V.called:
		V.beat = true
		V.hp -= dt * (5.0 + lv * 0.3)
		V.hitT -= dt
		if V.hitT <= 0:
			V.hitT = 0.55
			game.audio.sfx("clunk", 0.35, -0.1)
			if vox_node:
				vox_node.rotation = vox_base + Vector3(randf_range(-0.1, 0.1), 0, randf_range(-0.1, 0.1))
		if V.hp <= 0:
			G.dead_by = "voxie"
			game.S = "dead"
			game.scene_t = 0.0
			game.audio.sfx("scare", 0.8)
	else:
		if V.beat and H.node != "VOXIE":
			V.beat = false
			V.called = false

# ------------------------------------------------------------------ 7. noc: kanystr a požár
func fire_tick(dt: float) -> void:
	var G = game.G
	if G.task.kind != "fire":
		return
	if G.t >= game.HOUR * 4 and canister == null and G.task.done == 0:
		canister = Node3D.new()
		canister.position = Vector3(2.2, 0, -21.2)
		game.add_child(canister)
		_box(canister, Vector3(0.36, 0.48, 0.18), Vector3(0, 0.24, 0), _mat("#b01010", 0.5))
		_box(canister, Vector3(0.24, 0.06, 0.08), Vector3(0, 0.52, 0), _mat("#202020", 0.5))
		game.say("P", "Tady to někde musí být. Kanystr.")
	if not G.get("fire", false):
		return
	G.fireT += dt
	# šíření ohně po místnostech
	var order = ["HALL", "ARCH", "COC", "PIZ", "WC", "BACK", "ARC", "LOBBY"]
	var k = mini(order.size(), int(G.fireT / 6.0) + 1)
	while fire_root.get_child_count() < k * 2 and fire_root.get_child_count() < order.size() * 2:
		var id = order[fire_root.get_child_count() / 2]
		var r = game.MAP.rooms[id]
		var c = Vector3((r.x0 + r.x1) / 2, 0.4, (r.z0 + r.z1) / 2)
		var f = _fire(Vector3((r.x1 - r.x0) * 0.4, 0.3, (r.z1 - r.z0) * 0.4), 90)
		f.position = c
		fire_root.add_child(f)
		var l = OmniLight3D.new()
		l.light_color = Color("#ff6a1a")
		l.light_energy = 2.5
		l.omni_range = 9
		l.position = c + Vector3(0, 1.6, 0)
		fire_root.add_child(l)
		fire_lights.append(l)
		game.audio.sfx("burnlong", 0.4)
	for l in fire_lights:
		l.light_energy = 2.0 + sin(game.t_now * 17 + l.position.x) * 0.6 + randf() * 0.5
	# budova se rozpadá: padající sutiny
	G.debT -= dt
	if G.debT <= 0:
		G.debT = randf_range(0.6, 1.6)
		var base = Vector3(G.rp.x, 0, G.rp.z) if G.roam else Vector3(0, 0, 4.0)
		var p = base + Vector3(randf_range(-4, 4), 3.1, randf_range(-5, 1.5))
		var d = MeshInstance3D.new()
		var b = BoxMesh.new()
		b.size = Vector3(randf_range(0.4, 1.2), randf_range(0.05, 0.4), randf_range(0.4, 1.2))
		d.mesh = b
		d.material_override = _mat(game.pick(["#2a2420", "#3a3634", "#1a1210"]), 0.95)
		d.position = p
		d.rotation = Vector3(randf(), randf() * 3, randf())
		game.add_child(d)
		debris.append(d)
		var tw = game.create_tween()
		tw.tween_property(d, "position:y", b.size.y / 2, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			game.audio.sfx("clunk", 0.6, clampf((d.position.x - game.cam.position.x) / 5, -1, 1))
			G.shake = 0.35)
		if debris.size() > 70:
			debris.pop_front().queue_free()
	# budova se postupně hroutí: místnost po místnosti padá strop a kácí se zdi
	G.colT = G.get("colT", 10.0) - dt
	if G.colT <= 0:
		G.colT = randf_range(6.0, 9.0)
		var left = order.filter(func(id): return not G.get("fallen", []).has(id))
		if left.size():
			collapse_room(left[0])
	# na konci praská i strop kanceláře
	if G.t > game.HOUR * 5.7 and not G.get("fallen", []).has("OFF"):
		collapse_room("OFF", true)
	G.shake = maxf(0, G.get("shake", 0.0) - dt)
	# kouř ničí příčetnost, venku z kanceláře víc
	G.san -= dt * (1.2 if G.roam else 0.35)
	# hořící zajíc
	var H = G.hare
	if not H.get("dead", false):
		hare_fire.emitting = true
		if G.t > game.HOUR * 5.5:
			H.dead = true
			H.path = []
			game.say("H", "Hoří to! Ne! Ne!")
			var tw = game.create_tween()
			tw.tween_property(game.hare, "rotation:x", -PI / 2, 1.4).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(game.hare, "position:y", 0.3, 1.4)
			game.audio.sfx("powerdown", 0.6)
func collapse_room(id: String, partial := false) -> void:
	var G = game.G
	if not G.has("fallen"):
		G.fallen = []
	G.fallen.append(id)
	var room: Node3D = game.world.find_child("Room_" + id, true, false)
	if room == null:
		return
	var H = 3.2
	var i = 0
	for c in room.get_children():
		if not (c is MeshInstance3D) or not c.visible:
			continue
		var bm = c.mesh as BoxMesh
		if bm == null:
			continue
		var tw = game.create_tween()
		var delay = randf_range(0.0, 2.5)
		if c.position.y > H - 0.6:
			# strop, rastr a světla padají dolů
			if partial and randf() < 0.75:
				continue
			tw.tween_interval(delay)
			tw.tween_property(c, "position:y", randf_range(0.05, 0.6), randf_range(0.5, 0.9)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tw.parallel().tween_property(c, "rotation", Vector3(randf_range(-0.5, 0.5), randf_range(-0.4, 0.4), randf_range(-0.5, 0.5)), 0.8)
		elif bm.size.y > H - 0.3 and not partial and randf() < 0.5:
			# zeď se nakloní a propadne
			var ax = Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
			tw.tween_interval(delay + 1.0)
			tw.tween_property(c, "rotation", ax, randf_range(1.2, 2.0)).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(c, "position:y", c.position.y - randf_range(0.6, 1.4), 1.6)
		else:
			continue
		i += 1
	# hromady sutin
	var r = game.MAP.rooms[id]
	for k in (3 if partial else 9):
		var d = MeshInstance3D.new()
		var b = BoxMesh.new()
		b.size = Vector3(randf_range(0.5, 1.4), randf_range(0.2, 0.7), randf_range(0.5, 1.4))
		d.mesh = b
		d.material_override = _mat(game.pick(["#2a2420", "#3a3634", "#1a1210", "#4a2a18"]), 0.95)
		d.position = Vector3(randf_range(r.x0 + 0.5, r.x1 - 0.5), 4.0, randf_range(r.z0 + 0.5, r.z1 - 0.5))
		if partial:
			d.position = Vector3(randf_range(-2.6, 2.6), 4.0, randf_range(8.2, 9.8))
		d.rotation = Vector3(randf(), randf() * 3, randf())
		game.add_child(d)
		debris.append(d)
		var tw2 = game.create_tween()
		tw2.tween_interval(randf_range(0.2, 2.0))
		tw2.tween_property(d, "position:y", b.size.y * 0.35, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	game.audio.sfx("crackle", 1.0, clampf(((r.x0 + r.x1) / 2 - game.cam.position.x) / 8, -1, 1))
	game.audio.sfx("clunk", 1.0)
	G.shake = 1.2

func start_fire() -> void:
	var G = game.G
	G.fire = true
	G.fireT = 0.0
	G.debT = 2.0
	game.audio.sfx("burnlong", 0.9)
	game.audio.sfx("whoosh", 0.8)
	game.say("P", "Shoř. Shoř i s ním.")
	game.env.ambient_light_color = Color("#5a2a14")

func tick(dt: float) -> void:
	var G = game.G
	power_tick(dt)
	shadows_tick(dt)
	vox_tick(dt)
	fire_tick(dt)
	G.powFlash = maxf(0, G.powFlash - dt)
