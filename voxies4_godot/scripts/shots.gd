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
	await snap(g, "menu")
	g.start_night(2)
	g.begin_play()
	g.Q.clear()
	g.line = null
	g.G.vox.t = 99.0
	g.G.bun.t = 99.0
	g.G.t = 50.0
	await wait(g, 0.8)
	await snap(g, "closet")
	# Nightmare Voxie u levých dveří
	g.G.vox.side = "left"
	g.G.vox.stage = 2
	g.G.vox.open = 0.55
	g.G.view = "left"
	await wait(g, 1.2)
	await snap(g, "vox_door")
	g.G.light = true
	await wait(g, 0.5)
	await snap(g, "vox_lit")
	g.G.light = false
	g._repel("vox")
	g.G.vox.t = 99.0
	# Hollow Bunny ve skříni
	g.G.bun.stage = 1
	g.G.bun.open = 0.6
	g.G.view = "closet"
	await wait(g, 1.2)
	g.G.light = true
	await wait(g, 0.3)
	await snap(g, "bun_lit")
	g.G.light = false
	g._repel("bun")
	g.G.bun.t = 99.0
	g.G.view = "back"
	g.G.flash = 0.3
	await wait(g, 1.0)
	g.G.flash = 0.11
	await wait(g, 0.02)
	await snap(g, "bed_flash")
	g.G.view = "right"
	g.G.vox.side = "right"
	g.G.vox.stage = 2
	g.G.vox.open = 0.9
	await wait(g, 1.0)
	g.jumpscare("vox")
	await wait(g, 0.45)
	await snap(g, "scare")
	await wait(g, 2.4)
	await snap(g, "dead")
	g.get_tree().quit()
