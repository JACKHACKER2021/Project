extends Node
## Easter egg „Po zavíračce" (po konci 7. noci):
##  A) hraješ za Voxieho (uvnitř pan Vojtěch) – D. lije v kanceláři benzín, zkusíš ho zastavit → ERROR + BSOD
##  B) hraješ za Cocou (uvnitř Ema) – Voxie leží na zemi, za tebou stojí D. → utrhne hlavu → ERROR + BSOD
##  C) požár herny a to, jak tě D. podvedl

const Rig := preload("res://scripts/rig.gd")
var game
var day
var E = {}
var can: Node3D
var puddle: MeshInstance3D

func setup() -> void:
	can = Node3D.new()
	var b = day._box(Vector3(0.22, 0.3, 0.12), Color("#c01818"))
	can.add_child(b)
	var sp = day._box(Vector3(0.04, 0.12, 0.04), Color("#222222"))
	sp.position = Vector3(0.08, 0.2, 0)
	sp.rotation.z = -0.6
	can.add_child(sp)
	can.visible = false
	game.add_child(can)
	puddle = MeshInstance3D.new()
	var pm = PlaneMesh.new()
	pm.size = Vector2(1, 1)
	puddle.mesh = pm
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.35, 0.3, 0.12, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.metallic = 0.6
	m.roughness = 0.05
	puddle.material_override = m
	puddle.visible = false
	game.add_child(puddle)

func active() -> bool:
	return game.G != null and game.G.get("egg", "") != ""

# ---------------------------------------------------------------- start částí
func _base(part: String) -> void:
	game.audio.stop_menu_song()
	game.new_game(7)
	var G = game.G
	G.egg = part
	G.rep = null
	game.rep_apply_visuals()
	G.task = null
	G.sys = null
	G.call.on = false
	G.pzTimes = []
	G.vox.off = true
	G.coc.off = true
	G.coc.broken = false
	G.dinter = []
	G.out = false
	game.axe_mesh.visible = false
	for nm in day.npcs:
		day.npcs[nm].rig.root.visible = false
	day.clear_props()
	day._hold("")
	game.scene_ = "play"
	game.scene_t = 0.0
	game.audio.start_ambient()
	game.roam.on = false
	game.toggle_roam()
	game.roam.flash = true
	game.speech = null
	E = {"part": part, "t": 0.0, "ph": "walk", "phT": 0.0, "lines": [], "lt": 0.0, "fall": 0.0}
	puddle.visible = false
	can.visible = false

func start() -> void:
	game.st_set("voxies_egg", true)
	_base("voxie")
	var G = game.G
	game.roam.eye = 1.9
	game.roam.pos = Vector3(0, 1.6, -21.0)
	game.roam.yaw = PI
	game.COC.root.visible = true
	game.set_spot(game.COC, "m1A")
	day._place("D.", Vector3(2.4, 0, -1.6), -PI / 2)
	day.npcs["D."].pose = "pour"
	can.visible = true
	puddle.visible = true
	puddle.position = Vector3(1.4, 0.02, -1.4)
	puddle.scale = Vector3.ONE * 0.4
	game.hint("Jsi pan Vojtěch – uvnitř Voxieho. Z kanceláře je cítit benzín… Jdi tam levou chodbou.")
	G.dinter = [{"id": "e_stop", "x": 2.0, "z": -1.2, "r": 2.6, "label": "✋ ZASTAVIT D."}]
	game.WORK["e_stop"] = {"need": 0, "x": 2.0, "z": -1.2, "label": "Zastavit D."}

func start_cocoa() -> void:
	_base("cocoa")
	game.roam.eye = 1.55
	game.roam.pos = Vector3(0, 1.6, -14.6)
	game.roam.yaw = 0.0
	game.VOX.root.visible = true
	game.hint("Teď jsi Ema – uvnitř Cocoy. Voxie leží na zemi a nehýbe se…")
	day._place("D.", Vector3(0.2, 0, -12.9), PI)
	day.npcs["D."].rig.root.visible = false
	E.ph = "look"

# ---------------------------------------------------------------- akce
func on_inter(i: Dictionary) -> void:
	if i.id == "e_stop" and E.ph == "walk":
		game.G.dinter = []
		E.ph = "slam"
		E.phT = 0.0
		day.npcs["D."].pose = "grab"
		can.visible = false
		_say("D.", "Ale ale, pane Vojtěchu. Tentokrát mi nikam neutečete.")
		game.audio.sfx("sting")

func _say(who: String, text: String) -> void:
	var dur = clampf(text.length() * 0.065 + 1.6, 3.0, 9.0)
	game.speech = {"who": who, "text": text, "t": 0.0, "dur": dur, "col": Color("#9fd0ff") if who == "D." else Color("#ffc9a0"), "heard": true}
	game.audio.sfx("click")

func _bsod(kind: String) -> void:
	game.speech = null
	game.audio.stop_ambient()
	game.audio.sfx("sl_glitch")
	game.hud.bsod = {"kind": kind, "t": 0.0}
	game.scene_ = "bsod"
	game.scene_t = 0.0
	game.roam.eye = 1.6

func after_bsod(kind: String) -> void:
	if kind == "voxie":
		start_cocoa()
	else:
		_end_day()

func _end_day() -> void:
	game.G = {"night": 7, "egg": ""}
	for nm in day.npcs:
		day.npcs[nm].rig.root.visible = false
	game.roam_reset()
	game.audio.sfx("powerdown")
	game.hud.news_secret = "egg"
	game.scene_ = "eggend"
	game.scene_t = 0.0

# ---------------------------------------------------------------- update
func update(dt: float) -> void:
	var G = game.G
	E.t += dt
	E.phT += dt
	G.t += dt
	G.power = 100.0
	if game.speech:
		game.speech.t += 0.0
	if E.part == "voxie":
		_upd_voxie(dt)
	else:
		_upd_cocoa(dt)
	if E.ph in ["walk", "look"]:
		game.roam_update(dt)
	day._npc_update(dt)

func _upd_voxie(dt: float) -> void:
	var D: Dictionary = day.npcs["D."]
	var dr: Node3D = D.rig.root
	if E.ph == "walk":
		# kanystr v ruce D., kaluž roste
		can.global_position = dr.global_position + dr.global_transform.basis.z * 0.45 + Vector3(0, 1.0, 0)
		can.rotation = Vector3(0, dr.rotation.y, 1.2 + sin(E.t * 2) * 0.1)
		puddle.scale = Vector3.ONE * minf(3.2, 0.4 + E.t * 0.05)
		var near = Vector2(game.roam.pos.x - 2.0, game.roam.pos.z + 1.2).length()
		if near < 9 and not E.get("said1", false):
			E.said1 = true
			_say("D.", "Pane Vojtěchu… pořád v tom obleku, co? Herna zítra skončí. Pojišťovna zaplatí.")
			game.say_later(6.0, func(): if E.ph == "walk": _say("D.", "A vinu ponese ten nový hlídač. Ten hodnej kluk, co sem chodí přes den."))
	elif E.ph == "slam":
		# D. přiskočí, chytí tě a praští s tebou o zem
		var to = Vector3(game.roam.pos.x, 0, game.roam.pos.z) - dr.position
		if to.length() > 0.9:
			dr.position += to.normalized() * minf(to.length() - 0.9, dt * 4.5)
			dr.rotation.y = atan2(to.x, to.z)
		if E.phT > 1.6 and E.fall == 0.0:
			E.fall = 0.001
			game.audio.sfx("hit")
			game.audio.sfx("clank")
			game.glitch_flash(1.0)
			Input.vibrate_handheld(400)
		if E.fall > 0:
			E.fall = minf(1.0, E.fall + dt * 2.2)
		if E.phT > 3.4:
			_bsod("voxie")

func _upd_cocoa(dt: float) -> void:
	var D: Dictionary = day.npcs["D."]
	var dr: Node3D = D.rig.root
	if E.ph == "look":
		# hráč se otočí (nebo po chvíli) → za zády stojí D.
		var fwd = -game.roam_cam.global_transform.basis.z
		var to = (dr.global_position + Vector3(0, 1.5, 0)) - game.roam_cam.global_position
		if E.phT > 3.0 and not dr.visible:
			dr.visible = true
			D.pose = ""
		if dr.visible and (fwd.dot(to.normalized()) > 0.75 or E.phT > 18):
			E.ph = "talk"
			E.phT = 0.0
			E.lines = ["Ema. Tak tady ses schovala. Celou dobu v tom králíkovi.", "Měla jsi zůstat zticha. Tenkrát i dneska.", "Pan Vojtěch už nikomu nepomůže. A ty taky ne."]
			E.lt = 0.01
			game.audio.sfx("sting")
	elif E.ph == "talk":
		var to = Vector3(game.roam.pos.x, 0, game.roam.pos.z) - dr.position
		if to.length() > 0.85:
			dr.position += to.normalized() * minf(to.length() - 0.85, dt * 0.6)
		E.lt -= dt
		if E.lt <= 0:
			if E.lines.is_empty():
				E.ph = "rip"
				E.phT = 0.0
				D.pose = "grab"
				game.speech = null
			else:
				var l: String = E.lines.pop_front()
				_say("D.", l)
				E.lt = game.speech.dur
	elif E.ph == "rip":
		if E.phT > 0.6 and D.pose != "rip":
			D.pose = "rip"
			game.audio.sfx("zkrat")
			game.audio.sfx("hit")
			game.spark_burst(game.roam_cam.global_position - Vector3(0, 0.2, 0), 40, 1.0)
			Input.vibrate_handheld(600)
		if E.phT > 0.6:
			E.fall = minf(1.0, E.fall + dt * 1.1)
		if E.phT > 3.2:
			_bsod("cocoa")

## tělo hráče (Voxie/Cocoa) a pohled kamery – volá game.render po nastavení kamer
func render_extra(t: float) -> void:
	if not active():
		return
	var R: Dictionary = game.roam
	var me: Rig = game.VOX if E.part == "voxie" else game.COC
	var moving: bool = R.joy != null or R.keys.values().has(true)
	if E.ph in ["walk", "look"]:
		# vlastní tělo pod kamerou: když se podíváš dolů, vidíš ho
		me.root.visible = true
		me.root.position = Vector3(R.pos.x, 0, R.pos.z) + Vector3(sin(R.yaw), 0, cos(R.yaw)) * (0.25 if E.part == "voxie" else 0.6)
		me.root.rotation = Vector3(0, R.yaw + PI, 0)
		me.C.look = 0.0
		me.pose(t, "walk" if moving else "idle", 0.0)
		_hide_head(me)
		if E.part == "cocoa":
			# Cocoa má obří uši – v pohledu z očí by zakryly obraz, tělo jen schováme
			me.root.visible = false
	if E.part == "cocoa":
		# Voxie leží mrtvý na zemi
		game.VOX.root.visible = true
		game.VOX.root.position = Vector3(0.3, 0.25, -17.2)
		game.VOX.root.rotation = Vector3(-PI / 2, 0.4, 0)
		game.VOX.pose(t, "broken", 0.0)
		for m in game.vox_eyes:
			m.albedo_color = Color("#111111")
		game.eye_light.light_energy = 0.0
	if E.fall > 0:
		var k = E.fall * E.fall * (3 - 2 * E.fall)
		var cam: Camera3D = game.roam_cam
		var base = Vector3(R.pos.x, R.get("eye", 1.6), R.pos.z)
		if E.part == "voxie":
			# pád na zem
			cam.position = base.lerp(Vector3(R.pos.x, 0.25, R.pos.z), k) + Vector3(randf() - 0.5, randf() - 0.5, 0) * 0.08 * (1 - k)
			cam.rotation = Vector3(R.pitch + 0.9 * k, R.yaw, 1.3 * k)
		else:
			# utržená hlava: nahoru, roztočit, spadnout vedle těla
			var up = sin(minf(1, k * 1.6) * PI) * 0.5
			cam.position = base + Vector3(0.6 * k, up - 1.3 * k, 0.3 * k)
			cam.rotation = Vector3(R.pitch - 0.6 * k, R.yaw + 3.5 * k, 1.6 * k)
			_show_head(me)

func _hide_head(me: Rig) -> void:
	var h = me.joints.get("head")
	if h == null:
		return
	if h.has("n"):
		(h.n as Node3D).visible = false
	else:
		(h.sk as Skeleton3D).set_bone_pose_scale(h.i, Vector3.ONE * 0.001)

func _show_head(me: Rig) -> void:
	var h = me.joints.get("head")
	if h != null and h.has("n"):
		(h.n as Node3D).visible = true

func reset_bodies() -> void:
	var h = game.VOX.joints.get("head")
	if h != null and h.has("n"):
		(h.n as Node3D).visible = true
	game.VOX.root.rotation = Vector3.ZERO
	puddle.visible = false
	can.visible = false
