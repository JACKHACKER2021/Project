extends Node3D
## NIGHT AT VOXIE'S 3 – FRIGHTS & HIDES (Godot)
## Strašidelná atrakce z relikvií herny. Hlídač píše hlášení na Windows XP, sleduje kamery
## a Hollow Hare (Hollow Bunny s D. uvnitř) chodí po budově. Pohled na něj ničí příčetnost (sanity).

const HOUR := 50.0
const EYE := Vector3(0, 1.3, 8.6)
const LOOK_DOOR := 1.3
const LOOK_VENT := -1.25

var S := "loading"
var scene_t := 0.0
var t_now := 0.0
var G = null
var L: Dictionary            # repliky (data/lines.json)
var MAP: Dictionary          # místnosti a kamery (data/frights_hides_map.json)
var store := {}
var keys := {}
var menu_night := 1
var line = null              # {"who","t","dur","age"}
var Q := []
var end_kind := ""

var env: Environment
var cam: Camera3D
var feed_vp: SubViewport
var feed_cam: Camera3D
var post: ColorRect
var hud
var audio
var world: Node3D
var hare: Node3D
var hare_parts := {}
var hare_base := {}
var hare_eyes: Array = []
var kroupa: Dictionary
var door_n: Node3D
var vent_n: Node3D
var door_light: SpotLight3D
var vent_light: SpotLight3D
var desk_lamp: OmniLight3D
var screen_mat: StandardMaterial3D
var red_light: OmniLight3D
var coffee_led: MeshInstance3D
var DEV := {"god": false, "freeze": false, "fps": false, "panel": false}
var CUST := {"hare": 10, "sv": 5, "sd": 5, "vx": 5}
var sys

# ------------------------------------------------------------------ graf místností pro zajíce
const NODES := {
	"BACK": Vector3(0, 0, -20), "ARCH": Vector3(0.5, 0, -11), "HALL": Vector3(-1.2, 0, -1.5), "WC": Vector3(-4.5, 0, 0),
	"LOBBY": Vector3(-10, 0, 6), "ARC": Vector3(-10, 0, -3), "PIZ": Vector3(7, 0, -4.5), "COC": Vector3(5.5, 0, 3.8),
	"VENT": Vector3(12.5, 0, -5), "DOOR": Vector3(-4.1, 0, 7.8), "VENTDOOR": Vector3(3.9, 0, 7.6), "VOXIE": Vector3(1.0, 0, -4.1),
}
const LINKS := {
	"BACK": ["ARCH", "VENT"], "ARCH": ["BACK", "HALL"], "HALL": ["ARCH", "WC", "PIZ", "COC", "VOXIE"], "VOXIE": ["HALL"], "WC": ["HALL", "LOBBY", "ARC", "DOOR"],
	"LOBBY": ["WC", "ARC"], "ARC": ["WC", "LOBBY"], "PIZ": ["HALL"], "COC": ["HALL"], "VENT": ["BACK", "VENTDOOR"],
	"DOOR": ["WC"], "VENTDOOR": ["VENT"],
}
# průchody mezi místnostmi (aby zajíc nechodil zdí)
const VIA := {
	"BACK-ARCH": [[0, -14]], "ARCH-HALL": [[0, -8]], "HALL-WC": [[-3, -2.8]], "HALL-PIZ": [[3, -4]], "HALL-COC": [[3, 3]],
	"WC-LOBBY": [[-6, 6]], "WC-ARC": [[-6, -2]], "LOBBY-ARC": [[-10, 2]], "WC-DOOR": [[-4.5, 7.8]],
	"BACK-VENT": [[2.2, -18.5], [12.5, -18.5]], "VENT-VENTDOOR": [[12.5, 7.6]],
}
const CAM_ROOM := {"01": "LOBBY", "02": "ARC", "03": "WC", "04": "HALL", "05": "PIZ", "06": "COC", "07": "ARCH", "08": "BACK", "09": "VENT"}
const REPORTS := {
	1: "Hlášení noční směny, noc 1. Prohlídka s panem Kroupou proběhla. Exponáty jsou na místě: automaty, stoly, hlava Cocoy, zbytky Voxieho. Zajíc v zákulisí se nehýbe. Vše v pořádku.",
	2: "Hlášení, noc 2. Ve 2:00 zajíc nebyl v zákulisí. Na kameře 4 stál u Voxieho. Netuším, kdo ho přenesl. Dveře kanceláře jsem musel zavřít. Je tu vedro a smrad.",
	3: "Hlášení, noc 3. Zajíc chodí. Ne, nikdo ho nepřenáší, CHODÍ. Slyšel jsem, jak cvakají zámky. Z šachty šel hlas. Říkal, že ho to bolí. Prosím, pošlete sem někoho.",
	4: "Hlášení, noc 4. Točí se mi hlava, kdykoliv se na něj podívám na kameře. Ten hlas zná moje jméno. Uvnitř obleku je člověk. Vidím mu oči. Muzeum ho nesmí dostat.",
	6: "Hlášení, noc 6. Zkontroloval jsem exponáty. Všechny jsou na místě. Kromě zajíce, ten nikdy není tam, kde ho nechám. Zítra ho odvezou. To nedovolím.",
	7: "Hlášení, noc 7. Nebude žádné ráno pro tohle místo.",
	8: "Custom Night. Žádné hlášení, jen přežít.",
	5: "Hlášení, noc 5. Předposlední noc. Pokud tohle čtete, tak víte, že v tom zajíci je D. Springlocky ho tam zavřely navždy. Neprodávejte ho. Spalte ho. A mě už nehledejte.",
}
const MAILS := {
	1: [["Kroupa", "Vítejte!", "Vítejte ve Frights & Hides. Hlášení pište do Hlášení.doc na ploše. Kamery najdete v aplikaci F&H Kamery. Dveře zavírejte jen v nouzi, klimatizace nefunguje. — K."]],
	2: [["Kroupa", "Stížnosti", "Návštěvníci psali, že je zajíc sledoval očima. Svítí mu oči zeleně, to je skvělý efekt, zapomněl jsem, že jsme ho tam dali. Asi. — K."], ["neznámý", "(bez předmětu)", "nedívej se na něj dlouho"]],
	3: [["Kroupa", "MUZEUM!", "Muzeum nabízí za zajíce víc než za celou budovu. Hlavně ať se nic nerozbije. A jestli vám je zle, je to únava. — K."], ["Policie ČR – náčelník Král", "Pátrání", "Hledáme bývalého hlídače D., který před šesti týdny zmizel z převozu. Pokud uvidíte cokoliv podezřelého, volejte 158."]],
	4: [["Kroupa", "Prášky", "Brigádník omdlel. V šuplíku stolu máte prášky na uklidnění. Nepřehánějte to. — K."], ["neznámý", "otevři", "otevři dveře otevři dveře otevři dveře otevři"]],
	6: [["Kroupa", "Exponáty", "Projděte všechny exponáty, muzeum chce seznam. A nesahejte na Voxieho, prý se hýbe. Haha. — K."], ["D.", "...", "nedovol jim aby mě odvezli. spal to. spal mě."]],
	7: [["Kroupa", "Poslední noc", "Ráno přijede muzeum. Je to poslední noc, pak máte volno. — K."], ["neznámý", "benzín", "ve skladu za zákulisím stojí kanystr. ve 4 hodiny."]],
	8: [],
	5: [["Kroupa", "Zítra", "Ráno si zajíce odvezou. Budete mít volno. Hlášení prosím pečlivě, muzeum ho bude chtít vidět. — K."], ["D.", "...", "zámky povolily když jsem utíkal. jsem tu pořád. bolí to. nepouštěj je ke mně"]],
}

# ==================================================================
func _ready() -> void:
	L = JSON.parse_string(FileAccess.get_file_as_string("res://data/lines.json"))
	MAP = JSON.parse_string(FileAccess.get_file_as_string("res://data/frights_hides_map.json"))
	_load_store()
	menu_night = st_get("v3_night", 1)
	audio = preload("res://scripts/audio.gd").new()
	audio.game = self
	add_child(audio)
	_build()
	sys = preload("res://scripts/systems.gd").new()
	sys.game = self
	add_child(sys)
	sys.build()
	CUST = st_get("v3_cust", CUST)
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
	if "--burntglb" in OS.get_cmdline_user_args():
		var hb = preload("res://scripts/hare.gd").make_hare()
		add_child(hb)
		var keep = hare
		hare = hb
		hare_mats = {}
		seed(404)
		hare_burnt(true)
		hare = keep
		var doc = GLTFDocument.new()
		var st = GLTFState.new()
		doc.append_from_scene(hb, st)
		print("BURNT ", doc.write_to_filesystem(st, "res://models/hollow_hare_burnt.glb"))
		hare_mats = {}
		get_tree().quit()
		return
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
	if FileAccess.file_exists("user://v3.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("user://v3.json"))
		if d is Dictionary:
			store = d
func st_get(k: String, d):
	return store.get(k, d)
func st_set(k: String, v) -> void:
	store[k] = v
	var f = FileAccess.open("user://v3.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(store))

static func pick(a: Array):
	return a[randi() % a.size()]
static func ease_io(t: float) -> float:
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0

# ------------------------------------------------------------------ stavba
func _mat(c, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = c if c is Color else Color(c)
	m.roughness = rough
	m.metallic = metal
	return m
func _box(p: Node3D, sz: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.position = pos
	mi.material_override = m
	p.add_child(mi)
	return mi

func _build() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#020102")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#4a4458")
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color("#0a080c")
	env.fog_density = 0.035
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we = WorldEnvironment.new()
	we.environment = env
	add_child(we)
	world = load("res://models/frights_hides_map.glb").instantiate()
	add_child(world)
	# původní provizorní kancelářské věci z mapy pryč – kancelář dostane nové vybavení
	for nm in ["Monitor", "MonitorScreen", "ControlPanel", "OfficeWindow"]:
		var n = world.find_child(nm, true, false)
		if n:
			n.visible = false
	for l in world.find_children("*", "Light3D", true, false):
		l.shadow_enabled = false
	_build_office()
	_build_outside()
	hare = preload("res://scripts/hare.gd").make_hare()
	add_child(hare)
	for nm in ["leg_L", "leg_R", "chest", "head"]:
		hare_parts[nm] = hare.get_node(nm)
	hare_parts["arm_L"] = hare_parts.chest.get_node("arm_L")
	hare_parts["arm_R"] = hare_parts.chest.get_node("arm_R")
	hare_parts["jaw"] = hare_parts.head.get_node("jaw")
	for k in hare_parts:
		hare_base[k] = hare_parts[k].rotation
	for mi in hare.find_children("*", "MeshInstance3D", true, false):
		var m = mi.material_override
		if m is StandardMaterial3D and m.emission_enabled:
			hare_eyes.append(mi)
	var eye_l = OmniLight3D.new()
	eye_l.light_color = Color("#60ff70")
	eye_l.light_energy = 0.6
	eye_l.omni_range = 2.2
	eye_l.position = Vector3(0, 0.33, 0.6)
	hare_parts.head.add_child(eye_l)
	hare.position = NODES.BACK
	_make_portrait()
	kroupa = make_kroupa()
	add_child(kroupa.root)
	kroupa.root.visible = false
	cam = Camera3D.new()
	cam.fov = 72
	cam.near = 0.05
	cam.far = 60
	add_child(cam)
	cam.current = true
	feed_vp = SubViewport.new()
	feed_vp.size = Vector2i(640, 400)
	feed_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(feed_vp)
	feed_vp.world_3d = get_viewport().world_3d
	feed_cam = Camera3D.new()
	feed_cam.fov = 66
	feed_cam.far = 40
	feed_vp.add_child(feed_cam)
	var fl = OmniLight3D.new()
	fl.light_color = Color("#c8ffd0")
	fl.light_energy = 0.9
	fl.omni_range = 9
	feed_cam.add_child(fl)
	red_light = OmniLight3D.new()
	red_light.light_color = Color("#ff2010")
	red_light.light_energy = 0
	red_light.omni_range = 6
	red_light.position = EYE + Vector3(0, 1.2, 0)
	add_child(red_light)

## parkoviště před budovou + auto hlídače
var car: Node3D
var car_lights := []
func _build_outside() -> void:
	var o = Node3D.new()
	o.name = "Outside"
	add_child(o)
	var asph = _mat("#1a1a1c", 0.95)
	_box(o, Vector3(60, 0.1, 26), Vector3(-4, -0.06, 23.2), asph)
	_box(o, Vector3(30, 0.16, 2.2), Vector3(-2, 0.0, 11.3), _mat("#3a3836", 0.9))
	for i in 8:
		_box(o, Vector3(0.12, 0.012, 4.2), Vector3(-16 + i * 3.2, 0.0, 15.3), _mat("#d8d0b0", 0.8))
	# fasáda s vchodem a neonem
	var fac = _mat("#2a2230", 0.9)
	_box(o, Vector3(17.0, 5.0, 0.3), Vector3(-19.5 + 17.0 / 2 + 0.0, 2.5, 10.25), fac)
	_box(o, Vector3(23.0, 5.0, 0.3), Vector3(-9 + 23.0 / 2, 2.5, 10.25), fac)
	_box(o, Vector3(2.0, 2.7, 0.3), Vector3(-10, 3.65, 10.25), fac)
	_box(o, Vector3(42, 0.4, 0.5), Vector3(-1.5, 5.1, 10.3), _mat("#141018", 0.9))
	var sign = Label3D.new()
	sign.text = "FRIGHTS & HIDES"
	sign.font_size = 150
	sign.modulate = Color("#ff3030")
	sign.outline_modulate = Color("#400000")
	sign.position = Vector3(-10, 4.25, 10.45)
	sign.rotation.y = PI
	sign.rotation.y = 0
	o.add_child(sign)
	var sub = Label3D.new()
	sub.text = "strašidelný dům · relikvie z herny Voxie's"
	sub.font_size = 40
	sub.modulate = Color("#7dff8a")
	sub.position = Vector3(-10, 3.35, 10.45)
	o.add_child(sub)
	var neon = OmniLight3D.new()
	neon.light_color = Color("#ff3030")
	neon.light_energy = 1.6
	neon.omni_range = 7
	neon.position = Vector3(-10, 4.2, 11.2)
	o.add_child(neon)
	for x in [-18.0, 4.0]:
		_box(o, Vector3(0.12, 4.5, 0.12), Vector3(x, 2.25, 19.5), _mat("#3a3a40", 0.5, 0.6))
		_box(o, Vector3(0.6, 0.12, 0.3), Vector3(x, 4.5, 19.3), _mat("#3a3a40", 0.5, 0.6))
		var sl = OmniLight3D.new()
		sl.light_color = Color("#ffb060")
		sl.light_energy = 1.4
		sl.omni_range = 11
		sl.position = Vector3(x, 4.3, 19.2)
		o.add_child(sl)
	# auto: stará kostičková škodovka
	car = Node3D.new()
	car.name = "Car"
	o.add_child(car)
	var paint = _mat("#2a4a6a", 0.35, 0.4)
	var glass = _mat("#101820", 0.1, 0.3)
	_box(car, Vector3(1.7, 0.55, 4.0), Vector3(0, 0.55, 0), paint)
	_box(car, Vector3(1.5, 0.5, 2.1), Vector3(0, 1.08, 0.2), paint)
	_box(car, Vector3(1.52, 0.38, 1.9), Vector3(0, 1.08, 0.2), glass)
	_box(car, Vector3(1.72, 0.1, 4.04), Vector3(0, 0.36, 0), _mat("#151515", 0.6))
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var wh = MeshInstance3D.new()
			var cm = CylinderMesh.new()
			cm.top_radius = 0.33
			cm.bottom_radius = 0.33
			cm.height = 0.24
			wh.mesh = cm
			wh.material_override = _mat("#0a0a0a", 0.8)
			wh.rotation.z = PI / 2
			wh.position = Vector3(0.82 * sx, 0.33, 1.3 * sz)
			car.add_child(wh)
		_box(car, Vector3(0.36, 0.14, 0.04), Vector3(0.55 * sx, 0.62, -2.01), _mat("#fff8e0", 0.3))
		_box(car, Vector3(0.3, 0.12, 0.04), Vector3(0.55 * sx, 0.62, 2.01), _mat("#a01010", 0.4))
		var hl = SpotLight3D.new()
		hl.light_color = Color("#fff4d8")
		hl.light_energy = 3.0
		hl.spot_range = 16
		hl.spot_angle = 26
		hl.position = Vector3(0.55 * sx, 0.62, -2.1)
		car.add_child(hl)
		car_lights.append(hl)
	car.position = Vector3(-5.5, 0, 16.4)
	car.rotation.y = 0.0

## noc 1: příjezd autem na parkoviště
func start_arrive() -> void:
	new_night(1)
	S = "arrive"
	scene_t = 0.0
	audio.sfx("whoosh", 0.4)
func arrive_tick(dt: float) -> void:
	var t = scene_t
	tick_lines(dt)
	# auto přijede z ulice a zaparkuje čelem k budově
	var k = ease_io(clampf(t / 6.0, 0, 1))
	var a = Vector3(24, 0, 24)
	var b = Vector3(-3, 0, 22)
	var c = Vector3(-5.5, 0, 16.4)
	var p = a.lerp(b, k).lerp(b.lerp(c, k), k)
	var p2 = a.lerp(b, minf(1, k + 0.01)).lerp(b.lerp(c, minf(1, k + 0.01)), minf(1, k + 0.01))
	car.position = p
	if p2.distance_to(p) > 0.0005:
		car.rotation.y = lerp_angle(car.rotation.y, atan2(-(p2.x - p.x), -(p2.z - p.z)), dt * 6)
	for l in car_lights:
		l.light_energy = 3.0 if t < 7.2 else 0.0
	if t < 6.5:
		cam.position = Vector3(-1.0, 1.9, 24.5)
		cam.look_at(car.position + Vector3(0, 0.8, 0))
	else:
		var e = ease_io(clampf((t - 6.5) / 2.5, 0, 1))
		cam.position = Vector3(-4.0, 1.65, 18.6).lerp(Vector3(-8.4, 1.65, 18.2), e)
		cam.look_at(Vector3(-10, 2.6 + (1 - e) * 0.6, 10.3))
	if t > 7.0 and t - dt <= 7.0:
		audio.sfx("clunk", 0.6)
	if t > 8.5 and t - dt <= 8.5:
		for l in L.arrive:
			say("P", l)
	if t > 8.5 and (line != null or Q.size()):
		scene_t = minf(scene_t, 12.9)
	if t > 14.0:
		S = "tour"
		scene_t = 0.0
		tour_i = -1
		_tour_next()

var portrait_vp: SubViewport
func _make_portrait() -> void:
	portrait_vp = SubViewport.new()
	portrait_vp.size = Vector2i(256, 256)
	portrait_vp.own_world_3d = true
	portrait_vp.transparent_bg = true
	portrait_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(portrait_vp)
	var h = preload("res://scripts/hare.gd").make_hare()
	portrait_vp.add_child(h)
	var e = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#304a30")
	e.ambient_light_energy = 0.8
	e.glow_enabled = true
	var we = WorldEnvironment.new()
	we.environment = e
	portrait_vp.add_child(we)
	var key = OmniLight3D.new()
	key.light_color = Color("#a0ffb0")
	key.light_energy = 2.0
	key.omni_range = 4
	key.position = Vector3(0.8, 2.6, 1.4)
	portrait_vp.add_child(key)
	var c = Camera3D.new()
	c.fov = 34
	portrait_vp.add_child(c)
	c.look_at_from_position(Vector3(0.35, 2.0, 1.5), Vector3(0.05, 1.95, 0))
	c.current = true

func _build_office() -> void:
	var o = Node3D.new()
	o.name = "Office3"
	add_child(o)
	# monitor LCD (2004), počítačová skříň, klávesnice, myš, hrnek, šuplík s prášky
	var black = _mat("#1a1a1e", 0.4, 0.3)
	var silver = _mat("#a8aab0", 0.35, 0.6)
	_box(o, Vector3(0.24, 0.02, 0.18), Vector3(0, 0.83, 7.2), black)
	_box(o, Vector3(0.05, 0.22, 0.05), Vector3(0, 0.95, 7.2), black)
	_box(o, Vector3(0.58, 0.44, 0.05), Vector3(0, 1.18, 7.2), black)
	var scr = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(0.52, 0.38)
	scr.mesh = q
	screen_mat = StandardMaterial3D.new()
	screen_mat.albedo_texture = _bliss_tex()
	screen_mat.emission_enabled = true
	screen_mat.emission_texture = screen_mat.albedo_texture
	screen_mat.emission_energy_multiplier = 0.9
	scr.material_override = screen_mat
	scr.position = Vector3(0, 1.185, 7.228)
	o.add_child(scr)
	_box(o, Vector3(0.2, 0.44, 0.46), Vector3(0.75, 1.04, 7.15), silver)
	_box(o, Vector3(0.12, 0.02, 0.01), Vector3(0.75, 1.18, 7.385), black)
	_box(o, Vector3(0.02, 0.02, 0.01), Vector3(0.75, 1.0, 7.385), _mat("#40ff60", 0.5))
	_box(o, Vector3(0.46, 0.025, 0.16), Vector3(0, 0.835, 7.55), _mat("#2a2a2e", 0.6))
	_box(o, Vector3(0.06, 0.025, 0.1), Vector3(0.38, 0.835, 7.6), _mat("#2a2a2e", 0.6))
	var mug = MeshInstance3D.new()
	var cm = CylinderMesh.new()
	cm.top_radius = 0.045
	cm.bottom_radius = 0.04
	cm.height = 0.1
	mug.mesh = cm
	mug.material_override = _mat("#b02020", 0.5)
	mug.position = Vector3(-0.65, 0.87, 7.4)
	o.add_child(mug)
	_box(o, Vector3(0.5, 0.18, 0.6), Vector3(-0.85, 0.62, 7.2), _mat("#3a2a1e", 0.8))
	_box(o, Vector3(0.12, 0.03, 0.02), Vector3(-0.85, 0.62, 7.51), silver)
	# kávovar (sanity: káva uklidní)
	_box(o, Vector3(0.24, 0.34, 0.24), Vector3(1.12, 1.0, 7.1), _mat("#2a2a2e", 0.4, 0.4))
	_box(o, Vector3(0.24, 0.06, 0.1), Vector3(1.12, 1.14, 7.25), _mat("#2a2a2e", 0.4, 0.4))
	_box(o, Vector3(0.14, 0.12, 0.12), Vector3(1.12, 0.89, 7.25), _mat("#203040", 0.1, 0.3))
	coffee_led = _box(o, Vector3(0.03, 0.03, 0.01), Vector3(1.2, 1.08, 7.225), _mat("#ff3020", 0.5))
	# lampa
	_box(o, Vector3(0.14, 0.02, 0.14), Vector3(-1.0, 0.83, 7.0), black)
	_box(o, Vector3(0.02, 0.36, 0.02), Vector3(-1.0, 1.0, 7.0), black)
	_box(o, Vector3(0.16, 0.08, 0.12), Vector3(-0.95, 1.18, 7.05), _mat("#2a5a2a", 0.5))
	desk_lamp = OmniLight3D.new()
	desk_lamp.light_color = Color("#ffd8a0")
	desk_lamp.light_energy = 1.1
	desk_lamp.omni_range = 4.5
	desk_lamp.position = Vector3(-0.9, 1.1, 7.2)
	o.add_child(desk_lamp)
	# židle za hráčem
	_box(o, Vector3(0.5, 0.08, 0.5), Vector3(0, 0.5, 8.75), _mat("#202024", 0.7))
	_box(o, Vector3(0.5, 0.6, 0.06), Vector3(0, 0.85, 9.02), _mat("#202024", 0.7))
	# bezpečnostní roleta ve dveřích (západ) a klapka šachty (východ)
	door_n = Node3D.new()
	door_n.position = Vector3(-2.86, 0, 7.8)
	o.add_child(door_n)
	var dm = _mat("#5a5a60", 0.45, 0.75)
	for i in 10:
		_box(door_n, Vector3(0.06, 0.22, 1.64), Vector3(0, 0.12 + i * 0.23, 0), dm)
	_box(door_n, Vector3(0.08, 0.1, 1.66), Vector3(0, 0.02, 0), _mat("#e8c020", 0.6))
	vent_n = Node3D.new()
	vent_n.position = Vector3(2.86, 0, 7.6)
	o.add_child(vent_n)
	_box(vent_n, Vector3(0.05, 0.92, 0.92), Vector3(0, 0.6, 0), _mat("#4a4a50", 0.5, 0.7))
	for i in 4:
		_box(vent_n, Vector3(0.07, 0.04, 0.8), Vector3(0, 0.3 + i * 0.2, 0), _mat("#2a2a2e", 0.5, 0.7))
	door_light = SpotLight3D.new()
	door_light.light_color = Color("#fff4d0")
	door_light.spot_range = 7
	door_light.spot_angle = 32
	door_light.light_energy = 0
	add_child(door_light)
	door_light.look_at_from_position(Vector3(-2.5, 2.4, 8.4), Vector3(-4.6, 1.0, 7.8))
	vent_light = SpotLight3D.new()
	vent_light.light_color = Color("#fff4d0")
	vent_light.spot_range = 6
	vent_light.spot_angle = 30
	vent_light.light_energy = 0
	add_child(vent_light)
	vent_light.look_at_from_position(Vector3(2.4, 1.6, 8.2), Vector3(4.6, 0.4, 7.6))

func _bliss_tex() -> ImageTexture:
	var img = Image.create(128, 96, false, Image.FORMAT_RGB8)
	for y in 96:
		for x in 128:
			var c = Color("#3a7bd5").lerp(Color("#9ec9f0"), y / 60.0)
			var hill = 62 + 14 * sin(x / 128.0 * PI * 0.9 + 0.3) * 0.8
			if y > hill:
				c = Color("#5fae2e").lerp(Color("#2e7a12"), (y - hill) / 30.0)
			if y > 88:
				c = Color("#2456d6")
			if y > 88 and x < 22:
				c = Color("#3a9a3a")
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

## Pan Kroupa – majitel Frights & Hides (vylepšený kostičkový model z Voxie's 4)
func make_kroupa() -> Dictionary:
	var N = preload("res://scripts/people.gd").person("Kroupa", Color("#ece6da"), Color("#24242c"), Color("#e0b090"), Color("#2a2420"), 1.8, false)
	var body: Node3D = N.parts.body
	var head: Node3D = N.parts.head
	var jacket = _mat("#5a1a4a", 0.75)
	var jacket_d = _mat("#3e1032", 0.75)
	# sako přes košili: dva díly s výstřihem, klopy, kapsička, knoflíky
	for s in [-1, 1]:
		_box(body, Vector3(0.2, 0.66, 0.31), Vector3(0.155 * s, 1.16, 0), jacket)
		var lap = _box(body, Vector3(0.07, 0.3, 0.02), Vector3(0.085 * s, 1.34, 0.16), jacket_d)
		lap.rotation.z = 0.35 * s
	_box(body, Vector3(0.1, 0.07, 0.01), Vector3(-0.15, 1.3, 0.162), jacket_d)
	_box(body, Vector3(0.06, 0.05, 0.012), Vector3(-0.15, 1.33, 0.164), _mat("#e8e0d0"))
	for y in [1.08, 0.96]:
		_box(body, Vector3(0.03, 0.03, 0.02), Vector3(0.08, y, 0.165), _mat("#c8a448", 0.3, 0.8))
	# kravata a bříško
	_box(body, Vector3(0.06, 0.34, 0.02), Vector3(0, 1.24, 0.15), _mat("#a01818", 0.6))
	_box(body, Vector3(0.08, 0.05, 0.022), Vector3(0, 1.42, 0.152), _mat("#7a1010", 0.6))
	_box(body, Vector3(0.44, 0.24, 0.12), Vector3(0, 0.98, 0.12), jacket)
	# pásek s klíči a jmenovka
	_box(body, Vector3(0.52, 0.05, 0.3), Vector3(0, 0.86, 0), _mat("#1a1210", 0.5))
	_box(body, Vector3(0.05, 0.04, 0.02), Vector3(0, 0.86, 0.155), _mat("#c8a448", 0.3, 0.8))
	for i in 3:
		var k = _box(body, Vector3(0.015, 0.07, 0.01), Vector3(0.2 + i * 0.02, 0.8, 0.14), _mat("#b8b8c0", 0.3, 0.9))
		k.rotation.z = (i - 1) * 0.3
	_box(body, Vector3(0.12, 0.05, 0.012), Vector3(0.15, 1.28, 0.163), _mat("#ffe46b", 0.4, 0.5))
	# rukávy saka
	for s in [-1, 1]:
		var arm: Node3D = N.parts["arm" + str(s)]
		(arm.get_child(0) as MeshInstance3D).material_override = jacket
		_box(arm, Vector3(0.15, 0.04, 0.17), Vector3(0, -0.6, 0), _mat("#ece6da"))
	_box(N.parts["arm-1"], Vector3(0.06, 0.04, 0.17), Vector3(0, -0.56, 0.0), _mat("#c8a448", 0.3, 0.8))
	# hlava: pleš, šedé boky, knír, brýle, tvářičky
	var hr: MeshInstance3D = head.get_child(1)
	hr.visible = false
	for s in [-1, 1]:
		_box(head, Vector3(0.05, 0.16, 0.3), Vector3(0.17 * s, 0.28, -0.02), _mat("#6a645c"))
	_box(head, Vector3(0.34, 0.12, 0.06), Vector3(0, 0.3, -0.15), _mat("#6a645c"))
	_box(head, Vector3(0.2, 0.05, 0.04), Vector3(0, 0.14, 0.17), _mat("#4a3a2a"))
	_box(head, Vector3(0.06, 0.06, 0.04), Vector3(0, 0.19, 0.18), _mat("#d89a78"))
	var gl = _mat("#1a1a1a", 0.3, 0.6)
	for s in [-1, 1]:
		_box(head, Vector3(0.1, 0.012, 0.012), Vector3(0.08 * s, 0.28, 0.172), gl)
		_box(head, Vector3(0.1, 0.012, 0.012), Vector3(0.08 * s, 0.2, 0.172), gl)
		_box(head, Vector3(0.012, 0.09, 0.012), Vector3(0.08 * s + 0.045 * s, 0.24, 0.172), gl)
		_box(head, Vector3(0.012, 0.09, 0.012), Vector3(0.08 * s - 0.045 * s, 0.24, 0.172), gl)
		_box(head, Vector3(0.012, 0.012, 0.18), Vector3(0.17 * s, 0.27, 0.08), gl)
		_box(head, Vector3(0.05, 0.03, 0.01), Vector3(0.12 * s, 0.15, 0.162), _mat("#e89a88"))
	_box(head, Vector3(0.04, 0.012, 0.012), Vector3(0, 0.27, 0.172), gl)
	return N

# ------------------------------------------------------------------ dialogy
func say(who: String, t: String) -> void:
	Q.append([who, t])
func tick_lines(dt: float) -> void:
	if line:
		line.age += dt
		if line.age > line.dur:
			line = null
	if line == null and Q.size():
		var n = Q.pop_front()
		var who: String = n[0]
		var d: float
		if who in ["O", "H", "P", "V", "S"] and audio.AUD.voice.has(n[1]):
			d = audio.voice(n[1], {"O": 0.85, "H": 0.75, "P": 0.8, "V": 0.7, "S": 0.8}[who], _hare_pan() if who == "H" else (-0.1 if who == "V" else 0.0))
		else:
			d = clampf(n[1].length() * 0.06, 2.0, 6.0)
		line = {"who": who, "t": n[1], "dur": d + 0.45, "age": 0.0}
func talking(who: String) -> bool:
	return line != null and line.who == who and line.age < line.dur - 0.4

func _hare_pan() -> float:
	var d = hare.position - EYE
	return clampf(d.x / 6.0, -1, 1)

# ------------------------------------------------------------------ prohlídka (noc 1)
const TOUR_SHOT := {
	"LOBBY": [Vector3(-10, 0, 4.5), Vector3(-7.4, 1.6, 8.6), Vector3(-10, 1.4, 4.5)],
	"ARC": [Vector3(-9, 0, -0.8), Vector3(-7.0, 1.6, 1.4), Vector3(-11, 1.0, -5)],
	"HALL": [Vector3(1.4, 0, -3.6), Vector3(-0.6, 1.6, -0.8), Vector3(0, 1.2, -6)],
	"COC": [Vector3(5.2, 0, 1.6), Vector3(4.6, 1.6, 4.8), Vector3(8, 1.2, 3)],
	"PIZ": [Vector3(5.4, 0, -2.0), Vector3(4.0, 1.6, -0.4), Vector3(7, 0.8, -5)],
	"ARCH": [Vector3(1.6, 0, -10.6), Vector3(-0.4, 1.6, -8.6), Vector3(0, 1.6, -13.8)],
	"BACK": [Vector3(1.6, 0, -15.6), Vector3(-0.3, 1.6, -14.4), Vector3(0, 1.2, -20)],
	"OFF": [Vector3(-1.7, 0, 8.4), Vector3(0.4, 1.4, 9.4), Vector3(-1.7, 1.5, 8.4)],
}
var tour_i := 0
func start_tour() -> void:
	new_night(1)
	S = "tour"
	scene_t = 0.0
	tour_i = -1
	_tour_next()
func _tour_next() -> void:
	tour_i += 1
	Q.clear()
	line = null
	if tour_i >= L.tour.size():
		kroupa.root.visible = false
		S = "intro"
		scene_t = 0.0
		return
	var st = L.tour[tour_i]
	kroupa.root.visible = true
	var sh = TOUR_SHOT[st.at]
	kroupa.root.position = sh[0] + Vector3(-0.8, 0, 0.6)
	kroupa.walk_to = sh[0]
	G.tour_cut = 0.0
	for l in st.o:
		say("O", l)
	if L.tour_p.has(st.at):
		say("P", L.tour_p[st.at])
func tour_tick(dt: float) -> void:
	G.tour_cut += dt
	var st = L.tour[tour_i]
	var sh = TOUR_SHOT[st.at]
	var kr: Node3D = kroupa.root
	var to: Vector3 = kroupa.walk_to
	var moving = kr.position.distance_to(to) > 0.05
	if moving:
		kr.position = kr.position.move_toward(to, dt * 1.1)
		kr.rotation.y = atan2(to.x - kr.position.x, to.z - kr.position.z)
	else:
		var c: Vector3 = sh[1]
		kr.rotation.y = lerp_angle(kr.rotation.y, atan2(c.x - kr.position.x, c.z - kr.position.z), dt * 4)
	preload("res://scripts/people.gd").animate(kroupa, t_now, dt, moving, talking("O"), "point" if st.at in ["HALL", "COC", "ARCH"] and talking("O") and G.tour_cut > 3 else "")
	cam.position = sh[1] + Vector3(sin(t_now * 0.4) * 0.05, sin(t_now * 0.9) * 0.02, 0)
	var look: Vector3 = (sh[2] as Vector3).lerp(kr.position + Vector3(0, 1.5, 0), 0.5 + 0.5 * sin(G.tour_cut * 0.3))
	cam.look_at(look)
	tick_lines(dt)
	if line == null and Q.is_empty() and G.tour_cut > 1.0:
		_tour_next()

# ------------------------------------------------------------------ noc
func new_night(n: int) -> void:
	G = {
		"night": n, "t": 0.0, "look": 0.0, "lookT": 0.0, "mon": false, "monA": 0.0,
		"door": false, "vent": false, "dl": false, "vl": false, "san": 100.0, "heat": 0.0,
		"cam": "08", "staticT": 0.0, "typed": 0, "pills": 2 if n >= 3 else 1, "pillT": 0.0,
		"hare": {"node": "BACK", "path": [], "wait": 25.0 - n * 3, "at": 0.0, "bang": 0.0, "goal": "", "ph": 0.0, "moving": false, "lure": "", "lureT": 0.0, "talkT": 14.0, "atk": false},
		"lureCd": 0.0, "hall": 0.0, "hallT": 6.0, "heartT": 0.0, "kroupa": n > 1, "kt": 0.0, "mail": 0, "app": "desk",
		"pow": 100.0, "bangs": 0, "powFlash": 0.0, "blackout": false, "blackT": 0.0, "roam": false, "rp": {"x": 0.0, "z": 9.2, "yaw": 0.0, "pitch": 0.0, "bob": 0.0},
		"shadows": [], "scareFace": null, "vox": {"hp": 100.0, "callT": 25.0, "called": false, "twitch": 0.0, "beat": false, "hitT": 0.0}, "fire": false, "fireT": 0.0, "debT": 0.0, "shake": 0.0, "task": {},
		"mailsRead": {}, "brew": 0.0, "coffeeCd": 0.0, "cups": 0, "tour_cut": 0.0, "nausea": 0.0, "hurtT": 0.0, "dead_by": "",
	}
	hare.position = NODES.BACK
	hare.rotation = Vector3.ZERO
	hare.visible = true
	Q.clear()
	line = null
	door_n.position.y = 2.36
	vent_n.position.y = -0.95
	desk_lamp.visible = true
	env.ambient_light_color = Color("#4a4458")
	G.kroupa = n > 1 and n < 8
	sys.setup(n)
func start_night(n: int) -> void:
	audio.stop_menu_song()
	if n == 1:
		start_arrive()
		return
	new_night(n)
	if n == 8:
		st_set("v3_cust", CUST)
	S = "intro"
	scene_t = 0.0
func begin_play() -> void:
	S = "play"
	scene_t = 0.0
	audio.start_ambient()
	if G.kroupa:
		kroupa.root.visible = true
		kroupa.root.position = Vector3(-1.7, 0, 8.3)
		kroupa.walk_to = kroupa.root.position
		for l in L.nights[str(G.night)]:
			say("O", l)
		for l in L.talk.get(str(G.night), []):
			say(l[0], l[1])
	else:
		kroupa.root.visible = false

func hour() -> int:
	return int(G.t / HOUR) if G else 0

func harder() -> float:
	if G.night == 8:
		return CUST.hare / 10.0 + hour() * 0.05
	return (minf(G.night, 6) - 1) * 0.2 + hour() * 0.08

func play_tick(dt: float) -> void:
	G.t += dt
	if G.t >= HOUR * 6:
		return win_night()
	if G.task.kind == "fire" and G.t >= HOUR * 4 and G.task.done < 2:
		G.t = minf(G.t, HOUR * 4 + 0.5)
	tick_lines(dt)
	# Kroupa na začátku noci mluví ve dveřích, pak odejde
	if G.kroupa:
		var kr: Node3D = kroupa.root
		if line == null and Q.is_empty():
			kroupa.walk_to = Vector3(-4.6, 0, 7.8) if kr.position.x > -3.2 else Vector3(-4.6, 0, 3.0)
		var to: Vector3 = kroupa.walk_to
		var moving = kr.position.distance_to(to) > 0.05
		if moving:
			kr.position = kr.position.move_toward(to, dt * 1.3)
			kr.rotation.y = atan2(to.x - kr.position.x, to.z - kr.position.z)
		else:
			kr.rotation.y = lerp_angle(kr.rotation.y, atan2(EYE.x - kr.position.x, EYE.z - kr.position.z), dt * 4)
		preload("res://scripts/people.gd").animate(kroupa, t_now, dt, moving, talking("O"))
		if kr.position.z < 3.2:
			G.kroupa = false
			kr.visible = false
			audio.sfx("doorcreak", 0.4, -0.8)
		G.t = minf(G.t, 2.0)
	if G.roam:
		sys.roam_tick(dt)
	# pohled a monitor
	G.monA = move_toward(G.monA, 1.0 if G.mon else 0.0, dt * 4)
	if keys.get("left") or keys.get("a"):
		G.look = minf(LOOK_DOOR, G.look + dt * 2.2)
	if keys.get("right") or keys.get("d"):
		G.look = maxf(LOOK_VENT, G.look - dt * 2.2)
	if G.lookT != 0.0:
		G.look = move_toward(G.look, G.lookT, dt * 3.5)
		if absf(G.look - G.lookT) < 0.01:
			G.lookT = 0.0
	door_n.position.y = move_toward(door_n.position.y, 0.0 if G.door else 2.36, dt * 7)
	vent_n.position.y = move_toward(vent_n.position.y, 0.0 if G.vent else -0.95, dt * 5)
	door_light.light_energy = 3.5 if G.dl and not G.door else 0.0
	vent_light.light_energy = 3.0 if G.vl and not G.vent else 0.0
	G.staticT = maxf(0, G.staticT - dt)
	G.lureCd = maxf(0, G.lureCd - dt)
	G.pillT = maxf(0, G.pillT - dt)
	coffee_tick(dt)
	sys.tick(dt)
	if S != "play":
		return
	if not G.kroupa and not DEV.freeze and not G.hare.get("dead", false):
		hare_ai(dt)
	sanity_tick(dt)
	if DEV.god:
		G.san = 100.0

# ------------------------------------------------------------------ Hollow Hare
func _via(a: String, b: String) -> Array:
	if VIA.has(a + "-" + b):
		return VIA[a + "-" + b].duplicate()
	if VIA.has(b + "-" + a):
		var v = VIA[b + "-" + a].duplicate()
		v.reverse()
		return v
	return []
func _bfs(from: String, to: String) -> Array:
	var prev = {from: ""}
	var q = [from]
	while q.size():
		var c = q.pop_front()
		if c == to:
			break
		for n in LINKS[c]:
			if not prev.has(n):
				prev[n] = c
				q.append(n)
	var out = []
	var c = to
	while prev.has(c) and prev[c] != "":
		out.push_front(c)
		c = prev[c]
	return out
func hare_go(target: String) -> void:
	var H = G.hare
	var route = _bfs(H.node, target)
	if route.is_empty():
		return
	var nxt: String = route[0]
	H.path = []
	for p in _via(H.node, nxt):
		H.path.append([Vector3(p[0], 0, p[1]), ""])
	H.path.append([NODES[nxt], nxt])
	H.goal = target

func hare_ai(dt: float) -> void:
	var H = G.hare
	H.lureT = maxf(0, H.lureT - dt)
	if H.atk:
		return
	# při chůzi po budově tě zajíc pronásleduje, když je blízko
	if G.roam and hare.position.y > -0.5:
		var pp = Vector3(G.rp.x, 0, G.rp.z)
		var d = hare.position.distance_to(pp)
		if d < 6.5:
			var dir = (pp - hare.position).normalized()
			var sp = (1.3 + harder() * 0.5) * (0.6 if G.fire else 1.0)
			hare.position += dir * sp * dt
			hare.rotation.y = lerp_angle(hare.rotation.y, atan2(dir.x, dir.z), dt * 6)
			H.ph += dt * 6
			H.path = []
			_hare_pose(dt, true)
			if fmod(H.ph, PI) < dt * 6:
				audio.sfx("step", 0.4, 0.0)
			return
	var at_office = H.node == "DOOR" or H.node == "VENTDOOR"
	if at_office and H.path.is_empty():
		H.at += dt
		var shut = G.door if H.node == "DOOR" else G.vent
		hare.position = NODES[H.node] + (Vector3(0, -1.15, 0) if H.node == "VENTDOOR" else Vector3.ZERO)
		hare.rotation.y = PI / 2 if H.node == "DOOR" else -PI / 2
		_hare_pose(dt, false)
		if shut:
			H.bang -= dt
			if H.bang <= 0:
				H.bang = randf_range(0.9, 1.6)
				audio.sfx("clunk", 0.9, -0.8 if H.node == "DOOR" else 0.8)
				sys.on_bang()
				G.san -= 2.5
				G.staticT = 0.15
			if H.at > 9.0 - harder() * 2:
				H.at = 0.0
				H.node = "WC" if H.node == "DOOR" else "VENT"
				hare.position = NODES[H.node]
				H.wait = randf_range(4, 8)
				hare_go(pick(["BACK", "ARCH", "LOBBY", "PIZ"]) if H.node == "WC" else "BACK")
		elif (H.at > maxf(1.4, 3.6 - harder()) or (G.blackout and H.at > randf_range(4.0, 7.0))) and not DEV.god and not G.roam:
			jumpscare()
		return
	if H.path.size():
		var p: Vector3 = H.path[0][0]
		var d = hare.position.distance_to(p)
		var sp = (1.0 + harder() * 0.6) * (0.55 + 0.45 * absf(sin(H.ph)))
		if H.node == "VENT" or H.path[0][1] == "VENTDOOR":
			sp *= 0.8
		if d < 0.15:
			if H.path[0][1] != "":
				H.node = H.path[0][1]
				if H.node == "DOOR" or H.node == "VENTDOOR":
					H.at = 0.0
					H.bang = 2.5
					audio.sfx("servo", 0.6, -0.8 if H.node == "DOOR" else 0.8)
			H.path.pop_front()
			if H.path.is_empty():
				if H.goal != "" and H.goal != H.node:
					hare_go(H.goal)
				else:
					H.wait = maxf(2.5, randf_range(7, 14) - harder() * 4)
		else:
			var dir = (p - hare.position).normalized()
			hare.position += dir * minf(d, sp * dt)
			hare.rotation.y = lerp_angle(hare.rotation.y, atan2(dir.x, dir.z), dt * 6)
			var ph0 = H.ph
			H.ph += dt * 5.0
			if floor(ph0 / PI) != floor(H.ph / PI):
				var dist = hare.position.distance_to(EYE)
				audio.sfx("step", clampf(0.5 - dist * 0.03, 0.03, 0.5), _hare_pan())
				if randf() < 0.3:
					audio.sfx("servo", clampf(0.3 - dist * 0.02, 0.02, 0.3), _hare_pan())
		# ve větrací šachtě se plazí
		if H.node in ["VENT", "VENTDOOR"] or (H.path.size() and H.path[0][1] in ["VENT", "VENTDOOR"] and hare.position.x > 2.5):
			hare.position.y = -1.15
		else:
			hare.position.y = 0.0
		_hare_pose(dt, true)
	else:
		_hare_pose(dt, false)
		H.wait -= dt
		if H.wait <= 0:
			var target: String
			if H.lure != "" and H.lureT > 0:
				target = H.lure
				H.lure = ""
			elif randf() < 0.25 + harder() * 0.35 and hour() >= 1 - int(G.night >= 3):
				target = "DOOR" if randf() < 0.55 else "VENTDOOR"
			else:
				target = pick(LINKS[H.node])
				if target in ["DOOR", "VENTDOOR"] and hour() < 1:
					target = "BACK"
			hare_go(target)
	if G.mon:
		hare_stare(dt)
	# promluva
	H.talkT -= dt
	if H.talkT <= 0 and line == null and Q.is_empty():
		H.talkT = randf_range(16, 28) - G.night * 1.5
		var pool = L.hare.slice(0, 7)
		for k in L.hare_n:
			if int(k) <= G.night and int(k) < 7:
				pool += L.hare_n[k]
				if int(k) == G.night:
					pool += L.hare_n[k] + L.hare_n[k]
		say("H", pick(pool))

## Hollow Hare se na rozdíl od ostatních vždycky dívá přímo do kamery
func hare_stare(dt: float) -> void:
	if not hare_on_cam():
		return
	var c = MAP.cams[G.cam]
	var cp = Vector3(c.pos[0], c.pos[1], c.pos[2])
	var to = cp - hare.position
	var yaw = atan2(to.x, to.z)
	if G.hare.path.is_empty():
		hare.rotation.y = lerp_angle(hare.rotation.y, yaw, dt * 3)
	var rel = wrapf(yaw - hare.rotation.y, -PI, PI)
	var head: Node3D = hare_parts.head
	head.rotation.y = hare_base.head.y + clampf(rel, -1.2, 1.2)
	head.rotation.x = hare_base.head.x - atan2(to.y - 1.9, Vector2(to.x, to.z).length()) * 0.8

func _hare_pose(dt: float, walking: bool) -> void:
	var H = G.hare if G else {"ph": 0.0}
	var ph: float = H.ph
	var sw = sin(ph) * 0.5 if walking else 0.0
	hare_parts.leg_L.rotation = hare_base.leg_L + Vector3(sw, 0, 0)
	hare_parts.leg_R.rotation = hare_base.leg_R + Vector3(-sw, 0, 0)
	hare_parts.arm_L.rotation = hare_base.arm_L + Vector3(-sw * 0.6, 0, 0)
	hare_parts.arm_R.rotation = hare_base.arm_R + Vector3(sw * 0.6, 0, 0)
	# trhavé škubnutí hlavou (zámky)
	var tw = 0.0
	if fmod(t_now * 1.7, 4.0) < 0.12:
		tw = randf_range(-0.3, 0.3)
	hare_parts.head.rotation = hare_base.head + Vector3(sin(t_now * 0.7) * 0.05, sin(t_now * 0.5) * 0.15 + tw, tw * 0.5)
	var open = 0.0
	if talking("H"):
		open = absf(sin(t_now * 12)) * 0.35
	hare_parts.jaw.rotation = hare_base.jaw + Vector3(open, 0, 0)
	hare_parts.chest.rotation = hare_base.chest + Vector3(0, 0, sin(ph * 0.5) * 0.05 if walking else 0.0)

func lure() -> void:
	if G.lureCd > 0:
		return
	G.lureCd = 22.0
	var room: String = CAM_ROOM[G.cam]
	audio.sfx("lure", 0.7)
	if G.hare.node not in ["DOOR", "VENTDOOR"] and room != "VENT":
		G.hare.lure = room
		G.hare.lureT = 20.0
		G.hare.wait = minf(G.hare.wait, 1.0)
		if G.hare.path.size():
			G.hare.goal = room

# ------------------------------------------------------------------ sanity (příčetnost)
func hare_on_cam() -> bool:
	if not G.mon or G.app != "cam" or G.staticT > 0:
		return false
	var c = MAP.cams[G.cam]
	var cp = Vector3(c.pos[0], c.pos[1], c.pos[2])
	var lk = Vector3(c.look[0], c.look[1], c.look[2])
	var to = (hare.position + Vector3(0, 1.4, 0)) - cp
	return to.length() < 14 and (lk - cp).normalized().dot(to.normalized()) > 0.6
func hare_seen_at_office() -> bool:
	var H = G.hare
	if H.node == "DOOR" and H.path.is_empty() and not G.door and G.dl and absf(G.look - LOOK_DOOR) < 0.5 and not G.mon:
		return true
	if H.node == "VENTDOOR" and H.path.is_empty() and not G.vent and G.vl and absf(G.look - LOOK_VENT) < 0.5 and not G.mon:
		return true
	return false

func sanity_tick(dt: float) -> void:
	var drain = 0.0
	if hare_on_cam():
		drain += 3.2 + harder() * 2.0
	if hare_seen_at_office():
		drain += 5.0
	if G.door:
		drain += 0.55
	if G.vent:
		drain += 0.45
	G.heat = clampf(G.heat + ((0.03 if G.door else 0.0) + (0.025 if G.vent else 0.0) - 0.02) * dt * 10, 0, 1)
	drain += G.heat * 0.8
	var d2 = hare.position.distance_to(EYE)
	if d2 < 7 and not G.kroupa:
		drain += (7 - d2) * 0.12
	if G.night >= 3:
		drain += 0.05 * G.night
	if drain < 0.3:
		G.san += dt * 0.35
	G.san = clampf(G.san - drain * dt, 0, 100)
	var s = 1.0 - G.san / 100.0
	G.nausea = s
	# halucinace a tlukot srdce
	G.hallT -= dt
	if G.hallT <= 0:
		G.hallT = randf_range(5, 12) * (0.4 + G.san / 100.0)
		if G.san < 45:
			G.hall = 0.6
			audio.sfx("whisper", 0.25 + s * 0.4, randf_range(-1, 1))
	G.hall = maxf(0, G.hall - dt)
	if G.san < 40:
		G.heartT -= dt
		if G.heartT <= 0:
			G.heartT = 0.35 + G.san / 60.0
			audio.sfx("heart", 0.3 + s * 0.6)
	if G.san <= 0 and not DEV.god:
		collapse()

func take_pill() -> void:
	if G.pills <= 0 or G.pillT > 0:
		return
	G.pills -= 1
	G.pillT = 30.0
	G.san = minf(100, G.san + 30)
	audio.sfx("pick", 0.7)
	audio.sfx("can", 0.4)

func make_coffee() -> void:
	if G.brew > 0 or G.coffeeCd > 0:
		return
	G.brew = 6.0
	audio.sfx("drain", 0.6, 0.6)
func coffee_tick(dt: float) -> void:
	if G.brew > 0:
		G.brew -= dt
		if fmod(G.brew, 1.2) < dt:
			audio.sfx("drip", 0.4, 0.6)
		if G.brew <= 0:
			G.brew = 0.0
			G.coffeeCd = 35.0
			G.cups += 1
			G.san = minf(100, G.san + 20)
			audio.sfx("pick", 0.6)
	G.coffeeCd = maxf(0, G.coffeeCd - dt)
	(coffee_led.material_override as StandardMaterial3D).albedo_color = Color("#ffb020") if G.brew > 0 else (Color("#40ff60") if G.coffeeCd <= 0 else Color("#ff3020"))

func type_chars(n: int) -> void:
	var txt: String = REPORTS[G.night]
	if G.typed >= txt.length():
		return
	G.typed = mini(txt.length(), G.typed + n)
	audio.sfx("click", 0.25)
	if G.hare.node not in ["DOOR", "VENTDOOR"] and not hare_on_cam():
		G.san = minf(100, G.san + 0.12 * n)
	if G.typed >= txt.length():
		audio.sfx("task", 0.8)
func report_done() -> bool:
	return G.typed >= REPORTS[G.night].length()

# ------------------------------------------------------------------ konce noci
func toggle_mon() -> void:
	G.mon = not G.mon
	G.lookT = 0.0001 if G.mon else 0.0
	audio.sfx("cam" if G.mon else "click", 0.5)
func jumpscare() -> void:
	G.hare.atk = true
	S = "scare"
	scene_t = 0.0
	G.mon = false
	G.dead_by = "hare"
	G.hits = 0
	audio.stop_ambient()
	audio.sfx("scare", 1.2)
	say("H", "Mám tě.")
func collapse() -> void:
	S = "collapse"
	scene_t = 0.0
	G.mon = false
	G.dead_by = "sanity"
	audio.stop_ambient()
	audio.sfx("powerdown", 0.6)
func win_night() -> void:
	audio.stop_ambient()
	if G.night == 7:
		st_set("v3_end", true)
		audio.sfx("burnlong", 1.0)
		start_end7()
		return
	if G.night == 8:
		S = "win"
		scene_t = 0.0
		audio.sfx("chime")
		return
	if not report_done() or not sys.task_done():
		S = "fired"
		scene_t = 0.0
		audio.sfx("hangup")
		return
	S = "win"
	scene_t = 0.0
	audio.sfx("chime")
	var n: int = G.night
	st_set("v3_night", maxi(st_get("v3_night", 1), mini(7, n + 1)))
	menu_night = mini(7, n + 1)
var ex_i := 0
const EXTRAS := [
	["HOLLOW HARE", "springlock · 1980 / 2004", "Žlutý Hollow Bunny z roku 1980, Voxieho první parťák. Odstaven kvůli nestabilním pružinovým zámkům. Šest týdnů před otevřením Frights & Hides se do něj schoval bývalý hlídač D., když utekl policii. Zámky povolily. D. je uvnitř dodnes – a oblek chodí. Vždycky se dívá přímo do kamery."],
	["PAN KROUPA", "majitel Frights & Hides", "Podnikatel, který skoupil všechno, co přežilo požár herny Voxie's, a udělal z toho strašidelný dům. Fialové sako, zlatý knoflík, svazek klíčů. Na zajíce dostal nabídku od muzea. Na všechno, co mu řekneš, odpoví: haha, myslete si svoje."],
	["BROKEN VOXIE", "exponát · hlavní chodba", "Co zbylo z Voxieho po požáru v roce 2023. V sedmé noci se v něm pohne duše pana Vojtěcha a zavolá. Hollow Hare to slyší a jde do něj mlátit. Nedovol mu Voxieho zničit."],
	["SHADOW VOXIE", "duše, která není Vojtěch", "Černý opravený klasický Voxie z kostiček. Objevuje se v kanceláři nebo na kamerách. Nedívej se na něj dlouho – vyděsí tě a sebere ti kus příčetnosti."],
	["SHADOW D.", "duch bývalého hlídače", "Černá postava s bílýma očima. Duch D., který zemřel uvnitř Hollow Bunnyho. Stojí v rohu kanceláře nebo na kameře a dívá se na tebe."],
	["HOLLOW HARE (SHOŘELÝ)", "po požáru 7. noci", "Co zbylo z Hollow Hare, když Frights & Hides lehlo popelem. Zuhelnatělá látka, zčernalá kostra springlocku, zhaslé zelené oči. Uvnitř hasiči našli ostatky člověka. D. konečně odpočívá."],
	["COCOA", "exponát · vitrína", "Ohořelá hlava Cocoy ve skleněné vitríně. V roce 1997 v ní byla uvězněná duše malé Emy. Hlídač ji tehdy viděl."],
]
var ex_light: OmniLight3D
func start_extras() -> void:
	S = "extras"
	scene_t = 0.0
	ex_i = 0
func extras_tick(dt: float) -> void:
	var spot = Vector3(0, 1.2, -11.6)
	var r = 3.2
	hare.visible = ex_i == 0 or ex_i == 5
	hare_burnt(ex_i == 5)
	sys.hare_fire.emitting = false
	kroupa.root.visible = ex_i == 1
	sys.shadow_vox.visible = ex_i == 3
	sys.shadow_d.visible = ex_i == 4
	var rot = t_now * 0.4
	match ex_i:
		0:
			hare.position = Vector3(0, 0, -11.6)
			hare.rotation = Vector3(0, rot, 0)
			_hare_pose(dt, fmod(t_now, 6.0) < 3.0)
			spot = Vector3(0, 1.4, -11.6)
		1:
			kroupa.root.position = Vector3(0, 0, -11.6)
			kroupa.root.rotation.y = rot
			preload("res://scripts/people.gd").animate(kroupa, t_now, dt, false, fmod(t_now, 4.0) < 2.0)
			spot = Vector3(0, 1.1, -11.6)
		2:
			spot = Vector3(0, 1.2, -6.0)
			r = 3.6
		3:
			sys.shadow_vox.position = Vector3(0, 0, -11.6)
			sys.shadow_vox.rotation.y = rot
			spot = Vector3(0, 1.3, -11.6)
		4:
			sys.shadow_d.position = Vector3(0, 0, -11.6)
			sys.shadow_d.rotation.y = rot
			spot = Vector3(0, 1.1, -11.6)
		5:
			hare.position = Vector3(0, 0, -11.6)
			hare.rotation = Vector3(0, rot, 0)
			_hare_pose(dt, false)
			spot = Vector3(0, 1.4, -11.6)
		6:
			spot = Vector3(8, 1.3, 3)
			r = 1.6
	cam.position = spot + Vector3(sin(0.5) * r, 0.45, cos(0.5) * r)
	cam.look_at(spot)
	if ex_light == null:
		ex_light = OmniLight3D.new()
		ex_light.light_color = Color("#d0ffd8")
		ex_light.omni_range = 6
		add_child(ex_light)
	ex_light.visible = true
	ex_light.light_energy = 2.2
	ex_light.position = cam.position + Vector3(0.3, 0.8, -0.4)

func start_custom() -> void:
	S = "custom"
	scene_t = 0.0

func to_menu() -> void:
	S = "menu"
	scene_t = 0.0
	G = null
	hare.rotation = Vector3.ZERO
	Q.clear()
	line = null
	kroupa.root.visible = false
	sys.shadow_vox.visible = false
	sys.shadow_d.visible = false
	sys.flash.light_energy = 0.0
	if ex_light:
		ex_light.visible = false
	sys.hare_fire.emitting = false
	hare_burnt(false)
	hare.rotation = Vector3.ZERO
	for ep in end_parts:
		ep[0].queue_free()
	end_parts = []
	if sys.vox_node:
		sys.vox_node.rotation = sys.vox_base
	for c in sys.fire_root.get_children():
		c.queue_free()
	sys.fire_lights = []
	env.ambient_light_color = Color("#4a4458")
	audio.stop_ambient()
	audio.start_menu_song()

# ==================================================================
func _process(delta: float) -> void:
	var dt = minf(delta, 0.1)
	t_now += dt
	scene_t += dt
	match S:
		"tour": tour_tick(dt)
		"arrive": arrive_tick(dt)
		"play": play_tick(dt)
		"scare", "collapse": tick_lines(dt)
		"extras": extras_tick(dt)
		"end7": end7_tick(dt)
	render(dt)
	hud.queue_redraw()

func render(dt: float) -> void:
	var pm: ShaderMaterial = post.material
	pm.set_shader_parameter("uT", t_now)
	var sway = 0.0
	var dbl = 0.0
	var tint = 0.0
	var vig = 0.75
	var glitch = 0.0
	feed_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	match S:
		"menu", "loading":
			# pomalý průlet atrakcí
			var a = t_now * 0.05
			cam.position = Vector3(sin(a) * 1.2, 1.7, -2.0 + cos(a) * 3.0)
			cam.look_at(Vector3(0, 1.0, -6.0))
			hare.visible = true
			hare.position = NODES.BACK
			hare.rotation = Vector3.ZERO
			glitch = 0.08 if randf() < 0.03 else 0.0
		"tour", "arrive":
			hare.visible = true
			hare.position = NODES.BACK
			hare.rotation = Vector3.ZERO
			_hare_pose(dt, false)
		"intro", "win", "fired", "dead":
			cam.position = EYE
			cam.rotation = Vector3.ZERO
		"end7":
			vig = 0.9
		"play" when G.roam:
			sys.roam_cam(dt)
			var s2: float = G.nausea
			sway = pow(s2, 2.0) * 0.012
			dbl = maxf(0, s2 - 0.45) * 0.03
			tint = maxf(0, s2 - 0.55) * 0.9
			vig = 0.85 + s2 * 0.5
			glitch = G.hall * 0.6
			if G.shake > 0:
				cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * G.shake * 0.15
		"play":
			sys.flash.light_energy = 0.0
			var s: float = G.nausea
			cam.position = EYE + Vector3(sin(t_now * 0.9) * 0.03 * s, sin(t_now * 1.3) * 0.02 * s, 0)
			cam.rotation = Vector3(-0.08 * G.monA + sin(t_now * 0.6) * 0.03 * s * s, G.look * (1 - G.monA), sin(t_now * 0.7) * 0.09 * pow(s, 1.5))
			if G.monA > 0:
				cam.position = cam.position.lerp(Vector3(0, 1.19, 7.7), ease_io(G.monA))
			sway = pow(s, 2.0) * 0.012
			dbl = maxf(0, s - 0.45) * 0.03
			tint = maxf(0, s - 0.55) * 0.9
			vig = 0.75 + s * 0.5
			glitch = G.hall * 0.6 + (0.3 if G.staticT > 0 else 0.0)
			desk_lamp.light_energy = 1.1 * (0.85 + 0.15 * sin(t_now * 23)) if randf() > 0.01 else 0.2
			screen_mat.emission_energy_multiplier = 0.9
			if G.mon and G.app == "cam":
				var c = MAP.cams[G.cam]
				var cp = Vector3(c.pos[0], c.pos[1], c.pos[2])
				var lk = Vector3(c.look[0], c.look[1], c.look[2])
				feed_cam.global_position = cp + (lk - cp).normalized() * 0.3
				feed_cam.look_at(lk)
				feed_cam.rotate_y(sin(t_now * 0.25) * 0.12)
				feed_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			red_light.light_energy = 0.0
			if G.shake > 0:
				cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * G.shake * 0.12
			if G.blackout:
				screen_mat.emission_energy_multiplier = 0.0
		"scare":
			_render_scare(dt)
			glitch = 0.4 if scene_t < 0.7 else 0.0
			tint = 0.0
			vig = 1.0 + minf(scene_t / 5, 0.8)
		"collapse":
			var k = clampf(scene_t / 2.4, 0, 1)
			var e = ease_io(k)
			cam.position = EYE.lerp(Vector3(0.5, 0.25, 9.0), e)
			cam.rotation = Vector3(-0.08 - e * 0.25 + sin(t_now * 2) * 0.05, 0.3 * e, e * 1.35 + sin(t_now * 0.8) * 0.1)
			sway = 0.02 * (1 - k * 0.5)
			dbl = 0.03
			tint = 0.8
			vig = 1.2 + k
	pm.set_shader_parameter("uVig", vig)
	pm.set_shader_parameter("uGlitch", glitch)
	pm.set_shader_parameter("uSway", sway)
	pm.set_shader_parameter("uDouble", dbl)
	pm.set_shader_parameter("uSick", tint)
	pm.set_shader_parameter("uGrain", 0.05)

## zajíc vyrazí, srazí hlídače na zem a mlátí ho (v kanceláři i při chůzi po budově)
var SO := Vector3.ZERO
var SF := Vector3.FORWARD
func _scare_setup() -> void:
	if G.roam:
		SO = Vector3(G.rp.x, 1.6, G.rp.z)
		var d = hare.position - SO
		d.y = 0
		SF = d.normalized() if d.length() > 0.1 else Vector3(-sin(G.rp.yaw), 0, -cos(G.rp.yaw))
	else:
		SO = EYE
		SF = (Vector3(-1, 0, -0.2) if G.hare.node != "VENTDOOR" else Vector3(1, 0, -0.3)).normalized()
func _render_scare(dt: float) -> void:
	var t = scene_t
	if t < dt * 1.5:
		_scare_setup()
	var side = Vector3(SF.z, 0, -SF.x)
	var ground = Vector3(SO.x, 0, SO.z)
	var floor_p = ground - SF * 0.8 + Vector3(0, 0.22, 0)
	hare.visible = true
	hare.rotation.x = 0
	if t < 0.55:
		var k = ease_io(t / 0.55)
		hare.position = (ground + SF * 2.6).lerp(ground + SF * 1.05, k)
		hare.look_at(ground, Vector3.UP, true)
		cam.position = SO
		cam.look_at(hare.position + Vector3(0, 1.9, 0))
		hare_parts.jaw.rotation = hare_base.jaw + Vector3(0.6, 0, 0)
		hare_parts.arm_L.rotation = hare_base.arm_L + Vector3(-1.8, 0, 0)
		hare_parts.arm_R.rotation = hare_base.arm_R + Vector3(-1.8, 0, 0)
	elif t < 1.4:
		var k = ease_io((t - 0.55) / 0.85)
		cam.position = SO.lerp(floor_p, k) + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.06 * (1 - k)
		hare.position = (ground + SF * 1.05).lerp(ground + SF * 0.45, k)
		hare.look_at(Vector3(cam.position.x, 0, cam.position.z), Vector3.UP, true)
		cam.look_at(hare.position + Vector3(0, 1.8, 0))
		cam.rotate_object_local(Vector3.FORWARD, k * 0.5)
		if t - dt < 1.2 and t >= 1.2:
			audio.sfx("hurt", 1.0)
			audio.sfx("clunk", 1.0)
	else:
		var bt = t - 1.4
		var cyc = fmod(bt, 0.55) / 0.55
		var n = int(bt / 0.55)
		hare.position = ground + SF * 0.45
		hare.look_at(Vector3(floor_p.x, 0, floor_p.z), Vector3.UP, true)
		hare_parts.chest.rotation = hare_base.chest + Vector3(0.55, 0, 0)
		hare_parts.head.rotation = hare_base.head + Vector3(0.5, randf_range(-0.1, 0.1), 0)
		var hit_arm = "arm_R" if n % 2 == 0 else "arm_L"
		var other = "arm_L" if hit_arm == "arm_R" else "arm_R"
		var a = -2.8 + ease_io(clampf(cyc / 0.35, 0, 1)) * 2.4
		hare_parts[hit_arm].rotation = hare_base[hit_arm] + Vector3(a, 0, 0)
		hare_parts[other].rotation = hare_base[other] + Vector3(-2.6, 0, 0)
		hare_parts.jaw.rotation = hare_base.jaw + Vector3(0.4 + sin(t_now * 20) * 0.1, 0, 0)
		var shake = maxf(0, 0.3 - absf(cyc - 0.35)) * 0.6
		cam.position = floor_p + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shake * 0.4
		cam.look_at(hare.position + Vector3(0, 1.75, 0))
		cam.rotate_object_local(Vector3.FORWARD, 0.5 + randf_range(-1, 1) * shake)
		if bt < 4.4 and fmod(bt - dt, 0.55) / 0.55 < 0.35 and cyc >= 0.35:
			G.hits += 1
			G.hurtT = 0.25
			audio.sfx("hurt", 0.9)
			audio.sfx("clunk", 1.0, randf_range(-0.3, 0.3))
		red_light.light_energy = 2.5 * maxf(0, G.hurtT) * 4
		red_light.position = cam.position + Vector3(0, 0.5, 0)
	G.hurtT = maxf(0, G.hurtT - dt)
	cam.fov = 80
	if t > 6.6:
		cam.fov = 72
		S = "dead"
		scene_t = 0.0
		hare.visible = false

## ohořelá verze Hollow Hare (uhel, popraskaná látka, zhaslé oči)
var hare_mats := {}
func hare_burnt(on: bool, k := 1.0) -> void:
	for mi in hare.find_children("*", "MeshInstance3D", true, false):
		if not hare_mats.has(mi):
			hare_mats[mi] = mi.material_override
		var orig: StandardMaterial3D = hare_mats[mi]
		if not on:
			mi.material_override = orig
			continue
		var m: StandardMaterial3D = orig.duplicate()
		var c = orig.albedo_color
		var burnt = Color("#0e0b09").lerp(Color("#3a2a1c"), randf() * 0.35)
		if orig.metallic > 0.5:
			burnt = Color("#2a2622")
		m.albedo_color = c.lerp(burnt, k)
		m.roughness = 1.0
		m.metallic = orig.metallic * 0.3
		if orig.emission_enabled:
			m.emission = Color("#40ff60").lerp(Color("#000000"), k)
			m.emission_energy_multiplier = orig.emission_energy_multiplier * (1.0 - k)
		elif randf() < 0.12 * k:
			# doutnající uhlíky
			m.emission_enabled = true
			m.emission = Color("#ff5010")
			m.emission_energy_multiplier = 1.2
		mi.material_override = m

## 7. noc – konec: Voxie poděkuje a rozpadne se, Hollow Hare shoří, budova se hroutí
var end_parts := []
func _end7_fire_at(c: Vector3, ext: Vector3) -> void:
	var f = sys._fire(ext, 90)
	f.position = c
	sys.fire_root.add_child(f)
	var l = OmniLight3D.new()
	l.light_color = Color("#ff6a1a")
	l.light_energy = 3
	l.omni_range = 10
	l.position = c + Vector3(0, 1.5, 0)
	sys.fire_root.add_child(l)
	sys.fire_lights.append(l)
func start_end7() -> void:
	S = "end7"
	scene_t = 0.0
	Q.clear()
	line = null
	G.mon = false
	G.roam = false
	for c in sys.fire_root.get_children():
		c.queue_free()
	sys.fire_lights = []
	_end7_fire_at(Vector3(-2.2, 0.3, -3.5), Vector3(0.6, 0.2, 2.0))
	_end7_fire_at(Vector3(2.3, 0.3, -1.0), Vector3(0.5, 0.2, 2.0))
	sys.hare_fire.emitting = true
	hare.visible = true
	hare.rotation = Vector3(0, PI * 0.85, 0)
	hare.position = Vector3(-1.1, 0, -1.2)
	hare_burnt(false)
	end_parts = []
	G.task.kind = ""
func end7_tick(dt: float) -> void:
	var t = scene_t
	tick_lines(dt)
	for l in sys.fire_lights:
		l.light_energy = 2.6 + sin(t_now * 17 + l.position.x) * 0.7 + randf() * 0.6
	var vn: Node3D = sys.vox_node
	if t < 9.0:
		# Broken Voxie: duše pana Vojtěcha děkuje a oblek se rozpadá
		cam.position = Vector3(1.7, 1.55, -1.9) + Vector3(sin(t * 0.3) * 0.1, 0, 0)
		cam.look_at(Vector3(0, 1.3, -6.0))
		hare.visible = false
		if t > 0.8 and t - dt <= 0.8:
			say("V", "Děkuji, žes mě nenechal jako duši v tomhle obleku.")
		if vn and t < 4.4:
			vn.rotation = sys.vox_base + Vector3(sin(t * 13) * 0.02, sin(t * 7) * 0.05, 0)
		if vn and t > 4.6 and t - dt <= 4.6:
			var k = 0
			for nm in ["head", "arm_upper_L", "arm_upper_R_stump", "jaw_hanging", "ear_L", "candle_bracket"]:
				var part: Node3D = vn.find_child(nm, true, false)
				if part == null:
					continue
				var gt = part.global_transform
				part.get_parent().remove_child(part)
				add_child(part)
				part.global_transform = gt
				end_parts.append([part, gt])
				var tw = create_tween()
				tw.tween_interval(k * 0.35)
				var dest = part.global_position + Vector3(randf_range(-0.7, 0.7), 0, randf_range(0.3, 1.2))
				dest.y = 0.36 if absf(dest.x) < 1.3 and dest.z < -5.0 else 0.08
				tw.tween_property(part, "global_position", dest, 0.55).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
				tw.parallel().tween_property(part, "rotation", part.rotation + Vector3(randf_range(-1.5, 1.5), randf_range(-1, 1), randf_range(-1.5, 1.5)), 0.55)
				tw.tween_callback(func(): audio.sfx("clunk", 0.6))
				k += 1
			audio.sfx("servo", 0.8)
		if vn and t > 7.0:
			var e = ease_io(clampf((t - 7.0) / 1.2, 0, 1))
			vn.rotation = sys.vox_base + Vector3(-e * 1.45, 0, e * 0.2)
			if t - dt <= 8.2 and t > 8.2:
				audio.sfx("clunk", 1.0)
				G.shake = 0.8
	elif t < 18.0:
		# Hollow Hare hoří, potácí se, padá a umírá
		var ht = t - 9.0
		hare.visible = true
		cam.position = Vector3(0.6, 1.5, 3.2)
		cam.look_at(Vector3(-1.0, 1.1 - clampf((ht - 4.5) / 1.5, 0, 1) * 0.6, -1.4))
		if ht < 4.5:
			hare.position = Vector3(-1.1 + sin(ht * 2) * 0.25, 0, -1.2 + ht * 0.12)
			hare.rotation = Vector3(sin(ht * 5) * 0.08, PI * 0.85 + sin(ht * 3) * 0.4, sin(ht * 4) * 0.1)
			hare_parts.arm_L.rotation = hare_base.arm_L + Vector3(-1.6 + sin(ht * 9) * 0.8, 0, 0)
			hare_parts.arm_R.rotation = hare_base.arm_R + Vector3(-1.8 + cos(ht * 8) * 0.8, 0, 0)
			hare_parts.jaw.rotation = hare_base.jaw + Vector3(0.5 + sin(ht * 15) * 0.15, 0, 0)
			hare_parts.head.rotation = hare_base.head + Vector3(-0.3 + sin(ht * 6) * 0.2, sin(ht * 4) * 0.4, 0)
			if ht > 0.6 and ht - dt <= 0.6:
				say("H", "Hoří to! Ne! Ne!")
			if fmod(ht, 0.7) < dt:
				audio.sfx("hurt", 0.5)
		else:
			var e = ease_io(clampf((ht - 4.5) / 1.3, 0, 1))
			hare.rotation = Vector3(-e * PI / 2, PI * 0.85, 0)
			hare.position.y = e * 0.3
			if ht - dt < 5.8 and ht >= 5.8:
				audio.sfx("clunk", 1.0)
				audio.sfx("powerdown", 0.7)
				G.shake = 0.9
			hare_burnt(true, clampf((ht - 5.0) / 3.0, 0, 1))
			if ht > 7.5:
				sys.hare_fire.emitting = false
	else:
		if t - dt <= 18.0:
			for c in sys.fire_root.get_children():
				c.queue_free()
			sys.fire_lights = []
			hare.visible = false
		_render_end7_out(t - 18.0)
	if G.shake > 0:
		G.shake = maxf(0, G.shake - dt)
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * G.shake * 0.1
func _render_end7_out(t: float) -> void:
	cam.position = Vector3(-6.0 + t * 0.05, 1.7, 21.5)
	cam.look_at(Vector3(-8, 2.8, 9.0))
	if sys.fire_root.get_child_count() < 8:
		for i in 6:
			var f = sys._fire(Vector3(2.5, 0.6, 0.4), 80)
			f.position = Vector3(-16 + i * 5.0, 4.6, 10.4)
			sys.fire_root.add_child(f)
		var l = OmniLight3D.new()
		l.light_color = Color("#ff6a1a")
		l.light_energy = 4
		l.omni_range = 22
		l.position = Vector3(-6, 6, 13)
		sys.fire_root.add_child(l)
		sys.fire_lights.append(l)
	for l in sys.fire_lights:
		l.light_energy = 3.0 + randf() * 1.5
