extends RefCounted
## --shots: náhledy hlavních obrazovek (user://s3_*.png)

static func snap(g, name: String) -> void:
	for i in 4:
		await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	g.get_viewport().get_texture().get_image().save_png("user://s3_" + name + ".png")

static func run(g) -> void:
	await g.get_tree().create_timer(0.5).timeout
	await snap(g, "menu")
	g.start_night(1)
	await g.get_tree().create_timer(4.0).timeout
	await snap(g, "arrive1")
	g.scene_t = 9.5
	await g.get_tree().create_timer(0.6).timeout
	await snap(g, "arrive2")
	g.scene_t = 13.95
	await g.get_tree().create_timer(2.0).timeout
	await snap(g, "tour_lobby")
	for i in 2:
		g._tour_next()
	await g.get_tree().create_timer(1.6).timeout
	await snap(g, "tour_voxie")
	for i in 4:
		g._tour_next()
	await g.get_tree().create_timer(1.6).timeout
	await snap(g, "tour_back")
	g._tour_next()
	await g.get_tree().create_timer(3.0).timeout
	await snap(g, "tour_office")
	g.new_night(3)
	g.begin_play()
	g.G.kroupa = false
	g.kroupa.root.visible = false
	g.G.t = 120.0
	await g.get_tree().create_timer(0.6).timeout
	await snap(g, "desk")
	g.G.mon = true
	g.G.app = "word"
	g.G.typed = 90
	await g.get_tree().create_timer(0.8).timeout
	await snap(g, "xp_word")
	g.G.app = "cam"
	g.G.cam = "04"
	g.G.hare.node = "HALL"
	g.G.hare.path = []
	g.G.hare.wait = 99.0
	g.hare.position = Vector3(-1.0, 0, -3.0)
	await g.get_tree().create_timer(0.8).timeout
	await snap(g, "xp_cam")
	g.G.app = "mail"
	await g.get_tree().create_timer(0.3).timeout
	await snap(g, "xp_mail")
	g.G.mon = false
	g.G.hare.node = "DOOR"
	g.G.hare.at = -99.0
	g.G.dl = true
	g.G.look = g.LOOK_DOOR
	g.G.san = 30.0
	await g.get_tree().create_timer(1.0).timeout
	await snap(g, "door_sick")
	g.G.san = 30.0
	g.G.hare.at = 0.0
	g.jumpscare()
	await g.get_tree().create_timer(0.4).timeout
	await snap(g, "scare1")
	await g.get_tree().create_timer(1.3).timeout
	await snap(g, "scare2")
	await g.get_tree().create_timer(1.4).timeout
	await snap(g, "scare3")
	g.to_menu()
	g.start_extras()
	await g.get_tree().create_timer(0.8).timeout
	await snap(g, "extras")
	g.new_night(4)
	g.begin_play()
	g.G.kroupa = false
	g.kroupa.root.visible = false
	g.G.hare.node = "BACK"
	g.hare.position = g.NODES.BACK
	g.G.hare.path = []
	g.G.hare.wait = 99.0
	g.G.san = 0.5
	await g.get_tree().create_timer(1.8).timeout
	await snap(g, "collapse")
	g.get_tree().quit()
