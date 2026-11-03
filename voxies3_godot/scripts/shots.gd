extends RefCounted
## --shots: náhledy hlavních obrazovek (user://s3_*.png)

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
	await snap(g, "menu")
	g.start_night(1)
	await wait(g, 4.0)
	await snap(g, "arrive1")
	g.scene_t = 9.0
	await wait(g, 1.0)
	await snap(g, "arrive2")
	g.Q.clear()
	g.line = null
	g.scene_t = 13.95
	await wait(g, 1.5)
	for i in 6:
		g._tour_next()
	await wait(g, 1.6)
	await snap(g, "tour_back")
	# kamery
	await play(g, 3)
	g.G.t = 120.0
	g.G.mon = true
	g.G.app = "cam"
	g.G.cam = "04"
	g.G.hare.node = "HALL"
	g.G.hare.path = []
	g.G.hare.wait = 99.0
	g.hare.position = Vector3(-1.0, 0, -2.5)
	await wait(g, 1.0)
	await snap(g, "xp_cam")
	# shadow voxie v kanceláři
	g.G.mon = false
	g.G.hare.node = "BACK"
	g.hare.position = g.NODES.BACK
	g.sys.shadow_vox.visible = true
	g.sys.shadow_vox.position = g.EYE + Vector3(1.4, -1.3, -1.9)
	g.sys.shadow_vox.rotation.y = atan2(-1.4, 1.9)
	g.G.look = -0.6
	await wait(g, 0.6)
	await snap(g, "shadow_office")
	g.sys.shadow_vox.visible = false
	g.G.scareFace = {"who": "vox", "t": 0.8}
	await wait(g, 0.1)
	await snap(g, "shadow_face")
	g.G.scareFace = null
	# chůze: krabice v zákulisí
	g.G.look = 0.0
	g.sys.stand_up()
	g.G.rp.x = 0.0
	g.G.rp.z = -15.2
	g.G.rp.yaw = 0.3
	g.G.hare.wait = 99.0
	g.hare.position = Vector3(0, 0, -21.2)
	await wait(g, 0.8)
	await snap(g, "roam_boxes")
	# vytírání
	await play(g, 4)
	g.sys.stand_up()
	g.G.rp.x = 0.0
	g.G.rp.z = 1.0
	g.G.rp.yaw = 0.0
	g.G.rp.pitch = -0.4
	await wait(g, 0.8)
	await snap(g, "roam_mop")
	# 7. noc: požár a rozpad budovy
	await play(g, 7)
	g.G.t = g.HOUR * 4.2
	g.G.task.done = 1
	g.sys.start_fire()
	g.G.fireT = 30.0
	g.G.colT = 0.0
	await wait(g, 4.0)
	await snap(g, "fire_desk")
	g.sys.stand_up()
	g.G.rp.x = -4.5
	g.G.rp.z = 3.0
	g.G.rp.yaw = 0.0
	await wait(g, 3.0)
	await snap(g, "fire_roam")
	g.start_end7()
	g.scene_t = 3.0
	await wait(g, 0.5)
	await snap(g, "end7_voxie")
	g.scene_t = 8.5
	await wait(g, 0.5)
	await snap(g, "end7_voxie2")
	g.scene_t = 11.0
	await wait(g, 0.5)
	await snap(g, "end7_hare")
	g.scene_t = 17.0
	await wait(g, 0.5)
	await snap(g, "end7_hare2")
	g.scene_t = 29.0
	await wait(g, 1.5)
	await snap(g, "end7")
	g.to_menu()
	g.start_custom()
	await wait(g, 0.3)
	await snap(g, "custom")
	g.start_extras()
	g.ex_i = 3
	await wait(g, 0.8)
	await snap(g, "extras_svox")
	g.ex_i = 5
	await wait(g, 0.8)
	await snap(g, "extras_sd")
	g.get_tree().quit()
