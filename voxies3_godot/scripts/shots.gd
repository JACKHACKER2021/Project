extends RefCounted
## --shots: náhledy konce 7. noci (user://s3_*.png)
static func snap(g, name: String) -> void:
	for i in 4:
		await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("user://s3_" + name + ".png")
static func wait(g, s: float) -> void:
	await g.get_tree().create_timer(s).timeout
static func run(g) -> void:
	await wait(g, 0.5)
	g.new_night(7)
	g.begin_play()
	g.G.kroupa = false
	g.kroupa.root.visible = false
	g.Q.clear()
	g.line = null
	g.start_end7()
	g.scene_t = 22.0
	await wait(g, 1.5)
	await snap(g, "e7_fire")
	g.scene_t = 29.0
	await wait(g, 1.0)
	await snap(g, "e7_ruins")
	g.scene_t = 33.4
	await wait(g, 1.2)
	await snap(g, "e7_kroupa")
	g.get_tree().quit()
