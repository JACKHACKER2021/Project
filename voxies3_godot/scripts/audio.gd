extends Node
## Zvuk NaV2: efekty a hlas pana Vojtěcha jsou předrenderované z původního syntezátoru Remasteru.

var game
var AUD: Dictionary
var cache = {}
var ambient: AudioStreamPlayer
var menu: AudioStreamPlayer
const PANS = [-1.0, -0.6, -0.3, 0.0, 0.3, 0.6, 1.0]

func _ready() -> void:
	AUD = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio.json"))
	for p in PANS:
		var i = AudioServer.bus_count
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, "pan" + str(p))
		AudioServer.set_bus_send(i, "Master")
		if p != 0.0:
			var e = AudioEffectPanner.new()
			e.pan = p
			AudioServer.add_bus_effect(i, e)
	ambient = AudioStreamPlayer.new()
	var s: AudioStreamWAV = _stream("res://sfx/ambient.wav").duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = int(s.get_length() * s.mix_rate)
	ambient.stream = s
	add_child(ambient)
	menu = AudioStreamPlayer.new()
	var ms = load("res://audio/menu.mp3")
	if ms is AudioStreamMP3:
		ms.loop = true
	menu.stream = ms
	add_child(menu)

func _bus(pan: float) -> String:
	var best = 0.0
	var bd = 9.0
	for p in PANS:
		if absf(p - pan) < bd:
			bd = absf(p - pan)
			best = p
	return "pan" + str(best)

func _stream(path: String) -> AudioStream:
	if not cache.has(path):
		cache[path] = load(path)
	return cache[path]

func _play(stream: AudioStream, vol: float, pan: float) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = linear_to_db(maxf(0.0001, vol))
	p.bus = _bus(pan)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p

## vol = poměr k nahrané hlasitosti
func sfx(name: String, vol := 1.0, pan := 0.0) -> void:
	if not ResourceLoader.exists("res://sfx/" + name + ".wav"):
		return
	_play(_stream("res://sfx/" + name + ".wav"), clampf(vol, 0.02, 2.5), pan)

## hlas: vrací délku v sekundách
func voice(text: String, vol := 0.55, pan := 0.0) -> float:
	var v = AUD.voice.get(text)
	if v == null:
		sfx("click", 0.5)
		return clampf(text.length() * 0.07, 2.0, 8.0)
	_play(_stream("res://voice/" + v.f), vol / 0.9, pan)
	return v.dur

func start_ambient() -> void:
	if not ambient.playing:
		ambient.play()
func stop_ambient() -> void:
	ambient.stop()
func start_menu_song() -> void:
	if menu.playing:
		return
	menu.volume_db = -40
	menu.play()
	create_tween().tween_property(menu, "volume_db", linear_to_db(0.8), 1.5)
func stop_menu_song() -> void:
	if menu.playing:
		var t = create_tween()
		t.tween_property(menu, "volume_db", -40.0, 0.5)
		t.tween_callback(menu.stop)
