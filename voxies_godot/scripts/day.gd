extends Node
## Denní směny (Den 1–7) a návštěva D. v 5 AM poslední noci.
## D. = bývalý noční hlídač, teď přes den správce herny. Přátelský.

const Rig := preload("res://scripts/rig.gd")
var game
var npcs = {}            # jméno -> {rig, parts, moving}
var room_lights = []
var held: Node3D
var held_cake: Node3D
var held_pizza: Node3D
var held_mop: Node3D
var props = []           # dočasné předměty dne (dorty, skvrny, bedny…)
var eyeC = []            # světla v očích Cocoy
var S = {}               # stav dne
const D_COL := Color("#9fd0ff")
const K_COL := Color("#ffe46b")

const KIDS := [["Anička", Color("#ff6b6b"), Vector3(-19, 0, -16.9)], ["Tomáš", Color("#6bb2ff"), Vector3(-15, 0, -11.9)], ["Ella", Color("#7cff6b"), Vector3(-12, 0, -14.4)]]

# ---------------------------------------------------------------- stavba
func setup() -> void:
	for id in game.ROOMS:
		var r: Dictionary = game.ROOMS[id]
		var l = OmniLight3D.new()
		l.light_color = Color("#fff4dc")
		l.omni_range = maxf(r.x1 - r.x0, r.z1 - r.z0) * 0.95
		l.light_energy = 3.0
		l.position = Vector3((r.x0 + r.x1) / 2.0, r.get("h", game.H) - 0.3, (r.z0 + r.z1) / 2.0)
		l.visible = false
		game.add_child(l)
		room_lights.append(l)
	npcs["D."] = _person("D.", Color("#77777d"), Color("#26262a"), Color("#ecc4a0"), Color("#222226"), 1.82, false)
	for k in KIDS:
		npcs[k[0]] = _person(k[0], k[1], Color("#333344"), Color("#f0c8a0"), Color("#6a4020"), 1.15, false)
	for n in npcs.values():
		n.rig.root.visible = false
	held = Node3D.new()
	game.roam_cam.add_child(held)
	held.position = Vector3(0.32, -0.38, -0.62)
	held_cake = make_cake()
	held.add_child(held_cake)
	held_pizza = game.place_model("res://models/nove/pizza_cela.glb", 0.05, Vector3.ZERO, 0, held)
	held_pizza.scale *= 0.8
	held_mop = Node3D.new()
	var stick = _box(Vector3(0.04, 1.2, 0.04), Color("#8a6a3a"))
	stick.position = Vector3(0, 0.1, 0)
	held_mop.add_child(stick)
	var head = _box(Vector3(0.3, 0.12, 0.12), Color("#3a7aff"))
	head.position = Vector3(0, -0.5, -0.1)
	held_mop.add_child(head)
	held_mop.rotation = Vector3(0.5, 0, -0.3)
	held.add_child(held_mop)
	_hold("")
	for i in 2:
		var l = OmniLight3D.new()
		l.light_color = Color("#bfe8ff")
		l.omni_range = 0.45
		l.light_energy = 0.0
		game.add_child(l)
		eyeC.append(l)

func _box(sz: Vector3, c: Color) -> MeshInstance3D:
	var m = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = sz
	m.mesh = b
	var mat = StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.7
	m.material_override = mat
	return m

## kostičková postava (D. a děti) ve stylu herny
func _person(nm: String, shirt: Color, pants: Color, skin: Color, hair: Color, h: float, cap: bool) -> Dictionary:
	var rig = Rig.new()
	rig.name = nm
	rig.root = Node3D.new()
	game.add_child(rig.root)
	var k = h / 1.82
	var body = Node3D.new()
	body.scale = Vector3.ONE * k
	rig.root.add_child(body)
	var parts = {}
	for s in [-1, 1]:
		var leg = Node3D.new()
		leg.position = Vector3(0.12 * s, 0.85, 0)
		var lm = _box(Vector3(0.18, 0.85, 0.2), pants)
		lm.position = Vector3(0, -0.42, 0)
		leg.add_child(lm)
		body.add_child(leg)
		parts["leg" + str(s)] = leg
		var arm = Node3D.new()
		arm.position = Vector3(0.32 * s, 1.45, 0)
		var am = _box(Vector3(0.14, 0.62, 0.16), shirt)
		am.position = Vector3(0, -0.3, 0)
		arm.add_child(am)
		var hand = _box(Vector3(0.13, 0.13, 0.13), skin)
		hand.position = Vector3(0, -0.66, 0)
		arm.add_child(hand)
		body.add_child(arm)
		parts["arm" + str(s)] = arm
	var torso = _box(Vector3(0.5, 0.62, 0.28), shirt)
	torso.position = Vector3(0, 1.17, 0)
	body.add_child(torso)
	var headn = Node3D.new()
	headn.position = Vector3(0, 1.5, 0)
	body.add_child(headn)
	var hd = _box(Vector3(0.34, 0.36, 0.32), skin)
	hd.position = Vector3(0, 0.2, 0)
	headn.add_child(hd)
	var hr = _box(Vector3(0.36, 0.1, 0.34), hair)
	hr.position = Vector3(0, 0.4, -0.01)
	headn.add_child(hr)
	if nm == "D.":
		# D.: tmavé krátké vlasy s čepicí nad čelem, šedé tričko (jako v Extras)
		var hb = _box(Vector3(0.36, 0.2, 0.06), hair)
		hb.position = Vector3(0, 0.3, -0.16)
		headn.add_child(hb)
		var vis = _box(Vector3(0.3, 0.03, 0.08), hair)
		vis.position = Vector3(0, 0.37, 0.19)
		headn.add_child(vis)
	var lids = []
	for s in [-1, 1]:
		var e = _box(Vector3(0.05, 0.05, 0.02), Color("#111111"))
		e.position = Vector3(0.08 * s, 0.24, 0.165)
		headn.add_child(e)
		# víčko: při mrknutí překryje oko
		var lid = _box(Vector3(0.062, 0.062, 0.02), skin)
		lid.position = Vector3(0.08 * s, 0.24, 0.172)
		lid.visible = false
		headn.add_child(lid)
		lids.append(lid)
	# pusa: tmavá dutina, která se při mluvení otevírá
	var mouth = Node3D.new()
	mouth.position = Vector3(0, 0.1, 0.168)
	var mo = _box(Vector3(0.12, 0.03, 0.02), Color("#3a1010"))
	mouth.add_child(mo)
	var lip = _box(Vector3(0.13, 0.012, 0.022), Color("#8a4a3a"))
	lip.position = Vector3(0, 0.017, 0)
	mouth.add_child(lip)
	headn.add_child(mouth)
	parts.head = headn
	parts.mouth = mo
	parts.lids = lids
	parts.body = body
	if cap:
		var c1 = _box(Vector3(0.38, 0.1, 0.36), Color("#1a2a5a"))
		c1.position = Vector3(0, 0.44, 0)
		headn.add_child(c1)
		var c2 = _box(Vector3(0.3, 0.03, 0.16), Color("#1a2a5a"))
		c2.position = Vector3(0, 0.4, 0.24)
		headn.add_child(c2)
		var badge = _box(Vector3(0.08, 0.08, 0.02), Color("#ffe46b"))
		badge.position = Vector3(-0.12, 1.32, 0.15)
		body.add_child(badge)
		var mus = _box(Vector3(0.18, 0.04, 0.02), Color("#4a4a4a"))
		mus.position = Vector3(0, 0.14, 0.17)
		headn.add_child(mus)
	return {"rig": rig, "parts": parts, "blink": randf_range(1, 4), "look": 0.0, "lookT": 0.0, "hop": 0.0, "kid": h < 1.5, "pose": "", "walkT": 0.0, "a": {"path": null, "seg": 0, "speed": 1.6, "endYaw": 0.0}}

func make_cake() -> Node3D:
	var c = Node3D.new()
	var base = MeshInstance3D.new()
	var cy = CylinderMesh.new()
	cy.top_radius = 0.2
	cy.bottom_radius = 0.2
	cy.height = 0.14
	base.mesh = cy
	var m = StandardMaterial3D.new()
	m.albedo_color = Color("#ff8bea")
	base.material_override = m
	c.add_child(base)
	var top = MeshInstance3D.new()
	var cy2 = CylinderMesh.new()
	cy2.top_radius = 0.205
	cy2.bottom_radius = 0.205
	cy2.height = 0.03
	top.mesh = cy2
	var m2 = StandardMaterial3D.new()
	m2.albedo_color = Color("#fff6f0")
	top.material_override = m2
	top.position.y = 0.08
	c.add_child(top)
	for i in 3:
		var cd = _box(Vector3(0.02, 0.08, 0.02), Color("#ffffff"))
		cd.position = Vector3(cos(i * 2.1) * 0.1, 0.13, sin(i * 2.1) * 0.1)
		c.add_child(cd)
		var fl = _box(Vector3(0.025, 0.035, 0.025), Color("#ffb000"))
		(fl.material_override as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fl.position = cd.position + Vector3(0, 0.06, 0)
		c.add_child(fl)
	return c

func _hold(what: String) -> void:
	held_cake.visible = what == "cake"
	held_pizza.visible = what == "pizza"
	held_mop.visible = what == "mop"
	S["hold"] = what

func _spawn(n: Node3D, pos: Vector3) -> Node3D:
	game.add_child(n)
	n.position = pos
	props.append(n)
	return n

func clear_props() -> void:
	for p in props:
		if is_instance_valid(p):
			p.queue_free()
	props.clear()

# ---------------------------------------------------------------- start / konec dne
func start_day(n: int) -> void:
	game.audio.stop_menu_song()
	game.new_game(n)
	var G = game.G
	G.day = n
	G.rep = null
	game.rep_apply_visuals()
	G.task = null
	G.sys = null
	G.coc.broken = false
	G.call.on = false
	G.pzTimes = []
	G.vox.off = true
	G.coc.off = true
	G.vox.pos = "1A"
	G.coc.pos = "m1A"
	game.set_spot(game.VOX, "1A")
	game.set_spot(game.COC, "m1A")
	game.COC.root.visible = true
	game.axe_mesh.visible = false
	G.dinter = []
	if game.INTER.is_empty():
		game.INTER = game.T.INTER
		game.WORK = game.T.WORK.duplicate(true)
	S = {"n": n, "i": -1, "lines": [], "lt": 0.0, "wait": 0.0, "multi": [], "song": false, "hold": "", "done": false, "msg": ""}
	_hold("")
	clear_props()
	for nm in npcs:
		npcs[nm].rig.root.visible = false
	_set_day_look(true)
	game.scene_ = "play"
	game.scene_t = 0.0
	game.audio.start_ambient()
	game.roam.on = false
	game.toggle_roam()
	game.roam.flash = false
	game.hint("DEN " + str(n) + " · denní směna v herně Voxie's")
	_setup_people(n)
	_next()

func _set_day_look(on: bool) -> void:
	for l in room_lights:
		l.visible = on
	game.hemi_amb = 1.1 if on else 0.55
	game.env.fog_enabled = not on

func end_day_scene() -> void:
	_set_day_look(false)
	_hold("")
	clear_props()
	for nm in npcs:
		npcs[nm].rig.root.visible = false
	game.audio.stop_music_box()
	game.audio.stop_ambient()
	game.roam_reset()

func after_day(n: int) -> void:
	game.st_set("voxies_day", maxi(game.st_get("voxies_day", 0), n))
	if game.T.MINIS.has(str(n)):
		game.hud.start_mini(n)
	else:
		game.new_game(n)

func _setup_people(n: int) -> void:
	var dpos = {1: Vector3(-14.2, 0, -19.4), 2: Vector3(-13.2, 0, -12.8), 3: Vector3(2.2, 0, -21.2), 4: Vector3(-3.0, 0, -14.5), 5: Vector3(1.4, 0, 1.8), 6: Vector3(-13.2, 0, -12.8), 7: Vector3(-15.0, 0, 2.0)}
	_place("D.", dpos[n], PI)
	if n == 2 or n == 6:
		for k in KIDS:
			_place(k[0], k[2], PI)
	if n == 4:
		game.COC.root.visible = false

func _place(nm: String, p: Vector3, yaw: float) -> void:
	var r: Rig = npcs[nm].rig
	npcs[nm].pose = ""
	r.root.visible = true
	r.root.position = p
	r.root.rotation.y = yaw

func walk_npc(nm: String, to: Vector3) -> void:
	var N: Dictionary = npcs[nm]
	var r: Rig = N.rig
	N.a.path = game.nav_path(r.root.position, to)
	N.a.seg = 1
	N.a.endYaw = r.root.rotation.y

# ---------------------------------------------------------------- scénáře dnů
func script(n: int) -> Array:
	match n:
		1:
			return [
				{"t": "say", "l": [["D.", "Ahoj, ty jsi ten nový? Já jsem D. Dřív jsem tu hlídal v noci, teď dělám přes den správce."], ["D.", "Dneska máme objednanou oslavu. Pomůžeš mi upéct dort? Recept visí v kuchyni u pece."]]},
				{"t": "do", "id": "d_recipe", "x": -16, "z": -20.3, "label": "🧾 PŘEČÍST RECEPT", "need": 0, "task": "Přečti recept v Pizzerii (CAM 2)", "msg": "Recept: korpus, krém, růžová poleva a tři svíčky. Jako na oslavě v roce 1997."},
				{"t": "do", "id": "d_mix", "x": -15, "z": -13, "label": "🥣 UMÍCHAT TĚSTO", "need": 6, "task": "Umíchej těsto u stolu v Pizzerii"},
				{"t": "do", "id": "d_bake", "x": -20, "z": -17, "label": "🔥 DÁT KORPUS DO PECE", "need": 0, "task": "Dej korpus do pece", "fx": "oven"},
				{"t": "wait", "s": 15, "task": "Korpus se peče…", "fx": "baking"},
				{"t": "do", "id": "d_take", "x": -20, "z": -17, "label": "🍰 VYNDAT KORPUS", "need": 0, "task": "Vyndej korpus z pece", "fx": "hold_cake"},
				{"t": "do", "id": "d_decor", "x": -15, "z": -13, "label": "🎂 OZDOBIT DORT", "need": 6, "task": "Ozdob dort u stolu", "fx": "cake_on_table"},
				{"t": "say", "l": [["D.", "Ten je krásnej! Voxie by byl pyšnej. Kdysi takový dorty rozdával sám."], ["D.", "Zítra ho dáme dětem. Teď si odpočiň, v noci tě čeká hlídání."]]},
			]
		2:
			var s = [{"t": "say", "l": [["D.", "Děti jsou tady! Vezmi dort ze stolu v Pizzerii a rozdej ho. Každý dostane kousek."], ["Anička", "Jééé, dort! Bude i Voxie?"]]}]
			var i = 0
			for k in KIDS:
				s.append({"t": "do", "id": "d_cake" + str(i), "x": -15, "z": -13, "label": "🍰 VZÍT DORT", "need": 0, "task": "Vezmi dort ze stolu (" + str(i) + "/3)", "fx": "hold_cake"})
				s.append({"t": "do", "id": "d_kid" + str(i), "x": k[2].x, "z": k[2].z + 0.9, "r": 1.6, "label": "🎂 DÁT DORT: " + k[0].to_upper(), "need": 0, "task": "Dej dort: " + k[0], "fx": "give", "say": [k[0], ["Děkuju! Je růžovej jako Voxieho motýlek!", "Mňam! Můžu si pak sáhnout na Cocou?", "Ten je nejlepší! Děkuju, pane hlídači!"][i]]})
				i += 1
			s.append({"t": "say", "l": [["D.", "Vidíš ty úsměvy? Kvůli tomuhle tu herna kdysi byla."], ["Tomáš", "Pane D., proč Voxiemu nesvítí oči jako v reklamě?"], ["D.", "…Svítí. Jenom v noci."]]})
			return s
		3:
			return [
				{"t": "say", "l": [["D.", "Dneska testujeme animatroniky. Majitel chce vědět, jestli ještě zvládnou show."], ["D.", "Ovládací panel je vpravo u pódia. Pusť písničku a sleduj je."]]},
				{"t": "do", "id": "d_panel", "x": 3.6, "z": -22.6, "r": 2.0, "label": "🎛 SPUSTIT TEST SHOW", "need": 0, "task": "Spusť test show u pódia (CAM 1A)", "fx": "song"},
				{"t": "song", "task": "Test show: sleduj Voxieho a Cocou"},
				{"t": "say", "l": [["D.", "Fungujou… Oči svítí, pohyby sedí."], ["D.", "Jen… Voxie se na mě celou dobu díval. Jako by mě poznal."]]},
			]
		4:
			var boxes = [Vector3(18.5, 0, -8.2), Vector3(20.6, 0, -4.2), Vector3(12.2, 0, -8.4)]
			var s = [{"t": "say", "l": [["D.", "Dneska uklidíme sklad. Bedny k regálu, ať se tam dá projít."], ["D.", "Já zatím dojdu pro Cocou do bludiště, potřebuje kontrolu."]]}, {"t": "fx", "fx": "boxes", "pts": boxes}]
			for i in 3:
				s.append({"t": "do", "id": "d_box" + str(i), "x": boxes[i].x, "z": boxes[i].z, "label": "📦 SROVNAT BEDNU", "need": 3, "task": "Srovnej bedny ve skladu (" + str(i) + "/3)", "fx": "box_done"})
			s.append({"t": "fx", "fx": "argue_setup"})
			s.append({"t": "do", "id": "d_listen", "x": 15.5, "z": -3.4, "r": 3.2, "label": "👂 POSLOUCHAT", "need": 0, "task": "Někdo se hádá u prototypu… jdi blíž"})
			s.append({"t": "say", "l": [["Cocoa", "Pusťte mě do té kanceláře! Pan Vojtěch je pořád uvnitř!"], ["D.", "Cocoo, nech toho. Ta místnost zůstane zamčená. Kvůli všem."], ["Cocoa", "Vy jste tu tenkrát byl! Vy jste utekl s klíčem!"], ["D.", "Nesahej na ten zámek! …Cocoo, ne!"]]})
			s.append({"t": "fx", "fx": "zap"})
			s.append({"t": "say", "l": [["Cocoa", "Zzzt… au… p-proč… jste… to… udělal…"], ["D.", "To jsem nechtěl. Chytil jsem ji za ruku a ono to jiskřilo… Já jsem to nechtěl."], ["D.", "Nic jsi neviděl, jasný? Zítra ti všechno vysvětlím. Slibuju."]]})
			return s
		5:
			return [
				{"t": "say", "l": [["D.", "Pojď za mnou do kanceláře. Dlužím ti vysvětlení."]]},
				{"t": "do", "id": "d_sit", "x": 0, "z": 1.8, "r": 1.8, "label": "🪑 POSADIT SE K D.", "need": 0, "task": "Jdi do kanceláře za D."},
				{"t": "say", "l": [["D.", "Voxie's Fun Factory otevřel pan Vojtěch v devadesátém třetím. Medvěd z kostiček byl jeho nápad."], ["D.", "Voxie nebyl robot. Byl to oblek s pružinovými zámky. Pan Vojtěch v něm sám vystupoval."], ["D.", "V devadesát sedmém přibyla Cocoa. Nejmodernější robot široko daleko. Děti ji milovaly."], ["D.", "Čtrnáctého června byla oslava. Zhasla světla. Zámky obleku cvakly. A já držel klíč od kanceláře."], ["D.", "Utekl jsem. Celý roky jsem si to vyčítal. Proto jsem se vrátil – tentokrát přes den."], ["D.", "Včera s Cocou… to byla nehoda. Chtěla otevřít kancelář. Tam je vypínač obleku."], ["D.", "Až přijde poslední noc, přijdu za tebou. Tentokrát tě tu nenechám."]]},
			]
		6:
			var s = [{"t": "say", "l": [["D.", "Další oslava! Dneska dostanou děti pizzu. Pec už je rozpálená."], ["Ella", "Pizza! A bude Cocoa tancovat?"]]}]
			var i = 0
			for k in KIDS:
				s.append({"t": "do", "id": "d_pz" + str(i), "x": -20, "z": -17, "label": "🍕 VZÍT PIZZU Z PECE", "need": 2, "task": "Vezmi pizzu z pece (" + str(i) + "/3)", "fx": "hold_pizza"})
				s.append({"t": "do", "id": "d_pk" + str(i), "x": k[2].x, "z": k[2].z + 0.9, "r": 1.6, "label": "🍕 DÁT PIZZU: " + k[0].to_upper(), "need": 0, "task": "Dej pizzu: " + k[0], "fx": "give_pizza", "say": [k[0], ["Ta voní! Děkuju!", "Je tam srdíčko z kečupu! Jako Voxie speciál!", "Mňam. Pane hlídači, vy tu budete i v noci?"][i]]})
				i += 1
			s.append({"t": "say", "l": [["D.", "Děti se ptaly, jestli Voxie zase vystoupí. Řekl jsem, že možná."], ["D.", "Zítra je poslední den. Odpočiň si."]]})
			return s
		7:
			var spots = [Vector3(-5, 0, -4), Vector3(5, 0, -8), Vector3(0, 0, -15), Vector3(-6, 0, -19), Vector3(6, 0, -14), Vector3(-15, 0, -6), Vector3(-17, 0, -15), Vector3(1, 0, -6.5)]
			var s = [{"t": "say", "l": [["D.", "Poslední den. Majitel chce, aby se tu všechno lesklo."], ["D.", "Tady máš mop. Vytři ty skvrny na podlaze – chodby, herna, pizzerie."]]}, {"t": "fx", "fx": "dirt", "pts": spots}]
			var m = []
			for i in spots.size():
				m.append({"id": "d_dirt" + str(i), "x": spots[i].x, "z": spots[i].z, "r": 1.4, "label": "🧽 VYTŘÍT SKVRNU", "need": 2.5})
			s.append({"t": "multi", "items": m, "task": "Vytři skvrny"})
			s.append({"t": "say", "l": [["D.", "Hotovo. Takhle čistý to tu nebylo od devadesátýho sedmýho."], ["D.", "Poslouchej. Dneska v noci, v pět ráno, budu u tebe. Nebudeš tu sám."]]})
			return s
	return []

# ---------------------------------------------------------------- průběh
func _cur():
	var sc = script(S.n)
	return sc[S.i] if S.i >= 0 and S.i < sc.size() else null

func _next() -> void:
	var G = game.G
	S.i += 1
	G.dinter = []
	var st = _cur()
	if st == null:
		_finish()
		return
	match st.t:
		"say":
			S.lines = st.l.duplicate()
			_say_next()
		"do":
			_add_inter(st)
		"wait":
			S.wait = st.s
			_fx(st.get("fx", ""), st)
		"fx":
			_fx(st.fx, st)
			_next()
		"multi":
			S.multi = []
			for it in st.items:
				S.multi.append(it.id)
				_add_inter(it)
		"song":
			S.song = true
			S.songT = 0.0
			game.audio.start_music_box()

func _add_inter(st: Dictionary) -> void:
	var it = {"id": st.id, "x": st.x, "z": st.z, "r": st.get("r", 1.8), "label": st.label}
	game.G.dinter.append(it)
	game.WORK[st.id] = {"need": st.get("need", 0), "x": st.x, "z": st.z, "label": st.label.substr(2)}

func _say_next() -> void:
	if S.lines.is_empty():
		game.speech = null
		_next()
		return
	var l = S.lines.pop_front()
	var who: String = l[0]
	var text: String = l[1]
	var dur = clampf(text.length() * 0.065 + 1.6, 3.0, 9.0)
	var col = D_COL if who == "D." else (Color("#ffc9a0") if who == "Cocoa" else K_COL)
	var key = "C|" + text
	if who == "Cocoa" and game.AUD.voice.has(key):
		dur = maxf(dur, game.audio.voice(key, 0.6, 0.0, false))
	else:
		game.audio.sfx("click")
	game.speech = {"who": who, "text": text, "t": 0.0, "dur": dur, "col": col, "heard": true}
	S.lt = dur

func task_text() -> String:
	var st = _cur()
	if st == null:
		return ""
	if st.t == "multi":
		return "🧽 " + st.task + " (" + str(st.items.size() - S.multi.size()) + "/" + str(st.items.size()) + ")"
	if st.t == "say":
		return "💬 Poslouchej"
	if st.t == "wait":
		return "⏳ " + st.task + " " + str(ceili(S.wait)) + " s"
	return "📋 " + st.get("task", "")

func on_inter(i: Dictionary) -> void:
	var W: Dictionary = game.WORK[i.id]
	if W.need > 0:
		game.G.work = {"id": i.id, "prog": 0.0}
		game.hint("Zůstaň na místě…")
	else:
		on_work_done(i.id)

func on_work_done(id: String) -> void:
	var G = game.G
	var st = _cur()
	if st == null:
		return
	if st.t == "multi":
		S.multi.erase(id)
		G.dinter = G.dinter.filter(func(x): return x.id != id)
		for p in props:
			if is_instance_valid(p) and p.get_meta("id", "") == id:
				p.visible = false
		game.audio.sfx("found")
		if S.multi.is_empty():
			_next()
		return
	if st.t != "do" or st.id != id:
		return
	if st.has("msg"):
		game.hint(st.msg)
	if st.has("say"):
		game.speech = {"who": st.say[0], "text": st.say[1], "t": 0.0, "dur": 4.0, "col": K_COL, "heard": true}
	_fx(st.get("fx", ""), st)
	game.audio.sfx("work_done")
	_next()

func _fx(fx: String, st: Dictionary) -> void:
	match fx:
		"oven":
			game.hint("Korpus je v peci.")
		"hold_cake":
			_hold("cake")
		"hold_pizza":
			_hold("pizza")
		"cake_on_table":
			_hold("")
			_spawn(make_cake(), Vector3(-15, 0.83, -13))
		"give", "give_pizza":
			var p: Node3D = make_cake() if fx == "give" else game.place_model("res://models/nove/pizza_cela.glb", 0.05, Vector3.ZERO, 0)
			if fx != "give":
				p.get_parent().remove_child(p)
			_hold("")
			_spawn(p, Vector3(st.x, 0.83, st.z - 0.6))
		"boxes":
			var i = 0
			for p in st.pts:
				var b = _box(Vector3(0.7, 0.55, 0.6), Color("#8a6a3a"))
				b.set_meta("id", "d_box" + str(i))
				_spawn(b, p + Vector3(0, 0.28, 0))
				i += 1
		"box_done":
			for p in props:
				if is_instance_valid(p) and p.get_meta("id", "") == st.id:
					p.position = Vector3(21.3, 0.28 + 0.56 * int(st.id.right(1)), -2.9)
		"argue_setup":
			game.COC.root.visible = true
			game.COC.root.position = Vector3(14.9, 0, -5.4)
			game.COC.root.rotation.y = PI / 2
			_place("D.", Vector3(15.75, 0, -5.4), -PI / 2)
			npcs["D."].pose = "argue"
			game.hint("Ze skladu je slyšet hádka…")
		"zap":
			game.spark_burst(game.COC.root.position + Vector3(0, 1.0, 0), 50, 1.3)
			game.glitch_flash(0.6)
			S.zap = 2.5
			npcs["D."].pose = "grab"
			game.say_later(1.2, func(): npcs["D."].pose = "argue")
		"dirt":
			var i = 0
			for p in st.pts:
				var q = MeshInstance3D.new()
				var pm = PlaneMesh.new()
				pm.size = Vector2(1.1, 0.9)
				q.mesh = pm
				var m = StandardMaterial3D.new()
				m.albedo_color = Color(0.15, 0.1, 0.05, 0.75)
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				q.material_override = m
				q.rotation.y = randf() * TAU
				q.set_meta("id", "d_dirt" + str(i))
				_spawn(q, p + Vector3(0, 0.02, 0))
				i += 1
			_hold("mop")
		"baking":
			pass

func _finish() -> void:
	S.done = true
	game.speech = null
	game.G.dinter = []
	end_day_scene()
	game.scene_ = "dayend"
	game.scene_t = 0.0
	game.audio.sfx("chime")

# ---------------------------------------------------------------- update (volá game.update)
func update(dt: float) -> void:
	var G = game.G
	G.t += dt
	G.power = 100.0
	if S.lt > 0:
		S.lt -= dt
		if S.lt <= 0:
			_say_next()
	if S.wait > 0:
		S.wait -= dt
		game.oven_mouth.light_energy = (8.0 if sin(G.t * 6) > 0 else 5.0) * game.LK
		if S.wait <= 0:
			game.audio.sfx("oven_ding", -0.4)
			_next()
	if S.get("zap", 0.0) > 0:
		S.zap -= dt
		if randf() < dt * 6:
			game.spark_burst(game.COC.root.position + Vector3(0, 1.0, 0), 8, 0.6)
	if S.song:
		S.songT += dt
		if not game.audio.music_box.playing and S.songT > 1.0:
			S.song = false
			_next()
	game.roam_update(dt)
	_npc_update(dt)

func _npc_update(dt: float) -> void:
	var tt: float = game.t_now
	for nm in npcs:
		var N: Dictionary = npcs[nm]
		var r: Rig = N.rig
		if not r.root.visible:
			continue
		var P: Dictionary = N.parts
		var moving: bool = N.a.path != null
		if moving:
			game.walk_step(N.a, r, dt)
			N.walkT += dt * (9.0 if N.kid else 7.0)
		var sw = sin(N.walkT) * 0.5 if moving else 0.0
		var talking: bool = game.speech != null and game.speech.who == nm and game.speech.t < game.speech.dur
		var ph: float = float(nm.hash() % 100) * 0.37
		# dýchání a lehké přešlapování, aby nestáli jako sochy
		P.body.position.y = sin(tt * 1.8 + ph) * 0.012 + (absf(sin(N.walkT)) * 0.03 if moving else 0.0)
		P.body.rotation.z = sin(tt * 0.9 + ph) * 0.02
		P["leg-1"].rotation.x = sw
		P["leg1"].rotation.x = -sw
		var gest = 0.0
		if talking:
			gest = sin(tt * 3.1 + ph) * 0.35
		var aL: float = -sw * 0.8 + sin(tt * 1.8 + ph) * 0.04
		var aR: float = sw * 0.8 - sin(tt * 1.8 + ph) * 0.04
		if not moving and talking:
			aL = -0.5 - absf(gest) * 0.8
			aR = -0.2 + gest * 0.5
		P["arm-1"].rotation.x = aL
		P["arm1"].rotation.x = aR
		P["arm-1"].rotation.z = -0.06
		P["arm1"].rotation.z = 0.06
		match N.pose:
			"grab":
				P["arm-1"].rotation.x = -1.5
				P["arm1"].rotation.x = -1.5
				P["arm-1"].rotation.z = 0.25
				P["arm1"].rotation.z = -0.25
			"rip":
				P["arm-1"].rotation.x = -1.9 + sin(tt * 30) * 0.1
				P["arm1"].rotation.x = -1.9 - sin(tt * 30) * 0.1
				P["arm-1"].rotation.z = 0.35
				P["arm1"].rotation.z = -0.35
			"pour":
				P["arm1"].rotation.x = -1.1
				P["arm-1"].rotation.x = -0.9
		# děti poskakují radostí
		if N.kid and not moving:
			N.hop -= dt
			if N.hop <= 0:
				N.hop = randf_range(2.5, 6.0)
			if N.hop > 0 and N.hop < 0.35:
				P.body.position.y += sin(N.hop / 0.35 * PI) * 0.12
		# pusa: otevírá se podle slabik
		var open_k = 0.0
		if talking:
			open_k = absf(sin(tt * 13.0 + ph)) * (0.6 + 0.4 * absf(sin(tt * 5.3)))
		P.mouth.scale = Vector3(1.0 - open_k * 0.2, 1.0 + open_k * 3.0, 1.0)
		P.mouth.position.y = -open_k * 0.03
		# mrkání
		N.blink -= dt
		var closed: bool = N.blink < 0.12
		if N.blink <= 0:
			N.blink = randf_range(2.0, 5.0)
		for l in P.lids:
			l.visible = closed
		# hlava: rozhlížení, při mluvení kývání a otočení k hráči
		N.lookT -= dt
		if N.lookT <= 0:
			N.lookT = randf_range(1.5, 4.0)
			N.look = randf_range(-0.5, 0.5)
		var to: Vector3 = game.roam_cam.global_position - r.root.global_position
		var near: bool = to.length() < 6.0
		var want_head = N.look
		if near or talking:
			want_head = clampf(wrapf(atan2(to.x, to.z) - r.root.rotation.y, -PI, PI), -0.9, 0.9)
		P.head.rotation.y = lerp_angle(P.head.rotation.y, want_head, minf(1, dt * 5))
		P.head.rotation.x = (sin(tt * 9) * 0.06 if talking else 0.0) + sin(tt * 0.7 + ph) * 0.03
		if talking and not moving and N.pose == "":
			r.root.rotation.y = lerp_angle(r.root.rotation.y, atan2(to.x, to.z), minf(1, dt * 3))

## tanec při testu show + svítící oči Cocoy (volá game.render)
func render_extra(t: float) -> void:
	var G = game.G
	var dance: bool = G != null and G.get("day", 0) == 3 and S.get("song", false)
	if dance:
		game.VOX.root.position.y = 0.6 + absf(sin(t * 4.2)) * 0.12
		game.VOX.root.rotation.y = sin(t * 2.1) * 0.5
		game.COC.root.position.y = 0.6 + absf(sin(t * 4.2 + 1.5)) * 0.1
		game.COC.root.rotation.y = -sin(t * 2.1) * 0.5
	# oči Cocoy: světla před očima (atlas má oči na hlavě, svítí jen tam)
	var on: bool = game.COC.root.visible and game.scene_ in ["play", "extras", "menu", "scare"] and (G == null or not G.coc.broken)
	var head = game.COC.joints.get("head")
	if head == null:
		return
	var hp: Vector3 = game.COC.wpos(head)
	var b: Basis = game.COC.root.global_transform.basis.orthonormalized()
	for i in 2:
		var l: OmniLight3D = eyeC[i]
		l.visible = on
		l.global_position = hp + b.y * 0.28 + b.z * 0.33 + b.x * (0.11 if i == 0 else -0.11)
		l.light_energy = (1.4 if dance else 0.5) * (0.0 if (G != null and G.out) else 1.0)
