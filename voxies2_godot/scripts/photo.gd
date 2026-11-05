extends Node2D
## stará vybledlá fotka (Vojtěch, Ema, Cocoa) – kreslená pixelově
var idx := 0
func _draw() -> void:
	draw_rect(Rect2(0, 0, 160, 200), Color("#e8e0cc"))
	draw_rect(Rect2(10, 10, 140, 150), Color("#3a2a24"))
	var bg = [Color("#4a2050"), Color("#6a3a2a"), Color("#2a3a5a")][idx]
	draw_rect(Rect2(14, 14, 132, 142), bg)
	var R = func(x, y, w, h, c): draw_rect(Rect2(x, y, w, h), c)
	# muž (Vojtěch)
	if idx != 1:
		R.call(40, 50, 26, 26, Color("#e0b090")); R.call(38, 44, 30, 10, Color("#4a2a14")); R.call(46, 60, 4, 4, Color.BLACK); R.call(56, 60, 4, 4, Color.BLACK)
		R.call(34, 78, 38, 50, Color("#2a4a8a")); R.call(38, 128, 12, 24, Color("#1a1a2a")); R.call(56, 128, 12, 24, Color("#1a1a2a"))
	# dívka (Ema)
	R.call(96, 76, 22, 22, Color("#f0c8a0")); R.call(92, 70, 30, 10, Color("#c08040")); R.call(102, 84, 3, 3, Color.BLACK); R.call(110, 84, 3, 3, Color.BLACK)
	R.call(92, 98, 30, 34, Color("#ff6b9a")); R.call(96, 132, 8, 20, Color("#3a2a3a")); R.call(110, 132, 8, 20, Color("#3a2a3a"))
	if idx == 1:
		# Cocoa vedle Emy
		R.call(30, 26, 10, 30, Color("#f0b0c8")); R.call(50, 26, 10, 30, Color("#f0b0c8")); R.call(26, 54, 38, 30, Color("#f0b0c8")); R.call(34, 64, 6, 6, Color("#3a1a2a")); R.call(50, 64, 6, 6, Color("#3a1a2a"))
		R.call(24, 84, 42, 50, Color("#e090b0"))
		R.call(118, 112, 22, 18, Color("#ff8bea")); R.call(126, 106, 3, 6, Color("#ffd040"))
	if idx == 2:
		R.call(14, 14, 132, 18, Color("#2a0f3a"))
		draw_string(ThemeDB.fallback_font, Vector2(46, 28), "VOXIE'S", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#ffb030"))
	draw_rect(Rect2(14, 14, 132, 142), Color(0.6, 0.45, 0.2, 0.18))
	var cap = ["Pódium 1996", "Emy 9. narozeniny", "Táta, Ema a já"][idx]
	draw_string(ThemeDB.fallback_font, Vector2(14, 184), cap, HORIZONTAL_ALIGNMENT_LEFT, 132, 14, Color("#3a2a1a"))
