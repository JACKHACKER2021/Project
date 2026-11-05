extends Node3D
## NIGHT AT VOXIE'S 4 – NIGHTMARE (Godot preview)
## Malá Ema v pokojíčku, rok 1997. Dveře a skříň umí otevřít jen noční můry.
## Nightmare Voxie chodí chodbami k levým a pravým dveřím, Nightmare Hollow Bunny se schovává ve skříni.
## Obě se bojí světla: když se dveře otevírají, posviť do nich baterkou, dokud necouvnou. Přežij do 6:00.

const HOUR := 45.0
const EYE := Vector3(0, 1.05, 0.2)
const VIEWS := {"closet": 0.0, "left": PI / 2, "back": PI, "right": -PI / 2}
const ORDER := ["left", "closet", "right", "back"]

var S := "loading"
var scene_t := 0.0
var t_now := 0.0
var G = null
var store := {}
var keys := {}
var menu_night := 1
var line = null
var Q := []

var env: Environment
var cam: Camera3D
var torch: SpotLight3D
var post: ColorRect
var hud
var audio
var house: Node3D
var doors := {}        # "left"/"right"/"closet" -> [Node3D...] křídla
var door_open_y := {"left": [1.3], "right": [-1.3], "closet": [-1.0, 1.0]}
var vox: Node3D
var bun: Node3D
var nm_parts := {}
var sky_mat: StandardMaterial3D
var bolt: Node3D
var flash_l: OmniLight3D
var rain: Node3D
var moon: OmniLight3D
var rain_player: AudioStreamPlayer
var plush: Node3D
var mini
var DEV := {"god": false}
var scene_from_extras := false
const MINI := {1: "show", 2: "hide", 3: "pit", 5: "shutdown"}
var eye_nodes := {}
var d7_bunny: Node3D
var d7_light: OmniLight3D

func _ready() -> void:
	_load_store()
	menu_night = st_get("v4_night", 1)
	audio = preload("res://scripts/audio.gd").new()
	audio.game = self
	add_child(audio)
	_build()
	mini = preload("res://scripts/mini.gd").new()
	mini.game = self
	hud = preload("res://scripts/hud.gd").new()
	hud.game = self
	var pl = CanvasLayer.new()
	pl.layer = 0
	add_child(pl)
	post = ColorRect.new()
	post.set_anchors_preset(Control.PRESET_FULL_RECT)
	post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	post.material = ShaderMaterial.new()
	post.material.shader = load("res://scripts/post.gdshader")
	pl.add_child(post)
	var hl = CanvasLayer.new()
	hl.layer = 1
	add_child(hl)
	hl.add_child(hud)
	S = "menu"
	audio.start_menu_song()
	if "--shots" in OS.get_cmdline_user_args():
		preload("res://scripts/shots.gd").run(self)

func _gaabb(n: Node3D) -> AABB:
	var a = AABB()
	var first = true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var aa = mi.global_transform * mi.get_aabb()
		a = aa if first else a.merge(aa)
		first = false
	return a

func make_font() -> Font:
	var f: FontFile = load("res://fonts/mono.ttf")
	var sy: FontFile = load("res://fonts/symbols.ttf")
	var em: FontFile = load("res://fonts/emoji.ttf")
	for x in [f, sy, em]:
		x.allow_system_fallback = false
	f.fallbacks = [sy, em]
	return f
func _load_store() -> void:
	if FileAccess.file_exists("user://v4.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("user://v4.json"))
		if d is Dictionary:
			store = d
func st_get(k: String, d):
	return store.get(k, d)
func st_set(k: String, v) -> void:
	store[k] = v
	var f = FileAccess.open("user://v4.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(store))
static func ease_io(t: float) -> float:
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
static func pick(a: Array):
	return a[randi() % a.size()]

# ------------------------------------------------------------------ svět
func _build() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#020104")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#2a2850")
	env.ambient_light_energy = 0.3
	env.glow_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color("#05040a")
	env.fog_density = 0.08
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	house = load("res://models/ema_house.glb").instantiate()
	add_child(house)
	doors.left = [house.find_child("Door_L", true, false)]
	doors.right = [house.find_child("Door_R", true, false)]
	doors.closet = [house.find_child("Closet_L", true, false), house.find_child("Closet_R", true, false)]
	# skříň: místo plného černého bloku skutečný prostor, ve kterém se schová Hollow Bunny
	var closet = house.find_child("Closet", true, false)
	if closet:
		for mi in closet.get_children():
			if mi is MeshInstance3D and mi.get_aabb().size.z > 0.55 and mi.get_aabb().size.y > 1.9:
				mi.visible = false
		var wm = StandardMaterial3D.new()
		wm.albedo_color = Color("#3a2010")
		wm.roughness = 0.8
		for side in [[Vector3(0.04, 2.25, 0.72), Vector3(-0.73, 1.125, -2.56)], [Vector3(0.04, 2.25, 0.72), Vector3(0.73, 1.125, -2.56)], [Vector3(1.5, 0.04, 0.72), Vector3(0, 2.23, -2.56)]]:
			var sm = MeshInstance3D.new()
			var sb = BoxMesh.new()
			sb.size = side[0]
			sm.mesh = sb
			sm.position = side[1]
			sm.material_override = wm
			add_child(sm)
		# tyč s ramínky a šaty (Eminy šatičky na oslavu)
		var rod = MeshInstance3D.new()
		var rb = BoxMesh.new()
		rb.size = Vector3(1.4, 0.03, 0.03)
		rod.mesh = rb
		rod.position = Vector3(0, 1.9, -2.6)
		rod.material_override = wm
		add_child(rod)
		for i in 3:
			var dr = MeshInstance3D.new()
			var db = BoxMesh.new()
			db.size = Vector3(0.05, 0.7, 0.32)
			dr.mesh = db
			dr.position = Vector3(-0.55 + i * 0.12, 1.5, -2.6)
			var dmm = StandardMaterial3D.new()
			dmm.albedo_color = Color(["#e88ab8", "#f4ece0", "#8ab8e8"][i])
			dr.material_override = dmm
			add_child(dr)
		var back = MeshInstance3D.new()
		var bm = BoxMesh.new()
		bm.size = Vector3(1.3, 2.1, 0.04)
		back.mesh = bm
		back.position = Vector3(0, 1.05, -2.9)
		var dm = StandardMaterial3D.new()
		dm.albedo_color = Color("#120a08")
		back.material_override = dm
		add_child(back)
	# plyšová Cocoa (dodaný model) místo kostičkové
	var old = house.find_child("CocoaPlush", true, false)
	if old:
		old.visible = false
	if ResourceLoader.exists("res://models/cocoa_plush.glb"):
		var pl = load("res://models/cocoa_plush.glb").instantiate()
		pl.name = "CocoaPlushNew"
		add_child(pl)
		pl.rotation = Vector3(-0.2, PI, 0.1)
		var bb = _gaabb(pl)
		var k = 0.42 / maxf(0.01, bb.size.y)
		pl.scale = Vector3.ONE * k
		bb = _gaabb(pl)
		pl.position += Vector3(-0.22, 0.62, 1.92) - Vector3(bb.get_center().x, bb.position.y, bb.get_center().z)
		plush = pl
	bolt = house.find_child("LightningBolt", true, false)
	if bolt:
		bolt.visible = false
	rain = house.find_child("Rain", true, false)
	var sky = house.find_child("StormSky", true, false)
	if sky and sky is MeshInstance3D:
		sky_mat = (sky as MeshInstance3D).material_override
		if sky_mat == null:
			sky_mat = (sky as MeshInstance3D).mesh.surface_get_material(0)
	for l in house.find_children("*", "Light3D", true, false):
		l.queue_free()
	moon = OmniLight3D.new()
	moon.light_color = Color("#8aa8ff")
	moon.light_energy = 0.7
	moon.omni_range = 4
	moon.position = Vector3(1.6, 1.6, 1.4)
	add_child(moon)
	var night = OmniLight3D.new()
	night.light_color = Color("#ffc070")
	night.light_energy = 0.3
	night.omni_range = 1.8
	night.position = Vector3(-1.0, 0.4, -1.9)
	add_child(night)
	flash_l = OmniLight3D.new()
	flash_l.light_color = Color("#c8d8ff")
	flash_l.light_energy = 0
	flash_l.omni_range = 9
	flash_l.position = Vector3(2.6, 2.0, 1.4)
	add_child(flash_l)
	# noční můry
	var NM = preload("res://scripts/nm.gd")
	vox = NM.make_voxie()
	add_child(vox)
	bun = NM.make_bunny()
	add_child(bun)
	for n in [vox, bun]:
		var p = {}
		for k in ["head", "chest", "leg_L", "leg_R"]:
			p[k] = n.get_node(k)
		p.arm_L = p.chest.get_node("arm_L")
		p.arm_R = p.chest.get_node("arm_R")
		p.jaw = p.head.get_node("jaw")
		var base = {}
		for k in p:
			base[k] = p[k].rotation
		nm_parts[n] = [p, base]
		n.visible = false
		var eyes = []
		for mi in p.head.find_children("*", "MeshInstance3D", true, false):
			var mm = mi.material_override
			if mm is StandardMaterial3D and mm.emission_enabled and mi.get_aabb().size.x < 0.08:
				mm.emission_energy_multiplier = 6.0
				var el = OmniLight3D.new()
				el.light_color = mm.emission
				el.light_energy = 1.0
				el.omni_range = 1.4
				el.position = mi.position + Vector3(0, 0, 0.1)
				mi.get_parent().add_child(el)
				eyes.append([el, mi])
		eye_nodes[n] = eyes
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.05
	cam.far = 40
	add_child(cam)
	cam.current = true
	torch = SpotLight3D.new()
	torch.light_color = Color("#fff4d8")
	torch.light_energy = 0
	torch.spot_range = 10
	torch.spot_angle = 26
	torch.shadow_enabled = true
	torch.position = Vector3(0.15, -0.15, 0)
	cam.add_child(torch)
	rain_player = AudioStreamPlayer.new()
	var rs: AudioStreamWAV = load("res://sfx/rain.wav").duplicate()
	rs.loop_mode = AudioStreamWAV.LOOP_FORWARD
	rs.loop_end = int(rs.get_length() * rs.mix_rate)
	rain_player.stream = rs
	rain_player.volume_db = -14
	add_child(rain_player)

# ------------------------------------------------------------------ titulky
func say(who: String, t: String) -> void:
	Q.append([who, t])
func tick_lines(dt: float) -> void:
	if line:
		line.age += dt
		if line.age > line.dur:
			line = null
	if line == null and Q.size():
		var n = Q.pop_front()
		var d = audio.voice(n[1], 0.8) if audio.AUD.voice.has(n[1]) else clampf(n[1].length() * 0.06, 2.0, 5.0)
		line = {"who": n[0], "t": n[1], "dur": maxf(d + 0.9, 2.2), "age": 0.0}

# ------------------------------------------------------------------ noc
func new_night(n: int) -> void:
	var lv = (n - 1) * 0.7
	G = {
		"night": n, "t": 0.0, "view": "closet", "yaw": 0.0, "light": false, "bat": 100.0, "batLock": false,
		"fear": 0.0, "boltT": randf_range(6, 12), "flash": 0.0, "thunderT": -1.0,
		# Nightmare Voxie: chodí mezi chodbami, u dveří otevírá
		"vox": {"side": "left", "stage": 0, "t": maxf(5.0, randf_range(14, 22) - lv * 3), "open": 0.0, "lit": 0.0, "flinch": 0.0},
		# Nightmare Hollow Bunny: ve skříni
		"bun": {"side": "closet", "stage": 0, "t": (6.0 if n >= 7 else maxf(8.0, randf_range(26, 36) - lv * 4)), "open": 0.0, "lit": 0.0, "flinch": 0.0},
		"hurt": 0.0, "dead_by": "",
	}
	if n == 6:
		G.vox.t = 1e9
		G.bun.t = 1e9
	for k in doors:
		for d in doors[k]:
			d.rotation.y = 0.0
	vox.visible = false
	bun.visible = false
	Q.clear()
	line = null
func start_night(n: int) -> void:
	audio.stop_menu_song()
	new_night(n)
	scene_from_extras = false
	if MINI.has(n):
		start_mini(MINI[n])
		return
	if n == 4:
		start_d4()
		return
	if n == 7:
		start_d7()
		return
	S = "intro"
	scene_t = 0.0
func start_mini(kind: String, extras := false) -> void:
	S = "mini"
	scene_t = 0.0
	scene_from_extras = extras
	mini.start(kind, extras)
	audio.stop_menu_song()
func end_scene() -> void:
	if d7_bunny:
		d7_bunny.visible = false
	if d7_light:
		d7_light.visible = false
	bun.visible = false
	Q.clear()
	line = null
	if scene_from_extras:
		rain_player.stop()
		S = "extras"
		scene_t = 0.0
		audio.start_menu_song()
	else:
		S = "intro"
		scene_t = 0.0
func begin_play() -> void:
	S = "play"
	scene_t = 0.0
	rain_player.play()
	audio.sfx("thunder", 0.7, 0.4)
	G.flash = 0.25
	say("E", "Mami? Tati?")
	say("E", "Zase ta bouřka.")
	if G.night == 1:
		say("E", "Bojí se světla. Táta říkal, že se bojí světla.")

func hour() -> int:
	return int(G.t / HOUR) if G else 0

func play_tick(dt: float) -> void:
	G.t += dt
	if G.t >= HOUR * 6:
		return win_night()
	tick_lines(dt)
	# otáčení (plynulé)
	var target = VIEWS[G.view]
	G.yaw = lerp_angle(G.yaw, target, minf(1.0, dt * 9))
	# baterka
	if G.light and not G.batLock:
		G.bat = maxf(0, G.bat - dt * (0.0 if DEV.god else (9.0 + G.night * 0.6)))
		if G.bat <= 0:
			G.batLock = true
			audio.sfx("powerdown", 0.4)
	else:
		G.bat = minf(100, G.bat + dt * 5.5)
		if G.batLock and G.bat > 25:
			G.batLock = false
	torch.light_energy = 6.0 * (0.9 + 0.1 * sin(t_now * 40)) if G.light and not G.batLock else 0.0
	# bouřka
	storm_tick(dt)
	if G.night < 7:
		_enemy_tick("vox", dt)
	_enemy_tick("bun", dt)
	# strach: tlukot srdce, když je něco otevřené
	var danger = maxf(G.vox.open, G.bun.open)
	G.fear = move_toward(G.fear, danger, dt * 0.8)
	if G.fear > 0.3 and fmod(t_now, 1.0 - G.fear * 0.55) < dt:
		audio.sfx("heart", 0.2 + G.fear * 0.5)

func storm_tick(dt: float) -> void:
	G.boltT -= dt
	if G.boltT <= 0:
		G.boltT = randf_range(10, 24) - G.night
		G.flash = 0.35
		G.thunderT = randf_range(0.4, 1.6)
	if G.thunderT > 0:
		G.thunderT -= dt
		if G.thunderT <= 0:
			audio.sfx("thunder", randf_range(0.6, 1.0), 0.5)
	G.flash = maxf(0, G.flash - dt)
	var f = 0.0
	if G.flash > 0:
		f = 1.0 if fmod(G.flash, 0.12) > 0.05 else 0.25
	flash_l.light_energy = f * 4.0
	if bolt:
		bolt.visible = f > 0.5
	if sky_mat:
		sky_mat.emission_energy_multiplier = 0.35 + f * 3.0
	if rain:
		rain.position.y = -fmod(t_now * 9.0, 1.0)

## je pohled a baterka namířená na danou stranu?
func lit(side: String) -> bool:
	return G.light and not G.batLock and G.view == side and absf(wrapf(G.yaw - VIEWS[side], -PI, PI)) < 0.25

func _set_open(side: String, k: float) -> void:
	var ys = door_open_y[side]
	for i in doors[side].size():
		doors[side][i].rotation.y = ys[i] * k

# ---------- noční můry: Voxie (levé/pravé dveře), Hollow Bunny (skříň; v 7. noci všechny tři strany)
func _place(n: Node3D, side: String, k: float) -> void:
	if side == "closet":
		n.position = Vector3(0, -0.45, -2.6)
		n.rotation = Vector3.ZERO
		n.scale = Vector3.ONE * 0.74
	else:
		var s = -1.0 if side == "left" else 1.0
		n.scale = Vector3.ONE * 0.92
		# s otevíráním dveří se nakloní do škvíry
		n.position = Vector3(3.0 * s - s * 0.35 * k, 0, 0.05 + 0.18 * k)
		n.rotation = Vector3(0, -PI / 2 * s, 0.12 * k * s)

func _enemy_tick(who: String, dt: float) -> void:
	var E = G[who]
	var node: Node3D = vox if who == "vox" else bun
	var lv = (G.night - 1) * 0.7 + hour() * 0.3
	var pan = func(side): return -0.9 if side == "left" else (0.9 if side == "right" else 0.0)
	match E.stage:
		0:
			E.t -= dt
			if E.t <= 0:
				if who == "vox":
					E.side = pick(["left", "right"])
				elif G.night >= 7:
					E.side = pick(["left", "right", "closet"])
				else:
					E.side = "closet"
				E.stage = 1
				E.t = randf_range(2.0, 3.5) if G.night >= 7 else randf_range(4, 7)
				if E.side == "closet":
					audio.sfx("servo", 0.5, 0.0)
					audio.sfx("whisper", 0.4, 0.0)
		1:
			# kroky na chodbě (u skříně jen cvakání zámků)
			E.t -= dt
			if E.side != "closet" and fmod(E.t, 0.7) < dt:
				audio.sfx("step", 0.35, pan.call(E.side))
			if E.t <= 0 or E.side == "closet":
				E.stage = 2
				E.open = 0.0
				E.lit = 0.0
				E.flinch = 0.0
				audio.sfx("doorcreak", 0.8, pan.call(E.side))
				if randf() < 0.3 and E.side != "closet":
					say("E", "Něco je za dveřmi.")
		2:
			node.visible = true
			_place(node, E.side, ease_io(E.open))
			if E.flinch > 0:
				# couvá před světlem, pak dveře zabouchne
				E.flinch += dt
				_nm_pose(node, dt, E.open, E.flinch)
				node.position += node.transform.basis.z * -E.flinch * 0.9
				if E.flinch > 0.55:
					_repel(who)
				return
			_nm_pose(node, dt, E.open, 0.0)
			if lit(E.side):
				E.lit += dt
				if E.lit > (1.0 if who == "vox" else 1.1) + lv * 0.12:
					E.flinch = 0.01
					audio.sfx("servo", 0.7, pan.call(E.side))
					return
			else:
				E.lit = maxf(0, E.lit - dt * 0.5)
				var sp = (0.09 + lv * 0.03) if E.side != "closet" else (0.07 + lv * 0.025)
				if G.night >= 7:
					sp *= 1.25
				E.open = minf(1.0, E.open + dt * sp)
			_set_open(E.side, ease_io(E.open))
			if E.open >= 1.0:
				E.t += dt
				if E.t > 1.6 - minf(0.8, lv * 0.15):
					jumpscare(who)

func _repel(who: String) -> void:
	var lv = (G.night - 1) * 0.7
	var E = G[who]
	var node: Node3D = vox if who == "vox" else bun
	E.stage = 0
	E.open = 0.0
	E.flinch = 0.0
	if G.night >= 7:
		E.t = randf_range(3.0, 6.0)
	elif who == "vox":
		E.t = maxf(4.0, randf_range(12, 20) - lv * 2.5 - hour())
	else:
		E.t = maxf(6.0, randf_range(18, 28) - lv * 3 - hour())
	_set_open(E.side, 0.0)
	node.visible = false
	audio.sfx("clunk", 0.9, -0.9 if E.side == "left" else (0.9 if E.side == "right" else 0.0))

## animace: dýchání, škubání, ruka sahá na dveře, nahlíží škvírou; při světle si kryje oči
func _nm_pose(n: Node3D, dt: float, k: float, flinch := 0.0) -> void:
	var pb = nm_parts[n]
	var p = pb[0]
	var b = pb[1]
	var tw = 0.0
	if fmod(t_now * 1.9, 3.3) < 0.09:
		tw = randf_range(-0.35, 0.35)
	p.chest.scale = Vector3(1, 1.0 + sin(t_now * 2.2) * 0.02, 1)
	p.head.rotation = b.head + Vector3(sin(t_now * 1.3) * 0.06 - k * 0.15, sin(t_now * 0.7) * 0.2 + tw, 0.25 * k + tw * 0.5)
	p.jaw.rotation = b.jaw + Vector3(0.1 + k * 0.45 + absf(sin(t_now * 6)) * 0.08 * k, 0, 0)
	# levá ruka drží hranu dveří, pravá se natahuje
	p.arm_L.rotation = b.arm_L + Vector3(-1.2 * k, 0.4 * k, -0.5 * k)
	p.arm_R.rotation = b.arm_R + Vector3(-0.5 * k + sin(t_now * 3) * 0.12 * k, 0, 0.2 * k)
	if flinch > 0:
		var f = clampf(flinch / 0.3, 0, 1)
		p.arm_L.rotation = b.arm_L + Vector3(-2.4 * f, 0, 0.6 * f)
		p.arm_R.rotation = b.arm_R + Vector3(-2.4 * f, 0, -0.6 * f)
		p.head.rotation = b.head + Vector3(0.45 * f, randf_range(-0.1, 0.1), 0)
		p.jaw.rotation = b.jaw + Vector3(0.9 * f, 0, 0)
	# svítící oči: ve světle se zúží, jinak pomalu pulzují
	for e in eye_nodes.get(n, []):
		var lit_now = G != null and G.light and not G.batLock and flinch <= 0 and k > 0.05
		e[0].light_energy = (0.25 if lit_now else 1.1 + sin(t_now * 4) * 0.25) * (0.3 if flinch > 0 else 1.0)
		e[1].scale = Vector3.ONE * (0.55 if lit_now or flinch > 0 else 1.0)

func jumpscare(who: String) -> void:
	if DEV.god:
		_repel(who)
		return
	var node: Node3D = vox if who == "vox" else bun
	G.scareFrom = node.position
	G.scareSide = G[who].side
	S = "scare"
	scene_t = 0.0
	G.dead_by = who
	G.light = false
	rain_player.stop()
	audio.sfx("scare", 1.3)
	audio.sfx("scare_v" if who == "vox" else "scare_c", 1.0)
func win_night() -> void:
	S = "win"
	scene_t = 0.0
	rain_player.stop()
	audio.sfx("chime", 1.0)
	audio.voice("Už je ráno. Byl to jen sen.", 0.8)
	var n: int = G.night
	st_set("v4_night", maxi(st_get("v4_night", 1), mini(7, n + 1)))
	if n >= 7:
		st_set("v4_end", true)
	menu_night = mini(7, n + 1)
func to_menu() -> void:
	S = "menu"
	scene_t = 0.0
	G = null
	vox.visible = false
	bun.visible = false
	if d7_bunny:
		d7_bunny.visible = false
	if d7_light:
		d7_light.visible = false
	torch.light_energy = 0
	rain_player.stop()
	audio.start_menu_song()

func turn(dir: int) -> void:
	var i = ORDER.find(G.view)
	G.view = ORDER[(i + dir + 4) % 4]
	audio.sfx("step", 0.08)

# ==================================================================
func _process(delta: float) -> void:
	var dt = minf(delta, 0.1)
	t_now += dt
	scene_t += dt
	match S:
		"play": play_tick(dt)
		"d7": d7_tick(dt)
		"d4": d4_tick(dt)
		"mini":
			mini.tick(dt)
			if mini.done:
				end_scene()
		"extras": extras_tick(dt)
		"intro":
			if scene_t > 6.0:
				if d7_bunny:
					d7_bunny.visible = false
				begin_play()
	render(dt)
	hud.queue_redraw()

func render(dt: float) -> void:
	var pm: ShaderMaterial = post.material
	pm.set_shader_parameter("uT", t_now)
	var vig = 0.8
	var glitch = 0.0
	match S:
		"menu", "loading":
			var a = t_now * 0.12
			cam.position = EYE + Vector3(0, 0.1, 0)
			cam.rotation = Vector3(-0.05, sin(a) * 1.4, 0)
			# blesky i v menu
			if randf() < dt * 0.15:
				flash_l.light_energy = 4
				audio.sfx("thunder", 0.4, 0.5)
			flash_l.light_energy = maxf(0, flash_l.light_energy - dt * 12)
			if sky_mat:
				sky_mat.emission_energy_multiplier = 0.35 + flash_l.light_energy * 0.7
			bun.visible = true
			bun.position = Vector3(0, -0.45, -2.6)
			bun.scale = Vector3.ONE * 0.74
			_set_open("closet", 0.25)
		"mini":
			vig = 0.3
		"extras":
			vig = 0.9
		"d4", "d7":
			vig = 1.0
			glitch = 0.5 if G.flash > 0 else 0.0
		"play", "intro":
			cam.position = EYE
			var f: float = G.fear if G else 0.0
			cam.rotation = Vector3(-0.04 + sin(t_now * 1.1) * 0.01 * f, (G.yaw if G else 0.0) + sin(t_now * 13) * 0.004 * f, 0)
			vig = 0.8 + f * 0.5
			glitch = f * 0.15 if randf() < 0.1 else 0.0
		"scare":
			_render_scare(dt)
			vig = 1.2
			glitch = 0.5 if scene_t < 0.5 else 0.1
	pm.set_shader_parameter("uVig", vig)
	pm.set_shader_parameter("uGlitch", glitch)
	pm.set_shader_parameter("uGrain", 0.06)

func _render_scare(dt: float) -> void:
	var who: Node3D = vox if G.dead_by == "vox" else bun
	var t = scene_t
	who.visible = true
	var side: String = G.get("scareSide", "closet")
	# Ema se prudce otočí ke dveřím, ze kterých noční můra skočí
	G.yaw = lerp_angle(G.yaw, VIEWS[side], minf(1.0, dt * 14))
	var dir = Vector3(-sin(G.yaw), 0, -cos(G.yaw))
	var from: Vector3 = G.get("scareFrom", Vector3(0, 0, -2.0))
	var to = Vector3(EYE.x, 0, EYE.z) + dir * 1.35
	var k = ease_io(clampf(t / 0.42, 0, 1))
	who.scale = Vector3.ONE * lerpf(who.scale.x, 1.0, minf(1.0, dt * 10))
	who.position = from.lerp(to, k) + Vector3(0, sin(k * PI) * 0.55 - 0.25 * k, 0)
	who.look_at(Vector3(EYE.x, who.position.y, EYE.z), Vector3.UP, true)
	who.rotation.x = -0.35 * sin(k * PI)
	var pb = nm_parts[who]
	pb[0].jaw.rotation = pb[1].jaw + Vector3(0.95 + sin(t_now * 30) * 0.15, 0, 0)
	pb[0].head.rotation = pb[1].head + Vector3(randf_range(-0.1, 0.1), randf_range(-0.15, 0.15), 0)
	pb[0].arm_L.rotation = pb[1].arm_L + Vector3(-2.5, 0, 0.4)
	pb[0].arm_R.rotation = pb[1].arm_R + Vector3(-2.5, 0, -0.4)
	for e in eye_nodes.get(who, []):
		e[0].light_energy = 3.0
		e[1].scale = Vector3.ONE * 1.3
	cam.position = EYE + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * (0.015 + 0.03 * k)
	cam.rotation = Vector3(0.1 * k, G.yaw, 0)
	if k > 0.5:
		var head: Node3D = nm_parts[who][0].head
		cam.look_at(head.global_position + Vector3(0, 0.15, 0))
	torch.light_energy = 5.0 if fmod(t, 0.16) > 0.08 else 1.0
	if t > 2.4:
		S = "dead"
		scene_t = 0.0
		who.visible = false
		torch.light_energy = 0

# ---------- před 4. nocí: Hollow Bunny poprvé, zády, mluví o sobě jako o maskotovi
const D4 := ["Ahoj, děti! Já jsem Hollow Bunny!", "Jsem nejlepší kamarád všech dětí v herně Voxie's.", "Miluju děti. Miluju, když se smějí a hrají si se mnou.", "Voxie zpívá na pódiu. Ale já chodím za vámi.", "A víte co? Já si vás vždycky najdu."]
func start_d4(extras := false) -> void:
	S = "d4"
	scene_t = 0.0
	scene_from_extras = extras
	if G == null:
		new_night(4)
	G.d7 = 0
	G.d7t = 0.0
	if d7_bunny == null:
		d7_bunny = preload("res://scripts/hollow.gd").make(false)
		add_child(d7_bunny)
	if d7_light == null:
		d7_light = OmniLight3D.new()
		d7_light.light_color = Color("#9ab0ff")
		d7_light.omni_range = 3.5
		add_child(d7_light)
	d7_light.visible = true
	d7_light.light_energy = 0.9
	d7_light.position = Vector3(0.9, 2.2, -1.1)
	d7_bunny.visible = true
	d7_bunny.position = Vector3(0, 0, -1.85)
	d7_bunny.rotation = Vector3(0, PI, 0)
	rain_player.play()
	audio.stop_menu_song()
	for l in D4:
		say("D", l)
func d4_tick(dt: float) -> void:
	tick_lines(dt)
	storm_tick(dt)
	G.d7t += dt
	cam.position = EYE
	cam.rotation = Vector3(0.24, 0, 0)
	var head: Node3D = d7_bunny.get_node("head")
	# pohupuje se jako maskot na pódiu, mává
	var arm: Node3D = d7_bunny.get_node("chest").get_node("arm_R")
	arm.rotation = Vector3(-2.2 + sin(t_now * 4) * 0.4, 0, 0.3)
	d7_bunny.position.y = absf(sin(t_now * 2.2)) * 0.03
	head.rotation = Vector3(0.05, sin(t_now * 1.1) * 0.25, sin(t_now * 2.2) * 0.1)
	if line == null and Q.is_empty() and G.d7t > 2.0:
		# na konci natočí hlavu přes rameno… a tma
		head.rotation = Vector3(0.1, -1.1, 0.2)
		if G.d7 == 0:
			G.d7 = 1
			G.d7t = 0.0
			audio.sfx("servo", 0.8)
		elif G.d7t > 1.4:
			arm.rotation = Vector3.ZERO
			end_scene()

# ---------- Extras: postavy a přehrávání scén
var ex_page := "chars"
var ex_i := 0
var ex_nodes := []
const EX := [["NIGHTMARE VOXIE", "noční můra · jaro 1997", "Voxie Bear z Eminých snů. Zubatá tlama i na břiše, drápy, rudé oči. Chodí chodbami k levým a pravým dveřím a bojí se světla."], ["NIGHTMARE HOLLOW BUNNY", "noční můra · jaro 1997", "Hollow Bunny tak, jak si ho Ema pamatuje: ten, který ji vždycky našel. Schovává se ve skříni. Uvnitř obleku byl celou dobu D."], ["HOLLOW BUNNY", "springlock · 1980", "Žlutý springlock králík z roku 1980. Odstavený kvůli zámkům – ale D. si ho oblékal dál. Pro Emu to byl kamarád, který s ní hrál na schovávanou."], ["PLYŠOVÁ COCOA", "Emina hračka", "Plyšová Cocoa na Emině polštáři. Leží každou noc trochu jinak."]]
func start_extras() -> void:
	S = "extras"
	scene_t = 0.0
	ex_page = "chars"
	if G == null:
		new_night(1)
func extras_tick(dt: float) -> void:
	var spot = Vector3(0, 0, -1.2)
	vox.visible = ex_page == "chars" and ex_i == 0
	bun.visible = ex_page == "chars" and ex_i == 1
	if d7_bunny == null:
		d7_bunny = preload("res://scripts/hollow.gd").make(false)
		add_child(d7_bunny)
	d7_bunny.visible = ex_page == "chars" and ex_i == 2
	var n: Node3D = [vox, bun, d7_bunny, plush][ex_i]
	var rot = t_now * 0.5
	if ex_i < 3:
		n.position = spot
		n.rotation = Vector3(0, rot, 0)
		n.scale = Vector3.ONE * 0.8
		if ex_i < 2:
			_nm_pose(n, dt, 0.4 + 0.3 * sin(t_now))
		cam.position = Vector3(-0.6, 1.4, 1.6)
		cam.look_at(spot + Vector3(-0.85, 1.1, 0))
	else:
		cam.position = Vector3(0.1, 1.0, 1.0)
		cam.look_at(plush.global_position + Vector3(0, 0.15, 0))
	torch.light_energy = 3.0

# ---------- před 7. nocí: Hollow Bunny mluví k Emě zády, pak se otočí a ukáže se noční můra
const D7_A := ["Ahoj, Emo. Pamatuješ si mě?", "Hráli jsme spolu na schovávanou. Vždycky jsem tě našel.", "Myslela sis, že jsem jen robot. Že se zapínám sám.", "Ale uvnitř jsem byl celou dobu já.", "Pamatuješ, jak jsi řekla tátovi, ať jdete do auta? Viděla jsi, jak se dívám.", "A pak, v herně, zhaslo světlo."]
const D7_B := ["Je to tvoje vina. Tvoje a tvého táty.", "Ta herna měla být i moje. Nikdy mě nenechal být spoluvlastníkem.", "Tak si to zasloužíte. Oba."]
func start_d7(extras := false) -> void:
	if G == null:
		new_night(7)
	S = "d7"
	scene_t = 0.0
	scene_from_extras = extras
	audio.stop_menu_song()
	G.d7 = 0
	G.d7t = 0.0
	if d7_bunny == null:
		d7_bunny = preload("res://scripts/hollow.gd").make(false)
		add_child(d7_bunny)
	d7_bunny.visible = true
	if d7_light == null:
		d7_light = OmniLight3D.new()
		d7_light.light_color = Color("#9ab0ff")
		d7_light.omni_range = 3.5
		add_child(d7_light)
	d7_light.visible = true
	d7_light.light_energy = 0.9
	d7_light.position = Vector3(0.9, 2.2, -1.1)
	d7_bunny.position = Vector3(0, 0, -1.85)
	d7_bunny.rotation = Vector3(0, PI, 0)
	bun.visible = false
	rain_player.play()
	for l in D7_A:
		say("D", l)
func d7_tick(dt: float) -> void:
	tick_lines(dt)
	storm_tick(dt)
	G.d7t += dt
	cam.position = EYE
	cam.rotation = Vector3(0.24, 0, 0)
	var head: Node3D = d7_bunny.get_node("head")
	match G.d7:
		0:
			# mluví zády, hlava se pomalu naklání
			head.rotation = Vector3(0.1, sin(t_now * 0.6) * 0.15, 0.05 + sin(t_now * 0.9) * 0.08)
			if line == null and Q.is_empty() and G.d7t > 2.0:
				G.d7 = 1
				G.d7t = 0.0
				audio.sfx("servo", 0.9)
		1:
			# pomalé otočení
			var k = ease_io(clampf(G.d7t / 1.6, 0, 1))
			d7_bunny.rotation.y = PI * (1.0 - k)
			head.rotation = Vector3(0.15, -0.4 * (1 - k), 0.1)
			if fmod(G.d7t, 0.35) < dt:
				audio.sfx("servo", 0.5)
			if G.d7t > 1.9:
				# záblesk: z Hollow Bunnyho je noční můra
				G.d7 = 2
				G.d7t = 0.0
				G.flash = 0.45
				audio.sfx("thunder", 1.0, 0.4)
				audio.sfx("scare_c", 0.8)
				d7_bunny.visible = false
				bun.visible = true
				bun.position = Vector3(0, 0, -1.85)
				bun.rotation = Vector3.ZERO
				bun.scale = Vector3.ONE
				for l in D7_B:
					say("H", l)
		2:
			_nm_pose(bun, dt, 0.35 + absf(sin(t_now * 2)) * 0.2)
			var pb = nm_parts[bun]
			if line != null:
				pb[0].jaw.rotation = pb[1].jaw + Vector3(0.3 + absf(sin(t_now * 11)) * 0.4, 0, 0)
			if line == null and Q.is_empty() and G.d7t > 2.0:
				G.d7 = 3
				G.d7t = 0.0
				audio.sfx("scare", 0.9)
		3:
			# skočí k Emě a tma
			var k = clampf(G.d7t / 0.35, 0, 1)
			bun.position = Vector3(0, 0.2 * sin(k * PI), -1.85 + k * 0.9)
			if G.d7t > 0.9:
				end_scene()
