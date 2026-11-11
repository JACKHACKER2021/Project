extends Node3D
## Starý československý výtah Transporta TO 250 – celý svět se staví z kódu.

const N := 4          # počet podlaží (0..3)
const H := 3.0        # výška podlaží
const SPEED := 0.8    # m/s

var cabin: AnimatableBody3D
var target := 0
var moving := false
var doors: Array = []        # pivot Node3D pro každé patro
var door_open: Array = []
var indicators: Array = []
var gate_open := false
var gate_mesh: MeshInstance3D
var gate_shape: CollisionShape3D
var player
var hint: Label
var msg: Label
var msg_time := 0.0
var sfx := {}
var oneshot: AudioStreamPlayer
var motor: AudioStreamPlayer3D

var m_wall: StandardMaterial3D
var m_wall_low: StandardMaterial3D
var m_floor: StandardMaterial3D
var m_mesh: StandardMaterial3D
var m_frame: StandardMaterial3D
var m_btn: StandardMaterial3D
var m_wood: StandardMaterial3D

# ---------------------------------------------------------------- build
func _ready() -> void:
	_materials()
	_env()
	_sounds()
	# zem přízemí
	sb(Vector3(14, 0.2, 14), Vector3(0, -0.1, 3), m_floor)
	for f in N:
		_floor(f)
	# strop nejvyššího patra
	sb(Vector3(14, 0.2, 9), Vector3(0, N * H + 0.1, 4.25), m_wall)
	# šachta – boky a záda z pletiva
	var sh := N * H + 0.5
	sb(Vector3(0.05, sh, 1.6), Vector3(-0.8, sh / 2, 0), m_mesh)
	sb(Vector3(0.05, sh, 1.6), Vector3(0.8, sh / 2, 0), m_mesh)
	sb(Vector3(1.6, sh, 0.05), Vector3(0, sh / 2, -0.8), m_mesh)
	# rámové sloupky šachty
	for x in [-0.8, 0.8]:
		for z in [-0.8, 0.78]:
			sb(Vector3(0.07, sh, 0.07), Vector3(x, sh / 2, z), m_frame)
	_cabin()
	_ui()
	player = CharacterBody3D.new()
	player.set_script(load("res://player.gd"))
	add_child(player)
	player.position = Vector3(0, 0.05, 4.5)
	player.interacted.connect(_on_act)
	say("Přízemí paneláku. Šedá šachta s pletivem a cedulka POZOR VÝTAH! Zmáčkni tlačítko vedle dveří.", 6)

func _materials() -> void:
	m_wall = mat(Color(0.85, 0.78, 0.6))
	m_wall_low = mat(Color(0.72, 0.38, 0.22))
	m_floor = mat(Color(0.45, 0.42, 0.38))
	m_frame = mat(Color(0.78, 0.76, 0.66))
	m_btn = mat(Color(0.75, 0.75, 0.72))
	m_btn.metallic = 0.6
	m_wood = mat(Color(0.45, 0.3, 0.18))
	# pletivo – procedurální textura mřížky
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in 32:
		for t in 3:
			img.set_pixel(i, t, Color(0.35, 0.34, 0.3))
			img.set_pixel(t, i, Color(0.35, 0.34, 0.3))
	m_mesh = StandardMaterial3D.new()
	m_mesh.albedo_texture = ImageTexture.create_from_image(img)
	m_mesh.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m_mesh.cull_mode = BaseMaterial3D.CULL_DISABLED
	m_mesh.uv1_triplanar = true
	m_mesh.uv1_scale = Vector3(12, 12, 12)
	m_mesh.metallic = 0.5

func _env() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.05, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.33, 0.3)
	e.ambient_light_energy = 0.6
	we.environment = e
	add_child(we)

func _floor(f: int) -> void:
	var y := f * H
	if f > 0:
		sb(Vector3(14, 0.2, 8.2), Vector3(0, y - 0.1, 4.85), m_floor)
	# stěna chodby kolem šachty (dvoubarevná – olejový sokl)
	for s in [-1, 1]:
		sb(Vector3(6.2, 1.5, 0.1), Vector3(s * 3.9, y + 0.75, 0.85), m_wall_low)
		sb(Vector3(6.2, 1.5, 0.1), Vector3(s * 3.9, y + 2.25, 0.85), m_wall)
		# boční stěny chodby
		sb(Vector3(0.1, H, 8.2), Vector3(s * 7, y + H / 2, 4.85), m_wall)
	sb(Vector3(14, H, 0.1), Vector3(0, y + H / 2, 8.95), m_wall)
	# čelo šachty: sloupky vedle dveří a nadpraží z pletiva
	for s in [-1, 1]:
		sb(Vector3(0.38, H, 0.04), Vector3(s * 0.6, y + H / 2, 0.78), m_mesh)
	sb(Vector3(0.82, H - 2.1, 0.04), Vector3(0, y + 2.1 + (H - 2.1) / 2, 0.78), m_mesh)
	sb(Vector3(0.9, 0.06, 0.08), Vector3(0, y + 2.13, 0.8), m_frame)
	# šachetní dveře – otočné na pantu vlevo
	var pivot := Node3D.new()
	pivot.position = Vector3(-0.41, y, 0.8)
	add_child(pivot)
	var d := StaticBody3D.new()
	pivot.add_child(d)
	part(d, Vector3(0.8, 2.08, 0.03), Vector3(0.41, 1.04, 0), m_mesh, true)
	part(d, Vector3(0.82, 0.06, 0.05), Vector3(0.41, 0.03, 0), m_frame, false)
	part(d, Vector3(0.82, 0.06, 0.05), Vector3(0.41, 2.05, 0), m_frame, false)
	part(d, Vector3(0.82, 0.05, 0.05), Vector3(0.41, 1.0, 0), m_frame, false)
	part(d, Vector3(0.05, 2.1, 0.05), Vector3(0.025, 1.04, 0), m_frame, false)
	part(d, Vector3(0.05, 2.1, 0.05), Vector3(0.795, 1.04, 0), m_frame, false)
	# cedulka a klika
	part(d, Vector3(0.3, 0.1, 0.01), Vector3(0.41, 1.12, 0.03), mat(Color(0.95, 0.95, 0.9)), false)
	var cl := lbl("POZOR VÝTAH!\nNosnost 250 kg", Vector3(0.41, 1.12, 0.04), 0.0012, Color.BLACK)
	d.add_child(cl)
	part(d, Vector3(0.12, 0.03, 0.05), Vector3(0.7, 1.0, 0.05), mat(Color(0.1, 0.1, 0.1)), false)
	d.set_meta("act", ["door", f])
	d.set_meta("hint", "Šachetní dveře")
	doors.append(pivot)
	door_open.append(false)
	# kulatý ukazatel patra + přivolávač
	var ind := lbl("0", Vector3(0.62, y + 1.55, 0.83), 0.006, Color(1, 0.1, 0.1))
	add_child(ind)
	indicators.append(ind)
	button(self, Vector3(0.62, y + 1.25, 0.83), "VOLAT", ["call", f], 0.0, "Přivolat výtah")
	# číslo patra na zdi
	add_child(lbl(str(f), Vector3(0.1, y + 2.5, 0.83), 0.01, Color(0.2, 0.2, 0.2)))
	# žárovka na chodbě
	var l := OmniLight3D.new()
	l.position = Vector3(0, y + 2.7, 3.5)
	l.light_color = Color(1, 0.85, 0.6)
	l.omni_range = 7
	l.light_energy = 0.9
	l.shadow_enabled = true
	add_child(l)

func _cabin() -> void:
	cabin = AnimatableBody3D.new()
	cabin.sync_to_physics = true
	add_child(cabin)
	part(cabin, Vector3(1.44, 0.1, 1.44), Vector3(0, 0.05, 0), m_wood, true)
	part(cabin, Vector3(0.04, 2.3, 1.44), Vector3(-0.7, 1.25, 0), m_frame, true)
	part(cabin, Vector3(0.04, 2.3, 1.44), Vector3(0.7, 1.25, 0), m_frame, true)
	part(cabin, Vector3(1.44, 2.3, 0.04), Vector3(0, 1.25, -0.7), m_wood, true)
	part(cabin, Vector3(1.44, 0.05, 1.44), Vector3(0, 2.42, 0), m_frame, true)
	# lana
	part(cabin, Vector3(0.03, 20, 0.03), Vector3(-0.08, 12.45, 0), mat(Color(0.2, 0.2, 0.2)), false)
	part(cabin, Vector3(0.03, 20, 0.03), Vector3(0.08, 12.45, 0), mat(Color(0.2, 0.2, 0.2)), false)
	# shrnovací mříž
	var g := part(cabin, Vector3(1.36, 2.2, 0.03), Vector3(0, 1.2, 0.66), m_mesh, true)
	gate_mesh = g[0]
	gate_shape = g[1]
	var ga := Area3D.new()
	ga.position = Vector3(0, 1.2, 0.66)
	cabin.add_child(ga)
	var gs := CollisionShape3D.new()
	var gb := BoxShape3D.new()
	gb.size = Vector3(1.36, 2.2, 0.12)
	gs.shape = gb
	ga.add_child(gs)
	ga.set_meta("act", ["gate"])
	ga.set_meta("hint", "Shrnovací mříž kabiny")
	# ovládací panel na pravé stěně
	part(cabin, Vector3(0.02, 0.9, 0.22), Vector3(0.67, 1.3, 0.3), mat(Color(0.55, 0.53, 0.48)), false)
	for f in N:
		button(cabin, Vector3(0.655, 1.05 + f * 0.15, 0.3), str(f), ["go", f], -PI / 2, "Jet do patra " + str(f))
	button(cabin, Vector3(0.655, 1.7, 0.3), "STOP", ["stop"], -PI / 2, "STOP", Color(0.8, 0.1, 0.1))
	var bulb := OmniLight3D.new()
	bulb.position = Vector3(0, 2.25, 0)
	bulb.light_color = Color(1, 0.8, 0.5)
	bulb.omni_range = 2.5
	bulb.light_energy = 0.7
	cabin.add_child(bulb)
	part(cabin, Vector3(0.08, 0.08, 0.08), Vector3(0, 2.36, 0), mat(Color(1, 0.9, 0.6), true), false)
	motor = AudioStreamPlayer3D.new()
	motor.stream = sfx["motor"]
	motor.unit_size = 6
	motor.position.y = 2.6
	cabin.add_child(motor)

func _ui() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	var cross := Label.new()
	cross.text = "+"
	cross.set_anchors_preset(Control.PRESET_CENTER)
	cross.position -= Vector2(5, 12)
	cl.add_child(cross)
	hint = Label.new()
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint.position += Vector2(-150, 30)
	hint.size = Vector2(300, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.add_child(hint)
	msg = Label.new()
	msg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	msg.offset_top = -90
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_outline_color", Color.BLACK)
	msg.add_theme_constant_override("outline_size", 6)
	cl.add_child(msg)
	var help := Label.new()
	help.text = "WASD chůze · myš rozhled · LMB/E použít · Esc myš"
	help.position = Vector2(10, 10)
	help.modulate = Color(1, 1, 1, 0.6)
	cl.add_child(help)

# ---------------------------------------------------------------- helpers
func mat(c: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if glow:
		m.emission_enabled = true
		m.emission = c
	return m

func part(n: Node, size: Vector3, pos: Vector3, m: Material, col: bool) -> Array:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	n.add_child(mi)
	var cs: CollisionShape3D = null
	if col:
		cs = CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		cs.position = pos
		n.add_child(cs)
	return [mi, cs]

func sb(size: Vector3, pos: Vector3, m: Material) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.position = pos
	add_child(b)
	part(b, size, Vector3.ZERO, m, true)
	return b

func lbl(t: String, pos: Vector3, px: float, c: Color) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.position = pos
	l.pixel_size = px
	l.modulate = c
	l.outline_size = 0
	l.font_size = 32
	return l

func button(parent: Node, pos: Vector3, t: String, act: Array, rot: float, h: String, c := Color(0.15, 0.15, 0.15)) -> void:
	var a := Area3D.new()
	a.position = pos
	a.rotation.y = rot
	parent.add_child(a)
	part(a, Vector3(0.09, 0.09, 0.03), Vector3.ZERO, m_btn, true)
	var l := lbl(t, Vector3(0, 0, 0.017), 0.0018 if t.length() < 3 else 0.0011, c)
	a.add_child(l)
	a.set_meta("act", act)
	a.set_meta("hint", h)

func say(t: String, secs := 4.0) -> void:
	msg.text = t
	msg_time = secs

# ---------------------------------------------------------------- sounds
const SR := 22050

func _sounds() -> void:
	sfx["relay"] = _gen_relay()
	sfx["door"] = _gen_noise(0.7, 0.04, 2.5, 1.0)
	sfx["gate"] = _gen_rattle()
	sfx["brake"] = _gen_noise(0.45, 0.02, 2.0, 0.9)
	sfx["buzz"] = _gen_buzz()
	sfx["motor"] = _gen_motor()
	# vlastní nahrávky v res://sounds mají přednost
	for k in sfx.keys():
		for ext in ["ogg", "wav", "mp3"]:
			var p := "res://sounds/%s.%s" % [k, ext]
			if ResourceLoader.exists(p):
				var s = load(p)
				if k == "motor" and "loop" in s:
					s.loop = true
				sfx[k] = s
				break
	oneshot = AudioStreamPlayer.new()
	oneshot.max_polyphony = 8
	add_child(oneshot)

func play(k: String) -> void:
	oneshot.stream = sfx[k]
	oneshot.play()

func _to_wav(s: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	var b := PackedByteArray()
	b.resize(s.size() * 2)
	for i in s.size():
		b.encode_s16(i * 2, int(clamp(s[i], -1.0, 1.0) * 32000))
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = s.size()
	return w

# šum s jednopólovým filtrem (a = 0..1, menší = hlubší)
func _gen_noise(dur: float, a: float, decay: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * SR)
	var s := PackedFloat32Array()
	s.resize(n)
	var y := 0.0
	for i in n:
		y += a * (randf_range(-1, 1) - y)
		s[i] = y * pow(1.0 - float(i) / n, decay) * vol / sqrt(a) * 0.6
	return _to_wav(s)

func _gen_relay() -> AudioStreamWAV:
	var n := int(0.18 * SR)
	var s := PackedFloat32Array()
	s.resize(n)
	for c in [0, int(0.07 * SR)]:
		for i in int(0.03 * SR):
			s[c + i] += randf_range(-1, 1) * pow(1.0 - i / (0.03 * SR), 4) * 0.8
	return _to_wav(s)

func _gen_rattle() -> AudioStreamWAV:
	var n := int(0.9 * SR)
	var s := PackedFloat32Array()
	s.resize(n)
	for k in 12:
		var c := int((k * 0.065 + randf() * 0.02) * SR)
		for i in int(0.025 * SR):
			if c + i < n:
				s[c + i] += randf_range(-1, 1) * pow(1.0 - i / (0.025 * SR), 3) * 0.5
	return _to_wav(s)

func _gen_buzz() -> AudioStreamWAV:
	var n := int(0.5 * SR)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		s[i] = (0.25 if fmod(i * 100.0 / SR, 1.0) < 0.5 else -0.25)
	return _to_wav(s)

func _gen_motor() -> AudioStreamWAV:
	var n := SR * 2  # 2 s, celé periody => plynulá smyčka
	var s := PackedFloat32Array()
	s.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / SR
		var saw := fmod(t * 50.0, 1.0) * 2 - 1 + 0.6 * (fmod(t * 100.0, 1.0) * 2 - 1)
		y += 0.15 * (saw - y)
		var tick := 0.0
		var ph := fmod(t, 0.5)
		if ph < 0.01:
			tick = randf_range(-1, 1) * (1.0 - ph / 0.01) * 0.3
		s[i] = y * 0.45 + randf_range(-0.03, 0.03) + tick
	return _to_wav(s, true)

# ---------------------------------------------------------------- logic
func at_floor(f: int) -> bool:
	return not moving and abs(cabin.position.y - f * H) < 0.02

func _on_act(act: Array) -> void:
	match act[0]:
		"call":
			play("relay")
			if moving:
				say("Výtah už jede.")
			elif at_floor(act[1]):
				say("Výtah tu stojí. Otevři dveře.")
			else:
				start(act[1])
		"go":
			play("relay")
			if not moving and not at_floor(act[1]):
				start(act[1])
		"stop":
			play("relay")
			if moving:
				moving = false
				motor.stop()
				play("brake")
				say("STOP! Kabina visí mezi patry. Ticho, jen bzučí žárovka…", 5)
		"door":
			var f: int = act[1]
			if not at_floor(f):
				play("buzz")
				say("Dveře nejdou otevřít – kabina tu není, zámek drží.")
				return
			door_open[f] = not door_open[f]
			var tw := create_tween()
			tw.tween_property(doors[f], "rotation:y", -1.75 if door_open[f] else 0.0, 0.6).set_trans(Tween.TRANS_SINE)
			if door_open[f]:
				play("door")
				say("Zatáhneš za studenou kliku, těžké dveře zaskřípou.")
			else:
				tw.tween_callback(play.bind("door"))
				say("BOUCH! Dveře zaklapnou, ozvěna letí celou chodbou.")
		"gate":
			if moving:
				return
			gate_open = not gate_open
			play("gate")
			gate_shape.disabled = gate_open
			var tw := create_tween().set_parallel()
			tw.tween_property(gate_mesh, "scale:x", 0.08 if gate_open else 1.0, 0.5)
			tw.tween_property(gate_mesh, "position:x", 0.62 if gate_open else 0.0, 0.5)
			say("Mříž se s rachotem shrne do strany." if gate_open else "Řinč-řinč… zatáhneš mříž, kontakt cvakne.")

func start(f: int) -> void:
	if true in door_open:
		play("buzz")
		say("Nic. Šachetní dveře jsou otevřené – bezpečnostní kontakt nesepnul.")
		return
	if gate_open:
		play("buzz")
		say("Nic. Mříž v kabině není zatažená.")
		return
	target = f
	moving = true
	get_tree().create_timer(0.15).timeout.connect(func(): play("relay"))
	get_tree().create_timer(0.3).timeout.connect(_motor_on)

func _motor_on() -> void:
	if moving:
		motor.play()

func _physics_process(delta: float) -> void:
	if moving:
		var ty := target * H
		cabin.position.y = move_toward(cabin.position.y, ty, SPEED * delta)
		if is_equal_approx(cabin.position.y, ty):
			moving = false
			motor.stop()
			play("brake")
			say("Prudké zabrzdění – %d. patro. Kabina se ještě zhoupne na lanech." % target)
	var fl := str(clampi(roundi(cabin.position.y / H), 0, N - 1))
	for i in indicators:
		i.text = fl
	var inside := absf(player.position.x) < 0.7 and absf(player.position.z) < 0.7
	player.shake = moving and inside

func _process(delta: float) -> void:
	var c: Object = player.looked_at()
	hint.text = ("[E] " + c.get_meta("hint")) if c else ""
	if msg_time > 0:
		msg_time -= delta
		if msg_time <= 0:
			msg.text = ""
