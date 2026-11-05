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

func _ready() -> void:
	_load_store()
	menu_night = st_get("v4_night", 1)
	audio = preload("res://scripts/audio.gd").new()
	audio.game = self
	add_child(audio)
	_build()
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
	var lv = n - 1
	G = {
		"night": n, "t": 0.0, "view": "closet", "yaw": 0.0, "light": false, "bat": 100.0, "batLock": false,
		"fear": 0.0, "boltT": randf_range(6, 12), "flash": 0.0, "thunderT": -1.0,
		# Nightmare Voxie: chodí mezi chodbami, u dveří otevírá
		"vox": {"side": "left", "stage": 0, "t": randf_range(14, 22) - lv * 3, "open": 0.0, "lit": 0.0, "cool": 0.0},
		# Nightmare Hollow Bunny: ve skříni
		"bun": {"stage": 0, "t": randf_range(26, 36) - lv * 4, "open": 0.0, "lit": 0.0, "cool": 0.0},
		"hurt": 0.0, "dead_by": "",
	}
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
		G.bat = maxf(0, G.bat - dt * (9.0 + G.night))
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
	_vox_tick(dt)
	_bun_tick(dt)
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

# ---------- Nightmare Voxie u levých / pravých dveří
func _vox_tick(dt: float) -> void:
	var V = G.vox
	var lv = G.night - 1 + hour() * 0.35
	V.cool = maxf(0, V.cool - dt)
	match V.stage:
		0:
			V.t -= dt
			if V.t <= 0:
				V.side = pick(["left", "right"])
				V.stage = 1
				V.t = randf_range(4, 7)
				audio.sfx("step", 0.25, -0.9 if V.side == "left" else 0.9)
		1:
			# kroky na chodbě
			V.t -= dt
			if fmod(V.t, 0.7) < dt:
				audio.sfx("step", 0.35, -0.9 if V.side == "left" else 0.9)
			if V.t <= 0:
				V.stage = 2
				V.open = 0.0
				V.lit = 0.0
				audio.sfx("doorcreak", 0.8, -0.9 if V.side == "left" else 0.9)
				if randf() < 0.3:
					say("E", "Něco je za dveřmi.")
		2:
			# dveře se pomalu otevírají; světlo ho zažene
			vox.visible = true
			var s = -1.0 if V.side == "left" else 1.0
			vox.position = Vector3(3.0 * s, 0, 0.05)
			vox.rotation = Vector3(0, -PI / 2 * s, 0)
			_nm_pose(vox, dt, V.open)
			if lit(V.side):
				V.lit += dt
				vox.position.x += s * V.lit * 0.25
				if V.lit > 1.2 - minf(0.5, lv * 0.08):
					pass
				if V.lit > 1.0 + lv * 0.12:
					_repel("vox")
					return
			else:
				V.lit = maxf(0, V.lit - dt * 0.5)
				V.open = minf(1.0, V.open + dt * (0.09 + lv * 0.03))
			_set_open(V.side, ease_io(V.open))
			if V.open >= 1.0:
				V.t += dt
				if V.t > 1.6 - minf(0.8, lv * 0.15):
					jumpscare("vox")

# ---------- Nightmare Hollow Bunny ve skříni
func _bun_tick(dt: float) -> void:
	var B = G.bun
	var lv = G.night - 1 + hour() * 0.35
	match B.stage:
		0:
			B.t -= dt
			if B.t <= 0:
				B.stage = 1
				B.open = 0.0
				B.lit = 0.0
				audio.sfx("servo", 0.5, 0.0)
				audio.sfx("whisper", 0.4, 0.0)
		1:
			bun.visible = true
			bun.position = Vector3(0, -0.45, -2.6)
			bun.rotation = Vector3.ZERO
			bun.scale = Vector3.ONE * 0.74
			_nm_pose(bun, dt, B.open)
			if lit("closet"):
				B.lit += dt
				if B.lit > 1.1 + lv * 0.12:
					_repel("bun")
					return
			else:
				B.lit = maxf(0, B.lit - dt * 0.5)
				B.open = minf(1.0, B.open + dt * (0.07 + lv * 0.025))
			_set_open("closet", ease_io(B.open))
			if B.open >= 1.0:
				B.t += dt
				if B.t > 1.4 - minf(0.7, lv * 0.15):
					jumpscare("bun")

func _repel(who: String) -> void:
	var lv = G.night - 1
	if who == "vox":
		var V = G.vox
		V.stage = 0
		V.t = randf_range(12, 20) - lv * 2.5 - hour()
		V.open = 0.0
		_set_open(V.side, 0.0)
		vox.visible = false
		audio.sfx("clunk", 0.9, -0.9 if V.side == "left" else 0.9)
	else:
		var B = G.bun
		B.stage = 0
		B.t = randf_range(18, 28) - lv * 3 - hour()
		B.open = 0.0
		_set_open("closet", 0.0)
		bun.visible = false
		audio.sfx("clunk", 0.8)
	audio.sfx("servo", 0.6)

func _nm_pose(n: Node3D, dt: float, k: float) -> void:
	var pb = nm_parts[n]
	var p = pb[0]
	var b = pb[1]
	p.head.rotation = b.head + Vector3(sin(t_now * 1.3) * 0.06, sin(t_now * 0.7) * 0.2, 0)
	p.jaw.rotation = b.jaw + Vector3(0.1 + k * 0.4 + sin(t_now * 3) * 0.05, 0, 0)
	p.arm_L.rotation = b.arm_L + Vector3(-k * 0.8, 0, 0)
	p.arm_R.rotation = b.arm_R + Vector3(-k * 0.6, 0, 0)

func jumpscare(who: String) -> void:
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
	st_set("v4_night", maxi(st_get("v4_night", 1), mini(3, n + 1)))
	menu_night = mini(3, n + 1)
func to_menu() -> void:
	S = "menu"
	scene_t = 0.0
	G = null
	vox.visible = false
	bun.visible = false
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
		"intro":
			if scene_t > 6.0:
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
	var who = vox if G.dead_by == "vox" else bun
	var t = scene_t
	who.visible = true
	who.scale = Vector3.ONE
	var dir = Vector3(-sin(cam.rotation.y), 0, -cos(cam.rotation.y))
	var k = ease_io(clampf(t / 0.35, 0, 1))
	who.position = Vector3(EYE.x, 0, EYE.z) + dir * (2.0 - k * 1.25) + Vector3(0, -0.15 * k, 0)
	who.look_at(Vector3(EYE.x, 0, EYE.z), Vector3.UP, true)
	var pb = nm_parts[who]
	pb[0].jaw.rotation = pb[1].jaw + Vector3(0.9 + sin(t_now * 30) * 0.15, 0, 0)
	pb[0].head.rotation = pb[1].head + Vector3(randf_range(-0.1, 0.1), randf_range(-0.15, 0.15), 0)
	pb[0].arm_L.rotation = pb[1].arm_L + Vector3(-2.2, 0, 0)
	pb[0].arm_R.rotation = pb[1].arm_R + Vector3(-2.2, 0, 0)
	cam.position = EYE + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.03
	cam.look_at(who.position + Vector3(0, 2.1, 0))
	torch.light_energy = 5.0 if fmod(t, 0.16) > 0.08 else 1.0
	if t > 2.4:
		S = "dead"
		scene_t = 0.0
		who.visible = false
		torch.light_energy = 0
