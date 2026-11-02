extends Node3D
## Night at Voxie's (1. díl) – port z webové verze (three.js) do Godotu 4.
## Kancelář se dveřmi a světly, 10 kamer, proud, Voxie (levé dveře) a Cocoa (pravé dveře), noci 1–5 a vlastní noc.

const VoxieBuilder := preload("res://scripts/voxie.gd")
const HOUR := 70.0
const MOVE_INT := 5.0
const OFFICE_EYE := Vector3(0, 1.35, 1.9)
const DOOR_H := 2.5

const VOX_LEVELS := [[2, 2, 3, 4, 5, 5], [5, 6, 6, 7, 8, 9], [7, 8, 9, 10, 11, 12], [10, 11, 12, 13, 14, 15], [13, 14, 15, 17, 18, 20]]
const COC_LEVELS := [[1, 1, 2, 2, 3, 3], [3, 3, 4, 5, 5, 6], [5, 6, 6, 7, 8, 8], [7, 8, 9, 10, 10, 11], [10, 11, 12, 13, 14, 15]]
const DRAIN := [0.095, 0.1, 0.105, 0.11, 0.115, 0.115]

const CAMS := {
	"1A": ["Pódium", Vector3(5.2, 3.5, -22.6), Vector3(-1, 1.4, -27.5)],
	"1B": ["Herna s automaty", Vector3(-9.3, 2.9, -12.6), Vector3(3, 0.9, -18)],
	"2": ["Pizzerie", Vector3(-10.6, 2.9, -10.6), Vector3(-16, 0.7, -16)],
	"3": ["Trubkové bludiště", Vector3(10.6, 2.9, -10.6), Vector3(17, 0.6, -17)],
	"4": ["Sklad", Vector3(21.3, 2.9, -2.6), Vector3(15, 0.8, -7)],
	"5": ["Výdej lístků", Vector3(-10.6, 2.9, -2.6), Vector3(-17, 0.9, -7)],
	"6": ["Toalety", Vector3(3.4, 2.9, -11.4), Vector3(-1, 0.9, -5)],
	"7": ["Vchod", Vector3(-10.6, 2.9, 5.4), Vector3(-16, 1.2, -0.5)],
	"8": ["Levá chodba", Vector3(-5, 2.85, 0.7), Vector3(-5, 0.9, -10)],
	"9": ["Pravá chodba", Vector3(5, 2.85, 0.7), Vector3(5, 0.9, -10)],
}
const CAM_ORDER := ["1A", "1B", "2", "3", "4", "5", "6", "7", "8", "9"]
# zastávky animatroniků: [pozice, kamera, natočení (null = ke kameře)]
const SPOTS := {
	"1A": [Vector3(-1.4, 0.6, -27.6), "1A"], "1B": [Vector3(3, 0, -17), "1B"], "2": [Vector3(-15, 0, -15.6), "2"],
	"6": [Vector3(1.2, 0, -6.5), "6"], "8": [Vector3(-5, 0, -6), "8"], "DOOR": [Vector3(-5, 0, -0.15), "", PI / 2],
	"c3": [Vector3(15, 0, -13.2), "3"], "c4": [Vector3(14.2, 0, -5), "4"], "c1B": [Vector3(-3.5, 0, -16), "1B"],
	"c9": [Vector3(5, 0, -6.5), "9"], "cDOOR": [Vector3(5, 0, -0.15), "", -PI / 2],
}
const NEXT := {
	"V": {"1A": ["1B"], "1B": ["2", "2", "6"], "6": ["2"], "2": ["8"], "8": ["DOOR"]},
	"C": {"c3": ["c4", "c1B"], "c4": ["c1B", "c9"], "c1B": ["c9"], "c9": ["cDOOR"]},
}
const AI_DEF := {
	"V": {"side": "L", "start": "1A", "door": "DOOR", "back": ["2", "1B"], "nice": false, "name": "Voxie"},
	"C": {"side": "R", "start": "c3", "door": "cDOOR", "back": ["c3", "c4"], "nice": true, "name": "Cocoa"},
}

var state := "menu"
var scene_t := 0.0
var G := {}
var progress := 1
var custom := {"v": 10, "c": 6}
var killer := ""

var office_cam: Camera3D
var cam_cam: Camera3D
var env: Environment
var office_lamp: OmniLight3D
var room_light: OmniLight3D
var hall := {}
var red_light: OmniLight3D
var shut := {}
var vox: Node3D
var coc: Node3D
var chars := {}
var sfx := {}
var music: AudioStreamPlayer
var ambient: AudioStreamPlayer
var buzz: AudioStreamPlayer
var look := 0.0
var look_target = null
var dragging := false

# UI
var ui: CanvasLayer
var root_ui: Control
var font: Font
var static_rect: ColorRect
var flash_rect: ColorRect

func _ready() -> void:
	_load_save()
	_build_world()
	_build_audio()
	_build_ui()
	_show_menu()
	if "--shots" in OS.get_cmdline_user_args():
		_run_shots()

# ====================================================================
#  SVĚT
# ====================================================================
func _build_world() -> void:
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.35, 0.63)
	env.ambient_light_energy = 0.35
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.01, 0.03)
	env.fog_density = 0.03
	env.glow_enabled = true
	env.glow_intensity = 0.8
	we.environment = env
	add_child(we)
	var bld: Node3D = load("res://models/building.glb").instantiate()
	add_child(bld)
	_hide_glb_shutters(bld)
	office_cam = Camera3D.new()
	office_cam.fov = 72
	office_cam.position = OFFICE_EYE
	add_child(office_cam)
	cam_cam = Camera3D.new()
	cam_cam.fov = 68
	add_child(cam_cam)
	office_lamp = OmniLight3D.new()
	office_lamp.position = Vector3(0, 2.8, 0.4)
	office_lamp.light_color = Color("#ffd9a0")
	office_lamp.omni_range = 9
	office_lamp.light_energy = 2.2
	office_lamp.shadow_enabled = true
	add_child(office_lamp)
	room_light = OmniLight3D.new()
	room_light.light_color = Color("#fff0d8")
	room_light.omni_range = 26
	room_light.light_energy = 0
	add_child(room_light)
	for s in ["L", "R"]:
		var x := -5.0 if s == "L" else 5.0
		var sp := SpotLight3D.new()
		sp.light_color = Color("#ffe7b0")
		sp.spot_range = 14
		sp.spot_angle = 32
		sp.light_energy = 0
		sp.shadow_enabled = true
		add_child(sp)
		sp.look_at_from_position(Vector3(x, 2.9, 1.0), Vector3(x, 0.5, -8))
		hall[s] = sp
		var sh := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.08, DOOR_H, 2.05)
		sh.mesh = bm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("#4b505b")
		m.metallic = 0.6
		m.roughness = 0.5
		sh.material_override = m
		sh.position = Vector3(-4.0 if s == "L" else 4.0, DOOR_H * 1.5, 0)
		add_child(sh)
		shut[s] = sh
	red_light = OmniLight3D.new()
	red_light.light_color = Color(1, 0.06, 0.06)
	red_light.omni_range = 6
	red_light.light_energy = 0
	add_child(red_light)
	# animatronici
	vox = VoxieBuilder.build()
	add_child(vox)
	coc = Node3D.new()
	coc.name = "Cocoa"
	add_child(coc)
	var cm: Node3D = load("res://models/cocoa.glb").instantiate()
	coc.add_child(cm)
	var aabb := _aabb(cm)
	var k: float = 1.85 / max(aabb.size.y, 0.01)
	cm.scale = Vector3.ONE * k
	cm.position = Vector3(-(aabb.position.x + aabb.size.x / 2) * k, -aabb.position.y * k, -(aabb.position.z + aabb.size.z / 2) * k)
	chars = {"V": vox, "C": coc}

func _hide_glb_shutters(n: Node) -> void:
	# rolety dveří kanceláře z exportu mapy – máme vlastní, pohyblivé
	for c in n.get_children():
		if c is MeshInstance3D:
			var a: AABB = c.global_transform * c.get_aabb()
			var ctr := a.get_center()
			if abs(abs(ctr.x) - 4.0) < 0.3 and abs(ctr.z) < 1.2 and a.size.x < 0.3 and ctr.y < 2.7:
				c.visible = false
		_hide_glb_shutters(c)

func _aabb(n: Node) -> AABB:
	var res := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var a: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		if first:
			res = a
			first = false
		else:
			res = res.merge(a)
	return res

func _set_spot(id: String, pos_id: String) -> void:
	var ch: Node3D = chars[id]
	var s: Array = SPOTS[pos_id]
	ch.position = s[0]
	if s.size() > 2:
		ch.rotation.y = s[2]
	else:
		var cp: Vector3 = CAMS[s[1]][1]
		ch.rotation.y = atan2(cp.x - s[0].x, cp.z - s[0].z) + randf_range(-0.3, 0.3)

# ====================================================================
#  ZVUK
# ====================================================================
func _build_audio() -> void:
	for n in ["scream", "door", "step", "click", "cam", "knock", "chime", "powerdown", "buzz", "amb", "static"]:
		var p := AudioStreamPlayer.new()
		var st: AudioStreamWAV = load("res://sfx/" + n + ".wav")
		if n in ["buzz", "amb"]:
			st = st.duplicate()
			st.loop_mode = AudioStreamWAV.LOOP_FORWARD
			st.loop_end = st.data.size() / 2
		p.stream = st
		add_child(p)
		sfx[n] = p
	buzz = sfx["buzz"]
	ambient = sfx["amb"]
	ambient.volume_db = -6
	music = AudioStreamPlayer.new()
	var ms: AudioStreamMP3 = load("res://audio/menu.mp3")
	ms.loop = true
	music.stream = ms
	add_child(music)

func play(n: String, vol := 0.0, pitch := 1.0) -> void:
	var p: AudioStreamPlayer = sfx[n]
	p.volume_db = vol
	p.pitch_scale = pitch
	p.play()

# ====================================================================
#  HRA
# ====================================================================
func new_game(n: int) -> void:
	music.stop()
	G = {"night": n, "t": 0.0, "power": 100.0, "door": {"L": false, "R": false}, "a": {"L": 0.0, "R": 0.0}, "light": "", "cams": false, "cam": "1A",
		"out": false, "out_t": 0.0, "static": 0.0, "msg": "", "msg_t": 0.0,
		"ai": {"V": _mk_ai("V"), "C": _mk_ai("C")}}
	look = 0.0
	look_target = null
	for id in ["V", "C"]:
		_set_spot(id, G.ai[id].pos)
		chars[id].visible = true
	vox.find_child("RedEyes", true, false).visible = false
	state = "intro"
	scene_t = 0.0
	_show_hud()

func _mk_ai(id: String) -> Dictionary:
	return {"id": id, "pos": AI_DEF[id].start, "timer": 0.0, "lit": 0.0, "attack": false, "attack_t": 0.0, "retreat_t": 0.0, "knocked": false, "walk": 0.0}

func _hour() -> int:
	return min(6, int(G.t / HOUR))

func _lvl(id: String) -> int:
	if G.night == 6:
		return custom.v if id == "V" else custom.c
	var L: Array = VOX_LEVELS if id == "V" else COC_LEVELS
	return L[G.night - 1][min(5, _hour())]

func _usage() -> int:
	if G.out:
		return 0
	return 1 + int(G.door.L) + int(G.door.R) + int(G.light != "") + int(G.cams)

func toggle_door(s: String) -> void:
	if state != "play" or G.out or G.cams:
		return
	G.door[s] = not G.door[s]
	play("door", -4, 1.0 if s == "L" else 1.1)

func set_light(s: String) -> void:
	if state != "play" or G.out or G.cams:
		return
	G.light = "" if G.light == s else s
	if G.light != "":
		play("click")
		buzz.play()
	else:
		buzz.stop()

func toggle_cams() -> void:
	if state != "play" or G.out:
		return
	G.cams = not G.cams
	if G.cams and G.light != "":
		set_light(G.light)
	play("cam", -6)
	G.static = 0.3

func select_cam(id: String) -> void:
	if G.cam != id:
		G.cam = id
		G.static = 0.35
		play("cam", -8)

func _move_to(a: Dictionary, np: String) -> void:
	var old: String = a.pos
	a.pos = np
	a.walk = 1.0
	var from: Vector3 = chars[a.id].position
	_set_spot(a.id, np)
	a["from"] = from
	if G.cams and (SPOTS[old][1] == G.cam or SPOTS[np][1] == G.cam):
		G.static = 1.1
	var d: Dictionary = AI_DEF[a.id]
	if np == d.door:
		play("step", -2 if not d.nice else -8, 0.9)
		a.lit = 0.0
		a.knocked = false

func _retreat(a: Dictionary, knock: bool) -> void:
	var d: Dictionary = AI_DEF[a.id]
	if knock:
		play("knock", -2)
	a.pos = d.back[randi() % d.back.size()]
	a.lit = 0.0
	a.timer = -2.0
	a.retreat_t = 0.0
	_set_spot(a.id, a.pos)
	play("step", -10)

func _ai_update(a: Dictionary, dt: float) -> void:
	var d: Dictionary = AI_DEF[a.id]
	if a.attack:
		a.attack_t += dt
		if not G.cams or a.attack_t > 3.0:
			_jumpscare(a.id)
		return
	if a.retreat_t > 0:
		a.retreat_t -= dt
		if a.retreat_t <= 0:
			_retreat(a, false)
		return
	if a.pos == d.door and G.light == d.side and not G.door[d.side]:
		a.lit += dt
		if d.nice:
			if a.lit > 1.0:
				a.retreat_t = 1.2
		elif a.lit > 3.5:
			a.attack = true
			a.attack_t = 0.0
			set_light(G.light)
			return
	elif a.pos == d.door and not d.nice and a.lit >= 1.0 and G.light != d.side:
		a.retreat_t = 0.5
	if G.t < (35.0 if d.nice else 20.0):
		return
	a.timer += dt
	if a.timer < MOVE_INT:
		return
	a.timer -= MOVE_INT
	if randf() * 20.0 >= _lvl(a.id):
		return
	if a.pos == d.door:
		if G.door[d.side]:
			_retreat(a, true)
		elif G.light == d.side:
			pass
		elif d.nice and not a.knocked:
			a.knocked = true
			play("knock", -2)
			_say("Ťuk ťuk! To jsem já, Cocoa!")
		else:
			a.attack = true
			a.attack_t = 0.0
	else:
		var opts: Array = NEXT[a.id][a.pos]
		_move_to(a, opts[randi() % opts.size()])

func _say(t: String, dur := 3.0) -> void:
	G.msg = t
	G.msg_t = dur

func _power_out() -> void:
	G.out = true
	G.power = 0.0
	G.door = {"L": false, "R": false}
	G.light = ""
	G.cams = false
	buzz.stop()
	ambient.stop()
	play("powerdown")
	G.out_t = 0.0
	G.ai.V.pos = "DOOR"
	_set_spot("V", "DOOR")

func _jumpscare(id: String) -> void:
	if state != "play":
		return
	killer = id
	state = "scare"
	_clear_ui()
	scene_t = 0.0
	G.cams = false
	buzz.stop()
	ambient.stop()
	play("scream", 2)
	Input.vibrate_handheld(600)

func _win() -> void:
	state = "win"
	scene_t = 0.0
	buzz.stop()
	ambient.stop()
	play("chime")
	if G.night <= 5:
		progress = max(progress, min(6, G.night + 1))
		_save()

func _process(dt: float) -> void:
	scene_t += dt
	match state:
		"intro":
			if scene_t > 3.0:
				state = "play"
				scene_t = 0.0
				ambient.play()
		"play":
			_update_play(dt)
		"scare":
			if scene_t > 1.5:
				state = "dead"
				scene_t = 0.0
				_show_end(false)
	_update_view(dt)
	_update_ui(dt)

func _update_play(dt: float) -> void:
	G.t += dt
	if G.t >= 6.0 * HOUR:
		_win()
		_show_end(true)
		return
	for s in ["L", "R"]:
		G.a[s] = lerp(G.a[s], 1.0 if G.door[s] else 0.0, min(1.0, dt * 12.0))
	G.static = max(0.0, G.static - dt)
	if G.msg_t > 0:
		G.msg_t -= dt
	if G.out:
		G.out_t += dt
		if G.out_t > 10.0:
			_jumpscare("V")
		return
	G.power -= _usage() * DRAIN[G.night - 1] * dt
	if G.power <= 0:
		_power_out()
		return
	for id in ["V", "C"]:
		if _lvl(id) > 0 or G.night != 6:
			_ai_update(G.ai[id], dt)
	if Input.is_action_just_pressed("ui_left"):
		look_target = clamp(look + 0.95, -1.15, 1.15)
	if Input.is_action_just_pressed("ui_right"):
		look_target = clamp(look - 0.95, -1.15, 1.15)

func _unhandled_input(e: InputEvent) -> void:
	if state != "play" or G.cams:
		return
	if e is InputEventScreenDrag:
		look = clamp(look - e.relative.x / 400.0, -1.15, 1.15)
		look_target = null
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_A: toggle_door("L")
			KEY_D: toggle_door("R")
			KEY_Q: set_light("L")
			KEY_E: set_light("R")
			KEY_SPACE: toggle_cams()

func _update_view(dt: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var playing: bool = not G.is_empty() and state in ["play", "scare", "intro"]
	for s in ["L", "R"]:
		var a: float = G.a[s] if playing else 0.0
		shut[s].position.y = DOOR_H * (1.0 - a) + DOOR_H / 2.0
		hall[s].light_energy = 6.0 if playing and G.light == s and not G.out else 0.0
	office_lamp.light_energy = 0.0 if playing and G.out else 2.2 * (0.95 + randf() * 0.05)
	# animatronici: krátká chůze mezi zastávkami, stání na pódiu
	if playing:
		for id in ["V", "C"]:
			var a: Dictionary = G.ai[id]
			var ch: Node3D = chars[id]
			if a.walk > 0 and a.has("from"):
				a.walk = max(0.0, a.walk - dt * 1.2)
				var tgt: Vector3 = SPOTS[a.pos][0]
				ch.position = tgt.lerp(a.from, a.walk)
				ch.position.y = tgt.y + abs(sin(a.walk * 18.0)) * 0.05
			_pose(id, t, a.walk > 0)
	if state == "scare":
		var ch: Node3D = chars[killer]
		var k: float = clamp(scene_t / 0.12, 0.0, 1.0)
		var fwd := -office_cam.global_transform.basis.z
		fwd.y = 0
		fwd = fwd.normalized()
		ch.visible = true
		ch.position = office_cam.global_position + fwd * (2.6 - 1.2 * k)
		ch.position.y = office_cam.global_position.y - 1.75 - 0.2 * k
		ch.rotation = Vector3(0, atan2(-fwd.x, -fwd.z), randf_range(-0.05, 0.05))
		if killer == "V":
			vox.find_child("RedEyes", true, false).visible = true
			var rig: Dictionary = vox.get_meta("rig")
			rig.armR1.rotation.x = -1.4 * k
			rig.armL1.rotation.x = -1.4 * k
		red_light.light_energy = 6.0 * k
		red_light.position = ch.position - fwd * 0.9 + Vector3(0, 1.2, 0)
	else:
		red_light.light_energy = 0
	# kamera
	if look_target != null:
		look = lerp(look, float(look_target), 0.12)
		if abs(look - float(look_target)) < 0.01:
			look_target = null
	if playing and G.cams:
		var c: Array = CAMS[G.cam]
		cam_cam.position = c[1]
		cam_cam.look_at(c[2])
		cam_cam.rotate_y(sin(t * 0.35) * 0.12)
		cam_cam.current = true
		var rid := String(G.cam)
		room_light.position = c[2] + Vector3(0, 2.4, 0)
		room_light.light_energy = 2.5
	else:
		room_light.light_energy = 0
		var sh: float = 0.05 * (1.0 - clamp((scene_t - 0.9) / 0.5, 0.0, 1.0)) if state == "scare" else 0.0
		office_cam.position = OFFICE_EYE + Vector3(randf_range(-sh, sh), randf_range(-sh, sh), 0)
		office_cam.rotation = Vector3(-0.05, look, 0)
		office_cam.current = true
		if state == "menu":
			var c: Array = CAMS["1A"]
			cam_cam.position = c[1]
			cam_cam.look_at(c[2])
			cam_cam.current = true
			room_light.position = c[2] + Vector3(0, 2.4, 0)
			room_light.light_energy = 2.0

func _pose(id: String, t: float, walking: bool) -> void:
	if id == "V":
		var rig: Dictionary = vox.get_meta("rig")
		var ph := t * 7.0
		var w := 1.0 if walking else 0.0
		rig.legR1.rotation.x = sin(ph) * 0.4 * w
		rig.legL1.rotation.x = -sin(ph) * 0.4 * w
		rig.armR1.rotation.x = -sin(ph) * 0.3 * w
		rig.armL1.rotation.x = sin(ph) * 0.3 * w
		rig.head.rotation.y = sin(t * 1.3) * 0.15 if not walking else 0.0
		vox.find_child("RedEyes", true, false).visible = G.ai.V.pos == "DOOR" and G.light == "L"

# ====================================================================
#  UI (vše z kódu, aby šel projekt snadno číst a sestavit)
# ====================================================================
var hud_nodes := {}

func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	font = SystemFont.new()
	(font as SystemFont).font_names = PackedStringArray(["Courier New", "DejaVu Sans Mono", "monospace"])
	(font as SystemFont).font_weight = 700
	static_rect = ColorRect.new()
	static_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	static_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := ShaderMaterial.new()
	var code := Shader.new()
	code.code = "shader_type canvas_item; uniform float amount = 0.1; uniform float scan = 0.0; float h(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); } void fragment(){ vec2 uv = SCREEN_UV; float n = h(floor(uv * vec2(320.0,180.0)) + vec2(TIME * 60.0, TIME * 37.0)); float s = scan * step(0.5, fract(FRAGCOORD.y * 0.5)); float v = 1.0 - smoothstep(0.35, 0.9, distance(uv, vec2(0.5))); COLOR = vec4(vec3(n), amount) + vec4(0.0, 0.0, 0.0, s * 0.25) + vec4(0.0, 0.0, 0.0, (1.0 - v) * 0.55); }"
	sh.shader = code
	static_rect.material = sh
	ui.add_child(static_rect)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	ui.add_child(flash_rect)
	root_ui = Control.new()
	root_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root_ui)

func _clear_ui() -> void:
	for c in root_ui.get_children():
		c.queue_free()
	hud_nodes = {}

func _label(text: String, pos: Vector2, size := 20, col := Color.WHITE, parent: Control = null, align := HORIZONTAL_ALIGNMENT_LEFT, w := 0.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.horizontal_alignment = align
	if w > 0:
		l.size.x = w
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else root_ui).add_child(l)
	return l

func _button(text: String, pos: Vector2, sz: Vector2, cb: Callable, col := Color("#ff2bd6"), fs := 20) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.add_theme_font_override("font", font)
	b.add_theme_font_size_override("font_size", fs)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.04, 0.16, 0.75)
	sb.border_color = col
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	var sbh := sb.duplicate()
	sbh.bg_color = Color(col.r, col.g, col.b, 0.45)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_stylebox_override("focus", sb)
	b.pressed.connect(cb)
	root_ui.add_child(b)
	return b

func _vw() -> float:
	return get_viewport().get_visible_rect().size.x

func _show_menu() -> void:
	state = "menu"
	scene_t = 0.0
	G = {}
	_clear_ui()
	for id in chars:
		chars[id].visible = true
	_set_spot("V", "1A")
	chars.C.position = Vector3(1.6, 0.6, -27.4)
	chars.C.rotation.y = 0.3
	if not music.playing:
		music.play()
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.position = Vector2.ZERO
	shade.size = Vector2(640, 720)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_ui.add_child(shade)
	_label("NIGHT AT", Vector2(60, 60), 40, Color("#7ff4ff"))
	_label("VOXIE'S", Vector2(60, 100), 80, Color("#ff2bd6"))
	_label("Voxie's Fun Factory · zavřeno od 14. 6. 1997", Vector2(64, 196), 16, Color(0.8, 0.8, 0.8))
	_button("NOVÁ HRA", Vector2(60, 240), Vector2(420, 54), func(): new_game(1))
	_button("POKRAČOVAT · NOC " + str(min(progress, 5)), Vector2(60, 302), Vector2(420, 54), func(): new_game(min(progress, 5)))
	for n in range(1, 6):
		var ok := n <= progress
		var b := _button(str(n) if ok else "🔒", Vector2(60 + (n - 1) * 70, 372), Vector2(60, 48), func(): new_game(n), Color("#7ff4ff"))
		b.disabled = not ok
	var cb := _button("⚙ VLASTNÍ NOC  (Voxie " + str(custom.v) + " · Cocoa " + str(custom.c) + ")", Vector2(60, 436), Vector2(420, 48), func(): _show_custom(), Color("#ffe46b"), 17)
	cb.disabled = progress < 6
	_label("Táhni prstem = rozhlížení · A/D dveře · Q/E světla · mezerník kamery", Vector2(64, 690), 13, Color(0.5, 0.5, 0.5))
	_label("Godot verze · v2.1.0", Vector2(_vw() - 260, 690), 13, Color(0.45, 0.45, 0.45))

func _show_custom() -> void:
	_clear_ui()
	_label("VLASTNÍ NOC", Vector2(0, 90), 50, Color("#ffe46b"), null, HORIZONTAL_ALIGNMENT_CENTER, _vw())
	var rows := [["v", "Voxie (levé dveře)"], ["c", "Cocoa (pravé dveře)"]]
	for i in rows.size():
		var k: String = rows[i][0]
		var y := 220 + i * 110
		_label(rows[i][1], Vector2(_vw() / 2 - 380, y + 12), 26, Color.WHITE)
		_button("−", Vector2(_vw() / 2 + 120, y), Vector2(64, 56), func(): custom[k] = max(0, custom[k] - 1); _save(); _show_custom(), Color("#ff2bd6"), 28)
		_label(str(custom[k]), Vector2(_vw() / 2 + 190, y + 6), 36, Color.WHITE, null, HORIZONTAL_ALIGNMENT_CENTER, 80)
		_button("+", Vector2(_vw() / 2 + 276, y), Vector2(64, 56), func(): custom[k] = min(20, custom[k] + 1); _save(); _show_custom(), Color("#ff2bd6"), 28)
	_button("▶ HRÁT", Vector2(_vw() / 2 - 380, 480), Vector2(420, 60), func(): new_game(6), Color("#5dff8a"), 22)
	_button("← MENU", Vector2(_vw() / 2 + 60, 480), Vector2(300, 60), func(): _show_menu(), Color("#ff2bd6"), 20)

func _show_hud() -> void:
	_clear_ui()
	var vw := _vw()
	hud_nodes.night = _label("", Vector2(24, 18), 26)
	hud_nodes.time = _label("", Vector2(vw - 224, 14), 46, Color.WHITE, null, HORIZONTAL_ALIGNMENT_RIGHT, 200)
	hud_nodes.power = _label("", Vector2(24, 640), 24)
	hud_nodes.usage = _label("", Vector2(24, 674), 20, Color("#4cff6b"))
	hud_nodes.msg = _label("", Vector2(0, 120), 22, Color("#ffd0f0"), null, HORIZONTAL_ALIGNMENT_CENTER, vw)
	hud_nodes.camname = _label("", Vector2(30, 120), 30, Color.WHITE)
	hud_nodes.intro = _label("", Vector2(0, 300), 60, Color.WHITE, null, HORIZONTAL_ALIGNMENT_CENTER, vw)
	hud_nodes.doorL = _button("DVEŘE", Vector2(24, 280), Vector2(120, 60), func(): toggle_door("L"), Color("#ff3b3b"), 18)
	hud_nodes.lightL = _button("SVĚTLO", Vector2(24, 360), Vector2(120, 60), func(): set_light("L"), Color("#fff3c4"), 18)
	hud_nodes.doorR = _button("DVEŘE", Vector2(vw - 144, 280), Vector2(120, 60), func(): toggle_door("R"), Color("#ff3b3b"), 18)
	hud_nodes.lightR = _button("SVĚTLO", Vector2(vw - 144, 360), Vector2(120, 60), func(): set_light("R"), Color("#fff3c4"), 18)
	hud_nodes.lookL = _button("◀", Vector2(160, 300), Vector2(50, 120), func(): look_target = clamp((look if look_target == null else float(look_target)) + 0.95, -1.15, 1.15), Color("#7ff4ff"), 24)
	hud_nodes.lookR = _button("▶", Vector2(vw - 210, 300), Vector2(50, 120), func(): look_target = clamp((look if look_target == null else float(look_target)) - 0.95, -1.15, 1.15), Color("#7ff4ff"), 24)
	hud_nodes.cams = _button("▲  KAMERY  ▲", Vector2(vw / 2 - 240, 656), Vector2(480, 52), func(): toggle_cams(), Color("#7ff4ff"), 22)
	var grid := []
	for i in CAM_ORDER.size():
		var id: String = CAM_ORDER[i]
		grid.append(_button("CAM " + id, Vector2(vw - 600 + (i % 5) * 112, 470 + (i / 5) * 60), Vector2(104, 50), func(): select_cam(id), Color("#5dff8a"), 16))
	hud_nodes.grid = grid

func _show_end(win: bool) -> void:
	_clear_ui()
	var vw := _vw()
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ui.add_child(bg)
	if win:
		_label("6:00", Vector2(0, 200), 110, Color("#ffe46b"), null, HORIZONTAL_ALIGNMENT_CENTER, vw)
		_label("Noc " + str(G.night) + " přežita!" if G.night <= 5 else "Vlastní noc přežita!", Vector2(0, 360), 34, Color.WHITE, null, HORIZONTAL_ALIGNMENT_CENTER, vw)
		if G.night < 5:
			var nn: int = G.night + 1
			_button("DALŠÍ NOC", Vector2(vw / 2 - 200, 440), Vector2(400, 56), func(): new_game(nn))
		else:
			_button("ZNOVU", Vector2(vw / 2 - 200, 440), Vector2(400, 56), func(): new_game(G.night))
	else:
		_label("KONEC HRY", Vector2(0, 220), 72, Color("#ff3b3b"), null, HORIZONTAL_ALIGNMENT_CENTER, vw)
		var who: String = "Došel proud… a Voxie si tě našel." if G.out else AI_DEF[killer].name + (" tě našla." if killer == "C" else " tě našel.")
		_label(who, Vector2(0, 320), 26, Color.WHITE, null, HORIZONTAL_ALIGNMENT_CENTER, vw)
		var nn: int = G.night
		_button("ZKUSIT ZNOVU", Vector2(vw / 2 - 200, 420), Vector2(400, 56), func(): new_game(nn))
	_button("MENU", Vector2(vw / 2 - 200, 500), Vector2(400, 56), func(): _show_menu())

func _update_ui(dt: float) -> void:
	var mat := static_rect.material as ShaderMaterial
	var amt := 0.04
	var scan := 0.0
	flash_rect.color.a = 0.0
	if state == "menu":
		amt = 0.08
	elif state == "scare":
		amt = 0.15 + randf() * 0.15
		if scene_t < 0.06:
			flash_rect.color = Color(1, 1, 1, 1)
	elif state == "intro" and hud_nodes.has("intro"):
		hud_nodes.intro.text = "0:00\nNoc " + str(G.night) if G.night <= 5 else "0:00\nVlastní noc"
		flash_rect.color = Color(0, 0, 0, clamp(min(scene_t, 3.0 - scene_t) * 1.5, 0.0, 1.0) * 0.0)
	if state in ["play", "intro"] and not G.is_empty() and hud_nodes.has("time"):
		if state == "play":
			hud_nodes.intro.text = ""
		var h := _hour()
		hud_nodes.time.text = str(12 if h == 0 else h) + " AM"
		hud_nodes.night.text = "Noc " + str(G.night) if G.night <= 5 else "Vlastní noc"
		hud_nodes.power.text = "Proud: " + str(max(0, ceil(G.power))) + " %"
		hud_nodes.power.add_theme_color_override("font_color", Color("#ff6b6b") if G.power < 20 else Color.WHITE)
		hud_nodes.usage.text = "Spotřeba: " + "▮".repeat(_usage()) + "▯".repeat(5 - _usage())
		hud_nodes.msg.text = G.msg if G.msg_t > 0 else ""
		var cams_on: bool = G.cams
		for k in ["doorL", "lightL", "doorR", "lightR", "lookL", "lookR"]:
			hud_nodes[k].visible = not cams_on and not G.out
		hud_nodes.doorL.text = "DVEŘE ✕" if G.door.L else "DVEŘE"
		hud_nodes.doorR.text = "DVEŘE ✕" if G.door.R else "DVEŘE"
		hud_nodes.lightL.text = "SVĚTLO ●" if G.light == "L" else "SVĚTLO"
		hud_nodes.lightR.text = "SVĚTLO ●" if G.light == "R" else "SVĚTLO"
		hud_nodes.cams.visible = not G.out
		hud_nodes.cams.text = "▼  ZAVŘÍT KAMERY  ▼" if cams_on else "▲  KAMERY  ▲"
		for b in hud_nodes.grid:
			b.visible = cams_on
		hud_nodes.camname.text = ("CAM " + G.cam + " · " + CAMS[G.cam][0]) if cams_on else ""
		if cams_on:
			amt = 0.06 + G.static * 0.5
			scan = 1.0
		if G.out:
			flash_rect.color = Color(0, 0, 0, min(0.9, G.out_t * 0.15))
	mat.set_shader_parameter("amount", amt)
	mat.set_shader_parameter("scan", scan)

# ====================================================================
#  ULOŽENÍ
# ====================================================================
func _save() -> void:
	var cf := ConfigFile.new()
	cf.set_value("hra", "noc", progress)
	cf.set_value("hra", "vlastni_v", custom.v)
	cf.set_value("hra", "vlastni_c", custom.c)
	cf.save("user://voxies.cfg")

func _load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load("user://voxies.cfg") == OK:
		progress = cf.get_value("hra", "noc", 1)
		custom.v = cf.get_value("hra", "vlastni_v", 10)
		custom.c = cf.get_value("hra", "vlastni_c", 6)

# ====================================================================
#  TEST: projde hru a uloží screenshoty (godot -- --shots)
# ====================================================================
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://shot_" + n + ".png")

func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _run_shots() -> void:
	await _wait(2.0)
	await _shot("menu")
	new_game(1)
	await _wait(3.4)
	await _shot("office")
	look_target = 1.0
	await _wait(1.0)
	G.ai.V.pos = "DOOR"
	_set_spot("V", "DOOR")
	set_light("L")
	await _wait(0.6)
	await _shot("light_left")
	set_light("L")
	toggle_door("L")
	look_target = -1.0
	await _wait(1.0)
	G.ai.C.pos = "cDOOR"
	_set_spot("C", "cDOOR")
	set_light("R")
	await _wait(0.6)
	await _shot("light_right")
	set_light("R")
	look_target = 0.0
	toggle_cams()
	select_cam("1A")
	await _wait(0.8)
	await _shot("cam_1A")
	select_cam("2")
	await _wait(0.8)
	await _shot("cam_2")
	toggle_cams()
	_jumpscare("V")
	await _wait(0.25)
	await _shot("scare")
	await _wait(2.0)
	await _shot("dead")
	get_tree().quit()
