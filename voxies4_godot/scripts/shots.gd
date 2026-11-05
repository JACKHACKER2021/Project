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
	g.build.pt = 3.0
	await wait(g, 0.6)
	await snap(g, "cocoa_ema")
	g.build.done = true
	await wait(g, 0.3)
	g.start_night(2)
	g.begin_play()
	g.Q.clear()
	g.line = null
	g.G.vox.t = 99.0
	g.G.bun.t = 99.0
	g.G.view = "back"
	g.G.light = true
	await wait(g, 1.0)
	await snap(g, "plush")
	g.get_tree().quit()
