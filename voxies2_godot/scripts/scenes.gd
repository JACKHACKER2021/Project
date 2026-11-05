extends Node
## Nové scény NaV2: zatčení náčelníkem Králem po odchodu z herny a easter egg po konci 3
## (vězení → pravda o D. → útěk → jumpscare D.).
const People := preload("res://scripts/people.gd")
const Hollow := preload("res://scripts/hollow.gd")
var suit: Node3D
var game
var road: Node3D
var cell: Node3D
var police_L: OmniLight3D
var police_R: OmniLight3D
var kral: Dictionary
var dman: Dictionary
var S := {"k": "", "t": 0.0, "said": 0, "after": 1, "sirenT": 0.0}
const D_LINES := ["Tady mě nenajdou… nikdo mě v tom nenajde.", "Je to v pohodě… je to v po…", "Ne! Ne, ne! Zámky! Aaah!", "Pusť… mě… prosím… bolí to…", "Já… jsem to… nechtěl…"]
const WX := 600.0      # sklad (budoucí Frights and Hides)
var store: Node3D
var pool: MeshInstance3D
var bl_mm: MultiMeshInstance3D
var bl_p := PackedVector3Array()
var bl_v := PackedVector3Array()
var bl_l := PackedFloat32Array()
var bl_i := 0
const OX := 400.0      # ulice
const PX := -400.0     # vězení

const ARREST_SUB := [
	[1.0, "", "Konečně venku. Studený vzduch. Za tebou ještě kouří trosky."],
	[5.0, "", "Jdeš po prázdné silnici domů…"],
	[8.2, "", "Za zády se rozblikala modrá a červená."],
	[12.0, "Náčelník Král", "Policie! Stůjte. Ruce nahoru!"],
	[15.4, "Náčelník Král", "Jsem náčelník Král. Zatýkám vás pro podezření ze žhářství herny Voxie's."],
	[19.6, "Náčelník Král", "Máte právo nevypovídat. Všechno, co řeknete, může být použito proti vám."],
	[23.0, "", "Cvak. Pouta."],
]
const PRISON_SUB := [
	[1.0, "", "Vazební věznice. Cela číslo tři. Tři dny po zatčení."],
	[4.5, "Náčelník Král", "Hlídači. Máme výsledky z laboratoře."],
	[8.0, "Náčelník Král", "Na kanystru nejsou vaše otisky. Jsou tam otisky bývalého nočního hlídače. Toho, kterému říkají D."],
	[13.0, "Náčelník Král", "Záznam z kamery sedm nebyl smazaný celý. Je na něm on. S kanystrem."],
	[17.4, "Náčelník Král", "Jste volný. Omlouvám se. Jdeme pro něj."],
	[21.6, "", "Stopy vedly do skladu za městem. Sem převezli všechno, co zbylo z herny Voxie's."],
	[25.0, "Náčelník Král", "Stůj! Policie! Ze skladu nevedou žádné jiné dveře!"],
	[28.4, "", "Automaty, stoly z pizzerie, kulisy z pódia… a mezi nimi Hollow Bunny."],
	[31.4, "D.", "Tady mě nenajdou… nikdo mě v tom nenajde."],
	[34.4, "", "Oblékl si ho. Věděl, že zámky povolují samy od sebe."],
	[37.2, "D.", "Je to v pohodě… je to v po…"],
	[39.4, "", "Cvak."],
	[40.2, "D.", "Ne! Ne, ne! Zámky! Aaah!"],
	[43.2, "D.", "Pusť… mě… prosím… bolí to…"],
	[46.4, "D.", "Já… jsem to… nechtěl…"],
	[49.2, "", "Springlocky selhaly. Ticho. Jen kapání."],
]

static func _b(p: Node3D, sz: Vector3, pos: Vector3, c: String, emit := false) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	mi.mesh = b
	mi.position = pos
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(c)
	m.roughness = 0.9
	if emit:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	p.add_child(mi)
	return mi

func build() -> void:
	# --- ulice za hernou ---
	road = Node3D.new()
	road.position = Vector3(OX, 0, 0)
	game.add_child(road)
	_b(road, Vector3(8, 0.05, 120), Vector3(0, 0, -40), "#18181a")
	for i in 30:
		_b(road, Vector3(0.15, 0.06, 1.6), Vector3(0, 0.01, 10 - i * 4), "#bbbbaa")
	for s in [-1, 1]:
		_b(road, Vector3(3, 0.15, 120), Vector3(5.5 * s, 0.07, -40), "#3a3a3c")
		for i in 10:
			var z = 6 - i * 12
			_b(road, Vector3(0.12, 4, 0.12), Vector3(6.6 * s, 2, z), "#222222")
			_b(road, Vector3(0.5, 0.12, 0.3), Vector3(6.2 * s, 4, z), "#ffe0a0", true)
			if i % 2 == 0:
				var L = OmniLight3D.new()
				L.light_color = Color("#ffd090")
				L.light_energy = 1.4
				L.omni_range = 9
				L.position = Vector3(6 * s, 3.8, z)
				road.add_child(L)
		for i in 8:
			var h = randf_range(4, 9)
			_b(road, Vector3(8, h, 9), Vector3(12 * s, h / 2, 2 - i * 13), ["#2a2228", "#22262c", "#2c2420"][i % 3])
			for w in 3:
				_b(road, Vector3(0.05, 0.9, 0.9), Vector3((8 - 0.05) * s + 4 * -s + 0.0, randf_range(1.5, h - 1), 2 - i * 13 + (w - 1) * 2.5), "#ffd890" if randf() < 0.35 else "#101018", true)
	# vyhořelá herna vzadu
	_b(road, Vector3(18, 5, 6), Vector3(0, 2.5, 18), "#100c0c")
	_b(road, Vector3(4, 1.2, 0.2), Vector3(0, 4.2, 14.9), "#3a1020", true)
	# policejní auto
	var car = Node3D.new()
	car.position = Vector3(-1.6, 0, 9)
	road.add_child(car)
	_b(car, Vector3(1.9, 0.8, 4.4), Vector3(0, 0.7, 0), "#e8e8ea")
	_b(car, Vector3(1.8, 0.6, 2.4), Vector3(0, 1.4, 0.2), "#1a2a50")
	_b(car, Vector3(1.94, 0.25, 4.42), Vector3(0, 0.75, 0), "#1a4ab0")
	_b(car, Vector3(0.6, 0.15, 0.3), Vector3(-0.35, 1.78, 0.2), "#ff2020", true)
	_b(car, Vector3(0.6, 0.15, 0.3), Vector3(0.35, 1.78, 0.2), "#2040ff", true)
	for x in [-0.95, 0.95]:
		for z in [-1.4, 1.4]:
			_b(car, Vector3(0.25, 0.6, 0.6), Vector3(x, 0.3, z), "#111111")
	police_L = OmniLight3D.new()
	police_L.light_color = Color("#ff1010")
	police_L.omni_range = 18
	police_L.position = Vector3(-0.4, 2.2, 0.2)
	car.add_child(police_L)
	police_R = OmniLight3D.new()
	police_R.light_color = Color("#2040ff")
	police_R.omni_range = 18
	police_R.position = Vector3(0.4, 2.2, 0.2)
	car.add_child(police_R)
	road.visible = false
	# --- vězeňská cela ---
	cell = Node3D.new()
	cell.position = Vector3(PX, 0, 0)
	game.add_child(cell)
	_b(cell, Vector3(4, 0.1, 5), Vector3(0, 0, 0), "#3a3a3a")
	_b(cell, Vector3(4, 3, 0.2), Vector3(0, 1.5, -2.5), "#4a4a46")
	_b(cell, Vector3(0.2, 3, 5), Vector3(-2, 1.5, 0), "#464642")
	_b(cell, Vector3(0.2, 3, 5), Vector3(2, 1.5, 0), "#464642")
	_b(cell, Vector3(4, 0.1, 5), Vector3(0, 3, 0), "#2a2a2a")
	_b(cell, Vector3(1.8, 0.45, 0.7), Vector3(-0.9, 0.23, -2.0), "#5a4a3a")
	for i in 11:
		_b(cell, Vector3(0.05, 3, 0.05), Vector3(-1.9 + i * 0.38, 1.5, 2.5), "#555560")
	_b(cell, Vector3(4, 0.08, 0.08), Vector3(0, 1.2, 2.5), "#555560")
	_b(cell, Vector3(4, 4, 0.2), Vector3(0, 2, 6), "#2a2a2c")
	_b(cell, Vector3(0.25, 0.15, 0.25), Vector3(0, 2.92, 0), "#fff3c0", true)
	var bulb = OmniLight3D.new()
	bulb.light_color = Color("#ffe8b0")
	bulb.light_energy = 1.2
	bulb.omni_range = 8
	bulb.position = Vector3(0, 2.7, 0)
	cell.add_child(bulb)
	var hall = OmniLight3D.new()
	hall.light_color = Color("#c0d0ff")
	hall.light_energy = 0.9
	hall.omni_range = 7
	hall.position = Vector3(0, 2.6, 4)
	cell.add_child(hall)
	cell.visible = false
	_build_store()
	# postavy: náčelník Král a moderní D. (z 1. dílu)
	kral = People.person("Král", Color("#1c2a4a"), Color("#141a2a"), Color("#e0b090"), Color("#3a3a3a"), 1.85, true)
	game.add_child(kral.root)
	kral.root.visible = false
	dman = People.person("D.", Color("#77777d"), Color("#26262a"), Color("#ecc4a0"), Color("#222226"), 1.82, false)
	var hd: Node3D = dman.parts.head
	var hb = People._box(Vector3(0.36, 0.2, 0.06), Color("#222226"))
	hb.position = Vector3(0, 0.3, -0.16)
	hd.add_child(hb)
	var vis = People._box(Vector3(0.3, 0.03, 0.08), Color("#222226"))
	vis.position = Vector3(0, 0.37, 0.19)
	hd.add_child(vis)
	game.add_child(dman.root)
	dman.root.visible = false
	# Hollow Bunny v troskách u silnice (ohořelý, z kostiček)
	suit = Hollow.make(true)
	suit.position = Vector3(WX + 0.6, 0, -6.0)
	game.add_child(suit)
	suit.visible = false
	for i in 14:
		_b(road, Vector3(randf_range(0.4, 1.4), randf_range(0.2, 1.0), randf_range(0.4, 1.4)), Vector3(randf_range(-0.5, 3.5), 0.2, randf_range(-24, -19.5)), "#141210")
	var sl = OmniLight3D.new()
	sl.light_color = Color("#ffd090")
	sl.light_energy = 1.0
	sl.omni_range = 6
	sl.position = Vector3(1.4, 3.0, -20)
	road.add_child(sl)

var police_store := []
func _build_store() -> void:
	store = Node3D.new()
	store.position = Vector3(WX, 0, 0)
	game.add_child(store)
	_b(store, Vector3(16, 0.1, 20), Vector3(0, 0, -2), "#2a2a2c")
	_b(store, Vector3(16, 6, 0.3), Vector3(0, 3, -12), "#3a3836")
	for x in [-8, 8]:
		_b(store, Vector3(0.3, 6, 20), Vector3(x, 3, -2), "#36342f")
	_b(store, Vector3(5.5, 6, 0.3), Vector3(-5.25, 3, 8), "#3a3836")
	_b(store, Vector3(5.5, 6, 0.3), Vector3(5.25, 3, 8), "#3a3836")
	_b(store, Vector3(5, 2.2, 0.3), Vector3(0, 4.9, 8), "#3a3836")
	_b(store, Vector3(16, 0.2, 20), Vector3(0, 6, -2), "#1a1a1c")
	# regály s krabicemi „VOXIE'S – PIZZERIE“
	for side in [-1, 1]:
		for i in 4:
			var z = 4 - i * 3.6
			_b(store, Vector3(1.0, 2.6, 3.0), Vector3(6.8 * side, 1.3, z), "#4a3a2a")
			for k in 3:
				_b(store, Vector3(0.8, 0.55, 0.9), Vector3(6.8 * side, 0.4 + k * 0.85, z + randf_range(-0.8, 0.8)), ["#8a6a3a", "#7a5a30", "#9a7a44"][k])
	# automaty z herny
	for i in 4:
		var a = Node3D.new()
		a.position = Vector3(-4.5 + i * 1.1, 0, -10.8)
		store.add_child(a)
		_b(a, Vector3(0.9, 1.9, 0.8), Vector3(0, 0.95, 0), "#1a1626")
		_b(a, Vector3(0.7, 0.5, 0.05), Vector3(0, 1.35, 0.41), ["#ff2bd6", "#7ff4ff", "#ffe46b", "#5dff8a"][i], true)
	# stoly z pizzerie s ubrusem a kloboučky
	for p in [[-3.5, -3.0], [-2.8, 0.8], [3.0, -1.2]]:
		_b(store, Vector3(1.6, 0.06, 1.6), Vector3(p[0], 0.78, p[1]), "#c03030")
		_b(store, Vector3(0.12, 0.75, 0.12), Vector3(p[0], 0.38, p[1]), "#333333")
		for k in 3:
			_b(store, Vector3(0.12, 0.22, 0.12), Vector3(p[0] + (k - 1) * 0.4, 0.92, p[1]), ["#ff6b9a", "#7ff4ff", "#ffe46b"][k])
	# kulisy z pódia, ohořelá cedule a plachta budoucí atrakce
	_b(store, Vector3(4.0, 2.8, 0.1), Vector3(3.0, 1.4, -11.6), "#4a1030")
	_b(store, Vector3(3.2, 0.7, 0.08), Vector3(-2.0, 4.2, -11.8), "#2a0f1a")
	var sv = Label3D.new()
	sv.text = "VOXIE'S"
	sv.font_size = 96
	sv.modulate = Color("#ff8bea")
	sv.position = Vector3(-2.0, 4.2, -11.7)
	store.add_child(sv)
	var fh = Label3D.new()
	fh.text = "FRIGHTS & HIDES\nPŘIPRAVUJEME"
	fh.font_size = 64
	fh.modulate = Color("#ffb030")
	fh.position = Vector3(3.0, 3.6, -11.5)
	store.add_child(fh)
	for z in [-8.0, -2.0, 4.0]:
		_b(store, Vector3(0.4, 0.1, 0.4), Vector3(0, 5.9, z), "#fff3c0", true)
		var L = OmniLight3D.new()
		L.light_color = Color("#ffe0b0")
		L.light_energy = 1.8
		L.omni_range = 9
		L.position = Vector3(0, 5.5, z)
		store.add_child(L)
	for c in [Color("#ff1010"), Color("#2040ff")]:
		var pl = OmniLight3D.new()
		pl.light_color = c
		pl.omni_range = 14
		pl.light_energy = 0.0
		pl.position = Vector3(0, 2.2, 10.5)
		store.add_child(pl)
		police_store.append(pl)
	var sp = SpotLight3D.new()
	sp.light_color = Color("#fff0d0")
	sp.light_energy = 6.0
	sp.spot_range = 9
	sp.spot_angle = 28
	sp.shadow_enabled = true
	store.add_child(sp)
	sp.look_at_from_position(Vector3(1.8, 5.6, -3.0), Vector3(0.6, 0.5, -6.0))
	store.visible = false
	# kaluž krve
	pool = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.01
	cyl.radial_segments = 32
	pool.mesh = cyl
	var pm = StandardMaterial3D.new()
	pm.albedo_color = Color("#7a0808")
	pm.roughness = 0.08
	pm.metallic = 0.2
	pool.material_override = pm
	game.add_child(pool)
	pool.visible = false
	# kapky krve
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = 400
	var q = BoxMesh.new()
	q.size = Vector3(0.05, 0.05, 0.05)
	var bm = StandardMaterial3D.new()
	bm.albedo_color = Color("#6a0606")
	bm.roughness = 0.2
	q.material = bm
	mm.mesh = q
	bl_mm = MultiMeshInstance3D.new()
	bl_mm.multimesh = mm
	game.add_child(bl_mm)
	bl_p.resize(400)
	bl_v.resize(400)
	bl_l.resize(400)

func active() -> bool:
	return game.S == "arrest" or game.S == "prison"

func start_arrest(after_end: int) -> void:
	S = {"k": "arrest", "t": 0.0, "said": 0, "after": after_end, "sirenT": 0.0}
	game.S = "arrest"
	game.scene_t = 0.0
	road.visible = true
	cell.visible = false
	kral.root.visible = false
	game.VOX.visible = false
	game.COC.visible = false
	game.env.fog_depth_end = 40.0

func start_prison() -> void:
	S = {"k": "prison", "t": 0.0, "said": 0, "after": 3, "sirenT": 0.0}
	game.S = "prison"
	game.scene_t = 0.0
	cell.visible = true
	road.visible = false
	kral.root.visible = false
	dman.root.visible = false
	game.VOX.visible = false
	game.COC.visible = false
	game.audio.stop_ambient()
	game.st_set("v2_egg3", true)

func subs() -> Array:
	return ARREST_SUB if S.k == "arrest" else PRISON_SUB

func update(dt: float) -> void:
	S.t += dt
	var t: float = S.t
	var L = subs()
	while S.said < L.size() and t >= L[S.said][0]:
		var s = L[S.said]
		if s[1] != "":
			game.speech = {"who": s[1], "text": s[2], "t": 0.0, "dur": clampf(s[2].length() * 0.065 + 1.6, 3, 8), "heard": true}
			var di = D_LINES.find(s[2])
			if s[1] == "D." and di >= 0:
				game.audio._play(load("res://voice/d_say" + str(di) + ".wav"), 1.0, 0.0)
			else:
				game.audio.sfx("click", 0.4)
		S.said += 1
	if S.k == "arrest":
		if t > 8 and t < 26:
			S.sirenT -= dt
			if S.sirenT <= 0:
				S.sirenT = 3.9
				game.audio.sfx("siren", 0.55)
		if t > 23 and t - dt <= 23:
			game.audio.sfx("cuffs")
			game.audio.sfx("clunk", 0.6)
		if t < 8 and floor(t * 1.8) != floor((t - dt) * 1.8):
			game.audio.sfx("step", 0.12)
		if t > 26.5:
			_finish_arrest()
	else:
		if t > 21.5 and t < 28 and floor(t * 3.2) != floor((t - dt) * 3.2):
			game.audio.sfx("step", 0.3)
		if t > 24.5 and t < 39:
			S.sirenT -= dt
			if S.sirenT <= 0:
				S.sirenT = 3.9
				game.audio.sfx("siren", 0.3)
		for ct in [39.4, 39.9, 40.3, 40.6, 40.9, 41.3, 42.0]:
			if t > ct and t - dt <= ct:
				game.audio.sfx("clunk", 1.2)
				game.audio.sfx("cuffs", 1.0)
		if t > 40.2 and t - dt <= 40.2:
			game.audio.sfx("scare_v", 0.45)
			Input.vibrate_handheld(900)
		if t > 47.5 and t - dt <= 47.5:
			game.audio.sfx("hurt", 0.8)
		if t > 48.0 and randf() < dt * 1.2:
			game.audio.sfx("drip", 0.9)

func _finish_arrest() -> void:
	road.visible = false
	kral.root.visible = false
	game.env.fog_depth_end = 18.0
	game.news_end = S.after
	game.S = "news"
	game.scene_t = 0.0

func end_prison() -> void:
	cell.visible = false
	road.visible = false
	dman.root.visible = false
	kral.root.visible = false
	suit.visible = false
	store.visible = false
	pool.visible = false
	for i in 400:
		bl_l[i] = 0.0
	_blood_tick(0.0)
	game.red_light.light_energy = 0.0
	game.env.fog_depth_end = 18.0
	game.to_menu()

func render(t: float, dt: float) -> void:
	var cam: Camera3D = game.cam
	var st: float = S.t
	var talking_k: bool = game.speech != null and game.speech.who == "Náčelník Král" and game.speech.t < game.speech.dur
	var talking_d: bool = game.speech != null and game.speech.who == "D." and game.speech.t < game.speech.dur
	game.flash.light_energy = 0.0
	game.env.ambient_light_energy = 0.5
	if S.k == "arrest":
		var z = 4.0 - minf(st, 9.0) * 1.1
		var turn = game.ease_io(clampf((st - 9.0) / 1.5, 0, 1))
		cam.position = Vector3(OX + 0.6, 1.62 + (sin(st * 10) * 0.03 if st < 9 else 0.0), z)
		cam.rotation = Vector3(-0.02 + 0.05 * turn, PI * turn, 0)
		var on = st > 8.0
		var ph = int(st * 6) % 2
		police_L.light_energy = (4.0 if ph == 0 else 0.3) if on else 0.0
		police_R.light_energy = (4.0 if ph == 1 else 0.3) if on else 0.0
		# Král vystoupí z auta a dojde k tobě
		kral.root.visible = st > 10.5
		var kz = lerpf(8.0, z + 1.6, clampf((st - 10.5) / 3.0, 0, 1))
		kral.root.position = Vector3(OX + 0.2, 0, kz)
		kral.root.rotation.y = PI
		var walking = st > 10.5 and st < 13.5
		People.animate(kral, t, dt, walking, talking_k, "cuffs" if st > 22.5 else ("point" if st > 12 and st < 15 else ""))
	else:
		var P = Vector3(PX, 0, 0)
		if st < 21.5:
			cam.position = P + Vector3(-0.9, 1.25, -1.6)
			var look = P + Vector3(0, 1.3, 2.5)
			cam.look_at(look)
			cam.rotate_object_local(Vector3.FORWARD, sin(st * 0.4) * 0.01)
			kral.root.visible = st > 4
			kral.root.position = P + Vector3(lerpf(3.0, 0.3, clampf((st - 4) / 2.0, 0, 1)), 0, 3.2)
			kral.root.rotation.y = PI
			People.animate(kral, t, dt, st > 4 and st < 6, talking_k)
			dman.root.visible = false
			cell.visible = true
			road.visible = false
		else:
			_render_store(st, t, dt, talking_d)

## sklad: D. vběhne dovnitř, oblékne Hollow Bunnyho, springlocky selžou (krev, kaluž, umírání)
func _render_store(st: float, t: float, dt: float, talking_d: bool) -> void:
	var cam: Camera3D = game.cam
	cell.visible = false
	road.visible = false
	kral.root.visible = false
	store.visible = true
	suit.visible = true
	var W = Vector3(WX, 0, 0)
	var spos = W + Vector3(0.6, 0, -6.0)
	var ph = int(st * 6) % 2
	police_store[0].light_energy = (3.5 if ph == 0 else 0.3) if st > 24.5 else 0.0
	police_store[1].light_energy = (3.5 if ph == 1 else 0.3) if st > 24.5 else 0.0
	# D. vběhne dveřmi kolem kamery ke kostýmu
	var run = clampf((st - 22.0) / 5.0, 0, 1)
	var into = clampf((st - 35.6) / 1.4, 0, 1)
	var dpos = (W + Vector3(-0.6, 0, 7.5)).lerp(spos + Vector3(0, 0, 1.0), run).lerp(spos, into)
	dman.root.visible = st > 22.0 and st < 37.0
	dman.root.position = dpos
	dman.root.rotation.y = PI if run < 1 else lerp_angle(PI, 0.0, clampf((st - 30.5) / 0.8, 0, 1))
	People.animate(dman, t, dt, (run > 0 and run < 1) or (into > 0 and into < 1), talking_d)
	# kamera: od dveří, pak blíž ke kostýmu
	var cp = (W + Vector3(1.6, 1.62, 6.0)).lerp(spos + Vector3(1.3, 1.45, 3.2), game.ease_io(clampf((st - 27.0) / 3.0, 0, 1)))
	var fail = clampf((st - 39.4) / 3.0, 0, 1)
	var shake = 0.0 if st < 39.4 else (0.25 if st < 44.0 else (0.1 if st < 47.0 else 0.0))
	cam.position = cp + Vector3(randf() - 0.5, randf() - 0.5, 0) * shake * 0.08
	var lk = spos + Vector3(0, 1.1, 0) if st > 26 else dpos + Vector3(0, 1.3, -2)
	if st > 46.5:
		lk = lk.lerp(spos + Vector3(0, 0.25, 0.9), game.ease_io(clampf((st - 46.5) / 2.0, 0, 1)))
	cam.look_at(lk)
	# umírání: křeče → na kolena → pád dopředu
	var knee = game.ease_io(clampf((st - 46.0) / 1.5, 0, 1))
	var fall = game.ease_io(clampf((st - 47.6) / 0.8, 0, 1))
	suit.position = spos + Vector3(randf_range(-1, 1) * shake * 0.12, 0.05 - 0.3 * knee * (1 - fall) + 0.12 * fall, 0)
	suit.rotation = Vector3(randf_range(-1, 1) * shake * 0.25 + 1.45 * fall, randf_range(-1, 1) * shake * 0.6, randf_range(-1, 1) * shake * 0.3)
	var hd: Node3D = suit.get_node("head")
	hd.rotation = Vector3(0.1 + fail * 0.5 + randf_range(-1, 1) * shake, randf_range(-1, 1) * shake * 1.6, 0.05 + fail * 0.35)
	var ch: Node3D = suit.get_node("chest")
	ch.rotation.x = 0.1 + 0.5 * knee
	for an in ["arm_L", "arm_R"]:
		var ar: Node3D = ch.get_node(an)
		ar.rotation.x = -1.4 * fail * (1 - knee) + randf_range(-1, 1) * shake * 2.2 - 0.3 * knee
	for ln in ["leg_L", "leg_R"]:
		var lg: Node3D = suit.get_node(ln)
		lg.rotation.x = -1.2 * knee
		lg.get_node("shin").rotation.x = 1.9 * knee
	# krev: stříká ze švů a kloubů, pod kostýmem roste kaluž
	if st > 39.6 and st < 47.5:
		var rate = 90.0 if st < 44 else 30.0
		for k in int(rate * dt) + (1 if randf() < fmod(rate * dt, 1.0) else 0):
			var src = suit.global_position + Vector3(randf_range(-0.3, 0.3), randf_range(0.7, 1.9), randf_range(0.0, 0.3))
			_spurt(src)
	_blood_tick(dt)
	var pr = clampf((st - 40.5) / 8.0, 0, 1)
	pool.visible = pr > 0
	pool.global_position = Vector3(spos.x, 0.062, spos.z + 0.4 + 0.6 * fall)
	pool.scale = Vector3.ONE * maxf(0.01, pr * 1.6)
	if st > 40.2:
		game.red_light.light_energy = (1.4 if int(st * 10) % 2 == 0 else 0.2) if st < 46 else 0.4
		game.red_light.global_position = spos + Vector3(0.5, 1.9, 1.4)

func _spurt(p: Vector3) -> void:
	var i = bl_i % 400
	bl_i += 1
	bl_p[i] = p
	var a = randf() * TAU
	bl_v[i] = Vector3(cos(a) * randf_range(0.4, 1.6), randf_range(0.5, 2.6), abs(sin(a)) * randf_range(0.4, 1.6))
	bl_l[i] = randf_range(0.5, 1.2)

func _blood_tick(dt: float) -> void:
	var mm = bl_mm.multimesh
	for i in 400:
		if bl_l[i] <= 0:
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * 0.001), Vector3(0, -50, 0)))
			continue
		bl_l[i] -= dt
		var v = bl_v[i]
		v.y -= 9.8 * dt
		var p = bl_p[i] + v * dt
		if p.y < 0.07:
			p.y = 0.07
			v = Vector3.ZERO
			bl_l[i] = minf(bl_l[i], 3.0)
		bl_v[i] = v
		bl_p[i] = p
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1.6, 0.2, 1.6) if p.y <= 0.075 else Vector3.ONE), p))

func draw(h, t: float) -> void:
	var st: float = S.t
	h.vignette(0.7)
	if st < 1.2:
		h.rect(0, 0, h.HW, h.HH, Color(0, 0, 0, 1 - st / 1.2))
	var cur = null
	for s in subs():
		if st >= s[0] and st < s[0] + 3.6:
			cur = s
	if cur:
		h.rr(h.HW / 2 - 400, 600, 800, 64, 10, Color(0, 0, 0, 0.75))
		if cur[1] != "":
			h.txt(cur[1], h.HW / 2 - 384, 620, 14, "#9fd0ff" if cur[1] != "D." else "#ff8080")
		h.txt(cur[2], h.HW / 2, 648, 18, "#ffffff", "center")
	if S.k == "arrest":
		if st > 8 and st < 24:
			h.rect(0, 0, h.HW, h.HH, Color(1, 0, 0, 0.06) if int(st * 6) % 2 == 0 else Color(0, 0.1, 1, 0.06))
		if st > 24.5:
			h.rect(0, 0, h.HW, h.HH, Color(0, 0, 0, clampf((st - 24.5) / 1.5, 0, 1)))
		h.btn(h.HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "askip", _finish_arrest, true, 16)
	else:
		if st > 20.6 and st < 21.6:
			h.rect(0, 0, h.HW, h.HH, Color(0, 0, 0, 1.0 - absf(st - 21.1) * 2))
		if st > 39.4 and st < 46.0:
			h.noise(0.04 + randf() * 0.05)
			if int(st * 14) % 5 == 1:
				h.rect(0, 0, h.HW, h.HH, Color(0.7, 0, 0, 0.18))
		if st > 40.2 and st < 40.28:
			h.rect(0, 0, h.HW, h.HH, Color(0.7, 0, 0, 0.5))
		if st > 51.0:
			h.rect(0, 0, h.HW, h.HH, Color(0, 0, 0, clampf((st - 51.0) / 1.2, 0, 1)))
			if st > 52.4:
				h.neon("EASTER EGG: PRAVDA", h.HW / 2, 300, 46, "#ff3030", 20)
				h.txt("Byl to D. Ty jsi byl jen ten, kdo se měl vrátit na místo činu.", h.HW / 2, 360, 18, "#dddddd", "center")
				h.txt("D. zůstal uvězněný v Hollow Bunnym. Tak vznikl Hollow Hare.", h.HW / 2, 392, 18, "#9fff9f", "center")
				h.txt("Sklad i s ním koupil nový majitel. Za rok tu chce otevřít strašidelnou atrakci: FRIGHTS & HIDES.", h.HW / 2, 424, 16, "#ffb030", "center")
			if st > 54.0:
				h.btn(h.HW / 2 - 150, 470, 300, 54, "MENU", "pmenu", end_prison, true, 20)
		else:
			h.btn(h.HW - 220, 24, 196, 44, "PŘESKOČIT ▶", "pskip", func(): S.t = 51.5, true, 16)
