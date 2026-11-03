extends Node2D
## obrazovka počítače na stole (VOXIE-CAM v2) + bootování v úvodní scéně
var game
var acc := 0.0
func _process(d: float) -> void:
	acc += d
	if acc > (0.04 if game.S == "boot" else 0.2):
		acc = 0.0
		queue_redraw()
func _draw() -> void:
	var G = game.G
	var f: Font = game.hud.font if game.hud else ThemeDB.fallback_font
	var out: bool = G != null and G.out
	draw_rect(Rect2(0, 0, 256, 192), Color("#010101") if out else Color("#031208"))
	if out:
		return
	var c := Color("#5dff8a")
	if game.S == "boot":
		var t: float = game.scene_t
		if t < 19.2:
			draw_rect(Rect2(0, 0, 256, 192), Color("#000000"))
			return
		if t < 19.9:
			# zapnutí CRT: světlá čára se roztáhne do obrazu
			var k = (t - 19.2) / 0.7
			draw_rect(Rect2(0, 0, 256, 192), Color("#000000"))
			var hh = maxf(2.0, 192 * k * k)
			draw_rect(Rect2(128 - 128 * minf(1, k * 3), 96 - hh / 2, 256 * minf(1, k * 3), hh), Color(0.8, 1, 0.85, 1 - k * 0.6))
			return
		if t < 20.6:
			draw_rect(Rect2(0, 0, 256, 192), Color("#000080"))
			draw_string(f, Vector2(52, 100), "Windows 98", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
			return
		var lines = ["VOXIE BIOS 1.97", "MEM ....... 640K OK", "BATERIE ... 100%", "CAM 1A..9 . TEST", "  2 5 8 .... OK", "  ostatni .. ERR", "VOXIE-CAM v2 > _"]
		var n = mini(lines.size(), int((t - 20.6) * 1.6) + 1)
		for i in n:
			draw_string(f, Vector2(12, 26 + i * 24), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, c)
		return
	draw_string(f, Vector2(20, 40), "VOXIE-CAM v2", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)
	draw_string(f, Vector2(20, 80), ("BATERIE " + str(ceili(G.bat)) + "%") if G else "STANDBY", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)
	if sin(game.t_now * 3) > 0:
		draw_string(f, Vector2(20, 120), "_", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, c)
