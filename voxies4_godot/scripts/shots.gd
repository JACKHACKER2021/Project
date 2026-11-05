extends RefCounted
## --shots: náhledy (user://s4_*.png)
static func snap(g, name: String) -> void:
	for i in 4:
		await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("user://s4_" + name + ".png")
static func wait(g, s: float) -> void:
	await g.get_tree().create_timer(s).timeout
static func run(g) -> void:
	await wait(g, 1.0)
	g.start_night(3)
	g.begin_play()
	g.Q.clear()
	g.line = null
	g.G.bun.t = 99.0
	g.G.vox.side = "left"
	g.G.vox.stage = 2
	g.G.vox.open = 0.6
	g.G.vox.t = 0.0
	g.G.view = "left"
	await wait(g, 1.0)
	await snap(g, "eyes")
	g.G.light = true
	await wait(g, 1.6)
	await snap(g, "flinch")
	g.G.light = false
	await wait(g, 0.5)
	g.G.vox.side = "right"
	g.G.vox.stage = 2
	g.G.vox.open = 0.95
	g.G.vox.t = 0.0
	g.G.view = "closet"
	await wait(g, 1.0)
	g.jumpscare("vox")
	await wait(g, 0.2)
	await snap(g, "leap1")
	await wait(g, 0.35)
	await snap(g, "leap2")
	await wait(g, 2.5)
	g.start_night(7)
	await wait(g, 3.0)
	await snap(g, "d7_back")
	g.Q.clear()
	g.line = null
	g.G.d7t = 3.0
	await wait(g, 1.0)
	await snap(g, "d7_turn")
	await wait(g, 1.1)
	await snap(g, "d7_flash")
	await wait(g, 2.0)
	await snap(g, "d7_nm")
	g.get_tree().quit()
