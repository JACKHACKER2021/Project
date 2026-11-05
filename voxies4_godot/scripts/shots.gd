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
	await snap(g, "menu")
	g.start_night(1)
	g.mini.px = 190.0
	await wait(g, 4.5)
	await snap(g, "m_show")
	g.start_mini("hide")
	g.mini.px = 192.0
	g.mini.act()
	g.mini.pt = 7.4
	await wait(g, 0.3)
	await snap(g, "m_hide_scare")
	await wait(g, 1.5)
	await snap(g, "m_hide_ask")
	g.start_mini("pit")
	g.mini.px = 150.0
	await wait(g, 1.0)
	await snap(g, "m_pit")
	g.start_mini("shutdown")
	g.mini.px = 180.0
	await wait(g, 3.0)
	await snap(g, "m_shutdown")
	g.mini.done = true
	await wait(g, 0.2)
	g.to_menu()
	g.start_d4(true)
	await wait(g, 2.5)
	await snap(g, "d4")
	g.end_scene()
	g.start_extras()
	g.ex_i = 0
	await wait(g, 1.0)
	await snap(g, "ex_vox")
	g.ex_i = 1
	await wait(g, 1.0)
	await snap(g, "ex_bun")
	g.ex_page = "scenes"
	await wait(g, 0.3)
	await snap(g, "ex_scenes")
	g.get_tree().quit()
