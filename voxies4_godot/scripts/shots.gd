extends RefCounted
static func snap(g, name: String) -> void:
	for i in 4:
		await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("user://s4_" + name + ".png")
static func wait(g, s: float) -> void:
	await g.get_tree().create_timer(s).timeout
static func run(g) -> void:
	await wait(g, 1.0)
	g.start_mini("show", true)
	g.mini.px = 190.0
	await wait(g, 4.55)
	await snap(g, "show_glitch")
	g.start_mini("pit", true)
	g.mini.px = 210.0
	await wait(g, 2.6)
	await snap(g, "pit_lean")
	await wait(g, 2.4)
	await snap(g, "pit_sink")
	await wait(g, 2.5)
	await snap(g, "pit_stare")
	g.mini.done = true
	await wait(g, 0.3)
	g.start_build(true)
	await wait(g, 1.0)
	await snap(g, "build0")
	for i in 4:
		g.build.dx = 12.0
		g.build.act()
		g.build.dx = 18.5
		g.build.act()
	await wait(g, 0.5)
	await snap(g, "build_full")
	g.build.ph = 2
	g.build.pt = 2.5
	await wait(g, 0.8)
	await snap(g, "build_ema")
	g.build.done = true
	await wait(g, 0.3)
	g.start_night(3)
	g.begin_play()
	g.Q.clear()
	g.line = null
	g.G.bun.t = 99.0
	g.G.vox.side = "left"
	g.G.vox.stage = 2
	g.G.vox.open = 0.05
	g.G.view = "left"
	await wait(g, 0.6)
	await snap(g, "door_closed")
	g.G.vox.open = 0.6
	await wait(g, 0.6)
	await snap(g, "arms1")
	await wait(g, 0.7)
	await snap(g, "arms2")
	g.get_tree().quit()
