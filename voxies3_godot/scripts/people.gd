extends RefCounted
## Kostičkové postavy z 1. dílu (moderní D., náčelník Král): pusa, mrkání, gesta, chůze.

static func _box(sz: Vector3, c: Color) -> MeshInstance3D:
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
static func person(nm: String, shirt: Color, pants: Color, skin: Color, hair: Color, h: float, cap: bool) -> Dictionary:
	var root = Node3D.new()
	root.name = nm
	var k = h / 1.82
	var body = Node3D.new()
	body.scale = Vector3.ONE * k
	root.add_child(body)
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
	return {"root": root, "parts": parts, "blink": randf_range(1, 4), "look": 0.0, "lookT": 0.0, "hop": 0.0, "kid": h < 1.5, "pose": "", "walkT": 0.0, "a": {"path": null, "seg": 0, "speed": 1.6, "endYaw": 0.0}}


## animace: chůze (walk 0..1), mluvení (pusa + gesta), mrkání, pozice rukou
static func animate(N: Dictionary, t: float, dt: float, moving: bool, talking: bool, pose := "") -> void:
	var P: Dictionary = N.parts
	if moving:
		N.walkT += dt * 9.0
	var sw = sin(N.walkT) * 0.6 if moving else 0.0
	P.body.position.y = sin(t * 1.8) * 0.012 + (absf(sin(N.walkT)) * 0.04 if moving else 0.0)
	P["leg-1"].rotation.x = sw
	P["leg1"].rotation.x = -sw
	var aL = -sw * 0.8
	var aR = sw * 0.8
	if talking and not moving:
		aL = -0.5 - absf(sin(t * 3.1)) * 0.3
		aR = -0.2 + sin(t * 3.1) * 0.25
	match pose:
		"grab":
			aL = -1.5
			aR = -1.5
		"cuffs":
			aL = -0.9
			aR = -0.9
		"point":
			aR = -1.55
	P["arm-1"].rotation.x = aL
	P["arm1"].rotation.x = aR
	var open_k = absf(sin(t * 13.0)) * (0.6 + 0.4 * absf(sin(t * 5.3))) if talking else 0.0
	if pose == "scream":
		open_k = 1.6
	P.mouth.scale = Vector3(1.0 - open_k * 0.2, 1.0 + open_k * 3.0, 1.0)
	P.mouth.position.y = -open_k * 0.03
	N.blink -= dt
	if N.blink <= 0:
		N.blink = randf_range(2.0, 5.0)
	for l in P.lids:
		l.visible = N.blink < 0.12
	P.head.rotation.x = sin(t * 9) * 0.06 if talking else 0.0
