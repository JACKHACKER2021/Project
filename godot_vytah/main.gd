extends Node3D
## Starý československý výtah Transporta TOV 250 v paneláku – celý svět se staví z kódu.

const N := 12         # počet pater s výtahem (0..11), nad nimi strojovna
const H := 3.0        # výška podlaží
var SPEED := 1.0      # m/s (moderní motor jezdí rychleji)

var cabin: AnimatableBody3D
var target := 0
var moving := false
var stuck := false
var break_at := -1.0
var doors: Array = []
var door_open: Array = []
var indicators: Array = []
var busy_lamps: Array = []
var cab_btns: Array = []
var cab_lamp: MeshInstance3D
var gate_open := false
var gate_mesh: MeshInstance3D
var gate_shape: CollisionShape3D
var gate_area: Area3D
var gate_area_box: BoxShape3D
var bulb: OmniLight3D
var counterweight: Node3D
var rope_cab: MeshInstance3D
var rope_cw: MeshInstance3D
var wheel: Node3D
var player
var hint: Label
var msg: Label
var status: Label
var msg_time := 0.0
var sfx := {}
var oneshot: AudioStreamPlayer
var motor: AudioStreamPlayer3D

# stav výtahu
var health := 100.0
var fire: Node3D = null
var fire_floor := -1
var has_ext := false
var repairing := false
var has_axe := false
var door_glass: Array = []     # sklo dveří v každém patře (dá se rozbít)
var style := 0
const STYLES := [
	["Původní hnědá", Color(0.55, 0.33, 0.14), Color(0.4, 0.24, 0.13)],
	["Krémová Transporta", Color(0.86, 0.8, 0.56), Color(0.35, 0.34, 0.3)],
	["Šedá modernizace", Color(0.6, 0.62, 0.64), Color(0.3, 0.3, 0.32)],
	["Zelená jako sokl", Color(0.3, 0.45, 0.35), Color(0.2, 0.3, 0.22)],
	["Červená retro", Color(0.6, 0.15, 0.1), Color(0.35, 0.1, 0.08)],
]
var reset_rect := Rect2()

# --- díly výtahu: 0 = původní (1974), 1 = demontováno, 2 = moderní (21. století)
const OLD := 0
const GONE := 1
const NEW := 2
var parts := {}             # klíč -> stav
var parts_prev := {}        # co bylo před demontáží
var has_wrench := false
var motor_nodes: Array = []
var light_panel: MeshInstance3D
var control_box: Area3D
var curtain: Node3D
const PART_NAMES := {
	"gate": ["shrnovací mříž", "světelná závora"],
	"panel": ["panel s černými tlačítky", "dotykový panel s LED"],
	"light": ["žárovka", "LED svítidlo"],
	"motor": ["motor s převodovkou", "bezpřevodový motor s měničem"],
	"control": ["reléový rozvaděč", "mikroprocesorové řízení"],
	"ind": ["červené ukazatele", "LCD displeje"],
}

var m_wall: StandardMaterial3D
var m_wall_low: StandardMaterial3D
var m_floor: StandardMaterial3D
var m_mesh: StandardMaterial3D
var m_frame: StandardMaterial3D
var m_btn: StandardMaterial3D
var m_btn_black: StandardMaterial3D
var m_btn_lit: StandardMaterial3D
var m_lamp_off: StandardMaterial3D
var m_lamp_on: StandardMaterial3D
var m_wood: StandardMaterial3D
var m_glass: StandardMaterial3D
var m_grey: StandardMaterial3D
var m_stairs: StandardMaterial3D

# ---------------------------------------------------------------- build
func _ready() -> void:
	randomize()
	_materials()
	_env()
	_sounds()
	sb(Vector3(14, 0.2, 14), Vector3(0, -0.1, 3), m_floor)
	for f in N + 1:
		_floor(f)
	_stairs()
	_shaft()
	_machine_room()
	_axe()
	_wrench()
	_store()
	for k in PART_NAMES:
		parts[k] = OLD
	for f in N:
		parts["door:%d" % f] = OLD
	_cabin()
	_ui()
	player = CharacterBody3D.new()
	player.set_script(load("res://player.gd"))
	add_child(player)
	player.position = Vector3(0, 0.05, 4.5)
	player.interacted.connect(_on_act)
	player.ray.collision_mask = 1 | 4
	if OS.has_feature("mobile"):
		_touch_ui()
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.timeout.connect(_tick)
	add_child(t)
	say("Přízemí dvanáctipatrového paneláku. Hnědé dveře s drátěným sklem, POZOR VÝTAH. Zmáčkni VOLAT.", 6)

func _materials() -> void:
	m_wall = mat(Color(0.86, 0.82, 0.68))
	m_wall_low = mat(Color(0.35, 0.5, 0.42))        # olejový sokl
	m_floor = mat(Color(0.5, 0.45, 0.4))
	m_frame = mat(Color(0.55, 0.33, 0.14))          # hnědý lak
	m_frame.roughness = 0.5
	m_btn = mat(Color(0.75, 0.75, 0.72))
	m_btn.metallic = 0.6
	m_btn_black = mat(Color(0.08, 0.08, 0.08))
	m_btn_black.roughness = 0.3
	m_btn_lit = mat(Color(1, 0.55, 0.15), true)
	m_lamp_off = mat(Color(0.3, 0.05, 0.05))
	m_lamp_on = mat(Color(1, 0.1, 0.05), true)
	m_lamp_on.emission_energy_multiplier = 3
	m_wood = mat(Color(0.66, 0.48, 0.3))
	m_grey = mat(Color(0.5, 0.52, 0.5))
	m_grey.metallic = 0.4
	m_stairs = mat(Color(0.6, 0.55, 0.5))
	# pletivo šachty – rezavě hnědé
	m_mesh = _grid_mat(Color(0, 0, 0, 0), Color(0.4, 0.24, 0.13), 3, 12, BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
	m_mesh.metallic = 0.4
	# staré drátěné sklo – mléčné s jemnou drátěnou mřížkou
	m_glass = _grid_mat(Color(0.82, 0.86, 0.84, 0.55), Color(0.35, 0.35, 0.33, 0.8), 1, 40, BaseMaterial3D.TRANSPARENCY_ALPHA)
	m_glass.roughness = 0.15
	m_glass.metallic_specular = 0.8

func _grid_mat(bg: Color, line: Color, w: int, sc: float, tr) -> StandardMaterial3D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(bg)
	for i in 32:
		for t in w:
			img.set_pixel(i, t, line)
			img.set_pixel(t, i, line)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = tr
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(sc, sc, sc)
	return m

func _env() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.05, 0.05, 0.05)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.38, 0.34)
	e.ambient_light_energy = 0.7
	we.environment = e
	add_child(we)

# schodiště: rameno k vede z patra k do k+1; sudá ramena v pruhu A (stoupá k -z), lichá v pruhu B (k +z)
const ST_A := [-6.6, -5.4]
const ST_B := [-5.4, -4.2]
const ST_Z := [3.3, 7.5]

func _strip(k: int) -> Array:
	return ST_A if k % 2 == 0 else ST_B

func _floor(f: int) -> void:
	var y := f * H
	var top := f == N
	# podlaha s otvorem pro schodiště
	if f > 0:
		var hx: Array = _strip(f - 1)
		var zc := (0.8 + 8.95) / 2
		sb(Vector3(hx[0] + 7, 0.2, 8.15), Vector3((-7 + hx[0]) / 2, y - 0.1, zc), m_floor)
		sb(Vector3(7 - hx[1], 0.2, 8.15), Vector3((hx[1] + 7) / 2, y - 0.1, zc), m_floor)
		var w: float = hx[1] - hx[0]
		var cx: float = (hx[0] + hx[1]) / 2
		sb(Vector3(w, 0.2, ST_Z[0] - 0.8), Vector3(cx, y - 0.1, (0.8 + ST_Z[0]) / 2), m_floor)
		sb(Vector3(w, 0.2, 8.95 - ST_Z[1]), Vector3(cx, y - 0.1, (ST_Z[1] + 8.95) / 2), m_floor)
		# zábradlí kolem otvoru
		var rail := m_frame
		sb(Vector3(0.05, 1.0, ST_Z[1] - ST_Z[0]), Vector3(hx[0], y + 0.5, 5.4), rail)
		sb(Vector3(0.05, 1.0, ST_Z[1] - ST_Z[0]), Vector3(hx[1], y + 0.5, 5.4), rail)
		var ez: float = ST_Z[1] if (f - 1) % 2 == 0 else ST_Z[0]
		sb(Vector3(w, 1.0, 0.05), Vector3(cx, y + 0.5, ez), rail)
	# stěny chodby
	for s in [-1, 1]:
		sb(Vector3(0.1, H, 8.2), Vector3(s * 7, y + H / 2, 4.85), m_wall)
		if not top:
			sb(Vector3(6.2, 1.5, 0.1), Vector3(s * 3.9, y + 0.75, 0.85), m_wall_low)
			sb(Vector3(6.2, 1.5, 0.1), Vector3(s * 3.9, y + 2.25, 0.85), m_wall)
	sb(Vector3(14, H, 0.1), Vector3(0, y + H / 2, 8.95), m_wall)
	add_child(lbl(str(f) + ". NP" if not top else "STROJOVNA", Vector3(-2.5, y + 2.3, 0.91), 0.008, Color(0.2, 0.2, 0.2)))
	var l := OmniLight3D.new()
	l.position = Vector3(0, y + 2.7, 3.5)
	l.light_color = Color(1, 0.85, 0.6)
	l.omni_range = 8
	l.light_energy = 1.0
	add_child(l)
	if top:
		return
	# čelo šachty: vlevo pletivo, vpravo hnědý plech s ovládáním, nahoře pletivo
	sb(Vector3(0.38, H, 0.04), Vector3(-0.6, y + H / 2, 0.78), m_mesh)
	sb(Vector3(0.38, H, 0.04), Vector3(0.6, y + H / 2, 0.78), m_frame)
	sb(Vector3(0.82, H - 2.1, 0.04), Vector3(0, y + 2.1 + (H - 2.1) / 2, 0.78), m_mesh)
	sb(Vector3(0.9, 0.08, 0.08), Vector3(0, y + 2.13, 0.8), m_frame)
	# štítek s tlačítkem a lampičkou „obsazeno“
	sb(Vector3(0.07, 0.24, 0.01), Vector3(0.54, y + 1.3, 0.805), m_btn)
	var lamp: MeshInstance3D = part(self, Vector3(0.03, 0.03, 0.02), Vector3(0.54, y + 1.38, 0.815), m_lamp_off, false)[0]
	busy_lamps.append(lamp)
	button(self, Vector3(0.54, y + 1.27, 0.815), "", ["call", f], 0.0, "Přivolat výtah", m_btn_black, 0.04)
	var ind := lbl("0", Vector3(0.66, y + 1.6, 0.815), 0.004, Color(1, 0.1, 0.1))
	add_child(ind)
	indicators.append(ind)
	sb(Vector3(0.16, 0.22, 0.01), Vector3(0.62, y + 1.9, 0.805), mat(Color(0.95, 0.95, 0.92)))
	add_child(lbl("NÁVOD\nk obsluze\nvýtahu", Vector3(0.62, y + 1.9, 0.812), 0.0009, Color.BLACK))
	# šachetní dveře – hnědé, se starým drátěným sklem
	var pivot := Node3D.new()
	pivot.position = Vector3(-0.41, y, 0.8)
	add_child(pivot)
	var d := StaticBody3D.new()
	pivot.add_child(d)
	shape(d, Vector3(0.82, 2.08, 0.05), Vector3(0.41, 1.04, 0))
	var g1: MeshInstance3D = part(d, Vector3(0.66, 0.95, 0.01), Vector3(0.41, 1.55, 0), m_glass, false)[0]
	var g2: MeshInstance3D = part(d, Vector3(0.66, 0.8, 0.01), Vector3(0.41, 0.53, 0), m_glass, false)[0]
	door_glass.append([g1, g2])
	part(d, Vector3(0.82, 0.08, 0.05), Vector3(0.41, 0.04, 0), m_frame, false)
	part(d, Vector3(0.82, 0.1, 0.05), Vector3(0.41, 2.03, 0), m_frame, false)
	part(d, Vector3(0.82, 0.12, 0.05), Vector3(0.41, 1.0, 0), m_frame, false)
	part(d, Vector3(0.08, 2.08, 0.05), Vector3(0.04, 1.04, 0), m_frame, false)
	part(d, Vector3(0.08, 2.08, 0.05), Vector3(0.78, 1.04, 0), m_frame, false)
	for side in [1, -1]:
		part(d, Vector3(0.24, 0.05, 0.01), Vector3(0.41, 1.0, side * 0.03), mat(Color(0.95, 0.95, 0.9)), false)
		var pl := lbl("VÝTAH nosnost 250 kg", Vector3(0.41, 1.0, side * 0.036), 0.0006, Color.BLACK)
		if side < 0:
			pl.rotation.y = PI
		d.add_child(pl)
		part(d, Vector3(0.05, 0.05, 0.05), Vector3(0.72, 1.0, side * 0.05), m_btn, false)   # klika
	part(d, Vector3(0.28, 0.08, 0.08), Vector3(0.6, 1.95, 0.07), m_btn, false)               # zavírač
	d.add_child(lbl(str(f), Vector3(0.6, 1.25, 0.04), 0.003, Color(0.15, 0.1, 0.05)))
	var mount := Area3D.new()
	pivot.add_child(mount)
	shape(mount, Vector3(0.82, 2.08, 0.08), Vector3(0.41, 1.04, 0))
	mount.set_meta("act", ["door", f])
	mount.set_meta("hint", "Šachetní dveře")
	d.set_meta("act", ["door", f])
	d.set_meta("hint", "Šachetní dveře")
	doors.append(pivot)
	door_open.append(false)
	# hasicí přístroj na zdi
	var ex := Area3D.new()
	ex.position = Vector3(-1.4, y + 0.55, 0.98)
	add_child(ex)
	var cm := CylinderMesh.new()
	cm.top_radius = 0.09
	cm.bottom_radius = 0.09
	cm.height = 0.55
	var mi := MeshInstance3D.new()
	mi.mesh = cm
	mi.material_override = mat(Color(0.8, 0.05, 0.05))
	ex.add_child(mi)
	shape(ex, Vector3(0.2, 0.55, 0.2), Vector3.ZERO)
	ex.set_meta("act", ["ext"])
	ex.set_meta("hint", "Hasicí přístroj")

func _wrench() -> void:
	var a := Area3D.new()
	a.position = Vector3(3.3, 1.2, 0.95)
	add_child(a)
	part(a, Vector3(0.5, 0.7, 0.04), Vector3(0, 0, -0.02), mat(Color(0.2, 0.3, 0.55)), false)
	part(a, Vector3(0.05, 0.35, 0.02), Vector3(0, 0.05, 0.01), m_grey, false)
	part(a, Vector3(0.14, 0.06, 0.02), Vector3(0, 0.24, 0.01), m_grey, false)
	shape(a, Vector3(0.5, 0.7, 0.1), Vector3.ZERO)
	a.add_child(lbl("NÁŘADÍ\nrekonstrukce", Vector3(0, -0.25, 0.01), 0.0016, Color.WHITE))
	a.set_meta("act", ["wrench"])
	a.set_meta("hint", "Montážní klíč – rozebírání dílů")

func _axe() -> void:
	var a := Area3D.new()
	a.position = Vector3(2.5, 1.2, 0.95)
	add_child(a)
	part(a, Vector3(0.05, 0.7, 0.04), Vector3.ZERO, mat(Color(0.45, 0.28, 0.12)), false)
	part(a, Vector3(0.2, 0.12, 0.02), Vector3(0.08, 0.3, 0), m_grey, false)
	part(a, Vector3(0.4, 0.9, 0.02), Vector3(0, 0, -0.03), mat(Color(0.8, 0.1, 0.1)), false)
	shape(a, Vector3(0.4, 0.9, 0.1), Vector3.ZERO)
	a.add_child(lbl("SEKERA", Vector3(0, -0.38, 0.02), 0.002, Color.WHITE))
	a.set_meta("act", ["axe"])
	a.set_meta("hint", "Požární sekera")

func _stairs() -> void:
	var L := sqrt(4.2 * 4.2 + H * H)
	var ang := atan2(H, 4.2)
	for k in N:
		var y := k * H
		var s: Array = _strip(k)
		var w: float = s[1] - s[0] - 0.04
		var cx: float = (s[0] + s[1]) / 2
		var up_neg := k % 2 == 0
		# neviditelná rampa pro chůzi
		var r := StaticBody3D.new()
		r.position = Vector3(cx, y + H / 2 - 0.06, 5.4)
		r.rotation.x = ang if up_neg else -ang
		add_child(r)
		shape(r, Vector3(w, 0.1, L), Vector3.ZERO)
		# viditelné stupně
		for i in 15:
			var z: float = ST_Z[1] - (i + 0.5) * 0.28 if up_neg else ST_Z[0] + (i + 0.5) * 0.28
			part(self, Vector3(w, 0.2, 0.28), Vector3(cx, y + i * 0.2 + 0.1, z), m_stairs, false)

func _shaft() -> void:
	var sh := N * H
	sb(Vector3(0.05, sh, 1.95), Vector3(-0.8, sh / 2, -0.2), m_mesh)
	sb(Vector3(0.05, sh, 1.95), Vector3(0.8, sh / 2, -0.2), m_mesh)
	sb(Vector3(1.6, sh, 0.05), Vector3(0, sh / 2, -1.17), m_mesh)
	for x in [-0.8, 0.8]:
		for z in [-1.17, 0.78]:
			sb(Vector3(0.07, sh, 0.07), Vector3(x, sh / 2, z), m_frame)
	for f in N:
		sb(Vector3(1.6, 0.06, 0.06), Vector3(0, f * H + 2.5, -1.17), m_frame)
	# vodítka a závaží
	sb(Vector3(0.04, sh, 0.04), Vector3(-0.3, sh / 2, -0.95), m_grey)
	sb(Vector3(0.04, sh, 0.04), Vector3(0.3, sh / 2, -0.95), m_grey)
	counterweight = Node3D.new()
	add_child(counterweight)
	part(counterweight, Vector3(0.5, 1.2, 0.16), Vector3.ZERO, mat(Color(0.25, 0.25, 0.25)), false)
	for i in 6:
		part(counterweight, Vector3(0.52, 0.02, 0.17), Vector3(0, -0.5 + i * 0.2, 0), m_frame, false)
	rope_cab = part(self, Vector3(0.05, 1, 0.03), Vector3.ZERO, mat(Color(0.15, 0.15, 0.15)), false)[0]
	rope_cw = part(self, Vector3(0.05, 1, 0.03), Vector3.ZERO, mat(Color(0.15, 0.15, 0.15)), false)[0]

func _machine_room() -> void:
	var y := N * H
	sb(Vector3(6, 0.2, 3.8), Vector3(0, y - 0.1, -1.1), m_floor)
	sb(Vector3(0.1, H, 3.8), Vector3(-3, y + H / 2, -1.1), m_wall)
	sb(Vector3(0.1, H, 3.8), Vector3(3, y + H / 2, -1.1), m_wall)
	sb(Vector3(6, H, 0.1), Vector3(0, y + H / 2, -3.0), m_wall)
	sb(Vector3(4, H, 0.1), Vector3(-5, y + H / 2, 0.85), m_wall)
	sb(Vector3(4, H, 0.1), Vector3(5, y + H / 2, 0.85), m_wall)
	sb(Vector3(14, 0.2, 12), Vector3(0, y + H + 0.1, 3), m_wall)
	# motor s převodovkou a žlutým kladkovým kolem (podle fotky)
	motor_nodes.append(sb(Vector3(1.8, 0.35, 0.7), Vector3(-0.5, y + 0.17, -0.48), m_grey))
	motor_nodes.append(sb(Vector3(0.6, 0.55, 0.55), Vector3(-1.1, y + 0.62, -0.48), m_grey))
	motor_nodes.append(sb(Vector3(0.45, 0.55, 0.5), Vector3(-0.55, y + 0.62, -0.48), m_grey))
	var ma := Area3D.new()
	ma.position = Vector3(-0.6, y + 0.6, -0.48)
	add_child(ma)
	shape(ma, Vector3(2.0, 1.2, 0.8), Vector3.ZERO)
	ma.set_meta("act", ["motor"])
	ma.set_meta("hint", "Motor výtahu")
	var drum := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 0.18
	dm.bottom_radius = 0.18
	dm.height = 0.12
	drum.mesh = dm
	drum.material_override = mat(Color(0.8, 0.7, 0.2))
	drum.rotation.z = PI / 2
	drum.position = Vector3(-0.8, y + 0.62, -0.48)
	add_child(drum)
	motor_nodes.append(drum)
	wheel = Node3D.new()
	wheel.position = Vector3(0, y + 0.8, -0.48)
	add_child(wheel)
	var wm := CylinderMesh.new()
	wm.top_radius = 0.47
	wm.bottom_radius = 0.47
	wm.height = 0.14
	var wmi := MeshInstance3D.new()
	wmi.mesh = wm
	wmi.material_override = mat(Color(0.95, 0.8, 0.1))
	wmi.rotation.z = PI / 2
	wheel.add_child(wmi)
	for i in 3:   # paprsky, ať je vidět otáčení
		var sp: MeshInstance3D = part(wheel, Vector3(0.16, 0.88, 0.06), Vector3.ZERO, mat(Color(0.3, 0.3, 0.3)), false)[0]
		sp.rotation.x = i * PI / 3
	# rozvaděč
	var rv := Area3D.new()
	control_box = rv
	rv.position = Vector3(2.5, y + 1.2, -2.3)
	add_child(rv)
	part(rv, Vector3(0.4, 1.4, 0.8), Vector3.ZERO, m_grey, true)
	var rl := lbl("ROZVADĚČ\n⚡ 380 V", Vector3(-0.21, 0.4, 0), 0.0025, Color.BLACK)
	rl.rotation.y = -PI / 2
	rv.add_child(rl)
	rv.set_meta("act", ["repair"])
	rv.set_meta("hint", "Rozvaděč – opravit výtah")
	# rekonstrukční pult
	var rk := Area3D.new()
	rk.position = Vector3(-2.5, y + 1.0, -2.3)
	add_child(rk)
	part(rk, Vector3(0.4, 1.0, 0.8), Vector3.ZERO, mat(Color(0.3, 0.35, 0.5)), true)
	var rkl := lbl("REKONSTRUKCE", Vector3(0.21, 0.3, 0), 0.0025, Color.WHITE)
	rkl.rotation.y = PI / 2
	rk.add_child(rkl)
	rk.set_meta("act", ["rebuild"])
	rk.set_meta("hint", "Rekonstrukce výtahu – změnit vzhled")
	var l := OmniLight3D.new()
	l.position = Vector3(0, y + 2.6, -1.2)
	l.omni_range = 6
	add_child(l)

func _cabin() -> void:
	cabin = AnimatableBody3D.new()
	cabin.sync_to_physics = true
	add_child(cabin)
	part(cabin, Vector3(1.44, 0.1, 1.44), Vector3(0, -0.05, 0), mat(Color(0.25, 0.22, 0.2)), true)
	part(cabin, Vector3(0.04, 2.3, 1.44), Vector3(-0.7, 1.25, 0), m_wood, true)
	part(cabin, Vector3(0.04, 2.3, 1.44), Vector3(0.7, 1.25, 0), m_wood, true)
	part(cabin, Vector3(1.44, 2.3, 0.04), Vector3(0, 1.25, -0.7), m_wood, true)
	part(cabin, Vector3(1.44, 0.05, 1.44), Vector3(0, 2.42, 0), m_frame, true)
	part(cabin, Vector3(0.05, 0.05, 1.44), Vector3(-0.68, 0.9, 0), m_frame, false)   # madlo
	# shrnovací mříž
	var g := part(cabin, Vector3(1.36, 2.2, 0.03), Vector3(0, 1.2, 0.66), m_mesh, true)
	gate_mesh = g[0]
	gate_shape = g[1]
	gate_area = Area3D.new()
	gate_area.position = Vector3(0, 1.2, 0.66)
	cabin.add_child(gate_area)
	gate_area_box = BoxShape3D.new()
	gate_area_box.size = Vector3(1.36, 2.2, 0.12)
	var gs := CollisionShape3D.new()
	gs.shape = gate_area_box
	gate_area.add_child(gs)
	gate_area.set_meta("act", ["gate"])
	gate_area.set_meta("hint", "Shrnovací mříž kabiny")
	# nerezový panel s černými tlačítky (podle fotky)
	part(cabin, Vector3(0.015, 1.3, 0.2), Vector3(0.675, 1.32, 0.3), m_btn, false)
	cab_lamp = part(cabin, Vector3(0.02, 0.06, 0.06), Vector3(0.665, 1.9, 0.3), m_lamp_off, false)[0]
	for f in N:
		var b := button(cabin, Vector3(0.66, 0.92 + f * 0.075, 0.27), str(f), ["go", f], -PI / 2, "Jet do patra " + str(f), m_btn_black, 0.05)
		cab_btns.append(b)
	button(cabin, Vector3(0.66, 0.78, 0.27), "STOP", ["stop"], -PI / 2, "STOP", mat(Color(0.7, 0.1, 0.1)), 0.05)
	part(cabin, Vector3(0.18, 0.12, 0.01), Vector3(0.67, 2.1, 0.3), mat(Color(0.95, 0.95, 0.92)), false)
	var pl := lbl("ZPCHS Pardubice\nTyp: TOV\nNosnost 250 kg\n3 osoby", Vector3(0.66, 2.1, 0.3), 0.0008, Color(0.5, 0.1, 0.1))
	pl.rotation.y = -PI / 2
	cabin.add_child(pl)
	bulb = OmniLight3D.new()
	bulb.position = Vector3(0, 2.25, 0)
	bulb.light_color = Color(1, 0.8, 0.5)
	bulb.omni_range = 2.5
	bulb.light_energy = 0.8
	cabin.add_child(bulb)
	light_panel = part(cabin, Vector3(0.25, 0.04, 0.25), Vector3(0, 2.38, 0), mat(Color(1, 0.9, 0.7), true), false)[0]
	var la := Area3D.new()
	la.position = Vector3(0, 2.35, 0)
	cabin.add_child(la)
	shape(la, Vector3(0.4, 0.1, 0.4), Vector3.ZERO)
	la.set_meta("act", ["light"])
	la.set_meta("hint", "Světlo v kabině")
	# světelná závora (moderní náhrada mříže) – zatím schovaná
	curtain = Node3D.new()
	curtain.visible = false
	cabin.add_child(curtain)
	for i in 8:
		part(curtain, Vector3(1.3, 0.008, 0.008), Vector3(0, 0.15 + i * 0.25, 0.66), mat(Color(1, 0, 0), true), false)
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
	status = Label.new()
	status.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	status.position += Vector2(-260, 10)
	status.size = Vector2(250, 60)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	status.add_theme_constant_override("outline_size", 5)
	cl.add_child(status)
	var help := Label.new()
	help.text = "WASD chůze · myš rozhled · LMB/E použít · R reset mapy · Esc myš"
	help.position = Vector2(10, 10)
	help.modulate = Color(1, 1, 1, 0.6)
	cl.add_child(help)

# ---------------------------------------------------------------- dotykové ovládání
var joy_knob: Panel
var was_inside := false
var touch_layer: CanvasLayer

func _round_panel(sz: float, c: Color, border: Color) -> Panel:
	var p := Panel.new()
	var st := StyleBoxFlat.new()
	st.bg_color = c
	st.border_color = border
	st.set_border_width_all(4)
	st.set_corner_radius_all(int(sz / 2))
	p.add_theme_stylebox_override("panel", st)
	p.size = Vector2(sz, sz)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p

func _touch_ui() -> void:
	touch_layer = CanvasLayer.new()
	add_child(touch_layer)
	_layout_touch()
	get_viewport().size_changed.connect(_layout_touch)

func _layout_touch() -> void:
	for c in touch_layer.get_children():
		c.queue_free()
	var vs := get_viewport().get_visible_rect().size
	var base := _round_panel(240, Color(0, 0, 0, 0.3), Color(0.55, 0.33, 0.14, 0.8))
	base.position = Vector2(60, vs.y - 300)
	touch_layer.add_child(base)
	joy_knob = _round_panel(100, Color(0.55, 0.33, 0.14, 0.9), Color(0.2, 0.2, 0.2))
	touch_layer.add_child(joy_knob)
	player.joy_center = base.position + Vector2(120, 120)
	var b := _round_panel(200, Color(0.75, 0.75, 0.72, 0.85), Color(0.35, 0.35, 0.35))
	b.position = Vector2(vs.x - 260, vs.y - 280)
	touch_layer.add_child(b)
	var l := Label.new()
	l.text = "POUŽÍT"
	l.add_theme_font_size_override("font_size", 36)
	l.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	l.size = b.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(l)
	player.use_rect = Rect2(b.position, b.size)
	var rb := _round_panel(110, Color(0.6, 0.1, 0.1, 0.8), Color(0.2, 0.2, 0.2))
	rb.position = Vector2(vs.x - 140, 170)
	touch_layer.add_child(rb)
	var rlb := Label.new()
	rlb.text = "RESET"
	rlb.size = rb.size
	rlb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rlb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rb.add_child(rlb)
	reset_rect = Rect2(rb.position, rb.size)
	var info := Label.new()
	info.text = "táhni pravou stranou pro rozhled"
	info.modulate = Color(1, 1, 1, 0.5)
	info.position = Vector2(vs.x - 330, vs.y - 40)
	touch_layer.add_child(info)

# ---------------------------------------------------------------- helpers
func mat(c: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.8
	if glow:
		m.emission_enabled = true
		m.emission = c
	return m

func shape(n: Node, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	n.add_child(cs)

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

## tlačítko: Area3D s hmatníkem; číslo je vlevo na panelu. Vrací mesh hmatníku (kvůli podsvícení).
func button(parent: Node, pos: Vector3, t: String, act: Array, rot: float, h: String, m: Material, sz := 0.09) -> MeshInstance3D:
	var a := Area3D.new()
	a.position = pos
	a.rotation.y = rot
	parent.add_child(a)
	var mi: MeshInstance3D = part(a, Vector3(sz, sz, 0.03), Vector3.ZERO, m, false)[0]
	shape(a, Vector3(max(sz, 0.07), max(sz, 0.07), 0.05), Vector3.ZERO)
	if t != "":
		a.add_child(lbl(t, Vector3(-sz / 2 - 0.035, 0, 0.0), 0.0014 if t.length() < 3 else 0.0008, Color(0.1, 0.1, 0.1)))
	a.set_meta("act", act)
	a.set_meta("hint", h)
	return mi

func say(t: String, secs := 4.0) -> void:
	msg.text = t
	msg_time = secs

# ---------------------------------------------------------------- sounds
const SR := 22050

func _sounds() -> void:
	sfx["relay"] = _gen_relay()
	sfx["start"] = _gen_relay()
	sfx["enter"] = _gen_noise(0.3, 0.05, 2.0, 0.6)
	sfx["door"] = _gen_noise(0.7, 0.04, 2.5, 1.0)
	sfx["gate"] = _gen_rattle()
	sfx["brake"] = _gen_noise(0.45, 0.02, 2.0, 0.9)
	sfx["buzz"] = _gen_buzz()
	sfx["motor"] = _gen_motor()
	sfx["fire"] = _gen_crackle()
	sfx["spray"] = _gen_noise(1.5, 0.6, 0.5, 0.5)
	for k in sfx.keys():
		for ext in ["ogg", "wav", "mp3"]:
			var p := "res://sounds/%s.%s" % [k, ext]
			if ResourceLoader.exists(p):
				var s = load(p)
				if (k == "motor" or k == "fire") and "loop" in s:
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

func _gen_crackle() -> AudioStreamWAV:
	var n := SR * 2
	var s := PackedFloat32Array()
	s.resize(n)
	var y := 0.0
	for i in n:
		y += 0.05 * (randf_range(-1, 1) - y)
		s[i] = y * 1.5
	for k in 60:
		var c := randi() % (n - 300)
		for i in 200:
			s[c + i] += randf_range(-1, 1) * (1.0 - i / 200.0) * 0.6
	return _to_wav(s, true)

func _gen_buzz() -> AudioStreamWAV:
	var n := int(0.5 * SR)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		s[i] = (0.25 if fmod(i * 100.0 / SR, 1.0) < 0.5 else -0.25)
	return _to_wav(s)

func _gen_motor() -> AudioStreamWAV:
	var n := SR * 2
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

# ---------------------------------------------------------------- požár
func _particles(amount: int, life: float, c0: Color, c1: Color, sz: float, vel: float, add: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.direction = Vector3.UP
	p.spread = 15
	p.gravity = Vector3(0, 0.5, 0)
	p.initial_velocity_min = vel * 0.5
	p.initial_velocity_max = vel
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(sz, sz)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if add:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material = m
	p.mesh = q
	var g := Gradient.new()
	g.set_color(0, c0)
	g.set_color(1, c1)
	p.color_ramp = g
	return p

func start_fire() -> void:
	if fire:
		return
	fire_floor = randi() % N
	fire = Node3D.new()
	fire.position = Vector3(1.6, fire_floor * H, 1.5)
	add_child(fire)
	fire.add_child(_particles(40, 0.9, Color(1, 0.8, 0.2), Color(0.8, 0.1, 0, 0), 0.5, 1.2, true))
	var smoke := _particles(25, 3.0, Color(0.2, 0.2, 0.2, 0.7), Color(0.4, 0.4, 0.4, 0), 0.9, 0.6, false)
	smoke.position.y = 0.6
	fire.add_child(smoke)
	var l := OmniLight3D.new()
	l.light_color = Color(1, 0.5, 0.1)
	l.light_energy = 2
	l.omni_range = 5
	l.position.y = 0.6
	l.name = "L"
	fire.add_child(l)
	var a := Area3D.new()
	a.position.y = 0.5
	fire.add_child(a)
	shape(a, Vector3(1.0, 1.2, 1.0), Vector3.ZERO)
	a.set_meta("act", ["fire"])
	a.set_meta("hint", "Oheň – uhasit")
	var snd := AudioStreamPlayer3D.new()
	snd.stream = sfx["fire"]
	snd.unit_size = 4
	snd.autoplay = true
	fire.add_child(snd)
	if moving:
		_emergency_stop()
	say("HOŘÍ! V %d. patře u šachty vypukl požár. Výtah se vypnul. Vezmi hasicí přístroj!" % fire_floor, 7)

func _emergency_stop() -> void:
	moving = false
	motor.stop()
	play("brake")

# ---------------------------------------------------------------- logic
func at_floor(f: int) -> bool:
	return not moving and not stuck and abs(cabin.position.y - f * H) < 0.02

func _part_key(act: Array) -> String:
	match act[0]:
		"door": return "door:%d" % act[1]
		"gate": return "gate"
		"go", "stop": return "panel"
		"call": return "ind"
		"repair": return "control"
		"motor": return "motor"
		"light": return "light"
	return ""

func _part_name(k: String, st: int) -> String:
	if k.begins_with("door:"):
		return ["staré dveře s drátěným sklem", "", "moderní nerezové dveře"][st]
	return PART_NAMES[k][0 if st == OLD else 1]

func _on_act(act: Array) -> void:
	if has_wrench:
		var k := _part_key(act)
		if k != "":
			_wrench_part(k)
			return
	if act[0] in ["motor", "light"]:
		say("Na tohle potřebuješ montážní klíč (visí v přízemí vedle sekery).")
		return
	if act[0] in ["go", "stop"] and parts["panel"] == GONE:
		say("Panel je demontovaný, z díry trčí dráty.")
		return
	if has_axe and act[0] in ["door", "gate", "go", "call", "stop", "repair", "motor", "light"]:
		_hit(act)
		return
	match act[0]:
		"call":
			play("relay")
			if moving:
				say("Výtah už jede – svítí OBSAZENO.")
			elif at_floor(act[1]):
				say("Výtah tu stojí. Otevři dveře.")
			else:
				start(act[1])
		"go":
			play("relay")
			if stuck:
				say("Tlačítko nereaguje… kabina uvízla.")
			elif not moving and not at_floor(act[1]):
				start(act[1])
		"stop":
			play("relay")
			if moving:
				_emergency_stop()
				health = max(health - 4, 0)
				say("STOP! Prudké zabrzdění mezi patry, kabina se otřese. (opotřebení +)", 5)
		"door":
			var f: int = act[1]
			if parts["door:%d" % f] == GONE:
				say("Dveře chybí – zeje tu díra do šachty!")
				return
			if not at_floor(f):
				play("buzz")
				say("Dveře nejdou otevřít – kabina tu není, zámek drží.")
				return
			door_open[f] = not door_open[f]
			var tw := create_tween()
			tw.tween_property(doors[f], "rotation:y", -1.75 if door_open[f] else 0.0, 0.7).set_trans(Tween.TRANS_SINE)
			if door_open[f]:
				play("door")
				say("Zabereš za kliku, těžké dveře s drátěným sklem zaskřípou.")
			else:
				tw.tween_callback(play.bind("door"))
				say("Zavírač dveře přitáhne – BOUCH!")
		"gate":
			if moving or stuck:
				return
			if parts["gate"] == NEW:
				say("Mříž tu už není – kabinu hlídá moderní světelná závora.")
				return
			if parts["gate"] == GONE:
				say("Mříž je demontovaná.")
				return
			gate_open = not gate_open
			play("gate")
			gate_shape.disabled = gate_open
			# když je mříž shrnutá, „chytá“ se jen u boku, ať jde sáhnout na dveře
			gate_area.position.x = 0.6 if gate_open else 0.0
			gate_area_box.size.x = 0.2 if gate_open else 1.36
			var tw := create_tween().set_parallel()
			tw.tween_property(gate_mesh, "scale:x", 0.08 if gate_open else 1.0, 0.5)
			tw.tween_property(gate_mesh, "position:x", 0.62 if gate_open else 0.0, 0.5)
			say("Mříž se s rachotem shrne do strany." if gate_open else "Řinč-řinč… zatáhneš mříž, kontakt cvakne.")
		"drop":
			_drop()
		"take":
			if carry:
				say("Ruce máš plné – nejdřív díl odlož.")
			else:
				_set_carry({"kind": act[1], "mod": act[2]})
				say("Bereš ze skladu: %s." % _kind_name(act[1], act[2]))
		"pickup":
			if carry:
				say("Ruce máš plné.")
			else:
				_set_carry({"kind": act[1], "mod": act[2]})
				act[3].queue_free()
				say("Zvedáš: %s." % _kind_name(act[1], act[2]))
		"wrench":
			has_wrench = not has_wrench
			say("Bereš montážní klíč. Teď můžeš výtah rozebírat po dílech a montovat moderní náhrady." if has_wrench else "Vracíš nářadí.", 5)
		"axe":
			has_axe = not has_axe
			say("Sundáš ze zdi požární sekeru. Teď můžeš do výtahu sekat (zpátky ji vrátíš tady)." if has_axe else "Vrátíš sekeru na místo.")
		"rebuild":
			if fire:
				say("Nejdřív uhas požár!")
				return
			style = (style + 1) % STYLES.size()
			m_frame.albedo_color = STYLES[style][1]
			var tex: ImageTexture = m_mesh.albedo_texture
			var img := tex.get_image()
			for i in 32:
				for t in 3:
					img.set_pixel(i, t, STYLES[style][2])
					img.set_pixel(t, i, STYLES[style][2])
			tex.update(img)
			for pair in door_glass:
				for gm in pair:
					gm.visible = true
			health = 100
			play("relay")
			say("Rekonstrukce hotová: %s. Výtah má nové sklo a je jako nový." % STYLES[style][0], 5)
		"ext":
			if has_ext:
				say("Jeden hasičák už neseš.")
			else:
				has_ext = true
				say("Sundáš ze zdi hasicí přístroj. Těžký a studený.")
		"fire":
			if not has_ext:
				say("Holýma rukama to neuhasíš! Hasicí přístroj visí u každých dveří výtahu.")
				return
			play("spray")
			fire.queue_free()
			fire = null
			has_ext = false
			say("Pšššš! Oheň je uhašený. Výtah je ale ohořelý – oprav ho v rozvaděči ve strojovně.", 6)
		"repair":
			if fire:
				say("Nejdřív uhas požár!")
			elif repairing:
				pass
			elif health >= 100:
				say("V rozvaděči všechno cvaká, jak má. Výtah je v pořádku.")
			else:
				repairing = true
				play("relay")
				say("Vyměňuješ pojistky a čistíš stykače…", 3)
				await get_tree().create_timer(3.0).timeout
				health = 100
				repairing = false
				play("relay")
				say("Hotovo! Výtah je opravený.")

func _hit(act: Array) -> void:
	play("door")
	health = max(health - 10, 0)
	var k := _part_key(act)
	if act[0] == "door":
		var pair: Array = door_glass[act[1]]
		if parts[k] != GONE and (pair[0].visible or pair[1].visible):
			for gm in pair:
				_shards(gm)
				gm.visible = false
			say("PRÁSK! Drátěné sklo se roztříští a střepy letí na zem.")
		elif _destroy(k):
			say("Dveře se utrhnou z pantů a s rachotem padají na zem!")
		else:
			say("Tady už nic není.")
	elif k != "" and _destroy(k):
		var nm := _part_name(k, parts_prev.get(k, OLD))
		say("KŘACH! %s se rozpadá a kusy padají na zem." % (nm.substr(0, 1).to_upper() + nm.substr(1)), 5)
	else:
		say("Sekáš do prázdna – tady už nic není.")
	if moving and randf() < 0.4:
		_breakdown()
	if health <= 0:
		say("Výtah je úplně zničený. Oprav ho v rozvaděči nebo přines nové díly ze skladu.", 5)

# ---------------------------------------------------------------- fyzikální úlomky (ragdoll)
var debris: Array = []

func _part_nodes(k: String) -> Array:
	if k.begins_with("door:"):
		return [doors[int(k.split(":")[1])].get_child(0)]
	match k:
		"gate": return [gate_mesh]
		"panel":
			var a: Array = [cab_lamp]
			for b in cab_btns:
				a.append(b.get_parent())
			return a
		"light": return [light_panel]
		"motor": return motor_nodes + [wheel]
		"control": return [control_box]
		"ind": return busy_lamps
	return []

func _collect_meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D and n.is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		_collect_meshes(c, out)

func _spawn_body(mesh: Mesh, m: Material, xf: Transform3D, size: Vector3) -> RigidBody3D:
	var rb := RigidBody3D.new()
	rb.collision_layer = 2          # hráč úlomky neblokují, ale padají na podlahu
	rb.collision_mask = 1 | 2
	add_child(rb)
	rb.global_transform = xf
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	rb.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(max(size.x, 0.03), max(size.y, 0.03), max(size.z, 0.03))
	cs.shape = bs
	rb.add_child(cs)
	rb.mass = clampf(size.x * size.y * size.z * 400.0, 0.2, 60.0)
	var away: Vector3 = (xf.origin - player.global_position)
	away.y = 0
	rb.apply_central_impulse((away.normalized() * 1.5 + Vector3(randf_range(-1, 1), randf_range(0, 1.5), randf_range(-1, 1))) * rb.mass)
	rb.apply_torque_impulse(Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * rb.mass * 0.3)
	debris.append(rb)
	while debris.size() > 160:
		var old = debris.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	return rb

func _debris(nodes: Array) -> void:
	var meshes: Array = []
	for n in nodes:
		_collect_meshes(n, meshes)
	for mi in meshes:
		var sz: Vector3 = mi.get_aabb().size * mi.global_transform.basis.get_scale()
		_spawn_body(mi.mesh, mi.material_override, mi.global_transform.orthonormalized(), sz)

func _shards(mi: MeshInstance3D) -> void:
	if not mi.is_visible_in_tree():
		return
	var sz: Vector3 = mi.get_aabb().size
	for i in 10:
		var bm := BoxMesh.new()
		var piece := Vector3(sz.x * randf_range(0.15, 0.35), sz.y * randf_range(0.12, 0.3), 0.01)
		bm.size = piece
		var xf := mi.global_transform
		xf.origin += xf.basis * Vector3(randf_range(-0.4, 0.4) * sz.x, randf_range(-0.4, 0.4) * sz.y, 0)
		_spawn_body(bm, mi.material_override, xf, piece)

func _destroy(k: String) -> bool:
	if parts[k] == GONE:
		return false
	_modern_mats()
	_debris(_part_nodes(k))
	parts_prev[k] = parts[k]
	parts[k] = GONE
	_apply_part(k)
	return true

# ---------------------------------------------------------------- nošení dílů a sklad
var carry = null                 # {"kind": "door"/"gate"/…, "mod": OLD/NEW}
var carry_mesh: MeshInstance3D

func _kind(k: String) -> String:
	return "door" if k.begins_with("door:") else k

func _kind_name(kind: String, mod: int) -> String:
	return _part_name("door:0" if kind == "door" else kind, mod)

const KIND_SIZE := {
	"door": Vector3(0.45, 0.9, 0.04), "gate": Vector3(0.5, 0.7, 0.05), "panel": Vector3(0.12, 0.5, 0.03),
	"light": Vector3(0.25, 0.05, 0.25), "motor": Vector3(0.5, 0.4, 0.4), "control": Vector3(0.3, 0.45, 0.2),
	"ind": Vector3(0.2, 0.15, 0.05),
}

func _kind_mat(mod: int) -> Material:
	_modern_mats()
	return m_steel if mod == NEW else m_frame

func _set_carry(c) -> void:
	carry = c
	if carry_mesh:
		carry_mesh.queue_free()
		carry_mesh = null
	if c:
		carry_mesh = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = KIND_SIZE[c.kind]
		carry_mesh.mesh = bm
		carry_mesh.material_override = _kind_mat(c.mod)
		carry_mesh.position = Vector3(0.35, -0.35, -0.75)
		player.cam.add_child(carry_mesh)

func _drop() -> void:
	if carry == null:
		return
	var xf: Transform3D = player.cam.global_transform
	xf.origin += -xf.basis.z * 0.8
	var bm := BoxMesh.new()
	bm.size = KIND_SIZE[carry.kind]
	var rb := RigidBody3D.new()
	rb.collision_layer = 4          # odložené díly jdou zase zvednout
	rb.collision_mask = 1 | 2 | 4
	add_child(rb)
	rb.global_transform = xf
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.material_override = _kind_mat(carry.mod)
	rb.add_child(mi)
	shape(rb, bm.size, Vector3.ZERO)
	var name_: String = _kind_name(carry.kind, carry.mod)
	rb.set_meta("act", ["pickup", carry.kind, carry.mod, rb])
	rb.set_meta("hint", "Zvednout: " + name_)
	say("Odkládáš: %s." % name_)
	_set_carry(null)

func _store() -> void:
	# sklad dílů v přízemí u zadní stěny: nahoře moderní, dole staré
	add_child(lbl("SKLAD DÍLŮ  ·  nahoře 21. století  ·  dole původní 1974", Vector3(3.8, 2.4, 8.88), 0.004, Color(0.2, 0.2, 0.2)))
	for row in [[NEW, 1.45], [OLD, 0.55]]:
		sb(Vector3(5.8, 0.05, 0.5), Vector3(3.8, row[1] - 0.25, 8.65), m_wood)
	var kinds := ["door", "gate", "panel", "light", "motor", "control", "ind"]
	for i in kinds.size():
		for row in [[NEW, 1.45], [OLD, 0.55]]:
			var a := Area3D.new()
			a.position = Vector3(1.2 + i * 0.85, row[1] - 0.22 + KIND_SIZE[kinds[i]].y / 2, 8.62)
			add_child(a)
			var sz: Vector3 = KIND_SIZE[kinds[i]]
			part(a, sz, Vector3.ZERO, _kind_mat(row[0]), false)
			shape(a, Vector3(max(sz.x, 0.3), max(sz.y, 0.3), 0.4), Vector3.ZERO)
			var nm := _kind_name(kinds[i], row[0])
			a.add_child(lbl(nm, Vector3(0, -sz.y / 2 - 0.08, 0.26), 0.0014, Color(0.1, 0.1, 0.1)))
			a.set_meta("act", ["take", kinds[i], row[0]])
			a.set_meta("hint", "Vzít: " + nm)

func _input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_R:
		get_tree().reload_current_scene()
	elif e is InputEventScreenTouch and e.pressed and reset_rect.has_point(e.position):
		get_tree().reload_current_scene()

var m_steel: StandardMaterial3D
var m_clear: StandardMaterial3D
var m_led: StandardMaterial3D
var m_blue: StandardMaterial3D

func _modern_mats() -> void:
	if m_steel:
		return
	m_steel = mat(Color(0.78, 0.8, 0.82))
	m_steel.metallic = 0.9
	m_steel.roughness = 0.3
	m_clear = mat(Color(0.7, 0.85, 0.95, 0.3))
	m_clear.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m_clear.roughness = 0.05
	m_led = mat(Color(0.2, 0.6, 1.0), true)
	m_led.emission_energy_multiplier = 3
	m_blue = mat(Color(0.2, 0.35, 0.6))
	m_blue.metallic = 0.5

## nastaví materiál všem meshům pod uzlem (null = vrátí původní)
func _skin(n: Node, m: Material) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			if not c.has_meta("orig"):
				c.set_meta("orig", c.material_override)
			c.material_override = m if m else c.get_meta("orig")
		_skin(c, m)

func _solid(n: Node, on: bool) -> void:
	for c in n.get_children():
		if c is CollisionShape3D and not (n is Area3D):
			c.disabled = not on
		_solid(c, on)

func _wrench_part(k: String) -> void:
	if moving or stuck:
		say("Za jízdy nic nerozebírej!")
		return
	_modern_mats()
	var st: int = parts[k]
	var kind := _kind(k)
	if st != GONE:
		if carry:
			say("Ruce máš plné – nejdřív díl odlož (POUŽÍT do prázdna).")
			return
		parts_prev[k] = st
		parts[k] = GONE
		_apply_part(k)
		_set_carry({"kind": kind, "mod": st})
		play("gate")
		say("Povoluješ šrouby… odmontováno: %s. Neseš ho v rukou. Odlož ho a přines náhradu ze skladu v přízemí." % _part_name(k, st), 6)
	else:
		if carry == null:
			say("Tady chybí díl. Přines ho – nové i staré díly jsou ve skladu v přízemí.", 5)
			return
		if carry.kind != kind:
			say("Tohle sem nepasuje – neseš %s." % _kind_name(carry.kind, carry.mod))
			return
		parts[k] = carry.mod
		_apply_part(k)
		play("relay")
		say("Namontováno: %s." % _part_name(k, carry.mod) + (" Vítej v 21. století!" if carry.mod == NEW else " Zpátky v roce 1974."), 5)
		_set_carry(null)

func _apply_part(k: String) -> void:
	_modern_mats()
	var st: int = parts[k]
	if k.begins_with("door:"):
		var f := int(k.split(":")[1])
		var d: Node3D = doors[f].get_child(0)
		d.visible = st != GONE
		_solid(d, st != GONE)
		_skin(d, m_steel if st == NEW else null)
		for gm in door_glass[f]:
			gm.material_override = m_clear if st == NEW else m_glass
			gm.visible = true
		if st == GONE and door_open[f]:
			door_open[f] = false
			doors[f].rotation.y = 0
		return
	match k:
		"gate":
			gate_mesh.visible = st == OLD
			gate_shape.disabled = st != OLD or gate_open
			curtain.visible = st == NEW
		"panel":
			for b in cab_btns:
				b.get_parent().visible = st != GONE
			cab_lamp.visible = st != GONE
		"light":
			light_panel.visible = st != GONE
			light_panel.material_override = mat(Color(0.95, 0.97, 1), true) if st == NEW else light_panel.get_meta("orig", light_panel.material_override)
			if not light_panel.has_meta("orig"):
				light_panel.set_meta("orig", light_panel.material_override)
			bulb.light_color = Color(0.95, 0.97, 1) if st == NEW else Color(1, 0.8, 0.5)
		"motor":
			for n in motor_nodes:
				n.visible = st != GONE
				if n is StaticBody3D:
					_solid(n, st != GONE)
					_skin(n, m_blue if st == NEW else null)
			wheel.visible = st != GONE
			_skin(wheel, m_steel if st == NEW else null)
			SPEED = 1.8 if st == NEW else 1.0
			motor.pitch_scale = 1.5 if st == NEW else 1.0
			motor.volume_db = -10.0 if st == NEW else 0.0
		"control":
			control_box.visible = st != GONE
			_skin(control_box, mat(Color(0.92, 0.92, 0.9)) if st == NEW else null)
		"ind":
			for i in indicators:
				i.visible = st != GONE
				i.modulate = Color(0.3, 0.9, 1.0) if st == NEW else Color(1, 0.1, 0.1)
			for l in busy_lamps:
				l.visible = st != GONE

func start(f: int) -> void:
	if health <= 0:
		play("buzz")
		say("VÝTAH MIMO PROVOZ – je zničený. Oprav ho v rozvaděči ve strojovně (nahoře po schodech).", 6)
		return
	if fire:
		play("buzz")
		say("Při požáru výtah nejede! Uhas oheň v %d. patře." % fire_floor)
		return
	if true in door_open:
		play("buzz")
		say("Nic. Šachetní dveře jsou otevřené – bezpečnostní kontakt nesepnul.")
		return
	var missing := []
	for k in parts:
		if parts[k] == GONE:
			missing.append(_part_name(k, parts_prev.get(k, OLD)))
	if missing.size() > 0:
		play("buzz")
		say("Výtah nepojede, chybí: " + ", ".join(missing), 6)
		return
	if gate_open and parts["gate"] == OLD:
		play("buzz")
		say("Nic. Mříž v kabině není zatažená.")
		return
	target = f
	moving = true
	break_at = -1.0
	var p := 0.07 + (100.0 - health) / 250.0
	if parts["control"] == NEW:
		p *= 0.2
	if parts["motor"] == NEW:
		p *= 0.5
	if randf() < p and absf(cabin.position.y - f * H) > H:
		break_at = lerpf(cabin.position.y, f * H, randf_range(0.3, 0.7))
	play("start")
	get_tree().create_timer(1.0).timeout.connect(_motor_on)

func _motor_on() -> void:
	if moving:
		motor.play()

func _breakdown() -> void:
	_emergency_stop()
	stuck = true
	health = max(health - 8, 0)
	say("Rána, cvaknutí… a ticho. PORUCHA! Kabina uvízla mezi patry, žárovka bliká.", 6)
	await get_tree().create_timer(randf_range(5.0, 9.0)).timeout
	if fire or health <= 0:
		stuck = false
		return
	stuck = false
	moving = true
	play("start")
	get_tree().create_timer(0.8).timeout.connect(_motor_on)
	say("Něco ve strojovně naskočilo a kabina se škubnutím rozjede dál.")

func _tick() -> void:
	if fire:
		health = max(health - 2.0, 0)
		if health <= 0:
			say("Výtah je požárem zničený!")
	elif randf() < 1.0 / 300.0:   # zhruba jednou za 5 minut
		start_fire()

func _physics_process(delta: float) -> void:
	if moving:
		var ty := target * H
		var prev := cabin.position.y
		cabin.position.y = move_toward(cabin.position.y, ty, SPEED * delta)
		wheel.rotation.x += (cabin.position.y - prev) * 2.1
		if break_at >= 0 and absf(cabin.position.y - break_at) <= SPEED * delta:
			break_at = -1.0
			_breakdown()
		elif is_equal_approx(cabin.position.y, ty):
			moving = false
			motor.stop()
			play("brake")
			say("Zabrzdění – %d. patro. Kabina se ještě zhoupne na lanech." % target)
	# lana a závaží
	var cy := cabin.position.y
	var top := N * H + 0.8
	counterweight.position = Vector3(0, (N - 1) * H + 1.2 - cy, -0.95)
	rope_cab.position = Vector3(0, (cy + 2.45 + top) / 2, -0.04)
	rope_cab.scale.y = top - cy - 2.45
	var cwt := counterweight.position.y + 0.6
	rope_cw.position = Vector3(0, (cwt + top) / 2, -0.93)
	rope_cw.scale.y = top - cwt
	var fl := str(clampi(roundi(cy / H), 0, N - 1))
	for i in indicators:
		i.text = fl
	for l in busy_lamps:
		l.material_override = m_lamp_on if (moving or stuck) else m_lamp_off
	cab_lamp.material_override = m_lamp_on if (moving or stuck) else m_lamp_off
	for f in N:
		cab_btns[f].material_override = (m_led if parts["panel"] == NEW else m_btn_lit) if ((moving or stuck) and f == target) else (m_steel if parts["panel"] == NEW else m_btn_black)
	var inside: bool = absf(player.position.x) < 0.7 and absf(player.position.z) < 0.7 and absf(player.position.y - cy) < 1.0
	player.shake = moving and inside
	if inside != was_inside and not moving:
		if inside:
			play("enter")
		was_inside = inside

func _process(delta: float) -> void:
	if joy_knob:
		joy_knob.position = player.joy_center + player.touch_move * 90 - Vector2(50, 50)
	var c: Object = player.looked_at()
	hint.text = ("[E] " + c.get_meta("hint")) if c else ""
	if msg_time > 0:
		msg_time -= delta
		if msg_time <= 0:
			msg.text = ""
	# blikání žárovky při poruše / poškození
	if parts["light"] == GONE:
		bulb.light_energy = 0.0
	elif parts["light"] == NEW:
		bulb.light_energy = 1.3
	elif stuck or health < 40 or fire:
		bulb.light_energy = 0.8 if randf() > 0.15 else 0.05
	else:
		bulb.light_energy = 0.8
	if fire:
		var fl: OmniLight3D = fire.get_node("L")
		fl.light_energy = randf_range(1.5, 2.6)
	var st := "Stav výtahu: %d %%" % int(health)
	if health <= 0:
		st += "  ✖ MIMO PROVOZ"
	if fire:
		st += "\n🔥 POŽÁR v %d. patře" % fire_floor
	if has_ext:
		st += "\nNeseš hasicí přístroj"
	if has_axe:
		st += "\nNeseš sekeru 🪓"
	if has_wrench:
		st += "\nNeseš montážní klíč 🔧"
	if carry:
		st += "\nV rukou: " + _kind_name(carry.kind, carry.mod)
	var modern := 0
	for k in parts:
		if parts[k] == NEW:
			modern += 1
	if modern > 0:
		st += "\nModernizováno: %d / %d dílů" % [modern, parts.size()]
	status.text = st
