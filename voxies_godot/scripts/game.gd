extends Node3D
## Night at Voxie's Remastered – Godot port. Logika je převedená 1:1 z webového Remasteru.

const Rig := preload("res://scripts/rig.gd")
const HOUR := 70.0
const MOVE_INT := 5.0
const H := 3.2
const DOOR_H := 2.5
const OFFICE_EYE := Vector3(0, 1.35, 1.9)
const DESK_SPOT := Vector3(0, 0, 2.2)
const SHOW_Z := 44.0
# poměr intenzit světel three.js -> Godot
const LK := 0.16

var T: Dictionary                 # texty a data z Remasteru (data/texts.json)
var AUD: Dictionary               # zvuky a hlasy (data/audio.json)
var ROOMS: Dictionary
var CAMS: Dictionary
var SPOTS: Dictionary
var NEXT: Dictionary

var scene_ = "loading"
var scene_t = 0.0
var G = null
var scare_t = -1.0
var killer = null
var progress = 1
var beaten = false
var speech = null
var CUSTOM = {"v": 10, "c": 6, "cocPassive": false, "voxBoth": false, "damaged": false}
var DEV = {"on": false, "panel": false, "god": false, "freeze": false, "noclip": false, "map": true, "msg": "", "msgT": 0.0}
var store = {}
var look_target = null
var frame_dt = 1.0 / 60.0
var t_now = 0.0

# 3D
var world: Node3D
var office = {}
var office_cam: Camera3D
var cams3d = {}
var roam_cam: Camera3D
var show_cam: Camera3D
var env: Environment
var hemi_amb = 0.55
var office_lamp: OmniLight3D
var room_light: OmniLight3D
var hall_l: SpotLight3D
var hall_r: SpotLight3D
var red_light: OmniLight3D
var stage_spot: SpotLight3D
var stage_fill: OmniLight3D
var door_glow: OmniLight3D
var spark_light: OmniLight3D
var flash: SpotLight3D
var crt_img: Image
var crt_tex: ImageTexture
var crt_font: Font
var paper: MeshInstance3D
var coco_pizza: Node3D
var pizza_desk: Node3D
var axe_mesh: Node3D
var held_axe: Node3D
var oven_mouth: OmniLight3D
var order_ticket: Node3D
var rack_leds = []
var hall_flicker = []
var glitch_t = 0.0

var VOX: Rig
var COC: Rig
var vox_eyes = []
var coco_heads = []
var COCO_TEX = {}
var cocoa_hold = 0
var blink_t = 4.0

var hud: Control
var audio: Node

# ====================================================================
#  START
# ====================================================================
func _ready() -> void:
	T = JSON.parse_string(FileAccess.get_file_as_string("res://data/texts.json"))
	AUD = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio.json"))
	ROOMS = T.ROOMS
	CAMS = T.CAMS
	SPOTS = T.SPOTS
	NEXT = T.NEXT
	_load_store()
	progress = st_get("voxies_night", 1)
	beaten = st_get("voxies_beaten", false)
	for k in st_get("voxies_custom", {}):
		CUSTOM[k] = st_get("voxies_custom", {})[k]
	DEV.on = st_get("voxies_dev", false)
	audio = preload("res://scripts/audio.gd").new()
	audio.game = self
	add_child(audio)
	_build_scene()
	_build_nav()
	hud = preload("res://scripts/hud.gd").new()
	hud.game = self
	var layer = CanvasLayer.new()
	add_child(layer)
	layer.add_child(hud)
	menu_spots()
	scene_ = "menu"
	scene_t = 0.0
	audio.start_menu_song()
	if "--shots" in OS.get_cmdline_user_args():
		_shots()

# ---------- ukládání (jako localStorage) ----------
func _load_store() -> void:
	if FileAccess.file_exists("user://voxies.json"):
		var d = JSON.parse_string(FileAccess.get_file_as_string("user://voxies.json"))
		if d is Dictionary:
			store = d
func st_get(k: String, d):
	return store.get(k, d)
func st_set(k: String, v) -> void:
	store[k] = v
	var f = FileAccess.open("user://voxies.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(store))

static func ease_io(t: float) -> float:
	return 2.0 * t * t if t < 0.5 else 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0
static func pick(a: Array):
	return a[randi() % a.size()]
static func v3(a) -> Vector3:
	return Vector3(a[0], a[1], a[2])

# ====================================================================
#  SCÉNA
# ====================================================================
func _build_scene() -> void:
	var we = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.004, 0.016)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#6a5aa0").lerp(Color("#120a1c"), 0.4)
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.008, 0.004, 0.016)
	env.fog_depth_begin = 6.0
	env.fog_depth_end = 30.0
	env.fog_density = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	we.environment = env
	add_child(we)
	world = load("res://models/remaster_world.glb").instantiate()
	add_child(world)
	for l in world.find_children("*", "Light3D", true, false):
		l.queue_free()
	office.crt = world.find_child("CRT", true, false)
	office.phone_led = world.find_child("PhoneLed", true, false)
	office.blades = world.find_child("FanBlades", true, false)
	office.shutL = world.find_child("ShutL", true, false)
	office.shutR = world.find_child("ShutR", true, false)
	for k in ["PanLD", "PanLL", "PanRD", "PanRL"]:
		var m: MeshInstance3D = _first_mesh(world.find_child(k, true, false))
		office[k] = _own_unshaded(m)
	office.led_mat = _own_unshaded(_first_mesh(office.phone_led))
	for i in 8:
		var l: Node = world.find_child("RackLed" + str(i), true, false)
		if l:
			rack_leds.append(_own_unshaded(_first_mesh(l)))
	for s in ["L", "R"]:
		var hf: Node = world.find_child("HallFlicker" + s, true, false)
		if hf:
			hall_flicker.append(_own_unshaded(_first_mesh(hf)))
	# CRT monitor: živá textura
	crt_img = Image.create(256, 192, false, Image.FORMAT_RGBA8)
	crt_tex = ImageTexture.create_from_image(crt_img)
	crt_font = make_font()
	var crt_m = _first_mesh(office.crt)
	if crt_m:
		var cm = StandardMaterial3D.new()
		cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cm.albedo_texture = _crt_viewport_tex()
		cm.uv1_scale = Vector3(1, -1, 1)
		crt_m.material_override = cm
	# světla jako v Remasteru
	office_cam = Camera3D.new()
	office_cam.fov = 72
	office_cam.near = 0.05
	office_cam.far = 80
	office_cam.position = OFFICE_EYE
	add_child(office_cam)
	office_cam.rotation_order = EULER_ORDER_YXZ
	office_lamp = _omni(Color("#ffd9a0"), 9, 9, Vector3(0, 2.8, 0.4))
	office_lamp.shadow_enabled = true
	room_light = _omni(Color("#fff0d8"), 18, 26, Vector3.ZERO)
	hall_l = _spot(Color("#ffe7b0"), 0, 14, 0.55, Vector3(-5, 2.9, 1.2), Vector3(-5, 0, -2.5))
	hall_r = _spot(Color("#ffe7b0"), 0, 14, 0.55, Vector3(5, 2.9, 1.2), Vector3(5, 0, -2.5))
	red_light = _omni(Color(1, 0.06, 0.06), 0, 6, Vector3.ZERO)
	stage_spot = _spot(Color(1, 0, 1), 0, 40, 0.75, Vector3(0, 3.8, -23.2), Vector3(0, 0.5, -27.6))
	stage_fill = _omni(Color(1, 0, 1), 0, 14, Vector3(0, 3.2, -26))
	door_glow = _omni(Color("#a0c0ff"), 0, 4, Vector3(-4.6, 1.9, 0))
	spark_light = _omni(Color("#8fd0ff"), 0, 6, Vector3.ZERO)
	for id in CAMS:
		var c: Dictionary = CAMS[id]
		var cam = Camera3D.new()
		cam.fov = 68
		cam.near = 0.05
		cam.far = 60
		add_child(cam)
		cam.look_at_from_position(v3(c.pos), v3(c.look))
		cams3d[id] = {"cam": cam, "baseQ": cam.quaternion}
	roam_cam = Camera3D.new()
	roam_cam.fov = 72
	roam_cam.near = 0.05
	roam_cam.far = 60
	roam_cam.rotation_order = EULER_ORDER_YXZ
	add_child(roam_cam)
	flash = SpotLight3D.new()
	flash.light_color = Color("#fff3d0")
	flash.spot_range = 16
	flash.spot_angle = rad_to_deg(0.42)
	flash.spot_angle_attenuation = 0.55
	flash.light_energy = 0
	flash.shadow_enabled = true
	add_child(flash)
	show_cam = Camera3D.new()
	show_cam.fov = 42
	add_child(show_cam)
	show_cam.look_at_from_position(Vector3(2.4, 1.4, SHOW_Z + 6.4), Vector3(1.5, 1.05, SHOW_Z))
	_build_props()
	_build_chars()
	_build_n4()
	_build_sparks()

func _first_mesh(n: Node) -> MeshInstance3D:
	if n == null:
		return null
	if n is MeshInstance3D:
		return n
	for c in n.find_children("*", "MeshInstance3D", true, false):
		return c
	return null

func _own_unshaded(m: MeshInstance3D) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if m:
		var src = m.get_active_material(0)
		if src is StandardMaterial3D:
			mat.albedo_color = src.albedo_color
		m.material_override = mat
	return mat

func _omni(c: Color, e: float, r: float, p: Vector3) -> OmniLight3D:
	var l = OmniLight3D.new()
	l.light_color = c
	l.light_energy = e * LK
	l.omni_range = r
	l.position = p
	add_child(l)
	return l

func _spot(c: Color, e: float, r: float, ang: float, p: Vector3, tgt: Vector3) -> SpotLight3D:
	var l = SpotLight3D.new()
	l.light_color = c
	l.light_energy = e * LK
	l.spot_range = r
	l.spot_angle = rad_to_deg(ang)
	l.spot_angle_attenuation = 0.5
	add_child(l)
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

## model postavený na zem, vycentrovaný, s danou výškou
func place_model(path: String, h: float, pos: Vector3, yaw: float, parent: Node3D = null) -> Node3D:
	var holder = Node3D.new()
	(parent if parent else self).add_child(holder)
	var m: Node3D = load(path).instantiate()
	holder.add_child(m)
	var a = _aabb(m)
	var k: float = h / maxf(a.size.y, 0.001)
	m.scale = Vector3.ONE * k
	m.position = Vector3(-(a.position.x + a.size.x / 2.0) * k, -a.position.y * k, -(a.position.z + a.size.z / 2.0) * k)
	holder.position = pos
	holder.rotation.y = yaw
	return holder

func _build_props() -> void:
	# --- kuchyně pizzerie: pec s lopatou (nahrazuje starou krabicovou pec), objednávkový lístek (místo terminálu) ---
	place_model("res://models/nove/pizza_pec.glb", 1.9, Vector3(-20.75, 0, -17), PI / 2)
	oven_mouth = _omni(Color("#ff6a1a"), 0, 4, Vector3(-20.0, 0.9, -17))
	order_ticket = place_model("res://models/nove/objednavka.glb", 0.32, Vector3(-16, 1.1, -21.0), 0)
	# pizza na stole v kanceláři (úkol 3. noci) a pizza, kterou nosí Cocoa
	pizza_desk = place_model("res://models/nove/pizza_cela.glb", 0.05, Vector3(-0.5, 0.82, 0.35), 0)
	pizza_desk.visible = false
	coco_pizza = place_model("res://models/nove/pizza_cela.glb", 0.05, Vector3(0.8, 0.84, 0.55), 0)
	coco_pizza.visible = false
	for p in [[-19, -18, 0], [-15, -13, 1], [-12, -15.5, 0]]:
		if p[2] == 0:
			place_model("res://models/nove/pizza_cela.glb", 0.05, Vector3(p[0], 0.83, p[1]), randf() * TAU)
		else:
			for j in 2:
				place_model("res://models/nove/pizza_kousek.glb", 0.035, Vector3(p[0] + (j - 0.5) * 0.4, 0.83, p[1] + 0.15), randf() * TAU)
	# --- vchod: nová fialová pokladna místo staré krabicové (Kapitán Ticket ve výdeji lístků zůstává) ---
	for mi in world.find_children("*", "MeshInstance3D", true, false):
		var ab: AABB = mi.global_transform * mi.get_aabb()
		var c: Vector3 = ab.get_center()
		if c.x > -15.1 and c.x < -12.0 and c.z > -1.3 and c.z < 1.3 and c.y < 2.6 and ab.size.y < 3.0:
			mi.visible = false
	var pk = place_model("res://models/nove/pokladna.glb", 2.4, Vector3(-13.45, 0, -0.2), 0)
	var a = _aabb(pk)
	OBST.append({"x0": a.position.x, "z0": a.position.z, "x1": a.end.x, "z1": a.end.z, "ai": true, "hop": false})
	# --- kancelář pana Vojtěcha (zamčená místnost X za skladem) ---
	place_model("res://models/nove/psaci_stul.glb", 0.82, Vector3(16.0, 0, 3.6), PI)
	place_model("res://models/nove/zidle.glb", 1.05, Vector3(16.0, 0, 4.7), PI)
	place_model("res://models/nove/knihovna.glb", 2.1, Vector3(21.55, 0, 1.4), -PI / 2)
	place_model("res://models/nove/trezor.glb", 0.95, Vector3(21.2, 0, 5.2), -PI * 0.75)
	place_model("res://models/nove/kartoteka.glb", 1.35, Vector3(10.55, 0, 4.6), PI / 2)
	place_model("res://models/nove/kartoteka.glb", 1.35, Vector3(10.55, 0, 3.6), PI / 2)
	var vl = _omni(Color("#ffcf8a"), 6, 7, Vector3(16, 2.6, 2.8))
	vl.shadow_enabled = true
	# --- sekera (noc 7) a sekera v ruce ---
	axe_mesh = place_model("res://models/axe.glb", 1.0, Vector3(21.2, 0, -6.5), 0)
	axe_mesh.rotation.z = 0.25
	axe_mesh.visible = false
	held_axe = Node3D.new()
	roam_cam.add_child(held_axe)
	held_axe.position = Vector3(0.38, -0.42, -0.7)
	held_axe.rotation = Vector3(0.3, 0, -0.25)
	var ha = place_model("res://models/axe.glb", 0.75, Vector3(0, -0.3, 0), 0, held_axe)
	held_axe.visible = false
	# noviny na zdi kanceláře
	paper = MeshInstance3D.new()
	var pm = QuadMesh.new()
	pm.size = Vector2(0.7, 0.45)
	paper.mesh = pm
	paper.position = Vector3(-1.3, 1.05, -2.92)
	paper.rotation.z = -0.05
	add_child(paper)

func _crt_viewport_tex() -> Texture2D:
	# SubViewport s 2D kreslením obrazovky VOXIE-OS
	var sv = SubViewport.new()
	sv.size = Vector2i(256, 192)
	sv.transparent_bg = false
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sv)
	var cv = preload("res://scripts/crt.gd").new()
	cv.game = self
	sv.add_child(cv)
	office.crt_canvas = cv
	return sv.get_texture()

func set_paper(n: int) -> void:
	var sv = SubViewport.new()
	sv.size = Vector2i(448, 288)
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(sv)
	var bg = ColorRect.new()
	bg.color = Color("#d8d2c0")
	bg.size = Vector2(448, 288)
	sv.add_child(bg)
	var l = Label.new()
	l.text = T.PAPER[n - 1] if n - 1 < T.PAPER.size() else T.PAPER[0]
	l.add_theme_font_override("font", crt_font)
	l.add_theme_font_size_override("font_size", 46)
	l.add_theme_color_override("font_color", Color("#111111"))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(448, 288)
	sv.add_child(l)
	var m = StandardMaterial3D.new()
	m.albedo_texture = sv.get_texture()
	paper.material_override = m

# ====================================================================
#  POSTAVY
# ====================================================================
const NAME_RULES := {
	"hips": ["^Bone_?28$", "hips", "pelvis"], "spine": ["Bone_?006", "spine_?0?1?$"], "chest": ["Bone_?007", "spine_?2|chest"], "head": ["Bone_?013", "head$", "neck"],
	"armR1": ["Bone_?009_?r", "right_?arm$|rightarm$|upperarm_?r"], "armR2": ["Bone_?010_?r", "right_?fore_?arm|forearm_?r"], "armR3": ["Bone_?011_?r", "right_?hand$|hand_?r"],
	"armL1": ["Bone_?009_?l", "left_?arm$|leftarm$|upperarm_?l"], "armL2": ["Bone_?010_?l", "left_?fore_?arm|forearm_?l"], "armL3": ["Bone_?011_?l", "left_?hand$|hand_?l"],
	"legR1": ["Bone_?002_?r", "right_?up_?leg|thigh_?r"], "legR2": ["Bone_?003_?r", "right_?leg$|calf_?r"], "legL1": ["Bone_?002_?l", "left_?up_?leg|thigh_?l"], "legL2": ["Bone_?003_?l", "left_?leg$|calf_?l"],
	"earR1": ["Bone_?015_?r"], "earL1": ["Bone_?015_?l"], "jaw": ["jaw", "mouth"],
}

func _polish(n: Node) -> void:
	# lesklý „plastový" materiál jako polishMats v Remasteru
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in m.get_surface_override_material_count():
			var src = m.get_active_material(s)
			if src is StandardMaterial3D and src.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED:
				var p: StandardMaterial3D = src.duplicate()
				p.roughness = 0.2
				p.metallic = 0.25
				p.clearcoat_enabled = true
				p.clearcoat = 1.0
				p.clearcoat_roughness = 0.1
				p.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.set_surface_override_material(s, p)

func _build_chars() -> void:
	# Voxie z Remasteru (klouby jsou Node3D)
	VOX = Rig.new()
	VOX.name = "Voxie"
	VOX.root = Node3D.new()
	add_child(VOX.root)
	VOX.model = load("res://models/voxie.glb").instantiate()
	VOX.root.add_child(VOX.model)
	_polish(VOX.model)
	for role in ["hips", "chest", "head", "legR1", "legR2", "legL1", "legL2", "armR1", "armR2", "armR3", "armL1", "armL2", "armL3"]:
		var nd: Node = VOX.model.find_child(role, true, false)
		if nd:
			VOX.joints[role] = {"n": nd}
	if VOX.joints.has("chest"):
		VOX.joints["spine"] = VOX.joints.chest
	var ears = []
	for e in VOX.model.find_children("ear*", "Node3D", true, false):
		ears.append(e)
	if ears.size() >= 2:
		VOX.joints["earR1"] = {"n": ears[0]}
		VOX.joints["earL1"] = {"n": ears[1]}
	for e in VOX.model.find_children("VoxEye*", "Node3D", true, false):
		vox_eyes.append(_own_unshaded(_first_mesh(e)))
	for m in vox_eyes:
		m.albedo_color = Color("#111111")
	VOX.capture_rest()
	_measure_side(VOX)
	# Cocoa (GLB s kostrou)
	COC = Rig.new()
	COC.name = "Cocoa"
	COC.C.nice = true
	COC.root = Node3D.new()
	add_child(COC.root)
	COC.model = load("res://models/cocoa.glb").instantiate()
	COC.root.add_child(COC.model)
	_polish(COC.model)
	var a = _aabb(COC.model)
	var s: float = 1.85 / a.size.y
	COC.model.scale = Vector3.ONE * s
	COC.model.position = Vector3(-(a.position.x + a.size.x / 2) * s, -a.position.y * s, -(a.position.z + a.size.z / 2) * s)
	var sk: Skeleton3D = COC.model.find_children("*", "Skeleton3D", true, false)[0]
	for role in NAME_RULES:
		for re_s in NAME_RULES[role]:
			var re = RegEx.create_from_string("(?i)" + re_s)
			var found = -1
			for i in sk.get_bone_count():
				if re.search(sk.get_bone_name(i).replace(".", "")):
					found = i
					break
			if found >= 0:
				COC.joints[role] = {"sk": sk, "i": found}
				break
	COC.capture_rest()
	_measure_side(COC)
	# mrkání: textury open/blink na hlavě
	COCO_TEX.open = load("res://models/cocoa_open.png")
	COCO_TEX.blink = load("res://models/cocoa_blink.png")
	COCO_TEX.hurt = load("res://models/cocoa_hurt.png")
	var heads = []
	for mi in COC.model.find_children("*", "MeshInstance3D", true, false):
		if String(mi.name).begins_with("Head") or String(mi.get_parent().name).begins_with("Head"):
			heads.append(mi)
	if heads.is_empty():
		heads = COC.model.find_children("*", "MeshInstance3D", true, false)
	for mi in heads:
		var m: MeshInstance3D = mi
		for si in m.mesh.get_surface_count():
			var src = m.get_active_material(si)
			if src is StandardMaterial3D and src.albedo_texture != null:
				var own: StandardMaterial3D = src.duplicate()
				m.set_surface_override_material(si, own)
				coco_heads.append(own)
	cocoa_set_eyes(false)
	COC.root.visible = false

func _measure_side(ch: Rig) -> void:
	ch.root.position = Vector3.ZERO
	ch.root.rotation = Vector3.ZERO
	for k in ["R", "L"]:
		if ch.has("arm" + k + "1"):
			var p = ch.root.to_local(ch.wpos(ch.joints["arm" + k + "1"]))
			ch.side[k] = signf(p.x) if p.x != 0 else (-1.0 if k == "R" else 1.0)

func cocoa_set_eyes(closed: bool) -> void:
	var t: Texture2D = COCO_TEX.blink if closed else COCO_TEX.open
	for m in coco_heads:
		m.albedo_texture = t

func set_spot(ch: Rig, id: String) -> void:
	var s: Dictionary = SPOTS[id]
	ch.root.position = v3(s.p)
	if s.has("yaw"):
		ch.root.rotation.y = s.yaw
	else:
		var c: Array = CAMS[s.cam].pos
		ch.root.rotation.y = atan2(c[0] - s.p[0], c[2] - s.p[2]) + randf_range(-0.3, 0.3)

func menu_spots() -> void:
	set_spot(VOX, "1A")
	set_spot(COC, "m1A")
	VOX.root.visible = true
	COC.root.visible = true

# ====================================================================
#  STAV HRY A AI
# ====================================================================
var AI = {}
func _ai_def(id: String) -> Dictionary:
	if AI.is_empty():
		AI = {
			"V": {"ch": VOX, "side": "L", "start": "1A", "door": "DOOR", "hall": "8", "back": ["2", "1B"], "levels": T.VOX_LEVELS, "lines": T.LINES_V, "pitch": 190, "f": false, "nice": false},
			"C": {"ch": COC, "side": "R", "start": "c3", "door": "cDOOR", "hall": "c9", "back": ["c3", "c4"], "levels": T.COC_LEVELS, "lines": T.LINES_C, "pitch": 340, "f": true, "nice": true},
		}
	return AI[id]

func D(a: Dictionary) -> Dictionary:
	var d: Dictionary = _ai_def(a.id)
	if a.id == "V" and (a.pos == "v9" or a.pos == "vRDOOR"):
		var c = d.duplicate()
		c.side = "R"
		c.door = "vRDOOR"
		c.hall = "v9"
		return c
	return d

func mk_ai(id: String) -> Dictionary:
	var d = _ai_def(id)
	return {"walkT": 0.0, "path": null, "seg": 0, "speed": 1.7, "rush": false, "rushT": 0.0, "chase": false, "chaseT": 0.0, "seeT": 0.0, "stun": 0.0, "broken": false, "id": id, "pos": d.start, "timer": 0.0, "lit": 0.0, "seen": false, "warned": false, "knocked": false, "attack": false, "attackT": 0.0, "retreatT": 0.0, "watchT": 0.0, "spokeCam": false, "off": false, "nearSaid": false, "endYaw": 0.0}

func ai_list() -> Array:
	return [G.vox, G.coc] if G else []

func hour_of() -> int:
	return mini(6, int(floor(G.t / HOUR)))

func lvl(a: Dictionary) -> float:
	var base: float
	if G.night == 8:
		base = CUSTOM.v if a.id == "V" else CUSTOM.c
	else:
		base = _ai_def(a.id).levels[G.night - 1][mini(5, hour_of())]
	return maxf(0.0, base - (4.0 if a.id == "V" and G.pzCalm > 0 else 0.0))

func door_of(s: String) -> bool:
	return G.doorL if s == "L" else G.doorR

func usage() -> int:
	if G.out:
		return 0
	return 1 + int(G.doorL) + int(G.doorR) + int(G.light != null) + int(G.cams) + int(roam.on and roam.flash)

func start_night(n: int) -> void:
	if T.MINIS.has(str(n)):
		hud.start_mini(n)
	else:
		new_game(n)

func new_game(n: int) -> void:
	audio.stop_menu_song()
	var pz_times = [HOUR * (1.2 + randf() * 1.6)]
	if randf() < 0.5:
		pz_times.append(HOUR * (3.6 + randf() * 1.5))
	var lines: Array = T.CALLS[n - 1] if n - 1 < T.CALLS.size() else []
	G = {
		"night": n, "t": 0.0, "power": 100.0, "pz": null, "pzCalm": 0.0, "pzMsgT": 0.0, "pzMsg": "", "pzTimes": pz_times, "doorL": false, "doorR": false, "aL": 0.0, "aR": 0.0, "light": null, "cams": false, "camA": 0.0, "cam": "1A", "camStatic": 0.0,
		"vox": mk_ai("V"), "coc": mk_ai("C"), "met": false, "loreT": randf_range(90, 150),
		"out": false, "outT": 0.0, "outPhase": 0, "outDur": [0.0, 0.0, 0.0],
		"call": {"i": -1, "t": 0.0, "on": true, "ring": 3.2, "lines": lines, "dur": 0.0},
		"look": 0.0, "lookV": 0.0, "flick": 0.0, "ambT": randf_range(12, 25), "chatT": randf_range(25, 45), "tip": null,
		"task": null, "damaged": false, "friend": false, "work": null, "hits": 0, "axe": false, "swingT": 0.0, "sys": null, "sysMsg": 0.0,
		"dialog": null, "talked": false, "rep": null,
	}
	if n == 3:
		G.task = {"step": 0, "bake": 0.0}
	roam_reset()
	pizza_desk.visible = false
	G.damaged = CUSTOM.damaged if n == 8 else n >= 6
	if n == 8 and CUSTOM.cocPassive:
		G.friend = true
	if n == 5 or n == 6:
		G.sys = {"broken": false, "next": randf_range(50, 75)}
	if n == 4:
		G.coc.broken = true
		G.coc.pos = "c4"
	rep_init(n)
	axe_mesh.visible = n == 7
	speech = null
	scare_t = -1.0
	killer = null
	coco_pizza.visible = false
	for ch in [VOX, COC]:
		ch.C.look = 0.0
		ch.C.lit = 0.0
	set_spot(VOX, G.vox.pos)
	set_spot(COC, G.coc.pos)
	COC.root.visible = true
	if n == 4:
		G.vox.off = true
	VOX.root.visible = true
	set_paper(n)
	scene_ = "intro"
	scene_t = 0.0

func toggle_door(s: String) -> void:
	if scene_ != "play" or G.out or roam.on:
		return
	if s == "L":
		G.doorL = not G.doorL
	else:
		G.doorR = not G.doorR
	audio.sfx("door", -0.8 if s == "L" else 0.8)

func set_light(s) -> void:
	if scene_ != "play" or G.out:
		return
	var prev = G.light
	G.light = null if (G.light == s or s == null) else s
	if prev != null and G.light != prev:
		for a in ai_list():
			if D(a).side == prev:
				check_flash(a)
	if G.light != null:
		audio.sfx("click")
	audio.set_buzz(G.light != null, -0.8 if G.light == "L" else 0.8)
	for a in ai_list():
		var d = D(a)
		if not a.off and G.light == d.side and a.pos == d.door and not door_of(d.side) and not a.seen:
			a.seen = true
			if not d.nice:
				audio.sfx("sting")

func check_flash(a: Dictionary) -> void:
	var d = D(a)
	if not d.nice and a.pos == d.door and not a.attack and a.lit >= 1 and not door_of(d.side):
		if G.damaged and randf() < 0.5:
			say_a(a, "glitch", {"force": true, "creep": true})
			a.lit = 0.0
		else:
			a.retreatT = 0.5

func toggle_cams() -> void:
	if scene_ != "play" or G.out or roam.on:
		return
	if not G.cams and G.sys and G.sys.broken:
		audio.sfx("cam")
		G.sysMsg = 2.5
		return
	if not G.cams and G.light != null:
		set_light(null)
	G.cams = not G.cams
	audio.sfx("tablet")
	if G.cams:
		G.camStatic = 0.25

func select_cam(id: String) -> void:
	if G.cam != id:
		G.cam = id
		G.camStatic = 0.3
		audio.sfx("cam")
		for a in ai_list():
			a.watchT = 0.0

func hang_up() -> void:
	if G and G.call.on:
		G.call.on = false
		if speech and speech.who == "phone":
			audio.stop_voice()
			speech = null
		audio.sfx("click")

func glitch_flash(d := 0.6) -> void:
	glitch_t = maxf(glitch_t, d)

## mluva animatroniků (sayA)
func say_a(a: Dictionary, kind: String, o := {}) -> void:
	if not G or a.off:
		return
	if speech and speech.t < speech.dur and not o.get("force", false):
		return
	var d = D(a)
	var text: String = pick(d.lines[kind])
	var pan = 0.0
	var vol = 0.1
	var radio = false
	if a.pos == d.door:
		pan = -0.85 if d.side == "L" else 0.85
		vol = 0.75
	elif a.pos == d.hall:
		pan = -0.6 if d.side == "L" else 0.6
		vol = 0.35
	if G.cams and SPOTS.has(a.pos) and SPOTS[a.pos].has("cam") and SPOTS[a.pos].cam == G.cam:
		radio = true
		vol = maxf(vol, 0.55)
		pan = 0.0
	if o.get("speaker", false):
		radio = true
		vol = 0.45
		pan = 0.0
	if o.has("vol"):
		vol = o.vol
	var creep: bool = not d.nice and (G.night >= 3 or o.get("creep", false))
	var key = ("C" if a.id == "C" else ("Vc" if creep else "V")) + "|" + text
	var dur: float = audio.voice(key, vol, pan, radio)
	speech = {"who": d.ch.name + (" (reproduktor)" if o.get("speaker", false) else ""), "text": text, "t": 0.0, "dur": maxf(dur, 1.6), "col": Color("#ffc9a0") if d.nice else Color("#ff8bea"), "heard": vol > 0.2 or o.get("speaker", false)}

func say_later(sec: float, f: Callable) -> void:
	get_tree().create_timer(sec).timeout.connect(f)

func move_to(a: Dictionary, np: String) -> void:
	glitch_flash(0.22)
	var old: String = a.pos
	var ch: Rig = _ai_def(a.id).ch
	var from = ch.root.position
	a.pos = np
	var d = D(a)
	set_spot(ch, np)
	a.watchT = 0.0
	a.spokeCam = false
	start_walk(a, from)
	if G.cams and ((SPOTS.has(old) and SPOTS[old].get("cam", "") == G.cam) or SPOTS[np].get("cam", "") == G.cam):
		G.camStatic = 1.1
	var pan = -1.0 if d.side == "L" else 1.0
	var coc: Dictionary = G.coc
	if np == d.hall:
		audio.steps(pan * 0.55, 3, 0.12 if d.nice else 0.2)
		say_later(1.5, func(): if G and a.pos == d.hall: say_a(a, "hall"))
		if not d.nice and not coc.off and coc.pos != "cDOOR" and randf() < 0.5:
			say_later(4.2, func(): if G: say_a(coc, "help", {"speaker": true}))
	if np == d.door:
		audio.steps(pan * 0.9, 4, 0.25 if d.nice else 0.42, 0.42)
		a.lit = 0.0
		a.seen = false
		a.warned = false
		a.knocked = false
		say_later(2.2, func(): if G and a.pos == d.door and not door_of(d.side): say_a(a, "door"))
		if not d.nice and not coc.off and coc.pos != "cDOOR" and (G.friend or randf() < 0.6):
			say_later(0.8, func(): if G: say_a(coc, "help", {"speaker": true, "force": true}))

func retreat(a: Dictionary, knock: bool) -> void:
	var d = D(a)
	var pan = -1.0 if d.side == "L" else 1.0
	if knock:
		audio.sfx("knock", pan * 0.9)
		say_later(0.7, func(): say_a(a, "closed", {"vol": 0.5}))
	else:
		say_a(a, "flash", {"force": true})
	say_later(1.6 if knock else 0.9, func(): audio.steps(pan * 0.8, 4, 0.3, 0.45, 0.06))
	var ch: Rig = d.ch
	var from = ch.root.position
	a.pos = pick(d.back)
	a.lit = 0.0
	a.timer = -2.0
	a.retreatT = 0.0
	a.seen = false
	ch.C.lit = 0.0
	set_spot(ch, a.pos)
	start_walk(a, from)

func ai_update(a: Dictionary, dt: float) -> void:
	if DEV.freeze or a.off:
		return
	if G.rep and G.rep.get("fin") and a == G.coc:
		return
	var d = D(a)
	if G.dialog and a == G.coc:
		return
	if G.pz and a == G.coc:
		return
	if a.broken:
		a.timer += dt
		if a.timer > 25:
			a.timer = 0.0
			if roam.on and COC.root.position.distance_to(roam_cam.position) < 8:
				say_a(a, "broken", {"vol": 0.5})
		return
	if a.stun > 0:
		a.stun -= dt
	if a.rush:
		a.rushT -= dt
		if a.pos == d.door:
			a.rush = false
			a.speed = 1.7
		elif a.rushT <= 0:
			a.rushT = 1.3
			a.speed = 4.5
			move_to(a, pick(NEXT[a.id][a.pos]))
	if a.attack:
		a.attackT += dt
		if not G.cams or a.attackT > 3:
			G.cams = false
			jumpscare(a)
		return
	if a.retreatT > 0:
		a.retreatT -= dt
		if a.retreatT <= 0:
			retreat(a, false)
		return
	if a.pos == d.door and G.light == d.side and not door_of(d.side):
		a.lit += dt
		if d.nice:
			if a.lit > 1:
				if G.night == 2 and not G.talked:
					open_dialog()
				else:
					a.retreatT = 1.2
		else:
			if a.lit > 2.3 and not a.warned:
				a.warned = true
				say_a(a, "stare", {"force": true, "creep": true})
			if a.lit > 3.5:
				a.attack = true
				a.attackT = 0.0
				set_light(null)
				return
	var sp = SPOTS.get(a.pos)
	if G.cams and sp and sp.has("cam") and sp.cam == G.cam and G.camA >= 1:
		a.watchT += dt
		if G.damaged and a.id == "V" and a.watchT > 1.5 and not a.rush and a.pos != d.door and a.stun <= 0:
			a.rush = true
			a.rushT = 0.0
			G.camStatic = 1.2
			say_a(a, "glitch", {"force": true, "creep": true, "vol": 0.7})
			audio.sfx("sting")
		if a.watchT > 3 and not a.spokeCam:
			a.spokeCam = true
			if d.nice and not G.met:
				G.met = true
				say_a(a, "meet", {"force": true})
			else:
				say_a(a, "camera")
	else:
		a.watchT = maxf(0.0, a.watchT - dt * 2)
	if G.t < (35.0 if d.nice else 20.0):
		return
	a.timer += dt
	if a.timer < MOVE_INT:
		return
	a.timer -= MOVE_INT
	if randf() * 20.0 >= lvl(a):
		return
	if a.pos == d.door:
		if door_of(d.side):
			retreat(a, true)
		elif G.light == d.side:
			pass
		elif d.nice and not a.knocked:
			a.knocked = true
			audio.sfx("knock", 0.9)
			say_a(a, "door", {"force": true})
		elif d.nice and G.night == 8 and CUSTOM.cocPassive:
			retreat(a, false)
		else:
			a.attack = true
			a.attackT = 0.0
	else:
		var opts: Array = ["2", "6", "v9", "v9"] if (a.id == "V" and a.pos == "1B" and G.night == 8 and CUSTOM.voxBoth) else NEXT[a.id][a.pos]
		move_to(a, pick(opts))

func power_out() -> void:
	roam.flash = false
	glitch_flash(1.4)
	G.out = true
	G.power = 0.0
	if G.doorL or G.doorR:
		audio.sfx("door")
	G.doorL = false
	G.doorR = false
	G.light = null
	G.cams = false
	audio.set_buzz(false)
	audio.stop_ambient()
	audio.sfx("powerdown")
	hang_up()
	G.outPhase = 0
	G.outT = 0.0
	G.outDur = [randf_range(3, 7), randf_range(6, 13), randf_range(2, 4)]
	G.vox.pos = "DOOR"
	set_spot(VOX, "DOOR")

func out_update(dt: float) -> void:
	G.outT += dt
	if G.outT < G.outDur[mini(G.outPhase, 2)]:
		return
	G.outT = 0.0
	G.outPhase += 1
	if G.outPhase == 1:
		audio.start_music_box()
		say_later(0.8, func(): if G: say_a(G.vox, "dark", {"force": true, "vol": 0.6, "creep": true}))
	elif G.outPhase == 2:
		audio.stop_music_box()
	else:
		jumpscare(G.vox)

func jumpscare(a: Dictionary) -> void:
	if scene_ != "play":
		return
	if DEV.god:
		a.attack = false
		a.chase = false
		if a.pos == D(a).door:
			retreat(a, false)
		return
	killer = a
	scene_ = "scare"
	scene_t = 0.0
	audio.set_buzz(false)
	audio.stop_music_box()
	audio.stop_ambient()
	audio.sfx("scare")
	audio.voice(("Cscare|" if a.id == "C" else "Vscare|") + pick(_ai_def(a.id).lines.scare), 0.8, 0.0, false)
	scare_t = 0.0
	G.cams = false
	G.camA = 0.0
	glitch_flash(1.5)
	Input.vibrate_handheld(700)

func win() -> void:
	scene_ = "win"
	scene_t = 0.0
	audio.set_buzz(false)
	audio.stop_music_box()
	audio.stop_ambient()
	audio.sfx("chime")
	say_later(3.5, func(): audio.voice("Vwin|" + pick(T.LINES_V.win), 0.3, 0.0, false))
	if G and not G.coc.off:
		say_later(5.2, func(): audio.voice("Cwin|" + pick(T.LINES_C.win), 0.35, 0.0, false))
	if G.night <= 7:
		progress = mini(7, maxi(progress, G.night + 1))
		st_set("voxies_night", progress)
	if G.night == 7:
		st_set("voxies_n7", true)
	if G.night >= 5:
		beaten = true
		st_set("voxies_beaten", true)

func phone_line() -> void:
	var c: Dictionary = G.call
	var text: String = c.lines[c.i]
	var d: float = audio.voice("phone|" + text, 0.35, 0.3, false)
	c.dur = maxf(3.0, d + 0.4)
	speech = {"who": "phone", "text": text, "t": 0.0, "dur": c.dur, "col": Color("#fff7c9"), "heard": true}

func secret_end() -> void:
	if scene_ != "play":
		return
	scene_ = "secret"
	scene_t = 0.0
	st_set("voxies_secret", true)
	audio.set_buzz(false)
	audio.stop_ambient()
	audio.stop_music_box()
	audio.sfx("powerdown")
	say_later(3.5, func(): audio.voice("secret|Dě-ku-ju.", 0.6, 0.0, false))

func go_news(secret: bool) -> void:
	hud.news_secret = secret
	scene_ = "news"
	scene_t = 0.0
	audio.sfx("powerdown")
	st_set("voxies_fire", true)

func to_menu() -> void:
	say_later(0.4, func(): audio.start_menu_song())
	audio.set_buzz(false)
	audio.stop_music_box()
	audio.stop_ambient()
	audio.stop_chip()
	scene_ = "menu"
	scene_t = 0.0
	G = null
	speech = null
	scare_t = -1.0
	killer = null
	menu_spots()

# ====================================================================
#  HLAVNÍ SMYČKA
# ====================================================================
func _process(delta: float) -> void:
	var dt = minf(0.1, delta)
	frame_dt = dt
	t_now += dt
	update(dt)
	render(t_now)

func update(dt: float) -> void:
	scene_t += dt
	rep_tick(dt)
	if scene_ == "extras":
		hud.EX.rot += dt * 0.6
		if hud.EX.scare >= 0:
			hud.EX.scare += dt
			if hud.EX.scare > 1.6:
				hud.EX.scare = -1.0
	if speech:
		speech.t += dt
	if scene_ == "mini":
		hud.mini_update(dt)
		return
	if scene_ == "intro" and scene_t > 3:
		scene_ = "play"
		scene_t = 0.0
		audio.start_ambient()
	if scene_ == "scare":
		scare_t += dt
		if scene_t > 1.4:
			roam_reset()
			scene_ = "dead"
			scene_t = 0.0
		return
	if scene_ != "play":
		return
	G.t += dt
	if G.t >= 6 * HOUR and not fin_hold():
		win()
		return
	G.aL += ((1.0 if G.doorL else 0.0) - G.aL) * minf(1, dt * 12)
	G.aR += ((1.0 if G.doorR else 0.0) - G.aR) * minf(1, dt * 12)
	G.camA = clampf(G.camA + (dt if G.cams else -dt) * 5, 0, 1)
	G.camStatic = maxf(0, G.camStatic - dt)
	G.look = clampf(G.look + G.lookV * dt, -1.15, 1.15)
	G.flick = randf_range(0.05, 0.2) if randf() < 0.012 else maxf(0, G.flick - dt)
	if G.out:
		out_update(dt)
		return
	G.power -= usage() * T.DRAIN[G.night - 1] * dt
	if G.vox.off and G.power < 1:
		G.power = 1.0
	if G.power <= 0:
		power_out()
		return
	pizza_update(dt)
	for a in ai_list():
		ai_update(a, dt)
	if G.sys and not G.sys.broken:
		G.sys.next -= dt
		if G.sys.next <= 0:
			G.sys.broken = true
			if G.cams:
				G.cams = false
			audio.sfx("powerdown")
			G.sysMsg = 4.0
	if G.sysMsg > 0:
		G.sysMsg -= dt
	roam_update(dt)
	if G.rep:
		rep_update(dt)
		fin_update(dt)
	var c: Dictionary = G.call
	if c.on:
		if c.ring > 0:
			if floor(c.ring / 1.6) != floor((c.ring - dt) / 1.6) or c.ring == 3.2:
				audio.sfx("ring", 0.4)
			c.ring -= dt
			if c.ring <= 0:
				c.i = 0
				c.t = 0.0
				if c.lines.size():
					phone_line()
				else:
					c.on = false
		else:
			c.t += dt
			if c.t > c.dur:
				c.i += 1
				c.t = 0.0
				if c.i >= c.lines.size():
					c.on = false
				else:
					phone_line()
	G.ambT -= dt
	if G.ambT <= 0:
		G.ambT = randf_range(15, 35)
		audio.sfx("arcade" if randf() < 0.6 else "clank", randf_range(-0.7, 0.7))
	G.chatT -= dt
	if G.chatT <= 0:
		G.chatT = randf_range(40, 70)
		if not G.call.on:
			var cands = ai_list().filter(func(a): return not a.off and a.pos == _ai_def(a.id).start)
			if cands.size():
				say_a(pick(cands), "start", {"vol": 0.25})
	G.loreT -= dt
	if G.loreT <= 0:
		G.loreT = randf_range(100, 160)
		if not G.call.on and not G.coc.off and G.coc.pos != "cDOOR":
			say_a(G.coc, "lore", {"speaker": true})

# ====================================================================
#  CHOZENÍ PO BUDOVĚ + ÚKOLY
# ====================================================================
var roam = {"stamina": 1.0, "sprint": false, "tired": false, "y": 0.0, "vy": 0.0, "on": false, "pos": Vector3.ZERO, "yaw": 0.0, "pitch": 0.0, "flash": false, "joy": null, "look": null, "keys": {}, "bob": 0.0, "msg": "", "msgT": 0.0}
var WALK = []
var GAPS = []
var OBST = []
var ADJ = {}

func roam_reset() -> void:
	roam.stamina = 1.0
	roam.y = 0.0
	roam.vy = 0.0
	roam.sprint = false
	roam.tired = false
	roam.on = false
	roam.flash = false
	roam.joy = null
	roam.look = null
	roam.keys = {}
	flash.light_energy = 0

func _build_nav() -> void:
	for id in ROOMS:
		var r: Dictionary = ROOMS[id]
		WALK.append([r.x0 + 0.35, r.z0 + 0.35, r.x1 - 0.35, r.z1 - 0.35])
		for sd in r.open:
			for ab in r.open[sd]:
				var a: float = ab[0]
				var b: float = ab[1]
				var g: Array
				match sd:
					"n": g = [a + 0.3, r.z0 - 0.7, b - 0.3, r.z0 + 0.7]
					"s": g = [a + 0.3, r.z1 - 0.7, b - 0.3, r.z1 + 0.7]
					"w": g = [r.x0 - 0.7, a + 0.3, r.x0 + 0.7, b - 0.3]
					_: g = [r.x1 - 0.7, a + 0.3, r.x1 + 0.7, b - 0.3]
				var door = null
				if id == "OFF":
					door = "L" if sd == "w" else "R"
				GAPS.append({"r": g, "door": door})
	# překážky z Remasteru (bez staré pokladny ve vchodu – tam je nová)
	var ob = JSON.parse_string(FileAccess.get_file_as_string("res://data/obst.json"))
	for o in ob:
		var cx: float = (o[0] + o[2]) / 2.0
		var cz: float = (o[1] + o[3]) / 2.0
		if cx > -15.1 and cx < -12.0 and cz > -1.3 and cz < 1.3:
			continue
		OBST.append({"x0": o[0], "z0": o[1], "x1": o[2], "z1": o[3], "ai": o[4] == 1, "hop": o[5] == 1})
	for gg in GAPS:
		if gg.door != null:
			continue
		var g: Array = gg.r
		var cx: float = (g[0] + g[2]) / 2.0
		var cz: float = (g[1] + g[3]) / 2.0
		var rs = []
		for oo in [[0, 0.9], [0, -0.9], [0.9, 0], [-0.9, 0]]:
			var r = room_at(cx + oo[0], cz + oo[1])
			if r != null and not rs.has(r):
				rs.append(r)
		if rs.size() < 2:
			continue
		for pair in [[rs[0], rs[1]], [rs[1], rs[0]]]:
			if not ADJ.has(pair[0]):
				ADJ[pair[0]] = []
			ADJ[pair[0]].append({"to": pair[1], "p": [cx, cz]})

static func in_r(x: float, z: float, r: Array) -> bool:
	return x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]

func walkable(x: float, z: float) -> bool:
	if DEV.noclip:
		return true
	if x > -1.95 and x < 1.95 and z > -0.2 and z < 1.35:
		return false
	for r in WALK:
		if in_r(x, z, r):
			return true
	for g in GAPS:
		if in_r(x, z, g.r) and not (g.door != null and door_of(g.door)):
			return true
	return false

const PR := 0.22
func hit_obst(x: float, z: float, pad := PR) -> bool:
	for o in OBST:
		if x > o.x0 - pad and x < o.x1 + pad and z > o.z0 - pad and z < o.z1 + pad:
			return true
	return false

func room_at(x: float, z: float):
	for id in ROOMS:
		var r: Dictionary = ROOMS[id]
		if x >= r.x0 and x <= r.x1 and z >= r.z0 and z <= r.z1:
			return id
	return null

func hint(m: String) -> void:
	roam.msg = m
	roam.msgT = 3.5

func near_desk() -> bool:
	return roam.pos.distance_to(Vector3(0, 1.6, 2.2)) < 1.8

func toggle_roam() -> void:
	if scene_ != "play" or G.cams:
		return
	if not roam.on:
		if G.light != null:
			set_light(null)
		roam.on = true
		roam.pos = Vector3(0, 1.6, 2.2)
		roam.yaw = G.look
		roam.pitch = 0.0
		roam.flash = not G.out
		audio.steps(0, 2, 0.15)
		hint("Joystick vlevo = chůze, táhni vpravo = rozhlížení")
	elif near_desk():
		roam.on = false
		roam.flash = false
		G.look = clampf(roam.yaw, -1.15, 1.15)

func roam_jump() -> void:
	if roam.on and roam.y == 0 and roam.stamina > 0.08:
		roam.vy = 5.0
		roam.stamina = maxf(0, roam.stamina - 0.08)
		audio.sfx("step", 0, 0.08)

# ---------- pizza od Cocoy ----------
func pz_route(p: String) -> Array:
	var r = ["c3", "c4", "c1B", "c9", "cDOOR"]
	var i = r.find(p)
	return ["c9", "cDOOR"] if i < 0 else r.slice(i + 1)

func pz_leave() -> void:
	var a: Dictionary = G.coc
	if not G.pz:
		return
	G.pz = null
	coco_pizza.visible = false
	a.speed = 1.7
	a.knocked = true
	a.timer = -10.0
	a.lit = 0.0
	a.seen = false
	a.warned = false
	var from = COC.root.position
	a.pos = "c9"
	set_spot(COC, a.pos)
	start_walk(a, from)
	audio.steps(0.5, 4, 0.2, 0.4)

func take_pizza() -> void:
	if not G or not G.pz or G.pz.ph != "pizza":
		return
	coco_pizza.visible = false
	G.pz.ph = "thanks"
	G.pz.t = 0.0
	audio.sfx("ding_pizza")
	if randf() < 0.5:
		G.power = minf(100, G.power + 25)
		G.pzMsg = "Pizza! Cocoa ti dobila baterii: +25 % proudu."
	else:
		G.pzCalm = 45.0
		G.pzMsg = "Pizza! Voxie bude 45 s klidnější."
	G.pzMsgT = 4.0
	cocoa_hold = 1
	cocoa_set_eyes(true)
	say_later(1.0, func():
		cocoa_hold = 0
		cocoa_set_eyes(false))
	say_a(G.coc, "thanks", {"force": true, "vol": 0.6})

func pizza_update(dt: float) -> void:
	if G.pzCalm > 0:
		G.pzCalm -= dt
	if G.pzMsgT > 0:
		G.pzMsgT -= dt
	if coco_pizza.visible and not (G.rep and G.rep.get("fin") and G.rep.fin.ph == "sit"):
		coco_pizza.rotation.y += dt * 0.6
	var a: Dictionary = G.coc
	var P = G.pz
	if not P:
		if G.rep and G.rep.get("fin"):
			return
		if G.pzTimes.is_empty() or G.t < G.pzTimes[0]:
			return
		if G.t > G.pzTimes[0] + 45:
			G.pzTimes.pop_front()
			return
		if a.off or a.broken or a.attack or G.dialog or G.out or a.pos == "cDOOR" or G.vox.pos == "DOOR" or G.vox.attack:
			return
		G.pzTimes.pop_front()
		G.pz = {"ph": "walk", "t": 0.0, "route": pz_route(a.pos), "wait": 2.0, "k": 0, "open": 0.0, "lastK": 0.0}
		a.speed = 1.0
		a.retreatT = 0.0
		return
	if G.out or a.broken:
		G.pz = null
		coco_pizza.visible = false
		a.speed = 1.7
		return
	P.t += dt
	if P.ph == "walk":
		if a.path:
			return
		P.wait -= dt
		if P.wait > 0:
			return
		if P.route.size():
			move_to(a, P.route.pop_front())
			P.wait = 4.5
		else:
			P.ph = "knock"
			P.t = 0.0
			P.k = 0
	elif P.ph == "knock":
		if a.path:
			P.t = 0.0
			return
		if P.t > 1 and P.k == 0:
			P.k = 1
			audio.sfx("softknock", 0.9)
		if P.t > 2.8 and P.k == 1:
			P.k = 2
			audio.sfx("softknock", 0.9)
		if P.k == 2 and P.t > 4.2:
			P.ph = "wait"
			P.t = 0.0
			P.open = 0.0
			P.lastK = 0.0
	elif P.ph == "wait":
		P.open = 0.0 if G.doorR else P.open + dt
		if P.open > 1.5:
			P.ph = "peek"
			P.t = 0.0
		elif P.t > 22:
			pz_leave()
		elif P.t - P.lastK > 7:
			P.lastK = P.t
			audio.sfx("softknock", 0.9)
	elif P.ph == "peek":
		if P.t > 1:
			# Cocoa drží novou pizzu před sebou
			var y = COC.root.rotation.y
			coco_pizza.position = COC.root.position + Vector3(sin(y) * 0.5, 1.0, cos(y) * 0.5)
			coco_pizza.visible = true
			P.ph = "pizza"
			P.t = 0.0
			audio.sfx("pz_show")
			say_a(a, "pizza", {"force": true, "vol": 0.7})
	elif P.ph == "pizza":
		if P.t > 30:
			pz_leave()
	elif P.ph == "thanks":
		if P.t > 1.6:
			pz_leave()

# ---------- interakce ----------
var INTER = []
var WORK = {}
func _inter_ok(id: String) -> bool:
	match id:
		"order": return G.task != null and G.task.step == 0
		"oven": return G.task != null and G.task.step == 1
		"take": return G.task != null and G.task.step == 3
		"deliver": return G.task != null and G.task.step == 4
		"repair": return G.coc.broken and not G.work and not G.rep
		"server": return G.sys != null and G.sys.broken and not G.work
		"axe": return G.night == 7 and not G.axe
		"rep_inspect": return rep_ok(0)
		"rep_open": return rep_ok(1)
		"rep_boxS": return rep_ok(2) and not G.rep.searched.has("S")
		"rep_boxM": return rep_ok(2) and not G.rep.searched.has("M")
		"rep_boxO": return rep_ok(2) and not G.rep.searched.has("O")
		"rep_mount": return rep_ok(3)
		"rep_calib": return rep_ok(4)
		"rep_boot": return rep_ok(5)
	return false

func near_inter():
	if not roam.on:
		return null
	if INTER.is_empty():
		INTER = T.INTER
		WORK = T.WORK.duplicate(true)
	for i in INTER:
		if _inter_ok(i.id) and Vector2(roam.pos.x - i.x, roam.pos.z - i.z).length() < i.r:
			return i
	return null

func interact() -> void:
	var i = near_inter()
	if i == null:
		return
	var Tk = G.task
	audio.sfx("click")
	if String(i.id).begins_with("rep_"):
		rep_interact(i)
		return
	if i.id == "repair" or i.id == "server":
		G.work = {"id": i.id, "prog": 0.0}
		hint("Zůstaň u ní, dokud se oprava nedokončí. Hlídej čas!" if i.id == "repair" else "Restartuji… zůstaň u serveru.")
		return
	if i.id == "axe":
		G.axe = true
		axe_mesh.visible = false
		audio.sfx("clank")
		hint("Máš sekeru. Až bude Voxie blízko, klepni na ÚDER. Tři rány…")
		return
	if i.id == "order":
		Tk.step = 1
		hint("Objednávka č. 1997: „Voxie speciál“ – sýr, salám, srdíčko z kečupu.")
		audio.sfx("ding2")
	elif i.id == "oven":
		Tk.step = 2
		Tk.bake = 0.0
		hint("Peče se… (20 s). Zatím si hlídej dveře!")
	elif i.id == "take":
		Tk.step = 4
		hint("Pizza je hotová. Odnes ji ke stolu.")
	elif i.id == "deliver":
		Tk.step = 5
		G.power = minf(100, G.power + 20)
		hint("Hotovo! Majitel posílá bonus: +20 % proudu.")
		pizza_desk.visible = true
		if not G.coc.off:
			say_later(1.5, func(): if G: say_a(G.coc, "meet", {"speaker": true, "force": true}))

func work_done(id: String) -> void:
	audio.sfx("work_done")
	if id.begins_with("rep_"):
		rep_work_done(id)
		return
	if id == "repair":
		G.coc.broken = false
		G.friend = true
		G.coc.timer = -10.0
		hint("Cocoa je opravená! Teď tě bude hlídat.")
		say_a(G.coc, "fixed", {"force": true, "vol": 0.7})
	if id == "server":
		G.sys.broken = false
		G.sys.next = randf_range(45, 70) if G.night == 6 else randf_range(70, 100)
		hint("Server běží. Kamery jsou zpět.")

func hit_voxie() -> void:
	var a: Dictionary = G.vox
	if not G.axe or G.swingT > 0:
		return
	G.swingT = 0.4
	G.hits += 1
	audio.sfx("hit")
	say_a(a, "glitch", {"force": true, "creep": true, "vol": 0.8})
	if G.hits >= 3:
		say_later(0.7, secret_end)
		a.stun = 99.0
		a.chase = false
		a.path = null
		return
	a.chase = false
	a.rush = false
	a.stun = 9.0
	a.seeT = 0.0
	a.attack = false
	var from = VOX.root.position
	a.pos = "1B"
	set_spot(VOX, "1B")
	start_walk(a, from)
	a.speed = 2.6
	hint("Zásah " + str(G.hits) + "/3! Voxie ustoupil.")

func can_hit() -> bool:
	return G.axe and roam.on and not G.vox.off and VOX.root.position.distance_to(roam_cam.position) < 3.2

func roam_update(dt: float) -> void:
	if G.work:
		var w: Dictionary = WORK[G.work.id]
		if Vector2(roam.pos.x - w.x, roam.pos.z - w.z).length() < 2.4 and roam.on:
			G.work.prog += dt
			if randf() < dt * 3:
				audio.sfx("click")
		if G.work.prog >= w.need:
			var id: String = G.work.id
			G.work = null
			work_done(id)
	if G.swingT > 0:
		G.swingT -= dt
	held_axe.visible = roam.on and G.axe
	held_axe.rotation.x = 0.3 - (sin((0.4 - G.swingT) / 0.4 * PI) * 1.4 if G.swingT > 0 else 0.0)
	for i in rack_leds.size():
		var on: bool
		if G.sys and G.sys.broken:
			rack_leds[i].albedo_color = Color("#ff2020") if sin(G.t * 8 + i) > 0 else Color("#330000")
		else:
			rack_leds[i].albedo_color = Color("#3aff6a") if sin(G.t * 3 + i * 1.7) > -0.3 else Color("#0a3010")
	var v: Dictionary = G.vox
	if roam.on and G.damaged and not v.off and v.stun <= 0:
		var to = VOX.root.position - roam_cam.position
		var dist = to.length()
		to = to.normalized()
		var fwd = -roam_cam.global_transform.basis.z
		if dist < 14 and fwd.dot(to) > 0.9:
			v.seeT += dt
		else:
			v.seeT = maxf(0, v.seeT - dt)
		if v.seeT > 1.1 and not v.chase:
			v.chase = true
			v.chaseT = 0.0
			say_a(v, "glitch", {"force": true, "creep": true, "vol": 0.9})
			audio.sfx("scare")
	if v.chase:
		v.chaseT -= dt
		if v.chaseT <= 0 or not v.path:
			v.chaseT = 0.4
			v.path = nav_path(VOX.root.position, Vector3(roam.pos.x, 0, roam.pos.z))
			v.seg = 1
			v.speed = 4.2
			v.endYaw = VOX.root.rotation.y
		if not roam.on:
			v.chase = false
			set_spot(VOX, v.pos)
	if G.task and G.task.step == 2:
		G.task.bake += dt
		if G.task.bake >= 20:
			G.task.step = 3
			audio.sfx("oven_ding", -0.4)
			if roam.on:
				hint("Ding! Pizza je upečená.")
	# pec a objednávkový lístek během úkolu pizzy
	var baking: bool = G.task != null and G.task.step == 2
	oven_mouth.light_energy = ((8.0 if sin(G.t * 6) > 0 else 5.0) if baking else 0.6) * LK
	order_ticket.scale = Vector3.ONE * (1.0 + (0.12 * absf(sin(G.t * 5)) if G.task != null and G.task.step == 0 else 0.0))
	if roam.msgT > 0:
		roam.msgT -= dt
	if not roam.on:
		return
	var mx = 0.0
	var mz = 0.0
	if roam.joy:
		mx = roam.joy.dx
		mz = roam.joy.dy
	var k: Dictionary = roam.keys
	if k.get("w") or k.get("up"):
		mz -= 1
	if k.get("s") or k.get("down"):
		mz += 1
	if k.get("a") or k.get("left"):
		mx -= 1
	if k.get("d") or k.get("right"):
		mx += 1
	var ln = Vector2(mx, mz).length()
	if ln > 1:
		mx /= ln
		mz /= ln
	var running: bool = (roam.sprint or k.get("shift", false)) and ln > 0.1 and not roam.tired
	roam.stamina = clampf(roam.stamina + (-dt / 4.0 if running else dt / (7.0 if ln > 0.1 else 4.0)), 0, 1)
	if roam.stamina <= 0 and not roam.tired:
		roam.tired = true
		audio.sfx("step", 0, 0.2)
	if roam.tired and roam.stamina > 0.35:
		roam.tired = false
	roam.vy -= 14 * dt
	roam.y = maxf(0, roam.y + roam.vy * dt)
	if roam.y == 0 and roam.vy < 0:
		if roam.vy < -3:
			audio.sfx("step", 0, 0.12)
		roam.vy = 0.0
	var sp = (5.2 if running else 2.8) * dt
	var cy = cos(roam.yaw)
	var sy = sin(roam.yaw)
	var dx = (mx * cy + mz * sy) * sp
	var dz = (-mx * sy + mz * cy) * sp
	var stuck: bool = not DEV.noclip and hit_obst(roam.pos.x, roam.pos.z)
	if walkable(roam.pos.x + dx, roam.pos.z) and (DEV.noclip or stuck or not hit_obst(roam.pos.x + dx, roam.pos.z)):
		roam.pos.x += dx
	if walkable(roam.pos.x, roam.pos.z + dz) and (DEV.noclip or stuck or not hit_obst(roam.pos.x, roam.pos.z + dz)):
		roam.pos.z += dz
	if ln > 0.1:
		roam.bob += dt * 9
		if floor(roam.bob / PI) != floor((roam.bob - dt * 9) / PI):
			audio.sfx("step", 0, 0.06)
	for a in ai_list():
		if a.off or (a == G.coc and G.rep and not G.rep.done):
			continue
		var ch: Rig = _ai_def(a.id).ch
		var d = Vector2(ch.root.position.x - roam.pos.x, ch.root.position.z - roam.pos.z).length()
		if d < 1.3 and not (G.dialog and a == G.coc) and not (_ai_def(a.id).nice and G.friend):
			jumpscare(a)
			return
		if d < 4 and not a.nearSaid:
			a.nearSaid = true
			say_a(a, "hall" if _ai_def(a.id).nice else "stare", {"force": true, "vol": 0.7})
		if d > 6:
			a.nearSaid = false

func update_roam_cam() -> void:
	var bob_y = sin(roam.bob) * 0.04
	roam_cam.position = Vector3(roam.pos.x, 1.6 + (0.0 if roam.y > 0 else bob_y) + roam.y, roam.pos.z)
	roam_cam.rotation = Vector3(roam.pitch, roam.yaw, 0)
	var fwd = -roam_cam.global_transform.basis.z
	flash.global_position = roam_cam.position + fwd * 0.2 - Vector3(0, 0.15, 0)
	if fwd.length() > 0:
		flash.look_at(roam_cam.position + fwd * 5)
	flash.light_energy = (34.0 * (0.2 if randf() < 0.01 else 1.0) * LK) if roam.flash and not G.out else 0.0
	var rid = room_at(roam.pos.x, roam.pos.z)
	if rid != null and rid != "OFF":
		var r: Dictionary = ROOMS[rid]
		room_light.position = Vector3((r.x0 + r.x1) / 2.0, r.get("h", H) - 0.4, (r.z0 + r.z1) / 2.0)
		room_light.light_energy = 0.0 if G.out else 3.0 * LK
	else:
		room_light.light_energy = 0

# ====================================================================
#  NAVIGACE ANIMATRONIKŮ (port navPath / planLeg)
# ====================================================================
const AR := 0.42
const HOP_H := 1.3
func _in_box(p: Vector3, o: Dictionary, pad: float) -> bool:
	return p.x > o.x0 - pad and p.x < o.x1 + pad and p.z > o.z0 - pad and p.z < o.z1 + pad

func walk_nav(x: float, z: float) -> bool:
	for r in WALK:
		if in_r(x, z, r):
			return true
	for g in GAPS:
		if in_r(x, z, g.r):
			return true
	return false

func seg_hits_box(ax: float, az: float, bx: float, bz: float, o: Dictionary, pad: float) -> bool:
	var lo = [o.x0 - pad + 0.02, o.z0 - pad + 0.02]
	var hi = [o.x1 + pad - 0.02, o.z1 + pad - 0.02]
	var d = [bx - ax, bz - az]
	var q = [ax, az]
	var t0 = 0.0
	var t1 = 1.0
	for i in 2:
		if absf(d[i]) < 1e-9:
			if q[i] <= lo[i] or q[i] >= hi[i]:
				return false
			continue
		var u: float = (lo[i] - q[i]) / d[i]
		var v: float = (hi[i] - q[i]) / d[i]
		if u > v:
			var tmp = u
			u = v
			v = tmp
		t0 = maxf(t0, u)
		t1 = minf(t1, v)
		if t0 >= t1:
			return false
	return true

func box_edge_point(a: Vector3, b: Vector3, o: Dictionary, pad: float, kind: String):
	var lo = [o.x0 - pad, o.z0 - pad]
	var hi = [o.x1 + pad, o.z1 + pad]
	var q = [a.x, a.z]
	var d = [b.x - a.x, b.z - a.z]
	var tin = -INF
	var tout = INF
	for i in 2:
		if absf(d[i]) < 1e-9:
			continue
		var u: float = (lo[i] - q[i]) / d[i]
		var v: float = (hi[i] - q[i]) / d[i]
		if u > v:
			var tmp = u
			u = v
			v = tmp
		tin = maxf(tin, u)
		tout = minf(tout, v)
	var t = tout if kind == "out" else tin
	if is_inf(t):
		return null
	return Vector3(a.x + d[0] * t, 0, a.z + d[1] * t)

func plan_leg(a: Vector3, b: Vector3, skip: Array) -> Array:
	var obs = OBST.filter(func(o): return o.ai and not skip.has(o) and not _in_box(a, o, AR) and not _in_box(b, o, AR))
	var any = false
	for o in obs:
		if seg_hits_box(a.x, a.z, b.x, b.z, o, AR):
			any = true
			break
	if not any:
		return []
	var mnx = minf(a.x, b.x) - 6
	var mxx = maxf(a.x, b.x) + 6
	var mnz = minf(a.z, b.z) - 6
	var mxz = maxf(a.z, b.z) + 6
	var near = obs.filter(func(o): return o.x1 > mnx and o.x0 < mxx and o.z1 > mnz and o.z0 < mxz)
	var nodes = [Vector2(a.x, a.z), Vector2(b.x, b.z)]
	var e = AR + 0.06
	for o in near:
		for c in [[o.x0 - e, o.z0 - e], [o.x1 + e, o.z0 - e], [o.x0 - e, o.z1 + e], [o.x1 + e, o.z1 + e]]:
			if not walk_nav(c[0], c[1]):
				continue
			var inside = false
			for p in near:
				if _in_box(Vector3(c[0], 0, c[1]), p, AR - 0.03):
					inside = true
					break
			if not inside:
				nodes.append(Vector2(c[0], c[1]))
	var free = func(p: Vector2, q: Vector2) -> bool:
		for o in near:
			if seg_hits_box(p.x, p.y, q.x, q.y, o, AR):
				return false
		var L = p.distance_to(q)
		var n = int(floor(L / 0.4))
		for i in range(1, n + 1):
			var t = i * 0.4 / L
			if t < 0.999 and not walk_nav(p.x + (q.x - p.x) * t, p.y + (q.y - p.y) * t):
				return false
		return true
	var N = nodes.size()
	var dist = []
	var prev = []
	var done = []
	for i in N:
		dist.append(INF)
		prev.append(-1)
		done.append(false)
	dist[0] = 0.0
	for it in N:
		var u = -1
		for i in N:
			if not done[i] and (u < 0 or dist[i] < dist[u]):
				u = i
		if u < 0 or is_inf(dist[u]):
			break
		done[u] = true
		if u == 1:
			break
		for vv in N:
			if done[vv]:
				continue
			var w: float = nodes[u].distance_to(nodes[vv])
			if dist[u] + w < dist[vv] and free.call(nodes[u], nodes[vv]):
				dist[vv] = dist[u] + w
				prev[vv] = u
	if is_inf(dist[1]):
		return []
	var out = []
	var i: int = prev[1]
	while i > 0:
		out.push_front(Vector3(nodes[i].x, 0, nodes[i].y))
		i = prev[i]
	return out

func append_leg(out: Dictionary, a: Vector3, b: Vector3) -> void:
	var pit = null
	for o in OBST:
		if o.hop and (_in_box(a, o, 0) or _in_box(b, o, 0)):
			pit = o
			break
	if pit and _in_box(a, pit, 0) and not _in_box(b, pit, 0):
		var E = box_edge_point(a, b, pit, 0.45, "out")
		if E != null:
			out.arc[out.pts.size()] = true
			out.pts.append(E)
			a = E
	elif pit and _in_box(b, pit, 0) and not _in_box(a, pit, 0):
		var E = box_edge_point(a, b, pit, 0.45, "in")
		if E != null:
			for w in plan_leg(a, E, [pit]):
				out.pts.append(w)
			out.pts.append(E)
			out.arc[out.pts.size()] = true
			out.pts.append(b)
			return
	for w in plan_leg(a, b, [pit] if pit else []):
		out.pts.append(w)
	out.pts.append(b)

func nav_rooms(from: Vector3, to: Vector3) -> Array:
	var ra = room_at(from.x, from.z)
	var rb = room_at(to.x, to.z)
	var pts = [from]
	if ra != null and rb != null and ra != rb:
		var prev = {ra: null}
		var q = [ra]
		while q.size():
			var r = q.pop_front()
			if r == rb:
				break
			for e in ADJ.get(r, []):
				if not prev.has(e.to):
					prev[e.to] = {"r": r, "p": e.p}
					q.append(e.to)
		var mids = []
		var r2 = rb
		while prev.get(r2) != null:
			mids.push_front(prev[r2].p)
			r2 = prev[r2].r
		for m in mids:
			pts.append(Vector3(m[0], 0, m[1]))
	pts.append(to)
	return pts

func nav_path(from: Vector3, to: Vector3) -> Dictionary:
	var pts = nav_rooms(from, to)
	var out = {"pts": [pts[0]], "arc": {}}
	for i in range(1, pts.size()):
		append_leg(out, pts[i - 1], pts[i])
	return out

func start_walk(a: Dictionary, from: Vector3) -> void:
	var ch: Rig = _ai_def(a.id).ch
	var to = ch.root.position
	if from.distance_to(to) < 0.2:
		return
	a.endYaw = ch.root.rotation.y
	a.path = nav_path(from, to)
	a.seg = 1
	ch.root.position = from

func walk_step(a: Dictionary, ch: Rig, dt: float) -> void:
	var P: Array = a.path.pts
	var step: float = a.speed * dt
	while step > 0 and a.seg < P.size():
		var tgt: Vector3 = P[a.seg]
		var cur = ch.root.position
		var dx = tgt.x - cur.x
		var dz = tgt.z - cur.z
		var dy = tgt.y - cur.y
		var d = Vector2(dx, dz).length()
		if d <= step:
			ch.root.position = tgt
			step -= d
			a.seg += 1
			continue
		cur.x += dx / d * step
		cur.z += dz / d * step
		cur.y += dy * minf(1, step / d)
		ch.root.position = cur
		var want = atan2(dx, dz)
		var df = want - ch.root.rotation.y
		df = atan2(sin(df), cos(df))
		ch.root.rotation.y += df * minf(1, dt * 8)
		step = 0.0
	if a.seg < P.size() and a.seg > 0 and a.path.arc.has(a.seg):
		var s0: Vector3 = P[a.seg - 1]
		var s1: Vector3 = P[a.seg]
		var L = maxf(0.001, Vector2(s1.x - s0.x, s1.z - s0.z).length())
		var rem = Vector2(s1.x - ch.root.position.x, s1.z - ch.root.position.z).length()
		ch.root.position.y = sin(PI * clampf(1 - rem / L, 0, 1)) * HOP_H
	if a.seg >= P.size():
		a.path = null
		ch.root.rotation.y = a.endYaw

# ====================================================================
#  DIALOG S COCOU (noc 2)
# ====================================================================
func can_talk() -> bool:
	return G and G.night == 2 and not G.talked and not G.dialog and roam.on and not G.coc.off and COC.root.position.distance_to(roam_cam.position) < 3

func open_dialog() -> void:
	if not G or G.dialog or G.coc.off:
		return
	G.dialog = "start"
	G.talked = true
	dialog_say()

func dialog_say() -> void:
	var n: Dictionary = T.DIALOG[G.dialog]
	audio.voice("C|" + n.t, 0.5, 0.0 if roam.on else 0.6, false)

func choose(next) -> void:
	audio.sfx("click")
	var n: Dictionary = T.DIALOG[G.dialog]
	if n.get("fx") == "friend" or n.get("fx") == "promise":
		G.friend = true
	if n.get("fx") == "promise":
		st_set("voxies_promise", true)
	if next == null:
		G.dialog = null
		audio.stop_voice()
		if G.coc.pos == "cDOOR":
			G.coc.retreatT = 1.0
		return
	G.dialog = next
	dialog_say()

# ====================================================================
#  NOC 4 · OPRAVA COCOY (polovodič VX84, Ema, jiskry)
# ====================================================================
const STORAGE_SPOT := Vector2(11.9, -0.35)
const REP_BENCH := Vector3(10.62, -5.6, PI / 2)
const REP_SEAT := Vector2(12.55, -5.6)
const REP_SPOT := Vector2(14.0, -5.6)
const REP_PROTO := Vector3(16.45, -6.45, -0.5)
var REPO = {"seat": null, "chip": null, "seat_mats": [], "seat_own": null, "fin_obst": false}

func _build_n4() -> void:
	# stůl, prototyp a bedny jsou ve scéně z exportu; sedící Cocoa a polovodič se ukazují podle postupu
	REPO.seat = place_model("res://models/n4/cocoa_seated_broken.glb", 1.25, Vector3(REP_SEAT.x, 0, REP_SEAT.y), PI / 2 - 0.35)
	for mi in REPO.seat.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in m.mesh.get_surface_count():
			var src = m.get_active_material(s)
			var own: StandardMaterial3D = src.duplicate() if src is StandardMaterial3D else StandardMaterial3D.new()
			if REPO.seat_own == null:
				REPO.seat_own = own.albedo_texture
			m.set_surface_override_material(s, own)
			REPO.seat_mats.append(own)
	REPO.seat.visible = false
	REPO.chip = place_model("res://models/n4/polovodic.glb", 0.09, Vector3(REP_BENCH.x + 0.35, 0.86, REP_BENCH.y + 0.35), 0)
	REPO.chip.visible = false

func rep_apply_visuals() -> void:
	var R = G.rep if G else null
	REPO.seat.visible = R != null and (not R.done or (R.get("fin") != null and R.fin.ph == "sit"))
	REPO.chip.visible = R != null and (R.chip or R.st >= 4) and not R.done
	if R != null and not R.done:
		for m in REPO.seat_mats:
			m.albedo_texture = COCO_TEX.hurt

func rep_init(n: int) -> void:
	REPO.seat.position = Vector3(REP_SEAT.x, 0, REP_SEAT.y)
	REPO.seat.rotation.y = PI / 2 - 0.35
	if n != 4:
		G.rep = null
		rep_apply_visuals()
		return
	var parts: Array = T.REP_PARTS.duplicate(true)
	parts.shuffle()
	G.rep = {"st": 0, "chip": false, "hide": pick(["S", "M", "O"]), "searched": {}, "pick": false, "bad": {}, "parts": parts, "nextShort": randf_range(10, 16), "done": false, "mountT": -1.0, "msgT": 0.0, "fin": null}
	COC.root.visible = false
	rep_apply_visuals()

func rep_ok(st: int) -> bool:
	return G and G.rep and not G.work and not G.rep.pick and not G.rep.done and G.rep.st == st and hour_of() >= T.REP_MINH[st]

func rep_interact(i: Dictionary) -> void:
	var w: Dictionary = T.REP_WORK[i.id]
	WORK[i.id] = {"need": w.need, "x": i.x, "z": i.z, "label": w.label}
	G.work = {"id": i.id, "prog": 0.0}
	hint(w.msg)

func rep_chest() -> Vector3:
	return Vector3(REP_SEAT.x, 0.8, REP_SEAT.y)

func rep_say(kind: String, o := {}) -> void:
	if G and not G.coc.off:
		var oo = {"force": true, "vol": 0.65, "speaker": not (roam.on and Vector2(roam.pos.x - REP_SEAT.x, roam.pos.z - REP_SEAT.y).length() < 6)}
		oo.merge(o, true)
		say_a(G.coc, kind, oo)

func rep_work_done(id: String) -> void:
	var R = G.rep
	if not R:
		return
	if id == "rep_inspect":
		R.st = 1
		spark_burst(rep_chest(), 14, 0.8)
		rep_say("n4_scan")
		hint("Ve schránce se pere cizí signál. Odpoj napájení (po 1 AM).")
	elif id == "rep_open":
		R.st = 2
		spark_burst(rep_chest(), 30, 1.1)
		rep_say("n4_open")
		G.camStatic = 0.6
		hint("Na desce svítí: VX84 · TO-247. Hledej přesně tenhle polovodič v bednách za dveřmi skladu.")
	elif id.begins_with("rep_box"):
		var k = id.right(1)
		R.searched[k] = true
		if k == R.hide:
			R.pick = true
			audio.sfx("found")
			hint("Našel jsi tři podobné díly. Vyber ten správný – špatný = zkrat!")
		else:
			hint(T.REP_BOX_MSG[k])
			rep_say("n4_search", {"vol": 0.4})
	elif id == "rep_mount":
		R.st = 4
		R.chip = false
		R.mountT = 0.0
		spark_burst(rep_chest(), 40, 1.3)
		rep_say("n4_mount")
		G.camStatic = 0.8
		hint("Polovodič zasazen. Počkej na 4 AM a vyladíme napětí.")
	elif id == "rep_calib":
		R.st = 5
		spark_burst(rep_chest(), 22, 0.9)
		rep_say("n4_calib")
		hint("Napětí stabilní. Poslední krok: restart po 5 AM.")
	elif id == "rep_boot":
		R.st = 6
		R.done = true
		rep_apply_visuals()
		G.coc.broken = false
		G.friend = true
		G.coc.timer = -10.0
		G.coc.pos = "c4"
		set_spot(COC, "c4")
		COC.root.visible = true
		cocoa_set_eyes(false)
		spark_burst(rep_chest(), 50, 1.4)
		rep_say("n4_boot")
		st_set("voxies_ema", true)
		R.fin = {"ph": "wake", "t": 0.0, "tot": 0.0, "k": 0, "open": 0.0}
		G.pz = null
		G.coc.path = null
		hint("Cocoa je opravená. Ema už neječí… spí uvnitř. Teď tě bude hlídat.")

func fin_go(spot: String, sp: float) -> void:
	var a: Dictionary = G.coc
	var from = COC.root.position
	a.pos = spot
	set_spot(COC, spot)
	a.speed = sp
	a.path = null
	start_walk(a, from)

func fin_hold() -> bool:
	if not G.rep or not G.rep.get("fin"):
		return false
	var F: Dictionary = G.rep.fin
	return F.tot < 140 and not (F.ph == "sit" and F.t > 8)

func fin_sit() -> void:
	var a: Dictionary = G.coc
	a.pos = "cOFF"
	a.path = null
	COC.root.visible = false
	coco_pizza.visible = true
	coco_pizza.position = Vector3(1.2, 0.86, 0.8)
	var s: Node3D = REPO.seat
	s.position = Vector3(2.75, 0, 0.95)
	s.rotation.y = -1.2
	s.visible = true
	for m in REPO.seat_mats:
		m.albedo_texture = COCO_TEX.blink
		m.emission_enabled = false
	if not REPO.fin_obst:
		REPO.fin_obst = true
		OBST.append({"x0": 2.3, "z0": 0.45, "x1": 3.2, "z1": 1.45, "ai": false, "hop": false})
	hint("Cocoa ti přinesla pizzu a sedla si vedle tebe. Vydrž do 6 AM.")
	rep_say("n4_sit", {"speaker": false})

func fin_update(dt: float) -> void:
	var R = G.rep
	if not R or not R.get("fin"):
		return
	var F: Dictionary = R.fin
	F.t += dt
	F.tot += dt
	var a: Dictionary = G.coc
	if F.ph == "sit":
		return
	if F.ph in ["toD", "knock", "in"]:
		var y = COC.root.rotation.y
		coco_pizza.position = Vector3(COC.root.position.x + sin(y) * 0.5, 1.0, COC.root.position.z + cos(y) * 0.5)
	if F.ph == "wake":
		if F.t > 4:
			F.ph = "toK"
			F.t = 0.0
			rep_say("n4_kitchen")
			fin_go("cK", 3)
	elif F.ph == "toK":
		if not a.path:
			F.ph = "kit"
			F.t = 0.0
	elif F.ph == "kit":
		if F.t > 2.5:
			F.ph = "toD"
			F.t = 0.0
			coco_pizza.visible = true
			audio.sfx("pz_show")
			fin_go("cDOOR", 3)
	elif F.ph == "toD":
		if not a.path:
			F.ph = "knock"
			F.t = 0.0
			F.k = 0
			F.open = 0.0
			rep_say("n4_bring", {"speaker": false, "vol": 0.7})
	elif F.ph == "knock":
		if F.t > 0.8 and F.k == 0:
			F.k = 1
			audio.sfx("softknock", 0.9)
		if F.t > 2.4 and F.k == 1:
			F.k = 2
			audio.sfx("softknock", 0.9)
		F.open = 0.0 if G.doorR else F.open + dt
		if F.k == 2 and (F.open > 1 or F.t > 9):
			if G.doorR:
				G.doorR = false
				audio.sfx("door", 0.8)
				hint("Cocoa ti otevřela pravé dveře.")
			F.ph = "in"
			F.t = 0.0
			fin_go("cOFF", 2.2)
	elif F.ph == "in":
		if not a.path:
			F.ph = "sit"
			F.t = 0.0
			fin_sit()

func rep_pick(p: Dictionary) -> void:
	var R = G.rep
	if not R or not R.pick:
		return
	if p.ok:
		R.pick = false
		R.chip = true
		R.st = 3
		rep_apply_visuals()
		audio.sfx("work_done")
		hint("Polovodič VX84 máš v inventáři. Montáž půjde po 3 AM (díl musí vychladnout).")
		rep_say("n4_search", {"vol": 0.5})
	else:
		R.bad[p.id] = true
		spark_burst(Vector3(REP_BENCH.x + 0.6, 1.0, REP_BENCH.y), 34, 1.2)
		spark_burst(rep_chest(), 30, 1.2)
		G.power = maxf(1, G.power - 8)
		G.camStatic = 1.0
		rep_say("n4_wrong")
		hint("ZKRAT! Špatný díl. -8 % proudu. Vyber jiný.")

# --- jiskry ---
const SP_N := 240
var sp_pos = PackedVector3Array()
var sp_vel = PackedVector3Array()
var sp_life = PackedFloat32Array()
var sp_mm: MultiMeshInstance3D
var sp_i = 0
var rep_flash = 0.0

func _build_sparks() -> void:
	sp_pos.resize(SP_N)
	sp_vel.resize(SP_N)
	sp_life.resize(SP_N)
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = SP_N
	var q = QuadMesh.new()
	q.size = Vector2(0.075, 0.075)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.vertex_color_use_as_albedo = true
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	mm.mesh = q
	sp_mm = MultiMeshInstance3D.new()
	sp_mm.multimesh = mm
	add_child(sp_mm)
	for i in SP_N:
		sp_pos[i] = Vector3(0, -100, 0)

func spark_burst(p: Vector3, n := 26, pw := 1.0) -> void:
	for k in n:
		var i = sp_i % SP_N
		sp_i += 1
		var a = randf_range(0, TAU)
		var r = randf_range(0.3, 2) * pw
		sp_pos[i] = p + Vector3(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05), randf_range(-0.05, 0.05))
		sp_vel[i] = Vector3(cos(a) * r, randf_range(0.5, 2.6) * pw, sin(a) * r)
		sp_life[i] = randf_range(0.35, 0.95)
	rep_flash = maxf(rep_flash, 0.28)
	spark_light.position = p + Vector3(0, 0.2, 0)
	audio.sfx("zkrat", 0, minf(1, pw))

func spark_tick(dt: float) -> void:
	var mm = sp_mm.multimesh
	for i in SP_N:
		if sp_life[i] <= 0:
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(0, -100, 0)))
			continue
		sp_life[i] -= dt
		var v = sp_vel[i]
		v.y -= 7 * dt
		var p = sp_pos[i] + v * dt
		if p.y < 0.02:
			p.y = 0.02
			v.y *= -0.35
			v.x *= 0.6
			v.z *= 0.6
		sp_vel[i] = v
		sp_pos[i] = p
		var k = clampf(sp_life[i] * 2.2, 0, 1)
		mm.set_instance_transform(i, Transform3D(Basis(), p))
		mm.set_instance_color(i, Color(k, (0.65 + randf() * 0.3) * k, (0.25 + 0.75 * (1 - k)) * k, 1))
	rep_flash = maxf(0, rep_flash - dt)
	spark_light.light_energy = (randf_range(1.5, 9) * minf(1, rep_flash * 5) * LK) if rep_flash > 0 else 0.0

func rep_tick(dt: float) -> void:
	spark_tick(dt)
	if G and G.rep and not G.rep.done:
		var hot = rep_flash > 0
		for m in REPO.seat_mats:
			m.emission_enabled = hot
			if hot:
				m.emission = Color(randf_range(0.1, 0.5), randf_range(0.2, 0.7), randf_range(0.4, 1))
			var want = REPO.seat_own if (hot and randf() < 0.5 and REPO.seat_own) else COCO_TEX.hurt
			if want and m.albedo_texture != want:
				m.albedo_texture = want
	if G and G.rep and G.rep.mountT >= 0 and not G.rep.done:
		G.rep.mountT += dt
		var k = ease_io(clampf(G.rep.mountT / 2.0, 0, 1))
		var c = rep_chest()
		var a = Vector3(REP_BENCH.x + 0.35, 0.95, REP_BENCH.y + 0.35)
		REPO.chip.position = a.lerp(c, k)

func rep_update(dt: float) -> void:
	var R = G.rep
	if not R:
		return
	if not R.done:
		COC.root.visible = false
	if R.msgT > 0:
		R.msgT -= dt
	if R.done or R.st < 1:
		return
	R.nextShort -= dt
	if R.nextShort <= 0:
		R.nextShort = randf_range(13, 22) * (0.8 if R.st >= 4 else 1.0)
		spark_burst(rep_chest(), 24, 1)
		rep_say(pick(["n4_zap", "n4_pain"]), {"vol": 0.55})
		if R.st >= 4 and Vector2(roam.pos.x - REP_SEAT.x, roam.pos.z - REP_SEAT.y).length() < 3.2 and roam.on:
			G.power = maxf(1, G.power - 2)
			G.camStatic = maxf(G.camStatic, 0.5)
	if G.work and String(G.work.id).begins_with("rep_") and randf() < dt * 0.8:
		spark_burst(rep_chest(), 5, 0.5)

# ====================================================================
#  VYKRESLENÍ 3D
# ====================================================================
func stage_rgb(t: float) -> void:
	glitch_t = maxf(0, glitch_t - frame_dt)
	if glitch_t > 0:
		var c = Color("#ff0020") if int(floor(t * 18)) % 2 else Color("#8a00ff")
		stage_spot.light_color = c
		stage_fill.light_color = c
		stage_spot.light_energy = 110 * LK
		stage_fill.light_energy = 18 * LK
	else:
		var k = 0.25 if (G and G.out) else 1.0
		var c = Color.from_hsv((sin(t * 2.0) + 1) / 2.0, 0.9, 1.0)
		stage_spot.light_color = c
		stage_fill.light_color = c
		stage_spot.light_energy = 45 * k * LK
		stage_fill.light_energy = 7 * k * LK

func render(t: float) -> void:
	var out: bool = G != null and G.out
	if office.shutL:
		office.shutL.position.y = DOOR_H * (1 - (G.aL if G else 0.0))
		office.shutR.position.y = DOOR_H * (1 - (G.aR if G else 0.0))
	office_lamp.light_energy = 0.0 if out else 9 * (0.3 if (G and G.flick > 0) else 1.0) * (0.95 + randf() * 0.05) * LK
	env.ambient_light_energy = 0.06 if out else hemi_amb
	hall_l.light_energy = 26 * LK if (G and G.light == "L" and not out) else 0.0
	hall_r.light_energy = 26 * LK if (G and G.light == "R" and not out) else 0.0
	door_glow.light_energy = 1.2 * LK if (out and G.outPhase == 1 and randf() < 0.75) else 0.0
	if office.blades and not out:
		office.blades.rotation.z = t * 18
	for m in hall_flicker:
		var v = 0.15 if sin(t * 13) > 0.55 else 1.0
		m.albedo_color = Color("#fff3c4") * v
	if G:
		office.PanLD.albedo_color = Color("#ff3b3b") if G.doorL else Color("#4a1414")
		office.PanLL.albedo_color = Color("#fff3c4") if G.light == "L" else Color("#3a3a3a")
		office.PanRD.albedo_color = Color("#ff3b3b") if G.doorR else Color("#4a1414")
		office.PanRL.albedo_color = Color("#fff3c4") if G.light == "R" else Color("#3a3a3a")
		office.led_mat.albedo_color = Color("#ff3030") if (G.call.on and sin(t * 8) > 0) else Color("#300808")
	# mrkání Cocoy
	blink_t -= frame_dt
	if blink_t <= 0:
		blink_t = 3.0 + randf() * 3.0
		if cocoa_hold == 0:
			cocoa_set_eyes(true)
			say_later(0.14, func(): if cocoa_hold == 0: cocoa_set_eyes(false))
	var cam: Camera3D = office_cam
	red_light.light_energy = 0
	var EX: Dictionary = hud.EX
	for ch in [VOX, COC]:
		var a = null
		if G and scene_ != "extras":
			a = G.vox if ch == VOX else G.coc
		var mode = "idle"
		if scene_ == "extras":
			var sel: bool = EX.page == "chars" and (VOX if EX.idx == 0 else COC) == ch
			ch.root.visible = sel
			if not sel:
				continue
			if EX.scare >= 0:
				mode = "scare"
				var k = ease_io(clampf(EX.scare / 0.12, 0, 1))
				ch.root.position = Vector3(0, -0.25 * k, SHOW_Z + 2.3 * k)
				ch.root.rotation = Vector3.ZERO
				red_light.light_energy = 6 * k * LK
				red_light.position = Vector3(0, 0.8, SHOW_Z + 3.6)
			else:
				ch.root.position = Vector3(0, 0.3, SHOW_Z)
				ch.root.rotation = Vector3(0, EX.rot, 0)
				ch.C.look = 0.0
			ch.pose(t, mode, EX.scare)
			continue
		if scene_ == "scare" and killer and _ai_def(killer.id).ch == ch:
			mode = "scare"
			ch.root.visible = true
			var eye: Camera3D = roam_cam if roam.on else office_cam
			var fwd = -eye.global_transform.basis.z
			fwd.y = 0
			fwd = fwd.normalized()
			var k = ease_io(clampf(scare_t / 0.12, 0, 1))
			var stp = 0 if scare_t < 0.12 else (1 if scare_t < 0.26 else 2)
			ch.root.position = eye.global_position + fwd * [2.7, 2.0, 1.45][stp]
			ch.root.position.y = eye.global_position.y - 1.75 - 0.12 * stp
			ch.root.rotation = Vector3(0, atan2(-fwd.x, -fwd.z), 0)
			red_light.light_energy = 6 * k * (0.3 if randf() < 0.15 else 1.0) * LK
			red_light.position = ch.root.position - fwd * 0.9
			red_light.position.y = eye.global_position.y - 0.6
		elif a:
			if a.broken:
				mode = "broken"
			elif a.pos == D(a).door:
				mode = "door"
			if a.pos == "1A" or a.pos == "c3":
				mode = "stage"
			if a.path:
				mode = "walk"
		if a and a.path and scene_ == "play":
			walk_step(a, ch, frame_dt)
		var watching: bool = a != null and G.cams and G.camA >= 1 and SPOTS.has(a.pos) and SPOTS[a.pos].get("cam", "") == G.cam
		var tgt = 1.0 if (watching and a.watchT > 1.2) else 0.0
		var at = cams3d[G.cam].cam.global_position if watching else null
		if roam.on and a and not a.off and ch.root.position.distance_to(roam_cam.position) < 7:
			tgt = 1.0
			at = roam_cam.position
		if G and G.dialog and ch == COC:
			tgt = 1.0
			at = roam_cam.position if roam.on else office_cam.position
		if G and G.pz and ch == COC and G.pz.ph in ["peek", "pizza", "thanks"]:
			tgt = 1.0
			at = office_cam.position
		ch.C.look += (tgt - ch.C.look) * 0.06
		if at != null:
			ch.C.look_at = at
		elif ch.C.look < 0.02:
			ch.C.look_at = null
		ch.C.lit = a.lit if a else 0.0
		if scene_ == "menu":
			ch.C.look = 0.6
			ch.C.look_at = cams3d["1A"].cam.global_position
		if G and G.damaged and ch == VOX and mode != "walk" and mode != "scare":
			ch.C.lit = 3.0
		if a and a.broken:
			mode = "broken"
		ch.pose(t, mode, scare_t)
		if ch == VOX:
			var red: bool = G != null and G.damaged
			for m in vox_eyes:
				m.albedo_color = (Color("#ff1010") if randf() < 0.85 else Color("#330000")) if red else Color("#111111")
	# kamera
	if scene_ == "extras" and EX.page == "chars":
		cam = show_cam
		room_light.position = Vector3(0, 4, SHOW_Z + 2)
		room_light.light_energy = 22 * LK
		env.ambient_light_energy = 0.9
	elif scene_ in ["menu", "custom", "devmenu", "extras"]:
		cam = cams3d["1A"].cam
		room_light.position = v3(CAMS["1A"].light)
		room_light.light_energy = 14 * LK
	elif G and roam.on and scene_ in ["play", "scare"]:
		update_roam_cam()
		cam = roam_cam
		if scene_ == "scare":
			var I = 0.3 * (1 - clampf((scare_t - 0.9) / 0.5, 0, 1))
			roam_cam.position += Vector3((randf() - 0.5) * I, (randf() - 0.5) * I, 0)
	elif G and G.cams and G.camA >= 1:
		var c: Dictionary = cams3d[G.cam]
		cam = c.cam
		cam.quaternion = c.baseQ * Quaternion(Vector3.UP, sin(t * 0.35) * 0.12)
		room_light.position = v3(CAMS[G.cam].light)
		room_light.light_energy = ((16.0 if sin(t * 9) > 0.3 else 4.0) if G.cam == "4" else (9.0 if G.cam in ["8", "9"] else 22.0)) * LK
		env.ambient_light_energy = 0.8
	else:
		room_light.light_energy = 0
		flash.light_energy = 0
		var sh = 0.25 * (1 - clampf((scare_t - 0.9) / 0.5, 0, 1)) if scene_ == "scare" else 0.0
		office_cam.position = OFFICE_EYE + Vector3((randf() - 0.5) * sh, (randf() - 0.5) * sh, 0)
		if look_target != null and G:
			G.look += (float(look_target) - G.look) * 0.12
			if absf(float(look_target) - G.look) < 0.01:
				look_target = null
		office_cam.rotation = Vector3(-0.05, G.look if G else 0.0, (randf() - 0.5) * sh * 0.6)
	stage_rgb(t)
	var se: Camera3D = roam_cam if roam.on else office_cam
	var f = (60.0 if scare_t < 0.1 else 45.0) if scene_ == "scare" else 72.0
	office_cam.fov = f if se == office_cam else 72.0
	roam_cam.fov = f if se == roam_cam else 72.0
	cam.current = true
	hud.queue_redraw()

# ---------- automatické snímky pro kontrolu ----------
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shot_" + n + ".png")

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _shots() -> void:
	await _wait(2.0)
	await _shot("menu")
	new_game(1)
	await _wait(1.0)
	await _shot("intro")
	scene_ = "play"
	await _wait(1.0)
	await _shot("office")
	G.look = 1.0
	set_light("L")
	await _wait(0.5)
	await _shot("office_left")
	set_light(null)
	G.look = 0.0
	toggle_cams()
	await _wait(1.0)
	await _shot("cam1A")
	for c in ["2", "5", "4", "3"]:
		select_cam(c)
		await _wait(0.8)
		await _shot("cam" + c)
	toggle_cams()
	await _wait(0.5)
	new_game(3)
	scene_ = "play"
	G.t = 30
	toggle_roam()
	roam.pos = Vector3(-15.5, 1.6, -17.5)
	roam.yaw = PI * 0.75
	await _wait(1.0)
	await _shot("kitchen")
	roam.pos = Vector3(-16, 1.6, -19.6)
	await _wait(0.5)
	await _shot("kitchen_order")
	roam.pos = Vector3(-14, 1.6, 4.5)
	roam.yaw = 0.0
	await _wait(0.5)
	await _shot("vchod")
	roam.pos = Vector3(-13, 1.6, -5)
	roam.yaw = PI / 2
	await _wait(0.5)
	await _shot("pokladna")
	DEV.noclip = true
	roam.pos = Vector3(14, 1.6, 0.0)
	roam.yaw = -PI * 0.8
	await _wait(0.5)
	await _shot("vojtech")
	roam.yaw = PI * 0.8
	await _wait(0.5)
	await _shot("vojtech2")
	DEV.noclip = false
	new_game(4)
	scene_ = "play"
	toggle_roam()
	roam.pos = Vector3(14.2, 1.6, -5.6)
	roam.yaw = PI / 2
	await _wait(0.6)
	spark_burst(rep_chest(), 40, 1.2)
	await _wait(0.15)
	await _shot("repair")
	to_menu()
	scene_ = "extras"
	await _wait(1.0)
	await _shot("extras")
	hud.EX.idx = 1
	await _wait(0.6)
	await _shot("extras_cocoa")
	hud.EX.idx = 0
	store["voxies_secret"] = true
	hud.EX.page = "song"
	await _wait(0.5)
	await _shot("song")
	hud.EX.song = 7
	await _wait(0.3)
	await _shot("song_end")
	store.erase("voxies_secret")
	hud.start_mini(2)
	await _wait(1.0)
	await _shot("mini")
	get_tree().quit()

static func make_font() -> Font:
	var f: FontFile = load("res://fonts/mono.ttf")
	var sy: FontFile = load("res://fonts/symbols.ttf")
	var em: FontFile = load("res://fonts/emoji.ttf")
	for x in [f, sy, em]:
		x.allow_system_fallback = false
	f.fallbacks = [sy, em]
	return f
