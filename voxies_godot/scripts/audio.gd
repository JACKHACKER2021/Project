extends Node
## Zvuk: všechny efekty a hlasy jsou předrenderované z původního syntezátoru Remasteru.
## Panorama přes sběrnice, „rádio" (reproduktor/kamera) přes pásmovou propust.

var game
var AUD: Dictionary
var cache := {}
var buses := {}
var ambient: AudioStreamPlayer
var buzz: AudioStreamPlayer
var music_box: AudioStreamPlayer
var chip: AudioStreamPlayer
var menu: AudioStreamPlayer
var voice_p: AudioStreamPlayer
const PANS := [-1.0, -0.85, -0.6, -0.4, 0.0, 0.4, 0.6, 0.85, 1.0]

func _ready() -> void:
	AUD = game.AUD
	for p in PANS:
		_bus("pan" + str(p), p, false)
		_bus("radio" + str(p), p, true)
	ambient = _loop("ambient", 0.0)
	buzz = _loop("buzz", 0.0)
	music_box = AudioStreamPlayer.new()
	var song = load("res://audio/powerout_song.ogg")
	if song is AudioStreamOggVorbis:
		song.loop = false
	music_box.stream = song
	music_box.bus = _bus_for(-0.6, false)
	add_child(music_box)
	chip = _loop("chiptune", 0.0)
	menu = AudioStreamPlayer.new()
	var ms = load("res://audio/menu.mp3")
	if ms is AudioStreamMP3:
		ms.loop = true
	menu.stream = ms
	menu.bus = _bus_for(0.0, false)
	add_child(menu)
	voice_p = AudioStreamPlayer.new()
	add_child(voice_p)

func _bus(name: String, pan: float, radio: bool) -> void:
	var i := AudioServer.bus_count
	AudioServer.add_bus(i)
	AudioServer.set_bus_name(i, name)
	AudioServer.set_bus_send(i, "Master")
	if pan != 0.0:
		var p := AudioEffectPanner.new()
		p.pan = pan
		AudioServer.add_bus_effect(i, p)
	if radio:
		var hp := AudioEffectHighPassFilter.new()
		hp.cutoff_hz = 500
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 2800
		var d := AudioEffectDistortion.new()
		d.mode = AudioEffectDistortion.MODE_LOFI
		d.drive = 0.2
		AudioServer.add_bus_effect(i, hp)
		AudioServer.add_bus_effect(i, lp)
		AudioServer.add_bus_effect(i, d)
	buses[name] = i

func _bus_for(pan: float, radio: bool) -> String:
	var best := 0.0
	var bd := 9.0
	for p in PANS:
		if absf(p - pan) < bd:
			bd = absf(p - pan)
			best = p
	return ("radio" if radio else "pan") + str(best)

func _stream(path: String) -> AudioStream:
	if not cache.has(path):
		cache[path] = load(path)
	return cache[path]

func _loop(name: String, pan: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var s: AudioStreamWAV = _stream("res://sfx/" + name + ".wav").duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	p.stream = s
	p.bus = _bus_for(pan, false)
	add_child(p)
	return p

func _play(stream: AudioStream, vol: float, pan: float, radio := false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = linear_to_db(maxf(0.0001, vol))
	p.bus = _bus_for(pan, radio)
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p

## sfx(name, pan, vol): vol je poměr k hlasitosti, ve které byl efekt nahraný
func sfx(name: String, pan := 0.0, vol := -1.0) -> void:
	var k := 1.0
	if name == "step" and vol >= 0:
		k = clampf(vol / 0.2, 0.05, 2.5)
	elif vol >= 0:
		k = clampf(vol, 0.05, 1.5)
	_play(_stream("res://sfx/" + name + ".wav"), k, pan)

func steps(pan: float, n: int, vol: float, gap := 0.48, fade := 0.0) -> void:
	for i in n:
		var v := maxf(0.02, vol - fade * i)
		game.get_tree().create_timer(i * gap).timeout.connect(func(): sfx("step", pan, v))

## vrací délku repliky v sekundách
func voice(key: String, vol: float, pan: float, radio: bool) -> float:
	var v = AUD.voice.get(key)
	if v == null:
		return 2.0
	_play(_stream("res://voice/" + v.f), vol / 0.9 * (1.4 if radio else 1.0), pan, radio)
	return v.dur

func stop_voice() -> void:
	for c in get_children():
		if c is AudioStreamPlayer and c.stream and String(c.stream.resource_path).begins_with("res://voice/"):
			c.queue_free()

func start_ambient() -> void:
	if not ambient.playing:
		ambient.volume_db = -30
		ambient.play()
		create_tween().tween_property(ambient, "volume_db", 0.0, 2.0)
func stop_ambient() -> void:
	ambient.stop()
func set_buzz(on: bool, pan := 0.0) -> void:
	buzz.stop()
	if on:
		buzz.bus = _bus_for(pan, false)
		buzz.play()
## při 0 % proudu hraje narozeninová písnička od Voxieho
func start_music_box(from := 0.0) -> void:
	if not music_box.playing:
		music_box.volume_db = 0.0
		music_box.play(from)
func stop_music_box() -> void:
	if music_box.playing:
		var t := create_tween()
		t.tween_property(music_box, "volume_db", -40.0, 0.4)
		t.tween_callback(music_box.stop)
func start_chip() -> void:
	chip.play()
func stop_chip() -> void:
	chip.stop()
func start_menu_song() -> void:
	if menu.playing or game.scene_ != "menu" and game.scene_ != "loading":
		return
	menu.volume_db = -40
	menu.play()
	create_tween().tween_property(menu, "volume_db", linear_to_db(0.8), 1.5)
func stop_menu_song() -> void:
	if menu.playing:
		var t := create_tween()
		t.tween_property(menu, "volume_db", -40.0, 0.6)
		t.tween_callback(menu.stop)

func song_len() -> float:
	return music_box.stream.get_length() if music_box.stream else 20.0

## jumpscare zvuky postav (vlastní nahrávky)
func scare(id: String) -> void:
	var path := "res://audio/scare_cocoa.mp3" if id == "C" else "res://audio/scare_voxie.mp3"
	_play(_stream(path), 1.0, 0.0)
