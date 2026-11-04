extends RefCounted
## --shots: náhledy (user://s3_*.png)

static func snap(g, name: String) -> void:
	for i in 4:
		await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("user://s3_" + name + ".png")

static func wait(g, s: float) -> void:
	await g.get_tree().create_timer(s).timeout

static func play(g, n: int) -> void:
	g.new_night(n)
	g.begin_play()
	g.G.kroupa = false
	g.kroupa.root.visible = false
	g.Q.clear()
	g.line = null

static func run(g) -> void:
	await wait(g, 0.5)
	g.start_night(3)
	await wait(g, 3.0)
	await snap(g, "memory3")
	# Voxie: zajíc mlátí / kamera ho hlídá
	await play(g, 7)
	g.G.t = 60.0
	g.G.hare.node = "VOXIE"
	g.G.hare.path = []
	g.hare.position = g.NODES.VOXIE
	g.G.vox.called = true
	g.G.mon = true
	g.G.app = "cam"
	g.G.cam = "04"
	await wait(g, 1.2)
	await snap(g, "vox_watched")
	g.G.mon = false
	g.G.look = 0.0
	await wait(g, 1.0)
	g.G.mon = true
	g.G.app = "docs"
	await wait(g, 0.6)
	await snap(g, "docs")
	g.G.mon = false
	# rozpad budovy
	await play(g, 7)
	g.G.t = g.HOUR * 4.2
	g.G.task.done = 1
	g.sys.start_fire()
	g.G.colT = 0.0
	g.sys.stand_up()
	g.G.rp.x = -4.5
	g.G.rp.z = 4.5
	g.G.rp.yaw = 0.0
	await wait(g, 8.0)
	await snap(g, "collapse1")
	await wait(g, 14.0)
	await snap(g, "collapse2")
	g.G.rp.x = 0.0
	g.G.rp.z = 4.0
	await wait(g, 8.0)
	await snap(g, "collapse3")
	g.to_menu()
	g.start_extras()
	g.ex_i = 5
	await wait(g, 0.8)
	await snap(g, "burnt_front")
	await wait(g, 4.0)
	await snap(g, "burnt_side")
	g.ex_lore = true
	await wait(g, 0.3)
	await snap(g, "lore")
	g.get_tree().quit()
