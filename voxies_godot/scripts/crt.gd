extends Node2D
## obrazovka VOXIE-OS na monitoru v kanceláři (drawCRT)
var game
var acc := 0.0

func _process(d: float) -> void:
	acc += d
	if acc > 0.25:
		acc = 0.0
		queue_redraw()

func _draw() -> void:
	var G = game.G
	var out: bool = G != null and G.out
	draw_rect(Rect2(0, 0, 256, 192), Color("#010201") if out else Color("#0b2a14"))
	if G and not out:
		var f: Font = game.crt_font
		var c := Color("#5dff8a")
		for l in [["VOXIE-OS 2.0", 50], ["NOC " + str(G.night), 90], ["PROUD " + str(maxi(0, ceili(G.power))) + "%", 130], ["_" if sin(Time.get_ticks_msec() / 300.0) > 0 else " ", 165]]:
			var w := f.get_string_size(l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
			draw_string(f, Vector2(128 - w / 2, l[1]), l[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, c)
