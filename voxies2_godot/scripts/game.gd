extends Node3D
## Night at Voxie's 2 Remastered – Godot port (logika 1:1 z webové verze „NewVoxie")
## + inventář, prohlídka Cocoiny hlavy, fotky pro Voxieho, díra přes toalety, zasypané boční vchody, skok,
## + úvodní scéna: hráč poprvé zapíná VOXIE-CAM.

const HOUR := 60.0
const LK := 0.16          # převod intenzit světel z three.js
var D: Dictionary         # data z Remasteru
var RZ := -200.0
var RROOMS: Dictionary
var DOORS: Array
var BZ: Array
var PROPS: Array
var ADJ := {}
var CAMS: Dictionary
var ROUTE_L := ["1A", "1B", "2", "5", "8", "HOLE"]
var ROUTE_R := ["1A", "1B", "3", "4", "HOLE"]
var ROUTE: Array = ROUTE_L
var baked := false
var EYE := Vector3.ZERO
var desk_parts := []
var crt_node: Node3D
var MON := Vector3.ZERO

var S := "loading"
var scene_t := 0.0
var G = null
var t_now := 0.0
var frame_dt := 1.0 / 60
var speech = null
var store := {}
var CUST := {"v": 10, "c": 10}
var DEV := {"on": false, "panel": false, "god": false, "freeze": false, "msg": "", "msgT": 0.0}
var SV := {"call": "none", "cocGone": false, "fin": ""}
var menu_night := 1
var news_end := 1
var fin_pick = null
var home_reply = null
var keys := {}

# 3D
var env: Environment
var cam: Camera3D
var feed_cam: Camera3D
var feed_vp: SubViewport
var feed_light: OmniLight3D
var show_cam: Camera3D
var building: Node3D
var home: Node3D
var exit_g: Node3D
var flash: SpotLight3D
var tube: SpotLight3D
var emergency: OmniLight3D
var monitor_light: OmniLight3D
var spark_light: OmniLight3D
var red_light: OmniLight3D
var show_light: SpotLight3D
var fire_light: OmniLight3D
var b_lights := []        # [light, kind, base]
var stage_mats := []
var home_door: Node3D
var home_phone_mat: StandardMaterial3D
var home_pl: OmniLight3D
var crt_canvas: Node2D
var torch: Node3D
var torch_lens: StandardMaterial3D
var item_node: Node3D
var item_mat: StandardMaterial3D
var item_light: OmniLight3D
var post: ColorRect

# postavy
var HB: Node3D
var HB_show: Node3D
var coc_light: OmniLight3D
var VOX: Node3D
var vox_model: Node3D
var vox_anim: AnimationPlayer
var vox_red: Array = []
var COC: Node3D
var coc_model: Node3D
var coc_anim: AnimationPlayer
var coc_mat: ShaderMaterial
var coc_eyes: Array = []
var coc_eye_mat: StandardMaterial3D
var coc_sk: Skeleton3D
var coc_bones := []
var coc_eye_balls := []
var coc_vis := {"van": null, "born": null, "force": null, "scareT": 0.0}
var egg_head: Node3D
var can_m: Node3D
var can_hand: Node3D
var draw3d: MeshInstance3D
var photo_nodes := []
var hand: Node3D
var insp_light: OmniLight3D
var ghosts := []
var fl_mm: MultiMeshInstance3D
var fl_pos := PackedVector3Array()
var fl_vel := PackedFloat32Array()
var out_ground: MeshInstance3D

var hud
var scenes
var audio

# ====================================================================
func _ready() -> void:
	D = JSON.parse_string(FileAccess.get_file_as_string("res://data/data.json"))
	RZ = D.RZ
	RROOMS = D.RROOMS
	DOORS = D.DOORS
	BZ = D.BZ
	PROPS = D.PROPS
	CAMS = D.CAMS
	# finále: kamera jde dírou přes toalety (boční vchody jsou zasypané), cestou Hollow Bunny
	D.FIN_CAM[0] = [0, [0, 1.6, -0.9], [0, 1.5, -6]]
	D.FIN_CAM[1] = [3, [0, 1.6, -4.2], [0, 1.5, -10]]
	D.FIN_CAM[2] = [8, [0, 1.6, -11.4], [-3, 1.4, -15]]
	D.FIN_SUB.append([36.4, "", "V rohu pizzerie stál žlutý králík. Hollow Bunny."])
	D.FIN_SUB.append([38.6, "", "Springlock z roku osmdesát, odstavený kvůli zámkům… a přesto za tebou otočil hlavu."])
	D.FIN_SUB.sort_custom(func(a, b): return a[0] < b[0])
	D.BIOS.append({"name": "HOLLOW BUNNY", "sub": "springlock animatronik · 1980 · kostičkový remodel (nepoškozený)", "col": "#ffe46b", "text": "Žlutý králík z kostiček. Springlock animatronik stejně jako Voxie: chodil sám, ale dal se i obléknout jako kostým. V roce 1980 ho odstavili kvůli nestabilním pružinovým zámkům a zavřeli do skladu. Pan Vojtěch ho chtěl v roce 1997 vyndat na Eminu oslavu. Na fotkách z té noci stojí sám v rohu herny. Po požáru ho hasiči nenašli."})
	_load_store()
	menu_night = st_get("v2_night", 1)
	CUST = st_get("v2r_cust", CUST)
	DEV.on = st_get("v2_dev", false)
	SV.cocGone = st_get("v2_cocgone", false)
	audio = preload("res://scripts/audio.gd").new()
	audio.game = self
	add_child(audio)
	_adj()
	_build()
	scenes = preload("res://scripts/scenes.gd").new()
	scenes.game = self
	add_child(scenes)
	scenes.build()
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
	scene_t = 0.0
	audio.start_menu_song()
	if "--makebunny" in OS.get_cmdline_user_args():
		var doc = GLTFDocument.new()
		var st = GLTFState.new()
		HB_show.visible = true
		doc.append_from_scene(HB_show, st)
		print("BUNNY ", doc.write_to_filesystem(st, "res://models/hollow_bunny_unwithered.glb"))
		get_tree().quit()
		return
	if "--makemap" in OS.get_cmdline_user_args():
		make_map()
		return
	if "--shots2" in OS.get_cmdline_user_args():
		preload("res://scripts/shots.gd").run2(self)
	elif "--shots" in OS.get_cmdline_user_args():
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
	if FileAccess.file_exists("user://v2.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("user://v2.json"))
		if d is Dictionary:
			store = d
func st_get(k: String, d):
	return store.get(k, d)
func st_set(k: String, v) -> void:
	store[k] = v
	var f = FileAccess.open("user://v2.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(store))

static func ease_io(t: float) -> float:
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
static func pick(a: Array):
	return a[randi() % a.size()]
static func v3(a) -> Vector3:
	return Vector3(a[0], a[1], a[2])
func later(sec: float, f: Callable) -> void:
	get_tree().create_timer(sec).timeout.connect(f)

# ---------- mapa a průchody ----------
static func in_r(r, x: float, z: float, m: float) -> bool:
	return x > r.x0 + m and x < r.x1 - m and z > r.z0 + m and z < r.z1 - m
func walkable(x: float, z: float) -> bool:
	for id in RROOMS:
		if in_r(RROOMS[id], x, z, 0.3):
			return true
	for d in DOORS:
		if in_r(d.zone, x, z, 0):
			return true
	return false
func walk_m(x: float, z: float) -> bool:
	if walkable(x, z):
		return true
	for d in BZ:
		if in_r(d.zone, x, z, 0):
			return true
	return false
func room_at(x: float, z: float):
	for id in RROOMS:
		if in_r(RROOMS[id], x, z, 0):
			return id
	return null
func blocked(x: float, z: float) -> bool:
	for b in PROPS:
		if x > b[0] and x < b[1] and z > b[2] and z < b[3]:
			return true
	return false
func free_at(x: float, z: float) -> bool:
	return walkable(x, z) and not blocked(x, z)

func _adj() -> void:
	for id in RROOMS:
		ADJ[id] = []
	var outd = {"n": [0, -0.8], "s": [0, 0.8], "w": [-0.8, 0], "e": [0.8, 0]}
	for d in DOORS:
		var o = room_at(d.x + outd[d.side][0], d.z + outd[d.side][1])
		if o != null and o != d.id:
			var dup = false
			for e in ADJ[d.id]:
				if e.to == o:
					dup = true
			if not dup:
				ADJ[d.id].append({"to": o, "p": [d.x, d.z]})
	# z kanceláře se teď chodí jen dírou přes toalety
	EYE = Vector3(0, 1.35, RROOMS.TY.cz + 1.9)
	MON = Vector3(0, 1.12, RROOMS.TY.cz + 0.5)

func path_to(from, to: String) -> Array:
	var T = RROOMS[to]
	if from == null or from == to:
		return [[T.cx, T.cz]]
	var prev = {from: null}
	var q = [from]
	while q.size():
		var c = q.pop_front()
		if c == to:
			break
		for e in ADJ[c]:
			if not prev.has(e.to):
				prev[e.to] = {"c": c, "p": e.p}
				q.append(e.to)
	if not prev.has(to):
		return [[T.cx, T.cz]]
	var pts = [[T.cx, T.cz]]
	var c = to
	while prev[c] != null:
		pts.push_front(prev[c].p)
		c = prev[c].c
	return pts

# ====================================================================
#  STAVBA SCÉNY
# ====================================================================
func _mat(c, rough := 0.82, metal := 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c) if c is String else c
	m.roughness = rough
	m.metallic = metal
	return m
func _box(sz: Vector3, m: Material, p: Vector3, parent: Node3D = null) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.material_override = m
	mi.position = p
	(parent if parent else self).add_child(mi)
	return mi
func _omni(c, e: float, r: float, p: Vector3, parent: Node3D = null) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.light_color = Color(c) if c is String else c
	l.light_energy = e * LK
	l.omni_range = r
	l.position = p
	(parent if parent else self).add_child(l)
	return l
func _spot(c, e: float, r: float, ang: float, p: Vector3, tgt: Vector3, parent: Node3D = null) -> SpotLight3D:
	var l = SpotLight3D.new()
	l.light_color = Color(c) if c is String else c
	l.light_energy = e * LK
	l.spot_range = r
	l.spot_angle = rad_to_deg(ang)
	(parent if parent else self).add_child(l)
	l.look_at_from_position(p, tgt)
	return l
func _aabb(n: Node) -> AABB:
	var res = AABB()
	var first = true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		if first:
			res = a
			first = false
		else:
			res = res.merge(a)
	return res

func _build() -> void:
	var we = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#020101")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#1c2a3c")
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("#020101")
	env.fog_depth_begin = 4.0
	env.fog_depth_end = 18.0
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	env.glow_hdr_threshold = 0.82
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	add_child(we)
	# vyhořelá budova (export z Remasteru, včetně suti, stropu, kabelů a kouře)
	# celá zbořená mapa jako jeden GLB (vyrobený nástrojem --makemap z exportu Remasteru + úpravy kanceláře)
	baked = ResourceLoader.exists("res://models/broken_map.glb") and not ("--makemap" in OS.get_cmdline_user_args())
	building = load("res://models/broken_map.glb" if baked else "res://models/building.glb").instantiate()
	add_child(building)
	for mi in building.find_children("StageGlow*", "MeshInstance3D", true, false):
		var m = (mi as MeshInstance3D).get_active_material(0)
		if m is StandardMaterial3D:
			var own: StandardMaterial3D = m.duplicate()
			(mi as MeshInstance3D).material_override = own
			stage_mats.append([own, own.albedo_color * 18.0, randf() * 9])
	if not baked:
		_cut_office_walls()
	for L in D.lights:
		var l: Light3D
		if L.type == "spot":
			l = _spot("#" + L.col, L.I, L.d, L.angle, v3(L.p), v3(L.t))
		else:
			l = _omni("#" + L.col, L.I, L.d, v3(L.p))
		b_lights.append([l, L.kind, L.I])
	exit_g = load("res://models/exit.glb").instantiate()
	add_child(exit_g)
	exit_g.visible = false
	_omni("#dfe8ff", 6, 12, Vector3(-16, 1.6, RROOMS["7"].z1 - 1.2), exit_g)
	# kancelář: stůl s počítačem na baterii
	_build_office()
	# kamery
	cam = Camera3D.new()
	cam.fov = 70
	cam.near = 0.05
	cam.far = 60
	cam.rotation_order = EULER_ORDER_YXZ
	add_child(cam)
	flash = SpotLight3D.new()
	flash.light_color = Color("#fff0d0")
	flash.spot_range = 20
	flash.spot_angle = rad_to_deg(0.52)
	flash.spot_angle_attenuation = 0.55
	flash.shadow_enabled = true
	add_child(flash)
	tube = _spot("#b8d0ff", 5, 9, 0.9, EYE + Vector3(0, 1.75, -1.4), EYE + Vector3(0, -1.35, -3.6))
	tube.shadow_enabled = true
	emergency = _omni("#ff1a0a", 0, 12, EYE + Vector3(-3.4, 1.65, -4.6))
	spark_light = _omni("#ffc060", 0, 4, Vector3.ZERO)
	red_light = _omni("#ff1010", 0, 6, Vector3.ZERO)
	fire_light = _omni("#ff6a20", 0, 45, Vector3.ZERO)
	# kamera pro záběry VOXIE-CAM (vlastní viewport ve stejném světě)
	feed_vp = SubViewport.new()
	feed_vp.size = Vector2i(640, 400)
	feed_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(feed_vp)
	feed_vp.world_3d = get_viewport().world_3d
	feed_cam = Camera3D.new()
	feed_cam.fov = 62
	feed_cam.far = 40
	feed_vp.add_child(feed_cam)
	var fl = OmniLight3D.new()
	fl.light_color = Color("#a0ffb0")
	fl.omni_range = 14
	fl.light_energy = 0.0
	feed_cam.add_child(fl)
	feed_light = fl
	# Extras pódium
	show_cam = Camera3D.new()
	show_cam.fov = 42
	add_child(show_cam)
	show_cam.look_at_from_position(Vector3(2.4, 1.4, 46.4), Vector3(1.5, 1.05, 40))
	show_light = _spot("#ffd0b0", 0, 14, 0.6, Vector3(1, 5, 43), Vector3(0, 1, 40))
	var disc = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 1.6
	cy.bottom_radius = 1.7
	cy.height = 0.3
	disc.mesh = cy
	disc.material_override = _mat("#1a0a0a")
	disc.position = Vector3(0, 0.15, 40)
	add_child(disc)
	var ring = MeshInstance3D.new()
	var tor = TorusMesh.new()
	tor.inner_radius = 1.61
	tor.outer_radius = 1.69
	ring.mesh = tor
	var rm = StandardMaterial3D.new()
	rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.albedo_color = Color("#ff2020")
	ring.material_override = rm
	ring.position = Vector3(0, 0.3, 40)
	add_child(ring)
	# domov (scénka před 1. nocí)
	home = load("res://models/home.glb").instantiate()
	home.position = Vector3(200, 0, 0)
	add_child(home)
	home.visible = false
	home_door = home.find_child("HomeDoor", true, false)
	var ph = home.find_child("HomePhone", true, false)
	if ph:
		var pm = ph.find_children("*", "MeshInstance3D", true, false)
		var mi: MeshInstance3D = ph if ph is MeshInstance3D else (pm[0] if pm.size() else null)
		if mi:
			home_phone_mat = StandardMaterial3D.new()
			home_phone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mi.material_override = home_phone_mat
	for L in D.homeLights:
		if L.type == "hemi":
			continue
		var l: Light3D
		if L.type == "spot":
			l = _spot("#" + L.col, L.I, L.d if L.d > 0 else 20.0, L.angle, v3(L.p), v3(L.t), home)
		else:
			l = _omni("#" + L.col, L.I, L.d if L.d > 0 else 20.0, v3(L.p), home)
		if absf(L.p[0] - 1.7) < 0.01 and absf(L.p[2] + 1.8) < 0.01:
			home_pl = l
	_build_chars()
	HB = preload("res://scripts/hollow.gd").make(true)
	add_child(HB)
	HB.visible = false
	HB_show = preload("res://scripts/hollow.gd").make(false)
	add_child(HB_show)
	HB_show.visible = false
	coc_light = _omni("#b080ff", 0, 4, Vector3(0, 1.4, 0.6), COC)
	_omni("#ffe8a0", 2.5, 3.5, Vector3(0, 2.2, 1.2), HB)
	_build_items()

## díra ve zdi kanceláře do toalet; boční vchody kanceláře jsou zasypané (suť je z exportu)
func _cut_office_walls() -> void:
	var T = RROOMS.TY
	for mi in building.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		var c = a.get_center()
		# tenké zdi na rozhraní kancelář/toalety, které zasahují do díry x∈(-1,1)
		if absf(c.z - (T.z0 - 0.02)) < 0.3 and a.size.z < 0.5 and a.size.y > 1.5 and a.position.x < 1.0 and a.end.x > -1.0:
			(mi as MeshInstance3D).visible = false
	var wall = _mat("#2a2230", 0.95)
	for z in [T.z0, T.z0 - 0.05]:
		_box(Vector3(3.0, 3.2, 0.2), wall, Vector3(-2.5, 1.6, z), building)
		_box(Vector3(3.0, 3.2, 0.2), wall, Vector3(2.5, 1.6, z), building)
		_box(Vector3(2.0, 1.1, 0.2), wall, Vector3(0, 2.65, z), building)
	# rozlámané okraje díry
	for i in 10:
		var r = _box(Vector3(randf_range(.15, .4), randf_range(.15, .4), 0.3), wall, Vector3(randf_range(-1.1, 1.1), randf_range(0.1, 2.2), T.z0), building)
		if absf(r.position.x) < 0.75 and r.position.y < 1.9:
			r.position.x = signf(r.position.x + 0.001) * 1.0
		r.rotation.z = randf() * 3
	# zasypané boční vchody: sutí plné otvory
	for x in [T.x0, T.x1]:
		_box(Vector3(0.3, 2.2, 2.2), _mat("#141210", 1.0), Vector3(x, 1.1, T.cz), building)

func _build_office() -> void:
	if not baked:
		_office_shell()
	_office_screen()
	# kusy stolu a počítače, které při Voxieho lekačce spadnou
	desk_parts = []
	for mi in building.find_children("*", "MeshInstance3D", true, false):
		var aa: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		var cc = aa.get_center()
		if absf(cc.x) < 2.0 and cc.y < 1.7 and cc.z > EYE.z - 2.1 and cc.z < EYE.z - 0.6 and aa.size.x < 3.6 and aa.size.y < 1.2:
			desk_parts.append([mi, (mi as Node3D).global_transform])
	desk_parts.append([crt_node, crt_node.global_transform])

func _office_shell() -> void:
	# starý monitor z 1. dílu na stole nahradí nový (ten se zapínací animací)
	for mi in building.find_children("*", "MeshInstance3D", true, false):
		var aa: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		var cc = aa.get_center()
		if absf(cc.x) < 0.3 and cc.y > 0.95 and cc.y < 1.3 and absf(cc.z - (EYE.z - 1.5)) < 0.3 and aa.size.x < 0.9:
			(mi as MeshInstance3D).visible = false
	var shell = _mat("#d8d0b8", 0.6)
	_box(Vector3(0.72, 0.56, 0.5), shell, MON + Vector3(0, -0.01, -0.3), building)
	_box(Vector3(0.5, 0.42, 0.25), shell, MON + Vector3(0, 0.0, -0.62), building)
	_box(Vector3(0.3, 0.05, 0.28), shell, MON + Vector3(0, -0.29, -0.3), building)
	_box(Vector3(0.05, 0.03, 0.01), _mat("#40ff60"), MON + Vector3(0.27, -0.24, -0.04), building)

func _office_screen() -> void:
	var sv = SubViewport.new()
	sv.size = Vector2i(256, 192)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	crt_canvas = preload("res://scripts/crt.gd").new()
	crt_canvas.game = self
	sv.add_child(crt_canvas)
	var crt = MeshInstance3D.new()
	var q = QuadMesh.new()
	q.size = Vector2(0.56, 0.4)
	crt.mesh = q
	var cm = StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.albedo_texture = sv.get_texture()
	crt.material_override = cm
	crt.position = MON + Vector3(0, 0, -0.04)
	add_child(crt)
	crt_node = crt
	monitor_light = _omni("#40ff80", 1.6, 3.5, MON + Vector3(0, 0.1, 0.4))

# ---------- postavy ----------
func _build_chars() -> void:
	VOX = Node3D.new()
	add_child(VOX)
	vox_model = load("res://models/znicen_voxie.glb").instantiate()
	vox_model.scale = Vector3.ONE * 0.85
	VOX.add_child(vox_model)
	var aps = vox_model.find_children("*", "AnimationPlayer", true, false)
	if aps.size():
		vox_anim = aps[0]
		for n in vox_anim.get_animation_list():
			var a = vox_anim.get_animation(n)
			if n != "Jumpscare":
				a.loop_mode = Animation.LOOP_LINEAR
		vox_anim.play("Idle")
	for mi in vox_model.find_children("*", "MeshInstance3D", true, false):
		var nm = String(mi.name).to_lower()
		if "eye" in nm and ("red" in nm or "glow" in nm or "led" in nm):
			var m = StandardMaterial3D.new()
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(1, 0.1, 0.05)
			(mi as MeshInstance3D).material_override = m
			vox_red.append(m)
	# stínová Cocoa: shader s fresnelem a kouřem
	COC = Node3D.new()
	add_child(COC)
	coc_model = load("res://models/cocoa.glb").instantiate()
	COC.add_child(coc_model)
	var a = _aabb(coc_model)
	var s = 1.85 / a.size.y
	coc_model.scale = Vector3.ONE * s
	coc_model.position = Vector3(-(a.position.x + a.size.x / 2) * s, -a.position.y * s, -(a.position.z + a.size.z / 2) * s)
	coc_mat = ShaderMaterial.new()
	coc_mat.shader = load("res://scripts/shadow.gdshader")
	for mi in coc_model.find_children("*", "MeshInstance3D", true, false):
		var nm = String(mi.name)
		if nm.begins_with("cocEye"):
			continue
		(mi as MeshInstance3D).material_override = coc_mat
	var ca = coc_model.find_children("*", "AnimationPlayer", true, false)
	if ca.size():
		coc_anim = ca[0]
		for n in ["Idle", "Float"]:
			if coc_anim.has_animation(n):
				coc_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		coc_anim.play("Float")
	coc_eye_mat = StandardMaterial3D.new()
	coc_eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	coc_eye_mat.albedo_color = Color(3, 3, 3)
	# kostra: ruce dolů a houpání (originál je točil ručně, animace s rukama nehýbou)
	var sks = coc_model.find_children("*", "Skeleton3D", true, false)
	if sks.size():
		coc_sk = sks[0]
		for r in [["Bone.009_r", "z", 0.14, 1.1, 0.0, 1.15], ["Bone.009_l", "z", 0.14, 1.1, 1.7, -1.15], ["Bone.010_r", "x", 0.15, 1.6, 0.5, 0.0], ["Bone.010_l", "x", 0.15, 1.6, 2.2, 0.0]]:
			for i in coc_sk.get_bone_count():
				if coc_sk.get_bone_name(i).begins_with(r[0]):
					coc_bones.append([i, coc_sk.get_bone_pose_rotation(i), r[1], r[2], r[3], r[4], r[5]])
		# svítící oči připevněné ke kosti hlavy (Bone.013), mrkají podle animace cocEye_L/R
		var head_i = -1
		for i in coc_sk.get_bone_count():
			if coc_sk.get_bone_name(i).begins_with("Bone.013"):
				head_i = i
		var ba = BoneAttachment3D.new()
		coc_sk.add_child(ba)
		if head_i >= 0:
			ba.bone_idx = head_i
		var nb = _aabb(coc_model)
		for x in [-0.16, 0.16]:
			var e = MeshInstance3D.new()
			var sp = SphereMesh.new()
			sp.radius = 0.055
			sp.height = 0.11
			e.mesh = sp
			e.material_override = coc_eye_mat
			COC.add_child(e)
			e.position = Vector3(x, nb.end.y * 0.78, nb.end.z * 0.9)
			e.reparent(ba, true)
			coc_eye_balls.append(e)
	for nm in ["cocEye_R", "cocEye_L"]:
		var e = coc_model.find_child(nm, true, false)
		if e:
			coc_eyes.append(e)
	COC.visible = false

func _build_items() -> void:
	torch = Node3D.new()
	cam.add_child(torch)
	torch.position = Vector3(0.22, -0.24, -0.45)
	torch.rotation = Vector3(0.08, 0.05, 0)
	var body = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.03
	cy.bottom_radius = 0.03
	cy.height = 0.22
	body.mesh = cy
	body.material_override = _mat("#2a2a30")
	body.rotation.x = PI / 2
	torch.add_child(body)
	var lens = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = 0.04
	sp.height = 0.02
	lens.mesh = sp
	torch_lens = StandardMaterial3D.new()
	torch_lens.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lens.material_override = torch_lens
	lens.position = Vector3(0, 0, -0.12)
	torch.add_child(lens)
	_box(Vector3(0.09, 0.07, 0.1), _mat("#c89a78"), Vector3(0, -0.02, 0.03), torch)
	torch.visible = false
	# úkolový předmět
	item_node = Node3D.new()
	add_child(item_node)
	item_mat = StandardMaterial3D.new()
	item_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var ib = MeshInstance3D.new()
	var bm = BoxMesh.new()
	bm.size = Vector3(0.3, 0.3, 0.3)
	ib.mesh = bm
	ib.material_override = item_mat
	ib.name = "box"
	item_node.add_child(ib)
	var ih = MeshInstance3D.new()
	var hm = SphereMesh.new()
	hm.radius = 0.45
	hm.height = 0.9
	ih.mesh = hm
	ih.material_override = item_mat
	ih.name = "heart"
	item_node.add_child(ih)
	item_light = _omni("#ffd040", 2, 4, Vector3.ZERO, item_node)
	item_node.visible = false
	# kanystr, kresba, Cocoina hlava, fotky
	can_m = _make_can()
	add_child(can_m)
	can_m.scale = Vector3.ONE * 1.2
	can_m.visible = false
	can_hand = _make_can()
	can_hand.scale = Vector3.ONE * 0.9
	cam.add_child(can_hand)
	can_hand.visible = false
	draw3d = MeshInstance3D.new()
	var dq = QuadMesh.new()
	dq.size = Vector2(0.62, 0.62 * 626.0 / 952.0)
	draw3d.mesh = dq
	var dmat = StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_texture = load("res://models/kresba.png")
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	dmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	draw3d.material_override = dmat
	add_child(draw3d)
	draw3d.visible = false
	egg_head = Node3D.new()
	add_child(egg_head)
	var hd = load("res://models/cocoa_torn_head.glb").instantiate()
	hd.scale = Vector3.ONE * (0.3 / 2.66)
	egg_head.add_child(hd)
	egg_head.visible = false
	for i in 3:
		var ph = _make_photo(i)
		add_child(ph)
		ph.visible = false
		photo_nodes.append(ph)
	insp_light = OmniLight3D.new()
	insp_light.light_color = Color("#ffe8d0")
	insp_light.omni_range = 2.0
	insp_light.light_energy = 0.0
	insp_light.position = Vector3(0.3, 0.3, -0.2)
	cam.add_child(insp_light)
	hand = Node3D.new()
	cam.add_child(hand)
	var sk = _mat("#d9a37e")
	_box(Vector3(0.07, 0.07, 0.4), sk, Vector3(0, 0, -0.15), hand)
	_box(Vector3(0.1, 0.04, 0.12), sk, Vector3(0, 0, -0.38), hand)
	hand.visible = false
	for g in [[1.85, Color("#9fc0ff"), false], [1.1, Color("#ffa0d0"), true]]:
		ghosts.append(_make_ghost(g[0], g[1], g[2]))
	# plameny (konec 4)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 900
	mm.visible_instance_count = 0
	var fq = QuadMesh.new()
	fq.size = Vector2(1.2, 1.2)
	var fm = StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.albedo_texture = _flame_tex()
	fm.disable_fog = true
	fq.material = fm
	mm.mesh = fq
	fl_mm = MultiMeshInstance3D.new()
	fl_mm.multimesh = mm
	add_child(fl_mm)
	fl_pos.resize(900)
	fl_vel.resize(900)
	out_ground = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(120, 80)
	out_ground.mesh = pm
	out_ground.material_override = _mat("#0b0b0e", 1.0)
	add_child(out_ground)
	out_ground.visible = false

func _flame_tex() -> Texture2D:
	var g = GradientTexture2D.new()
	g.fill = GradientTexture2D.FILL_RADIAL
	g.fill_from = Vector2(0.5, 0.5)
	g.fill_to = Vector2(1, 0.5)
	var gr = Gradient.new()
	gr.set_color(0, Color(1, 0.94, 0.67, 1))
	gr.add_point(0.35, Color(1, 0.47, 0.08, 0.75))
	gr.set_color(gr.get_point_count() - 1, Color(0.47, 0.04, 0, 0))
	g.gradient = gr
	return g

func _make_can() -> Node3D:
	var g = Node3D.new()
	var red = _mat("#b3171a", 0.5, 0.3)
	red.emission_enabled = true
	red.emission = Color("#3a0505")
	_box(Vector3(0.46, 0.56, 0.18), red, Vector3(0, 0.3, 0), g)
	for dy in [0.1, 0.5]:
		_box(Vector3(0.48, 0.035, 0.2), red, Vector3(0, dy, 0), g)
	_box(Vector3(0.26, 0.045, 0.09), _mat("#1c1c1c", 0.6, 0.6), Vector3(-0.07, 0.66, 0), g)
	var spout = _box(Vector3(0.07, 0.14, 0.07), _mat("#1c1c1c"), Vector3(0.15, 0.66, 0), g)
	spout.rotation.z = -0.5
	var cap = _box(Vector3(0.1, 0.05, 0.1), _mat("#e8c020"), Vector3(0.2, 0.72, 0), g)
	cap.rotation.z = -0.5
	_box(Vector3(0.26, 0.13, 0.01), _mat("#e8c020"), Vector3(0, 0.3, 0.092), g)
	return g

## fotky pana Vojtěcha s Emou (nové: dají se dát Voxiemu)
func _make_photo(i: int) -> Node3D:
	var g = Node3D.new()
	var sv = SubViewport.new()
	sv.size = Vector2i(160, 200)
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(sv)
	var cv = preload("res://scripts/photo.gd").new()
	cv.idx = i
	sv.add_child(cv)
	var q = MeshInstance3D.new()
	var qm = QuadMesh.new()
	qm.size = Vector2(0.24, 0.3)
	q.mesh = qm
	var m = StandardMaterial3D.new()
	m.albedo_texture = sv.get_texture()
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission_texture = sv.get_texture()
	m.emission_energy_multiplier = 0.4
	q.material_override = m
	g.add_child(q)
	g.set_meta("tex", sv.get_texture())
	return g

func _make_ghost(h: float, col: Color, pig: bool) -> Node3D:
	var g = Node3D.new()
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(col.r, col.g, col.b, 0)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var bd = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = h * 0.13
	cy.bottom_radius = h * 0.2
	cy.height = h * 0.6
	bd.mesh = cy
	bd.material_override = m
	bd.position.y = h * 0.45
	g.add_child(bd)
	var hd = MeshInstance3D.new()
	var sp = SphereMesh.new()
	sp.radius = h * 0.12
	sp.height = h * 0.24
	hd.mesh = sp
	hd.material_override = m
	hd.position.y = h * 0.87
	g.add_child(hd)
	if pig:
		for x in [-1, 1]:
			var p = MeshInstance3D.new()
			var s2 = SphereMesh.new()
			s2.radius = h * 0.05
			s2.height = h * 0.1
			p.mesh = s2
			p.material_override = m
			p.position = Vector3(x * h * 0.13, h * 0.93, 0)
			g.add_child(p)
	g.set_meta("mat", m)
	g.visible = false
	add_child(g)
	return g

# ====================================================================
#  HRA
# ====================================================================
func hour() -> int:
	return mini(6, int(floor(G.t / HOUR)))
func say(m: String, t := 3.0) -> void:
	G.msg = m
	G.msgT = t
func vojtech(kind: String, o := {}) -> void:
	if speech and speech.t < speech.dur and not o.get("force", false):
		return
	var tx: String = pick(D.VOJ[kind])
	speech = {"who": "Vojtěch", "text": tx, "t": 0.0, "dur": maxf(2.5, audio.voice(tx, o.get("vol", 0.55), o.get("pan", 0.0)))}
func voj_say(tx: String) -> void:
	speech = {"who": "Vojtěch", "text": tx, "t": 0.0, "dur": maxf(2.5, audio.voice(tx, 0.55))}

func new_game(n := -1) -> void:
	if n < 0:
		n = G.night if G else 1
	audio.stop_menu_song()
	n = clampi(n, 1, 7)
	ROUTE = ROUTE_L
	var online = ["8"] if n >= 5 else (["5", "8"] if n >= 3 else ["2", "5", "8"])
	G = {"t": 0.0, "bat": 100.0, "mon": false, "monA": 0.0, "flash": false, "look": 0.0, "cam": "8", "online": online, "fix": null,
		"night": n, "roam": false, "rp": {"x": 0.0, "z": 0.0, "y": 0.0, "vy": 0.0, "yaw": 0.0, "pitch": 0.0, "st": 1.0, "bob": 0.0}, "task": 0, "hold": 0.0, "calm": 1.0, "heartOff": false,
		"vox": {"i": 0, "timer": 0.0, "lure": null, "lureT": 0.0, "lit": 0.0, "holeT": 0.0, "rx": 0.0, "rz": 0.0, "path": [], "ph": 0.0, "moving": false, "chase": false, "hold": false, "face": 0.0, "nc": 0.0, "bt": 0.0, "lastSt": 0},
		"coc": {"on": false, "t": 0.0, "stay": 0.0, "spot": 0},
		"msg": "", "msgT": 0.0, "out": false, "outT": 0.0, "killer": null, "staticT": 0.0, "custom": false, "egg": null, "peace": false, "cut": null,
		"can": false, "draw": false, "photos": 0, "gave": false, "inv": [], "hsReady": false, "hsLock": false, "hb": 0.0, "dripT": randf_range(4, 9), "ventT": randf_range(8, 15), "servoT": 3.0, "sig": {}, "stable": false}
	var r = RROOMS["1A"]
	G.vox.rx = r.cx
	G.vox.rz = r.cz - 1
	init_sig()
	place_vox()
	COC.visible = false
	G.coc.t = coc_t()
	if SV.cocGone:
		G.coc.t = 1e9
	reset_extras()
	S = "intro"
	scene_t = 0.0

func init_sig() -> void:
	G.sig = {}
	for id in CAMS:
		G.sig[id] = {"on": randf() < 0.7, "t": randf_range(1, 10)}
	G.stable = false
	upd_sig(0)
func upd_sig(dt: float) -> void:
	var k = G.night - 1
	for id in G.sig:
		var c = G.sig[id]
		c.t -= dt
		if c.t <= 0:
			c.on = not c.on
			c.t = randf_range(7, 16) * (1 - k * 0.06) if c.on else randf_range(2, 5) * (1 + k * 0.15)
			if not c.on and G.mon and G.cam == id:
				G.staticT = 0.6
	G.online = []
	for id in G.sig:
		if G.stable or G.sig[id].on:
			G.online.append(id)
	if G.get("fixed"):
		for id in G.fixed:
			if not G.online.has(id):
				G.online.append(id)
func online(id: String) -> bool:
	return G.online.has(id)
func coc_t() -> float:
	if G.custom:
		return randf_range(55, 80) * (1 - CUST.c * 0.042) if CUST.c else 1e9
	return randf_range(32, 55) * (1 - (G.night - 1) * 0.08) * G.calm
func start_custom() -> void:
	audio.stop_menu_song()
	new_game(7)
	G.night = 8
	G.custom = true
	G.coc.t = coc_t()

func place_vox() -> void:
	pass

func vox_move(to: int) -> void:
	var v = G.vox
	if to <= 1 and v.i > 1:
		ROUTE = ROUTE_L if randf() < 0.5 else ROUTE_R
	var from: int = v.i
	v.i = clampi(to, 0, ROUTE.size() - 1)
	var closeness = float(v.i) / (ROUTE.size() - 1)
	var pan = randf_range(-0.3, 0.3)
	audio.sfx("step", 0.16 + closeness * 0.7, pan)
	audio.sfx("spark", 0.1 + closeness * 0.5, pan)
	if G.mon and (ROUTE[from] == G.cam or ROUTE[v.i] == G.cam):
		G.staticT = 0.8
	v.path = vox_path()
	v.chase = false
	if G.roam:
		return
	if ROUTE[v.i] == "HOLE":
		v.lit = 0.0
		v.holeT = 0.0
		say("…něco jiskří přímo před tebou.", 2.5)
		later(0.6, func(): if G: vojtech("hole", {"force": true, "vol": 0.7}))

func vox_target(i: int) -> String:
	return "TY" if ROUTE[i] == "HOLE" else ROUTE[i]
func vox_path() -> Array:
	var v = G.vox
	var to = vox_target(v.i)
	var from = room_at(v.rx, v.rz)
	var pts = path_to(from if from != null else to, to)
	if ROUTE[v.i] == "HOLE":
		# díra ve zdi kanceláře (z toalet)
		pts = pts.slice(0, pts.size() - 1)
		pts.append([RROOMS.TY.cx, RROOMS.TY.z0 - 0.35])
	return pts

func vox_walk(dt: float) -> void:
	var v = G.vox
	var base = 0.9 + (G.night - 1) * 0.12 + (0.5 if v.chase else 0.0)
	v.ph += dt * 5.5
	var sp = base * (1.0 if sin(v.ph) > 0 else 0.3)
	var tx = null
	var tz = null
	if v.chase and G.roam:
		tx = G.rp.x
		tz = G.rp.z
	elif v.path.size():
		tx = v.path[0][0]
		tz = v.path[0][1]
		if Vector2(tx - v.rx, tz - v.rz).length() < 0.25:
			v.path.pop_front()
	v.moving = not v.hold and tx != null and Vector2(tx - v.rx, tz - v.rz).length() > 0.2
	if v.moving:
		var dx = tx - v.rx
		var dz = tz - v.rz
		var l = Vector2(dx, dz).length()
		var sx = dx / l * sp * dt
		var sz = dz / l * sp * dt
		if v.nc > 0:
			v.nc -= dt
			v.rx += sx
			v.rz += sz
		elif blocked(v.rx, v.rz) or not blocked(v.rx + sx, v.rz + sz):
			v.rx += sx
			v.rz += sz
			v.bt = 0.0
		elif not blocked(v.rx + sx, v.rz):
			v.rx += sx
		elif not blocked(v.rx, v.rz + sz):
			v.rz += sz
		else:
			v.bt += dt
			v.rx -= sz * 0.8
			v.rz += sx * 0.8
			if v.bt > 1.2:
				v.nc = 0.9
				v.bt = 0.0
		v.face = atan2(dx, dz)
		var st = int(floor(v.ph / PI))
		if st != v.lastSt:
			v.lastSt = st
			if G.roam:
				var dd = Vector2(G.rp.x - v.rx, G.rp.z - v.rz).length()
				if dd < 14:
					audio.sfx("step", clampf(0.9 - dd * 0.06, 0.04, 0.9) * (0.5 if st % 2 else 1.0))

func update(dt: float) -> void:
	scene_t += dt
	if S == "extras":
		hud.EX.rot += dt * 0.6
		hud.EX.at += dt
		if hud.EX.scare >= 0:
			hud.EX.scare += dt
			if hud.EX.scare > 1.6:
				hud.EX.scare = -1.0
	if speech:
		speech.t += dt
	if S == "arrest" or S == "prison":
		scenes.update(dt)
		return
	if S == "intro" and scene_t > 6:
		begin_play()
	if S == "boot":
		update_boot(dt)
		return
	if S == "mini":
		hud.update_mini(dt)
		return
	if S == "home":
		update_home(dt)
		return
	if S == "finale":
		update_finale(dt)
		return
	if S == "scare" and scene_t > 2.1:
		S = "dead"
		scene_t = 0.0
	if S != "play":
		return
	if G.cut:
		cut_tick(dt)
		return
	var h_prev = hour()
	G.t += dt
	if G.t >= 6 * HOUR:
		win_night()
		return
	if hour() != h_prev:
		later(1.2, func(): if G and S == "play": vojtech("hour"))
	G.hb -= dt
	if G.hb <= 0:
		var k = float(G.vox.i) / (ROUTE.size() - 1)
		G.hb = 1.6 - k * 1.0
		if k > 0.3:
			audio.sfx("heart", 0.16 + k * 0.4)
	if randf() < dt * 0.04:
		audio.sfx("whisper")
	ambient_fx(dt)
	G.monA = clampf(G.monA + (dt if G.mon else -dt) * 5, 0, 1)
	G.staticT = maxf(0, G.staticT - dt)
	if G.msgT > 0:
		G.msgT -= dt
	var v = G.vox
	var c = G.coc
	if not G.out:
		G.bat -= dt * (0.05 + (0.09 if G.mon else 0.0) + (0.16 if (G.flash and not G.roam) else 0.0) + (0.12 if G.fix else 0.0))
		if G.bat <= 0:
			G.bat = 0.0
			G.out = true
			G.mon = false
			G.flash = false
			G.fix = null
			audio.sfx("powerdown")
			say("Baterie je prázdná…", 4)
			G.outT = 0.0
			later(3.0, func(): if G: vojtech("out", {"force": true, "vol": 0.7}))
	else:
		G.outT += dt
		if G.outT > 9 and ROUTE[v.i] != "HOLE":
			v.i = ROUTE.size() - 1
			v.path = vox_path()
		if G.outT > 13:
			jumpscare("V")
		return
	upd_sig(dt)
	if G.fix:
		if not G.mon:
			G.fix = null
		else:
			G.fix.p += dt
			if randf() < dt * 4:
				audio.sfx("click")
			if G.fix.p >= 6:
				if not G.has("fixed"):
					G.fixed = []
				G.fixed.append(G.fix.id)
				say("Kamera " + G.fix.id + " je zpět online.", 2.5)
				audio.sfx("fixed")
				G.fix = null
	if G.roam and not G.egg:
		roam_player(dt)
		G.flash = true
	var lvl = CUST.v + hour() * 0.3 if G.custom else D.LV[hour()] + (G.night - 1) * 1.5
	if DEV.freeze:
		if G.roam:
			roam_player(0)
		return
	if G.roam and ROUTE[v.i] == "HOLE":
		v.i = ROUTE.size() - 2
		v.path = vox_path()
	if G.peace or G.egg:
		if G.peace:
			G.vox.i = 0
		vox_walk(dt)
		if G.roam:
			roam_update(dt)
		return
	vox_walk(dt)
	if ROUTE[v.i] == "HOLE":
		var looking = absf(G.look) < 0.38 and not G.mon
		if G.flash and looking:
			v.lit += dt
			if v.lit > 1.5:
				audio.sfx("spark", 0.8)
				vox_move(pick([1, 2]))
				say("Couvl zpátky do tmy.", 2)
				vojtech("back", {"force": true})
		v.holeT += dt * (1.8 if G.mon else 1.0)
		if v.holeT > 5.5 - (G.night - 1) * 0.3:
			G.mon = false
			jumpscare("V")
			return
		if randf() < dt * 2:
			audio.sfx("spark", 0.5)
	else:
		if v.lureT > 0:
			v.lureT -= dt
		else:
			v.lure = null
		v.timer += dt
		if G.night >= 6 and G.mon and G.cam == ROUTE[v.i] and online(G.cam):
			v.timer += dt * 1.5
		if v.timer > 6 - (G.night - 1) * 0.4:
			v.timer = 0.0
			if v.lure != null and v.lure != v.i:
				vox_move(v.i + signi(v.lure - v.i))
			elif v.lure == null and randf() * 20 < lvl:
				vox_move(v.i + 1)
		if randf() < dt * 0.3:
			audio.sfx("spark", 0.06 + float(v.i) / (ROUTE.size() - 1) * 0.3, randf_range(-0.5, 0.5))
	if G.roam:
		roam_update(dt)
		return
	# stínová Cocoa v kanceláři
	if not c.on:
		c.t -= dt
		if c.t <= 0:
			c.on = true
			c.stay = 0.0
			c.spot = randi() % D.COC_SPOTS.size()
			var s = D.COC_SPOTS[c.spot]
			COC.position = EYE + Vector3(s[0], -EYE.y, s[2] - 3.6)
			COC.rotation = Vector3(0, s[3], 0)
			COC.visible = true
			coc_vis.van = null
			coc_vis.born = 0.0
			audio.sfx("whisper")
	else:
		c.stay += dt
		var s = D.COC_SPOTS[c.spot]
		var dir = (Vector3(EYE.x + s[0], 1.3, EYE.z + s[2] - 3.6) - EYE).normalized()
		var fwd = Vector3(0, 0, -1).rotated(Vector3.UP, G.look)
		if G.flash and not G.mon and fwd.dot(dir) > 0.85:
			c.on = false
			coc_van()
			c.t = coc_t() + 5
			audio.sfx("whisper")
			say("Cocoa: „" + pick(D.HINTS) + "“", 4)
		elif c.stay > 4.5:
			c.on = false
			coc_van()
			c.t = coc_t()
			G.bat = maxf(0, G.bat - 22)
			audio.sfx("drain")
			G.staticT = 1.0
			say("Cocoa vysála kus baterie! (-22 %)", 3)
			later(1.5, func(): if G: vojtech("coc"))

func ambient_fx(dt: float) -> void:
	G.dripT -= dt
	if G.dripT <= 0:
		G.dripT = randf_range(5, 14)
		audio.sfx("drip", 1.0, randf_range(-0.8, 0.8))
	G.ventT -= dt
	if G.ventT <= 0:
		G.ventT = randf_range(10, 22)
		audio.sfx("vent", 1.0, randf_range(-0.9, 0.9))
	G.servoT -= dt
	if G.servoT <= 0 and G.vox.path.size():
		G.servoT = randf_range(1.5, 3.5)
		var k = float(G.vox.i) / (ROUTE.size() - 1)
		audio.sfx("servo", 0.3 + k, 0.5 if ROUTE == ROUTE_R else -0.5)

func scare_sound(who: String) -> void:
	audio.sfx("scare_c" if who == "C" else "scare_v")
func jumpscare(who: String) -> void:
	if S != "play":
		return
	if DEV.god:
		if who == "V":
			G.vox.holeT = 0.0
			vox_move(1)
		if G.out:
			G.out = false
			G.bat = 30.0
		return
	G.roam = false
	G.killer = who
	S = "scare"
	scene_t = 0.0
	scare_sound(who)
	audio.stop_ambient()
	Input.vibrate_handheld(700)
func toggle_mon() -> void:
	if S != "play" or G.out:
		return
	G.mon = not G.mon
	audio.sfx("cam")
	if not G.mon:
		hud._stop_tape()
	if G.mon:
		G.staticT = 0.3
func lure() -> void:
	if not online(G.cam) or G.cam == "8":
		say("Na chodbě by ho to přilákalo blíž!" if G.cam == "8" else "Kamera je offline.", 2)
		return
	var idx = ROUTE.find(G.cam)
	if idx < 0:
		say("Odsud ho zvuk nepřiláká.", 2)
		return
	G.vox.lure = idx
	G.vox.lureT = 14.0
	G.bat -= 4
	audio.sfx("lure")
	say("Hraje melodie v: " + CAMS[G.cam], 2.5)
	if randf() < 0.5:
		later(2.0, func(): if G: vojtech("lure"))

func begin_play() -> void:
	S = "play"
	scene_t = 0.0
	audio.start_ambient()
	if G.night == 7 and not G.custom:
		later(14.0, func(): if G and S == "play" and not G.can: say("Ve skladu možná zbyl kanystr… a v bludišti se v míčcích cosi bělá.", 6))
	say("Baterie počítače je jediný zdroj energie. Šetři ji.", 5)
	later(2.5, func():
		if not G or S != "play":
			return
		if G.night == 1:
			vojtech("start", {"force": true})
		elif D.VOJN.has(str(G.night)):
			voj_say(D.VOJN[str(G.night)])
		else:
			vojtech("start", {"force": true}))

func win_night() -> void:
	var n: int = G.night
	S = "win"
	scene_t = 0.0
	G.roam = false
	audio.stop_ambient()
	audio.sfx("chime")
	if G.custom:
		var sc = (CUST.v + CUST.c) * 10
		if sc > st_get("v2r_cbest", 0):
			st_set("v2r_cbest", sc)
	else:
		st_set("v2_won", true)
		st_set("v2_night", maxi(st_get("v2_night", 1), mini(7, n + 1)))
		if n == 7:
			st_set("v2_end", 5 if G.heartOff else 1)
	later(3.5, func(): audio.voice(pick(D.VOJ.win), 0.5))

# ---------- úkoly nocí ----------
func tasks(n: int) -> Array:
	match n:
		2: return [{"room": "2", "kind": "pick", "name": "pojistku 1/3", "col": Color("#ffd040"), "on": "bat15"}, {"room": "3", "kind": "pick", "name": "pojistku 2/3", "col": Color("#ffd040"), "on": "bat15"}, {"room": "4", "kind": "pick", "name": "pojistku 3/3", "col": Color("#ffd040"), "on": "bat15"}]
		3: return [{"room": "5", "kind": "pick", "name": "kazetu 1/3", "col": Color("#ff60ff"), "on": "tape0"}, {"room": "1B", "kind": "pick", "name": "kazetu 2/3", "col": Color("#ff60ff"), "on": "tape1"}, {"room": "7", "kind": "pick", "name": "kazetu 3/3", "col": Color("#ff60ff"), "on": "tape2"}]
		4: return [{"room": "9", "kind": "hold", "t": 4.0, "name": "oprav rozvaděč (stůj u něj)", "col": Color("#40c0ff"), "on": "stable"}]
		5: return [{"room": "3", "kind": "pick", "name": "Cocoinu hlavu", "col": Color("#d0a0ff"), "on": "calm"}]
		6: return [{"room": "1A", "kind": "pick", "name": "klíč na pódiu", "col": Color("#ffe46b"), "on": "key"}, {"room": "4", "kind": "hold", "t": 3.0, "name": "odemkni skříňku ve skladu", "col": Color("#ffe46b"), "on": "bat40"}]
		7: return [{"room": "1B", "kind": "flash", "t": 5.0, "name": "zhasni srdce herny baterkou", "col": Color("#ff2020"), "on": "heart"}]
	return []
func cur_task():
	var T = tasks(G.night) if not G.custom else []
	return T[G.task] if G.task < T.size() else null
func task_done(st: Dictionary) -> void:
	G.task += 1
	G.hold = 0.0
	audio.sfx("task")
	match st.on:
		"bat15":
			G.bat = minf(100, G.bat + 15)
			say("Baterie +15 %", 3)
		"bat40":
			G.bat = minf(100, G.bat + 40)
			say("Baterie +40 %", 3)
		"tape0", "tape1", "tape2":
			voj_say(D.TAPES[int(st.on.right(1))])
		"stable":
			G.stable = true
			say("Rozvaděč opraven – signál všech kamer je stabilní!", 4)
		"calm":
			G.calm = 1.8
			say("Cocoa: „Děkuju…“ Bude teď chodit méně.", 4)
		"key":
			say("Máš klíč. Teď skříňka ve skladu.", 3)
		"heart":
			G.heartOff = true
			win_night()

func leave_desk() -> void:
	if not G or G.mon or G.out or G.roam:
		return
	G.roam = true
	G.flash = false
	G.fix = null
	COC.visible = false
	G.coc.on = false
	# vstaneš přímo od stolu – stejná kancelář, jen v ní chodíš
	G.rp.x = EYE.x
	G.rp.z = EYE.z
	G.rp.yaw = G.look
	G.rp.pitch = 0.0
	G.rp.bob = 0.0
	G.rp.y = 0.0
	G.rp.vy = 0.0
	var v = G.vox
	if ROUTE[v.i] == "HOLE":
		v.i = ROUTE.size() - 2
		v.path = vox_path()
	v.lit = 0.0
	audio.sfx("step", 0.4)
	say("Odešel jsi od stolu. Kapesní baterka svítí – namiř ji na Voxieho. Ven se dá jen dírou přes toalety.", 4)
func back_desk() -> void:
	if not G or not G.roam:
		return
	G.roam = false
	G.flash = false
	G.look = clampf(wrapf(G.rp.yaw, -PI, PI), -1.25, 1.25)
	audio.sfx("step", 0.4)
func near_desk() -> bool:
	return G.roam and Vector2(G.rp.x - EYE.x, G.rp.z - EYE.z).length() < 1.6

func roam_jump() -> void:
	if G and G.roam and G.rp.y == 0.0 and G.rp.st > 0.08:
		G.rp.vy = 4.6
		G.rp.st = maxf(0, G.rp.st - 0.08)
		audio.sfx("jump", 0.6)

func roam_player(dt: float) -> void:
	var p = G.rp
	var mx = 0.0
	var mz = 0.0
	var joy = hud.joy
	if joy:
		mx = joy.dx
		mz = joy.dy
	if keys.get("w") or keys.get("up"):
		mz -= 1
	if keys.get("s") or keys.get("down"):
		mz += 1
	if keys.get("a"):
		mx -= 1
	if keys.get("d"):
		mx += 1
	if keys.get("left"):
		p.yaw += dt * 2
	if keys.get("right"):
		p.yaw -= dt * 2
	var m = Vector2(mx, mz).length()
	var run = (m > 0.92 or keys.get("shift", false)) and p.st > 0.02 and m > 0.1
	p.st = clampf(p.st + (-dt * 0.22 if run else dt * 0.12), 0, 1)
	# skok
	p.vy -= 13.0 * dt
	p.y = maxf(0.0, p.y + p.vy * dt)
	if p.y == 0.0 and p.vy < 0:
		if p.vy < -3:
			audio.sfx("step", 0.3)
		p.vy = 0.0
	if m > 0.05:
		var sp = (4.0 if run else 2.2) * dt * minf(1, m) / m
		var sn = sin(p.yaw)
		var cs = cos(p.yaw)
		var dx = (mx * cs + mz * sn) * sp
		var dz = (-mx * sn + mz * cs) * sp
		# ve skoku se dá přeskočit nízká suť
		var air = p.y > 0.35
		if (free_at(p.x + dx, p.z) or (air and walkable(p.x + dx, p.z))) and not _desk_block(p.x + dx, p.z):
			p.x += dx
		if (free_at(p.x, p.z + dz) or (air and walkable(p.x, p.z + dz))) and not _desk_block(p.x, p.z + dz):
			p.z += dz
		var pb = p.bob
		p.bob += dt * (12 if run else 8)
		if floor(pb / PI) != floor(p.bob / PI) and p.y == 0.0:
			audio.sfx("step", 0.1)
func _desk_block(x: float, z: float) -> bool:
	return x > EYE.x - 1.5 and x < EYE.x + 1.5 and z > EYE.z - 1.6 and z < EYE.z - 0.4

func roam_update(dt: float) -> void:
	var v = G.vox
	var p = G.rp
	if G.egg:
		egg_tick(dt)
		return
	extras_tick(dt)
	var dx = p.x - v.rx
	var dz = p.z - v.rz
	var d = maxf(0.01, Vector2(dx, dz).length())
	var ch = d < 5.5 and not G.peace
	if v.chase and not ch:
		v.path = vox_path()
	v.chase = ch
	G.hsReady = G.night == 7 and not G.custom and not G.peace and not G.hsLock and SV.call != "police" and d < 3.3
	G.giveReady = not G.peace and not G.gave and G.photos > 0 and d < 3.6
	if G.hsReady or G.giveReady:
		v.hold = true
		v.chase = false
	else:
		v.hold = false
	if randf() < dt * 3 and d < 8:
		audio.sfx("spark", 0.6)
	var fwd = Vector3(0, 0, -1).rotated(Vector3.RIGHT, p.pitch).rotated(Vector3.UP, p.yaw)
	var to = Vector3(v.rx - p.x, -0.3, v.rz - p.z).normalized()
	if G.flash and not G.out and d < 9 and fwd.dot(to) > 0.9:
		v.lit += dt
		if v.lit > 1.5:
			v.lit = 0.0
			audio.sfx("spark", 0.8)
			vox_move(maxi(0, v.i - 2))
			say("Couvl do tmy.", 2)
	else:
		v.lit = maxf(0, v.lit - dt * 0.5)
	if d < 1.1 and not G.peace and not G.giveReady:
		jumpscare("V")
		return
	var st = cur_task()
	if st == null:
		return
	var ir = RROOMS[st.room]
	var idist = Vector2(p.x - ir.cx, p.z - ir.cz).length()
	if st.kind == "pick":
		if idist < 1.3:
			task_done(st)
	elif st.kind == "hold":
		if idist < 1.6:
			G.hold += dt
			if randf() < dt * 4:
				audio.sfx("click")
			if G.hold >= st.t:
				task_done(st)
		else:
			G.hold = 0.0
	else:
		var tv = Vector3(ir.cx - p.x, -0.5, ir.cz - p.z)
		var dd = tv.length()
		tv = tv.normalized()
		if G.flash and not G.out and dd < 8 and fwd.dot(tv) > 0.88:
			G.hold += dt
			if randf() < dt * 2:
				audio.sfx("heart", 0.6)
		else:
			G.hold = maxf(0, G.hold - dt * 0.5)
		if G.hold >= st.t:
			task_done(st)

# ---------- sbírané předměty (kanystr, kresba, Cocoina hlava, fotky) ----------
var XI := []
func reset_extras() -> void:
	can_m.visible = false
	draw3d.visible = false
	if egg_head.get_parent() != self:
		egg_head.get_parent().remove_child(egg_head)
		add_child(egg_head)
	egg_head.visible = false
	egg_head.position = Vector3.ZERO
	egg_head.rotation = Vector3.ZERO
	can_hand.visible = false
	for ph in photo_nodes:
		ph.visible = false
	XI = [
		{"id": "can", "room": "4", "far": 1.6, "seed": 1.0, "y": 0.02, "p": null},
		{"id": "draw", "room": "3", "far": 2.2, "seed": 3.0, "y": 0.3, "p": null},
		{"id": "head", "room": "3", "far": 2.2, "seed": 0.0, "y": 0.22, "p": null},
		{"id": "photo0", "room": "2", "far": 2.0, "seed": 5.0, "y": 0.5, "p": null},
		{"id": "photo1", "room": "5", "far": 1.8, "seed": 2.0, "y": 0.5, "p": null},
		{"id": "photo2", "room": "9", "far": 1.4, "seed": 4.0, "y": 0.5, "p": null},
	]
func spot_in(id: String, far: float, seed: float) -> Array:
	var r = RROOMS[id]
	for k in 80:
		var a = k * 2.4 + seed
		var rad = far + (k % 7) * 0.45
		var x = r.cx + cos(a) * rad
		var z = r.cz + sin(a) * rad
		var ok = true
		for o in [[0, 0], [0.5, 0], [-0.5, 0], [0, 0.5], [0, -0.5]]:
			if not free_at(x + o[0], z + o[1]):
				ok = false
				break
		if ok:
			return [x, z]
	return [r.cx, r.cz]
func _xi_on(id: String) -> bool:
	match id:
		"can": return G.night == 7 and not G.custom and not G.can
		"draw": return G.night == 7 and not G.custom and not G.draw
		"head": return not SV.cocGone and not G.peace and not G.inv.has("head")
		"photo0", "photo1", "photo2": return not G.custom and G.night >= 5 and not G.inv.has(id) and not G.gave
	return false
func _xi_node(id: String) -> Node3D:
	match id:
		"can": return can_m
		"draw": return draw3d
		"head": return egg_head
	return photo_nodes[int(id.right(1))]
func extras_tick(dt: float) -> void:
	var p = G.rp
	for it in XI:
		var m = _xi_node(it.id)
		if it.id == "head" and m.get_parent() != self:
			continue
		var on = _xi_on(it.id)
		m.visible = on
		if not on:
			continue
		if it.p == null:
			it.p = spot_in(it.room, it.far, it.seed)
		m.position = Vector3(it.p[0], it.y + sin(t_now * 1.6 + it.seed) * 0.03, it.p[1])
		if it.id == "draw":
			m.rotation = Vector3(-PI / 2 + 0.15, 0, t_now * 0.5)
		else:
			m.rotation.y = t_now * 0.6
		if Vector2(p.x - it.p[0], p.z - it.p[1]).length() < 1.15:
			grab(it.id)
func grab(id: String) -> void:
	match id:
		"can":
			G.can = true
			G.inv.append("can")
			audio.sfx("can")
			say("Vzal jsi kanystr. Je plný. Zapalovač máš v kapse. (inventář)", 5)
		"draw":
			G.draw = true
			G.inv.append("draw")
			audio.sfx("draw")
			say("Ohořelá dětská kresba z míčků: „TÁTA“. Vezmi ji k Voxiemu.", 6)
		"head":
			G.inv.append("head")
			egg_start()
		_:
			G.inv.append(id)
			G.photos += 1
			audio.sfx("pick")
			say("Našel jsi fotku (" + str(G.photos) + "/3): " + ["Vojtěch s Emou na pódiu, 1996.", "Ema s Cocoou na oslavě narozenin.", "Rodinná fotka před hernou. „Táta, Ema a já.“"][int(id.right(1))], 5)

## NOVÉ: dát Voxiemu fotky – na noc ho uklidní (a s kresbou i rukou podanou ukončí příběh dál)
func give_photos() -> void:
	if not G.giveReady:
		return
	var n: int = G.photos
	G.gave = true
	for i in 3:
		G.inv.erase("photo" + str(i))
	G.cut = {"k": "photo", "t": 0.0, "said": 0, "n": n}
	var v = G.vox
	var p = G.rp
	v.moving = false
	v.face = atan2(p.x - v.rx, p.z - v.rz)
	audio.sfx("heart", 0.8)

# ---------- easter egg: Cocoina hlava ----------
func egg_start() -> void:
	var p = G.rp
	var v = G.vox
	G.egg = {"t": 0.0, "y0": p.yaw, "p0": p.pitch, "sub": "", "said": 0, "ty": 0.0}
	G.flash = false
	egg_head.get_parent().remove_child(egg_head)
	cam.add_child(egg_head)
	egg_head.visible = true
	egg_head.position = Vector3(0, -0.9, -0.45)
	egg_head.rotation = Vector3(0.15, 0.5, 0)
	SV.cocGone = true
	st_set("v2_cocgone", true)
	G.coc.on = false
	G.coc.t = 1e9
	COC.visible = false
	var base = p.yaw + PI
	var ok = false
	for dd in [4.2, 3.4, 2.8]:
		for da in [0, 0.6, -0.6, 1.2, -1.2]:
			var a = base + da
			var x = p.x - sin(a) * dd
			var z = p.z - cos(a) * dd
			if not ok and walkable(x, z):
				v.rx = x
				v.rz = z
				ok = true
	if not ok:
		v.rx = p.x + 2.4
		v.rz = p.z
	v.path = []
	v.chase = false
	v.hold = true
	v.moving = false
	G.egg.ty = atan2(-(v.rx - p.x), -(v.rz - p.z))
	audio.sfx("heart", 1.0)
	audio.sfx("egg")
func egg_tick(dt: float) -> void:
	var e = G.egg
	var p = G.rp
	var v = G.vox
	e.t += dt
	var t = e.t
	while e.said < D.EGG_SUB.size() and t >= D.EGG_SUB[e.said][0]:
		var s = D.EGG_SUB[e.said]
		e.sub = (s[1] + ": „" + s[2] + "“") if s[1] != "" else s[2]
		if s[1] != "":
			audio.voice(s[2], 0.7)
		if e.said == 1:
			audio.sfx("step", 0.6)
		e.said += 1
	if t > 11:
		e.sub = ""
	if t < 1.6:
		var k = ease_io(t / 1.6)
		egg_head.position = Vector3(0.14 * k, -0.9 + 0.62 * k, -0.45)
		p.pitch = e.p0 - 0.35 * sin(k * PI)
	elif t < 3.8:
		var k = ease_io((t - 1.6) / 2.2)
		var dy = atan2(sin(e.ty - e.y0), cos(e.ty - e.y0))
		p.yaw = e.y0 + dy * k
		p.pitch = e.p0 * (1 - k)
		egg_head.position = Vector3(0.14, -0.28, -0.45)
	else:
		egg_head.position = Vector3(0.14, -0.28 + sin(t * 2) * 0.006, -0.45)
	v.face = atan2(p.x - v.rx, p.z - v.rz)
	v.moving = false
	if t > 8.6:
		var d = maxf(1.0, Vector2(v.rx - p.x, v.rz - p.z).length())
		v.face = atan2(v.rx - p.x, v.rz - p.z)
		v.moving = true
		v.ph += dt * 5.5
		v.rx += (v.rx - p.x) / d * 0.9 * dt
		v.rz += (v.rz - p.z) / d * 0.9 * dt
	if t > 12:
		var r = RROOMS["1A"]
		v.rx = r.cx
		v.rz = r.cz - 1
		v.path = []
		v.moving = false
		v.hold = false
		v.i = 0
		G.egg = null
		G.peace = true
		egg_head.position = Vector3(-0.22, -0.3, -0.5)
		egg_head.rotation = Vector3(0.2, -0.4, 0)
		say("Voxie tě tu noc nechá být. Cocoa už se nevrátí. (Hlavu máš v inventáři – prohlédni si ji.)", 6)

# ---------- konec 3 (podaná ruka), konec 4 (oheň), NOVÉ: fotky ----------
func start_hs() -> void:
	if not G.draw:
		G.hsLock = true
		G.vox.hold = false
		say("Voxie ruku nepřijal. Chybí mu něco od Emy… něco z bludiště.", 5)
		return
	var p = G.rp
	var v = G.vox
	var d = maxf(1.0, Vector2(v.rx - p.x, v.rz - p.z).length())
	var m = maxf(0, d - 1.8)
	p.x += (v.rx - p.x) / d * m
	p.z += (v.rz - p.z) / d * m
	p.yaw = atan2(-(v.rx - p.x), -(v.rz - p.z))
	p.pitch = -0.04
	v.moving = false
	v.face = atan2(p.x - v.rx, p.z - v.rz)
	G.cut = {"k": "hs", "t": 0.0, "said": 0}
	audio.sfx("heart", 0.8)
func start_burn() -> void:
	if not G or not G.can or G.cut or not G.roam:
		return
	G.cut = {"k": "fire", "t": 0.0, "said": 0, "lim": 0}
	G.rp.pitch = -0.8
	can_hand.visible = true
	exit_g.visible = false
	audio.sfx("burnlong")
	audio.sfx("heart", 1.0)
const PHOTO_SUB := [[0.5, "", "Podal jsi Voxiemu fotky."], [3.0, "", "Voxie je bere drápem, opatrně, jednu po druhé."], [6.0, "Vojtěch", "Ema… a já. Na pódiu."], [9.2, "Vojtěch", "Pamatuju si ten den. Smála se."], [12.4, "", "Rudé oko pohaslo. Voxie se otočil a odkulhal na pódium."]]
func cut_subs(k: String) -> Array:
	return D.HS_SUB if k == "hs" else (D.FIRE_SUB if k == "fire" else PHOTO_SUB)
func cut_tick(dt: float) -> void:
	var c = G.cut
	c.t += dt
	var t = c.t
	var SUB = cut_subs(c.k)
	while c.said < SUB.size() and t >= SUB[c.said][0]:
		var s = SUB[c.said]
		if s[1] != "":
			audio.voice(s[2], 0.7 if s[1] == "Vojtěch" else 0.45, 0.0 if s[1] == "Vojtěch" else -0.2)
		c.said += 1
	if c.k == "hs":
		if t > 3 and t - dt <= 3:
			audio.sfx("hs")
		if t > 8.6 and t - dt <= 8.6:
			audio.sfx("whisper")
		if t > 18.6:
			end_cut(3)
	elif c.k == "photo":
		if t > 15:
			G.cut = null
			G.peace = true
			G.vox.i = 0
			G.vox.path = vox_path()
			G.vox.hold = false
			hand.visible = false
			say("Voxie tě tuhle noc nechá být. Fotky si odnesl.", 5)
	else:
		if t > 3.2 and randf() < dt * 14:
			audio.sfx("crackle", 0.5 + minf(0.75, t * 0.05))
		if t > 6 and t - dt <= 6:
			audio.sfx("whoosh")
			audio.voice("Ema! Ne, ne, ne…", 0.6)
		if t > 12 and t - dt <= 12:
			audio.sfx("heart", 0.4)
		if t > 24.6:
			end_cut(4)
func end_cut(n: int) -> void:
	G.cut = null
	COC.visible = false
	hand.visible = false
	draw3d.visible = false
	fl_mm.multimesh.visible_instance_count = 0
	out_ground.visible = false
	for g in ghosts:
		g.visible = false
	fire_light.light_energy = 0
	can_hand.visible = false
	exit_g.visible = false
	st_set("v2_end", n)
	st_set("v2_won", true)
	news_end = n
	S = "news"
	scene_t = 0.0
	audio.stop_ambient()
	if n == 3:
		audio.sfx("chime")

# ====================================================================
#  ÚVODNÍ SCÉNA 1. NOCI: zapnutí VOXIE-CAM (NOVÉ)
# ====================================================================
const BOOT_SUB := [[0.6, "Co se tu proboha stalo…"], [4.2, "Všechno je ohořelé. Ten smrad kouře je všude."], [8.0, "Tady byla moje kancelář. Ještě před týdnem jsem tu seděl."], [12.0, "A tamhle… ve zdi je díra. Ta tu nebyla."], [16.0, "Počítač. Snad ještě funguje. Baterie by mohla vydržet."], [21.0, "…naskočil."], [24.5, "Kamery. Většina je spálená. Ale něco snad uvidím."], [28.5, "Kdo mě sem volal? A proč zněl jako…"], [32.0, "Nevím. Ale dneska tu vydržím do šesti."]]
var boot_said := 0
func start_boot() -> void:
	S = "boot"
	scene_t = 0.0
	boot_said = 0
	audio.start_ambient()
func update_boot(dt: float) -> void:
	var t = scene_t
	if t > 19.2 and t - dt <= 19.2:
		audio.sfx("cam")
		audio.sfx("click")
	if t > 20.5 and t - dt <= 20.5:
		audio.sfx("fixed")
	if t > 2 and t < 17 and randf() < dt * 0.4:
		audio.sfx("drip", 0.8, randf_range(-0.8, 0.8))
	if t > 12 and t - dt <= 12:
		audio.sfx("spark", 0.5)
	if t > 35:
		S = "intro"
		scene_t = 0.0
		G.booted = true
func boot_cam(t: float) -> void:
	# rozhlédnutí po ohořelé kanceláři, pohled na díru, pak k počítači
	var keys_ = [[0.0, 0.9, 0.05], [4.0, -0.9, -0.05], [8.0, 0.4, 0.15], [11.0, 0.0, -0.02], [15.0, 0.0, -0.18], [19.0, 0.0, -0.2], [30.0, 0.0, -0.2], [34.0, 0.0, -0.06]]
	var i = 0
	while i < keys_.size() - 2 and t > keys_[i + 1][0]:
		i += 1
	var a = keys_[i]
	var b = keys_[i + 1]
	var k = ease_io(clampf((t - a[0]) / (b[0] - a[0]), 0, 1))
	var yaw = lerpf(a[1], b[1], k)
	var pitch = lerpf(a[2], b[2], k)
	var zoom = clampf((t - 15) / 4, 0, 1) * (1 - clampf((t - 30) / 4, 0, 1))
	cam.position = EYE.lerp(MON + Vector3(0, 0.05, 0.62), zoom) + Vector3(0, sin(t * 1.3) * 0.006, 0)
	cam.rotation = Vector3(pitch, yaw, 0)
	flash.light_energy = 14 * LK if t < 15 else 0.0
	flash.global_position = cam.global_position - Vector3(0, 0.2, 0)
	var fw = -cam.global_transform.basis.z
	flash.look_at(cam.global_position + fw * 6)

# ====================================================================
#  SCÉNKA DOMA, MINIHRY, FINÁLE
# ====================================================================
var home_said := 0
func start_home() -> void:
	S = "home"
	scene_t = 0.0
	home_said = 0
	home_reply = null
	SV.call = "none"
	st_set("v2_call", "none")
	home.visible = true
func update_home(dt: float) -> void:
	var t = scene_t
	if t < 5.5 and floor(t * 2) != floor((t - dt) * 2) and int(floor(t * 2)) % 3 != 2:
		audio.sfx("ring", 0.8)
	while home_said < D.CALL.size() and t >= D.CALL[home_said][0]:
		audio.voice(D.CALL[home_said][1], 0.5)
		if home_said == D.CALL.size() - 1:
			audio.sfx("scare", 0.8)
		home_said += 1
	if t > 19.6 and t - dt <= 19.6:
		audio.sfx("hangup")
	if t > 24 and t - dt <= 24:
		audio.sfx("doorcreak")
	if t > 23 and t < 45 and floor(t * 1.8) != floor((t - dt) * 1.8):
		audio.sfx("step", 0.12)
	if home_door:
		home_door.rotation.y = -clampf((t - 24) / 2, 0, 1) * 1.5
	if home_pl:
		home_pl.light_energy = (((2.0 if sin(t * 12) > 0 else 0.5) if t < 5.5 else 1.5) if t < 20 else 0.0) * LK
	if home_phone_mat:
		home_phone_mat.albedo_color = Color("#80c0ff") if t < 20 else Color("#202020")
func home_pick(k: String) -> void:
	home_reply = {"k": k, "t": scene_t, "text": D.HCT[k]}
	SV.call = k
	st_set("v2_call", k)
	audio.voice(D.HCT[k], 0.45)
func home_cam(t: float) -> void:
	var K = D.HK_
	var i = 0
	while i < K.size() - 2 and t > K[i + 1][0]:
		i += 1
	var a = K[i]
	var b = K[i + 1]
	var k = ease_io(clampf((t - a[0]) / (b[0] - a[0]), 0, 1))
	var p = v3(a[1]).lerp(v3(b[1]), k)
	var l = v3(a[2]).lerp(v3(b[2]), k)
	var walk = sin(t * 11) * 0.03 if (t > 23 and t < 45) else 0.0
	cam.position = Vector3(p.x + 200, p.y + walk, p.z)
	cam.look_at(Vector3(l.x + 200, l.y, l.z))

func start_night(n: int) -> void:
	audio.stop_menu_song()
	audio.stop_ambient()
	n = clampi(n, 1, 7)
	if n == 1:
		SV.cocGone = false
		st_set("v2_cocgone", false)
	G = null
	if n == 1 and not hud.mg_paper:
		hud.mg_paper = true
		S = "paper1"
		scene_t = 0.0
		hud.paper_n = n
		audio.sfx("powerdown")
		return
	hud.start_mini(n)

var fin_said := 0
func start_finale() -> void:
	S = "finale"
	scene_t = 0.0
	fin_said = 0
	fin_pick = null
	exit_g.visible = true
	audio.stop_ambient()
func update_finale(dt: float) -> void:
	var heart = G != null and G.heartOff
	if not heart and fin_pick == null and scene_t >= 49:
		scene_t = 49.0
	var t = scene_t
	var subs = D.FIN_SUB if heart else D.FIN_SUB + D.FIN_A
	while fin_said < subs.size() and t >= subs[fin_said][0]:
		var s = subs[fin_said]
		if s[1] != "":
			audio.voice(s[2], 0.7 if s[1] == "Vojtěch" else 0.45, 0.0 if s[1] == "Vojtěch" else -0.2)
		fin_said += 1
	if not heart:
		if t > 45.5 and t - dt <= 45.5:
			audio.sfx("clunk")
		if t > 46 and floor(t * 1.3) != floor((t - dt) * 1.3):
			audio.sfx("heart", 0.7)
	if (t < 11 or (t > 34 and t < 48)) and floor(t * 1.8) != floor((t - dt) * 1.8):
		audio.sfx("step", 0.12)
	if t > 23 and t < 34 and floor(t * 1.4) != floor((t - dt) * 1.4) and (t < 26.5 or t > 30.5):
		audio.sfx("step", 0.5)
		if randf() < 0.4:
			audio.sfx("spark", 0.3)
	if t > 26.5 and t - dt <= 26.5:
		audio.sfx("heart", 0.6)
	if t > 53:
		exit_g.visible = false
		COC.visible = false
		HB.visible = false
		# venku po cestě… za zády policie a náčelník Král
		scenes.start_arrest(5 if heart else 1)
func fin_choose(k: String) -> void:
	fin_pick = k
	SV.fin = k
	audio.voice(D.FIN_R[k], 0.7)

func coc_van() -> void:
	if coc_anim:
		coc_vis.van = 1.05
		coc_vis.born = null
	else:
		COC.visible = false

func to_menu() -> void:
	S = "menu"
	scene_t = 0.0
	audio.stop_ambient()
	audio.start_menu_song()
	home.visible = false

# ====================================================================
#  SMYČKA A VYKRESLENÍ
# ====================================================================
func _process(delta: float) -> void:
	var dt = minf(0.1, delta)
	frame_dt = dt
	t_now += dt
	update(dt)
	render(t_now, dt)

func vox_pose_anim(name: String, tm := -1.0) -> void:
	if not vox_anim:
		return
	if not vox_anim.has_animation(name):
		name = "Idle"
	if tm >= 0:
		if vox_anim.current_animation != name:
			vox_anim.play(name)
		vox_anim.seek(minf(tm, vox_anim.get_animation(name).length - 0.001), true)
		vox_anim.pause()
	else:
		if vox_anim.current_animation != name or not vox_anim.is_playing():
			vox_anim.play(name, 0.2)

func coc_pose(name: String, tm: float) -> void:
	if not coc_anim or not coc_anim.has_animation(name):
		return
	var dur = coc_anim.get_animation(name).length
	var loop = name == "Idle" or name == "Float"
	var tt = fposmod(tm, dur) if loop else clampf(tm, 0, dur - 0.001)
	if coc_anim.current_animation != name:
		coc_anim.play(name)
	coc_anim.seek(tt, true)
	coc_anim.pause()

func coc_bones_tick(t: float) -> void:
	if coc_sk == null:
		return
	for B in coc_bones:
		var e = Vector3.ZERO
		var ax = 2 if B[2] == "z" else 0
		e[ax] = B[6] + sin(t * B[4] + B[5]) * B[3]
		coc_sk.set_bone_pose_rotation(B[0], B[1] * Quaternion.from_euler(e))
	for i in mini(coc_eyes.size(), coc_eye_balls.size()):
		coc_eye_balls[i].scale = (coc_eyes[i] as Node3D).scale

func coc_clip(t: float, dt: float) -> void:
	var F = coc_vis.force
	coc_vis.force = null
	if S == "scare":
		coc_pose("Lunge", coc_vis.scareT)
		return
	if S == "extras" and hud.EX.scare >= 0:
		coc_pose("Lunge", hud.EX.scare)
		return
	if F:
		coc_pose(F[0], F[1])
		return
	if coc_vis.van != null:
		coc_vis.van += dt
		if coc_vis.van > 1.7:
			coc_vis.van = null
			COC.visible = false
			return
		coc_pose("Vanish", coc_vis.van)
		return
	if coc_vis.born != null:
		coc_vis.born += dt
		if coc_vis.born < 0.45:
			coc_pose("Vanish", coc_vis.born)
			return
		coc_vis.born = null
	if S == "extras":
		if hud.EX.cAnim == "Vanish":
			coc_pose("Vanish", fmod(hud.EX.at, 3.0))
			return
		coc_pose("Float" if hud.EX.cAnim == "Float" else "Idle", t)
		return
	coc_pose("Float", t)

func anim_building(t: float, dt: float, on: bool) -> void:
	for L in b_lights:
		var l: Light3D = L[0]
		match L[1]:
			"red":
				l.light_energy = (2.2 if sin(t * 2.4 + l.position.x) > 0.2 else 0.15) * LK
			"stage":
				var on2 = sin(t * 9) * sin(t * 2.3 + 1) > 0.15 or randf() < 0.04
				l.light_energy = (2.5 if on2 else 0.0) * LK
				for s in stage_mats:
					s[0].albedo_color = s[1] * (0.55 if (on2 and sin(t * 5 + s[2]) > -0.3) else 0.03)
			"spark":
				var k = randf() < 0.12
				l.light_energy = randf_range(1, 5) * LK if k else 0.0
				if k and on and randf() < 0.2 and G and Vector2(G.rp.x - l.position.x, G.rp.z - l.position.z).length() < 8:
					audio.sfx("spark", 0.3)
			"x":
				l.visible = exit_g.visible

func render(t: float, dt: float) -> void:
	var out = G != null and G.out
	monitor_light.light_energy = (0.0 if out else 1.6) * LK
	emergency.light_energy = (0.0 if out else (5.0 if sin(t * 2.6) > 0 else 0.4)) * LK
	tube.light_energy = (0.0 if out else (5.0 if randf() > 0.01 else 1.0)) * LK
	if G and S == "play" and not G.roam:
		if keys.get("left") or keys.get("a"):
			G.look = clampf(G.look + dt * 1.6, -1.25, 1.25)
		if keys.get("right") or keys.get("d"):
			G.look = clampf(G.look - dt * 1.6, -1.25, 1.25)
	var look = G.look if G else sin(t * 0.2) * 0.3
	cam.position = EYE
	cam.rotation = Vector3(-0.06, look, 0)
	if G and S == "play" and not G.roam and G.monA > 0:
		# obličej až k obrazovce (zoom na monitor)
		var k = ease_io(G.monA)
		var mon = MON
		cam.position = EYE.lerp(mon + Vector3(0, 0, 0.42), k)
		var yaw_m = atan2(-(mon.x - EYE.x), -(mon.z - EYE.z))
		cam.rotation = Vector3(lerpf(-0.06, -0.02, k), lerp_angle(look, yaw_m, k), 0)
	var roaming = G != null and G.roam and S == "play"
	if roaming:
		cam.position = Vector3(G.rp.x, 1.5 + G.rp.y + (sin(G.rp.bob) * 0.04 if G.rp.y == 0.0 else 0.0), G.rp.z)
		cam.rotation = Vector3(G.rp.pitch, G.rp.yaw, 0)
	var fwd = -cam.global_transform.basis.z
	flash.global_position = cam.global_position + fwd * 0.2 - Vector3(0, 0.2, 0)
	flash.look_at(cam.global_position + fwd * 6)
	flash.light_energy = (30.0 * (0.3 if randf() < 0.02 else 1.0) * LK) if (G and G.flash and not G.mon and not out) else 0.0
	# Voxie fyzicky v budově
	if G and S in ["play", "scare"]:
		var v = G.vox
		VOX.visible = true
		VOX.position = Vector3(v.rx, absf(sin(v.ph)) * 0.07 if v.moving else 0.0, v.rz)
		VOX.rotation = Vector3(0, v.face, sin(v.ph) * 0.06 if v.moving else 0.03)
		if v.chase and roaming:
			VOX.rotation.y = atan2(G.rp.x - v.rx, G.rp.z - v.rz)
		if not roaming and ROUTE[v.i] == "HOLE" and not v.moving:
			VOX.rotation.y = 0.0
		vox_pose_anim(("Walk" if (G.night >= 5 or G.custom) else "Limp") if v.moving else "Idle")
		spark_light.light_energy = (randf_range(1, 4) * LK) if randf() < 0.15 else 0.0
		spark_light.position = Vector3(v.rx, 1.4, v.rz + 0.4)
	for m in vox_red:
		m.albedo_color = Color(1, 0.05, 0.02) * (4.0 if randf() < 0.9 else 0.2)
	red_light.light_energy = 0
	_render_item(t, roaming)
	anim_building(t, dt, roaming)
	env.ambient_light_energy = 0.55 if roaming else 0.35
	torch.visible = roaming
	torch_lens.albedo_color = Color("#fff3c4") if (G and G.flash) else Color("#333333")
	if roaming:
		torch.position.y = -0.24 + sin(G.rp.bob) * 0.01
	if egg_head.get_parent() == cam:
		egg_head.visible = roaming and (G.peace or G.egg != null)
		if G and G.egg == null and hud.inspect == null:
			egg_head.scale = Vector3.ONE
			egg_head.position = Vector3(-0.22, -0.3, -0.5)
			egg_head.rotation = Vector3(0.2, -0.4, 0)
	_render_inspect()
	if S == "scare":
		var k = ease_io(clampf(scene_t / 0.15, 0, 1))
		var j = 1 - clampf((scene_t - 0.8) / 0.6, 0, 1)
		cam.position = EYE
		cam.rotation = Vector3(-0.06, 0, 0)
		if G.killer == "V":
			# Voxie skočí přes stůl: stůl i počítač se převrhnou na tebe
			var fk = ease_io(clampf((scene_t - 0.12) / 0.45, 0, 1))
			var piv = Vector3(0, 0, EYE.z - 0.75)
			var rot = Transform3D(Basis(Vector3.RIGHT, 1.35 * fk).rotated(Vector3.UP, 0.25 * fk), Vector3.ZERO)
			for dp in desk_parts:
				var tr: Transform3D = dp[1]
				(dp[0] as Node3D).global_transform = Transform3D(Basis(), piv) * rot * Transform3D(Basis(), -piv) * tr
			if scene_t > 0.12 and scene_t - dt <= 0.12:
				audio.sfx("clunk", 1.2)
			VOX.visible = true
			VOX.position = EYE + Vector3(randf_range(-0.04, 0.04) * j, -EYE.y - 0.08 * k, -2.4 + 1.2 * k)
			VOX.rotation = Vector3(0, 0, (randf() - 0.5) * 0.12 * j)
			vox_pose_anim("Jumpscare", scene_t)
			var strobe = int(floor(scene_t * 18)) % 3
			tube.light_energy = (14.0 if strobe == 0 else 0.0) * LK
			tube.light_color = Color("#ff2020") if strobe == 1 else Color("#ffffff")
			red_light.light_energy = (10.0 if strobe == 1 else 2.0) * LK
			red_light.position = EYE + Vector3(0, -0.15, -0.8)
		else:
			COC.visible = true
			var hops = mini(3, int(floor(scene_t / 0.09)))
			COC.position = EYE + Vector3([1.5, -0.8, 0.2, 0.0][hops], -EYE.y - 0.2, -[3.4, 2.6, 1.8, 1.25][hops])
			var sp = clampf((scene_t - 0.3) / 0.25, 0, 1)
			COC.scale = Vector3(1 + sp * 0.6, 1 + sp * 0.15, 1)
			COC.rotation = Vector3(0, 0, sin(scene_t * 3) * 0.1)
			coc_eye_mat.albedo_color = Color.WHITE * (5.0 if fmod(scene_t, 0.2) < 0.15 else 0.0)
			coc_vis.scareT = scene_t
			tube.light_energy = 0
			flash.light_energy = 0
			env.ambient_light_energy = 0.02
		var sh = 0.09 * maxf(0, 1 - scene_t / 1.1)
		var fall = ease_io(clampf((scene_t - (0.55 if G.killer == "V" else 1.1)) / 0.35, 0, 1))
		cam.position += Vector3((randf() - 0.5) * sh, (randf() - 0.5) * sh - fall * 1.05, 0)
		cam.rotation = Vector3(-fall * 0.9, 0, (randf() - 0.5) * sh * 0.5 + fall * 0.7)
		flash.light_energy = 14 * LK if G.killer == "V" else 0.0
	else:
		tube.light_color = Color("#b8d0ff")
		COC.scale = Vector3.ONE
		if desk_parts.size() and (desk_parts[0][0] as Node3D).global_transform != desk_parts[0][1]:
			for dp in desk_parts:
				(dp[0] as Node3D).global_transform = dp[1]
	if COC.visible and S != "scare":
		coc_eye_mat.albedo_color = Color.WHITE * (0.2 if randf() < 0.06 else 3.0)
		COC.position.y = sin(t * 1.3) * 0.04 + 0.08
	show_light.light_energy = 0
	var view: Camera3D = cam
	if S == "extras" and hud.EX.page == "chars":
		view = show_cam
		show_light.light_energy = 40 * LK
		flash.light_energy = 0
		var isV = hud.EX.idx == 0
		VOX.visible = isV
		COC.visible = hud.EX.idx == 1
		HB_show.visible = hud.EX.idx == 2
		if hud.EX.idx == 2:
			var kb = ease_io(clampf(hud.EX.scare / 0.12, 0, 1)) if hud.EX.scare >= 0 else 0.0
			HB_show.position = Vector3(0, 0.3 - 0.3 * kb, 40 + 2.4 * kb)
			HB_show.scale = Vector3.ONE * 0.82
			HB_show.rotation = Vector3(0, 0.0 if hud.EX.scare >= 0 else hud.EX.rot, 0)
			HB_show.get_node("head").rotation = Vector3(0.12 + sin(t * 0.8) * 0.05, sin(t * 0.5) * 0.3, 0.06 + sin(t * 0.7) * 0.08)
		var ch: Node3D = VOX if isV else (COC if hud.EX.idx == 1 else HB_show)
		var k = ease_io(clampf(hud.EX.scare / 0.12, 0, 1)) if hud.EX.scare >= 0 else 0.0
		ch.position = Vector3(0, 0.3 - 0.3 * k, 40 + 2.4 * k)
		ch.rotation = Vector3(0, 0.0 if hud.EX.scare >= 0 else hud.EX.rot, 0)
		if isV:
			if hud.EX.scare >= 0:
				vox_pose_anim("Jumpscare", hud.EX.scare)
			else:
				vox_pose_anim(hud.EX.vAnim)
		if hud.EX.scare >= 0:
			red_light.light_energy = 6 * k * LK
			red_light.position = Vector3(0, 0.8, 43.6)
	else:
		HB_show.visible = false
	if S == "extras" and hud.EX.page == "chars":
		pass
	elif S in ["menu", "custom", "extras", "devmenu", "loading"]:
		VOX.visible = true
		COC.visible = false
		VOX.position = EYE + Vector3(0, -EYE.y, -4.9)
		VOX.rotation = Vector3.ZERO
		vox_pose_anim("Idle")
		cam.position = EYE
		cam.rotation = Vector3(-0.05, sin(t * 0.15) * 0.15, 0)
		flash.global_position = cam.global_position - Vector3(0, 0.2, 0)
		flash.look_at(EYE + Vector3(0, -0.4, -5))
		flash.light_energy = 14 * LK
	elif S == "boot":
		VOX.visible = false
		boot_cam(scene_t)
	if S == "home":
		home_cam(scene_t)
		VOX.visible = false
	if S == "finale":
		finale_scene(scene_t)
	if scenes.active():
		VOX.visible = false
		COC.visible = false
		scenes.render(t, dt)
		view = cam
	if COC.visible:
		coc_clip(t, dt)
		coc_bones_tick(t)
	if G and G.cut and S == "play":
		cut_pose(t, dt)
	coc_mat.set_shader_parameter("uT", t)
	# post-processing (zrno, vinětace, aberace, scanlines, glitch)
	var pm: ShaderMaterial = post.material
	pm.set_shader_parameter("uT", t)
	pm.set_shader_parameter("uScan", 1.0 if (S == "play" and G and G.mon) else 0.0)
	var sc = scene_t if S == "scare" else (hud.EX.scare if (S == "extras" and hud.EX.scare >= 0) else -1.0)
	pm.set_shader_parameter("uCA", 0.012 * maxf(0, 1 - sc) if sc >= 0 else 0.002)
	pm.set_shader_parameter("uGlitch", (1.0 if (sc < 0.15 or (sc > 0.6 and sc < 0.75) or randf() < 0.25) else 0.2) if sc >= 0 else 0.0)
	pm.set_shader_parameter("uGrain", 0.18 + maxf(0, sc - 1.1) * 1.2 if sc >= 0 else 0.04)
	post.visible = S in ["arrest", "prison", "play", "scare", "menu", "custom", "extras", "devmenu", "home", "finale", "boot"]
	view.current = true
	# záběr kamery do počítače
	if S == "play" and G and G.mon and G.monA >= 1 and online(G.cam):
		var cp = D.CAMPOS[G.cam]
		feed_cam.global_position = v3(cp.pos)
		feed_cam.look_at(v3(cp.look))
		feed_cam.rotate_y(sin(t * 0.25) * 0.18)
		feed_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		env.ambient_light_energy = 2.0
		feed_light.light_energy = 1.4
	else:
		feed_light.light_energy = 0.0
		feed_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	hud.queue_redraw()

## prohlídka předmětu z inventáře: předmět ve 3D před kamerou, otáčí se tažením prstu
var insp_prev = null
func _render_inspect() -> void:
	var I = hud.inspect
	if insp_prev != null and (I == null or I.id != insp_prev):
		var old = _insp_node(insp_prev)
		if old:
			old.scale = Vector3.ONE * (1.2 if insp_prev == "can" else 1.0)
			old.visible = false
		insp_light.light_energy = 0.0
		if insp_prev == "head":
			egg_head.position = Vector3(-0.22, -0.3, -0.5)
			egg_head.rotation = Vector3(0.2, -0.4, 0)
			egg_head.scale = Vector3.ONE
	insp_prev = I.id if I != null else null
	if I == null:
		return
	var n = _insp_node(I.id)
	if n == null:
		return
	n.visible = true
	insp_light.light_energy = 2.5
	var dist = 0.55
	var sc = {"head": 1.6, "can": 0.7, "draw": 1.0}.get(I.id, 1.4)
	var rot = Basis.from_euler(Vector3(I.get("rx", 0.1), I.get("ry", 0.0), 0))
	if n.get_parent() == cam:
		n.position = Vector3(-0.15, -0.02, -dist)
		n.basis = rot.scaled(Vector3.ONE * sc)
	else:
		var b = cam.global_transform.basis
		var off = Vector3(0, -0.15, 0) if I.id == "can" else Vector3.ZERO
		n.global_transform = Transform3D(b * rot.scaled(Vector3.ONE * sc), cam.global_position + b * (Vector3(-0.15, -0.02, -dist) + off))
func _insp_node(id):
	match id:
		"head": return egg_head
		"can": return can_m
		"draw": return draw3d
	if String(id).begins_with("photo"):
		return photo_nodes[int(String(id).right(1))]
	return null

func _render_item(t: float, roaming: bool) -> void:
	var st = cur_task() if G else null
	item_node.visible = roaming and st != null
	if not item_node.visible:
		return
	var r = RROOMS[st.room]
	var heart = st.kind == "flash"
	item_node.get_node("box").visible = not heart
	item_node.get_node("heart").visible = heart
	item_mat.albedo_color = st.col
	item_light.light_color = st.col
	item_node.position = Vector3(r.cx, 1.0 if heart else 0.6 + sin(t * 2) * 0.08, r.cz)
	item_node.rotation.y = t
	var k = 1 + maxf(0, sin(t * 7)) * 0.25 * (1 - G.hold / st.t) if heart else 1.0
	item_node.scale = Vector3.ONE * k

func finale_scene(t: float) -> void:
	var K = D.FIN_CAM
	var i = 0
	while i < K.size() - 2 and t > K[i + 1][0]:
		i += 1
	var a = K[i]
	var b = K[i + 1]
	var k = ease_io(clampf((t - a[0]) / (b[0] - a[0]), 0, 1))
	var p = v3(a[1]).lerp(v3(b[1]), k)
	var l = v3(a[2]).lerp(v3(b[2]), k)
	var walking = t < 11 or t > 34
	cam.position = Vector3(p.x, p.y + (sin(t * 10) * 0.03 if walking else 0.0), p.z + RZ)
	cam.look_at(Vector3(l.x, l.y, l.z + RZ))
	COC.visible = t > 9 and t < 22.5
	coc_light.light_energy = 2.0 * LK if COC.visible else 0.0
	COC.position = Vector3(-7, 0, -17 + RZ)
	# Hollow Bunny v rohu pizzerie, otáčí hlavu za kamerou a pak zmizí
	HB.visible = t > 34.5 and t < 40.6 and not (t > 39.8 and randf() < 0.5)
	if HB.visible:
		HB.position = Vector3(-14.4, 0, -12.6 + RZ)
		HB.rotation.y = PI * 0.45
		var hd = HB.get_node("head")
		var to = cam.global_position - HB.global_position
		hd.rotation.y = clampf(wrapf(atan2(to.x, to.z) - HB.rotation.y, -PI, PI), -1.0, 1.0) * clampf((t - 37) / 1.5, 0, 1)
	COC.rotation.y = atan2(cam.position.x - COC.position.x, cam.position.z - COC.position.z)
	coc_mat.set_shader_parameter("uOp", clampf(0.85 - maxf(0, t - 19.5) * 0.3, 0, 0.85) + sin(t * 6) * 0.05)
	coc_vis.force = ["Vanish", 1.05 + clampf((t - 19.5) / 2.5, 0, 1) * 0.6] if t > 19.5 else ["Idle", t]
	var from = Vector2(0, -23)
	var stop = Vector2(-1.6, -18.5)
	var vp = null
	var moving = false
	var face = 0.0
	if t > 23 and t < 26.5:
		vp = from.lerp(stop, (t - 23) / 3.5)
		moving = true
		face = atan2(stop.x - from.x, stop.y - from.y)
	elif t >= 26.5 and t < 30.5:
		vp = stop
		face = atan2(cam.position.x - stop.x, cam.position.z - RZ - stop.y)
	elif t >= 30.5 and t < 35:
		vp = stop.lerp(from, (t - 30.5) / 4.5)
		moving = true
		face = atan2(from.x - stop.x, from.y - stop.y)
	VOX.visible = vp != null
	if vp != null:
		VOX.position = Vector3(vp.x, absf(sin(t * 5.5)) * 0.07 if moving else 0.0, vp.y + RZ)
		VOX.rotation = Vector3(0, face, sin(t * 5.5) * 0.06 if moving else 0.03)
		vox_pose_anim("Limp" if moving else "Idle")
	flash.global_position = cam.global_position - Vector3(0, 0.2, 0)
	flash.look_at(cam.global_position - cam.global_transform.basis.z * 6)
	flash.light_energy = 30 * LK
	env.ambient_light_energy = 0.5
	if not (G and G.heartOff) and t > 46:
		var kk = ease_io(clampf((t - 46) / 1.6, 0, 1))
		var an = PI * kk
		cam.position = Vector3(-16, 1.6, 4.2 + RZ)
		cam.look_at(Vector3(-16 + sin(an) * 3, 1.4 - kk * 0.1, 4.2 + RZ + cos(an) * 3))
		VOX.visible = true
		VOX.position = Vector3(-15.6, 0, -2.2 + RZ - maxf(0, 50 - t) * 0.3)
		VOX.rotation = Vector3(0, 0, 0.04)
		vox_pose_anim("Idle")
		flash.light_energy = (0.0 if t > 48.2 else 30.0 * (0.2 if randf() < 0.3 else 1.0)) * LK
		red_light.light_energy = 3 * LK
		red_light.position = Vector3(-15.6, 1.5, -1.6 + RZ)

func cut_pose(t: float, dt: float) -> void:
	var c = G.cut
	var p = G.rp
	var v = G.vox
	var ct: float = c.t
	torch.visible = false
	if c.k == "hs" or c.k == "photo":
		cam.position = Vector3(p.x, 1.5, p.z)
		cam.rotation = Vector3(-0.04, p.yaw, 0)
		VOX.visible = true
		VOX.position = Vector3(v.rx, 0, v.rz)
		VOX.rotation = Vector3(0, v.face, 0.03)
		vox_pose_anim("Idle")
		var k = ease_io(clampf(ct / 1.6, 0, 1))
		var arm = vox_model.find_child("arm_upper_R_stump", true, false)
		if arm:
			arm.rotation.x -= 1.2 * k
		var head = vox_model.find_child("head", true, false)
		if head:
			head.rotation.z += 0.25 * ease_io(clampf((ct - 3) / 2, 0, 1))
		hand.visible = ct < 15
		hand.position = Vector3(0.16, -0.26, -0.2 - 0.5 * k)
		var fw = Vector3(-sin(p.yaw), 0, -cos(p.yaw))
		var rt = Vector3(cos(p.yaw), 0, -sin(p.yaw))
		if c.k == "hs":
			var dk = ease_io(clampf((ct - 3) / 1.5, 0, 1))
			draw3d.visible = ct > 3
			draw3d.scale = Vector3.ONE * maxf(0.01, dk)
			draw3d.global_position = Vector3(p.x + fw.x, 1.15 + sin(ct * 1.5) * 0.02, p.z + fw.z)
			draw3d.look_at(cam.global_position)
			draw3d.rotate_object_local(Vector3.UP, PI)
			var ck = clampf((ct - 8.4) / 1.5, 0, 1) * (1 - clampf((ct - 16) / 2, 0, 1))
			COC.visible = ck > 0.01
			COC.position = Vector3(v.rx + rt.x * 1.2, 0, v.rz + rt.z * 1.2)
			COC.rotation.y = atan2(p.x - COC.position.x, p.z - COC.position.z)
			coc_mat.set_shader_parameter("uOp", 0.85 * ck)
			coc_vis.force = ["Vanish", 1.05 + clampf((ct - 16) / 2, 0, 1) * 0.6] if ct > 16 else (["Vanish", ck * 0.45] if ck < 1 else ["Idle", ct])
		else:
			# fotky v ruce, pak u Voxieho
			for i in photo_nodes.size():
				var ph: Node3D = photo_nodes[i]
				ph.visible = ct < 6 and i < c.n
				ph.global_position = cam.global_position + fw * (0.6 + 0.25 * k) + rt * (-0.1 + i * 0.1) + Vector3(0, -0.15 + i * 0.01, 0)
				ph.look_at(cam.global_position)
				ph.rotate_object_local(Vector3.UP, PI)
			if ct > 12.4:
				v.moving = true
				v.ph += dt * 5.5
				var r = RROOMS["1A"]
				var d = Vector2(r.cx - v.rx, r.cz - v.rz)
				if d.length() > 0.3:
					v.face = atan2(d.x, d.y)
					v.rx += d.normalized().x * dt * 0.9
					v.rz += d.normalized().y * dt * 0.9
				VOX.position = Vector3(v.rx, 0, v.rz)
				VOX.rotation.y = v.face
				vox_pose_anim("Limp")
		flash.light_energy = 16 * LK
	else:
		var outside = ct >= 10.4
		var door = D.G1["7"].z1 + RZ
		exit_g.visible = false
		VOX.visible = false
		COC.visible = false
		var n = int(floor((900 if outside else 520) * clampf((ct - 2.8) / 6, 0, 1)))
		var mm = fl_mm.multimesh
		mm.visible_instance_count = n
		if not outside:
			cam.position = Vector3(p.x + ((randf() - 0.5) * 0.03 if ct > 5 else 0.0), 1.5, p.z)
			var pk = ease_io(clampf(ct / 3.2, 0, 1))
			cam.rotation = Vector3(-0.8 * (1 - pk) - 0.1 * pk, p.yaw, 0)
			can_hand.visible = ct < 3.6
			can_hand.position = Vector3(0.32, -0.4, -0.65)
			can_hand.rotation = Vector3(0, 0.4, -1.2 * sin(clampf(ct / 3, 0, 1) * PI))
			fire_light.position = Vector3(p.x, 1.4, p.z)
			fire_light.light_energy = 70 * clampf((ct - 3) / 4, 0, 1) * (0.8 + randf() * 0.4) * LK
			flash.light_energy = 10 * LK
			for i in n:
				var y = fl_pos[i].y
				if fl_vel[i] == 0 or y > 3.6:
					var a = randf() * TAU
					var r = sqrt(randf()) * 8
					fl_pos[i] = Vector3(p.x + cos(a) * r, randf() * 0.3, p.z + sin(a) * r)
					fl_vel[i] = 0.8 + randf() * 1.6
				fl_pos[i].y += fl_vel[i] * dt
				mm.set_instance_transform(i, Transform3D(Basis(), fl_pos[i]))
		else:
			can_hand.visible = false
			out_ground.visible = true
			out_ground.position = Vector3(-16, -0.02, door - 10)
			cam.position = Vector3(-16, 1.65, door + 7.5 - ct * 0.04)
			cam.look_at(Vector3(-16, 2.8, door - 12))
			fire_light.position = Vector3(-16, 3, door - 3)
			fire_light.light_energy = 120 * (0.8 + randf() * 0.4) * LK
			flash.light_energy = 0
			env.ambient_light_energy = 0.5
			for i in n:
				var y = fl_pos[i].y
				if fl_vel[i] == 0 or y > 5 or c.lim != 1:
					fl_pos[i] = Vector3(randf_range(-26, 8), randf() * 1.5, randf_range(door - 30, door))
					fl_vel[i] = 1 + randf() * 1.8
				fl_pos[i].y += fl_vel[i] * dt
				mm.set_instance_transform(i, Transform3D(Basis(), fl_pos[i]))
			c.lim = 1
			var gk = ease_io(clampf((ct - 11.6) / 2, 0, 1))
			var turn = ease_io(clampf((ct - 14) / 1.2, 0, 1))
			var fade = 1 - clampf((ct - 21.5) / 2.5, 0, 1)
			for j in 2:
				var g: Node3D = ghosts[j]
				var x = [-17.1, -15.4][j]
				g.visible = true
				g.position = Vector3(x, sin(ct * 1.3 + x) * 0.05, door + 3.6)
				g.rotation.y = PI * (1 - turn)
				var gm: StandardMaterial3D = g.get_meta("mat")
				gm.albedo_color.a = 0.5 * gk * fade

## nástroj: uloží celou zbořenou mapu (budova + díra + suť + kancelář s novým monitorem) do jednoho GLB
func make_map() -> void:
	for mi in building.find_children("*", "MeshInstance3D", true, false):
		if not (mi as MeshInstance3D).visible:
			mi.get_parent().remove_child(mi)
			mi.free()
	var doc = GLTFDocument.new()
	var st = GLTFState.new()
	var err = doc.append_from_scene(building, st)
	if err == OK:
		err = doc.write_to_filesystem(st, "res://models/broken_map.glb")
	print("MAKEMAP ", err)
	get_tree().quit()
