extends RefCounted
## automatické snímky pro kontrolu (spouští se s -- --shots)
static func shot(g, n: String) -> void:
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("user://shot_" + n + ".png")
static func w(g, s: float) -> void:
	await g.get_tree().create_timer(s).timeout
static func run(g) -> void:
	await w(g, 2.0)
	await shot(g, "menu")
	g.new_game(1)
	g.start_boot()
	await w(g, 5.0)
	await shot(g, "boot_a")
	g.scene_t = 19.5
	await w(g, 0.15)
	await shot(g, "boot_on")
	g.scene_t = 23.0
	await w(g, 0.6)
	await shot(g, "boot_b")
	g.new_game(2)
	g.begin_play()
	await w(g, 1.0)
	await shot(g, "desk")
	g.G.look = 0.0
	g.G.vox.i = g.ROUTE.size() - 1
	g.G.vox.path = g.vox_path()
	g.G.vox.rx = g.RROOMS.TY.cx
	g.G.vox.rz = g.RROOMS.TY.z0 - 0.35
	g.G.vox.path = []
	g.G.flash = true
	await w(g, 0.6)
	await shot(g, "hole")
	g.G.flash = false
	g.G.vox.i = 0
	g.G.vox.rx = g.RROOMS["1A"].cx
	g.G.vox.rz = g.RROOMS["1A"].cz - 1
	g.G.coc.t = 0.0
	g.G.look = 0.9
	await w(g, 0.8)
	await shot(g, "cocoa")
	g.toggle_mon()
	g.G.online = ["8", "5", "2", "1A", "1B"]
	g.G.cam = "1B"
	await w(g, 1.0)
	await shot(g, "cams")
	g.toggle_mon()
	await w(g, 0.4)
	g.leave_desk()
	g.G.rp.yaw = 0.0
	await w(g, 0.6)
	await shot(g, "roam_office")
	g.G.rp.x = 0.0
	g.G.rp.z = g.RROOMS["6"].cz
	g.G.rp.yaw = PI
	await w(g, 0.6)
	await shot(g, "toilets")
	g.G.rp.x = 0.0
	g.G.rp.z = g.RROOMS["1B"].cz
	g.G.rp.yaw = 0.0
	g.G.inv = ["head", "photo0", "can"]
	await w(g, 0.6)
	await shot(g, "herna")
	g.hud.inv_open = true
	await w(g, 0.3)
	await shot(g, "inv")
	g.grab("head")
	await w(g, 13.0)
	g.hud.inspect = {"id": "head"}
	await w(g, 0.4)
	await shot(g, "inspect")
	g.hud.inv_open = false
	g.hud.inspect = null
	g.jumpscare("V")
	await w(g, 0.5)
	await shot(g, "scare")
	g.start_home()
	await w(g, 7.0)
	await shot(g, "home")
	g.hud.start_mini(3)
	await w(g, 1.5)
	await shot(g, "mini")
	g.S = "extras"
	g.hud.EX.page = "chars"
	await w(g, 1.0)
	await shot(g, "extras")
	g.hud.EX.idx = 1
	await w(g, 1.0)
	await shot(g, "extras_c")
	g.get_tree().quit()
